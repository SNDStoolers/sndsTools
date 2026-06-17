# Fournit une connexion duckdb à une base de donnée synthétique du SNDS

Fournit une connexion duckdb à une base de donnée synthétique du SNDS

## Usage

``` r
connect_synthetic_snds(path2db = NULL, force_download = FALSE)
```

## Arguments

- force_download:

  Logical. Si TRUE, re-télécharge la base si elle existe déjà (FALSE par
  défaut).

- path2b:

  Character. Chemin vers le fichier de la base DuckDB à créer. La valeur
  par défaut est `~/.cache/sndsTools/synthetic_snds.duckdb`.

## Value

Connexion DuckDB. Une connexion duckdb vers la base DuckDB créée.

## Details

Fournit une base de données avec des données synthétiques SNDS. La base
est téléchargée depuis https://github.com/SNDStoolers/synthetic_snds. Ce
projet reprend les données synthétiques produites par [la Plateforme de
Données de
Santé](https://www.data.gouv.fr/datasets/donnees-synthetiques-de-la-base-principales-du-systeme-national-des-donnees-de-sante)
afin de forcer les types des données à ceux du portail Cnam et
consolider les différents fichiers csv dans une seule base duckdb. La
base est mis en cache dans le chemin `path2b` à la première utilisation
puis réutilisée aux appels suivants.

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
[`download_synthetic_snds()`](https://sndstoolers.github.io/sndsTools/reference/download_synthetic_snds.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Crée une base DuckDB avec les données synthétiques SNDS
conn <- connect_synthetic_snds()
} # }
```
