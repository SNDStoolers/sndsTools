# Création d'une table à partir d'une requête SQL.

Création d'une table à partir d'une requête SQL.

## Usage

``` r
create_table_from_query(
  conn = NULL,
  output_table_name = NULL,
  query = NULL,
  overwrite = FALSE
)
```

## Arguments

- conn:

  Connexion à la base de données

- output_table_name:

  Nom de la table de sortie

- query:

  Requête SQL

- overwrite:

  Logical. Indique si la table `output_table_name` doit être écrasée
  dans le cas où elle existe déjà.

## Details

La fonction crée une table sous Oracle à partir d'une requête SQL. Si la
table `output_table_name` existe déjà, elle est écrasée si le paramètre
`overwrite` est TRUE.
