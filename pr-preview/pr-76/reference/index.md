# Package index

## Extraction SNDS

Fonctions pour extraire les données de soins individuelles à partir du
SNDS.

- [`.extract_drug_by_month()`](dot-extract_drug_by_month.md) : Fonction
  pour traiter un mois de délivrances de médicaments
- [`extract_consultations_erprsf()`](extract_consultations_erprsf.md) :
  Extraction des consultations dans le DCIR.
- [`extract_drug_erprsf()`](extract_drug_erprsf.md) : Extraction des
  délivrances de médicaments.
- [`extract_hospital_consultations()`](extract_hospital_consultations.md)
  : Extraction des consultations externes à l'hôpital (MCO).
- [`extract_hospital_stays()`](extract_hospital_stays.md) : Extraction
  des diagnostics des séjours hospitaliers (MCO).
- [`extract_long_term_disease()`](extract_long_term_disease.md) :
  Extraction des Affections Longue Durée (ALD)

## Extraction SNDS en SQL

Fonctions pour extraire les données de soins individuelles à partir du
SNDS en pur SQL.

- [`sql_extract_drug_erprsf()`](sql_extract_drug_erprsf.md) : Extraction
  des délivrances de médicaments à partir de SQL injecté dans du R
  (modèle dbExecute de Thomas Soeiro).

## Utilitaires

Fonctions utilitaires pour manipuler les données extraites.

- [`connect_duckdb()`](connect_duckdb.md) : Initialisation de la
  connexion à la base de données duckdb.

- [`connect_oracle()`](connect_oracle.md) : Initialisation de la
  connexion à la base de données.

- [`constants_snds()`](constants_snds.md) : Stocke des constantes pour
  sndsTools

- [`create_table_from_query()`](create_table_from_query.md) : Création
  d'une table à partir d'une requête SQL.

- [`gather_table_stats()`](gather_table_stats.md) : Récupération des
  statistiques des tables

- [`get_first_non_archived_year()`](get_first_non_archived_year.md) :
  Récupération de l'année non archivée la plus ancienne de la table
  ER_PRS_F.

- [`insert_into_table_from_query()`](insert_into_table_from_query.md) :
  Insertion des résultats d'une requête SQL dans une table existante.

- [`parallelize_query_by_flx_month()`](parallelize_query_by_flx_month.md)
  : Exécute une fonction de construction de requête par mois de flux

- [`retrieve_all_psa_from_idt()`](retrieve_all_psa_from_idt.md) :

  Gestion des identifiants patients à l'aide de `BEN_IDT_ANO`

- [`retrieve_all_psa_from_psa()`](retrieve_all_psa_from_psa.md) :

  Gestion des identifiants patients à l'aide de `BEN_NIR_PSA`

## Constantes

Constantes (variable globales) utilisées dans le package. Par exemple,
noms de tables temporaires, listes de colonnes importantes, etc.

- [`TNAME_FILTER_IR_PHA_R`](TNAME_FILTER_IR_PHA_R.md) : Nom de la table
  temporaire pour les filtres ir_pha_r
- [`TNAME_FILTER_PATIENTS`](TNAME_FILTER_PATIENTS.md) : Nom de la table
  temporaire pour les IDs de patients
