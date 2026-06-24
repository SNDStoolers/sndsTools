require(dplyr)

create_mock_had_stays <- function(conn) {
  fake_c_table <- data.frame(
    NIR_ANO_17 = c("12345", "23456", "34567"),
    ETA_NUM_EPMSI = c("123", "456", "789"),
    RHAD_NUM = c("abc", "def", "ghi"),
    ETA_NUM_GEO = c("aaa", "bbb", "ccc"),
    NAI_RET = c("0", "0", "0"),
    NIR_RET = c("0", "0", "1"),
    SEJ_RET = c("0", "0", "1"),
    SEX_RET = c("0", "0", "1"),
    FHO_RET = c("0", "0", "1"),
    PMS_RET = c("0", "0", "1"),
    DAT_RET = c("0", "0", "1"),
    COH_NAI_RET = c("0", "0", "1"),
    COH_SEX_RET = c("0", "0", "1")
  )
  DBI::dbWriteTable(conn, "T_HAD19C", fake_c_table, overwrite = TRUE)
}

test_that("extract_had_stays_per_year works", {
  conn <- connect_duckdb(PATH2TEST_DB)
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  create_mock_had_stays(conn)

  had_stays <- extract_had_stays_per_year(
    year = 19,
    remove_patient_filters = TRUE,
    conn = conn
  ) |>
    dplyr::arrange(NIR_ANO_17, ETA_NUM_EPMSI, RHAD_NUM, ETA_NUM_GEO)

  expect_equal(
    had_stays |>
      dplyr::select(
        NIR_ANO_17,
        ETA_NUM_EPMSI,
        RHAD_NUM,
        ETA_NUM_GEO,
        NAI_RET,
        NIR_RET,
        SEJ_RET,
        SEX_RET,
        FHO_RET,
        PMS_RET,
        DAT_RET,
        COH_NAI_RET,
        COH_SEX_RET
      ) |> collect(),
    structure(
      list(
        NIR_ANO_17 = c("12345", "23456"),
        ETA_NUM_EPMSI = c("123", "456"),
        RHAD_NUM = c("abc", "def"),
        ETA_NUM_GEO = c("aaa", "bbb"),
        NAI_RET = c("0", "0"),
        NIR_RET = c("0", "0"),
        SEJ_RET = c("0", "0"),
        SEX_RET = c("0", "0"),
        FHO_RET = c("0", "0"),
        PMS_RET = c("0", "0"),
        DAT_RET = c("0", "0"),
        COH_NAI_RET = c("0", "0"),
        COH_SEX_RET = c("0", "0")
      ),
      class = c("tbl_df", "tbl", "data.frame"),
      row.names = c(NA, -2L)
    )
  )
})
