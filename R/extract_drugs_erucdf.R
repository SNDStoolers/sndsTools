#' Extrait les dispensations de médicaments en accès précoces depuis le DCIR.
#'
#' @description Cette fonction permet
#' d'extraire les dispensations de médicaments en accès précoces réalisés en
#' hospitalisation privée (ex-OQN) ou en rétrocession hospitalière privée et
#' publique (ex-OQN et ex-DGF).
#' Les dispensations dont les dates `EXE_SOI_DTD` sont comprises entre
#' `start_date` et `end_date` (incluses) sont extraites.
#'
#' @details Le décalage de remontée des données est pris en compte en récupérant
#' également les dispensations dont les dates `FLX_DIS_DTD` sont comprises dans
#' les `dis_dtd_lag_months` mois suivant end_date.
#'
#' NB: La jointure avec la table établissement est faite avec un inner_join. On
#' ne garde que les AP prescrites en établissement.
#'
#' @param conn DBI connection. Une connexion à la base de données Oracle.
#' @param start_date Date. La date de début de la période des dispensations à
#' extraire.
#' @param end_date Date. La date de fin de la période des dispensations à
#' extraire.
#' @param ucd_codes_filter Character vector (Optionnel). Les codes UCD des
#' dispensations de médicaments à extraire. Attention, les codes UCD doivent
#' être fournis au format UCD 7 caractères préfixé de 6 zéros :
#' "0000009419723". Ce format est celui utilisé dans la base de données.
#' Si NULL, extrait tous les codes.
#' @param patients_ids_filter data.frame (Optionnel). Un data.frame contenant
#' les paires d'identifiants des patients pour lesquels les délivrances de
#' médicaments doivent être extraites. Les colonnes de ce data.frame doivent
#' être "BEN_IDT_ANO", "BEN_NIR_PSA" et "BEN_RNG_GEM". Les "BEN_NIR_PSA" doivent
#' être tous les "BEN_NIR_PSA" associés aux "BEN_IDT_ANO" fournis. Défaut à
#' NULL.
#' @param dis_dtd_lag_months Integer (Optionnel). Le nombre maximum de mois de
#' décalage de FLX_DIS_DTD par rapport à EXE_SOI_DTD pris en compte pour
#' récupérer les dispensations de médicaments. Défaut à 6 mois.
#' @param sup_columns Character vector (Optionnel). Les colonnes supplémentaires
#' à ajouter à la table de sortie. Défaut à NULL, donc aucune colonne ajoutée.
#' @return Retourne une lazy table contenant les dispensations de médicaments en
#' accès précoces. Les colonnes de la table de sortie sont :
#' - BEN_NIR_PSA : Colonne présente uniquement si les identifiants
#' patients (`patients_ids_filter`) ne sont pas fournis. Identifiant SNDS,
#' aussi appelé pseudo-NIR.
#' - BEN_IDT_ANO : Colonne présente uniquement si les identifiants
#' patients (`patients_ids_filter`) sont fournis. Numéro d'inscription
#' au répertoire (NIR) anonymisé.
#' - BEN_RNG_GEM : Colonne présente uniquement si les identifiants
#' patients (`patients_ids_filter`) ne sont pas fournis. Rang GEM.
#' - EXE_SOI_DTD : Date de la prestation
#' - EXE_SOI_DTF : Heure de la prestation
#' - PRS_NAT_REF : Code de la nature de la prestation
#' - UCD_TOP_UCD : Circuit de délivrance
#' - UCD_UCD_COD : Code UCD du médicament
#' - UCD_DLV_NBR : Nombre de délivrances
#' - Les colonnes supplémentaires spécifiées dans `sup_columns` si fournies.
#'
#' @examples
#' \dontrun{
#' start_date <- as.Date("2019-01-01")
#' end_date <- as.Date("2019-12-31")
#' ucd_codes <- c("0000009419723")
#' conn <- connect_oracle()
#'
#' result <- extract_drugs_erucdf(
#'   conn = conn,
#'   start_date = start_date,
#'   end_date = end_date,
#'   ucd_codes_filter = ucd_codes
#' )
#' }
#' @family extract
#' @export
extract_drugs_erucdf <- function(
  conn,
  start_date,
  end_date,
  ucd_codes_filter = NULL,
  patients_ids_filter = NULL,
  dis_dtd_lag_months = 6,
  sup_columns = NULL
) {
  stopifnot(
    !is.null(conn),
    !is.null(start_date),
    !is.null(end_date),
    inherits(conn, "DBIConnection"),
    inherits(start_date, "Date"),
    inherits(end_date, "Date"),
    start_date <= end_date
  )

  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

  if (!is.null(patients_ids_filter)) {
    stopifnot(
      identical(
        names(patients_ids_filter),
        c("BEN_IDT_ANO", "BEN_NIR_PSA", "BEN_RNG_GEM")
      ),
      !anyDuplicated(patients_ids_filter)
    )
    patients_ids_table_name <- glue::glue("TMP_PATIENTS_IDS_{timestamp}")
    DBI::dbWriteTable(
      conn,
      patients_ids_table_name,
      patients_ids_filter,
      temporary = TRUE,
      overwrite = TRUE
    )
  }
  # TODO: Extract as a utils.
  dis_dtd_end_date <- end_date |>
    lubridate::add_with_rollback(months(dis_dtd_lag_months)) |>
    lubridate::floor_date("months")

  start_year <- lubridate::year(start_date)
  end_year <- lubridate::year(dis_dtd_end_date)

  formatted_start_date <- format(start_date, "%Y-%m-%d")
  formatted_end_date <- format(end_date, "%Y-%m-%d")
  formatted_dis_dtd_end_date <- format(dis_dtd_end_date, "%Y-%m-%d")

  first_non_archived_year <- get_first_non_archived_year(conn)
  # For archived years, flx distrib for exec in dec. in year Y are in jan/feb of year Y+1 cf. https://github.com/SNDStoolers/sndsTools/issues/82 # nolint
  # TODO: we need to add a test for this special case.
  if (start_year <= first_non_archived_year) {
    dis_dtd_end_date <- max(
      dis_dtd_end_date,
      end_date |>
        lubridate::add_with_rollback(months(dis_dtd_lag_months + 2)) |>
        lubridate::floor_date("months")
    )
  }

  if (!is.null(ucd_codes_filter)) {
    logger::log_info(
      glue::glue(
        "Extracting drug dispenses with UTC codes starting with {paste(ucd_codes_filter, collapse = ' or ')}" # nolint
      )
    )
    # filter
    filter_ucd <- dplyr::tibble(UCD_UCD_COD = ucd_codes_filter)
    filter_ucd_table_name <- "SDNS_TOOLS_TMP_FILTER_UCD"
    if (DBI::dbExistsTable(conn, filter_ucd_table_name)) {
      DBI::dbRemoveTable(conn, filter_ucd_table_name)
    }
    DBI::dbWriteTable(conn, filter_ucd_table_name, filter_ucd)
    filter_ucd_table <- dplyr::tbl(conn, filter_ucd_table_name)
  } else {
    logger::log_info(glue::glue("Extracting drug dispenses for all UTC codes"))
  }

  if (start_year <= first_non_archived_year) {
    er_prs_f <- purrr::map(
      start_year:min(end_year, first_non_archived_year - 1),
      function(year) {
        tbl_oracle(conn, glue::glue("ER_PRS_F_{year}"))
      }
    ) |>
      purrr::reduce(dplyr::union_all) |>
      dplyr::union_all(
        tbl_oracle(conn, "ER_PRS_F")
      )

    er_ucd_f <- purrr::map(
      start_year:min(end_year, first_non_archived_year - 1),
      function(year) {
        tbl_oracle(conn, glue::glue("ER_UCD_F_{year}"))
      }
    ) |>
      purrr::reduce(dplyr::union_all) |>
      dplyr::union_all(
        tbl_oracle(conn, "ER_UCD_F")
      )

    er_ete_f <- purrr::map(
      start_year:min(end_year, first_non_archived_year - 1),
      function(year) {
        tbl_oracle(conn, glue::glue("ER_ETE_F_{year}"))
      }
    ) |>
      purrr::reduce(dplyr::union_all) |>
      dplyr::union_all(
        tbl_oracle(conn, "ER_ETE_F")
      )
  } else {
    er_prs_f <- tbl_oracle(conn, "ER_PRS_F")
    er_ucd_f <- tbl_oracle(conn, "ER_UCD_F")
    er_ete_f <- tbl_oracle(conn, "ER_ETE_F")
  }

  dis_dtd_condition <- glue::glue(
    "FLX_DIS_DTD >= DATE '{formatted_start_date}' AND FLX_DIS_DTD <= DATE '{formatted_dis_dtd_end_date}'" # nolint
  )

  exe_soi_dtd_condition <- glue::glue(
    "EXE_SOI_DTD >= DATE '{formatted_start_date}' AND EXE_SOI_DTD <= DATE '{formatted_end_date}'" # nolint
  )
  er_prs_f_filtered <- er_prs_f |>
    dplyr::filter(
      dbplyr::sql(dis_dtd_condition),
      dbplyr::sql(exe_soi_dtd_condition),
      !(DPN_QLF %in% c(71, 72)),
      CPL_MAJ_TOP < 2L,
      BEN_CDI_NIR %in% c("00", "03", "04")
    ) |>
    dplyr::mutate(PRS_NAT_REF = as.character(PRS_NAT_REF))

  er_ucd_f_filtered <- er_ucd_f |>
    dplyr::filter(dbplyr::sql(dis_dtd_condition))
  if (!is.null(ucd_codes_filter)) {
    er_ucd_f_filtered <- er_ucd_f_filtered |>
      dplyr::inner_join(filter_ucd_table, by = "UCD_UCD_COD")
  }

  ap_dans_er_ucd_f <- er_prs_f_filtered |>
    dplyr::inner_join(er_ucd_f_filtered, by = COLS_DCIR_JOIN_KEY)

  er_ete_f <- er_ete_f |>
    dplyr::filter(dbplyr::sql(dis_dtd_condition))
  query <- ap_dans_er_ucd_f |>
    dplyr::inner_join(er_ete_f, by = COLS_DCIR_JOIN_KEY)

  cols_to_select <- c(
    "BEN_NIR_PSA",
    "BEN_RNG_GEM",
    "EXE_SOI_DTD",
    "EXE_SOI_DTF",
    "PRS_NAT_REF",
    "UCD_TOP_UCD",
    "UCD_UCD_COD",
    "UCD_DLV_NBR"
  )
  if (!is.null(sup_columns)) {
    cols_to_select <- c(cols_to_select, sup_columns)
  }
  result <- query |>
    dplyr::select(dplyr::all_of(cols_to_select)) |>
    dplyr::distinct()

  if (!is.null(patients_ids_filter)) {
    patients_ids_table <- dplyr::tbl(conn, patients_ids_table_name)
    patients_ids_table <- patients_ids_table |>
      dplyr::select(BEN_IDT_ANO, BEN_NIR_PSA, BEN_RNG_GEM) |>
      dplyr::distinct()
    result <- result |>
      dplyr::inner_join(
        patients_ids_table,
        by = c("BEN_NIR_PSA", "BEN_RNG_GEM")
      ) |>
      dplyr::select(BEN_IDT_ANO, dplyr::all_of(cols_to_select)) |>
      dplyr::distinct()
  }

  result
}
