# Liste des finess géographiques APHP, APHM et HCL à supprimer pour éviter les
# doublons
FINESS_DOUBLONS <- c(
  "130780521",
  "130783236",
  "130783293",
  "130784234",
  "130804297",
  "600100101",
  "750041543",
  "750100018",
  "750100042",
  "750100075",
  "750100083",
  "750100091",
  "750100109",
  "750100125",
  "750100166",
  "750100208",
  "750100216",
  "750100232",
  "750100273",
  "750100299",
  "750801441",
  "750803447",
  "750803454",
  "910100015",
  "910100023",
  "920100013",
  "920100021",
  "920100039",
  "920100047",
  "920100054",
  "920100062",
  "930100011",
  "930100037",
  "930100045",
  "940100027",
  "940100035",
  "940100043",
  "940100050",
  "940100068",
  "950100016",
  "690783154",
  "690784137",
  "690784152",
  "690784178",
  "690787478",
  "830100558"
)

#' Construit les conditions pour extraire les diagnostics principaux et reliés.
#'
#' @description
#' Cette fonction permet de construire les conditions pour extraire les
#' diagnostics principaux et reliés.
#'
#' @param cim10_codes_starts_with character vector Les codes CIM10 cibles des
#' diagnostics à extraire.
#' @param include_dr logical Indique si les diagnostics reliés doivent être
#' ajoutés dans les conditions. Si TRUE, la recherche dans les diagnostics
#' principaux des codes CIM10 cibles est ajoutée dans les conditions. Si FALSE,
#' les codes CIM10 cibles sont recherchés seulement pour les diagnostics
#' principaux.
#' @return character Les conditions pour extraire les diagnostics principaux et
#' reliés.
#'
#' @examples
#' build_dp_dr_conditions(c("A00", "B00"), include_dr = TRUE)
#' build_dp_dr_conditions(c("A00", "B00"), include_dr = FALSE)
#' @export
build_dp_dr_conditions <- function(cim10_codes_starts_with = NULL,
                                   include_dr = FALSE) {
  starts_with_conditions_dp <- sapply(cim10_codes_starts_with, function(code)
    glue::glue("DGN_PAL LIKE '{code}%'"))
  if (include_dr) {
    starts_with_conditions_dr <- sapply(cim10_codes_starts_with, function(code)
      glue::glue("DGN_REL LIKE '{code}%'"))
  } else {
    starts_with_conditions_dr <- NULL
  }
  starts_with_conditions <- c(starts_with_conditions_dp, starts_with_conditions_dr)
  combined_conditions <- paste(starts_with_conditions, collapse = " OR ")
  combined_conditions <- glue::glue("({combined_conditions})")
  return(combined_conditions)
}

#' Construit les conditions pour extraire les diagnostics associés.
#' @description
#' Cette fonction permet de construire les conditions pour extraire les
#' diagnostics associés.
#' @param cim10_codes_starts_with character vector Les codes CIM10 cibles des
#' diagnostics à extraire.
#' @return character Les conditions pour extraire les diagnostics associés.
#'
#' @examples
#' build_da_conditions(c("A00", "B00"))
#' @export
build_da_conditions <- function(cim10_codes_starts_with = NULL) {
  starts_with_conditions_da <- sapply(cim10_codes_starts_with, function(code)
    glue::glue("ASS_DGN LIKE '{code}%'"))
  combined_conditions <- paste(starts_with_conditions_da, collapse = " OR ")
  combined_conditions <- glue::glue("({combined_conditions})")
  return(combined_conditions)
}

#' Normalise le nombre de colonnes pour les tables diagnostics d'unité médicale
#' @description
#' Cette fonction limite le nombre de colonne à un nombre fixé par
#' l'utilisateur. Cela permet de se limiter aux `max_columns_number` diagnostics
#' seulement pour les diagnostics des unités médicales étant en nombre variable.
#' @param df data.frame Le data.frame à normaliser.
#' @param column_prefix character Le préfixe pour les colonnes à normaliser.
#' @param max_columns_number numeric Le nombre maximum de colonnes à conserver.
#'
#' @return data.frame Le data.frame normalisé.
#'
#' @examples
#' df <- data.frame(
#'   DGN_PAL_UM_1 = "A", DGN_PAL_UM_2 = "B", DGN_PAL_UM_3 = "C"
#' )
#' normalize_column_number(df, "DGN_PAL_UM_", 2)
#'@export
normalize_column_number <- function(df, column_prefix, max_columns_number) {
  expected_cols <- paste(column_prefix, 1:max_columns_number, sep = "")

  missing_cols <- setdiff(expected_cols, names(df))
  df[missing_cols] <- NA

  excess_cols <- names(df)[stringr::str_detect(names(df), glue::glue("^{column_prefix}\\d+$")) &
                             !names(df) %in% expected_cols]
  df <- df[, !(names(df) %in% excess_cols)]
  return(df)
}

#' Extraction des séjours hospitaliers (MCO).
#'
#' @description
#' Cette fonction permet d'extraire les séjours hospitaliers en MCO. Les séjours
#' dont les dates `EXE_SOI_DTD` sont comprises entre `start_date` et `end_date`
#' sont extraits.
#'
#' @details
#' Si `dp_cim10_codes_starts_with_filter` est renseigné, seules les séjours avec
#' les codes CIM10 correspondants sont extraits.
#'
#' Si `or_dr_with_same_codes_filter` est renseigné, les séjours avec les codes
#' DR correspondants sont également extraits.
#'
#' Si `or_da_with_same_codes_filter` est renseigné, les séjours avec les codes
#' DA correspondants sont également extraits.
#'
#' Si `and_da_with_other_codes_filter` est renseigné, les séjours avec les codes
#' DA différents sont également extraits.
#'
#' @param start_date Date La date de début de la période sur laquelle extraire
#' les séjours.
#' @param end_date Date La date de fin de la période sur laquelle extraire les
#' séjours.
#' @param dp_cim10_codes_starts_with_filter character vector (Optionnel). Les
#' codes CIM10 des diagnostics principaux à extraire. Défaut à `NULL`.
#' @param or_dr_with_same_codes logical (Optionnel).Indique si les séjours avec
#' les mêmes codes DR doivent être extraits. Défaut à `NULL`.
#' @param or_da_with_same_codes logical (Optionnel). Indique si les séjours avec
#' les mêmes codes DA doivent être extraits. Défaut à `NULL`.
#' @param and_da_with_other_codes_filter logical (Optionnel). Indique si les
#' séjours avec des codes DA différents doivent être extraits. Défaut à `NULL`.
#' @param da_cim10_codes_starts_with_filter character vector (Optionnel). Les
#' codes CIM10 des diagnostics associés à extraire. Défaut à `NULL`.
#' @param patients_ids_filter data.frame (Optionnel). Un data.frame contenant
#' les paires d'identifiants des patients pour lesquels les consultations
#' doivent être extraites. Les colonnes de ce data.frame doivent être
#' `BEN_IDT_ANO` et `BEN_NIR_PSA` (en majuscules). Les "BEN_NIR_PSA" doivent
#' être tous les "BEN_NIR_PSA" associés aux "BEN_IDT_ANO" fournis. Si
#' `patients_ids` n'est pas fourni, les consultations de tous les patients sont
#' extraites. Défaut à `NULL`.
#' @param output_table_name character Le nom de la table de sortie dans la base
#' de données. Si `output_table_name` n'est pas fourni, une table de sortie
#' intermédiaire est créée. Défaut à `NULL`.
#' @param conn dbConnection La connexion à la base de données. Si `conn` n'est
#' pas fourni, une connexion à la base de données est initialisée. Défaut à
#' `NULL`.
#'
#' @return Un data.frame contenant les séjours hospitaliers. Les colonnes sont
#' les suivantes :
#' - `BEN_IDT_ANO` : Identifiant bénéficiaire anonymisé (seulement si
#'   patient_ids non nul)
#' - `NIR_ANO_17` : NIR anonymisé
#' - `EXE_SOI_DTD` : Date de début du séjour hospitalier
#' - `EXE_SOI_DTF` : Date de fin du séjour hospitalier
#' - `ETA_NUM` : Numéro FINESS e-PMSI
#' - `RSA_NUM` : N° d'index du RSA
#' - `SEJ_NUM` : N° de séjour
#' - `SEJ_NBJ` : Nombre de jours de séjour
#' - `NBR_DGN` : Nombre de diagnostics associés significatifs
#' - `NBR_RUM` : Nombre de RUM (unité médicales)
#' - `NBR_ACT` : Nombre d'actes
#' - `ENT_MOD` : Mode d'entrée
#' - `ENT_PRV` : Provenance
#' - `SOR_MOD` : Mode de sortie
#' - `SOR_DES` : Destination
#' - `DGN_PAL` : Diagnostic principal
#' - `DGN_REL` : Diagnostic relié
#' - `GRG_GHM` : Groupe homogène de malades
#' - `BDI_DEP` : Département de résidence
#' - `BDI_COD` : Code postal de résidence
#' - `COD_SEX` : Sexe
#' - `AGE_ANN` : Age en années
#' - `AGE_JOU` : Age en jours
#' - `DGN_PAL_UM_XX` : Diagnostic principal des unité médicale de 1 à 10
#' - `DGN_REL_UM_XX` : Diagnostic relié des unité médicale de 1 à 10
#' - `ASS_DGN_XX` : Diagnostic associé de 1 à 20
#'
#' @examples
#' \dontrun{
#' extract_hospital_stays(
#'   start_date = as.Date("2019-01-01"),
#'   end_date = as.Date("2019-12-31"),
#'   dp_cim10_codes_starts_with = c("A00", "B00")
#' )
#' }
#' @export
extract_hospital_stays <- function(start_date,
                                   end_date,
                                   dp_cim10_codes_starts_with_filter = NULL,
                                   or_dr_with_same_codes_filter = FALSE,
                                   or_da_with_same_codes_filter = FALSE,
                                   and_da_with_other_codes_filter = FALSE,
                                   da_cim10_codes_starts_with_filter = NULL,
                                   patients_ids_filter = NULL,
                                   output_table_name = NULL,
                                   conn = NULL) {
  stopifnot(
    !is.null(start_date),!is.null(end_date),
    inherits(start_date, "Date"),
    inherits(end_date, "Date"),
    start_date <= end_date
  )

  connection_opened <- FALSE
  if (is.null((conn))) {
    conn <- connect_oracle()
    connection_opened <- TRUE
  }

  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  if (!is.null(output_table_name)) {
    stopifnot(
      is.character(output_table_name),!DBI::dbExistsTable(conn, output_table_name)
    )
  }

  if (!is.null(patients_ids_filter)) {
    stopifnot(identical(
      names(patients_ids_filter),
      c("BEN_IDT_ANO", "BEN_NIR_PSA")
    ),!anyDuplicated(patients_ids_filter))
    patients_ids_table_name <- glue::glue("TMP_PATIENTS_IDS_{timestamp}")
    DBI::dbWriteTable(conn, patients_ids_table_name, patients_ids_filter)
  }

  start_year <- lubridate::year(start_date)
  end_year <- lubridate::year(end_date)
  formatted_start_date <- format(start_date, "%Y-%m-%d")
  formatted_end_date <- format(end_date, "%Y-%m-%d")

  hospital_stays_list <- list()

  pb <- progress::progress_bar$new(
    format = "Extracting :year1 (going from :year2 to :year3) \
    [:bar] :percent in :elapsed (eta: :eta)",
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

    formatted_year <- sprintf("%02d", year %% 100)

    t_mco_b <- dplyr::tbl(conn, glue::glue("T_MCO{formatted_year}B"))
    t_mco_c <- dplyr::tbl(conn, glue::glue("T_MCO{formatted_year}C"))
    t_mco_d <- dplyr::tbl(conn, glue::glue("T_MCO{formatted_year}D"))
    t_mco_um <- dplyr::tbl(conn, glue::glue("T_MCO{formatted_year}UM"))

    dp_dr_conditions <- build_dp_dr_conditions(cim10_codes_starts_with = dp_cim10_codes_starts_with_filter,
                                               include_dr = or_dr_with_same_codes_filter)

    eta_num_rsa_num <- t_mco_b |>
      dplyr::filter(dbplyr::sql(dp_dr_conditions)) |>
      dplyr::select(ETA_NUM, RSA_NUM) |>
      dplyr::distinct()

    if (or_da_with_same_codes_filter) {
      da_conditions <- build_da_conditions(cim10_codes_starts_with = dp_cim10_codes_starts_with_filter)
      dp_dr_conditions <- build_dp_dr_conditions(cim10_codes_starts_with = dp_cim10_codes_starts_with_filter,
                                                 include_dr = TRUE)
      eta_num_rsa_num_da_d <- t_mco_d |>
        dplyr::filter(dbplyr::sql(da_conditions)) |>
        dplyr::select(ETA_NUM, RSA_NUM) |>
        dplyr::distinct()
      eta_num_rsa_num_da_um <- t_mco_um |>
        dplyr::filter(dbplyr::sql(dp_dr_conditions)) |>
        dplyr::select(ETA_NUM, RSA_NUM) |>
        dplyr::distinct()
      eta_num_rsa_num_da <- dplyr::union(eta_num_rsa_num_da_d, eta_num_rsa_num_da_um)
      eta_num_rsa_num <- dplyr::union(eta_num_rsa_num, eta_num_rsa_num_da)
    } else if (and_da_with_other_codes_filter) {
      da_conditions <- build_da_conditions(cim10_codes_starts_with = da_cim10_codes_starts_with_filter)
      dp_dr_conditions <- build_dp_dr_conditions(cim10_codes_starts_with = da_cim10_codes_starts_with_filter,
                                                 include_dr = TRUE)
      eta_num_rsa_num_da_d <- t_mco_d |>
        dplyr::filter(dbplyr::sql(da_conditions)) |>
        dplyr::select(ETA_NUM, RSA_NUM) |>
        dplyr::distinct()
      eta_num_rsa_num_da_um <- t_mco_um |>
        dplyr::filter(dbplyr::sql(dp_dr_conditions)) |>
        dplyr::select(ETA_NUM, RSA_NUM) |>
        dplyr::distinct()
      eta_num_rsa_num_da <- dplyr::union(eta_num_rsa_num_da_d, eta_num_rsa_num_da_um)
      eta_num_rsa_num <- eta_num_rsa_num |>
        dplyr::inner_join(eta_num_rsa_num_da, by = c("ETA_NUM", "RSA_NUM"))
    }

    selected_cols_b <- c(
      "ETA_NUM",
      "RSA_NUM",
      "SEJ_NUM",
      "SEJ_NBJ",
      "NBR_DGN",
      "NBR_RUM",
      "NBR_ACT",
      "ENT_MOD",
      "ENT_PRV",
      "SOR_MOD",
      "SOR_DES",
      "DGN_PAL",
      "DGN_REL",
      "GRG_GHM",
      "BDI_DEP",
      "BDI_COD",
      "COD_SEX",
      "AGE_ANN",
      "AGE_JOU"
    )

    selected_cols_c <- c(
      "NIR_ANO_17",
      "EXE_SOI_DTD",
      "EXE_SOI_DTF",
      "FHO_RET",
      "NAI_RET",
      "NIR_RET",
      "PMS_RET",
      "SEJ_RET",
      "SEX_RET"
    )
    # SOR_ANN and SOR_MOI have been removed from the selected columns
    # because they are not always present in the tables

    if (year >= 2013) {
      selected_cols <- c(selected_cols_b,
                         selected_cols_c,
                         "DAT_RET",
                         "COH_NAI_RET",
                         "COH_SEX_RET")
    } else {
      selected_cols <- c(selected_cols_b, selected_cols_c)
    }

    t_mco_b_c <- t_mco_b |>
      dplyr::inner_join(t_mco_c, by = c("ETA_NUM", "RSA_NUM")) |>
      dplyr::inner_join(eta_num_rsa_num, by = c("ETA_NUM", "RSA_NUM")) |>
      dplyr::select(dplyr::all_of(selected_cols))

    exe_soi_dtd_condition <- glue::glue(
      "EXE_SOI_DTD >= DATE '{formatted_start_date}'
      AND EXE_SOI_DTD <= DATE '{formatted_end_date}'"
    )
    t_mco_b_c_dtd_filtered <- t_mco_b_c |>
      dplyr::filter(dbplyr::sql(exe_soi_dtd_condition)) |>
      dplyr::distinct()

    if (!is.null(patients_ids_filter)) {
      patients_ids_table <- dplyr::tbl(conn, patients_ids_table_name)
      t_mco_b_c_dtd_filtered <- t_mco_b_c_dtd_filtered |>
        dplyr::inner_join(patients_ids_table, by = c("NIR_ANO_17" = "BEN_NIR_PSA")) |>
        dplyr::select(-NIR_ANO_17)
    }

    selected_eta_num_rsa_num <- t_mco_b_c_dtd_filtered |>
      dplyr::select(ETA_NUM, RSA_NUM) |>
      dplyr::distinct()

    t_mco_b_c_dtd_filtered <- t_mco_b_c_dtd_filtered |>
      dplyr::collect()

    # Medical unit diagnoses
    selected_cols_um <- c("ETA_NUM", "RSA_NUM", "DGN_PAL", "DGN_REL")
    tmp_um <- t_mco_um |>
      dplyr::inner_join(selected_eta_num_rsa_num, by = c("ETA_NUM", "RSA_NUM")) |>
      dplyr::select(dplyr::all_of(selected_cols_um)) |>
      dplyr::distinct() |>
      dplyr::collect()

    tmp_um_dp <- tmp_um |>
      dplyr::select(ETA_NUM, RSA_NUM, DGN_PAL) |>
      dplyr::distinct() |>
      dplyr::group_by(ETA_NUM, RSA_NUM) |>
      dplyr::mutate(row_id = dplyr::row_number()) |>
      tidyr::pivot_wider(
        names_from = row_id,
        values_from = DGN_PAL,
        names_prefix = "DGN_PAL_UM_"
      ) |>
      dplyr::ungroup()

    max_columns_dgn_pal_um <- 10
    tmp_um_dp <- normalize_column_number(
      df = tmp_um_dp,
      column_prefix = "DGN_PAL_UM_",
      max_columns_number = max_columns_dgn_pal_um
    )

    tmp_um_dr <- tmp_um |>
      dplyr::select(ETA_NUM, RSA_NUM, DGN_REL) |>
      dplyr::distinct() |>
      dplyr::group_by(ETA_NUM, RSA_NUM) |>
      dplyr::mutate(row_id = dplyr::row_number()) |>
      tidyr::pivot_wider(
        names_from = row_id,
        values_from = DGN_REL,
        names_prefix = "DGN_REL_UM_"
      ) |>
      dplyr::ungroup()

    max_columns_dgn_rel_um <- 10
    tmp_um_dr <- normalize_column_number(
      df = tmp_um_dr,
      column_prefix = "DGN_REL_UM_",
      max_columns_number = max_columns_dgn_rel_um
    )

    # Create one line for both DP and DR from UM table
    tmp_um_dp_dr <- tmp_um_dp |>
      dplyr::left_join(tmp_um_dr, by = c("ETA_NUM", "RSA_NUM"))

    # Associated diagnoses
    selected_cols <- c("ETA_NUM", "RSA_NUM", "ASS_DGN")
    tmp_d <- t_mco_d |>
      dplyr::inner_join(selected_eta_num_rsa_num, by = c("ETA_NUM", "RSA_NUM")) |>
      dplyr::select(dplyr::all_of(selected_cols)) |>
      dplyr::distinct() |>
      dplyr::collect()

    # Bind all non DP diagnoses: associated, DP and DR from UM
    tmp2_d <- dplyr::bind_rows(
      tmp_d,
      tmp_um |>
        dplyr::select(ETA_NUM, RSA_NUM, DGN_PAL) |>
        dplyr::rename(ASS_DGN = DGN_PAL) |>
        dplyr::distinct(),
      tmp_um |>
        dplyr::select(ETA_NUM, RSA_NUM, DGN_REL) |>
        dplyr::rename(ASS_DGN = DGN_REL) |>
        dplyr::distinct()
    ) |>
      dplyr::distinct()

    selected_cols <- c("ETA_NUM", "RSA_NUM", "DGN_PAL")
    tmp3_d <- t_mco_b_c_dtd_filtered |>
      dplyr::select(dplyr::all_of(selected_cols)) |>
      dplyr::distinct() |>
      dplyr::left_join(tmp2_d, by = c("ETA_NUM", "RSA_NUM")) |>
      dplyr::filter(!(ASS_DGN == DGN_PAL |
                        tolower(ASS_DGN) == "xxxx")) |>
      dplyr::select(-DGN_PAL) |>
      dplyr::group_by(ETA_NUM, RSA_NUM) |>
      dplyr::mutate(row_id = dplyr::row_number()) |>
      tidyr::pivot_wider(
        names_from = row_id,
        values_from = ASS_DGN,
        names_prefix = "ASS_DGN_"
      ) |>
      dplyr::ungroup()

    max_columns_da <- 20
    tmp3_d <- normalize_column_number(
      df = tmp3_d,
      column_prefix = "ASS_DGN_",
      max_columns_number = max_columns_da
    )

    # join all diagnoses:
    # Stay DP, DP and DR from medical units (UM) and DA.
    all_diagnoses <- t_mco_b_c_dtd_filtered |>
      dplyr::left_join(tmp_um_dp_dr, by = c("ETA_NUM", "RSA_NUM")) |>
      dplyr::left_join(tmp3_d, by = c("ETA_NUM", "RSA_NUM"))

    # quality filters
    all_diagnoses_filtered <- all_diagnoses |>
      dplyr::filter(NIR_RET == 0,
                    NAI_RET == 0,
                    SEX_RET == 0,
                    SEJ_RET == 0,
                    FHO_RET == 0,
                    PMS_RET == 0) |>
      dplyr::select(-NIR_RET, -NAI_RET, -SEX_RET, -SEJ_RET, -FHO_RET, -PMS_RET)

    if (year >= 2013) {
      all_diagnoses_filtered <- all_diagnoses_filtered |>
        dplyr::filter(DAT_RET == 0, COH_NAI_RET == 0, COH_SEX_RET == 0) |>
        dplyr::select(-DAT_RET, -COH_NAI_RET, -COH_SEX_RET)
    }

    hospital_stays <- all_diagnoses_filtered |>
      dplyr::filter(GRG_GHM != 90, !(ETA_NUM %in% FINESS_DOUBLONS))

    hospital_stays_list <- append(hospital_stays_list, list(hospital_stays))
  }

  result <- dplyr::bind_rows(hospital_stays_list)
  if (!is.null(output_table_name)) {
    DBI::dbWriteTable(conn, output_table_name, result, overwrite = TRUE)
    result <- invisible(NULL)
    message(glue::glue("Results saved to table {output_table_name} in Oracle."))
  }
  if (connection_opened) {
    DBI::dbDisconnect(conn)
  }
  return(result)
}
