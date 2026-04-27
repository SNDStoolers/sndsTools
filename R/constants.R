#' @title Stocke des constantes pour sndsTools

#' @return A list of constants for sndsTools.
#' @export
#' @family utils
constants_snds_tools <- function() {
  constants <- list()
  constants$is_portail <- dir.exists("~/sasdata1")
  constants
}

DIR2SNDS_CACHE <- "~/.cache/sndsTools"
if (!dir.exists(DIR2SNDS_CACHE)) {
  dir.create(DIR2SNDS_CACHE, recursive = TRUE)
}
PATH2SYNTHETIC_SNDS <- file.path(
  DIR2SNDS_CACHE,
  "synthetic_snds.duckdb"
)

PATH2TEST_DB <- file.path(
  DIR2SNDS_CACHE,
  "synthetic_snds_test.duckdb"
)
