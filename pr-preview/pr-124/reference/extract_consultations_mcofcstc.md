# Extraction des consultations externes à l'hôpital (MCO).

Cette fonction permet d'extraire les consultations à l'hôpital en MCO.
Les consultations dont les dates `EXE_SOI_DTD` sont comprises entre
start_date et end_date sont extraites.

## Usage

``` r
extract_consultations_mcofcstc(
  conn,
  start_date,
  end_date,
  spe_codes_filter = NULL,
  prestation_codes_filter = NULL,
  ccam_codes_filter = NULL,
  patients_ids_filter = NULL
)
```

## Arguments

- conn:

  DBI connection. Une connexion à la base de données Oracle.

- start_date:

  Date La date de début de la période sur laquelle extraire les
  consultations.

- end_date:

  Date La date de fin de la période sur laquelle extraire les
  consultations.

- spe_codes_filter:

  character vector Optionnel. Les codes spécialités des médecins
  effectuant les consultations à extraire. Si `spe_codes_filter` n'est
  pas fourni, les consultations de tous les spécialités sont extraites.

- prestation_codes_filter:

  character vector Optionnel. Les codes des prestations à extraire. Si
  `prestation_codes_filter` n'est pas fourni, les consultations de tous
  les prestations sont extraites. Les codes des prestations sont
  disponibles sur la page [actes et consultations externes de la
  documentation
  SNDS](https://documentation-snds.health-data-hub.fr/snds/fiches/actes_consult_externes.html#exemple-de-requetes-pour-analyse).

- ccam_codes_filter:

  character vector Optionnel. Les codes CCAM des actes médicaux des
  consultations à extraire. Si `ccam_codes_filter` n'est pas fourni, les
  consultations de tous les actes sont extraites. Les codes des actes
  médicaux d'après la CCAM est disponible sur [le site de cette
  dernière](https://www.ameli.fr/accueil-de-la-ccam/index.php).

- patients_ids_filter:

  data.frame Optionnel. Un data.frame contenant les paires
  d'identifiants des patients pour lesquels les consultations doivent
  être extraites. Les colonnes de ce data.frame doivent être
  `BEN_IDT_ANO` et `BEN_NIR_PSA` (en majuscules). Les `BEN_NIR_PSA`
  doivent être tous les `BEN_NIR_PSA` associés aux `BEN_IDT_ANO`
  fournis. Si `patients_ids_filter` n'est pas fourni, les consultations
  de tous les patients sont extraites.

## Value

Retourne une lazy table contenant les consultations. Les colonnes sont
les suivantes :

- `BEN_IDT_ANO` : Identifiant bénéficiaire anonymisé (seulement si
  patients_ids_filter non nul)

- `NIR_ANO_17` : NIR anonymisé

- `EXE_SOI_DTD` : Date de la délivrance

- `ACT_COD` : Code prestation de l'acte

- `EXE_SPE` : Code de spécialité du professionnel de soin prescripteur

- `CCAM_COD` : Code de l'acte médical classifié avec la CCAM.

## Details

Si spe_codes_filter est renseigné, seules les consultations des
spécialités correspondantes sont extraites.

Si prestation_codes_filter est renseigné, seules les consultations des
prestations correspondantes sont extraites.

Si ccam_codes_filter est renseigné, seules les consultations des actes
médicaux correspondants sont extraites. Notez que si `ccam_codes_filter`
est fourni, `spe_codes_filter` et `prestation_codes_filter` peuvent être
nuls, et vice versa.

Si patients_ids_filter est fourni, seules les délivrances de médicaments
pour les patients dont les identifiants sont dans patients_ids_filter
sont extraites.

## See also

Other extract:
[`extract_consultations_erprsf()`](https://sndstoolers.github.io/sndsTools/reference/extract_consultations_erprsf.md),
[`extract_deaths()`](https://sndstoolers.github.io/sndsTools/reference/extract_deaths.md),
[`extract_drugs_erphaf()`](https://sndstoolers.github.io/sndsTools/reference/extract_drugs_erphaf.md),
[`extract_drugs_erucdf()`](https://sndstoolers.github.io/sndsTools/reference/extract_drugs_erucdf.md),
[`extract_longtermdiseases_irimbr()`](https://sndstoolers.github.io/sndsTools/reference/extract_longtermdiseases_irimbr.md),
[`extract_stays_mcob()`](https://sndstoolers.github.io/sndsTools/reference/extract_stays_mcob.md),
[`extract_stays_ssr()`](https://sndstoolers.github.io/sndsTools/reference/extract_stays_ssr.md)

## Examples

``` r
if (FALSE) { # \dontrun{
conn <- connect_oracle()
# Extraction des consultations à l'hôpital en 2019 pour les spécialités 01 et 02
extract_consultations_mcofcstc(
  conn = conn,
  start_date = as.Date("2019-01-01"),
  end_date = as.Date("2019-12-31"),
  spe_codes_filter = c("01", "02")
)
# Extraction de consultations à l'hôpital à partir de code CCAM
extract_consultations_mcofcstc(
  conn = conn,
  start_date = as.Date("2019-01-01"),
  end_date = as.Date("2019-12-31"),
  ccam_codes_filter = c("ACQK001", "ACQH003")
)
# Extraction de consultations à l'hôpital à partir de code CCAM et de spécialités
extract_consultations_mcofcstc(
  conn = conn,
  start_date = as.Date("2019-01-01"),
  end_date = as.Date("2019-12-31"),
  ccam_codes_filter = c("ACQK001", "ACQH003"),
  spe_codes_filter = c("01", "02")
)
} # }
```
