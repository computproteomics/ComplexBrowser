\name{complexbrowser-cli}
\alias{complexbrowser-cli}
\alias{complexbrowser_cli}
\title{Run the ComplexBrowser command-line interface}
\usage{
complexbrowser_cli(args = commandArgs(trailingOnly = TRUE))
}
\arguments{
\item{args}{Character vector of command-line-style arguments. The first value
is the subcommand (\code{"qc"} or \code{"complex"}); remaining values are
\code{--option value} pairs. Defaults to trailing command-line arguments when
called from \code{Rscript}.}
}
\value{
An integer status code, invisibly: \code{0} for success, \code{2} for usage
errors, and \code{1} for unexpected runtime errors. Successful runs write CSV
and RDS files to \code{--outdir}.
}
\description{
Runs headless ComplexBrowser workflows from command-line-style arguments. The
subcommands are \code{qc} and \code{complex}; both use package APIs for
calculation and write structured outputs for pipelines or external software.
}
\details{
Common QC options:
\itemize{
\item \code{--input}: CSV input table path.
\item \code{--outdir}: output directory; created when missing.
\item \code{--conditions}: positive integer number of conditions.
\item \code{--replicates}: positive integer number of replicates per condition.
\item \code{--grouped}: \code{true} if replicate columns are grouped by
condition; default \code{false}.
\item \code{--log2}: \code{true} if measurement values are log2 transformed;
default \code{true}.
\item \code{--q-values}: \code{true} if q-value columns are supplied; default
\code{true}.
\item \code{--normalization}: \code{none}, \code{Mean}, \code{Median},
\code{Quantile}, or \code{Total Intensity}; default \code{none}.
\item \code{--design}: \code{unpaired} or \code{paired}; default
\code{unpaired}.
}

The \code{complex} subcommand additionally requires:
\itemize{
\item \code{--database}: \code{CORUM}, \code{EBI Complex Portal}, or a path to
a user-defined complex database CSV.
\item \code{--organism}: organism label exactly as used in the selected
database, for example \code{Mouse} for CORUM or \code{Mus musculus} for EBI
Complex Portal.
\item \code{--database-name}: optional display label for metadata.
}

The \code{qc} command writes \code{input_statistics.csv} and
\code{qc_result.rds}. The \code{complex} command writes those QC outputs plus
\code{complex_result.rds} and, when complexes match, \code{complex_table.csv}.

R packages do not normally install executables directly onto the user's shell
\code{PATH}. The portable entry point is \code{complexbrowser_cli()} from R, or
an \code{Rscript} wrapper that forwards command-line arguments to this function.
}
\examples{
input <- system.file(
  "shiny", "data", "example_tcell_cut.csv",
  package = "complexbrowser"
)
outdir <- tempfile("complexbrowser-qc-")

status <- complexbrowser_cli(c(
  "qc",
  "--input", input,
  "--outdir", outdir,
  "--conditions", "4",
  "--replicates", "2",
  "--grouped", "true",
  "--log2", "false",
  "--q-values", "false"
))
status
file.exists(file.path(outdir, "input_statistics.csv"))

\dontrun{
Rscript -e 'status <- complexbrowser::complexbrowser_cli(commandArgs(TRUE)); quit(save="no", status=as.integer(status), runLast=FALSE)' --args complex \
  --input input.csv --outdir out --conditions 4 --replicates 2 \
  --grouped true --log2 false --q-values false --database CORUM --organism Mouse

system.file("exec", "complexbrowser", package = "complexbrowser")
}
}
\seealso{
\code{\link{complexbrowser_run_qc}},
\code{\link{complexbrowser_run_complex_analysis}}
}
