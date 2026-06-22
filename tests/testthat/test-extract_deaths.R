require(dplyr)
require(tibble)

conn <- connect_synthetic_snds(PATH2SYNTHETIC_SNDS)
on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

# KI_CCI_R : cause initiale du décès (DCD_CIM_COD).
# KI_ECD_R : ensemble des causes (ECD_CIM_COD).
# P3 décède en 2005 (hors période des tests), P5 n'a pas de cause initiale,
# P7 n'a qu'une cause initiale, P9 n'apparaît dans aucune table.
fake_ki_cci_r <- tibble::tribble(
  ~BEN_IDT_ANO, ~DCD_CIM_COD, ~BEN_DCD_DTE,
  "P1",         "G20",        "2015-06-01",
  "P2",         "I50",        "2016-03-10",
  "P3",         "G10",        "2005-01-01",
  "P7",         "C50",        "2018-02-02"
) |>
  dplyr::mutate(BEN_DCD_DTE = as.Date(BEN_DCD_DTE))

fake_ki_ecd_r <- tibble::tribble(
  ~BEN_IDT_ANO, ~ECD_CIM_COD, ~BEN_DCD_DTE,
  "P1",         "G20",        "2015-06-01",
  "P1",         "I10",        "2015-06-01",
  "P1",         "E11",        "2015-06-01",
  "P2",         "J44",        "2016-03-10",
  "P3",         "G10",        "2005-01-01",
  "P5",         "G20",        "2017-09-09",
  "P5",         "X59",        "2017-09-09"
) |>
  dplyr::mutate(BEN_DCD_DTE = as.Date(BEN_DCD_DTE))

DBI::dbWriteTable(conn, "KI_CCI_R", fake_ki_cci_r, overwrite = TRUE)
DBI::dbWriteTable(conn, "KI_ECD_R", fake_ki_ecd_r, overwrite = TRUE)


test_that("extract_deaths filters by diagnosis codes", {
  deaths <- extract_deaths(
    start_date = as.Date("2010-01-01"),
    end_date = as.Date("2020-12-31"),
    diagnosis_codes_filter = c("G10", "G20"),
    conn = conn
  )

  # Une ligne par code, cause initiale non dupliquée en "Other", P3 (2005) exclu
  # car hors période. P5 est retenu via ses codes "Other".
  expected <- tibble::tribble(
    ~BEN_IDT_ANO, ~EXE_SOI_DTD,  ~CIM_COD, ~STATUS,
    "P1",         "2015-06-01",  "G20",    "Initial cause",
    "P1",         "2015-06-01",  "E11",    "Other",
    "P1",         "2015-06-01",  "I10",    "Other",
    "P5",         "2017-09-09",  "G20",    "Other",
    "P5",         "2017-09-09",  "X59",    "Other"
  ) |>
    dplyr::mutate(EXE_SOI_DTD = as.Date(EXE_SOI_DTD))

  # extract_deaths() renvoie une lazy table : on la collecte pour comparer.
  expect_equal(
    deaths |>
      dplyr::arrange(BEN_IDT_ANO, EXE_SOI_DTD, STATUS, CIM_COD) |>
      dplyr::collect(),
    expected
  )
})

test_that("extract_deaths filters by patient ids and flags survivors", {
  deaths <- extract_deaths(
    start_date = as.Date("2010-01-01"),
    end_date = as.Date("2020-12-31"),
    patient_ids_filter = c("P1", "P5", "P7", "P9"),
    conn = conn
  )

  # Chaque identifiant fourni est restitué : ses causes de décès, ou une ligne
  # "Alive" s'il n'a pas de décès dans la période (P9).
  expected <- tibble::tribble(
    ~BEN_IDT_ANO, ~EXE_SOI_DTD,  ~CIM_COD, ~STATUS,
    "P1",         "2015-06-01",  "G20",    "Initial cause",
    "P1",         "2015-06-01",  "E11",    "Other",
    "P1",         "2015-06-01",  "I10",    "Other",
    "P5",         "2017-09-09",  "G20",    "Other",
    "P5",         "2017-09-09",  "X59",    "Other",
    "P7",         "2018-02-02",  "C50",    "Initial cause",
    "P9",         NA,            NA,       "Alive"
  ) |>
    dplyr::mutate(EXE_SOI_DTD = as.Date(EXE_SOI_DTD))

  expect_equal(
    deaths |>
      dplyr::arrange(BEN_IDT_ANO, EXE_SOI_DTD, STATUS, CIM_COD) |>
      dplyr::collect(),
    expected
  )
})
