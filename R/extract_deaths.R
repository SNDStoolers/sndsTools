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

#' Projette une table de causes de décès sur le format de sortie commun.
#'
#' @description
#' Standardise une table des causes médicales de décès (`KI_CCI_R` ou
#' `KI_ECD_R`) sur les quatre colonnes de sortie communes
#' (`BEN_IDT_ANO`, `EXE_SOI_DTD`, `CIM_COD`, `STATUS`), en renommant la colonne
#' de code CIM-10 propre à la table et en marquant le statut.
#'
#' @param tbl tbl_lazy La table source déjà filtrée.
#' @param code_col character Le nom de la colonne de code CIM-10 à projeter sur
#'   `CIM_COD` (ex. `"DCD_CIM_COD"` ou `"ECD_CIM_COD"`).
#' @param status character La valeur de la colonne `STATUS` (ex.
#'   `"Initial cause"` ou `"Other"`).
#' @return tbl_lazy Une requête paresseuse dédoublonnée aux colonnes
#'   `BEN_IDT_ANO`, `EXE_SOI_DTD`, `CIM_COD`, `STATUS`.
#' @keywords internal
select_death_codes <- function(tbl, code_col, status) {
  tbl |>
    dplyr::mutate(
      EXE_SOI_DTD = BEN_DCD_DTE,
      CIM_COD = !!rlang::sym(code_col),
      STATUS = status
    ) |>
    dplyr::select(BEN_IDT_ANO, EXE_SOI_DTD, CIM_COD, STATUS) |>
    dplyr::distinct()
}

#' Extraction des décès et de leurs causes médicales (CIM-10)
#'
#' @description
#' Extrait, pour chaque patient décédé entre `start_date` et `end_date` (bornes
#' incluses), l'ensemble des codes CIM-10 associés à son décès, à raison d'**une
#' ligne par code**. La colonne `STATUS` indique si le code est la cause
#' initiale du décès (`"Initial cause"`) ou un autre code de l'ensemble des
#' causes (`"Other"`).
#'
#' Deux filtres optionnels et combinables restreignent l'extraction :
#'   - `diagnosis_codes_filter` : ne conserve que les décès dont la cause
#'     initiale **ou** l'un des autres codes correspond aux codes fournis ;
#'   - `patient_ids_filter` : restreint à une liste d'identifiants patients.
#'     Tout identifiant fourni sans décès correspondant dans la période est tout
#'     de même restitué sur une ligne `STATUS == "Alive"`.
#'
#' @details
#' La fonction interroge les deux tables des causes médicales de décès :
#'   - `KI_CCI_R` (cause initiale, colonne `DCD_CIM_COD`) fournit les codes
#'     `"Initial cause"` ;
#'   - `KI_ECD_R` (ensemble des causes, colonne `ECD_CIM_COD`) fournit les codes
#'     `"Other"`.
#' Un code déjà rapporté comme cause initiale d'un patient n'est pas dupliqué en
#' `"Other"`. La correspondance des codes (`diagnosis_codes_filter`) se fait par
#' préfixe (`LIKE 'code%'`).
#'
#' Lorsque `patient_ids_filter` est fourni, `"Alive"` signifie « aucun décès
#' correspondant dans la période » : selon les filtres, le patient peut être
#' vivant, décédé hors période, ou décédé d'une cause non retenue par
#' `diagnosis_codes_filter`.
#'
#' À noter : le chargement des tables associées au décès (`KI_CCI_R`,
#' `KI_ECD_R`) en mode paresseux est long. Un enregistrement sur Oracle (via
#' `output_table_name`) est donc recommandé pour éviter de dupliquer le
#' chargement des tables paresseuses à chaque réévaluation de la requête.
#'
#' @param start_date Date La date de début de la période de décès (incluse).
#' @param end_date Date La date de fin de la période de décès (incluse).
#' @param diagnosis_codes_filter character vector (Optionnel). Codes CIM-10 à
#'   rechercher parmi les causes de décès. Si `NULL`, tous les décès de la
#'   période sont extraits. Défaut à `NULL`.
#' @param patient_ids_filter character vector (Optionnel). Identifiants patients
#'   (`BEN_IDT_ANO`) à extraire ; les doublons sont ignorés. Si `NULL`, aucune
#'   restriction sur les patients. Défaut à `NULL`.
#' @param output_table_name character (Optionnel). Si fourni, les résultats sont
#'   sauvegardés dans une table portant ce nom dans Oracle au lieu d'être
#'   retournés sous forme de data frame. Défaut à `NULL`.
#' @param conn dbConnection (Optionnel). Une connexion à la base Oracle. Si
#'   `conn` n'est pas fourni, une connexion à Oracle est initialisée. Pour
#'   enchaîner d'autres traitements sur la lazy table retournée, fournissez
#'   votre propre `conn` : la connexion ouverte en interne reste alors ouverte
#'   (la requête paresseuse en a besoin) et c'est à l'appelant de la fermer.
#'   Défaut à `NULL`.
#'
#' @return Si `output_table_name` est `NULL`, retourne une lazy table dbplyr
#'   (`tbl_lazy`) — la requête n'est pas évaluée tant qu'elle n'est pas
#'   collectée (`dplyr::collect()`), ce qui permet de l'enchaîner avec d'autres
#'   fonctions du paquet et de bénéficier des optimisations Oracle. Si
#'   `output_table_name` est fourni, la requête est matérialisée directement
#'   dans Oracle (`CREATE TABLE ... AS SELECT`, sans transiter par R) et la
#'   fonction retourne `NULL` de manière invisible. Dans les deux cas, une ligne
#'   par code CIM-10 et par patient décédé (plus une ligne par patient
#'   `"Alive"` si
#'   `patient_ids_filter` est fourni), avec les colonnes :
#'   - `BEN_IDT_ANO` : identifiant patient pseudonymisé.
#'   - `EXE_SOI_DTD` : date du décès (`NA` pour un patient `"Alive"`).
#'   - `CIM_COD` : un code CIM-10 associé au décès (`NA` si `"Alive"`).
#'   - `STATUS` : `"Initial cause"`, `"Other"` ou `"Alive"`.
#'
#' @examples
#' \dontrun{
#' # Décès dont une cause commence par G10 ou G20, entre 2010 et 2020.
#' deaths <- extract_deaths(
#'   start_date = as.Date("2010-01-01"),
#'   end_date = as.Date("2020-12-31"),
#'   diagnosis_codes_filter = c("G10", "G20")
#' )
#'
#' # Statut vital et causes de décès d'une liste d'identifiants.
#' deaths <- extract_deaths(
#'   start_date = as.Date("2010-01-01"),
#'   end_date = as.Date("2020-12-31"),
#'   patient_ids_filter = c("ABC123", "DEF456")
#' )
#'
#' # Sur le SNDS (Oracle) : cohorte issue d'IR_BEN_R, écrite dans Oracle.
#' conn <- connect_oracle()
#' pat_list <- dplyr::tbl(conn, "IR_BEN_R") |>
#'   head(10) |>
#'   dplyr::pull(BEN_IDT_ANO)
#' extract_deaths(
#'   start_date = as.Date("2010-01-01"),
#'   end_date = as.Date("2020-12-31"),
#'   patient_ids_filter = pat_list,
#'   output_table_name = "DEATHS_OUTPUT_2"
#' )
#' }
#' @export
#' @family extract
extract_deaths <- function(
  start_date,
  end_date,
  diagnosis_codes_filter = NULL,
  patient_ids_filter = NULL,
  output_table_name = NULL,
  conn = NULL
) {
  stopifnot(
    inherits(start_date, "Date"),
    inherits(end_date, "Date"),
    start_date <= end_date,
    is.null(diagnosis_codes_filter) || is.character(diagnosis_codes_filter),
    is.null(patient_ids_filter) ||
      (is.character(patient_ids_filter) && length(patient_ids_filter) > 0)
  )

  connection_opened <- FALSE
  if (is.null(conn)) {
    conn <- connect_oracle()
    connection_opened <- TRUE
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

  initial_cause <- dplyr::tbl(conn, "KI_CCI_R") |>
    dplyr::filter(dbplyr::sql(date_condition), !is.na(BEN_IDT_ANO))
  all_causes <- dplyr::tbl(conn, "KI_ECD_R") |>
    dplyr::filter(dbplyr::sql(date_condition), !is.na(BEN_IDT_ANO))

  ids_db <- NULL
  ids_table_name <- NULL
  if (!is.null(patient_ids_filter)) {
    # La liste d'identifiants passe par une table temporaire de session
    # (`temporary = TRUE`) afin de réaliser la jointure côté base. Elle n'est
    # pas supprimée au retour : la requête paresseuse y fait encore référence ;
    # Oracle la nettoie automatiquement à la fin de la session.
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    ids_table_name <- glue::glue("TMP_DEATH_IDS_{timestamp}")
    DBI::dbWriteTable(
      conn,
      ids_table_name,
      dplyr::tibble(BEN_IDT_ANO = unique(patient_ids_filter)),
      temporary = TRUE
    )
    ids_db <- dplyr::tbl(conn, ids_table_name)
    initial_cause <- initial_cause |>
      dplyr::inner_join(ids_db, by = "BEN_IDT_ANO")
    all_causes <- all_causes |>
      dplyr::inner_join(ids_db, by = "BEN_IDT_ANO")
  }

  if (!is.null(diagnosis_codes_filter)) {
    # Cohorte des patients dont la cause initiale OU un autre code correspond ;
    # les patients retenus conservent l'ensemble de leurs codes.
    cohort <- dplyr::union(
      initial_cause |>
        dplyr::filter(dbplyr::sql(build_death_cim_conditions(
          "DCD_CIM_COD",
          diagnosis_codes_filter
        ))) |>
        dplyr::select(BEN_IDT_ANO),
      all_causes |>
        dplyr::filter(dbplyr::sql(build_death_cim_conditions(
          "ECD_CIM_COD",
          diagnosis_codes_filter
        ))) |>
        dplyr::select(BEN_IDT_ANO)
    )
    initial_cause <- initial_cause |>
      dplyr::semi_join(cohort, by = "BEN_IDT_ANO")
    all_causes <- all_causes |>
      dplyr::semi_join(cohort, by = "BEN_IDT_ANO")
  }

  initial_codes <- select_death_codes(
    initial_cause,
    "DCD_CIM_COD",
    "Initial cause"
  )

  # Un code déjà rapporté comme cause initiale n'est pas redupliqué en "Other".
  other_codes <- select_death_codes(all_causes, "ECD_CIM_COD", "Other") |>
    dplyr::anti_join(
      initial_codes |> dplyr::select(BEN_IDT_ANO, CIM_COD),
      by = c("BEN_IDT_ANO", "CIM_COD")
    )

  deceased <- dplyr::union_all(initial_codes, other_codes)

  if (is.null(patient_ids_filter)) {
    result <- deceased
  } else {
    # left_join sur la liste d'identifiants : ceux sans décès correspondant
    # ressortent en "Alive" (EXE_SOI_DTD et CIM_COD restant NULL).
    result <- ids_db |>
      dplyr::left_join(deceased, by = "BEN_IDT_ANO") |>
      dplyr::mutate(STATUS = dplyr::coalesce(STATUS, "Alive")) |>
      dplyr::select(BEN_IDT_ANO, EXE_SOI_DTD, CIM_COD, STATUS)
  }

  result <- result |>
    dplyr::arrange(BEN_IDT_ANO, EXE_SOI_DTD, STATUS, CIM_COD)

  # Sans table de sortie, on retourne la requête paresseuse sans la collecter ni
  # fermer la connexion : l'appelant l'enchaîne et la collecte quand il veut.
  if (is.null(output_table_name)) {
    return(result)
  }

  # Avec une table de sortie, on matérialise directement dans Oracle, puis on
  # nettoie les ressources que l'on a ouvertes (table temporaire, connexion).
  create_table_from_query(conn, output_table_name, result)
  message(glue::glue("Results saved to table {output_table_name} in Oracle."))
  if (!is.null(ids_table_name)) {
    DBI::dbRemoveTable(conn, ids_table_name)
  }
  if (connection_opened) {
    DBI::dbDisconnect(conn)
  }
  invisible(NULL)
}
