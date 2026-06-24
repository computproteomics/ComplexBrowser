test_that("download filenames preserve Shiny prefixes and extensions", {
  timestamp <- "2024-01-02 03:04:05"

  expect_equal(
    complexbrowser_input_statistics_filename(timestamp),
    "MSComplexR_Input_WithStats2024-01-02 03:04:05.csv"
  )
  expect_equal(
    complexbrowser_complex_table_filename(timestamp),
    "Protein_complex_resutls2024-01-02 03:04:05.csv"
  )
})

test_that("input statistics export preserves columns and values", {
  fixture <- readRDS(test_path("fixtures", "example_qc_unpaired.rds"))
  file <- tempfile(fileext = ".csv")

  complexbrowser_write_input_statistics(fixture$merged, file)
  current <- utils::read.csv(file, check.names = FALSE)
  expected <- as.data.frame(fixture$merged, stringsAsFactors = FALSE)

  expect_equal(dim(current), dim(expected))
  expect_named(current, names(expected))
  expect_equal(as.character(current$ProteinID), as.character(expected$ProteinID))
  expect_numeric_columns_equal(current, expected, fixture$metadata$tolerance)
})

test_that("complex table export preserves columns and values", {
  fixture <- readRDS(test_path("fixtures", "example_complex_corum_mouse.rds"))
  file <- tempfile(fileext = ".csv")

  complexbrowser_write_complex_table(fixture$display_table, file)
  current <- utils::read.csv(file, check.names = FALSE)
  expected <- as.data.frame(fixture$display_table, stringsAsFactors = FALSE)

  expect_equal(dim(current), dim(expected))
  expect_named(current, names(expected))
  expect_equal(as.character(current$ComplexID), as.character(expected$ComplexID))
  expect_equal(as.character(current$Complex_Name), as.character(expected$Complex_Name))
  expect_equal(as.character(current$Subunits), as.character(expected$Subunits))

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

test_that("QC report data has the expected report-table shape", {
  fixture <- readRDS(test_path("fixtures", "example_qc_unpaired.rds"))

  current <- complexbrowser_prepare_qc_report_data(
    stats = fixture$stats,
    no_cond = fixture$metadata$no_cond,
    no_rep = fixture$metadata$no_rep
  )

  expect_named(current, c("r", "c", "VAL_t", "CV_t", "fc_t", "qValue_t"))
  expect_equal(current$r, ceiling(fixture$metadata$no_cond / 2))
  expect_equal(current$c, 2)
  expect_equal(dim(current$VAL_t), c(4L, fixture$metadata$no_cond))
  expect_equal(dim(current$CV_t), c(4L, fixture$metadata$no_cond))
  expect_equal(dim(current$fc_t), c(4L, fixture$metadata$no_cond - 1L))
  expect_equal(dim(current$qValue_t), c(4L, fixture$metadata$no_cond - 1L))
  expect_equal(rownames(current$VAL_t), c("Min", "Mean", "Median", "Max"))
  expect_equal(colnames(current$VAL_t), paste0("Cond. ", seq_len(fixture$metadata$no_cond)))
})
