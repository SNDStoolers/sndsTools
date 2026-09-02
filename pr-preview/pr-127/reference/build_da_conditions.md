# Construit les conditions pour extraire les diagnostics associés.

Cette fonction permet de construire les conditions pour extraire les
diagnostics associés.

## Usage

``` r
build_da_conditions(cim10_codes = NULL)
```

## Arguments

- cim10_codes:

  character vector Les codes CIM10 cibles des diagnostics à extraire.

## Value

character Les conditions pour extraire les diagnostics associés.

## Examples

``` r
if (FALSE) { # \dontrun{
build_da_conditions(c("A00", "B00"))
} # }
```
