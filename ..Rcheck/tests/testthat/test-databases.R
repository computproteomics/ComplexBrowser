test_that("prepared CORUM database loads from package assets", {
  corum <- complexbrowser_load_corum()

  expect_s3_class(corum, "data.frame")
  expect_gt(nrow(corum), 0)
  expect_named(
    corum,
    c("ComplexID", "Complex_Name", "Organism", "NUS", "Subunits", "GO_terms", "PubMed.ID")
  )
})

test_that("prepared Complex Portal database loads from package assets", {
  complex_portal <- complexbrowser_load_complex_portal()

  expect_s3_class(complex_portal, "data.frame")
  expect_gt(nrow(complex_portal), 0)
  expect_named(
    complex_portal,
    c("ComplexID", "Complex_Name", "Organism", "NUS", "Subunits", "GO_terms", "Complex_assembly")
  )
})

test_that("missing extdata path errors clearly", {
  expect_error(
    complexbrowser_extdata_path("missing-file.Rds"),
    "ComplexBrowser extdata file not found"
  )
})
