#' Prepare a quantitative proteomics input table
#'
#' @param data A data frame whose first column contains protein identifiers.
#' @param no_cond Number of experimental conditions.
#' @param no_rep Number of replicates per condition.
#' @param log2 If `TRUE`, measurement values are treated as log2 values and
#'   converted to absolute intensities.
#' @param grouped If `TRUE`, replicate columns are grouped by condition.
#' @param q_values If `TRUE`, q-value columns are expected after measurement
#'   columns.
#'
#' @return A data frame with ComplexBrowser-compatible column names and order.
#' @export
complexbrowser_prepare_input_table <- function(data, no_cond, no_rep,
                                               log2 = TRUE, grouped = FALSE,
                                               q_values = TRUE) {
  assert_input_table(data)
  assert_count(no_cond, "no_cond")
  assert_count(no_rep, "no_rep")

  columns <- no_cond * no_rep + 1L
  full_columns <- columns + no_cond - 1L
  if (ncol(data) < columns || (isTRUE(q_values) && ncol(data) < full_columns)) {
    stop("Input table does not contain the expected condition, replicate, and q-value columns.", call. = FALSE)
  }

  data <- data[, seq_len(if (isTRUE(q_values)) full_columns else columns), drop = FALSE]
  if (isTRUE(log2)) {
    data[, 2:columns] <- 2^data[, 2:columns]
  }

  measurement_names <- sample_column_names(no_cond, no_rep, grouped)
  names(data) <- c("ProteinID", measurement_names, qvalue_column_names(no_cond)[seq_len(ncol(data) - columns)])
  qvalue_names <- if (ncol(data) > columns) names(data)[(columns + 1L):ncol(data)] else character()
  data[, c("ProteinID", gtools::mixedsort(names(data)[2:columns]), qvalue_names), drop = FALSE]
}

assert_input_table <- function(data) {
  if (!is.data.frame(data)) {
    stop("Input data must be a data frame.", call. = FALSE)
  }
  if (ncol(data) < 2L) {
    stop("Input data must contain protein identifiers and measurement columns.", call. = FALSE)
  }
}

assert_count <- function(value, name) {
  if (length(value) != 1L || is.na(value) || value < 1L || value != as.integer(value)) {
    stop(name, " must be a positive integer.", call. = FALSE)
  }
}

sample_column_names <- function(no_cond, no_rep, grouped) {
  if (isTRUE(grouped)) {
    return(unlist(lapply(seq_len(no_cond), function(condition) {
      paste0("C", condition, "_", seq_len(no_rep))
    }), use.names = FALSE))
  }

  unlist(lapply(seq_len(no_rep), function(replicate) {
    paste0("C", seq_len(no_cond), "_", replicate)
  }), use.names = FALSE)
}

qvalue_column_names <- function(no_cond) {
  paste("qValue C", 2:no_cond, sep = "")
}
