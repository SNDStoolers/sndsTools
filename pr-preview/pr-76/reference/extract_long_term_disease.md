# Extraction des Affections Longue Durée (ALD)

Cette fonction permet d'extraire des ALD actives au moins un jour sur
une période donnée. Les ALD dont l'intersection IMB_ALD_DTD, IMB_ALD_DTF
avec la période start_date, end_date n'est pas vide sont extraites. Si
des codes ICD 10 ou des numéros d'ALD sont fournis, seules les ALD
associées à ces codes ICD 10 ou numéros d'ALD sont extraites. Dans le
cas contraire, toutes les ALD sont extraites. Si des identifiants de
patients sont fournis, seules les ALD associées à ces patients sont
extraites. Dans le cas contraire, les ALD de tous les patients sont
extraites.

## Usage

``` r
extract_long_term_disease(
  start_date = NULL,
  end_date = NULL,
  icd_cod_starts_with = NULL,
  ald_numbers = NULL,
  excl_etm_nat = c("11", "12", "13"),
  patients_ids = NULL,
  output_table_name = NULL,
  overwrite = FALSE,
  conn = NULL
)
```

## Arguments

- start_date:

  Date La date de début de la période sur laquelle extraire les ALD
  actives.

- end_date:

  Date La date de fin de la période sur laquelle extraire les ALD
  actives.

- icd_cod_starts_with:

  character vector Un vecteur de codes ICD 10. Si `icd_cod_starts_with`
  ou `ald_numbers` sont fournis, seules les ALD associées à ces codes
  ICD 10 ou numéros d'ALD sont extraites. Sinon, toutes les ALD actives
  sur la période start_date, end_date sont extraites.

- ald_numbers:

  numeric vector Un vecteur de numéros d'ALD. Si `icd_cod_starts_with`
  ou `ald_numbers` sont fournis, seules les ALD associées à ces codes
  ICD 10 ou numéros d'ALD sont extraites. Sinon, toutes les ALD actives
  sur la période start_date, end_date sont extraites.

- excl_etm_nat:

  character vector Un vecteur de codes IMB_ETM_NAT à exclure. Par
  défaut, les ALD de nature 11, 12 et 13 sont exclues car elles
  correspondent à des exonérations pour accidents du travail ou maladies
  professionnelles. Voir [la fiche sur les ALD de la documentation du
  SNDS](https://documentation-snds.health-data-hub.fr/snds/fiches/beneficiaires_ald.html).
  et notamment le Programme \#1 pour la référence de ce filtre.

- patients_ids:

  data.frame Optionnel. Un data.frame contenant les paires
  d'identifiants des patients pour lesquels les délivrances de
  médicaments doivent être extraites. Les colonnes de ce data.frame
  doivent être "BEN_IDT_ANO" et "BEN_NIR_PSA". Les "BEN_NIR_PSA" doivent
  être tous les "BEN_NIR_PSA" associés aux "BEN_IDT_ANO" fournis.

- output_table_name:

  Character Optionnel. Si fourni, les résultats seront sauvegardés dans
  une table portant ce nom dans la base de données au lieu d'être
  retournés sous forme de data frame.

- overwrite:

  Logical. Indique si la table `output_table_name` doit être écrasée
  dans le cas où elle existe déjà.

- conn:

  DBI connection Une connexion à la base de données Oracle. Si non
  fournie, une connexion est établie par défaut.

## Value

Si output_table_name est NULL, retourne un data.frame contenant les les
ALDs actives sur la période. Si output_table_name est fourni, sauvegarde
les résultats dans la table spécifiée dans Oracle et retourne NULL de
manière invisible. Dans les deux cas les colonnes de la table de sortie
sont :

- BEN_NIR_PSA : Colonne présente uniquement si les identifiants patients
  (`patients_ids`) ne sont pas fournis. Identifiant SNDS, ausi appelé
  pseudo-NIR.

- BEN_IDT_ANO : Colonne présente uniquement si les identifiants patients
  (`patients_ids`) sont fournis. Numéro d’inscription au répertoire
  (NIR) anonymisé.

- IMB_ALD_NUM : Le numéro de l'ALD

- IMB_ALD_DTD : La date de début de l'ALD

- IMB_ALD_DTF : La date de fin de l'ALD

- IMB_ETM_NAT : La nature de l'ALD

- MED_MTF_COD : Le code ICD 10 de la pathologie associée à l'ALD

## See also

Other extract:
[`extract_consultations_erprsf()`](extract_consultations_erprsf.md),
[`extract_drug_dispenses()`](extract_drug_dispenses.md),
[`extract_hospital_consultations()`](extract_hospital_consultations.md),
[`extract_hospital_stays()`](extract_hospital_stays.md)

## Examples

``` r
if (FALSE) { # \dontrun{
start_date <- as.Date("2010-01-01")
end_date <- as.Date("2010-01-03")
icd_cod_starts_with <- c("G20")

long_term_disease <- extract_long_term_disease(
  start_date = start_date,
  end_date = end_date,
  icd_cod_starts_with = icd_cod_starts_with
)
} # }
```
