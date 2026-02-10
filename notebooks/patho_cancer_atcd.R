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

cancer_codes <- c(
  "C",
  "D00",
  "D01",
  "D02",
  "D03",
  "D04",
  "D05",
  "D06",
  "D07",
  "D08",
  "D09"
)

retrieval_start_date <- as.Date("01/01/2009", format = "%d/%m/%Y")
retrieval_end_date <- as.Date("31/12/2013", format = "%d/%m/%Y")


start_date <- retrieval_start_date
end_date <- retrieval_end_date

dp_cim10_codes_starts_with <- cancer_codes
or_dr_with_same_codes <- TRUE
or_da_with_same_codes <- FALSE
and_da_with_other_codes <- FALSE
da_cim10_codes_starts_with <- NULL

ben_table_name <- ben_ids_orauser
output_table_name <- NULL
r_output_path <- NULL

hospital_stays <- extract_hospital_stays(
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

hospital_stays <- hospital_stays %>%
  rename_with(tolower) %>%
  select(ben_idt_ano, exe_soi_dtd, dgn_pal, dgn_rel) %>%
  distinct()


start_date <- retrieval_start_date
end_date <- retrieval_end_date

icd_cod_starts_with <- cancer_codes
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


has_cancer_atcd <- selected_ben %>%
  select(ben_idt_ano) %>%
  left_join(has_hospital_stay, by = "ben_idt_ano") %>%
  left_join(has_ongoing_ald, by = "ben_idt_ano") %>%
  mutate(
    has_cancer_atcd = ((!is.na(has_hospital_stay) & has_hospital_stay) |
      (!is.na(has_ald) & has_ald))
  ) %>%
  distinct()

saveRDS(
  has_cancer_atcd,
  "~/sasdata1/pathologies-retrieval-snds/data/processed/has_cancer_atcd.RDS"
)
