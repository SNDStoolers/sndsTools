# Extraction des décès et de leurs causes médicales (CIM-10)

Extrait, pour chaque patient décédé entre `start_date` et `end_date`
(bornes incluses), l'ensemble des codes CIM-10 associés à son décès, à
raison d'**une ligne par code**. La colonne `STATUS` indique si le code
est la cause initiale du décès (`"Initial cause"`) ou un autre code de
l'ensemble des causes (`"Other"`).

Deux filtres optionnels et combinables restreignent l'extraction :

- `diagnosis_codes_filter` : ne conserve que les décès dont la cause
  initiale **ou** l'un des autres codes correspond aux codes fournis ;

- `patient_ids_filter` : restreint à une liste d'identifiants patients.
  Tout identifiant fourni sans décès correspondant dans la période est
  tout de même restitué sur une ligne `STATUS == "Alive"`.

## Usage

``` r
extract_deaths(
  conn,
  start_date,
  end_date,
  diagnosis_codes_filter = NULL,
  patient_ids_filter = NULL,
  sup_columns = NULL
)
```

## Arguments

- start_date:

  Date La date de début de la période de décès (incluse).

- end_date:

  Date La date de fin de la période de décès (incluse).

- diagnosis_codes_filter:

  character vector (Optionnel). Codes CIM-10 à rechercher parmi les
  causes de décès. Si `NULL`, tous les décès de la période sont
  extraits. Défaut à `NULL`.

- patient_ids_filter:

  character vector (Optionnel). Identifiants patients (`BEN_IDT_ANO`) à
  extraire ; les doublons sont ignorés. Si `NULL`, aucune restriction
  sur les patients. Défaut à `NULL`.

- sup_columns:

  character vector (Optionnel). Colonnes supplémentaires à inclure dans
  le résultat. Défaut à `NULL`.

## Value

Retourne une lazy table dbplyr (`tbl_lazy`). Une ligne par code CIM-10
et par patient décédé (plus une ligne par patient `"Alive"` si
`patient_ids_filter` est fourni), avec les colonnes :

- `BEN_IDT_ANO` : identifiant patient pseudonymisé.

- `EXE_SOI_DTD` : date du décès (`NA` pour un patient `"Alive"`).

- `CIM_COD` : un code CIM-10 associé au décès (`NA` si `"Alive"`).

- `STATUS` : `"Initial cause"`, `"Other"` ou `"Alive"`.

## Details

La fonction interroge les deux tables des causes médicales de décès :

- `KI_CCI_R` (cause initiale, colonne `DCD_CIM_COD`) fournit les codes
  `"Initial cause"` ;

- `KI_ECD_R` (ensemble des causes, colonne `ECD_CIM_COD`) fournit les
  codes `"Other"`. Un code déjà rapporté comme cause initiale d'un
  patient n'est pas dupliqué en `"Other"`. La correspondance des codes
  (`diagnosis_codes_filter`) se fait par préfixe (`LIKE 'code%'`).

Lorsque `patient_ids_filter` est fourni, `"Alive"` signifie « aucun
décès correspondant dans la période » : selon les filtres, le patient
peut être vivant, décédé hors période, ou décédé d'une cause non retenue
par `diagnosis_codes_filter`.

## See also

Other extract:
[`extract_consultations_erprsf()`](https://sndstoolers.github.io/sndsTools/reference/extract_consultations_erprsf.md),
[`extract_consultations_mcofcstc()`](https://sndstoolers.github.io/sndsTools/reference/extract_consultations_mcofcstc.md),
[`extract_drugs_erphaf()`](https://sndstoolers.github.io/sndsTools/reference/extract_drugs_erphaf.md),
[`extract_drugs_erucdf()`](https://sndstoolers.github.io/sndsTools/reference/extract_drugs_erucdf.md),
[`extract_ij_erprsf()`](https://sndstoolers.github.io/sndsTools/reference/extract_ij_erprsf.md),
[`extract_longtermdiseases_irimbr()`](https://sndstoolers.github.io/sndsTools/reference/extract_longtermdiseases_irimbr.md),
[`extract_stays_mcob()`](https://sndstoolers.github.io/sndsTools/reference/extract_stays_mcob.md),
[`extract_stays_ssr()`](https://sndstoolers.github.io/sndsTools/reference/extract_stays_ssr.md),
[`snds_codes()`](https://sndstoolers.github.io/sndsTools/reference/snds_codes.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Décès dont une cause commence par G10 ou G20, entre 2010 et 2020.
extract_deaths(
  conn,
  start_date = as.Date("2010-01-01"),
  end_date = as.Date("2020-12-31"),
  diagnosis_codes_filter = c("G10", "G20")
)

# Statut vital et causes de décès d'une liste d'identifiants.
extract_deaths(
  conn,
  start_date = as.Date("2010-01-01"),
  end_date = as.Date("2020-12-31"),
  patient_ids_filter = c("ABC123", "DEF456")
)

# Sur le SNDS (Oracle) : cohorte issue d'IR_BEN_R, écrite dans Oracle.
pat_list <- dplyr::tbl(conn, "IR_BEN_R") |>
  head(10) |>
  dplyr::pull(BEN_IDT_ANO)
extract_deaths(
  conn,
  start_date = as.Date("2010-01-01"),
  end_date = as.Date("2020-12-31"),
  patient_ids_filter = pat_list
)
} # }
```
