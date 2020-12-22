library(shiny)
library(DT)
library(preprocessCore)
library(colourpicker)
library(shinydashboard)
library(shinyBS)
library(plotly)
library(networkD3)
library(heatmaply)
library(GGally)
library(rmarkdown)
library(dplyr)
library(jsonlite)
#For webshot2
#install.packages("remotes")
#library(remotes)
#remotes::install_github("rstudio/webshot2")
library(webshot2)
library(htmlwidgets)
library(shinyjs)
library(grid)
library(gridExtra)
library(lattice)
library(cowplot)
library(shinycssloaders)

source("Functions.R")

# Application's header with custom dropdown menu.(Done)
header <- shinydashboard::dashboardHeader(title = "ComplexBrowser", titleWidth = 250,
                                          shiny::tags$li(class = "dropdown", shiny::tags$style(shiny::HTML(".text-info {color:#DD9977;}"))),
                                          shinydashboard::dropdownMenuOutput("notification_dropdown_menu"))


# Interface sidebar, two panels, depending on the tabs clicked. (Done)
sidebar <- shinydashboard::dashboardSidebar(width = 250, 
                                            tags$head(tags$script('
    Shiny.addCustomMessageHandler("resetFileInputHandler", function(x) {      
        var id = "#" + x + "_progress";
        var idFile = "#" + x;
        var idBar = id + " .bar";
        $(id).css("visibility", "hidden");
        $(idBar).css("width", "0%");
        $(id).addClass("active");
        $(idFile).replaceWith(idFile = $(idFile).clone(true));
    });
 window.addEventListener("message", displayMessage, false);
 function displayMessage(evt) { 
 console.log(evt.data)
 var inmessage = JSON.parse(evt.data);
 console.log(inmessage); 
 console.log("read message");
 Shiny.setInputValue("extdata", evt.data);
}
  ')),
                                            shinydashboard::sidebarMenu(id = "sidebar_menu",
                                              shiny::tags$head(shiny::tags$style(shiny::HTML(".skin-black .sidebar-menu>li>a {color: #DD9977!important;};"))),
                                              shiny::tags$head(shiny::tags$style(shiny::HTML(".sidebar-menu .text-success {color:#DD9977;}"))),
                                              shinydashboard::dropdownMenuOutput("notification_sidebar"),
                                              shinydashboard::menuItem(text = "Data input and QC", tabName = "input", icon = shiny::icon("table")),
                                              shinydashboard::menuItem(text = "Complex analysis", tabName = "analysis", icon = shiny::icon("line-chart")),
                                              shiny::conditionalPanel(condition = "input.sidebar_menu === 'input'",
                                                                      shiny::tags$div(style = "text-align:center;", shiny::tags$h5(id = "input_text", shiny::tags$b("Select input file "))),
                                                                      shinyBS::bsTooltip(id = "input_text", title = "Input file in .csv or .txt format. First column must contain unique protein identifiers and the sebsequent columns the quantitative data. Optionally, a statisticall score column can be added at the end."),
                                                                      shiny::fileInput(inputId = "in_file", label = NULL, accept = c("text/csv","text/comma-separated-values,text/plain",".csv") ),
                                                                      textOutput("fileInText"),
                                                                      shiny::actionButton(inputId = "load_example", label = "Load example", width = "220px", icon = shiny::icon("upload")),
                                                                      shinyBS::bsTooltip(id = "load_example", title= "Taken from <i>Integrative Proteomics and Phosphoproteomics Profiling Reveals Dynamic Signaling Networks and Bioenergetics Pathways Underlying T Cell Activation</i> Immunity, 2017 "),
                                                                      shiny::actionButton(inputId = "run_QC", label = "Run QC", width = "220px", icon = shiny::icon("bar-chart")),
                                                                      shiny::uiOutput(outputId = "download_input_stats_merged"),
                                                                      shiny::uiOutput(outputId = "QC_report_button"),
                                                                      shiny::radioButtons(inputId = "separator", label = "Separator:", choices = c(";", ",", ":", "tab"), selected = ",", inline = TRUE),
                                                                      shinyBS::bsTooltip(id = "separator", title = "The separator character used in the input file."),
                                                                      shiny::radioButtons(inputId = "decimal", label = "Decimal mark", choices = c(".", ","), inline = TRUE),
                                                                      shinyBS::bsTooltip(id = "decimal", title = "Character used to separate integer from the fractional part of the values."),
                                                                      shiny::sliderInput(inputId = "no_conditions", label = "Select number of conditions", min = 2, max = 20, step = 1, value = 2),
                                                                      shinyBS::bsTooltip(id = "no_conditions", title = "Number of different experimental conditions in your experiment."),
                                                                      shiny::sliderInput(inputId = "no_replicates", label = "Select number of replicates", min = 2, max = 20, step = 1, value = 2),
                                                                      shinyBS::bsTooltip(id = "no_replicates", title = "Number of replicates in every condition."),
                                                                      shiny::checkboxInput(inputId = "log2", label = "Is data log2 transformed?", value = FALSE),
                                                                      shiny::checkboxInput(inputId = "grouped", label = "Replicates are grouped", value = TRUE),
                                                                      shinyBS::bsTooltip(id = "grouped", title = "Are biological replicates in adjacent columns? (C1.1, C1.2, C1.3...)"),
                                                                      shiny::checkboxInput(inputId = "statistics", label = "Are q-values included?", value = TRUE),
                                                                      shinyBS::bsTooltip(id = "statistics", title = "If no p/q values are provided, the LIMMA test will be performed."),
                                                                      shiny::uiOutput(outputId = "design")),
                                              shiny::conditionalPanel(condition = "input.sidebar_menu === 'analysis'",
                                                                      shiny::checkboxInput(inputId = "q_values_th", label = "Statistical threshold for visualisation", value = TRUE),
                                                                      shinyBS::bsTooltip(id = "q_values_th", title = "Use a statistical test value threshold in the analysis?"),
                                                                      shiny::uiOutput(outputId = "significance_level"),
                                                                      shiny::numericInput(inputId = "FC_th", label = "Fold change threshold", min = 1, max = 3, step = 0.05, value = 1.2),
                                                                      shinyBS::bsTooltip(id = "FC_th", title = "Select threshold for considering fold changes as up(> X) / down (-< X) regulation."),
                                                                      shiny::numericInput(inputId = "noise_th", label = "Noise threshold for summary", min = 0.01, max = 1, step = 0.05, value = 0.5),
                                                                      shinyBS::bsTooltip(id = "noise_th", title = "Select noise level threshold, that will be considered when creating a top5 summary report."),
                                                                      shinyBS::bsTooltip(id = "significance_level", title = "What should be the statistical threshold for considering a protein to be differentially regulated?"),
                                                                      shiny::selectInput(inputId = "database", label = "Select database for analysis", choices = c("CORUM", "EBI Complex Portal","User defined database")),
                                                                      shinyBS::bsTooltip(id = "database", title = "Which protein complex database should be used in the analysis?", placement = "top"),
                                                                      selectizeTooltip(id = "database", choice = "CORUM", title = "CORUM version: 02.07.2017", placement = "right"),
                                                                      selectizeTooltip(id = "database", choice = "EBI Complex Portal", title = "Complex Portal version: 03.21.2018", placement = "right"),
                                                                      selectizeTooltip(id = "database", choice = "User defined database", title = "Input custom database according to the provided example (UserDB_EXAMPLE.csv)", placement = "right"),
                                                                      shiny::uiOutput(outputId = "user_database"),
                                                                      shinyBS::bsTooltip(id = "user_database", title = "User defined database table in .RDS format must contain 6 columns. ComplexID, ComplexName, Organism, Subnits (; separated, no spaces),GO_terms, Comment."),
                                                                      shiny::uiOutput(outputId = "species"),
                                                                      shiny::actionButton(inputId = "run_analysis", label = "Run analysis", icon = shiny::icon("cogs")),
                                                                      shiny::uiOutput("download_complex_table"))
                                                                      )
                                            )

body <- dashboardBody(
  tags$script(src = "CallShiny.js"),

  includeCSS("styling/ComplexBrowser.css"),
  shinyjs::useShinyjs(),
  tabItems(
    ##### TAB 1 - Data quality control #####
    tabItem(
      tabName = "input",
      h2("Input data quality control", style = "text-align: center;"),
      DT::dataTableOutput("input_file"),
      br(),
      tags$head(tags$style(HTML("div.box-header {text-align: center;}"))),
      fluidRow(
        box(title = "Log-transformed values distribution",
            div(style="display: inline-block;vertical-align:top; width: 250px;",
                selectInput(inputId = "norm_technique", label = "Choose normalization technique", selected = "Median", choices = c("Total Intensity","Mean", "Median", "Quantile"))),
            div(style="display: inline-block;vertical-align:top; width: 200px; margin: 0px 0px 0px 0px;",
                actionButton(inputId = "norm_run", label = "Run normalization", icon = icon("bar-chart"))),
            shinycssloaders::withSpinner(plotlyOutput(outputId = "input_boxplot", height = 500), type = 1, size = 1),
            uiOutput("input_boxplot_download_cui")
        ),
        box(title = "Missing values distribution",
            tags$hr(style = "height:33px; visibility:hidden;"),
            shinycssloaders::withSpinner(plotlyOutput(outputId = "NA_barplot", height = 500), type = 1, size = 1),
            uiOutput("NA_barplot_download_cui")
        )
      ),
      br(),
      fluidRow(
        tabBox(
          tabPanel(
            title = "Coefficient of variation distribution",
            div(style="display: inline-block;vertical-align:top; width: 300px;",
                uiOutput("CV_reference")),
            div(style="display: inline-block;vertical-align:top; width: 50px;", tags$hr(style = "height:1px; visibility:hidden;")),
            div(style="display: inline-block;vertical-align:top; width: 250px; margin: 10px 0px 0px 0px;",
                colourpicker::colourInput(inputId = "CV_colour", label = "CV plot colour", value = "#428bca")),
            br(),
            htmlOutput("CV_mean_median"),
            br(),
            shinycssloaders::withSpinner(plotlyOutput("CV_distr", height = 500), type = 1, size = 1), 
            uiOutput("CV_distr_download_cui")),
          tabPanel(
            title = "Number of significant features",
            div(style="display: inline-block;vertical-align:top; width: 300px;",
                uiOutput("qV_reference")),
            div(style="display: inline-block;vertical-align:top; width: 50px;", tags$hr(style = "height:1px; visibility:hidden;")),
            div(style="display: inline-block;vertical-align:top; width: 250px; margin: 10px 0px 0px 0px;",
                colourpicker::colourInput(inputId = "qV_colour", label = "q value plot colour", value = "#428bca")),
            br(),
            tags$hr(style = "height:24px; margin-top: 0; margin-bottom: 0; visibility:hidden;"),
            br(),
            shinycssloaders::withSpinner(plotlyOutput("qV_distr", height = 500), type = 1, size = 1),
            uiOutput("qV_distr_download_cui")),
          tabPanel(
            title = "Volcano plot",
            div(style="display: inline-block;vertical-align:top; width: 300px;",
                sliderInput("volcano_th", "FDR threshold", min = 0.001, max = 0.1, step = 0.01, value = 0.05)),
            div(style="display: inline-block;vertical-align:top; width: 50px;", tags$hr(style = "height:1px; visibility:hidden;")),
            div(style="display: inline-block;vertical-align:top; width: 300px;",
                uiOutput(outputId = "volcano_cond")),
            br(),
            tags$hr(style = "height:24px; margin-top: 0; margin-bottom: 0; visibility:hidden;"),
            br(),
            shinycssloaders::withSpinner(plotlyOutput(outputId = "volcano", height = 500), type = 1, size = 1),
            uiOutput("volcano_download_cui")),
          tabPanel(
            title = "PCA",
            tags$hr(style = "height:45px; margin-top: 0; margin-bottom: 0; visibility:hidden;"),
            br(),
            tags$hr(style = "height:24px; margin-top: 0; margin-bottom: 0; visibility:hidden;"),
            br(),
            shinycssloaders::withSpinner(plotlyOutput("pca", height = 500), type = 1, size = 1),
            uiOutput("pca_download_cui"))
        ),
        box(
          title = "Sample to sample correlation",
          div(style="display: inline-block;vertical-align:top; width: 200px; margin: 10px 0px 0px 0px;",
              selectInput(inputId = "correlation_scatter", label = "Choose correlation measure", choices = c("pearson", "kendall", "spearman"), width = "300px")),
          div(style="display: inline-block;vertical-align:top; width: 50px;", tags$hr(style = "height:1px; visibility:hidden;")),
          div(style="display: inline-block;vertical-align:top; width: 230px;",
              uiOutput(outputId = "scatter_c1")),
          div(style="display: inline-block;vertical-align:top; width: 50px;", tags$hr(style = "height:1px; visibility:hidden;")),
          div(style="display: inline-block;vertical-align:top; width: 230px;",
              uiOutput(outputId = "scatter_c2")),
          br(),
          tags$hr(style = "height:24px; margin-top: 0; margin-bottom: 0; visibility:hidden;"),
          br(),
          shinycssloaders::withSpinner(plotlyOutput(outputId = "scatter", height = 500), type = 1, size = 1),
          uiOutput("scatter_download_cui")))),
    ##### Tab 2 - protein complexes ######                     
    tabItem(tabName = "analysis",
            h2("Protein complex analysis", style = "text-align: center;"),
            DT::dataTableOutput("user_complexes"),
            br(),
            fluidRow(
              box(
                title = "Protein complex visualization",
                div(style="width: 300px;",
                    uiOutput("graph_condition")),
                br(),
                shinycssloaders::withSpinner(forceNetworkOutput("complex_graph"), type = 1, size = 1),
                uiOutput("complex_graph_download_cui"),
                actionButton("CoExpresso", "Submit proteins to CoExpresso"),
                bsTooltip(id = "CoExpresso",
                          title = "Check for co-regulation in human cells for all here quantified proteins of the complex. This works only for human complexes! CoExpresso is based on data from ProteomicsDB. (experimental feature)"),

                actionButton("CoExpressoFull", "Submit all complex proteins to CoExpresso"),
                bsTooltip(id = "CoExpressoFull",
                          title = "Check for co-regulation in human cells for all proteins of the complex. This works only for human complexes! CoExpresso is based on data from ProteomicsDB. (experimental feature)")
              ),
              tabBox(
                tabPanel(
                  title = "Subunits expression profiles",
                  div(style="width: 300px;",
                      selectInput(inputId = "multiline_scale", label = "Select value to plot on Y axis", choices = c("zScore", "Log2 Intensity"), selected = "Log2 Intensity")),
                  tags$hr(style = "height:10px; margin-top: 0; margin-bottom: 0; visibility:hidden;"),
                  br(),
                  shinycssloaders::withSpinner(plotlyOutput("multiline_plot", height = "500px"), type = 1, size = 1),
                  br(),
                  uiOutput("multiline_plot_download_cui")
                ),
                tabPanel(
                  title = "Protein expression barplot",
                  uiOutput("multiple"),
                  bsTooltip(id = "multiple", 
                            title = "The protein you selected can be found in multiple complexes, 
                            use the accession in the search in the table above to see them", 
                            placement = "top"),
                  uiOutput("uniprot"),
                  br(),
                  shinycssloaders::withSpinner(plotlyOutput("expression_barplot", height = "410px"), type = 1, size = 1),
                  uiOutput("expression_barplot_download_cui"),
                  DT::dataTableOutput("fc_table"),
                  DT::dataTableOutput("qValue_table")),
                tabPanel(
                  title = "Co-expression LM",
                  div(style="display: inline-block;vertical-align:top; width: 300px;",
                      uiOutput(outputId = "Corr_C1")),
                  div(style="display: inline-block;vertical-align:top; width: 50px;", tags$hr(style = "height:1px; visibility:hidden;")),
                  div(style="display: inline-block;vertical-align:top; width: 300px;",
                      uiOutput(outputId = "Corr_C2")),
                  br(),
                  br(),
                  shinycssloaders::withSpinner(plotlyOutput(outputId = "Complex_correlation", height = 500), type = 1, size = 1),
                  uiOutput("Complex_correlation_download_cui")),
                tabPanel(title = "Complex information",
                         DT::dataTableOutput("complex_information", height = 500)
                )
              )),
            fluidRow(
              tabBox(
                tabPanel( #(Done)
                  title = "Protein expression heatmap",
                  shiny::tags$head(shiny::tags$style(shiny::HTML("#complex_name {text-align: center;} div.box-header {text-align: center;}"))),
                  shiny::textOutput(outputId = "complex_name"),
                  shiny::tags$div(style = "display: inline-block;vertical-align:top; width: 150px; margin: 10px 0px 0px 0px;",
                                  shiny::selectInput(inputId = "d_measure", label = "Distance measure", choices = c("manhattan", "euclidean", "minkowski", "maximum"), selected = "euclidean")),
                  shiny::tags$div(style = "display: inline-block;vertical-align:top; width: 20px;", shiny::tags$hr(style = "height:1px; visibility:hidden;")),
                  shiny::tags$div(style = "display: inline-block;vertical-align:top; width: 150px; margin: 10px 0px 0px 0px;",
                                  shiny::selectInput(inputId = "agg_method", label = "Linkage method", choices = c("single", "complete", "average", "median", "centroid"), selected = "complete")),
                  shiny::tags$div(style = "display: inline-block;vertical-align:top; width: 20px;", shiny::tags$hr(style = "height:1px; visibility:hidden;")),
                  shiny::tags$div(style="display: inline-block;vertical-align:top; width: 150px; margin: 10px 0px 0px 0px;",
                                  shiny::uiOutput(outputId = "minkowski_p")),
                  shiny::tags$br(),
                  shinycssloaders::withSpinner(plotly::plotlyOutput(outputId = "expression_heatmap", height = 500), type = 1, size = 1),
                  shiny::uiOutput("expression_heatmap_download_cui")),
                tabPanel(
                  title = "Protein correlation heatmap",
                  textOutput("complex_name1"),
                  div(style="width: 200px; margin: 10px 0px 0px 0px;",
                      selectInput(inputId = "correlation_measure",
                                  label = "Correlation measure",
                                  choices = c("pearson", "spearman", "kendall"),
                                  selected = "pearson")),
                  shinycssloaders::withSpinner(plotlyOutput(outputId = "correlation_heatmap", height = 500), type = 1, size = 1),
                  uiOutput("correlation_heatmap_download_cui"))),
              tabBox(
                tabPanel(
                  title = "Summary",
                  div(style="display: inline-block;vertical-align:top; width: 1px;", tags$hr(style = "height:65px; visibility:hidden;")),
                  shinycssloaders::withSpinner(plotlyOutput("summary_barplot", height = 500), type = 1, size = 1),
                  uiOutput("summary_barplot_download_cui")
                ),
                tabPanel(
                  title = "Top 5 Up/Down",
                  uiOutput(outputId = "summary_cond"),
                  dataTableOutput(outputId = "changing_table"),
                  textOutput(outputId = "summary", 
                             inline = TRUE)
                ))))))

dashboardPage(header,sidebar,body, skin = "black")







