#' @title Environnement d'exécution de sndsTools
#' @return Boolean. True si le package sndsTools est exécuté dan
#' l'environnement de travail du Portail, False sinon.
#' @export
#' @family constants
IS_PORTAIL <- dir.exists("~/sasdata1")

# nolint start
#' @title Neufs clés de jointure du DCIR
#' @return Character vector. Neufs clés de jointure du DCIR : table principale ER_PRS_F et [tables affinées](https://documentation-snds.health-data-hub.fr/snds/fiches/tables_affinees.html#les-tables-affinees#les-tables-affinees).
#' @family constants
#' @export
# nolint end
COLNAMES_DCIR_KEYS <- c(
  "FLX_DIS_DTD",
  "FLX_TRT_DTD",
  "FLX_EMT_TYP",
  "FLX_EMT_NUM",
  "FLX_EMT_ORD",
  "ORG_CLE_NUM",
  "DCT_ORD_NUM",
  "PRS_ORD_NUM",
  "REM_TYP_AFF"
)
