#' Gestion des identifiants patients.
#' @description
#' Ces deux fonctions visent à extraire exhaustivement la clé de jointure
#' la plus fine (les `BEN_NIR_PSA`) pour un identifiant patient donné
#' (`BEN_IDT_ANO`) à partir d'une table d'entrée incluant l'un de ces deux
#' identifiants.
#'
#' Cinq variables sont ajoutées en sortie pour aider au processus d'inclusion :
#' 1. psa_w_multiple_idt : permet d'identifier les `BEN_IDT_ANO`
#' présentant des `BEN_NIR_PSA` associé à plusieurs `BEN_IDT_ANO`.
#' 2. cdi_nir_00 : permet d'identifier les `BEN_NIR_PSA` non fictifs.
#' 3. nir_ano_defined : permet d'identifier les `BEN_NIR_PSA` pour lesquels
#' un `BEN_NIR_ANO` est défini.
#' 4. birth_date_variation : permet d'identifier les `BEN_IDT_ANO`
#' présentant des inconsistances au niveau de la date de naissance.
#' 5. sex_variation : permet d'identifier les `BEN_IDT_ANO`
#' présentant des inconsistances relatives aux codes sexe.
#'
#' @details
#' @param ben_table_name Character Obligatoire. Nom de la table d'entrée
#'   comprenant au moins la variable `BEN_NIR_PSA` ou `BEN_IDT_ANO`.
#' 		Si la variable `BEN_RNG_GEM` est incluse, elle sera également
#' 		utilisée pour les jointures avec les référentiels.
#' @param check_arc_table Logical Optionnel. Si TRUE (par défaut), les tables
#'   `IR_BEN_R_ARC` sont également consultées pour la recherche des
#' 		`BEN_IDT_ANO` et des critères de sélection.
#' @param output_table_name Character Optionnel. Si fourni, les résultats seront
#'   sauvegardés dans une table portant ce nom dans Oracle. Sinon la table en
#'   sortie est retournée sous la forme d'un data.frame(/tibble).
#' @param conn DBI connection Optionnel Une connexion à la base de données Oracle.
#'   Si non fournie, une connexion est établie par défaut.
#' @return A partir d'une table avec `BEN_IDT_ANO`, la fonction retournera
#'   l'ensemble des `BEN_NIR_PSA` + `BEN_RNG_GEM` associés.
#'   A partir d'une table avec `BEN_NIR_PSA`, la fonction retournera
#'   l'ensemble des `BEN_NIR_PSA` + `BEN_RNG_GEM` associés au `BEN_IDT_ANO`.
#'   La table en sortie est une copie de(s) référentiel(s) `IR_BEN_R`
#' 	 (et `IR_BEN_R_ARC`) relatifs aux `BEN_IDT_ANO` impliqués et enregistrée
#' 		sous Oracle ou retournée sous la forme d'un data.frame(/tibble).
#'   Si output_table_name est `NULL`, retourne un data.frame(/tibble).
#'   Si output_table_name est fourni, sauvegarde les résultats dans la table
#' 	 spécifiée dans Oracle et retourne `NULL` de manière invisible.
#' 	 Dans les deux cas les colonnes de la table de sortie sont celles
#'   des tables `IR_BEN_R` et `IR_BEN_R_ARC` auxquelles sont ajoutées les variables:
#'   - psa_w_multiple_idt (Logical): permet d'identifier les `BEN_IDT_ANO`
#'     présentant des `BEN_NIR_PSA` associé à plusieurs `BEN_IDT_ANO`
#'   - cdi_nir_00 (Logical): permet d'identifier les `BEN_NIR_PSA` non fictifs
#'   - nir_ano_defined (Logical): permet d'identifier les `BEN_NIR_PSA` pour lesquels
#'     un `BEN_NIR_ANO` est défini
#'   - birth_date_variation (Logical): permet d'identifier les `BEN_IDT_ANO`
#'     présentant des dates de naissance différentes pour un même `BEN_IDT_ANO`
#'   - sex_variation (Logical): permet d'identifier les `BEN_IDT_ANO`
#'     présentant des codes sexe différents pour un même `BEN_IDT_ANO`
#'
#' @examples
#' \dontrun{
#' ex_1 <- dplyr::tbl(conn, "IR_BEN_R") |>
#'   dplyr::select(BEN_IDT_ANO) |>
#'   head(10) |>
#'   dplyr::collect()
#' dbWriteTable(conn, "SAMP", ex_1, overwrite = TRUE)
#' retrieve_all_psa_from_idt(ben_table_name = "SAMP")
#' retrieve_all_psa_from_idt(ben_table_name = "SAMP", output_table_name = "TEST_SAVE_ORACLE")
#' retrieve_all_psa_from_idt(ben_table_name = "SAMP", check_arc_table = FALSE)
#'
#' ex_2 <- dplyr::tbl(conn, "IR_BEN_R") |>
#'   dplyr::select(BEN_IDT_ANO, BEN_RNG_GEM) |>
#'   head(10) |>
#'   dplyr::collect()
#' dbWriteTable(conn, "SAMP", ex_2, overwrite = TRUE)
#' retrieve_all_psa_from_idt(ben_table_name = "SAMP")
#' retrieve_all_psa_from_idt(ben_table_name = "SAMP", output_table_name = "TEST_SAVE_ORACLE")
#' retrieve_all_psa_from_idt(ben_table_name = "SAMP", check_arc_table = FALSE)
#'
#' ex_3 <- dplyr::tbl(conn, "IR_BEN_R") |>
#'   dplyr::select(BEN_NIR_PSA) |>
#'   head(10) |>
#'   dplyr::collect()
#' dbWriteTable(conn, "SAMP", ex_3, overwrite = TRUE)
#' retrieve_all_psa_from_psa(ben_table_name = "SAMP")
#' retrieve_all_psa_from_psa(ben_table_name = "SAMP", output_table_name = "TEST_SAVE_ORACLE")
#' retrieve_all_psa_from_psa(ben_table_name = "SAMP", check_arc_table = FALSE)
#'
#' ex_4 <- dplyr::tbl(conn, "IR_BEN_R") |>
#'   dplyr::select(BEN_NIR_PSA, BEN_RNG_GEM) |>
#'   head(10) |>
#'   dplyr::collect()
#' dbWriteTable(conn, "SAMP", ex_4, overwrite = TRUE)
#' retrieve_all_psa_from_psa(ben_table_name = "SAMP")
#' retrieve_all_psa_from_psa(ben_table_name = "SAMP", output_table_name = "TEST_SAVE_ORACLE")
#' retrieve_all_psa_from_psa(ben_table_name = "SAMP", check_arc_table = FALSE)
#' }
#' @export

# Retrieve all of the PSA (+BEN_RNG_GEM) associated with the input IDT
retrieve_all_psa_from_idt <- function(conn = NULL,
                                      check_arc_table = TRUE,
                                      ben_table_name = "NULL",
                                      output_table_name = NULL) {
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
  if (!"BEN_IDT_ANO" %in% ben_table_colnames) {
    stop("ben_table_name must contain BEN_IDT_ANO")
  }

  # Handling BEN_RNG_GEM if included in the input table
  BEN_RNG_GEM_if_included <- if ("BEN_RNG_GEM" %in% ben_table_colnames) {
    "BEN_RNG_GEM"
  } else {
    NULL
  }
  psa_key <- c("BEN_NIR_PSA", BEN_RNG_GEM_if_included) |> purrr::compact()
  idt_key <- c("BEN_IDT_ANO", BEN_RNG_GEM_if_included) |> purrr::compact()

  # Select distinct values from the input table
  idt <- dplyr::tbl(conn, ben_table_name) |>
    dplyr::select(!!!rlang::syms(idt_key)) |>
    dplyr::distinct()

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
    dplyr::mutate(psa_w_multiple_idt = dplyr::n_distinct(BEN_IDT_ANO) > 1) |>
    dplyr::ungroup() |>
    dplyr::group_by(!!!rlang::syms(idt_key)) |>
    dplyr::mutate(
      psa_w_multiple_idt = any(psa_w_multiple_idt),
      cdi_nir_00 = !is.na(BEN_CDI_NIR) & BEN_CDI_NIR == "00",
      nir_ano_defined = !is.na(BEN_NIR_ANO),
      birth_date_variation = (dplyr::n_distinct(BEN_NAI_ANN) > 1 ||
        dplyr::n_distinct(BEN_NAI_MOI) > 1),
      sex_variation = dplyr::n_distinct(BEN_SEX_COD) > 1
    )
  # Handle output: Return or save the table
  if (is.null(output_table_name)) {
    if (connection_opened) DBI::dbDisconnect(conn)
    return(idt_psa)
  } else {
    DBI::dbWriteTable(conn,
      output_table_name, idt_psa |> dplyr::collect(),
      overwrite = TRUE
    )
    message(glue::glue("Results saved to table {output_table_name} in Oracle."))
    if (connection_opened) DBI::dbDisconnect(conn)
  }
}


# Retrieve all of the PSA (+BEN_RNG_GEM) associated with the input PSA
retrieve_all_psa_from_psa <- function(conn = NULL,
                                      check_arc_table = TRUE,
                                      ben_table_name = "NULL",
                                      output_table_name = NULL) {
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
  if (!"BEN_NIR_PSA" %in% ben_table_colnames) {
    stop("ben_table_name must contain BEN_NIR_PSA")
  }

  # Handling BEN_RNG_GEM if included in the input table
  BEN_RNG_GEM_if_included <- if ("BEN_RNG_GEM" %in% ben_table_colnames) {
    "BEN_RNG_GEM"
  } else {
    NULL
  }
  psa_key <- c("BEN_NIR_PSA", BEN_RNG_GEM_if_included) |> purrr::compact()
  idt_key <- c("BEN_IDT_ANO", BEN_RNG_GEM_if_included) |> purrr::compact()

  # BEN_IDT_ANO retrieval from BEN_NIR_PSA
  idt <- dplyr::tbl(conn, ben_table_name) |>
    dplyr::inner_join(ben, by = setNames(psa_key, psa_key)) |>
    dplyr::select(!!!rlang::syms(idt_key)) |>
    dplyr::distinct()

  # Consider archived table if requested
  if (check_arc_table) {
    psa_arc <- dplyr::tbl(conn, ben_table_name) |>
      dplyr::inner_join(ben_arc, by = setNames(psa_key, psa_key)) |>
      dplyr::select(!!!rlang::syms(idt_key))

    idt <- dplyr::union(idt, psa_arc) |>
      dplyr::distinct()
  }

  # Retrieve corresponding BEN_NIR_PSA
  idt_psa <- idt |>
    dplyr::inner_join(ben, by = setNames(idt_key, idt_key)) |>
    dplyr::distinct()

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
    dplyr::mutate(psa_w_multiple_idt = dplyr::n_distinct(BEN_IDT_ANO) > 1) |>
    dplyr::group_by(!!!rlang::syms(idt_key)) |>
    dplyr::mutate(
      psa_w_multiple_idt = any(psa_w_multiple_idt),
      cdi_nir_00 = !is.na(BEN_CDI_NIR) & BEN_CDI_NIR == "00",
      nir_ano_defined = !is.na(BEN_NIR_ANO),
      birth_date_variation = (dplyr::n_distinct(BEN_NAI_ANN) > 1 ||
        dplyr::n_distinct(BEN_NAI_MOI) > 1),
      sex_variation = dplyr::n_distinct(BEN_SEX_COD) > 1
    )
  # Return data.frame /tibble
  if (is.null(output_table_name)) {
    return(idt_psa)
    if (connection_opened) {
      DBI::dbDisconnect(conn)
    }
  } else { # Save table in Oracle
    dbWriteTable(conn, output_table_name, idt_psa, overwrite = TRUE)
    message(glue::glue("Results saved to table {output_table_name} in Oracle."))
    if (connection_opened) {
      DBI::dbDisconnect(conn)
    }
  }
}
