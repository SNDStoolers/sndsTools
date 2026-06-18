# Colonnes du SNDS manipulées en évaluation non-standard (dplyr/dbplyr) dans les
# fonctions d'extraction des décès. On les déclare pour éviter les notes
# "no visible binding for global variable" de R CMD check.
utils::globalVariables(c(
  "BEN_IDT_ANO",
  "BEN_DCD_DTE",
  "DCD_CIM_COD",
  "ECD_CIM_COD",
  "CIM_COD",
  "EXE_SOI_DTD",
  "STATUS"
))

#' Construit la condition SQL de recherche de codes CIM-10 sur une colonne.
#'
#' @description
#' Construit une clause SQL `OR` recherchant les codes diagnostics fournis sur
#' la colonne indiquée. La recherche est effectuée par préfixe : un code partiel
#' (ex. `"G20"`) capture donc l'ensemble de ses sous-codes (ex. `"G200"`,
#' `"G201"`).
#'
#' @param col_name character Le nom de la colonne sur laquelle rechercher les
#'   codes (ex. `"ECD_CIM_COD"` ou `"DCD_CIM_COD"`).
#' @param diagnosis_codes character vector Les codes CIM-10 à rechercher.
#' @return character La condition SQL combinée par `OR`.
#'
#' @examples
#' \dontrun{
#' build_death_cim_conditions("DCD_CIM_COD", c("G10", "G20"))
#' }
#' @keywords internal
build_death_cim_conditions <- function(col_name, diagnosis_codes) {
  starts_with_conditions <- glue::glue("{col_name} LIKE '{diagnosis_codes}%'")
  paste(starts_with_conditions, collapse = " OR ")
}

# nolint start
#' Extraction des décès à partir d'une cause médicale (CIM-10)
#'
#' @description
#' Extrait, pour chaque patient décédé entre `start_date` et `end_date` (bornes
#' incluses), l'ensemble des codes CIM-10 associés à son décès, à raison d'**une
#' ligne par code**. La colonne `STATUS` indique si le code est la cause
#' initiale du décès (`"Initial cause"`) ou un autre code de l'ensemble des
#' causes (`"Other"`). Si `diagnosis_codes` est renseigné, seuls les décès dont
#' la cause initiale **ou** l'un des autres codes correspond à ces codes sont
#' retournés ; sinon tous les décès de la période sont extraits.
#'
#' @details
#' La fonction interroge les deux tables des causes médicales de décès :
#'   - `KI_CCI_R` (« circonstances et cause initiale du décès », colonne
#'     `DCD_CIM_COD`) fournit les codes de cause initiale
#'     (`STATUS == "Initial cause"`) ;
#'   - `KI_ECD_R` (« ensemble des causes de décès », colonne `ECD_CIM_COD`)
#'     fournit les autres codes (`STATUS == "Other"`).
#' Les deux tables sont rapprochées par `BEN_IDT_ANO`. Un code qui est déjà la
#' cause initiale d'un patient n'est pas dupliqué en `"Other"` : il n'apparaît
#' qu'une fois, en `"Initial cause"`. Un patient sans cause initiale renseignée
#' n'a donc que des lignes `"Other"`. La correspondance des codes (filtre
#' `diagnosis_codes`) est réalisée par préfixe (`LIKE 'code%'`) : un code partiel
#' (ex. `"G20"`) capture donc l'ensemble de ses sous-codes (ex. `"G200"`,
#' `"G201"`).
#'
#' La requête est construite de façon **paresseuse** (lazy) et exécutée
#' intégralement côté base : aucune des tables de décès n'est chargée en mémoire
#' R. Lorsque `output_table_name` est fourni, le résultat est matérialisé
#' directement dans la base Oracle (`CREATE TABLE ... AS SELECT`), sans `collect`.
#'
#' @param start_date Date La date de début de la période de décès à extraire
#'   (borne incluse).
#' @param end_date Date La date de fin de la période de décès à extraire (borne
#'   incluse).
#' @param diagnosis_codes character vector (Optionnel). Vecteur de codes
#'   diagnostics CIM-10 à rechercher parmi les causes de décès. Si `NULL`, tous
#'   les décès de la période sont extraits. Défaut à `NULL`.
#' @param output_table_name character (Optionnel). Si fourni, les résultats sont
#'   sauvegardés dans une table portant ce nom dans Oracle au lieu
#'   d'être retournés sous forme de data frame. Défaut à `NULL`.
#' @param conn dbConnection (Optionnel). Une connexion à la base Oracle. Si
#'   `conn` n'est pas fourni, une connexion à Oracle est initialisée. Défaut à
#'   `NULL`.
#'
#' @return Si `output_table_name` est `NULL`, retourne un data frame ; sinon
#'   sauvegarde les résultats dans la table spécifiée et retourne `NULL` de
#'   manière invisible. Dans les deux cas, **une ligne par code CIM-10 et par
#'   patient décédé**, avec les colonnes :
#'   - `BEN_IDT_ANO` : identifiant patient pseudonymisé.
#'   - `EXE_SOI_DTD` : date du décès.
#'   - `CIM_COD` : un code CIM-10 associé au décès.
#'   - `STATUS` : origine du code, `"Initial cause"` si c'est la cause initiale
#'     du décès (`KI_CCI_R`), `"Other"` si c'est un autre code de l'ensemble des
#'     causes (`KI_ECD_R`).
#'
#' @examples
#' \dontrun{
#' # Décès dont une cause est un code commençant par G10 ou G20, entre 2010 et 2020
#' deaths <- extract_idt_from_death_causes(
#'   start_date = as.Date("2010-01-01"),
#'   end_date = as.Date("2020-12-31"),
#'   diagnosis_codes = c("G10", "G20")
#' )
#' # Tous les décès de l'année 2019
#' deaths <- extract_idt_from_death_causes(
#'   start_date = as.Date("2019-01-01"),
#'   end_date = as.Date("2019-12-31")
#' )
#' }
#' @export
#' @family extract
# nolint end
extract_idt_from_death_causes <- function(
  start_date,
  end_date,
  diagnosis_codes = NULL,
  output_table_name = NULL,
  conn = NULL
) {
  stopifnot(
    !is.null(start_date),
    !is.null(end_date),
    inherits(start_date, "Date"),
    inherits(end_date, "Date"),
    start_date <= end_date,
    is.null(diagnosis_codes) || is.character(diagnosis_codes)
  )

  if (is.null(conn)) {
    conn <- connect_oracle()
    on.exit(DBI::dbDisconnect(conn), add = TRUE)
  }

  if (!is.null(output_table_name)) {
    check_output_table_name(output_table_name, conn)
  }

  formatted_start_date <- format(start_date, "%Y-%m-%d")
  formatted_end_date <- format(end_date, "%Y-%m-%d")

  date_condition <- glue::glue(
    "BEN_DCD_DTE >= DATE '{formatted_start_date}'
    AND BEN_DCD_DTE <= DATE '{formatted_end_date}'"
  )

  # Cause initiale du décès (KI_CCI_R) : codes "Initial cause".
  initial_cause <- dplyr::tbl(conn, "KI_CCI_R") |>
    dplyr::filter(dbplyr::sql(date_condition), !is.na(BEN_IDT_ANO))
  # Ensemble des causes du décès (KI_ECD_R) : codes "Other".
  all_causes <- dplyr::tbl(conn, "KI_ECD_R") |>
    dplyr::filter(dbplyr::sql(date_condition), !is.na(BEN_IDT_ANO))

  # Restriction à la cohorte : patients dont la cause initiale OU un des autres
  # codes correspond aux codes recherchés.
  if (!is.null(diagnosis_codes)) {
    cohort <- dplyr::union(
      initial_cause |>
        dplyr::filter(dbplyr::sql(build_death_cim_conditions(
          "DCD_CIM_COD",
          diagnosis_codes
        ))) |>
        dplyr::select(BEN_IDT_ANO),
      all_causes |>
        dplyr::filter(dbplyr::sql(build_death_cim_conditions(
          "ECD_CIM_COD",
          diagnosis_codes
        ))) |>
        dplyr::select(BEN_IDT_ANO)
    )
    initial_cause <- initial_cause |>
      dplyr::semi_join(cohort, by = "BEN_IDT_ANO")
    all_causes <- all_causes |>
      dplyr::semi_join(cohort, by = "BEN_IDT_ANO")
  }

  # Une ligne par code de cause initiale. Tout reste paresseux (SQL) : le
  # collect éventuel est centralisé dans save_or_return_result().
  initial_codes <- initial_cause |>
    dplyr::select(
      BEN_IDT_ANO,
      EXE_SOI_DTD = BEN_DCD_DTE,
      CIM_COD = DCD_CIM_COD
    ) |>
    dplyr::distinct() |>
    dplyr::mutate(STATUS = "Initial cause")

  # Une ligne par code de l'ensemble des causes. Un code déjà rapporté comme
  # cause initiale du patient n'est pas dupliqué en "Other".
  other_codes <- all_causes |>
    dplyr::select(
      BEN_IDT_ANO,
      EXE_SOI_DTD = BEN_DCD_DTE,
      CIM_COD = ECD_CIM_COD
    ) |>
    dplyr::distinct() |>
    dplyr::mutate(STATUS = "Other") |>
    dplyr::anti_join(
      initial_codes |> dplyr::select(BEN_IDT_ANO, CIM_COD),
      by = c("BEN_IDT_ANO", "CIM_COD")
    )

  # union_all (et non bind_rows) car les opérandes sont des requêtes
  # paresseuses.
  # Les deux branches sont disjointes (anti_join) : pas de doublon introduit.
  result <- dplyr::union_all(
    initial_codes |>
      dplyr::select(BEN_IDT_ANO, EXE_SOI_DTD, CIM_COD, STATUS),
    other_codes |>
      dplyr::select(BEN_IDT_ANO, EXE_SOI_DTD, CIM_COD, STATUS)
  ) |>
    dplyr::arrange(BEN_IDT_ANO, EXE_SOI_DTD, STATUS, CIM_COD)

  save_or_return_result(result, output_table_name, conn)
}

# nolint start
#' Extraction des causes de décès pour une liste de patients
#'
#' @description
#' Pour un ensemble d'identifiants patients fourni en entrée, extrait l'ensemble
#' des codes CIM-10 associés à leur décès survenu entre `start_date` et
#' `end_date` (bornes incluses), à raison d'**une ligne par code**. C'est la
#' fonction sœur de [extract_idt_from_death_causes()] : même sortie, mais la sélection se fait
#' sur une liste d'identifiants plutôt que sur des codes diagnostics.
#'
#' @details
#' La fonction interroge les deux tables des causes médicales de décès,
#' restreintes aux identifiants fournis :
#'   - `KI_CCI_R` (« cause initiale du décès », colonne `DCD_CIM_COD`) fournit
#'     les codes `STATUS == "Initial cause"` ;
#'   - `KI_ECD_R` (« ensemble des causes de décès », colonne `ECD_CIM_COD`)
#'     fournit les codes `STATUS == "Other"`.
#' Un code déjà rapporté comme cause initiale d'un patient n'est pas dupliqué en
#' `"Other"`.
#'
#' **Patients vivants.** Un identifiant fourni qui n'a aucun code de décès dans
#' la période (patient vivant, ou décédé hors `[start_date, end_date]`) est tout
#' de même restitué, sur une unique ligne `STATUS == "Alive"` avec `CIM_COD` et
#' `EXE_SOI_DTD` à `NA`. Tous les identifiants fournis (dédoublonnés) sont donc
#' présents en sortie. Cette restitution est obtenue par une jointure externe
#' (`LEFT JOIN`) de la liste d'identifiants sur les décès.
#'
#' La liste d'identifiants est injectée dans une table temporaire de la base
#' (supprimée en fin d'exécution) pour réaliser la jointure. La requête reste
#' **paresseuse** (lazy) et s'exécute côté base ; lorsque `output_table_name` est
#' fourni, le résultat est matérialisé directement dans la base Oracle
#' (`CREATE TABLE ... AS SELECT`), sans `collect`.
#'
#' @param patient_ids character vector Les identifiants patients
#'   (`BEN_IDT_ANO`) à extraire. Les doublons sont ignorés.
#' @param start_date Date La date de début de la période de décès à extraire
#'   (borne incluse).
#' @param end_date Date La date de fin de la période de décès à extraire (borne
#'   incluse).
#' @param output_table_name character (Optionnel). Si fourni, les résultats sont
#'   sauvegardés dans une table portant ce nom dans Oracle au lieu
#'   d'être retournés sous forme de data frame. Défaut à `NULL`.
#' @param conn dbConnection (Optionnel). Une connexion à la base de données. Si
#'   `conn` n'est pas fourni, une connexion à Oracle est initialisée. Défaut à
#'   `NULL`.
#'
#' @return Si `output_table_name` est `NULL`, retourne un data frame ; sinon
#'   sauvegarde les résultats dans la table spécifiée et retourne `NULL` de
#'   manière invisible. Dans les deux cas, **une ligne par code CIM-10 et par
#'   patient décédé**, plus une ligne par patient vivant, avec les colonnes :
#'   - `BEN_IDT_ANO` : identifiant patient pseudonymisé.
#'   - `EXE_SOI_DTD` : date du décès (`NA` pour un patient vivant).
#'   - `CIM_COD` : un code CIM-10 associé au décès (`NA` pour un patient vivant).
#'   - `STATUS` : `"Initial cause"` (cause initiale, `KI_CCI_R`), `"Other"`
#'     (autre code, `KI_ECD_R`), ou `"Alive"` (aucun décès dans la période).
#'
#' @examples
#' \dontrun{
#' # Données synthétiques : liste d'identifiants fournie directement.
#' deaths <- extract_death_causes_from_idt(
#'   patient_ids = c("ABC123", "DEF456"),
#'   start_date = as.Date("2010-01-01"),
#'   end_date = as.Date("2020-12-31")
#' )
#'
#' # Données Oracle du SNDS : identifiants récupérés depuis IR_BEN_R.
#' pat_list <- dplyr::tbl(conn, "IR_BEN_R") |>
#'   head(10) |>
#'   dplyr::pull(BEN_IDT_ANO)
#' deaths <- extract_death_causes_from_idt(
#'   patient_ids = pat_list,
#'   start_date = as.Date("2010-01-01"),
#'   end_date = as.Date("2020-12-31")
#' )
#' }
#' @export
#' @family extract
#' @seealso [extract_idt_from_death_causes()]
# nolint end
extract_death_causes_from_idt <- function(
  patient_ids,
  start_date,
  end_date,
  output_table_name = NULL,
  conn = NULL
) {
  stopifnot(
    !is.null(patient_ids),
    is.character(patient_ids),
    length(patient_ids) > 0,
    !is.null(start_date),
    !is.null(end_date),
    inherits(start_date, "Date"),
    inherits(end_date, "Date"),
    start_date <= end_date
  )

  if (is.null(conn)) {
    conn <- connect_oracle()
    on.exit(DBI::dbDisconnect(conn), add = TRUE)
  }

  if (!is.null(output_table_name)) {
    check_output_table_name(output_table_name, conn)
  }

  patient_ids <- unique(patient_ids)

  # Injecte la liste d'identifiants dans une table temporaire pour la jointure.
  ids_table_name <- "SNDS_TOOLS_TMP_DEATH_IDS"
  DBI::dbWriteTable(
    conn,
    ids_table_name,
    dplyr::tibble(BEN_IDT_ANO = patient_ids),
    overwrite = TRUE
  )
  on.exit(
    try(DBI::dbRemoveTable(conn, ids_table_name), silent = TRUE),
    add = TRUE
  )
  ids_db <- dplyr::tbl(conn, ids_table_name)

  formatted_start_date <- format(start_date, "%Y-%m-%d")
  formatted_end_date <- format(end_date, "%Y-%m-%d")

  date_condition <- glue::glue(
    "BEN_DCD_DTE >= DATE '{formatted_start_date}'
    AND BEN_DCD_DTE <= DATE '{formatted_end_date}'"
  )

  # Cause initiale et ensemble des causes, restreintes aux identifiants fournis.
  initial_cause <- dplyr::tbl(conn, "KI_CCI_R") |>
    dplyr::filter(dbplyr::sql(date_condition), !is.na(BEN_IDT_ANO)) |>
    dplyr::inner_join(ids_db, by = "BEN_IDT_ANO")
  all_causes <- dplyr::tbl(conn, "KI_ECD_R") |>
    dplyr::filter(dbplyr::sql(date_condition), !is.na(BEN_IDT_ANO)) |>
    dplyr::inner_join(ids_db, by = "BEN_IDT_ANO")

  # Une ligne par code de cause initiale. Tout reste paresseux (SQL) : le
  # collect éventuel est centralisé dans save_or_return_result().
  initial_codes <- initial_cause |>
    dplyr::select(
      BEN_IDT_ANO,
      EXE_SOI_DTD = BEN_DCD_DTE,
      CIM_COD = DCD_CIM_COD
    ) |>
    dplyr::distinct() |>
    dplyr::mutate(STATUS = "Initial cause")

  # Une ligne par code de l'ensemble des causes. Un code déjà rapporté comme
  # cause initiale n'est pas dupliqué en "Other".
  other_codes <- all_causes |>
    dplyr::select(
      BEN_IDT_ANO,
      EXE_SOI_DTD = BEN_DCD_DTE,
      CIM_COD = ECD_CIM_COD
    ) |>
    dplyr::distinct() |>
    dplyr::mutate(STATUS = "Other") |>
    dplyr::anti_join(
      initial_codes |> dplyr::select(BEN_IDT_ANO, CIM_COD),
      by = c("BEN_IDT_ANO", "CIM_COD")
    )

  deceased <- dplyr::union_all(
    initial_codes |>
      dplyr::select(BEN_IDT_ANO, EXE_SOI_DTD, CIM_COD, STATUS),
    other_codes |>
      dplyr::select(BEN_IDT_ANO, EXE_SOI_DTD, CIM_COD, STATUS)
  )

  # Patients vivants : un left_join de la liste d'identifiants sur les décès
  # restitue tous les identifiants fournis. Pour ceux sans code de décès dans la
  # période, EXE_SOI_DTD et CIM_COD sont NULL (typés par les colonnes de
  # `deceased`, ce qui évite tout souci de typage d'un NA littéral) et STATUS
  # est mis à "Alive". Les décédés conservent leurs lignes de codes.
  result <- ids_db |>
    dplyr::left_join(deceased, by = "BEN_IDT_ANO") |>
    dplyr::mutate(STATUS = dplyr::coalesce(STATUS, "Alive")) |>
    dplyr::select(BEN_IDT_ANO, EXE_SOI_DTD, CIM_COD, STATUS) |>
    dplyr::arrange(BEN_IDT_ANO, EXE_SOI_DTD, STATUS, CIM_COD)

  save_or_return_result(result, output_table_name, conn)
}
