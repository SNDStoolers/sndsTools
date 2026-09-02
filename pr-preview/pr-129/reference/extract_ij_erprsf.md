# Extraction des indemnités journalières sans retraitement (brutes)

Cette fonction permet d'extraire les indemnités journalières (IJ) brutes
depuis la table ER_PRS_F pour une période donnée. Elle utilise les codes
de prestations spécifiques aux indemnités journalières et sauvegarde les
résultats dans une table Oracle.

## Usage

``` r
extract_ij_erprsf(
  conn,
  start_date,
  end_date,
  exe_dtd_lag_months = 6,
  patients_ids_filter = NULL,
  sup_columns = NULL
)
```

## Arguments

- conn:

  DBI connection. Une connexion à la base de données Oracle.

- start_date:

  Date. La date de début de la période des IJ à extraire.

- end_date:

  Date. La date de fin de la période des IJ à extraire.

- exe_dtd_lag_months:

  Integer (Optionnel). Le nombre maximum de mois de décalage de
  `FLX_TRT_DTD` (date d'entrée de l'IJ dans le SI) par rapport à
  `EXE_SOI_DTD` (date de versement de l'IJ) pris en compte pour
  récupérer les consultations. Défaut à 6 mois.

- patients_ids_filter:

  data frame (Optionnel). Un data frame contenant les paires
  d'identifiants des patients pour lesquels les consultations doivent
  être extraites. Les colonnes de ce data frame doivent être
  `BEN_IDT_ANO`, `BEN_NIR_PSA` et `BEN_RNG_GEM`. Les BEN_NIR_PSA doivent
  être tous les BEN_NIR_PSA associés aux BEN_IDT_ANO fournis. Défaut à
  `NULL`.

- sup_columns:

  Vecteur de noms de colonnes (Optionnel). Ajoute ces colonnes à la
  table créée. Défaut à `NULL`.

## Value

Si `output_table_name` est `NULL`, retourne une lazy table contenant les
consultations. Si `output_table_name` est fourni, sauvegarde les
résultats dans la table spécifiée dans Oracle et retourne le nom de la
table. Dans les deux cas les colonnes de la table de sortie sont :

- Toutes les colonnes standard de
  [`extract_consultations_erprsf()`](https://sndstoolers.github.io/sndsTools/reference/extract_consultations_erprsf.md)

- `RGO_ASU_NAT` : Nature d'assurance

- `EXE_SOI_DTF` : Date de fin de soins

- `BSE_REM_MNT` : Montant versé/remboursé (acte de base)

- `PRS_ACT_NBR` : Nombre réel de jours indemnisés

- `IJR_EMP_NUM` : Numéro de l'employeur (Siret)

## Details

La fonction extrait les IJ en utilisant une liste prédéfinie de codes de
prestations provenant d'un échange avec l'assurance maladie. Ces codes
incluent les IJ normales, réduites, partielles, majorées, maternité,
adoption, et autres types d'indemnités (cf. section exemple ci-dessous
pour la liste de codes utilisées). Des filtres supplémentaires obtenues
auprès de Colinot et al. (2024) sont ajoutés pour ne conserver que les
régimes du champ d'étude, à savoir le régime général sans les
indépendants, praticiens et auxiliaires médicaux conventionnés. Ces
filtres concernent le code petit régime `RGM_COD`, le code de
l'organisme d'affiliation du bénéficiaire `ORG_AFF_BEN` et le top
facture travailleurs indépendants `PRS_FAC_TOP`. Un filtre temporel est
également appliqué pour ne conserver que les flux de traitement dans les
6 mois suivant la date de début de l'IJ, afin d'avoir un champ constant
pour les dates de flux (notamment pour les ATMP qui peuvent être traités
longtemps après la date de début de l'IJ).

Les données extraites sont sauvegardées dans une table Oracle
temporaire.

## See also

[`extract_consultations_erprsf()`](https://sndstoolers.github.io/sndsTools/reference/extract_consultations_erprsf.md)
pour la fonction sous-jacente d'extraction

Other extract:
[`extract_consultations_erprsf()`](https://sndstoolers.github.io/sndsTools/reference/extract_consultations_erprsf.md),
[`extract_consultations_mcofcstc()`](https://sndstoolers.github.io/sndsTools/reference/extract_consultations_mcofcstc.md),
[`extract_deaths()`](https://sndstoolers.github.io/sndsTools/reference/extract_deaths.md),
[`extract_drugs_erphaf()`](https://sndstoolers.github.io/sndsTools/reference/extract_drugs_erphaf.md),
[`extract_drugs_erucdf()`](https://sndstoolers.github.io/sndsTools/reference/extract_drugs_erucdf.md),
[`extract_longtermdiseases_irimbr()`](https://sndstoolers.github.io/sndsTools/reference/extract_longtermdiseases_irimbr.md),
[`extract_stays_mcob()`](https://sndstoolers.github.io/sndsTools/reference/extract_stays_mcob.md),
[`extract_stays_ssr()`](https://sndstoolers.github.io/sndsTools/reference/extract_stays_ssr.md),
[`snds_codes()`](https://sndstoolers.github.io/sndsTools/reference/snds_codes.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Extraction des IJ pour l'année 2020
conn <- connect_oracle()
extract_ij_erprsf(
  conn = conn,
  start_date = as.Date("2020-01-01"),
  end_date = as.Date("2020-12-31")
)
} # }
# Codes prestations utilisés
print(snds_codes()$ij_prs_nat_ref)
#>  [1] "6110" "6111" "6112" "6113" "6114" "6115" "6116" "6117" "6118" "6119"
#> [11] "6120" "6131" "6132" "6133" "6121" "6122" "6123" "6124"
# Codes régimes principaux utilisés
print(snds_codes()$main_regime_codes)
#>   RGM_COD RGM_GRG_COD
#> 1       1           1
#> 2     100           1
#> 3     101           1
#> 4     102           1
#> 5     200           1
#> 6     201           1
#> 7     210           1
```
