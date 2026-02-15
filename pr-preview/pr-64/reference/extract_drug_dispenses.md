# Extraction des délivrances de médicaments.

Cette fonction permet d'extraire les délivrances de médicaments par code
ATC ou par code CIP13. Les délivrances dont les dates `EXE_SOI_DTD` sont
comprises entre `start_date` et `end_date` (incluses) sont extraites.

## Usage

``` r
extract_drug_dispenses(
  start_date,
  end_date,
  atc_cod_starts_with_filter = NULL,
  cip13_cod_filter = NULL,
  patients_ids_filter = NULL,
  dis_dtd_lag_months = 6,
  sup_columns = NULL,
  output_table_name = NULL,
  conn = NULL,
  show_sql_query = TRUE
)
```

## Arguments

- start_date:

  Date. La date de début de la période des délivrances des médicaments à
  extraire.

- end_date:

  Date. La date de fin de la période des délivrances des médicaments à
  extraire.

- atc_cod_starts_with_filter:

  Character vector (Optionnel). Les codes ATC par lesquels les
  délivrances de médicaments à extraire doivent commencer. Défaut à
  NULL.

- cip13_cod_filter:

  Character vector (Optionnel). Les codes CIP des délivrances de
  médicaments à extraire en complément des codes ATC. Défaut à NULL.

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
  Défault à NULL.

- conn:

  DBI connection (Optionnel). Une connexion à la base de données Oracle.
  Si non fournie, une connexion est établie par défaut. Défaut à NULL.

## Value

Si output_table_name est NULL, retourne un data.frame contenant les
délivrances de médicaments. Si output_table_name est fourni, sauvegarde
les résultats dans la table spécifiée dans Oracle et retourne NULL de
manière invisible. Dans les deux cas les colonnes de la table de sortie
sont :

- BEN_NIR_PSA : Colonne présente uniquement si les identifiants patients
  (`patients_ids_filter`) ne sont pas fournis. Identifiant SNDS, aussi
  appelé pseudo-NIR.

- BEN_IDT_ANO : Colonne présente uniquement si les identifiants patients
  (`patients_ids_filter`) sont fournis. Numéro d’inscription au
  répertoire (NIR) anonymisé.

- EXE_SOI_DTD : Date de la délivrance

- PHA_ACT_QSN : Quantité délivrée

- PHA_ATC_CLA : Code ATC du médicament délivré

- PHA_PRS_C13 : Code CIP du médicament délivré (nom dans la table
  ER_PHA_F : PHA_PRS_C13, nom dans la table IR_PHA_R : PHA_CIP_C13)

- PSP_SPE_COD : Code de spécialité du professionnel de soin prescripteur
  (voir nomenclature IR_SPE_V)

- Les colonnes supplémentaires spécifiées dans `sup_columns` si
  fournies.

## Details

Le décalage de remontée des données est pris en compte en récupérant
également les délivrances dont les dates `FLX_DIS_DTD` sont comprises
dans les `dis_dtd_lag_months` mois suivant end_date.

Si `atc_cod_starts_with` ou `cip13_codes` sont fournies, seules les
délivrances de médicaments dont le code ATC commence par l'un des
éléments de `atc_cod_starts_with` OU dont le code CIP13 est dans
`cip13_codes` sont extraites. Dans le cas ou aucun des filtres n'est
renseigné, les délivrances pour tous les codes ATC et CIP13 sont
extraites. Si l'un des filtres est `NULL`, mais pas l'autre, seul les
délivrances pour le filtre non `NULL` sont extraites.

Si `patients_ids_filter` est fourni, seules les délivrances de
médicaments pour les patients dont les identifiants sont dans
`patients_ids_filter` sont extraites. Dans le cas contraire, les
délivrances de tous les patients sont extraites. Pour être à flux
constant sur l'ensemble des années, il faut utiliser
`dis_dtd_lag_months` = 27 Cela rallonge le temps d'extraction alors que
l'impact sur l'extraction est minime car [la Cnam estime que 99 % des
soins sont remontés à 6
mois](https://documentation-snds.health-data-hub.fr/snds/formation_snds/initiation/schema_relationnel_snds.html#_3-3-dcir),
c'est-à-dire pour dis_dtd_lag_months = 6.

## See also

Other extract:
[`extract_consultations_erprsf()`](extract_consultations_erprsf.md),
[`extract_hospital_consultations()`](extract_hospital_consultations.md),
[`extract_hospital_stays()`](extract_hospital_stays.md),
[`extract_long_term_disease()`](extract_long_term_disease.md)

## Examples

``` r
if (FALSE) { # \dontrun{
start_date <- as.Date("2010-01-01")
end_date <- as.Date("2010-01-03")
atc_cod_starts_with <- c("N04A")

dispenses <- extract_drug_dispenses(
  start_date = start_date,
  end_date = end_date,
  atc_cod_starts_with = atc_cod_starts_with
)
} # }
```
