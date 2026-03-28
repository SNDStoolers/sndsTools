#' @title Stocke des constantes pour sndsTools

#' @return A list of constants for sndsTools.
#' @export
#' @family utils
constants_snds <- function() {
  constants <- list()
  constants$is_portail <- dir.exists("~/sasdata1")
  constants
}


#' @title Nom de la table temporaire pour les filtres ir_pha_r
#' @return A string with the name of the temporary table for ir_pha_r filters.
#' @export
#' @family constants
TNAME_FILTER_IR_PHA_R <- "SNDS_TOOLS_TMP_IR_PHA_R"

#' @title Nom de la table temporaire pour les IDs de patients
#' @return A string with the name of the temporary table for patient IDs.
#' @export
#' @family constants
TNAME_FILTER_PATIENTS <- "SNDS_TOOLS_TMP_PATIENTS_IDS"
