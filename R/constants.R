# Fichier pour stocker les constantes du paquet sndsTools

# Constantes exportées ie. accessibles par les utilisateurs du paquet

#' @title Est-ce que le code tourne sur le portail de la CNAM ?
#' @export
#' @family utils
IS_PORTAIL <- dir.exists("~/sasdata1")

# Constantes non exportées ie. utilisées uniquement en interne dans le paquet

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
