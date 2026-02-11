#' @title Stocke des constantes pour sndsTools

#' @return A list of constants for sndsTools.
#' @export
#' @family utils
constants_snds_tools <- function() {
  constants <- list()
  constants$is_portail <- dir.exists("~/sasdata1")
  constants
}
