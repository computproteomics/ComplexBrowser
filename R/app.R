complexbrowser_shiny_app_dir <- function() {
  app_dir <- system.file("shiny", package = "complexbrowser")
  if (!nzchar(app_dir)) {
    stop("The packaged Shiny app directory could not be found.", call. = FALSE)
  }
  app_dir
}

complexbrowser_run_app <- function(...) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("The shiny package is required to run the ComplexBrowser app.", call. = FALSE)
  }

  shiny::runApp(complexbrowser_shiny_app_dir(), ...)
}
