# Construit les conditions pour extraire les diagnostics principaux et reliés.

Cette fonction permet de construire les conditions pour extraire les
diagnostics principaux et reliés.

## Usage

``` r
build_dp_dr_conditions(cim10_codes = NULL, include_dr = FALSE)
```

## Arguments

- cim10_codes:

  character vector Les codes CIM10 cibles des diagnostics à extraire.

- include_dr:

  logical Indique si les diagnostics reliés doivent être ajoutés dans
  les conditions. Si TRUE, la recherche dans les diagnostics principaux
  des codes CIM10 cibles est ajoutée dans les conditions. Si FALSE, les
  codes CIM10 cibles sont recherchés seulement pour les diagnostics
  principaux.

## Value

character Les conditions pour extraire les diagnostics principaux et
reliés.

## Examples

``` r
if (FALSE) { # \dontrun{
build_dp_dr_conditions(c("A00", "B00"), include_dr = TRUE)
build_dp_dr_conditions(c("A00", "B00"), include_dr = FALSE)
} # }
```
