# Télécharge les données synthétiques SNDS et les charge dans une base DuckDB

Télécharge les données synthétiques SNDS depuis le compte de la
Plateforme des Données de Santé sur data.gouv.fr avec la fonction
`other_function`, décompresse les archives ZIP, puis lit les fichiers
CSV et les charge dans une base DuckDB locale.

## Usage

``` r
connect_synthetic_snds(
  path2db = NULL,
  force_insert = FALSE,
  force_download = FALSE,
  subset_tables = NULL
)
```

## Arguments

- force_insert:

  Logical. Si TRUE, force la réinsertion des données même si la base
  existe déjà (FALSE par défaut). Si FALSE et que la base existe, la
  fonction retourne la connexion à la base existante sans réinsertion.

- force_download:

  Logical. Si TRUE, retélécharge tous les fichiers même si la base
  existe déjà (FALSE par défaut). Si FALSE et que la base existe, la
  fonction retourne le chemin de la base existante sans
  retéléchargement.

- subset_tables:

  Character vector. Si non NULL, ne charge que les tables dont le nom
  contient une des chaînes de ce vecteur. Par exemple,
  `subset_tables = c("T_MCO", "T_RIM")`. Par défaut, toutes les tables
  sont chargées.

- path2b:

  Character. Chemin vers le fichier de la base DuckDB à créer. La valeur
  par défaut est `~/.cache/sndsTools/synthetic_snds.duckdb`.

## Value

Connexion DuckDB. Une connexion duckdb vers la base DuckDB créée.

## Details

Cette fonction télécharge 9 fichiers zip contenant des données
synthétiques pour 50 patients fictifs basés sur le schéma SNDS 2019. Les
fichiers sont produits par Health Data Hub et hébergés sur data.gouv.fr.

## See also

Other synthetic:
[`connect_synthetic_data_avc()`](https://sndstoolers.github.io/sndsTools/reference/connect_synthetic_data_avc.md),
[`create_mock_er_ete_f()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_er_ete_f.md),
[`create_mock_er_pha_f()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_er_pha_f.md),
[`create_mock_er_prs_f()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_er_prs_f.md),
[`create_mock_ir_ben_r()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_ir_ben_r.md),
[`create_mock_ir_imb_r()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_ir_imb_r.md),
[`create_mock_ir_pha_r()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_ir_pha_r.md),
[`create_mock_mco_tables()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_mco_tables.md),
[`create_mock_patients_ids()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_patients_ids.md),
[`download_synthetic_snds_csv()`](https://sndstoolers.github.io/sndsTools/reference/download_synthetic_snds_csv.md),
[`get_kwikly_format()`](https://sndstoolers.github.io/sndsTools/reference/get_kwikly_format.md),
[`insert_synthetic_snds_table()`](https://sndstoolers.github.io/sndsTools/reference/insert_synthetic_snds_table.md)
