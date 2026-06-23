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

# Liste des finess géographiques APHP, APHM et HCL à supprimer pour éviter les
# doublons
FINESS_DOUBLONS <- c(
  "130780521",
  "130783236",
  "130783293",
  "130784234",
  "130804297",
  "600100101",
  "750041543",
  "750100018",
  "750100042",
  "750100075",
  "750100083",
  "750100091",
  "750100109",
  "750100125",
  "750100166",
  "750100208",
  "750100216",
  "750100232",
  "750100273",
  "750100299",
  "750801441",
  "750803447",
  "750803454",
  "910100015",
  "910100023",
  "920100013",
  "920100021",
  "920100039",
  "920100047",
  "920100054",
  "920100062",
  "930100011",
  "930100037",
  "930100045",
  "940100027",
  "940100035",
  "940100043",
  "940100050",
  "940100068",
  "950100016",
  "690783154",
  "690784137",
  "690784152",
  "690784178",
  "690787478",
  "830100558"
)

