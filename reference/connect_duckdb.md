# Initialisation de la connexion à la base de données duckdb.

Utilisation pour le testing uniquement. Si le code s'exécute en dehors
du portail, il faut initier une connexion duckdb pour effectuer les
tests.

## Usage

``` r
connect_duckdb()
```

## Value

dbConnection Connexion à la base de données duckdb

## See also

Other utils: [`connect_oracle()`](connect_oracle.md),
[`constants_snds_tools()`](constants_snds_tools.md),
[`create_table_from_query()`](create_table_from_query.md),
[`gather_table_stats()`](gather_table_stats.md),
[`get_first_non_archived_year()`](get_first_non_archived_year.md),
[`insert_into_table_from_query()`](insert_into_table_from_query.md),
[`retrieve_all_psa_from_idt()`](retrieve_all_psa_from_idt.md),
[`retrieve_all_psa_from_psa()`](retrieve_all_psa_from_psa.md)
