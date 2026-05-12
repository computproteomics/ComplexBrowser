find_repo_file <- function(filename) {
  roots <- c(
    getwd(),
    file.path(getwd(), ".."),
    file.path(getwd(), "..", ".."),
    Sys.getenv("COMPLEXBROWSER_SOURCE_DIR", unset = "")
  )
  roots <- roots[nzchar(roots)]
  candidates <- file.path(roots, filename)
  existing <- candidates[file.exists(candidates)]

  if (length(existing) == 0) {
    return(NA_character_)
  }

  normalizePath(existing[[1]], mustWork = FALSE)
}

expect_numeric_columns_equal <- function(current, expected, tolerance) {
  numeric_columns <- setdiff(names(expected), "ProteinID")

  for (column in numeric_columns) {
    current_values <- suppressWarnings(as.numeric(current[[column]]))
    expected_values <- suppressWarnings(as.numeric(expected[[column]]))
    both_missing <- is.na(current_values) & is.na(expected_values)
    scale <- pmax(abs(expected_values), 1)
    close <- abs(current_values - expected_values) <= tolerance * scale

    expect_true(
      all(both_missing | close, na.rm = TRUE),
      info = paste("Column differs beyond tolerance:", column)
    )
  }
}

load_example_input_fixture <- function() {
  fixture_path <- test_path("fixtures", "example_input_tcell_cut.rds")
  if (file.exists(fixture_path)) {
    return(readRDS(fixture_path))
  }

  example_path <- find_repo_file(file.path("inst", "shiny", "data", "example_tcell_cut.csv"))
  if (is.na(example_path)) {
    return(NULL)
  }

  read.csv(example_path)
}

shiny_helper_path <- function(filename) {
  installed <- system.file("shiny", "R", filename, package = "complexbrowser")
  if (nzchar(installed)) {
    return(installed)
  }
  find_repo_file(file.path("inst", "shiny", "R", filename))
}
