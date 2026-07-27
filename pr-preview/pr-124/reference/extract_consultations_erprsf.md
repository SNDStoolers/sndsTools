# Extraction des consultations dans le DCIR.

Cette fonction permet d'extraire les consultations dans le DCIR. Les
consultations dont les dates `EXE_SOI_DTD` sont comprises entre
`start_date` et `end_date` (incluses) sont extraites.

## Usage

``` r
extract_consultations_erprsf(
  conn,
  start_date,
  end_date,
  pse_spe_filter = NULL,
  prestation_filter = NULL,
  patients_ids_filter = NULL,
  analyse_couts = FALSE,
  dis_dtd_lag_months = 6,
  sup_columns = NULL
)
```

## Arguments

- conn:

  DBI connection. Une connexion à la base de données Oracle.

- start_date:

  Date. La date de début de la période des consultations à extraire.

- end_date:

  Date. La date de fin de la période des consultations à extraire.

- pse_spe_filter:

  Character vector (Optionnel). Les codes spécialités des médecins
  (référentiel `IR_SPE_V`) effectuant les consultations à extraire.
  Défaut à `NULL`.

- prestation_filter:

  Character vector (Optionnel). Les codes des prestations à extraire en
  norme B5 (colonne `PRS_NAT_REF`, référentiel `IR_NAT_V`). Défaut à
  `NULL`.

- patients_ids_filter:

  data.frame (Optionnel). Un data.frame contenant les paires
  d'identifiants des patients pour lesquels les consultations doivent
  être extraites. Les colonnes de ce data.frame doivent être
  "BEN_IDT_ANO", "BEN_NIR_PSA" et "BEN_RNG_GEM". Les "BEN_NIR_PSA"
  doivent être tous les "BEN_NIR_PSA" associés aux "BEN_IDT_ANO"
  fournis. Défaut à `NULL`.

- analyse_couts:

  Logical (Optionnel). Si `TRUE`, les filtres de qualité liés aux coûts,
  écartant les actes en majorations sont ignorés. Utile pour des
  analyses portant sur les coûts. Défaut à `FALSE`.

- dis_dtd_lag_months:

  Integer (Optionnel). Le nombre maximum de mois de décalage de
  FLX_DIS_DTD par rapport à EXE_SOI DTD pris en compte pour récupérer
  les consultations. Défaut à 6 mois.

- sup_columns:

  Character vector (Optionnel). Les colonnes supplémentaires à ajouter à
  la table de sortie. Défaut à NULL, donc aucune colonne ajoutée.

## Value

Retourne une lazy table contenant les consultations. Les colonnes de la
table de sortie sont :

- BEN_NIR_PSA : Colonne présente uniquement si les identifiants patients
  (`patients_ids_filter`) ne sont pas fournis. Identifiant SNDS, aussi
  appelé pseudo-NIR.

- BEN_IDT_ANO : Colonne présente uniquement si les identifiants patients
  (`patients_ids_filter`) sont fournis. Numéro d'inscription au
  répertoire (NIR) anonymisé.

- EXE_SOI_DTD : Date de la consultation.

## Details

Le décalage de remontée des données est pris en compte en récupérant
également les consultations dont les dates `FLX_DIS_DTD` sont comprises
dans les `dis_dtd_lag_months` mois suivant end_date.

Si `patients_ids_filter` est fourni, seules les consultations pour les
patients dont les identifiants sont dans `patients_ids_filter` sont
extraites. Dans le cas contraire, les consultations de tous les patients
sont extraites.

Pour être à flux constant sur l'ensemble des années, il faut utiliser
`dis_dtd_lag_months` = 27 Cela rallonge le temps d'extraction alors que
l'impact sur l'extraction est minime car [la Cnam estime que 99 % des
soins sont remontés à 6
mois](https://documentation-snds.health-data-hub.fr/snds/formation_snds/initiation/schema_relationnel_snds.html#_3-3-dcir),
c'est-à-dire pour dis_dtd_lag_months = 6.

## See also

Other extract:
[`extract_consultations_mcofcstc()`](https://sndstoolers.github.io/sndsTools/reference/extract_consultations_mcofcstc.md),
[`extract_deaths()`](https://sndstoolers.github.io/sndsTools/reference/extract_deaths.md),
[`extract_drugs_erphaf()`](https://sndstoolers.github.io/sndsTools/reference/extract_drugs_erphaf.md),
[`extract_drugs_erucdf()`](https://sndstoolers.github.io/sndsTools/reference/extract_drugs_erucdf.md),
[`extract_longtermdiseases_irimbr()`](https://sndstoolers.github.io/sndsTools/reference/extract_longtermdiseases_irimbr.md),
[`extract_stays_mcob()`](https://sndstoolers.github.io/sndsTools/reference/extract_stays_mcob.md),
[`extract_stays_ssr()`](https://sndstoolers.github.io/sndsTools/reference/extract_stays_ssr.md)

## Examples

``` r
if (FALSE) { # \dontrun{
start_date <- as.Date("2010-01-01")
end_date <- as.Date("2010-01-03")
conn <- connect_oracle()
consultations <- extract_consultations_erprsf(
 conn = conn,
  start_date = start_date,
  end_date = end_date,
  pse_spe_filter = c("0", "00", "36")
)
} # }
```
