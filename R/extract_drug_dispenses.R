#' Extraction des délivrances de médicaments.
#'
#' @description Cette fonction permet
#' d'extraire les délivrances de médicaments par code ATC ou par code CIP13.
#' Les délivrances dont les dates `EXE_SOI_DTD` sont comprises entre
#' `start_date` et `end_date` (incluses) sont extraites.
#'
#' @details Le décalage de remontée des données est pris en compte en récupérant
#' également les délivrances dont les dates `FLX_DIS_DTD` sont comprises dans
#' les `dis_dtd_lag_months` mois suivant end_date.
#'
#' #' Si `atc_cod_starts_with` ou `cip13_codes` sont fournies, seules les
#' délivrances de médicaments dont le code ATC commence par l'un des éléments de
#' `atc_cod_starts_with` OU dont le code CIP13 est dans `cip13_codes` sont
#' extraites. Dans le cas ou aucun des filtres n'est renseigné, les délivrances
#' pour tous les codes ATC et CIP13 sont extraites. Si l'un des filtres est
#' `NULL`, mais pas l'autre, seul les délivrances pour le filtre non `NULL` sont
#' extraites.
#'
#' Si `patients_ids_filter` est fourni, seules les délivrances de médicaments
#' pour les patients dont les identifiants sont dans `patients_ids_filter` sont
#' extraites. Dans le cas contraire, les délivrances de tous les patients sont
#' extraites.

#' Pour être à flux constant sur l'ensemble des années, il faut utiliser
#' `dis_dtd_lag_months` = 27 Cela rallonge le temps d'extraction alors que
#' l'impact sur l'extraction est minime car la Cnam estime que 99 % des soins
#' sont remontés à 6 mois c'est-à-dire pour dis_dtd_lag_months = 6 Voir
#' https://documentation-snds.health-data-hub.fr/snds/formation_snds/initiation/schema_relationnel_snds.html#_3-3-dcir
#'
#' @param start_date Date. La date de début de la période
#'   des délivrances des médicaments à extraire.
#' @param end_date Date. La date de fin de la période
#'   des délivrances des médicaments à extraire.
#' @param atc_cod_starts_with_filter Character vector (Optionnel). Les codes ATC
#'   par lesquels les délivrances de médicaments à extraire
#'   doivent commencer. Défaut à NULL.
#' @param cip13_cod_filter Character vector (Optionnel). Les codes CIP des
#'   délivrances de médicaments à extraire en complément des codes ATC. Défaut à
#' NULL.
#' @param patients_ids_filter data.frame (Optionnel). Un data.frame contenant
#'   les paires d'identifiants des patients pour lesquels les délivrances de
#'   médicaments doivent être extraites. Les colonnes de ce data.frame doivent
#'   être "BEN_IDT_ANO" et "BEN_NIR_PSA". Les "BEN_NIR_PSA" doivent être tous
#'   les "BEN_NIR_PSA" associés aux "BEN_IDT_ANO" fournis. Défaut à NULL.
#' @param dis_dtd_lag_months Integer (Optionnel). Le nombre maximum de mois de
#'   décalage de FLX_DIS_DTD par rapport à EXE_SOI DTD pris en compte pour
#'   récupérer les délivrances de médicaments. Défaut à 6 mois.
#' @param sup_columns Character vector (Optionnel). Les colonnes supplémentaires
#'  à ajouter à la table de sortie. Défaut à NULL, donc aucune colonne ajoutée.
#' @param output_table_name Character (Optionnel). Si fourni, les résultats
#'   seront sauvegardés dans une table portant ce nom dans la base de données au
#'   lieu d'être retournés sous forme de data frame. Si la table existe déjà
#'   dans la base oracle, alors le programme s'arrête en retournant une erreur.
#'   Défault à NULL.
#' @param conn DBI connection (Optionnel). Une connexion à la base de données
#'   Oracle. Si non fournie, une connexion est établie par défaut. Défaut à
#'   NULL.
#' @return Si output_table_name est NULL, retourne un data.frame contenant les
#'   délivrances de médicaments. Si output_table_name est fourni, sauvegarde les
#'   résultats dans la table spécifiée dans Oracle et retourne NULL de manière
#'   invisible. Dans les deux cas les colonnes de la table de sortie sont :
#'   - BEN_NIR_PSA : Colonne présente uniquement si les identifiants
#'   patients (`patients_ids_filter`) ne sont pas fournis. Identifiant SNDS,
#'   aussi appelé pseudo-NIR.
#'   - BEN_IDT_ANO : Colonne présente uniquement si les identifiants
#'   patients (`patients_ids_filter`) sont fournis. Numéro d’inscription
#'   au répertoire (NIR) anonymisé.
#'   - EXE_SOI_DTD : Date de la délivrance
#'   - PHA_ACT_QSN : Quantité délivrée
#'   - PHA_ATC_CLA : Code ATC du médicament délivré
#'   - PHA_PRS_C13 : Code CIP du médicament délivré (nom dans la table
#'    ER_PHA_F : PHA_PRS_C13, nom dans la table IR_PHA_R : PHA_CIP_C13)
#'   - PSP_SPE_COD : Code de spécialité du professionnel de soin prescripteur
#'   (voir nomenclature IR_SPE_V)
#'  - Les colonnes supplémentaires spécifiées dans `sup_columns` si fournies.
#'
#' @examples
#' \dontrun{
#' start_date <- as.Date("2010-01-01")
#' end_date <- as.Date("2010-01-03")
#' atc_cod_starts_with <- c("N04A")
#'
#' dispenses <- extract_drug_dispenses(
#'   start_date = start_date,
#'   end_date = end_date,
#'   atc_cod_starts_with = atc_cod_starts_with
#' )
#' }
#' @export
extract_drug_dispenses <- function(start_date,
                                   end_date,
                                   atc_cod_starts_with_filter = NULL,
                                   cip13_cod_filter = NULL,
                                   patients_ids_filter = NULL,
                                   dis_dtd_lag_months = 6,
                                   sup_columns = NULL,
                                   output_table_name = NULL,
                                   conn = NULL,
                                   show_sql_query = TRUE) {
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
      !DBI::dbExistsTable(conn, output_table_name)
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
      conn, patients_ids_table_name, patients_ids_filter,
      overwrite = TRUE
    )
  }

  dis_dtd_end_date <-
    end_date |>
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

  if (!is.null(atc_cod_starts_with_filter)) {
    print(
      glue::glue(
        "Extracting drug dispenses with ATC codes starting with {paste(atc_cod_starts_with_filter, collapse = ' or ')}" # nolint
      )
    )
  } else {
    print(glue::glue("Extracting drug dispenses for all ATC codes"))
  }

  if (!is.null(cip13_cod_filter)) {
    print(
      glue::glue(
        "Extracting drug dispenses with CIP13 codes {paste(cip13_cod_filter, collapse = ' or ')}" # nolint
      )
    )
  } else {
    print(glue::glue("Extracting drug dispenses for all CIP13 codes"))
  }

  ir_pha_r <- dplyr::tbl(conn, "IR_PHA_R")

  if (!is.null(atc_cod_starts_with_filter)) {
    starts_with_conditions <- vapply(
      atc_cod_starts_with_filter, function(code) {
        glue::glue("PHA_ATC_CLA LIKE '{code}%'")
      }, character(1)
    )
    atc_conditions <- paste(starts_with_conditions, collapse = " OR ")
    atc_conditions <- glue::glue("({atc_conditions})")
  }

  if (!is.null(cip13_cod_filter)) {
    cip13_conditions <- glue::glue(
      "PHA_CIP_C13 IN ({paste(cip13_cod_filter, collapse = ',')})"
    )
  }
  if (!is.null(atc_cod_starts_with_filter) &&
    !is.null(cip13_cod_filter)) {
    drug_filter <- atc_conditions + " OR " + cip13_conditions
  } else if (!is.null(cip13_cod_filter) &&
    is.null(atc_cod_starts_with_filter)) {
    drug_filter <- cip13_conditions
  } else if (!is.null(atc_cod_starts_with_filter) &&
    is.null(cip13_cod_filter)) {
    drug_filter <- atc_conditions
  } else {
    drug_filter <- NULL
  }

  ir_pha_cols <- colnames(ir_pha_r)
  ir_pha_needed_cols <- c("PHA_CIP_C13", "PHA_ATC_CLA")
  for (col in sup_columns) {
    if (col %in% ir_pha_cols) {
      ir_pha_needed_cols <- c(ir_pha_needed_cols, col)
    }
  }
  ir_pha_filtered <- ir_pha_r |> dplyr::select(
    dplyr::all_of(ir_pha_needed_cols)
  )
  if (!is.null(drug_filter)) {
    ir_pha_filtered_query <- ir_pha_filtered |>
      dplyr::filter(dbplyr::sql(drug_filter)) |>
      dbplyr::sql_render()
  }
  ir_pha_r_filtered_name <- glue::glue("TMP_IR_PHA_R_{timestamp}")
  DBI::dbExecute(
    conn,
    glue::glue(
      "CREATE TABLE {ir_pha_r_filtered_name} AS {ir_pha_filtered_query}"
    )
  )
  ir_pha_filtered_table <- dplyr::tbl(conn, ir_pha_r_filtered_name)

  pb <- progress::progress_bar$new(
    format = "Extracting :year1 (going from :year2 to :year3) [:bar] :percent in :elapsed (eta: :eta)", # nolint
    total = (end_year - start_year + 1),
    clear = FALSE,
    width = 80
  )
  pb$tick(0)
  for (year in start_year:end_year) {
    pb$tick(tokens = list(
      year1 = year,
      year2 = start_year,
      year3 = end_year
    ))

    if (year < first_non_archived_year) {
      er_prs_f <- dplyr::tbl(conn, glue::glue("ER_PRS_F_{year}"))
      er_pha_f <- dplyr::tbl(conn, glue::glue("ER_PHA_F_{year}"))
      er_ete_f <- dplyr::tbl(conn, glue::glue("ER_ETE_F_{year}"))
    } else {
      er_prs_f <- dplyr::tbl(conn, "ER_PRS_F")
      er_pha_f <- dplyr::tbl(conn, "ER_PHA_F")
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

      print(glue::glue("-flux: {dis_dtd_start} to {dis_dtd_end}"))

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
      ir_pha_col_distinct_from_er_pha <- setdiff(
        colnames(ir_pha_filtered_table),
        colnames(er_pha_f)
      )

      query <- er_prs_f |>
        dplyr::inner_join(er_pha_f, by = dcir_join_keys) |>
        dplyr::inner_join(
          ir_pha_filtered_table |>
            dplyr::select(dplyr::all_of(ir_pha_col_distinct_from_er_pha)),
          by = c("PHA_PRS_C13" = "PHA_CIP_C13")
        ) |>
        dplyr::left_join(er_ete_f, by = dcir_join_keys) |>
        dplyr::filter(
          dbplyr::sql(soi_dtd_condition),
          dbplyr::sql(dis_dtd_condition)
        ) |>
        dplyr::filter(
          DPN_QLF != 71L,
          CPL_MAJ_TOP < 2L,
          (ETE_IND_TAA != 1L) || is.na(ETE_IND_TAA)
        )

      cols_to_select <- c(
        "EXE_SOI_DTD",
        "PHA_ACT_QSN",
        "PHA_ATC_CLA",
        "PHA_PRS_C13",
        "PSP_SPE_COD"
      )
      if (!is.null(sup_columns)) {
        cols_to_select <- c(cols_to_select, sup_columns)
      }

      query <- query |>
        dplyr::select(BEN_NIR_PSA, dplyr::all_of(cols_to_select)) |>
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

      query <- query |> dbplyr::sql_render()
      if (year == start_year && month == flux_start_month) {
        DBI::dbExecute(
          conn,
          glue::glue("CREATE TABLE {output_table_name} AS {query}")
        )
        if (show_sql_query) {
          message(glue::glue("Premier mois requêté en date de flux à l'aide de la requête sql suivante :\n {query}"))
        }
      } else {
        DBI::dbExecute(
          conn,
          glue::glue("INSERT INTO {output_table_name} {query}")
        )
      }
    }
  }

  DBI::dbRemoveTable(conn, ir_pha_r_filtered_name)

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

  return(result)
}
