# Extraction des consultations dans le DCIR.

Cette fonction permet d'extraire les consultations dans le DCIR. Les
consultations dont les dates `EXE_SOI_DTD` sont comprises entre
`start_date` et `end_date` (incluses) sont extraites.

## Usage

``` r
extract_consultations_erprsf(
  start_date,
  end_date,
  pse_spe_filter = NULL,
  prestation_filter = NULL,
  analyse_couts = FALSE,
  dis_dtd_lag_months = 6,
  patients_ids_filter = NULL,
  output_table_name = NULL,
  conn = NULL
)
```

## Arguments

- start_date:

  Date. La date de début de la période des consultations à extraire.

- end_date:

  Date. La date de fin de la période des consultations à extraire.

- pse_spe_filter:

  Character vector (Optionnel). Les codes spécialités des médecins
  (référentiel `IR_SPE_V`) effectuant les consultations à extraire. Si
  `pse_spe_filter` n'est pas fourni, les consultations de tous les
  spécialités sont extraites. Défaut à `NULL`.

- prestation_filter:

  Character vector (Optionnel). Les codes des prestations à extraire en
  norme B5 (colonne `PRS_NAT_REF`, référentiel `IR_NAT_V`). Si
  `prestation_filter` n'est pas fourni, les consultations de tous les
  prestations sont extraites. Les codes des prestations sont disponibles
  sur la page ["Cibler selon les natures de
  prestations"](https://documentation-snds.health-data-hub.fr/snds/fiches/prestation.html)
  de la documentation SNDS. Défaut à `NULL`.

- analyse_couts:

  Logical (Optionnel). Si `TRUE`, les filtres de qualité liés aux coûts,
  écartant les actes en majorations sont ignorés. Utile pour des
  analyses portant sur les coûts. Défaut à `FALSE`.

- dis_dtd_lag_months:

  Integer (Optionnel). Le nombre maximum de mois de décalage de
  `FLX_DIS_DTD` par rapport à `EXE_SOI DTD` pris en compte pour
  récupérer les consultations. Défaut à 6 mois.

- patients_ids_filter:

  data frame (Optionnel). Un data frame contenant les paires
  d'identifiants des patients pour lesquels les consultations doivent
  être extraites. Les colonnes de ce data frame doivent être
  `BEN_IDT_ANO`, `BEN_NIR_PSA` et `BEN_RNG_GEM`. Les BEN_NIR_PSA doivent
  être tous les BEN_NIR_PSA associés aux BEN_IDT_ANO fournis. Défaut à
  `NULL`.

- output_table_name:

  Character (Optionnel). Si fourni, les résultats seront sauvegardés
  dans une table portant ce nom dans la base de données au lieu d'être
  retournés sous forme de data frame. Si cette table existe déjà, le
  programme s'arrête avec un message d'erreur. Défaut à `NULL`.

- conn:

  DBI connection (Optionnel). Une connexion à la base de données Oracle.
  Par défaut, une connexion est établie avec oracle.

## Value

Si `output_table_name` est `NULL`, retourne un data frame contenant les
consultations. Si `output_table_name` est fourni, sauvegarde les
résultats dans la table spécifiée dans Oracle et retourne `NULL` de
manière invisible. Dans les deux cas les colonnes de la table de sortie
sont :

- `BEN_NIR_PSA` : Colonne présente uniquement si les identifiants
  patients (`patients_ids_filter`) ne sont pas fournis. Identifiant
  SNDS, aussi appelé pseudo-NIR.

- `BEN_IDT_ANO` : Colonne présente uniquement si les identifiants
  patients (`patients_ids_filter`) sont fournis. Numéro d’inscription au
  répertoire (NIR) anonymisé.

- `EXE_SOI_DTD` : Date de la consultation.

## Details

Le décalage de remontée des données est pris en compte en récupérant
également les consultations dont les dates `FLX_DIS_DTD` sont comprises
dans les `dis_dtd_lag_months` mois suivant `end_date`.

Si `patients_ids_filter` est fourni, seules les consultations pour les
patients dont les identifiants sont dans `patients_ids_filter` sont
extraites. Dans le cas contraire, les consultations de tous les patients
sont extraites.

Pour être à flux constant sur l'ensemble des années, il faut utiliser
`dis_dtd_lag_months = 27` Cela rallonge le temps d'extraction alors que
l'impact sur l'extraction est minime car [la Cnam estime que 99 % des
soins sont remontés à 6
mois](https://documentation-snds.health-data-hub.fr/snds/formation_snds/initiation/schema_relationnel_snds.html#_3-3-2-2-dates)
c'est-à-dire pour `dis_dtd_lag_months = 6`.

Un guide sur l'activité des médecins libéraux est disponibles sur la
page [Activité des médecins
libéraux](https://documentation-snds.health-data-hub.fr/snds/fiches/activite_medecins.html#contexte).

## See also

Other extract: [`extract_drug_dispenses()`](extract_drug_dispenses.md),
[`extract_hospital_consultations()`](extract_hospital_consultations.md),
[`extract_hospital_stays()`](extract_hospital_stays.md),
[`extract_long_term_disease()`](extract_long_term_disease.md)

## Examples

``` r
if (FALSE) { # \dontrun{
dispenses <- extract_consultations_erprsf(
  start_date = as.Date("2010-01-01"),
  end_date = as.Date("2010-01-03"),
  pse_spe_filter = c("0", "00", "36")
)
} # }
```
