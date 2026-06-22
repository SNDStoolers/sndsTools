# =============================================================================
# Démo locale : extract_deaths() sur DuckDB
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
# POURQUOI DES DONNÉES FICTIVES, ET NON LA BASE SYNTHÉTIQUE ?
# ----------------------------------------------------------
# extract_deaths() s'appuie sur la date de décès BEN_DCD_DTE des tables des
# causes médicales de décès (KI_CCI_R, KI_ECD_R). Or, dans la base synthétique
# « corrigée » (parquet de SNDStoolers/synthetic_snds) chargée par
# connect_synthetic_snds(), la colonne BEN_DCD_DTE est actuellement NULL : les
# dates de décès, au format SAS dans la source, n'ont pas été parsées lors de la
# conversion en parquet. Sur ces données, extract_deaths() ne renverrait donc
# aucune ligne, quelle que soit la période.
#
# Ce notebook se rend par conséquent AUTONOME : il crée une petite base DuckDB
# EN MÉMOIRE et y écrit des tables de décès FICTIVES (avec de vraies dates) pour
# démontrer le comportement de extract_deaths(). Aucune donnée n'est téléchargée.
#
# FORMAT DE SORTIE : extract_deaths() renvoie une LAZY TABLE (requête dbplyr non
# encore évaluée) tant que output_table_name n'est pas fourni. La requête n'est
# exécutée qu'au moment du dplyr::collect() : cela permet de l'enchaîner avec
# d'autres traitements et de laisser Oracle optimiser. On collecte donc
# ci-dessous pour afficher les résultats. Une fois collectée, on obtient UNE
# LIGNE PAR CODE CIM-10 et par patient décédé, avec les colonnes BEN_IDT_ANO,
# EXE_SOI_DTD, CIM_COD et STATUS. STATUS vaut "Initial cause" si le code est la
# cause initiale du décès (KI_CCI_R), "Other" pour les autres codes de
# l'ensemble des causes (KI_ECD_R).
# =============================================================================

# %% [1] Chargement du package depuis les sources locales -----------------------
# Pas besoin d'installer le package : pkgload::load_all() charge toutes les
# fonctions à partir du dossier R/. here::here() retrouve la racine du dépôt
# quel que soit le répertoire de travail. Les tableaux de décès sont affichés
# avec knitr::kable() (table markdown lisible en console).
library(dplyr)
pkgload::load_all(here::here())

# %% [2] Base DuckDB en mémoire --------------------------------------------------
# Connexion DuckDB EN MÉMOIRE (aucun fichier, donc aucun verrou ni
# téléchargement). shutdown = TRUE à la fermeture (cellule [8]) libère tout.
conn <- duckdb::dbConnect(duckdb::duckdb())

# %% [2b] Tables de décès fictives ----------------------------------------------
# On reproduit le schéma des deux tables des causes médicales de décès :
#   KI_CCI_R = cause initiale du décès (colonne DCD_CIM_COD) -> "Initial cause"
#   KI_ECD_R = ensemble des causes (colonne ECD_CIM_COD)     -> "Other"
# Dates volontairement réparties sur plusieurs années pour illustrer le filtre
# de période. P5 n'a pas de cause initiale (lignes "Other" uniquement).
fake_ki_cci_r <- data.frame(
  BEN_IDT_ANO = c("P1", "P2", "P3", "P4"),
  DCD_CIM_COD = c("M170", "W010", "I219", "W199"),
  BEN_DCD_DTE = as.Date(c("2015-06-01", "2003-04-10", "2018-02-02", "2010-09-15")),
  stringsAsFactors = FALSE
)
fake_ki_ecd_r <- data.frame(
  BEN_IDT_ANO = c("P1", "P1", "P1", "P2", "P3", "P4", "P5", "P5"),
  ECD_CIM_COD = c("M170", "I10", "E11", "X59", "N179", "S065", "M545", "W500"),
  BEN_DCD_DTE = as.Date(c(
    "2015-06-01", "2015-06-01", "2015-06-01", "2003-04-10",
    "2018-02-02", "2010-09-15", "2017-03-03", "2017-03-03"
  )),
  stringsAsFactors = FALSE
)
DBI::dbWriteTable(conn, "KI_CCI_R", fake_ki_cci_r, overwrite = TRUE)
DBI::dbWriteTable(conn, "KI_ECD_R", fake_ki_ecd_r, overwrite = TRUE)
DBI::dbListTables(conn)

# %% [3] Scénario A : tous les décès sur une large période -----------------------
# Sans filtre, extract_deaths() renvoie tous les décès de la période, une ligne
# par code CIM-10 et par patient. Un patient peut donc apparaître sur plusieurs
# lignes ; un code déjà rapporté comme cause initiale n'est pas dupliqué en
# "Other".
all_deaths <- extract_deaths(
  start_date = as.Date("1980-01-01"),
  end_date = as.Date("2020-12-31"),
  conn = conn
) |>
  dplyr::collect()
cat("Nombre de lignes (codes) extraites :", nrow(all_deaths), "\n")
cat(
  "Nombre de patients décédés :",
  dplyr::n_distinct(all_deaths$BEN_IDT_ANO), "\n"
)
print(knitr::kable(all_deaths))

# %% [4] Scénario B : décès par code CIM-10 (recherche par préfixe) ---------------
# "M" capture tous les codes de cause commençant par M. La recherche se fait dans
# la cause initiale (KI_CCI_R) ET dans l'ensemble des causes (KI_ECD_R) : un
# patient est retenu dès qu'un de ses codes correspond, et toutes ses lignes sont
# renvoyées.
deaths_m <- extract_deaths(
  start_date = as.Date("1980-01-01"),
  end_date = as.Date("2020-12-31"),
  diagnosis_codes_filter = c("M"),
  conn = conn
) |>
  dplyr::collect()
cat("Décès avec une cause en 'M' :", nrow(deaths_m), "\n")
print(knitr::kable(deaths_m))

# %% [5] Scénario C : effet du filtre de période ---------------------------------
# Mêmes codes ("W"), mais une fenêtre temporelle restreinte : P2 (2003) disparaît
# quand on ne garde que 2005-2020.
deaths_w_all <- extract_deaths(
  start_date = as.Date("1980-01-01"),
  end_date = as.Date("2020-12-31"),
  diagnosis_codes_filter = c("W"),
  conn = conn
) |>
  dplyr::collect()
deaths_w_recent <- extract_deaths(
  start_date = as.Date("2005-01-01"),
  end_date = as.Date("2020-12-31"),
  diagnosis_codes_filter = c("W"),
  conn = conn
) |>
  dplyr::collect()
cat(
  "Décès en 'W' : période large =", nrow(deaths_w_all),
  "| depuis 2005 =", nrow(deaths_w_recent), "\n"
)

# %% [6] Scénario D : sauvegarde du résultat dans une table ----------------------
# Avec output_table_name, le résultat est écrit dans une table de la base (via
# "CREATE TABLE ... AS SELECT", sans transiter par R) et la fonction renvoie NULL
# de manière invisible.
output_table_name <- "TMP_DEMO_DEATH"
if (DBI::dbExistsTable(conn, output_table_name)) {
  DBI::dbRemoveTable(conn, output_table_name)
}

extract_deaths(
  start_date = as.Date("1980-01-01"),
  end_date = as.Date("2020-12-31"),
  diagnosis_codes_filter = c("M"),
  output_table_name = output_table_name,
  conn = conn
)

# On relit la table créée pour vérifier son contenu.
dplyr::tbl(conn, output_table_name) |>
  dplyr::collect() |>
  knitr::kable() |>
  print()

# %% [7] Scénario E : extraction par liste d'identifiants ------------------------
# Avec patient_ids_filter, chaque identifiant fourni est restitué : ses causes de
# décès, ou une ligne STATUS == "Alive" (CIM_COD et EXE_SOI_DTD à NA) s'il n'a
# aucun décès correspondant dans la période (inconnu, ou décès hors période).

# Quelques identifiants réellement décédés (repris du scénario A)...
sample_dead_ids <- head(unique(all_deaths$BEN_IDT_ANO), 3)
# ...et des identifiants fictifs, absents des tables de décès -> "Alive".
fake_alive_ids <- c("FAKE_ALIVE_001", "FAKE_ALIVE_002")

deaths_by_ids <- extract_deaths(
  start_date = as.Date("1980-01-01"),
  end_date = as.Date("2020-12-31"),
  patient_ids_filter = c(sample_dead_ids, fake_alive_ids),
  conn = conn
) |>
  dplyr::collect()
cat("Répartition des STATUS (dont Alive) :\n")
print(table(deaths_by_ids$STATUS, useNA = "ifany"))
print(knitr::kable(deaths_by_ids))

# %% [8] Fermeture de la connexion -----------------------------------------------
DBI::dbDisconnect(conn, shutdown = TRUE)
