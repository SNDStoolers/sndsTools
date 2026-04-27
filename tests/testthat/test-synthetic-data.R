test_that("download_synthetic_snds_csv downloads SNDS directories", {
  skip_on_ci()

  dir2test_db <- dirname(PATH2TEST_DB)

  download_synthetic_snds_csv(dir2test_db)

  expected_dir <- c(
    "SSR",
    "RIM-P",
    "MCO",
    "HAD",
    "DCIR_DCIRS",
    "DCIR",
    "Causes_de_Deces",
    "CARTOGRAPHIE_PATHOLOGIES",
    "BENEFICIAIRE"
  )

  expected_dirs <- list.dirs(dir2test_db, recursive = FALSE, full.names = TRUE)
  inter <- intersect(expected_dir, basename(expected_dirs))
  expect_true(length(inter) == length(expected_dirs))
})

test_that("insert_synthetic_snds_table creates a table from CSV", {
  temp_dir <- tempdir()
  csv_file <- file.path(temp_dir, "test_table.scsv")
  writeLines(c("col_a,col_b", "1,abc", "2,def"), csv_file)
  on.exit(file.remove(csv_file))

  db_path <- file.path(temp_dir, "test_insert.duckdb")
  on.exit(unlink(db_path), add = TRUE)

  conn <- DBI::dbConnect(duckdb::duckdb(), db_path)
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  # random table
  sndsTools:::insert_synthetic_snds_table(
    conn,
    csv_file,
    col_types = list(
      col_a = "integer",
      col_b = "character"
    )
  )

  expect_true(DBI::dbExistsTable(conn, "test_table"))

  result <- DBI::dbGetQuery(conn, "SELECT * FROM test_table")
  expect_equal(ncol(result), 2)
  expect_equal(nrow(result), 2)
  expect_equal(result$col_a, c(1L, 2L))
  expect_equal(result$col_b, c("abc", "def"))
})


test_that("connect_synthetic_snds works", {
  skip_on_ci()

  on.exit(unlink(PATH2TEST_DB), add = TRUE)

  result_conn <- connect_synthetic_snds(
    path2db = PATH2TEST_DB,
    force_insert = TRUE,
    subset_tables = c("IR_BEN_R", "ER_PRS_F", "T_MCOAAC")
  )
  result_conn |> DBI::dbDisconnect()
  # Check that it created the file
  expect_true(file.exists(PATH2TEST_DB))
  # Check that it works the second time it is called
  second_con <- connect_synthetic_snds(
    path2db = PATH2TEST_DB
  )
  on.exit(DBI::dbDisconnect(second_con), add = TRUE)
  # check that it returns a duckdb connection
  expect_true(inherits(second_con, "duckdb_connection"))
  # check that tables have been loaded in the database
  tables <- DBI::dbListTables(second_con)
  expect_true(length(tables) > 0)
})

test_that("get_kwikly_format returns expected columns and types", {
  skip_on_ci()

  result <- sndsTools:::get_kwikly_format("ER_PRS_F")

  expect_true(is.list(result))
  expect_true("PRS_NAT_REF" %in% names(result))
  expect_true(inherits(result$PRS_NAT_REF, "collector_double"))
})
