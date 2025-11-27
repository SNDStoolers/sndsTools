# Extraction des consultations externes à l'hôpital (MCO).

Cette fonction permet d'extraire les consultations à l'hôpital en MCO.
Les consultations dont les dates `EXE_SOI_DTD` sont comprises entre
start_date et end_date sont extraites.

## Usage

``` r
extract_hospital_consultations(
  start_date,
  end_date,
  spe_codes_filter = NULL,
  prestation_codes_filter = NULL,
  patient_ids_filter = NULL,
  output_table_name = NULL,
  conn = NULL
)
```

## Arguments

- start_date:

  Date La date de début de la période sur laquelle extraire les
  consultations.

- end_date:

  Date La date de fin de la période sur laquelle extraire les
  consultations.

- spe_codes_filter:

  character vector Optionnel. Les codes spécialités des médecins
  effectuant les consultations à extraire. Si `spe_codes` n'est pas
  fourni, les consultations de tous les spécialités sont extraites.

- prestation_codes_filter:

  character vector Optionnel. Les codes des prestations à extraire. Si
  `prestation_codes` n'est pas fourni, les consultations de tous les
  prestations sont extraites. Les codes des prestations sont disponibles
  sur la page [actes et consultations externes de la documentation
  SNDS](https://documentation-snds.health-data-hub.fr/snds/fiches/actes_consult_externes.html#exemple-de-requetes-pour-analyse).

- patient_ids_filter:

  data.frame Optionnel. Un data.frame contenant les paires
  d'identifiants des patients pour lesquels les consultations doivent
  être extraites. Les colonnes de ce data.frame doivent être
  `BEN_IDT_ANO` et `BEN_NIR_PSA` (en majuscules). Les `BEN_NIR_PSA`
  doivent être tous les `BEN_NIR_PSA` associés aux `BEN_IDT_ANO`
  fournis. Si `patients_ids` n'est pas fourni, les consultations de tous
  les patients sont extraites.

- output_table_name:

  character Optionnel. Le nom de la table de sortie dans la base de
  données. Si `output_table_name` n'est pas fourni, une table de sortie
  intermédiaire est créée en R. Si `output_table_name` est fourni mais
  que cette table existe déjà dans oracle, le programme s'arrête avec un
  message d'erreur.

- conn:

  dbConnection La connexion à la base de données. Si `conn` n'est pas
  fourni, une connexion à la base de données est initialisée. Par
  défaut, une connexion est établie avec oracle.

## Value

Un data.frame contenant les consultations. Les colonnes sont les
suivantes :

- `BEN_IDT_ANO` : Identifiant bénéficiaire anonymisé (seulement si

- patient_ids non nul)

- `NIR_ANO_17` : NIR anonymisé

- `EXE_SOI_DTD` : Date de la délivrance

- `ACT_COD` : Code de l'acte

- `EXE_SPE` : Code de spécialité du professionnel de soin prescripteur

## Details

Si spe_codes est renseigné, seules les consultations des spécialités
correspondantes sont extraites.

Si prestation_codes est renseigné, seules les consultations des
prestations correspondantes sont extraites.

Si patients_ids est fourni, seules les délivrances de médicaments pour
les patients dont les identifiants sont dans patients_ids sont
extraites.

## Examples

``` r
if (FALSE) { # \dontrun{
extract_hospital_consultations(
  start_date = as.Date("2019-01-01"),
  end_date = as.Date("2019-12-31"),
  spe_codes = c("01", "02")
)
} # }
```
