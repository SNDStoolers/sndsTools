# Extrait les dispensations de médicaments en accès précoces depuis le DCIR.

Extrait les dispensations de médicaments en accès précoces réalisés en
hospitalisation privée (ex-OQN) ou en rétrocession hospitalière privée
et publique (ex-OQN et ex-DGF) pour une année donnée et une liste de
codes UCD donnée.

## Usage

``` r
extract_drug_erucdf(
  start_date,
  end_date,
  ucd_codes_filter = NULL,
  patients_ids_filter = NULL,
  dis_dtd_lag_months = 6,
  sup_columns = NULL,
  output_table_name = NULL,
  conn = NULL,
  show_sql_query = FALSE
)
```

## Arguments

- start_date:

  Début d'extraction (date de soin)

- end_date:

  Fin d'extraction (date de soin)

- ucd_codes_filter:

  Liste de codes ucd à extraire. Attention, les codes UCD doivent être
  fournis au format UCD 7 caractères préfixé de 6 zéros :
  "0000009419723". Ce format est celui utilisé dans la base de données.
  Si NULL, extrait tous les codes.

- patients_ids_filter:

  data.frame (Optionnel). Un data.frame contenant les paires
  d'identifiants des patients pour lesquels les délivrances de
  médicaments doivent être extraites. Les colonnes de ce data.frame
  doivent être "BEN_IDT_ANO" et "BEN_NIR_PSA". Les "BEN_NIR_PSA" doivent
  être tous les "BEN_NIR_PSA" associés aux "BEN_IDT_ANO" fournis. Défaut
  à NULL.

- dis_dtd_lag_months:

  Integer (Optionnel). Le nombre maximum de mois de décalage de
  FLX_DIS_DTD par rapport à EXE_SOI DTD pris en compte pour récupérer
  les délivrances de médicaments. Défaut à 6 mois.

- sup_columns:

  Character vector (Optionnel). Les colonnes supplémentaires à ajouter à
  la table de sortie. Défaut à NULL, donc aucune colonne ajoutée.

- output_table_name:

  Character (Optionnel). Si fourni, les résultats seront sauvegardés
  dans une table portant ce nom dans la base de données au lieu d'être
  retournés sous forme de data frame. Si la table existe déjà dans la
  base oracle, alors le programme s'arrête en retournant une erreur.
  Défaut à NULL.

- conn:

  DBI connection (Optionnel). Une connexion à la base de données Oracle.
  Si non fournie, une connexion est établie par défaut. Défaut à NULL.

- show_sql_query:

  Boolean (Optionnel). Affiche la requête SQL du premier mois. Défaut à
  FALSE.

## Value

Consommations individuelles d'accès précoces pour l'hospitalisation
privée et les rétrocessions hospitalières.

@examples \*

## Details

Les données sont filtrées par date de prestation (`EXE_SOI_DTD`), et par
date de flux (`FLX_DIS_DTD`) en regardant 7 mois au delà de la date de
fin d'étude `end_date` pour prendre en compte la durée de remontée de
l'information. Les données sont filtrées en ne conservant que les
PRS_NAT_REF d'accès précoces ("3336", "3317", "3351", "3421").

NB: Les données sont extraites par date de flux, puis filtrées par date
de soin. Elles sont extraites d'un bloc sur la période d'intérêt par
contraste avec les recommandations de la CNAM qui préconise d'extraire
mois par mois pour des raisons d'optimisation technique (éviter la
saturation d'un temporary space partagé entre utilisateurs).
L'alternative serait de code une fonction extrayant mois par mois (ie.
"magic loop").

NB: La jointure avec la table établissement est faite avec un
inner_join. On ne garde que les AP préscrites en établissement.

## See also

Other extract:
[`extract_consultations_erprsf()`](extract_consultations_erprsf.md),
[`extract_drug_dispenses()`](extract_drug_dispenses.md),
[`extract_hospital_consultations()`](extract_hospital_consultations.md),
[`extract_hospital_stays()`](extract_hospital_stays.md),
[`extract_long_term_disease()`](extract_long_term_disease.md)
