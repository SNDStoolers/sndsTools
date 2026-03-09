# Requêtage d'une table Oracle (SNDS ou ORAUSER).

Requêtage d'une table Oracle (SNDS ou ORAUSER).

## Usage

``` r
snds_table(conn, table_name, profile = 108, schema = NULL)
```

## Arguments

- conn:

  Connexion à la base de données.

- table_name:

  Nom de la table Oracle à explorer.

- profile:

  Nom de profil. Par défaut, profile = 108.

- schema:

  Si table hors du schéma standard, renseigner ici le schéma à explorer.
  NULL par défaut.

## Value

tbl_dbi. Exploration paresseuse (lazy query) d'une table Oracle
(ORAUSER, ou SNDS).

## Details

La fonction détecte automatiquement les tables de l'ESND et de la
cartographie. Normalement, pas besoin d'utiliser l'argument schéma pour
ces tables.

## See also

Other utils: [`connect_duckdb()`](connect_duckdb.md),
[`connect_oracle()`](connect_oracle.md),
[`create_table_from_query()`](create_table_from_query.md),
[`gather_table_stats()`](gather_table_stats.md),
[`get_first_non_archived_year()`](get_first_non_archived_year.md),
[`insert_into_table_from_query()`](insert_into_table_from_query.md),
[`retrieve_all_psa_from_idt()`](retrieve_all_psa_from_idt.md),
[`retrieve_all_psa_from_psa()`](retrieve_all_psa_from_psa.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Connexion au SNDS
conn <- connect_oracle()

# Exploration paresseuse de la table ER_PRS_F
conn |>
 snds_table("ER_PRS_F") |>
 # Filtre sur la date de flux
 dplyr::filter(FLX_DIS_DTD == TO_DATE("2024-02-01", "yyyy-MM-dd"))

# Déconnexion du SNDS
DBI::dbDisconnect(conn)
} # }
```
