# Récupération des statistiques des tables

Récupération des statistiques des tables

## Usage

``` r
gather_table_stats(conn, table)
```

## Arguments

- conn:

  Connexion à la base de données

- table:

  Chaine de caractère indiquant le nom d'une table

## References

https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_STATS.html#GUID-CA6A56B9-0540-45E9-B1D7-D78769B7714C
\#nolint

## See also

Other utils: [`connect_duckdb()`](connect_duckdb.md),
[`connect_oracle()`](connect_oracle.md),
[`constants_snds_tools()`](constants_snds_tools.md),
[`create_table_from_query()`](create_table_from_query.md),
[`get_first_non_archived_year()`](get_first_non_archived_year.md),
[`insert_into_table_from_query()`](insert_into_table_from_query.md),
[`retrieve_all_psa_from_idt()`](retrieve_all_psa_from_idt.md),
[`retrieve_all_psa_from_psa()`](retrieve_all_psa_from_psa.md)
