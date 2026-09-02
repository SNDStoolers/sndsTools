# Accès à une table du SNDS en qualifiant le schéma du profil.

Certaines mises à jour du portail cassent les connexions Oracle qui ne
déclarent pas le schéma. Cette fonction préfixe donc la table par le
profil de l'utilisateur. Hors Oracle, elle se rabat sur
[`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html).

## Usage

``` r
tbl_oracle(conn, table_name, profil = NULL)
```

## Arguments

- conn:

  Connexion à la base de données

- table_name:

  Nom de la table

- profil:

  Nom du schéma du profil. Par défaut, celui de l'utilisateur connecté.

## Value

Table lazy

## See also

Other utils:
[`.onLoad()`](https://sndstoolers.github.io/sndsTools/reference/dot-onLoad.md),
[`check_output_table_name()`](https://sndstoolers.github.io/sndsTools/reference/check_output_table_name.md),
[`connect_oracle()`](https://sndstoolers.github.io/sndsTools/reference/connect_oracle.md),
[`create_table_from_query()`](https://sndstoolers.github.io/sndsTools/reference/create_table_from_query.md),
[`gather_table_stats()`](https://sndstoolers.github.io/sndsTools/reference/gather_table_stats.md),
[`get_first_non_archived_year()`](https://sndstoolers.github.io/sndsTools/reference/get_first_non_archived_year.md),
[`get_profil_snds()`](https://sndstoolers.github.io/sndsTools/reference/get_profil_snds.md),
[`insert_into_table_from_query()`](https://sndstoolers.github.io/sndsTools/reference/insert_into_table_from_query.md),
[`retrieve_all_psa_from_idt()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_all_psa_from_idt.md),
[`retrieve_all_psa_from_psa()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_all_psa_from_psa.md),
[`retrieve_psa()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_psa.md),
[`write_oracle_table_by_batch()`](https://sndstoolers.github.io/sndsTools/reference/write_oracle_table_by_batch.md)
