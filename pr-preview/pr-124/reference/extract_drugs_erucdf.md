# Extrait les dispensations de médicaments en accès précoces depuis le DCIR.

Cette fonction permet d'extraire les dispensations de médicaments en
accès précoces réalisés en hospitalisation privée (ex-OQN) ou en
rétrocession hospitalière privée et publique (ex-OQN et ex-DGF). Les
dispensations dont les dates `EXE_SOI_DTD` sont comprises entre
`start_date` et `end_date` (incluses) sont extraites.

## Usage

``` r
extract_drugs_erucdf(
  conn,
  start_date,
  end_date,
  ucd_codes_filter = NULL,
  patients_ids_filter = NULL,
  dis_dtd_lag_months = 6,
  sup_columns = NULL
)
```

## Arguments

- conn:

  DBI connection. Une connexion à la base de données Oracle.

- start_date:

  Date. La date de début de la période des dispensations à extraire.

- end_date:

  Date. La date de fin de la période des dispensations à extraire.

- ucd_codes_filter:

  Character vector (Optionnel). Les codes UCD des dispensations de
  médicaments à extraire. Attention, les codes UCD doivent être fournis
  au format UCD 7 caractères préfixé de 6 zéros : "0000009419723". Ce
  format est celui utilisé dans la base de données. Si NULL, extrait
  tous les codes.

- patients_ids_filter:

  data.frame (Optionnel). Un data.frame contenant les paires
  d'identifiants des patients pour lesquels les délivrances de
  médicaments doivent être extraites. Les colonnes de ce data.frame
  doivent être "BEN_IDT_ANO", "BEN_NIR_PSA" et "BEN_RNG_GEM". Les
  "BEN_NIR_PSA" doivent être tous les "BEN_NIR_PSA" associés aux
  "BEN_IDT_ANO" fournis. Défaut à NULL.

- dis_dtd_lag_months:

  Integer (Optionnel). Le nombre maximum de mois de décalage de
  FLX_DIS_DTD par rapport à EXE_SOI_DTD pris en compte pour récupérer
  les dispensations de médicaments. Défaut à 6 mois.

- sup_columns:

  Character vector (Optionnel). Les colonnes supplémentaires à ajouter à
  la table de sortie. Défaut à NULL, donc aucune colonne ajoutée.

## Value

Retourne une lazy table contenant les dispensations de médicaments en
accès précoces. Les colonnes de la table de sortie sont :

- BEN_NIR_PSA : Colonne présente uniquement si les identifiants patients
  (`patients_ids_filter`) ne sont pas fournis. Identifiant SNDS, aussi
  appelé pseudo-NIR.

- BEN_IDT_ANO : Colonne présente uniquement si les identifiants patients
  (`patients_ids_filter`) sont fournis. Numéro d'inscription au
  répertoire (NIR) anonymisé.

- BEN_RNG_GEM : Colonne présente uniquement si les identifiants patients
  (`patients_ids_filter`) ne sont pas fournis. Rang GEM.

- EXE_SOI_DTD : Date de la prestation

- EXE_SOI_DTF : Heure de la prestation

- PRS_NAT_REF : Code de la nature de la prestation

- UCD_TOP_UCD : Circuit de délivrance

- UCD_UCD_COD : Code UCD du médicament

- UCD_DLV_NBR : Nombre de délivrances

- Les colonnes supplémentaires spécifiées dans `sup_columns` si
  fournies.

## Details

Le décalage de remontée des données est pris en compte en récupérant
également les dispensations dont les dates `FLX_DIS_DTD` sont comprises
dans les `dis_dtd_lag_months` mois suivant end_date.

NB: La jointure avec la table établissement est faite avec un
inner_join. On ne garde que les AP prescrites en établissement.

## See also

Other extract:
[`extract_consultations_erprsf()`](https://sndstoolers.github.io/sndsTools/reference/extract_consultations_erprsf.md),
[`extract_consultations_mcofcstc()`](https://sndstoolers.github.io/sndsTools/reference/extract_consultations_mcofcstc.md),
[`extract_deaths()`](https://sndstoolers.github.io/sndsTools/reference/extract_deaths.md),
[`extract_drugs_erphaf()`](https://sndstoolers.github.io/sndsTools/reference/extract_drugs_erphaf.md),
[`extract_ij_erprsf()`](https://sndstoolers.github.io/sndsTools/reference/extract_ij_erprsf.md),
[`extract_longtermdiseases_irimbr()`](https://sndstoolers.github.io/sndsTools/reference/extract_longtermdiseases_irimbr.md),
[`extract_stays_mcob()`](https://sndstoolers.github.io/sndsTools/reference/extract_stays_mcob.md),
[`extract_stays_ssr()`](https://sndstoolers.github.io/sndsTools/reference/extract_stays_ssr.md),
[`snds_codes()`](https://sndstoolers.github.io/sndsTools/reference/snds_codes.md)

## Examples

``` r
if (FALSE) { # \dontrun{
start_date <- as.Date("2019-01-01")
end_date <- as.Date("2019-12-31")
ucd_codes <- c("0000009419723")
conn <- connect_oracle()

result <- extract_drugs_erucdf(
  conn = conn,
  start_date = start_date,
  end_date = end_date,
  ucd_codes_filter = ucd_codes
)
} # }
```
