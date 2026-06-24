pkgname <- "complexbrowser"
source(file.path(R.home("share"), "R", "examples-header.R"))
options(warn = 1)
library('complexbrowser')

base::assign(".oldSearch", base::search(), pos = 'CheckExEnv')
base::assign(".old_wd", base::getwd(), pos = 'CheckExEnv')
cleanEx()
nameEx("complexbrowser-package")
### * complexbrowser-package

flush(stderr()); flush(stdout())

### Name: complexbrowser-package
### Title: ComplexBrowser proteomics quality-control and protein-complex
###   workflows
### Aliases: complexbrowser-package complexbrowser

### ** Examples

library(complexbrowser)

input_file <- system.file(
  "shiny", "data", "example_tcell_cut.csv",
  package = "complexbrowser"
)
input <- read.csv(input_file, check.names = FALSE)

qc <- suppressWarnings(complexbrowser_run_qc(
  input,
  no_cond = 4,
  no_rep = 2,
  log2 = FALSE,
  grouped = TRUE,
  q_values = FALSE
))

qc$metadata

sort(unique(complexbrowser_load_corum()$Organism))



cleanEx()
nameEx("complexbrowser_run_app")
### * complexbrowser_run_app

flush(stderr()); flush(stdout())

### Name: complexbrowser_run_app
### Title: Launch the packaged ComplexBrowser Shiny app
### Aliases: complexbrowser_run_app

### ** Examples

## Not run: 
##D complexbrowser_run_app()
## End(Not run)




### * <FOOTER>
###
cleanEx()
options(digits = 7L)
base::cat("Time elapsed: ", proc.time() - base::get("ptime", pos = 'CheckExEnv'),"\n")
grDevices::dev.off()
###
### Local variables: ***
### mode: outline-minor ***
### outline-regexp: "\\(> \\)?### [*]+" ***
### End: ***
quit('no')
