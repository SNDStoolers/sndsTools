# 0001 — Échec de décompression des données synthétiques (noms de fichiers non-UTF-8) sur macOS/Linux

- **Statut** : ✅ Corrigé
- **Fichier concerné** : `R/synthetic_data.R` (fonction `download_synthetic_snds_csv()`)
- **Tests concernés** : `tests/testthat/test-synthetic-data.R`

## Symptôme

L'exécution de la suite de tests (ou tout appel à `connect_synthetic_snds()` /
`download_synthetic_snds_csv()`) échouait sur macOS/Linux avec :

```
Error in `utils::unzip(zip_path, exdir = expected_dir)`:
  cannot open file '/Users/.../.cache/sndsTools/Causes_de_Deces/Causes de d�c�s/KI_CCI_R.csv':
  No such file or directory
```

3 tests en échec : `[ FAIL 3 | WARN 0 | SKIP 1 | PASS 34 ]`.

## Cause racine

`download_synthetic_snds_csv()` télécharge 9 archives ZIP depuis data.gouv.fr puis
les décompresse. L'archive `Causes_de_Deces` contient un sous-dossier nommé
**`Causes de décès/`**.

Ce nom est stocké dans le ZIP en encodage **Latin-1 / CP437** (`é` = octet `0xE9`,
`è` = octet `0xE8`), **sans** le drapeau « UTF-8 filename » (bit 11 de l'en-tête ZIP).

Sur macOS (APFS) et Linux, les noms de fichiers doivent être de l'UTF-8 valide.
Les octets Latin-1 isolés ne le sont pas → la création du dossier échoue :

- `utils::unzip()` (dézippeur interne de R) : crée un chemin avec des caractères
  de remplacement (`d�c�s`) puis n'arrive plus à ouvrir le fichier → erreur.
- `/usr/bin/unzip` (Info-ZIP d'Apple) : `checkdir error: ... Illegal byte sequence`.
- `unzip -O CP437` : option non supportée par le build Apple.
- `ditto -x -k` : décode (à tort) en CP437 → crée `Causes de dÇcäs/` (nom erroné).

Le code ne gérait ce cas que **sous Windows**, via un appel externe à PowerShell
(`Expand-Archive`). Sur tout autre OS il retombait sur `utils::unzip()` nu, d'où
le plantage.

## Investigation

Comportement vérifié empiriquement sur l'archive `Causes_de_Deces` :

| Méthode | Résultat |
|---------|----------|
| `utils::unzip()` (défaut) | ❌ `cannot open file` |
| `/usr/bin/unzip` | ❌ `Illegal byte sequence` |
| `/usr/bin/unzip -O CP437` | ❌ option non supportée (build Apple) |
| `ditto -x -k` | ⚠️ extrait mais nom erroné (`dÇcäs`) |
| `utils::unzip(junkpaths = TRUE)` | ✅ extrait `KI_CCI_R.csv`, `KI_ECD_R.csv` |

Point clé observé dans le code aval (`connect_synthetic_snds()`) :

```r
csv_files <- list.files(dir2db, pattern = "\\.csv$", recursive = TRUE, full.names = TRUE)
table_name <- tools::file_path_sans_ext(basename(csv_file))   # ex. "KI_CCI_R"
```

→ **seul le `basename` (ASCII) du CSV est utilisé**. Le nom accentué du
sous-dossier intermédiaire n'intervient jamais.

## Correctif

Remplacement de tout le bloc conditionnel par OS par un unique appel R pur,
identique sur tous les systèmes :

```r
utils::unzip(zip_path, exdir = expected_dir, junkpaths = TRUE)
```

`junkpaths = TRUE` ignore l'arborescence interne de l'archive et écrit chaque
fichier sous son seul nom de base (ASCII) directement dans `expected_dir/`. Le
sous-dossier accentué est ainsi entièrement contourné.

### Pourquoi c'est correct

- En aval, les CSV sont retrouvés par `list.files(..., recursive = TRUE)` et la
  table est nommée d'après le `basename` : la structure interne du ZIP est sans
  importance.
- **Seul risque** de `junkpaths` : une collision de `basename` au sein d'une
  même archive. Vérifié sur les 9 archives → aucune collision (`total == uniques`
  pour chaque ZIP).

### Bénéfice annexe

Suppression de la dépendance à un processus externe (PowerShell) sur Windows.
Le même code R pur traite désormais tous les OS de façon identique.

## Vérification

Après correctif : `[ FAIL 0 | WARN 4 | SKIP 1 | PASS 39 ]`. Les CSV de
`Causes_de_Deces` se chargent et se relisent correctement (KI_CCI_R : 2×49).
