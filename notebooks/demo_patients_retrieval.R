# Création et enregistrement dans Oracle d'un tibble de 100 BEN_IDT_ANO
idt_sample_1 <- dplyr::tbl(conn, "IR_BEN_R") |>
  dplyr::select(BEN_IDT_ANO) |>
  dplyr::distinct() |>
  head(100) |>
  dplyr::collect()
dbWriteTable(conn, "IDT_SAMP_1", idt_sample_1, overwrite = TRUE)
# Récupération de la table en format tibble
retrieve_all_psa_from_idt(conn = conn, ben_table_name = "IDT_SAMP_1")
# Récupération et enregistrement de la table dans Oracle
retrieve_all_psa_from_idt(
  conn = conn,
  ben_table_name = "IDT_SAMP_1",
  output_table_name = "TEST_SAVE_ORACLE"
)
# Récupération de la table sans considérer la table de référentiel archivée
retrieve_all_psa_from_idt(
  conn = conn,
  ben_table_name = "IDT_SAMP_1",
  check_arc_table = FALSE
)

# Création et enregistrement dans Oracle d'un tibble de 100 couples de (BEN_IDT_ANO + BEN_RNG_GEM)
idt_sample_2 <- dplyr::tbl(conn, "IR_BEN_R") |>
  dplyr::select(BEN_IDT_ANO, BEN_RNG_GEM) |>
  dplyr::distinct() |>
  head(100) |>
  dplyr::collect()
dbWriteTable(conn, "IDT_SAMP_2", idt_sample_2, overwrite = TRUE)
# Récupération de la table en format tibble
retrieve_all_psa_from_idt(conn = conn, ben_table_name = "IDT_SAMP_2")
# Récupération et enregistrement de la table dans Oracle
retrieve_all_psa_from_idt(
  conn = conn,
  ben_table_name = "IDT_SAMP_2",
  output_table_name = "TEST_SAVE_ORACLE"
)
# Récupération de la table sans considérer la table de référentiel archivée
retrieve_all_psa_from_idt(
  conn = conn,
  ben_table_name = "IDT_SAMP_2",
  check_arc_table = FALSE
)

# Création et enregistrement dans Oracle d'un tibble de 100 BEN_NIR_PSA
psa_sample_1 <- dplyr::tbl(conn, "IR_BEN_R") |>
  dplyr::select(BEN_NIR_PSA) |>
  head(100) |>
  dplyr::collect()
dbWriteTable(conn, "PSA_SAMP_1", psa_sample_1, overwrite = TRUE)
# Récupération de la table en format tibble
retrieve_all_psa_from_psa(conn = conn, ben_table_name = "PSA_SAMP_1")
# Récupération et enregistrement de la table dans Oracle
retrieve_all_psa_from_psa(conn = conn, ben_table_name = "PSA_SAMP_1", output_table_name = "TEST_SAVE_ORACLE")
# Récupération de la table sans considérer la table de référentiel archivée
retrieve_all_psa_from_psa(conn = conn, ben_table_name = "PSA_SAMP_1", check_arc_table = FALSE)

# Création et enregistrement dans Oracle de 100 couples de (BEN_NIR_PSA+BEN_RNG_GEM)
psa_sample_2 <- dplyr::tbl(conn, "IR_BEN_R") |>
  dplyr::select(BEN_NIR_PSA, BEN_RNG_GEM) |>
  head(100) |>
  dplyr::collect()
dbWriteTable(conn, "PSA_SAMP_2", psa_sample_2, overwrite = TRUE)
# Récupération de la table en format tibble
retrieve_all_psa_from_psa(conn = conn, ben_table_name = "PSA_SAMP_2")
# Récupération et enregistrement de la table dans Oracle
retrieve_all_psa_from_psa(
  conn = conn,
  ben_table_name = "PSA_SAMP_2",
  output_table_name = "TEST_SAVE_ORACLE"
)
# Récupération de la table sans considérer la table de référentiel archivée
retrieve_all_psa_from_psa(
  conn = conn,
  ben_table_name = "PSA_SAMP_2",
  check_arc_table = FALSE
)
