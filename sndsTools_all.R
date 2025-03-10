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
#' sont remontés à 6 mois](https://documentation-snds.health-data-hub.fr/snds/formation_snds/initiation/schema_relationnel_snds.html#_3-3-2-2-dates) #nolint
#' c'est-à-dire pour `dis_dtd_lag_months = 6`.
#'
#' Un guide sur l'activité des médecins libéraux est disponibles sur la page
#' [Activité des médecins
#' libéraux](https://documentation-snds.health-data-hub.fr/snds/fiches/activite_medecins.html#contexte). #nolint
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
#' disponibles sur la page ["Cibler selon les natures de
#' prestations"](https://documentation-snds.health-data-hub.fr/snds/fiches/prestation.html) de la documentation SNDS. Défaut à `NULL`. #nolint
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
extract_consultations_erprsf <- function(start_date,
                                         end_date,
                                         pse_spe_filter = NULL,
                                         prestation_filter = NULL,
                                         dis_dtd_lag_months = 6,
                                         patients_ids_filter = NULL,
                                         output_table_name = NULL,
                                         conn = NULL) {
  stopifnot(
    !is.null(start_date), !is.null(end_date),
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
      glue::glue("
      Extracting consultations
      from all specialties among
      {paste(pse_spe_filter, collapse = ' or ')}...")
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
    pb$tick(tokens = list(
      year1 = year,
      year2 = start_year,
      year3 = end_year
    ))
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
      dis_dtd_condition <- glue::glue("FLX_DIS_DTD BETWEEN DATE '{year}-02-01'
      AND DATE '{year + 1}-01-01'")
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
        # rémontée pour information, cette activité est mesurée par ailleurs
        # pour les établissements de santé dans le champ de la SAE
        (PRS_DPN_QLP != 71 | is.na(PRS_DPN_QLP)),
        # Suppression des ACE pour information
        (CPL_MAJ_TOP < 2),
        # Suppression des majorations
        (CPL_AFF_COD != 16),
        # Suppression des participations forfaitaires!(PSE_STJ_COD %in% c(61,
        # 62, 63, 64, 69)), Suppression des prestations de professionneles
        # exécutants salariés (impact négligeable)
        PRS_ACT_QTE > 0
      )

    cols_to_select <- c(
      "EXE_SOI_DTD",
      "PSE_SPE_COD",
      "PFS_EXE_NUM",
      "PRS_NAT_REF",
      "PRS_ACT_QTE",
      "BEN_RNG_GEM"
    )
    query <- er_prs_f_clean |>
      dplyr::filter(
        PRS_NAT_REF %in% prestation_filter,
        PSE_SPE_COD %in% pse_spe_filter
      ) |>
      dplyr::select(BEN_NIR_PSA, dplyr::all_of(cols_to_select)) |>
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

  return(result)
}
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
#' https://documentation-snds.health-data-hub.fr/snds/formation_snds/initiation/schema_relationnel_snds.html#_3-3-dcir # nolint
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
extract_drug_dispenses <- function(start_date, # nolint
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
  if (!is.null(atc_cod_starts_with_filter) && !is.null(cip13_cod_filter)) { # nolint
    drug_filter <- atc_conditions + " OR " + cip13_conditions
  } else if (!is.null(cip13_cod_filter) && is.null(atc_cod_starts_with_filter)) { # nolint
    drug_filter <- cip13_conditions
  } else if (!is.null(atc_cod_starts_with_filter) &&
    is.null(cip13_cod_filter)) { # nolint
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
          message(glue::glue("
          Premier mois requêté en date de flux
          à l'aide de la requête sql suivante :\n {query}"))
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
#' Extraction des consultations externes à l'hôpital (MCO).
#'
#' @description
#' Cette fonction permet d'extraire les consultations à l'hôpital en MCO. Les
#' consultations dont les dates `EXE_SOI_DTD` sont comprises entre start_date et
#' end_date sont extraites.
#'
#' @details
#' Si spe_codes est renseigné, seules les consultations des spécialités
#' correspondantes sont extraites.
#'
#' Si prestation_codes est renseigné, seules les consultations des prestations
#' correspondantes sont extraites.
#'
#' Si patients_ids est fourni, seules les délivrances de médicaments pour les
#' patients dont les identifiants sont dans patients_ids sont extraites.
#'
#' @param start_date Date La date de début de la période sur laquelle extraire
#' les consultations.
#' @param end_date Date La date de fin de la période sur laquelle extraire les
#' consultations.
#' @param spe_codes_filter character vector Optionnel. Les codes spécialités des
#' médecins effectuant les consultations à extraire. Si `spe_codes` n'est pas
#' fourni, les consultations de tous les spécialités sont extraites.
#' @param prestation_codes_filter character vector Optionnel. Les codes des
#' prestations à extraire. Si `prestation_codes` n'est pas fourni, les
#' consultations de tous les prestations sont extraites. Les codes des
#' prestations sont disponibles sur la page [actes et consultations externes de
#' la documentation
#' SNDS](https://documentation-snds.health-data-hub.fr/snds/fiches/actes_consult_externes.html#exemple-de-requetes-pour-analyse). #nolint
#' @param patient_ids_filter data.frame Optionnel. Un data.frame contenant les
#' paires d'identifiants des patients pour lesquels les consultations doivent
#' être extraites. Les colonnes de ce data.frame doivent être `BEN_IDT_ANO` et
#' `BEN_NIR_PSA` (en majuscules). Les `BEN_NIR_PSA` doivent être tous les
#' `BEN_NIR_PSA` associés aux `BEN_IDT_ANO` fournis. Si `patients_ids` n'est pas
#' fourni, les consultations de tous les patients sont extraites.
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
#' - patient_ids
#'   non nul)
#' - `NIR_ANO_17` : NIR anonymisé
#' - `EXE_SOI_DTD` : Date de la délivrance
#' - `ACT_COD` : Code de l'acte
#' - `EXE_SPE` : Code de spécialité du professionnel de soin prescripteur
#'
#' @examples
#' \dontrun{
#' extract_hospital_consultations(
#'   start_date = as.Date("2019-01-01"),
#'   end_date = as.Date("2019-12-31"),
#'   spe_codes = c("01", "02")
#' )
#' }
#' @export
extract_hospital_consultations <- function(start_date,
                                           end_date,
                                           spe_codes_filter = NULL,
                                           prestation_codes_filter = NULL,
                                           patient_ids_filter = NULL,
                                           output_table_name = NULL,
                                           conn = NULL) {
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
    try(DBI::dbRemoveTable(conn, patient_ids_table_name),
      silent = TRUE
    )
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
    pb$tick(tokens = list(
      year1 = year,
      year2 = start_year,
      year3 = end_year
    ))

    formatted_year <- sprintf("%02d", year %% 100)

    cstc <-
      dplyr::tbl(conn, glue::glue("T_MCO{formatted_year}CSTC")) |>
      filter(
        NIR_RET == "0",
        NAI_RET == "0",
        SEX_RET == "0",
        ENT_DAT_RET == "0",
        IAS_RET == "0"
      ) |>
      dplyr::select(ETA_NUM, SEQ_NUM, NIR_ANO_17, EXE_SOI_DTD) |>
      dplyr::distinct()

    fcstc <-
      dplyr::tbl(conn, glue::glue("T_MCO{formatted_year}FCSTC")) |>
      dplyr::select(ETA_NUM, SEQ_NUM, ACT_COD, EXE_SPE) |>
      dplyr::distinct()

    date_condition <- glue::glue("
    EXE_SOI_DTD <= DATE '{formatted_end_date}'
      AND EXE_SOI_DTD >= DATE '{formatted_start_date}'")
    ace <- cstc |>
      filter(dbplyr::sql(date_condition)) |>
      dplyr::left_join(fcstc, by = c("ETA_NUM", "SEQ_NUM")) |>
      dplyr::select(NIR_ANO_17, EXE_SOI_DTD, ACT_COD, EXE_SPE) |>
      dplyr::distinct()

    if (!is.null(spe_codes_filter)) {
      ace <- ace |>
        filter(EXE_SPE %in% spe_codes_filter)
    }

    if (!is.null(prestation_codes_filter)) {
      ace <- ace |>
        filter(ACT_COD %in% prestation_codes_filter)
    }

    if (!is.null(patient_ids_filter)) {
      patient_ids_table <- dplyr::tbl(conn, patient_ids_table_name)
      query <- patient_ids_table |>
        dplyr::inner_join(ace,
          by = c("BEN_NIR_PSA" = "NIR_ANO_17"),
          keep = TRUE
        )
      selected_columns <-
        c(
          "BEN_IDT_ANO",
          "NIR_ANO_17",
          "EXE_SOI_DTD",
          "ACT_COD",
          "EXE_SPE"
        )
    } else {
      query <- ace
      selected_columns <-
        c("NIR_ANO_17", "EXE_SOI_DTD", "ACT_COD", "EXE_SPE")
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

  return(result)
}
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
#'   https://documentation-snds.health-data-hub.fr/snds/fiches/beneficiaires_ald.html #nolint
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
    # nolint:
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
finess_out <- c(
  "130780521", "130783236", "130783293", "130784234", "130804297",
  "600100101", "750041543", "750100018", "750100042", "750100075",
  "750100083", "750100091", "750100109", "750100125", "750100166",
  "750100208", "750100216", "750100232", "750100273", "750100299",
  "750801441", "750803447", "750803454", "910100015", "910100023",
  "920100013", "920100021", "920100039", "920100047", "920100054",
  "920100062", "930100011", "930100037", "930100045", "940100027",
  "940100035", "940100043", "940100050", "940100068", "950100016",
  "690783154", "690784137", "690784152", "690784178", "690787478",
  "830100558"
)

build_dp_dr_conditions <- function(
    cim10_codes_starts_with = NULL, include_dr = NULL) {
  starts_with_conditions_dp <- sapply(
    cim10_codes_starts_with, function(code) glue("DGN_PAL LIKE '{code}%'")
  )
  if (include_dr) {
    starts_with_conditions_dr <- sapply(
      cim10_codes_starts_with, function(code) glue("DGN_REL LIKE '{code}%'")
    )
  } else {
    starts_with_conditions_dr <- NULL
  }
  starts_with_conditions <- c(
    starts_with_conditions_dp, starts_with_conditions_dr
  )
  combined_conditions <- paste(starts_with_conditions, collapse = " OR ")
  combined_conditions <- glue("({combined_conditions})")
  return(combined_conditions)
}

build_da_conditions <- function(cim10_codes_starts_with = NULL) {
  starts_with_conditions_da <- sapply(
    cim10_codes_starts_with, function(code) glue("ASS_DGN LIKE '{code}%'")
  )
  combined_conditions <- paste(starts_with_conditions_da, collapse = " OR ")
  combined_conditions <- glue("({combined_conditions})")
  return(combined_conditions)
}

normalize_column_number <- function(
    df = NULL, column_prefix = NULL, max_columns_number = NULL) {
  expected_cols <- paste(column_prefix, 1:max_columns_number, sep = "")

  missing_cols <- setdiff(expected_cols, names(df))
  df[missing_cols] <- NA

  excess_cols <- names(df)[str_detect(
    names(df), glue("^{column_prefix}\\d+$")
  ) & !names(df) %in% expected_cols]
  df <- df[, !(names(df) %in% excess_cols)]
  return(df)
}

extract_hospital_stays <- function(
    start_date = NULL,
    end_date = NULL,
    dp_cim10_codes_starts_with = NULL,
    or_dr_with_same_codes = NULL,
    or_da_with_same_codes = NULL,
    and_da_with_other_codes = NULL,
    da_cim10_codes_starts_with = NULL,
    ben_table_name = NULL,
    output_table_name = NULL,
    r_output_path = NULL) {
  conn <- connect_oracle() # Connect to database

  start_year <- lubridate::year(start_date)
  end_year <- lubridate::year(end_date)
  formatted_start_date <- format(start_date, "%Y-%m-%d")
  formatted_end_date <- format(end_date, "%Y-%m-%d")

  hospital_stays_list <- list()

  for (year in start_year:end_year) {
    start_time <- Sys.time()
    print(glue("Processing year: {year}"))
    formatted_year <- sprintf("%02d", year %% 100)
    if (!is.null(ben_table_name)) {
      ben <- tbl(conn, ben_table_name)
    }
    t_mco_b <- tbl(conn, glue("T_MCO{formatted_year}B"))
    t_mco_c <- tbl(conn, glue("T_MCO{formatted_year}C"))
    t_mco_d <- tbl(conn, glue("T_MCO{formatted_year}D"))
    t_mco_um <- tbl(conn, glue("T_MCO{formatted_year}UM"))

    dp_dr_conditions <- build_dp_dr_conditions(
      cim10_codes_starts_with = dp_cim10_codes_starts_with,
      include_dr = or_dr_with_same_codes
    )

    eta_num_rsa_num <- t_mco_b %>%
      filter(sql(dp_dr_conditions)) %>%
      select(ETA_NUM, RSA_NUM) %>%
      distinct()

    if (or_da_with_same_codes) {
      da_conditions <- build_da_conditions(
        cim10_codes_starts_with = dp_cim10_codes_starts_with
      )
      dp_dr_conditions <- build_dp_dr_conditions(
        cim10_codes_starts_with = dp_cim10_codes_starts_with, include_dr = TRUE
      )
      eta_num_rsa_num_da_d <- t_mco_d %>%
        filter(sql(da_conditions)) %>%
        select(ETA_NUM, RSA_NUM) %>%
        distinct()
      eta_num_rsa_num_da_um <- t_mco_um %>%
        filter(sql(dp_dr_conditions)) %>%
        select(ETA_NUM, RSA_NUM) %>%
        distinct()
      eta_num_rsa_num_da <- union(eta_num_rsa_num_da_d, eta_num_rsa_num_da_um)
      eta_num_rsa_num <- union(eta_num_rsa_num, eta_num_rsa_num_da)
    } else if (and_da_with_other_codes) {
      da_conditions <- build_da_conditions(
        cim10_codes_starts_with = da_cim10_codes_starts_with
      )
      dp_dr_conditions <- build_dp_dr_conditions(
        cim10_codes_starts_with = da_cim10_codes_starts_with,
        include_dr = TRUE
      )
      eta_num_rsa_num_da_d <- t_mco_d %>%
        filter(sql(da_conditions)) %>%
        select(ETA_NUM, RSA_NUM) %>%
        distinct()
      eta_num_rsa_num_da_um <- t_mco_um %>%
        filter(sql(dp_dr_conditions)) %>%
        select(ETA_NUM, RSA_NUM) %>%
        distinct()
      eta_num_rsa_num_da <- union(eta_num_rsa_num_da_d, eta_num_rsa_num_da_um)
      eta_num_rsa_num <- eta_num_rsa_num %>%
        inner_join(eta_num_rsa_num_da, by = c("ETA_NUM", "RSA_NUM"))
    }

    selected_cols <- c(
      "ETA_NUM", "RSA_NUM", "SEJ_NUM", "SEJ_NBJ", "NBR_DGN",
      "NBR_RUM", "NBR_ACT", "ENT_MOD", "ENT_PRV", "SOR_MOD",
      "SOR_DES", "DGN_PAL", "DGN_REL", "GRG_GHM", "BDI_DEP",
      "BDI_COD", "COD_SEX", "AGE_ANN", "AGE_JOU", "NIR_ANO_17",
      "EXE_SOI_DTD", "EXE_SOI_DTF", "FHO_RET", "NAI_RET",
      "NIR_RET", "PMS_RET", "SEJ_RET", "SEX_RET"
    )
    # SOR_ANN and SOR_MOI have been removed from the selected columns
    # because they are not always present in the tables

    if (year >= 2013) {
      selected_cols <- c(selected_cols, "DAT_RET", "COH_NAI_RET", "COH_SEX_RET")
    }

    tmp1 <- t_mco_b %>%
      inner_join(t_mco_c, by = c("ETA_NUM", "RSA_NUM")) %>%
      inner_join(eta_num_rsa_num, by = c("ETA_NUM", "RSA_NUM")) %>%
      select(all_of(selected_cols)) %>%
      filter(
        EXE_SOI_DTD >= TO_DATE(formatted_start_date, "YYYY-MM-DD") &
          EXE_SOI_DTD <= TO_DATE(formatted_end_date, "YYYY-MM-DD")
      ) %>%
      distinct()

    if (!is.null(ben_table_name)) {
      ben <- ben %>%
        select(BEN_IDT_ANO, BEN_NIR_PSA) %>%
        distinct()
      tmp1 <- tmp1 %>%
        inner_join(ben, by = c("NIR_ANO_17" = "BEN_NIR_PSA")) %>%
        select(-NIR_ANO_17)
    }

    selected_eta_num_rsa_num <- tmp1 %>%
      select(ETA_NUM, RSA_NUM) %>%
      distinct()

    tmp1 <- tmp1 %>%
      collect()


    selected_cols <- c("ETA_NUM", "RSA_NUM", "DGN_PAL", "DGN_REL")
    tmp1_um <- t_mco_um %>%
      inner_join(selected_eta_num_rsa_num, by = c("ETA_NUM", "RSA_NUM")) %>%
      select(all_of(selected_cols)) %>%
      distinct() %>%
      collect()

    tmp1_um_dp <- tmp1_um %>%
      select(ETA_NUM, RSA_NUM, DGN_PAL) %>%
      distinct() %>%
      group_by(ETA_NUM, RSA_NUM) %>%
      mutate(row_id = row_number()) %>%
      pivot_wider(
        names_from = row_id, values_from = DGN_PAL, names_prefix = "DGN_PAL_UM_"
      ) %>%
      ungroup()

    max_columns_dgn_pal_um <- 10
    tmp1_um_dp <- normalize_column_number(
      df = tmp1_um_dp,
      column_prefix = "DGN_PAL_UM_",
      max_columns_number = max_columns_dgn_pal_um
    )

    tmp1_um_dr <- tmp1_um %>%
      select(ETA_NUM, RSA_NUM, DGN_REL) %>%
      distinct() %>%
      group_by(ETA_NUM, RSA_NUM) %>%
      mutate(row_id = row_number()) %>%
      pivot_wider(
        names_from = row_id,
        values_from = DGN_REL,
        names_prefix = "DGN_REL_UM_"
      ) %>%
      ungroup()

    max_columns_dgn_rel_um <- 10
    tmp1_um_dr <- normalize_column_number(
      df = tmp1_um_dr,
      column_prefix = "DGN_REL_UM_",
      max_columns_number = max_columns_dgn_rel_um
    )

    tmp_um <- tmp1_um_dp %>%
      left_join(tmp1_um_dr, by = c("ETA_NUM", "RSA_NUM"))


    selected_cols <- c("ETA_NUM", "RSA_NUM", "ASS_DGN")
    tmp1_d <- t_mco_d %>%
      inner_join(selected_eta_num_rsa_num, by = c("ETA_NUM", "RSA_NUM")) %>%
      select(all_of(selected_cols)) %>%
      distinct() %>%
      collect()

    tmp2_d <- bind_rows(
      tmp1_d,
      tmp1_um %>%
        select(ETA_NUM, RSA_NUM, DGN_PAL) %>%
        rename(ASS_DGN = DGN_PAL) %>%
        distinct(),
      tmp1_um %>%
        select(ETA_NUM, RSA_NUM, DGN_REL) %>%
        rename(ASS_DGN = DGN_REL) %>%
        distinct()
    ) %>%
      distinct()

    selected_cols <- c("ETA_NUM", "RSA_NUM", "DGN_PAL")
    tmp3_d <- tmp1 %>%
      select(all_of(selected_cols)) %>%
      distinct() %>%
      left_join(tmp2_d, by = c("ETA_NUM", "RSA_NUM")) %>%
      filter(!(ASS_DGN == DGN_PAL | tolower(ASS_DGN) == "xxxx")) %>%
      select(-DGN_PAL) %>%
      group_by(ETA_NUM, RSA_NUM) %>%
      mutate(row_id = row_number()) %>%
      pivot_wider(
        names_from = row_id,
        values_from = ASS_DGN,
        names_prefix = "ASS_DGN_"
      ) %>%
      ungroup()

    max_columns_da <- 20
    tmp3_d <- normalize_column_number(
      df = tmp3_d,
      column_prefix = "ASS_DGN_",
      max_columns_number = max_columns_da
    )

    tmp3 <- tmp1 %>%
      left_join(tmp_um, by = c("ETA_NUM", "RSA_NUM")) %>%
      left_join(tmp3_d, by = c("ETA_NUM", "RSA_NUM"))

    tmp4 <- tmp3 %>%
      filter(
        NIR_RET == 0,
        NAI_RET == 0,
        SEX_RET == 0,
        SEJ_RET == 0,
        FHO_RET == 0,
        PMS_RET == 0
      ) %>%
      select(
        -NIR_RET,
        -NAI_RET,
        -SEX_RET,
        -SEJ_RET,
        -FHO_RET,
        -PMS_RET
      )

    if (year >= 2013) {
      tmp4 <- tmp4 %>%
        filter(
          COH_NAI_RET == 0,
          COH_SEX_RET == 0
        ) %>%
        select(
          -COH_NAI_RET,
          -COH_SEX_RET
        )
    }

    hospital_stays <- tmp4 %>%
      filter(
        GRG_GHM != 90,
        !(ETA_NUM %in% finess_out)
      )

    hospital_stays_list <- append(hospital_stays_list, list(hospital_stays))

    end_time <- Sys.time()
    print(
      glue::glue("
      Time taken for year {year}:
      {round(difftime(end_time, start_time, units='mins'),1)} mins.")
    )
  }

  hospital_stays <- bind_rows(hospital_stays_list)


  if (!is.null(r_output_path)) {
    saveRDS(hospital_stays, glue::glue("
    {r_output_path}/{tolower(output_table_name)}.RDS"))
  }

  dbDisconnect(conn)

  return(hospital_stays)
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
sql_extract_drug_dispenses <- function(start_date, # nolint
                                       end_date,
                                       output_table_name,
                                       atc_cod_starts_with_filter = NULL,
                                       cip13_cod_filter = NULL,
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
  # Format the dates (used in the glued SQL query)
  formatted_start_date <- format(start_date, "%Y-%m-%d") # nolint
  formatted_end_date <- format(end_date, "%Y-%m-%d") # nolint

  # Create the subset of IR_PHA_V table that should be joined to the DCIR
  # tables(same code as extract_drug_dispenses)
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
  if (!is.null(atc_cod_starts_with_filter) && !is.null(cip13_cod_filter)) { # nolint
    drug_filter <- atc_conditions + " OR " + cip13_conditions
  } else if (!is.null(cip13_cod_filter) && is.null(atc_cod_starts_with_filter)) { # nolint
    drug_filter <- cip13_conditions
  } else if (!is.null(atc_cod_starts_with_filter) && is.null(cip13_cod_filter)) { # nolint
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
    as.Date(dis_dtd_start_date), as.Date(dis_dtd_end_date), "month"
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
        conn, glue::glue("CREATE TABLE {output_table_name} AS {query}")
      )
    } else {
      DBI::dbExecute(
        conn, glue::glue("INSERT INTO {output_table_name} {query}")
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
connect_duckdb <- function() {
  print(
    "Le code ne s'exécute pas sur le portail CNAM.
    Initialisation d'une connexion duckdb en mémoire."
  )
  conn <- DBI::dbConnect(duckdb::duckdb(), ":memory:")

  # Generate fake user_synonyms table for testing: used in all er_prs_f
  # functions
  user_synonyms <- data.frame(
    SYNONYM_NAME = c("ER_PRS_F_2009", "ER_PRS_F_2010")
  )
  DBI::dbWriteTable(conn, "user_synonyms", user_synonyms)
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
create_table_from_query <- function(conn = NULL,
                                    output_table_name = NULL,
                                    query = NULL,
                                    overwrite = FALSE) {
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
insert_into_table_from_query <- function(
    conn = NULL,
    output_table_name = NULL,
    query = NULL) {
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
gather_table_stats <- function(conn, table) {
  user <- DBI::dbGetQuery(conn, "SELECT user FROM dual")
  user <- DBI::dbQuoteIdentifier(conn, user$USER)
  DBI::dbExecute(
    conn,
    "BEGIN DBMS_STATS.GATHER_TABLE_STATS(:1, :2); END;",
    data = data.frame(user, table)
  )
}
