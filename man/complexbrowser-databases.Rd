\name{complexbrowser-databases}
\alias{complexbrowser_extdata_path}
\alias{complexbrowser_load_corum}
\alias{complexbrowser_load_complex_portal}
\title{Load bundled ComplexBrowser database assets}
\usage{
complexbrowser_extdata_path(..., must_work = TRUE)

complexbrowser_load_corum()

complexbrowser_load_complex_portal()
}
\arguments{
\item{...}{Path components below the package \code{inst/extdata} directory.
For example, \code{"Corum_prepared_20221125.Rds"} or
\code{c("examples", "myo.csv")}.}

\item{must_work}{Logical. If \code{TRUE}, throw an error when the resolved
file does not exist. If \code{FALSE}, return the best package-relative path
candidate even when the file is absent.}
}
\value{
\code{complexbrowser_extdata_path()} returns a character scalar path.
\code{complexbrowser_load_corum()} and
\code{complexbrowser_load_complex_portal()} return prepared database data
frames with columns such as \code{ComplexID}, \code{Complex_Name},
\code{Organism}, \code{NUS}, \code{Subunits}, and \code{GO_terms}.
}
\description{
Helpers for resolving and loading data files distributed with the
\code{complexbrowser} package.
}
\details{
The package ships two prepared complex databases:
\itemize{
\item \code{complexbrowser_load_corum()} loads the bundled CORUM prepared
database. CORUM organism labels in the current bundle include
\code{"Human"}, \code{"Mouse"}, \code{"Rat"}, \code{"Bovine"}, \code{"Dog"},
\code{"Hamster"}, \code{"Mammalia"}, \code{"MINK"}, \code{"Pig"}, and
\code{"Rabbit"}.
\item \code{complexbrowser_load_complex_portal()} loads the bundled EBI Complex
Portal prepared database. EBI organism labels use scientific names such as
\code{"Homo sapiens"}, \code{"Mus musculus"}, \code{"Rattus norvegicus"},
\code{"Bos taurus"}, \code{"Drosophila melanogaster"}, and
\code{"Saccharomyces cerevisiae S288C"}.
}

Use \code{sort(unique(database$Organism))} on the loaded database to inspect
the authoritative list for the installed package version.
}
\examples{
corum <- complexbrowser_load_corum()
dim(corum)
sort(unique(corum$Organism))

ebi <- complexbrowser_load_complex_portal()
head(sort(unique(ebi$Organism)))

complexbrowser_extdata_path("examples", "myo.csv")
}
\seealso{
\code{\link{complexbrowser_select_database}},
\code{\link{complexbrowser_run_complex_analysis}}
}
