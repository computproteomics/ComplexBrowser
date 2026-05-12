\name{complexbrowser-package}
\alias{complexbrowser-package}
\alias{complexbrowser}
\docType{package}
\title{ComplexBrowser proteomics quality-control and protein-complex workflows}
\description{
The \pkg{complexbrowser} package exposes reusable R functions for the
ComplexBrowser Shiny application. It supports tabular proteomics input
preparation, QC/statistics calculation, bundled complex database loading,
protein-complex matching and scoring, CSV/RDS exports, vignettes, and a thin
command-line interface for headless workflows.
}
\details{
Main workflow functions:
\itemize{
\item \code{complexbrowser_run_qc()} prepares input data and calculates QC
statistics.
\item \code{complexbrowser_run_complex_analysis()} matches quantified proteins
to CORUM, EBI Complex Portal, or user-defined complex databases.
\item \code{complexbrowser_cli()} runs the package workflows from
command-line-style arguments.
\item \code{complexbrowser_run_app()} starts the packaged Shiny application.
}

Bundled data:
\itemize{
\item Prepared CORUM and EBI Complex Portal databases are available through
\code{complexbrowser_load_corum()} and
\code{complexbrowser_load_complex_portal()}.
\item Reusable example inputs are available below
\code{system.file("extdata", "examples", package = "complexbrowser")}.
\item Shiny-specific example inputs are available below
\code{system.file("shiny", "data", package = "complexbrowser")}.
}
}
\examples{
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
}
\seealso{
\code{\link{complexbrowser_run_qc}},
\code{\link{complexbrowser_run_complex_analysis}},
\code{\link{complexbrowser_cli}},
\code{\link{complexbrowser_run_app}},
\code{vignette("qc-workflow", package = "complexbrowser")},
\code{vignette("complex-analysis", package = "complexbrowser")}
}
