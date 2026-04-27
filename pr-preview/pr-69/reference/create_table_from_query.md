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
  dans le cas où elle existe déjà. Défaut à FALSE.

## Details

La fonction crée une table sous Oracle à partir d'une requête SQL. Si la
table `output_table_name` existe déjà, elle est écrasée si le paramètre
`overwrite` est TRUE.

## See also

Other utils:
[`IS_PORTAIL`](https://sndstoolers.github.io/sndsTools/reference/IS_PORTAIL.md),
[`check_output_table_name()`](https://sndstoolers.github.io/sndsTools/reference/check_output_table_name.md),
[`connect_duckdb()`](https://sndstoolers.github.io/sndsTools/reference/connect_duckdb.md),
[`connect_oracle()`](https://sndstoolers.github.io/sndsTools/reference/connect_oracle.md),
[`gather_table_stats()`](https://sndstoolers.github.io/sndsTools/reference/gather_table_stats.md),
[`get_first_non_archived_year()`](https://sndstoolers.github.io/sndsTools/reference/get_first_non_archived_year.md),
[`insert_into_table_from_query()`](https://sndstoolers.github.io/sndsTools/reference/insert_into_table_from_query.md),
[`retrieve_all_psa_from_idt()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_all_psa_from_idt.md),
[`retrieve_all_psa_from_psa()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_all_psa_from_psa.md),
[`retrieve_psa()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_psa.md)
