require(dplyr)

test_that("get_first_non_archived_year_works", {
  conn <- connect_duckdb()
  first_non_archived_year <- get_first_non_archived_year(conn)
  expect_equal(first_non_archived_year, 2011)
})

test_that("check_output_table_name accepte un nom valide en majuscules", {
  conn <- connect_duckdb()
  expect_invisible(check_output_table_name("MA_TABLE", conn))
})

test_that("check_output_table_name échoue si le nom n'est pas une chaîne", {
  conn <- connect_duckdb()
  expect_error(
    check_output_table_name(123, conn),
    regexp = "character"
  )
})

test_that("check_output_table_name échoue si le nom contient des minuscules", {
  conn <- connect_duckdb()
  expect_error(
    check_output_table_name("ma_table", conn),
    regexp = "majuscules"
  )
  expect_error(
    check_output_table_name("Ma_Table", conn),
    regexp = "majuscules"
  )
})

test_that("check_output_table_name échoue si la table existe déjà", {
  conn <- connect_duckdb()
  DBI::dbWriteTable(conn, "TABLE_EXISTANTE", data.frame(x = 1))
  expect_error(
    check_output_table_name("TABLE_EXISTANTE", conn),
    regexp = "existe dans la base de données"
  )
})
