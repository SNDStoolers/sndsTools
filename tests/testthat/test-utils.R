require(dplyr)

test_that("get_first_non_archived_year_works", {
  conn <- connect_synthetic_snds()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  first_non_archived_year <- get_first_non_archived_year(conn)
  expect_equal(first_non_archived_year, 2011)
})

test_that("onLoad works", {
  timezone <- Sys.getenv("TZ")
  oracle_timezone <- Sys.getenv("ORA_SDTZ")
  expect_equal(timezone, "Europe/Paris")
  expect_equal(oracle_timezone, "Europe/Paris")
})

test_that("check_output_table_name accepte un nom valide en majuscules", {
  conn <- connect_synthetic_snds()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  expect_invisible(check_output_table_name("MA_TABLE", conn))
})

test_that("check_output_table_name échoue si le nom n'est pas une chaîne", {
  conn <- connect_synthetic_snds()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  expect_error(
    check_output_table_name(123, conn),
    regexp = "character"
  )
})

test_that("check_output_table_name échoue si le nom contient des minuscules", {
  conn <- connect_synthetic_snds()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

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
  conn <- connect_synthetic_snds()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  DBI::dbWriteTable(
    conn,
    "TABLE_EXISTANTE",
    data.frame(x = 1),
    overwrite = TRUE
  )
  on.exit(
    try(DBI::dbRemoveTable(conn, "TABLE_EXISTANTE"), silent = TRUE),
    add = TRUE,
    after = FALSE
  )
  expect_error(
    check_output_table_name("TABLE_EXISTANTE", conn),
    regexp = "existe dans la base de données"
  )
})

test_that("write_oracle_by_batch écrit correctement les données par batch", {
  conn <- connect_synthetic_snds()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  df <- dplyr::tibble(
    FLX_DIS_DTD = seq.Date(
      from = as.Date("2020-01-01"),
      to = as.Date("2020-12-31"),
      by = "month"
    ),
    value = 1:12
  ) |>
    dplyr::mutate(FLX_DIS_DTD = as.Date(FLX_DIS_DTD))
  conn |>
    dplyr::copy_to(
      df,
      "TEMP_LAZY_TABLE",
      temporary = TRUE,
      overwrite = TRUE
    )
  lazy_df <- dplyr::tbl(conn, "TEMP_LAZY_TABLE")

  output_table_name <- "TEST_BATCH_TABLE"

  write_oracle_table_by_batch(
    conn,
    lazy_df,
    output_table_name,
    start_date = as.Date("2020-01-01"),
    end_date = as.Date("2020-12-31"),
    batch_colname = "FLX_DIS_DTD",
    batch_by = "month"
  )

  result <- DBI::dbReadTable(conn, output_table_name)
  expect_equal(nrow(result), nrow(lazy_df |> collect()))
  expect_equal(result |> dplyr::pull(value), lazy_df |> dplyr::pull(value))
})
