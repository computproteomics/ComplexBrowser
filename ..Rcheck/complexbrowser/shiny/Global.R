complexbrowser_app_paths_file <- local({
  frame_file <- tryCatch(normalizePath(sys.frame(1)$ofile, mustWork = TRUE), error = function(e) "")
  candidates <- c(
    file.path(dirname(frame_file), "app_paths.R"),
    "app_paths.R",
    file.path("inst", "shiny", "app_paths.R")
  )
  candidates[file.exists(candidates)][[1]]
})
options(complexbrowser.app_dir = dirname(normalizePath(complexbrowser_app_paths_file, mustWork = TRUE)))
source(complexbrowser_app_paths_file, local = FALSE)

if (requireNamespace("complexbrowser", quietly = TRUE)) {
  corum_prepared <- complexbrowser::complexbrowser_load_corum()
  complex_portal_prepared <- complexbrowser::complexbrowser_load_complex_portal()
} else {
  source(complexbrowser_repo_path("R", "database.R"), local = FALSE)
  corum_prepared <- complexbrowser_load_corum()
  complex_portal_prepared <- complexbrowser_load_complex_portal()
}


