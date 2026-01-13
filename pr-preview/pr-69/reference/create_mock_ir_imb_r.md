# Créer des données factices pour les ALD (IR_IMB_R)

Créer des données factices pour les ALD (IR_IMB_R)

## Usage

``` r
create_mock_ir_imb_r(
  patients_ids = create_mock_patients_ids(),
  start_date = as.Date("2020-01-01"),
  end_date = as.Date("2020-12-31")
)
```

## Arguments

- patients_ids:

  data.frame avec BEN_IDT_ANO et BEN_NIR_PSA

- start_date:

  Date de début

- end_date:

  Date de fin

## Value

data.frame avec les données d'ALD
