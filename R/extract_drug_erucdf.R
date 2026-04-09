#' Extrait les dispensations de médicaments en accès précoces depuis le DCIR.
#'
#' Extrait les dispensations de médicaments en accès précoces réalisés en
#' hospitalisation privée (ex-OQN) ou en rétrocession hospitalière privée et
#' publique (ex-OQN et ex-DGF) pour une année donnée et une liste de codes UCD
#' donnée.
#'
#' Les données sont filtrées par date de prestation (`EXE_SOI_DTD`), et par date
#' de flux (`FLX_DIS_DTD`) en regardant 7 mois au delà de la date de fin d'étude
#' `end_date` pour prendre en compte la durée de remontée de l'information. Les
#' données sont filtrées en ne conservant que les PRS_NAT_REF d'accès précoces
#' ("3336", "3317", "3351", "3421").
#'
#' NB: Les données sont extraites par date de flux, puis filtrées par date de
#' soin.  Elles sont extraites d'un bloc sur la période d'intérêt par contraste
#' avec les recommandations de la CNAM qui préconise d'extraire mois par mois
#' pour des raisons d'optimisation technique (éviter la saturation d'un
#' temporary space partagé entre utilisateurs). L'alternative serait de code une
#' fonction extrayant mois par mois (ie. "magic loop").
#'
#' NB: La jointure avec la table établissement est faite avec un inner_join. On
#' ne garde que les AP préscrites en établissement.
#'
#' @param start_date Début d'extraction (date de soin)
#' @param end_date Fin d'extraction (date de soin)
#' @param ucd_codes_filter Liste de codes ucd à extraire. Attention, les codes
#' UCD doivent être fournis au format UCD 7 caractères préfixé de 6 zéros :
#' "0000009419723". Ce format est celui utilisé dans la base de données.
#' Si NULL, extrait tous les codes.
#' @param patients_ids_filter data.frame (Optionnel). Un data.frame contenant
#' les paires d'identifiants des patients pour lesquels les délivrances de
#' médicaments doivent être extraites. Les colonnes de ce data.frame doivent
#' être "BEN_IDT_ANO" et "BEN_NIR_PSA". Les "BEN_NIR_PSA" doivent être tous
#' les "BEN_NIR_PSA" associés aux "BEN_IDT_ANO" fournis. Défaut à NULL.
#' @param dis_dtd_lag_months Integer (Optionnel). Le nombre maximum de mois de
#' décalage de FLX_DIS_DTD par rapport à EXE_SOI DTD pris en compte pour
#' récupérer les délivrances de médicaments. Défaut à 6 mois.
#' @param sup_columns Character vector (Optionnel). Les colonnes supplémentaires
#' à ajouter à la table de sortie. Défaut à NULL, donc aucune colonne ajoutée.
#' @param output_table_name Character (Optionnel). Si fourni, les résultats
#' seront sauvegardés dans une table portant ce nom dans la base de données au
#' lieu d'être retournés sous forme de data frame. Si la table existe déjà
#' dans la base oracle, alors le programme s'arrête en retournant une erreur.
#' Défaut à NULL.
#' @param conn DBI connection (Optionnel). Une connexion à la base de données
#' Oracle. Si non fournie, une connexion est établie par défaut. Défaut à
#' NULL.
#' @param show_sql_query Boolean (Optionnel). Affiche la requête SQL du premier
#'  mois. Défaut à FALSE.
#'
#' @return Consommations individuelles d'accès précoces pour l'hospitalisation
#' privée et les rétrocessions hospitalières.
#'
#'  @examples
#'  \dontrun{
#'  result <- extract_drug_erucdf(
#'    start_date = as.Date("2019-01-01"),
#'    end_date = as.Date("2019-12-31"),
#'    ucd_codes_filter = c("0000009419723"),
#'    output_table_name = "result_drug_erucdf",
#'    dis_dtd_lag_months = 6
#'  )
#' }*
#' @family extract
#' @export
extract_drug_erucdf <- function(
  start_date,
  end_date,
  ucd_codes_filter = NULL,
  patients_ids_filter = NULL,
  dis_dtd_lag_months = 6,
  sup_columns = NULL,
  output_table_name = NULL,
  conn = NULL,
  show_sql_query = FALSE
) {
  stopifnot(
    !is.null(start_date),
    !is.null(end_date),
    inherits(start_date, "Date"),
    inherits(end_date, "Date"),
    start_date <= end_date
  )

  connection_opened <- FALSE
  if (is.null(conn)) {
    conn <- connect_oracle()
    connection_opened <- TRUE
  }

  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  if (!is.null(output_table_name)) {
    output_table_name_is_temp <- FALSE
    stopifnot(
      is.character(output_table_name),
      !DBI::dbExistsTable(conn, toupper(output_table_name))
    )
  } else {
    output_table_name_is_temp <- TRUE
    output_table_name <- glue::glue("TMP_DISP_{timestamp}")
  }

  if (!is.null(patients_ids_filter)) {
    stopifnot(
      identical(
        names(patients_ids_filter),
        c("BEN_IDT_ANO", "BEN_NIR_PSA")
      ),
      !anyDuplicated(patients_ids_filter)
    )
    patients_ids_table_name <- glue::glue("TMP_PATIENTS_IDS_{timestamp}")
    DBI::dbWriteTable(
      conn,
      patients_ids_table_name,
      patients_ids_filter,
      overwrite = TRUE
    )
  }
  dis_dtd_end_date <- end_date |>
    lubridate::add_with_rollback(months(dis_dtd_lag_months)) |>
    lubridate::floor_date("months")

  start_year <- lubridate::year(start_date)
  end_year <- lubridate::year(dis_dtd_end_date)
  start_month <- lubridate::month(start_date)
  formatted_start_date <- format(start_date, "%Y-%m-%d")
  formatted_end_date <- format(end_date, "%Y-%m-%d")
  formatted_dis_dtd_end_date <- format(dis_dtd_end_date, "%Y-%m-%d")
  dis_dtd_end_month <- lubridate::month(formatted_dis_dtd_end_date)

  first_non_archived_year <- get_first_non_archived_year(conn)

  if (!is.null(ucd_codes_filter)) {
    logger::log_info(
      glue::glue(
        "Extracting drug dispenses with UTC codes starting with {paste(ucd_codes_filter, collapse = ' or ')}" # nolint
      )
    )
  } else {
    logger::log_info(glue::glue("Extracting drug dispenses for all UTC codes"))
  }

  dcir_join_keys <- c(
    "DCT_ORD_NUM",
    "FLX_DIS_DTD",
    "FLX_EMT_ORD",
    "FLX_EMT_NUM",
    "FLX_EMT_TYP",
    "FLX_TRT_DTD",
    "ORG_CLE_NUM",
    "PRS_ORD_NUM",
    "REM_TYP_AFF"
  )
  # filter
  filter_ucd <- dplyr::tibble(UCD_UCD_COD = ucd_codes_filter)
  filter_ucd_table_name <- "SDNS_TOOLS_TMP_FILTER_UCD"
  DBI::dbWriteTable(conn, filter_ucd_table_name, filter_ucd, overwrite = TRUE)
  filter_ucd_table <- dplyr::tbl(conn, filter_ucd_table_name)
  # looping logic
  pb <- progress::progress_bar$new(
    format = "Extracting :year1 (going from :year2 to :year3) [:bar] :percent in :elapsed (eta: :eta)", # nolint
    total = (end_year - start_year + 1),
    clear = FALSE,
    width = 80
  )
  pb$tick(0)
  for (year in start_year:end_year) {
    pb$tick(
      tokens = list(
        year1 = year,
        year2 = start_year,
        year3 = end_year
      )
    )

    if (year < first_non_archived_year) {
      er_prs_f <- dplyr::tbl(conn, glue::glue("ER_PRS_F_{year}"))
      er_ucd_f <- dplyr::tbl(conn, glue::glue("ER_UCD_F_{year}"))
      er_ete_f <- dplyr::tbl(conn, glue::glue("ER_ETE_F_{year}"))
    } else {
      er_prs_f <- dplyr::tbl(conn, "ER_PRS_F")
      er_ucd_f <- dplyr::tbl(conn, "ER_UCD_F")
      er_ete_f <- dplyr::tbl(conn, "ER_ETE_F")
    }

    flux_start_month <- 1
    flux_end_month <- 12
    if (year == end_year) {
      flux_end_month <- dis_dtd_end_month
    }
    if (year == start_year) {
      flux_start_month <- max(1, start_month)
    }
    for (month in c(flux_start_month:flux_end_month)) {
      dis_dtd_start <- glue::glue("DATE '{year}-{sprintf('%02d', month)}-01'")
      dis_dtd_end <- glue::glue("DATE '{year}-{sprintf('%02d', month + 1)}-01'")

      if ((year != end_year) && (month == 12)) {
        # For archived years, some lines of decembers are indexed in the
        # following year: https://github.com/SNDStoolers/sndsTools/issues/26
        dis_dtd_end <- glue::glue("DATE '{year + 1}-01-01'")
      }
      dis_dtd_condition <- glue::glue(
        "FLX_DIS_DTD >= {dis_dtd_start} AND FLX_DIS_DTD < {dis_dtd_end}"
      )

      soi_dtd_condition <- glue::glue(
        "EXE_SOI_DTD >= DATE '{formatted_start_date}' AND EXE_SOI_DTD <= DATE '{formatted_end_date}'" # nolint
      )

      logger::log_info(glue::glue("-flux: {dis_dtd_start} to {dis_dtd_end}"))
      er_prs_f_filtered <- er_prs_f |>
        dplyr::filter(
          dbplyr::sql(dis_dtd_condition),
          dbplyr::sql(soi_dtd_condition),
          !(DPN_QLF %in% c(71, 72)),
          CPL_MAJ_TOP < 2L,
          BEN_CDI_NIR %in% c("00", "03", "04") # NIR certifiés ou provisoires
        ) |>
        dplyr::mutate(PRS_NAT_REF = as.character(PRS_NAT_REF))

      er_ucd_f_filtered <- er_ucd_f |>
        dplyr::filter(dbplyr::sql(dis_dtd_condition))
      # TODO: use a join here instead of filter
      if (!is.null(ucd_codes_filter)) {
        er_ucd_f_filtered <- er_ucd_f_filtered |>
          dplyr::inner_join(filter_ucd_table, by = "UCD_UCD_COD")
      }

      ap_dans_er_ucd_f <- er_prs_f_filtered |>
        dplyr::inner_join(er_ucd_f_filtered, by = dcir_join_keys)

      er_ete_f <- dplyr::tbl(conn, "ER_ETE_F") |>
        dplyr::filter(
          dbplyr::sql(dis_dtd_condition),
          (ETE_IND_TAA != 1) | is.null(ETE_IND_TAA)
        )
      query <- ap_dans_er_ucd_f |>
        dplyr::inner_join(er_ete_f, by = dcir_join_keys)

      cols_to_select <- c(
        "BEN_NIR_PSA",
        "EXE_SOI_DTD",
        "EXE_SOI_DTF",
        "PRS_NAT_REF",
        "UCD_TOP_UCD", #circuit de délivrance (rétrocession ou délivrances en consultation externe / hospitalisation) #nolint
        "UCD_UCD_COD",
        "UCD_DLV_NBR"
      )
      if (!is.null(sup_columns)) {
        cols_to_select <- c(cols_to_select, sup_columns)
      }
      query <- query |>
        dplyr::select(dplyr::all_of(cols_to_select)) |>
        dplyr::distinct()

      if (!is.null(patients_ids_filter)) {
        patients_ids_table <- dplyr::tbl(conn, patients_ids_table_name)
        patients_ids_table <- patients_ids_table |>
          dplyr::select(BEN_IDT_ANO, BEN_NIR_PSA) |>
          dplyr::distinct()
        query <- query |>
          dplyr::inner_join(patients_ids_table, by = "BEN_NIR_PSA") |>
          dplyr::select(BEN_IDT_ANO, dplyr::all_of(cols_to_select)) |>
          dplyr::distinct()
      }

      # inserting data
      query <- query |> dbplyr::sql_render()
      if (!DBI::dbExistsTable(conn, output_table_name)) {
        DBI::dbExecute(
          conn,
          glue::glue("CREATE TABLE {output_table_name} AS {query}")
        )
        if (show_sql_query) {
          message(glue::glue(
            "Premier mois requêté en date de flux avec la requête sql suivante :\n {query}" # nolint
          ))
        }
      } else {
        DBI::dbExecute(
          conn,
          glue::glue("INSERT INTO {output_table_name} {query}")
        )
      }
    }
  }

  if (!is.null(patients_ids_filter)) {
    DBI::dbRemoveTable(conn, patients_ids_table_name)
  }

  if (output_table_name_is_temp) {
    query <- dplyr::tbl(conn, output_table_name)
    result <- dplyr::collect(query)
    DBI::dbRemoveTable(conn, output_table_name)
  } else {
    result <- invisible(NULL)
    message(glue::glue("Results saved to table {output_table_name} in Oracle."))
  }

  if (connection_opened) {
    DBI::dbDisconnect(conn)
  }

  result
}
