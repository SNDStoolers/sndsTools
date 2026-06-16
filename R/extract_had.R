# nolint start
#' Extraction des consultations dans le DCIR.
#' @description
#' Cette fonction permet d'extraire les séjours HAD PAR AN
#' TODO: permettre d'itérer sur plusieurs années
#' @param year numeric. Year to consider in a 2-character numeric format.
#' @param remove_patint_filters boolean (Optional). Default is TRUE. Whether or not to remove filters with return codes
#' as recommanded in SNDS collaborative documentation. For epidemiological studies, it is
#' strongly recommanded to set to TRUE. For studies on care centers, it may not be necessary.
# nolint end

extract_had_stays_per_year <- function(
  year,
  remove_patient_filters = TRUE,
  conn = NULL
) {
  stopifnot(
    is.numeric(year)
  )

  connection_opened <- FALSE
  if (is.null(conn)) {
    conn <- connect_oracle()
    connection_opened <- TRUE
  }

  # load tables
  had_c <- dplyr::tbl(conn, glue::glue("T_HAD{year}C"))
  had_grp <- dplyr::tbl(conn, glue::glue("T_HAD{year}GRP"))

  # clean with return codes
  if (remove_patient_filters) {
    had_c <- had_c |> dplyr::filter(NIR_RET == "0" & NAI_RET == "0" & SEX_RET == "0" & SEJ_RET == "0" & FHO_RET == "0" & PMS_RET == "0" & DAT_RET == "0")
    if (year >= 13) {
      had_c <- had_c |> dplyr::filter(COH_NAI_RET == "0" & COH_SEX_RET == "0")
    }
  }

  had_grp <- had_grp |> dplyr::filter(GHT_NUM != "99")

  ## TODO:join had_grp et had_c

  result <- had_c

  if (connection_opened) {
    DBI::dbDisconnect(conn)
  }

  result
}
