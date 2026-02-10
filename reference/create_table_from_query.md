# Création d'une table à partir d'une requête SQL.

Création d'une table à partir d'une requête SQL.

## Usage

``` r
create_table_from_query(
  conn = NULL,
  output_table_name = NULL,
  query = NULL,
  overwrite = FALSE
)
```

## Arguments

- conn:

  Connexion à la base de données

- output_table_name:

  Nom de la table de sortie

- query:

  Requête SQL

- overwrite:

  Logical. Indique si la table `output_table_name` doit être écrasée
  dans le cas où elle existe déjà.

## Details

La fonction crée une table sous Oracle à partir d'une requête SQL. Si la
table `output_table_name` existe déjà, elle est écrasée si le paramètre
`overwrite` est TRUE.

## See also

Other utils: [`connect_duckdb()`](connect_duckdb.md),
[`connect_oracle()`](connect_oracle.md),
[`constants_snds_tools()`](constants_snds_tools.md),
[`gather_table_stats()`](gather_table_stats.md),
[`get_first_non_archived_year()`](get_first_non_archived_year.md),
[`insert_into_table_from_query()`](insert_into_table_from_query.md),
[`retrieve_all_psa_from_idt()`](retrieve_all_psa_from_idt.md),
[`retrieve_all_psa_from_psa()`](retrieve_all_psa_from_psa.md)
