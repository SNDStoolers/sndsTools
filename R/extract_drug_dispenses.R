#' Extraction des délivrances de médicaments.
#' @description
#' Cette fonction permet d'extraire les délivrances de médicaments.
#' Les délivrances dont les dates EXE_SOI_DTD sont comprises
#' entre start_date et end_date (incluses) sont extraites.
#' Le décalage de remontée des données est pris en compte
#' en récupérant également les délivrances dont les dates
#' FLX_DIS_DTD sont comprises dans les `dis_dtd_lag_months`
#' mois suivant end_date.
#' Si atc_cod_starts_with est fourni, seules les délivrances
#' de médicaments dont le code ATC commence par l'un des
#' éléments de atc_cod_starts_with sont extraites. Dans le
#' cas contraire, les délivrances pour tous les codes
#' ATC sont extraites.
#' Si patients_ids est fourni, seules les délivrances
#' de médicaments pour les patients dont les identifiants
#' sont dans patients_ids sont extraites. Dans le cas
#' contraire, les délivrances de tous les patients sont
#' extraites.
#' @details
#' Pour être à flux constant sur l'ensemble des années,
#' il faut utiliser dis_dtd_lag_months = 27
#' Cela rallonge le temps d'extraction alors que l'impact sur
#' l'extraction est minime car la Cnam estime que 99 % des soins sont
#' remontés à 6 mois c'est-à-dire pour dis_dtd_lag_months = 6
#' Voir https://documentation-snds.health-data-hub.fr/snds/formation_snds/initiation/schema_relationnel_snds.html#_3-3-dcir
#'
#' @param start_date Date. La date de début de la période
#'   des délivrances des médicaments à extraire.
#' @param end_date Date La date de fin de la période
#'   des délivrances des médicaments à extraire.
#' @param atc_cod_starts_with Character vector Optionnel. Les codes ATC
#'   par lesquels les délivrances de médicaments à extraire
#'   doivent commencer.
#' @param dis_dtd_lag_months Integer. Le nombre maximum de
#'   mois de décalage de FLX_DIS_DTD par rapport à EXE_SOI DTD pris en compte
#'   pour récupérer les délivrances de médicaments. Par défaut, 6 mois.
#' @param patients_ids data.frame Optionnel. Un data.frame contenant les
#'   paires d'identifiants des patients pour lesquels les délivrances de
#'   médicaments doivent être extraites. Les colonnes de ce data.frame
#'   doivent être "BEN_IDT_ANO" et "BEN_NIR_PSA". Les "BEN_NIR_PSA" doivent
#'   être tous les "BEN_NIR_PSA" associés aux "BEN_IDT_ANO" fournis.
#' @param output_table_name Character Optionnel. Si fourni, les résultats seront
#'   sauvegardés dans une table portant ce nom dans la base de données au lieu
#'   d'être retournés sous forme de data frame.
#' @param overwrite Logical. Indique si la table `output_table_name`
#'  doit être écrasée dans le cas où elle existe déjà.
#' @param conn DBI connection Une connexion à la base de données Oracle.
#'   Si non fournie, une connexion est établie par défaut.
#' @return Si output_table_name est NULL, retourne un data.frame contenant les
#'   délivrances de médicaments. Si output_table_name est fourni, sauvegarde les
#'   résultats dans la table spécifiée dans Oracle et retourne NULL de manière
#'   invisible. Dans les deux cas les colonnes de la table de sortie sont :
#'   - BEN_NIR_PSA : Colonne présente uniquement si les identifiants
#'   patients (`patients_ids`) ne sont pas fournis. Identifiant SNDS,
#'   aussi appelé pseudo-NIR.
#'   - BEN_IDT_ANO : Colonne présente uniquement si les identifiants
#'   patients (`patients_ids`) sont fournis. Numéro d’inscription
#'   au répertoire (NIR) anonymisé.
#'   - EXE_SOI_DTD : Date de la délivrance
#'   - PHA_ACT_QSN : Quantité délivrée
#'   - PHA_ATC_CLA : Code ATC du médicament délivré
#'   - PHA_PRS_C13 : Code CIP du médicament délivré (nom dans la table
#'    ER_PHA_F : PHA_PRS_C13, nom dans la table IR_PHA_R : PHA_CIP_C13)
#'   - PSP_SPE_COD : Code de spécialité du professionnel de soin prescripteur
#'   (voir nomenclature IR_SPE_V)
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
extract_drug_dispenses <- function(
    start_date = NULL,
    end_date = NULL,
    atc_cod_starts_with = NULL,
    dis_dtd_lag_months = 6,
    patients_ids = NULL,
    output_table_name = NULL,
    overwrite = FALSE,
    conn = NULL) {
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
      !DBI::dbExistsTable(conn, output_table_name) || (DBI::dbExistsTable(conn, output_table_name) && overwrite)
    )
    if (DBI::dbExistsTable(conn, output_table_name) && overwrite) {
      warning(
        glue::glue(
          "Table {output_table_name} already exists and will be overwritten."
        )
      )
      DBI::dbRemoveTable(conn, output_table_name)
    }
  } else {
    output_table_name_is_temp <- TRUE
    output_table_name <- glue::glue("TMP_DISP_{timestamp}")
  }

  if (!is.null(patients_ids)) {
    stopifnot(
      identical(
        names(patients_ids),
        c("BEN_IDT_ANO", "BEN_NIR_PSA")
      ),
      !anyDuplicated(patients_ids)
    )
    patients_ids_table_name <- glue::glue("TMP_PATIENTS_IDS_{timestamp}")
    DBI::dbWriteTable(conn, patients_ids_table_name, patients_ids)
  }


  dis_dtd_end_date <-
    end_date |>
    lubridate::add_with_rollback(months(dis_dtd_lag_months)) |>
    lubridate::floor_date("months")

  start_year <- lubridate::year(start_date)
  end_year <- lubridate::year(dis_dtd_end_date)

  formatted_start_date <- format(start_date, "%Y-%m-%d")
  formatted_end_date <- format(end_date, "%Y-%m-%d")
  formatted_dis_dtd_end_date <- format(dis_dtd_end_date, "%Y-%m-%d")

  first_non_archived_year <- get_first_non_archived_year(conn)

  if (!is.null(atc_cod_starts_with)) {
    print(
      glue::glue(
        "Extracting drug dispenses with ATC codes starting with {paste(atc_cod_starts_with, collapse = ' or ')}..."
      )
    )
  } else {
    print(
      glue::glue(
        "Extracting drug dispenses for all ATC codes..."
      )
    )
  }

  pb <- progress::progress_bar$new(
    format = "Extracting :year1 (going from :year2 to :year3) [:bar] :percent in :elapsed (eta: :eta)",
    total = (end_year - start_year + 1), clear = FALSE, width = 80
  )
  pb$tick(0)
  for (year in start_year:end_year) {
    pb$tick(tokens = list(year1 = year, year2 = start_year, year3 = end_year))

    if (year < first_non_archived_year) {
      er_prs_f <- dplyr::tbl(conn, glue::glue("ER_PRS_F_{year}"))
      er_pha_f <- dplyr::tbl(conn, glue::glue("ER_PHA_F_{year}"))
    } else {
      er_prs_f <- dplyr::tbl(conn, "ER_PRS_F")
      er_pha_f <- dplyr::tbl(conn, "ER_PHA_F")
    }
    ir_pha_r <- dplyr::tbl(conn, "IR_PHA_R")

    starts_with_conditions <- vapply(
      atc_cod_starts_with,
      function(code) glue::glue("PHA_ATC_CLA LIKE '{code}%'"),
      character(1)
    )
    atc_conditions <- paste(starts_with_conditions, collapse = " OR ")
    atc_conditions <- glue::glue("({atc_conditions})")

    if (year == end_year) {
      dis_dtd_condition <- glue::glue(
        "FLX_DIS_DTD >= DATE '{year}-02-01'
        AND FLX_DIS_DTD <= DATE '{formatted_dis_dtd_end_date}'"
      )
    } else {
      dis_dtd_condition <- glue::glue(
        "FLX_DIS_DTD >= DATE '{year}-02-01'
      AND FLX_DIS_DTD <= DATE '{year + 1}-01-01'"
      )
    }
    soi_dtd_condition <- glue::glue(
      "EXE_SOI_DTD >= DATE '{formatted_start_date}'
      AND EXE_SOI_DTD <= DATE '{formatted_end_date}'"
    )

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

    query <- er_prs_f |>
      dplyr::inner_join(er_pha_f, by = dcir_join_keys) |>
      dplyr::inner_join(ir_pha_r, by = c("PHA_PRS_C13" = "PHA_CIP_C13")) |>
      dplyr::filter(
        dbplyr::sql(soi_dtd_condition),
        dbplyr::sql(dis_dtd_condition)
      )

    if (!is.null(atc_cod_starts_with)) {
      query <- query |>
        dplyr::filter(dbplyr::sql(atc_conditions))
    }

    cols_to_select <- c(
      "EXE_SOI_DTD",
      "PHA_ACT_QSN",
      "PHA_ATC_CLA",
      "PHA_PRS_C13",
      "PSP_SPE_COD"
    )

    query <- query |>
      dplyr::select(
        BEN_NIR_PSA,
        dplyr::all_of(cols_to_select)
      ) |>
      dplyr::distinct()

    if (!is.null(patients_ids)) {
      patients_ids_table <- dplyr::tbl(conn, patients_ids_table_name)
      patients_ids_table <- patients_ids_table |>
        dplyr::select(BEN_IDT_ANO, BEN_NIR_PSA) |>
        dplyr::distinct()
      query <- query |>
        dplyr::inner_join(patients_ids_table, by = "BEN_NIR_PSA") |>
        dplyr::select(
          BEN_IDT_ANO,
          dplyr::all_of(cols_to_select)
        ) |>
        dplyr::distinct()
    }

    if (DBI::dbExistsTable(conn, output_table_name)) {
      DBI::dbExecute(
        conn,
        glue::glue("INSERT INTO {output_table_name} {query}")
      )
    } else {
      DBI::dbExecute(
        conn,
        glue::glue("CREATE TABLE {output_table_name} AS {query}")
      )
    }
  }

  if (!is.null(patients_ids)) {
    DBI::dbRemoveTable(conn, patients_ids_table_name)
  }

  if (output_table_name_is_temp) {
    query <- dplyr::tbl(conn, output_table_name)
    result <- dplyr::collect(query)
    DBI::dbRemoveTable(conn, output_table_name)
  } else {
    result <- invisible(NULL)
    message(
      glue::glue("Results saved to table {output_table_name} in Oracle.")
    )
  }

  if (connection_opened) {
    DBI::dbDisconnect(conn)
  }

  return(result)
}
