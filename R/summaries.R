#' Summarize scored complexes for a condition
#'
#' @param scored_database Scored complex database.
#' @param no_cond Number of experimental conditions.
#' @param no_rep Number of replicates per condition.
#' @param condition Condition number.
#' @param noise_threshold Maximum allowed noise.
#'
#' @return A character scalar summary.
#' @export
complexbrowser_complex_summary <- function(scored_database, no_cond, no_rep,
                                           condition, noise_threshold) {
  n <- nrow(scored_database)
  n3 <- sum(scored_database$NQS >= 3)
  fc_col_index <- 8 + condition - 1
  filtered <- scored_database
  if (noise_threshold != 1) {
    filtered <- filtered[filtered$Noise <= noise_threshold, , drop = FALSE]
  }

  fc_col <- filtered[, fc_col_index]
  max_row <- filtered[match(max(fc_col, na.rm = TRUE), filtered[, fc_col_index]), ]
  min_row <- filtered[match(min(fc_col, na.rm = TRUE), filtered[, fc_col_index]), ]
  paste0(
    "We have found ", n,
    " protein complexes in your dataset and ", n3,
    " among them with at least 3 quantified subunits. In condition ", condition,
    " the most upragulated protein complex in is ", max_row$Complex_Name,
    " with a fold change of ", max_row[fc_col_index],
    ", ", max_row$NQS,
    " quantified subunits and noise level of ", max_row$Noise,
    ". The most downregulated protein complex is ", min_row$Complex_Name,
    " with a fold change of ", min_row[fc_col_index],
    ", ", min_row$NQS,
    " quantified subunits and noise level of ", min_row$Noise,
    "."
  )
}

#' Build top changing-complex table data
#'
#' @param scored_database Scored complex database.
#' @param condition Condition number.
#' @param noise_threshold Maximum allowed noise.
#' @param fc_threshold Fold-change threshold.
#'
#' @return A data frame for top up/down complexes.
#' @export
complexbrowser_changing_table_data <- function(scored_database, condition,
                                               noise_threshold, fc_threshold) {
  table <- scored_database[, c(2, 4, 9:ncol(scored_database))]
  table <- table[table$Noise <= noise_threshold, , drop = FALSE]
  fc_col <- 1 + condition

  up <- table[table[, fc_col] >= fc_threshold, , drop = FALSE]
  up5 <- rbind(NA, up[order(up[, fc_col], decreasing = TRUE)[1:5], ])
  up5$Complex_Name <- as.character(up5$Complex_Name)
  up5[1, 1] <- "Top5 Up"

  down <- table[table[, fc_col] <= -fc_threshold, , drop = FALSE]
  down5 <- rbind(NA, down[order(down[, fc_col], decreasing = FALSE)[1:5], ])
  down5$Complex_Name <- as.character(down5$Complex_Name)
  down5[1, 1] <- "Top5 Down"

  rbind(up5, down5)
}
