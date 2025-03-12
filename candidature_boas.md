# Appel à projet BOAS

## Description synthétique du projet (10 lignes max)

L'exploitation des données du Système National des Données de Santé (SNDS) présente de nombreux défis techniques : complexité des tables et de leur évolution dans le temps, requêtes nécessitant une expertise approfondie des données, temps d'extraction souvent longs, et implémentation hétérogènes des bonnes pratiques (filtres qualité, requêtes mois par mois). Ces obstacles conduisent à une duplication des efforts entre les organisations, chacune développant ses propres outils d'extraction non standardisés, augmentant les risques d'erreurs et limitant la reproductibilité des analyses. Sans solution commune, les analystes du SNDS consacrent un temps considérable à des tâches d'ingénierie de données plutôt qu'à l'analyse des données de santé.

Le projet sndsTools est une librairie R (package) open-source qui simplifie l'extraction des données du SNDS. Initié suite à une rencontre d'utilisateurs du SNDS lors du congrès d'épidémiologie EMOIS 2024, ce projet communautaire vise à rassembler différentes expertises des utilisateurs du SNDS pour créer un outil standardisé, validé par les pairs et facile d'accès. 

Il permet d'extraire efficacement les données de consultations, médicaments, affections de longue durée et hospitalisations, tout en intégrant les recommandations de la CNAM concernant les requêtes mois par mois et les filtres qualité. Cette librairie s'inscrit dans une démarche collaborative permettant à chaque expert d'apporter sa contribution.

## Partenaires et équipe projet

### Porteur du projet

Le service mission data de la Haute Autorité de santé est porteur du projet. L'appel à projet est rédigé par un contributeur principal de la librairie sndsTools. Il est appuyé pour la relecture et le suivi du projet par le coordinateur des études SNDS de la mission data ainsi que par deux ingénieures SDNS à la HAS. Il est également relu et amendé par les contributeurs principaux de la librairie (décrits dans la partie partenaire).

Lors de la mise en oeuvre, les rôles seront définis comme suit :

- Le responsable de la mission data et le coordinateur des études SNDS superviseront le marché public pour le recrutement de deux prestataires pour le développement de la librairie.  

- Les deux personnes recrutées auront le rôle d'animateur de la librairie sndsTools : une personne aura une valence technique d'ingénierie logicielle et une personne portera l'expertise SNDS. Les deux animateurs de la librairie porteront conjointement l'axe d'organisation et de communication du projet. Les compétences recherchées sont : 

  - Animateur technique : compétence en R, en gestion de projet open-source, en gestion de communauté et en ingénierie logicielle, expertise en traitement de la donnée, compétences en communication de projet.
  - Animateur métier : expertise SNDS (études menées sur la base principale), expertise en épidémiologie et traitement de la donnée, connaissance des besoins des utilisateurs du SNDS, compétences en communication de projet.

A la HAS, des membres déjà présents de la mission data pourront être mobilisés pour des tâches spécifiques :

- Le coordinateur des études SNDS identifiera et transmettra les besoins des différents services de la HAS pour orienter les principaux usages couverts par la librairie. 

- Les ingénieures SNDS de la HAS porteront des besoins utilisateurs, aideront les animateurs à orienter les choix de nouvelles fonctionnalités et reliront certaines contributions à la librairie.

### Partenaires 

Plusieurs contributeurs provenant d'autres organisations apportent leurs expertises concernant le code ou la documentation du projet, actuellement en tant que contributeurs principaux.

- Un contributeur est pharmaco-épidémiologiste à l'Assistance Publique - Hôpitaux de Marseilles (AP-HM). C'est un expert SNDS et R, ayant participé au contenu de formation de la CNAM sur le SNDS. 

- Deux autres contributeurs sont ingénieurs de données à l'Institut du Cerveau (ICM). Il ont une expertise sur le SNDS et en développement logicielle.

## Présentation du projet

### Algorithmes ou outils concernés

Cette librairie vise à simplifier les étapes d'extraction des données du SNDS. Initiée en marge d'une rencontre d'utilisateurs du SNDS lors du congrès EMOIS en mars 2024 (compte rendu de la rencontre : https://entraide.health-data-hub.fr/t/compte-rendu-de-latelier-r-snds-tenu-au-congres-emois-2024/2071), ce projet vise à rassembler les différentes expertises des utilisateurs pour créer un outil standardisé et facile d'accès simplifiant les étapes répétitives des études SNDS. 

#### Contexte, enjeux, bénéfices attendus

####  Description sommaire et pertinence de l’algorithme ou de l'outil

Les étapes d'extraction des données depuis la base principale du SNDS vers un format adapté aux études épidémiologiques sont longues et difficiles du fait de la complexité des données. En effet, malgré la documentation fournie par la CNAM ou la Plateforme des données de santé (PDS), les détails d'implémentation sont parcellaires et éparpillés. De plus, le développement de requêtes d'extraction de données nécessite une expertise approfondie des données, des filtres qualité et du fonctionnement du portail SNDS (ex. requête mois par mois pour le DCIR). Nous proposons, via la librairie sndsTools de simplifier ces étapes en fournissant des fonctions d'extraction standardisées, documentées (renvoyant aux sources principales si celles-ci existent), respectant des standards modernes de développement logiciel (tests unitaires, prises de décisions tracées, paramètres et sorties standardisée), validées par les pairs et faciles à utiliser. De plus, une partie du projet vise à associer à ces fonctions des cas d'usage simples pour faciliter la prise en main de la librairie.

Les fonctions d’extraction déjà implémentées sont les suivantes : 

- Extraction des consultations externes à l'hôpital : Récupère les consultations médicales avec leurs dates, spécialités médicales et le code de l'acte.
- Extraction des consultations en ville : Récupère les consultations médicales avec leurs dates, spécialités médicales et le code de l'acte.
- Extraction des médicaments délivrés en ville : Récupère les délivrances de médicaments avec leurs dates, codes de la Dénomination Commune Internationale (nomenclature ATC) et de la nomenclature CIP13, spécialité du prescripteur et quantité délivrée.
- Extraction des affections de longue durée : Récupère les données d'ALD avec codes CIM-10 et dates de début/fin.
- Extraction des hospitalisations : Récupère les séjours hospitaliers avec diagnostics, dates d'entrée/sortie et durées.

Les prochaines pistes de travail pourront inclure (non-exhaustif) : 

- Pour toutes les fonctions d'extraction déjà implémentées : Vérification et référencement dans la documentation vers les sources de la CNAM concernant les filtres qualité. Actuellement, certains filtres manquent d'une référence. 
- Ajout de cas d'usage simples utilisant les fonctions de la librairie afin de faciliter la prise en main,
- Ajout dans chaque fonction d’un paramètre affichant à l’utilisateur la requête SQL effectuée. Cet affichage permettrait de simplifier la compréhension des requêtes effectuées pour les utilisateurs de SAS ou SQL, 
- Ajout de données fictives pour les tests en se basant sur les schémas du SNDS,
- Ajout de fonctions d’extraction sur des données actuellement non couvertes : Par exemple, les autres champs du PMSI (SMR, HAD), les actes CCAM dans le PMSI ou le DCIR, ...
- Ajout de fonctions utilitaires : Par exemple, graphe de pyramide des âges, génération d'un diagramme de sélection de population (flowchart), 

#### Caractère innovant
Ce projet est innovant à plusieurs titres :

- Le caractère communautaire du projet permettant de mutualiser les efforts et les expertises des utilisateurs du SNDS de multiples organisations au sein d'un même dépôt de code. En cela, ce projet prolonge sur le plan des codes d'extraction les efforts existants concernant la documentation collaborative du SNDS.
- L'utilisation de la technologie de librairie R pour simplifier l'extraction des données du SNDS. Utiliser les outils et les normes de la communauté R permet de simplifier les étapes d'extraction pour les utilisateurs SNDS. Cette simplification est permise grâce aux efforts aboutissant à un consensus entre utilisateurs sur la documentation, les paramètres et nom des fonctions, les filtres qualité, les exemples d'utilisation. L'adoption de bonnes pratiques de développement logiciel apportent également de la robustesse à la librairie et facilite l'ajout de nouvelles fonctionnalités (tests unitaires, linter, style du code R). Plusieurs projets ont déjà essayé de tirer parti des innovations logiciels des langages de programmation haut-niveaux pour simplifier les extractions SNDS. Parmi ces projets, on peut citer le cas de la librairie Scalpel, écrite en Scala et utilisée couramment sur la plateforme data du service statistique du ministère de la santé (Drees). Cette bibliothèque a été développé conjointement entre l’assurance maladie et le laboratoire de mathématiques appliqués de Polytechnique. Cependant, elle n’a pas atteint une utilisation au-delà de la Drees. Cette sous-utilisation peut être due à différents facteurs : Scalpel nécessite une plateforme et des logiciels spécifiques pour traiter les données SNDS. De plus, elle est écrite dans un langage de programmation éloigné des pratiques des utilisateurs SNDS. Nous avons également connaissance d'autres travaux similaires en python, mais ils ne sont pas open-sources et ne sont pas communautaires (au sens où ils sont portés par une seule institution). La mise à disposition de R sur le portail SNDS permet de contourner ces contraintes. 
- La présence conjointe au sein d'un même projet des fonctions d'extraction (simple d'utilisation) et de la documentation (complète et transparente) permettant une prise en main rapide de l'outil ainsi qu'une confiance dans l'outil. Cet effort mis dans la documentation, notamment avec des cas pratiques est un travail complexe, souvent négligé. Il n'existe pas à notre connaissance d'une telle documentation de cas pratiques sur le SNDS dont il est possible de s'inspirer en changeant quelques paramètres pour adapter le code à son cas d'étude.


### Présentation de la démarche

#### Développement de l'algorithme, évaluation

Cet effort de développement d’une librairie R pour les données du SNDS est un projet communautaire basé sur le consensus et l’investissement personnel de ses membres. Tout utilisateur ayant un intérêt dans le projet peut rejoindre la communauté, contribuer au projet et à ses orientations futures. Les principes de gouvernance sont décrits de façon transparente dans le fichier gouvernance.Rmd du projet (https://sndstoolers.github.io/sndsTools/articles/gouvernance.html). Ce document précise comment la participation a lieu, comment trouver / gagner sa place dans le projet, et quels sont les différents rôles et responsabilités.

Actuellement, la librairie essaye de fonctionner avec deux types de contributeurs :

- Les contributeurs
- Les contributeurs principaux (core contributors) 

Les contributeurs classiques peuvent librement créer des issues, échanger sur une issue existante, proposer de nouvelles fonctionnalités (pull requests) ou relire l'ajout de nouvelles fonctionnalités. Chaque nouvelle fonctionnalité, avant d’être intégrée doit être revue par un contributeur principal. Cette revue permet une validation de la fonctionnalité, de la documentation, de la qualité du code et de la cohérence avec les autres fonctions de la librairie.

Les contributeurs principaux sont particulièrement investis dans le projet. Ils ont des accès larges sur le dépôt. Ce sont eux seulement qui valident l’intégration de nouvelles fonctionnalités (pull requests) et peuvent fermer les issues.

Tout utilisateur peut être contributeur en faisant une nouvelle issue, une pull request, ou en effectuant une revue sur une pull request existante. Un guide de contribution détaille les différentes manières et étape pour contribuer (https://sndstoolers.github.io/sndsTools/articles/contribuer.html).

Devenir un contributeur principal : Après une ou deux pull requests ou revues de la part d’un nouveau contributeur, sur demande de ce dernier, les contributeurs principaux décident collégialement de l’intégrer au projet. Le nombre de contributeurs principaux n’est pas limité. Le projet est en phase très précoce, et accueille à bras ouverts de nouveaux contributeurs principaux.

Les besoins des utilisateurs et les décisions sont discutées et tracées dans les tickets du projet github. Un consensus est recherché avant toute prise de décision. Chaque changement du code est d’abord effectué dans une branche dédiée par un contributeur, puis est relue et validée par un contributeur principal avant d’être intégré dans la branche principale du projet. 

#### Validation externe

NA 

#### Documentation et licence 

Un axe majeur du projet est l'effort porté sur la documentation. Le projet possède une documentation en ligne sur le site https://sndstools.github.io/sndstools/. Cette documentation est rédigée par les contributeurs avec le même soucis de relecture par les pairs que pour le code R. Quand cela est possible, il est encouragé de fournir des liens vers les sources primaires des informations (par exemple : le site de documentation du SNDS de la PDS, un papier de recherche, des documents de formation de la CNAM ou d'un autre organisme de confiance).

Cette documentation comporte plusieurs parties distinctes : 

 - Les vignettes : Une partie de la documentation est constituée de pages spécifiques nommées vignettes. Celles-ci présentent le projet de façon générale, explique la prise en main, la gouvernance ou décrivent des cas d'usage concrets. C'est une partie de la documentation orientée vers les usages pour une prise en main rapide.

 - Les références : Cette partie documentent les fonctions R de la librairie. Cette partie est générée automatiquement à partir des fichiers R du projet et de la syntaxe de documentation roxygen2 (https://roxygen2.r-lib.org/). La documentation est donc rédigée conjointement à l'écriture du code R. Elle doit comporter une description générale de la fonction, des exemples d'utilisation, et des informations sur les paramètres de la fonction et sur le résultat retourné. Cette documentation est orientée vers des utilisateurs plus avancés qui souhaitent comprendre le fonctionnement interne de la librairie.

Le projet est sous licence publique de l'Union Européenne, EUPL v. 1.2.

#### Maturité du projet 

Le projet est dans une phase de développement initial et dispose de plusieurs fonctions d'extraction déjà implémentées, testées et documentée ainsi que d'un site de documentation. La librairie n'a pas encore été utilisée pour des études. Il est prévu que cette librairie soit utilisée au cours de l'année 2025 pour des questions simples d'extraction de données du SNDS à la HAS.

#### Périmètre des données requises

La librairie est orientée pour une utilisation du SNDS avec un accès permanent (profil 108). Elle couvre largement les différentes tables du SNDS. Actuellement, elle fait appel aux données des tables : du DCIR, du PMSI MCO, IR_IMB_R, IR_BEN_R. 

##### Population ciblée

##### Profondeur historique

La librairie est centrée sur la version non-archivée des données (environ les 10 dernières années). Cependant, pour répondre aux besoins des projets de recherche qui ont parfois besoin d'accéder à des données antérieures, la gestion des différentes versions des bases est en discussion. Actuellement, les versions archivées du DCIR sont prises en comptes, mais pas les changements de schéma dans le PMSI. 

##### Autres sources

NA

### Calendrier du projet

#### Grands jalons 

Sur le plan organisationnel, le projet doit en premier lieu identifier et intégrer des contributeurs principaux extérieurs au porteur du projet. Puis, il faudra réussir à faire vivre ce premier noyau de contributeurs avec l'organisation de temps d'échange (rythme mensuel envisagé) et de développement. Cette étape est particulièrement importante pour valider l'intérêt de la communauté pour le projet et pour assurer sa pérennité. Dans un second temps, il est prévu de communiquer plus largement auprès des utilisateurs SNDS, par le biais de meetups (exemple meetup SNDS), des sessions de formations ou des conférences (ex. EMOIS 2026). L'animation de la communauté des contributeurs principaux sera également enrichie avec la rédaction d'un article scientifique et l'organisation de sessions accélérées de développement et documentation (sprint).

Sur le plan technique, une version majeure (V1) de la librairie n'est pas encore prévue à ce jour, ni au cours du financement. En effet, dans les standards open source, une version majeure est souvent associée à une version stable et complète du projet (cf. https://semver.org/lang/fr/spec/v1.0.0.html). Le financement de BOAS couvrirait une phase active de développement qui aidera à définir les contours d'une version stable (en terme de besoins, fonctionnalités, API) mais il semble trop ambitieux d'aboutir à une V1 en moins de deux ans. Plusieurs versions mineures sont en revanche prévues.

La temporalité prévue pour les différents jalons sont les suivants : 

- Deuxième semestre 2025 : Identification de contributeurs principaux dans l'écosystème. Objectif de participations multiples à la librairie (issue, documentation ou code) de deux contributeurs principaux supplémentaires par rapport à ceux existants à ce jour. L'identification de contributeurs principaux pourra être associée à des sessions de formations pour ces nouveaux contributeurs. Une première version mineure (V 0.1) comporterait a minima les fonctions d'extraction déjà implémentées avec une API cohérente entre les différentes fonctions, une documentation de référence, un guide de contribution, une gouvernance claire et un cas d'usage simple de la librairie. Il manque actuellement pour cette version le cas d'usage simple. 

- Premier semestre 2026 : Communication au congrès EMOIS 2026. Installation de la librairie sur le portail de la CNAM. Participation active des contributeurs principaux identifiés au semestre précédent. Version mineure (V 0.2) avec des nouvelles fonctionnalités d'extraction (par exemple, extraction des actes CCAM, extensions des fonctions existantes au champ PMSI HAD et SMR, ajout de données fictives pour les tests) et deux ou trois cas d'études simples mais courants.

#### Budget

#### Modalités de financement

- Fléchage du financement : Le financement de l'appel à projet sera fléché pour le recrutement des deux animateurs du projet pour un an. Selon la somme obtenue, le recours à un prestataire pour le développement permettra de moduler le temps effectif des animateurs (deux mi-temps sont envisagés)

- Mission des animateurs : Les deux personnes recrutées auront le rôle d'animateur de la librairie sndsTools. Ils orienteront les besoins de nouvelles fonctionnalités, identifieront des contributeurs potentiels,organiseront les événements liés à l'animation de la communauté des utilisateurs et porteront des actions de communication et de formation liés à la librairie.

  - Animateur technique : Cet animateur aura pour mission de coordonner les différentes tâches sur le plan technique, c'est à dire de relire et valider des nouvelles fonctionnalités, d'en développer certaines, de veiller aux bonnes pratiques de programmation et à la cohérence technique de la librairie.

  - Animateur métier : Cet animateur aura pour mission de coordonner les différentes tâches sur le plan métier, entre-autres de rédiger la documentation ou de relire celles écrites par d'autres contributeurs, d'orienter les besoins de nouvelles fonctionnalités et de veiller à la cohérence métier de la librairie.

- Compétences : 
  - Animateur technique : compétence en R, en gestion de projet open-source, en gestion de communauté et en ingénierie logicielle, expertise en traitement de la donnée, compétences en communication de projet.
  
  - Animateur métier : expertise SNDS (études menées sur la base principale), expertise en épidémiologie et traitement de la donnée, connaissance des besoins des utilisateurs du SNDS, compétences en communication de projet.

#### Risques anticipés

- Inadaptation aux besoins des utilisateurs : Afin de limiter ce risque, les orientations du projet (notamment avec le tri des issues et lors de réunions de suivi régulières de prise d’orientation) sont principalement prises par des utilisateurs du SNDS avec une expérience significative sur les étapes d'extraction.

- Complexification technique du code : des efforts sont faits pour maintenir le code simple et lisible en associant au projet des ingénieurs logiciels avec une expertise en R et en gestion de projet open-source.

- Manque de contributeurs : La partie communautaire est centrale dans le projet afin de créer du consensus et de la mutualisation d'efforts. Le manque de contributeurs venant de divers organismes en diminuerait l'importance et donc l'intérêt du projet. La place centrale de la HAS dans l'écosystème des données de santé ainsi que des efforts de communication et de promotion du projet (par exemple lors de conférences, de meetups ou de sprints) devraient permettre de limiter ce risque.

### Accompagnement demandé au Health Data Hub 

- Accompagnement financier pour le recrutement des animateurs technique et métier du projet.
- Expertise et accompagnement sur les aspects open science, et open source 
- Accompagnement sur les aspects de communication et de promotion du projet : par exemple mise à disposition de salles à PariSanté Campus pour des événements de type sprint.
- Accompagnement technique pour créer un miroir du projet depuis le github (github est favorisé car plus facilement communautaire) vers le gitlab BOAS de la PDS.

### Open science

Le projet est conforme aux principes de l'open science dans la mesure où il est open source, open review, avec une licence ouverte, un aspect communautaire fort et un accent mis sur la documentation. 