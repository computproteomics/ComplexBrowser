\name{complexbrowser-complex-analysis}
\alias{complexbrowser_prepare_user_database}
\alias{complexbrowser_filter_stats_for_database}
\alias{complexbrowser_filter_database}
\alias{complexbrowser_score_complexes}
\alias{complexbrowser_display_complex_table}
\alias{complexbrowser_run_complex_analysis}
\alias{complexbrowser_complex_summary}
\alias{complexbrowser_changing_table_data}
\alias{complexbrowser_select_database}
\title{Run ComplexBrowser complex-analysis workflows}
\usage{
complexbrowser_prepare_user_database(csv_file)

complexbrowser_select_database(database)

complexbrowser_filter_stats_for_database(stats, database, organism)

complexbrowser_filter_database(f_data, database, organism)

complexbrowser_score_complexes(filtered_database, stats, no_cond, no_rep)

complexbrowser_display_complex_table(scored_database)

complexbrowser_run_complex_analysis(stats, database, organism, no_cond, no_rep,
  database_name = NULL)

complexbrowser_complex_summary(scored_database, no_cond, no_rep, condition,
  noise_threshold)

complexbrowser_changing_table_data(scored_database, condition, noise_threshold,
  fc_threshold)
}
\arguments{
\item{csv_file}{Path to a user-defined complex database CSV file. The file
must contain columns \code{ComplexID}, \code{Complex_Name}, \code{Organism},
\code{Subunits}, \code{GO_terms}, and \code{Comment}. \code{Subunits} must be
a semicolon-separated list of protein accessions with no embedded spaces.}

\item{database}{Complex database selector. Use \code{"CORUM"},
\code{"EBI Complex Portal"}, a prepared complex database data frame, or a path
to a user-defined CSV database. Prepared database data frames must contain
\code{ComplexID}, \code{Complex_Name}, \code{Organism}, \code{NUS},
\code{Subunits}, and \code{GO_terms}.}

\item{stats}{QC statistics list, normally \code{qc$stats} from
\code{complexbrowser_run_qc()}. Required fields include \code{absolute_df},
\code{FC_df}, and the other statistic matrices returned by
\code{complexbrowser_calculate_statistics()}.}

\item{organism}{Organism label to analyze. The label must match the selected
database exactly. Inspect available labels with
\code{sort(unique(complexbrowser_load_corum()$Organism))} or
\code{sort(unique(complexbrowser_load_complex_portal()$Organism))}.}

\item{f_data}{Filtered absolute intensity data. This is usually
\code{filtered_stats$absolute_df}, where \code{filtered_stats} was returned by
\code{complexbrowser_filter_stats_for_database()}.}

\item{filtered_database}{Filtered complex database returned by
\code{complexbrowser_filter_database()}. Rows contain complexes with at least
one quantified subunit and appended \code{NQS} and \code{Coverage} columns.}

\item{no_cond}{Positive integer number of experimental conditions in the input
data. This must match the QC settings used to create \code{stats}.}

\item{no_rep}{Positive integer number of replicate measurement columns per
condition. This must match the QC settings used to create \code{stats}.}

\item{scored_database}{Filtered database with appended fold-change score
columns and \code{Noise}, normally \code{result$scored_database} from
\code{complexbrowser_run_complex_analysis()}.}

\item{database_name}{Optional database label stored in the returned metadata.
Use this when \code{database} is a data frame or file path and you still want a
human-readable name in downstream output.}

\item{condition}{Condition number for summaries or top-changing tables. Use
condition 2 or higher when interpreting fold-change columns, because condition
1 is the reference.}

\item{noise_threshold}{Maximum allowed complex noise for summary filtering.
Use \code{1} to keep all scored complexes, or a smaller value such as
\code{0.5} for a stricter summary.}

\item{fc_threshold}{Fold-change threshold for top-changing complex tables.
Positive values define up-regulated complexes; negative fold-change values are
used for down-regulated complexes.}
}
\value{
\code{complexbrowser_prepare_user_database()} returns a prepared complex
database data frame.

\code{complexbrowser_select_database()} returns a prepared database from a
selector, data frame, or CSV path.

\code{complexbrowser_filter_stats_for_database()} returns the QC statistics
list filtered to proteins that occur in complexes for the selected organism.

\code{complexbrowser_filter_database()} returns a database table filtered to
complexes with quantified subunits, or \code{NULL} when no complexes match.

\code{complexbrowser_score_complexes()} returns a matrix with fold-change
columns \code{FC C2/C1}, \code{FC C3/C1}, ... and \code{Noise}.

\code{complexbrowser_display_complex_table()} returns the scored database with
subunits collapsed into comma-separated text for display or CSV export.

\code{complexbrowser_run_complex_analysis()} returns a
\code{complexbrowser_complex_result} object, a list with fields
\code{filtered_stats}, \code{filtered_database}, \code{scores},
\code{scored_database}, \code{display_table}, and \code{metadata}.

\code{complexbrowser_complex_summary()} returns a one-sentence character
summary for the selected condition.

\code{complexbrowser_changing_table_data()} returns a data frame containing top
up- and down-regulated complexes after noise and fold-change filtering.
}
\description{
Package-level helpers for reusing the ComplexBrowser protein complex analysis
workflow from R code. The main user-facing function is
\code{complexbrowser_run_complex_analysis()}; the other helpers expose the
individual filtering, scoring, display, and summary steps.
}
\details{
Bundled database selectors are \code{"CORUM"} and
\code{"EBI Complex Portal"}. \code{"CORUM"} currently uses short organism
labels such as \code{"Human"}, \code{"Mouse"}, and \code{"Rat"}.
\code{"EBI Complex Portal"} uses scientific names such as
\code{"Homo sapiens"}, \code{"Mus musculus"}, and
\code{"Rattus norvegicus"}.

The full available organism list depends on the bundled database files. Use:
\preformatted{
sort(unique(complexbrowser_load_corum()$Organism))
sort(unique(complexbrowser_load_complex_portal()$Organism))
}

The analysis first filters proteins to the selected organism database, then
keeps complexes with at least one quantified subunit. Complexes with fewer than
two quantified subunits are kept in the filtered database but receive missing
fold-change and noise scores.
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

result <- complexbrowser_run_complex_analysis(
  stats = qc$stats,
  database = "CORUM",
  organism = "Mouse",
  no_cond = 4,
  no_rep = 2,
  database_name = "CORUM"
)

result$metadata
head(result$display_table[, c("ComplexID", "Complex_Name", "Coverage", "Noise")])

sort(unique(complexbrowser_load_corum()$Organism))
head(sort(unique(complexbrowser_load_complex_portal()$Organism)))
}
\seealso{
\code{\link{complexbrowser_run_qc}},
\code{\link{complexbrowser_load_corum}},
\code{\link{complexbrowser_load_complex_portal}},
\code{vignette("complex-analysis", package = "complexbrowser")}
}
