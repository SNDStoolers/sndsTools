# Package index

## Extraction SNDS

Fonctions pour extraire les données de soins individuelles à partir du
SNDS.

- [`extract_consultations_erprsf()`](https://sndstoolers.github.io/sndsTools/reference/extract_consultations_erprsf.md)
  : Extraction des consultations dans le DCIR.
- [`extract_drug_dispenses()`](https://sndstoolers.github.io/sndsTools/reference/extract_drug_dispenses.md)
  : Extraction des délivrances de médicaments.
- [`extract_drug_erucdf()`](https://sndstoolers.github.io/sndsTools/reference/extract_drug_erucdf.md)
  : Extrait les dispensations de médicaments en accès précoces depuis le
  DCIR.
- [`extract_hospital_consultations()`](https://sndstoolers.github.io/sndsTools/reference/extract_hospital_consultations.md)
  : Extraction des consultations externes à l'hôpital (MCO).
- [`extract_hospital_stays()`](https://sndstoolers.github.io/sndsTools/reference/extract_hospital_stays.md)
  : Extraction des diagnostics des séjours hospitaliers (MCO).
- [`extract_long_term_disease()`](https://sndstoolers.github.io/sndsTools/reference/extract_long_term_disease.md)
  : Extraction des Affections Longue Durée (ALD)

## Extraction SNDS en SQL

Fonctions pour extraire les données de soins individuelles à partir du
SNDS en pur SQL.

- [`sql_extract_drug_dispenses()`](https://sndstoolers.github.io/sndsTools/reference/sql_extract_drug_dispenses.md)
  : Extraction des délivrances de médicaments à partir de SQL injecté
  dans du R (modèle dbExecute de Thomas Soeiro).

## Utilitaires

Fonctions utilitaires pour manipuler les données extraites.

- [`IS_PORTAIL`](https://sndstoolers.github.io/sndsTools/reference/IS_PORTAIL.md)
  : Est-ce que le code tourne sur le portail de la CNAM ?

- [`check_output_table_name()`](https://sndstoolers.github.io/sndsTools/reference/check_output_table_name.md)
  : Vérifie la validité du nom de la table de sortie Oracle.

- [`connect_duckdb()`](https://sndstoolers.github.io/sndsTools/reference/connect_duckdb.md)
  : Initialisation de la connexion à la base de données duckdb.

- [`connect_oracle()`](https://sndstoolers.github.io/sndsTools/reference/connect_oracle.md)
  : Initialisation de la connexion à la base de données.

- [`create_table_from_query()`](https://sndstoolers.github.io/sndsTools/reference/create_table_from_query.md)
  : Création d'une table à partir d'une requête SQL.

- [`gather_table_stats()`](https://sndstoolers.github.io/sndsTools/reference/gather_table_stats.md)
  : Récupération des statistiques des tables

- [`get_first_non_archived_year()`](https://sndstoolers.github.io/sndsTools/reference/get_first_non_archived_year.md)
  : Récupération de l'année non archivée la plus ancienne de la table
  ER_PRS_F.

- [`insert_into_table_from_query()`](https://sndstoolers.github.io/sndsTools/reference/insert_into_table_from_query.md)
  : Insertion des résultats d'une requête SQL dans une table existante.

- [`retrieve_all_psa_from_idt()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_all_psa_from_idt.md)
  :

  Gestion des identifiants patients à l'aide de `BEN_IDT_ANO`

- [`retrieve_all_psa_from_psa()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_all_psa_from_psa.md)
  :

  Gestion des identifiants patients à l'aide de `BEN_NIR_PSA`

- [`retrieve_psa()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_psa.md)
  : Generic function retrieving patient identifiers

## Données synthétiques

Fonctions utilisées pour générer des données synthétiques similaires à
celles du SNDS.

- [`connect_synthetic_data_avc()`](https://sndstoolers.github.io/sndsTools/reference/connect_synthetic_data_avc.md)
  : Configurer une base de données DuckDB avec toutes les tables
  factices
- [`connect_synthetic_snds()`](https://sndstoolers.github.io/sndsTools/reference/connect_synthetic_snds.md)
  : Télécharge les données synthétiques SNDS et les charge dans une base
  DuckDB
- [`create_mock_er_ete_f()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_er_ete_f.md)
  : Créer des données factices pour ER_ETE_F (Actes externes)
- [`create_mock_er_pha_f()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_er_pha_f.md)
  : Créer des données factices pour les médicaments délivrés (ER_PHA_F)
- [`create_mock_er_prs_f()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_er_prs_f.md)
  : Créer des données factices pour les délivrances de médicaments
  (ER_PRS_F)
- [`create_mock_ir_ben_r()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_ir_ben_r.md)
  : Créer des données factices pour IR_BEN_R (référentiel bénéficiaires)
- [`create_mock_ir_imb_r()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_ir_imb_r.md)
  : Créer des données factices pour les ALD (IR_IMB_R)
- [`create_mock_ir_pha_r()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_ir_pha_r.md)
  : Créer des données factices pour le référentiel médicaments
  (IR_PHA_R)
- [`create_mock_mco_tables()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_mco_tables.md)
  : Créer des données factices pour les séjours MCO (tables B, C, D, UM)
- [`create_mock_patients_ids()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_patients_ids.md)
  : Fonctions pour créer des données factices pour le tutoriel sndsTools
- [`download_synthetic_snds_csv()`](https://sndstoolers.github.io/sndsTools/reference/download_synthetic_snds_csv.md)
  : Télécharger les fichiers CSV synthétiques SNDS
- [`get_kwikly_format()`](https://sndstoolers.github.io/sndsTools/reference/get_kwikly_format.md)
  : Obtenir les formats de colonnes à partir du fichier kwikly
- [`insert_synthetic_snds_table()`](https://sndstoolers.github.io/sndsTools/reference/insert_synthetic_snds_table.md)
  : Insérer un fichier CSV dans une table DuckDB
