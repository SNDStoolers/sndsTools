#' Extraction des délivrances de médicaments à partir de SQL injecté dans du R
#' (modèle dbExecute de Thomas Soeiro).
#'
#' @description Cette fonction permet d'extraire les délivrances de médicaments
#' par code ATC ou par code CIP13. Les délivrances dont les dates `EXE_SOI_DTD`
#' sont comprises entre `start_date` et `end_date` (incluses) sont extraites.
#'
#' @param start_date Date. La date de début de la période des délivrances des
#'   médicaments à extraire.
#' @param end_date Date. La date de fin de la période des délivrances des
#'   médicaments à extraire.
#' @param atc_cod_starts_with_filter Character vector (Optionnel). Les codes ATC
#'   par lesquels les délivrances de médicaments à extraire doivent commencer.
#'   Défaut à NULL.
#' @param cip13_cod_filter Character vector (Optionnel). Les codes CIP des
#'   délivrances de médicaments à extraire en complément des codes ATC. Défaut à
#' NULL.
#' @param output_table_name Character (Optionnel). Si fourni, les résultats
#'   seront sauvegardés dans une table portant ce nom dans la base de données au
#'   lieu d'être retournés sous forme de data frame. Défault à NULL.
#' @param conn DBI connection (Optionnel). Une connexion à la base de données
#'   Oracle. Si non fournie, une connexion est établie par défaut. Défaut à
#'   NULL.
#'
#' @export
sql_extract_drug_dispenses <- function(start_date, # nolint
                                       end_date,
                                       output_table_name,
                                       atc_cod_starts_with_filter = NULL,
                                       cip13_cod_filter = NULL,
                                       conn = NULL) {
  stopifnot(
    !is.null(start_date),
    !is.null(end_date),
    inherits(start_date, "Date"),
    inherits(end_date, "Date"),
    start_date <= end_date
  )

  connection_opened <- FALSE
  if (is.null(conn)) {
    conn <- connect_oracle()
    connection_opened <- TRUE
  }
  # Format the dates (used in the glued SQL query)
  formatted_start_date <- format(start_date, "%Y-%m-%d") # nolint
  formatted_end_date <- format(end_date, "%Y-%m-%d") # nolint

  # Create the subset of IR_PHA_V table that should be joined to the DCIR
  # tables(same code as extract_drug_dispenses)
  ir_pha_r <- dplyr::tbl(conn, "IR_PHA_R")

  if (!is.null(atc_cod_starts_with_filter)) {
    starts_with_conditions <- vapply(
      atc_cod_starts_with_filter, function(code) {
        glue::glue("PHA_ATC_CLA LIKE '{code}%'")
      }, character(1)
    )
    atc_conditions <- paste(starts_with_conditions, collapse = " OR ")
    atc_conditions <- glue::glue("({atc_conditions})")
  }
  if (!is.null(cip13_cod_filter)) {
    cip13_conditions <- glue::glue(
      "PHA_CIP_C13 IN ({paste(cip13_cod_filter, collapse = ',')})"
    )
  }
  if (!is.null(atc_cod_starts_with_filter) && !is.null(cip13_cod_filter)) { # nolint
    drug_filter <- atc_conditions + " OR " + cip13_conditions
  } else if (!is.null(cip13_cod_filter) && is.null(atc_cod_starts_with_filter)) { # nolint
    drug_filter <- cip13_conditions
  } else if (!is.null(atc_cod_starts_with_filter) && is.null(cip13_cod_filter)) { # nolint
    drug_filter <- atc_conditions
  } else {
    drug_filter <- NULL
  }
  ir_pha_needed_cols <- c("PHA_CIP_C13", "PHA_ATC_CLA", "PHA_GRD_CND")
  ir_pha_filtered <- ir_pha_r |>
    dplyr::select(dplyr::all_of(ir_pha_needed_cols))
  if (!is.null(drug_filter)) {
    ir_pha_filtered_query <- ir_pha_filtered |>
      dplyr::filter(dbplyr::sql(drug_filter)) |>
      dbplyr::sql_render()
  }
  timestamp_ <- format(Sys.time(), "%Y%m%d_%H%M%S")
  ir_pha_r_filtered_name <- glue::glue("TMP_IR_PHA_R_{timestamp_}")
  DBI::dbExecute(
    conn,
    glue::glue(
      "CREATE TABLE {ir_pha_r_filtered_name} AS {ir_pha_filtered_query}"
    )
  )

  sql_drug_query <- "
  SELECT DISTINCT prs.BEN_NIR_PSA,
    prs.BEN_CMU_TOP,
    prs.BEN_AMA_COD,
    prs.BEN_SEX_COD,
    prs.BEN_RES_DPT,
    prs.FLX_DIS_DTD,
    prs.EXE_SOI_DTD,
    prs.PRS_ACT_QTE,
    prs.BSE_REM_MNT,
    prs.BSE_PRS_NAT,
    prs.PSP_SPE_COD,
    ete.ETE_IND_TAA,
    ete.ETB_EXE_FIN,
    ete.ETE_MCO_DDP,
    ir_pha_filter.PHA_ATC_CLA,
    ir_pha_filter.PHA_GRD_CND,
    pha.PHA_PRS_IDE,
    pha.PHA_PRS_C13,
    pha.PHA_DEC_TOP,
    pha.PHA_ACT_QSN,
    pha.PHA_DEC_QSU
FROM er_prs_f prs
    INNER JOIN ER_PHA_F pha
        ON pha.FLX_DIS_DTD = prs.FLX_DIS_DTD
            AND pha.FLX_TRT_DTD = prs.FLX_TRT_DTD
            AND pha.FLX_EMT_TYP = prs.FLX_EMT_TYP
            AND pha.FLX_EMT_NUM = prs.FLX_EMT_NUM
            AND pha.FLX_EMT_ORD = prs.FLX_EMT_ORD
            AND pha.ORG_CLE_NUM = prs.ORG_CLE_NUM
            AND pha.DCT_ORD_NUM = prs.DCT_ORD_NUM
            AND pha.PRS_ORD_NUM = prs.PRS_ORD_NUM
            AND pha.REM_TYP_AFF = prs.REM_TYP_AFF
    INNER JOIN {ir_pha_r_filtered_name} ir_pha_filter
        ON ir_pha_filter.PHA_CIP_C13 = pha.PHA_PRS_C13
    LEFT JOIN ER_ETE_F ete
        ON ete.FLX_DIS_DTD = prs.FLX_DIS_DTD
            AND	ete.FLX_TRT_DTD = prs.FLX_TRT_DTD
            AND	ete.FLX_EMT_TYP = prs.FLX_EMT_TYP
            AND	ete.FLX_EMT_NUM = prs.FLX_EMT_NUM
            AND	ete.FLX_EMT_ORD = prs.FLX_EMT_ORD
            AND	ete.ORG_CLE_NUM = prs.ORG_CLE_NUM
            AND	ete.DCT_ORD_NUM = prs.DCT_ORD_NUM
            AND	ete.PRS_ORD_NUM = prs.PRS_ORD_NUM
            AND	ete.REM_TYP_AFF = prs.REM_TYP_AFF
WHERE (
    prs.FLX_DIS_DTD >= DATE '{dis_dtd_start}'
      AND prs.FLX_DIS_DTD < DATE '{dis_dtd_end}'
    )
    AND (
    prs.exe_soi_dtd >= DATE '{formatted_start_date}'
      AND prs.exe_soi_dtd <= DATE '{formatted_end_date}')
    AND prs.DPN_QLF <> 71
    AND prs.CPL_MAJ_TOP < 2
    AND (ete.ETE_IND_TAA <> 1 OR ete.ETE_IND_TAA IS NULL)"
  dis_dtd_lag_months <- 6
  dis_dtd_end_date <-
    end_date |>
    lubridate::add_with_rollback(months(dis_dtd_lag_months)) |>
    lubridate::floor_date("months")
  flux_start_month <- max(1, lubridate::month(start_date))
  dis_dtd_start_date <- lubridate::make_date(
    year = lubridate::year(start_date),
    month = flux_start_month,
    day = 1
  )
  flx_dates <- seq(
    as.Date(dis_dtd_start_date), as.Date(dis_dtd_end_date), "month"
  )
  for (i in seq_along(flx_dates)) {
    # assign flx_date to be taken into account in glued sql_drug_query
    dis_dtd_start <- as.Date(flx_dates[[i]]) # nolint
    dis_dtd_end <- dis_dtd_start |>
      lubridate::add_with_rollback(months(1)) |>
      lubridate::floor_date("months")
    query <- glue::glue(sql_drug_query)
    print(glue::glue("-flux: {dis_dtd_start} to {dis_dtd_end}"))
    if (i == 1) {
      DBI::dbExecute(
        conn, glue::glue("CREATE TABLE {output_table_name} AS {query}")
      )
    } else {
      DBI::dbExecute(
        conn, glue::glue("INSERT INTO {output_table_name} {query}")
      )
    }
  }
  message(glue::glue("Results saved to table {output_table_name} in Oracle."))

  # Cleaning
  DBI::dbRemoveTable(conn, ir_pha_r_filtered_name)
  if (connection_opened) {
    DBI::dbDisconnect(conn)
  }
}
