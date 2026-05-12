#' Run the ComplexBrowser command-line interface
#'
#' @param args Command-line arguments. Defaults to `commandArgs(TRUE)`.
#'
#' @return An integer status code, invisibly: 0 for success, 2 for usage errors,
#'   and 1 for unexpected runtime errors.
#' @export
complexbrowser_cli <- function(args = commandArgs(trailingOnly = TRUE)) {
  tryCatch(
    {
      dispatch_cli(args)
      invisible(0L)
    },
    complexbrowser_cli_usage_error = function(error) {
      cli_message("Error: ", conditionMessage(error))
      cli_message(cli_usage())
      invisible(2L)
    },
    error = function(error) {
      cli_message("Error: ", conditionMessage(error))
      invisible(1L)
    }
  )
}

dispatch_cli <- function(args) {
  if (length(args) == 0L || args[[1]] %in% c("-h", "--help")) {
    stop_cli_usage("Missing command.")
  }

  command <- args[[1]]
  options <- parse_cli_options(args[-1])
  if (identical(command, "qc")) {
    return(run_cli_qc(options))
  }
  if (identical(command, "complex")) {
    return(run_cli_complex(options))
  }

  stop_cli_usage("Unsupported command: ", command)
}

run_cli_qc <- function(options) {
  settings <- parse_qc_cli_settings(options)
  qc <- run_cli_qc_workflow(settings)
  write_cli_qc_outputs(qc, settings$outdir)
}

run_cli_complex <- function(options) {
  settings <- parse_complex_cli_settings(options)
  qc <- run_cli_qc_workflow(settings)
  complex <- complexbrowser_run_complex_analysis(
    stats = qc$stats,
    database = settings$database,
    organism = settings$organism,
    no_cond = settings$no_cond,
    no_rep = settings$no_rep,
    database_name = settings$database_name
  )

  write_cli_qc_outputs(qc, settings$outdir)
  write_cli_complex_outputs(complex, settings$outdir)
}

parse_cli_options <- function(args) {
  options <- list()
  index <- 1L
  while (index <= length(args)) {
    item <- args[[index]]
    if (!startsWith(item, "--")) {
      stop_cli_usage("Expected option beginning with --, got: ", item)
    }

    parsed <- parse_cli_option(args, index)
    options[[parsed$name]] <- parsed$value
    index <- parsed$next_index
  }
  options
}

parse_cli_option <- function(args, index) {
  item <- args[[index]]
  if (grepl("=", item, fixed = TRUE)) {
    parts <- strsplit(sub("^--", "", item), "=", fixed = TRUE)[[1]]
    return(list(name = parts[[1]], value = paste(parts[-1], collapse = "="), next_index = index + 1L))
  }

  name <- sub("^--", "", item)
  if (index + 1L > length(args) || startsWith(args[[index + 1L]], "--")) {
    stop_cli_usage("Missing value for --", name)
  }
  list(name = name, value = args[[index + 1L]], next_index = index + 2L)
}

parse_qc_cli_settings <- function(options) {
  outdir <- required_option(options, "outdir")
  ensure_output_dir(outdir)
  list(
    input = validate_input_file(required_option(options, "input")),
    outdir = outdir,
    no_cond = parse_positive_integer(required_option(options, "conditions"), "conditions"),
    no_rep = parse_positive_integer(required_option(options, "replicates"), "replicates"),
    grouped = parse_boolean(option_value(options, "grouped", "false"), "grouped"),
    log2 = parse_boolean(option_value(options, "log2", "true"), "log2"),
    q_values = parse_boolean(option_value(options, "q-values", "true"), "q-values"),
    normalization = parse_normalization(option_value(options, "normalization", "none")),
    design = parse_design(option_value(options, "design", "unpaired"))
  )
}

parse_complex_cli_settings <- function(options) {
  settings <- parse_qc_cli_settings(options)
  settings$database <- required_option(options, "database")
  settings$organism <- required_option(options, "organism")
  settings$database_name <- option_value(options, "database-name", settings$database)
  settings
}

run_cli_qc_workflow <- function(settings) {
  input <- utils::read.csv(settings$input, check.names = FALSE)
  complexbrowser_run_qc(
    data = input,
    no_cond = settings$no_cond,
    no_rep = settings$no_rep,
    log2 = settings$log2,
    grouped = settings$grouped,
    q_values = settings$q_values,
    normalization = settings$normalization,
    design = settings$design
  )
}

write_cli_qc_outputs <- function(qc, outdir) {
  complexbrowser_write_input_statistics(qc$merged_table, file.path(outdir, "input_statistics.csv"))
  saveRDS(qc, file.path(outdir, "qc_result.rds"))
}

write_cli_complex_outputs <- function(complex, outdir) {
  saveRDS(complex, file.path(outdir, "complex_result.rds"))
  if (!is.null(complex$display_table)) {
    complexbrowser_write_complex_table(complex$display_table, file.path(outdir, "complex_table.csv"))
  }
}

required_option <- function(options, name) {
  value <- option_value(options, name, NULL)
  if (is.null(value) || !nzchar(value)) {
    stop_cli_usage("Missing required option --", name)
  }
  value
}

option_value <- function(options, name, default) {
  value <- options[[name]]
  if (is.null(value)) {
    return(default)
  }
  value
}

validate_input_file <- function(path) {
  if (!file.exists(path)) {
    stop_cli_usage("Input file not found: ", path)
  }
  path
}

ensure_output_dir <- function(path) {
  if (!dir.exists(path) && !dir.create(path, recursive = TRUE, showWarnings = FALSE)) {
    stop_cli_usage("Could not create output directory: ", path)
  }
  invisible(path)
}

parse_positive_integer <- function(value, name) {
  parsed <- suppressWarnings(as.integer(value))
  if (is.na(parsed) || parsed < 1L || as.character(parsed) != value) {
    stop_cli_usage("Option --", name, " must be a positive integer.")
  }
  parsed
}

parse_boolean <- function(value, name) {
  normalized <- tolower(value)
  if (normalized %in% c("true", "t", "1", "yes", "y")) {
    return(TRUE)
  }
  if (normalized %in% c("false", "f", "0", "no", "n")) {
    return(FALSE)
  }
  stop_cli_usage("Option --", name, " must be true or false.")
}

parse_normalization <- function(value) {
  if (tolower(value) %in% c("none", "null", "na", "")) {
    return(NULL)
  }

  allowed <- c("Total Intensity", "Mean", "Median", "Quantile")
  matched <- allowed[tolower(allowed) == tolower(value)]
  if (length(matched) == 1L) {
    return(matched)
  }
  stop_cli_usage("Unsupported normalization method: ", value)
}

parse_design <- function(value) {
  if (value %in% c("unpaired", "paired")) {
    return(value)
  }
  stop_cli_usage("Unsupported design: ", value)
}

stop_cli_usage <- function(...) {
  message <- paste0(...)
  error <- structure(list(message = message), class = c("complexbrowser_cli_usage_error", "error", "condition"))
  stop(error)
}

cli_message <- function(...) {
  cat(paste0(..., "\n"), file = stderr())
}

cli_usage <- function() {
  paste(
    "Usage:",
    "  complexbrowser qc --input FILE --outdir DIR --conditions N --replicates N [--grouped true|false] [--log2 true|false] [--q-values true|false] [--normalization none|Mean|Median|Quantile|Total Intensity] [--design unpaired|paired]",
    "  complexbrowser complex --input FILE --outdir DIR --conditions N --replicates N --database CORUM|\"EBI Complex Portal\"|FILE --organism NAME [QC options]",
    sep = "\n"
  )
}
