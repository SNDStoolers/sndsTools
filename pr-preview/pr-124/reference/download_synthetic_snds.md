# Télécharge la base de données synthétique du SNDS

Télécharge la base de données synthétique du SNDS

## Usage

``` r
download_synthetic_snds(path2zip)
```

## Arguments

- db_path:

  Character. Répertoire dans lequel télécharger et extraire les
  fichiers.

## Value

Nothing.

## Details

La base est téléchargée depuis
https://github.com/SNDStoolers/synthetic_snds/data/synthetic_snds.duckdb.
C'est une version corrigée de la base fournie par la plateforme de
données de santé sur data.gouv.fr :
https://www.data.gouv.fr/datasets/donnees-synthetiques-de-la-base-principales-du-systeme-national-des-donnees-de-sante

## See also

Other synthetic:
[`connect_synthetic_data_avc()`](https://sndstoolers.github.io/sndsTools/reference/connect_synthetic_data_avc.md),
[`connect_synthetic_snds()`](https://sndstoolers.github.io/sndsTools/reference/connect_synthetic_snds.md),
[`create_mock_er_ete_f()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_er_ete_f.md),
[`create_mock_er_pha_f()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_er_pha_f.md),
[`create_mock_er_prs_f()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_er_prs_f.md),
[`create_mock_ir_ben_r()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_ir_ben_r.md),
[`create_mock_ir_imb_r()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_ir_imb_r.md),
[`create_mock_ir_pha_r()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_ir_pha_r.md),
[`create_mock_mco_tables()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_mco_tables.md),
[`create_mock_patients_ids()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_patients_ids.md)
