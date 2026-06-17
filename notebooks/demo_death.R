# =============================================================================
# Démo locale : extract_death() / extract_death_from_ids() sur DuckDB
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
# extract_death() s'appuie sur la date de décès BEN_DCD_DTE des tables des
# causes médicales de décès (KI_CCI_R, KI_ECD_R). Or, dans la base synthétique
# « corrigée » (parquet de SNDStoolers/synthetic_snds) chargée par
# connect_synthetic_snds(), la colonne BEN_DCD_DTE est actuellement NULL pour
# toutes les tables (KI_CCI_R, KI_ECD_R, IR_BEN_R, ER_PRS_F) : les dates de
# décès, au format SAS dans la source, n'ont pas été parsées lors de la
# conversion en parquet. Sur ces données, extract_death() ne renverrait donc
# aucune ligne, quelle que soit la période.
#
# Ce notebook se rend par conséquent AUTONOME : il crée une petite base DuckDB
# EN MÉMOIRE et y écrit des tables de décès FICTIVES (avec de vraies dates) pour
# démontrer le comportement de extract_death() et extract_death_from_ids().
# Aucune donnée n'est téléchargée. Dès que BEN_DCD_DTE sera renseignée en amont,
# on pourra rejouer ces mêmes appels sur connect_synthetic_snds().
#
# FORMAT DE SORTIE : extract_death() renvoie UNE LIGNE PAR CODE CIM-10 et par
# patient décédé, avec les colonnes BEN_IDT_ANO, EXE_SOI_DTD, CIM_COD et STATUS.
# STATUS vaut "Initial cause" si le code est la cause initiale du décès
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
#   BEN_IDT_ANO  DATE        CIM   STATUS
#   P1           2015-06-01  M170  Initial cause
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

  # Affiche les NA comme "NA" (notamment CIM_COD/EXE_SOI_DTD des patients vivants).
  na_to_chr <- function(x) {
    x <- as.character(x)
    x[is.na(x)] <- "NA"
    x
  }
  idt_v <- na_to_chr(shown$BEN_IDT_ANO)
  dte_v <- na_to_chr(format(shown$EXE_SOI_DTD))
  cod_v <- na_to_chr(shown$CIM_COD)
  sta_v <- shown$STATUS

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

# %% [2] Base DuckDB en mémoire --------------------------------------------------
# On ouvre une connexion DuckDB EN MÉMOIRE (aucun fichier, donc aucun verrou ni
# téléchargement). On y écrira nos tables de décès fictives à la cellule
# suivante. shutdown = TRUE à la fermeture (cellule [10]) libère tout.
conn <- duckdb::dbConnect(duckdb::duckdb())

# %% [2b] Tables de décès fictives ----------------------------------------------
# On reproduit le schéma des deux tables des causes médicales de décès :
#   KI_CCI_R = circonstances et CAUSE INITIALE du décès (colonne DCD_CIM_COD)
#              -> lignes STATUS == "Initial cause"
#   KI_ECD_R = ENSEMBLE DES CAUSES du décès (colonne ECD_CIM_COD)
#              -> lignes STATUS == "Other"
# Cohorte fictive (dates de décès volontairement réparties sur plusieurs années
# pour illustrer le filtre de période) :
#   P1 : cause initiale M170 (2015) ; autres causes M170, I10, E11
#   P2 : cause initiale W010 (2003) ; autre cause X59
#   P3 : cause initiale I219 (2018) ; autre cause N179
#   P4 : cause initiale W199 (2010) ; autre cause S065
#   P5 : pas de cause initiale ; autres causes M545, W500 (2017)
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
# Sans diagnosis_codes, extract_death() renvoie tous les décès de la période,
# une ligne par code CIM-10 et par patient, avec :
#   - CIM_COD : un code CIM-10 associé au décès ;
#   - STATUS  : "Initial cause" (cause initiale, KI_CCI_R) ou "Other" (autre
#               code de l'ensemble des causes, KI_ECD_R).
# Un patient peut donc apparaître sur plusieurs lignes. Un code déjà rapporté
# comme cause initiale n'est pas dupliqué en "Other".
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
print_deaths_pretty(all_deaths)

# %% [4] Scénario B : décès par code CIM-10 (recherche par préfixe) ---------------
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

# %% [5] Scénario C : effet du filtre de période ---------------------------------
# Mêmes codes ("W" = causes externes / chutes), mais une fenêtre temporelle
# restreinte : seuls les décès survenus dans la période sont conservés. P2 (2003)
# disparaît quand on ne garde que 2005-2020.
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

# %% [6] Scénario D : sauvegarde du résultat dans une table ----------------------
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

# %% [7] Scénario E : extraction par liste d'identifiants ------------------------
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

# %% [8] Fermeture de la connexion -----------------------------------------------
DBI::dbDisconnect(conn, shutdown = TRUE)
