# Ecriture d'une table lazy vers oracle par batch

Cette fonction permet d'écrire une table lazy vers Oracle en la
découpant en plusieurs batchs selon un critère de date. Cela permet de
gérer des volumes de données importants et d'éviter les problèmes de
mémoire ou de timeout lors de l'insertion. Elle est particulièrement
utile pour les tables du DCIR indexées sur la colonne `FLX_DIS_DTD`.

## Usage

``` r
write_oracle_table_by_batch(
  conn,
  lazy_df,
  output_table_name,
  start_date,
  end_date,
  dis_dtd_lag_months = 6,
  batch_by = "month",
  batch_colname = NULL
)
```

## Arguments

- conn:

  Connexion à la base de données

- lazy_df:

  Table lazy à écrire

- output_table_name:

  Nom de la table de sortie

- start_date:

  Date de début pour le batch

- end_date:

  Date de fin pour le batch

- dis_dtd_lag_months:

  Nombre de mois de décalage pour la colonne FLX_DIS_DTD si la table à
  écrire provient du DCIR. Par défaut 6 mois.

- batch_by:

  Taille de batch : "month" ou "year"

- batch_colname:

  Nom de la colonne à utiliser pour le batch. Par défaut utilise
  "FLX_DIS_DTD" si la table provient du DCIR.

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
[`tbl_oracle()`](https://sndstoolers.github.io/sndsTools/reference/tbl_oracle.md)
