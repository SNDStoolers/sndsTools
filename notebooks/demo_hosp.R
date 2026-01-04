start_date <- as.Date("01/01/2009", format = "%d/%m/%Y")
end_date <- as.Date("31/12/2013", format = "%d/%m/%Y")

dp_cim10_codes_starts_with <- c("C")
or_dr_with_same_codes <- FALSE
or_da_with_same_codes <- FALSE
and_da_with_other_codes <- FALSE
da_cim10_codes_starts_with <- NULL

ben_table_name <- "PD_10_22_IDS"
output_table_name <- "TEST_HOSPITAL_STAYS"
r_output_path <- "~/sasdata1/park/visualize/data/raw"

extract_hospital_stays(
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
