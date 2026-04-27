# Insérer un fichier CSV dans une table DuckDB

Lit un fichier CSV et l'insère dans une table DuckDB. Le nom de la table
est dérivé du nom du fichier CSV.

## Usage

``` r
insert_synthetic_snds_table(conn, path2csv, delim = ",", col_types = NULL)
```

## Arguments

- conn:

  DuckDB connection. Connexion à la base DuckDB.

- path2csv:

  Character. Chemin vers le fichier CSV à insérer.

## Value

Invisible. Retourne la connexion DuckDB après insertion.
