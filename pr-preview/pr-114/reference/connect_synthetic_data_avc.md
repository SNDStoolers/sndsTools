# Configurer une base de données DuckDB avec toutes les tables factices

Configurer une base de données DuckDB avec toutes les tables factices

## Usage

``` r
connect_synthetic_data_avc(
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

## See also

Other synthetic:
[`connect_synthetic_snds()`](https://sndstoolers.github.io/sndsTools/reference/connect_synthetic_snds.md),
[`create_mock_er_ete_f()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_er_ete_f.md),
[`create_mock_er_pha_f()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_er_pha_f.md),
[`create_mock_er_prs_f()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_er_prs_f.md),
[`create_mock_ir_ben_r()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_ir_ben_r.md),
[`create_mock_ir_imb_r()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_ir_imb_r.md),
[`create_mock_ir_pha_r()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_ir_pha_r.md),
[`create_mock_mco_tables()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_mco_tables.md),
[`create_mock_patients_ids()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_patients_ids.md),
[`download_synthetic_snds_csv()`](https://sndstoolers.github.io/sndsTools/reference/download_synthetic_snds_csv.md),
[`get_kwikly_format()`](https://sndstoolers.github.io/sndsTools/reference/get_kwikly_format.md),
[`insert_synthetic_snds_table()`](https://sndstoolers.github.io/sndsTools/reference/insert_synthetic_snds_table.md)
