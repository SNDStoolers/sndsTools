# =============================================================================
# Démo locale : extract_death() sur les données synthétiques SNDS (DuckDB)
# =============================================================================
#
# COMMENT FONCTIONNE UN "NOTEBOOK" R ?
# ------------------------------------
# Il n'y a pas de format ".ipynb" ici : un "notebook" R est simplement un
# script .R que l'on exécute *interactivement*, ligne par ligne, plutôt que
# d'un seul bloc. Trois façons de le lancer :
#
#   1. Dans RStudio ou VS Code (extension R) : place le curseur sur une ligne
#      (ou sélectionne un bloc) et fais Ctrl+Entrée (Cmd+Entrée sur Mac). La
#      ligne est envoyée à la console R et le résultat s'affiche.
#
#   2. Les marqueurs "# %%" ci-dessous découpent le script en "cellules".
#      Dans VS Code, un bouton "Run Cell" apparaît au-dessus de chaque "# %%"
#      et exécute tout le bloc jusqu'à la cellule suivante.
#
#   3. Tout d'un coup, depuis un terminal à la racine du dépôt :
#         Rscript notebooks/demo_death.R
#
# Ce notebook se connecte à la base synthétique SNDS (50 patients fictifs,
# téléchargée automatiquement au besoin), corrige "à la volée" le format de la
# date de décès, puis appelle extract_death() sur plusieurs scénarios.
#
# FORMAT DE SORTIE (V2) : extract_death() renvoie UNE LIGNE PAR CODE CIM-10 et
# par patient décédé, avec les colonnes BEN_IDT_ANO, EXE_SOI_DTD, CIM_COD et
# STATUS. STATUS vaut "Initial cause" si le code est la cause initiale du décès
# (KI_CCI_R), "Other" pour les autres codes de l'ensemble des causes (KI_ECD_R).
# =============================================================================

# %% [1] Chargement du package depuis les sources locales -----------------------
# Pas besoin d'installer le package : pkgload::load_all() charge toutes les
# fonctions à partir du dossier R/. here::here() retrouve la racine du dépôt
# quel que soit le répertoire de travail.
library(dplyr)
pkgload::load_all(here::here())

# %% [1b] Affichage "joli" du tableau de décès ----------------------------------
# extract_death() renvoie une ligne par code CIM-10. print_deaths_pretty()
# affiche ce tableau LIGNE PAR LIGNE, colonnes alignées, pour une lecture
# rapide en console :
#   BEN_IDT_ANO        DATE        CIM     STATUS
#   aQsInJLbqvXKdQGHK  1998-06-26  V598    Initial cause
# Par défaut toutes les lignes sont affichées ; passer `n` pour en limiter le
# nombre (ex. print_deaths_pretty(all_deaths, n = 10)).
print_deaths_pretty <- function(deaths, n = Inf) {
  deaths <- as.data.frame(deaths)
  total <- nrow(deaths)
  if (total == 0L) {
    cat("(aucune ligne)\n")
    return(invisible(deaths))
  }
  shown <- utils::head(deaths, n)

  idt_v <- shown$BEN_IDT_ANO
  dte_v <- format(shown$EXE_SOI_DTD)
  cod_v <- shown$CIM_COD
  sta_v <- shown$STATUS

  # Affiche les NA comme "NA" (notamment CIM_COD/EXE_SOI_DTD des patients vivants).
  na_to_chr <- function(x) {
    x <- as.character(x)
    x[is.na(x)] <- "NA"
    x
  }
  idt_v <- na_to_chr(idt_v)
  dte_v <- na_to_chr(dte_v)
  cod_v <- na_to_chr(cod_v)

  # Largeur de chaque colonne = max(titre, valeurs) pour aligner en-tête et données.
  w_idt <- max(nchar(c(idt_v, "BEN_IDT_ANO")))
  w_dte <- max(nchar(c(dte_v, "DATE")))
  w_cod <- max(nchar(c(cod_v, "CIM")))

  fmt <- function(x, w) formatC(as.character(x), flag = "-", width = w)
  line <- function(a, b, c, d) {
    paste(fmt(a, w_idt), fmt(b, w_dte), fmt(c, w_cod), d)
  }

  header <- line("BEN_IDT_ANO", "DATE", "CIM", "STATUS")
  cat(header, "\n", sep = "")
  cat(strrep("-", nchar(header)), "\n", sep = "")
  cat(line(idt_v, dte_v, cod_v, sta_v), sep = "\n")
  cat("\n")
  if (total > nrow(shown)) {
    cat(sprintf("... (%d lignes affichées sur %d)\n", nrow(shown), total))
  }
  invisible(deaths)
}

# %% [2] Connexion à la base synthétique ----------------------------------------
# connect_synthetic_snds() télécharge les données (si absentes) et charge les
# tables demandées dans une base DuckDB locale. On ne charge ici que les deux
# tables des causes médicales de décès, pour aller vite.
data_dir <- path.expand("~/.cache/sndsTools")
path2db <- file.path(data_dir, "synthetic_snds.duckdb")

conn <- connect_synthetic_snds(
  path2db = path2db,
  subset_tables = c("KI_ECD_R", "KI_CCI_R")
)

# KI_CCI_R = circonstances et CAUSE INITIALE du décès (colonne DCD_CIM_COD)
#            -> lignes STATUS == "Initial cause"
# KI_ECD_R = ENSEMBLE DES CAUSES du décès (colonne ECD_CIM_COD)
#            -> lignes STATUS == "Other"
DBI::dbListTables(conn)

# %% [3] Le problème : la date de décès est NA après chargement ------------------
# La date BEN_DCD_DTE est stockée au format SAS (ex. "26Jun1998:18:15:58"), mais
# le chargement standard l'interprète avec le format "%d/%m/%Y". Résultat : la
# colonne est NA partout, donc le filtre sur la période ne peut pas fonctionner.
dplyr::tbl(conn, "KI_ECD_R") |>
  dplyr::select(BEN_IDT_ANO, ECD_CIM_COD, BEN_DCD_DTE) |>
  head() |>
  dplyr::collect()

# %% [4] Correction "à la volée" du format de date -------------------------------
# On relit les CSV bruts en parsant BEN_DCD_DTE avec son vrai format
# "%d%b%Y:%H:%M:%S" (locale anglaise forcée car les mois sont en anglais :
# Jun, Dec...), puis on réécrit les tables dans la base.
#
# NB : ceci est un correctif LOCAL au notebook. Le correctif propre du pipeline
# de chargement (get_kwikly_format / synthetic_data.R) est un sujet séparé.
load_death_table_with_dates <- function(conn, csv_path, table_name) {
  df <- readr::read_delim(
    csv_path,
    delim = ";",
    show_col_types = FALSE,
    # On lit toutes les colonnes en texte (évite les avertissements de parsing
    # sur la donnée synthétique) ; seule BEN_DCD_DTE est ensuite convertie.
    col_types = readr::cols(.default = readr::col_character())
  )
  df$BEN_DCD_DTE <- as.Date(readr::parse_datetime(
    df$BEN_DCD_DTE,
    format = "%d%b%Y:%H:%M:%S",
    locale = readr::locale(date_names = "en")
  ))
  DBI::dbWriteTable(conn, table_name, df, overwrite = TRUE)
  invisible(table_name)
}

load_death_table_with_dates(
  conn,
  file.path(data_dir, "Causes_de_Deces", "KI_ECD_R.csv"),
  "KI_ECD_R"
)
load_death_table_with_dates(
  conn,
  file.path(data_dir, "Causes_de_Deces", "KI_CCI_R.csv"),
  "KI_CCI_R"
)

# Vérification : les dates sont désormais correctement remplies.
dplyr::tbl(conn, "KI_ECD_R") |>
  dplyr::select(BEN_IDT_ANO, ECD_CIM_COD, BEN_DCD_DTE) |>
  head() |>
  dplyr::collect()

# %% [5] Scénario A : tous les décès sur une large période -----------------------
# Sans diagnosis_codes, extract_death() renvoie tous les décès de la période,
# une ligne par code CIM-10 et par patient, avec :
#   - CIM_COD : un code CIM-10 associé au décès ;
#   - STATUS  : "Initial cause" (cause initiale, KI_CCI_R) ou "Other" (autre
#               code de l'ensemble des causes, KI_ECD_R).
# Un patient peut donc apparaître sur plusieurs lignes.
all_deaths <- extract_death(
  start_date = as.Date("1980-01-01"),
  end_date = as.Date("2020-12-31"),
  conn = conn
)
cat("Nombre de lignes (codes) extraites :", nrow(all_deaths), "\n")
cat(
  "Nombre de patients décédés :",
  dplyr::n_distinct(all_deaths$BEN_IDT_ANO), "\n"
)
cat("Répartition des STATUS :\n")
print(table(all_deaths$STATUS))
# Affichage ligne par ligne, colonnes alignées.
print_deaths_pretty(all_deaths)

# %% [6] Scénario B : décès par code CIM-10 (recherche par préfixe) ---------------
# "M" capture tous les codes de cause commençant par M (appareil
# ostéo-articulaire). La recherche se fait dans la cause initiale (KI_CCI_R) ET
# dans l'ensemble des causes (KI_ECD_R) : un patient est retenu dès qu'un de ses
# codes correspond, et toutes ses lignes (codes principaux et secondaires) sont
# renvoyées.
deaths_m <- extract_death(
  start_date = as.Date("1980-01-01"),
  end_date = as.Date("2020-12-31"),
  diagnosis_codes = c("M"),
  conn = conn
)
cat("Décès avec une cause en 'M' :", nrow(deaths_m), "\n")
print_deaths_pretty(deaths_m)

# %% [7] Scénario C : effet du filtre de période ---------------------------------
# Mêmes codes ("W" = causes externes / chutes), mais une fenêtre temporelle
# restreinte : seuls les décès survenus dans la période sont conservés.
deaths_w_all <- extract_death(
  start_date = as.Date("1980-01-01"),
  end_date = as.Date("2020-12-31"),
  diagnosis_codes = c("W"),
  conn = conn
)
deaths_w_recent <- extract_death(
  start_date = as.Date("2005-01-01"),
  end_date = as.Date("2020-12-31"),
  diagnosis_codes = c("W"),
  conn = conn
)
cat(
  "Décès en 'W' : période large =", nrow(deaths_w_all),
  "| depuis 2005 =", nrow(deaths_w_recent), "\n"
)

# %% [8] Scénario D : sauvegarde du résultat dans une table ----------------------
# Avec output_table_name, le résultat est écrit dans une table de la base au
# lieu d'être renvoyé. La fonction renvoie alors NULL de manière invisible.
#
# NB (performance) : extract_death() construit sa requête de façon PARESSEUSE
# (lazy) et ne collecte jamais les tables de décès en mémoire R. Lorsque
# output_table_name est fourni, le résultat est matérialisé directement dans la
# base via "CREATE TABLE ... AS SELECT" : la donnée ne transite pas par R (pas
# de collect, pas d'aller-retour mémoire). Sans output_table_name, le collect
# n'a lieu qu'une seule fois, au moment de renvoyer le data frame.
output_table_name <- "TMP_DEMO_DEATH"
if (DBI::dbExistsTable(conn, output_table_name)) {
  DBI::dbRemoveTable(conn, output_table_name)
}

extract_death(
  start_date = as.Date("1980-01-01"),
  end_date = as.Date("2020-12-31"),
  diagnosis_codes = c("M"),
  output_table_name = output_table_name,
  conn = conn
)

# On relit la table créée pour vérifier son contenu.
dplyr::tbl(conn, output_table_name) |>
  dplyr::collect() |>
  print_deaths_pretty()

# %% [9] Scénario E : extraction par liste d'identifiants ------------------------
# extract_death_from_ids() est la fonction sœur de extract_death() : même sortie
# (une ligne par code CIM-10), mais l'entrée est une LISTE D'IDENTIFIANTS patients
# au lieu de codes diagnostics. Les identifiants sans décès dans la période
# (inconnus, ou décès hors période) sont restitués sur une ligne STATUS ==
# "Alive", avec CIM_COD et EXE_SOI_DTD à NA.

# Quelques identifiants réellement décédés (repris du scénario A)...
sample_dead_ids <- head(unique(all_deaths$BEN_IDT_ANO), 3)
# ...et des identifiants fictifs, absents des tables de décès -> "vivants".
fake_alive_ids <- c("FAKE_ALIVE_001", "FAKE_ALIVE_002")

deaths_by_ids <- extract_death_from_ids(
  patient_ids = c(sample_dead_ids, fake_alive_ids),
  start_date = as.Date("1980-01-01"),
  end_date = as.Date("2020-12-31"),
  conn = conn
)
cat("Répartition des STATUS (dont Alive) :\n")
print(table(deaths_by_ids$STATUS, useNA = "ifany"))
print_deaths_pretty(deaths_by_ids)

# %% [10] Fermeture de la connexion ----------------------------------------------
DBI::dbDisconnect(conn, shutdown = TRUE)
