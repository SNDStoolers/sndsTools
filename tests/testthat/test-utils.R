test_that("get_first_non_archived_year_works", {
  conn <- connect_duckdb()
  first_non_archived_year <- get_first_non_archived_year(conn)
  expect_equal(first_non_archived_year, 2011)
})


test_that("onLoad works", {
  timezone <- Sys.getenv("TZ")
  oracle_timezone <- Sys.getenv("ORA_SDTZ")
  expect_equal(timezone, "Europe/Paris")
  expect_equal(oracle_timezone, "Europe/Paris")
})
