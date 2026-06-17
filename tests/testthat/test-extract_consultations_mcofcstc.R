require(dplyr)
require(tibble)

conn <- connect_duckdb(PATH2TEST_DB)
on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

patients_ids_filter <- tibble::tribble(
  ~BEN_IDT_ANO, ~BEN_NIR_PSA,
             1,           11,
             2,           12,
             3,           13,
             4,           14
)

fake_cstc_table <- tibble::tribble(
  ~ETA_NUM, ~SEQ_NUM, ~NIR_ANO_17, ~EXE_SOI_DTD,
        20,       31,          11, "2019-01-10",
        20,       32,          12, "2019-01-02",
        20,       33,          13, "2019-01-03",
        20,       34,          14, "2019-01-04",
) |>
  dplyr::mutate(
    EXE_SOI_DTD = as.Date(EXE_SOI_DTD),
    NIR_RET = "0",
    NAI_RET = "0",
    SEX_RET = "0",
    ENT_DAT_RET = "0",
    IAS_RET = "0"
  )

fake_fcstc_table <- tibble::tribble(
  ~ETA_NUM, ~SEQ_NUM, ~EXE_SPE, ~ACT_COD,
        20,       31,  "01",     "C",
        20,       32,  "22",     "CS",
        20,       33,  "99",     "C",
        20,       34,  "01",     "C"
)

fake_fmstc_table <- tibble::tribble(
  ~ETA_NUM, ~SEQ_NUM, ~CCAM_COD,
        20,       31,  "ACQK001",
        20,       32,  "ACQH003",
        20,       33,  "ACQK002"
)

DBI::dbWriteTable(conn, "T_MCO19CSTC", fake_cstc_table, overwrite = TRUE)
DBI::dbWriteTable(conn, "T_MCO19FCSTC", fake_fcstc_table, overwrite = TRUE)
DBI::dbWriteTable(conn, "T_MCO19FMSTC", fake_fmstc_table, overwrite = TRUE)


test_that("extract_consultations_mcofcstc works", {
  start_date <- as.Date("2019-01-01")
  end_date <- as.Date("2019-12-31")
  spe_codes_filter <- c("01", "22", "32", "34")

  consultations <- extract_consultations_mcofcstc(
    start_date = start_date,
    end_date = end_date,
    spe_codes_filter = spe_codes_filter,
    patient_ids_filter = patients_ids_filter,
    conn = conn
  )

  expected <- tibble::tribble(
    ~BEN_IDT_ANO, ~NIR_ANO_17, ~EXE_SOI_DTD, ~CCAM_COD, ~ACT_COD, ~EXE_SPE,
               1,          11, "2019-01-10", "ACQK001", "C",      "01",
               2,          12, "2019-01-02", "ACQH003", "CS",     "22",
               4,          14, "2019-01-04", NA,        "C",      "01"
  ) |>
    dplyr::mutate(EXE_SOI_DTD = as.Date(EXE_SOI_DTD))

  expect_equal(
    consultations |> dplyr::arrange(BEN_IDT_ANO, EXE_SOI_DTD),
    expected
  )

})

test_that("extract_consultations_mcofcstc works with multiple filters", {
  start_date <- as.Date("2019-01-01")
  end_date <- as.Date("2019-12-31")
  spe_codes_filter <- c("01", "22")
  prestation_codes_filter <- c("C")
  ccam_codes_filter <- c("ACQK001", "ACQH003")

  consultations <- extract_consultations_mcofcstc(
    start_date = start_date,
    end_date = end_date,
    spe_codes_filter = spe_codes_filter,
    prestation_codes_filter = prestation_codes_filter,
    ccam_codes_filter = ccam_codes_filter,
    patient_ids_filter = patients_ids_filter,
    conn = conn
  )

  expected <- tibble::tribble(
    ~BEN_IDT_ANO, ~NIR_ANO_17, ~EXE_SOI_DTD, ~CCAM_COD, ~ACT_COD, ~EXE_SPE,
               1,          11, "2019-01-10", "ACQK001", "C",      "01"
  ) |>
    dplyr::mutate(EXE_SOI_DTD = as.Date(EXE_SOI_DTD))

  expect_equal(
    consultations |> dplyr::arrange(BEN_IDT_ANO, EXE_SOI_DTD),
    expected
  )

})
