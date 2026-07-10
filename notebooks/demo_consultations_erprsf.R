library(ROracle)
library(dplyr)
library(dbplyr)
library(DBI)
library(glue)
library(lubridate)

is_package <- require(sndsTools)

if (!is_package) {
  source("../sndsTools.R")
}

conn <- connect_oracle()

# Retrieve all consultations for general practitioners (01, 22, 23) for the
# first week of December 2022
start_date <- as.Date("01/12/2022", format = "%d/%m/%Y")
end_date <- as.Date("08/12/2022", format = "%d/%m/%Y")

pse_spe_filter <- c(1, 22, 32)
prestation_filter <- c(1111, 1112)

consultations_med_g <- extract_consultations_erprsf(
  conn = conn,
  start_date = start_date,
  end_date = end_date,
  pse_spe_filter = pse_spe_filter,
  prestation_filter = prestation_filter,
)

# Either collect the results into a tibble
consultations_med_g_tibble <- consultations_med_g |>
  dplyr::collect()
head(consultations_med_g_tibble)
# Or save the results into an Oracle table
output_table_name <- "TEST_CONSULTATIONS_ERPRSF"
consultations_med_g |>
  write_oracle_table_by_batch(
    conn = conn,
    output_table_name = output_table_name,
    start_date = start_date,
    end_date = end_date,
    batch_by = "month" # could also batch by "year"
  )
# Query the table
consultations_med_g_oracle <- tbl(conn, output_table_name)
consultations_med_g_oracle |> head(100)
# You may want to delete the output table if it is no longer needed
DBI::dbRemoveTable(conn, output_table_name)

# Same as above but only for a sample of patients
# Create a sample of patients
ref_ir_ben <- tbl(conn, "IR_BEN_R")
patients_ids_sample <- ref_ir_ben %>%
  select(BEN_IDT_ANO, BEN_NIR_PSA) %>%
  distinct() %>%
  head(10000) %>%
  collect()
head(patients_ids_sample)

consultations_med_g_sample_patients <- extract_consultations_erprsf(
  conn = conn,
  start_date = start_date,
  end_date = end_date,
  pse_spe_filter = pse_spe_filter,
  prestation_filter = prestation_filter,
  patients_ids_filter = patients_ids_sample
) |>
  dplyr::collect()
head(consultations_med_g_sample_patients)

# Close the connection
DBI::dbDisconnect(conn)
