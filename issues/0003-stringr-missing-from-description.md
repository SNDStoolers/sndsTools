# 0003 — `stringr` utilisé mais absent des `Imports` du `DESCRIPTION`

- **Statut** : ✅ Corrigé
- **Fichier concerné** : `DESCRIPTION`
- **Origine** : utilisé dans `R/synthetic_data.R`

## Symptôme

Le package utilise `stringr::` dans `R/synthetic_data.R` :

- `stringr::str_detect()` (sélection des CSV via `subset_tables`)
- `stringr::str_starts()` / `stringr::str_replace()` (normalisation des noms de
  tables PMSI)

mais `stringr` ne figurait pas dans la section `Imports:` du `DESCRIPTION`.

Aucune erreur visible en l'état car `stringr` est installé en **dépendance
transitive** (tiré par d'autres paquets). Mais c'est une dépendance non déclarée :

- `R CMD check` / `devtools::check()` émet un WARNING
  (« '::' or ':::' import not declared from: 'stringr' ») ;
- l'installation peut échouer dans un environnement où `stringr` n'est pas déjà
  présent (le portail CNAM charge `sndsTools.R` par concaténation, donc les
  fonctions s'exécutent en supposant `stringr` disponible).

## Correctif

Ajout de `stringr` à la section `Imports:` du `DESCRIPTION` :

```
Imports:
    ...
    readr,
    stringr
```

## Vérification

`grep -rn "stringr" R/` ne référence plus que `R/synthetic_data.R`, désormais
couvert par la déclaration `Imports`.
