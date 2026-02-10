# Insertion des résultats d'une requête SQL dans une table existante.

Insertion des résultats d'une requête SQL dans une table existante.

## Usage

``` r
insert_into_table_from_query(
  conn = NULL,
  output_table_name = NULL,
  query = NULL
)
```

## Arguments

- conn:

  Connexion à la base de données

- output_table_name:

  Nom de la table de sortie

- query:

  Requête SQL

## See also

Other utils: [`connect_duckdb()`](connect_duckdb.md),
[`connect_oracle()`](connect_oracle.md),
[`constants_snds_tools()`](constants_snds_tools.md),
[`create_table_from_query()`](create_table_from_query.md),
[`gather_table_stats()`](gather_table_stats.md),
[`get_first_non_archived_year()`](get_first_non_archived_year.md),
[`retrieve_all_psa_from_idt()`](retrieve_all_psa_from_idt.md),
[`retrieve_all_psa_from_psa()`](retrieve_all_psa_from_psa.md)
