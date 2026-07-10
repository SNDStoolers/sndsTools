require(dplyr)

# nolint start
fake_dcir_join_keys <- tibble::tribble(
  ~DCT_ORD_NUM , ~FLX_EMT_ORD , ~FLX_EMT_NUM , ~FLX_EMT_TYP , ~ORG_CLE_NUM , ~PRS_ORD_NUM , ~REM_TYP_AFF , ~FLX_DIS_DTD , ~FLX_TRT_DTD ,
             1 ,            1 ,            1 ,            1 ,            1 ,            1 ,            1 , "2019-02-10" , "2019-02-10" ,
             2 ,            1 ,            1 ,            1 ,            1 ,            1 ,            1 , "2019-02-02" , "2019-02-02" ,
             3 ,            1 ,            1 ,            1 ,            1 ,            1 ,            1 , "2019-02-03" , "2019-02-03" ,
             4 ,            1 ,            1 ,            1 ,            1 ,            1 ,            1 , "2019-02-04" , "2019-02-04" ,
             5 ,            1 ,            1 ,            1 ,            1 ,            1 ,            1 , "2019-03-01" , "2019-03-01" ,
             6 ,            2 ,            2 ,            2 ,            2 ,            2 ,            2 , "2019-03-02" , "2019-03-02"
) |>
  dplyr::mutate(
    across(c(FLX_DIS_DTD, FLX_TRT_DTD), as.Date)
  )

fake_er_prs_f <- tibble::tribble(
  ~BEN_NIR_PSA , ~BEN_RNG_GEM , ~EXE_SOI_DTD , ~EXE_SOI_DTF , ~PSP_SPE_COD , ~DPN_QLF , ~CPL_MAJ_TOP , ~BEN_CDI_NIR , ~PRS_NAT_REF ,
            11 ,            1 , "2019-01-10" , "2019-01-10" , "01"         ,        0 ,            0 , "00"         , "3336"       ,
            12 ,            1 , "2019-01-02" , "2019-01-02" , "02"         ,        0 ,            0 , "03"         , "3336"       ,
            13 ,            1 , "2019-01-03" , "2019-01-03" , "03"         ,        0 ,            0 , "04"         , "3317"       ,
            15 ,            1 , "2019-01-04" , "2019-01-04" , "04"         ,        0 ,            1 , "00"         , "3336"       ,
            13 ,            1 , "2019-02-01" , "2019-02-01" , "05"         ,        0 ,            2 , "03"         , "3351"       ,
            16 ,            1 , "2019-02-02" , "2019-02-02" , "06"         ,        0 ,            0 , "00"         , "3317"
) |>
  dplyr::bind_cols(fake_dcir_join_keys) |>
  dplyr::mutate(
    across(c(EXE_SOI_DTD, EXE_SOI_DTF), as.Date)
  )

fake_er_ucd_f <- tibble::tribble(
  ~UCD_TOP_UCD , ~UCD_UCD_COD , ~UCD_DLV_NBR ,
             0 , "9231824"    ,            1 ,
             1 , "9231825"    ,            1 ,
             9 , "9231824"    ,            1 ,
             2 , "9231824"    ,            1 ,
             3 , "9231827"    ,            1 ,
             4 , "9231827"    ,            1
) |>
  dplyr::bind_cols(fake_dcir_join_keys)

fake_er_ete_f <- tibble::tribble(
  ~ETE_NUM , ~ETE_IND_TAA ,
        11 ,           10 ,
        12 ,           10 ,
        13 ,           10 ,
        14 ,            1 ,
        15 ,            1 ,
        15 ,           10
) |>
  dplyr::bind_cols(fake_dcir_join_keys)
# nolint end

conn <- connect_synthetic_snds()
on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)
DBI::dbWriteTable(conn, "ER_PRS_F", fake_er_prs_f, overwrite = TRUE)
DBI::dbWriteTable(conn, "ER_UCD_F", fake_er_ucd_f, overwrite = TRUE)
DBI::dbWriteTable(conn, "ER_ETE_F", fake_er_ete_f, overwrite = TRUE)

test_that("extract_drugs_erucdf respects UCD filter", {
  start_date <- as.Date("01/01/2019", format = "%d/%m/%Y")
  end_date <- as.Date("01/04/2019", format = "%d/%m/%Y")

  # Test with specific UCD filter (only J05 codes)
  result_with_filter <- extract_drugs_erucdf(
    conn,
    start_date = start_date,
    end_date = end_date,
    ucd_codes_filter = c("9231824"),
    dis_dtd_lag_months = 1
  ) |>
    dplyr::collect()

  # test structure of the result
  expect_equal(
    colnames(result_with_filter),
    c(
      "BEN_NIR_PSA",
      "BEN_RNG_GEM",
      "EXE_SOI_DTD",
      "EXE_SOI_DTF",
      "PRS_NAT_REF",
      "UCD_TOP_UCD",
      "UCD_UCD_COD",
      "UCD_DLV_NBR"
    )
  )
  # test that only three rows are present (three matching UCD codes in synthetic data)
  expect_equal(nrow(result_with_filter), 3)
})
