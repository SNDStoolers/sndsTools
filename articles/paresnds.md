# Prise en main

## A quoi sert ce paquet R de traitement de données ?

Ce paquet R de traitement de données a pour objectif de faciliter
l’accès aux données du Système National des Données de Santé (SNDS) pour
les utilisateurs de R. Il permet de simplifier les extractions de
données et de mettre à disposition des fonctions implémentants les
bonnes pratiques pour utiliser ces données.

## Prise en main rapide

### Installation

#### Sur le portail CNAM

Il est nécessaire de copier/coller le code source du paquet sur le
portail CNAM. Pour cela, il faut suivre les étapes suivantes :

- 1.  En local (sur votre ordinateur) : Télécharger [le fichier
      `sndsTool.R` de la dernière release du paquet disponible sur
      github](https://github.com/SNDStoolers/sndsTools/releases).
      Celui-ci contient toutes les fonctions du paquet.
- 2.  En local, ouvrir le fichier `sndsTool.R` et copier tout son
      contenu.
- 3.  Sur le portail CNAM, coller le contenu de ce fichier dans un
      nouveau script R `sndsTools.R`.
- 4.  Sur le portail CNAM, charger toutes les fonctions du paquet:
      `source("sndsTools.R")`

NB: La version la plus à jour de `sndsTools.R` (entre deux releases) est
disponible comme artifact [sur le dépôt GitHub sur la page de
l’action](https://github.com/SNDStoolers/sndsTools/actions/workflows/concat-r-files.yaml).
Attention, cette version peut être instable, il est recommandé
d’utiliser une release stable du paquet.

#### En local (pour le développement du paquet uniquement)

Ouvrir le paquet avec Rstudio, puis lancer :

``` r
devtools::install(dependencies = TRUE)
```

Puis pour charger le paquet :

``` r
library(sndsTools)
```

### Utilisation

Pour les besoins de formation, développement et test, le paquet
`sndsTools` inclut une fonction `connect_synthetic_snds()` qui
télécharge des données synthétiques du SNDS, les charge dans une base de
données DuckDB et retourne une connexion à cette base. Ces données
synthétiques sont basées sur le schéma SNDS 2019 et contiennent des
informations pour 50 patients fictifs.

NB: le premier appel de `connect_synthetic_snds()` peut prendre
plusieurs secondes, car il télécharge et traite les données. Les appels
suivants seront plus rapides, car les données seront mises en cache
localement.

``` r
library(sndsTools)
# Télécharger les données synthétiques du SNDS et les charger dans une base DuckDB. On se limite à la table ER_PRS_F pour gagner du temps.
conn <- connect_synthetic_snds(
  subset_tables = c(
    "ER_PRS_F"
  ),
  force_insert = TRUE
)
#> INFO [2026-04-27 11:39:51] Creating database at: /home/runner/.cache/sndsTools/synthetic_snds.duckdb
#> INFO [2026-04-27 11:40:05] All files downloaded and extracted to: /home/runner/.cache/sndsTools
#> Warning: The following named parsers don't match the column names: AMC_ECL_TOP,
#> BEN_C2S_TYP, PCB_FOR_AMC, PEN_TYP_COD, PRE_JOU_NBR, PRS_DRA_DTD, PRS_FAC_TOP,
#> PRS_TYP_MIN, PRS_ZON_FIL, PSE_PPS_CLE, PSE_PPS_NUM
#> Warning: One or more parsing issues, call `problems()` on your data frame for details,
#> e.g.:
#>   dat <- vroom(...)
#>   problems(dat)
#> INFO [2026-04-27 11:40:06] Successfully loaded 2 tables: ER_PRS_F, user_synonyms
# Afficher les tables disponibles dans la base DuckDB
DBI::dbListTables(conn)
#> [1] "ER_PRS_F"      "user_synonyms"
```

#### Exemple basique d’extraction de données

Extraction des consultations de chirurgie vasculaire :

``` r
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union

consultations_df <- extract_consultations_erprsf(
  conn = conn,
  start_date = as.Date("2011-01-01"),
  end_date = as.Date("2019-12-31"),
  pse_spe_filter = c(48)
)
#> Extracting consultations
#> from all specialties among
#> 48...
consultations_df |> knitr::kable()
```

| BEN_NIR_PSA       | EXE_SOI_DTD | PSE_SPE_COD | PFS_EXE_NUM | PRS_NAT_REF | PRS_ACT_QTE | BEN_RNG_GEM |
|:------------------|:------------|------------:|:------------|------------:|------------:|------------:|
| PEyUrNJzINkmgxwUz | 2019-12-23  |          48 | HKcvLcRye   |        2132 |           1 |           3 |

``` r

conn |> DBI::dbDisconnect() # Ne pas oublier de fermer la connexion à la base de données une fois que vous avez fini de l'utiliser
```
