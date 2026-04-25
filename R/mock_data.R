#' Download synthetic SNDS data and load into a DuckDB database
#'
#' Automatically downloads all synthetic SNDS data files from Health Data Hub's
#' data.gouv.fr API endpoints, unzips them, reads the CSVs, and loads them into
#' a local DuckDB database.
#'
#' @param db_path Character. Path to the DuckDB database file to create.
#'   Defaults to `./synthetic_snds.duckdb` in the current working directory.
#' @param force_download Logical. If TRUE, re-download all files even if the
#'   database already exists (default FALSE). If FALSE and the database exists,
#'   the function returns the existing database path without re-downloading.
#' @param verbose Logical. If TRUE, prints progress messages during download and loading.
#' @return DuckDB connection. A duckdb connection to the created DuckDB database file.
#'
#' @details
#' This function downloads 9 zip files containing synthetic data for 50
#' fictitious patients based on the 2019 SNDS schema. The files are produced
#' by Health Data Hub and hosted on data.gouv.fr.
#'
#' @section Note:
#' The `duckdb` package must be installed for this function to work.
#'
#' @export
#' @family mock_data
get_synthetic_snds <- function(
  db_path = NULL,
  force_download = FALSE
) {
  if (is.null(db_path)) {
    db_path <- path.expand(FNAME_SYNTHETIC_SNDS)
  }
  # Create parent directory if needed
  db_dir <- dirname(db_path)
  if (!dir.exists(db_dir)) {
    dir.create(db_dir, recursive = TRUE)
  }
  # If database exists and no force, return
  if (file.exists(db_path) && !force_download) {
    logger::log_info("Database already exists at: %s", db_path)
    conn <- DBI::dbConnect(duckdb::duckdb(), db_path)
    return(invisible(conn))
  }
  logger::log_info(
    paste0("Creating database at: %s", db_path)
  )
  # Remove old db if exists with force
  if (file.exists(db_path)) {
    file.remove(db_path)
  }
  # check that files does not exists at the db_path
  expected_synthetic_dirs <- c(
    "SSR",
    "RIM-P",
    "MCO",
    "HAD",
    "DCIR_DCIRS",
    "DCIR",
    "Causes_de_Deces",
    "CARTOGRAPHIE_PATHOLOGIES",
    "BENEFICIAIRE"
  )
  # Check if all synthetic directories are already present in the db_dir
  synthetic_dirs <- list.dirs(db_dir, recursive = FALSE, full.names = TRUE)
  inter <- intersect(expected_synthetic_dirs, basename(synthetic_dirs))
  if (length(inter) == length(expected_synthetic_dirs)) {
    # download the synthetic data CSV files
    download_synthetic_snds_csv(db_dir)
  }

  # Create temp directory for unzipping

  # Connect to DuckDB
  conn <- DBI::dbConnect(duckdb::duckdb(), db_path)
  on.exit(DBI::dbDisconnect(conn), add = TRUE)
  # Insert all CSV files in all extracted subdirectories
  for (synthetic_dir in csv_dir) {
    if (length(synthetic_dir) == 0) {
      logger::log_warn("No CSV files found in %s", zip_name)
      next
    }
    # Process each CSV file
    for (csv_file in synthetic_dir) {
      insert_synthetic_snds_table(conn, csv_file)
    }
  }

  # List loaded tables
  tables <- DBI::dbListTables(conn)
  message(
    "Successfully loaded ",
    length(tables),
    " tables: ",
    paste(tables, collapse = ", ")
  )
  return(invisible(conn))
}

download_synthetic_snds_csv <- function(db_path, verbose = TRUE) {
  synth_resources <- c(
    "SSR" = "877d3a9f-8ea0-4925-987a-cfb2f53bbc72",
    "RIM-P" = "2a4fa5d4-245d-4e21-bad2-7b438199e3c8",
    "MCO" = "832cfa99-5106-4081-be16-520991375e6d",
    "HAD" = "9dcf3637-ec46-4188-981a-2a28637f6577",
    "DCIR_DCIRS" = "ab204542-5894-4891-b8e0-af3379677f9e",
    "DCIR" = "33b5e0ac-cf40-49be-9026-30525f667ca1",
    "Causes_de_Deces" = "3b9a7898-9bcf-4839-aeb2-ccb3e4990b03",
    "CARTOGRAPHIE_PATHOLOGIES" = "e75e0fc2-0acf-4f58-8b4f-fcc26b651918",
    "BENEFICIAIRE" = "a57fcd0f-e63a-48f0-ba73-f8e93a15aec2"
  )
  synth_url_base <- "https://www.data.gouv.fr/api/1/datasets/r/"
  synthetic_urls <- paste0(
    synth_url_base,
    synth_resources
  )

  # Create progress bar
  pb <- progress::progress_bar$new(
    format = "Downloading [:bar] :percent | :current / :total files",
    total = length(synthetic_urls),
    clear = FALSE,
    width = 60
  )

  # Download and process each zip file
  for (i in seq_along(synthetic_urls)) {
    url <- synthetic_urls[i]
    zip_name <- basename(url)
    pb$tick()
    # Download zip file
    zip_path <- file.path(temp_dir, zip_name)
    tryCatch(
      utils::download.file(url, zip_path, mode = "wb", quiet = TRUE),
      error = function(e) {
        stop("Failed to download: ", zip_name, " error: ", e$message)
      }
    )

    # Unzip
  }
  if (verbose) {
    utils::unzip(zip_path, exdir = temp_dir)
    file.remove(zip_path)
  }
  if (verbose) {
    logger::log_info("All files downloaded and extracted to: %s", temp_dir)
  }
}

insert_synthetic_snds_table <- function(conn, path2csv) {
  table_name <- tools::file_path_sans_ext(basename(path2csv))
  # Read CSV
  df <- readr::read_csv(
    path2csv,
    na = c("", "NA"),
    col_types = readr::cols(.default = readr::col_guess())
  )

  # Write table to DuckDB (overwrite if exists)
  if (DBI::dbExistsTable(conn, table_name)) {
    DBI::dbRemoveTable(conn, table_name)
  }
  DBI::dbWriteTable(
    conn,
    table_name,
    df,
    overwrite = TRUE,
    row.names = FALSE
  )
}
