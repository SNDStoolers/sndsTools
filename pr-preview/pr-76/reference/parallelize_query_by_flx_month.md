# Exécute une fonction de construction de requête par mois de flux

Cette fonction découpe la période d'extraction en mois de flux, prépare
les paramètres spécifiques à chaque mois et invoque la fonction
`query_builder_function` soit en mode séquentiel, soit en parallèle via
le package `parallel`. Elle gère la création de la table de sortie lors
du premier mois.

## Usage

``` r
parallelize_query_by_flx_month(
  conn,
  start_date,
  end_date,
  query_builder_function,
  query_builder_kwargs,
  dis_dtd_lag_months = 6,
  r_cluster_cores = 1
)
```

## Arguments

- conn:

  Connexion DBI à la base de données.

- start_date:

  Date. Date de début de la période d'extraction.

- end_date:

  Date. Date de fin de la période d'extraction.

- query_builder_function:

  Fonction qui construit la requête SQL pour un mois donné. Exemple :
  [`.extract_drug_by_month`](dot-extract_drug_by_month.md) depuis le
  fichier `R/extract_drug_erprsf.R`.

- query_builder_kwargs:

  Liste d'arguments supplémentaires transmis à la fonction de
  construction. Elle contient typiquement les paramètres globaux comme
  `sup_columns`, `output_table_name`, etc.

- dis_dtd_lag_months:

  Entier. Nombre de mois de retard pris en compte pour la date
  `FLX_DIS_DTD`. Valeur par défaut : 6.

- r_cluster_cores:

  Entier. Nombre de cœurs à utiliser pour le parallélisme. Valeur par
  défaut : 1 (exécution séquentielle).

## Value

Invisible NULL. La fonction orchestre l'exécution de la fonction de
construction de requête pour chaque mois, en créant ou insérant les
résultats dans la table de sortie.

## Details

La fonction construit une liste `months_to_process` contenant pour
chaque mois les paramètres `dis_dtd_year`, `dis_dtd_month`,
`is_first_month`, `formatted_start_date`, `formatted_end_date`,
`end_year` ainsi que les arguments fournis dans `query_builder_kwargs`.
Elle crée ensuite un cluster si `r_cluster_cores` \> 1, exporte les
packages nécessaires et la connexion, exécute le premier mois pour créer
la table, puis traite les mois restants en parallèle avec
[`parallel::parLapply`](https://rdrr.io/r/parallel/clusterApply.html).

## See also

Other utils: [`connect_duckdb()`](connect_duckdb.md),
[`connect_oracle()`](connect_oracle.md),
[`constants_snds()`](constants_snds.md),
[`create_table_from_query()`](create_table_from_query.md),
[`gather_table_stats()`](gather_table_stats.md),
[`get_first_non_archived_year()`](get_first_non_archived_year.md),
[`insert_into_table_from_query()`](insert_into_table_from_query.md),
[`retrieve_all_psa_from_idt()`](retrieve_all_psa_from_idt.md),
[`retrieve_all_psa_from_psa()`](retrieve_all_psa_from_psa.md)

## Examples

``` r
if (FALSE) { # \dontrun{
parallelize_query_by_flx_month(
  conn = conn,
  start_date = as.Date("2020-01-01"),
  end_date = as.Date("2020-03-31"),
  query_builder_function = .extract_drug_by_month,
  query_builder_kwargs = list(
    sup_columns = NULL,
    output_table_name = "TMP_DISP",
    show_sql_query = FALSE
  )
)
} # }
```
