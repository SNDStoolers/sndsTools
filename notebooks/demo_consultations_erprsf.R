library(ROracle)
library(dplyr)
library(dbplyr)
library(DBI)
library(glue)
library(lubridate)

is_package <- require(sndsTools)

if (!is_package) {
  source("../R/extract_consultations_erprsf.R")
  source("../R/utils.R")
}

# Retrieve all consultations for general practitioners (01, 22, 23) for the
# first week of December 2022
start_date <- as.Date("01/12/2022", format = "%d/%m/%Y")
end_date <- as.Date("08/12/2022", format = "%d/%m/%Y")

pse_spe_filter <- c(1, 22, 32)
prestation_filter <- c(1111, 1112)

consultations_med_g <- extract_consultations_erprsf(
  start_date = start_date,
  end_date = end_date,
  pse_spe_filter = pse_spe_filter,
  prestation_filter = prestation_filter,
)
head(consultations_med_g)

# Same as above but only for a sample of patients

# Create a sample of patients
conn <- connect_oracle()
ref_ir_ben <- tbl(conn, "IR_BEN_R")
patients_ids_sample <- ref_ir_ben %>%
  select(BEN_IDT_ANO, BEN_NIR_PSA) %>%
  distinct() %>%
  head(10000) %>%
  collect()
head(patients_ids_sample)
# Close the connection
DBI::dbDisconnect(conn)

consultations_med_g_sample_patients <- extract_consultations_erprsf(
  start_date = start_date,
  end_date = end_date,
  pse_spe_filter = pse_spe_filter,
  prestation_filter = prestation_filter,
  patients_ids_filter = patients_ids_sample
)
head(consultations_med_g_sample_patients)


# If the output_table_name argument is provided,
# the output will be stored in a table with the
# given name. This is especially useful when the
# output table is too large to be stored in memory.
start_date <- as.Date("01/12/2022", format = "%d/%m/%Y")
end_date <- as.Date("08/12/2022", format = "%d/%m/%Y")

pse_spe_filter <- c(1, 22, 32)
prestation_filter <- c(1111, 1112)

output_table_name <- "TMP_DISPENSES"

conn <- connect_oracle()
print(dbExistsTable(conn, output_table_name))
consultations_med_g <- extract_consultations_erprsf(
  start_date = start_date,
  end_date = end_date,
  pse_spe_filter = pse_spe_filter,
  prestation_filter = prestation_filter,
  output_table_name = output_table_name,
  conn = conn
)
print(dbExistsTable(conn, output_table_name))
# The output table can be queried using SQL
query <- glue("SELECT COUNT(*) FROM {output_table_name}")
result <- dbGetQuery(conn, query)
print(result)
# You may want to delete the output table if it is no longer needed
DBI::dbRemoveTable(conn, output_table_name)
# Close the connection
DBI::dbDisconnect(conn)
