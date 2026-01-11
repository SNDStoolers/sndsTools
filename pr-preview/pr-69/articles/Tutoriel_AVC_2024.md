# Exemple d'étude possible avec sndsTools

Cette page présente un exemple typique d’utilisation des fonctions de
`sndsTools` pour étudier les données du SNDS.

Le cas d’étude porte sur les patients hospitalisés pour un Accident
Vasculaire Cérébral (AVC) au cours de l’année 2024.

## Contexte de l’étude

Dans le cadre de cette étude, nous souhaitons analyser les parcours de
soins des patients hospitalisés pour un AVC au cours de l’année 2024.
Nous utiliserons les fonctions disponibles dans `sndsTools` pour
extraire et analyser les données pertinentes.

Cette étude est un exemple pédagogique de l’utilisation du package
`sndsTools`. Elle ne constitue en aucun cas une étude réelle valide
scientifiquement concernant les patients hospitalisés pour un AVC.

Les objectifs de cette étude sont : 1. Identifier les patients avec une
hospitalisation pour AVC en 2024 (codes CIM-10 : I61, I62, I63, I64) 2.
Récupérer leurs identifiants complets via
[`retrieve_all_psa_from_psa()`](../R/retrieve_patient_id.R:330) 3.
Extraire leurs consultations médicales en ville via
[`extract_consultations_erprsf()`](../R/extract_consultations_erprsf.R:81)
4. Extraire leurs Affections de Longue Durée (ALD) via
[`extract_long_term_disease()`](../R/extract_long_term_disease.R:80) 5.
Etraire leurs prescriptions médicamenteuses en ville via
[`extract_long_term_disease()`](../R/extract_long_term_disease.R:80) 6.
Présenter quelques analyses descriptives sur ces données

### Prérequis

Avant de commencer, assurez-vous d’avoir : - Une connexion à la base de
données Oracle du SNDS sur le portail de la CNAM - Le code du package
`sndsTools` [copié sur le
portail](https://sndstoolers.github.io/sndsTools/articles/sndsTools.html#sur-le-portail-cnam)

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
    conn <- connect_duckdb()
}
# packages utiles pour l'analyse
library(dplyr)
library(lubridate)
library(knitr)
```

### Étape 1 : Extraction des hospitalisations pour AVC

Nous commençons par extraire les séjours hospitaliers avec un diagnostic
principal d’AVC en utilisant la fonction
[`extract_hospital_stays()`](../R/extract_hospital_stays.R:216). Les
[codes CIM-10 pour les
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
head(sejours_avc)

# Analyser la répartition par type d'AVC
avc_par_type <- sejours_avc |>
  count(DGN_PAL, sort = TRUE) |>
  mutate(pourcentage = round(n / sum(n) * 100, 1))
kable(avc_par_type)
```

### Étape 2 : Identification des patients uniques

À partir des séjours, nous identifions les patients uniques en
[récupérant leurs identifiants uniques
`BEN_NIR_ANO`](https://documentation-snds.health-data-hub.fr/snds/fiches/fiche_beneficiaire.html)
dans le référentiel des bénéficiaires en utilisant
[`retrieve_all_psa_from_psa()`](../R/retrieve_patient_id.R:330).

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

# TODO: enlever ces filtres ? 
# Filtrer les patients avec des critères de qualité
patients_avc_qualite <- patients_identifiants_avc |>
  filter(
    !psa_w_multiple_idt_or_nir,  # Éviter les PSA multiples
    cdi_nir_00,                   # NIR non fictifs
    nir_ano_defined,              # NIR anonyme défini
    !birth_date_variation,        # Pas de variation date naissance
    !sex_variation               # Pas de variation sexe
  )

print(paste("Nombre de patients uniques avec AVC :", nrow(patients_avc_qualite)))

# Préparer les identifiants pour les extractions ultérieures
patients_ids_filter <- patients_avc_qualite |>
  select(BEN_IDT_ANO, BEN_NIR_PSA, BEN_RNG_GEM)
```

### Étape 3 : Extraction des consultations médicales

Nous extrayons toutes les consultations médicales en ville de ces
patients en utilisant
[`extract_consultations_erprsf()`](../R/extract_consultations_erprsf.R:81).

``` r
# Extraire toutes les consultations des patients avec AVC
consultations_avc <- extract_consultations_erprsf(
  start_date = start_date,
  end_date = end_date,
  patients_ids_filter = patients_ids_filter,
  conn = conn
)

print(paste("Nombre de consultations extraites :", nrow(consultations_avc)))

# Analyser la répartition par spécialité médicale
consultations_par_specialite <- consultations_avc |>
  count(PSE_SPE_COD, sort = TRUE) |>
  mutate(pourcentage = round(n / sum(n) * 100, 1))
kable(head(consultations_par_specialite, 10))

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
kable(summary(consultations_par_patient$nb_consultations))
```

### Étape 4 : Extraction des Affections de Longue Durée (ALD)

Nous extrayons les ALD des patients avec AVC en utilisant
[`extract_long_term_disease()`](../R/extract_long_term_disease.R:80).

``` r

# Extraire les ALD des patients avec AVC
ald_patients_avc <- extract_long_term_disease(
  start_date = start_date,
  end_date = end_date,
  icd_cod_starts_with = NULL, # Pas de filtre spécifique : nous extrayons toutes les ALD
  patients_ids = patients_ids_filter,
  conn = conn
)

print(paste("Nombre d'ALD extraites :", nrow(ald_patients_avc)))

# Analyser la répartition par type d'ALD
ald_resume <- ald_patients_avc |>
  count(MED_MTF_COD, sort = TRUE) |>
  mutate(pourcentage = round(n / sum(n) * 100, 1))
print(ald_resume)

# Analyser le pourcentage de patients AVC avec une ALD
patients_avec_ald <- ald_patients_avc |>
  select(BEN_IDT_ANO) |>
  distinct() |>
  nrow()

pourcentage_ald <- round(patients_avec_ald / nrow(patients_avc_qualite) * 100, 1)
print(paste("Pourcentage de patients AVC avec une ALD :", pourcentage_ald, "%"))
```

### Étape 5 : Analyses descriptives

#### 5.1 Caractéristiques démographiques des patients

``` r
# Analyser l'âge des patients avec AVC
age_analyse_avc <- sejours_avc |>
  group_by(BEN_NIR_PSA) |>
  slice(1) |>  # Un seul enregistrement par patient
  ungroup() |>
  summarise(
    age_moyen = mean(AGE_ANN, na.rm = TRUE),
    age_median = median(AGE_ANN, na.rm = TRUE),
    age_min = min(AGE_ANN, na.rm = TRUE),
    age_max = max(AGE_ANN, na.rm = TRUE)
  )
print("Analyse de l'âge des patients AVC :")
print(age_analyse_avc)

# Répartition par sexe
sexe_repartition_avc <- sejours_avc |>
  group_by(BEN_NIR_PSA) |>
  slice(1) |>
  ungroup() |>
  count(COD_SEX) |>
  mutate(pourcentage = round(n / sum(n) * 100, 1))
print("Répartition par sexe :")
print(sexe_repartition_avc)

# Analyser la durée des séjours AVC
duree_sejours_avc <- sejours_avc |>
  summarise(
    duree_moyenne = mean(SEJ_NBJ, na.rm = TRUE),
    duree_mediane = median(SEJ_NBJ, na.rm = TRUE),
    duree_min = min(SEJ_NBJ, na.rm = TRUE),
    duree_max = max(SEJ_NBJ, na.rm = TRUE)
  )
print("Durée des séjours AVC :")
print(duree_sejours_avc)
```

#### 5.2 Analyses des consultations post-AVC

``` r
# Analyser les consultations les plus fréquentes
consultations_frequentes <- consultations_avc |>
  count(PRS_NAT_REF, sort = TRUE) |>
  mutate(pourcentage = round(n / sum(n) * 100, 1))
print("Types de consultations les plus fréquents :")
print(head(consultations_frequentes, 10))

# Évolution temporelle des consultations
evolution_consultations_avc <- consultations_avc |>
  mutate(mois = floor_date(EXE_SOI_DTD, "month")) |>
  count(mois) |>
  arrange(mois)
print("Évolution mensuelle des consultations :")
print(evolution_consultations_avc)

# Analyser les spécialités les plus consultées
specialites_frequentes <- consultations_avc |>
  filter(!is.na(PSE_SPE_COD)) |>
  count(PSE_SPE_COD, sort = TRUE) |>
  mutate(pourcentage = round(n / sum(n) * 100, 1))
print("Spécialités médicales les plus consultées :")
print(head(specialites_frequentes, 10))
```

#### 5.3 Analyse des parcours de soins

``` r
# Analyser le délai entre l'hospitalisation et la première consultation
parcours_soins <- sejours_avc |>
  group_by(BEN_NIR_PSA) |>
  summarise(
    date_hospitalisation = min(ENT_DAT, na.rm = TRUE),
    .groups = "drop"
  ) |>
  inner_join(
    consultations_par_patient |>
      select(BEN_IDT_ANO, premiere_consultation),
    by = c("BEN_NIR_PSA" = "BEN_IDT_ANO")  # Adapter selon les colonnes disponibles
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
print("Délai entre hospitalisation AVC et première consultation (jours) :")
print(delai_stats)
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
```

### Conclusion

Ce tutoriel a présenté une étude complète des patients hospitalisés pour
AVC en 2024 en utilisant le package `sndsTools`. Les principales étapes
couvertes incluent :

1.  **Extraction des hospitalisations pour AVC** avec
    [`extract_hospital_stays()`](../R/extract_hospital_stays.R:216) en
    utilisant les codes CIM-10 I61, I62, I63, I64
2.  **Gestion des identifiants patients** avec
    [`retrieve_all_psa_from_psa()`](../R/retrieve_patient_id.R:330)
3.  **Extraction des consultations médicales** avec
    [`extract_consultations_erprsf()`](../R/extract_consultations_erprsf.R:81)
4.  **Extraction des ALD** avec
    [`extract_long_term_disease()`](../R/extract_long_term_disease.R:80)
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
[`connect_oracle()`](../R/utils.R:6) pour la connexion Oracle -
[`create_table_from_query()`](../R/utils.R:52) pour créer des tables à
partir de requêtes - [`gather_table_stats()`](../R/utils.R:117) pour
optimiser les performances

Pour plus d’informations, consultez la documentation complète du package
et les exemples dans le dossier [`notebooks/`](../notebooks/).
