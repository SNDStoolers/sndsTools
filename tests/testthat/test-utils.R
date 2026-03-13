require(dplyr)

test_that("get_first_non_archived_year_works", {
  conn <- connect_duckdb()
  first_non_archived_year <- get_first_non_archived_year(conn)
  expect_equal(first_non_archived_year, 2011)
})


test_that("snds_table_works", {
  conn <- connect_duckdb()
  # create fake table
  DBI::dbExecute(conn, "CREATE TABLE ER_PRS_F AS SELECT 1 AS id")

  snds_table <- snds_table(conn, "ER_PRS_F")
  expect_s3_class(snds_table, "tbl_dbi")
})


test_that("snds_table_works with CRTO table", {
  conn <- connect_duckdb()
  # create fake schema and table
  DBI::dbExecute(conn, "CREATE SCHEMA IF NOT EXISTS MEPSGP_108;")
  DBI::dbExecute(conn, "CREATE TABLE MEPSGP_108.CRTO_G12 AS SELECT 1 AS id")

  snds_table <- snds_table(conn, "CRTO_G12")
  expect_s3_class(snds_table, "tbl_dbi")
  conn |> DBI::dbDisconnect()
})
