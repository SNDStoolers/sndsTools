#' Gestion des identifiants patients (IDT et PSA).
#' @description
#' Cette fonction vise à extraire la clé de jointure la plus fine
#' (les BEN_NIR_PSA+BEN_RNG_GEM) pour un identifiant patient donné (BEN_IDT_ANO)
#' à partir d'une table d'entrée incluant l'un de ces deux identifiants.
#'
#' A partir d'une table avec BEN_IDT_ANO, la fonction retournera
#' l'ensemble des BEN_NIR_PSA+BEN_RNG_GEM associés.
#' A partir d'une table avec BEN_NIR_PSA, la fonction retournera
#' l'ensemble des BEN_NIR_PSA+BEN_RNG_GEM associés au BEN_IDT_ANO.
#'
#' La table en sortie est une copie de(s) référentiel(s) IR_BEN_R (et IR_BEN_R_ARC)
#' relatifs aux BEN_IDT_ANO impliqués et enregistrée sous Oracle ou retournée
#' sous la forme d'un tibble.
#'
#' Cinq variables sont ajoutées en sortie pour l'aide à la sélection :
#' 1. psa_w_multiple_idt : permet d'identifier les BEN_IDT_ANO
#' présentant des BEN_NIR_PSA associé à plusieurs BEN_IDT_ANO.
#' 2. cdi_nir_00 : permet d'identifier les BEN_NIR_PSA non fictifs.
#' 3. nir_ano_defined : permet d'identifier les BEN_NIR_PSA pour lesquels
#' un BEN_NIR_ANO est défini.
#' 4. birth_date_variation : permet d'identifier les BEN_IDT_ANO
#' présentant des inconsistances au niveau de la date de naissance.
#' 5. sex_variation : permet d'identifier les BEN_IDT_ANO
#' présentant inconsistances relatives aux codes sexe.
#'
#' @details
#' @param ben_table_name Character Obligatoire. Nom de la table d'entrée
#'   comprenant au moins la variable BEN_NIR_PSA ou BEN_IDT_ANO.
#' @param check_arc_table Logical Optionnel. Si TRUE (par défaut), les tables IR_BEN_R_ARC sont
#'   également consultées pour la recherche des BEN_IDT_ANO et des critères de sélection.
#' @param output_table_name Character Optionnel. Si fourni, les résultats seront
#'   sauvegardés dans une table portant ce nom dans Oracle. Sinon la table en 
#' sortie est retournée sous la forme d'un tibble.
#' @param conn DBI connection Une connexion à la base de données Oracle.
#'   Si non fournie, une connexion est établie par défaut.
#' @return Si output_table_name est NULL, retourne un tibble.
#'   Si output_table_name est fourni, sauvegarde les
#'   résultats dans la table spécifiée dans Oracle et retourne NULL de manière
#'   invisible. Dans les deux cas les colonnes de la table de sortie sont celles 
#'   des tables IR_BEN_R et IR_BEN_R_ARC auxquelles sont ajoutées les variables:
#'   - psa_w_multiple_idt : permet d'identifier les BEN_IDT_ANO
#'     présentant des BEN_NIR_PSA associé à plusieurs BEN_IDT_ANO
#'   - cdi_nir_00 : permet d'identifier les BEN_NIR_PSA non fictifs
#'   - nir_ano_defined : permet d'identifier les BEN_NIR_PSA pour lesquels
#'     un BEN_NIR_ANO est défini
#'   - birth_date_variation : permet d'identifier les BEN_IDT_ANO
#'     présentant des dates de naissance différentes pour un même BEN_IDT_ANO
#'   - sex_variation : permet d'identifier les BEN_IDT_ANO
#'     présentant des codes sexe différents pour un même BEN_IDT_ANO
#'
#' @examples
#'# Sample data (BEN_NIR_PSA only)
#' tbl(conn, "IR_BEN_R") %>%
#'   select(BEN_NIR_PSA) %>%
#'   head(10) %>%
#'   collect() %>%
#'   dbWriteTable(conn, "SAMP", ., overwrite = TRUE)
#'
#' retrieve_patient_ids(conn, "SAMP")
#'
#' Sample data (BEN_NIR_PSA and BEN_RNG_GEM)
#' tbl(conn, "IR_BEN_R") %>%
#'   select(BEN_NIR_PSA, BEN_RNG_GEM) %>%
#'   head(10) %>%
#'   collect() %>%
#'   dbWriteTable(conn, "SAMP", ., overwrite = TRUE)
#'
#' retrieve_patient_ids(conn, "SAMP", check_arc_table = FALSE)
#'
#' # Sample data (BEN_IDT_ANO only)
#' tbl(conn, "IR_BEN_R") %>%
#'   select(BEN_IDT_ANO) %>%
#'   head(10) %>%
#'   collect() %>%
#'   dbWriteTable(conn, "SAMP", ., overwrite = TRUE)
#'
#' retrieve_patient_ids(conn, "SAMP", "TEST_SAVE_ORACLE")
#' @export

retrieve_patient_ids <- function(conn = NULL,
				 check_arc_table = TRUE,
                                 ben_table_name = NULL,
                                 output_table_name = NULL) {
  conn <- connect_oracle() # Connect to database

  # Check table format (ORACLE table)
  if (is.character(ben_table_name) & dbExistsTable(conn, ben_table_name)) {
    # pass
  } else {
    stop("ben_table_name must be a character name of an existing ORACLE table")
  }

  # Check table contents and retrieve BEN_IDT_ANO in both archived and non-archived tables
  if ("BEN_IDT_ANO" %in% (tbl(conn, ben_table_name) %>% colnames())) {
    idt <- tbl(conn, ben_table_name) %>%
      select(BEN_IDT_ANO) %>%
      distinct()
  } else if ("BEN_NIR_PSA" %in% (tbl(conn, ben_table_name) %>% colnames())) {
		# Consider BEN_RNG_GEM for join if available
    join_cond <- ifelse(
      all(c("BEN_NIR_PSA", "BEN_RNG_GEM") %in% (tbl(conn, ben_table_name) %>%
        colnames())),
      c("BEN_NIR_PSA", "BEN_RNG_GEM"),
      c("BEN_NIR_PSA")
    )
    psa_reg <- tbl(conn, ben_table_name) %>%
      select(BEN_NIR_PSA) %>%
      left_join(tbl(conn, "IR_BEN_R"), by = join_cond) %>%
      select(BEN_IDT_ANO) %>%
      distinct()
  # Consider archived table if requested
  if (check_arc_table) {
    psa_arc <- tbl(conn, ben_table_name) %>%
      select(BEN_NIR_PSA) %>%
      left_join(tbl(conn, "IR_BEN_R_ARC"), by = join_cond) %>%
      select(BEN_IDT_ANO) %>%
      distinct()

    idt <- union_all(psa_reg, psa_arc) %>%
      distinct()
  } else { # Only consider non-archived table
		idt <- psa_reg, psa_arc %>%
			distinct()
  }
  } else {
    stop("ben_table_name must contain (at least) either BEN_IDT_ANO or BEN_NIR_PSA")
  }

  # Retrieve corresponding BEN_NIR_PSA
  idt_psa_reg <- idt %>%
    inner_join(tbl(conn, "IR_BEN_R"), by = "BEN_IDT_ANO") %>%
    filter(!is.na(BEN_NIR_PSA))
  # Consider archived table if requested
 if (check_arc_table) {
   idt_psa_arc <- idt %>%
     inner_join(tbl(conn, "IR_BEN_R_ARC"), by = "BEN_IDT_ANO") %>%
     filter(!is.na(BEN_NIR_PSA))
   idt_psa <-  union_all(idt_psa_reg, idt_psa_arc)
 } else { # Only consider non-archived table
   idt_psa <- idt_psa_reg
 }
  # Assessment of exclusion criteria
  idt_psa <- idt_psa %>%
    distinct() %>%
    collect() %>%
    group_by(BEN_NIR_PSA) %>%
    mutate(psa_w_multiple_idt = n_distinct(BEN_IDT_ANO) > 1) %>%
    group_by(BEN_IDT_ANO) %>%
    mutate(
      psa_w_multiple_idt = any(psa_w_multiple_idt), # flag IDT with PSA associated w/ multiple IDT
      cdi_nir_00 = !is.na(BEN_CDI_NIR) & BEN_CDI_NIR == "00", # flag non-fictive NIR
      nir_ano_defined = !is.na(BEN_NIR_ANO), # flag defined BEN_NIR_ANO
      birth_date_variation = (n_distinct(BEN_NAI_ANN) > 1 || n_distinct(BEN_NAI_MOI) > 1), # flag IDT with multiple birth dates
      sex_variation = n_distinct(BEN_SEX_COD) > 1 # flag IDT with multiple sex codes
    )
  # Return tibble
  if (is.null(output_table_name)) {
    return(idt_psa)
    dbDisconnect(conn)
  } else { # Save table in Oracle
    dbWriteTable(conn, output_table_name, idt_psa, overwrite = TRUE)
    dbDisconnect(conn)
  }
}
