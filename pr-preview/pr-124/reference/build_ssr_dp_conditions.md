# Construit les conditions pour extraire les diagnostics SSR. (affection étiologique, manifestation morbide principale et, avant 2023, finalité principale de prise en charge).

Cette fonction génère une chaîne de conditions SQL (clauses `LIKE`)
portant sur les colonnes `ETL_AFF` (affection étiologique) et `MOR_PRP`
(manifestation morbide principale) de la table `T_SSR*B`. Pour les
années antérieures à 2023, la colonne `FP_PEC` (finalité principale de
prise en charge) est également incluse.

## Usage

``` r
build_ssr_dp_conditions(cim10_codes = NULL, index_year = NULL)
```

## Arguments

- cim10_codes:

  character vector Les codes CIM10 cibles des diagnostics à extraire.

- index_year:

  integer L'année d'indexation des séjours ssr.

## Value

character Les conditions pour extraire les diagnostics

## Examples

``` r
if (FALSE) { # \dontrun{
build_ssr_dp_conditions(c("A00", "B00"), index_year = 2023)
} # }
```
