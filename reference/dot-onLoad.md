# onLoad function

Cette fonction est appelée lors du chargement du package ou d'une de ses
fonctions (via `::`). Elle configure le fuseau horaire par défaut à
"Europe/Paris" pour :

- `TZ`: la session R

- `ORA_SDTZ`: les connexions Oracle, pour s'assurer que les datetimes
  sont traitées dans le bon fuseau horaire. Cette configuration est
  essentielle pour garantir la cohérence entre les objets datetime
  manipulés dans R et ceux stockés ou récupérés depuis la base de
  données Oracle : [cf détails et
  exemples](https://soeiro.gitlab.io/pepidoc/r.html#dates-heures-et-fuseaux-horaires).
  \# nolint

## Usage

``` r
.onLoad(libname, pkgname)
```

## See also

Other utils:
[`check_output_table_name()`](https://sndstoolers.github.io/sndsTools/reference/check_output_table_name.md),
[`connect_oracle()`](https://sndstoolers.github.io/sndsTools/reference/connect_oracle.md),
[`create_table_from_query()`](https://sndstoolers.github.io/sndsTools/reference/create_table_from_query.md),
[`gather_table_stats()`](https://sndstoolers.github.io/sndsTools/reference/gather_table_stats.md),
[`get_first_non_archived_year()`](https://sndstoolers.github.io/sndsTools/reference/get_first_non_archived_year.md),
[`insert_into_table_from_query()`](https://sndstoolers.github.io/sndsTools/reference/insert_into_table_from_query.md),
[`retrieve_all_psa_from_idt()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_all_psa_from_idt.md),
[`retrieve_all_psa_from_psa()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_all_psa_from_psa.md),
[`retrieve_psa()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_psa.md),
[`write_oracle_table_by_batch()`](https://sndstoolers.github.io/sndsTools/reference/write_oracle_table_by_batch.md)
