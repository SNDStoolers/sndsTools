library(sndsTools)
library(dplyr)

# - initialize_connection
# - extract_hospital_consultations

# Recherche toutes les consultations hospitalières pour les spécialités de médecine générale (01, 22, 23).

start_date <- as.Date("01/01/2019", format = "%d/%m/%Y")
end_date <- as.Date("31/12/2022", format = "%d/%m/%Y")
spe_codes <- c("01", "22", "23")

consultations <- extract_hospital_consultations(
  start_date = start_date,
  end_date = end_date,
  spe_codes = spe_codes,
)
consultations |> head()
