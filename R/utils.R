#' Initialisation de la connexion à la base de données.
#'
#' @return dbConnection Connexion à la base de données oracle
#'
#' @export
#' @family utils
connect_oracle <- function() {
  require(ROracle)
  Sys.setenv(TZ = "Europe/Paris")
  Sys.setenv(ORA_SDTZ = "Europe/Paris")
  drv <- DBI::dbDriver("Oracle")
  conn <- DBI::dbConnect(drv, dbname = "IPIAMPR2.WORLD")
  conn
}

# TODO: deprecate in favor of connect_synthetic_snds if synthetic data is sufficient for all tests and tutoriels #nolint
#' Initialisation de la connexion à la base de données duckdb.
#'
#' @description Utilisation pour les tests et les tutoriels. Si le code
#' s'exécute en dehors du portail, il faut initier une connexion duckdb pour
#' effectuer les tests.
#'
#' @param db_path Character. Chemin vers la base de données duckdb à utiliser.
#' Si NULL, la fonction utilise le chemin par défaut défini dans
#' `PATH2SYNTHETIC_SNDS`.
#'
#' @return dbConnection Connexion à la base de données duckdb
#'
#' @export
#' @family utils
connect_duckdb <- function(path2db = NULL) {
  if (is.null(path2db)) {
    path2db <- PATH2SYNTHETIC_SNDS
  }
  conn <- duckdb::dbConnect(duckdb::duckdb(), dbdir = path2db)

  # Generate fake user_synonyms table for testing: used in all er_prs_f
  # functions
  if (!DBI::dbExistsTable(conn, "user_synonyms")) {
    user_synonyms <- data.frame(
      SYNONYM_NAME = c("ER_PRS_F_2009", "ER_PRS_F_2010")
    )
    DBI::dbWriteTable(conn, "user_synonyms", user_synonyms)
  }
  conn
}

#' Création d'une table à partir d'une requête SQL.
#' @details
#' La fonction crée une table sous Oracle à partir d'une requête SQL.
#' Si la table `output_table_name` existe déjà, elle est écrasée si
#' le paramètre `overwrite` est TRUE.
#' @param conn Connexion à la base de données
#' @param output_table_name Nom de la table de sortie
#' @param query Requête SQL
#' @param overwrite Logical. Indique si la table `output_table_name`
#' doit être écrasée dans le cas où elle existe déjà. Défaut à FALSE.
#' @return NULL
#'
#' @export
#' @family utils
create_table_from_query <- function(
  conn = NULL,
  output_table_name = NULL,
  query = NULL,
  overwrite = FALSE
) {
  stopifnot(
    !DBI::dbExistsTable(conn, output_table_name) ||
      (DBI::dbExistsTable(conn, output_table_name) && overwrite)
  )
  if (DBI::dbExistsTable(conn, output_table_name) && overwrite) {
    DBI::dbRemoveTable(conn, output_table_name)
  }
  query <- dbplyr::sql_render(query)
  DBI::dbExecute(
    conn,
    glue::glue(
      "CREATE TABLE {output_table_name} AS {query}"
    )
  )
}

#' Insertion des résultats d'une requête SQL dans une table existante.
#' @param conn Connexion à la base de données
#' @param output_table_name Nom de la table de sortie
#' @param query Requête SQL
#' @return NULL
#'
#' @export
#' @family utils
insert_into_table_from_query <- function(
  conn = NULL,
  output_table_name = NULL,
  query = NULL
) {
  stopifnot(DBI::dbExistsTable(conn, output_table_name))
  query <- dbplyr::sql_render(query)
  DBI::dbExecute(
    conn,
    glue::glue("INSERT INTO {output_table_name} {query}")
  )
}


#' Vérifie la validité du nom de la table de sortie Oracle.
#'
#' @description
#' Cette fonction vérifie que le nom de la table de sortie fourni respecte
#' les contraintes imposées par Oracle :
#' - Le nom doit être une chaîne de caractères.
#' - Le nom doit être entièrement en majuscules, car Oracle stocke et compare
#'   les noms de tables en majuscules. Un nom en minuscules provoquerait une
#'   incohérence : le test d'existence de la table ne détecterait pas une table
#'   déjà existante, puis Oracle échouerait à la création en signalant un
#'   conflit.
#' - La table ne doit pas déjà exister dans la base de données (la comparaison
#'   est effectuée en majuscules pour être robuste).
#'
#' @param output_table_name Character. Le nom de la table de sortie à valider.
#' @param conn DBI connection. La connexion à la base de données Oracle.
#' @return Retourne `output_table_name` de manière invisible si toutes les
#'   vérifications sont satisfaites. Sinon, la fonction lève une erreur avec
#'   un message explicatif.
#'
#' @examples
#' \dontrun{
#' conn <- connect_duckdb()
#' check_output_table_name("MA_TABLE", conn)  # OK
#' check_output_table_name("ma_table", conn)  # Erreur : doit être en majuscules
#' }
#' @export
#' @family utils
check_output_table_name <- function(output_table_name, conn) {
  if (!is.character(output_table_name)) {
    stop(
      "`output_table_name` doit être une chaîne de charactère (character). ",
      "Valeur reçue : ",
      class(output_table_name),
      "."
    )
  }
  if (output_table_name != toupper(output_table_name)) {
    stop(
      "`output_table_name` doit être entièrement en majuscules. ",
      "Oracle stocke les noms de tables en majuscules : un nom en minuscules ",
      "empêche la détetion d'une table existante et provoque une erreur ",
      "lors de la création. Valeur reçue : '",
      output_table_name,
      "'. ",
      "Suggestion : '",
      toupper(output_table_name),
      "'."
    )
  }
  if (DBI::dbExistsTable(conn, output_table_name)) {
    stop(
      "La table '",
      output_table_name,
      "' existe dans la base de données. ",
      "Veuillez choisir un autre nom ou supprimer la table existante."
    )
  }
  invisible(output_table_name)
}

#' Récupération de l'année non archivée la plus ancienne de la table ER_PRS_F.
#' @param conn Connexion à la base de données
#' @return Année non archivée la plus ancienne
#'
#' @export
#' @family utils
get_first_non_archived_year <- function(conn) {
  user_synonyms <- DBI::dbGetQuery(
    conn,
    "SELECT synonym_name
      FROM user_synonyms WHERE synonym_name LIKE 'ER_PRS_F_%'"
  )
  max_archived_year <-
    sub("ER_PRS_F_", "", x = user_synonyms$SYNONYM_NAME, fixed = TRUE) |>
    as.numeric() |>
    max()
  max_archived_year + 1
}

#' Récupération des statistiques des tables
#' @param conn Connexion à la base de données
#' @param table Chaine de caractère indiquant le nom d'une table
#' @references https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_STATS.html#GUID-CA6A56B9-0540-45E9-B1D7-D78769B7714C #nolint
#' @return NULL
#' @export
#' @family utils
gather_table_stats <- function(conn, table) {
  user <- DBI::dbGetQuery(conn, "SELECT user FROM dual")
  user <- DBI::dbQuoteIdentifier(conn, user$USER)
  DBI::dbExecute(
    conn,
    "BEGIN DBMS_STATS.GATHER_TABLE_STATS(:1, :2); END;",
    data = data.frame(user, table)
  )
}
