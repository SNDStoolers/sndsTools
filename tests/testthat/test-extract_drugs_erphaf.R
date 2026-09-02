require(dplyr)

# nolint start
fake_patients_ids <- tibble::tribble(
  ~BEN_IDT_ANO , ~BEN_NIR_PSA , ~BEN_RNG_GEM ,
             1 ,           11 ,            1 ,
             2 ,           12 ,            1 ,
             3 ,           13 ,            1
)
fake_dcir_join_keys <- tibble::tribble(
  ~DCT_ORD_NUM , ~FLX_EMT_ORD , ~FLX_EMT_NUM , ~FLX_EMT_TYP , ~ORG_CLE_NUM , ~PRS_ORD_NUM , ~REM_TYP_AFF , ~FLX_DIS_DTD , ~FLX_TRT_DTD ,
             1 ,            1 ,            1 ,            1 ,            1 ,            1 ,            1 , "2019-02-10" , "2019-01-10" ,
             2 ,            1 ,            1 ,            1 ,            1 ,            1 ,            1 , "2019-02-02" , "2019-01-02" ,
             3 ,            1 ,            1 ,            1 ,            1 ,            1 ,            1 , "2019-02-03" , "2019-01-03" ,
             4 ,            1 ,            1 ,            1 ,            1 ,            1 ,            1 , "2020-02-05" , "2020-01-05" ,
             5 ,            1 ,            1 ,            1 ,            1 ,            1 ,            1 , "2019-02-04" , "2019-01-04"
) |>
  dplyr::mutate(
    across(c(FLX_DIS_DTD, FLX_TRT_DTD), as.Date)
  )


fake_erprsf <- tibble::tribble(
  ~BEN_NIR_PSA , ~BEN_RNG_GEM , ~EXE_SOI_DTD , ~PSP_SPE_COD , ~DPN_QLF , ~CPL_MAJ_TOP ,
            11 ,            1 , "2019-01-10" , "01"         ,        0 ,            0 ,
            12 ,            1 , "2019-01-02" , "22"         ,        0 ,            0 ,
            13 ,            1 , "2019-01-03" , "32"         ,        0 ,            0 ,
            15 ,            1 , "2020-01-05" , "34"         ,        0 ,            1 ,
            13 ,            1 , "2019-01-04" , "01"         ,       71 ,            2
) |>
  dplyr::bind_cols(fake_dcir_join_keys) |>
  dplyr::mutate(
    across(c(EXE_SOI_DTD), as.Date)
  )

fake_eretef <- tibble::tribble(
  ~ETE_NUM , ~ETE_IND_TAA ,
        11 ,           10 ,
        12 ,           10 ,
        13 ,           10
) |>
  dplyr::bind_cols(fake_dcir_join_keys |> head(3))

fake_erphaf <- tibble::tribble(
  ~PHA_PRS_C13    , ~PHA_ACT_QSN ,
  "3400932026555" ,            1 ,
  "3400932725847" ,            1 ,
  "3400930219874" ,            1 ,
  "3400930219874" ,            1 ,
  "3400936267343" ,            1
) |>
  dplyr::bind_cols(fake_dcir_join_keys)

fake_irphar <- tibble::tribble(
  ~PHA_CIP_C13    , ~PHA_ATC_CLA ,
  "3400932026555" , "N04BC01"    ,
  "3400932725847" , "N05AC01"    ,
  "3400930219874" , "J05AG05"    ,
  "3400930219874" , "J05AG05"    ,
  "3400936267343" , "J01MA06"
)
# nolint end

conn <- connect_synthetic_snds()
on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

DBI::dbWriteTable(conn, "ER_PHA_F", fake_erphaf, overwrite = TRUE)
DBI::dbWriteTable(conn, "IR_PHA_R", fake_irphar, overwrite = TRUE)
DBI::dbWriteTable(conn, "ER_PRS_F", fake_erprsf, overwrite = TRUE)
DBI::dbWriteTable(conn, "ER_ETE_F", fake_eretef, overwrite = TRUE)

test_that("extract_drugs_erphaf works for ATC", {
  start_date <- as.Date("01/01/2019", format = "%d/%m/%Y")
  end_date <- as.Date("31/12/2019", format = "%d/%m/%Y")

  drug_dispenses <- extract_drugs_erphaf(
    start_date = start_date,
    end_date = end_date,
    atc_cod_starts_with_filter = c("J05"),
    patients_ids = fake_patients_ids,
    conn = conn
  ) |>
    dplyr::collect()

  expected_drug_dispenses <- tibble::tribble(
    ~BEN_IDT_ANO , ~EXE_SOI_DTD          , ~FLX_DIS_DTD          , ~PHA_ACT_QSN , ~PHA_ATC_CLA , ~PHA_PRS_C13    , ~PSP_SPE_COD , ~BEN_RNG_GEM ,
               3 , as.Date("2019-01-03") , as.Date("2019-02-03") ,            1 , "J05AG05"    , "3400930219874" , "32"         ,            1
  )
  expect_equal(
    drug_dispenses |> dplyr::arrange(BEN_IDT_ANO, EXE_SOI_DTD),
    expected_drug_dispenses
  )
})

test_that("extract_drugs_erphaf works for CIP13", {
  start_date <- as.Date("01/01/2019", format = "%d/%m/%Y")
  end_date <- as.Date("31/12/2019", format = "%d/%m/%Y")

  drug_dispenses <- extract_drugs_erphaf(
    start_date = start_date,
    end_date = end_date,
    atc_cod_starts_with_filter = c("J05"),
    cip13_cod_filter = c("3400932725847"),
    patients_ids = fake_patients_ids,
    conn = conn
  ) |>
    dplyr::collect()
  # nolint start
  expected_drug_dispenses <- tibble::tribble(
    ~BEN_IDT_ANO , ~EXE_SOI_DTD          , ~FLX_DIS_DTD          , ~PHA_ACT_QSN , ~PHA_ATC_CLA , ~PHA_PRS_C13    , ~PSP_SPE_COD , ~BEN_RNG_GEM ,
               2 , as.Date("2019-01-02") , as.Date("2019-02-02") ,            1 , "N05AC01"    , "3400932725847" , "22"         ,            1 ,
               3 , as.Date("2019-01-03") , as.Date("2019-02-03") ,            1 , "J05AG05"    , "3400930219874" , "32"         ,            1
  )
  # nolint end
  expect_equal(
    drug_dispenses |> dplyr::arrange(BEN_IDT_ANO, EXE_SOI_DTD),
    expected_drug_dispenses
  )
})

test_that("une prestation portant une ligne ER_ETE_F en T2A est exclue", {
  # ER_ETE_F peut porter plusieurs lignes par prestation. Dès que l'une d'elles
  # est en T2A (ETE_IND_TAA == 1), la délivrance est déjà comptée dans le PMSI
  # et doit être exclue, même si une autre ligne de la même prestation ne l'est
  # pas.
  eretef_with_taa <- fake_eretef |>
    dplyr::bind_rows(
      fake_eretef |>
        dplyr::filter(DCT_ORD_NUM == 3) |>
        dplyr::mutate(ETE_NUM = 99, ETE_IND_TAA = 1)
    )
  DBI::dbWriteTable(conn, "ER_ETE_F", eretef_with_taa, overwrite = TRUE)
  on.exit(DBI::dbWriteTable(conn, "ER_ETE_F", fake_eretef, overwrite = TRUE))

  drug_dispenses <- extract_drugs_erphaf(
    start_date = as.Date("2019-01-01"),
    end_date = as.Date("2019-12-31"),
    atc_cod_starts_with_filter = c("J05"),
    conn = conn
  ) |>
    dplyr::collect()

  expect_equal(nrow(drug_dispenses), 0)
})

test_that("le référentiel médicament filtré est unique par CIP13", {
  # IR_PHA_R contient plusieurs lignes par CIP13. Sans dédoublonnage, la
  # jointure avec ER_PHA_F multiplie les lignes, et le distinct final ne
  # rattrape le tir qu'après les trois jointures.
  extract_drugs_erphaf(
    start_date = as.Date("2019-01-01"),
    end_date = as.Date("2019-12-31"),
    atc_cod_starts_with_filter = c("J05"),
    conn = conn
  )

  # La table temporaire au timestamp le plus récent est celle qu'on vient de créer.
  tmp_ir_pha_r <- DBI::dbListTables(conn) |>
    grep(pattern = "^TMP_IR_PHA_R_", value = TRUE) |>
    sort() |>
    utils::tail(1)
  filtered_ref <- dplyr::tbl(conn, tmp_ir_pha_r) |> dplyr::collect()

  expect_equal(nrow(filtered_ref), dplyr::n_distinct(filtered_ref$PHA_CIP_C13))
})
