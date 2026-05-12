#' Locate a packaged ComplexBrowser extdata file
#'
#' @param ... Path components below the package `inst/extdata` directory.
#' @param must_work If `TRUE`, error when the resolved file does not exist.
#'
#' @return A character scalar with the resolved path.
#' @export
complexbrowser_extdata_path <- function(..., must_work = TRUE) {
  filename <- file.path(...)
  candidates <- c(
    system.file("extdata", filename, package = "complexbrowser", mustWork = FALSE),
    file.path("inst", "extdata", filename),
    filename
  )

  candidates <- candidates[nzchar(candidates)]
  existing <- candidates[file.exists(candidates)]

  if (length(existing) > 0) {
    return(normalizePath(existing[[1]], mustWork = FALSE))
  }

  if (isTRUE(must_work)) {
    stop("ComplexBrowser extdata file not found: ", filename, call. = FALSE)
  }

  candidates[[1]]
}

#' Load the bundled prepared CORUM database
#'
#' @return A data frame containing prepared CORUM complex records.
#' @export
complexbrowser_load_corum <- function() {
  readRDS(complexbrowser_extdata_path("Corum_prepared_20221125.Rds"))
}

#' Load the bundled prepared EBI Complex Portal database
#'
#' @return A data frame containing prepared EBI Complex Portal complex records.
#' @export
complexbrowser_load_complex_portal <- function() {
  readRDS(complexbrowser_extdata_path("Complex_Portal_Prepared.Rds"))
}
