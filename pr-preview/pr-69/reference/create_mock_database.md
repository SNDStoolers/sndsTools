# Configurer une base de données DuckDB avec toutes les tables factices

Configurer une base de données DuckDB avec toutes les tables factices

## Usage

``` r
create_mock_database(
  n_patients = 100,
  year = 2020,
  start_date = as.Date("2020-01-01"),
  end_date = as.Date("2020-12-31")
)
```

## Arguments

- n_patients:

  Nombre de patients à générer

- year:

  Année pour les tables MCO

- start_date:

  Date de début

- end_date:

  Date de fin

## Value

Connexion DuckDB avec toutes les tables chargées
