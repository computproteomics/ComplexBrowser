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
#Packages needed for plotly to PDF
#install.packages("webshot")
library(webshot)
#webshot::install_phantomjs()
#install.packages("htmlwidgets")
library(htmlwidgets)
library(shinyjs)

# Make sure rmarkdown version is 1.8
#remove.packages("rmarkdown")
#library(devtools)
#install_version("rmarkdown", version = "1.8")
#install.packages("glue")
library(grid)
library(gridExtra)
library(lattice)
#install.packages("cowplot")
library(cowplot)
#install.packages("shinycssloaders")
library(shinycssloaders)

#Avoid the background colour errors
tags$script(HTML("$('body').addClass('sidebar-mini');"))


# Interface or the top part of the aplication, dropdown menu with buttons for references
header <- dashboardHeader(title = "ComplexBrowser", titleWidth = 250,
                          dropdownMenu(
                            type = "notifications", 
                            icon = icon("question-circle"),
                            badgeStatus = NULL,
                            headerText = "Documentation and help",
                            notificationItem(text = "Source code and documenatation", 
                                             icon = icon("question"),
                                             href = "https://bitbucket.org/michalakw/complexbrowser/"),
                            notificationItem(text = "CORUM database", 
                                             icon = icon("database"),
                                             href = "http://mips.helmholtz-muenchen.de/corum/download/coreComplexes.txt.zip"),
                            notificationItem(text = "ComplexPortal database", 
                                             icon = icon("database"),
                                             href = "https://www.ebi.ac.uk/complexportal/download"),
                            notificationItem(text = "Report a Bug!", 
                                             icon = icon("bug"), 
                                             href = "mailto:wojciechm@bmb.sdu.dk"),
                            notificationItem(text = "Go to article page", 
                                             icon = icon("book"),
                                             href = "https://www.ncbi.nlm.nih.gov/pubmed/")))  
# Interface sidebar, two panels, depending on the tabs clicked.
sidebar <- dashboardSidebar(
  width = 250,
  sidebarMenu(id = "sidebar_menu",
              menuItem(text = "Data input and QC",
                       tabName = "input", 
                       icon = icon("table")),
              menuItem(text = "Complex analysis", 
                       tabName = "analysis", 
                       icon = icon("line-chart")),
              conditionalPanel(condition = "input.sidebar_menu === 'input'",
                               fileInput(inputId = "in_file",
                                         label = "Select input file"),
                               actionButton(inputId = "load_example", 
                                            label = "Load example", 
                                            width = "220px", 
                                            icon = icon("upload")),
                               bsTooltip(id= "load_example",
                                         title= "Taken from <i>Integrative Proteomics and Phosphoproteomics Profiling Reveals Dynamic Signaling Networks and Bioenergetics Pathways Underlying T Cell Activation</i> Immunity, 2017 "),
                               actionButton(inputId = "run_QC", 
                                            label = "Run QC", 
                                            width = "220px", 
                                            icon = icon("bar-chart")),
                               uiOutput(outputId = "download_input_stats_merged"),
                               uiOutput(outputId = "QC_report_button"),
                               radioButtons(inputId = "separator",
                                            label = "Separator:", 
                                            choices = c(";",",",":","tab"),
                                            selected = ",",
                                            inline = TRUE),
                               bsTooltip(id = "separator", 
                                         title = "Character in your file used to separate cells in one row"),
                               radioButtons(inputId = "decimal",
                                            label = "Decimal mark",
                                            choices = c(".",", "),
                                            inline = TRUE),
                               bsTooltip(id = "decimal", 
                                         title = "Character used to separate integer from the fractional part of the values"),
                               sliderInput(inputId = "no_conditions",
                                           label = "Select number of conditions", 
                                           min = 2, 
                                           max = 20, 
                                           step = 1, 
                                           value = 2),
                               bsTooltip(id = "no_conditions", 
                                         title = "Number of different experimental conditions in your experiment"),
                               sliderInput(inputId = "no_replicates",
                                           label = "Select number of replicates", 
                                           min = 2, 
                                           max = 20, 
                                           step = 1, 
                                           value = 2),
                               bsTooltip(id = "no_replicates", 
                                         title = "Number of replicates in every condition"),
                               #Here the inputs are not styled with CSS; for some reason when doing so the checkbox ends up on the label!
                               div(style = "display: block;; margin:0 auto; text-align: center;",
                                   checkboxInput(inputId = "log2",
                                                 label = "Is data log2 transformed?",
                                                 value = FALSE)),
                               div(style = "display: block;; margin:0 auto; text-align: center;",
                                   checkboxInput(inputId = "grouped",
                                                 label = "Replicates are grouped",
                                                 value = TRUE)),
                               bsTooltip(id = "grouped",
                                         title = "Are biological replicates in adjacent columns? (C1.1, C1.2, C1.3...)"),
                               div(style = "display: block;; margin:0 auto; text-align: center;",
                                   checkboxInput(inputId = "statistics",
                                                 label = "Are q-values included?",
                                                 value = TRUE)),
                               bsTooltip(id = "statistics",
                                         title = "If no p/q values are provided, the LIMMA test will be performed"),
                               uiOutput(outputId = "design")),
              
              
              
              conditionalPanel(condition = "input.sidebar_menu === 'analysis'",
                               checkboxInput(inputId = "q_values_th",
                                             label = "Statistical threshold for visualisation", 
                                             value = TRUE),
                               bsTooltip(id = "q_values_th", 
                                         title = "Use a statistical test value threshold in the analysis?"),
                               div(style = "display: block;; margin:0 auto; text-align: center;",
                                   uiOutput(outputId = "significance_level")),
                               numericInput(inputId = "FC_th", label = "Fold change threshold",
                                            min = 1, max = 3, step = 0.05, value = 1.2),
                               bsTooltip(id = "FC_th", 
                                         title = "Select threshold for considering fold changes as up(>X) / down ( -< X) regulation"),
                               numericInput(inputId = "noise_th",
                                            label = "Noise threshold for summary",
                                            min=0.01, max = 1, step = 0.05, value = 0.5),
                               bsTooltip(id = "noise_th",
                                         title = "Select noise level threshold, that will be considered when creating a summary"),
                               bsTooltip(id = "significance_level", 
                                         title = "What should be the statistical threshold for considering a protein to be differentially regulated?"),
                               div(style = "display: block;; margin:0 auto; text-align: center;",
                                   selectInput(inputId = "database", 
                                               label = "Select database for analysis", 
                                               choices = c("CORUM", "EBI Complex Portal","User defined database"))),
                               bsTooltip(id = "database", 
                                         title = "Which protein complex database should be used in the analysis?<br/>CORUM version: 02.07.2017<br/>Complex Portal version: 03.21.2018", 
                                         placement = "top"),
                               div(style = "display: block;; margin:0 auto; text-align: center;",
                                   uiOutput(outputId = "user_database")),
                               bsTooltip(id = "user_database", 
                                         title = "User defined database table in .RDS format must contain 6 columns. ComplexID, ComplexName, Organism, Subnits (; separated, no spaces),GO_terms, Comment"),
                               
                               div(style = "display: block;; margin:0 auto; text-align: center;",
                                   uiOutput(outputId = "species")),
                               actionButton(inputId = "run_analysis", 
                                            label = "Run analysis",
                                            icon = icon("cogs")),
                               uiOutput("download_complex_table")
                               
              )))


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
                selectInput(inputId = "norm_technique", label = "Choose normalization technique", selected = "Quantile", choices = c("Total Intensity","Mean", "Median", "Quantile"))),
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
                tabPanel(
                  title = "Protein expression heatmap",
                  tags$head(tags$style(HTML("
                                            #complex_name {
                                            text-align: center;
                                            }
                                            div.box-header {
                                            text-align: center;
                                            }
                                            "))),
                  textOutput(outputId = "complex_name"),
                  div(style="display: inline-block;vertical-align:top; width: 200px; margin: 10px 0px 0px 0px;",
                      selectInput(inputId = "d_measure",
                                  label = "Distance measure for clustering",
                                  choices = c("manhattan", "euclidean", "minkowski", "maximum"),
                                  selected = "euclidean")),
                  div(style="display: inline-block;vertical-align:top; width: 50px;", tags$hr(style = "height:1px; visibility:hidden;")),
                  div(style="display: inline-block;vertical-align:top; width: 300px; margin: 10px 0px 0px 0px;",
                      selectInput(inputId = "agg_method",
                                  label = "Aggregation method for hierarchical clustering",
                                  choices = c("single", "complete", "average", "median", "centroid"),
                                  selected = "complete")),
                  div(style="display: inline-block;vertical-align:top; width: 50px;", tags$hr(style = "height:1px; visibility:hidden;")),
                  div(style="display: inline-block;vertical-align:top; width: 200px; margin: 10px 0px 0px 0px;",
                      uiOutput(outputId = "minkowski_p")),
                  br(),
                  shinycssloaders::withSpinner(plotlyOutput(outputId = "expression_heatmap", height = 500), type = 1, size = 1),
                  uiOutput("expression_heatmap_download_cui")),
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
