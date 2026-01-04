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

Pour une utilisation sur le portail CNAM, il est nécessaire de
copier/coller le code source du paquet sur le portail CNAM. Pour cela,
il faut suivre les étapes suivantes :

``` r
## 1. En local (sur votre ordinateur) : Copier le fichier contenant toutes les fonctions: [sndsTools_all.R](https://github.com/SNDStoolers/sndsTools/sndsTools_all.R)
## 2. Sur le portail CNAM, coller le fichier sndsTools.R sur le portail CNAM
## 3. Sur le portail CNAM, charger toutes les fonctions du paquet:
source("sndsTools_all.R")
```

#### En local (pour le développement du paquet)

Ouvrir le paquet avec Rstudio, puis lancer :

``` r
devtools::install(dependencies = TRUE)
```

Puis pour charger le paquet :

``` r
library(sndsTools)
```
