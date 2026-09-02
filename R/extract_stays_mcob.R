#' Construit les conditions pour extraire les diagnostics principaux et reliés.
#'
#' @description
#' Cette fonction permet de construire les conditions pour extraire les
#' diagnostics principaux et reliés.
#'
#' @param cim10_codes character vector Les codes CIM10 cibles des
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
#' \dontrun{
#' build_dp_dr_conditions(c("A00", "B00"), include_dr = TRUE)
#' build_dp_dr_conditions(c("A00", "B00"), include_dr = FALSE)
#' }
#' @keywords internal
build_dp_dr_conditions <- function(cim10_codes = NULL, include_dr = FALSE) {
  starts_with_conditions <- glue::glue("DGN_PAL LIKE '{cim10_codes}%'")
  if (include_dr) {
    starts_with_conditions_dr <- glue::glue("DGN_REL LIKE '{cim10_codes}%'")
    starts_with_conditions <- c(
      starts_with_conditions,
      starts_with_conditions_dr
    )
  }
  collapsed_conditions <- paste(starts_with_conditions, collapse = " OR ")
  collapsed_conditions
}

#' Construit les conditions pour extraire les diagnostics associés.
#' @description
#' Cette fonction permet de construire les conditions pour extraire les
#' diagnostics associés.
#' @param cim10_codes character vector Les codes CIM10 cibles des
#' diagnostics à extraire.
#' @return character Les conditions pour extraire les diagnostics associés.
#'
#' @examples
#' \dontrun{
#' build_da_conditions(c("A00", "B00"))
#' }
#' @keywords internal
build_da_conditions <- function(cim10_codes = NULL) {
  starts_with_conditions_da <- glue::glue("ASS_DGN LIKE '{cim10_codes}%'")
  collapsed_conditions <- paste(starts_with_conditions_da, collapse = " OR ")
  collapsed_conditions
}

# nolint start
#' Extraction des diagnostics des séjours hospitaliers (MCO).
#'
#' @description Cette fonction permet d'extraire les diagnostics des séjours
#' hospitaliers en MCO. Les diagnostics dont les dates `EXE_SOI_DTD` sont
#' comprises entre `start_date` et `end_date` sont extraits.
#'
#' @details La sélection des séjours se fait à l'aide de filtres sur les
#' diagnostics:
#'
#' - Si `dp_cim10_codes_filter` est renseigné, seuls les séjours dont les
#' diagnostics principaux contiennent les codes CIM10 correspondants sont
#' extraits.
#'
#' - Si `or_dr_with_same_codes_filter` est renseigné, les séjours avec les codes
#' DR correspondants sont également extraits.
#'
#' - Si `or_da_with_same_codes_filter` est renseigné, les séjours avec les codes
#' DA correspondants sont également extraits.
#'
#' - Si `and_da_with_other_codes_filter` est renseigné, les séjours avec les
#' codes DA différents sont également extraits.
#'
#' Tous les diagnostics principaux, reliés et associés sont extraits pour les
#' séjours sélectionnés.
#'
#' La fonction joint les tables T_MCO*B, T_MCO*C ensemble, puis joint
#' successivement à cette table "séjour" les tables T_MCO*D et T_MCO*UM.
#' Finalement, les deux tables obtenues sont concaténées horizontalement. Il est
#' donc fréquent d'avoir des doublons concernant les colonnes des tables B et C
#' dans les lignes de la table résultante. Une explication détaillée et un
#' diagramme illustrant le fonctionnement retenu sont disponibles sur [le github du projet Scalpel](https://github.com/X-DataInitiative/SCALPEL-Flattening/blob/DREES-104-DocFlattening/README_joins.md#the-pmsi-flattening).
#'
#' @param conn DBI connection. Une connexion à la base de données Oracle.
#' @param start_date Date La date de début de la période sur laquelle extraire
#' les séjours.
#' @param end_date Date La date de fin de la période sur laquelle
#' extraire les séjours.
#' @param dp_cim10_codes_filter character vector
#' (Optionnel). Les codes CIM10 des diagnostics principaux à extraire. La
#' requête est effectuée par préfixe : Par exemple, si E12 est renseigné, tous
#' les codes commençant par E12 sont extraits. Défaut à `NULL`.
#' @param or_dr_with_same_codes logical (Optionnel).Indique si les séjours avec
#' les mêmes codes DR doivent être extraits. La requête est effectuée par
#' préfixe : Par exemple, si E12 est renseigné, tous les codes commençant par
#' E12 sont extraits. Défaut à `NULL`.
#' @param or_da_with_same_codes logical (Optionnel). Indique si les séjours avec
#' les mêmes codes DA doivent être extraits. La requête est effectuée par
#' préfixe : Par exemple, si E12 est renseigné, tous les codes commençant par
#' E12 sont extraits. Défaut à `NULL`.
#' @param and_da_with_other_codes_filter logical (Optionnel). Indique si les
#' séjours avec des codes DA différents doivent être extraits. La requête est
#' effectuée par préfixe : Par exemple, si E12 est renseigné, tous les codes
#' commençant par E12 sont extraits. Défaut à `NULL`.
#' @param da_cim10_codes_filter character vector (Optionnel). Les codes CIM10
#' des diagnostics associés à extraire. La requête est effectuée par préfixe :
#' Par exemple, si E12 est renseigné, tous les codes commençant par E12 sont
#' extraits. Défaut à `NULL`.
#' @param patients_ids_filter data.frame (Optionnel). Un data.frame contenant
#' les paires d'identifiants des patients pour lesquels les consultations
#' doivent être extraites. Les colonnes de ce data.frame doivent être
#' `BEN_IDT_ANO` et `BEN_NIR_PSA` (en majuscules). Les "BEN_NIR_PSA" doivent
#' être tous les "BEN_NIR_PSA" associés aux "BEN_IDT_ANO" fournis. Si
#' `patients_ids` n'est pas fourni, les consultations de tous les patients sont
#' extraites. Défaut à `NULL`.
#' @param sup_columns character vector (Optionnel). Colonnes supplémentaires à
#'   inclure dans le résultat. Défaut à `NULL`.
#'
#' @return Retourne une lazy table contenant les séjours hospitaliers. Attention: Les
#'   lignes des tables MCO B et C peuvent être dupliquées. Les colonnes sont les
#' suivantes :
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
#' - `DGN_PAL_UM` : Diagnostic principal des unité médicale
#' - `DGN_REL_UM` : Diagnostic relié des unité médicale
#' - `ASS_DGN` : Diagnostic associé
#'
#' @examples \dontrun{
 #' conn <- connect_oracle()
 #' # Extrait uniquement les séjours en 2019 dont le diagnostic principal commence par A ou B
 #' extract_stays_mcob(
 #'  conn = conn,
 #'  start_date = as.Date("2019-01-01"),
 #'  end_date = as.Date("2019-12-31"),
 #'  dp_cim10_codes_filter = c("A", "B")
 #' )
 #' # Extrait tous les séjours en 2019
 #' extract_stays_mcob(
 #'  conn = conn,
 #'  start_date = as.Date("2019-01-01"),
 #'  end_date = as.Date("2019-12-31")
 #' )
 #' }
#' @export
#' @family extract
# nolint end
extract_stays_mcob <- function(
  conn,
  start_date,
  end_date,
  dp_cim10_codes_filter = NULL,
  or_dr_with_same_codes_filter = FALSE,
  or_da_with_same_codes_filter = FALSE,
  and_da_with_other_codes_filter = FALSE,
  da_cim10_codes_filter = NULL,
  patients_ids_filter = NULL,
  sup_columns = NULL
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

  if (!is.null(patients_ids_filter)) {
    stopifnot(
      identical(names(patients_ids_filter), c("BEN_IDT_ANO", "BEN_NIR_PSA")),
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

  start_year <- lubridate::year(start_date)
  end_year <- lubridate::year(end_date)
  formatted_start_date <- format(start_date, "%Y-%m-%d")
  formatted_end_date <- format(end_date, "%Y-%m-%d")

  hospital_stays_by_year <- purrr::map(start_year:end_year, function(year) {
    formatted_year <- sprintf("%02d", year %% 100)

    t_mco_b <- tbl_oracle(conn, glue::glue("T_MCO{formatted_year}B"))
    t_mco_c <- tbl_oracle(conn, glue::glue("T_MCO{formatted_year}C"))
    t_mco_d <- tbl_oracle(conn, glue::glue("T_MCO{formatted_year}D"))
    t_mco_um <- tbl_oracle(conn, glue::glue("T_MCO{formatted_year}UM"))

    if (is.null(dp_cim10_codes_filter)) {
      eta_num_rsa_num <-
        t_mco_b |>
        dplyr::select(ETA_NUM, RSA_NUM) |>
        dplyr::distinct()
    } else {
      dp_dr_conditions <- build_dp_dr_conditions(
        cim10_codes = dp_cim10_codes_filter,
        include_dr = or_dr_with_same_codes_filter
      )
      eta_num_rsa_num <-
        t_mco_b |>
        dplyr::filter(dbplyr::sql(dp_dr_conditions)) |>
        dplyr::select(ETA_NUM, RSA_NUM) |>
        dplyr::distinct()
    }
    # Ajoute les identifiants séjours de la table D en plus de la table B
    if (or_da_with_same_codes_filter) {
      da_conditions <- build_da_conditions(cim10_codes = dp_cim10_codes_filter)
      dp_dr_conditions <- build_dp_dr_conditions(
        cim10_codes = dp_cim10_codes_filter,
        include_dr = TRUE
      )
      eta_num_rsa_num_da_d <-
        t_mco_d |>
        dplyr::filter(dbplyr::sql(da_conditions)) |>
        dplyr::select(ETA_NUM, RSA_NUM) |>
        dplyr::distinct()

      eta_num_rsa_num_da_um <-
        t_mco_um |>
        dplyr::filter(dbplyr::sql(dp_dr_conditions)) |>
        dplyr::select(ETA_NUM, RSA_NUM) |>
        dplyr::distinct()

      eta_num_rsa_num_da <- dplyr::union(
        eta_num_rsa_num_da_d,
        eta_num_rsa_num_da_um
      )

      eta_num_rsa_num <- dplyr::union(eta_num_rsa_num, eta_num_rsa_num_da)
    } else if (and_da_with_other_codes_filter) {
      da_conditions <- build_da_conditions(cim10_codes = da_cim10_codes_filter)
      dp_dr_conditions <- build_dp_dr_conditions(
        cim10_codes = da_cim10_codes_filter,
        include_dr = TRUE
      )
      eta_num_rsa_num_da_d <-
        t_mco_d |>
        dplyr::filter(dbplyr::sql(da_conditions)) |>
        dplyr::select(ETA_NUM, RSA_NUM) |>
        dplyr::distinct()

      eta_num_rsa_num_da_um <-
        t_mco_um |>
        dplyr::filter(dbplyr::sql(dp_dr_conditions)) |>
        dplyr::select(ETA_NUM, RSA_NUM) |>
        dplyr::distinct()

      eta_num_rsa_num_da <- dplyr::union(
        eta_num_rsa_num_da_d,
        eta_num_rsa_num_da_um
      )
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

    selected_cols <- c(selected_cols_b, selected_cols_c)
    if (year >= 2013) {
      selected_cols <- c(
        selected_cols,
        "DAT_RET",
        "COH_NAI_RET",
        "COH_SEX_RET"
      )
    }

    t_mco_b_c <-
      t_mco_b |>
      dplyr::inner_join(t_mco_c, by = c("ETA_NUM", "RSA_NUM")) |>
      dplyr::inner_join(eta_num_rsa_num, by = c("ETA_NUM", "RSA_NUM")) |>
      dplyr::select(dplyr::all_of(selected_cols))

    exe_soi_dtd_condition <- glue::glue(
      "EXE_SOI_DTD >= DATE '{formatted_start_date}'
      AND EXE_SOI_DTD <= DATE '{formatted_end_date}'"
    )
    t_mco_b_c_dtd_filtered <-
      t_mco_b_c |>
      dplyr::filter(dbplyr::sql(exe_soi_dtd_condition)) |>
      dplyr::distinct()

    # Quality filters
    t_mco_b_c_quality_filtered <-
      t_mco_b_c_dtd_filtered |>
      dplyr::filter(
        NIR_RET == 0,
        NAI_RET == 0,
        SEX_RET == 0,
        SEJ_RET == 0,
        FHO_RET == 0,
        PMS_RET == 0
      ) |>
      dplyr::select(
        -NIR_RET,
        -NAI_RET,
        -SEX_RET,
        -SEJ_RET,
        -FHO_RET,
        -PMS_RET
      ) |>
      dplyr::filter(!(GRG_GHM %like% "%90%"), !(ETA_NUM %in% FINESS_DOUBLONS))

    if (year >= 2013) {
      t_mco_b_c_quality_filtered <-
        t_mco_b_c_quality_filtered |>
        dplyr::filter(DAT_RET == 0, COH_NAI_RET == 0, COH_SEX_RET == 0) |>
        dplyr::select(-DAT_RET, -COH_NAI_RET, -COH_SEX_RET)
    }

    # Optional patient filter
    if (!is.null(patients_ids_filter)) {
      patients_ids_table <- dplyr::tbl(conn, patients_ids_table_name)
      t_mco_b_c_quality_filtered <-
        t_mco_b_c_quality_filtered |>
        dplyr::inner_join(
          patients_ids_table,
          by = c("NIR_ANO_17" = "BEN_NIR_PSA")
        ) |>
        dplyr::select(-NIR_ANO_17)
    }

    selected_eta_num_rsa_num <-
      t_mco_b_c_quality_filtered |>
      dplyr::select(ETA_NUM, RSA_NUM) |>
      dplyr::distinct()

    # Medical unit diagnoses
    selected_cols_um <- c("ETA_NUM", "RSA_NUM", "DGN_PAL", "DGN_REL")
    t_mco_um_selected_stays <-
      t_mco_um |>
      dplyr::inner_join(
        selected_eta_num_rsa_num,
        by = c("ETA_NUM", "RSA_NUM")
      ) |>
      dplyr::select(dplyr::all_of(selected_cols_um)) |>
      dplyr::rename(
        DGN_PAL_UM = DGN_PAL,
        DGN_REL_UM = DGN_REL
      ) |>
      dplyr::distinct()

    mco_b_c_um <-
      t_mco_b_c_quality_filtered |>
      dplyr::left_join(
        t_mco_um_selected_stays,
        by = c("ETA_NUM", "RSA_NUM")
      )

    # Associated diagnoses
    selected_cols <- c("ETA_NUM", "RSA_NUM", "ASS_DGN")
    t_mco_d_selected_stays <-
      t_mco_d |>
      dplyr::inner_join(
        selected_eta_num_rsa_num,
        by = c("ETA_NUM", "RSA_NUM")
      ) |>
      dplyr::select(dplyr::all_of(selected_cols)) |>
      dplyr::distinct()

    mco_b_c_d <- t_mco_b_c_quality_filtered |>
      dplyr::left_join(
        t_mco_d_selected_stays,
        by = c("ETA_NUM", "RSA_NUM")
      )

    # Bind all diagnoses: DP, DR, associated, DP and DR from UM
    all_diagnoses <-
      dplyr::union_all(
        mco_b_c_um,
        mco_b_c_d
      ) |>
      dplyr::distinct()

    # remove possible useless duplicates with all NaN on D and UM diagnoses
    all_diagnoses_wo_duplicates <- all_diagnoses |>
      dplyr::filter(
        !dplyr::if_all(c(DGN_PAL_UM, DGN_REL_UM, ASS_DGN), is.na)
      )
    all_diagnoses_wo_duplicates
  })

  result <- purrr::reduce(hospital_stays_by_year, dplyr::union_all)

  result
}
