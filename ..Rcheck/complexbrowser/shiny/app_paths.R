complexbrowser_app_dir <- normalizePath(
  getOption("complexbrowser.app_dir", getwd()),
  mustWork = FALSE
)

complexbrowser_app_path <- function(...) {
  file.path(complexbrowser_app_dir, ...)
}

complexbrowser_repo_path <- function(...) {
  candidates <- unique(c(
    normalizePath(file.path(complexbrowser_app_dir, "..", ".."), mustWork = FALSE),
    normalizePath(getwd(), mustWork = FALSE)
  ))

  for (candidate in candidates) {
    path <- file.path(candidate, ...)
    if (file.exists(path)) {
      return(path)
    }
  }

  file.path(...)
}
