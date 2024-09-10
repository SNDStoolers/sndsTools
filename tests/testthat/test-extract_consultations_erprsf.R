require(dplyr)

test_that("extract_consultations_erprsf_works ", {
  conn <- connect_duckdb()

  fake_patients_ids <- data.frame(
    BEN_IDT_ANO = c(1, 2, 3),
    BEN_NIR_PSA = c(11, 12, 13),
    BEN_RNG_GEM = c(1, 1, 1)
  )

  fake_erprsf <- data.frame(
    BEN_NIR_PSA = c(11, 12, 13, 13, 15),
    BEN_RNG_GEM = c(1, 1, 1, 1, 1),
    EXE_SOI_DTD = as.Date(c("2019-01-10", "2019-01-02", "2019-01-03", "2020-01-05", "2019-01-04")),
    FLX_DIS_DTD = as.Date(c("2019-02-10", "2019-02-02", "2019-02-03", "2020-02-05", "2019-02-04")),
    PSE_SPE_COD = c("01", "22", "99", "01", "01"),
    PFS_EXE_NUM = c(1, 2, 3, 4, 5),
    PRS_NAT_REF = c("C", "CS", "C", "C", "C"),
    PRS_ACT_QTE = c(1, 1, 1, 1, 1),
    DPN_QLF = c("0", "0", "0", "0", "0"),
    PRS_DPN_QLP = c("0", "0", "0", "0", "0"),
    CPL_MAJ_TOP = c(0, 0, 0, 0, 0),
    CPL_AFF_COD = c(0, 0, 0, 0, 0),
    PSE_STJ_COD = c(51, 51, 51, 51, 51)
  )

  DBI::dbWriteTable(conn, "ER_PRS_F", fake_erprsf)

  start_date <- as.Date("01/01/2019", format = "%d/%m/%Y")
  end_date <- as.Date("31/12/2019", format = "%d/%m/%Y")
  pse_spe_filter <- c("01", "22", "32", "34")
  prestation_filter <- c("C", "CS")

  consultations <- extract_consultations_erprsf(
    start_date = start_date,
    end_date = end_date,
    pse_spe_filter = pse_spe_filter,
    prestation_filter = prestation_filter,
    patients_ids_filter = fake_patients_ids,
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
        EXE_SOI_DTD = as.Date(c("2019-01-10", "2019-01-02")),
        PSE_SPE_COD = c(
          "01",
          "22"
        ),
        PFS_EXE_NUM = c(1, 2),
        PRS_NAT_REF = c(
          "C",
          "CS"
        ),
        PRS_ACT_QTE = c(1, 1),
        BEN_RNG_GEM = c(1, 1)
      ),
      class = c("tbl_df", "tbl", "data.frame"),
      row.names = c(NA, -2L)
    )
  )
})
