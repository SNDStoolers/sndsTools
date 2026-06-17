# 0002 — Table temporaire orpheline / test *flaky* dans `extract_stays_mcob`

- **Statut** : ✅ Corrigé
- **Fichier concerné** : `R/extract_stays_mcob.R` (fonction `extract_stays_mcob()`)
- **Tests concernés** : `tests/testthat/test-extract_stays_mcob.R`

## Symptôme

Échec **intermittent** (*flaky*) de la suite de tests :

```
Error in `.local(conn, name, value, ...)`:
  Table TMP_PATIENTS_IDS_20260617_103805 already exists.
  Set `overwrite = TRUE` if you want to remove the existing table.
```

Backtrace : `test-extract_stays_mcob.R:129` → `extract_stays_mcob()` →
`DBI::dbWriteTable(conn, patients_ids_table_name, patients_ids_filter)`.

Le test pouvait passer ou échouer d'une exécution à l'autre selon le *timing*.

## Cause racine

`extract_stays_mcob()`, lorsqu'un `patients_ids_filter` est fourni, crée une table
temporaire :

```r
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")           # résolution à la SECONDE
patients_ids_table_name <- glue::glue("TMP_PATIENTS_IDS_{timestamp}")
DBI::dbWriteTable(conn, patients_ids_table_name, patients_ids_filter)   # sans overwrite
```

Deux défauts cumulés :

1. **Écriture non idempotente** : `dbWriteTable()` sans `overwrite = TRUE` lève une
   erreur si la table existe déjà.
2. **Aucun nettoyage** : la table temporaire n'était **jamais** supprimée
   (aucun `dbRemoveTable`), contrairement à toutes les autres fonctions
   d'extraction.

Le nom n'étant horodaté qu'à la seconde, deux appels (ici deux `test_that` du même
fichier partageant le même fichier DuckDB, exécutés à quelques millisecondes
d'intervalle) tombent dans la même seconde → même nom de table → collision.

### Comparaison avec les autres fonctions

`extract_stays_mcob` était la **seule** fonction d'extraction à ne faire ni
`overwrite` ni nettoyage de sa table temporaire :

| Fonction | `overwrite = TRUE` | supprime la temp |
|----------|:---:|:---:|
| `extract_drugs_erphaf` | ✅ | ✅ |
| `extract_drugs_erucdf` | ✅ | ✅ |
| `extract_consultations_erprsf` | ❌ | ✅ |
| `extract_consultations_mcofcstc` | (drop avant write) | ✅ |
| `extract_longtermdiseases_irimbr` | ❌ | ✅ |
| **`extract_stays_mcob`** | **❌** | **❌** |

## Correctif

Alignement sur le patron déjà utilisé par les autres fonctions (notamment
`extract_consultations_erprsf`) :

1. Écriture idempotente :

```r
DBI::dbWriteTable(
  conn,
  patients_ids_table_name,
  patients_ids_filter,
  overwrite = TRUE
)
```

2. Nettoyage en fin de fonction (tant que la connexion est ouverte) :

```r
# nettoyage de la table temporaire des identifiants patients
if (!is.null(patients_ids_filter)) {
  DBI::dbRemoveTable(conn, patients_ids_table_name)
}
```

## Bénéfices

- Test déterministe (plus de collision de nom à la seconde).
- Plus de table temporaire orpheline laissée dans la base — comportement plus
  propre, y compris sur le portail CNAM (Oracle).

## Vérification

Après correctif : `[ FAIL 0 | WARN 4 | SKIP 1 | PASS 39 ]`, suite stable.
