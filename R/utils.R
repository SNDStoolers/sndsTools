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
connect_duckdb <- function(db_dir = NULL) {
  if (is.null(db_dir)) {
    db_dir <- ":memory:"
  }
  logger:::log_info(
    glue::glue("Initialisation d'une connexion duckdb à {db_dir}.")
  )
  conn <- DBI::dbConnect(duckdb::duckdb(), db_dir)

  # Generate fake user_synonyms table for testing: used in all er_prs_f
  # functions
  user_synonyms <- data.frame(
    SYNONYM_NAME = c("ER_PRS_F_2009", "ER_PRS_F_2010")
  )
  DBI::dbWriteTable(conn, "user_synonyms", user_synonyms, overwrite = TRUE)
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


parallelize_query_by_flx_month <- function(
  conn,
  start_date,
  end_date,
  query_builder_function,
  query_builder_kwargs,
  dis_dtd_lag_months = 6,
  r_cluster_cores = 1
) {
  # Date stuff
  ## Healthcare dates
  start_year <- lubridate::year(start_date)
  start_month <- lubridate::month(start_date)
  formatted_start_date <- format(start_date, "%Y-%m-%d")
  formatted_end_date <- format(end_date, "%Y-%m-%d")
  ## Flux dates: adding a lag
  dis_dtd_end_date <- end_date |>
    lubridate::add_with_rollback(months(dis_dtd_lag_months)) |>
    lubridate::floor_date("months")
  dis_dtd_end_month <- lubridate::month(format(dis_dtd_end_date, "%Y-%m-%d"))
  end_year <- lubridate::year(dis_dtd_end_date)

  months_to_process <- list()
  month_index <- 1
  for (year in start_year:end_year) {
    flux_start_month <- 1
    flux_end_month <- 12
    if (year == end_year) {
      flux_end_month <- dis_dtd_end_month
    }
    # do not query months before the start date
    if (year == start_year) {
      flux_start_month <- max(1, start_month)
    }

    for (month in c(flux_start_month:flux_end_month)) {
      is_first_month <- (year == start_year && month == flux_start_month)

      months_to_process[[month_index]] <- c(
        list(
          dis_dtd_year = year,
          dis_dtd_month = month,
          is_first_month = is_first_month,
          formatted_start_date = formatted_start_date,
          formatted_end_date = formatted_end_date,
          end_year = end_year
        ),
        query_builder_kwargs
      )
      month_index <- month_index + 1
    }
  }
  if (!is.null(r_cluster_cores) && r_cluster_cores > 1) {
    logger::log_info(glue::glue(
      "Starting parallel processing with {r_cluster_cores} cores"
    ))

    cl <- parallel::makeCluster(r_cluster_cores)
    on.exit(parallel::stopCluster(cl), add = TRUE)

    # Export packages and fonctions to workers
    parallel::clusterEvalQ(cl, {
      # TODO: should not be necessary since prefix usage in query_builder_function.
      library(dplyr)
      library(dbplyr)
      library(glue)
      library(DBI)
      library(lubridate)
      source(here::here("sndsTools.R"))
      is_portail <- constants_snds()$is_portail
      # Export the same Oracle connexion to workers
      if (!is_portail) {
        #TODO: not possible to use month parallelization in duckdb since there is a lock on the database
        conn <<- connect_duckdb("tmp_db")
      } else {
        conn <<- connect_oracle()
      }
    })

    # Export to each worker the builder function
    parallel::clusterExport(
      cl,
      "query_builder_function",
      envir = environment()
    )

    # First month to create the table
    first_month_params <- months_to_process[[1]]
    first_month_params$conn <- conn
    query_builder_function(first_month_params)

    # Process the other months in parallel
    parallel::parLapply(
      cl,
      months_to_process[-1],
      query_builder_function
    )

    # Close connexions in each worker (? Necessary?)
    parallel::clusterEvalQ(cl, {
      DBI::dbDisconnect(conn)
    })

    logger::log_info("Parallel processing completed")
  } else {
    #
    logger::log_info("Starting sequential processing")
    months_to_process_with_conn <- lapply(months_to_process, function(m) {
      m$conn <- conn
      m
    })
    invisible(lapply(
      months_to_process_with_conn,
      query_builder_function
    ))
  }
}
