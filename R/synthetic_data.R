# nolint start
#' Fournit une connexion duckdb à une base de donnée synthétique du SNDS
#'
#' @details Fournit une base de données avec des données synthétiques SNDS.
#' La base est téléchargée depuis https://github.com/SNDStoolers/synthetic_snds.
#' Ce projet reprend les données synthétiques produites par [la Plateforme de
#' Données de Santé](https://www.data.gouv.fr/datasets/donnees-synthetiques-de-la-base-principales-du-systeme-national-des-donnees-de-sante) afin de forcer les types des
#' données à ceux du portail Cnam et consolider les différents fichiers csv dans
#' une seule base duckdb.
#' La base est mis en cache dans le chemin `path2b` à la première utilisation
#' puis réutilisée aux appels suivants.
#'
#' @param path2b Character. Chemin vers le fichier de la base DuckDB à créer. La
#'   valeur par défaut est `~/.cache/sndsTools/synthetic_snds.duckdb`.
#' @param force_download Logical. Si TRUE, re-télécharge la base si elle existe
#'   déjà (FALSE par défaut).
#' @return Connexion DuckDB. Une connexion duckdb vers la base DuckDB créée.
#'
#' @examples
#' \dontrun{
#' # Crée une base DuckDB avec les données synthétiques SNDS
#' conn <- connect_synthetic_snds()
#' }
#' @export
#' @family synthetic
# nolint end
connect_synthetic_snds <- function(
  path2db = NULL,
  force_download = FALSE
) {
  if (is.null(path2db)) {
    path2db <- path.expand(PATH2SYNTHETIC_SNDS)
  }

  # If database exists and no force, return the existing db connection
  if (file.exists(path2db) && !force_download) {
    logger::log_info(paste0("Connection to an existing database at: ", path2db))
  } else {
    logger::log_info(
      paste0("Creating database at: ", path2db)
    )
    # Remove old db if exists with force
    if (file.exists(path2db)) {
      file.remove(path2db)
    }
    path2zip <- file.path(
      dirname(path2db),
      "synthetic_snds_parquet.zip"
    )
    if (!file.exists(path2zip) || force_download) {
      if (dir.exists(path2db)) {
        unlink(path2db, recursive = TRUE)
      }
      download_synthetic_snds(path2zip)
    }
    utils::unzip(path2zip, exdir = path2db)
  }

  conn <- duckdb::dbConnect(duckdb::duckdb())
  conn |> DBI::dbExecute(glue::glue("IMPORT DATABASE '{path2db}'"))
  # necessary for archived tables
  if (!DBI::dbExistsTable(conn, "user_synonyms")) {
    user_synonyms <- data.frame(
      SYNONYM_NAME = c("ER_PRS_F_2009", "ER_PRS_F_2010")
    )
    DBI::dbWriteTable(conn, "user_synonyms", user_synonyms)
  }
  conn
}

# nolint start
#' Télécharge la base de données synthétique du SNDS
#' @details La base est téléchargée depuis https://github.com/SNDStoolers/synthetic_snds/data/synthetic_snds.duckdb.
#' C'est une version corrigée de la base fournie par la plateforme de données de santé sur data.gouv.fr : https://www.data.gouv.fr/datasets/donnees-synthetiques-de-la-base-principales-du-systeme-national-des-donnees-de-sante
#'
#' @param db_path Character. Répertoire dans lequel télécharger et extraire les fichiers.
#'
#' @return Nothing.
#'
#' @export
#' @family synthetic
# nolint end
download_synthetic_snds <- function(path2zip) {
  synth_url_db <- "https://github.com/SNDStoolers/synthetic_snds/raw/refs/heads/main/data/synthetic_snds_parquet.zip"
  logger::log_info(glue::glue(
    "Télécharge la base synthétique du SNDS au chemin {path_}",
    path_ = path2zip
  ))
  # Create directory if needed
  if (!dir.exists(dirname(path2zip))) {
    dir.create(dirname(path2zip), recursive = TRUE)
  }
  tryCatch(
    utils::download.file(synth_url_db, path2zip, mode = "wb", quiet = FALSE),
    error = function(e) {
      stop("Failed to download from ", synth_url_db, ": ", e$message)
    }
  )
}
