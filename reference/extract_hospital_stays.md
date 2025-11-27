# Extraction des diagnostics des séjours hospitaliers (MCO).

Cette fonction permet d'extraire les diagnostics des séjours
hospitaliers en MCO. Les diagnostics dont les dates `EXE_SOI_DTD` sont
comprises entre `start_date` et `end_date` sont extraits.

## Usage

``` r
extract_hospital_stays(
  start_date,
  end_date,
  dp_cim10_codes_filter = NULL,
  or_dr_with_same_codes_filter = FALSE,
  or_da_with_same_codes_filter = FALSE,
  and_da_with_other_codes_filter = FALSE,
  da_cim10_codes_filter = NULL,
  patients_ids_filter = NULL,
  output_table_name = NULL,
  conn = NULL
)
```

## Arguments

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

  logical (Optionnel). Indique si les séjours avec des codes DA
  différents doivent être extraits. La requête est effectuée par préfixe
  : Par exemple, si E12 est renseigné, tous les codes commençant par E12
  sont extraits. Défaut à `NULL`.

- da_cim10_codes_filter:

  character vector (Optionnel). Les codes CIM10 des diagnostics associés
  à extraire. La requête est effectuée par préfixe : Par exemple, si E12
  est renseigné, tous les codes commençant par E12 sont extraits. Défaut
  à `NULL`.

- patients_ids_filter:

  data.frame (Optionnel). Un data.frame contenant les paires
  d'identifiants des patients pour lesquels les consultations doivent
  être extraites. Les colonnes de ce data.frame doivent être
  `BEN_IDT_ANO` et `BEN_NIR_PSA` (en majuscules). Les "BEN_NIR_PSA"
  doivent être tous les "BEN_NIR_PSA" associés aux "BEN_IDT_ANO"
  fournis. Si `patients_ids` n'est pas fourni, les consultations de tous
  les patients sont extraites. Défaut à `NULL`.

- output_table_name:

  character Le nom de la table de sortie dans la base de données. Si
  `output_table_name` n'est pas fourni, une table de sortie
  intermédiaire est créée. Défaut à `NULL`.

- conn:

  dbConnection La connexion à la base de données. Si `conn` n'est pas
  fourni, une connexion à la base de données est initialisée. Défaut à
  `NULL`.

- or_dr_with_same_codes:

  logical (Optionnel).Indique si les séjours avec les mêmes codes DR
  doivent être extraits. La requête est effectuée par préfixe : Par
  exemple, si E12 est renseigné, tous les codes commençant par E12 sont
  extraits. Défaut à `NULL`.

- or_da_with_same_codes:

  logical (Optionnel). Indique si les séjours avec les mêmes codes DA
  doivent être extraits. La requête est effectuée par préfixe : Par
  exemple, si E12 est renseigné, tous les codes commençant par E12 sont
  extraits. Défaut à `NULL`.

## Value

Un data.frame contenant les séjours hospitaliers. Attention: Les lignes
des tables MCO B et C peuvent être dupliquées. Les colonnes sont les
suivantes :

- `BEN_IDT_ANO` : Identifiant bénéficiaire anonymisé (seulement si
  patient_ids non nul)

- `NIR_ANO_17` : NIR anonymisé

- `EXE_SOI_DTD` : Date de début du séjour hospitalier

- `EXE_SOI_DTF` : Date de fin du séjour hospitalier

- `ETA_NUM` : Numéro FINESS e-PMSI

- `RSA_NUM` : N° d'index du RSA

- `SEJ_NUM` : N° de séjour

- `SEJ_NBJ` : Nombre de jours de séjour

- `NBR_DGN` : Nombre de diagnostics associés significatifs

- `NBR_RUM` : Nombre de RUM (unité médicales)

- `NBR_ACT` : Nombre d'actes

- `ENT_MOD` : Mode d'entrée

- `ENT_PRV` : Provenance

- `SOR_MOD` : Mode de sortie

- `SOR_DES` : Destination

- `DGN_PAL` : Diagnostic principal

- `DGN_REL` : Diagnostic relié

- `GRG_GHM` : Groupe homogène de malades

- `BDI_DEP` : Département de résidence

- `BDI_COD` : Code postal de résidence

- `COD_SEX` : Sexe

- `AGE_ANN` : Age en années

- `AGE_JOU` : Age en jours

- `DGN_PAL_UM` : Diagnostic principal des unité médicale

- `DGN_REL_UM` : Diagnostic relié des unité médicale

- `ASS_DGN` : Diagnostic associé

## Details

La sélection des séjours se fait à l'aide de filtres sur les
diagnostics:

- Si `dp_cim10_codes_filter` est renseigné, seuls les séjours dont les
  diagnostics principaux contiennent les codes CIM10 correspondants sont
  extraits.

- Si `or_dr_with_same_codes_filter` est renseigné, les séjours avec les
  codes DR correspondants sont également extraits.

- Si `or_da_with_same_codes_filter` est renseigné, les séjours avec les
  codes DA correspondants sont également extraits.

- Si `and_da_with_other_codes_filter` est renseigné, les séjours avec
  les codes DA différents sont également extraits.

Tous les diagnostics principaux, reliés et associés sont extraits pour
les séjours sélectionnés.

La fonction joint les tables T_MCO*B, T_MCO*C ensemble, puis joint
successivement à cette table "séjour" les tables T_MCO*D et T_MCO*UM.
Finalement, les deux tables obtenues sont concaténées horizontalement.
Il est donc fréquent d'avoir des doublons concernant les colonnes des
tables B et C dans les lignes de la table résultante. Une explication
détaillée et un diagramme illustrant le fonctionnement retenu sont
disponibles sur [le github du projet
Scalpel](https://github.com/X-DataInitiative/SCALPEL-Flattening/blob/DREES-104-DocFlattening/README_joins.md#the-pmsi-flattening).

## Examples

``` r
if (FALSE) { # \dontrun{
extract_hospital_stays(
  start_date =
    as.Date("2019-01-01"), end_date = as.Date("2019-12-31"), dp_cim10_codes =
    c("A00", "B00")
)  @export
} # }
```
