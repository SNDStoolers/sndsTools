# Exemple d'étude possible avec sndsTools

Cette page présente un exemple type d’utilisation des fonctions de
`sndsTools` pour étudier les données du SNDS.

Le cas d’étude porte sur les patients hospitalisés pour un accident
vasculaire cérébral (AVC) en 2024.

## Contexte de l’étude

Dans le cadre de cette étude, nous souhaitons analyser les parcours de
soins des patients hospitalisés pour un AVC au cours de l’année 2024.
Nous utiliserons les fonctions disponibles dans `sndsTools` pour
extraire et analyser les données pertinentes.

Cette étude est un exemple pédagogique de l’utilisation du package
`sndsTools`. Elle ne constitue en aucun cas une étude réelle valide
scientifiquement concernant les patients hospitalisés pour un AVC.

Les objectifs de cette étude sont :

1.  Identifier les patients avec une hospitalisation pour AVC en 2024
    (codes CIM-10 : I61, I62, I63, I64) via la fonction
    [`extract_hospital_stays()`](../reference/extract_hospital_stays.md)

2.  Récupérer leurs identifiants complets via
    [`retrieve_all_psa_from_psa()`](../reference/retrieve_all_psa_from_psa.md)

3.  Extraire leurs consultations médicales en ville via
    [`extract_consultations_erprsf()`](../reference/extract_consultations_erprsf.md)

4.  Extraire leurs Affections de Longue Durée (ALD) via
    [`extract_long_term_disease()`](../reference/extract_long_term_disease.md)

5.  Extraire leurs prescriptions médicamenteuses en ville via
    [`extract_drug_dispenses()`](../reference/extract_drug_dispenses.md)

6.  Nettoyer et fermer la connexion à la base de données

### Prérequis

Avant de commencer, assurez-vous d’avoir :

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
    conn <- create_mock_database(
      n_patients = 100,
      year = 2024,
      start_date = as.Date("2024-01-01"),
      end_date = as.Date("2024-12-31")
    )
}
#> [1] "Le code ne s'exécute pas sur le portail CNAM.\n    Initialisation d'une connexion duckdb en mémoire."
#> Base de données factice créée avec 100 patients
#> Période : 2024-01-01 à 2024-12-31
#> Tables fictives MCO, ER_PRS_F, ER_PHA_F et ER_ETE_F pour l'année 2024
# packages utiles pour l'analyse
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
library(lubridate)
#> 
#> Attaching package: 'lubridate'
#> The following objects are masked from 'package:base':
#> 
#>     date, intersect, setdiff, union
library(knitr)
```

### Étape 1 : Extraction des hospitalisations pour AVC

Nous commençons par extraire les séjours hospitaliers avec un diagnostic
principal d’AVC en utilisant la fonction
[`extract_hospital_stays()`](../reference/extract_hospital_stays.md).

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
extract_hospital_stays(
  start_date = start_date,
  end_date = end_date,
  dp_cim10_codes_filter = codes_avc,
  or_dr_with_same_codes_filter = TRUE,  # Inclure les diagnostics reliés
  or_da_with_same_codes_filter = FALSE,  # Exclure diagnostics associés similaires
  and_da_with_other_codes_filter = FALSE,  # Exclure diagnostics associés différents
  da_cim10_codes_filter = NULL,  # Pas de filtre sur diagnostics associés
  patients_ids_filter = NULL,  # Extraire tous les patients
  output_table_name = "TMP_SEJOURS_AVC",  # Stocker en table Oracle
  conn = conn
)
#> Results saved to table TMP_SEJOURS_AVC in Oracle.
#> NULL

# Récupérer un aperçu des données
sejours_avc_head <- dplyr::tbl(conn, "TMP_SEJOURS_AVC") |>
  head(5) |>
  dplyr::collect()

kable(sejours_avc_head)
```

| ETA_NUM | RSA_NUM | SEJ_NUM | SEJ_NBJ | NBR_DGN | NBR_RUM | NBR_ACT | ENT_MOD | ENT_PRV | SOR_MOD | SOR_DES | DGN_PAL | DGN_REL | GRG_GHM | BDI_DEP | BDI_COD | COD_SEX | AGE_ANN | AGE_JOU | NIR_ANO_17 | EXE_SOI_DTD | EXE_SOI_DTF | DGN_PAL_UM | DGN_REL_UM | ASS_DGN |
|--------:|--------:|--------:|--------:|--------:|--------:|--------:|:--------|:--------|:--------|:--------|:--------|:--------|:--------|:--------|:--------|:--------|--------:|--------:|-----------:|:------------|:------------|:-----------|:-----------|:--------|
|  190076 |       3 |       3 |      10 |       3 |       2 |       6 | 7       | 6       | 6       | 5       | I62     | NA      | 05K76   | 94      | 81924   | 2       |      45 |      36 |      10050 | 2024-06-22  | 2024-07-02  | I50        | I63        | NA      |
|  190076 |       3 |       3 |      10 |       3 |       2 |       6 | 7       | 6       | 6       | 5       | I62     | NA      | 05K76   | 94      | 81924   | 2       |      45 |      36 |      10050 | 2024-06-22  | 2024-07-02  | I25        | NA         | NA      |
|  883006 |      23 |      23 |      17 |       2 |       2 |      11 | 6       | 2       | 6       | 7       | I62     | NA      | 05M30   | 08      | 49331   | 2       |      78 |      37 |      10035 | 2024-06-04  | 2024-06-21  | I10        | I10        | NA      |
|  883006 |      23 |      23 |      17 |       2 |       2 |      11 | 6       | 2       | 6       | 7       | I62     | NA      | 05M30   | 08      | 49331   | 2       |      78 |      37 |      10035 | 2024-06-04  | 2024-06-21  | I20        | I64        | NA      |
|  490232 |      20 |      20 |      18 |       1 |       1 |       2 | 6       | 2       | 6       | 2       | I62     | I12     | 05M42   | 84      | 33760   | 1       |      73 |     310 |      10094 | 2024-08-31  | 2024-09-18  | I10        | NA         | NA      |

``` r

# Analyser la répartition par type d'AVC
avc_par_type <- dplyr::tbl(conn, "TMP_SEJOURS_AVC") |>
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
[`retrieve_all_psa_from_psa()`](../reference/retrieve_all_psa_from_psa.md).

``` r
# Créer une table temporaire des pseudo-NIR des patients avec AVC
patients_psa_avc <- dplyr::tbl(conn, "TMP_SEJOURS_AVC") |>
  dplyr::select(BEN_NIR_PSA = NIR_ANO_17) |>
  dplyr::distinct() |>
  dplyr::collect()

# Sauvegarder temporairement dans Oracle
DBI::dbWriteTable(conn, "TMP_PATIENTS_AVC_PSA", patients_psa_avc, overwrite = TRUE)

# Récupérer tous les identifiants patients associés
patients_identifiants_avc <- retrieve_all_psa_from_psa(
  ben_table_name = "TMP_PATIENTS_AVC_PSA",
  conn = conn,
  output_table_name = NULL,  # Retourner data.frame
  check_arc_table = FALSE # Pas de recherche dans la table d'identifiant archivée,
)

# Filtrer les patients avec des critères de qualité
patients_avc_qualite <- patients_identifiants_avc |>
  filter(
    !psa_w_multiple_idt_or_nir,  # Éviter les PSA multiples
    cdi_nir_00,                   # NIR non fictifs
    nir_ano_defined,              # NIR anonyme défini
    !birth_date_variation,        # Pas de variation date naissance
    !sex_variation               # Pas de variation sexe
  )
# Préparer les identifiants pour les extractions ultérieures
patients_ids_filter <- patients_avc_qualite |>
  select(BEN_IDT_ANO, BEN_NIR_PSA, BEN_RNG_GEM) |>
  distinct()

paste("Nombre de patients uniques avec AVC :", nrow(patients_avc_qualite))
#> [1] "Nombre de patients uniques avec AVC : 7"
```

### Étape 3 : Extraction des consultations médicales

Nous extrayons toutes les consultations médicales en ville de ces
patients en utilisant
[`extract_consultations_erprsf()`](../reference/extract_consultations_erprsf.md).

``` r
# Extraire toutes les consultations des patients avec AVC
extract_consultations_erprsf(
  start_date = start_date,
  end_date = end_date,
  pse_spe_filter = c(32, 10, 47, 3),  # Spécalités neuro ou cardio
  prestation_filter = NULL,  # Toutes les prestations
  analyse_couts = FALSE,  # Filtrer les majorations
  dis_dtd_lag_months = 6,  # Décalage standard 6 mois
  patients_ids_filter = patients_ids_filter,
  output_table_name = "TMP_CONSULTATIONS_AVC",  # Stocker en table Oracle
  conn = conn
)
#> Extracting consultations
#> from all specialties among
#> 32 or 10 or 47 or 3...
#> Results saved to table TMP_CONSULTATIONS_AVC in Oracle.
#> NULL

# Récupérer un aperçu des consultations
consultations_avc_head <- dplyr::tbl(conn, "TMP_CONSULTATIONS_AVC") |>
  head(5) |>
  dplyr::collect()

# Analyser la répartition par spécialité médicale
consultations_par_specialite <- dplyr::tbl(conn, "TMP_CONSULTATIONS_AVC") |>
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
consultations_par_patient <- dplyr::tbl(conn, "TMP_CONSULTATIONS_AVC") |>
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
[`extract_long_term_disease()`](../reference/extract_long_term_disease.md).

``` r

# Extraire les ALD des patients avec AVC
patients_ids_for_ald <- patients_ids_filter |>
  select(BEN_IDT_ANO, BEN_NIR_PSA) |>
  distinct()

extract_long_term_disease(
  start_date = start_date,
  end_date = end_date,
  icd_cod_starts_with = NULL,  # Extraire toutes les ALD
  ald_numbers = NULL,  # Pas de filtre sur numéros ALD
  excl_etm_nat = c("11", "12", "13"),  # Exclure accidents travail/maladies pro
  patients_ids = patients_ids_for_ald,
  output_table_name = "TMP_ALD_AVC",  # Stocker en table Oracle
  overwrite = FALSE,  # Ne pas écraser table existante
  conn = conn
)
#> Extracting LTD status for all ICD 10 codes...
#> Results saved to table TMP_ALD_AVC in Oracle.
#> NULL

# Récupérer un aperçu des ALD
ald_avc_head <- dplyr::tbl(conn, "TMP_ALD_AVC") |>
  head(5) |>
  dplyr::collect()

kable(ald_avc_head)
```

| BEN_IDT_ANO | IMB_ALD_NUM | IMB_ALD_DTD | IMB_ALD_DTF | IMB_ETM_NAT | MED_MTF_COD |
|------------:|------------:|:------------|:------------|:------------|:------------|
|          43 |           5 | 2023-07-28  | 2024-04-25  | 01          | I50         |
|          42 |           1 | 2023-06-08  | 2026-01-23  | 01          | I20         |
|          87 |          12 | 2023-03-05  | 2025-12-14  | 02          | I25         |
|          95 |           8 | 2023-05-01  | 2026-02-08  | 03          | I13         |
|          43 |           8 | 2023-11-02  | 2026-03-27  | 01          | I60         |

``` r

# Analyser la répartition par type d'ALD
ald_resume <- dplyr::tbl(conn, "TMP_ALD_AVC") |>
  dplyr::count(MED_MTF_COD, sort = TRUE) |>
  dplyr::mutate(pourcentage = round(n / sum(n) * 100, 1)) |>
  arrange(-pourcentage) |>
  dplyr::collect()
kable(head(ald_resume, 5))
```

| MED_MTF_COD |   n | pourcentage |
|:------------|----:|------------:|
| I60         |   1 |        14.3 |
| I25         |   1 |        14.3 |
| I70         |   1 |        14.3 |
| I21         |   1 |        14.3 |
| I50         |   1 |        14.3 |

``` r

# Analyser le pourcentage de patients AVC avec une ALD
patients_avec_ald <- dplyr::tbl(conn, "TMP_ALD_AVC") |>
  dplyr::select(BEN_IDT_ANO) |>
  dplyr::distinct() |>
  dplyr::collect() |>
  nrow()

pourcentage_ald <- round(patients_avec_ald / nrow(patients_avc_qualite) * 100, 1)
print(paste("Pourcentage de patients AVC avec une ALD :", pourcentage_ald, "%"))
#> [1] "Pourcentage de patients AVC avec une ALD : 71.4 %"
```

### Étape 5 : Extraction des prescriptions médicamenteuses

Nous extrayons les délivrances de médicaments des patients avec AVC en
utilisant
[`extract_drug_dispenses()`](../reference/extract_drug_dispenses.md).

C’est la requête la plus longue sur le portail. Pour les 122 887
patients hospitalisés pour AVC en 2024, elle tourne en 5 min environ.
Cette lenteur est dûe à la jointure nécessaire entre les deux tables
volumineuses `ER_PHA_F` et `ER_PRS_F`.

``` r

# Extraire les délivrances de médicaments des patients avec AVC
patients_ids_for_drugs <- patients_ids_filter |>
  select(BEN_IDT_ANO, BEN_NIR_PSA) |>
  distinct()

# Codes ATC pour les médicaments courants post-AVC
# N : système nerveux
# C : système cardiovasculaire
atc_codes_avc <- c("N", "C")

extract_drug_dispenses(
  start_date = start_date,
  end_date = end_date,
  atc_cod_starts_with_filter = atc_codes_avc,  # Médicaments SNC et CV
  cip13_cod_filter = NULL,  # Pas de filtre spécifique CIP13
  patients_ids_filter = patients_ids_for_drugs,
  dis_dtd_lag_months = 6,  # Décalage standard 6 mois
  sup_columns = NULL,  # Pas de colonnes supplémentaires
  output_table_name = "TMP_DRUG_DISPENSES_AVC",  # Stocker en table Oracle
  show_sql_query = FALSE,  # Ne pas afficher requête SQL
  conn = conn
)
#> Extracting drug dispenses with ATC codes starting with N or C
#> Extracting drug dispenses for all CIP13 codes
#> -flux: DATE '2024-01-01' to DATE '2024-02-01'
#> -flux: DATE '2024-02-01' to DATE '2024-03-01'
#> -flux: DATE '2024-03-01' to DATE '2024-04-01'
#> -flux: DATE '2024-04-01' to DATE '2024-05-01'
#> -flux: DATE '2024-05-01' to DATE '2024-06-01'
#> -flux: DATE '2024-06-01' to DATE '2024-07-01'
#> -flux: DATE '2024-07-01' to DATE '2024-08-01'
#> -flux: DATE '2024-08-01' to DATE '2024-09-01'
#> -flux: DATE '2024-09-01' to DATE '2024-10-01'
#> -flux: DATE '2024-10-01' to DATE '2024-11-01'
#> -flux: DATE '2024-11-01' to DATE '2024-12-01'
#> -flux: DATE '2024-12-01' to DATE '2025-01-01'
#> -flux: DATE '2025-01-01' to DATE '2025-02-01'
#> -flux: DATE '2025-02-01' to DATE '2025-03-01'
#> -flux: DATE '2025-03-01' to DATE '2025-04-01'
#> -flux: DATE '2025-04-01' to DATE '2025-05-01'
#> -flux: DATE '2025-05-01' to DATE '2025-06-01'
#> -flux: DATE '2025-06-01' to DATE '2025-07-01'
#> Results saved to table TMP_DRUG_DISPENSES_AVC in Oracle.
#> NULL

# Récupérer un aperçu des délivrances
drugs_avc_head <- dplyr::tbl(conn, "TMP_DRUG_DISPENSES_AVC") |>
  head(5) |>
  dplyr::collect()
kable(drugs_avc_head)
```

| BEN_IDT_ANO | EXE_SOI_DTD | PHA_ACT_QSN | PHA_ATC_CLA | PHA_PRS_C13   | PSP_SPE_COD |
|------------:|:------------|------------:|:------------|:--------------|:------------|
|          95 | 2024-02-17  |           1 | C08CA01     | 3400936267343 | 22          |
|          72 | 2024-03-12  |           1 | C02AC01     | 3400932026555 | 34          |
|          36 | 2024-04-17  |           1 | C08CA01     | 3400936267343 | 02          |
|          87 | 2024-07-16  |           1 | C08CA01     | 3400936267343 | 01          |
|          36 | 2024-06-01  |           1 | C02AC01     | 3400932026555 | 22          |

``` r

# Analyser la répartition par code ATC
drugs_par_atc <- dplyr::tbl(conn, "TMP_DRUG_DISPENSES_AVC") |>
  dplyr::count(PHA_ATC_CLA, sort = TRUE) |>
  dplyr::mutate(pourcentage = round(n / sum(n) * 100, 1)) |>
  arrange(-pourcentage) |>
  dplyr::collect()
kable(head(drugs_par_atc, 5))
```

| PHA_ATC_CLA |   n | pourcentage |
|:------------|----:|------------:|
| C09AA02     |   8 |        26.7 |
| C08CA01     |   5 |        16.7 |
| C02AC01     |   4 |        13.3 |
| C03AA03     |   4 |        13.3 |
| C07AB07     |   4 |        13.3 |

### Étape 6 : Nettoyage et fermeture de la session

``` r
# Supprimer les tables temporaires
tables_to_remove <- c("TMP_PATIENTS_AVC_PSA", "TMP_SEJOURS_AVC",
                      "TMP_CONSULTATIONS_AVC", "TMP_ALD_AVC", "TMP_DRUG_DISPENSES_AVC")
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
