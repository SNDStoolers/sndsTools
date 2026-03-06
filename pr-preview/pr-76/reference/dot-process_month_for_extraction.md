# Fonction helper pour traiter un mois individuel dans extract_drug_dispenses

Fonction interne utilisée par extract_drug_dispenses pour traiter un
mois de flux en parallèle avec parLapply.

## Usage

``` r
.process_month_for_extraction(month_params)
```

## Arguments

- month_params:

  List contenant les paramètres pour un mois :

  - year: Integer, l'année du flux

  - month: Integer, le mois du flux

  - is_first_month: Logical, TRUE si c'est le premier mois traité

  - start_year: Integer, l'année de début de la période

  - end_year: Integer, l'année de fin de la période

  - dis_dtd_end_month: Integer, le mois de fin pour FLX_DIS_DTD

  - formatted_start_date: Character, date formatée de début (YYYY-MM-DD)

  - formatted_end_date: Character, date formatée de fin (YYYY-MM-DD)

  - output_table_name: Character, nom de la table de sortie

  - show_sql_query: Logical, afficher la requête SQL du premier mois

  - oracle_parallelism: Integer ou NULL, degré de parallélisme Oracle

  - first_non_archived_year: Integer, première année non archivée

## Value

Invisible NULL (modifie la table output_table_name en base de données)

## Details

Cette fonction est destinée à être utilisée via
[`parallel::parLapply()`](https://rdrr.io/r/parallel/clusterApply.html)
et ne doit pas être appelée directement par l'utilisateur.
