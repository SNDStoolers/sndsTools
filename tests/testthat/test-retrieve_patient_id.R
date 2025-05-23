require(dplyr)

# Create fake IR_BEN_R data
fake_ir_ben_r <- data.frame(
  BEN_IDT_ANO = c(1, 2, 3, 1),
  BEN_NIR_PSA = c(11, 12, 13, 14),
  BEN_RNG_GEM = c(1, 1, 1, 2),
  BEN_NIR_ANO = c("NIR001", "NIR002", "NIR003", "NIR001"),
  BEN_CDI_NIR = c("00", "00", "01", "00"),
  BEN_NAI_ANN = c(1990, 1985, 1992, 1990),
  BEN_NAI_MOI = c(5, 3, 8, 5),
  BEN_SEX_COD = c(1, 2, 1, 1),
  BEN_ORG_AFF = c("01", "01", "01", "02")
)

# Create fake IR_BEN_R_ARC data (archived)
fake_ir_ben_r_arc <- data.frame(
  BEN_IDT_ANO = c(4, 5),
  BEN_NIR_PSA = c(15, 16),
  BEN_RNG_GEM = c(1, 1),
  BEN_NIR_ANO = c("NIR004", "NIR005"),
  BEN_CDI_NIR = c("00", "00"),
  BEN_NAI_ANN = c(1988, 1995),
  BEN_NAI_MOI = c(2, 7),
  BEN_SEX_COD = c(2, 1),
  BEN_ORG_AFF = c("01", "01")
)

# Test input tables
fake_idt_input <- data.frame(
  BEN_IDT_ANO = c(1, 2, 3)
)

fake_psa_input <- data.frame(
  BEN_NIR_PSA = c(11, 12, 13),
  BEN_RNG_GEM = c(1, 1, 1)
)

fake_psa_input_no_rng <- data.frame(
  BEN_NIR_PSA = c(11, 12)
)

test_that("retrieve_all_psa_from_idt works", {
  conn <- connect_duckdb()

  # Set up test data
  DBI::dbWriteTable(conn, "IR_BEN_R", fake_ir_ben_r)
  DBI::dbWriteTable(conn, "IR_BEN_R_ARC", fake_ir_ben_r_arc)
  DBI::dbWriteTable(conn, "TEST_IDT_INPUT", fake_idt_input)

  # Test the function
  result <- retrieve_all_psa_from_idt(
    ben_table_name = "TEST_IDT_INPUT",
    conn = conn,
    check_arc_table = TRUE
  )

  DBI::dbDisconnect(conn)

  # Check that we got results
  expect_true(nrow(result) > 0)

  # Check that we have the expected BEN_IDT_ANO values
  expect_true(all(c(1, 2, 3) %in% result$BEN_IDT_ANO))

  # Check that logical columns exist and are logical
  expect_true(is.logical(result$psa_w_multiple_idt_or_nir))
  expect_true(is.logical(result$cdi_nir_00))
})

test_that("retrieve_all_psa_from_psa works", {
  conn <- connect_duckdb()

  # Set up test data
  DBI::dbWriteTable(conn, "IR_BEN_R", fake_ir_ben_r)
  DBI::dbWriteTable(conn, "IR_BEN_R_ARC", fake_ir_ben_r_arc)
  DBI::dbWriteTable(conn, "TEST_PSA_INPUT", fake_psa_input)

  # Test the function
  result <- retrieve_all_psa_from_psa(
    ben_table_name = "TEST_PSA_INPUT",
    conn = conn,
    check_arc_table = TRUE
  )

  DBI::dbDisconnect(conn)

  # Check that we got results
  expect_true(nrow(result) > 0)

  # Check that we have the expected BEN_NIR_PSA values
  expect_true(all(c(11, 12, 13) %in% result$BEN_NIR_PSA))
})
