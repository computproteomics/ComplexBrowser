#' Build the input-statistics CSV filename
#'
#' @param time Timestamp to include in the filename.
#'
#' @return A filename matching the Shiny download handler.
#' @export
complexbrowser_input_statistics_filename <- function(time = Sys.time()) {
  paste0("MSComplexR_Input_WithStats", time, ".csv")
}

#' Build the complex-table CSV filename
#'
#' @param time Timestamp to include in the filename.
#'
#' @return A filename matching the Shiny download handler.
#' @export
complexbrowser_complex_table_filename <- function(time = Sys.time()) {
  paste0("Protein_complex_resutls", time, ".csv")
}

#' Write the input-statistics table as CSV
#'
#' @param table Input statistics table.
#' @param file Output CSV path.
#'
#' @return `file`, invisibly.
#' @export
complexbrowser_write_input_statistics <- function(table, file) {
  utils::write.csv(table, file, row.names = FALSE)
  invisible(file)
}

#' Write the complex-analysis table as CSV
#'
#' @param table Complex analysis display table.
#' @param file Output CSV path.
#'
#' @return `file`, invisibly.
#' @export
complexbrowser_write_complex_table <- function(table, file) {
  utils::write.csv(table, file, row.names = FALSE)
  invisible(file)
}

#' Prepare QC report summary data
#'
#' @param stats QC statistics list.
#' @param no_cond Number of experimental conditions.
#' @param no_rep Number of replicates per condition.
#'
#' @return A list matching the legacy `QCreport.rmd` parameter data.
#' @export
complexbrowser_prepare_qc_report_data <- function(stats, no_cond, no_rep) {
  list(
    r = if (no_cond < 2L) 1L else ceiling(no_cond / 2L),
    c = if (no_cond < 2L) 1L else 2L,
    VAL_t = qc_report_summary_table(stats$log2_means, seq_len(no_cond), 3, paste0("Cond. ", seq_len(no_cond))),
    CV_t = qc_report_summary_table(stats$CV_df, seq_len(no_cond), 3, paste0("Cond. ", seq_len(no_cond))),
    fc_t = qc_report_summary_table(stats$FC_df, seq_len(no_cond - 1L), 3, paste0("FC C", 2:no_cond, "/C1")),
    qValue_t = qc_report_summary_table(stats$qValue_df, seq_len(no_cond - 1L), 4, paste0("qValue C", 2:no_cond, "/C1"))
  )
}

qc_report_summary_table <- function(values, columns, digits, names) {
  table <- rbind(
    Min = vapply(columns, function(x) min(values[, x], na.rm = TRUE), numeric(1)),
    Mean = vapply(columns, function(x) mean(values[, x], na.rm = TRUE), numeric(1)),
    Median = vapply(columns, function(x) stats::median(values[, x], na.rm = TRUE), numeric(1)),
    Max = vapply(columns, function(x) max(values[, x], na.rm = TRUE), numeric(1))
  )
  table <- round(table, digits)
  colnames(table) <- names
  rownames(table) <- c("Min", "Mean", "Median", "Max")
  table
}
