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
#Avoid the background colour errors
tags$script(HTML("$('body').addClass('sidebar-mini');"))
# Interface or the top part of the aplication, dropdown menu with buttons for references
header <- dashboardHeader(title = "ComplexBrowser", 
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
              menuItem(text = "Analysis", 
                       tabName = "analysis", 
                       icon = icon("line-chart")),
              conditionalPanel(condition = "input.sidebar_menu === 'input'",
                               fileInput(inputId = "in_file",
                                         label = "Select input file"),
                               actionButton(inputId = "load_example", 
                                            label = "Load example", 
                                            width = "220px", 
                                            icon = icon("upload")),
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
                                         title = "Select threshold for considering fold changes as up(>X) / down ( < -X) regulation"),
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
                                               choices = c("CORUM", "EBI Complex Portal"))),
                               bsTooltip(id = "database", 
                                         title = "Which protein complex database should be used in the analysis?", 
                                         placement = "top"),
                               div(style = "display: block;; margin:0 auto; text-align: center;",
                                   uiOutput(outputId = "species")),
                               actionButton(inputId = "run_analysis", 
                                            label = "Run analysis",
                                            icon = icon("cogs")),
                               uiOutput("download_complex_table")
                               
              )))


body <- dashboardBody(
  includeCSS("styling/ComplexBrowser.css"),
  tabItems(
    ##### TAB 1 - Data quality control #####
    tabItem(
      tabName = "input",
      h2("Input data quality control", style = "text-align: center;"),
      DT::dataTableOutput("input_file"),
      fixedRow(
        column(
          width = 6, offset = 0,
          h3("Log-transformed values distribution", style = "text-align: center;"),
          br(),
          fluidRow(
            column(
              width = 4, offset = 3,
              selectInput(inputId = "norm_technique", label = "Choose normalization technique",
                          selected = "Quantile", choices = c("Total Intensity","Mean", "Median", "Quantile"))),
            column(
              width = 1, offset = 0,
              actionButton(inputId = "norm_run", label = "Run normalization", icon = icon("bar-chart")))),
          br(),
          plotlyOutput(outputId = "input_boxplot", 
                       height = 500)),
        column(
          width = 6, offset = 0,
          h3("Missing values distribution", style = "text-align: center;"),
          br(),
          plotlyOutput(outputId = "NA_barplot",
                       height = 550),
          br())),
      br(),
      fluidRow(
        tabBox(
          tabPanel(
            title = "Coefficient of variation distribution",
            uiOutput("CV_reference"),
            colourInput(inputId = "CV_colour",
                        label = "CV plot colour",
                        value = "#428bca"),
            br(),
            htmlOutput("CV_mean_median"),
            br(),
            plotlyOutput("CV_distr")),
          tabPanel(
            title = "Number of significant features",
            uiOutput("qV_reference"),
            colourInput(inputId = "qV_colour",
                        label = "q value plot colour",
                        value = "#428bca"),
            br(),
            plotlyOutput("qV_distr", height = 500)),
          tabPanel(
            title = "Volcano plot",
            sliderInput("volcano_th",
                        "FDR threshold",
                        min = 0.001, max = 0.1, step = 0.01, value = 0.05),
            uiOutput(outputId = "volcano_cond"),
            br(),
            plotlyOutput(outputId = "volcano", height = 500)),
          tabPanel(
            title = "PCA",
            br(),
            br(),
            br(),
            plotlyOutput("pca", height = 500))),
        box(
          title = "Sample to sample correlation",
          selectInput(inputId = "correlation_scatter",
                      label = "Choose correlation measure",
                      choices = c("pearson", "kendall", "spearman"),
                      width = "300px"),
          uiOutput(outputId = "scatter_c1"),
          uiOutput(outputId = "scatter_c2"),
          br(),
          plotlyOutput(outputId = "scatter")))),
    ##### Tab 2 - protein complexes ######                     
    tabItem(tabName = "analysis",
            h2("Protein complex analysis", style = "text-align: center;"),
            DT::dataTableOutput("user_complexes"),
            br(),
            fluidRow(
              box(
                title = "Protein complex visualization",
                uiOutput("graph_condition"),
                forceNetworkOutput("complex_graph")
              ),
              tabBox(
                tabPanel(
                  title = "Subunits expression profiles",
                  selectInput(inputId = "multiline_scale", 
                              label = "Select value to plot on Y axis",
                              choices = c("zScore", "Log2 Intensity"), 
                              selected = "Log2 Intensity"),
                  plotlyOutput("multiline_plot", 
                               height = "500px")),
                tabPanel(
                  title = "Protein expression barplot",
                  uiOutput("multiple"),
                  bsTooltip(id = "multiple", 
                            title = "The protein you selected can be found in multiple complexes, 
                            use the accession in the search in the table above to see them", 
                            placement = "top"),
                  uiOutput("uniprot"),
                  br(),
                  plotlyOutput("expression_barplot", height = "410px"),
                  DT::dataTableOutput("fc_table"),
                  DT::dataTableOutput("qValue_table")),
                tabPanel(
                  title = "Co-expression LM",
                  uiOutput(outputId = "Corr_C1"),
                  uiOutput(outputId = "Corr_C2"),
                  plotlyOutput(outputId = "Complex_correlation")),
                tabPanel(title = "Complex information",
                         DT::dataTableOutput("complex_information", height = 500)))),
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
                    selectInput(inputId = "d_measure",
                                label = "Distance measure for clustering",
                                choices = c("manhattan", "euclidean", "minkowski", "maximum"),
                                selected = "euclidean"),
                    selectInput(inputId = "agg_method",
                                label = "Aggregation method for hierarchical clustering",
                                choices = c("single", "complete", "average", "median", "centroid"),
                                selected = "complete"),
                    uiOutput(outputId = "minkowski_p"),
                    plotlyOutput(outputId = "expression_heatmap")),
                  tabPanel(
                    title = "Protein correlation heatmap",
                    textOutput("complex_name1"),
                    selectInput(inputId = "correlation_measure",
                                label = "Correlation measure",
                                choices = c("pearson", "spearman", "kendall"),
                                selected = "pearson"),
                    plotlyOutput(outputId = "correlation_heatmap", 
                                 height = "150%"))),
                tabBox(
                  tabPanel(
                    title = "Summary",
                    plotlyOutput("summary_barplot", width = "100%", height = "150%")
                  ),
                  tabPanel(
                    title = "Top 5 Up/Down",
                    uiOutput(outputId = "summary_cond"),
                    dataTableOutput(outputId = "changing_table"),
                    textOutput(outputId = "summary", 
                               inline = TRUE)
                  ))))))

dashboardPage(header,sidebar,body, skin = "black")




