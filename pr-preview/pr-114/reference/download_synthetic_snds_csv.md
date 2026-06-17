# Télécharger les fichiers CSV synthétiques SNDS

Télécharge les fichiers zip depuis [le dépôt de la Plateforme de Données
de Santé sur
datagouv.fr](https://www.data.gouv.fr/datasets/donnees-synthetiques-de-la-base-principales-du-systeme-national-des-donnees-de-sante)
et les décompresse.

## Usage

``` r
download_synthetic_snds_csv(db_path)
```

## Arguments

- db_path:

  Character. Répertoire dans lequel télécharger et extraire les
  fichiers.

## Value

Nothing.

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
[`create_mock_patients_ids()`](https://sndstoolers.github.io/sndsTools/reference/create_mock_patients_ids.md),
[`get_kwikly_format()`](https://sndstoolers.github.io/sndsTools/reference/get_kwikly_format.md),
[`insert_synthetic_snds_table()`](https://sndstoolers.github.io/sndsTools/reference/insert_synthetic_snds_table.md)
