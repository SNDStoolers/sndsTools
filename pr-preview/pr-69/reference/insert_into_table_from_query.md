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

Other utils:
[`IS_PORTAIL`](https://sndstoolers.github.io/sndsTools/reference/IS_PORTAIL.md),
[`check_output_table_name()`](https://sndstoolers.github.io/sndsTools/reference/check_output_table_name.md),
[`connect_duckdb()`](https://sndstoolers.github.io/sndsTools/reference/connect_duckdb.md),
[`connect_oracle()`](https://sndstoolers.github.io/sndsTools/reference/connect_oracle.md),
[`create_table_from_query()`](https://sndstoolers.github.io/sndsTools/reference/create_table_from_query.md),
[`gather_table_stats()`](https://sndstoolers.github.io/sndsTools/reference/gather_table_stats.md),
[`get_first_non_archived_year()`](https://sndstoolers.github.io/sndsTools/reference/get_first_non_archived_year.md),
[`retrieve_all_psa_from_idt()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_all_psa_from_idt.md),
[`retrieve_all_psa_from_psa()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_all_psa_from_psa.md),
[`retrieve_psa()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_psa.md)
