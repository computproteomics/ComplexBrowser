\name{complexbrowser-exports}
\alias{complexbrowser-exports}
\alias{complexbrowser_input_statistics_filename}
\alias{complexbrowser_complex_table_filename}
\alias{complexbrowser_write_input_statistics}
\alias{complexbrowser_write_complex_table}
\alias{complexbrowser_prepare_qc_report_data}
\title{Export and report helpers}
\usage{
complexbrowser_input_statistics_filename(time = Sys.time())

complexbrowser_complex_table_filename(time = Sys.time())

complexbrowser_write_input_statistics(table, file)

complexbrowser_write_complex_table(table, file)

complexbrowser_prepare_qc_report_data(stats, no_cond, no_rep)
}
\arguments{
\item{time}{Timestamp included in legacy-compatible download filenames. This
is usually a \code{POSIXct} value such as \code{Sys.time()}, but any value that
can be pasted into a filename is accepted.}

\item{table}{Data frame or matrix to write as CSV. For input statistics this is
usually \code{qc$merged_table}; for complex analysis this is usually
\code{result$display_table}.}

\item{file}{Output CSV path. Parent directories must already exist.}

\item{stats}{QC statistics list, normally \code{qc$stats} from
\code{complexbrowser_run_qc()}.}

\item{no_cond}{Positive integer number of experimental conditions used to
create \code{stats}.}

\item{no_rep}{Positive integer number of replicate measurement columns per
condition used to create \code{stats}.}
}
\value{
Filename helpers return a character scalar. CSV writers return the output path
invisibly after writing \code{row.names = FALSE}. 
\code{complexbrowser_prepare_qc_report_data()} returns a list with layout
values \code{r} and \code{c} plus summary tables \code{VAL_t}, \code{CV_t},
\code{fc_t}, and \code{qValue_t}.
}
\description{
Helpers that preserve the existing Shiny download filenames, CSV formatting,
and QC report data shape while exposing the behavior to package callers.
}
\examples{
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
  q_values = FALSE,
  design = "unpaired"
))

report_data <- complexbrowser_prepare_qc_report_data(qc$stats, 4, 2)
report_data$VAL_t

outfile <- tempfile(fileext = ".csv")
complexbrowser_write_input_statistics(qc$merged_table, outfile)
file.exists(outfile)

complexbrowser_input_statistics_filename(as.POSIXct("2026-05-12 10:00:00"))
}
\seealso{
\code{\link{complexbrowser_run_qc}},
\code{\link{complexbrowser_run_complex_analysis}}
}
