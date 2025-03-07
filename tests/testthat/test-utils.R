require(dplyr)

test_that("get_first_non_archived_year_works", {
  conn <- connect_duckdb()
  first_non_archived_year <- get_first_non_archived_year(conn)
  expect_equal(first_non_archived_year, 2011)
})
