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

- En local (sur votre ordinateur) : Télécharger [le fichier `sndsTool.R`
  de la dernière release du paquet disponible sur
  github](https://github.com/SNDStoolers/sndsTools/releases). Celui-ci
  contient toutes les fonctions du paquet.

- En local, ouvrir le fichier `sndsTool.R` et copier tout son contenu.

- Sur le portail CNAM, coller le contenu de ce fichier dans un nouveau
  script R `sndsTools.R`.

- Sur le portail CNAM, charger toutes les fonctions du paquet:
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
`sndsTools` inclut une fonction
[`connect_synthetic_snds()`](https://sndstoolers.github.io/sndsTools/reference/connect_synthetic_snds.md)
qui télécharge des données synthétiques du SNDS, les charge dans une
base de données DuckDB et retourne une connexion à cette base.

Ces données synthétiques sont basées sur le schéma SNDS 2019 et
contiennent des informations pour 50 patients fictifs.

NB: le premier appel de
[`connect_synthetic_snds()`](https://sndstoolers.github.io/sndsTools/reference/connect_synthetic_snds.md)
peut prendre plusieurs secondes, car il télécharge et traite les
données. Les appels suivants seront plus rapides, car les données seront
mises en cache localement.

``` r

# Télécharge les données synthétiques du SNDS et les charge dans une base DuckDB.
conn <- connect_synthetic_snds()
#> INFO [2026-06-17 12:03:05] Creating database at: /home/runner/.cache/sndsTools/synthetic_snds_parquet
#> INFO [2026-06-17 12:03:05] Télécharge la base synthétique du SNDS au chemin /home/runner/.cache/sndsTools/synthetic_snds_parquet.zip
DBI::dbListTables(conn)
#>   [1] "BE_IDE_R"          "CT_DEP_AAAA_GN"    "CT_IDE_AAAA_GN"   
#>   [4] "CT_IND_AAAA_GN"    "DA_PRA_R"          "ER_ANO_F"         
#>   [7] "ER_ARO_F"          "ER_BIO_F"          "ER_CAM_F"         
#>  [10] "ER_CPT_F"          "ER_DCT_F"          "ER_DTR_F"         
#>  [13] "ER_ETE_F"          "ER_INV_F"          "ER_LOT_F"         
#>  [16] "ER_PHA_F"          "ER_PRS_F"          "ER_RAT_F"         
#>  [19] "ER_TIP_F"          "ER_TRS_F"          "ER_UCD_F"         
#>  [22] "IR_ACS_R"          "IR_BEN_R"          "IR_ETM_R"         
#>  [25] "IR_IBA_R"          "IR_IMB_R"          "IR_MAT_R"         
#>  [28] "IR_MTT_R"          "IR_ORC_R"          "KI_CCI_R"         
#>  [31] "KI_ECD_R"          "T_HAD19A"          "T_HAD19B"         
#>  [34] "T_HAD19C"          "T_HAD19D"          "T_HAD19DMPA"      
#>  [37] "T_HAD19DMPP"       "T_HAD19E"          "T_HAD19EHPA"      
#>  [40] "T_HAD19FA"         "T_HAD19FB"         "T_HAD19FC"        
#>  [43] "T_HAD19FH"         "T_HAD19FI"         "T_HAD19FL"        
#>  [46] "T_HAD19FM"         "T_HAD19FP"         "T_HAD19GJ"        
#>  [49] "T_HAD19GRE"        "T_HAD19GRP"        "T_HAD19LEG"       
#>  [52] "T_HAD19MED"        "T_HAD19MEDATU"     "T_HAD19MEDCHL"    
#>  [55] "T_HAD19MON"        "T_HAD19S"          "T_HAD19STC"       
#>  [58] "T_MCO19A"          "T_MCO19B"          "T_MCO19BPHN"      
#>  [61] "T_MCO19C"          "T_MCO19CSTC"       "T_MCO19D"         
#>  [64] "T_MCO19DIALP"      "T_MCO19DMIP"       "T_MCO19E"         
#>  [67] "T_MCO19FA"         "T_MCO19FASTC"      "T_MCO19FB"        
#>  [70] "T_MCO19FBSTC"      "T_MCO19FC"         "T_MCO19FCSTC"     
#>  [73] "T_MCO19FH"         "T_MCO19FHSTC"      "T_MCO19FI"        
#>  [76] "T_MCO19FL"         "T_MCO19FLSTC"      "T_MCO19FM"        
#>  [79] "T_MCO19FMSTC"      "T_MCO19FP"         "T_MCO19FPSTC"     
#>  [82] "T_MCO19GVxx"       "T_MCO19IVG"        "T_MCO19LEG"       
#>  [85] "T_MCO19MED"        "T_MCO19MEDATU"     "T_MCO19MEDTHROMBO"
#>  [88] "T_MCO19ORP"        "T_MCO19PIE"        "T_MCO19PIP"       
#>  [91] "T_MCO19PORG"       "T_MCO19STC"        "T_MCO19SUP_BPHNA" 
#>  [94] "T_MCO19SUP_BPHNC"  "T_MCO19SUP_BPHNP"  "T_MCO19SUP_CES"   
#>  [97] "T_MCO19SUP_FFM"    "T_MCO19SUP_LACT"   "T_MCO19SUP_PPCO"  
#> [100] "T_MCO19SUP_SMUR"   "T_MCO19SUP_USMP"   "T_MCO19UM"        
#> [103] "T_MCO19UPGV"       "T_MCO19VALO"       "T_MCO19VALOACE"   
#> [106] "T_MCO19Z"          "T_RIP19C"          "T_RIP19CCAM"      
#> [109] "T_RIP19E"          "T_RIP19FA"         "T_RIP19FB"        
#> [112] "T_RIP19FC"         "T_RIP19FH"         "T_RIP19FI"        
#> [115] "T_RIP19FL"         "T_RIP19FM"         "T_RIP19FP"        
#> [118] "T_RIP19ISOCONT"    "T_RIP19R3A"        "T_RIP19R3AD"      
#> [121] "T_RIP19RSA"        "T_RIP19RSAD"       "T_RIP19S"         
#> [124] "T_RIP19STC"        "T_SSR19A"          "T_SSR19B"         
#> [127] "T_SSR19C"          "T_SSR19CCAM"       "T_SSR19CCAR"      
#> [130] "T_SSR19CMC"        "T_SSR19CSARR"      "T_SSR19CSTC"      
#> [133] "T_SSR19D"          "T_SSR19E"          "T_SSR19FA"        
#> [136] "T_SSR19FASTC"      "T_SSR19FB"         "T_SSR19FBSTC"     
#> [139] "T_SSR19FC"         "T_SSR19FCSTC"      "T_SSR19FH"        
#> [142] "T_SSR19FI"         "T_SSR19FL"         "T_SSR19FLSTC"     
#> [145] "T_SSR19FM"         "T_SSR19FMSTC"      "T_SSR19FP"        
#> [148] "T_SSR19GHJ"        "T_SSR19GME"        "T_SSR19LEG"       
#> [151] "T_SSR19MED"        "T_SSR19MEDATU"     "T_SSR19S"         
#> [154] "T_SSR19STC"        "T_SUP19ALD"        "T_SUP19ATU"       
#> [157] "T_SUP19BPHN"       "T_SUP19DMI"        "T_SUP19FFM"       
#> [160] "T_SUP19IVG"        "T_SUP19MON"        "user_synonyms"
```

#### Exemple basique d’extraction de données (consultations de chirurgie vasculaire)

``` r

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

| BEN_NIR_PSA | EXE_SOI_DTD | PSE_SPE_COD | PFS_EXE_NUM | PRS_NAT_REF | PRS_ACT_QTE | BEN_RNG_GEM |
|:---|:---|---:|:---|---:|---:|---:|
| PEyUrNJzINkmgxwUz | 2019-12-23 | 48 | HKcvLcRye | 2132 | 1 | 3 |

``` r


# Fermer la connexion à la base de données en fin de programme
conn |> DBI::dbDisconnect()
```
