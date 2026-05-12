\name{complexbrowser_run_app}
\alias{complexbrowser_run_app}
\title{Run the ComplexBrowser Shiny app}
\usage{
complexbrowser_run_app(...)
}
\arguments{
\item{...}{Arguments passed to \code{shiny::runApp()}, such as
\code{port}, \code{host}, \code{launch.browser}, or \code{quiet}.}
}
\value{
The return value from \code{shiny::runApp()}. This function is usually called
for its side effect of starting the interactive Shiny application.
}
\description{
Runs the Shiny application bundled in the installed package under
\code{inst/shiny}.
}
\details{
This is the package-friendly launcher for the interactive app. It resolves the
installed app directory with
\code{system.file("shiny", package = "complexbrowser")} and passes that path to
\code{shiny::runApp()}.

From a source checkout, developers can also run the app directly with
\code{shiny::runApp("inst/shiny")}. After package installation, prefer
\code{complexbrowser_run_app()}.
}
\examples{
\dontrun{
complexbrowser_run_app()
complexbrowser_run_app(port = 3838, host = "0.0.0.0")

shiny::runApp(system.file("shiny", package = "complexbrowser"))
}
}
\seealso{
\code{\link[shiny:runApp]{shiny::runApp}},
\code{\link{complexbrowser_run_qc}},
\code{\link{complexbrowser_run_complex_analysis}}
}
