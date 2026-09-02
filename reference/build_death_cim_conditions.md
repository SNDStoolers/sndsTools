# Construit la condition SQL de recherche de codes CIM-10 sur une colonne.

Construit une clause SQL `OR` recherchant les codes diagnostics fournis
sur la colonne indiquée. La recherche est effectuée par préfixe : un
code partiel (ex. `"G20"`) capture donc l'ensemble de ses sous-codes
(ex. `"G200"`, `"G201"`).

## Usage

``` r
build_death_cim_conditions(col_name, diagnosis_codes)
```

## Arguments

- col_name:

  character Le nom de la colonne sur laquelle rechercher les codes (ex.
  `"ECD_CIM_COD"` ou `"DCD_CIM_COD"`).

- diagnosis_codes:

  character vector Les codes CIM-10 à rechercher.

## Value

character La condition SQL combinée par `OR`.

## Examples

``` r
if (FALSE) { # \dontrun{
build_death_cim_conditions("DCD_CIM_COD", c("G10", "G20"))
} # }
```
