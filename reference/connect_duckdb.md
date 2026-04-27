# Initialisation de la connexion à la base de données duckdb.

Utilisation pour les tests et les tutoriels. Si le code s'exécute en
dehors du portail, il faut initier une connexion duckdb pour effectuer
les tests.

## Usage

``` r
connect_duckdb(path2db = NULL)
```

## Arguments

- db_path:

  Character. Chemin vers la base de données duckdb à utiliser. Si NULL,
  la fonction utilise le chemin par défaut défini dans
  `PATH2SYNTHETIC_SNDS`.

## Value

dbConnection Connexion à la base de données duckdb

## See also

Other utils:
[`IS_PORTAIL`](https://sndstoolers.github.io/sndsTools/reference/IS_PORTAIL.md),
[`check_output_table_name()`](https://sndstoolers.github.io/sndsTools/reference/check_output_table_name.md),
[`connect_oracle()`](https://sndstoolers.github.io/sndsTools/reference/connect_oracle.md),
[`create_table_from_query()`](https://sndstoolers.github.io/sndsTools/reference/create_table_from_query.md),
[`gather_table_stats()`](https://sndstoolers.github.io/sndsTools/reference/gather_table_stats.md),
[`get_first_non_archived_year()`](https://sndstoolers.github.io/sndsTools/reference/get_first_non_archived_year.md),
[`insert_into_table_from_query()`](https://sndstoolers.github.io/sndsTools/reference/insert_into_table_from_query.md),
[`retrieve_all_psa_from_idt()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_all_psa_from_idt.md),
[`retrieve_all_psa_from_psa()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_all_psa_from_psa.md),
[`retrieve_psa()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_psa.md)
