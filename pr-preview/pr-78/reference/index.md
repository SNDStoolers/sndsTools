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

- [`connect_duckdb()`](connect_duckdb.md) : Initialisation de la
  connexion à la base de données duckdb.

- [`connect_oracle()`](connect_oracle.md) : Initialisation de la
  connexion à la base de données.

- [`constants_snds_tools()`](constants_snds_tools.md) : Stocke des
  constantes pour SndsTools

- [`create_table_from_query()`](create_table_from_query.md) : Création
  d'une table à partir d'une requête SQL.

- [`gather_table_stats()`](gather_table_stats.md) : Récupération des
  statistiques des tables

- [`get_first_non_archived_year()`](get_first_non_archived_year.md) :
  Récupération de l'année non archivée la plus ancienne de la table
  ER_PRS_F.

- [`insert_into_table_from_query()`](insert_into_table_from_query.md) :
  Insertion des résultats d'une requête SQL dans une table existante.

- [`retrieve_all_psa_from_idt()`](retrieve_all_psa_from_idt.md) :

  Gestion des identifiants patients à l'aide de `BEN_IDT_ANO`

- [`retrieve_all_psa_from_psa()`](retrieve_all_psa_from_psa.md) :

  Gestion des identifiants patients à l'aide de `BEN_NIR_PSA`
