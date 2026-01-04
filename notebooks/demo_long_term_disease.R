library(ROracle)
library(dplyr)
library(dbplyr)
library(DBI)
library(glue)
library(lubridate)

is_package <- require(sndsTools)

if (!is_package) {
  source("../R/extract_long_term_disease.R")
  source("../R/utils.R")
}

# Retrieve all active long-term diseases in 2010
# with ICD 10 code corresponding to Parkinson's
# disease (G20)
start_date <- as.Date("2010-01-01")
end_date <- as.Date("2010-12-31")
icd_cod_starts_with <- c("G20")

ald <- extract_long_term_disease(
  start_date = start_date,
  end_date = end_date,
  icd_cod_starts_with = icd_cod_starts_with
)
head(ald)

# You can also provide your own database connection
# to the extract_drug_dispenses function. This is useful
# to avoid opening and closing a connection for each
# extraction function call.
conn <- connect_oracle()
start_date <- as.Date("2010-01-01")
end_date <- as.Date("2010-12-31")
icd_cod_starts_with <- c("G20")

ald <- extract_long_term_disease(
  start_date = start_date,
  end_date = end_date,
  icd_cod_starts_with = icd_cod_starts_with,
  conn = conn
)
head(ald)

# Retrieve all active long-term diseases in 2010
# with ALD number corresponding to diabetes (8).
# Gives roughly 6.5 million rows.
start_date <- as.Date("2010-01-01")
end_date <- as.Date("2010-12-31")
ald_numbers <- c(8)

ald <- extract_long_term_disease(
  start_date = start_date,
  end_date = end_date,
  ald_numbers = ald_numbers
)
head(ald)

# If the output_table_name argument is provided,
# the output will be stored in a table with the
# given name. This is especially useful when the
# output table is too large to be stored in memory.
start_date <- as.Date("2010-01-01")
end_date <- as.Date("2010-12-31")
ald_numbers <- c(8)
output_table_name <- "TMP_LTD"
print(DBI::dbExistsTable(conn, output_table_name))

extract_long_term_disease(
  start_date = start_date,
  end_date = end_date,
  ald_numbers = ald_numbers,
  output_table_name = output_table_name
)

print(DBI::dbExistsTable(conn, output_table_name))
query <- glue::glue("SELECT COUNT(*) FROM {output_table_name}")
result <- DBI::dbGetQuery(conn, query)
print(result)
