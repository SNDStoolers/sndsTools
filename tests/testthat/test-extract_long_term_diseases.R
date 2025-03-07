require(dplyr)

test_that("extract_long_term_disease works", {
  conn <- connect_duckdb()

  fake_patients_ids <- data.frame(
    BEN_IDT_ANO = c(1, 2, 3),
    BEN_NIR_PSA = c(11, 12, 13)
  )
  fake_ald <- data.frame(
    BEN_NIR_PSA = c(11, 15, 12, 13, 13),
    IMB_ALD_DTD = as.Date(
      c(
        "2019-01-10",
        "2019-01-02",
        "2019-01-03",
        "2019-01-05",
        "2019-01-04"
      )
    ),
    IMB_ALD_DTF = as.Date(
      c(
        "2019-02-10",
        "2019-02-02",
        "2019-02-03",
        "2019-02-05",
        "2019-02-04"
      )
    ),
    IMB_ALD_NUM = c(2, 1, 1, 1, 1),
    MED_MTF_COD = c("I50", "I65", "I65", "I60", "I60"),
    IMB_ETM_NAT = c("01", "01", "01", "01", "11")
  )
  DBI::dbWriteTable(conn, "IR_IMB_R", fake_ald)

  start_date <- as.Date("01/01/2019", format = "%d/%m/%Y")
  end_date <- as.Date("31/12/2019", format = "%d/%m/%Y")

  ald <- extract_long_term_disease(
    start_date = start_date,
    end_date = end_date,
    icd_cod_starts_with = c("I6"),
    patients_ids = fake_patients_ids,
    conn = conn
  )

  DBI::dbDisconnect(conn)

  expect_equal(
    ald |> dplyr::arrange(BEN_IDT_ANO, IMB_ALD_DTD),
    structure(
      list(
        BEN_IDT_ANO = c(2, 3),
        IMB_ALD_NUM = c(1, 1),
        IMB_ALD_DTD = as.Date(c(
          "2019-01-03",
          "2019-01-05"
        )),
        IMB_ALD_DTF = as.Date(c(
          "2019-02-03",
          "2019-02-05"
        )),
        IMB_ETM_NAT = c("01", "01"),
        MED_MTF_COD = c("I65", "I60")
      ),
      class = c("tbl_df", "tbl", "data.frame"),
      row.names = c(NA, -2L)
    )
  )
})
