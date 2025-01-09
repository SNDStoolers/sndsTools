require(dplyr)

test_that("extract_drug_dispenses works", {
  conn <- connect_duckdb()

  fake_patients_ids <- data.frame(
    BEN_IDT_ANO = c(1, 2, 3),
    BEN_NIR_PSA = c(11, 12, 13)
    #BEN_RNG_GEM = c(1, 1, 1)
  )

  fake_erprsf <- data.frame(
    BEN_NIR_PSA = c(11, 12, 13, 15, 13),
    BEN_RNG_GEM = c(1, 1, 1, 1, 1),
    EXE_SOI_DTD = as.Date(
      c(
        "2019-01-10",
        "2019-01-02",
        "2019-01-03",
        "2020-01-05",
        "2019-01-04"
      )
    ),
    PSP_SPE_COD = c("01", "22", "32", "34", "01"),
    DCT_ORD_NUM = c(1, 2, 3, 4, 5),
    FLX_DIS_DTD = as.Date(
      c(
        "2019-02-10",
        "2019-02-02",
        "2019-02-03",
        "2020-02-05",
        "2019-02-04"
      )
    ),
    FLX_EMT_ORD = c(1, 1, 1, 1, 1),
    FLX_EMT_NUM = c(1, 1, 1, 1, 1),
    FLX_EMT_TYP = c(1, 1, 1, 1, 1),
    FLX_TRT_DTD = as.Date(
      c(
        "2019-01-10",
        "2019-01-02",
        "2019-01-03",
        "2020-01-05",
        "2019-01-04"
      )
    ),
    ORG_CLE_NUM = c(1, 1, 1, 1, 1),
    PRS_ORD_NUM = c(1, 1, 1, 1, 1),
    REM_TYP_AFF = c(1, 1, 1, 1, 1)
  )
  fake_erphaf <- data.frame(
    PHA_PRS_C13 = c(
      "3400932026555",
      "3400932725847",
      "3400930219874",
      "3400930219874",
      "3400936267343"
    ),
    PHA_ACT_QSN = c(1, 1, 1, 1, 1),
    DCT_ORD_NUM = c(1, 2, 3, 4, 5),
    FLX_DIS_DTD = as.Date(
      c(
        "2019-02-10",
        "2019-02-02",
        "2019-02-03",
        "2020-02-05",
        "2019-02-04"
      )
    ),
    FLX_EMT_ORD = c(1, 1, 1, 1, 1),
    FLX_EMT_NUM = c(1, 1, 1, 1, 1),
    FLX_EMT_TYP = c(1, 1, 1, 1, 1)
    ,
    FLX_TRT_DTD = as.Date(
      c(
        "2019-01-10",
        "2019-01-02",
        "2019-01-03",
        "2020-01-05",
        "2019-01-04"
      )
    ),
    ORG_CLE_NUM = c(1, 1, 1, 1, 1),
    PRS_ORD_NUM = c(1, 1, 1, 1, 1),
    REM_TYP_AFF = c(1, 1, 1, 1, 1)
  )

  fake_irphar <- data.frame(
    PHA_CIP_C13 = c(
      "3400932026555",
      "3400932725847",
      "3400930219874",
      "3400930219874",
      "3400936267343"
    ),
    PHA_ATC_CLA = c("N04BC01", "N05AC01", "J05AG05", "J05AG05", "J01MA06")
  )
  DBI::dbWriteTable(conn, "ER_PHA_F", fake_erphaf)
  DBI::dbWriteTable(conn, "IR_PHA_R", fake_irphar)
  DBI::dbWriteTable(conn, "ER_PRS_F", fake_erprsf)

  start_date <- as.Date("01/01/2019", format = "%d/%m/%Y")
  end_date <- as.Date("31/12/2019", format = "%d/%m/%Y")


  drug_dispenses <- extract_drug_dispenses(
    start_date = start_date,
    end_date = end_date,
    atc_cod_starts_with = c("J05"),
    patients_ids = fake_patients_ids,
    conn = conn
  )

  DBI::dbDisconnect(conn)

  expect_equal(
    drug_dispenses |> dplyr::arrange(BEN_IDT_ANO, EXE_SOI_DTD),
    structure(
      list(
        BEN_IDT_ANO = c(3),
        EXE_SOI_DTD = as.Date(c("2019-01-03")),
        PHA_ACT_QSN = c(1),
        PHA_ATC_CLA = c("J05AG05"),
        PHA_PRS_C13 = c("3400930219874"),
        PSP_SPE_COD = c("32")
        #BEN_RNG_GEM = c(1, 1)
      ),
      class = c("tbl_df", "tbl", "data.frame"),
      row.names = c(NA, -1L)
    )
  )
})
