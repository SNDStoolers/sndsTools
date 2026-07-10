test_that("extract and retrieve functions work with real SNDS data", {
  library(testthat)
  skip_if(!dir.exists("~/sasdata1"))
  source(here::here("sndsTools.R"))

  # Connection to Oracle
  conn <- connect_oracle()

  # Define a short time period (1 week) for quick extraction
  start_date <- as.Date("2023-01-01")
  end_date <- as.Date("2023-01-01")

  # Test : extract_drugs_erphaf with dis_dtd_lag_months = 1
  result_drug_dispenses <- extract_drugs_erphaf(
    conn,
    start_date,
    end_date,
    atc_cod_starts_with_filter = "N",
    dis_dtd_lag_months = 1
  ) |>
    dplyr::collect()
  expect_true(is.data.frame(result_drug_dispenses))
  expect_true(nrow(result_drug_dispenses) > 0)

  # Test : extract_drugs_erucdf with dis_dtd_lag_months = 0 and UCD filter
  result_drug_erucdf <- extract_drugs_erucdf(
    conn,
    start_date,
    end_date = as.Date("2023-01-31"),
    ucd_codes_filter = c("0000009419723"),
    dis_dtd_lag_months = 1
  ) |>
    dplyr::collect()
  expect_true(is.data.frame(result_drug_erucdf))
  expect_true(nrow(result_drug_erucdf) > 0)

  # Test : extract_consultations_erprsf with dis_dtd_lag_months = 1
  result_consultations_erprsf <- extract_consultations_erprsf(
    conn,
    start_date,
    end_date,
    pse_spe_filter = c("01"),
    dis_dtd_lag_months = 1
  ) |>
    dplyr::collect()
  expect_true(is.data.frame(result_consultations_erprsf))
  expect_true(nrow(result_consultations_erprsf) > 0)

  # Test : extract_stays_mcob
  result_hospital_stays <- extract_stays_mcob(
    conn,
    start_date,
    end_date,
    dp_cim10_codes_filter = c("A00", "B00")
  ) |>
    dplyr::collect()
  expect_true(is.data.frame(result_hospital_stays))
  expect_true(nrow(result_hospital_stays) > 0)

  # Test : extract_consultations_mcofcstc
  result_hospital_consultations <- extract_consultations_mcofcstc(
    conn,
    start_date,
    end_date,
    spe_codes_filter = c("01")
  ) |>
    dplyr::collect()
  expect_true(is.data.frame(result_hospital_consultations))
  expect_true(nrow(result_hospital_consultations) > 0)
  # Test : extract_stays_ssr
  result_stays_ssr <- extract_stays_ssr(
    conn,
    start_date,
    end_date,
    dp_cim10_codes_filter = c("I")
  ) |>
    dplyr::collect()
  expect_true(is.data.frame(result_stays_ssr))
  expect_true(nrow(result_stays_ssr) > 0)

  # Test : extract_longtermdiseases_irimbr
  result_long_term_disease <- extract_longtermdiseases_irimbr(
    conn,
    start_date,
    end_date,
    icd_cod_starts_with = c("G20")
  ) |>
    head(n = 100) |>
    dplyr::collect()
  expect_true(is.data.frame(result_long_term_disease))
  expect_true(nrow(result_long_term_disease) > 0)
  # Test: extract_ij_erprsf
  result_ij_erprsf <- extract_ij_erprsf(
    start_date = start_date,
    end_date = end_date,
    patients_ids_filter = NULL,
    conn = conn
  )
  expect_true(is.data.frame(result_ij_erprsf))
  expect_true(nrow(result_ij_erprsf) > 0)
  # Test : retrieve_all_psa_from_idt
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
    ) |>
      dplyr::collect()
    expect_true(is.data.frame(result_psa_from_idt))
    expect_true(nrow(result_psa_from_idt) >= 0)

    # Test : retrieve_all_psa_from_psa

    result_psa_from_psa <- retrieve_all_psa_from_psa(
      ben_table_name = test_table_name,
      conn = conn
    ) |>
      dplyr::collect()
    expect_true(is.data.frame(result_psa_from_psa))
    expect_true(nrow(result_psa_from_psa) >= 0)

    # Clean up test table
    try(DBI::dbRemoveTable(conn, test_table_name), silent = TRUE)
  }
})


test_that("write_oracle_by_batch écrit correctement les données avec de vraies données DCIR", {
  library(testthat)
  skip_if(!dir.exists("~/sasdata1"))
  source(here::here("sndsTools.R"))

  # Connection to Oracle
  conn <- connect_oracle()

  # Define a short time period (1 week) for quick extraction
  start_date <- as.Date("2023-01-01")
  end_date <- as.Date("2023-04-01")

  # Test : extract_drugs_erphaf with dis_dtd_lag_months = 0
  lazy_df <- extract_drugs_erphaf(
    conn,
    start_date,
    end_date,
    atc_cod_starts_with_filter = "N02AA05" # oxycodone (should not be prescribed a lot)
  )
  output_table_name <- "TEST_DRUGS_DF"
  write_oracle_table_by_batch(
    conn,
    lazy_df,
    output_table_name,
    start_date = start_date,
    end_date = end_date,
    batch_colname = "FLX_DIS_DTD",
    batch_by = "month"
  ) # 4 min pour cette requête.
  new_table <- conn |> dplyr::tbl(output_table_name)
  # conn |> DBI::dbRemoveTable(output_table_name)
  expect_true(inherits(new_table, "tbl_lazy"))
  expect_true(new_table |> dplyr::tally() |> dplyr::pull("n") > 0)

  # Close connection
  DBI::dbDisconnect(conn)
})


test_that("write_oracle_by_batch écrit correctement les données avec de vraies données PMSI", {
  library(testthat)
  skip_if(!dir.exists("~/sasdata1"))
  source(here::here("sndsTools.R"))

  # Connection to Oracle
  conn <- connect_oracle()

  # Define a short time period (1 week) for quick extraction
  start_date <- as.Date("2023-01-01")
  end_date <- as.Date("2024-01-01")

  # Test : extract_stays_mcob with dis_dtd_lag_months = 0
  lazy_df <- extract_stays_mcob(
    conn,
    start_date,
    end_date,
    dp_cim10_codes_filter = c("E10") # diabète de type 1
  )
  output_table_name <- "TEST_STAYS_MCOB"
  write_oracle_table_by_batch(
    conn,
    lazy_df,
    output_table_name,
    start_date = start_date,
    end_date = end_date,
    batch_colname = "EXE_SOI_DTD",
    batch_by = "year"
  ) # ~3min for 2023 year
  new_table <- conn |> dplyr::tbl(output_table_name)
  # conn |> DBI::dbRemoveTable(output_table_name)
  expect_true(inherits(new_table, "tbl_lazy"))
  expect_true(new_table |> dplyr::tally() |> dplyr::pull("n") > 0)

  # Close connection
  DBI::dbDisconnect(conn)
})
