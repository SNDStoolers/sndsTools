source(here::here("sndsTools.R"))

# Paramètres d'extraction
atc_vitamine_d_7 <- c("M05BB03", "M05BB04", "A11CC05", "A11CC01", "A12CD51")

cip_vitamine_d_b <- c(
    3400935657190, 3400936584969, 3400936923751, 3400934880254)

# Colonnes supplémentaires pour la fonction `extract_drug_dispenses`.
sup_columns <- c(
    "BEN_CMU_TOP",
    "BEN_AMA_COD",
    "BEN_SEX_COD",
    "BEN_RES_DPT",
    "FLX_DIS_DTD",
    "PRS_ACT_QTE",
    "BSE_REM_MNT",
    "BSE_PRS_NAT",
    "ETE_IND_TAA",
    "ETB_EXE_FIN",
    "ETE_MCO_DDP",
    "PHA_GRD_CND",
    "PHA_PRS_IDE",
    "PHA_DEC_TOP",
    "PHA_DEC_QSU"
)

start_dates <- rep(as.Date("2020-01-01"), 2)
end_dates <- c(
    as.Date("2020-08-01"),
    as.Date("2020-02-01")
)

# R-level parallelism cores to test
r_cluster_levels <- c(4, 8)

path2benchmark  <- file.path(
    here::here("inst", "extdata", "benchmark_r_parallelism.csv"))
dir.create(dirname(path2benchmark), recursive = TRUE)
first_iter <- FALSE
for (i in seq_along(start_dates)) {
    start_date <- start_dates[i]
    end_date <- end_dates[i]
    message("Extraction pour la période : ", start_date, " - ", end_date)

    for (r_cluster_cores in r_cluster_levels) {
        conn <- connect_oracle()
        # Format table names
        formatted_study_dates <- glue::glue(
            '{format(start_date, "%Y%m%d")}_{format(end_date, "%Y%m%d")}')

        table_name <- glue::glue(
            "dplyr_r_parallel_{r_cluster_cores}_{formatted_study_dates}")
        message("Extraction avec R parallelism : ", r_cluster_cores, " cores")

        # Benchmark with R-level parallelism
        time_0 <- Sys.time()
        extract_drug_dispenses(
            start_date = start_date,
            end_date = end_date,
            atc_cod_starts_with_filter = atc_vitamine_d_7,
            cip13_cod_filter = cip_vitamine_d_b,
            output_table_name = table_name,
            sup_columns = sup_columns,
            conn = conn,
            r_cluster_cores = r_cluster_cores
        )
        time_taken <- as.numeric(
            lubridate::as.duration(Sys.time() - time_0), "seconds")

        # Get result count
        n_rows <- DBI::dbGetQuery(
            conn, glue::glue("select count(*) from {table_name}"))

        # enregistrement des résultats
        tmp_timing_results <- data.frame(
            start_date = as.character(start_date),
            end_date = as.character(end_date),
            r_cores = r_cluster_cores,
            time_taken_seconds = time_taken,
            n_rows = n_rows[[1]]
        )

        # Drop the temporary table
        on.exit(DBI::dbExecute(conn, glue::glue("DROP TABLE {table_name}")))

        # Write results to CSV
        write.table(
            tmp_timing_results,
            path2benchmark,
            append = !first_iter,
            row.names = FALSE,
            col.names = first_iter,
            sep = ","
        )
        first_iter <- FALSE
        conn |> DBI::dbDisconnect()
    }
}

DBI::dbDisconnect(conn)

# Summary of results
message("\n=== Benchmark Summary ===")
results <- read.csv(path2benchmark)
results |> knitr::kable()
