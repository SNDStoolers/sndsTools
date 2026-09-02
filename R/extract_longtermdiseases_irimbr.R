# nolint start
#' Extraction des Affections Longue Durée (ALD)
#' @description
#' Cette fonction permet d'extraire des ALD actives au
#' moins un jour sur une période donnée.
#' Les ALD dont l'intersection (`MB_ALD_DTD`, `IMB_ALD_DTF`)
#' avec la période (`start_date`, `end_date`) n'est pas vide
#' sont extraites.
#' Si des codes ICD 10 ou des numéros d'ALD sont fournis,
#' seules les ALD associées à ces codes ICD 10 ou numéros
#' d'ALD sont extraites. Dans le cas contraire, toutes les
#' ALD sont extraites.
#' Si des identifiants de patients sont fournis, seules
#' les ALD associées à ces patients sont extraites. Dans
#' le cas contraire, les ALD de tous les patients sont extraites.
#'
#' @param conn DBI connection. Une connexion à la base de données Oracle.
#' @param start_date Date La date de début de la période
#'   sur laquelle extraire les ALD actives.
#' @param end_date Date La date de fin de la période
#'   sur laquelle extraire les ALD actives.
#' @param icd_cod_starts_with character vector Un vecteur de codes
#'   ICD 10. Si `icd_cod_starts_with` ou `ald_numbers` sont fournis,
#'   seules les ALD associées à ces codes ICD 10 ou numéros d'ALD
#'   sont extraites. Sinon, toutes les ALD actives sur la période
#'   (`start_date`, `end_date`) sont extraites.
#' @param ald_numbers numeric vector Un vecteur de numéros d'ALD.
#'   Si `icd_cod_starts_with` ou `ald_numbers` sont fournis,
#'   seules les ALD associées à ces codes ICD 10 ou numéros d'ALD
#'   sont extraites. Sinon, toutes les ALD actives sur la période
#'   (`start_date`, `end_date`) sont extraites.
#' @param excl_etm_nat character vector Un vecteur de codes
#'   IMB_ETM_NAT à exclure. Par défaut, les ALD de nature
#'   11, 12 et 13 sont exclues car elles correspondent à des
#'   exonérations pour accidents du travail ou maladies professionnelles.
#'   Voir [la fiche sur les ALD de la documentation du SNDS](
#' https://documentation-snds.health-data-hub.fr/snds/fiches/beneficiaires_ald.html).
#'   et notamment le Programme #1 pour la référence de ce filtre.
#' @param patients_ids_filter data.frame Optionnel. Un data.frame contenant les
#'   paires d'identifiants des patients pour lesquels les ALD doivent être
#'   extraites. Les colonnes de ce data.frame doivent être "BEN_IDT_ANO",
#'   "BEN_NIR_PSA" et "BEN_RNG_GEM". Les "BEN_NIR_PSA" doivent être tous les
#'   "BEN_NIR_PSA" associés aux "BEN_IDT_ANO" fournis.
#' @param sup_columns character vector (Optionnel). Colonnes supplémentaires à
#'   inclure dans le résultat. Défaut à `NULL`.
#' @return Retourne une lazy table contenant les
#'   les ALDs actives sur la période. Si output_table_name est fourni,
#'   sauvegarde les résultats dans la table spécifiée dans Oracle et
#'   retourne NULL de manière invisible. Dans les deux cas les colonnes
#'   de la table de sortie sont :
#'   - BEN_NIR_PSA : Colonne présente uniquement si les identifiants
#'   patients (`patients_ids_filter`) ne sont pas fournis. Identifiant SNDS,
#'   ausi appelé pseudo-NIR.
#'   - BEN_IDT_ANO : Colonne présente uniquement si les identifiants
#'   patients (`patients_ids_filter`) sont fournis. Numéro d'inscription
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
#' conn <- connect_oracle()
#'
#' long_term_disease <- extract_longtermdiseases_irimbr(
#'   conn = conn,
#'   start_date = start_date,
#'   end_date = end_date,
#'   icd_cod_starts_with = icd_cod_starts_with
#' )
#' }
#' @export
#' @family extract
extract_longtermdiseases_irimbr <- function(
  conn,
  start_date,
  end_date,
  icd_cod_starts_with = NULL,
  ald_numbers = NULL,
  excl_etm_nat = c("11", "12", "13"),
  patients_ids_filter = NULL,
  sup_columns = NULL
) {
  # nolint end. Force # nolint: cyclocomp_linter for the function.
  stopifnot(
    inherits(conn, "DBIConnection"),
    !is.null(start_date),
    !is.null(end_date),
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

  formatted_start_date <- format(start_date, "%Y-%m-%d")
  formatted_end_date <- format(end_date, "%Y-%m-%d")

  if (!is.null(icd_cod_starts_with)) {
    print(glue::glue(
      "Extracting LTD status for ICD 10 codes starting \
    with {paste(icd_cod_starts_with, collapse = ' or ')}..."
    ))
  }
  if (!is.null(ald_numbers)) {
    print(glue::glue(
      "Extracting LTD status for ALD numbers \
    {paste(ald_numbers, collapse = ',')}..."
    ))
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
    "BEN_NIR_PSA",
    "BEN_RNG_GEM",
    "IMB_ALD_NUM",
    "IMB_ALD_DTD",
    "IMB_ALD_DTF",
    "IMB_ETM_NAT",
    "MED_MTF_COD"
  )
  if (!is.null(sup_columns)) {
    cols_to_select <- c(cols_to_select, sup_columns)
  }

  result <- query |>
    dplyr::select(
      dplyr::all_of(cols_to_select)
    ) |>
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
      dplyr::select(
        BEN_IDT_ANO,
        dplyr::all_of(cols_to_select)
      ) |>
      dplyr::distinct()
  }

  result
}
