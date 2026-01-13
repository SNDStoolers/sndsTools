# Exemple d'étude possible avec sndsTools

Cette page présente un example type d’utilisation des fonctions de
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
    [`extract_long_term_disease()`](../reference/extract_long_term_disease.md)

6.  Présenter quelques analyses descriptives sur ces données

### Prérequis

Avant de commencer, assurez-vous d’avoir :

- Une connexion à la base de données Oracle du SNDS sur le portail de la
  CNAM

- Le code du package `sndsTools` [copié sur le
  portail](https://sndstoolers.github.io/sndsTools/articles/sndsTools.html#sur-le-portail-cnam)

Cette vigne peut être executée hors du portail CNAM. Dans ce cas, des
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
sont I61 (hémorragie intracérébrale), I62 (Autres hémorragies
intracrâniennes non traumatique), I63 (infarctus cérébral) et I64
(accident vasculaire cérébral non précisé).

``` r
# Définir la période d'étude - année 2024
start_date <- as.Date("2024-01-01")
end_date <- as.Date("2024-12-31")

# Codes CIM-10 pour les AVC
codes_avc <- c("I61", "I62", "I63", "I64")

# Extraire les séjours avec diagnostics d'AVC
sejours_avc <- extract_hospital_stays(
  start_date = start_date,
  end_date = end_date,
  dp_cim10_codes_filter = codes_avc,
  or_dr_with_same_codes_filter = TRUE,  # Inclure les diagnostics reliés
  conn = conn
)

# Afficher un aperçu des données
print(paste("Nombre de séjours pour AVC extraits :", nrow(sejours_avc)))
#> [1] "Nombre de séjours pour AVC extraits : 21"
kable(head(sejours_avc))
```

| ETA_NUM | RSA_NUM | SEJ_NUM | SEJ_NBJ | NBR_DGN | NBR_RUM | NBR_ACT | ENT_MOD | ENT_PRV | SOR_MOD | SOR_DES | DGN_PAL | DGN_REL | GRG_GHM | BDI_DEP | BDI_COD | COD_SEX | AGE_ANN | AGE_JOU | NIR_ANO_17 | EXE_SOI_DTD | EXE_SOI_DTF | DGN_PAL_UM | DGN_REL_UM | ASS_DGN |
|--------:|--------:|--------:|--------:|--------:|--------:|--------:|:--------|:--------|:--------|:--------|:--------|:--------|:--------|:--------|:--------|:--------|--------:|--------:|-----------:|:------------|:------------|:-----------|:-----------|:--------|
|  153240 |       7 |       7 |      14 |       2 |       2 |      18 | 7       | 5       | 6       | 5       | I10     | I61     | 05C76   | 50      | 02175   | 2       |      61 |     206 |      10041 | 2024-04-29  | 2024-05-13  | I20        | NA         | NA      |
|  153240 |       7 |       7 |      14 |       2 |       2 |      18 | 7       | 5       | 6       | 5       | I10     | I61     | 05C76   | 50      | 02175   | 2       |      61 |     206 |      10041 | 2024-04-29  | 2024-05-13  | I11        | I70        | NA      |
|  807015 |      12 |      12 |       8 |       2 |       1 |       0 | 6       | 1       | 6       | 3       | I62     | NA      | 06C82   | 42      | 30384   | 2       |      33 |     102 |      10089 | 2024-03-27  | 2024-04-04  | I64        | NA         | NA      |
|  807015 |      12 |      12 |       8 |       2 |       1 |       0 | 6       | 1       | 6       | 3       | I62     | NA      | 06C82   | 42      | 30384   | 2       |      33 |     102 |      10089 | 2024-03-27  | 2024-04-04  | I11        | I70        | NA      |
|  143041 |      16 |      16 |      15 |       3 |       2 |      10 | 6       | 5       | 6       | 1       | I63     | I48     | 06M50   | 13      | 16315   | 1       |      78 |     138 |      10071 | 2024-06-13  | 2024-06-28  | I10        | I12        | NA      |
|  190076 |       3 |       3 |      10 |       3 |       2 |       6 | 7       | 6       | 6       | 5       | I62     | NA      | 05K76   | 94      | 81924   | 2       |      45 |      36 |      10050 | 2024-06-22  | 2024-07-02  | I50        | I63        | NA      |

``` r

# Analyser la répartition par type d'AVC
avc_par_type <- sejours_avc |>
  count(DGN_PAL, sort = TRUE) |>
  mutate(pourcentage = round(n / sum(n) * 100, 1))
kable(avc_par_type)
```

| DGN_PAL |   n | pourcentage |
|:--------|----:|------------:|
| I62     |  12 |        57.1 |
| I63     |   4 |        19.0 |
| I10     |   3 |        14.3 |
| I61     |   2 |         9.5 |

### Étape 2 : Identification des patients uniques

À partir des séjours, nous identifions les patients uniques en
[récupérant leurs identifiants uniques
`BEN_NIR_ANO`](https://documentation-snds.health-data-hub.fr/snds/fiches/fiche_beneficiaire.html)
dans le référentiel des bénéficiaires en utilisant
[`retrieve_all_psa_from_psa()`](../reference/retrieve_all_psa_from_psa.md).

``` r
# Créer une table temporaire des pseudo-NIR des patients avec AVC
patients_psa_avc <- sejours_avc |>
  select(BEN_NIR_PSA = NIR_ANO_17) |>
  distinct()

# Sauvegarder temporairement dans Oracle
DBI::dbWriteTable(conn, "TMP_PATIENTS_AVC_PSA", patients_psa_avc, overwrite = TRUE)

# Récupérer tous les identifiants patients associés
patients_identifiants_avc <- retrieve_all_psa_from_psa(
  ben_table_name = "TMP_PATIENTS_AVC_PSA",
  conn = conn
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
  select(BEN_IDT_ANO, BEN_NIR_PSA, BEN_RNG_GEM)

paste("Nombre de patients uniques avec AVC :", nrow(patients_avc_qualite))
#> [1] "Nombre de patients uniques avec AVC : 7"
```

### Étape 3 : Extraction des consultations médicales

Nous extrayons toutes les consultations médicales en ville de ces
patients en utilisant
[`extract_consultations_erprsf()`](../reference/extract_consultations_erprsf.md).

``` r
# Extraire toutes les consultations des patients avec AVC
consultations_avc <- extract_consultations_erprsf(
  start_date = start_date,
  end_date = end_date,
  pse_spe_filter = NULL, # Pas de filtre spécifique sur la spécialité
  prestation_filter = NULL, # Pas de filtre spécifique sur la prestation
  patients_ids_filter = patients_ids_filter,
  conn = conn
)
#> Extracting consultations from all specialties codes...

print(paste("Nombre de consultations extraites :", nrow(consultations_avc)))
#> [1] "Nombre de consultations extraites : 26"

# Analyser la répartition par spécialité médicale
consultations_par_specialite <- consultations_avc |>
  count(PSE_SPE_COD, sort = TRUE) |>
  mutate(pourcentage = round(n / sum(n) * 100, 1))
kable(head(consultations_par_specialite, 10))
```

| PSE_SPE_COD |   n | pourcentage |
|:------------|----:|------------:|
| 05          |   7 |        26.9 |
| 01          |   6 |        23.1 |
| 04          |   6 |        23.1 |
| 03          |   4 |        15.4 |
| 02          |   3 |        11.5 |

``` r

# Analyser le nombre de consultations par patient
consultations_par_patient <- consultations_avc |>
  group_by(BEN_IDT_ANO) |>
  summarise(
    nb_consultations = n(),
    premiere_consultation = min(EXE_SOI_DTD, na.rm = TRUE),
    derniere_consultation = max(EXE_SOI_DTD, na.rm = TRUE)
  ) |>
  ungroup()

print("Statistiques des consultations par patient :")
#> [1] "Statistiques des consultations par patient :"
summary(consultations_par_patient$nb_consultations)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   2.000   3.000   4.000   3.714   4.500   5.000
```

### Étape 4 : Extraction des Affections de Longue Durée (ALD)

Nous extrayons les ALD des patients avec AVC en utilisant
[`extract_long_term_disease()`](../reference/extract_long_term_disease.md).

``` r

# Extraire les ALD des patients avec AVC
patients_ids_for_ald <- patients_ids_filter |>
  select(BEN_IDT_ANO, BEN_NIR_PSA)

ald_patients_avc <- extract_long_term_disease(
  start_date = start_date,
  end_date = end_date,
  icd_cod_starts_with = NULL, # Pas de filtre spécifique : nous extrayons toutes les ALD
  patients_ids = patients_ids_for_ald,
  conn = conn
)
#> Extracting LTD status for all ICD 10 codes...

print(paste("Nombre d'ALD extraites :", nrow(ald_patients_avc)))
#> [1] "Nombre d'ALD extraites : 7"

# Analyser la répartition par type d'ALD
ald_resume <- ald_patients_avc |>
  count(MED_MTF_COD, sort = TRUE) |>
  mutate(pourcentage = round(n / sum(n) * 100, 1))
print(ald_resume)
#> # A tibble: 7 × 3
#>   MED_MTF_COD     n pourcentage
#>   <chr>       <int>       <dbl>
#> 1 I13             1        14.3
#> 2 I20             1        14.3
#> 3 I21             1        14.3
#> 4 I25             1        14.3
#> 5 I50             1        14.3
#> 6 I60             1        14.3
#> 7 I70             1        14.3

# Analyser le pourcentage de patients AVC avec une ALD
patients_avec_ald <- ald_patients_avc |>
  select(BEN_IDT_ANO) |>
  distinct() |>
  nrow()

pourcentage_ald <- round(patients_avec_ald / nrow(patients_avc_qualite) * 100, 1)
print(paste("Pourcentage de patients AVC avec une ALD :", pourcentage_ald, "%"))
#> [1] "Pourcentage de patients AVC avec une ALD : 71.4 %"
```

### Étape 5 : Analyses descriptives

#### 5.1 Caractéristiques démographiques des patients

``` r
# Analyser l'âge des patients avec AVC
age_analyse_avc <- sejours_avc |>
  group_by(NIR_ANO_17) |>
  slice(1) |>  # Un seul enregistrement par patient
  ungroup() |>
  summarise(
    age_moyen = mean(AGE_ANN, na.rm = TRUE),
    age_median = median(AGE_ANN, na.rm = TRUE),
    age_min = min(AGE_ANN, na.rm = TRUE),
    age_max = max(AGE_ANN, na.rm = TRUE)
  )
print("Analyse de l'âge des patients AVC :")
#> [1] "Analyse de l'âge des patients AVC :"
print(age_analyse_avc)
#> # A tibble: 1 × 4
#>   age_moyen age_median age_min age_max
#>       <dbl>      <dbl>   <dbl>   <dbl>
#> 1      60.6         67      33      83

# Répartition par sexe
sexe_repartition_avc <- sejours_avc |>
  group_by(NIR_ANO_17) |>
  slice(1) |>
  ungroup() |>
  count(COD_SEX) |>
  mutate(pourcentage = round(n / sum(n) * 100, 1))
print("Répartition par sexe :")
#> [1] "Répartition par sexe :"
print(sexe_repartition_avc)
#> # A tibble: 2 × 3
#>   COD_SEX     n pourcentage
#>   <chr>   <int>       <dbl>
#> 1 1           4          50
#> 2 2           4          50

# Analyser la durée des séjours AVC
duree_sejours_avc <- sejours_avc |>
  summarise(
    duree_moyenne = mean(SEJ_NBJ, na.rm = TRUE),
    duree_mediane = median(SEJ_NBJ, na.rm = TRUE),
    duree_min = min(SEJ_NBJ, na.rm = TRUE),
    duree_max = max(SEJ_NBJ, na.rm = TRUE)
  )
print("Durée des séjours AVC :")
#> [1] "Durée des séjours AVC :"
print(duree_sejours_avc)
#> # A tibble: 1 × 4
#>   duree_moyenne duree_mediane duree_min duree_max
#>           <dbl>         <int>     <int>     <int>
#> 1          14.1            15         7        20
```

#### 5.2 Analyses des consultations post-AVC

``` r
# Analyser les consultations les plus fréquentes
consultations_frequentes <- consultations_avc |>
  count(PSE_SPE_COD, sort = TRUE) |>
  mutate(pourcentage = round(n / sum(n) * 100, 1))
print("Types de consultations les plus fréquents :")
#> [1] "Types de consultations les plus fréquents :"
print(head(consultations_frequentes, 10))
#> # A tibble: 5 × 3
#>   PSE_SPE_COD     n pourcentage
#>   <chr>       <int>       <dbl>
#> 1 05              7        26.9
#> 2 01              6        23.1
#> 3 04              6        23.1
#> 4 03              4        15.4
#> 5 02              3        11.5

# Évolution temporelle des consultations
evolution_consultations_avc <- consultations_avc |>
  mutate(mois = floor_date(EXE_SOI_DTD, "month")) |>
  count(mois) |>
  arrange(mois)
print("Évolution mensuelle des consultations :")
#> [1] "Évolution mensuelle des consultations :"
print(evolution_consultations_avc)
#> # A tibble: 12 × 2
#>    mois           n
#>    <date>     <int>
#>  1 2024-01-01     1
#>  2 2024-02-01     2
#>  3 2024-03-01     4
#>  4 2024-04-01     2
#>  5 2024-05-01     2
#>  6 2024-06-01     1
#>  7 2024-07-01     3
#>  8 2024-08-01     2
#>  9 2024-09-01     1
#> 10 2024-10-01     1
#> 11 2024-11-01     6
#> 12 2024-12-01     1

# Analyser les spécialités les plus consultées
specialites_frequentes <- consultations_avc |>
  filter(!is.na(PSE_SPE_COD)) |>
  count(PSE_SPE_COD, sort = TRUE) |>
  mutate(pourcentage = round(n / sum(n) * 100, 1))
print("Spécialités médicales les plus consultées :")
#> [1] "Spécialités médicales les plus consultées :"
print(head(specialites_frequentes, 10))
#> # A tibble: 5 × 3
#>   PSE_SPE_COD     n pourcentage
#>   <chr>       <int>       <dbl>
#> 1 05              7        26.9
#> 2 01              6        23.1
#> 3 04              6        23.1
#> 4 03              4        15.4
#> 5 02              3        11.5
```

#### 5.3 Analyse des parcours de soins

``` r
# Analyser le délai entre l'hospitalisation et la première consultation
parcours_soins <- sejours_avc |>
  group_by(NIR_ANO_17) |>
  summarise(
    date_hospitalisation = min(EXE_SOI_DTD, na.rm = TRUE),
    .groups = "drop"
  ) |>
  inner_join(
    consultations_par_patient |>
      select(BEN_IDT_ANO, premiere_consultation),
    by = c("NIR_ANO_17" = "BEN_IDT_ANO")  # Adapter selon les colonnes disponibles
  ) |>
  mutate(
    delai_jours = as.numeric(premiere_consultation - date_hospitalisation)
  ) |>
  filter(!is.na(delai_jours))

# Statistiques sur les délais
delai_stats <- parcours_soins |>
  summarise(
    delai_moyen = mean(delai_jours, na.rm = TRUE),
    delai_median = median(delai_jours, na.rm = TRUE),
    delai_min = min(delai_jours, na.rm = TRUE),
    delai_max = max(delai_jours, na.rm = TRUE)
  )
#> Warning: There were 2 warnings in `summarise()`.
#> The first warning was:
#> ℹ In argument: `delai_min = min(delai_jours, na.rm = TRUE)`.
#> Caused by warning in `min()`:
#> ! no non-missing arguments to min; returning Inf
#> ℹ Run `dplyr::last_dplyr_warnings()` to see the 1 remaining warning.
print("Délai entre hospitalisation AVC et première consultation (jours) :")
#> [1] "Délai entre hospitalisation AVC et première consultation (jours) :"
print(delai_stats)
#> # A tibble: 1 × 4
#>   delai_moyen delai_median delai_min delai_max
#>         <dbl>        <dbl>     <dbl>     <dbl>
#> 1         NaN           NA       Inf      -Inf
```

### Étape 6 : Nettoyage et fermeture

``` r
# Supprimer les tables temporaires
if (DBI::dbExistsTable(conn, "TMP_PATIENTS_AVC_PSA")) {
  DBI::dbRemoveTable(conn, "TMP_PATIENTS_AVC_PSA")
}

# Fermer la connexion
DBI::dbDisconnect(conn)

# Résumé de l'étude
cat("
=== RÉSUMÉ DE L'ÉTUDE AVC 2024 ===
Période analysée :", format(start_date), "au", format(end_date), "
Patients avec hospitalisation AVC :", nrow(patients_avc_qualite), "
Séjours hospitaliers AVC :", nrow(sejours_avc), "
Consultations médicales :", nrow(consultations_avc), "
ALD associées :", nrow(ald_patients_avc), "
Pourcentage de patients avec ALD :", pourcentage_ald, "%
")
#> 
#> === RÉSUMÉ DE L'ÉTUDE AVC 2024 ===
#> Période analysée : 2024-01-01 au 2024-12-31 
#> Patients avec hospitalisation AVC : 7 
#> Séjours hospitaliers AVC : 21 
#> Consultations médicales : 26 
#> ALD associées : 7 
#> Pourcentage de patients avec ALD : 71.4 %
```

### Conclusion

Ce tutoriel a présenté une étude complète des patients hospitalisés pour
AVC en 2024 en utilisant le package `sndsTools`. Les principales étapes
couvertes incluent :

1.  **Extraction des hospitalisations pour AVC** avec
    [`extract_hospital_stays()`](../reference/extract_hospital_stays.md)
    en utilisant les codes CIM-10 I61, I62, I63, I64
2.  **Gestion des identifiants patients** avec
    [`retrieve_all_psa_from_psa()`](../reference/retrieve_all_psa_from_psa.md)
3.  **Extraction des consultations médicales** avec
    [`extract_consultations_erprsf()`](../reference/extract_consultations_erprsf.md)
4.  **Extraction des ALD** avec
    [`extract_long_term_disease()`](../reference/extract_long_term_disease.md)
5.  **Analyses descriptives** des parcours de soins post-AVC

#### Perspectives d’analyse

Cette étude de base peut être enrichie par : - L’analyse des traitements
médicamenteux post-AVC - L’étude des réhospitalisations - L’analyse des
coûts des parcours de soins - La comparaison entre différents types
d’AVC - L’étude de la mortalité à court et long terme

#### Bonnes pratiques

- Toujours utiliser des filtres de qualité sur les identifiants patients
- Vérifier la cohérence des dates et périodes d’extraction
- Nettoyer les tables temporaires après utilisation
- Fermer les connexions à la base de données
- Documenter les codes CIM-10 et ATC utilisés

#### Fonctions utilitaires supplémentaires

Le package propose également des fonctions utilitaires : -
[`connect_oracle()`](../reference/connect_oracle.md) pour la connexion
Oracle -
[`create_table_from_query()`](../reference/create_table_from_query.md)
pour créer des tables à partir de requêtes -
[`gather_table_stats()`](../reference/gather_table_stats.md) pour
optimiser les performances

Pour plus d’informations, consultez la documentation complète du package
et les exemples dans le dossier [`notebooks/`](../notebooks/).
