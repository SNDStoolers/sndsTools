# nolint start
#' Extraction des consultations externes à l'hôpital (MCO).
#'
#' @description
#' Cette fonction permet d'extraire les consultations à l'hôpital en MCO. Les
#' consultations dont les dates `EXE_SOI_DTD` sont comprises entre start_date et
#' end_date sont extraites.
#'
#' @details
#' Si spe_codes_filter est renseigné, seules les consultations des spécialités
#' correspondantes sont extraites.
#'
#' Si prestation_codes_filter est renseigné, seules les consultations des
#' prestations correspondantes sont extraites.
#'
#' Si ccam_codes_filter est renseigné, seules les consultations des actes
#' médicaux correspondants sont extraites. Notez que si `ccam_codes_filter` est
#' fourni, `spe_codes_filter` et `prestation_codes_filter` peuvent être nuls, et
#' vice versa.
#'
#' Si patients_ids_filter est fourni, seules les délivrances de médicaments pour
#' les patients dont les identifiants sont dans patients_ids_filter sont
#' extraites.
#'
#' @param conn DBI connection. Une connexion à la base de données Oracle.
#' @param start_date Date La date de début de la période sur laquelle extraire
#' les consultations.
#' @param end_date Date La date de fin de la période sur laquelle extraire les
#' consultations.
#' @param spe_codes_filter character vector Optionnel. Les codes spécialités des
#' médecins effectuant les consultations à extraire. Si `spe_codes_filter` n'est pas
#' fourni, les consultations de tous les spécialités sont extraites.
#' @param prestation_codes_filter character vector Optionnel. Les codes des
#' prestations à extraire. Si `prestation_codes_filter` n'est pas fourni, les
#' consultations de tous les prestations sont extraites. Les codes des
#' prestations sont disponibles sur la page [actes et consultations externes de
#' la documentation
#' SNDS](https://documentation-snds.health-data-hub.fr/snds/fiches/actes_consult_externes.html#exemple-de-requetes-pour-analyse).
#' @param ccam_codes_filter character vector Optionnel. Les codes CCAM des actes
#' médicaux des consultations à extraire. Si `ccam_codes_filter` n'est pas fourni, les
#' consultations de tous les actes sont extraites. Les codes des actes médicaux
#' d'après la CCAM est disponible sur [le site de cette dernière](https://www.ameli.fr/accueil-de-la-ccam/index.php).
#' @param patients_ids_filter data.frame Optionnel. Un data.frame contenant les
#' paires d'identifiants des patients pour lesquels les consultations doivent
#' être extraites. Les colonnes de ce data.frame doivent être `BEN_IDT_ANO` et
#' `BEN_NIR_PSA` (en majuscules). Les `BEN_NIR_PSA` doivent être tous les
#' `BEN_NIR_PSA` associés aux `BEN_IDT_ANO` fournis. Si `patients_ids_filter`
#' n'est pas fourni, les consultations de tous les patients sont extraites.
#'
#' @return Retourne une lazy table contenant les consultations. Les colonnes sont les suivantes :
#' - `BEN_IDT_ANO` : Identifiant bénéficiaire anonymisé (seulement si
#' patients_ids_filter non nul)
#' - `NIR_ANO_17` : NIR anonymisé
#' - `EXE_SOI_DTD` : Date de la délivrance
#' - `ACT_COD` : Code prestation de l'acte
#' - `EXE_SPE` : Code de spécialité du professionnel de soin prescripteur
#' - `CCAM_COD` : Code de l'acte médical classifié avec la CCAM.
#'
#' @examples
#' \dontrun{
#' conn <- connect_oracle()
#' # Extraction des consultations à l'hôpital en 2019 pour les spécialités 01 et 02
#' extract_consultations_mcofcstc(
#'   conn = conn,
#'   start_date = as.Date("2019-01-01"),
#'   end_date = as.Date("2019-12-31"),
#'   spe_codes_filter = c("01", "02")
#' )
#' # Extraction de consultations à l'hôpital à partir de code CCAM
#' extract_consultations_mcofcstc(
#'   conn = conn,
#'   start_date = as.Date("2019-01-01"),
#'   end_date = as.Date("2019-12-31"),
#'   ccam_codes_filter = c("ACQK001", "ACQH003")
#' )
#' # Extraction de consultations à l'hôpital à partir de code CCAM et de spécialités
#' extract_consultations_mcofcstc(
#'   conn = conn,
#'   start_date = as.Date("2019-01-01"),
#'   end_date = as.Date("2019-12-31"),
#'   ccam_codes_filter = c("ACQK001", "ACQH003"),
#'   spe_codes_filter = c("01", "02")
#' )
#' }
#' @export
#' @family extract
# nolint end
extract_consultations_mcofcstc <- function(
  conn,
  start_date,
  end_date,
  spe_codes_filter = NULL,
  prestation_codes_filter = NULL,
  ccam_codes_filter = NULL,
  patients_ids_filter = NULL
) {
  stopifnot(
    inherits(conn, "DBIConnection"),
    !is.null(start_date),
    !is.null(end_date),
    inherits(start_date, "Date"),
    inherits(end_date, "Date"),
    start_date <= end_date
  )

  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  start_year <- lubridate::year(start_date)
  end_year <- lubridate::year(end_date)
  formatted_start_date <- format(start_date, "%Y-%m-%d")
  formatted_end_date <- format(end_date, "%Y-%m-%d")

  # no ben_rng_gem in PMSI
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
      temporary = TRUE,
      overwrite = TRUE
    )
  }

  consultations_by_year <- purrr::map(start_year:end_year, function(year) {
    formatted_year <- sprintf("%02d", year %% 100)

    date_condition <- glue::glue(
      "EXE_SOI_DTD <= DATE '{formatted_end_date}' AND EXE_SOI_DTD >= DATE '{formatted_start_date}'" # nolint
    )
    cstc <- dplyr::tbl(conn, glue::glue("T_MCO{formatted_year}CSTC")) |>
      dplyr::filter(
        NIR_RET == "0",
        NAI_RET == "0",
        SEX_RET == "0",
        ENT_DAT_RET == "0",
        IAS_RET == "0"
      ) |>
      dplyr::filter(dbplyr::sql(date_condition)) |>
      dplyr::select(ETA_NUM, SEQ_NUM, NIR_ANO_17, EXE_SOI_DTD) |>
      dplyr::distinct()

    # Filtre sur codes CCAM
    fmstc <- dplyr::tbl(conn, glue::glue("T_MCO{formatted_year}FMSTC")) |>
      dplyr::select(ETA_NUM, SEQ_NUM, CCAM_COD) |>
      dplyr::distinct()
    if (!is.null(ccam_codes_filter)) {
      fmstc <- fmstc |>
        dplyr::filter(CCAM_COD %in% ccam_codes_filter)
      ace <- cstc |>
        dplyr::inner_join(fmstc, by = c("ETA_NUM", "SEQ_NUM")) |>
        dplyr::distinct()
    } else {
      # joining with fmstc without filtering on ccam codes
      ace <- cstc |>
        dplyr::left_join(fmstc, by = c("ETA_NUM", "SEQ_NUM")) |>
        dplyr::distinct()
    }
    # Filtre sur codes prestatioon et spécialités
    fcstc <- dplyr::tbl(conn, glue::glue("T_MCO{formatted_year}FCSTC")) |>
      dplyr::select(ETA_NUM, SEQ_NUM, ACT_COD, EXE_SPE)
    if (!is.null(prestation_codes_filter)) {
      fcstc <- fcstc |>
        dplyr::filter(ACT_COD %in% prestation_codes_filter)
    }
    if (!is.null(spe_codes_filter)) {
      fcstc <- fcstc |>
        dplyr::filter(EXE_SPE %in% spe_codes_filter)
    }
    if (!is.null(prestation_codes_filter) || !is.null(spe_codes_filter)) {
      # joining all tables
      ace <- ace |>
        dplyr::inner_join(fcstc, by = c("ETA_NUM", "SEQ_NUM")) |>
        dplyr::distinct()
    } else {
      # joining with fcstc without filtering on prestation and spe codes
      ace <- ace |>
        dplyr::left_join(fcstc, by = c("ETA_NUM", "SEQ_NUM")) |>
        dplyr::distinct()
    }

    if (!is.null(patients_ids_filter)) {
      patients_ids_table <- dplyr::tbl(conn, patients_ids_table_name)
      consultations_of_year <- patients_ids_table |>
        dplyr::inner_join(
          ace,
          by = c("BEN_NIR_PSA" = "NIR_ANO_17"),
          keep = TRUE
        )
      selected_columns <-
        c(
          "BEN_IDT_ANO",
          "NIR_ANO_17",
          "EXE_SOI_DTD",
          "CCAM_COD",
          "ACT_COD",
          "EXE_SPE"
        )
    } else {
      consultations_of_year <- ace
      selected_columns <-
        c("NIR_ANO_17", "EXE_SOI_DTD", "CCAM_COD", "ACT_COD", "EXE_SPE")
    }
    consultations_of_year |>
      dplyr::select(dplyr::all_of(selected_columns)) |>
      dplyr::distinct()
  })
  result <- purrr::reduce(consultations_by_year, dplyr::union_all)

  result
}
