#' Prepare a user-defined complex database
#'
#' @param csv_file Path to a CSV file with complex database columns.
#'
#' @return A prepared database data frame.
#' @export
complexbrowser_prepare_user_database <- function(csv_file) {
  if (!file.exists(csv_file)) {
    stop("User database file not found: ", csv_file, call. = FALSE)
  }

  db <- utils::read.csv(csv_file, header = TRUE)
  required <- c("ComplexID", "Complex_Name", "Organism", "Subunits", "GO_terms", "Comment")
  missing <- setdiff(required, names(db))
  if (length(missing) > 0) {
    stop("User database is missing required columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }

  db$Subunits <- lapply(as.character(db$Subunits), function(x) strsplit(x, ";", fixed = TRUE)[[1]])
  db$NUS <- vapply(db$Subunits, length, integer(1))
  db[, c("ComplexID", "Complex_Name", "Organism", "NUS", "Subunits", "GO_terms", "Comment")]
}

#' Select a bundled or supplied complex database
#'
#' @param database Database selector. Use `"CORUM"`, `"EBI Complex Portal"`,
#'   a prepared data frame, or a path to a user-defined CSV database.
#'
#' @return A prepared complex database.
#' @export
complexbrowser_select_database <- function(database) {
  if (is.data.frame(database)) {
    assert_complex_database(database)
    return(database)
  }
  if (!is.character(database) || length(database) != 1L || is.na(database)) {
    stop("Database must be a name, file path, or prepared data frame.", call. = FALSE)
  }
  if (identical(database, "CORUM")) {
    return(complexbrowser_load_corum())
  }
  if (identical(database, "EBI Complex Portal")) {
    return(complexbrowser_load_complex_portal())
  }
  if (file.exists(database)) {
    return(complexbrowser_prepare_user_database(database))
  }
  stop("Unsupported complex database: ", database, call. = FALSE)
}

#' Filter statistics to proteins present in a complex database
#'
#' @param stats QC statistics list.
#' @param database Prepared complex database or database selector accepted by
#'   `complexbrowser_select_database()`.
#' @param organism Organism label to analyze.
#'
#' @return A statistics list filtered to proteins found in database complexes.
#' @export
complexbrowser_filter_stats_for_database <- function(stats, database, organism) {
  assert_complex_database(database)
  organism_database <- database[database$Organism == organism, , drop = FALSE]
  accessions <- unique(as.character(unlist(organism_database$Subunits)))
  index <- which(stats$absolute_df[, 1] %in% accessions)

  lapply(stats, function(x) {
    if (!is.vector(x)) {
      return(x[index, , drop = FALSE])
    }
    x[index]
  })
}

#' Filter a complex database to complexes with quantified subunits
#'
#' @param f_data Filtered absolute intensity data.
#' @param database Prepared complex database.
#' @param organism Organism label to analyze.
#'
#' @return A filtered database, or `NULL` when no complexes match.
#' @export
complexbrowser_filter_database <- function(f_data, database, organism) {
  assert_complex_database(database)
  organism_database <- database[database$Organism == organism, , drop = FALSE]
  quantified <- as.character(f_data[, 1])
  present_counts <- vapply(organism_database$Subunits, function(x) {
    sum(x %in% quantified)
  }, integer(1))
  filtered <- organism_database[present_counts > 0, , drop = FALSE]

  if (nrow(filtered) == 0) {
    return(NULL)
  }

  rownames(filtered) <- seq_len(nrow(filtered))
  nqs <- vapply(filtered$Subunits, function(x) sum(x %in% quantified), integer(1))
  coverage <- round((nqs / filtered$NUS) * 100, 2)
  filtered <- cbind(filtered, NQS = nqs, Coverage = coverage)
  filtered[, c(1, 2, 4, 8, 9, 5:7)]
}

#' Score filtered complexes with the legacy FARMS workflow
#'
#' @param filtered_database Database returned by
#'   `complexbrowser_filter_database()`.
#' @param stats Filtered statistics returned by
#'   `complexbrowser_filter_stats_for_database()`.
#' @param no_cond Number of experimental conditions.
#' @param no_rep Number of replicates per condition.
#'
#' @return A matrix of complex fold-change and noise scores.
#' @export
complexbrowser_score_complexes <- function(filtered_database, stats, no_cond, no_rep) {
  if (is.null(filtered_database) || nrow(filtered_database) == 0) {
    return(NULL)
  }

  proteins <- stats$absolute_df[, 1]
  result <- t(vapply(seq_len(nrow(filtered_database)), function(row) {
    complex_fc_farms(filtered_database, stats, proteins, row, no_cond, no_rep)
  }, numeric(no_cond)))
  result
}

#' Convert scored complexes to the display-table shape
#'
#' @param scored_database Filtered database with appended score columns.
#'
#' @return A data frame with subunits collapsed for display.
#' @export
complexbrowser_display_complex_table <- function(scored_database) {
  display <- scored_database
  display$Subunits <- vapply(display$Subunits, function(x) paste(x, collapse = ", "), character(1))
  display
}

#' Run package-level complex analysis
#'
#' @param stats QC statistics list.
#' @param database Prepared complex database.
#' @param organism Organism label to analyze.
#' @param no_cond Number of experimental conditions.
#' @param no_rep Number of replicates per condition.
#' @param database_name Optional database label for metadata.
#'
#' @return A `complexbrowser_complex_result` object.
#' @export
complexbrowser_run_complex_analysis <- function(stats, database, organism,
                                                no_cond, no_rep,
  database_name = NULL) {
  database <- complexbrowser_select_database(database)
  filtered_stats <- complexbrowser_filter_stats_for_database(stats, database, organism)
  filtered_database <- complexbrowser_filter_database(filtered_stats$absolute_df, database, organism)

  result <- list(
    filtered_stats = filtered_stats,
    filtered_database = filtered_database,
    scores = NULL,
    scored_database = NULL,
    display_table = NULL,
    metadata = list(
      database = database_name,
      organism = organism,
      no_cond = no_cond,
      no_rep = no_rep,
      no_proteins_used = nrow(filtered_stats$absolute_df),
      no_complexes = if (is.null(filtered_database)) 0L else nrow(filtered_database)
    )
  )

  if (!is.null(filtered_database)) {
    result$scores <- complexbrowser_score_complexes(filtered_database, filtered_stats, no_cond, no_rep)
    result$scored_database <- cbind(filtered_database, result$scores)
    result$display_table <- complexbrowser_display_complex_table(result$scored_database)
  }

  class(result) <- c("complexbrowser_complex_result", "list")
  result
}

assert_complex_database <- function(database) {
  if (!is.data.frame(database)) {
    stop("Complex database must be a data frame.", call. = FALSE)
  }

  required <- c("ComplexID", "Complex_Name", "Organism", "NUS", "Subunits", "GO_terms")
  missing <- setdiff(required, names(database))
  if (length(missing) > 0) {
    stop("Complex database is missing required columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }
}

fast_farms <- function(probes, weight = 0.1, mu = 0.1, max_iter = 1000,
                       force_iter = FALSE, min_noise = 0.0001, fill_nan = 0) {
  readouts <- as.matrix(probes)
  readouts[is.na(readouts)] <- fill_nan
  x <- t(readouts)
  x <- t(t(x) - colMeans(x, na.rm = TRUE))
  xsd <- apply(x, 2, function(col) stats::sd(col, na.rm = TRUE) * sqrt((length(col) - 1) / length(col)))
  xsd[xsd < min_noise] <- 1
  x <- t(t(x) / xsd)
  x[!is.finite(x)] <- 0
  n_samples <- nrow(x)
  n_features <- ncol(x)
  c_matrix <- crossprod(x, x) / n_samples
  c_matrix <- (c_matrix + t(c_matrix)) / 2
  c_matrix[c_matrix < 0] <- 0
  svd_result <- svd(c_matrix)
  s <- svd_result$d
  s[s < min_noise] <- min_noise
  c_matrix <- svd_result$u %*% diag(s) %*% t(svd_result$v)
  diag(c_matrix)[diag(c_matrix) < 0] <- 0
  lambda <- sqrt(0.75 * diag(c_matrix))
  psi <- diag(c_matrix) - lambda^2
  old_psi <- psi
  alpha <- weight * n_features
  expectation <- 1

  for (iteration in seq_len(max_iter)) {
    phi <- (1 / psi) * lambda
    a <- as.vector(1 + crossprod(lambda, phi))
    eta <- phi / a
    zeta <- c_matrix %*% eta
    expectation <- 1 - as.vector(eta) %*% lambda + as.vector(eta) %*% zeta
    lambda <- zeta / (c(expectation) + as.vector(psi) * alpha)
    psi <- diag(c_matrix) - as.vector(zeta)[1] * lambda + psi * alpha * lambda * (mu - lambda)
    psi[psi < min_noise^2] <- min_noise^2
    if (!force_iter && max(abs(psi - old_psi)) / max(abs(old_psi)) < min_noise / 10) {
      break
    }
    old_psi <- psi
  }

  loading <- as.vector(sqrt(expectation)) * lambda
  phi <- loading / psi
  list(loadings = loading / max(loading), noise = 1 / as.vector(1 + crossprod(loading, phi)))
}

complex_fc_farms <- function(f_database, stats, proteins, row, no_cond, no_rep) {
  if (f_database[row, "NQS"] < 2) {
    result <- rep(NA, no_cond)
    names(result) <- c(paste0("FC C", 2:no_cond, "/C1"), "Noise")
    return(result)
  }

  subunits <- f_database[row, ]$Subunits[[1]]
  subunits <- subunits[subunits %in% proteins]
  subunit_indexes <- vapply(subunits, function(x) match(x, proteins), integer(1))
  probes <- log2(stats$absolute_df[subunit_indexes, -1, drop = FALSE])
  probes[probes == -Inf] <- NA
  probes <- data.frame(t(apply(probes, 1, add_variance_if_constant)))
  probes <- probes[rowSums(!is.na(probes)) > 1, , drop = FALSE]

  if (nrow(probes) <= 1) {
    result <- rep(NA, no_cond)
    names(result) <- c(paste0("FC C", 2:no_cond, "/C1"), "Noise")
    return(result)
  }

  farms <- fast_farms(probes)
  probes_adj <- (farms$loadings * probes) / sum(farms$loadings, na.rm = TRUE)
  fc <- vapply(2:no_cond, function(condition) {
    condition_mean <- mean(colSums(probes_adj[, condition_indexes(condition, no_rep)], na.rm = TRUE))
    reference_mean <- mean(colSums(probes_adj[, seq_len(no_rep)], na.rm = TRUE))
    log_fc <- condition_mean - reference_mean
    ifelse(log_fc >= 0, 2^log_fc, -1 / (2^log_fc))
  }, numeric(1))
  result <- round(c(fc, farms$noise), 3)
  names(result) <- c(paste0("FC C", 2:no_cond, "/C1"), "Noise")
  result
}

add_variance_if_constant <- function(x) {
  if (length(unique(unlist(x))) == 1) {
    x[1] <- x[1] * 1.0001
  }
  x
}
