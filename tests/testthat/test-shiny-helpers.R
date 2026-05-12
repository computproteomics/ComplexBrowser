test_that("species selector prefers the organism with matching accessions", {
  source(shiny_helper_path("ui_helpers.R"))
  fixture <- readRDS(test_path("fixtures", "example_qc_unpaired.rds"))
  ebi <- complexbrowser_load_complex_portal()

  selected <- complexbrowser_species_selection(ebi, stats = fixture$stats, preferred = "Homo sapiens")

  expect_true("Homo sapiens" %in% selected$choices)
  expect_equal(selected$selected, "Mus musculus")
})

test_that("species selector keeps preferred organism when no statistics are available", {
  source(shiny_helper_path("ui_helpers.R"))
  ebi <- complexbrowser_load_complex_portal()

  selected <- complexbrowser_species_selection(ebi, stats = NULL, preferred = "Homo sapiens")

  expect_equal(selected$selected, "Homo sapiens")
})
