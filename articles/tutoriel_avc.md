# Exemple d'étude possible avec sndsTools

Cette page présente un exemple type d’utilisation des fonctions de
`sndsTools` pour étudier les données du SNDS.

Le cas d’étude porte sur les patients hospitalisés pour un accident
vasculaire cérébral (AVC) en 2024.

## Contexte de l’étude

Dans le cadre de cette étude “exemple”, nous souhaitons analyser les
parcours de soins des patients hospitalisés pour un AVC au cours de
l’année 2024. Nous utiliserons les fonctions disponibles dans
`sndsTools` pour extraire et analyser les données pertinentes.

Cette étude est un exemple pédagogique de l’utilisation du package
`sndsTools`. Elle ne constitue en aucun cas une étude réelle valide
scientifiquement concernant les patients hospitalisés pour un AVC.

Les étapes de cette étude “exemple” sont :

1.  Identifier les patients avec une hospitalisation pour AVC en 2024
    (codes CIM-10 : I61, I62, I63, I64) via la fonction
    [`extract_stays_mcob()`](https://sndstoolers.github.io/sndsTools/reference/extract_stays_mcob.md)

2.  Récupérer leurs identifiants complets via
    [`retrieve_all_psa_from_psa()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_all_psa_from_psa.md)

3.  Extraire leurs consultations médicales en ville via
    [`extract_consultations_erprsf()`](https://sndstoolers.github.io/sndsTools/reference/extract_consultations_erprsf.md)

4.  Extraire leurs Affections de Longue Durée (ALD) via
    [`extract_longtermdiseases_irimbr()`](https://sndstoolers.github.io/sndsTools/reference/extract_longtermdiseases_irimbr.md)

5.  Extraire leurs prescriptions médicamenteuses en ville via
    [`extract_drugs_erphaf()`](https://sndstoolers.github.io/sndsTools/reference/extract_drugs_erphaf.md)

6.  Fermer la connexion à la base de données

### Prérequis

Si vous souhaitez reproduire cette étude sur le portail CNAM,
assurez-vous d’avoir :

- Une connexion à la base de données Oracle du SNDS sur le portail de la
  CNAM

- Le code du package `sndsTools` [copié sur le
  portail](https://sndstoolers.github.io/sndsTools/articles/sndsTools.html#sur-le-portail-cnam)

Cette vignette peut être exécutée hors du portail CNAM. Dans ce cas, des
données fictives sont générées pour illustrer les étapes de l’étude.

``` r

# Charger les packages nécessaires
if (dir.exists("~/sasdata1")) {
  # sur le portail CNAM
  source("../sndsTools_all.R")
  # Établir la connexion à la base de données
  conn <- connect_oracle()
} else {
  # hors portail CNAM (ex. pour construire cette vignette)
  library(sndsTools)
  # Charge des données fictives
  conn <- connect_synthetic_data_avc(
    n_patients = 100,
    year = 2024,
    start_date = as.Date("2024-01-01"),
    end_date = as.Date("2024-12-31")
  )
}
#> INFO [2026-09-04 10:29:35] Charge le package sndsTools.
#> Variables d'environment TZ et ORA_SDTZ fixées à 'Europe/Paris.'
#> INFO [2026-09-04 10:29:35] Connection to an existing database at: /home/runner/.cache/sndsTools/synthetic_snds_parquet
# packages utiles pour l'analyse
library(dplyr)
library(lubridate)
library(knitr)
```

### Étape 1 : Extraction des hospitalisations pour AVC

Nous commençons par extraire les séjours hospitaliers avec un diagnostic
principal d’AVC en utilisant la fonction
[`extract_stays_mcob()`](https://sndstoolers.github.io/sndsTools/reference/extract_stays_mcob.md).

Les [codes CIM-10 pour les
AVC](https://fr.wikipedia.org/wiki/CIM-10_Chapitre_09_:_Maladies_de_l%27appareil_circulatoire)
sont I61 (hémorragie intracérébrale), I62 (autres hémorragies
intracrâniennes non traumatiques), I63 (infarctus cérébral) et I64
(accident vasculaire cérébral non précisé).

``` r

# Définir la période d'étude - année 2024
start_date <- as.Date("2024-01-01")
end_date <- as.Date("2024-12-31")

# Codes CIM-10 pour les AVC
codes_avc <- c("I61", "I62", "I63", "I64")

# Extraire les séjours avec diagnostics d'AVC
extract_stays_mcob(
  conn,
  start_date = start_date,
  end_date = end_date,
  dp_cim10_codes_filter = codes_avc,
  or_dr_with_same_codes_filter = TRUE, # Inclure les diagnostics reliés
  or_da_with_same_codes_filter = FALSE, # Exclure diagnostics associés similaires
  and_da_with_other_codes_filter = FALSE, # Exclure diagnostics associés différents
  da_cim10_codes_filter = NULL, # Pas de filtre sur diagnostics associés
  patients_ids_filter = NULL # Extraire tous les patients
)
#> # A query:  ?? x 25
#> # Database: DuckDB 1.5.5 [unknown@Linux 6.17.0-1022-azure:R 4.6.1/:memory:]
#>    ETA_NUM RSA_NUM SEJ_NUM SEJ_NBJ NBR_DGN NBR_RUM NBR_ACT ENT_MOD ENT_PRV
#>      <int>   <int>   <int>   <int>   <int>   <int>   <int> <chr>   <chr>  
#>  1  490232      20      20      18       1       1       2 6       2      
#>  2  143041      16      16      15       3       2      10 6       5      
#>  3  664182      21      21      20       2       2       3 6       5      
#>  4  153240       7       7      14       2       2      18 7       5      
#>  5  664182      21      21      20       2       2       3 6       5      
#>  6  153240       7       7      14       2       2      18 7       5      
#>  7  807015      12      12       8       2       1       0 6       1      
#>  8  143041      16      16      15       3       2      10 6       5      
#>  9  883006      23      23      17       2       2      11 6       2      
#> 10  490232      20      20      18       1       1       2 6       2      
#> # ℹ more rows
#> # ℹ 16 more variables: SOR_MOD <chr>, SOR_DES <chr>, DGN_PAL <chr>,
#> #   DGN_REL <chr>, GRG_GHM <chr>, BDI_DEP <chr>, BDI_COD <chr>, COD_SEX <chr>,
#> #   AGE_ANN <dbl>, AGE_JOU <int>, NIR_ANO_17 <dbl>, EXE_SOI_DTD <date>,
#> #   EXE_SOI_DTF <date>, DGN_PAL_UM <chr>, DGN_REL_UM <chr>, ASS_DGN <chr>

# Récupérer un aperçu des données
sejours_avc_head <- extract_stays_mcob(
  conn,
  start_date = start_date,
  end_date = end_date,
  dp_cim10_codes_filter = codes_avc,
  or_dr_with_same_codes_filter = TRUE,
  or_da_with_same_codes_filter = FALSE,
  and_da_with_other_codes_filter = FALSE,
  da_cim10_codes_filter = NULL,
  patients_ids_filter = NULL
) |> head(5) |> dplyr::collect()

kable(sejours_avc_head)
```

| ETA_NUM | RSA_NUM | SEJ_NUM | SEJ_NBJ | NBR_DGN | NBR_RUM | NBR_ACT | ENT_MOD | ENT_PRV | SOR_MOD | SOR_DES | DGN_PAL | DGN_REL | GRG_GHM | BDI_DEP | BDI_COD | COD_SEX | AGE_ANN | AGE_JOU | NIR_ANO_17 | EXE_SOI_DTD | EXE_SOI_DTF | DGN_PAL_UM | DGN_REL_UM | ASS_DGN |
|---:|---:|---:|---:|---:|---:|---:|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|---:|---:|---:|:---|:---|:---|:---|:---|
| 883006 | 23 | 23 | 17 | 2 | 2 | 11 | 6 | 2 | 6 | 7 | I62 | NA | 05M30 | 08 | 49331 | 2 | 78 | 37 | 10035 | 2024-06-04 | 2024-06-21 | NA | NA | E78 |
| 807015 | 12 | 12 | 8 | 2 | 1 | 0 | 6 | 1 | 6 | 3 | I62 | NA | 06C82 | 42 | 30384 | 2 | 33 | 102 | 10089 | 2024-03-27 | 2024-04-04 | I11 | I70 | NA |
| 190076 | 3 | 3 | 10 | 3 | 2 | 6 | 7 | 6 | 6 | 5 | I62 | NA | 05K76 | 94 | 81924 | 2 | 45 | 36 | 10050 | 2024-06-22 | 2024-07-02 | I25 | NA | NA |
| 883006 | 23 | 23 | 17 | 2 | 2 | 11 | 6 | 2 | 6 | 7 | I62 | NA | 05M30 | 08 | 49331 | 2 | 78 | 37 | 10035 | 2024-06-04 | 2024-06-21 | I10 | I10 | NA |
| 190076 | 3 | 3 | 10 | 3 | 2 | 6 | 7 | 6 | 6 | 5 | I62 | NA | 05K76 | 94 | 81924 | 2 | 45 | 36 | 10050 | 2024-06-22 | 2024-07-02 | I50 | I63 | NA |

``` r


# Analyser la répartition par type d'AVC
stays_result <- extract_stays_mcob(
  conn,
  start_date = start_date,
  end_date = end_date,
  dp_cim10_codes_filter = codes_avc,
  or_dr_with_same_codes_filter = TRUE,
  or_da_with_same_codes_filter = FALSE,
  and_da_with_other_codes_filter = FALSE,
  da_cim10_codes_filter = NULL,
  patients_ids_filter = NULL
)
avc_par_type <- stays_result |>
  dplyr::count(DGN_PAL, sort = TRUE) |>
  dplyr::mutate(pourcentage = round(n / sum(n) * 100, 1)) |>
  dplyr::collect()
kable(avc_par_type)
```

| DGN_PAL |   n | pourcentage |
|:--------|----:|------------:|
| I61     |   2 |         9.5 |
| I62     |  12 |        57.1 |
| I10     |   3 |        14.3 |
| I63     |   4 |        19.0 |

### Étape 2 : Identification des patients uniques

À partir des séjours, nous identifions les patients uniques en
[récupérant leurs identifiants uniques
`BEN_NIR_ANO`](https://documentation-snds.health-data-hub.fr/snds/fiches/fiche_beneficiaire.html)
dans le référentiel des bénéficiaires en utilisant
[`retrieve_all_psa_from_psa()`](https://sndstoolers.github.io/sndsTools/reference/retrieve_all_psa_from_psa.md).

``` r

# Créer une table temporaire des pseudo-NIR des patients avec AVC
patients_psa_avc <- stays_result |>
  dplyr::select(BEN_NIR_PSA = NIR_ANO_17) |>
  dplyr::distinct() |>
  dplyr::collect()

# Sauvegarder temporairement dans Oracle
DBI::dbWriteTable(conn, "TMP_PATIENTS_AVC_PSA", patients_psa_avc, overwrite = TRUE)

# Récupérer tous les identifiants patients associés
patients_identifiants_avc <- retrieve_all_psa_from_psa(
  ben_table_name = "TMP_PATIENTS_AVC_PSA",
  conn = conn,
  output_table_name = NULL, # Retourner data.frame
  check_arc_table = FALSE # Pas de recherche dans la table d'identifiant archivée,
) |> collect()

# Filtrer les patients avec des critères de qualité
patients_avc_qualite <- patients_identifiants_avc
#  |>
#   filter(
#     !psa_w_multiple_idt_or_nir, # Éviter les PSA multiples
#     cdi_nir_00, # NIR non fictifs
#     nir_ano_defined, # NIR anonyme défini
#     !birth_date_variation, # Pas de variation date naissance
#     !sex_variation # Pas de variation sexe
#   )
# Préparer les identifiants pour les extractions ultérieures
patients_ids_filter <- patients_avc_qualite |>
  select(BEN_IDT_ANO, BEN_NIR_PSA, BEN_RNG_GEM) |>
  distinct()

paste("Nombre de patients uniques avec AVC :", nrow(patients_avc_qualite))
#> [1] "Nombre de patients uniques avec AVC : 9"
```

### Étape 3 : Extraction des consultations médicales

Nous extrayons toutes les consultations médicales en ville de ces
patients en utilisant
[`extract_consultations_erprsf()`](https://sndstoolers.github.io/sndsTools/reference/extract_consultations_erprsf.md).

``` r

# Extraire toutes les consultations des patients avec AVC
consultations_result <- extract_consultations_erprsf(
  conn,
  start_date = start_date,
  end_date = end_date,
  pse_spe_filter = c(32, 10, 47, 3), # Spécialités neuro ou cardio
  prestation_filter = NULL, # Toutes les prestations
  analyse_couts = FALSE, # Filtrer les majorations
  dis_dtd_lag_months = 6, # Décalage standard 6 mois
  patients_ids_filter = patients_ids_filter
)
#> Extracting consultations with speciality codes 32 or 10 or 47 or 3

# Récupérer un aperçu des consultations
consultations_avc_head <- consultations_result |>
  head(5) |>
  dplyr::collect()

# Analyser la répartition par spécialité médicale
consultations_par_specialite <- consultations_result |>
  dplyr::count(PSE_SPE_COD, sort = TRUE) |>
  dplyr::mutate(pourcentage = round(n / sum(n) * 100, 1)) |>
  dplyr::collect()
kable(head(consultations_par_specialite, 5))
```

| PSE_SPE_COD |   n | pourcentage |
|:------------|----:|------------:|
| 03          |   4 |         100 |

``` r


# Analyser le nombre de consultations par patient
consultations_par_patient <- consultations_result |>
  dplyr::group_by(BEN_IDT_ANO) |>
  dplyr::summarise(
    nb_consultations = n(),
    premiere_consultation = min(EXE_SOI_DTD, na.rm = TRUE),
    derniere_consultation = max(EXE_SOI_DTD, na.rm = TRUE),
    .groups = "drop"
  ) |>
  dplyr::collect()
```

### Étape 4 : Extraction des Affections de Longue Durée (ALD)

Nous extrayons les ALD des patients avec AVC en utilisant
[`extract_longtermdiseases_irimbr()`](https://sndstoolers.github.io/sndsTools/reference/extract_longtermdiseases_irimbr.md).

``` r

# Extraire les ALD des patients avec AVC
patients_ids_for_ald <- patients_ids_filter |>
  select(BEN_IDT_ANO, BEN_NIR_PSA, BEN_RNG_GEM) |>
  distinct()

ald_result <- extract_longtermdiseases_irimbr(
  conn,
  start_date = start_date,
  end_date = end_date,
  icd_cod_starts_with = NULL, # Extraire toutes les ALD
  ald_numbers = NULL, # Pas de filtre sur numéros ALD
  excl_etm_nat = c("11", "12", "13"), # Exclure accidents travail/maladies pro
  patients_ids_filter = patients_ids_for_ald
)
#> Extracting LTD status for all ICD 10 codes...

# Récupérer un aperçu des ALD
ald_avc_head <- ald_result |>
  head(5) |>
  dplyr::collect()


kable(ald_avc_head)
```

| BEN_IDT_ANO | BEN_NIR_PSA | BEN_RNG_GEM | IMB_ALD_NUM | IMB_ALD_DTD | IMB_ALD_DTF | IMB_ETM_NAT | MED_MTF_COD |
|---:|---:|---:|---:|:---|:---|:---|:---|
| 51 | 10050 | 1 | 8 | 2023-08-23 | 2024-01-26 | 02 | I70 |
| 42 | 10041 | 1 | 1 | 2023-06-08 | 2026-01-23 | 01 | I20 |
| 87 | 10086 | 1 | 12 | 2023-03-05 | 2025-12-14 | 02 | I25 |
| 95 | 10094 | 1 | 8 | 2023-05-01 | 2026-02-08 | 03 | I13 |
| 43 | 10042 | 1 | 8 | 2023-11-02 | 2026-03-27 | 01 | I60 |

``` r


# Analyser la répartition par type d'ALD
ald_resume <- ald_result |>
  dplyr::count(MED_MTF_COD, sort = TRUE) |>
  dplyr::mutate(pourcentage = round(n / sum(n) * 100, 1)) |>
  arrange(-pourcentage) |>
  dplyr::collect()
kable(head(ald_resume, 5))
```

| MED_MTF_COD |   n | pourcentage |
|:------------|----:|------------:|
| I70         |   2 |        25.0 |
| I60         |   1 |        12.5 |
| I21         |   1 |        12.5 |
| I25         |   1 |        12.5 |
| I50         |   1 |        12.5 |

``` r


# Analyser le pourcentage de patients AVC avec une ALD
patients_avec_ald <- ald_result |>
  dplyr::select(BEN_IDT_ANO) |>
  dplyr::distinct() |>
  dplyr::collect() |>
  nrow()
pourcentage_ald <- round(patients_avec_ald / nrow(patients_avc_qualite) * 100, 1)
print(paste("Pourcentage de patients AVC avec une ALD :", pourcentage_ald, "%"))
#> [1] "Pourcentage de patients AVC avec une ALD : 66.7 %"
```

### Étape 5 : Extraction des prescriptions médicamenteuses

Nous extrayons les délivrances de médicaments des patients avec AVC en
utilisant
[`extract_drugs_erphaf()`](https://sndstoolers.github.io/sndsTools/reference/extract_drugs_erphaf.md).

C’est la requête la plus longue sur le portail. Pour les 122 887
patients hospitalisés pour AVC en 2024, elle tourne en 5 min environ.
Cette lenteur est dûe à la jointure nécessaire entre les deux tables
volumineuses `ER_PHA_F` et `ER_PRS_F`.

``` r

# Extraire les délivrances de médicaments des patients avec AVC
patients_ids_for_drugs <- patients_ids_filter |>
  select(BEN_IDT_ANO, BEN_NIR_PSA, BEN_RNG_GEM) |>
  distinct()

# Codes ATC pour les médicaments courants post-AVC
# N : système nerveux
# C : système cardiovasculaire
atc_codes_avc <- c("N", "C")

# Extraire les délivrances de médicaments des patients avec AVC
drugs_result <- extract_drugs_erphaf(
  conn,
  start_date = start_date,
  end_date = end_date,
  atc_cod_starts_with_filter = atc_codes_avc, # Médicaments SNC et CV
  cip13_cod_filter = NULL, # Pas de filtre spécifique CIP13
  patients_ids_filter = patients_ids_for_drugs,
  dis_dtd_lag_months = 6, # Décalage standard 6 mois
  sup_columns = NULL # Pas de colonnes supplémentaires
)
#> Extracting drug dispenses with ATC codes starting with N or C
#> Extracting drug dispenses for all CIP13 codes
#> INFO [2026-09-04 10:29:42] Filtre codes médicaments :
#> (PHA_ATC_CLA LIKE 'N%' OR PHA_ATC_CLA LIKE 'C%')

# Récupérer un aperçu des délivrances
drugs_avc_head <- drugs_result |>
  head(5) |>
  dplyr::collect()
kable(drugs_avc_head)
```

| BEN_IDT_ANO | EXE_SOI_DTD | FLX_DIS_DTD | PHA_ACT_QSN | PHA_ATC_CLA | PHA_PRS_C13 | PSP_SPE_COD | BEN_RNG_GEM |
|---:|:---|:---|---:|:---|:---|:---|---:|
| 51 | 2024-06-23 | 2024-07-17 | 1 | C03AA03 | 3400932725847 | 22 | 1 |
| 51 | 2024-02-03 | 2024-06-24 | 1 | C09AA02 | 3400955555555 | 34 | 1 |
| 72 | 2024-03-28 | 2024-11-26 | 1 | C09AA02 | 3400955555555 | 03 | 1 |
| 72 | 2024-12-22 | 2024-09-04 | 1 | C07AB07 | 3400977777777 | 34 | 1 |
| 36 | 2024-10-05 | 2024-05-04 | 1 | C08CA01 | 3400936267343 | 03 | 1 |

``` r


# Analyser la répartition par code ATC
drugs_par_atc <- drugs_result |>
  dplyr::count(PHA_ATC_CLA, sort = TRUE) |>
  dplyr::mutate(pourcentage = round(n / sum(n) * 100, 1)) |>
  arrange(-pourcentage) |>
  dplyr::collect()
kable(head(drugs_par_atc, 5))
```

| PHA_ATC_CLA |   n | pourcentage |
|:------------|----:|------------:|
| C09AA02     |   9 |        25.0 |
| C02AC01     |   6 |        16.7 |
| C08CA01     |   6 |        16.7 |
| C03AA03     |   6 |        16.7 |
| C07AB07     |   4 |        11.1 |

### Étape 6 : Nettoyage et fermeture de la session

``` r

# Supprimer les tables temporaires (si elles existent encore)
tables_to_remove <- c(
  "TMP_PATIENTS_AVC_PSA", "TMP_SEJOURS_AVC",
  "TMP_DRUG_DISPENSES_AVC"
)
for (table_name in tables_to_remove) {
  if (DBI::dbExistsTable(conn, table_name)) {
    DBI::dbRemoveTable(conn, table_name)
  }
}

# Fermer la connexion
DBI::dbDisconnect(conn)
```

### Conclusion

Ce tutoriel a présenté quelques fonctions concernant des étapes
d’extraction usuelles à partir du SNDS en utilisant le package
`sndsTools`.

La liste complète des fonctions existantes est disponible dans la
[documentation du
package](https://sndstoolers.github.io/sndsTools/reference/index.html#extraction-snds).
