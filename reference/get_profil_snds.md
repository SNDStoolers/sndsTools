# Récupération du profil SNDS de l'utilisateur connecté.

Sur le portail, chaque utilisateur appartient à un profil (`PROFIL_XXX`)
qui est le schéma hébergeant les tables du SNDS. Le nom du profil est
déduit de l'identifiant Oracle, par exemple `ORAxxxxxx123` -\>
`PROFIL_123`.

## Usage

``` r
get_profil_snds(conn)
```

## Arguments

- conn:

  Connexion à la base de données

## Value

Nom du schéma du profil, ou NULL si la connexion n'est pas Oracle (par
exemple sur la base synthétique duckdb).

## See also

Other utils:
[`.onLoad()`](https://sndstoolers.github.io/sndsTools/reference/dot-onLoad.md),
[`check_output_table_name()`](https://sndstoolers.github.io/sndsTools/reference/check_output_table_name.md),
[`connect_oracle()`](https://sndstoolers.github.io/sndsTools/reference/connect_oracle.md),
[`create_table_from_query()`](https://sndstoolers.github.io/sndsTools/reference/create_table_from_query.md),
[`gather_table_stats()`](https://sndstoolers.github.io/sndsTools/reference/gather_table_stats.md),
[`get_first_non_archived_year()`](https://sndstoolers.github.io/sndsTools/reference/get_first_non_archived_year.md),
[`insert_into_table_from_query()`](https://sndstoolers.github.io/sndsTools/reference/insert_into_table_from_query.md),
[`retrieve_all_psa_from_idt()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_all_psa_from_idt.md),
[`retrieve_all_psa_from_psa()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_all_psa_from_psa.md),
[`retrieve_psa()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_psa.md),
[`tbl_oracle()`](https://sndstoolers.github.io/sndsTools/reference/tbl_oracle.md),
[`write_oracle_table_by_batch()`](https://sndstoolers.github.io/sndsTools/reference/write_oracle_table_by_batch.md)
