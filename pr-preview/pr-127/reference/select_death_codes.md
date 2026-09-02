# Projette une table de causes de décès sur le format de sortie commun.

Standardise une table des causes médicales de décès (`KI_CCI_R` ou
`KI_ECD_R`) sur les quatre colonnes de sortie communes (`BEN_IDT_ANO`,
`EXE_SOI_DTD`, `CIM_COD`, `STATUS`), en renommant la colonne de code
CIM-10 propre à la table et en marquant le statut.

## Usage

``` r
select_death_codes(tbl, code_col, status)
```

## Arguments

- tbl:

  tbl_lazy La table source déjà filtrée.

- code_col:

  character Le nom de la colonne de code CIM-10 à projeter sur `CIM_COD`
  (ex. `"DCD_CIM_COD"` ou `"ECD_CIM_COD"`).

- status:

  character La valeur de la colonne `STATUS` (ex. `"Initial cause"` ou
  `"Other"`).

## Value

tbl_lazy Une requête paresseuse dédoublonnée aux colonnes `BEN_IDT_ANO`,
`EXE_SOI_DTD`, `CIM_COD`, `STATUS`.
