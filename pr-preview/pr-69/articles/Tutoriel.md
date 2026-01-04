# 

## Tutoriel : cas d’étude

Ceci est un tutoriel illustrant une utilisation de [`sndsTools`](../R/)
dans le cadre d’une étude fictive sur l’analyse des médicaments
antihypertenseurs.

### Contexte de l’étude

Dans le cadre de cette étude, nous souhaitons analyser la consommation
de médicaments antihypertenseurs chez les patients du SNDS. Nous allons
extraire les données pertinentes en utilisant les fonctions disponibles
dans [`sndsTools`](../R/), effectuer des analyses descriptives et
présenter les résultats.

Les objectifs de cette étude sont : 1. Identifier les patients avec des
délivrances d’antihypertenseurs 2. Analyser les Affections de Longue
Durée (ALD) cardiovasculaires associées 3. Étudier les séjours
hospitaliers en lien avec l’hypertension 4. Effectuer des analyses
descriptives sur ces populations

### Prérequis

Avant de commencer, assurez-vous d’avoir : - Une connexion à la base de
données Oracle du SNDS - Le package [`sndsTools`](../R/) installé et
chargé - Les autorisations nécessaires pour accéder aux données

``` r
# Charger les packages nécessaires
library(sndsTools)
library(dplyr)
library(lubridate)

# Établir la connexion à la base de données
conn <- connect_oracle()
```

### Étape 1 : Extraction des délivrances d’antihypertenseurs

Nous commençons par extraire les délivrances de médicaments
antihypertenseurs en utilisant la fonction
[`extract_drug_dispenses()`](../R/extract_drug_dispenses.R:94). Les
codes ATC pour les antihypertenseurs commencent généralement par “C02”,
“C03”, “C07”, “C08”, et “C09”.

``` r
# Définir la période d'étude
start_date <- as.Date("2020-01-01")
end_date <- as.Date("2020-12-31")

# Codes ATC pour les antihypertenseurs
atc_antihypertenseurs <- c("C02")

# Extraire les délivrances d'antihypertenseurs
antihypertenseurs_data <- extract_drug_dispenses(
  start_date = start_date,
  end_date = end_date,
  atc_cod_starts_with_filter = atc_antihypertenseurs,
  conn = conn
)

# Afficher un aperçu des données
print(paste("Nombre de délivrances extraites :", nrow(antihypertenseurs_data)))
head(antihypertenseurs_data)
```

### Étape 2 : Identification des patients uniques

À partir des délivrances, nous identifions les patients uniques et
récupérons leurs identifiants complets en utilisant
[`retrieve_all_psa_from_psa()`](../R/retrieve_patient_id.R:330).

``` r
# Créer une table temporaire des patients avec délivrances d'antihypertenseurs
patients_psa <- antihypertenseurs_data |>
  select(BEN_NIR_PSA) |>
  distinct()

# Sauvegarder temporairement dans Oracle
DBI::dbWriteTable(conn, "TMP_PATIENTS_PSA", patients_psa, overwrite = TRUE)

# Récupérer tous les identifiants patients associés
patients_identifiants <- retrieve_all_psa_from_psa(
  ben_table_name = "TMP_PATIENTS_PSA",
  conn = conn
)

# Filtrer les patients avec des critères de qualité
patients_qualite <- patients_identifiants |>
  filter(
    !psa_w_multiple_idt_or_nir,  # Éviter les PSA multiples
    cdi_nir_00,                   # NIR non fictifs
    nir_ano_defined,              # NIR anonyme défini
    !birth_date_variation,        # Pas de variation date naissance
    !sex_variation               # Pas de variation sexe
  )

print(paste("Nombre de patients identifiés :", nrow(patients_qualite)))
```

### Étape 3 : Extraction des Affections de Longue Durée (ALD)

Nous extrayons ensuite les ALD cardiovasculaires pour nos patients en
utilisant
[`extract_long_term_disease()`](../R/extract_long_term_disease.R:80).

``` r
# Codes ICD-10 pour les maladies cardiovasculaires
icd_cardiovasculaires <- c("I10", "I11", "I12", "I13", "I15", "I20", "I21", "I22", "I25")

# Préparer les identifiants patients pour l'extraction
patients_ids_filter <- patients_qualite |>
  select(BEN_IDT_ANO, BEN_NIR_PSA)

# Extraire les ALD cardiovasculaires
ald_cardiovasculaires <- extract_long_term_disease(
  start_date = start_date,
  end_date = end_date,
  icd_cod_starts_with = icd_cardiovasculaires,
  patients_ids = patients_ids_filter,
  conn = conn
)

print(paste("Nombre d'ALD cardiovasculaires :", nrow(ald_cardiovasculaires)))

# Analyser la répartition par type d'ALD
ald_resume <- ald_cardiovasculaires |>
  count(MED_MTF_COD, sort = TRUE)
print(ald_resume)
```

### Étape 4 : Extraction des séjours hospitaliers

Nous extrayons les séjours hospitaliers avec des diagnostics
cardiovasculaires en utilisant
[`extract_hospital_stays()`](../R/extract_hospital_stays.R:216).

``` r
# Extraire les séjours avec diagnostics cardiovasculaires
sejours_cardiovasculaires <- extract_hospital_stays(
  start_date = start_date,
  end_date = end_date,
  dp_cim10_codes_filter = icd_cardiovasculaires,
  or_dr_with_same_codes_filter = TRUE,  # Inclure les diagnostics reliés
  patients_ids_filter = patients_ids_filter,
  conn = conn
)

print(paste("Nombre de séjours cardiovasculaires :", nrow(sejours_cardiovasculaires)))

# Analyser la durée moyenne des séjours
duree_moyenne <- sejours_cardiovasculaires |>
  summarise(
    duree_moyenne = mean(SEJ_NBJ, na.rm = TRUE),
    duree_mediane = median(SEJ_NBJ, na.rm = TRUE)
  )
print(duree_moyenne)
```

### Étape 5 : Analyses descriptives

#### 5.1 Caractéristiques des patients

``` r
# Analyser l'âge des patients avec antihypertenseurs
age_analyse <- sejours_cardiovasculaires |>
  group_by(BEN_IDT_ANO) |>
  slice(1) |>  # Un seul enregistrement par patient
  ungroup() |>
  summarise(
    age_moyen = mean(AGE_ANN, na.rm = TRUE),
    age_median = median(AGE_ANN, na.rm = TRUE),
    age_min = min(AGE_ANN, na.rm = TRUE),
    age_max = max(AGE_ANN, na.rm = TRUE)
  )
print(age_analyse)

# Répartition par sexe
sexe_repartition <- sejours_cardiovasculaires |>
  group_by(BEN_IDT_ANO) |>
  slice(1) |>
  ungroup() |>
  count(COD_SEX) |>
  mutate(pourcentage = round(n / sum(n) * 100, 1))
print(sexe_repartition)
```

#### 5.2 Analyses des délivrances

``` r
# Analyser les délivrances par code ATC
delivrances_atc <- antihypertenseurs_data |>
  count(PHA_ATC_CLA, sort = TRUE) |>
  mutate(pourcentage = round(n / sum(n) * 100, 1))
print(head(delivrances_atc, 10))

# Analyser la quantité moyenne délivrée
quantite_analyse <- antihypertenseurs_data |>
  summarise(
    quantite_moyenne = mean(PHA_ACT_QSN, na.rm = TRUE),
    quantite_mediane = median(PHA_ACT_QSN, na.rm = TRUE)
  )
print(quantite_analyse)

# Évolution temporelle des délivrances
evolution_mensuelle <- antihypertenseurs_data |>
  mutate(mois = floor_date(EXE_SOI_DTD, "month")) |>
  count(mois) |>
  arrange(mois)
print(evolution_mensuelle)
```

### Étape 6 : Nettoyage et fermeture

``` r
# Supprimer les tables temporaires
if (DBI::dbExistsTable(conn, "TMP_PATIENTS_PSA")) {
  DBI::dbRemoveTable(conn, "TMP_PATIENTS_PSA")
}

# Fermer la connexion
DBI::dbDisconnect(conn)

# Résumé de l'étude
cat("
=== RÉSUMÉ DE L'ÉTUDE ===
Période analysée :", format(start_date), "au", format(end_date), "
Patients avec antihypertenseurs :", nrow(patients_qualite), "
ALD cardiovasculaires :", nrow(ald_cardiovasculaires), "
Séjours cardiovasculaires :", nrow(sejours_cardiovasculaires), "
")
```

### Conclusion

Ce tutoriel a présenté un exemple complet d’utilisation du package
[`sndsTools`](../R/) pour analyser les données d’antihypertenseurs dans
le SNDS. Les principales étapes couvertes incluent :

1.  **Extraction des délivrances** avec
    [`extract_drug_dispenses()`](../R/extract_drug_dispenses.R:94)
2.  **Gestion des identifiants patients** avec
    [`retrieve_all_psa_from_psa()`](../R/retrieve_patient_id.R:330)
3.  **Extraction des ALD** avec
    [`extract_long_term_disease()`](../R/extract_long_term_disease.R:80)
4.  **Extraction des séjours hospitaliers** avec
    [`extract_hospital_stays()`](../R/extract_hospital_stays.R:216)
5.  **Analyses descriptives** des données extraites

#### Bonnes pratiques

- Toujours utiliser des filtres de qualité sur les identifiants patients
- Vérifier la cohérence des dates et périodes d’extraction
- Nettoyer les tables temporaires après utilisation
- Fermer les connexions à la base de données

#### Fonctions utilitaires supplémentaires

Le package propose également des fonctions utilitaires : -
[`connect_oracle()`](../R/utils.R:6) pour la connexion Oracle -
[`create_table_from_query()`](../R/utils.R:52) pour créer des tables à
partir de requêtes - [`gather_table_stats()`](../R/utils.R:117) pour
optimiser les performances

Pour plus d’informations, consultez la documentation complète du package
et les exemples dans le dossier [`notebooks/`](../notebooks/).
