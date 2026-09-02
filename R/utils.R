#' onLoad function
#' @description
#' Cette fonction est appelée lors du chargement du package ou d'une de ses
#' fonctions (via `::`). Elle configure le fuseau horaire par défaut à
#' "Europe/Paris" pour :
#' - `TZ`: la session R
#' - `ORA_SDTZ`: les connexions Oracle, pour s'assurer que les datetimes sont
#'   traitées dans le bon fuseau horaire.
#' Cette configuration est essentielle pour garantir la cohérence entre les
#' objets datetime manipulés dans R et ceux stockés ou récupérés depuis la base
#' de données Oracle : [cf détails et exemples](https://soeiro.gitlab.io/pepidoc/r.html#dates-heures-et-fuseaux-horaires). # nolint
#' @return NULL
#' @export
#' @family utils
.onLoad <- function(libname, pkgname) {
  Sys.setenv(
    TZ = "Europe/Paris",
    ORA_SDTZ = "Europe/Paris"
  )
  logger::log_info(
    "Charge le package sndsTools.
    Variables d'environment TZ et ORA_SDTZ fixées à 'Europe/Paris.'"
  )
}
# run if the code is run on the portal
if (dir.exists("~/sasdata1")) {
  .onLoad()
}

#' Initialisation de la connexion à la base de données.
#'
#' @return dbConnection Connexion à la base de données oracle
#'
#' @export
#' @family utils
connect_oracle <- function() {
  require(ROracle)
  drv <- DBI::dbDriver("Oracle")
  conn <- DBI::dbConnect(drv, dbname = "IPIAMPR2.WORLD")
  conn
}

#' Récupération du profil SNDS de l'utilisateur connecté.
#' @description
#' Sur le portail, chaque utilisateur appartient à un profil (`PROFIL_XXX`)
#' qui est le schéma hébergeant les tables du SNDS. Le nom du profil est
#' déduit de l'identifiant Oracle, par exemple `ORAxxxxxx123` -> `PROFIL_123`.
#' @param conn Connexion à la base de données
#' @return Nom du schéma du profil, ou NULL si la connexion n'est pas Oracle
#' (par exemple sur la base synthétique duckdb).
#'
#' @export
#' @family utils
get_profil_snds <- function(conn) {
  if (!inherits(conn, "OraConnection")) {
    return(NULL)
  }
  DBI::dbGetQuery(
    conn,
    "SELECT 'PROFIL_' || substr(user, 11, 3) AS PROFIL FROM dual"
  )[[1]]
}

#' Accès à une table du SNDS en qualifiant le schéma du profil.
#' @description
#' Certaines mises à jour du portail cassent les connexions Oracle qui ne
#' déclarent pas le schéma. Cette fonction préfixe donc la table par le profil
#' de l'utilisateur. Hors Oracle, elle se rabat sur [dplyr::tbl()].
#' @param conn Connexion à la base de données
#' @param table_name Nom de la table
#' @param profil Nom du schéma du profil. Par défaut, celui de l'utilisateur
#' connecté.
#' @return Table lazy
#'
#' @export
#' @family utils
tbl_oracle <- function(conn, table_name, profil = NULL) {
  if (is.null(profil)) {
    profil <- get_profil_snds(conn)
  }
  if (is.null(profil)) {
    return(dplyr::tbl(conn, table_name))
  }
  dplyr::tbl(conn, DBI::Id(schema = profil, table = table_name))
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
#' conn <- connect_oracle()
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

#' Ecriture d'une table lazy vers oracle par batch
#' @description
#' Cette fonction permet d'écrire une table lazy vers Oracle en la découpant
#' en plusieurs batchs selon un critère de date. Cela permet de gérer des
#' volumes de données importants et d'éviter les problèmes de mémoire ou de
#' timeout lors de l'insertion.
#' Elle est particulièrement utile pour les tables du DCIR indexées sur la
#' colonne `FLX_DIS_DTD`.
#' @param conn Connexion à la base de données
#' @param lazy_df Table lazy à écrire
#' @param output_table_name Nom de la table de sortie
#' @param start_date Date de début pour le batch
#' @param end_date Date de fin pour le batch
#' @param dis_dtd_lag_months Nombre de mois de décalage pour la colonne
#' FLX_DIS_DTD si la table à écrire provient du DCIR. Par défaut 6 mois.
#' @param batch_by Taille de batch : "month" ou "year"
#' @param batch_colname Nom de la colonne à utiliser pour le batch. Par défaut
#' utilise "FLX_DIS_DTD" si la table provient du DCIR.
#' @return NULL
#' @export
#' @family utils
write_oracle_table_by_batch <- function(
  conn,
  lazy_df,
  output_table_name,
  start_date,
  end_date,
  dis_dtd_lag_months = 6,
  batch_by = "month",
  batch_colname = NULL
) {
  check_output_table_name(output_table_name, conn)
  stopifnot(
    batch_by %in% c("month", "year")
  )
  is_dcir_table <- "FLX_DIS_DTD" %in% colnames(lazy_df)
  if (is_dcir_table) {
    # For DCIR tables, take into account the lag of input data into SNDS
    batch_colname <- "FLX_DIS_DTD"
    extract_end_date <-
      end_date |>
      lubridate::add_with_rollback(months(dis_dtd_lag_months)) |>
      lubridate::floor_date("months")
  } else {
    extract_end_date <- end_date
  }
  # TODO: if the table is not from DCIR (then it is PMSI), so maybe we should put EXE_SOI_DTD as default #nolint
  stopifnot(
    batch_colname %in% colnames(lazy_df)
  )

  # create range
  batch_range <- seq(
    from = as.Date(start_date),
    to = as.Date(extract_end_date),
    by = batch_by
  )

  pb <- progress::progress_bar$new(
    format = "Extracting :batch (going from :start  to :end) [:bar] :percent in :elapsed (eta: :eta)", # nolint
    total = length(batch_range),
    clear = FALSE,
    width = 80
  )
  pb$tick(0)
  batch_range |>
    purrr::map(function(batch_start) {
      pb$tick(
        tokens = list(
          batch = batch_start,
          start = batch_range[1],
          end = batch_range[length(batch_range)]
        )
      )
      batch_end <- lubridate::ceiling_date(batch_start, unit = batch_by)
      batch_query <- lazy_df |>
        dplyr::filter(
          .data[[batch_colname]] >= as.Date(batch_start) &
            .data[[batch_colname]] < as.Date(batch_end)
        ) |>
        dbplyr::sql_render()
      # write to oracle
      is_first_batch <- batch_start == batch_range[1]

      if (is_first_batch) {
        DBI::dbExecute(
          conn,
          glue::glue("CREATE TABLE {output_table_name} AS {batch_query}")
        )
      } else {
        DBI::dbExecute(
          conn,
          glue::glue("INSERT INTO {output_table_name} {batch_query}")
        )
      }
    })
}
