# nolint start
#' Extraction des consultations dans le DCIR.
#'
#' @description Cette fonction permet
#' d'extraire les consultations dans le DCIR. Les
#' consultations dont les dates `EXE_SOI_DTD` sont comprises entre
#' `start_date` et `end_date` (incluses) sont extraites.
#'
#' @details Le décalage de remontée des données est pris en compte en récupérant
#' également les consultations dont les dates `FLX_DIS_DTD` sont comprises dans
#' les `dis_dtd_lag_months` mois suivant end_date.
#'
#' Si `patients_ids_filter` est fourni, seules les consultations pour les
#' patients dont les identifiants sont dans `patients_ids_filter` sont
#' extraites. Dans le cas contraire, les consultations de tous les patients sont
#' extraites.
#'
#' Pour être à flux constant sur l'ensemble des années, il faut utiliser
#' `dis_dtd_lag_months` = 27 Cela rallonge le temps d'extraction alors que
#' l'impact sur l'extraction est minime car [la Cnam estime que 99 % des soins
#' sont remontés à 6 mois](https://documentation-snds.health-data-hub.fr/snds/formation_snds/initiation/schema_relationnel_snds.html#_3-3-dcir),
#' c'est-à-dire pour dis_dtd_lag_months = 6.
#'
#' @param conn DBI connection. Une connexion à la base de données
#'   Oracle.
#' @param start_date Date. La date de début de la période
#'   des consultations à extraire.
#' @param end_date Date. La date de fin de la période
#'   des consultations à extraire.
#' @param pse_spe_filter Character vector (Optionnel). Les codes spécialités des
#'   médecins (référentiel `IR_SPE_V`) effectuant les consultations à extraire.
#'   Défaut à `NULL`.
#' @param prestation_filter Character vector (Optionnel). Les codes des
#'   prestations à extraire en norme B5 (colonne `PRS_NAT_REF`, référentiel
#'   `IR_NAT_V`). Défaut à `NULL`.
#' @param analyse_couts Logical (Optionnel). Si `TRUE`, les filtres de qualité
#'   liés aux coûts, écartant les actes en majorations sont ignorés. Utile pour
#'   des analyses portant sur les coûts. Défaut à `FALSE`.
#' @param patients_ids_filter data.frame (Optionnel). Un data.frame contenant
#'   les paires d'identifiants des patients pour lesquels les consultations
#'   doivent être extraites. Les colonnes de ce data.frame doivent être
#'   "BEN_IDT_ANO", "BEN_NIR_PSA" et "BEN_RNG_GEM". Les "BEN_NIR_PSA" doivent
#'   être tous les "BEN_NIR_PSA" associés aux "BEN_IDT_ANO" fournis. Défaut à
#'   `NULL`.
#' @param dis_dtd_lag_months Integer (Optionnel). Le nombre maximum de mois de
#'   décalage de FLX_DIS_DTD par rapport à EXE_SOI DTD pris en compte pour
#'   récupérer les consultations. Défaut à 6 mois.
#' @param sup_columns Character vector (Optionnel). Les colonnes supplémentaires
#'  à ajouter à la table de sortie. Défaut à NULL, donc aucune colonne ajoutée.
#' @return Retourne une lazy table contenant les
#'   consultations. Les colonnes de la table de sortie sont :
#'   - BEN_NIR_PSA : Colonne présente uniquement si les identifiants
#'   patients (`patients_ids_filter`) ne sont pas fournis. Identifiant SNDS,
#'   aussi appelé pseudo-NIR.
#'   - BEN_IDT_ANO : Colonne présente uniquement si les identifiants
#'   patients (`patients_ids_filter`) sont fournis. Numéro d'inscription
#'   au répertoire (NIR) anonymisé.
#'   - EXE_SOI_DTD : Date de la consultation.
#'
#' @examples
#' \dontrun{
#' start_date <- as.Date("2010-01-01")
#' end_date <- as.Date("2010-01-03")
#' conn <- connect_oracle()
#' consultations <- extract_consultations_erprsf(
#'  conn = conn,
#'   start_date = start_date,
#'   end_date = end_date,
#'   pse_spe_filter = c("0", "00", "36")
#' )
#' }
#' @export
#' @family extract
# nolint end
extract_consultations_erprsf <- function(
  conn,
  start_date,
  end_date,
  pse_spe_filter = NULL,
  prestation_filter = NULL,
  patients_ids_filter = NULL,
  analyse_couts = FALSE,
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

  # Extract as a utils.
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

  if (!is.null(pse_spe_filter)) {
    print(
      glue::glue(
        "Extracting consultations with speciality codes {paste(pse_spe_filter, collapse = ' or ')}" # nolint
      )
    )
  } else {
    print(glue::glue("Extracting consultations from all specialties codes..."))
  }

  dis_dtd_condition <- glue::glue(
    "FLX_DIS_DTD >= DATE '{formatted_start_date}' AND FLX_DIS_DTD <= DATE '{formatted_dis_dtd_end_date}'" # nolint
  )
  soi_dtd_condition <- glue::glue(
    "EXE_SOI_DTD >= DATE '{formatted_start_date}' AND EXE_SOI_DTD <= DATE '{formatted_end_date}'" # nolint
  )

  # concatenate all archived years
  if (start_year <= first_non_archived_year) {
    er_prs_f <- purrr::map(
      start_year:min(end_year, first_non_archived_year - 1),
      function(year) {
        dplyr::tbl(conn, glue::glue("ER_PRS_F_{year}"))
      }
    ) |>
      purrr::reduce(dplyr::union_all) |>
      dplyr::union_all(
        dplyr::tbl(conn, "ER_PRS_F")
      )
  } else {
    er_prs_f <- dplyr::tbl(conn, "ER_PRS_F")
  }

  # TODO: Ces filtres qualité devraient être externalisés dans une fonction
  # spécifique, documentée avec les références aux documentations de la CNAM
  # concernant les choix.
  er_prs_f_clean <- er_prs_f |>
    dplyr::filter(
      dbplyr::sql(soi_dtd_condition),
      dbplyr::sql(dis_dtd_condition)
    ) |>
    dplyr::filter(
      (DPN_QLF != 71 | is.na(DPN_QLF)),
      # Suppression de l'activité des actes et consultations externes (ACE)
      # remontée pour information, cette activité est mesurée par ailleurs
      # pour les établissements de santé dans le champ de la SAE
      (PRS_DPN_QLP != 71 | is.na(PRS_DPN_QLP)),
    )
  if (!analyse_couts) {
    er_prs_f_clean <- er_prs_f_clean |>
      dplyr::filter(
        # Suppression des ACE pour information
        (CPL_MAJ_TOP < 2),
        # Suppression des majorations
        (CPL_AFF_COD != 16),
        PRS_ACT_QTE > 0
      )
  }

  cols_to_select <- c(
    "EXE_SOI_DTD",
    "PSE_SPE_COD",
    "PFS_EXE_NUM",
    "PRS_NAT_REF",
    "PRS_ACT_QTE",
    "BEN_RNG_GEM",
    sup_columns
  )
  # apply query filters
  query <- er_prs_f_clean |>
    dplyr::select(BEN_NIR_PSA, dplyr::all_of(cols_to_select))
  if (!is.null(prestation_filter)) {
    query <- query |>
      dplyr::filter(
        PRS_NAT_REF %in% prestation_filter
      )
  }
  if (!is.null(pse_spe_filter)) {
    query <- query |>
      dplyr::filter(
        PSE_SPE_COD %in% pse_spe_filter
      )
  }
  query <- query |>
    dplyr::distinct()

  # TODO : lien patients_ids_filter pourrait être extrait en utils
  if (!is.null(patients_ids_filter)) {
    patients_ids_table <- dplyr::tbl(conn, patients_ids_table_name)
    patients_ids_table <- patients_ids_table |>
      dplyr::select(BEN_IDT_ANO, BEN_NIR_PSA, BEN_RNG_GEM) |>
      dplyr::distinct()

    query <- query |>
      dplyr::inner_join(
        patients_ids_table,
        by = c("BEN_NIR_PSA", "BEN_RNG_GEM")
      ) |>
      dplyr::select(BEN_IDT_ANO, dplyr::all_of(cols_to_select)) |>
      dplyr::distinct()
  }

  result <- query

  result
}
