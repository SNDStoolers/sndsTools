#' Extraction des Affections Longue Durée (ALD)
#' @description
#' Cette fonction permet d'extraire des ALD actives au
#' moins un jour sur une période donnée.
#' Les ALD dont l'intersection [IMB_ALD_DTD, IMB_ALD_DTF]
#' avec la période [start_date, end_date] n'est pas vide
#' sont extraites.
#' Si des codes ICD 10 ou des numéros d'ALD sont fournis,
#' seules les ALD associées à ces codes ICD 10 ou numéros
#' d'ALD sont extraites. Dans le cas contraire, toutes les
#' ALD sont extraites.
#' Si des identifiants de patients sont fournis, seules
#' les ALD associées à ces patients sont extraites. Dans
#' le cas contraire, les ALD de tous les patients sont extraites.
#'
#' @param start_date Date La date de début de la période
#'   sur laquelle extraire les ALD actives.
#' @param end_date Date La date de fin de la période
#'   sur laquelle extraire les ALD actives.
#' @param icd_cod_starts_with character vector Un vecteur de codes
#'   ICD 10. Si `icd_cod_starts_with` ou `ald_numbers` sont fournis,
#'   seules les ALD associées à ces codes ICD 10 ou numéros d'ALD
#'   sont extraites. Sinon, toutes les ALD actives sur la période
#'   [start_date, end_date] sont extraites.
#' @param ald_numbers numeric vector Un vecteur de numéros d'ALD.
#'   Si `icd_cod_starts_with` ou `ald_numbers` sont fournis,
#'   seules les ALD associées à ces codes ICD 10 ou numéros d'ALD
#'   sont extraites. Sinon, toutes les ALD actives sur la période
#'   [start_date, end_date] sont extraites.
#' @param excl_etm_nat character vector Un vecteur de codes
#'   IMB_ETM_NAT à exclure. Par défaut, les ALD de nature
#'   11, 12 et 13 sont exclues car elles correspondent à des
#'   exonérations pour accidents du travail ou maladies professionnelles.
#'   Voir la fiche suivante de la documentation :
#'   https://documentation-snds.health-data-hub.fr/snds/fiches/beneficiaires_ald.html
#'   et notamment le Programme #1 pour la référence de ce filtre.
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
#'   les ALDs actives sur la période. Si output_table_name est fourni,
#'   sauvegarde les résultats dans la table spécifiée dans Oracle et
#'   retourne NULL de manière invisible. Dans les deux cas les colonnes
#'   de la table de sortie sont :
#'   - BEN_NIR_PSA : Colonne présente uniquement si les identifiants
#'   patients (`patients_ids`) ne sont pas fournis. Identifiant SNDS,
#'   ausi appelé pseudo-NIR.
#'   - BEN_IDT_ANO : Colonne présente uniquement si les identifiants
#'   patients (`patients_ids`) sont fournis. Numéro d’inscription
#'   au répertoire (NIR) anonymisé.
#'   - IMB_ALD_NUM : Le numéro de l'ALD
#'   - IMB_ALD_DTD : La date de début de l'ALD
#'   - IMB_ALD_DTF : La date de fin de l'ALD
#'   - IMB_ETM_NAT : La nature de l'ALD
#'   - MED_MTF_COD : Le code ICD 10 de la pathologie associée à l'ALD
#'
#' @examples
#' \dontrun{
#' start_date <- as.Date("2010-01-01")
#' end_date <- as.Date("2010-01-03")
#' icd_cod_starts_with <- c("G20")
#'
#' long_term_disease <- extract_long_term_disease(
#'   start_date = start_date,
#'   end_date = end_date,
#'   icd_cod_starts_with = icd_cod_starts_with
#' )
#' }
#' @export
extract_long_term_disease <- function(
    start_date = NULL,
    end_date = NULL,
    icd_cod_starts_with = NULL,
    ald_numbers = NULL,
    excl_etm_nat = c("11", "12", "13"),
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
    output_table_name <- glue::glue("TMP_LTD_{timestamp}")
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

  formatted_start_date <- format(start_date, "%Y-%m-%d")
  formatted_end_date <- format(end_date, "%Y-%m-%d")

  if (!is.null(icd_cod_starts_with)) {
    print(glue::glue("Extracting LTD status for ICD 10 codes starting \
    with {paste(icd_cod_starts_with, collapse = ' or ')}..."))
  }
  if (!is.null(ald_numbers)) {
    print(glue::glue("Extracting LTD status for ALD numbers \
    {paste(ald_numbers, collapse = ',')}..."))
  }
  if (is.null(icd_cod_starts_with) && is.null(ald_numbers)) {
    print(glue::glue("Extracting LTD status for all ICD 10 codes..."))
  }

  codes_conditions <- list()
  if (!is.null(icd_cod_starts_with)) {
    starts_with_conditions <- sapply(
      icd_cod_starts_with,
      function(code) glue::glue("MED_MTF_COD LIKE '{code}%'")
    )
    codes_conditions <- c(
      codes_conditions,
      paste(starts_with_conditions, collapse = " OR ")
    )
  }
  if (!is.null(ald_numbers)) {
    codes_conditions <- c(
      codes_conditions,
      glue::glue("IMB_ALD_NUM IN ({paste(ald_numbers, collapse = ',')})")
    )
  }

  codes_conditions <- paste(codes_conditions, collapse = " OR ")

  imb_r <- dplyr::tbl(conn, "IR_IMB_R")

  date_condition <- glue::glue(
    "IMB_ALD_DTD <= DATE '{formatted_end_date}'
    AND IMB_ALD_DTF >= DATE '{formatted_start_date}'"
  )

  query <- imb_r |>
    dplyr::filter(
      dbplyr::sql(date_condition),
      !(IMB_ETM_NAT %in% excl_etm_nat)
    )

  if (!is.null(icd_cod_starts_with) || !is.null(ald_numbers)) {
    query <- query |>
      dplyr::filter(
        dbplyr::sql(codes_conditions)
      )
  }

  cols_to_select <- c(
    "IMB_ALD_NUM",
    "IMB_ALD_DTD",
    "IMB_ALD_DTF",
    "IMB_ETM_NAT",
    "MED_MTF_COD"
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

  query <- query |>
    dbplyr::sql_render()

  DBI::dbExecute(
    conn,
    glue::glue("CREATE TABLE {output_table_name} AS {query}")
  )

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
