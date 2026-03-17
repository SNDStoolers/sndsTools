# Generic function retrieving patient identifiers

Refer to `retrieve_all_psa_from_idt` and `retrieve_all_psa_from_psa` for
details.

## Usage

``` r
retrieve_psa(
  ben_table_name,
  start_key,
  check_arc_table = TRUE,
  output_table_name = NULL,
  conn = NULL
)
```

## Arguments

- ben_table_name:

  Character Obligatoire. Nom de la table d'entrée comprenant au moins la
  variable `BEN_IDT_ANO` ou `BEN_NIR PSA`. Si la variable `BEN_RNG_GEM`
  est incluse, elle sera également utilisée pour les jointures avec les
  référentiels.

- start_key:

  Character Obligatoire. Doit être égal à "BEN_IDT_ANO" ou
  "BEN_NIR_PSA".

- check_arc_table:

  Logical Optionnel. Si TRUE (par défaut), les tables `IR_BEN_R_ARC`
  sont également consultées pour la recherche des `BEN_IDT_ANO` et des
  critères de sélection.

- output_table_name:

  Character Optionnel. Si fourni, les résultats seront sauvegardés dans
  une table portant ce nom dans Oracle. Sinon la table en sortie est
  retournée sous la forme d'un data.frame(/tibble).

- conn:

  DBI connection Optionnel Une connexion à la base de données Oracle. Si
  non fournie, une connexion est établie par défaut.

## See also

Other utils: [`connect_duckdb()`](connect_duckdb.md),
[`connect_oracle()`](connect_oracle.md), `constants_snds_tools()`,
[`create_table_from_query()`](create_table_from_query.md),
[`gather_table_stats()`](gather_table_stats.md),
[`get_first_non_archived_year()`](get_first_non_archived_year.md),
[`insert_into_table_from_query()`](insert_into_table_from_query.md),
[`retrieve_all_psa_from_idt()`](retrieve_all_psa_from_idt.md),
[`retrieve_all_psa_from_psa()`](retrieve_all_psa_from_psa.md)
