
#' Construit les conditions pour extraire les diagnostics SSR.
#' (affection étiologique, manifestation morbide principale et, avant 2023,
#' finalité principale de prise en charge).
#' 
#' @description
#' Cette fonction génère une chaîne de conditions SQL (clauses `LIKE`) portant
#' sur les colonnes `ETL_AFF` (affection étiologique) et `MOR_PRP`
#' (manifestation morbide principale) de la table `T_SSR*B`. Pour les années
#' antérieures à 2023, la colonne `FP_PEC` (finalité principale de prise en
#' charge) est également incluse.
#'
#' @param cim10_codes character vector Les codes CIM10 cibles des
#' diagnostics à extraire.
#' @param index_year integer L'année d'indexation des séjours ssr.
#' @return character Les conditions pour extraire les diagnostics 
#'
#' @examples
#' \dontrun{
#' build_ssr_dp_conditions(c("A00", "B00"), index_year = 2023)
#' }
#' @keywords internal
build_ssr_dp_conditions <- function(cim10_codes = NULL,
index_year = NULL) {

    
    # Affection étiologique
    starts_with_conditions_e <- glue::glue("ETL_AFF LIKE '{cim10_codes}%'") 

    # Manifestation morbide principale
    starts_with_conditions_mp <- glue::glue("MOR_PRP LIKE '{cim10_codes}%'")

    starts_with_conditions <- c(
    starts_with_conditions_e,
    starts_with_conditions_mp
    )

    if (index_year < 2023) {
        # Finalité principale de prise en charge
        starts_with_conditions_fp <- glue::glue("FP_PEC LIKE '{cim10_codes}%'")

        starts_with_conditions <- c(
            starts_with_conditions_e,
            starts_with_conditions_mp,
            starts_with_conditions_fp
        )
    }

  collapsed_conditions <- paste(starts_with_conditions, collapse = " OR ")
  collapsed_conditions
}


#' Construit les conditions pour extraire les diagnostics principaux.
#' @description
#' Cette fonction permet de construire les conditions pour extraire les
#' diagnostics associés.
#' @param cim10_codes character vector Les codes CIM10 cibles des
#' diagnostics à extraire.
#' @return character Les conditions pour extraire les diagnostics principaux.
#'
#' @examples
#' \dontrun{
#' build_ssr_da_conditions(c("A00", "B00"))
#' }
#' @keywords internal

build_ssr_da_conditions <- function(cim10_codes = NULL) {
  starts_with_conditions_da <- glue::glue("DGN_COD LIKE '{cim10_codes}%'")
  collapsed_conditions <- paste(starts_with_conditions_da, collapse = " OR ")
  collapsed_conditions
}

# nolint start
#' Extraction des diagnostics des séjours de soins de réadaptation (SSR)
#'
#' @description Cette fonction permet d'extraire les diagnostics des séjours
#' de soins de réadaptation. Les diagnostics dont les dates `EXE_SOI_DTD` sont
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
#' - Si `and_da_with_other_codes` est renseigné, les séjours avec les codes
#' DA correspondants sont également extraits.
#'
#' - Si `and_da_with_other_codes_filter` est renseigné, les séjours avec les
#' codes DA différents sont également extraits.
#'
#' Tous les diagnostics principaux, reliés et associés sont extraits pour les
#' séjours sélectionnés.
#'
#' La fonction joint les tables T_SSR*B, T_SSR*C ensemble, puis joint
#' successivement à cette table "séjour" les tables T_SSR*D.
#' Finalement, les deux tables obtenues sont concaténées horizontalement. Il est
#' donc fréquent d'avoir des doublons concernant les colonnes des tables B et D
#' dans les lignes de la table résultante. 
#' 
#' @param start_date Date La date de début de la période sur laquelle extraire
#' les séjours.
#' @param end_date Date La date de fin de la période sur laquelle
#' extraire les séjours.
#' @param dp_cim10_codes_filter character vector
#' (Optionnel). Les codes CIM10 des diagnostics principaux à extraire. La
#' requête est effectuée par préfixe : Par exemple, si E12 est renseigné, tous
#' les codes commençant par E12 sont extraits. Défaut à `NULL`.
#' @param or_da_with_same_codes logical (Optionnel). Indique si les séjours avec
#' les mêmes codes ETL_AFF, MOR_PRP et FP_PEC doivent être extraits. La requête est effectuée par
#' préfixe : Par exemple, si E12 est renseigné, tous les codes commençant par
#' E12 sont extraits. Défaut à `NULL`.
#' @param and_da_with_other_codes_filter logical (Optionnel). Indique si les
#' séjours avec des codes ETL_AFF, MOR_PRP et FP_PEC différents doivent être extraits. La requête est
#' effectuée par préfixe : Par exemple, si E12 est renseigné, tous les codes
#' commençant par E12 sont extraits. Défaut à `NULL`.
#' @param da_cim10_codes_filter character vector (Optionnel). Les codes CIM10
#' des diagnostics ETL_AFF, MOR_PRP et FP_PEC à extraire. La requête est effectuée par préfixe :
#' Par exemple, si E12 est renseigné, tous les codes commençant par E12 sont
#' extraits. Défaut à `NULL`.
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
#' @return Un data.frame contenant les séjours de soins de réadaptation. Les colonnes sont les
#' suivantes :
#- `BEN_IDT_ANO` : Identifiant bénéficiaire anonymisé (présent
#'   uniquement si `patients_ids_filter` est renseigné ; remplace
#'   `NIR_ANO_17`).
#' - `NIR_ANO_17` : NIR anonymisé à 17 caractères (absent si
#'   `patients_ids_filter` est renseigné).
#' - `ETA_NUM` : Numéro FINESS e-PMSI de l'établissement SSR.
#' - `RHA_NUM` : Numéro séquentiel du RHA (résumé hebdomadaire
#'   anonyme SSR).
#' - `SEJ_NUM` : Numéro de séjour SSR.
#' - `NBR_DGN` : Nombre de diagnostics associés significatifs SSR.
#' - `ENT_MOD` : Mode d'entrée dans le séjour SSR.
#' - `ENT_PRV` : Provenance du patient à l'entrée du séjour SSR.
#' - `SOR_MOD` : Mode de sortie du séjour SSR.
#' - `SOR_DES` : Destination de sortie du séjour SSR.
#' - `MOR_PRP` : Manifestation morbide principale SSR.
#' - `ETL_AFF` : Affection étiologique SSR.
#' - `DGN_COD` : Diagnostic associé significatif SSR (table
#'   `T_SSR*D`).
#' - `BDI_DEP` : Département de résidence du bénéficiaire.
#' - `BDI_COD` : Code géographique de résidence du bénéficiaire.
#' - `COD_SEX` : Sexe du bénéficiaire.
#' - `AGE_ANN` : Âge en années du bénéficiaire.
#' - `MOI_ANN` : Mois et année de sortie SSR (format MMAAAA).
#' - `EXE_SOI_DTD` : Date de début de la semaine SSR.
#' - `EXE_SOI_DTF` : Date de fin de la semaine SSR.
#' - `GRG_GME` : Groupe médico-économique SSR (présent à partir
#'   de 2013).
#' - `FP_PEC` : Finalité principale de prise en charge SSR
#'   (présent avant 2023 uniquement).
#' 
#' @examples \dontrun{
#' # Extrait uniquement les séjours en 2019 dont le diagnostic principal commence par A ou B
#' extract_stays_mcob(
#'  start_date = as.Date("2019-01-01"),
#'  end_date = as.Date("2019-12-31"),
#'  dp_cim10_codes = c("A", "B")
#' )
#' # Extrait tous les séjours en 2019
#' extract_stays_mcob(
#'  start_date = as.Date("2019-01-01"),
#'  end_date = as.Date("2019-12-31")
#' )
#' }
#' @export
#' @family extract
# nolint end
extract_stays_ssr <- function(
  start_date,
  end_date,
  dp_cim10_codes_filter = NULL,
  or_da_with_same_codes_filter = FALSE,
  and_da_with_other_codes_filter = FALSE,
  da_cim10_codes_filter = NULL,
  patients_ids_filter = NULL,
  output_table_name = NULL,
  conn = NULL
) {
  stopifnot(
    !is.null(start_date),
    !is.null(end_date),
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
    check_output_table_name(output_table_name, conn)
  }

  if (!is.null(patients_ids_filter)) {
    stopifnot(
      identical(names(patients_ids_filter), c("BEN_IDT_ANO", "BEN_NIR_PSA")),
      !anyDuplicated(patients_ids_filter)
    )
    patients_ids_table_name <- glue::glue("TMP_PATIENTS_IDS_{timestamp}")
    DBI::dbWriteTable(conn, patients_ids_table_name, patients_ids_filter)
  }

  start_year <- lubridate::year(start_date)
  end_year <- lubridate::year(end_date)
  formatted_start_date <- format(start_date, "%Y-%m-%d")
  formatted_end_date <- format(end_date, "%Y-%m-%d")

  ssr_stays_list <- list()

  pb <- progress::progress_bar$new(
    format = "Extracting :year1 (going from :year2 to :year3) \
    [:bar] :percent in :elapsed (eta: :eta)",
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

    formatted_year <- sprintf("%02d", year %% 100)

    t_ssr_b <- dplyr::tbl(conn, glue::glue("T_SSR{formatted_year}B"))
    t_ssr_c <- dplyr::tbl(conn, glue::glue("T_SSR{formatted_year}C"))
    t_ssr_d <- dplyr::tbl(conn, glue::glue("T_SSR{formatted_year}D"))

    if (is.null(dp_cim10_codes_filter)) {
      eta_num_rsa_num <-
        t_ssr_d |>
        dplyr::select(ETA_NUM, RHA_NUM, RHS_NUM) |>
        dplyr::distinct()
    } else {
        
        dp_conditions <- build_ssr_dp_conditions(cim10_codes = dp_cim10_codes_filter, index_year = year)

        eta_num_rsa_num <-
        t_ssr_b |>
        dplyr::filter(dbplyr::sql(dp_conditions)) |>
        dplyr::select(ETA_NUM, RHA_NUM, RHS_NUM) |>
        dplyr::distinct()
    }

    if (or_da_with_same_codes_filter) {

        da_conditions <- build_ssr_da_conditions(cim10_codes = dp_cim10_codes_filter)

        eta_num_rsa_num_da <-
        t_ssr_d |>
        dplyr::filter(dbplyr::sql(da_conditions)) |>
        dplyr::select(ETA_NUM, RHA_NUM, RHS_NUM) |>
        dplyr::distinct()

        eta_num_rsa_num <- dplyr::union(eta_num_rsa_num, eta_num_rsa_num_da)

    } else if (and_da_with_other_codes_filter) {

        da_specific_conditions <- build_ssr_da_conditions(cim10_codes = da_cim10_codes_filter)

        eta_num_rsa_num_da <-
        t_ssr_d |>
        dplyr::filter(dbplyr::sql(da_specific_conditions)) |>
        dplyr::select(ETA_NUM, RHA_NUM, RHS_NUM) |>
        dplyr::distinct()

        eta_num_rsa_num <- eta_num_rsa_num |>
            dplyr::inner_join(eta_num_rsa_num_da, by = c("ETA_NUM", "RHA_NUM", "RHS_NUM"))
    }

    selected_cols_b <- c(
      "ETA_NUM",
      "RHA_NUM",
      "RHS_NUM",
      "SEJ_NUM",
      "NBR_DGN",
      "ENT_MOD",
      "ENT_PRV",
      "SOR_MOD",
      "SOR_DES",
      "MOR_PRP",
        "ETL_AFF",
      "DGN_COD",
      "BDI_DEP",
      "BDI_COD",
      "COD_SEX",
      "AGE_ANN",
      "MOI_ANN"        
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

    selected_cols <- c(selected_cols_b, selected_cols_c)
    if (year >= 2013) {
      selected_cols <- c(
        selected_cols,
        "DAT_RET",
        "COH_NAI_RET",
        "COH_SEX_RET",
        "GRG_GME" 
      )
    }

    if (year < 2023) {
        selected_cols <- c(selected_cols, "FP_PEC")
    }

    if (year >= 2015) {
      selected_cols <- c(selected_cols, "TYP_GEN_RHA")
    }

    t_ssr_b_d <-
      t_ssr_b |>
      dplyr::left_join(t_ssr_c, by = c("ETA_NUM", "RHA_NUM", "RHS_NUM")) |>
        dplyr::left_join(t_ssr_d, by = c("ETA_NUM", "RHA_NUM", "RHS_NUM")) |>
      dplyr::inner_join(eta_num_rsa_num, by = c("ETA_NUM", "RHA_NUM", "RHS_NUM")) |>
      dplyr::select(dplyr::all_of(selected_cols))


    exe_soi_dtd_condition <- glue::glue(
      "EXE_SOI_DTD >= DATE '{formatted_start_date}'
      AND EXE_SOI_DTD <= DATE '{formatted_end_date}'"
    )

     # Quality filters
    t_ssr_b_d_quality_filtered <-
      t_ssr_b_d |>
      dplyr::filter(dbplyr::sql(exe_soi_dtd_condition)) |>
      dplyr::distinct()

    if (year >= 2013) {
      t_ssr_b_d_quality_filtered <-
        t_ssr_b_d_quality_filtered |>
        dplyr::filter(DAT_RET == 0, COH_NAI_RET == 0, COH_SEX_RET == 0) |>
        dplyr::filter(dbplyr::sql("GRG_GME NOT LIKE '90%'")) |>
        dplyr::select(-DAT_RET, -COH_NAI_RET, -COH_SEX_RET)
    }

    if (year >= 2015) {
      t_ssr_b_d_quality_filtered <-
        t_ssr_b_d_quality_filtered |>
        dplyr::filter(TYP_GEN_RHA %in% c("0", "4"))
    }

    moi_ann_year_condition <- glue::glue(
      "SUBSTR(MOI_ANN, LENGTH(MOI_ANN) - 3, 4) = '{year}'"
    )

    t_ssr_b_d_quality_filtered <-
      t_ssr_b_d_quality_filtered |>
      dplyr::filter(dbplyr::sql(moi_ann_year_condition))

    t_ssr_b_d_quality_filtered <-
      t_ssr_b_d_quality_filtered |>
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
      dplyr::filter( !(ETA_NUM %in% finess_doublons))


    if (year >= 2015) {
      t_ssr_b_d_quality_filtered <-
        t_ssr_b_d_quality_filtered |>
        dplyr::select(-TYP_GEN_RHA)
    }


    # Optional patient filter
    if (!is.null(patients_ids_filter)) {
      patients_ids_table <- dplyr::tbl(conn, patients_ids_table_name)
      t_ssr_b_d_quality_filtered <-
        t_ssr_b_d_quality_filtered |>
        dplyr::inner_join(
          patients_ids_table,
          by = c("NIR_ANO_17" = "BEN_NIR_PSA")
        ) |>
        dplyr::select(-NIR_ANO_17)
    }


    ssr_stays_list <- append(
      ssr_stays_list,
      list(t_ssr_b_d_quality_filtered |> distinct())
    )
  }

  result <- purrr::reduce(ssr_stays_list, dplyr::union_all)


  if (!is.null(output_table_name)) {
    query <- result |> dbplyr::sql_render()

    DBI::dbExecute(conn,glue::glue("CREATE TABLE {output_table_name} AS {query}"))
    result <- invisible(NULL)
    message(glue::glue("Results saved to table {output_table_name} in Oracle."))
  }
  if (connection_opened) {
    DBI::dbDisconnect(conn)
  }
  result
}
