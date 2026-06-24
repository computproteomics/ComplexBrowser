test_that("package QC workflow matches bundled example fixture", {
  fixture <- readRDS(test_path("fixtures", "example_qc_unpaired.rds"))
  example_data <- load_example_input_fixture()
  skip_if(is.null(example_data), "bundled example input is not available")
  result <- NULL
  expect_warning(
    result <- complexbrowser_run_qc(
      data = example_data,
      no_cond = fixture$metadata$no_cond,
      no_rep = fixture$metadata$no_rep,
      log2 = FALSE,
      grouped = TRUE,
      q_values = fixture$metadata$qValues,
      normalization = fixture$metadata$normalize,
      design = fixture$metadata$design
    ),
    "Zero sample variances"
  )

  current <- as.data.frame(result$merged_table, stringsAsFactors = FALSE)
  expected <- as.data.frame(fixture$merged, stringsAsFactors = FALSE)

  expect_s3_class(result, "complexbrowser_qc_result")
  expect_equal(dim(current), dim(expected))
  expect_named(current, names(expected))
  expect_equal(current$ProteinID, expected$ProteinID)
  expect_numeric_columns_equal(current, expected, fixture$metadata$tolerance)
})

test_that("input preparation reports missing q-value columns", {
  input <- data.frame(protein = "P1", C1 = 1, C2 = 2)

  expect_error(
    complexbrowser_prepare_input_table(input, no_cond = 2, no_rep = 1, q_values = TRUE),
    "expected condition, replicate, and q-value columns"
  )
})
