#' Calculate ComplexBrowser QC statistics
#'
#' @param data Prepared input table with protein identifiers in the first
#'   column.
#' @param no_cond Number of experimental conditions.
#' @param no_rep Number of replicates per condition.
#' @param q_values If `TRUE`, q-values are read from `data`; otherwise they are
#'   calculated with LIMMA.
#' @param normalization Optional normalization method: `"Total Intensity"`,
#'   `"Mean"`, `"Median"`, or `"Quantile"`.
#' @param design Statistical design used when q-values must be calculated:
#'   `"unpaired"` or `"paired"`.
#'
#' @return A named list of statistics matching the legacy Shiny output shape.
#' @export
complexbrowser_calculate_statistics <- function(data, no_cond, no_rep,
                                                q_values = TRUE,
                                                normalization = NULL,
                                                design = c("unpaired", "paired")) {
  assert_input_table(data)
  assert_count(no_cond, "no_cond")
  assert_count(no_rep, "no_rep")
  design <- match.arg(design)

  columns <- no_cond * no_rep + 1L
  absolute_df <- prepare_absolute_values(data, columns)
  protein_id <- clean_protein_ids(data[[1]])
  log2_absolute_df <- build_log2_absolute(absolute_df)
  if (!is.null(normalization)) {
    absolute_df <- normalize_values(absolute_df, no_cond, no_rep, normalization)
    data[, 2:columns] <- absolute_df
  }
  qvalue_df <- calculate_qvalues(data, no_cond, no_rep, q_values, normalization, design, columns)
  summaries <- summarize_conditions(absolute_df, no_cond, no_rep)
  ratios <- calculate_ratios(summaries$means_df, no_cond)
  absolute_df <- cbind(ProteinID = protein_id, round(absolute_df, 3))

  list(
    absolute_df = absolute_df,
    log2_absolute_df = round(log2_absolute_df, 2),
    means_df = signif(summaries$means_df, 4),
    SD_df = signif(summaries$sd_df, 3),
    CV_df = signif(summaries$cv_df, 4),
    qValue_df = round_qvalues(qvalue_df),
    log2_means = round(summaries$log2_means_df, 3),
    zScore = round(calculate_zscores(summaries$log2_means_df, no_cond), 3),
    ratios = round(as.matrix(ratios), 3),
    FC_df = round(as.matrix(calculate_fold_changes(ratios, no_cond)), 3),
    log2_ratios = round(calculate_log2_ratios(ratios, no_cond), 3)
  )
}

#' Run the package QC workflow
#'
#' @inheritParams complexbrowser_prepare_input_table
#' @inheritParams complexbrowser_calculate_statistics
#'
#' @return A `complexbrowser_qc_result` object with prepared input,
#'   statistics, merged display table, and workflow metadata.
#' @export
complexbrowser_run_qc <- function(data, no_cond, no_rep, log2 = TRUE,
                                  grouped = FALSE, q_values = TRUE,
                                  normalization = NULL,
                                  design = c("unpaired", "paired")) {
  design <- match.arg(design)
  prepared <- complexbrowser_prepare_input_table(data, no_cond, no_rep, log2, grouped, q_values)
  stats <- complexbrowser_calculate_statistics(prepared, no_cond, no_rep, q_values, normalization, design)
  result <- list(
    input = prepared,
    stats = stats,
    merged_table = merge_qc_statistics(stats),
    metadata = list(
      no_cond = no_cond,
      no_rep = no_rep,
      log2 = log2,
      grouped = grouped,
      q_values = q_values,
      normalization = normalization,
      design = design
    )
  )
  class(result) <- c("complexbrowser_qc_result", "list")
  result
}

prepare_absolute_values <- function(data, columns) {
  absolute_df <- data[, 2:columns, drop = FALSE]
  absolute_df[absolute_df == 0] <- NA
  absolute_df
}

clean_protein_ids <- function(protein_id) {
  protein_id[is.na(protein_id)] <- "No ID"
  protein_id[protein_id == ""] <- "No ID"
  protein_id
}

build_log2_absolute <- function(absolute_df) {
  log2_absolute_df <- as.matrix(log2(absolute_df))
  log2_absolute_df[log2_absolute_df == -Inf] <- NA
  colnames(log2_absolute_df) <- paste0("Log2(Int) ", colnames(absolute_df))
  log2_absolute_df
}

calculate_qvalues <- function(data, no_cond, no_rep, q_values, normalization,
                              design, columns) {
  if (isTRUE(q_values) && is.null(normalization)) {
    return(data[, -(1:columns), drop = FALSE])
  }

  qvalue_df <- if (identical(design, "unpaired")) {
    limma_unpaired_qvalues(data, no_cond, no_rep, reference = 1)
  } else {
    limma_paired_qvalues(data, no_cond, no_rep)
  }
  colnames(qvalue_df) <- qvalue_column_names(no_cond)
  qvalue_df
}

normalize_values <- function(data_num, no_cond, no_rep, method) {
  normalized <- as.matrix(data_num)
  normalized[normalized == 0] <- NA

  normalized <- switch(method,
    "Total Intensity" = normalize_total_intensity(normalized),
    "Mean" = normalize_by_mean(normalized),
    "Median" = normalize_by_median(normalized),
    "Quantile" = normalize_by_quantile(normalized, no_cond, no_rep),
    stop("Unsupported normalization method: ", method, call. = FALSE)
  )

  colnames(normalized) <- colnames(data_num)
  normalized
}

normalize_total_intensity <- function(values) {
  totals <- colSums(values, na.rm = TRUE)
  data.frame(apply(values, 2, function(x) (x / sum(x, na.rm = TRUE)) * mean(totals)))
}

normalize_by_mean <- function(values) {
  totals <- colSums(values, na.rm = TRUE)
  data.frame(apply(values, 2, function(x) (x / mean(x, na.rm = TRUE) * mean(totals))))
}

normalize_by_median <- function(values) {
  totals <- colSums(values, na.rm = TRUE)
  data.frame(apply(values, 2, function(x) (x / stats::median(x, na.rm = TRUE) * stats::median(totals))))
}

normalize_by_quantile <- function(values, no_cond, no_rep) {
  for (condition in seq_len(no_cond)) {
    index <- condition_indexes(condition, no_rep)
    values[, index] <- preprocessCore::normalize.quantiles(values[, index])
  }
  normalize_total_intensity(values)
}

limma_unpaired_qvalues <- function(data, no_cond, no_rep, reference = 1) {
  data_num <- log2(data[, 2:(no_cond * no_rep + 1), drop = FALSE])
  data_num[data_num == -Inf] <- NA
  rownames(data_num) <- data[[1]]
  design <- unpaired_design(no_cond, no_rep)
  contrast_matrix <- limma::makeContrasts(
    contrasts = unpaired_contrasts(design, no_cond, reference),
    levels = design
  )
  fitted <- limma::lmFit(data_num, design)
  bayes <- limma::eBayes(limma::contrasts.fit(fitted, contrast_matrix))
  adjust_pvalues(bayes$p.value)
}

unpaired_design <- function(no_cond, no_rep) {
  samples <- rep(seq_len(no_cond), each = no_rep)
  design <- stats::model.matrix(~0 + factor(samples - 1))
  colnames(design) <- paste0("C", seq_len(no_cond))
  design
}

unpaired_contrasts <- function(design, no_cond, reference) {
  vapply((seq_len(no_cond))[-reference], function(condition) {
    paste(colnames(design)[condition], colnames(design)[reference], sep = "-")
  }, character(1))
}

limma_paired_qvalues <- function(data, no_cond, no_rep) {
  data_num <- log2(data[, 2:(no_cond * no_rep + 1), drop = FALSE])
  data_num[data_num == -Inf] <- NA
  rownames(data_num) <- data[[1]]
  ratios_df <- paired_ratios(data_num, no_cond, no_rep)
  design <- paired_design(no_cond, no_rep)
  bayes <- limma::eBayes(limma::lmFit(ratios_df, design))
  adjust_pvalues(bayes$p.value)
}

paired_ratios <- function(data_num, no_cond, no_rep) {
  no_samples <- no_cond * no_rep
  ratios <- matrix(nrow = nrow(data_num))
  for (replicate in seq_len(no_rep)) {
    indexes <- seq(replicate, no_samples - no_rep + replicate, by = no_rep)
    ratios <- cbind(ratios, data_num[, indexes[-1], drop = FALSE] - data_num[, indexes[1]])
  }
  ratios <- ratios[, -1, drop = FALSE]
  rownames(ratios) <- rownames(data_num)
  ratios
}

paired_design <- function(no_cond, no_rep) {
  design_labels <- rep(seq_len(no_cond - 1L), no_rep)
  do.call(cbind, lapply(seq_len(no_cond - 1L), function(condition) {
    as.numeric(design_labels == condition)
  }))
}

adjust_pvalues <- function(pvalues) {
  qvalues <- matrix(NA, nrow = nrow(pvalues), ncol = ncol(pvalues), dimnames = dimnames(pvalues))
  for (column in seq_len(ncol(pvalues))) {
    adjusted <- if (nrow(pvalues) > 100L) {
      qvalue::qvalue(stats::na.omit(pvalues[, column]))$qvalues
    } else {
      stats::p.adjust(pvalues[, column], method = "BH")
    }
    qvalues[names(adjusted), column] <- adjusted
  }
  qvalues
}

summarize_conditions <- function(absolute_df, no_cond, no_rep) {
  sd_df <- condition_stat_matrix(absolute_df, no_cond, no_rep, stats::sd)
  means_df <- condition_stat_matrix(absolute_df, no_cond, no_rep, mean)
  cv_df <- (sd_df / means_df) * 100
  log2_means_df <- log2(means_df)

  colnames(sd_df) <- paste("Condition", seq_len(no_cond), "SD", sep = "_")
  colnames(means_df) <- paste("Mean intensity C", seq_len(no_cond), sep = "")
  colnames(cv_df) <- paste("Condition", seq_len(no_cond), "CV", sep = "_")
  colnames(log2_means_df) <- paste("Log2 intensity C", seq_len(no_cond), sep = "")

  list(sd_df = sd_df, means_df = means_df, cv_df = cv_df, log2_means_df = log2_means_df)
}

condition_stat_matrix <- function(absolute_df, no_cond, no_rep, fun) {
  output <- matrix(nrow = nrow(absolute_df), ncol = no_cond)
  for (condition in seq_len(no_cond)) {
    index <- condition_indexes(condition, no_rep)
    output[, condition] <- apply(absolute_df, 1, function(x) fun(x[index], na.rm = TRUE))
  }
  output
}

condition_indexes <- function(condition, no_rep) {
  start <- (condition - 1L) * no_rep + 1L
  start:(start + no_rep - 1L)
}

calculate_zscores <- function(log2_means_df, no_cond) {
  zscores <- t(apply(log2_means_df, 1, function(x) (x - mean(x)) / stats::sd(x)))
  colnames(zscores) <- paste0("Z-Score C", seq_len(no_cond))
  zscores
}

calculate_ratios <- function(means_df, no_cond) {
  ratios <- as.matrix(means_df[, -1, drop = FALSE])
  for (ratio in seq_len(no_cond - 1L)) {
    ratios[, ratio] <- means_df[, ratio + 1L] / means_df[, 1]
  }
  colnames(ratios) <- paste("Ratio C", 2:no_cond, "/C1", sep = "")
  round(ratios, 3)
}

calculate_fold_changes <- function(ratios, no_cond) {
  fc_df <- apply(ratios, c(1, 2), function(x) ifelse(x >= 1, yes = x, no = -1 / x))
  colnames(fc_df) <- paste("Fold change C", 2:no_cond, "/C1", sep = "")
  fc_df
}

calculate_log2_ratios <- function(ratios, no_cond) {
  log2_ratios <- log2(ratios)
  colnames(log2_ratios) <- paste("Log2(ratio) C", 2:no_cond, "/C1", sep = "")
  log2_ratios
}

round_qvalues <- function(qvalue_df) {
  apply(qvalue_df, c(1, 2), function(x) ifelse(x < 0.00001, yes = 0.00001, no = round(x, 5)))
}

merge_qc_statistics <- function(stats) {
  cbind(stats[[1]], do.call(what = "cbind", stats[2:11]))
}
