# Fonction pour traiter un mois de délivrances de médicaments

Cette fonction est appelée par
[`extract_drug_erprsf`](extract_drug_erprsf.md) via pour construire et
exécuter la requête SQL d'un mois de flux. Elle reçoit une liste de
paramètres (`kwargs`) contenant les valeurs spécifiques au mois et les
autres paramètres de la fonction principale (noms des tables filtres,
nom de la table de sortie, ...).

## Usage

``` r
.extract_drug_by_month(kwargs)
```

## Arguments

- kwargs:

  Liste. Éléments :

  - `dis_dtd_year` entier. Année du flux FLX_DIS_DTD.

  - `dis_dtd_month` entier. Mois du flux FLX_DIS_DTD.

  - `is_first_month` logique. `TRUE` pour le premier mois (crée la table
    de sortie), `FALSE` pour les mois suivants (insère les lignes).

  - `formatted_start_date` caractère. Date de début de la période
    (YYYY‑MM‑DD).

  - `formatted_end_date` caractère. Date de fin de la période
    (YYYY‑MM‑DD).

  - `end_year` entier. Année de fin de la période.

  - `output_table_name` caractère. Nom de la table de destination.

  - `show_sql_query` logique. Si `TRUE`, la requête SQL du premier mois
    est journalisée.

  - `ir_pha_r_filtered_name` caractère. Nom de la table temporaire
    contenant les lignes filtrées de `IR_PHA_R`.

  - `sup_columns` vecteur de caractères. Colonnes supplémentaires à
    conserver.

  - `patients_ids_table_name` caractère ou `NULL`. Table temporaire avec
    les IDs patients.

  - `conn` connexion DBI. Connexion à la base (peut être `NULL` en
    workers parallèles).

## Value

Invisible `NULL`. La fonction crée ou ajoute des lignes à
`output_table_name` dans la base Oracle.

## Details

La fonction construit une requête joignant les tables de prescription et
de délivrance, applique les filtres médicaments, les filtres patients et
les colonnes additionnelles éventuelles, puis crée la table de sortie
(premier mois) ou y insère les lignes (mois suivants).

## See also

Other extract:
[`extract_consultations_erprsf()`](extract_consultations_erprsf.md),
[`extract_drug_erprsf()`](extract_drug_erprsf.md),
[`extract_hospital_consultations()`](extract_hospital_consultations.md),
[`extract_hospital_stays()`](extract_hospital_stays.md),
[`extract_long_term_disease()`](extract_long_term_disease.md)
