# Package index

## Extraction SNDS

Fonctions pour extraire les données de soins individuelles à partir du
SNDS.

- [`extract_consultations_erprsf()`](extract_consultations_erprsf.md) :
  Extraction des consultations dans le DCIR.
- [`extract_drug_dispenses()`](extract_drug_dispenses.md) : Extraction
  des délivrances de médicaments.
- [`extract_hospital_consultations()`](extract_hospital_consultations.md)
  : Extraction des consultations externes à l'hôpital (MCO).
- [`extract_hospital_stays()`](extract_hospital_stays.md) : Extraction
  des diagnostics des séjours hospitaliers (MCO).
- [`extract_long_term_disease()`](extract_long_term_disease.md) :
  Extraction des Affections Longue Durée (ALD)

## Extraction SNDS en SQL

Fonctions pour extraire les données de soins individuelles à partir du
SNDS en pur SQL.

- [`sql_extract_drug_dispenses()`](sql_extract_drug_dispenses.md) :
  Extraction des délivrances de médicaments à partir de SQL injecté dans
  du R (modèle dbExecute de Thomas Soeiro).

## Utilitaires

Fonctions utilitaires pour manipuler les données extraites.

- [`insert_into_table_from_query()`](insert_into_table_from_query.md) :
  Insertion des résultats d'une requête SQL dans une table existante.

- [`get_first_non_archived_year()`](get_first_non_archived_year.md) :
  Récupération de l'année non archivée la plus ancienne de la table
  ER_PRS_F.

- [`create_table_from_query()`](create_table_from_query.md) : Création
  d'une table à partir d'une requête SQL.

- [`connect_duckdb()`](connect_duckdb.md) : Initialisation de la
  connexion à la base de données duckdb.

- [`connect_oracle()`](connect_oracle.md) : Initialisation de la
  connexion à la base de données.

- [`gather_table_stats()`](gather_table_stats.md) : Récupération des
  statistiques des tables

- [`retrieve_all_psa_from_idt()`](retrieve_all_psa_from_idt.md) :

  Gestion des identifiants patients à l'aide de `BEN_IDT_ANO`

- [`retrieve_all_psa_from_psa()`](retrieve_all_psa_from_psa.md) :

  Gestion des identifiants patients à l'aide de `BEN_NIR_PSA`

## Données factices

Fonctions pour générer des données factices similaires à celles du SNDS.

- [`create_mock_database()`](create_mock_database.md) : Configurer une
  base de données DuckDB avec toutes les tables factices
- [`create_mock_er_ete_f()`](create_mock_er_ete_f.md) : Créer des
  données factices pour ER_ETE_F (Actes externes)
- [`create_mock_er_pha_f()`](create_mock_er_pha_f.md) : Créer des
  données factices pour les médicaments délivrés (ER_PHA_F)
- [`create_mock_er_prs_f()`](create_mock_er_prs_f.md) : Créer des
  données factices pour les délivrances de médicaments (ER_PRS_F)
- [`create_mock_ir_ben_r()`](create_mock_ir_ben_r.md) : Créer des
  données factices pour IR_BEN_R (référentiel bénéficiaires)
- [`create_mock_ir_imb_r()`](create_mock_ir_imb_r.md) : Créer des
  données factices pour les ALD (IR_IMB_R)
- [`create_mock_ir_pha_r()`](create_mock_ir_pha_r.md) : Créer des
  données factices pour le référentiel médicaments (IR_PHA_R)
- [`create_mock_mco_tables()`](create_mock_mco_tables.md) : Créer des
  données factices pour les séjours hospitaliers MCO (tables B, C, D,
  UM)
- [`create_mock_patients_ids()`](create_mock_patients_ids.md) :
  Fonctions pour créer des données factices pour le tutoriel sndsTools
