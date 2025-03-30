#' Initialisation de la connexion à la base de données.
#'
#' @return dbConnection Connexion à la base de données oracle
#'
#' @export
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
create_table_from_query <- function(conn = NULL,
                                    output_table_name = NULL,
                                    query = NULL,
                                    overwrite = FALSE) {
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
insert_into_table_from_query <- function(
    conn = NULL,
    output_table_name = NULL,
    query = NULL) {
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
gather_table_stats <- function(conn, table) {
  user <- DBI::dbGetQuery(conn, "SELECT user FROM dual")
  user <- DBI::dbQuoteIdentifier(conn, user$USER)
  DBI::dbExecute(
    conn,
    "BEGIN DBMS_STATS.GATHER_TABLE_STATS(:1, :2); END;",
    data = data.frame(user, table)
  )
}

#' Télécharge et zip les données synthétiques du SNDS
#'
#' @description
#' Télécharge [les données fictives du
#' SNDS](https://www.data.gouv.fr/fr/datasets/donnees-synthetiques-de-la-base-principales-du-systeme-national-des-donnees-de-sante/)
#' disponible sur datagouv.fr. Puis, zip dans une seul fichier
#' `synthetic_data.zip` toutes les tables des données fictives. Sauvegarde ce
#' fichier zip dans le répertoire `inst/extdata` du package.
#' @return Le chemin vers le répertoire contenant le fichier zip contenant les
#' données.
#' @export
download_synthetic_snds <- function() {
  # Utilisation du répertoire inst/extdata standard pour les packages R
  pkg_root <- rprojroot::find_package_root_file()
  extdata_dir <- file.path(pkg_root, "inst", "extdata")
  synthetic_data_dir <- file.path(extdata_dir, "synthetic_data")
  if (!dir.exists(synthetic_data_dir)) {
    dir.create(synthetic_data_dir, recursive = TRUE)
  }
  snds_produits <- list(dcir_tables = "https://www.data.gouv.fr/fr/datasets/r/33b5e0ac-cf40-49be-9026-30525f667ca1")
  snds_produits <- list(dcir_tables = "https://www.data.gouv.fr/fr/datasets/r/33b5e0ac-cf40-49be-9026-30525f667ca1", mco_tables = "https://www.data.gouv.fr/fr/datasets/r/832cfa99-5106-4081-be16-520991375e6d", had_tables = "https://www.data.gouv.fr/fr/datasets/r/9dcf3637-ec46-4188-981a-2a28637f6577", ssr_tables = "https://www.data.gouv.fr/fr/datasets/r/877d3a9f-8ea0-4925-987a-cfb2f53bbc72", rimp_tables = "https://www.data.gouv.fr/fr/datasets/r/2a4fa5d4-245d-4e21-bad2-7b438199e3c8", beneficiaries_tables = "https://www.data.gouv.fr/fr/datasets/r/a57fcd0f-e63a-48f0-ba73-f8e93a15aec2", cartographie_pathologies_tables = "https://www.data.gouv.fr/fr/datasets/r/e75e0fc2-0acf-4f58-8b4f-fcc26b651918", causes_de_deces_tables = "https://www.data.gouv.fr/fr/datasets/r/3b9a7898-9bcf-4839-aeb2-ccb3e4990b03") # nolint

  for (produit in names(snds_produits)) {
    zip_url <- snds_produits[[produit]]
    # Define the destination file path
    zip_file <- tempfile(fileext = ".zip")
    # Download the zip file
    download.file(zip_url, zip_file, mode = "wb")
    # Unzip the file to a temporary directory
    unzip_dir <- tempdir()
    # Use system unzip with UTF-8 encoding to handle Latin-encoded names
    system(
      glue::glue(
        "unzip -o -O LATIN1 {shQuote(zip_file)} -d {shQuote(synthetic_data_dir)}" # nolint
      )
    )
  }

  dir2produits <- list.dirs(synthetic_data_dir, full.names = TRUE)
  # zip all the directories into one zip file
  zip_file <- file.path(extdata_dir, "synthetic_data.zip")
  zip(zip_file, dir2produits, flags = "-r9Xj", extras = "-i *.csv")
  # Remove the unzipped directories
  print(dir2produits)
  for (dir in dir2produits) {
    unlink(dir, recursive = TRUE)
  }
  return(zip_file)
}

#' Charger les données synthétiques du SNDS
#'
#' @description
#' Cette fonction charge les données synthétiques du SNDS à partir d'un fichier
#' zip contenu dans le répertoire `synthetic_data.zip`. Ce fichier zip contient
#' un fichier CSV pour chaque table du SDNS.
#'
#' @details
#' Le fichier zip `synthetic_data.zip` a été obtenu en téléchargeant [les
#' données fictives du
#' SNDS](https://www.data.gouv.fr/fr/datasets/donnees-synthetiques-de-la-base-principales-du-systeme-national-des-donnees-de-sante/)
#' disponible sur datagouv.fr. Ces données ont été générées en 2019 grâce au
#' [schéma formel du
#' SNDS](https://gitlab.com/healthdatahub/applications-du-hdh/schema-snds) et au
#' projet
#' [synthetic-generator](https://gitlab.com/healthdatahub/se-former-au-snds/synthetic-generator/).
#'
#' @return Une liste de data frames, chacun correspondant à un fichier CSV dans
#' le zip.
#' @examples
#' # Charger les données synthétiques
#' donnees_synthetiques <- load_synthetic_snds("chemin/vers/synthetic_data.zip")
#' # Accéder à un data frame spécifique
#' #' df <- donnees_synthetiques[["ER_PRS_F"]]
#' #' # Afficher les premières lignes du data frame
#' #' print(head(df))
#' @export
load_synthetic_snds <- function() {
  # Create a temporary directory to extract the zip file
  temp_dir <- tempdir()
  path2zip <- file.path(
    rprojroot::find_package_root_file(),
    "inst",
    "extdata",
    "synthetic_data.zip"
  )
  unzip(path2zip, exdir = temp_dir)

  # List all CSV files in the extracted directory
  csv_files <- list.files(temp_dir, pattern = "\\.csv$", full.names = TRUE)

  # Read each CSV file into a data frame and store in a list
  data_list <- lapply(csv_files, read.csv,
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8",
    sep = ";"
  )
  names(data_list) <- gsub("\\.csv$", "", basename(csv_files))

  return(data_list)
}

#' Charge et insére les données synthétiques du SNDS dans une base de données
#' temporaire
#'
#' @description
#' Cette fonction charge les données synthétiques du SNDS à partir d'un fichier
#' zip contenu dans le répertoire `synthetic_data.zip`.
#' Ensuite elle insère chaque table dans une base de données temporaire.
#' @param conn Connexion à la base de données
#' @examples
#' # Connexion à la base de données
#' conn <- connect_duckdb()
#' # Insérer les données synthétiques
#' insert_synthetic_snds(conn)
#' # Vérifier les tables insérées
#' tables <- DBI::dbListTables(conn)
#' print(tables[[1, 10]])
#' @export
insert_synthetic_snds <- function(conn) {
  # Load the synthetic data
  synthetic_data <- load_synthetic_snds()

  # Loop through each data frame in the list and insert into the database
  for (table_name in names(synthetic_data)) {
    df <- synthetic_data[[table_name]]
    # force datetime conversion
    if ("EXE_SOI_DTD" %in% colnames(df)) {
      # Convert the EXE_SOI_DTD column to Date format
      df$EXE_SOI_DTD <- as.Date(df$EXE_SOI_DTD, format = "%d/%m/%Y")
    }
    if ("EXE_SOI_DTF" %in% colnames(df)) {
      # Convert the EXE_SOI_DTF column to Date format
      df$EXE_SOI_DTF <- as.Date(df$EXE_SOI_DTF, format = "%d/%m/%Y")
    }
    if ("FLX_DIS_DTD" %in% colnames(df)) {
      # Convert the FLX_DIS_DTD column to Date format
      df$FLX_DIS_DTD <- as.Date(df$FLX_DIS_DTD, format = "%d/%m/%Y")
    }

    # Write the data frame to the database
    DBI::dbWriteTable(conn, table_name, df)
  }
}
