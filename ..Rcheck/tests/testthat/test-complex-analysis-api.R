test_that("package complex analysis matches CORUM Mouse fixture", {
  fixture <- readRDS(test_path("fixtures", "example_complex_corum_mouse.rds"))
  example_data <- load_example_input_fixture()
  skip_if(is.null(example_data), "bundled example input is not available")

  qc <- NULL
  expect_warning(
    qc <- complexbrowser_run_qc(
      data = example_data,
      no_cond = fixture$metadata$no_cond,
      no_rep = fixture$metadata$no_rep,
      log2 = FALSE,
      grouped = TRUE,
      q_values = FALSE,
      normalization = NULL,
      design = "unpaired"
    ),
    "Zero sample variances"
  )

  result <- complexbrowser_run_complex_analysis(
    stats = qc$stats,
    database = fixture$metadata$database,
    organism = fixture$metadata$organism,
    no_cond = fixture$metadata$no_cond,
    no_rep = fixture$metadata$no_rep,
    database_name = fixture$metadata$database
  )

  current <- as.data.frame(result$display_table, stringsAsFactors = FALSE)
  expected <- as.data.frame(fixture$display_table, stringsAsFactors = FALSE)

  expect_s3_class(result, "complexbrowser_complex_result")
  expect_equal(result$metadata$no_proteins_used, fixture$metadata$no_filtered_proteins)
  expect_equal(result$metadata$no_complexes, fixture$metadata$no_complexes)
  expect_equal(dim(current), dim(expected))
  expect_named(current, names(expected))
  expect_equal(as.character(current$ComplexID), as.character(expected$ComplexID))
  expect_equal(as.character(current$Complex_Name), as.character(expected$Complex_Name))
  expect_equal(as.character(current$Subunits), as.character(expected$Subunits))
  expect_equal(
    complexbrowser_complex_summary(
      result$scored_database,
      no_cond = fixture$metadata$no_cond,
      no_rep = fixture$metadata$no_rep,
      condition = fixture$summary$condition,
      noise_threshold = fixture$summary$noise_threshold
    ),
    fixture$summary$text
  )

  numeric_columns <- names(expected)[vapply(expected, is.numeric, logical(1))]
  for (column in numeric_columns) {
    scale <- pmax(abs(expected[[column]]), 1)
    close <- abs(current[[column]] - expected[[column]]) <= fixture$metadata$tolerance * scale
    expect_true(
      all(is.na(current[[column]]) & is.na(expected[[column]]) | close, na.rm = TRUE),
      info = paste("Column differs beyond tolerance:", column)
    )
  }
})

test_that("database selector supports bundled and invalid databases", {
  expect_s3_class(complexbrowser_select_database("CORUM"), "data.frame")
  expect_s3_class(complexbrowser_select_database("EBI Complex Portal"), "data.frame")
  expect_error(complexbrowser_select_database("Nope"), "Unsupported complex database")
})

test_that("complex analysis returns no-match result without scores", {
  fixture <- readRDS(test_path("fixtures", "example_qc_unpaired.rds"))
  result <- complexbrowser_run_complex_analysis(
    stats = fixture$stats,
    database = complexbrowser_load_corum(),
    organism = "Not a species",
    no_cond = fixture$metadata$no_cond,
    no_rep = fixture$metadata$no_rep,
    database_name = "CORUM"
  )

  expect_s3_class(result, "complexbrowser_complex_result")
  expect_equal(result$metadata$no_complexes, 0)
  expect_null(result$filtered_database)
  expect_null(result$display_table)
})
