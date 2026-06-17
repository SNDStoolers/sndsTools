## Utilitaires spécifiques aux IJ

#' Produit les listes de codes pour extraire des données SNDS
#'
#' @export
#' @family ij
snds_codes <- function() {
  all_codes <- list()
  # Codes prestations
  ## Pour les IJ
  # nolint start
  # Cette liste de codes provient de [la documentation SNDS](https://documentation-snds.health-data-hub.fr/snds/fiches/indemnites_journalieres.html#les-indemnites-journalieres-dans-le-snds)
  # Elle a été ajusté après discussion avec les auteurs à la CNAM de [Colinot et al., 2024](https://drees.solidarites-sante.gouv.fr/sites/default/files/2024-12/ER1321_0.pdf)
  # Quatres codes supplémentaires sont listés sur [le forum d'entraide](https://entraide.health-data-hub.fr/t/indemnite-journaliere/1102) et semblent concerner le délai de carence. : 6011,6012,6013,6014.
  # nolint end
  all_codes$ij_prs_nat_ref <- c(
    # "6011", # Carence -
    # "6012", # Carence +
    # "6013", # IJ Carence
    # "6014", # Complement IJ
    # IJ maladie ou ATMP
    "6110", # IJ NORMALES +6MOIS
    "6111", # IJ NORMALES -3MOIS
    "6112", # IJ NORMALES +3MOIS
    "6113", # IJ REDUITES -3MOIS
    "6114", # IJ REDUITES +3MOIS
    "6115", # IJ MAJOREES -3MOIS
    "6116", # IJ MAJOREES +3MOIS
    "6117", # IJ PARTIELLE, PERTE DE SALAIRE -3MOIS
    "6118", # IJ PARTIELLE, PERTE DE SALAIRE +3MOIS
    "6119", # IJ MAJOREES +6MOIS
    "6120", # Indemnité temporaire d'inaptitude AT/MP
    "6131", # IJ normales pour cure thermale
    "6132", # IJ majorées pour cure thermale
    "6133" # IJ réduites pour cure thermale
    # IJ maternité
    # "6121", # IJ PRENATALES
    # "6122", # IJ POSTNATALES
    # "6123", # IJ EN CAS D’ADOPTION
    # "6124" # IJ CONGE SUPPLEMENTAIRE PREMA
    # "6126", # Forfait grossesse taux plein TI
    # "6127", # Forfait grossesse taux réduit TI
    # "6128", # Forfait adoption taux plein TI
    # "6129", # Forfait adoption taux réduit TI
    # "6212", # IJ CONGE MATERNITE AU PERE
    # "6134", # INDEMNITE MALADIE PAMC -3MOIS
    # "6135", # INDEMNITE MALADIE PAMC +3MOIS
    # "6239" # INDEMNITE MALADIE DOUBLE ACTIVITE PAMC
  )

  # Codes régimes pour les IJ
  # Ne conserve que les salariés du privé ou contractuels du régime général
  # liste des petits régimes à conserver (RGM_COD)
  list_filtre_regime_general <- list(
    "1" = c(
      1, # SALARIES EXCLUSIVEMENT POUR RISQUE PROFESSIONNEL
      100, # AGENTS NON TITULAIRE DE L'ETAT
      101, # SALARIES DU REGIME SPECIAL non agricole
      102, # SALARIES REGIME GENERAL AT. GERE PAR ENTREPRISE
      200, # SALARIES : MALADIE, MATERNITE, DECES, INVALIDITE (SOINS UNIQUEMENT)
      201, # ASSURES POUR MALADIE, MATERNITE, DECES, AT
      210 # SALARIES POUVANT PRETENDRE: MAT. INVAL. DECES
    )
  )
  df_filtre_regime_general <- stack(list_filtre_regime_general)
  colnames(df_filtre_regime_general) <- c("RGM_COD", "RGM_GRG_COD")
  all_codes$main_regime_codes <- df_filtre_regime_general

  df_filtre_regime_alsace_moselle <- stack(list(
    "10" = c(
      206, # SALARIE DU REGIME ALSACE-MOSELLE POUR COMPLEMENT CRPCEN
      207 # RETRAITE DU REGIME ALSACE MOSELLE POUR PS  )
    )
  ))
  colnames(df_filtre_regime_alsace_moselle) <- c("RGM_COD", "RGM_GRG_COD")
  all_codes$alsace_moselle_regime_codes <- df_filtre_regime_alsace_moselle

  all_codes
}

# nolint start
#' Extraction des indemnités journalières sans retraitement (brutes)
#' @description
#' Cette fonction permet d'extraire les indemnités journalières (IJ) brutes
#' depuis la table ER_PRS_F pour une période donnée. Elle utilise les codes de
#' prestations spécifiques aux indemnités journalières et sauvegarde les
#' résultats dans une table Oracle.
#'
#' @details
#' La fonction extrait les IJ en utilisant une liste prédéfinie de codes de
#' prestations provenant d'un échange avec l'assurance maladie. Ces codes incluent les IJ normales, réduites, partielles, majorées, maternité,
#' adoption, et autres types d'indemnités (cf. section exemple ci-dessous pour la liste de codes utilisées).
#' Des filtres supplémentaires obtenues auprès de Colinot et al. (2024) sont ajoutés pour ne conserver que les régimes du champ d'étude, à savoir le régime général sans les indépendants, praticiens et auxiliaires médicaux conventionnés. Ces filtres concernent le code petit régime `RGM_COD`, le code de l'organisme d'affiliation du bénéficiaire `ORG_AFF_BEN` et le top facture travailleurs indépendants `PRS_FAC_TOP`. Un filtre temporel est également appliqué pour ne conserver que les flux de traitement dans les 6 mois suivant la date de début de l'IJ, afin d'avoir un champ constant pour les dates de flux (notamment pour les ATMP qui peuvent être traités longtemps après la date de début de l'IJ).
#'
#' Les données extraites sont sauvegardées dans une table Oracle temporaire.
#'
#' @param start_date Date. La date de début de la période des IJ à extraire.
#' @param end_date Date. La date de fin de la période des IJ à extraire.
#' @param patients_ids_filter data frame (Optionnel). Un data frame contenant
#' les paires d'identifiants des patients pour lesquels les consultations
#' doivent être extraites. Les colonnes de ce data frame doivent être
#' `BEN_IDT_ANO`, `BEN_NIR_PSA` et `BEN_RNG_GEM`. Les BEN_NIR_PSA doivent être
#' tous les BEN_NIR_PSA associés
#' aux BEN_IDT_ANO fournis. Défaut à `NULL`.
#' @param conn DBI connection (Optionnel). Une connexion à la base de données
#' Oracle. Par défaut, une connexion est établie automatiquement.
#' @param sup_columns Vecteur de noms de colonnes (Optionnel). 
#' Ajoute ces colonnes à la table créée. Défaut à `NULL`.
#' @param output_table_name Character (Optionnel). Si fourni, les résultats
#' seront sauvegardés dans une table portant ce nom dans la base de données au
#' lieu d'être retournés sous forme de lazy table. Si cette table existe déjà,
#' le programme s'arrête avec un message d'erreur. Défaut à `NULL`.
#' @param exe_dtd_lag_months Integer (Optionnel). Le nombre maximum de mois de
#' décalage de `FLX_TRT_DTD` (date d'entrée de l'IJ dans le SI) par rapport à `EXE_SOI_DTD` (date de versement de l'IJ) pris en compte pour
#' récupérer les consultations. Défaut à 6 mois.
#'
#' @return @return Si `output_table_name` est `NULL`, retourne une lazy table contenant
#' les consultations. Si `output_table_name` est fourni, sauvegarde les
#' résultats dans la table spécifiée dans Oracle et retourne le nom de la table.
#' Dans les deux cas les colonnes de la table de sortie sont :
#'   - Toutes les colonnes standard de [`extract_consultations_erprsf()`]
#'   - `RGO_ASU_NAT` : Nature d'assurance
#'   - `EXE_SOI_DTF` : Date de fin de soins
#'   - `BSE_REM_MNT` : Montant versé/remboursé (acte de base)
#'   - `PRS_ACT_NBR` : Nombre réel de jours indemnisés
#'   - `IJR_EMP_NUM` : Numéro de l'employeur (Siret)
#'
#' @examples
#' \dontrun{
#' # Extraction des IJ pour l'année 2020
#' extract_ij_erprsf(
#'   start_date = as.Date("2020-01-01"),
#'   end_date = as.Date("2020-12-31")
#' )
#' }
#' # Codes prestations utilisés
#' print(snds_codes()$ij_prs_nat_ref)
#' # Codes régimes principaux utilisés
#' print(snds_codes()$main_regime_codes)
#' @seealso
#' [`extract_consultations_erprsf()`] pour la fonction sous-jacente d'extraction
#'
#' @export
# nolint end
extract_ij_erprsf <- function(
  start_date,
  end_date,
  patients_ids_filter,
  conn,
  sup_columns = NULL,
  output_table_name = NULL,
  exe_dtd_lag_months = 6
) {
  all_codes <- snds_codes()
  ij_atmp_prs_nat_ref_codes <- all_codes$ij_prs_nat_ref

  ij_sup_columns <- c(
    "RGO_ASU_NAT", # Nature d'assurance
    "EXE_SOI_DTF",
    "BSE_REM_MNT", # Montant versé/remboursé (acte de base)
    "PRS_ACT_NBR", # Dénombrement (signé) d'actes: correspond pour les ij aux nombre réel de jours indemnisés (cf. [documentation SNDS](https://entraide.health-data-hub.fr/t/indemnites-journalieres-nombre-et-valeurs-etonnantes/2714/2)) #nolint
    "IJR_EMP_NUM" # Numéro de l'employeur (Siret)
  )
    
  required_filter_columns <- c(
    "FLX_TRT_DTD",
    "ORL_BSE_NUM",
    "FLX_DIS_DTD",
    "PRS_FAC_TOP",
    "ORG_AFF_BEN",
    "RGM_COD"
  )  
    
  if (!is.null(sup_columns)) {
    ij_sup_columns <- c(ij_sup_columns, sup_columns)
  }
  # Extraction des IJ par création d'une table Oracle
  logger::log_info("Extracting RAW IJ from ER_PRSRF.")

  extracted_consultation_query <- extract_consultations_erprsf(
    start_date = start_date,
    end_date = end_date,
    pse_spe_filter = NULL,
    prestation_filter = ij_atmp_prs_nat_ref_codes,
    sup_columns = c(ij_sup_columns, required_filter_columns),
    patients_ids_filter = patients_ids_filter,
    conn = conn
  )
    
  # Régime général uniquement
  sql_filter_regime_general <- glue::glue(
    "(ORL_BSE_NUM LIKE '01%')" # nolint
  )
  # sans les indépendants
  sql_filter_no_independant <- "
(
  (EXTRACT(YEAR FROM FLX_DIS_DTD) <= 2019) AND
      ((PRS_FAC_TOP <> '1') OR (PRS_FAC_TOP IS NULL))
  )
   OR (
  (EXTRACT(YEAR FROM FLX_DIS_DTD) >= 2020) AND
      ((PRS_FAC_TOP <> '1') OR (PRS_FAC_TOP IS NULL)) AND
  (
    (NOT (ORG_AFF_BEN LIKE '01C%')) OR
    (SUBSTR(ORG_AFF_BEN, -3, 3) <> '895') OR
    (RGM_COD NOT IN (110, 120, 224, 330))
  )
)"
  # sans les praticiens et auxiliaires médicaux conventionnés
  ## utile seulement >=2021 pour les ij maladies et >=2022 pour les maternités
  sql_filter_no_pamc <- "(RGM_COD < 900) OR (RGM_COD > 990)"
  # Conserve uniquement les lignes avec versement dans les 6 mois après date de début de l'IJ pour avoir un champ constant. Joue notamment beaucoup pour les ATMP. #nolint
  sql_filter_flux_trs_dtd <- glue::glue("(FLX_TRT_DTD - EXE_SOI_DTD) <= {exe_dtd_lag_months * 12}")
  sql_sup_filter <- glue::glue(
    "({sql_filter_regime_general}) AND
    ({sql_filter_flux_trs_dtd}) AND
    ({sql_filter_no_independant}) AND
    ({sql_filter_no_pamc})"
  )
    
  extracted_consultation_query <- extracted_consultation_query |>
      dplyr::filter(dplyr::sql(sql_sup_filter)) |>
      dplyr::select(
        tidyselect::any_of(c("BEN_IDT_ANO", "BEN_NIR_PSA")),
        tidyselect::all_of(c(
            "BEN_RNG_GEM",
            "EXE_SOI_DTD", "EXE_SOI_DTF", "PRS_ACT_NBR", "BSE_REM_MNT",
            "PFS_EXE_NUM", "PRS_NAT_REF", "RGO_ASU_NAT", "IJR_EMP_NUM"
          ))
        )

  if (!is.null(output_table_name)) {
    extracted_consultation_query |> 
        dplyr::compute(name = output_table_name)
      
    logger::log_info(glue::glue(
        "Filtered table on main regimes saved as {output_table_name}. End of raw IJ extraction." # nolint
      ))
    
    output_table_name
  } else {
    logger::log_info(glue::glue(
        "Filtered table on main regimes returned as a tbl lazy. End of raw IJ extraction." # nolint
      ))
    
    extracted_consultation_query
  }
}
