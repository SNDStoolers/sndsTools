# Insérer un fichier CSV dans une table DuckDB

Lit un fichier CSV et l'insère dans une table DuckDB. Le nom de la table
est dérivé du nom du fichier CSV.

## Usage

``` r
insert_synthetic_snds_table(conn, path2csv, delim = ",", col_types = NULL)
```

## Arguments

- conn:

  DuckDB connection. Connexion à la base DuckDB.

- path2csv:

  Character. Chemin vers le fichier CSV à insérer.

## Value

Invisible. Retourne la connexion DuckDB après insertion.

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
[`get_kwikly_format()`](https://sndstoolers.github.io/sndsTools/reference/get_kwikly_format.md)
