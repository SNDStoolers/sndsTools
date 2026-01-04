## library(ROracle)
library(dplyr)
library(dbplyr)
library(DBI)
library(glue)
library(lubridate)
# source("~/sasdata1/pathologies-retrieval-snds/common/utils.R")
# source("~/sasdata1/pathologies-retrieval-snds/common/retrieve_hosp.R")
# source("~/sasdata1/pathologies-retrieval-snds/common/retrieve_ald.R")
# source("~/sasdata1/pathologies-retrieval-snds/common/retrieve_atc.R")

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

antihypertensive_codes <- c(
  "C02AB02",
  "C02AC01",
  "C02AC02",
  "C02AC05",
  "C02AC06",
  "C02CA01",
  "C02CA06",
  "C02DC01",
  "C02LA01",
  "C03AA01",
  "C03AA03",
  "C03BA04",
  "C03BA10",
  "C03BA11",
  "C03BX03",
  "C03CA01",
  "C03CA02",
  "C03CA03",
  "C03DA01",
  "C03DB01",
  "C03EA01",
  "C03EA04",
  "C07AA02",
  "C07AA03",
  "C07AA05",
  "C07AA06",
  "C07AA12",
  "C07AA15",
  "C07AA16",
  "C07AA23",
  "C07AB02",
  "C07AB03",
  "C07AB04",
  "C07AB05",
  "C07AB07",
  "C07AB08",
  "C07AB12",
  "C07AG01",
  "C07BA02",
  "C07BB02",
  "C07BB03",
  "C07BB07",
  "C07BB12",
  "C07CA03",
  "C07DA06",
  "C07FB02",
  "C07FB03",
  "C08CA01",
  "C08CA02",
  "C08CA03",
  "C08CA04",
  "C08CA05",
  "C08CA08",
  "C08CA09",
  "C08CA11",
  "C08CA13",
  "C08CX01",
  "C08DA01",
  "C08DB01",
  "C08GA02",
  "C09AA01",
  "C09AA02",
  "C09AA03",
  "C09AA04",
  "C09AA05",
  "C09AA06",
  "C09AA07",
  "C09AA08",
  "C09AA09",
  "C09AA10",
  "C09AA13",
  "C09AA15",
  "C09AA16",
  "C09BA01",
  "C09BA02",
  "C09BA03",
  "C09BA04",
  "C09BA05",
  "C09BA06",
  "C09BA07",
  "C09BA09",
  "C09BA15",
  "C09BB02",
  "C09BB04",
  "C09BB07",
  "C09BB10",
  "C09BX02",
  "C09CA01",
  "C09CA02",
  "C09CA03",
  "C09CA04",
  "C09CA06",
  "C09CA07",
  "C09CA08",
  "C09DA01",
  "C09DA02",
  "C09DA03",
  "C09DA04",
  "C09DA06",
  "C09DA07",
  "C09DA08",
  "C09DB01",
  "C09DB02",
  "C09DB04",
  "C09XA02",
  "C09XA52",
  "C10BX03"
)


start_date <- retrieval_start_date
end_date <- retrieval_end_date

starts_with_codes <- antihypertensive_codes
is_exactly_codes <- NULL

ben_table_name <- ben_ids_orauser
output_table_name <- "PD_HYPERT_ATC_09_13"
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

dispenses <- dispenses %>%
  rename_with(tolower)


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

has_antihypertens <- selected_ben %>%
  select(ben_idt_ano) %>%
  left_join(has_dispense, by = "ben_idt_ano") %>%
  mutate(
    has_antihypertens = (!is.na(has_dispense) & has_dispense)
  ) %>%
  distinct()

saveRDS(
  has_antihypertens,
  "~/sasdata1/pathologies-retrieval-snds/data/processed/has_antihypertens.RDS"
)
