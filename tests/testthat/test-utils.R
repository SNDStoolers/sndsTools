require(dplyr)

test_that("get_first_non_archived_year_works", {
  conn <- connect_synthetic_snds()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  first_non_archived_year <- get_first_non_archived_year(conn)
  expect_equal(first_non_archived_year, 2011)
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

  DBI::dbWriteTable(conn, "TABLE_EXISTANTE", data.frame(x = 1), overwrite = TRUE)
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

# -----------------------------------------------------------------------------
# save_or_return_result() accepte indifféremment un data.frame (déjà collecté)
# ou une tbl_lazy (requête dbplyr non exécutée), et centralise le collect /
# l'écriture en base.
# -----------------------------------------------------------------------------

setup_sor_source <- function(conn) {
  src <- data.frame(
    BEN_IDT_ANO = c("A", "B"),
    CIM_COD = c("G20", "I50"),
    stringsAsFactors = FALSE
  )
  DBI::dbWriteTable(conn, "TMP_SOR_SRC", src, overwrite = TRUE)
  invisible(src)
}

test_that("save_or_return_result collecte une tbl_lazy si output_table_name est NULL", {
  conn <- connect_synthetic_snds()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)
  src <- setup_sor_source(conn)
  on.exit(
    try(DBI::dbRemoveTable(conn, "TMP_SOR_SRC"), silent = TRUE),
    add = TRUE,
    after = FALSE
  )

  lazy <- dplyr::tbl(conn, "TMP_SOR_SRC")
  result <- save_or_return_result(lazy, output_table_name = NULL, conn = conn)

  expect_s3_class(result, "data.frame")
  expect_false(inherits(result, "tbl_lazy"))
  expect_setequal(result$BEN_IDT_ANO, src$BEN_IDT_ANO)
})

test_that("save_or_return_result matérialise une tbl_lazy via CREATE TABLE AS", {
  conn <- connect_synthetic_snds()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)
  setup_sor_source(conn)
  on.exit(
    try(DBI::dbRemoveTable(conn, "TMP_SOR_SRC"), silent = TRUE),
    add = TRUE,
    after = FALSE
  )

  output_table_name <- "TMP_SOR_OUT"
  if (DBI::dbExistsTable(conn, output_table_name)) {
    DBI::dbRemoveTable(conn, output_table_name)
  }
  on.exit(
    try(DBI::dbRemoveTable(conn, output_table_name), silent = TRUE),
    add = TRUE,
    after = FALSE
  )

  lazy <- dplyr::tbl(conn, "TMP_SOR_SRC") |>
    dplyr::filter(BEN_IDT_ANO == "A")
  result <- save_or_return_result(lazy, output_table_name, conn)

  expect_null(result)
  expect_true(DBI::dbExistsTable(conn, output_table_name))
  saved <- dplyr::tbl(conn, output_table_name) |> dplyr::collect()
  expect_equal(saved$BEN_IDT_ANO, "A")
  expect_equal(saved$CIM_COD, "G20")
})

test_that("save_or_return_result renvoie un data.frame tel quel si output_table_name est NULL", {
  conn <- connect_synthetic_snds()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  df <- data.frame(x = 1:2, y = c("a", "b"), stringsAsFactors = FALSE)
  result <- save_or_return_result(df, output_table_name = NULL, conn = conn)
  expect_identical(result, df)
})

test_that("save_or_return_result écrit un data.frame avec dbWriteTable", {
  conn <- connect_synthetic_snds()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  output_table_name <- "TMP_SOR_DF_OUT"
  if (DBI::dbExistsTable(conn, output_table_name)) {
    DBI::dbRemoveTable(conn, output_table_name)
  }
  on.exit(
    try(DBI::dbRemoveTable(conn, output_table_name), silent = TRUE),
    add = TRUE,
    after = FALSE
  )

  df <- data.frame(x = 1:2, y = c("a", "b"), stringsAsFactors = FALSE)
  result <- save_or_return_result(df, output_table_name, conn)

  expect_null(result)
  expect_true(DBI::dbExistsTable(conn, output_table_name))
  saved <- dplyr::tbl(conn, output_table_name) |>
    dplyr::collect() |>
    dplyr::arrange(x)
  expect_equal(saved$x, df$x)
  expect_equal(saved$y, df$y)
})
