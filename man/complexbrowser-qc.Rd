\name{complexbrowser-qc}
\alias{complexbrowser_prepare_input_table}
\alias{complexbrowser_calculate_statistics}
\alias{complexbrowser_run_qc}
\title{Run ComplexBrowser quality-control workflows}
\usage{
complexbrowser_prepare_input_table(data, no_cond, no_rep, log2 = TRUE,
  grouped = FALSE, q_values = TRUE)

complexbrowser_calculate_statistics(data, no_cond, no_rep, q_values = TRUE,
  normalization = NULL, design = c("unpaired", "paired"))

complexbrowser_run_qc(data, no_cond, no_rep, log2 = TRUE, grouped = FALSE,
  q_values = TRUE, normalization = NULL, design = c("unpaired", "paired"))
}
\arguments{
\item{data}{Input data frame. The first column must contain unique protein
identifiers. Measurement columns follow next. If \code{q_values = TRUE}, the
last \code{no_cond - 1} columns are interpreted as q-values comparing
conditions 2, 3, ... to condition 1.}

\item{no_cond}{Positive integer number of experimental conditions.}

\item{no_rep}{Positive integer number of replicate measurement columns per
condition.}

\item{log2}{Logical. If \code{TRUE}, measurement values are treated as log2
intensities and converted back to absolute intensities before QC statistics are
calculated. If \code{FALSE}, values are treated as already being on the raw
intensity scale.}

\item{grouped}{Logical. If \code{TRUE}, measurement columns are expected in
condition-major order: all replicates for condition 1, then all replicates for
condition 2, and so on. If \code{FALSE}, columns are expected in
replicate-major order: replicate 1 for all conditions, then replicate 2 for all
conditions, and so on.}

\item{q_values}{Logical. If \code{TRUE}, q-value columns are read from
\code{data}. If \code{FALSE}, q-values are calculated with LIMMA from the
measurement columns.}

\item{normalization}{Optional normalization method for measurement columns.
Use \code{NULL} for no normalization, or one of \code{"Total Intensity"},
\code{"Mean"}, \code{"Median"}, or \code{"Quantile"}.}

\item{design}{Statistical design used only when q-values must be calculated
(\code{q_values = FALSE}) or normalization forces recalculation. Use
\code{"unpaired"} for independent samples and \code{"paired"} when replicate
measurements are paired across conditions.}
}
\value{
\code{complexbrowser_prepare_input_table()} returns a data frame with standard
ComplexBrowser column names and ordering.

\code{complexbrowser_calculate_statistics()} returns a named list containing
\code{absolute_df}, \code{log2_absolute_df}, \code{means_df}, \code{SD_df},
\code{CV_df}, \code{qValue_df}, \code{log2_means}, \code{zScore},
\code{ratios}, \code{FC_df}, and \code{log2_ratios}.

\code{complexbrowser_run_qc()} returns a \code{complexbrowser_qc_result}
object, a list with fields \code{input}, \code{stats}, \code{merged_table},
and \code{metadata}.
}
\description{
Package-level quality-control helpers for reusing the ComplexBrowser Shiny QC
workflow from R code. \code{complexbrowser_run_qc()} is the main entry point;
it prepares input data, calculates QC/statistical summaries, and returns the
merged table used by the app and CLI.
}
\details{
For a data set with \code{no_cond = 3} and \code{no_rep = 2}, the measurement
portion contains six columns. With \code{grouped = TRUE}, the columns are
interpreted as \code{C1_1, C1_2, C2_1, C2_2, C3_1, C3_2}. With
\code{grouped = FALSE}, the columns are interpreted as
\code{C1_1, C2_1, C3_1, C1_2, C2_2, C3_2}.

When q-values are supplied, there must be \code{no_cond - 1} q-value columns.
They are renamed to \code{qValue C2}, \code{qValue C3}, ... and are treated as
comparisons against condition 1.
}
\examples{
input_file <- system.file(
  "shiny", "data", "example_tcell_cut.csv",
  package = "complexbrowser"
)
input <- read.csv(input_file, check.names = FALSE)

qc <- suppressWarnings(complexbrowser_run_qc(
  data = input,
  no_cond = 4,
  no_rep = 2,
  log2 = FALSE,
  grouped = TRUE,
  q_values = FALSE,
  normalization = NULL,
  design = "unpaired"
))

qc$metadata
dim(qc$merged_table)
head(qc$merged_table[, c("ProteinID", "Mean intensity C1", "qValue C2")])
}
\seealso{
\code{\link{complexbrowser_run_complex_analysis}},
\code{\link{complexbrowser_prepare_qc_report_data}},
\code{vignette("qc-workflow", package = "complexbrowser")}
}
