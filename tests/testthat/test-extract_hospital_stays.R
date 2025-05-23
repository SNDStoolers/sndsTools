require(dplyr)

test_that("extract_hospital_stays works", {
  conn <- connect_duckdb()

  patients_ids_filter <- data.frame(
    BEN_IDT_ANO = c(1, 2, 3),
    BEN_NIR_PSA = c("12345", "23456", "34567")
  )

  test_year <- 2019
  start_date <- as.Date(glue::glue("01/01/{test_year}"), format = "%d/%m/%Y")
  end_date <- as.Date(glue::glue("31/12/{test_year}"), format = "%d/%m/%Y")
  formatted_year <- format(start_date, "%y")
  fake_b_table <- data.frame(
    ETA_NUM = c(1, 2, 3),
    RSA_NUM = c(1, 2, 3),
    SEJ_NBJ = c(5, 10, 15),
    NBR_DGN = c(2, 3, 1),
    NBR_RUM = c(1, 1, 1),
    NBR_ACT = c(4, 5, 6),
    ENT_MOD = c("A", "B", "C"),
    ENT_PRV = c("X", "Y", "Z"),
    SOR_MOD = c("D", "E", "F"),
    SOR_DES = c("G", "H", "I"),
    DGN_PAL = c("A00", "B00", "C00"),
    DGN_REL = c("A01", "B01", "C01"),
    GRG_GHM = c("GHM1", "GHM2", "GHM3"),
    BDI_DEP = c("75", "92", "93"),
    BDI_COD = c("75001", "92001", "93001"),
    COD_SEX = c("M", "F", "M"),
    AGE_ANN = c(30, 40, 50),
    AGE_JOU = c(10950, 14600, 18250)
  )
  fake_c_table <- data.frame(
    ETA_NUM = c(1, 2, 3),
    RSA_NUM = c(1, 2, 3),
    EXE_SOI_DTD = as.Date(c("2019-01-10", "2019-01-02", "2019-01-03")),
    EXE_SOI_DTF = as.Date(c("2019-01-15", "2019-01-12", "2019-01-18")),
    SEJ_NUM = c(101, 102, 103),
    NIR_ANO_17 = c("12345", "23456", "34567"),
    FHO_RET = c(0, 0, 0),
    NAI_RET = c(0, 0, 0),
    NIR_RET = c(0, 0, 0),
    PMS_RET = c(0, 0, 0),
    SEJ_RET = c(0, 0, 0),
    SEX_RET = c(0, 0, 0),
    DAT_RET = c(0, 0, 0),
    COH_NAI_RET = c(0, 0, 0),
    COH_SEX_RET = c(0, 0, 0)
  )
  fake_d_table <- data.frame(
    ASS_DGN = c("E00", "E00", "F00"),
    ETA_NUM = c(1, 2, 3),
    RSA_NUM = c(1, 2, 3)
  )
  fake_um_table <- data.frame(
    DGN_PAL = c("A00", "A01", "B00", "C00"),
    DGN_REL = c("Z00", "Z01", "B01", "Z00"),
    ETA_NUM = c(1, 1, 2, 3),
    RSA_NUM = c(1, 1, 2, 3)
  )

  DBI::dbWriteTable(conn, paste0("T_MCO", formatted_year, "B"), fake_b_table)
  DBI::dbWriteTable(conn, paste0("T_MCO", formatted_year, "C"), fake_c_table)
  DBI::dbWriteTable(conn, paste0("T_MCO", formatted_year, "D"), fake_d_table)
  DBI::dbWriteTable(conn, paste0("T_MCO", formatted_year, "UM"), fake_um_table)


  dp_cim10_codes_filter <- c("A", "B")

  hospital_stays <- extract_hospital_stays(
    start_date = start_date,
    end_date = end_date,
    dp_cim10_codes_filter = c("A", "B"),
    patients_ids_filter = patients_ids_filter,
    conn = conn
  ) |> dplyr::arrange(BEN_IDT_ANO, EXE_SOI_DTD, DGN_PAL, DGN_PAL_UM, ASS_DGN)

  DBI::dbDisconnect(conn)

  expect_equal(
    hospital_stays |>
      dplyr::select(
        ETA_NUM, RSA_NUM, BEN_IDT_ANO, EXE_SOI_DTD,
        DGN_PAL, DGN_REL, DGN_PAL_UM, DGN_REL_UM, ASS_DGN
      ),
    structure(
      list(
        ETA_NUM = c(1, 1, 1, 2, 2),
        RSA_NUM = c(1, 1, 1, 2, 2),
        BEN_IDT_ANO = c(1, 1, 1, 2, 2),
        EXE_SOI_DTD = as.Date(
          c(
            "2019-01-10", "2019-01-10", "2019-01-10",
            "2019-01-02", "2019-01-02"
          )
        ),
        DGN_PAL = c("A00", "A00", "A00", "B00", "B00"),
        DGN_REL = c("A01", "A01", "A01", "B01", "B01"),
        DGN_PAL_UM = c("A00", "A01", NA, "B00", NA),
        DGN_REL_UM = c("Z00", "Z01", NA, "B01", NA),
        ASS_DGN = c(NA, NA, "E00", NA, "E00")
      ),
      class = c("tbl_df", "tbl", "data.frame"),
      row.names = c(NA, -5L)
    )
  )
})


test_that("build_dp_dr_conditions works correctly", {
  # Test with include_dr = TRUE
  result1 <- build_dp_dr_conditions(
    cim10_codes = c("A00", "B00"),
    include_dr = TRUE
  )
  expect_equal(
    result1,
    paste0(
      "DGN_PAL LIKE 'A00%' OR DGN_PAL LIKE 'B00%' OR ",
      "DGN_REL LIKE 'A00%' OR DGN_REL LIKE 'B00%'"
    )
  )

  # Test with include_dr = FALSE
  result2 <- build_dp_dr_conditions(
    cim10_codes = c("A00", "B00"),
    include_dr = FALSE
  )
  expect_equal(
    result2,
    "DGN_PAL LIKE 'A00%' OR DGN_PAL LIKE 'B00%'"
  )

  # Test with single code
  result3 <- build_dp_dr_conditions(
    cim10_codes = "A00",
    include_dr = TRUE
  )
  expect_equal(
    result3,
    "DGN_PAL LIKE 'A00%' OR DGN_REL LIKE 'A00%'"
  )
})
