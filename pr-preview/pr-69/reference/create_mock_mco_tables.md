# Créer des données factices pour les séjours hospitaliers MCO (tables B, C, D, UM)

Créer des données factices pour les séjours hospitaliers MCO (tables B,
C, D, UM)

## Usage

``` r
create_mock_mco_tables(
  patients_ids = create_mock_patients_ids(),
  year = 2020,
  start_date = as.Date("2020-01-01"),
  end_date = as.Date("2020-12-31")
)
```

## Arguments

- patients_ids:

  data.frame avec BEN_IDT_ANO et BEN_NIR_PSA

- year:

  Année des séjours

- start_date:

  Date de début

- end_date:

  Date de fin

## Value

list avec les 4 tables MCO (B, C, D, UM)
