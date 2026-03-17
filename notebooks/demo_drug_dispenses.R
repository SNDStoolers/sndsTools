library(ROracle)
library(dplyr)
library(dbplyr)
library(DBI)
library(glue)
library(lubridate)
library(progress)
# Source the following functions to run the code below:
# - connect_oracle
# - get_first_non_archived_year
# - create_table_from_query
# - insert_into_table_from_query
# - extract_drug_erprsf

# Retrieve all N04A drug dispenses over three days
# The output will contain ben_nir_psa as the patient
# identifier, since no patients_ids are provided
start_date <- as.Date("2010-01-01")
end_date <- as.Date("2010-01-03")
atc_cod_starts_with <- c("N04A")

dispenses <- extract_drug_erprsf(
  start_date = start_date,
  end_date = end_date,
  atc_cod_starts_with = atc_cod_starts_with
)
head(dispenses)
stopifnot(all(grepl("^N04A", dispenses$PHA_ATC_CLA)))

# Same as above, but for N04A and A10 drug dispenses
start_date <- as.Date("2010-01-01")
end_date <- as.Date("2010-01-03")
atc_cod_starts_with <- c(
  "N04A",
  "A10"
)

dispenses <- extract_drug_erprsf(
  start_date = start_date,
  end_date = end_date,
  atc_cod_starts_with = atc_cod_starts_with
)
head(dispenses)
stopifnot(all(grepl("^N04A|^A10", dispenses$PHA_ATC_CLA)))

# You can also provide your own database connection
# to the extract_drug_erprsf function. This is useful
# to avoid opening and closing a connection for each
# extraction function call.
conn <- connect_oracle()
start_date <- as.Date("2010-01-01")
end_date <- as.Date("2010-01-03")
atc_cod_starts_with <- c("N04A")

dispenses <- extract_drug_erprsf(
  start_date = start_date,
  end_date = end_date,
  atc_cod_starts_with = atc_cod_starts_with,
  conn = conn
)
head(dispenses)
stopifnot(all(grepl("^N04A", dispenses$PHA_ATC_CLA)))
# Close the connection
DBI::dbDisconnect(conn)

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


# Retrieve antidiabetic drug dispenses for
# the given sample of patients over one month.
# The output will contain ben_idt_ano as the patient
# identifier, since patients_ids are provided
start_date <- as.Date("2010-01-01")
end_date <- as.Date("2010-01-31")
atc_cod_starts_with <- c("A10")

dispenses <- extract_drug_erprsf(
  start_date = start_date,
  end_date = end_date,
  atc_cod_starts_with = atc_cod_starts_with,
  patients_ids = patients_ids_sample
)
head(dispenses)
stopifnot(all(dispenses$BEN_IDT_ANO %in% patients_ids_sample$BEN_IDT_ANO))
stopifnot(all(grepl("^A10", dispenses$PHA_ATC_CLA)))

# Retrieve all dispenses for the sample
# of patients over one week. The fact that
# no atc_cod_starts_with are provided allows
# all dispenses to be retrieved.
start_date <- as.Date("2010-01-01")
end_date <- as.Date("2010-01-07")

dispenses <- extract_drug_erprsf(
  start_date = start_date,
  end_date = end_date,
  patients_ids = patients_ids_sample
)
head(dispenses)
stopifnot(all(dispenses$BEN_IDT_ANO %in% patients_ids_sample$BEN_IDT_ANO))

# If the output_table_name argument is provided,
# the output will be stored in a table with the
# given name. This is especially useful when the
# output table is too large to be stored in memory.
start_date <- as.Date("2010-01-01")
end_date <- as.Date("2010-01-15")
output_table_name <- "TMP_DISPENSES"

conn <- connect_oracle()
print(dbExistsTable(conn, output_table_name))
extract_drug_erprsf(
  start_date = start_date,
  end_date = end_date,
  patients_ids = patients_ids_sample,
  output_table_name = output_table_name
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
