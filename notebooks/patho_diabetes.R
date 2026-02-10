# library(ROracle)
library(dplyr)
library(dbplyr)
library(DBI)
library(glue)
library(lubridate)

ben_ids_orauser <- "BEN_FILTERED_IDS"

selected_ben <- readRDS(
  "~/sasdata1/pathologies-retrieval-snds/data/processed/ben_filtered.RDS"
)
selected_ben <- selected_ben %>%
  select(ben_idt_ano, first_series_date) %>%
  mutate(first_series_date = as.Date(first_series_date)) %>%
  distinct()

retrieval_start_date <- as.Date("01/01/2009", format = "%d/%m/%Y")
retrieval_end_date <- as.Date("31/12/2013", format = "%d/%m/%Y")

diabetes_codes <- c("E10", "E11", "E12", "E13", "E14")
diabetes_complication_codes <- c(
  "G590",
  "G632",
  "G730",
  "G990",
  "H280",
  "H360",
  "I792",
  "L97",
  "M142",
  "M146",
  "N083"
)

selected_ben <- readRDS(
  "~/sasdata1/park/visualize/data/processed/ben_filtered.RDS"
)
selected_ben <- selected_ben %>%
  select(ben_idt_ano, first_series_date) %>%
  mutate(first_series_date = as.Date(first_series_date)) %>%
  distinct()

# First retrieval of hospital stays based on principal and related diagnoses (DP and DR)
start_date <- retrieval_start_date
end_date <- retrieval_end_date

dp_cim10_codes_starts_with <- diabetes_codes
or_dr_with_same_codes <- TRUE
or_da_with_same_codes <- FALSE
and_da_with_other_codes <- FALSE
da_cim10_codes_starts_with <- NULL

ben_table_name <- ben_ids_orauser
output_table_name <- NULL
r_output_path <- NULL

hospital_stays_main_diagnosis <- extract_hospital_stays(
  start_date = start_date,
  end_date = end_date,
  dp_cim10_codes_starts_with = dp_cim10_codes_starts_with,
  or_dr_with_same_codes = or_dr_with_same_codes,
  or_da_with_same_codes = or_da_with_same_codes,
  and_da_with_other_codes = and_da_with_other_codes,
  da_cim10_codes_starts_with = da_cim10_codes_starts_with,
  ben_table_name = ben_table_name,
  output_table_name = output_table_name,
  r_output_path = r_output_path
)

hospital_stays_main_diagnosis <- hospital_stays_main_diagnosis %>%
  rename_with(tolower) %>%
  select(ben_idt_ano, exe_soi_dtd, dgn_pal, dgn_rel) %>%
  distinct()


# Second retrieval of hospital stays based on principal and related diagnoses (DA)
start_date <- retrieval_start_date
end_date <- retrieval_end_date

dp_cim10_codes_starts_with <- diabetes_complication_codes
or_dr_with_same_codes <- TRUE
or_da_with_same_codes <- FALSE
and_da_with_other_codes <- TRUE
da_cim10_codes_starts_with <- diabetes_codes

ben_table_name <- ben_ids_orauser
output_table_name <- NULL
r_output_path <- NULL


hospital_stays_complication <- extract_hospital_stays(
  start_date = start_date,
  end_date = end_date,
  dp_cim10_codes_starts_with = dp_cim10_codes_starts_with,
  or_dr_with_same_codes = or_dr_with_same_codes,
  or_da_with_same_codes = or_da_with_same_codes,
  and_da_with_other_codes = and_da_with_other_codes,
  da_cim10_codes_starts_with = da_cim10_codes_starts_with,
  ben_table_name = ben_table_name,
  output_table_name = output_table_name,
  r_output_path = r_output_path
)

hospital_stays_complication <- hospital_stays_complication %>%
  rename_with(tolower) %>%
  select(ben_idt_ano, exe_soi_dtd, dgn_pal, dgn_rel) %>%
  distinct()

# Combine the two tables
hospital_stays <- bind_rows(
  hospital_stays_main_diagnosis,
  hospital_stays_complication
) %>%
  distinct()


start_date <- retrieval_start_date
end_date <- retrieval_end_date

icd_cod_starts_with <- diabetes_codes
icd_cod_is_exactly <- NULL
ald_numbers <- NULL
excl_atm_nat <- c("11", "12", "13")

ben_table_name <- ben_ids_orauser
output_table_name <- NULL
save_to_sas <- FALSE
r_output_path <- NULL

ald <- extract_ald(
  start_date = start_date,
  end_date = end_date,
  icd_cod_starts_with = icd_cod_starts_with,
  icd_cod_is_exactly = icd_cod_is_exactly,
  ald_numbers = ald_numbers,
  excl_atm_nat = excl_atm_nat,
  ben_table_name = ben_table_name,
  output_table_name = output_table_name,
  save_to_sas = save_to_sas,
  r_output_path = r_output_path
)

ald <- ald %>%
  rename_with(tolower)

start_date <- retrieval_start_date
end_date <- retrieval_end_date

starts_with_codes <- c("A10")
is_exactly_codes <- NULL

ben_table_name <- ben_ids_orauser
output_table_name <- "PD_DIAB_ATC_09_13"
r_output_path <- NULL


dispenses <- extract_dispenses(
  start_date = start_date,
  end_date = end_date,
  starts_with_codes = starts_with_codes,
  is_exactly_codes = is_exactly_codes,
  ben_table_name = ben_table_name,
  output_table_name = output_table_name,
  r_output_path = r_output_path
)

# Mediator must be excluded (cf CNAM methodology)
dispenses <- dispenses %>%
  rename_with(tolower) %>%
  filter(pha_atc_cla != "A10BX06")

has_hospital_stay <- selected_ben %>%
  inner_join(hospital_stays, by = "ben_idt_ano") %>%
  filter(
    exe_soi_dtd <= first_series_date &
      exe_soi_dtd >= (first_series_date - years(2))
  ) %>%
  select(ben_idt_ano) %>%
  distinct() %>%
  mutate(has_hospital_stay = TRUE)

has_ongoing_ald <- selected_ben %>%
  inner_join(ald, by = "ben_idt_ano") %>%
  filter(
    imb_ald_dtd <= first_series_date &
      imb_ald_dtf >= (first_series_date - years(2))
  ) %>%
  select(ben_idt_ano) %>%
  distinct() %>%
  mutate(has_ald = TRUE)

has_dispense <- selected_ben %>%
  inner_join(dispenses, by = "ben_idt_ano") %>%
  filter(
    exe_soi_dtd <= first_series_date &
      exe_soi_dtd >= (first_series_date - years(2))
  ) %>%
  select(ben_idt_ano, exe_soi_dtd) %>%
  group_by(ben_idt_ano) %>%
  summarise(n_dispenses = n_distinct(exe_soi_dtd)) %>%
  ungroup() %>%
  filter(n_dispenses >= 3) %>%
  select(ben_idt_ano) %>%
  distinct() %>%
  mutate(has_dispense = TRUE)

has_diabetes <- selected_ben %>%
  select(ben_idt_ano) %>%
  left_join(has_hospital_stay, by = "ben_idt_ano") %>%
  left_join(has_ongoing_ald, by = "ben_idt_ano") %>%
  left_join(has_dispense, by = "ben_idt_ano") %>%
  mutate(
    has_diabetes = ((!is.na(has_hospital_stay) & has_hospital_stay) |
      (!is.na(has_ald) & has_ald) |
      (!is.na(has_dispense) & has_dispense))
  ) %>%
  distinct()

saveRDS(
  has_diabetes,
  "~/sasdata1/pathologies-retrieval-snds/data/processed/has_diabetes.RDS"
)
