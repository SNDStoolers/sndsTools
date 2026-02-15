# Récupération de l'année non archivée la plus ancienne de la table ER_PRS_F.

Récupération de l'année non archivée la plus ancienne de la table
ER_PRS_F.

## Usage

``` r
get_first_non_archived_year(conn)
```

## Arguments

- conn:

  Connexion à la base de données

## Value

Année non archivée la plus ancienne

## See also

Other utils: [`connect_duckdb()`](connect_duckdb.md),
[`connect_oracle()`](connect_oracle.md),
[`constants_snds_tools()`](constants_snds_tools.md),
[`create_table_from_query()`](create_table_from_query.md),
[`gather_table_stats()`](gather_table_stats.md),
[`insert_into_table_from_query()`](insert_into_table_from_query.md),
[`retrieve_all_psa_from_idt()`](retrieve_all_psa_from_idt.md),
[`retrieve_all_psa_from_psa()`](retrieve_all_psa_from_psa.md)
