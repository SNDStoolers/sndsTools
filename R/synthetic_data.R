#' Télécharge les données synthétiques SNDS et les charge dans une base DuckDB
#'
#' Télécharge les données synthétiques SNDS depuis le compte de
#' la Plateforme des Données de Santé sur data.gouv.fr avec la fonction
#' \code{\link{other_function}}, décompresse les archives ZIP, puis lit les
#' fichiers CSV et les charge dans une base DuckDB locale.
#'
#' @param path2b Character. Chemin vers le fichier de la base DuckDB à créer. La
#'   valeur par défaut est `~/.cache/sndsTools/synthetic_snds.duckdb`.
#' @param force_insert Logical. Si TRUE, force la réinsertion des données même
#'   si la base existe déjà (FALSE par défaut). Si FALSE et que la base existe,
#' la fonction retourne la connexion à la base existante sans réinsertion.
#' @param force_download Logical. Si TRUE, retélécharge tous les fichiers même
#'   si la base existe déjà (FALSE par défaut). Si FALSE et que la base existe,
#'   la fonction retourne le chemin de la base existante sans retéléchargement.
#' @param subset_tables Character vector. Si non NULL, ne charge que les tables
#' dont le nom contient une des chaînes de ce vecteur. Par exemple,
#' `subset_tables = c("T_MCO", "T_RIM")`. Par défaut, toutes les tables sont
#' chargées.
#' @return Connexion DuckDB. Une connexion duckdb vers la base DuckDB créée.
#'
#' @details Cette fonction télécharge 9 fichiers zip contenant des données
#' synthétiques pour 50 patients fictifs basés sur le schéma SNDS 2019. Les
#' fichiers sont produits par Health Data Hub et hébergés sur data.gouv.fr.
#'
#' @export
#' @family synthetic
connect_synthetic_snds <- function(
  path2db = NULL,
  force_insert = FALSE,
  force_download = FALSE,
  subset_tables = NULL
) {
  if (is.null(path2db)) {
    path2db <- path.expand(PATH2SYNTHETIC_SNDS)
  }

  # If database exists and no force, return the existing db connection
  if (file.exists(path2db) && !force_insert && !force_download) {
    logger::log_info(paste0("Connection to an existing database at: ", path2db))
    conn <- connect_duckdb(path2db = path2db)
    return(invisible(conn))
  }
  logger::log_info(
    paste0("Creating database at: ", path2db)
  )
  # Remove old db if exists with force
  if (file.exists(path2db)) {
    file.remove(path2db)
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
  dir2db <- dirname(path2db)
  # Check if all synthetic directories are already present in the db_dir
  synthetic_dirs <- list.dirs(dir2db, recursive = FALSE, full.names = TRUE)
  inter <- intersect(expected_synthetic_dirs, basename(synthetic_dirs))

  if ((length(inter) < length(expected_synthetic_dirs)) || force_download) {
    # clean existing synthetic dirs if force download
    if (length(inter) > 0) {
      for (d in inter) {
        unlink(file.path(dir2db, d), recursive = TRUE)
      }
    }
    download_synthetic_snds_csv(dir2db)
  }

  # Connect to DuckDB
  conn <- connect_duckdb(path2db = path2db)
  # Insert all CSV files in all extracted subdirectories
  csv_files <- list.files(
    dir2db,
    pattern = "\\.csv$",
    recursive = TRUE,
    full.names = TRUE
  )

  if (!is.null(subset_tables)) {
    csv_files <- csv_files[stringr::str_detect(
      csv_files,
      paste0(subset_tables, collapse = "|")
    )]
  }
  pb <- progress::progress_bar$new(
    format = "Loading tables [:bar] :percent | :current / :total files",
    total = length(csv_files),
    clear = FALSE,
    width = 60
  )

  for (csv_file in csv_files) {
    table_name <- tools::file_path_sans_ext(basename(csv_file))

    kwikly_format <- get_kwikly_format(table_name)

    insert_synthetic_snds_table(
      conn,
      csv_file,
      delim = ";",
      col_types = kwikly_format
    )
    pb$tick()
  }
  # List loaded tables
  tables <- DBI::dbListTables(conn)
  logger::log_info(
    "Successfully loaded ",
    length(tables),
    " tables: ",
    paste(tables, collapse = ", ")
  )
  invisible(conn)
}

# nolint start
#' Télécharger les fichiers CSV synthétiques SNDS
#'
#' Télécharge les fichiers zip depuis [le dépôt de la Plateforme de Données de
#' Santé sur
#' datagouv.fr](https://www.data.gouv.fr/datasets/donnees-synthetiques-de-la-base-principales-du-systeme-national-des-donnees-de-sante) et les décompresse.
#'
#' @param db_path Character. Répertoire dans lequel télécharger et extraire les fichiers.
#'
#' @return Nothing.
#'
#' @export
#' @family synthetic
# nolint end
download_synthetic_snds_csv <- function(db_path) {
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
  synthetic_urls <- stats::setNames(
    paste0(synth_url_base, synth_resources),
    names(synth_resources)
  )
  # Create progress bar
  pb <- progress::progress_bar$new(
    format = "Downloading [:bar] :percent | :current / :total files",
    total = length(synthetic_urls),
    clear = FALSE,
    width = 60
  )
  # Create directory if needed
  if (!dir.exists(db_path)) {
    dir.create(db_path, recursive = TRUE)
  }
  # Download and process each zip file
  for (i in seq_along(synthetic_urls)) {
    url <- synthetic_urls[i]
    zip_name <- names(synthetic_urls)[i]
    pb$tick()
    # Download zip file
    zip_path <- file.path(db_path, paste0(zip_name, ".zip"))
    tryCatch(
      utils::download.file(url, zip_path, mode = "wb", quiet = TRUE),
      error = function(e) {
        stop("Failed to download: ", zip_name, " error: ", e$message)
      }
    )
    # Décompression robuste sur Windows : certaines archives contiennent des
    # noms de fichiers non UTF-8, ce qui peut faire échouer utils::unzip().
    expected_dir <- file.path(db_path, zip_name)
    if (!dir.exists(expected_dir)) {
      dir.create(expected_dir, recursive = TRUE)
    }

    if (.Platform$OS.type == "windows") {
      ps_zip <- gsub(
        "'",
        "''",
        normalizePath(zip_path, winslash = "\\", mustWork = FALSE)
      )
      ps_dir <- gsub(
        "'",
        "''",
        normalizePath(expected_dir, winslash = "\\", mustWork = FALSE)
      )
      ps_cmd <- paste0(
        "Expand-Archive -LiteralPath '",
        ps_zip,
        "' -DestinationPath '",
        ps_dir,
        "' -Force"
      )
      status <- suppressWarnings(
        system2(
          "powershell",
          c("-NoProfile", "-NonInteractive", "-Command", ps_cmd),
          stdout = FALSE,
          stderr = FALSE
        )
      )
      if (!identical(status, 0L)) {
        utils::unzip(zip_path, exdir = expected_dir)
      }
    } else {
      utils::unzip(zip_path, exdir = expected_dir)
    }

    file.remove(zip_path)
  }
  logger::log_info(paste0(
    "All files downloaded and extracted to: ",
    db_path
  ))
}

#' Insérer un fichier CSV dans une table DuckDB
#'
#' Lit un fichier CSV et l'insère dans une table DuckDB. Le nom de la table est
#' dérivé du nom du fichier CSV.
#' @param conn DuckDB connection. Connexion à la base DuckDB.
#' @param path2csv Character. Chemin vers le fichier CSV à insérer.
#' @return Invisible. Retourne la connexion DuckDB après insertion.
#' @export
#' @family synthetic
insert_synthetic_snds_table <- function(
  conn,
  path2csv,
  delim = ",",
  col_types = NULL
) {
  table_name <- tools::file_path_sans_ext(basename(path2csv))
  if (is.null(col_types)) {
    col_types <- readr::cols(.default = readr::col_guess())
  }

  # Read CSV, change all booleans to numeric (no boolean in SNDS)
  df <- readr::read_delim(
    path2csv,
    col_types = col_types,
    delim = delim,
    show_col_types = FALSE
  ) |>
    dplyr::mutate(
      dplyr::across(dplyr::where(is.logical), as.numeric)
    )

  # Force annee=19 for PMSI data
  if (stringr::str_starts(table_name, "T_")) {
    table_name <- stringr::str_replace(table_name, "aa", "19")
  }
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
  invisible(conn)
}

#' Obtenir les formats de colonnes à partir du fichier kwikly
#'
#' Lit le fichier kwikly pour obtenir les formats de colonnes à utiliser lors de
#' la lecture des fichiers CSV synthétiques. Le fichier kwikly est téléchargé
#' depuis le dépôt de la CNAM si nécessaire.
#' @param table_name Character. Nom de la table pour laquelle obtenir les
#' formats de colonnes. Par exemple, "T_MCO", "T_RIM_P", etc.
#' @return Named list. Une liste nommée de formats de colonnes à utiliser avec
#' readr::cols() lors de la lecture du CSV. Les noms de la liste correspondent
#' aux noms des colonnes, et les valeurs sont des objets readr::col_* indiquant
#' le type de chaque colonne.
#' @export
#' @family synthetic
get_kwikly_format <- function(table_name) {
  url2kwikly <- "https://gitlab.com/healthdatahub/applications-du-hdh/documentation-snds/-/raw/master/snds/files/CNAM_NEW/formations/kwikly/KWIKLY_Katalogue_Sniiram_SNDS_v2026-1.xlsm" #nolint

  # download the kwikly if it does not exist in cachedir
  dir2kwikly <- file.path(DIR2SNDS_CACHE, "kwikly.xlsx")
  if (!file.exists(dir2kwikly)) {
    utils::download.file(url2kwikly, dir2kwikly, mode = "wb", quiet = TRUE)
  }
  table_name_ <- toupper(table_name)
  if (stringr::str_starts(table_name_, "T_")) {
    table_name_ <- stringr::str_replace(table_name_, "AA", "XX")
  }
  # get the sheet names
  sheet_names <- openxlsx::getSheetNames(dir2kwikly)
  if (!(table_name_ %in% sheet_names)) {
    return(NULL)
  }
  start_row <- 4
  if (table_name_ == "IR_BEN_R") {
    start_row <- 7
  }
  if (table_name_ == "IR_IMB_R") {
    start_row <- 6
  }
  kwikly_format <-
    openxlsx::read.xlsx(
      dir2kwikly,
      sheet = table_name_,
      startRow = start_row,
      colNames = TRUE
    )
  if ("Nom.variable" %in% names(kwikly_format)) {
    cols <- c("Nom.variable", "Type")
  } else {
    cols <- c("Nom.Variable", "Type")
  }
  kwikly_format <- kwikly_format |>
    dplyr::select(dplyr::all_of(cols)) |>
    dplyr::mutate(
      Type = dplyr::recode(
        Type,
        "Date" = "date",
        "Num" = "numeric",
        "Char" = "character"
      )
    )
  # In the synthetic data, some columns are boolean despite being numeric in the real SNDS. # nolint
  # First read them as boolean (to avoid NA)
  bool_cols_to_convert <- c(
    "CPL_MAJ_TOP"
  )
  kwikly_format <- kwikly_format |>
    dplyr::mutate(
      Type = ifelse(
        !!dplyr::sym(cols[1]) %in% bool_cols_to_convert,
        "boolean",
        Type
      )
    )

  setNames(
    lapply(kwikly_format$Type, function(x) {
      switch(
        x,
        "date" = readr::col_date(format = "%d/%m/%Y"),
        "numeric" = readr::col_double(),
        "character" = readr::col_character(),
        "boolean" = readr::col_logical(),
        readr::col_guess()
      )
    }),
    kwikly_format$Nom.variable
  )
}
