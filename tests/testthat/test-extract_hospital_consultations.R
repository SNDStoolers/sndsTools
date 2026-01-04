require(dplyr)

test_that("extract_hospital_consultations works", {
  conn <- connect_duckdb()

  patients_ids_filter <- data.frame(
    BEN_IDT_ANO = c(1, 2, 3),
    BEN_NIR_PSA = c(11, 12, 13)
  )

  fake_cstc_table <- data.frame(
    ETA_NUM = c(20, 20, 20),
    SEQ_NUM = c(31, 32, 33),
    NIR_ANO_17 = c(11, 12, 13),
    EXE_SOI_DTD = as.Date(c(
      "2019-01-10",
      "2019-01-02",
      "2019-01-03"
    )),
    NIR_RET = c("0", "0", "0"),
    NAI_RET = c("0", "0", "0"),
    SEX_RET = c("0", "0", "0"),
    ENT_DAT_RET = c("0", "0", "0"),
    IAS_RET = c("0", "0", "0")
  )
  fake_fcstc_table <- data.frame(
    ETA_NUM = c(20, 20, 20),
    SEQ_NUM = c(31, 32, 33),
    EXE_SPE = c("01", "22", "99"),
    ACT_COD = c("C", "CS", "C")
  )

  DBI::dbWriteTable(conn, "T_MCO19CSTC", fake_cstc_table)
  DBI::dbWriteTable(conn, "T_MCO19FCSTC", fake_fcstc_table)

  start_date <- as.Date("01/01/2019", format = "%d/%m/%Y")
  end_date <- as.Date("31/12/2019", format = "%d/%m/%Y")
  spe_codes_filter <- c("01", "22", "32", "34")

  consultations <- extract_hospital_consultations(
    start_date = start_date,
    end_date = end_date,
    spe_codes_filter = spe_codes_filter,
    patient_ids_filter = patients_ids_filter,
    conn = conn
  )

  DBI::dbDisconnect(conn)
  expect_equal(
    consultations |> arrange(BEN_IDT_ANO, EXE_SOI_DTD),
    structure(
      list(
        BEN_IDT_ANO = c(
          1,
          2
        ),
        NIR_ANO_17 = c(
          11,
          12
        ),
        EXE_SOI_DTD = as.Date(c("2019-01-10", "2019-01-02")),
        ACT_COD = c(
          "C",
          "CS"
        ),
        EXE_SPE = c("01", "22")
      ),
      class = c("tbl_df", "tbl", "data.frame"),
      row.names = c(NA, -2L)
    )
  )
})
