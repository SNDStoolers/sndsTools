library(sndsTools)
library(duckdb)

test_that("get_synthetic_snds creates the database file", {
  skip_on_ci()

  db_path <- tempfile(pattern = "synthetic_snds_", fileext = ".duckdb")
  on.exit(unlink(dirname(db_path), recursive = TRUE), add = TRUE)

  result_conn <- get_synthetic_snds(db_path = db_path, force_download = TRUE)
  expect_true(file.exists(db_path))
})

test_that("get_synthetic_snds returns invisible path on second call", {
  skip_on_ci()

  db_path <- tempfile(pattern = "synthetic_snds_", fileext = ".duckdb")
  on.exit(unlink(dirname(db_path), recursive = TRUE), add = TRUE)

  first_con <- get_synthetic_snds(db_path = db_path, force_download = TRUE)
  DBI::dbDisconnect(first_con)
  second_con <- get_synthetic_snds(db_path = db_path, force_download = FALSE)
  expect_true(file.exists(db_path))
})


test_that("get_synthetic_snds creates tables in the database", {
  skip_on_ci()

  require(duckdb)

  db_path <- tempfile(pattern = "synthetic_snds_", fileext = ".duckdb")
  on.exit(unlink(dirname(db_path), recursive = TRUE), add = TRUE)

  get_synthetic_snds(db_path = db_path, force_download = TRUE)

  conn <- DBI::dbConnect(duckdb(), db_path)
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  tables <- DBI::dbListTables(conn)
  expect_true(length(tables) > 0)
})

test_that("insert_synthetic_snds_table creates a table from CSV", {
  require(duckdb)

  temp_dir <- tempdir()
  csv_file <- file.path(temp_dir, "test_table.scsv")
  writeLines(c("col_a,col_b", "1,abc", "2,def"), csv_file)
  on.exit(file.remove(csv_file))

  db_path <- file.path(temp_dir, "test_insert.duckdb")
  on.exit(unlink(db_path), add = TRUE)

  conn <- DBI::dbConnect(duckdb(), db_path)
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  sndsTools:::insert_synthetic_snds_table(conn, csv_file)

  expect_true(DBI::dbExistsTable(conn, "test_table"))

  result <- DBI::dbGetQuery(conn, "SELECT * FROM test_table")
  expect_equal(ncol(result), 2)
  expect_equal(nrow(result), 2)
  expect_equal(result$col_a, c(1L, 2L))
  expect_equal(result$col_b, c("abc", "def"))
})
