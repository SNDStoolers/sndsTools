require(dplyr)

# Jeux de données factices partagés par les tests.
# KI_CCI_R : circonstances et CAUSE INITIALE du décès (colonne DCD_CIM_COD)
#            -> lignes STATUS == "Initial cause".
# KI_ECD_R : ENSEMBLE DES CAUSES du décès (colonne ECD_CIM_COD)
#            -> lignes STATUS == "Other".
#
# extract_death() renvoie désormais UNE LIGNE PAR CODE CIM-10 et par patient.
# Un code déjà rapporté comme cause initiale n'est pas dupliqué en "Other".
#
# Patients :
#   P1 : cause initiale G20 (2015) ; autres causes G20, I10, E11
#        -> G20/Initial cause, E11/Other, I10/Other (G20 non dupliqué en Other)
#   P2 : cause initiale I50 (2016) ; autre cause J44
#        -> I50/Initial cause, J44/Other
#   P3 : cause initiale G10 (2005) ; hors période dans la plupart des tests
#   P5 : pas de cause initiale ; autres causes G20, X59 (2017)
#        -> G20/Other, X59/Other (aucune ligne "Initial cause")
#   P7 : cause initiale C50 (2018) ; aucune autre cause
#        -> C50/Initial cause uniquement
fake_ki_cci_r <- function() {
  data.frame(
    BEN_IDT_ANO = c("P1", "P2", "P3", "P7"),
    DCD_CIM_COD = c("G20", "I50", "G10", "C50"),
    BEN_DCD_DTE = as.Date(c(
      "2015-06-01",
      "2016-03-10",
      "2005-01-01",
      "2018-02-02"
    )),
    stringsAsFactors = FALSE
  )
}

fake_ki_ecd_r <- function() {
  data.frame(
    BEN_IDT_ANO = c("P1", "P1", "P1", "P2", "P3", "P5", "P5"),
    ECD_CIM_COD = c("G20", "I10", "E11", "J44", "G10", "G20", "X59"),
    BEN_DCD_DTE = as.Date(c(
      "2015-06-01",
      "2015-06-01",
      "2015-06-01",
      "2016-03-10",
      "2005-01-01",
      "2017-09-09",
      "2017-09-09"
    )),
    stringsAsFactors = FALSE
  )
}

setup_death_tables <- function() {
  conn <- connect_duckdb(PATH2TEST_DB)
  DBI::dbWriteTable(conn, "KI_CCI_R", fake_ki_cci_r(), overwrite = TRUE)
  DBI::dbWriteTable(conn, "KI_ECD_R", fake_ki_ecd_r(), overwrite = TRUE)
  conn
}

test_that("extract_death renvoie une ligne par code CIM-10 avec son STATUS", {
  conn <- setup_death_tables()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  result <- extract_death(
    start_date = as.Date("2010-01-01"),
    end_date = as.Date("2020-12-31"),
    diagnosis_codes = c("G10", "G20"),
    conn = conn
  )

  # P1 : cause initiale G20 ; autres codes E11/I10 (G20 non dupliqué en Other).
  # P5 : pas de cause initiale, retrouvé via "G20" -> ses codes G20/X59 en Other.
  # P3 (G10) est exclu car son décès (2005) est hors période.
  expect_equal(
    result |>
      dplyr::arrange(BEN_IDT_ANO, STATUS, CIM_COD) |>
      as.data.frame(),
    data.frame(
      BEN_IDT_ANO = c("P1", "P1", "P1", "P5", "P5"),
      EXE_SOI_DTD = as.Date(c(
        "2015-06-01",
        "2015-06-01",
        "2015-06-01",
        "2017-09-09",
        "2017-09-09"
      )),
      CIM_COD = c("G20", "E11", "I10", "G20", "X59"),
      STATUS = c(
        "Initial cause",
        "Other",
        "Other",
        "Other",
        "Other"
      ),
      stringsAsFactors = FALSE
    )
  )
})

test_that("extract_death ne duplique pas la cause initiale parmi les codes Other", {
  conn <- setup_death_tables()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  result <- extract_death(
    start_date = as.Date("2010-01-01"),
    end_date = as.Date("2020-12-31"),
    diagnosis_codes = "G20",
    conn = conn
  )

  p1 <- result |>
    dplyr::filter(BEN_IDT_ANO == "P1") |>
    dplyr::arrange(STATUS, CIM_COD)

  # G20 apparaît une seule fois, en "Initial cause".
  expect_equal(
    p1 |> dplyr::filter(CIM_COD == "G20") |> dplyr::pull(STATUS),
    "Initial cause"
  )
  # Les codes "Other" de P1 ne contiennent pas G20.
  other_codes <- p1 |>
    dplyr::filter(STATUS == "Other") |>
    dplyr::pull(CIM_COD)
  expect_setequal(other_codes, c("E11", "I10"))
})

test_that("extract_death ne produit que des lignes Other sans cause initiale", {
  conn <- setup_death_tables()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  # X59 n'apparaît que dans l'ensemble des causes de P5, qui n'a pas de cause
  # initiale -> uniquement des lignes "Other".
  result <- extract_death(
    start_date = as.Date("2010-01-01"),
    end_date = as.Date("2020-12-31"),
    diagnosis_codes = "X59",
    conn = conn
  )

  expect_setequal(result$BEN_IDT_ANO, "P5")
  expect_true(all(result$STATUS == "Other"))
  expect_setequal(result$CIM_COD, c("G20", "X59"))
})

test_that("extract_death sélectionne la cohorte via la cause initiale OU les autres causes", {
  conn <- setup_death_tables()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  # "E11" n'est ni une cause initiale ni un préfixe de cause initiale, mais c'est
  # un autre code de P1 -> P1 doit être sélectionné via ses codes "Other".
  result <- extract_death(
    start_date = as.Date("2010-01-01"),
    end_date = as.Date("2020-12-31"),
    diagnosis_codes = "E11",
    conn = conn
  )
  expect_setequal(result$BEN_IDT_ANO, "P1")

  # Recherche par préfixe : "G2" capture G20.
  result_prefix <- extract_death(
    start_date = as.Date("2010-01-01"),
    end_date = as.Date("2020-12-31"),
    diagnosis_codes = "G2",
    conn = conn
  )
  expect_setequal(unique(result_prefix$BEN_IDT_ANO), c("P1", "P5"))

  # Aucun code correspondant -> aucune ligne.
  result_empty <- extract_death(
    start_date = as.Date("2010-01-01"),
    end_date = as.Date("2020-12-31"),
    diagnosis_codes = "Z99",
    conn = conn
  )
  expect_equal(nrow(result_empty), 0L)
})

test_that("extract_death filtre sur les deux bornes de la période", {
  conn <- setup_death_tables()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  # Borne haute : période 2015 -> seul P1 (2015).
  upper <- extract_death(
    start_date = as.Date("2015-01-01"),
    end_date = as.Date("2015-12-31"),
    conn = conn
  )
  expect_setequal(unique(upper$BEN_IDT_ANO), "P1")

  # Borne basse : à partir de 2016 -> P1 (2015) exclu.
  lower <- extract_death(
    start_date = as.Date("2016-01-01"),
    end_date = as.Date("2020-12-31"),
    conn = conn
  )
  expect_setequal(unique(lower$BEN_IDT_ANO), c("P2", "P5", "P7"))
})

test_that("extract_death sans diagnosis_codes extrait tous les décès de la période", {
  conn <- setup_death_tables()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  result <- extract_death(
    start_date = as.Date("2010-01-01"),
    end_date = as.Date("2020-12-31"),
    conn = conn
  )

  # Tous les patients sauf P3 (décédé en 2005, hors période).
  expect_setequal(unique(result$BEN_IDT_ANO), c("P1", "P2", "P5", "P7"))

  # P7 a une cause initiale mais aucune autre cause -> une seule ligne.
  p7 <- result |> dplyr::filter(BEN_IDT_ANO == "P7")
  expect_equal(nrow(p7), 1L)
  expect_equal(p7$CIM_COD, "C50")
  expect_equal(p7$STATUS, "Initial cause")

  # P2 : cause initiale I50, autre code J44.
  p2 <- result |>
    dplyr::filter(BEN_IDT_ANO == "P2") |>
    dplyr::arrange(STATUS, CIM_COD)
  expect_equal(p2$CIM_COD, c("I50", "J44"))
  expect_equal(p2$STATUS, c("Initial cause", "Other"))
})

test_that("extract_death sauvegarde dans une table si output_table_name fourni", {
  conn <- setup_death_tables()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  output_table_name <- "TMP_TEST_DEATH_OUT"
  if (DBI::dbExistsTable(conn, output_table_name)) {
    DBI::dbRemoveTable(conn, output_table_name)
  }
  on.exit(
    try(DBI::dbRemoveTable(conn, output_table_name), silent = TRUE),
    add = TRUE
  )

  result <- extract_death(
    start_date = as.Date("2010-01-01"),
    end_date = as.Date("2020-12-31"),
    diagnosis_codes = c("G10", "G20"),
    output_table_name = output_table_name,
    conn = conn
  )

  expect_null(result)
  expect_true(DBI::dbExistsTable(conn, output_table_name))

  saved <- dplyr::tbl(conn, output_table_name) |>
    dplyr::collect()
  expect_setequal(unique(saved$BEN_IDT_ANO), c("P1", "P5"))

  # P1 : G20 en cause initiale, E11/I10 en Other.
  p1 <- saved |>
    dplyr::filter(BEN_IDT_ANO == "P1") |>
    dplyr::arrange(STATUS, CIM_COD)
  expect_equal(p1$CIM_COD, c("G20", "E11", "I10"))
  expect_equal(
    p1$STATUS,
    c("Initial cause", "Other", "Other")
  )
})

test_that("extract_death valide ses arguments", {
  conn <- setup_death_tables()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  # start_date postérieure à end_date
  expect_error(
    extract_death(
      start_date = as.Date("2020-01-01"),
      end_date = as.Date("2019-01-01"),
      conn = conn
    )
  )
  # dates non Date
  expect_error(
    extract_death(
      start_date = "2019-01-01",
      end_date = as.Date("2020-01-01"),
      conn = conn
    )
  )
  # diagnosis_codes non character
  expect_error(
    extract_death(
      start_date = as.Date("2010-01-01"),
      end_date = as.Date("2020-12-31"),
      diagnosis_codes = 20,
      conn = conn
    )
  )
})

# -----------------------------------------------------------------------------
# extract_death_from_ids() : même sortie que extract_death(), mais en entrée une
# liste d'identifiants patients. Les patients vivants (aucun code CIM-10 dans la
# période) sont restitués sur une ligne STATUS == "Alive" (CIM_COD/EXE_SOI_DTD
# à NA). P9 n'existe dans aucune table -> patient "vivant".
# -----------------------------------------------------------------------------

test_that("extract_death_from_ids renvoie les codes des décédés et marque les vivants", {
  conn <- setup_death_tables()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  result <- extract_death_from_ids(
    patient_ids = c("P1", "P5", "P7", "P9"),
    start_date = as.Date("2010-01-01"),
    end_date = as.Date("2020-12-31"),
    conn = conn
  )

  expect_equal(
    result |>
      dplyr::arrange(BEN_IDT_ANO, STATUS, CIM_COD) |>
      as.data.frame(),
    data.frame(
      BEN_IDT_ANO = c("P1", "P1", "P1", "P5", "P5", "P7", "P9"),
      EXE_SOI_DTD = as.Date(c(
        "2015-06-01",
        "2015-06-01",
        "2015-06-01",
        "2017-09-09",
        "2017-09-09",
        "2018-02-02",
        NA
      )),
      CIM_COD = c("G20", "E11", "I10", "G20", "X59", "C50", NA),
      STATUS = c(
        "Initial cause",
        "Other",
        "Other",
        "Other",
        "Other",
        "Initial cause",
        "Alive"
      ),
      stringsAsFactors = FALSE
    )
  )
})

test_that("extract_death_from_ids marque comme Alive un id absent des tables", {
  conn <- setup_death_tables()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  result <- extract_death_from_ids(
    patient_ids = "P9",
    start_date = as.Date("2010-01-01"),
    end_date = as.Date("2020-12-31"),
    conn = conn
  )

  expect_equal(nrow(result), 1L)
  expect_equal(result$BEN_IDT_ANO, "P9")
  expect_equal(result$STATUS, "Alive")
  expect_true(is.na(result$CIM_COD))
  expect_true(is.na(result$EXE_SOI_DTD))
})

test_that("extract_death_from_ids traite un décès hors période comme Alive", {
  conn <- setup_death_tables()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  # P3 est décédé en 2005 : hors de la période 2010-2020 -> Alive.
  out_of_period <- extract_death_from_ids(
    patient_ids = "P3",
    start_date = as.Date("2010-01-01"),
    end_date = as.Date("2020-12-31"),
    conn = conn
  )
  expect_equal(nrow(out_of_period), 1L)
  expect_equal(out_of_period$STATUS, "Alive")

  # Dans une période couvrant 2005, P3 est bien décédé (cause initiale G10).
  in_period <- extract_death_from_ids(
    patient_ids = "P3",
    start_date = as.Date("2000-01-01"),
    end_date = as.Date("2010-12-31"),
    conn = conn
  )
  expect_equal(nrow(in_period), 1L)
  expect_equal(in_period$CIM_COD, "G10")
  expect_equal(in_period$STATUS, "Initial cause")
})

test_that("extract_death_from_ids ne duplique pas la cause initiale parmi les Other", {
  conn <- setup_death_tables()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  result <- extract_death_from_ids(
    patient_ids = "P1",
    start_date = as.Date("2010-01-01"),
    end_date = as.Date("2020-12-31"),
    conn = conn
  )

  expect_equal(
    result |> dplyr::filter(CIM_COD == "G20") |> dplyr::pull(STATUS),
    "Initial cause"
  )
  other_codes <- result |>
    dplyr::filter(STATUS == "Other") |>
    dplyr::pull(CIM_COD)
  expect_setequal(other_codes, c("E11", "I10"))
})

test_that("extract_death_from_ids dédoublonne les identifiants fournis", {
  conn <- setup_death_tables()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  result <- extract_death_from_ids(
    patient_ids = c("P1", "P1", "P9"),
    start_date = as.Date("2010-01-01"),
    end_date = as.Date("2020-12-31"),
    conn = conn
  )

  # P1 n'apparaît que via ses 3 codes (pas 6), P9 sur une ligne Alive.
  expect_equal(sum(result$BEN_IDT_ANO == "P1"), 3L)
  expect_equal(sum(result$BEN_IDT_ANO == "P9"), 1L)
})

test_that("extract_death_from_ids sauvegarde dans une table si output_table_name fourni", {
  conn <- setup_death_tables()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  output_table_name <- "TMP_TEST_DEATH_IDS_OUT"
  if (DBI::dbExistsTable(conn, output_table_name)) {
    DBI::dbRemoveTable(conn, output_table_name)
  }
  on.exit(
    try(DBI::dbRemoveTable(conn, output_table_name), silent = TRUE),
    add = TRUE
  )

  result <- extract_death_from_ids(
    patient_ids = c("P1", "P9"),
    start_date = as.Date("2010-01-01"),
    end_date = as.Date("2020-12-31"),
    output_table_name = output_table_name,
    conn = conn
  )

  expect_null(result)
  expect_true(DBI::dbExistsTable(conn, output_table_name))

  saved <- dplyr::tbl(conn, output_table_name) |> dplyr::collect()
  expect_setequal(unique(saved$BEN_IDT_ANO), c("P1", "P9"))

  p9 <- saved |> dplyr::filter(BEN_IDT_ANO == "P9")
  expect_equal(p9$STATUS, "Alive")
  expect_true(is.na(p9$CIM_COD))
})

test_that("extract_death_from_ids valide ses arguments", {
  conn <- setup_death_tables()
  on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)

  # patient_ids non character
  expect_error(
    extract_death_from_ids(
      patient_ids = c(1, 2),
      start_date = as.Date("2010-01-01"),
      end_date = as.Date("2020-12-31"),
      conn = conn
    )
  )
  # patient_ids vide
  expect_error(
    extract_death_from_ids(
      patient_ids = character(0),
      start_date = as.Date("2010-01-01"),
      end_date = as.Date("2020-12-31"),
      conn = conn
    )
  )
  # start_date postérieure à end_date
  expect_error(
    extract_death_from_ids(
      patient_ids = "P1",
      start_date = as.Date("2020-01-01"),
      end_date = as.Date("2019-01-01"),
      conn = conn
    )
  )
})
