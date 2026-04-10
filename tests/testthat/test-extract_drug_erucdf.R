require(dplyr)

fake_dcir_join_keys <- data.frame(
  DCT_ORD_NUM = c(1, 2, 3, 4, 5, 6),
  FLX_DIS_DTD = as.Date(
    c(
      "2019-02-10",
      "2019-02-02",
      "2019-02-03",
      "2019-02-04",
      "2019-03-01",
      "2019-03-02"
    )
  ),
  FLX_EMT_ORD = c(1, 1, 1, 1, 1, 2),
  FLX_EMT_NUM = c(1, 1, 1, 1, 1, 2),
  FLX_EMT_TYP = c(1, 1, 1, 1, 1, 2),
  FLX_TRT_DTD = as.Date(
    c(
      "2019-02-10",
      "2019-02-02",
      "2019-02-03",
      "2019-02-04",
      "2019-03-01",
      "2019-03-02"
    )
  ),
  ORG_CLE_NUM = c(1, 1, 1, 1, 1, 2),
  PRS_ORD_NUM = c(1, 1, 1, 1, 1, 2),
  REM_TYP_AFF = c(1, 1, 1, 1, 1, 2)
)

fake_er_prs_f <- data.frame(
  BEN_NIR_PSA = c(11, 12, 13, 15, 13, 16),
  EXE_SOI_DTD = as.Date(
    c(
      "2019-01-10",
      "2019-01-02",
      "2019-01-03",
      "2019-01-04",
      "2019-02-01",
      "2019-02-02"
    )
  ),
  EXE_SOI_DTF = as.Date(
    c(
      "2019-01-10",
      "2019-01-02",
      "2019-01-03",
      "2019-01-04",
      "2019-02-01",
      "2019-02-02"
    )
  ),
  PSP_SPE_COD = c("01", "02", "03", "04", "05", "06"),
  DPN_QLF = c(0, 0, 0, 0, 0, 0),
  CPL_MAJ_TOP = c(0, 0, 0, 1, 2, 0),
  BEN_CDI_NIR = c("00", "03", "04", "00", "03", "00"),
  PRS_NAT_REF = c(
    "3336",
    "3336",
    "3317",
    "3336",
    "3351",
    "3317"
  )
) |>
  cbind(fake_dcir_join_keys)

fake_er_ucd_f <- data.frame(
  UCD_TOP_UCD = c(0, 1, 9, 2, 3, 4),
  UCD_UCD_COD = c(
    "9231824",
    "9231825",
    "9231824",
    "9231824",
    "9231827",
    "9231827"
  ),
  UCD_DLV_NBR = c(1, 1, 1, 1, 1, 1)
) |>
  cbind(fake_dcir_join_keys)

fake_er_ete_f <- data.frame(
  ETE_NUM = c(11, 12, 13, 14, 15, 15),
  ETE_IND_TAA = c(10, 10, 10, 1, 1, 10)
) |>
  cbind(fake_dcir_join_keys)

conn <- connect_duckdb()
on.exit(DBI::dbDisconnect(conn))
DBI::dbWriteTable(conn, "ER_PRS_F", fake_er_prs_f)
DBI::dbWriteTable(conn, "ER_UCD_F", fake_er_ucd_f)
DBI::dbWriteTable(conn, "ER_ETE_F", fake_er_ete_f)

test_that("extract_drug_erucdf respects UCD filter", {
  start_date <- as.Date("01/01/2019", format = "%d/%m/%Y")
  end_date <- as.Date("01/04/2019", format = "%d/%m/%Y")

  # Test with specific UCD filter (only J05 codes)
  result_with_filter <- extract_drug_erucdf(
    start_date = start_date,
    end_date = end_date,
    ucd_codes_filter = c("9231824"),
    output_table_name = "RESULT_WITH_FILTER",
    dis_dtd_lag_months = 1,
    conn = conn
  )

  result_data_with_filter <- dplyr::tbl(conn, "RESULT_WITH_FILTER") |>
    dplyr::collect()

  # test structure of the result
  expect_equal(
    colnames(result_data_with_filter),
    c(
      "BEN_NIR_PSA",
      "EXE_SOI_DTD",
      "EXE_SOI_DTF",
      "PRS_NAT_REF",
      "UCD_TOP_UCD",
      "UCD_UCD_COD",
      "UCD_DLV_NBR"
    )
  )
  # test that only two rows are present
  expect_equal(nrow(result_data_with_filter), 2)
})
