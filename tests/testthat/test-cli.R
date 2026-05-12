test_that("CLI reports usage errors", {
  expect_equal(
    complexbrowser_cli(character()),
    2L
  )
  expect_equal(
    complexbrowser_cli(c("nope")),
    2L
  )
  expect_equal(
    complexbrowser_cli(c(
      "qc",
      "--input", "missing.csv",
      "--outdir", tempdir(),
      "--conditions", "2",
      "--replicates", "4",
      "--grouped", "maybe"
    )),
    2L
  )
})

test_that("CLI QC command writes expected outputs", {
  example_data <- load_example_input_fixture()
  skip_if(is.null(example_data), "bundled example input is not available")
  fixture <- readRDS(test_path("fixtures", "example_qc_unpaired.rds"))
  input <- tempfile(fileext = ".csv")
  outdir <- tempfile()
  utils::write.csv(example_data, input, row.names = FALSE)

  status <- complexbrowser_cli(c(
    "qc",
    "--input", input,
    "--outdir", outdir,
    "--conditions", fixture$metadata$no_cond,
    "--replicates", fixture$metadata$no_rep,
    "--grouped", "true",
    "--log2", "false",
    "--q-values", "false",
    "--design", "unpaired"
  ))

  expect_equal(status, 0L)
  expect_true(file.exists(file.path(outdir, "input_statistics.csv")))
  expect_true(file.exists(file.path(outdir, "qc_result.rds")))

  current <- utils::read.csv(file.path(outdir, "input_statistics.csv"), check.names = FALSE)
  expected <- as.data.frame(fixture$merged, stringsAsFactors = FALSE)
  expect_equal(dim(current), dim(expected))
  expect_named(current, names(expected))
  expect_equal(as.character(current$ProteinID), as.character(expected$ProteinID))
  expect_s3_class(readRDS(file.path(outdir, "qc_result.rds")), "complexbrowser_qc_result")
})

test_that("CLI complex command writes expected outputs", {
  example_data <- load_example_input_fixture()
  skip_if(is.null(example_data), "bundled example input is not available")
  fixture <- readRDS(test_path("fixtures", "example_complex_corum_mouse.rds"))
  input <- tempfile(fileext = ".csv")
  outdir <- tempfile()
  utils::write.csv(example_data, input, row.names = FALSE)

  status <- complexbrowser_cli(c(
    "complex",
    "--input", input,
    "--outdir", outdir,
    "--conditions", fixture$metadata$no_cond,
    "--replicates", fixture$metadata$no_rep,
    "--grouped", "true",
    "--log2", "false",
    "--q-values", "false",
    "--design", "unpaired",
    "--database", "CORUM",
    "--organism", fixture$metadata$organism
  ))

  expect_equal(status, 0L)
  expect_true(file.exists(file.path(outdir, "input_statistics.csv")))
  expect_true(file.exists(file.path(outdir, "qc_result.rds")))
  expect_true(file.exists(file.path(outdir, "complex_result.rds")))
  expect_true(file.exists(file.path(outdir, "complex_table.csv")))

  current <- utils::read.csv(file.path(outdir, "complex_table.csv"), check.names = FALSE)
  expected <- as.data.frame(fixture$display_table, stringsAsFactors = FALSE)
  expect_equal(dim(current), dim(expected))
  expect_named(current, names(expected))
  expect_equal(as.character(current$ComplexID), as.character(expected$ComplexID))
  expect_s3_class(readRDS(file.path(outdir, "complex_result.rds")), "complexbrowser_complex_result")
})

test_that("CLI complex command treats no matches as a successful result", {
  example_data <- load_example_input_fixture()
  skip_if(is.null(example_data), "bundled example input is not available")
  fixture <- readRDS(test_path("fixtures", "example_complex_corum_mouse.rds"))
  input <- tempfile(fileext = ".csv")
  outdir <- tempfile()
  utils::write.csv(example_data, input, row.names = FALSE)

  status <- complexbrowser_cli(c(
    "complex",
    "--input", input,
    "--outdir", outdir,
    "--conditions", fixture$metadata$no_cond,
    "--replicates", fixture$metadata$no_rep,
    "--grouped", "true",
    "--log2", "false",
    "--q-values", "false",
    "--database", "CORUM",
    "--organism", "Not a species"
  ))

  result <- readRDS(file.path(outdir, "complex_result.rds"))
  expect_equal(status, 0L)
  expect_true(file.exists(file.path(outdir, "complex_result.rds")))
  expect_false(file.exists(file.path(outdir, "complex_table.csv")))
  expect_equal(result$metadata$no_complexes, 0L)
  expect_null(result$display_table)
})
