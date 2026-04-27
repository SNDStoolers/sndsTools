# Créer des données factices pour les délivrances de médicaments (ER_PRS_F)

Créer des données factices pour les délivrances de médicaments
(ER_PRS_F)

## Usage

``` r
create_mock_er_prs_f(
  patients_ids = create_mock_patients_ids(),
  start_date = as.Date("2020-01-01"),
  end_date = as.Date("2020-12-31"),
  n_dispenses = 5
)
```

## Arguments

- patients_ids:

  data.frame avec BEN_IDT_ANO et BEN_NIR_PSA

- start_date:

  Date de début

- end_date:

  Date de fin

- n_dispenses:

  Nombre de délivrances par patient (moyenne)

## Value

data.frame avec les données de délivrances

## See also

Other synthetic:
[`connect_synthetic_data_avc()`](https://sndstoolers.github.io/sndsTools/reference/connect_synthetic_data_avc.md),
[`connect_synthetic_snds()`](https://sndstoolers.github.io/sndsTools/reference/connect_synthetic_snds.md),
[`create_mock_er_ete_f()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_er_ete_f.md),
[`create_mock_er_pha_f()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_er_pha_f.md),
[`create_mock_ir_ben_r()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_ir_ben_r.md),
[`create_mock_ir_imb_r()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_ir_imb_r.md),
[`create_mock_ir_pha_r()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_ir_pha_r.md),
[`create_mock_mco_tables()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_mco_tables.md),
[`create_mock_patients_ids()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_patients_ids.md)
