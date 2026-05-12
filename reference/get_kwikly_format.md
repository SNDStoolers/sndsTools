# Obtenir les formats de colonnes à partir du fichier kwikly

Lit le fichier kwikly pour obtenir les formats de colonnes à utiliser
lors de la lecture des fichiers CSV synthétiques. Le fichier kwikly est
téléchargé depuis le dépôt de la CNAM si nécessaire.

## Usage

``` r
get_kwikly_format(table_name)
```

## Arguments

- table_name:

  Character. Nom de la table pour laquelle obtenir les formats de
  colonnes. Par exemple, "T_MCO", "T_RIM_P", etc.

## Value

Named list. Une liste nommée de formats de colonnes à utiliser avec
readr::cols() lors de la lecture du CSV. Les noms de la liste
correspondent aux noms des colonnes, et les valeurs sont des objets
readr::col\_\* indiquant le type de chaque colonne.

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
[`download_synthetic_snds_csv()`](https://sndstoolers.github.io/sndsTools/reference/download_synthetic_snds_csv.md),
[`insert_synthetic_snds_table()`](https://sndstoolers.github.io/sndsTools/reference/insert_synthetic_snds_table.md)
