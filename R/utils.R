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

#' Initialisation de la connexion à la base de données duckdb.
#'
#' Utilisation pour le testing uniquement. Si le code s'exécute en dehors du
#' portail, il faut initier une connexion duckdb pour effectuer les tests.
#'
#' @return dbConnection Connexion à la base de données duckdb
#'
#' @export
#' @family utils
connect_duckdb <- function() {
  print(
    "Le code ne s'exécute pas sur le portail CNAM.
    Initialisation d'une connexion duckdb en mémoire."
  )
  conn <- DBI::dbConnect(duckdb::duckdb(), ":memory:")

  # Generate fake user_synonyms table for testing: used in all er_prs_f
  # functions
  user_synonyms <- data.frame(
    SYNONYM_NAME = c("ER_PRS_F_2009", "ER_PRS_F_2010")
  )
  DBI::dbWriteTable(conn, "user_synonyms", user_synonyms)
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
#' doit être écrasée dans le cas où elle existe déjà.
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

#' Requêtage d'une table Oracle (SNDS ou ORAUSER).
#'
#' @param conn Connexion à la base de données.
#' @param table_name Nom de la table Oracle à explorer.
#' @param profile Nom de profil. Par défaut, profile = 108.
#' @param schema Si table hors du schéma standard, renseigner ici le schéma à
#' explorer. NULL par défaut.
#'
#' @details La fonction détecte automatiquement les tables de l'ESND et de la
#' cartographie. Normalement, pas besoin d'utiliser l'argument schéma pour ces
#' tables.
#'
#' @returns tbl_dbi. Exploration paresseuse (lazy query) d'une table Oracle
#' (ORAUSER, ou SNDS).
#'
#' @examples
#'\dontrun{
#' # Connexion au SNDS
#' conn <- connect_oracle()
#'
#' # Exploration paresseuse de la table ER_PRS_F
#' conn |>
#'  snds_table("ER_PRS_F") |>
#'  # Filtre sur la date de flux
#'  dplyr::filter(FLX_DIS_DTD == TO_DATE("2024-02-01", "yyyy-MM-dd"))
#'
#' # Déconnexion du SNDS
#' DBI::dbDisconnect(conn)
#'}
#' @export
#' @family utils
snds_table <- function(
  conn,
  table_name,
  profile = 108,
  schema = NULL
) {
  # Ajout du schéma si la table fait partie de l'ESND ou la cartographie.
  if (!is.null(schema)) {
    query <- dplyr::tbl(conn, in_schema(schema, table_name))
  } else {
    if (grepl(x = table_name, pattern = "ESND_|CRTO_")) {
      # gestion différente pour duckdb, mais nécessaire pour les tests
      if (!IS_PORTAIL) {
        table_id <- DBI::Id(
          schema = paste0("MEPSGP_", profile),
          table = table_name
        )
        query <- dplyr::tbl(conn, table_id)
      } else {
        query <- dplyr::tbl(
          conn,
          dbplyr::in_schema(paste0("MEPSGP_", profile), table_name)
        )
      }
    } else {
      query <- dplyr::tbl(conn, table_name)
    }
  }

  query
}
