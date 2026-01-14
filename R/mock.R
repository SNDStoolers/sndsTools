#' Fonctions pour créer des données factices pour le tutoriel sndsTools
#'
#' Ce fichier contient des fonctions pour générer des données d'exemple
#' basées sur les structures utilisées dans les tests du package sndsTools.
#'
#' @author Matthieu Doutreligne

#' Créer des données factices pour les patients
#'
#' @param n_patients Nombre de patients à générer
#' @return data.frame avec BEN_IDT_ANO et BEN_NIR_PSA
#' @export
create_mock_patients_ids <- function(n_patients = 100) {
  set.seed(123) # Pour la reproductibilité

  data.frame(
    BEN_IDT_ANO = seq_len(n_patients),
    BEN_NIR_PSA = seq(from = 10000, length.out = n_patients)
  )
}

#' Créer des données factices pour IR_BEN_R (référentiel bénéficiaires)
#'
#' @param patients_ids data.frame avec BEN_IDT_ANO et BEN_NIR_PSA
#' @return data.frame avec toutes les colonnes du référentiel bénéficiaires
#' @export
create_mock_ir_ben_r <- function(patients_ids = create_mock_patients_ids()) {
  set.seed(123)
  n <- nrow(patients_ids)

  # Ajouter quelques doublons pour certains patients (cas réels)
  additional_rows <- sample(seq_len(n), size = min(5, n), replace = FALSE)
  extended_patients <- dplyr::bind_rows(
    patients_ids,
    patients_ids[additional_rows, ] |>
      dplyr::mutate(BEN_NIR_PSA = BEN_NIR_PSA + 50000, BEN_RNG_GEM = 2)
  )

  extended_patients |>
    dplyr::mutate(
      BEN_RNG_GEM = ifelse(is.na(BEN_RNG_GEM), 1, BEN_RNG_GEM),
      BEN_NIR_ANO = paste0("NIR", sprintf("%06d", BEN_IDT_ANO)),
      BEN_CDI_NIR = sample(
        c("00", "01"),
        dplyr::n(),
        replace = TRUE,
        prob = c(0.9, 0.1)
      ),
      BEN_NAI_ANN = sample(1950:2000, dplyr::n(), replace = TRUE),
      BEN_NAI_MOI = sample(1:12, dplyr::n(), replace = TRUE),
      BEN_SEX_COD = sample(c(1, 2), dplyr::n(), replace = TRUE),
      BEN_ORG_AFF = sample(
        c("01", "02", "03"),
        dplyr::n(),
        replace = TRUE,
        prob = c(0.7, 0.2, 0.1)
      )
    )
}

#' Créer des données factices pour les délivrances de médicaments (ER_PRS_F)
#'
#' @param patients_ids data.frame avec BEN_IDT_ANO et BEN_NIR_PSA
#' @param start_date Date de début
#' @param end_date Date de fin
#' @param n_dispenses Nombre de délivrances par patient (moyenne)
#' @return data.frame avec les données de délivrances
#' @export
create_mock_er_prs_f <- function(
  patients_ids = create_mock_patients_ids(),
  start_date = as.Date("2020-01-01"),
  end_date = as.Date("2020-12-31"),
  n_dispenses = 5
) {
  set.seed(123)

  # Créer les clés de jointure DCIR
  n_total_dispenses <- nrow(patients_ids) * n_dispenses

  dcir_keys <- data.frame(
    DCT_ORD_NUM = seq_len(n_total_dispenses),
    FLX_DIS_DTD = sample(
      seq(start_date, end_date, by = "day"),
      n_total_dispenses,
      replace = TRUE
    ),
    FLX_EMT_ORD = sample(1:5, n_total_dispenses, replace = TRUE),
    FLX_EMT_NUM = sample(1:10, n_total_dispenses, replace = TRUE),
    FLX_EMT_TYP = sample(1:3, n_total_dispenses, replace = TRUE),
    FLX_TRT_DTD = sample(
      seq(start_date - 30, end_date, by = "day"),
      n_total_dispenses,
      replace = TRUE
    ),
    ORG_CLE_NUM = sample(1:1000, n_total_dispenses, replace = TRUE),
    PRS_ORD_NUM = sample(1:50, n_total_dispenses, replace = TRUE),
    REM_TYP_AFF = sample(1:5, n_total_dispenses, replace = TRUE)
  )

  # Générer les données des prescriptions
  patients_expanded <- patients_ids[
    rep(seq_len(nrow(patients_ids)), each = n_dispenses),
  ]

  dplyr::bind_cols(
    data.frame(
      BEN_NIR_PSA = patients_expanded$BEN_NIR_PSA,
      BEN_RNG_GEM = 1,
      EXE_SOI_DTD = sample(
        seq(start_date, end_date, by = "day"),
        n_total_dispenses,
        replace = TRUE
      ),
      PSP_SPE_COD = sample(
        c("01", "02", "03", "22", "32", "34"),
        n_total_dispenses,
        replace = TRUE
      ),
      DPN_QLF = sample(
        c(0, 71),
        n_total_dispenses,
        replace = TRUE,
        prob = c(0.95, 0.05)
      ),
      PRS_DPN_QLP = sample(
        c(0, 71),
        n_total_dispenses,
        replace = TRUE,
        prob = c(0.95, 0.05)
      ),
      CPL_MAJ_TOP = sample(
        c(0, 1, 2),
        n_total_dispenses,
        replace = TRUE,
        prob = c(0.9, 0.08, 0.02)
      ),
      CPL_AFF_COD = sample(
        1:30,
        n_total_dispenses,
        replace = TRUE
      ),
      PRS_ACT_QTE = sample(1:10, n_total_dispenses, replace = TRUE),
      PSE_SPE_COD = sample(
        c("01", "02", "03", "04", "05"),
        n_total_dispenses,
        replace = TRUE
      ),
      PFS_EXE_NUM = sample(1:5000, n_total_dispenses, replace = TRUE),
      PRS_NAT_REF = sample(
        c(0, 1),
        n_total_dispenses,
        replace = TRUE,
        prob = c(0.9, 0.1)
      )
    ),
    dcir_keys
  )
}

#' Créer des données factices pour les médicaments délivrés (ER_PHA_F)
#'
#' @param er_prs_f data.frame des prescriptions
#' @return data.frame avec les données des médicaments
#' @export
create_mock_er_pha_f <- function(er_prs_f) {
  set.seed(123)

  #nolint start
  # Codes CIP13 d'antihypertenseurs fictifs
  antihypertenseur_cips <- c(
    "3400932026555", # C02 - Antihypertenseur central
    "3400932725847", # C03 - Diurétique
    "3400930219874", # C07 - Bêta-bloquant
    "3400936267343", # C08 - Inhibiteur calcique
    "3400955555555", # C09 - IEC/ARA2
    "3400966666666", # C09 - IEC/ARA2
    "3400977777777" # C07 - Bêta-bloquant
  )
  #nolint end

  n_rows <- nrow(er_prs_f)

  er_prs_f |>
    dplyr::select(dplyr::all_of(c(
      "DCT_ORD_NUM",
      "FLX_DIS_DTD",
      "FLX_EMT_ORD",
      "FLX_EMT_NUM",
      "FLX_EMT_TYP",
      "FLX_TRT_DTD",
      "ORG_CLE_NUM",
      "PRS_ORD_NUM",
      "REM_TYP_AFF"
    ))) |>
    dplyr::mutate(
      PHA_PRS_C13 = sample(antihypertenseur_cips, n_rows, replace = TRUE),
      PHA_ACT_QSN = sample(
        c(1, 2, 3),
        n_rows,
        replace = TRUE,
        prob = c(0.7, 0.2, 0.1)
      )
    )
}

#' Créer des données factices pour le référentiel médicaments (IR_PHA_R)
#'
#' @return data.frame avec les codes CIP13 et ATC
#' @export
create_mock_ir_pha_r <- function() {
  data.frame(
    PHA_CIP_C13 = c(
      "3400932026555", # C02 - Antihypertenseur central
      "3400932725847", # C03 - Diurétique thiazidique
      "3400930219874", # C07 - Bêta-bloquant
      "3400936267343", # C08 - Inhibiteur calcique
      "3400955555555", # C09 - IEC
      "3400966666666", # C09 - ARA2
      "3400977777777" # C07 - Bêta-bloquant sélectif
    ),
    PHA_ATC_CLA = c(
      "C02AC01", # Clonidine
      "C03AA03", # Hydrochlorothiazide
      "C07AB02", # Metoprolol
      "C08CA01", # Amlodipine
      "C09AA02", # Enalapril
      "C09CA01", # Losartan
      "C07AB07" # Bisoprolol
    )
  )
}

#' Créer des données factices pour les ALD (IR_IMB_R)
#'
#' @param patients_ids data.frame avec BEN_IDT_ANO et BEN_NIR_PSA
#' @param start_date Date de début
#' @param end_date Date de fin
#' @return data.frame avec les données d'ALD
#' @export
create_mock_ir_imb_r <- function(
  patients_ids = create_mock_patients_ids(),
  start_date = as.Date("2020-01-01"),
  end_date = as.Date("2020-12-31")
) {
  set.seed(123)

  # Codes ICD-10 cardiovasculaires
  cv_codes <- c(
    "I10",
    "I11",
    "I12",
    "I13",
    "I15",
    "I20",
    "I21",
    "I22",
    "I25",
    "I50",
    "I60",
    "I65",
    "I70",
    "I80"
  )

  # Environ 30% des patients ont une ALD CV
  patients_with_ald <- dplyr::sample_n(
    patients_ids,
    size = round(0.3 * nrow(patients_ids))
  )

  # Certains patients peuvent avoir plusieurs ALD
  n_ald_per_patient <- sample(
    c(1, 2, 3),
    nrow(patients_with_ald),
    replace = TRUE,
    prob = c(0.7, 0.25, 0.05)
  )

  patients_expanded <- patients_with_ald[
    rep(seq_len(nrow(patients_with_ald)), times = n_ald_per_patient),
  ]

  patients_expanded |>
    dplyr::mutate(
      IMB_ALD_DTD = sample(
        seq(start_date - 365, start_date, by = "day"),
        dplyr::n(),
        replace = TRUE
      ),
      IMB_ALD_DTF = IMB_ALD_DTD +
        sample(30:1095, dplyr::n(), replace = TRUE), # 1 mois à 3 ans
      IMB_ALD_NUM = sample(
        c(1, 3, 5, 8, 12, 13, 30),
        dplyr::n(),
        replace = TRUE
      ),
      MED_MTF_COD = sample(cv_codes, dplyr::n(), replace = TRUE),
      IMB_ETM_NAT = sample(
        c("01", "02", "03", "11", "12", "13"),
        dplyr::n(),
        replace = TRUE,
        prob = c(0.7, 0.15, 0.1, 0.02, 0.02, 0.01)
      )
    ) |>
    dplyr::select(
      BEN_NIR_PSA,
      IMB_ALD_DTD,
      IMB_ALD_DTF,
      IMB_ALD_NUM,
      MED_MTF_COD,
      IMB_ETM_NAT
    )
}

#' Créer des données factices pour les séjours MCO (tables B, C, D, UM)
#'
#' @param patients_ids data.frame avec BEN_IDT_ANO et BEN_NIR_PSA
#' @param year Année des séjours
#' @param start_date Date de début
#' @param end_date Date de fin
#' @return list avec les 4 tables MCO (B, C, D, UM)
#' @export
create_mock_mco_tables <- function(
  patients_ids = create_mock_patients_ids(),
  year = 2020,
  start_date = as.Date("2020-01-01"),
  end_date = as.Date("2020-12-31")
) {
  set.seed(123)

  # Environ 20% des patients ont des séjours hospitaliers
  patients_with_stays <- dplyr::sample_n(
    patients_ids,
    size = round(0.2 * nrow(patients_ids))
  )

  # 1-3 séjours par patient avec séjour
  n_stays_per_patient <- sample(
    c(1, 2, 3),
    nrow(patients_with_stays),
    replace = TRUE,
    prob = c(0.7, 0.25, 0.05)
  )

  patients_expanded <- patients_with_stays[
    rep(seq_len(nrow(patients_with_stays)), times = n_stays_per_patient),
  ]

  n_total_stays <- nrow(patients_expanded)

  # Codes diagnostics cardiovasculaires (incluant les codes AVC)
  cv_dp_codes <- c(
    "I10",
    "I11",
    "I20",
    "I21",
    "I25",
    "I50",
    "I80",
    "I61",
    "I62",
    "I63",
    "I64"
  )
  cv_dr_codes <- c(
    "I10",
    "I11",
    "I12",
    "I48",
    "I70",
    "I80",
    "E78",
    "I61",
    "I62",
    "I63",
    "I64"
  )
  cv_da_codes <- c(
    "E78",
    "E11",
    "I48",
    "I70",
    "N18",
    "Z95",
    "I61",
    "I62",
    "I63",
    "I64"
  )

  # Table B (données administratives du séjour)
  mco_b <- data.frame(
    ETA_NUM = sample(100000:999999, n_total_stays, replace = TRUE),
    RSA_NUM = seq_len(n_total_stays),
    SEJ_NUM = seq_len(n_total_stays),
    SEJ_NBJ = sample(
      1:20,
      n_total_stays,
      replace = TRUE,
      prob = c(rep(0.3 / 5, 5), rep(0.7 / 15, 15))
    ),
    NBR_DGN = sample(
      0:10,
      n_total_stays,
      replace = TRUE,
      prob = c(0.1, 0.2, 0.3, 0.2, 0.1, rep(0.02, 6))
    ),
    NBR_RUM = sample(
      1:5,
      n_total_stays,
      replace = TRUE,
      prob = c(0.6, 0.25, 0.1, 0.04, 0.01)
    ),
    NBR_ACT = sample(0:20, n_total_stays, replace = TRUE),
    ENT_MOD = sample(
      c("6", "7", "8"),
      n_total_stays,
      replace = TRUE,
      prob = c(0.7, 0.2, 0.1)
    ),
    ENT_PRV = sample(
      c("1", "2", "3", "4", "5", "6", "7", "8"),
      n_total_stays,
      replace = TRUE
    ),
    SOR_MOD = sample(
      c("6", "7", "8", "9"),
      n_total_stays,
      replace = TRUE,
      prob = c(0.6, 0.15, 0.15, 0.1)
    ),
    SOR_DES = sample(
      c("1", "2", "3", "4", "5", "6", "7"),
      n_total_stays,
      replace = TRUE
    ),
    DGN_PAL = sample(cv_dp_codes, n_total_stays, replace = TRUE),
    DGN_REL = sample(
      c(cv_dr_codes, NA),
      n_total_stays,
      replace = TRUE,
      prob = c(rep(0.7 / length(cv_dr_codes), length(cv_dr_codes)), 0.3)
    ),
    GRG_GHM = paste0(
      sample(
        c("05C", "05K", "05M", "06C", "06M"),
        n_total_stays,
        replace = TRUE
      ),
      sample(10:99, n_total_stays, replace = TRUE)
    ),
    BDI_DEP = sample(sprintf("%02d", 1:95), n_total_stays, replace = TRUE),
    BDI_COD = paste0(
      sample(sprintf("%02d", 1:95), n_total_stays, replace = TRUE),
      sample(sprintf("%03d", 1:999), n_total_stays, replace = TRUE)
    ),
    COD_SEX = sample(c("1", "2"), n_total_stays, replace = TRUE),
    AGE_ANN = pmax(
      18,
      pmin(100, round(rnorm(n_total_stays, mean = 65, sd = 15)))
    ),
    AGE_JOU = sample(0:364, n_total_stays, replace = TRUE)
  )

  # Table C (données patients et temporelles)
  mco_c <- data.frame(
    ETA_NUM = mco_b$ETA_NUM,
    RSA_NUM = mco_b$RSA_NUM,
    BEN_IDT_ANO = patients_expanded$BEN_IDT_ANO,
    BEN_RNG_GEM = 1,
    NIR_ANO_17 = patients_expanded$BEN_NIR_PSA,
    EXE_SOI_DTD = sample(
      seq(start_date, end_date, by = "day"),
      n_total_stays,
      replace = TRUE
    ),
    EXE_SOI_DTF = NA, # Sera calculé après
    FHO_RET = sample(
      c(0, 1),
      n_total_stays,
      replace = TRUE,
      prob = c(0.95, 0.05)
    ),
    NAI_RET = sample(
      c(0, 1),
      n_total_stays,
      replace = TRUE,
      prob = c(0.98, 0.02)
    ),
    NIR_RET = sample(
      c(0, 1),
      n_total_stays,
      replace = TRUE,
      prob = c(0.97, 0.03)
    ),
    PMS_RET = sample(
      c(0, 1),
      n_total_stays,
      replace = TRUE,
      prob = c(0.99, 0.01)
    ),
    SEJ_RET = sample(
      c(0, 1),
      n_total_stays,
      replace = TRUE,
      prob = c(0.98, 0.02)
    ),
    SEX_RET = sample(
      c(0, 1),
      n_total_stays,
      replace = TRUE,
      prob = c(0.99, 0.01)
    ),
    DAT_RET = sample(
      c(0, 1),
      n_total_stays,
      replace = TRUE,
      prob = c(0.99, 0.01)
    ),
    COH_NAI_RET = sample(
      c(0, 1),
      n_total_stays,
      replace = TRUE,
      prob = c(0.99, 0.01)
    ),
    COH_SEX_RET = sample(
      c(0, 1),
      n_total_stays,
      replace = TRUE,
      prob = c(0.99, 0.01)
    )
  )

  # Calculer EXE_SOI_DTF
  mco_c$EXE_SOI_DTF <- mco_c$EXE_SOI_DTD + mco_b$SEJ_NBJ

  # Table D (diagnostics associés) - certains séjours n'en ont pas
  has_da <- sample(
    c(TRUE, FALSE),
    n_total_stays,
    replace = TRUE,
    prob = c(0.7, 0.3)
  )
  stays_with_da <- which(has_da)

  # Générer 1-5 DA par séjour ayant des DA
  n_da_per_stay <- sample(
    1:5,
    length(stays_with_da),
    replace = TRUE,
    prob = c(0.4, 0.3, 0.2, 0.08, 0.02)
  )

  mco_d <- data.frame(
    ETA_NUM = rep(mco_b$ETA_NUM[stays_with_da], times = n_da_per_stay),
    RSA_NUM = rep(mco_b$RSA_NUM[stays_with_da], times = n_da_per_stay),
    ASS_DGN = sample(cv_da_codes, sum(n_da_per_stay), replace = TRUE)
  )

  # Table UM (unités médicales) - certains séjours n'en ont pas
  has_um <- sample(
    c(TRUE, FALSE),
    n_total_stays,
    replace = TRUE,
    prob = c(0.8, 0.2)
  )
  stays_with_um <- which(has_um)

  # Générer 1-3 UM par séjour ayant des UM
  n_um_per_stay <- sample(
    1:3,
    length(stays_with_um),
    replace = TRUE,
    prob = c(0.7, 0.25, 0.05)
  )

  mco_um <- data.frame(
    ETA_NUM = rep(mco_b$ETA_NUM[stays_with_um], times = n_um_per_stay),
    RSA_NUM = rep(mco_b$RSA_NUM[stays_with_um], times = n_um_per_stay),
    DGN_PAL = sample(cv_dp_codes, sum(n_um_per_stay), replace = TRUE),
    DGN_REL = sample(
      c(cv_dr_codes, NA),
      sum(n_um_per_stay),
      replace = TRUE,
      prob = c(rep(0.6 / length(cv_dr_codes), length(cv_dr_codes)), 0.4)
    )
  )

  list(
    B = mco_b,
    C = mco_c,
    D = mco_d,
    UM = mco_um
  )
}

#' Créer des données factices pour ER_ETE_F (Actes externes)
#'
#' @param er_prs_f data.frame des prescriptions
#' @return data.frame avec données d'actes externes
#' @export
create_mock_er_ete_f <- function(er_prs_f) {
  set.seed(123)

  # Seulement certaines prescriptions ont des actes externes
  sample_size <- round(0.3 * nrow(er_prs_f))
  sampled_rows <- dplyr::sample_n(er_prs_f, size = sample_size)

  sampled_rows |>
    dplyr::select(dplyr::all_of(c(
      "DCT_ORD_NUM",
      "FLX_DIS_DTD",
      "FLX_EMT_ORD",
      "FLX_EMT_NUM",
      "FLX_EMT_TYP",
      "FLX_TRT_DTD",
      "ORG_CLE_NUM",
      "PRS_ORD_NUM",
      "REM_TYP_AFF"
    ))) |>
    dplyr::mutate(
      ETE_NUM = sample(1000:9999, dplyr::n(), replace = TRUE),
      ETE_IND_TAA = sample(
        c(0, 1, 10),
        dplyr::n(),
        replace = TRUE,
        prob = c(0.85, 0.1, 0.05)
      )
    )
}

#' Configurer une base de données DuckDB avec toutes les tables factices
#'
#' @param n_patients Nombre de patients à générer
#' @param year Année pour les tables MCO
#' @param start_date Date de début
#' @param end_date Date de fin
#' @return Connexion DuckDB avec toutes les tables chargées
#' @export
create_mock_database <- function(
  n_patients = 100,
  year = 2020,
  start_date = as.Date("2020-01-01"),
  end_date = as.Date("2020-12-31")
) {
  # Connexion DuckDB
  conn <- connect_duckdb()

  # Générer les données de base
  patients_ids <- create_mock_patients_ids(n_patients)
  ir_ben_r <- create_mock_ir_ben_r(patients_ids)
  er_prs_f <- create_mock_er_prs_f(patients_ids, start_date, end_date)
  er_pha_f <- create_mock_er_pha_f(er_prs_f)
  ir_pha_r <- create_mock_ir_pha_r()
  ir_imb_r <- create_mock_ir_imb_r(patients_ids, start_date, end_date)
  er_ete_f <- create_mock_er_ete_f(er_prs_f)
  mco_tables <- create_mock_mco_tables(
    patients_ids,
    year,
    start_date,
    end_date
  )

  # Charger dans DuckDB
  DBI::dbWriteTable(conn, "IR_BEN_R", ir_ben_r, overwrite = TRUE)
  DBI::dbWriteTable(
    conn,
    "IR_BEN_R_ARC",
    ir_ben_r[sample(nrow(ir_ben_r), size = 10), ],
    overwrite = TRUE
  )
  DBI::dbWriteTable(conn, "ER_PRS_F", er_prs_f, overwrite = TRUE)
  DBI::dbWriteTable(conn, "ER_PHA_F", er_pha_f, overwrite = TRUE)
  DBI::dbWriteTable(conn, "IR_PHA_R", ir_pha_r, overwrite = TRUE)
  DBI::dbWriteTable(conn, "IR_IMB_R", ir_imb_r, overwrite = TRUE)
  DBI::dbWriteTable(conn, "ER_ETE_F", er_ete_f, overwrite = TRUE)

  # Tables MCO avec format année
  formatted_year <- sprintf("%02d", year %% 100)
  DBI::dbWriteTable(
    conn,
    paste0("T_MCO", formatted_year, "B"),
    mco_tables$B,
    overwrite = TRUE
  )
  DBI::dbWriteTable(
    conn,
    paste0("T_MCO", formatted_year, "C"),
    mco_tables$C,
    overwrite = TRUE
  )
  DBI::dbWriteTable(
    conn,
    paste0("T_MCO", formatted_year, "D"),
    mco_tables$D,
    overwrite = TRUE
  )
  DBI::dbWriteTable(
    conn,
    paste0("T_MCO", formatted_year, "UM"),
    mco_tables$UM,
    overwrite = TRUE
  )

  message(paste("Base de données factice créée avec", n_patients, "patients"))
  message(paste("Période :", start_date, "à", end_date))
  message(paste(
    "Tables fictives MCO, ER_PRS_F, ER_PHA_F et ER_ETE_F pour l'année",
    year
  ))

  conn
}
