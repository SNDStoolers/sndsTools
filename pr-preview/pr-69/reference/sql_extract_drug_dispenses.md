# Extraction des délivrances de médicaments à partir de SQL injecté dans du R (modèle dbExecute de Thomas Soeiro).

Cette fonction permet d'extraire les délivrances de médicaments par code
ATC ou par code CIP13. Les délivrances dont les dates `EXE_SOI_DTD` sont
comprises entre `start_date` et `end_date` (incluses) sont extraites.

## Usage

``` r
sql_extract_drug_dispenses(
  start_date,
  end_date,
  output_table_name,
  atc_cod_starts_with_filter = NULL,
  cip13_cod_filter = NULL,
  conn = NULL
)
```

## Arguments

- start_date:

  Date. La date de début de la période des délivrances des médicaments à
  extraire.

- end_date:

  Date. La date de fin de la période des délivrances des médicaments à
  extraire.

- output_table_name:

  Character (Optionnel). Si fourni, les résultats seront sauvegardés
  dans une table portant ce nom dans la base de données au lieu d'être
  retournés sous forme de data frame. Défault à NULL.

- atc_cod_starts_with_filter:

  Character vector (Optionnel). Les codes ATC par lesquels les
  délivrances de médicaments à extraire doivent commencer. Défaut à
  NULL.

- cip13_cod_filter:

  Character vector (Optionnel). Les codes CIP des délivrances de
  médicaments à extraire en complément des codes ATC. Défaut à NULL.

- conn:

  DBI connection (Optionnel). Une connexion à la base de données Oracle.
  Si non fournie, une connexion est établie par défaut. Défaut à NULL.
