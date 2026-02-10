#' @title Stocke des constantes pour SndsTools

#' @return A list of constants for SNDs tools.
#' @export
#' @family utils
constants_snds_tools <- function() {
  constants <- list()
  constants$is_portail <- dir.exists("~/sasdata1")
  constants
}
