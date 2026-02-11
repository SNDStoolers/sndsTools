[![codecov](https://codecov.io/gh/sndstoolers/sndsTools/graph/badge.svg?token=NKPHJFLAN8)](https://codecov.io/gh/sndstoolers/sndsTools)
[![GitHub release](https://img.shields.io/github/v/release/SNDStoolers/sndsTools)](https://github.com/SNDStoolers/sndsTools/releases/latest)
[![Documentation](https://img.shields.io/badge/docs-pkgdown-blue.svg)](https://sndstoolers.github.io/sndsTools/)

# `sndsTools` : Extraction de recours aux soins dans le SNDS avec R

## Description

Ce package R permet d'extraire des données de recours aux soins du SNDS (Système National des Données de Santé) pour une population donnée.

## Fonctionnalités

Ce package R simplifie les étapes d'extraction de données du SNDS sur des données utilisées dans la majorité des études sur le SNDS. Les principales fonctionnalités couvertes sont les suivantes :

- Effectuer l'extraction des tables individuelles pour les données suivantes :
    - Consultations dans le DCIR,
    - Médicaments dans le DCIR,
    - Affections de longue durée (ALD),
    - Hospitalisations dans le MCO,
    - Consultations dans le MCO.

- Intègre les requêtes mois par mois sur la date de flux pour les données DCIR conformément aux recommandations de la CNAM.

- Intègre les filtres qualités usuels pour exclure les lignes indésirables (ex. `PRS_DPN_QLP != 71` pour [exclure les remontées pour information dans le DCIR](https://documentation-snds.health-data-hub.fr/snds/fiches/sas_prestation_dcir.html#recommandations-pour-les-requetes)).

## Historique

Ce projet a été initié suite à la rencontre de plusieurs utilisateurs du SNDS lors du congrès Emois en mars 2024. Il est actuellement en phase de développement actif.

C'est un projet communautaire, évolutif par nature, qui vise à rassembler les différents utilisateurs du SNDS.

## Installation sur le portail de l'assurance maladie (CNAM)

Il est nécessaire de copier/coller le code source du paquet sur le portail CNAM. Pour cela, il faut suivre les étapes suivantes :

- 1. En local (sur votre ordinateur) : Télécharger [le fichier `sndsTool.R` de la dernière release du paquet disponible sur github](https://github.com/SNDStoolers/sndsTools/releases). Celui-ci contient toutes les fonctions du paquet.

- 2. En local, ouvrir le fichier `sndsTool.R` et copier tout son contenu.

- 3. Sur le portail CNAM, coller le contenu de ce fichier dans un nouveau script R `sndsTools.R`.

- 4. Sur le portail CNAM, charger toutes les fonctions du paquet: `source("sndsTools.R")`

## Contexte technique

### Données

Les données sont issues du SNDS et sont hébergées sur le [portail de l'assurance maladie (CNAM)](https://portail.sniiram.ameli.fr/). Pour mener utiliser ce package, il est nécessaire d'avoir un accès aux [données individuelles bénéficiaires exhaustives de consommation de soins](https://documentation-snds.health-data-hub.fr/snds/formation_snds/documents_cnam/guides_pedagogiques_snds/guide_pedagogique_acces_permanents.html#qui-a-acces-au-snds-et-a-quelles-donnees).

###  Schéma de flux de données

TODO (figure à mettre dans man/figures)

### Technologies

- Langage de programmation : R
- Packages utilisés : dplyr, dbplyr, DBI, glue, lubridate, progress

## Liens utiles

- **lien vers cette page de la documentation** : [https://sndstoolers.github.io/sndsTools/index.html](https://sndstoolers.github.io/sndsTools/index.html)

- **Dépôt du code source** : [https://github.com/SNDStoolers/sndsTools](https://github.com/SNDStoolers/sndsTools)

- **Description des extractions et des tables de données créées** : TODO [Flux de données](data.html)

- **Prise en main rapide** : [Prise en main]([sndsTools.html](https://sndstoolers.github.io/sndsTools/articles/paresnds.html))

- [Référence]([reference/index.html](https://sndstoolers.github.io/sndsTools/reference/index.html)) des fonctions utilisées

- [Guide de contribution]([contributing.html](https://sndstoolers.github.io/sndsTools/articles/contribuer.html))

- [Principes de gouvernance]([gouvernance.html](https://sndstoolers.github.io/sndsTools/articles/gouvernance.html))
