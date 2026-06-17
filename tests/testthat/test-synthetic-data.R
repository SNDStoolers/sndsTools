PATH2TEST_ZIP <- file.path(
  dirname(PATH2SYNTHETIC_SNDS),
  "synthetic_snds_parquet.zip"
)

test_that("download_synthetic_snds downloads SNDS database", {
  skip_on_ci()
  if (file.exists(PATH2TEST_ZIP)) {
    file.remove(PATH2TEST_ZIP)
  }
  download_synthetic_snds(PATH2TEST_ZIP)

  expect_true(file.exists(PATH2TEST_ZIP))
})

test_that("connect_synthetic_snds works", {
  skip_on_ci()
  on.exit(unlink(PATH2SYNTHETIC_SNDS), add = TRUE)

  result_conn <- connect_synthetic_snds(
    path2db = PATH2SYNTHETIC_SNDS
  )
  on.exit(DBI::dbDisconnect(result_conn), add = TRUE)
  # Check that it works the first time it is called
  tables <- DBI::dbListTables(result_conn)
  expect_true(length(tables) > 0)
  # Check that it works the second time it is called
  second_con <- connect_synthetic_snds(
    path2db = PATH2SYNTHETIC_SNDS
  )
  on.exit(DBI::dbDisconnect(second_con), add = TRUE)
  # check that tables have been loaded in the database
  tables <- DBI::dbListTables(second_con)
  expect_true(length(tables) > 0)
})
