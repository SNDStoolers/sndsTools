test_that("extract and retrieve functions work with real SNDS data", {
  cons <- constants_snds_tools()
  skip_if(!cons$is_portail)
  source("sndsTools.R")
  source("debug.R")
  library(testthat)
  # Connection to Oracle
  conn <- connect_oracle()

  # Define a short time period (1 week) for quick extraction
  start_date <- as.Date("2023-01-01")
  end_date <- as.Date("2023-01-01")

  # Test 1: extract_hospital_stays
  result_hospital_stays <- extract_hospital_stays(
    start_date = start_date,
    end_date = end_date,
    dp_cim10_codes = c("A00", "B00"),
    conn = conn
  )
  expect_true(is.data.frame(result_hospital_stays))
  expect_true(nrow(result_hospital_stays) >= 0)

  # Test 2: extract_drug_dispenses with dis_dtd_lag_months = 0
  result_drug_dispenses <- extract_drug_dispenses(
    start_date = start_date,
    end_date = end_date,
    atc_cod_starts_with_filter = "N04A",
    dis_dtd_lag_months = 0,
    conn = conn,
    show_sql_query = FALSE
  )
  expect_true(is.data.frame(result_drug_dispenses))
  expect_true(nrow(result_drug_dispenses) >= 0)

  # Test 3: extract_consultations_erprsf with dis_dtd_lag_months = 0
  result_consultations_erprsf <- extract_consultations_erprsf(
    start_date = start_date,
    end_date = end_date,
    pse_spe_filter = c("01"),
    dis_dtd_lag_months = 0,
    conn = conn
  )
  expect_true(is.data.frame(result_consultations_erprsf))
  expect_true(nrow(result_consultations_erprsf) >= 0)

  # Test 4: extract_hospital_consultations
  result_hospital_consultations <- extract_hospital_consultations(
    start_date = start_date,
    end_date = end_date,
    spe_codes_filter = c("01"),
    conn = conn
  )
  expect_true(is.data.frame(result_hospital_consultations))
  expect_true(nrow(result_hospital_consultations) >= 0)

  # Test 5: extract_long_term_disease
  result_long_term_disease <- extract_long_term_disease(
    start_date = start_date,
    end_date = end_date,
    icd_cod_starts_with = c("G20"),
    conn = conn
  )
  expect_true(is.data.frame(result_long_term_disease))
  expect_true(nrow(result_long_term_disease) >= 0)

  # Test 6: retrieve_all_psa_from_idt
  # Small test table with patient IDs from referentiel beneficiaires
  if (nrow(result_hospital_stays) > 0) {
    # Take first 10 patients
    test_patients <- dplyr::tbl(conn, "IR_BEN_R") |>
      dplyr::select(BEN_IDT_ANO, BEN_NIR_PSA) |>
      head(10) |>
      dplyr::collect()
    test_table_name <- paste0(
      "TMP_TEST_PATIENTS_",
      format(Sys.time(), "%Y%m%d_%H%M%S")
    )
    DBI::dbWriteTable(conn, test_table_name, test_patients)

    result_psa_from_idt <- retrieve_all_psa_from_idt(
      ben_table_name = test_table_name,
      conn = conn
    )
    expect_true(is.data.frame(result_psa_from_idt))
    expect_true(nrow(result_psa_from_idt) >= 0)

    # Test 7: retrieve_all_psa_from_psa

    result_psa_from_psa <- retrieve_all_psa_from_psa(
      ben_table_name = test_table_name,
      conn = conn
    )
    expect_true(is.data.frame(result_psa_from_psa))
    expect_true(nrow(result_psa_from_psa) >= 0)

    # Clean up test table
    try(DBI::dbRemoveTable(conn, test_table_name), silent = TRUE)
  }

  # Close connection
  DBI::dbDisconnect(conn)
})
