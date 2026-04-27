# Télécharge les données synthétiques SNDS et les charge dans une base DuckDB

Télécharge tous les fichiers de données synthétiques SNDS depuis l'API
de Health Data Hub sur data.gouv.fr, décompresse les archives ZIP, lit
les fichiers CSV et les charge dans une base DuckDB locale.

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

- force_download:

  Logical. Si TRUE, retélécharge tous les fichiers même si la base
  existe déjà (FALSE par défaut). Si FALSE et que la base existe, la
  fonction retourne le chemin de la base existante sans
  retéléchargement.

- db_path:

  Character. Chemin vers le fichier de la base DuckDB à créer. La valeur
  par défaut est `./synthetic_snds.duckdb` dans le répertoire de travail
  courant.

## Value

Connexion DuckDB. Une connexion duckdb vers la base DuckDB créée.

## Details

Cette fonction télécharge 9 fichiers zip contenant des données
synthétiques pour 50 patients fictifs basés sur le schéma SNDS 2019. Les
fichiers sont produits par Health Data Hub et hébergés sur data.gouv.fr.
\#'

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
[`create_mock_patients_ids()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_patients_ids.md)
