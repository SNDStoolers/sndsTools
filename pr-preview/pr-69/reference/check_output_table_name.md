# Vérifie la validité du nom de la table de sortie Oracle.

Cette fonction vérifie que le nom de la table de sortie fourni respecte
les contraintes imposées par Oracle :

- Le nom doit être une chaîne de caractères.

- Le nom doit être entièrement en majuscules, car Oracle stocke et
  compare les noms de tables en majuscules. Un nom en minuscules
  provoquerait une incohérence : le test d'existence de la table ne
  détecterait pas une table déjà existante, puis Oracle échouerait à la
  création en signalant un conflit.

- La table ne doit pas déjà exister dans la base de données (la
  comparaison est effectuée en majuscules pour être robuste).

## Usage

``` r
check_output_table_name(output_table_name, conn)
```

## Arguments

- output_table_name:

  Character. Le nom de la table de sortie à valider.

- conn:

  DBI connection. La connexion à la base de données Oracle.

## Value

Retourne `output_table_name` de manière invisible si toutes les
vérifications sont satisfaites. Sinon, la fonction lève une erreur avec
un message explicatif.

## See also

Other utils:
[`IS_PORTAIL`](https://sndstoolers.github.io/sndsTools/reference/IS_PORTAIL.md),
[`connect_duckdb()`](https://sndstoolers.github.io/sndsTools/reference/connect_duckdb.md),
[`connect_oracle()`](https://sndstoolers.github.io/sndsTools/reference/connect_oracle.md),
[`create_table_from_query()`](https://sndstoolers.github.io/sndsTools/reference/create_table_from_query.md),
[`gather_table_stats()`](https://sndstoolers.github.io/sndsTools/reference/gather_table_stats.md),
[`get_first_non_archived_year()`](https://sndstoolers.github.io/sndsTools/reference/get_first_non_archived_year.md),
[`insert_into_table_from_query()`](https://sndstoolers.github.io/sndsTools/reference/insert_into_table_from_query.md),
[`retrieve_all_psa_from_idt()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_all_psa_from_idt.md),
[`retrieve_all_psa_from_psa()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_all_psa_from_psa.md),
[`retrieve_psa()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_psa.md)

## Examples

``` r
if (FALSE) { # \dontrun{
conn <- connect_duckdb()
check_output_table_name("MA_TABLE", conn)  # OK
check_output_table_name("ma_table", conn)  # Erreur : doit être en majuscules
} # }
```
