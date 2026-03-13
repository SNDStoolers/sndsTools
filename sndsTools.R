#' @title Stocke des constantes pour sndsTools

#' @return A list of constants for sndsTools.
#' @export
#' @family utils
constants_snds <- function() {
  constants <- list()
  constants$is_portail <- dir.exists("~/sasdata1")
  constants
}
# nolint start
#' Extraction des consultations dans le DCIR.
#' @description
#' Cette fonction permet d'extraire les consultations dans le DCIR. Les
#' consultations dont les dates `EXE_SOI_DTD` sont comprises entre `start_date`
#' et `end_date` (incluses) sont extraites.
#'
#' @details Le décalage de remontée des données est pris en compte en récupérant
#' également les consultations dont les dates `FLX_DIS_DTD` sont comprises dans
#' les `dis_dtd_lag_months` mois suivant `end_date`.
#'
#' Si `patients_ids_filter` est fourni, seules les consultations pour les
#' patients dont les identifiants sont dans `patients_ids_filter` sont
#' extraites. Dans le cas contraire, les consultations de tous les patients sont
#' extraites.
#'
#' Pour être à flux constant sur l'ensemble des années, il faut utiliser
#' `dis_dtd_lag_months = 27` Cela rallonge le temps d'extraction alors que
#' l'impact sur l'extraction est minime car [la Cnam estime que 99 % des soins
#' sont remontés à 6 mois](https://documentation-snds.health-data-hub.fr/snds/formation_snds/initiation/schema_relationnel_snds.html#_3-3-2-2-dates)
#' c'est-à-dire pour `dis_dtd_lag_months = 6`.
#'
#' Un guide sur l'activité des médecins libéraux est disponibles sur la page
#' [Activité des médecins
#' libéraux](https://documentation-snds.health-data-hub.fr/snds/fiches/activite_medecins.html#contexte).
#'
#' @param start_date Date. La date de début de la période des consultations à
#' extraire.
#' @param end_date Date. La date de fin de la période des consultations à
#' extraire.
#' @param pse_spe_filter Character vector (Optionnel). Les codes spécialités des
#' médecins (référentiel `IR_SPE_V`) effectuant les consultations à extraire. Si
#' `pse_spe_filter` n'est pas fourni, les consultations de tous les spécialités
#' sont extraites. Défaut à `NULL`.
#' @param prestation_filter Character vector (Optionnel). Les codes des
#' prestations à extraire en norme B5 (colonne `PRS_NAT_REF`, référentiel
#' `IR_NAT_V`). Si `prestation_filter` n'est pas fourni, les consultations de
#' tous les prestations sont extraites. Les codes des prestations sont
#' disponibles sur la page ["Cibler selon les natures de prestations"](https://documentation-snds.health-data-hub.fr/snds/fiches/prestation.html) de la documentation SNDS. Défaut à `NULL`.
#' @param analyse_couts Logical (Optionnel). Si `TRUE`, les filtres de qualité
#' liés aux coûts, écartant les actes en majorations sont ignorés. Utile pour
#' des analyses portant sur les coûts. Défaut à `FALSE`.
#' @param dis_dtd_lag_months Integer (Optionnel). Le nombre maximum de mois de
#' décalage de `FLX_DIS_DTD` par rapport à `EXE_SOI DTD` pris en compte pour
#' récupérer les consultations. Défaut à 6 mois.
#' @param patients_ids_filter data frame (Optionnel). Un data frame contenant
#' les paires d'identifiants des patients pour lesquels les consultations
#' doivent être extraites. Les colonnes de ce data frame doivent être
#' `BEN_IDT_ANO`, `BEN_NIR_PSA` et `BEN_RNG_GEM`. Les BEN_NIR_PSA doivent être
#' tous les BEN_NIR_PSA associés
#' aux BEN_IDT_ANO fournis. Défaut à `NULL`.
#' @param output_table_name Character (Optionnel). Si fourni, les résultats
#' seront sauvegardés dans une table portant ce nom dans la base de données au
#' lieu d'être retournés sous forme de data frame. Si cette table existe déjà,
#' le programme s'arrête avec un message d'erreur. Défaut à `NULL`.
#' @param conn DBI connection (Optionnel). Une connexion à la base de données
#' Oracle. Par défaut, une connexion est établie avec oracle.
#' @return Si `output_table_name` est `NULL`, retourne un data frame contenant
#' les consultations. Si `output_table_name` est fourni, sauvegarde les
#' résultats dans la table spécifiée dans Oracle et retourne `NULL` de manière
#' invisible.
#' Dans les deux cas les colonnes de la table de sortie sont :
#'   - `BEN_NIR_PSA` : Colonne présente uniquement si les identifiants
#'   patients (`patients_ids_filter`) ne sont pas fournis. Identifiant SNDS,
#'   aussi appelé pseudo-NIR.
#'   - `BEN_IDT_ANO` : Colonne présente uniquement si les identifiants
#'   patients (`patients_ids_filter`) sont fournis. Numéro d’inscription
#'   au répertoire (NIR) anonymisé.
#'   - `EXE_SOI_DTD` : Date de la consultation.
#'
#' @examples
#' \dontrun{
#' dispenses <- extract_consultations_erprsf(
#'   start_date = as.Date("2010-01-01"),
#'   end_date = as.Date("2010-01-03"),
#'   pse_spe_filter = c("0", "00", "36")
#' )
#' }
#' @export
#' @family extract
# nolint end
extract_consultations_erprsf <- function(
  start_date,
  end_date,
  pse_spe_filter = NULL,
  prestation_filter = NULL,
  analyse_couts = FALSE,
  dis_dtd_lag_months = 6,
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
        c("BEN_IDT_ANO", "BEN_NIR_PSA", "BEN_RNG_GEM")
      ),
      !anyDuplicated(patients_ids_filter)
    )
    patients_ids_table_name <- glue::glue("TMP_PATIENTS_IDS_{timestamp}")
    DBI::dbWriteTable(conn, patients_ids_table_name, patients_ids_filter)
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

  if (!is.null(pse_spe_filter)) {
    print(
      glue::glue(
        "
      Extracting consultations
      from all specialties among
      {paste(pse_spe_filter, collapse = ' or ')}..."
      )
    )
  } else {
    print(glue::glue("Extracting consultations from all specialties codes..."))
  }

  pb <- progress::progress_bar$new(
    format = "Extracting :year1 (going from :year2 to :year3) [:bar] :percent in :elapsed (eta: :eta)", # nolint
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
    if (year < first_non_archived_year) {
      er_prs_f <- dplyr::tbl(conn, glue::glue("ER_PRS_F_{year}"))
    } else {
      er_prs_f <- dplyr::tbl(conn, "ER_PRS_F")
    }

    if (year == end_year) {
      dis_dtd_condition <- glue::glue(
        "FLX_DIS_DTD BETWEEN DATE '{year}-02-01'
        AND DATE '{formatted_dis_dtd_end_date}'"
      )
    } else {
      dis_dtd_condition <- glue::glue(
        "FLX_DIS_DTD BETWEEN DATE '{year}-02-01'
      AND DATE '{year + 1}-01-01'"
      )
    }
    soi_dtd_condition <- glue::glue(
      "EXE_SOI_DTD BETWEEN DATE '{formatted_start_date}'
      AND DATE '{formatted_end_date}'"
    )

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
      "BEN_RNG_GEM"
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

    # TODO : le lien avec les patients_ids_filter pourrait être extrait comme un
    # utilitaire.
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

    query <- query |> dbplyr::sql_render()
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

  # cleaning tables
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

  result
}
# nolint start
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
#' Si `atc_cod_starts_with` ou `cip13_codes` sont fournies, seules les
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
#' l'impact sur l'extraction est minime car [la Cnam estime que 99 % des soins
#' sont remontés à 6
#' mois](https://documentation-snds.health-data-hub.fr/snds/formation_snds/initiation/schema_relationnel_snds.html#_3-3-dcir),
#' c'est-à-dire pour dis_dtd_lag_months = 6.
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
#' @family extract
# nolint end
extract_drug_dispenses <- function(
  start_date,
  end_date,
  atc_cod_starts_with_filter = NULL,
  cip13_cod_filter = NULL,
  patients_ids_filter = NULL,
  dis_dtd_lag_months = 6,
  sup_columns = NULL,
  output_table_name = NULL,
  conn = NULL,
  show_sql_query = FALSE,
  r_cluster_cores = NULL
) {
  # Check arguments
  stopifnot(
    !is.null(start_date),
    !is.null(end_date),
    inherits(start_date, "Date"),
    inherits(end_date, "Date"),
    start_date <= end_date
  )
  if (!is.null(r_cluster_cores)) {
    stopifnot(
      is.numeric(r_cluster_cores),
      r_cluster_cores >= 0
    )
  }
  # check connection
  connection_opened <- FALSE
  if (is.null(conn)) {
    conn <- connect_oracle()
    connection_opened <- TRUE
  }
  # check output table
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

  # Initialize filter tables
  ## Patient filters
  patients_ids_table_name <- NULL
  if (!is.null(patients_ids_filter)) {
    stopifnot(
      identical(
        names(patients_ids_filter),
        c("BEN_IDT_ANO", "BEN_NIR_PSA")
      ),
      !anyDuplicated(patients_ids_filter)
    )
    patients_ids_table_name <- "TMP_PATIENTS_IDS"
    DBI::dbWriteTable(
      conn,
      patients_ids_table_name,
      patients_ids_filter,
      overwrite = TRUE
    )
  }
  # Drug filters
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
      atc_cod_starts_with_filter,
      function(code) {
        glue::glue("PHA_ATC_CLA LIKE '{code}%'")
      },
      character(1)
    )
    atc_conditions <- paste(starts_with_conditions, collapse = " OR ")
    atc_conditions <- glue::glue("({atc_conditions})")
  }

  if (!is.null(cip13_cod_filter)) {
    cip13_conditions <- glue::glue(
      "PHA_CIP_C13 IN ({paste(cip13_cod_filter, collapse = ',')})"
    )
  }
  if (!is.null(atc_cod_starts_with_filter) && !is.null(cip13_cod_filter)) {
    # nolint
    drug_filter <- atc_conditions + " OR " + cip13_conditions
  } else if (
    !is.null(cip13_cod_filter) && is.null(atc_cod_starts_with_filter)
  ) {
    drug_filter <- cip13_conditions
  } else if (
    !is.null(atc_cod_starts_with_filter) &&
      is.null(cip13_cod_filter)
  ) {
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
  ir_pha_filtered <- ir_pha_r |>
    dplyr::select(
      dplyr::all_of(ir_pha_needed_cols)
    )
  if (!is.null(drug_filter)) {
    ir_pha_filtered_query <- ir_pha_filtered |>
      dplyr::filter(dbplyr::sql(drug_filter))
  }
  ir_pha_r_filtered_name <- "TMP_IR_PHA_R"
  # overwrite
  create_table_from_query(
    conn = conn,
    output_table_name = ir_pha_r_filtered_name,
    query = ir_pha_filtered_query,
    overwrite = TRUE
  )
  # DBI::dbExecute(
  #   conn,
  #   glue::glue(
  #     "CREATE TABLE {ir_pha_r_filtered_name} AS {ir_pha_filtered_query}"
  #   )
  # )
  ir_pha_filtered_table <- dplyr::tbl(conn, ir_pha_r_filtered_name)

  # Iterate by month and execute queries

  parallelize_query_by_flx_month(
    conn = conn,
    query_builder_function = .extract_drug_by_month,
    query_builder_kwargs = list(
      sup_columns = sup_columns,
      output_table_name = output_table_name,
      show_sql_query = show_sql_query,
      ir_pha_r_filtered_name = ir_pha_r_filtered_name,
      patients_ids_table_name = patients_ids_table_name
    ),
    start_date = start_date,
    end_date = end_date,
    r_cluster_cores = r_cluster_cores
  )
  # Clean up temporary tables
  on.exit(DBI::dbRemoveTable(conn, ir_pha_r_filtered_name))
  on.exit(
    if (!is.null(patients_ids_filter)) {
      DBI::dbRemoveTable(conn, patients_ids_table_name)
    },
    add = TRUE
  )

  if (output_table_name_is_temp) {
    query <- dplyr::tbl(conn, output_table_name)
    result <- dplyr::collect(query)
    DBI::dbRemoveTable(conn, output_table_name)
  } else {
    result <- invisible(NULL)
    message(glue::glue("Results saved to table {output_table_name} in Oracle."))
    result <- output_table_name
  }

  if (connection_opened) {
    DBI::dbDisconnect(conn)
  }
  result
}

# nolint start
#' Fonction helper pour traiter un mois individuel dans extract_drug_dispenses
#'
#' @description Fonction interne utilisée par extract_drug_dispenses pour traiter
#' un mois de flux en parallèle avec parLapply.
#'
#' @param month_params List contenant les paramètres pour un mois :
#'   - year: Integer, l'année du flux
#'   - month: Integer, le mois du flux
#'   - is_first_month: Logical, TRUE si c'est le premier mois traité
#'   - start_year: Integer, l'année de début de la période
#'   - end_year: Integer, l'année de fin de la période
#'   - dis_dtd_end_month: Integer, le mois de fin pour FLX_DIS_DTD
#'   - formatted_start_date: Character, date formatée de début (YYYY-MM-DD)
#'   - formatted_end_date: Character, date formatée de fin (YYYY-MM-DD)
#'   - output_table_name: Character, nom de la table de sortie
#'   - show_sql_query: Logical, afficher la requête SQL du premier mois
#'   - first_non_archived_year: Integer, première année non archivée
#'   - ir_pha_r_filtered_name: Character, nom de la table IR_PHA_R filtrée
#'   - sup_columns: Character vector, colonnes supplémentaires
#'   - patients_ids_table_name: Character ou NULL, nom de la table des IDs patients
#'   - conn: Connexion DBI (peut être NULL en contexte parallèle où conn est global)
#'
#' @return Invisible NULL (modifie la table output_table_name en base de données)
#'
#' @details Cette fonction est destinée à être utilisée via `parallel::parLapply()`
#' et ne doit pas être appelée directement par l'utilisateur.
#' En contexte parallèle, la connexion 'conn' est disponible comme variable globale
#' dans l'environnement du worker.
#'
#' @keywords internal
# nolint end
# TODO : refacto :
# target API
# extract_drug_dispense( ) : user facing function with SNDS-friendly parameters
# query_builder_function(year, month, **kwargs) : helper function building the query for a given month and year with the provided parameters (executed in parallel)
# query_by_month_parallel(conn, query_builder_function, query_kwargs, start_date, end_date, r_cluster_cores)
.extract_drug_by_month <- function(kwargs) {
  # Get back parameters
  conn <- kwargs$conn # for no parallel context
  # date parameters
  dis_dtd_year <- kwargs$dis_dtd_year
  dis_dtd_month <- kwargs$dis_dtd_month
  is_first_month <- kwargs$is_first_month
  formatted_start_date <- kwargs$formatted_start_date
  formatted_end_date <- kwargs$formatted_end_date
  end_year <- kwargs$end_year

  # other parameters
  output_table_name <- kwargs$output_table_name
  show_sql_query <- kwargs$show_sql_query
  ir_pha_r_filtered_name <- kwargs$ir_pha_r_filtered_name
  sup_columns <- kwargs$sup_columns
  patients_ids_table_name <- kwargs$patients_ids_table_name

  # Use global connexion
  if (!is.null(conn)) {
    # Connexion provided as argument (non-parallel context)
    conn <- conn
  } else if (exists("conn", envir = .GlobalEnv)) {
    conn <- get("conn", envir = .GlobalEnv)
  } else {
    stop("No database connection available")
  }

  # Load tables for the year
  if (dis_dtd_year < get_first_non_archived_year(conn)) {
    er_prs_f <- dplyr::tbl(conn, glue::glue("ER_PRS_F_{dis_dtd_year}"))
    er_pha_f <- dplyr::tbl(conn, glue::glue("ER_PHA_F_{dis_dtd_year}"))
    er_ete_f <- dplyr::tbl(conn, glue::glue("ER_ETE_F_{dis_dtd_year}"))
  } else {
    er_prs_f <- dplyr::tbl(conn, "ER_PRS_F")
    er_pha_f <- dplyr::tbl(conn, "ER_PHA_F")
    er_ete_f <- dplyr::tbl(conn, "ER_ETE_F")
  }

  # Charger la table IR_PHA filtrée
  ir_pha_filtered_table <- dplyr::tbl(conn, ir_pha_r_filtered_name)

  # Construire les dates de flux
  dis_dtd_start <- glue::glue(
    "DATE '{dis_dtd_year}-{sprintf('%02d', dis_dtd_month)}-01'"
  )
  dis_dtd_end <- glue::glue(
    "DATE '{dis_dtd_year}-{sprintf('%02d', dis_dtd_month + 1)}-01'"
  )

  if ((dis_dtd_year != end_year) && (dis_dtd_month == 12)) {
    # For archived years, some lines of decembers are indexed in the
    # following year: https://github.com/SNDStoolers/sndsTools/issues/26
    dis_dtd_end <- glue::glue("DATE '{dis_dtd_year + 1}-01-01'")
  }

  dis_dtd_condition <- glue::glue(
    "FLX_DIS_DTD >= {dis_dtd_start} AND FLX_DIS_DTD < {dis_dtd_end}"
  )

  soi_dtd_condition <- glue::glue(
    "EXE_SOI_DTD >= DATE '{formatted_start_date}' AND EXE_SOI_DTD <= DATE '{formatted_end_date}'" # nolint
  )

  logger::log_info(glue::glue("-flux: {dis_dtd_start} to {dis_dtd_end}"))

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
  ir_pha_cols_not_in_er_pha <- setdiff(
    colnames(ir_pha_filtered_table),
    colnames(er_pha_f)
  )

  query <- er_prs_f |>
    dplyr::inner_join(er_pha_f, by = dcir_join_keys) |>
    dplyr::inner_join(
      ir_pha_filtered_table |>
        dplyr::select(dplyr::all_of(ir_pha_cols_not_in_er_pha)),
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
      (ETE_IND_TAA != 1L) | is.na(ETE_IND_TAA)
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

  if (!is.null(patients_ids_table_name)) {
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

  if (is_first_month) {
    DBI::dbExecute(
      conn,
      glue::glue("CREATE TABLE {output_table_name} AS {query}")
    )
    if (show_sql_query) {
      logger::log_info(glue::glue(
        "
     Premier mois requêté en date de flux
     à l'aide de la requête sql suivante :\n {query}"
      ))
    }
  } else {
    insert_query <- glue::glue("INSERT INTO {output_table_name} {query}")
    DBI::dbExecute(conn, insert_query)
  }

  invisible(NULL)
}
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
#' @param patient_ids_filter data.frame Optionnel. Un data.frame contenant les
#' paires d'identifiants des patients pour lesquels les consultations doivent
#' être extraites. Les colonnes de ce data.frame doivent être `BEN_IDT_ANO` et
#' `BEN_NIR_PSA` (en majuscules). Les `BEN_NIR_PSA` doivent être tous les
#' `BEN_NIR_PSA` associés aux `BEN_IDT_ANO` fournis. Si `patient_ids_filter`
#' n'est pas fourni, les consultations de tous les patients sont extraites.
#' @param output_table_name character Optionnel. Le nom de la table de sortie
#' dans la base de données. Si `output_table_name` n'est pas fourni, une table
#' de sortie intermédiaire est créée en R. Si `output_table_name` est fourni
#' mais que cette table existe déjà dans oracle, le programme s'arrête avec un
#' message d'erreur.
#' @param conn dbConnection La connexion à la base de données. Si `conn` n'est
#' pas fourni, une connexion à la base de données est initialisée. Par défaut,
#' une connexion est établie avec oracle.
#'
#' @return Un data.frame contenant les consultations. Les colonnes sont les
#' suivantes :
#' - `BEN_IDT_ANO` : Identifiant bénéficiaire anonymisé (seulement si
#' patient_ids_filter non nul)
#' - `NIR_ANO_17` : NIR anonymisé
#' - `EXE_SOI_DTD` : Date de la délivrance
#' - `ACT_COD` : Code prestation de l'acte
#' - `EXE_SPE` : Code de spécialité du professionnel de soin prescripteur
#' - `CCAM_COD` : Code de l'acte médical classifié avec la CCAM.
#'
#' @examples
#' \dontrun{
#' # Extraction des consultations à l'hôpital en 2019 pour les spécialités 01 et 02
#' extract_hospital_consultations(
#'   start_date = as.Date("2019-01-01"),
#'   end_date = as.Date("2019-12-31"),
#'   spe_codes_filter = c("01", "02")
#' )
#' # Extraction de consultations à l'hôpital à partir de code CCAM
#' extract_hospital_consultations(
#'   start_date = as.Date("2019-01-01"),
#'   end_date = as.Date("2019-12-31"),
#'   ccam_codes_filter = c("ACQK001", "ACQH003")
#' )
#' # Extraction de consultations à l'hôpital à partir de code CCAM et de spécialités
#' extract_hospital_consultations(
#'   start_date = as.Date("2019-01-01"),
#'   end_date = as.Date("2019-12-31"),
#'   ccam_codes_filter = c("ACQK001", "ACQH003"),
#'   spe_codes_filter = c("01", "02")
#'
#' )
#' }
#' @export
#' @family extract
# nolint end
extract_hospital_consultations <- function(
  start_date,
  end_date,
  spe_codes_filter = NULL,
  prestation_codes_filter = NULL,
  ccam_codes_filter = NULL,
  patient_ids_filter = NULL,
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
    output_table_name_is_temp <- FALSE
    stopifnot(
      is.character(output_table_name),
      !DBI::dbExistsTable(conn, output_table_name)
    )
  } else {
    output_table_name_is_temp <- TRUE
    output_table_name <- glue::glue("TMP_DISP_{timestamp}")
  }

  start_year <- lubridate::year(start_date)
  end_year <- lubridate::year(end_date)
  formatted_start_date <- format(start_date, "%Y-%m-%d")
  formatted_end_date <- format(end_date, "%Y-%m-%d")

  if (!is.null(patient_ids_filter)) {
    patient_ids_table_name <- "TMP_PATIENT_IDS"
    try(DBI::dbRemoveTable(conn, patient_ids_table_name), silent = TRUE)
    DBI::dbWriteTable(conn, patient_ids_table_name, patient_ids_filter)
  }

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

    if (!is.null(patient_ids_filter)) {
      patient_ids_table <- dplyr::tbl(conn, patient_ids_table_name)
      query <- patient_ids_table |>
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
      query <- ace
      selected_columns <-
        c("NIR_ANO_17", "EXE_SOI_DTD", "CCAM_COD", "ACT_COD", "EXE_SPE")
    }
    query <- query |>
      dplyr::select(dplyr::all_of(selected_columns)) |>
      dplyr::distinct()

    if (DBI::dbExistsTable(conn, output_table_name)) {
      query <- dbplyr::sql_render(query)
      DBI::dbExecute(
        conn,
        glue::glue("INSERT INTO {output_table_name} {query}")
      )
    } else {
      query <- dbplyr::sql_render(query)
      DBI::dbExecute(
        conn,
        glue::glue("CREATE TABLE {output_table_name} AS {query}")
      )
    }
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

  result
}
# Liste des finess géographiques APHP, APHM et HCL à supprimer pour éviter les
# doublons
finess_doublons <- c(
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
#' @param output_table_name character Le nom de la table de sortie dans la base
#' de données. Si `output_table_name` n'est pas fourni, une table de sortie
#' intermédiaire est créée. Défaut à `NULL`.
#' @param conn dbConnection La connexion à la base de données. Si `conn` n'est
#' pas fourni, une connexion à la base de données est initialisée. Défaut à
#' `NULL`.
#'
#' @return Un data.frame contenant les séjours hospitaliers. Attention: Les
#' lignes des tables MCO B et C peuvent être dupliquées. Les colonnes sont les
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
#' extract_hospital_stays(
#'   start_date =
#'     as.Date("2019-01-01"), end_date = as.Date("2019-12-31"), dp_cim10_codes =
#'     c("A00", "B00")
#' )
#' }
#' @export
#' @family extract
# nolint end
extract_hospital_stays <- function(
  start_date,
  end_date,
  dp_cim10_codes_filter = NULL,
  or_dr_with_same_codes_filter = FALSE,
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
    stopifnot(
      is.character(output_table_name),
      !DBI::dbExistsTable(conn, output_table_name)
    )
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
    pb$tick(
      tokens = list(
        year1 = year,
        year2 = start_year,
        year3 = end_year
      )
    )

    formatted_year <- sprintf("%02d", year %% 100)

    t_mco_b <- dplyr::tbl(conn, glue::glue("T_MCO{formatted_year}B"))
    t_mco_c <- dplyr::tbl(conn, glue::glue("T_MCO{formatted_year}C"))
    t_mco_d <- dplyr::tbl(conn, glue::glue("T_MCO{formatted_year}D"))
    t_mco_um <- dplyr::tbl(conn, glue::glue("T_MCO{formatted_year}UM"))

    dp_dr_conditions <- build_dp_dr_conditions(
      cim10_codes = dp_cim10_codes_filter,
      include_dr = or_dr_with_same_codes_filter
    )

    eta_num_rsa_num <-
      t_mco_b |>
      dplyr::filter(dbplyr::sql(dp_dr_conditions)) |>
      dplyr::select(ETA_NUM, RSA_NUM) |>
      dplyr::distinct()

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
      dplyr::filter(!(GRG_GHM %like% "%90%"), !(ETA_NUM %in% finess_doublons))

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

    t_mco_b_c_quality_filtered_c <- t_mco_b_c_quality_filtered |>
      dplyr::collect()

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
      dplyr::distinct() |>
      dplyr::collect()

    mco_b_c_um <-
      t_mco_b_c_quality_filtered_c |>
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
      dplyr::distinct() |>
      dplyr::collect()

    mco_b_c_d <- t_mco_b_c_quality_filtered_c |>
      dplyr::left_join(
        t_mco_d_selected_stays,
        by = c("ETA_NUM", "RSA_NUM")
      )

    # Bind all diagnoses: DP, DR, associated, DP and DR from UM
    all_diagnoses <-
      dplyr::bind_rows(
        mco_b_c_um,
        mco_b_c_d
      ) |>
      dplyr::distinct()

    # remove possible useless duplicates with all NaN on D and UM diagnoses
    all_diagnoses_wo_duplicates <- all_diagnoses |>
      dplyr::filter(
        !dplyr::if_all(c(DGN_PAL_UM, DGN_REL_UM, ASS_DGN), is.na)
      )

    hospital_stays_list <- append(
      hospital_stays_list,
      list(all_diagnoses_wo_duplicates)
    )
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
  result
}
# nolint start
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
#'   Voir [la fiche sur les ALD de la documentation du SNDS](
#' https://documentation-snds.health-data-hub.fr/snds/fiches/beneficiaires_ald.html).
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
#' @family extract
extract_long_term_disease <- function(
  start_date = NULL,
  end_date = NULL,
  icd_cod_starts_with = NULL,
  ald_numbers = NULL,
  excl_etm_nat = c("11", "12", "13"),
  patients_ids = NULL,
  output_table_name = NULL,
  overwrite = FALSE,
  conn = NULL
) {
  # nolint end. Force # nolint: cyclocomp_linter for the function.
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
      !DBI::dbExistsTable(conn, output_table_name) ||
        (DBI::dbExistsTable(conn, output_table_name) && overwrite)
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

  result
}
# Function to retrieve
retrieve_psa <- function(
  ben_table_name,
  start_key,
  conn = NULL,
  check_arc_table = TRUE,
  output_table_name = NULL
) {
  # Check if a connection is provided
  connection_opened <- FALSE
  if (is.null(conn)) {
    conn <- connect_oracle()
    connection_opened <- TRUE
  }

  # Check if the input arguments are of the correct type
  stopifnot(
    is.logical(check_arc_table),
    is.character(ben_table_name),
    is.character(output_table_name) | is.null(output_table_name)
  )

  # Retrieve ben_table_name column names
  ben_table_colnames <- dplyr::tbl(conn, ben_table_name) |> colnames()

  # Define reference table names
  ben <- dplyr::tbl(conn, "IR_BEN_R")
  ben_arc <- dplyr::tbl(conn, "IR_BEN_R_ARC")

  # Check table content
  if (!(start_key %in% ben_table_colnames)) {
    stop(glue::glue("ben_table_name must contain at least {start_key}"))
  }

  # Handling BEN_RNG_GEM if included in the input table
  is_ben_rng_gem_included <- if ("BEN_RNG_GEM" %in% ben_table_colnames) {
    "BEN_RNG_GEM"
  } else {
    NULL
  }
  psa_key <- c("BEN_NIR_PSA", is_ben_rng_gem_included) |> purrr::compact()
  idt_key <- c("BEN_IDT_ANO", is_ben_rng_gem_included) |> purrr::compact()

  # Retrieve BEN_IDT_ANO from initial table
  # Start from BEN_NIR_PSA
  if (start_key == "BEN_NIR_PSA") {
    ben_table <- dplyr::tbl(conn, ben_table_name)
    # rename BEN_IDT_ANO to avoid confusion in joins
    if ("BEN_IDT_ANO" %in% ben_table_colnames) {
      ben_table <- dplyr::tbl(conn, ben_table_name) |>
        dplyr::rename(BEN_IDT_ANO_ben_table = BEN_IDT_ANO)
    }
    idt <- ben_table |>
      dplyr::inner_join(ben, by = setNames(psa_key, psa_key)) |>
      dplyr::select(!!!rlang::syms(idt_key)) |>
      dplyr::distinct()
    if (check_arc_table) {
      idt_arc <- ben_table |>
        dplyr::inner_join(ben_arc, by = setNames(psa_key, psa_key)) |>
        dplyr::select(!!!rlang::syms(idt_key)) |>
        dplyr::distinct()

      idt <- dplyr::union(idt, idt_arc)
    }
  } else {
    # Start from BEN_IDT_ANO
    ben_table <- dplyr::tbl(conn, ben_table_name)
    # rename BEN_NIR_PSA to avoid confusion in joins
    if ("BEN_NIR_PSA" %in% ben_table_colnames) {
      ben_table <- dplyr::tbl(conn, ben_table_name) |>
        dplyr::rename(BEN_NIR_PSA_ben_table = BEN_NIR_PSA)
    }
    idt <- ben_table |>
      dplyr::distinct()
  }

  # BEN_NIR_PSA retrieval from BEN_IDT_ANO
  idt_psa <- idt |>
    dplyr::inner_join(ben, by = setNames(idt_key, idt_key))

  # Consider archived table if requested
  if (check_arc_table) {
    idt_psa_arc <- idt |>
      dplyr::inner_join(ben_arc, by = setNames(idt_key, idt_key))
    idt_psa <- dplyr::union(idt_psa, idt_psa_arc)
  }

  # Assessment of exclusion criteria
  idt_psa <- idt_psa |>
    dplyr::distinct() |>
    dplyr::collect() |>
    dplyr::group_by(!!!rlang::syms(psa_key)) |>
    dplyr::mutate(
      psa_w_multiple_idt_or_nir = dplyr::n_distinct(BEN_IDT_ANO) > 1 |
        dplyr::n_distinct(BEN_NIR_ANO) > 1
    ) |>
    dplyr::ungroup() |>
    dplyr::group_by(!!!rlang::syms(idt_key)) |>
    dplyr::mutate(
      psa_w_multiple_idt_or_nir = any(psa_w_multiple_idt_or_nir),
      cdi_nir_00 = !is.na(BEN_CDI_NIR) & BEN_CDI_NIR == "00",
      nir_ano_defined = !is.na(BEN_NIR_ANO),
      birth_date_variation = dplyr::n_distinct(BEN_NAI_ANN) > 1 |
        dplyr::n_distinct(BEN_NAI_MOI) > 1,
      sex_variation = dplyr::n_distinct(BEN_SEX_COD) > 1
    )

  # Handle output: Return or save the table
  if (is.null(output_table_name)) {
    if (connection_opened) {
      DBI::dbDisconnect(conn)
    }
    idt_psa
  } else {
    DBI::dbWriteTable(
      conn,
      output_table_name,
      idt_psa |> dplyr::collect(),
      overwrite = TRUE
    )
    message(glue::glue("Results saved to table {output_table_name} in Oracle."))
    if (connection_opened) DBI::dbDisconnect(conn)
  }
}

# nolint start
#' Gestion des identifiants patients à l'aide de `BEN_IDT_ANO`
#' @description
#' La fonction `retrieve_all_psa_from_idt` permet d'extraire le reférentiel des
#' bénéficiaires avec la clé de jointure la plus fine (l'ensemble des
#' `BEN_NIR_PSA`) à partir d'une table contenant un identifiant patient
#' `BEN_IDT_ANO`.
#'
#' Cinq variables binaires sont ajoutées en sortie pour aider au processus
#' d'inclusion :
#' 1. `psa_w_multiple_idt_or_nir` : permet d'identifier les `BEN_IDT_ANO` ou
#' `BEN_NIR_ANO` présentant des `BEN_NIR_PSA` associés à plusieurs `BEN_IDT_ANO`
#' ou `BEN_NIR_ANO`.
#' 2. `cdi_nir_00` : permet d'identifier les `BEN_NIR_PSA` non fictifs.
#' 3. `nir_ano_defined` : permet d'identifier les `BEN_NIR_PSA` pour lesquels
#' un `BEN_NIR_ANO` est défini.
#' 4. `birth_date_variation` : permet d'identifier les `BEN_IDT_ANO`
#' présentant des inconsistances au niveau de la date de naissance.
#' 5. `sex_variation` : permet d'identifier les `BEN_IDT_ANO`
#' présentant des inconsistances relatives aux codes sexe.
#'
#' @details
#' La fonction retourne une copie du/des référentiel(s) `IR_BEN_R`
#' (/`IR_BEN_R_ARC`) dans une table dédoublonnée avec des indicateurs visant
#' à améliorer le processus d'inclusion.
#' @param ben_table_name Character Obligatoire. Nom de la table d'entrée
#' comprenant au moins la variable `BEN_NIR_PSA`.
#' Si la variable `BEN_RNG_GEM` est incluse, elle sera également
#' utilisée pour les jointures avec les référentiels.
#' @param conn DBI connection Optionnel Une connexion à la base de données
#' Oracle.
#' Si non fournie, une connexion est établie par défaut.
#' @param check_arc_table Logical Optionnel. Si TRUE (par défaut), les tables
#' `IR_BEN_R_ARC` sont également consultées pour la recherche des
#' `BEN_IDT_ANO` et des critères de sélection.
#' @param output_table_name Character Optionnel. Si fourni, les résultats seront
#' sauvegardés dans une table portant ce nom dans Oracle. Sinon la table en
#' sortie est retournée sous la forme d'un data.frame(/tibble).
#' @return A partir d'une table avec `BEN_IDT_ANO`, la fonction retournera
#' l'ensemble des `BEN_NIR_PSA` + `BEN_RNG_GEM` associés au `BEN_IDT_ANO`
#' dans une table dédoublonnée.
#' La table en sortie est une copie de(s) référentiel(s) `IR_BEN_R`
#' (et `IR_BEN_R_ARC`) relatifs aux `BEN_IDT_ANO` impliqués et enregistrée
#' sous Oracle ou retournée sous la forme d'un data.frame(/tibble).
#' Si output_table_name est `NULL`, retourne un data.frame(/tibble).
#' Si output_table_name est fourni, sauvegarde les résultats dans la table
#' spécifiée dans Oracle et retourne `NULL` de manière invisible.
#' Dans les deux cas les colonnes de la table de sortie sont celles
#' des tables `IR_BEN_R` et `IR_BEN_R_ARC` auxquelles sont ajoutées les
#' variables binaires:
#'   - `psa_w_multiple_idt_or_nir` (Logical): permet de vérifier que
#'     chaque BEN_NIR_PSA est associé à un seul `BEN_IDT_ANO` ou `BEN_NIR_ANO`.
#'     Si cette relation d’unicité est respectée, alors les bases PMSI et
#'     DCIR peuvent être interrogées directement à partir de la variable
#'     BEN_NIR_PSA, qui suffit alors pour identifier de manière unique
#'     un patient. Dans le cas contraire, seules les tables du DCIR peuvent
#'     être exploitées pour effectuer des requêtes à l’échelle d’un patient
#'     unique. Il est alors nécessaire de prendre en compte les variables
#'     `BEN_IDT_ANO`, `BEN_RNG_GEM` et `BEN_ORG_AFF` afin d’assurer une
#'     interprétation correcte des identifiants. La variable `BEN_NIR_ANO`,
#'     bien qu’elle permette théoriquement de distinguer les individus
#'     de manière anonyme, peut être manquante. Quant à `BEN_RNG_GEM`,
#'     défini comme le rang gémellaire, il peut prendre différentes valeurs en
#'     cas de changement de régime, identifiable via la variable `BEN_ORG_AFF`.
#'      Source :
#'      https://documentation-snds.health-data-hub.fr/files/Sante_publique_France/2021-10-SpF-SNDS-ce-quil-faut-savoir-v3-MPL-2.0.pdf.
#'   - `cdi_nir_00` (Logical): permet d'identifier les `BEN_NIR_PSA` non fictifs
#'   - `nir_ano_defined` (Logical): permet d'identifier les `BEN_NIR_PSA` pour
#'      lesquels un `BEN_NIR_ANO` et un `BEN_IDT_ANO` sont défini
#'   - `birth_date_variation` (Logical): permet d'identifier les `BEN_IDT_ANO`
#'     présentant des dates de naissance différentes pour un même `BEN_IDT_ANO`
#'   - `sex_variation` (Logical): permet d'identifier les `BEN_IDT_ANO`
#'     présentant des codes sexe différents pour un même `BEN_IDT_ANO`
#'
#' @examples
#' \dontrun{
#' # Création et enregistrement dans Oracle d'un tibble de 100 BEN_IDT_ANO
#' idt_sample_1 <- dplyr::tbl(conn, "IR_BEN_R") |>
#'   dplyr::select(BEN_IDT_ANO) |>
#'   dplyr::distinct() |>
#'   head(100) |>
#'   dplyr::collect()
#' dbWriteTable(conn, "IDT_SAMP_1", idt_sample_1, overwrite = TRUE)
#'
#' # Récupération de la table en format tibble
#' retrieve_all_psa_from_idt(conn = conn, ben_table_name = "IDT_SAMP_1")
#' # Récupération et enregistrement de la table dans Oracle
#' retrieve_all_psa_from_idt(
#'   conn = conn,
#'   ben_table_name = "IDT_SAMP_1",
#'   output_table_name = "TEST_SAVE_ORACLE"
#' )
#' # Récupération de la table sans considérer la table de référentiel archivée
#' retrieve_all_psa_from_idt(
#'   conn = conn,
#'   ben_table_name = "IDT_SAMP_1",
#'   check_arc_table = FALSE
#' )
#' }
#' @export
#' @family utils
# nolint end
retrieve_all_psa_from_idt <- function(
  ben_table_name,
  conn = NULL,
  check_arc_table = TRUE,
  output_table_name = NULL
) {
  start_key <- "BEN_IDT_ANO"
  retrieve_psa(
    ben_table_name,
    start_key,
    conn,
    check_arc_table,
    output_table_name
  )
}

# nolint start
#' Gestion des identifiants patients à l'aide de `BEN_NIR_PSA`
#' @description
#' La fonction `retrieve_all_psa_from_psa` permet d'extraire le reférentiel des
#' bénéficiaires avec la clé de jointure la plus fine (l'ensemble des
#' `BEN_NIR_PSA`) à partir d'une table contenant un identifiant patient
#' `BEN_NIR_PSA`.
#'
#' Cinq variables binaires sont ajoutées en sortie pour aider au processus
#' d'inclusion :
#' 1. `psa_w_multiple_idt_or_nir` : permet d'identifier les `BEN_IDT_ANO` ou
#' `BEN_NIR_ANO` présentant des `BEN_NIR_PSA` associés à plusieurs `BEN_IDT_ANO`
#' ou `BEN_NIR_ANO`.
#' 2. `cdi_nir_00` : permet d'identifier les `BEN_NIR_PSA` non fictifs.
#' 3. `nir_ano_defined` : permet d'identifier les `BEN_NIR_PSA` pour lesquels
#' un `BEN_NIR_ANO` est défini.
#' 4. `birth_date_variation` : permet d'identifier les `BEN_IDT_ANO`
#' présentant des inconsistances au niveau de la date de naissance.
#' 5. `sex_variation` : permet d'identifier les `BEN_IDT_ANO`
#' présentant des inconsistances relatives aux codes sexe.
#'
#' @details
#' La fonction retourne une copie du/des référentiel(s) `ÌR_BEN_R`
#' (/`ÌR_BEN_R_ARC`) dans une table dédoublonnée avec des indicateurs visant
#' à améliorer le processus d'inclusion.
#' @param ben_table_name Character Obligatoire. Nom de la table d'entrée
#' comprenant au moins la variable `BEN_IDT_ANO`.
#' Si la variable `BEN_RNG_GEM` est incluse, elle sera également
#' utilisée pour les jointures avec les référentiels.
#' @param conn DBI connection Optionnel Une connexion à la base de données
#' Oracle.
#' Si non fournie, une connexion est établie par défaut.
#' @param check_arc_table Logical Optionnel. Si TRUE (par défaut), les tables
#' `IR_BEN_R_ARC` sont également consultées pour la recherche des
#' `BEN_IDT_ANO` et des critères de sélection.
#' @param output_table_name Character Optionnel. Si fourni, les résultats seront
#' sauvegardés dans une table portant ce nom dans Oracle. Sinon la table en
#' sortie est retournée sous la forme d'un data.frame(/tibble).
#' @return A partir d'une table avec `BEN_IDT_ANO`, la fonction retournera
#' l'ensemble des `BEN_NIR_PSA` + `BEN_RNG_GEM` associés au `BEN_IDT_ANO`
#' dans une table dédoublonnée.
#' La table en sortie est une copie de(s) référentiel(s) `IR_BEN_R`
#' (et `IR_BEN_R_ARC`) relatifs aux `BEN_IDT_ANO` impliqués et enregistrée
#' sous Oracle ou retournée sous la forme d'un data.frame(/tibble).
#' Si output_table_name est `NULL`, retourne un data.frame(/tibble).
#' Si output_table_name est fourni, sauvegarde les résultats dans la table
#' spécifiée dans Oracle et retourne `NULL` de manière invisible.
#' Dans les deux cas les colonnes de la table de sortie sont celles
#' des tables `IR_BEN_R` et `IR_BEN_R_ARC` auxquelles sont ajoutées les
#' variables binaires:
#'   - `psa_w_multiple_idt_or_nir` (Logical): permet de vérifier que
#'     chaque BEN_NIR_PSA est associé à un seul `BEN_IDT_ANO` ou `BEN_NIR_ANO`.
#'     Si cette relation d’unicité est respectée, alors les bases PMSI et
#'     DCIR peuvent être interrogées directement à partir de la variable
#'     BEN_NIR_PSA, qui suffit alors pour identifier de manière unique
#'     un patient. Dans le cas contraire, seules les tables du DCIR peuvent
#'     être exploitées pour effectuer des requêtes à l’échelle d’un patient
#'     unique. Il est alors nécessaire de prendre en compte les variables
#'     `BEN_IDT_ANO`, `BEN_RNG_GEM` et `BEN_ORG_AFF` afin d’assurer une
#'     interprétation correcte des identifiants. La variable `BEN_NIR_ANO`,
#'     bien qu’elle permette théoriquement de distinguer les individus
#'     de manière anonyme, peut être manquante. Quant à `BEN_RNG_GEM`,
#'     défini comme le rang gémellaire, il peut prendre différentes valeurs en
#'     cas de changement de régime, identifiable via la variable `BEN_ORG_AFF`.
#'      Source :
#'      https://documentation-snds.health-data-hub.fr/files/Sante_publique_France/2021-10-SpF-SNDS-ce-quil-faut-savoir-v3-MPL-2.0.pdf.
#'   - `cdi_nir_00` (Logical): permet d'identifier les `BEN_NIR_PSA` non fictifs
#'   - `nir_ano_defined` (Logical): permet d'identifier les `BEN_NIR_PSA` pour
#'      lesquels un `BEN_NIR_ANO` et un `BEN_IDT_ANO` sont défini
#'   - `birth_date_variation` (Logical): permet d'identifier les `BEN_IDT_ANO`
#'     présentant des dates de naissance différentes pour un même `BEN_IDT_ANO`
#'   - `sex_variation` (Logical): permet d'identifier les `BEN_IDT_ANO`
#'     présentant des codes sexe différents pour un même `BEN_IDT_ANO`
#'
#' @examples
#' \dontrun{
#' # Création et enregistrement dans Oracle de 100 couples de (BEN_NIR_PSA+BEN_RNG_GEM)
#' psa_sample_2 <- dplyr::tbl(conn, "IR_BEN_R") |>
#'   dplyr::select(BEN_NIR_PSA, BEN_RNG_GEM) |>
#'   head(100) |>
#'   dplyr::collect()
#' dbWriteTable(conn, "PSA_SAMP_2", psa_sample_2, overwrite = TRUE)
#' # Récupération de la table en format tibble
#' retrieve_all_psa_from_psa(conn = conn, ben_table_name = "PSA_SAMP_2")
#' # Récupération et enregistrement de la table dans Oracle
#' retrieve_all_psa_from_psa(
#'   conn = conn,
#'   ben_table_name = "PSA_SAMP_2",
#'   output_table_name = "TEST_SAVE_ORACLE"
#' )
#' # Récupération de la table sans considérer la table de référentiel archivée
#' retrieve_all_psa_from_psa(
#'   conn = conn,
#'   ben_table_name = "PSA_SAMP_2",
#'   check_arc_table = FALSE
#' )
#' }
#' @export
#' @family utils
# nolint end
retrieve_all_psa_from_psa <- function(
  ben_table_name,
  conn = NULL,
  check_arc_table = TRUE,
  output_table_name = NULL
) {
  start_key <- "BEN_NIR_PSA"
  retrieve_psa(
    ben_table_name,
    start_key,
    conn,
    check_arc_table,
    output_table_name
  )
}
#' Extraction des délivrances de médicaments à partir de SQL injecté dans du R
#' (modèle dbExecute de Thomas Soeiro).
#'
#' @description Cette fonction permet d'extraire les délivrances de médicaments
#' par code ATC ou par code CIP13. Les délivrances dont les dates `EXE_SOI_DTD`
#' sont comprises entre `start_date` et `end_date` (incluses) sont extraites.
#'
#' @param start_date Date. La date de début de la période des délivrances des
#'   médicaments à extraire.
#' @param end_date Date. La date de fin de la période des délivrances des
#'   médicaments à extraire.
#' @param atc_cod_starts_with_filter Character vector (Optionnel). Les codes ATC
#'   par lesquels les délivrances de médicaments à extraire doivent commencer.
#'   Défaut à NULL.
#' @param cip13_cod_filter Character vector (Optionnel). Les codes CIP des
#'   délivrances de médicaments à extraire en complément des codes ATC. Défaut à
#' NULL.
#' @param output_table_name Character (Optionnel). Si fourni, les résultats
#'   seront sauvegardés dans une table portant ce nom dans la base de données au
#'   lieu d'être retournés sous forme de data frame. Défault à NULL.
#' @param conn DBI connection (Optionnel). Une connexion à la base de données
#'   Oracle. Si non fournie, une connexion est établie par défaut. Défaut à
#'   NULL.
#'
#' @export
sql_extract_drug_dispenses <- function(
  start_date, # nolint
  end_date,
  output_table_name,
  atc_cod_starts_with_filter = NULL,
  cip13_cod_filter = NULL,
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
  if (is.null(conn)) {
    conn <- connect_oracle()
    connection_opened <- TRUE
  }
  # Format the dates (used in the glued SQL query)
  formatted_start_date <- format(start_date, "%Y-%m-%d") # nolint
  formatted_end_date <- format(end_date, "%Y-%m-%d") # nolint

  # Create the subset of IR_PHA_V table that should be joined to the DCIR
  # tables(same code as extract_drug_dispenses)
  ir_pha_r <- dplyr::tbl(conn, "IR_PHA_R")

  if (!is.null(atc_cod_starts_with_filter)) {
    starts_with_conditions <- vapply(
      atc_cod_starts_with_filter,
      function(code) {
        glue::glue("PHA_ATC_CLA LIKE '{code}%'")
      },
      character(1)
    )
    atc_conditions <- paste(starts_with_conditions, collapse = " OR ")
    atc_conditions <- glue::glue("({atc_conditions})")
  }
  if (!is.null(cip13_cod_filter)) {
    cip13_conditions <- glue::glue(
      "PHA_CIP_C13 IN ({paste(cip13_cod_filter, collapse = ',')})"
    )
  }
  if (!is.null(atc_cod_starts_with_filter) && !is.null(cip13_cod_filter)) {
    # nolint
    drug_filter <- atc_conditions + " OR " + cip13_conditions
  } else if (
    !is.null(cip13_cod_filter) && is.null(atc_cod_starts_with_filter)
  ) {
    # nolint
    drug_filter <- cip13_conditions
  } else if (
    !is.null(atc_cod_starts_with_filter) && is.null(cip13_cod_filter)
  ) {
    # nolint
    drug_filter <- atc_conditions
  } else {
    drug_filter <- NULL
  }
  ir_pha_needed_cols <- c("PHA_CIP_C13", "PHA_ATC_CLA", "PHA_GRD_CND")
  ir_pha_filtered <- ir_pha_r |>
    dplyr::select(dplyr::all_of(ir_pha_needed_cols))
  if (!is.null(drug_filter)) {
    ir_pha_filtered_query <- ir_pha_filtered |>
      dplyr::filter(dbplyr::sql(drug_filter)) |>
      dbplyr::sql_render()
  }
  timestamp_ <- format(Sys.time(), "%Y%m%d_%H%M%S")
  ir_pha_r_filtered_name <- glue::glue("TMP_IR_PHA_R_{timestamp_}")
  DBI::dbExecute(
    conn,
    glue::glue(
      "CREATE TABLE {ir_pha_r_filtered_name} AS {ir_pha_filtered_query}"
    )
  )

  sql_drug_query <- "
  SELECT DISTINCT prs.BEN_NIR_PSA,
    prs.BEN_CMU_TOP,
    prs.BEN_AMA_COD,
    prs.BEN_SEX_COD,
    prs.BEN_RES_DPT,
    prs.FLX_DIS_DTD,
    prs.EXE_SOI_DTD,
    prs.PRS_ACT_QTE,
    prs.BSE_REM_MNT,
    prs.BSE_PRS_NAT,
    prs.PSP_SPE_COD,
    ete.ETE_IND_TAA,
    ete.ETB_EXE_FIN,
    ete.ETE_MCO_DDP,
    ir_pha_filter.PHA_ATC_CLA,
    ir_pha_filter.PHA_GRD_CND,
    pha.PHA_PRS_IDE,
    pha.PHA_PRS_C13,
    pha.PHA_DEC_TOP,
    pha.PHA_ACT_QSN,
    pha.PHA_DEC_QSU
FROM er_prs_f prs
    INNER JOIN ER_PHA_F pha
        ON pha.FLX_DIS_DTD = prs.FLX_DIS_DTD
            AND pha.FLX_TRT_DTD = prs.FLX_TRT_DTD
            AND pha.FLX_EMT_TYP = prs.FLX_EMT_TYP
            AND pha.FLX_EMT_NUM = prs.FLX_EMT_NUM
            AND pha.FLX_EMT_ORD = prs.FLX_EMT_ORD
            AND pha.ORG_CLE_NUM = prs.ORG_CLE_NUM
            AND pha.DCT_ORD_NUM = prs.DCT_ORD_NUM
            AND pha.PRS_ORD_NUM = prs.PRS_ORD_NUM
            AND pha.REM_TYP_AFF = prs.REM_TYP_AFF
    INNER JOIN {ir_pha_r_filtered_name} ir_pha_filter
        ON ir_pha_filter.PHA_CIP_C13 = pha.PHA_PRS_C13
    LEFT JOIN ER_ETE_F ete
        ON ete.FLX_DIS_DTD = prs.FLX_DIS_DTD
            AND	ete.FLX_TRT_DTD = prs.FLX_TRT_DTD
            AND	ete.FLX_EMT_TYP = prs.FLX_EMT_TYP
            AND	ete.FLX_EMT_NUM = prs.FLX_EMT_NUM
            AND	ete.FLX_EMT_ORD = prs.FLX_EMT_ORD
            AND	ete.ORG_CLE_NUM = prs.ORG_CLE_NUM
            AND	ete.DCT_ORD_NUM = prs.DCT_ORD_NUM
            AND	ete.PRS_ORD_NUM = prs.PRS_ORD_NUM
            AND	ete.REM_TYP_AFF = prs.REM_TYP_AFF
WHERE (
    prs.FLX_DIS_DTD >= DATE '{dis_dtd_start}'
      AND prs.FLX_DIS_DTD < DATE '{dis_dtd_end}'
    )
    AND (
    prs.exe_soi_dtd >= DATE '{formatted_start_date}'
      AND prs.exe_soi_dtd <= DATE '{formatted_end_date}')
    AND prs.DPN_QLF <> 71
    AND prs.CPL_MAJ_TOP < 2
    AND (ete.ETE_IND_TAA <> 1 OR ete.ETE_IND_TAA IS NULL)"
  dis_dtd_lag_months <- 6
  dis_dtd_end_date <-
    end_date |>
    lubridate::add_with_rollback(months(dis_dtd_lag_months)) |>
    lubridate::floor_date("months")
  flux_start_month <- max(1, lubridate::month(start_date))
  dis_dtd_start_date <- lubridate::make_date(
    year = lubridate::year(start_date),
    month = flux_start_month,
    day = 1
  )
  flx_dates <- seq(
    as.Date(dis_dtd_start_date),
    as.Date(dis_dtd_end_date),
    "month"
  )
  for (i in seq_along(flx_dates)) {
    # assign flx_date to be taken into account in glued sql_drug_query
    dis_dtd_start <- as.Date(flx_dates[[i]]) # nolint
    dis_dtd_end <- dis_dtd_start |>
      lubridate::add_with_rollback(months(1)) |>
      lubridate::floor_date("months")
    query <- glue::glue(sql_drug_query)
    print(glue::glue("-flux: {dis_dtd_start} to {dis_dtd_end}"))
    if (i == 1) {
      DBI::dbExecute(
        conn,
        glue::glue("CREATE TABLE {output_table_name} AS {query}")
      )
    } else {
      DBI::dbExecute(
        conn,
        glue::glue("INSERT INTO {output_table_name} {query}")
      )
    }
  }
  message(glue::glue("Results saved to table {output_table_name} in Oracle."))

  # Cleaning
  DBI::dbRemoveTable(conn, ir_pha_r_filtered_name)
  if (connection_opened) {
    DBI::dbDisconnect(conn)
  }
}
#' Initialisation de la connexion à la base de données.
#'
#' @return dbConnection Connexion à la base de données oracle
#'
#' @export
#' @family utils
connect_oracle <- function() {
  require(ROracle)
  Sys.setenv(TZ = "Europe/Paris")
  Sys.setenv(ORA_SDTZ = "Europe/Paris")
  drv <- DBI::dbDriver("Oracle")
  conn <- DBI::dbConnect(drv, dbname = "IPIAMPR2.WORLD")
  conn
}

#' Initialisation de la connexion à la base de données duckdb.
#'
#' Utilisation pour le testing uniquement. Si le code s'exécute en dehors du
#' portail, il faut initier une connexion duckdb pour effectuer les tests.
#'
#' @return dbConnection Connexion à la base de données duckdb
#'
#' @export
#' @family utils
connect_duckdb <- function(db_dir = NULL) {
  if (is.null(db_dir)) {
    db_dir <- ":memory:"
  }
  logger:::log_info(
    glue::glue("Initialisation d'une connexion duckdb à {db_dir}.")
  )
  conn <- DBI::dbConnect(duckdb::duckdb(), db_dir)

  # Generate fake user_synonyms table for testing: used in all er_prs_f
  # functions
  user_synonyms <- data.frame(
    SYNONYM_NAME = c("ER_PRS_F_2009", "ER_PRS_F_2010")
  )
  DBI::dbWriteTable(conn, "user_synonyms", user_synonyms, overwrite = TRUE)
  conn
}

#' Création d'une table à partir d'une requête SQL.
#' @details
#' La fonction crée une table sous Oracle à partir d'une requête SQL.
#' Si la table `output_table_name` existe déjà, elle est écrasée si
#' le paramètre `overwrite` est TRUE.
#' @param conn Connexion à la base de données
#' @param output_table_name Nom de la table de sortie
#' @param query Requête SQL
#' @param overwrite Logical. Indique si la table `output_table_name`
#' doit être écrasée dans le cas où elle existe déjà.
#' @return NULL
#'
#' @export
#' @family utils
create_table_from_query <- function(
  conn = NULL,
  output_table_name = NULL,
  query = NULL,
  overwrite = FALSE
) {
  stopifnot(
    !DBI::dbExistsTable(conn, output_table_name) ||
      (DBI::dbExistsTable(conn, output_table_name) && overwrite)
  )
  if (DBI::dbExistsTable(conn, output_table_name) && overwrite) {
    DBI::dbRemoveTable(conn, output_table_name)
  }
  query <- dbplyr::sql_render(query)
  DBI::dbExecute(
    conn,
    glue::glue(
      "CREATE TABLE {output_table_name} AS {query}"
    )
  )
}

#' Insertion des résultats d'une requête SQL dans une table existante.
#' @param conn Connexion à la base de données
#' @param output_table_name Nom de la table de sortie
#' @param query Requête SQL
#' @return NULL
#'
#' @export
#' @family utils
insert_into_table_from_query <- function(
  conn = NULL,
  output_table_name = NULL,
  query = NULL
) {
  stopifnot(DBI::dbExistsTable(conn, output_table_name))
  query <- dbplyr::sql_render(query)
  DBI::dbExecute(
    conn,
    glue::glue("INSERT INTO {output_table_name} {query}")
  )
}


#' Récupération de l'année non archivée la plus ancienne de la table ER_PRS_F.
#' @param conn Connexion à la base de données
#' @return Année non archivée la plus ancienne
#'
#' @export
#' @family utils
get_first_non_archived_year <- function(conn) {
  user_synonyms <- DBI::dbGetQuery(
    conn,
    "SELECT synonym_name
      FROM user_synonyms WHERE synonym_name LIKE 'ER_PRS_F_%'"
  )
  max_archived_year <-
    sub("ER_PRS_F_", "", x = user_synonyms$SYNONYM_NAME, fixed = TRUE) |>
    as.numeric() |>
    max()
  max_archived_year + 1
}

#' Récupération des statistiques des tables
#' @param conn Connexion à la base de données
#' @param table Chaine de caractère indiquant le nom d'une table
#' @references https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_STATS.html#GUID-CA6A56B9-0540-45E9-B1D7-D78769B7714C #nolint
#' @return NULL
#' @export
#' @family utils
gather_table_stats <- function(conn, table) {
  user <- DBI::dbGetQuery(conn, "SELECT user FROM dual")
  user <- DBI::dbQuoteIdentifier(conn, user$USER)
  DBI::dbExecute(
    conn,
    "BEGIN DBMS_STATS.GATHER_TABLE_STATS(:1, :2); END;",
    data = data.frame(user, table)
  )
}


parallelize_query_by_flx_month <- function(
  conn,
  start_date,
  end_date,
  query_builder_function,
  query_builder_kwargs,
  dis_dtd_lag_months = 6,
  r_cluster_cores = 1
) {
  # Date stuff
  ## Healthcare dates
  start_year <- lubridate::year(start_date)
  start_month <- lubridate::month(start_date)
  formatted_start_date <- format(start_date, "%Y-%m-%d")
  formatted_end_date <- format(end_date, "%Y-%m-%d")
  ## Flux dates: adding a lag
  dis_dtd_end_date <- end_date |>
    lubridate::add_with_rollback(months(dis_dtd_lag_months)) |>
    lubridate::floor_date("months")
  dis_dtd_end_month <- lubridate::month(format(dis_dtd_end_date, "%Y-%m-%d"))
  end_year <- lubridate::year(dis_dtd_end_date)

  months_to_process <- list()
  month_index <- 1
  for (year in start_year:end_year) {
    flux_start_month <- 1
    flux_end_month <- 12
    if (year == end_year) {
      flux_end_month <- dis_dtd_end_month
    }
    # do not query months before the start date
    if (year == start_year) {
      flux_start_month <- max(1, start_month)
    }

    for (month in c(flux_start_month:flux_end_month)) {
      is_first_month <- (year == start_year && month == flux_start_month)

      months_to_process[[month_index]] <- c(
        list(
          dis_dtd_year = year,
          dis_dtd_month = month,
          is_first_month = is_first_month,
          formatted_start_date = formatted_start_date,
          formatted_end_date = formatted_end_date,
          end_year = end_year
        ),
        query_builder_kwargs
      )
      month_index <- month_index + 1
    }
  }
  if (!is.null(r_cluster_cores) && r_cluster_cores > 1) {
    logger::log_info(glue::glue(
      "Starting parallel processing with {r_cluster_cores} cores"
    ))

    cl <- parallel::makeCluster(r_cluster_cores)
    on.exit(parallel::stopCluster(cl), add = TRUE)

    # Export packages and fonctions to workers
    parallel::clusterEvalQ(cl, {
      # TODO: should not be necessary since prefix usage in query_builder_function.
      library(dplyr)
      library(dbplyr)
      library(glue)
      library(DBI)
      library(lubridate)
      source(here::here("sndsTools.R"))
      is_portail <- constants_snds()$is_portail
      if (!is_portail) {
        # Export the same Oracle connexion to workers
        conn <<- connect_duckdb()
      } else {
        conn <<- connect_oracle()
      }
    })

    # Export to each worker the builder function
    parallel::clusterExport(
      cl,
      "query_builder_function",
      envir = environment()
    )

    # First month to create the table
    first_month_params <- months_to_process[[1]]
    first_month_params$conn <- conn
    query_builder_function(first_month_params)

    # Process the other months in parallel
    parallel::parLapply(
      cl,
      months_to_process[-1],
      query_builder_function
    )

    # Close connexions in each worker (? Necessary?)
    parallel::clusterEvalQ(cl, {
      DBI::dbDisconnect(conn)
    })

    logger::log_info("Parallel processing completed")
  } else {
    #
    logger::log_info("Starting sequential processing")
    months_to_process_with_conn <- lapply(months_to_process, function(m) {
      m$conn <- conn
      m
    })
    invisible(lapply(
      months_to_process_with_conn,
      query_builder_function
    ))
  }
}
