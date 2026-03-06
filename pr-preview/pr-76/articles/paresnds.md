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
