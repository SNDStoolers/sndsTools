# Fichier pour stocker les constantes du paquet sndsTools

# Constantes exportées ie. accessibles par les utilisateurs du paquet

#' @title Est-ce que le code tourne sur le portail de la CNAM ?
#' @export
#' @family utils
IS_PORTAIL <- dir.exists("~/sasdata1")

#' @title Clés de jointure des tables DCIR
#' @export
#' @family utils
COLS_DCIR_JOIN_KEY <- c(
  "DCT_ORD_NUM",
  "FLX_DIS_DTD",
  "FLX_EMT_ORD",
  "FLX_EMT_NUM",
  "FLX_EMT_TYP",
  "FLX_TRT_DTD",
  "ORG_CLE_NUM",
  "PRS_ORD_NUM",
  "REM_TYP_AFF"
)

# Constantes non exportées ie. utilisées uniquement en interne dans le paquet

DIR2SNDS_CACHE <- file.path("~", ".cache", "sndsTools")
if (!dir.exists(DIR2SNDS_CACHE)) {
  dir.create(DIR2SNDS_CACHE, recursive = TRUE)
}

PATH2SYNTHETIC_SNDS <- file.path(
  DIR2SNDS_CACHE,
  "synthetic_snds_parquet"
)
