complexbrowser_shiny_app_dir <- function() {
  app_dir <- system.file("shiny", package = "complexbrowser")
  if (!nzchar(app_dir)) {
    stop("The packaged Shiny app directory could not be found.", call. = FALSE)
  }
  app_dir
}

#' Launch the packaged ComplexBrowser Shiny app
#'
#' Start the installed ComplexBrowser app from the package `inst/shiny`
#' directory.
#'
#' @param ... Additional arguments passed to `shiny::runApp()`.
#'
#' @return The result of `shiny::runApp()`, invisibly.
#'
#' @examples
#' \dontrun{
#' complexbrowser_run_app()
#' }
#'
#' @export
complexbrowser_run_app <- function(...) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("The shiny package is required to run the ComplexBrowser app.", call. = FALSE)
  }

  shiny::runApp(complexbrowser_shiny_app_dir(), ...)
}
