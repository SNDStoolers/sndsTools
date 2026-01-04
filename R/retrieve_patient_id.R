# Function to retrieve
retrieve_psa <- function(
  ben_table_name,
  start_key,
  conn = NULL,
  check_arc_table = TRUE,
  output_table_name = NULL
) {
  # Check if a connection is provided
  connection_opened <- FALSE
  if (is.null(conn)) {
    conn <- connect_oracle()
    connection_opened <- TRUE
  }

  # Check if the input arguments are of the correct type
  stopifnot(
    is.logical(check_arc_table),
    is.character(ben_table_name),
    is.character(output_table_name) | is.null(output_table_name)
  )

  # Retrieve ben_table_name column names
  ben_table_colnames <- dplyr::tbl(conn, ben_table_name) |> colnames()

  # Define reference table names
  ben <- dplyr::tbl(conn, "IR_BEN_R")
  ben_arc <- dplyr::tbl(conn, "IR_BEN_R_ARC")

  # Check table content
  if (!(start_key %in% ben_table_colnames)) {
    stop(glue::glue("ben_table_name must contain at least {start_key}"))
  }

  # Handling BEN_RNG_GEM if included in the input table
  is_ben_rng_gem_included <- if ("BEN_RNG_GEM" %in% ben_table_colnames) {
    "BEN_RNG_GEM"
  } else {
    NULL
  }
  psa_key <- c("BEN_NIR_PSA", is_ben_rng_gem_included) |> purrr::compact()
  idt_key <- c("BEN_IDT_ANO", is_ben_rng_gem_included) |> purrr::compact()

  # Retrieve BEN_IDT_ANO from initial table
  # Start from BEN_NIR_PSA
  if (start_key == "BEN_NIR_PSA") {
    idt <- dplyr::tbl(conn, ben_table_name) |>
      dplyr::inner_join(ben, by = setNames(psa_key, psa_key)) |>
      dplyr::select(!!!rlang::syms(idt_key)) |>
      dplyr::distinct()
    if (check_arc_table) {
      idt_arc <- dplyr::tbl(conn, ben_table_name) |>
        dplyr::inner_join(ben_arc, by = setNames(psa_key, psa_key)) |>
        dplyr::select(!!!rlang::syms(idt_key)) |>
        dplyr::distinct()

      idt <- dplyr::union(idt, idt_arc)
    }
  } else {
    # Start from BEN_IDT_ANO
    idt <- dplyr::tbl(conn, ben_table_name) |>
      dplyr::distinct()
  }

  # BEN_NIR_PSA retrieval from BEN_IDT_ANO
  idt_psa <- idt |>
    dplyr::inner_join(ben, by = setNames(idt_key, idt_key))

  # Consider archived table if requested
  if (check_arc_table) {
    idt_psa_arc <- idt |>
      dplyr::inner_join(ben_arc, by = setNames(idt_key, idt_key))
    idt_psa <- dplyr::union(idt_psa, idt_psa_arc)
  }

  # Assessment of exclusion criteria
  idt_psa <- idt_psa |>
    dplyr::distinct() |>
    dplyr::collect() |>
    dplyr::group_by(!!!rlang::syms(psa_key)) |>
    dplyr::mutate(
      psa_w_multiple_idt_or_nir = dplyr::n_distinct(BEN_IDT_ANO) > 1 |
        dplyr::n_distinct(BEN_NIR_ANO) > 1
    ) |>
    dplyr::ungroup() |>
    dplyr::group_by(!!!rlang::syms(idt_key)) |>
    dplyr::mutate(
      psa_w_multiple_idt_or_nir = any(psa_w_multiple_idt_or_nir),
      cdi_nir_00 = !is.na(BEN_CDI_NIR) & BEN_CDI_NIR == "00",
      nir_ano_defined = !is.na(BEN_NIR_ANO),
      birth_date_variation = dplyr::n_distinct(BEN_NAI_ANN) > 1 |
        dplyr::n_distinct(BEN_NAI_MOI) > 1,
      sex_variation = dplyr::n_distinct(BEN_SEX_COD) > 1
    )

  # Handle output: Return or save the table
  if (is.null(output_table_name)) {
    if (connection_opened) {
      DBI::dbDisconnect(conn)
    }
    idt_psa
  } else {
    DBI::dbWriteTable(
      conn,
      output_table_name,
      idt_psa |> dplyr::collect(),
      overwrite = TRUE
    )
    message(glue::glue("Results saved to table {output_table_name} in Oracle."))
    if (connection_opened) DBI::dbDisconnect(conn)
  }
}

# nolint start
#' Gestion des identifiants patients à l'aide de `BEN_IDT_ANO`
#' @description
#' La fonction `retrieve_all_psa_from_idt` permet d'extraire le reférentiel des
#' bénéficiaires avec la clé de jointure la plus fine (l'ensemble des
#' `BEN_NIR_PSA`) à partir d'une table contenant un identifiant patient
#' `BEN_IDT_ANO`.
#'
#' Cinq variables binaires sont ajoutées en sortie pour aider au processus
#' d'inclusion :
#' 1. `psa_w_multiple_idt_or_nir` : permet d'identifier les `BEN_IDT_ANO` ou
#' `BEN_NIR_ANO` présentant des `BEN_NIR_PSA` associés à plusieurs `BEN_IDT_ANO`
#' ou `BEN_NIR_ANO`.
#' 2. `cdi_nir_00` : permet d'identifier les `BEN_NIR_PSA` non fictifs.
#' 3. `nir_ano_defined` : permet d'identifier les `BEN_NIR_PSA` pour lesquels
#' un `BEN_NIR_ANO` est défini.
#' 4. `birth_date_variation` : permet d'identifier les `BEN_IDT_ANO`
#' présentant des inconsistances au niveau de la date de naissance.
#' 5. `sex_variation` : permet d'identifier les `BEN_IDT_ANO`
#' présentant des inconsistances relatives aux codes sexe.
#'
#' @details
#' La fonction retourne une copie du/des référentiel(s) `IR_BEN_R`
#' (/`IR_BEN_R_ARC`) dans une table dédoublonnée avec des indicateurs visant
#' à améliorer le processus d'inclusion.
#' @param ben_table_name Character Obligatoire. Nom de la table d'entrée
#' comprenant au moins la variable `BEN_NIR_PSA`.
#' Si la variable `BEN_RNG_GEM` est incluse, elle sera également
#' utilisée pour les jointures avec les référentiels.
#' @param conn DBI connection Optionnel Une connexion à la base de données
#' Oracle.
#' Si non fournie, une connexion est établie par défaut.
#' @param check_arc_table Logical Optionnel. Si TRUE (par défaut), les tables
#' `IR_BEN_R_ARC` sont également consultées pour la recherche des
#' `BEN_IDT_ANO` et des critères de sélection.
#' @param output_table_name Character Optionnel. Si fourni, les résultats seront
#' sauvegardés dans une table portant ce nom dans Oracle. Sinon la table en
#' sortie est retournée sous la forme d'un data.frame(/tibble).
#' @return A partir d'une table avec `BEN_IDT_ANO`, la fonction retournera
#' l'ensemble des `BEN_NIR_PSA` + `BEN_RNG_GEM` associés au `BEN_IDT_ANO`
#' dans une table dédoublonnée.
#' La table en sortie est une copie de(s) référentiel(s) `IR_BEN_R`
#' (et `IR_BEN_R_ARC`) relatifs aux `BEN_IDT_ANO` impliqués et enregistrée
#' sous Oracle ou retournée sous la forme d'un data.frame(/tibble).
#' Si output_table_name est `NULL`, retourne un data.frame(/tibble).
#' Si output_table_name est fourni, sauvegarde les résultats dans la table
#' spécifiée dans Oracle et retourne `NULL` de manière invisible.
#' Dans les deux cas les colonnes de la table de sortie sont celles
#' des tables `IR_BEN_R` et `IR_BEN_R_ARC` auxquelles sont ajoutées les
#' variables binaires:
#'   - `psa_w_multiple_idt_or_nir` (Logical): permet de vérifier que
#'     chaque BEN_NIR_PSA est associé à un seul `BEN_IDT_ANO` ou `BEN_NIR_ANO`.
#'     Si cette relation d’unicité est respectée, alors les bases PMSI et
#'     DCIR peuvent être interrogées directement à partir de la variable
#'     BEN_NIR_PSA, qui suffit alors pour identifier de manière unique
#'     un patient. Dans le cas contraire, seules les tables du DCIR peuvent
#'     être exploitées pour effectuer des requêtes à l’échelle d’un patient
#'     unique. Il est alors nécessaire de prendre en compte les variables
#'     `BEN_IDT_ANO`, `BEN_RNG_GEM` et `BEN_ORG_AFF` afin d’assurer une
#'     interprétation correcte des identifiants. La variable `BEN_NIR_ANO`,
#'     bien qu’elle permette théoriquement de distinguer les individus
#'     de manière anonyme, peut être manquante. Quant à `BEN_RNG_GEM`,
#'     défini comme le rang gémellaire, il peut prendre différentes valeurs en
#'     cas de changement de régime, identifiable via la variable `BEN_ORG_AFF`.
#'      Source :
#'      https://documentation-snds.health-data-hub.fr/files/Sante_publique_France/2021-10-SpF-SNDS-ce-quil-faut-savoir-v3-MPL-2.0.pdf.
#'   - `cdi_nir_00` (Logical): permet d'identifier les `BEN_NIR_PSA` non fictifs
#'   - `nir_ano_defined` (Logical): permet d'identifier les `BEN_NIR_PSA` pour
#'      lesquels un `BEN_NIR_ANO` et un `BEN_IDT_ANO` sont défini
#'   - `birth_date_variation` (Logical): permet d'identifier les `BEN_IDT_ANO`
#'     présentant des dates de naissance différentes pour un même `BEN_IDT_ANO`
#'   - `sex_variation` (Logical): permet d'identifier les `BEN_IDT_ANO`
#'     présentant des codes sexe différents pour un même `BEN_IDT_ANO`
#'
#' @examples
#' \dontrun{
#' # Création et enregistrement dans Oracle d'un tibble de 100 BEN_IDT_ANO
#' idt_sample_1 <- dplyr::tbl(conn, "IR_BEN_R") |>
#'   dplyr::select(BEN_IDT_ANO) |>
#'   dplyr::distinct() |>
#'   head(100) |>
#'   dplyr::collect()
#' dbWriteTable(conn, "IDT_SAMP_1", idt_sample_1, overwrite = TRUE)
#'
#' # Récupération de la table en format tibble
#' retrieve_all_psa_from_idt(conn = conn, ben_table_name = "IDT_SAMP_1")
#' # Récupération et enregistrement de la table dans Oracle
#' retrieve_all_psa_from_idt(
#'   conn = conn,
#'   ben_table_name = "IDT_SAMP_1",
#'   output_table_name = "TEST_SAVE_ORACLE"
#' )
#' # Récupération de la table sans considérer la table de référentiel archivée
#' retrieve_all_psa_from_idt(
#'   conn = conn,
#'   ben_table_name = "IDT_SAMP_1",
#'   check_arc_table = FALSE
#' )
#' }
#' @export
# nolint end
retrieve_all_psa_from_idt <- function(
  ben_table_name,
  conn = NULL,
  check_arc_table = TRUE,
  output_table_name = NULL
) {
  start_key <- "BEN_IDT_ANO"
  retrieve_psa(
    ben_table_name,
    start_key,
    conn,
    check_arc_table,
    output_table_name
  )
}

# nolint start
#' Gestion des identifiants patients à l'aide de `BEN_NIR_PSA`
#' @description
#' La fonction `retrieve_all_psa_from_psa` permet d'extraire le reférentiel des
#' bénéficiaires avec la clé de jointure la plus fine (l'ensemble des
#' `BEN_NIR_PSA`) à partir d'une table contenant un identifiant patient
#' `BEN_NIR_PSA`.
#'
#' Cinq variables binaires sont ajoutées en sortie pour aider au processus
#' d'inclusion :
#' 1. `psa_w_multiple_idt_or_nir` : permet d'identifier les `BEN_IDT_ANO` ou
#' `BEN_NIR_ANO` présentant des `BEN_NIR_PSA` associés à plusieurs `BEN_IDT_ANO`
#' ou `BEN_NIR_ANO`.
#' 2. `cdi_nir_00` : permet d'identifier les `BEN_NIR_PSA` non fictifs.
#' 3. `nir_ano_defined` : permet d'identifier les `BEN_NIR_PSA` pour lesquels
#' un `BEN_NIR_ANO` est défini.
#' 4. `birth_date_variation` : permet d'identifier les `BEN_IDT_ANO`
#' présentant des inconsistances au niveau de la date de naissance.
#' 5. `sex_variation` : permet d'identifier les `BEN_IDT_ANO`
#' présentant des inconsistances relatives aux codes sexe.
#'
#' @details
#' La fonction retourne une copie du/des référentiel(s) `ÌR_BEN_R`
#' (/`ÌR_BEN_R_ARC`) dans une table dédoublonnée avec des indicateurs visant
#' à améliorer le processus d'inclusion.
#' @param ben_table_name Character Obligatoire. Nom de la table d'entrée
#' comprenant au moins la variable `BEN_IDT_ANO`.
#' Si la variable `BEN_RNG_GEM` est incluse, elle sera également
#' utilisée pour les jointures avec les référentiels.
#' @param conn DBI connection Optionnel Une connexion à la base de données
#' Oracle.
#' Si non fournie, une connexion est établie par défaut.
#' @param check_arc_table Logical Optionnel. Si TRUE (par défaut), les tables
#' `IR_BEN_R_ARC` sont également consultées pour la recherche des
#' `BEN_IDT_ANO` et des critères de sélection.
#' @param output_table_name Character Optionnel. Si fourni, les résultats seront
#' sauvegardés dans une table portant ce nom dans Oracle. Sinon la table en
#' sortie est retournée sous la forme d'un data.frame(/tibble).
#' @return A partir d'une table avec `BEN_IDT_ANO`, la fonction retournera
#' l'ensemble des `BEN_NIR_PSA` + `BEN_RNG_GEM` associés au `BEN_IDT_ANO`
#' dans une table dédoublonnée.
#' La table en sortie est une copie de(s) référentiel(s) `IR_BEN_R`
#' (et `IR_BEN_R_ARC`) relatifs aux `BEN_IDT_ANO` impliqués et enregistrée
#' sous Oracle ou retournée sous la forme d'un data.frame(/tibble).
#' Si output_table_name est `NULL`, retourne un data.frame(/tibble).
#' Si output_table_name est fourni, sauvegarde les résultats dans la table
#' spécifiée dans Oracle et retourne `NULL` de manière invisible.
#' Dans les deux cas les colonnes de la table de sortie sont celles
#' des tables `IR_BEN_R` et `IR_BEN_R_ARC` auxquelles sont ajoutées les
#' variables binaires:
#'   - `psa_w_multiple_idt_or_nir` (Logical): permet de vérifier que
#'     chaque BEN_NIR_PSA est associé à un seul `BEN_IDT_ANO` ou `BEN_NIR_ANO`.
#'     Si cette relation d’unicité est respectée, alors les bases PMSI et
#'     DCIR peuvent être interrogées directement à partir de la variable
#'     BEN_NIR_PSA, qui suffit alors pour identifier de manière unique
#'     un patient. Dans le cas contraire, seules les tables du DCIR peuvent
#'     être exploitées pour effectuer des requêtes à l’échelle d’un patient
#'     unique. Il est alors nécessaire de prendre en compte les variables
#'     `BEN_IDT_ANO`, `BEN_RNG_GEM` et `BEN_ORG_AFF` afin d’assurer une
#'     interprétation correcte des identifiants. La variable `BEN_NIR_ANO`,
#'     bien qu’elle permette théoriquement de distinguer les individus
#'     de manière anonyme, peut être manquante. Quant à `BEN_RNG_GEM`,
#'     défini comme le rang gémellaire, il peut prendre différentes valeurs en
#'     cas de changement de régime, identifiable via la variable `BEN_ORG_AFF`.
#'      Source :
#'      https://documentation-snds.health-data-hub.fr/files/Sante_publique_France/2021-10-SpF-SNDS-ce-quil-faut-savoir-v3-MPL-2.0.pdf.
#'   - `cdi_nir_00` (Logical): permet d'identifier les `BEN_NIR_PSA` non fictifs
#'   - `nir_ano_defined` (Logical): permet d'identifier les `BEN_NIR_PSA` pour
#'      lesquels un `BEN_NIR_ANO` et un `BEN_IDT_ANO` sont défini
#'   - `birth_date_variation` (Logical): permet d'identifier les `BEN_IDT_ANO`
#'     présentant des dates de naissance différentes pour un même `BEN_IDT_ANO`
#'   - `sex_variation` (Logical): permet d'identifier les `BEN_IDT_ANO`
#'     présentant des codes sexe différents pour un même `BEN_IDT_ANO`
#'
#' @examples
#' \dontrun{
#' # Création et enregistrement dans Oracle de 100 couples de (BEN_NIR_PSA+BEN_RNG_GEM)
#' psa_sample_2 <- dplyr::tbl(conn, "IR_BEN_R") |>
#'   dplyr::select(BEN_NIR_PSA, BEN_RNG_GEM) |>
#'   head(100) |>
#'   dplyr::collect()
#' dbWriteTable(conn, "PSA_SAMP_2", psa_sample_2, overwrite = TRUE)
#' # Récupération de la table en format tibble
#' retrieve_all_psa_from_psa(conn = conn, ben_table_name = "PSA_SAMP_2")
#' # Récupération et enregistrement de la table dans Oracle
#' retrieve_all_psa_from_psa(
#'   conn = conn,
#'   ben_table_name = "PSA_SAMP_2",
#'   output_table_name = "TEST_SAVE_ORACLE"
#' )
#' # Récupération de la table sans considérer la table de référentiel archivée
#' retrieve_all_psa_from_psa(
#'   conn = conn,
#'   ben_table_name = "PSA_SAMP_2",
#'   check_arc_table = FALSE
#' )
#' }
#' @export
# nolint end
retrieve_all_psa_from_psa <- function(
  ben_table_name,
  conn = NULL,
  check_arc_table = TRUE,
  output_table_name = NULL
) {
  start_key <- "BEN_NIR_PSA"
  retrieve_psa(
    ben_table_name,
    start_key,
    conn,
    check_arc_table,
    output_table_name
  )
}
