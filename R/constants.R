#' @title Stocke des constantes pour sndsTools

#' @return A list of constants for sndsTools.
#' @export
#' @family utils
constants_snds <- function() {
  constants <- list()
  constants$is_portail <- dir.exists("~/sasdata1")
  constants
}
