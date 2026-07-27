# Extraction des diagnostics des séjours de soins de réadaptation (SSR)

Cette fonction permet d'extraire les diagnostics des séjours de soins de
réadaptation. Les diagnostics dont les dates `EXE_SOI_DTD` sont
comprises entre `start_date` et `end_date` sont extraits. Les séjours
extraits sont à l'échelle de la semaine de séjour, avec une ligne par
semaine de séjour. Les séjours sont extraits à partir des tables
T_SSR*B, T_SSR*C et T_SSR\*D.

## Usage

``` r
extract_stays_ssr(
  conn,
  start_date,
  end_date,
  dp_cim10_codes_filter = NULL,
  or_da_with_same_codes_filter = FALSE,
  and_da_with_other_codes_filter = FALSE,
  da_cim10_codes_filter = NULL,
  patients_ids_filter = NULL,
  sup_columns = NULL
)
```

## Arguments

- conn:

  DBI connection. Une connexion à la base de données Oracle.

- start_date:

  Date La date de début de la période sur laquelle extraire les séjours.

- end_date:

  Date La date de fin de la période sur laquelle extraire les séjours.

- dp_cim10_codes_filter:

  character vector (Optionnel). Les codes CIM10 des diagnostics
  principaux à extraire. La requête est effectuée par préfixe : Par
  exemple, si E12 est renseigné, tous les codes commençant par E12 sont
  extraits. Défaut à `NULL`.

- and_da_with_other_codes_filter:

  logical (Optionnel). Indique si les séjours avec des codes ETL_AFF,
  MOR_PRP et FP_PEC différents doivent être extraits. La requête est
  effectuée par préfixe : Par exemple, si E12 est renseigné, tous les
  codes commençant par E12 sont extraits. Défaut à `NULL`.

- da_cim10_codes_filter:

  character vector (Optionnel). Les codes CIM10 des diagnostics ETL_AFF,
  MOR_PRP et FP_PEC à extraire. La requête est effectuée par préfixe :
  Par exemple, si E12 est renseigné, tous les codes commençant par E12
  sont extraits. Défaut à `NULL`.

- patients_ids_filter:

  data.frame (Optionnel). Un data.frame contenant les paires
  d'identifiants des patients pour lesquels les consultations doivent
  être extraites. Les colonnes de ce data.frame doivent être
  `BEN_IDT_ANO` et `BEN_NIR_PSA` (en majuscules). Les "BEN_NIR_PSA"
  doivent être tous les "BEN_NIR_PSA" associés aux "BEN_IDT_ANO"
  fournis. Si `patients_ids` n'est pas fourni, les consultations de tous
  les patients sont extraites. Défaut à `NULL`.

- sup_columns:

  character vector (Optionnel). Colonnes supplémentaires à inclure dans
  le résultat. Défaut à `NULL`.

- or_da_with_same_codes:

  logical (Optionnel). Indique si les séjours avec les mêmes codes
  ETL_AFF, MOR_PRP et FP_PEC doivent être extraits. La requête est
  effectuée par préfixe : Par exemple, si E12 est renseigné, tous les
  codes commençant par E12 sont extraits. Défaut à `NULL`.

## Value

Retourne une lazy table contenant les séjours de soins de réadaptation.
les séjours de soins de réadaptation. Si `output_table_name` est fourni,
sauvegarde les résultats dans la table spécifiée dans Oracle et retourne
`NULL` de manière invisible. Les colonnes sont les suivantes :
uniquement si `patients_ids_filter` est renseigné ; remplace
`NIR_ANO_17`).

- `NIR_ANO_17` : NIR anonymisé à 17 caractères (absent si
  `patients_ids_filter` est renseigné).

- `ETA_NUM` : Numéro FINESS e-PMSI de l'établissement SSR.

- `RHA_NUM` : Numéro séquentiel du RHA (résumé hebdomadaire anonyme
  SSR).

- `SEJ_NUM` : Numéro de séjour SSR.

- `NBR_DGN` : Nombre de diagnostics associés significatifs SSR.

- `ENT_MOD` : Mode d'entrée dans le séjour SSR.

- `ENT_PRV` : Provenance du patient à l'entrée du séjour SSR.

- `SOR_MOD` : Mode de sortie du séjour SSR.

- `SOR_DES` : Destination de sortie du séjour SSR.

- `MOR_PRP` : Manifestation morbide principale SSR.

- `ETL_AFF` : Affection étiologique SSR.

- `DGN_COD` : Diagnostic associé significatif SSR (table `T_SSR*D`).

- `BDI_DEP` : Département de résidence du bénéficiaire.

- `BDI_COD` : Code géographique de résidence du bénéficiaire.

- `COD_SEX` : Sexe du bénéficiaire.

- `AGE_ANN` : Âge en années du bénéficiaire.

- `MOI_ANN` : Mois et année de sortie SSR (format MMAAAA).

- `EXE_SOI_DTD` : Date de début de la semaine SSR.

- `EXE_SOI_DTF` : Date de fin de la semaine SSR.

- `GRG_GME` : Groupe médico-économique SSR (présent à partir de 2013).

- `FP_PEC` : Finalité principale de prise en charge SSR (présent avant
  2023 uniquement).

## Details

La sélection des séjours se fait à l'aide de filtres sur les
diagnostics:

- Si `dp_cim10_codes_filter` est renseigné, seuls les séjours dont les
  diagnostics principaux contiennent les codes CIM10 correspondants sont
  extraits.

- Si `or_dr_with_same_codes_filter` est renseigné, les séjours avec les
  codes DR correspondants sont également extraits.

- Si `and_da_with_other_codes` est renseigné, les séjours avec les codes
  DA correspondants sont également extraits.

- Si `and_da_with_other_codes_filter` est renseigné, les séjours avec
  les codes DA différents sont également extraits.

Tous les diagnostics principaux, reliés et associés sont extraits pour
les séjours sélectionnés.

La fonction joint les tables T_SSR*B, T_SSR*C ensemble, puis joint
successivement à cette table "séjour" les tables T_SSR\*D. Finalement,
les deux tables obtenues sont concaténées horizontalement. Il est donc
fréquent d'avoir des doublons concernant les colonnes des tables B et D
dans les lignes de la table résultante.

## See also

Other extract:
[`extract_consultations_erprsf()`](https://sndstoolers.github.io/sndsTools/reference/extract_consultations_erprsf.md),
[`extract_consultations_mcofcstc()`](https://sndstoolers.github.io/sndsTools/reference/extract_consultations_mcofcstc.md),
[`extract_deaths()`](https://sndstoolers.github.io/sndsTools/reference/extract_deaths.md),
[`extract_drugs_erphaf()`](https://sndstoolers.github.io/sndsTools/reference/extract_drugs_erphaf.md),
[`extract_drugs_erucdf()`](https://sndstoolers.github.io/sndsTools/reference/extract_drugs_erucdf.md),
[`extract_longtermdiseases_irimbr()`](https://sndstoolers.github.io/sndsTools/reference/extract_longtermdiseases_irimbr.md),
[`extract_stays_mcob()`](https://sndstoolers.github.io/sndsTools/reference/extract_stays_mcob.md)

## Examples

``` r
if (FALSE) { # \dontrun{
conn <- connect_oracle()
# Extrait uniquement les séjours en 2019 dont le diagnostic principal commence par A ou B
extract_stays_ssr(
 conn = conn,
 start_date = as.Date("2019-01-01"),
 end_date = as.Date("2019-12-31"),
 dp_cim10_codes_filter = c("A", "B")
)
# Extrait tous les séjours en 2019
extract_stays_ssr(
 conn = conn,
 start_date = as.Date("2019-01-01"),
 end_date = as.Date("2019-12-31")
)
} # }
```
