finess_out <- c(
  "130780521", "130783236", "130783293", "130784234", "130804297",
  "600100101", "750041543", "750100018", "750100042", "750100075",
  "750100083", "750100091", "750100109", "750100125", "750100166",
  "750100208", "750100216", "750100232", "750100273", "750100299",
  "750801441", "750803447", "750803454", "910100015", "910100023",
  "920100013", "920100021", "920100039", "920100047", "920100054",
  "920100062", "930100011", "930100037", "930100045", "940100027",
  "940100035", "940100043", "940100050", "940100068", "950100016",
  "690783154", "690784137", "690784152", "690784178", "690787478",
  "830100558"
)

build_dp_dr_conditions <- function(
    cim10_codes_starts_with = NULL, include_dr = NULL) {
  starts_with_conditions_dp <- sapply(
    cim10_codes_starts_with, function(code) glue("DGN_PAL LIKE '{code}%'")
  )
  if (include_dr) {
    starts_with_conditions_dr <- sapply(
      cim10_codes_starts_with, function(code) glue("DGN_REL LIKE '{code}%'")
    )
  } else {
    starts_with_conditions_dr <- NULL
  }
  starts_with_conditions <- c(
    starts_with_conditions_dp, starts_with_conditions_dr
  )
  combined_conditions <- paste(starts_with_conditions, collapse = " OR ")
  combined_conditions <- glue("({combined_conditions})")
  return(combined_conditions)
}

build_da_conditions <- function(cim10_codes_starts_with = NULL) {
  starts_with_conditions_da <- sapply(
    cim10_codes_starts_with, function(code) glue("ASS_DGN LIKE '{code}%'")
  )
  combined_conditions <- paste(starts_with_conditions_da, collapse = " OR ")
  combined_conditions <- glue("({combined_conditions})")
  return(combined_conditions)
}

normalize_column_number <- function(
    df = NULL, column_prefix = NULL, max_columns_number = NULL) {
  expected_cols <- paste(column_prefix, 1:max_columns_number, sep = "")

  missing_cols <- setdiff(expected_cols, names(df))
  df[missing_cols] <- NA

  excess_cols <- names(df)[str_detect(
    names(df), glue("^{column_prefix}\\d+$")
  ) & !names(df) %in% expected_cols]
  df <- df[, !(names(df) %in% excess_cols)]
  return(df)
}

extract_hospital_stays <- function(
    start_date = NULL,
    end_date = NULL,
    dp_cim10_codes_starts_with = NULL,
    or_dr_with_same_codes = NULL,
    or_da_with_same_codes = NULL,
    and_da_with_other_codes = NULL,
    da_cim10_codes_starts_with = NULL,
    ben_table_name = NULL,
    output_table_name = NULL,
    r_output_path = NULL) {
  conn <- connect_oracle() # Connect to database

  start_year <- lubridate::year(start_date)
  end_year <- lubridate::year(end_date)
  formatted_start_date <- format(start_date, "%Y-%m-%d")
  formatted_end_date <- format(end_date, "%Y-%m-%d")

  hospital_stays_list <- list()

  for (year in start_year:end_year) {
    start_time <- Sys.time()
    print(glue("Processing year: {year}"))
    formatted_year <- sprintf("%02d", year %% 100)
    if (!is.null(ben_table_name)) {
      ben <- tbl(conn, ben_table_name)
    }
    t_mco_b <- tbl(conn, glue("T_MCO{formatted_year}B"))
    t_mco_c <- tbl(conn, glue("T_MCO{formatted_year}C"))
    t_mco_d <- tbl(conn, glue("T_MCO{formatted_year}D"))
    t_mco_um <- tbl(conn, glue("T_MCO{formatted_year}UM"))

    dp_dr_conditions <- build_dp_dr_conditions(
      cim10_codes_starts_with = dp_cim10_codes_starts_with,
      include_dr = or_dr_with_same_codes
    )

    eta_num_rsa_num <- t_mco_b %>%
      filter(sql(dp_dr_conditions)) %>%
      select(ETA_NUM, RSA_NUM) %>%
      distinct()

    if (or_da_with_same_codes) {
      da_conditions <- build_da_conditions(
        cim10_codes_starts_with = dp_cim10_codes_starts_with
      )
      dp_dr_conditions <- build_dp_dr_conditions(
        cim10_codes_starts_with = dp_cim10_codes_starts_with, include_dr = TRUE
      )
      eta_num_rsa_num_da_d <- t_mco_d %>%
        filter(sql(da_conditions)) %>%
        select(ETA_NUM, RSA_NUM) %>%
        distinct()
      eta_num_rsa_num_da_um <- t_mco_um %>%
        filter(sql(dp_dr_conditions)) %>%
        select(ETA_NUM, RSA_NUM) %>%
        distinct()
      eta_num_rsa_num_da <- union(eta_num_rsa_num_da_d, eta_num_rsa_num_da_um)
      eta_num_rsa_num <- union(eta_num_rsa_num, eta_num_rsa_num_da)
    } else if (and_da_with_other_codes) {
      da_conditions <- build_da_conditions(
        cim10_codes_starts_with = da_cim10_codes_starts_with
      )
      dp_dr_conditions <- build_dp_dr_conditions(
        cim10_codes_starts_with = da_cim10_codes_starts_with,
        include_dr = TRUE
      )
      eta_num_rsa_num_da_d <- t_mco_d %>%
        filter(sql(da_conditions)) %>%
        select(ETA_NUM, RSA_NUM) %>%
        distinct()
      eta_num_rsa_num_da_um <- t_mco_um %>%
        filter(sql(dp_dr_conditions)) %>%
        select(ETA_NUM, RSA_NUM) %>%
        distinct()
      eta_num_rsa_num_da <- union(eta_num_rsa_num_da_d, eta_num_rsa_num_da_um)
      eta_num_rsa_num <- eta_num_rsa_num %>%
        inner_join(eta_num_rsa_num_da, by = c("ETA_NUM", "RSA_NUM"))
    }

    selected_cols <- c(
      "ETA_NUM", "RSA_NUM", "SEJ_NUM", "SEJ_NBJ", "NBR_DGN",
      "NBR_RUM", "NBR_ACT", "ENT_MOD", "ENT_PRV", "SOR_MOD",
      "SOR_DES", "DGN_PAL", "DGN_REL", "GRG_GHM", "BDI_DEP",
      "BDI_COD", "COD_SEX", "AGE_ANN", "AGE_JOU", "NIR_ANO_17",
      "EXE_SOI_DTD", "EXE_SOI_DTF", "FHO_RET", "NAI_RET",
      "NIR_RET", "PMS_RET", "SEJ_RET", "SEX_RET"
    )
    # SOR_ANN and SOR_MOI have been removed from the selected columns
    # because they are not always present in the tables

    if (year >= 2013) {
      selected_cols <- c(selected_cols, "DAT_RET", "COH_NAI_RET", "COH_SEX_RET")
    }

    tmp1 <- t_mco_b %>%
      inner_join(t_mco_c, by = c("ETA_NUM", "RSA_NUM")) %>%
      inner_join(eta_num_rsa_num, by = c("ETA_NUM", "RSA_NUM")) %>%
      select(all_of(selected_cols)) %>%
      filter(
        EXE_SOI_DTD >= TO_DATE(formatted_start_date, "YYYY-MM-DD") &
          EXE_SOI_DTD <= TO_DATE(formatted_end_date, "YYYY-MM-DD")
      ) %>%
      distinct()

    if (!is.null(ben_table_name)) {
      ben <- ben %>%
        select(BEN_IDT_ANO, BEN_NIR_PSA) %>%
        distinct()
      tmp1 <- tmp1 %>%
        inner_join(ben, by = c("NIR_ANO_17" = "BEN_NIR_PSA")) %>%
        select(-NIR_ANO_17)
    }

    selected_eta_num_rsa_num <- tmp1 %>%
      select(ETA_NUM, RSA_NUM) %>%
      distinct()

    tmp1 <- tmp1 %>%
      collect()


    selected_cols <- c("ETA_NUM", "RSA_NUM", "DGN_PAL", "DGN_REL")
    tmp1_um <- t_mco_um %>%
      inner_join(selected_eta_num_rsa_num, by = c("ETA_NUM", "RSA_NUM")) %>%
      select(all_of(selected_cols)) %>%
      distinct() %>%
      collect()

    tmp1_um_dp <- tmp1_um %>%
      select(ETA_NUM, RSA_NUM, DGN_PAL) %>%
      distinct() %>%
      group_by(ETA_NUM, RSA_NUM) %>%
      mutate(row_id = row_number()) %>%
      pivot_wider(
        names_from = row_id, values_from = DGN_PAL, names_prefix = "DGN_PAL_UM_"
      ) %>%
      ungroup()

    max_columns_dgn_pal_um <- 10
    tmp1_um_dp <- normalize_column_number(
      df = tmp1_um_dp,
      column_prefix = "DGN_PAL_UM_",
      max_columns_number = max_columns_dgn_pal_um
    )

    tmp1_um_dr <- tmp1_um %>%
      select(ETA_NUM, RSA_NUM, DGN_REL) %>%
      distinct() %>%
      group_by(ETA_NUM, RSA_NUM) %>%
      mutate(row_id = row_number()) %>%
      pivot_wider(
        names_from = row_id,
        values_from = DGN_REL,
        names_prefix = "DGN_REL_UM_"
      ) %>%
      ungroup()

    max_columns_dgn_rel_um <- 10
    tmp1_um_dr <- normalize_column_number(
      df = tmp1_um_dr,
      column_prefix = "DGN_REL_UM_",
      max_columns_number = max_columns_dgn_rel_um
    )

    tmp_um <- tmp1_um_dp %>%
      left_join(tmp1_um_dr, by = c("ETA_NUM", "RSA_NUM"))


    selected_cols <- c("ETA_NUM", "RSA_NUM", "ASS_DGN")
    tmp1_d <- t_mco_d %>%
      inner_join(selected_eta_num_rsa_num, by = c("ETA_NUM", "RSA_NUM")) %>%
      select(all_of(selected_cols)) %>%
      distinct() %>%
      collect()

    tmp2_d <- bind_rows(
      tmp1_d,
      tmp1_um %>%
        select(ETA_NUM, RSA_NUM, DGN_PAL) %>%
        rename(ASS_DGN = DGN_PAL) %>%
        distinct(),
      tmp1_um %>%
        select(ETA_NUM, RSA_NUM, DGN_REL) %>%
        rename(ASS_DGN = DGN_REL) %>%
        distinct()
    ) %>%
      distinct()

    selected_cols <- c("ETA_NUM", "RSA_NUM", "DGN_PAL")
    tmp3_d <- tmp1 %>%
      select(all_of(selected_cols)) %>%
      distinct() %>%
      left_join(tmp2_d, by = c("ETA_NUM", "RSA_NUM")) %>%
      filter(!(ASS_DGN == DGN_PAL | tolower(ASS_DGN) == "xxxx")) %>%
      select(-DGN_PAL) %>%
      group_by(ETA_NUM, RSA_NUM) %>%
      mutate(row_id = row_number()) %>%
      pivot_wider(
        names_from = row_id,
        values_from = ASS_DGN,
        names_prefix = "ASS_DGN_"
      ) %>%
      ungroup()

    max_columns_da <- 20
    tmp3_d <- normalize_column_number(
      df = tmp3_d,
      column_prefix = "ASS_DGN_",
      max_columns_number = max_columns_da
    )

    tmp3 <- tmp1 %>%
      left_join(tmp_um, by = c("ETA_NUM", "RSA_NUM")) %>%
      left_join(tmp3_d, by = c("ETA_NUM", "RSA_NUM"))

    tmp4 <- tmp3 %>%
      filter(
        NIR_RET == 0,
        NAI_RET == 0,
        SEX_RET == 0,
        SEJ_RET == 0,
        FHO_RET == 0,
        PMS_RET == 0
      ) %>%
      select(
        -NIR_RET,
        -NAI_RET,
        -SEX_RET,
        -SEJ_RET,
        -FHO_RET,
        -PMS_RET
      )

    if (year >= 2013) {
      tmp4 <- tmp4 %>%
        filter(
          COH_NAI_RET == 0,
          COH_SEX_RET == 0
        ) %>%
        select(
          -COH_NAI_RET,
          -COH_SEX_RET
        )
    }

    hospital_stays <- tmp4 %>%
      filter(
        GRG_GHM != 90,
        !(ETA_NUM %in% finess_out)
      )

    hospital_stays_list <- append(hospital_stays_list, list(hospital_stays))

    end_time <- Sys.time()
    print(
      glue::glue("
      Time taken for year {year}:
      {round(difftime(end_time, start_time, units='mins'),1)} mins.")
    )
  }

  hospital_stays <- bind_rows(hospital_stays_list)


  if (!is.null(r_output_path)) {
    saveRDS(hospital_stays, glue::glue("
    {r_output_path}/{tolower(output_table_name)}.RDS"))
  }

  dbDisconnect(conn)

  return(hospital_stays)
}
