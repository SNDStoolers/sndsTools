require(dplyr)

fake_patients_ids <- data.frame(
  BEN_IDT_ANO = c(1, 2, 3),
  BEN_NIR_PSA = c(11, 12, 13)
  # BEN_RNG_GEM = c(1, 1, 1)
)

fake_dcir_join_keys <- data.frame(
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

fake_erprsf <- data.frame(
  BEN_NIR_PSA = c(11, 12, 13, 11, 13),
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
  DPN_QLF = c(0, 0, 0, 0, 71),
  CPL_MAJ_TOP = c(0, 0, 0, 1, 0),
  BEN_CMU_TOP = c(0, 0, 0, 1, 0),
  BEN_RES_DPT = c(1, 1, 1, 1, 1),
  BEN_AMA_COD = c(1, 1, 1, 1, 1),
  BEN_SEX_COD = c(1, 1, 1, 1, 1),
  PRS_ACT_QTE = c(1, 1, 1, 1, 1),
  BSE_REM_MNT = c(1, 1, 1, 1, 1),
  BSE_PRS_NAT = c(1, 1, 1, 1, 1)
) |> cbind(fake_dcir_join_keys)

fake_erphaf <- data.frame(
  PHA_PRS_C13 = c(
    "3400932026555",
    "3400932725847",
    "3400930219874",
    "3400930219874",
    "3400936267343"
  ),
  PHA_ACT_QSN = c(1, 1, 1, 1, 1),
  PHA_PRS_IDE = c(1, 2, 3, 4, 5),
  PHA_DEC_TOP = c(1, 1, 1, 1, 1),
  PHA_DEC_QSU = c(1, 1, 1, 1, 1)
) |> cbind(fake_dcir_join_keys)

fake_irphar <- data.frame(
  PHA_CIP_C13 = c(
    "3400932026555",
    "3400932725847",
    "3400930219874",
    "3400930219874",
    "3400936267343"
  ),
  PHA_ATC_CLA = c("N04BC01", "N05AC01", "J05AG05", "J04AG05", "J01MA06"),
  PHA_GRD_CND = c(1, 1, 1, 1, 1)
)


fake_eretef <- data.frame(
  "ETE_NUM" = c(11, 12, 13),
  "ETE_IND_TAA" = c(10, 10, 10),
  "ETB_EXE_FIN" = c(1, 1, 1),
  "ETE_MCO_DDP" = c(1, 1, 1)
) |> cbind(fake_dcir_join_keys |> head(3))


conn <- connect_duckdb()
DBI::dbWriteTable(conn, "ER_PHA_F", fake_erphaf)
DBI::dbWriteTable(conn, "IR_PHA_R", fake_irphar)
DBI::dbWriteTable(conn, "ER_PRS_F", fake_erprsf)
DBI::dbWriteTable(conn, "ER_ETE_F", fake_eretef)

test_that("sql_extract_drug_dispenses works for ATC", {
  start_date <- as.Date("01/01/2019", format = "%d/%m/%Y")
  end_date <- as.Date("31/12/2019", format = "%d/%m/%Y")

  drug_dispenses <- sql_extract_drug_dispenses(
    start_date = start_date,
    end_date = end_date,
    atc_cod_starts_with_filter = c("J05"),
    output_table_name = "TMP_DRUG_DISPENSES",
    conn = conn
  )
  drug_dispenses <- dplyr::tbl(conn, "TMP_DRUG_DISPENSES")
  expect_equal(
    drug_dispenses |>
      dplyr::arrange(BEN_NIR_PSA, EXE_SOI_DTD) |>
      dplyr::select(
        BEN_NIR_PSA,
        EXE_SOI_DTD,
        PHA_ACT_QSN,
        PHA_ATC_CLA,
        PHA_PRS_C13
      ) |> collect(),
    structure(
      list(
        BEN_NIR_PSA = c(13),
        EXE_SOI_DTD = as.Date(c("2019-01-03")),
        PHA_ACT_QSN = c(1),
        PHA_ATC_CLA = c("J05AG05"),
        PHA_PRS_C13 = c("3400930219874")
        # BEN_RNG_GEM = c(1, 1)
      ),
      class = c("tbl_df", "tbl", "data.frame"),
      row.names = c(NA, -1L)
    )
  )
  DBI::dbRemoveTable(conn, "TMP_DRUG_DISPENSES")
})

test_that("sql_extract_drug_dispenses works for CIP13", {
  start_date <- as.Date("01/01/2019", format = "%d/%m/%Y")
  end_date <- as.Date("31/12/2019", format = "%d/%m/%Y")
  
  drug_dispenses <- sql_extract_drug_dispenses(
    start_date = start_date,
    end_date = end_date,
    atc_cod_starts_with_filter = c("J05"),
    cip13_cod_filter = c("3400932725847"),
    output_table_name = "TMP_DRUG_DISPENSES",
    # patients_ids = fake_patients_ids,
    conn = conn
  )
  drug_dispenses <- dplyr::tbl(conn, "TMP_DRUG_DISPENSES")


  expect_equal(
    drug_dispenses |>
      dplyr::arrange(BEN_NIR_PSA, EXE_SOI_DTD) |>
      dplyr::select(
        BEN_NIR_PSA,
        EXE_SOI_DTD,
        PHA_ACT_QSN,
        PHA_ATC_CLA,
        PHA_PRS_C13
      ) |> collect(),
    structure(
      list(
        BEN_NIR_PSA = c(12, 13),
        EXE_SOI_DTD = as.Date(c("2019-01-02", "2019-01-03")),
        PHA_ACT_QSN = c(1, 1),
        PHA_ATC_CLA = c("N05AC01", "J05AG05"),
        PHA_PRS_C13 = c("3400932725847", "3400930219874")
        # BEN_RNG_GEM = c(1, 1)
      ),
      class = c("tbl_df", "tbl", "data.frame"),
      row.names = c(NA, -2L)
    )
  )
  DBI::dbRemoveTable(conn, "TMP_DRUG_DISPENSES")
})


DBI::dbDisconnect(conn)
