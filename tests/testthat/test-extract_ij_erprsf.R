require(dplyr)

test_that("extract_ij_erprsf_works ", {
  conn <- connect_duckdb(PATH2TEST_DB)
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)


  fake_patients_ids <- tibble::tribble(
    ~BEN_IDT_ANO, ~BEN_NIR_PSA, ~BEN_RNG_GEM,
    1, 11, 1,
    2, 12, 1,
    3, 13, 1           
  )

  fake_erprsf <- tibble::tribble(
  ~BEN_NIR_PSA, ~BEN_RNG_GEM, ~EXE_SOI_DTD, ~FLX_DIS_DTD, ~FLX_TRT_DTD, ~PSE_SPE_COD, ~PFS_EXE_NUM, ~PRS_NAT_REF,
  ~PRS_ACT_NBR, ~PRS_ACT_QTE, ~EXE_SOI_DTF, ~DPN_QLF, ~PRS_DPN_QLP, ~CPL_MAJ_TOP, ~CPL_AFF_COD,
  ~PSE_STJ_COD, ~RGO_ASU_NAT, ~BSE_REM_MNT, ~IJR_EMP_NUM, ~ORL_BSE_NUM, ~PRS_FAC_TOP, ~ORG_AFF_BEN, ~RGM_COD,
  
  11, 1, as.Date("2019-01-10"), as.Date("2019-02-01"), as.Date("2019-01-15"), "99", 1, "6110", 1,  1,  as.Date("2019-01-10"), "0", "0", 0, 0, 90, 10,  40,   "077664451202199", "01C011", "", "01C011106", 101,
  12, 1, as.Date("2019-01-02"), as.Date("2019-02-01"), as.Date("2019-01-15"), "99", 2, "6120", 5,  5,  as.Date("2019-01-06"), "0", "0", 0, 0, 90, 10, 200,   "077664451202199", "01C011", "", "01C011106", 1,
  13, 1, as.Date("2019-01-03"), as.Date("2019-02-01"), as.Date("2019-01-15"), "99", 3, "6110", 10, 10, as.Date("2019-01-12"), "0", "0", 0, 0, 90, 40, 400,   "077664451202199", "01C011", "", "01C011106", 2,
  13, 1, as.Date("2020-01-20"), as.Date("2020-10-01"), as.Date("2019-09-20"), "99", 4, "6131", 5,  5,  as.Date("2020-01-24"), "0", "0", 0, 0, 90, 40, 200,   "077664451202199", "01C011", "", "01C011106", 2, # ij mais lag > 6 mois
  15, 1, as.Date("2019-01-04"), as.Date("2019-02-01"), as.Date("2019-01-15"), "01", 5, "C",    1,  1,  as.Date(NA), "0", "0", 0, 0, 51, 10, 16.1, "077664451202199", "01C011", "", "01C011106", 1 # pas un ij
  )

  DBI::dbWriteTable(conn, "ER_PRS_F", fake_erprsf, overwrite = TRUE)

  start_date <- as.Date("01/01/2019", format = "%d/%m/%Y")
  end_date <- as.Date("31/12/2019", format = "%d/%m/%Y")

  consultations <- extract_ij_erprsf(
    start_date = start_date,
    end_date = end_date,
    patients_ids_filter = fake_patients_ids,
    conn = conn
  )

  expect_equal(
    consultations |> arrange(BEN_IDT_ANO, EXE_SOI_DTD) |> collect(),
    structure(
      list(
        BEN_IDT_ANO = c(1, 2, 3),
        BEN_RNG_GEM = c(1, 1, 1),
        EXE_SOI_DTD = as.Date(c("2019-01-10", "2019-01-02", "2019-01-03")),
        EXE_SOI_DTF = as.Date(c("2019-01-10", "2019-01-06", "2019-01-12")),
        PRS_ACT_NBR = c(1, 5, 10),
        BSE_REM_MNT = c(40, 200, 400),
        PFS_EXE_NUM = c(1, 2, 3),
        PRS_NAT_REF = c("6110", "6120", "6110"),
        RGO_ASU_NAT = c(10, 10, 40),
        IJR_EMP_NUM = c(
          "077664451202199",
          "077664451202199",
          "077664451202199"
        )
      ),
      class = c("tbl_df", "tbl", "data.frame"),
      row.names = c(NA, -3L)
    )
  )
})
