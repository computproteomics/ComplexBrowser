source("Functions.R")
#Developed by Wojciech Michalak as MSc thesis project
#"Bioinformatics in Proteomics: A web based platform for supervised analysis focused on protein complexes"
# June 2018

options(shiny.maxRequestSize=2000*1024^2)

function(input,output,session){
  
  ####################################### ANNOTATIONS ############################################
  
  #Custom notification dropdown menu function. (Done)
  output$notification_dropdown_menu <- shinydashboard::renderMenu({
    
    notification_SC <- shinydashboard::notificationItem(text = "Source code and installation", icon = shiny::icon("file-code-o"), status = "info", href = paste0("noti"))
    notification_SC$children[[1]] <- shiny::tags$a(href = "https://bitbucket.org/michalakw/complexbrowser/", target = "_blank", list(notification_SC$children[[1]]$children))
    
    notification_Tut <- shinydashboard::notificationItem(text = "Tutorial", icon = shiny::icon("question"), status = "info", href = paste0("tut"))
    notification_Tut$children[[1]] <- shiny::tags$a(href = "Manual.pdf", target = "_blank", list(notification_Tut$children[[1]]$children))
    
    notification_Corum <- shinydashboard::notificationItem(text = "CORUM database", icon = shiny::icon("database"), status = "info", href = paste0("corum"))
    notification_Corum$children[[1]] <- shiny::tags$a(href = "http://mips.helmholtz-muenchen.de/corum/download/coreComplexes.txt.zip", target = "_blank", list(notification_Corum$children[[1]]$children))
    
    notification_Portal <- shinydashboard::notificationItem(text = "ComplexPortal database", icon = shiny::icon("database"), status = "info", href = paste0("portal"))
    notification_Portal$children[[1]] <- shiny::tags$a(href = "https://www.ebi.ac.uk/complexportal/download", target = "_blank", list(notification_Portal$children[[1]]$children))
    
    notification_Contact <- shinydashboard::notificationItem(text = "Report a Bug!", icon = shiny::icon("bug"), status = "info", href = paste0("bug"))
    notification_Contact$children[[1]] <- shiny::tags$a(href = "mailto:veits@bmb.sdu.dk", target = "_blank", list(notification_Contact$children[[1]]$children))
    
    notification_menu <- shinydashboard::dropdownMenu(notification_SC,
                                                      notification_Tut,
                                                      notification_Corum,
                                                      notification_Portal,
                                                      notification_Contact,
                                                      type = "notifications",
                                                      badgeStatus = NULL,
                                                      icon = icon("question-circle"),
                                                      headerText = "Info:")
    
    return(notification_menu)
    
  })
  
  #Custom notification for sidebar menu. (Done)
  output$notification_sidebar <- shinydashboard::renderMenu({
    
    notification_Citation <- shinydashboard::notificationItem(text = "Publication (please cite)", icon = shiny::icon("book-open"), href = paste0("cite"))
    notification_Citation$children[[1]] <- shiny::tags$a(href = "https://www.mcponline.org/content/early/2019/08/25/mcp.TIR119.001434", target = "_blank", list(notification_Citation$children[[1]]$children))
    
    return(notification_Citation)
    
  })
  
  ############################### INITIALIZE INPUT OBJECTS #######################################
  
  #Initiate empty reactiveValues object to store all data and results.
  data <- shiny::reactiveValues()
  user_input <- NULL
  data$file_indicator <- FALSE
  normalization_type <- shiny::reactiveValues(type = NA)
  
  ####################################### UI FUNCTIONS ###########################################
  
  ################ TAB 1 - Input ################
  #1.1 Conditional UI for LIMMA testing when statistical score is not included. (Sidebar) (Done)
  output$design <- shiny::renderUI({
    
    shiny::req(input$statistics == FALSE)
    shiny::radioButtons(inputId = "design", label = "Choose design for limma", choices = c("unpaired", "paired"), select = "unpaired", inline = TRUE)
    
  })
  
  #1.2 Download button - conditional UI that appears after statistics is calculated, to download table 1. (Sidebar) (Done)
  output$download_input_stats_merged <- shiny::renderUI({
    
    shiny::req(data$input_stats_merged)
    shiny::downloadButton(outputId = "input_stats_download", label = "Download table")
    
  })
  
  #1.3 Download button - conditional UI to create and download the QC report. (Sidebar) (Done)
  output$QC_report_button <- shiny::renderUI({
    
    shiny::req(data$stats)
    shiny::downloadButton(outputId = "QC_report", label = "Download QC Report")
    
  })
  
  
  #1.4 QValue distribution
  output$qV_reference <- renderUI(
    sliderInput(inputId = "qV_reference",
                label = "Condition number",
                value = 2,
                min = 2,
                max = data$no_cond,
                step = 1))
  
  #5. CV distribution
  output$CV_reference <- renderUI(
    sliderInput(inputId = "CV_reference",
                label = "Condition number",
                value = 1,
                min = 1,
                max = data$no_cond,
                step = 1))
  
  #6. Volcano plot
  output$volcano_cond <- renderUI(
    sliderInput(inputId = "volcano_cond",
                label = "Condition",
                value = 2,
                min = 2,
                max = data$no_cond,
                step = 1))
  
  ################ TAB 2 - Analysis ################
  #2.1. Conditional UI for species selection, depending on the selected database. (Sidebar) (Done)
  output$species <- shiny::renderUI({
    
    shiny::req(input$database)
    
    if(input$database == "CORUM"){
      
      shiny::selectInput(inputId = "species", label = "Species", choices = unique(corum_prepared$Organism), selected = "Human")
      
    } else if(input$database == "EBI Complex Portal"){ 
      
      shiny::selectInput(inputId = "species", label = "Species", choices = unique(complex_portal_prepared$Organism), selected = "Homo sapiens")
      
    }
    
  })
  
  #2.2 Conditional UI that appears when user defined database is selected. (Sidebar) (Done)
  output$user_database <- renderUI({
    
    shiny::req(input$database == "User defined database")
    shiny::fileInput(inputId = "user_database", label = "Select user defined database")
    
  })
  
  #2.3 Conditional UI that appears only when user applies statistical score threshold to the analysis. (Sidebar) (Done)
  output$significance_level <- shiny::renderUI({
    
    shiny::req(input$q_values_th)
    shiny::numericInput(inputId = "significance_level", label = "Enter q-value threshold", value = 0.05, step = 0.01, max = 1, min = 0)
    
  })
  
  #2.4. Conditional UI for complex table download. (Sidebar) (Done)
  output$download_complex_table <- shiny::renderUI({
    
    shiny::req(data$for_display)
    shiny::downloadButton(outputId = "complex_table_DH", label = "Download complex table", style = "width: 220px")
    
  })
  
  #5. Input helpers 
  
  #appears only if the graph is displayed
  output$graph_condition <- renderUI(
    sliderInput(inputId = "star_condition", label = "Select condition for visualization", value = 2, 
                min = 2, max = data$no_cond, step = 1)
  )
  #scatter_c1 - sample to sample correlation C1
  output$scatter_c1 <- renderUI(
    sliderInput(inputId = "scatter_c1",
                label = "Sample number for X axis",
                value = 1,
                min = 1,
                max = data$no_cond*data$no_rep,
                step = 1))
  #scatter_c2 - sample to sample correlation C2
  output$scatter_c2 <- renderUI(
    sliderInput(inputId = "scatter_c2",
                label = "Sample number for Y axis",
                value = 2,
                min = 1,
                max = data$no_cond*data$no_rep,
                step = 1))
  #scatter_c2 - coexpression graph LM - C1
  output$Corr_C1 <- renderUI(
    sliderInput(inputId = "Corr_C1",
                label = "Condition for X axis",
                value = 1,
                min = 1,
                max = data$no_cond,
                step = 1))
  #scatter_c2 - coexpression graph LM - C2
  output$Corr_C2 <- renderUI(
    sliderInput(inputId = "Corr_C2",
                label = "Condition for Y axis",
                value = 2,
                min = 1,
                max = data$no_cond,
                step = 1))
  #6. Check how many complexes is a protein in 
  output$multiple <- renderUI({
    s <- sum(unlist(data$f_database$Subunits) == input$node_clicked)
    req(s > 1)
    actionButton(inputId = "multiple", 
                 label = paste0("Notice! This protein was found in ", s, " complexes"),
                 icon = icon("exclamation"),
                 style = "background-color: #ffd9b3")
  })
  #7. Create a "GO TO" button, sending the user to the uniprot website of protein ID selected (node)
  output$uniprot <- renderUI({
    req(input$node_clicked)
    actionButton(inputId = "uniprot", 
                 label = "Read more at Uniprot.org",
                 icon = icon("book"),
                 onclick = (paste0("window.open('https://www.uniprot.org/uniprot/",as.character(input$node_clicked),"')")))
  })
  
  #8. Minkowski distance p - appears if minkowski distance is selected. (Body) (Done)
  output$minkowski_p <- shiny::renderUI({
    
    shiny::req(input$d_measure == "minkowski")
    shiny::selectInput(inputId = "minkowski_p", label = "Minkowski p", choices = round(2^c(-2,-1.5, -1, 0.5, 0.5, 2, 3, 4, 5, 6), digits = 2), selected = 4)
    
  })
  
  #9. Reference condition for the text summary
  output$summary_cond <- renderUI({
    req(data$x)
    sliderInput("complex_summary_reference",
                label = "Condition for the summary information",
                min = 2, 
                max = data$no_cond,
                step = 1)
  })
  #10. Reference for the summary
  output$summary_cond <- renderUI({
    req(data$no_cond)
    sliderInput(inputId = "summary_cond",
                label = "Summary condition",
                min = 2, max = data$no_cond, step = 1, value = 2)
  })
  
  
  ################################################ 3 Download handlers ################################################
  
  #3.1 Download input file with calculated statistics (table 1) (Sidebar) (Done)
  output$input_stats_download <- shiny::downloadHandler(
    
    filename = function(){
      
      paste("MSComplexR_Input_WithStats", Sys.time(), ".csv", sep = "")
      
    },
    content = function(file){
      
      write.csv(data$input_stats_merged, file, row.names = FALSE)
      
    },
    contentType = "text/csv"
  )
  
  #3.2 Download protein complex table (table 2) (Sidebar) (Done)
  output$complex_table_DH <- shiny::downloadHandler(
    
    filename = function(){
      
      paste("Protein_complex_resutls", Sys.time(), ".csv", sep = "")
      
    },
    content = function(file) {
      
      write.csv(data$for_display, file, row.names = FALSE)
      
    },
    contentType = "text/csv"
  )
  
  #3. Generate QC data (generateQCreport()), create QC report (QCreport.rmd template) and download QC report. (Done)
  output$QC_report <- shiny::downloadHandler(
    
    filename = function() {
      
      file <- "QCreport.pdf"
      return(file)
      
    },
    content = function(file) {
      
      data$QC_report <- generateQCreport(data$stats, no_cond = data$no_cond, no_rep = data$no_rep)
      tempReport <- file.path(tempdir(), "QCreport.rmd")
      file.copy("QCreport.rmd", tempReport, overwrite = TRUE)
      params <- list(stats = data$stats, 
                     no_cond = data$no_cond, 
                     no_rep = data$no_rep, 
                     QC_report = data$QC_report, 
                     log = input$log2, 
                     normalization = normalization_type$type,
                     file = input$in_file)
      
      shiny::withProgress(message = "Quality Control Report: ", min = 0, max = 12, value = 0,{
        
        output <- rmarkdown::render(input = tempReport, 
                                    params = params,
                                    envir = new.env(parent = globalenv()))
        
        file.copy(output, file)
        
        shiny::incProgress(1, detail = "DONE!")
        
      })
    }
  )
  
  
  
  ################ ################ ################ DATA LOADING AND WRANGLING ################ ################ ################
  
  #1. Read in file
  output$input_file <- renderDataTable({
    expr = {
      shiny::withProgress(message = "Input data:", min = 0, max = 2, detail = "Loading data.",value = 1, {
        
        data$input <- input$in_file
        if(is.null(data$input)){
          return(NULL)
        }
        user_input <<- read.table(file = data$input$datapath,
                                  header = TRUE, 
                                  stringsAsFactors = FALSE, 
                                  sep = ifelse(input$separator=="tab", yes = "\t", no = input$separator),
                                  dec = input$decimal, 
                                  na.strings = c("NA","NaN"))
        if(ncol(user_input)== 1){
          return(DT::datatable(data.frame(Error = "Incorrect input format! - Check separator!")))
        }
        
        #Make sure there are no duplicated protein IDs
        else if(sum(duplicated(user_input[,1]))!= 0){
          DT::datatable(
            data.frame(Error = "Incorrect input format! - Check file for duplicate protein IDs!"))}
        
        shiny::incProgress(1, detail = "Data loaded.")
      })
    }})
  observeEvent(
    input$run_QC,
    {
      if (!is.null(user_input)) {
        shiny::withProgress(message = "Quality control:", min = 0, max = 4, detail = "Preparing data.",value = 1, {
          
          if(ncol(user_input)!= (1+(input$no_conditions*input$no_replicates)) & 
             ncol(user_input)!= (input$no_conditions*(input$no_replicates+1))){
            
            output$input_file <- renderDataTable({
              DT::datatable(data.frame(Error = "Incorrect number of columns! It should be equal to C*R+1 or C*(R+1)"))})
            
            shiny::incProgress(3, detail = "Error!")
            
          }
          else if(ncol(user_input) == (1+(input$no_conditions*input$no_replicates)) & input$statistics) {
            output$input_file <- renderDataTable({
              DT::datatable(data.frame(Error = "There are no additional columns q-values from statistical testing with this number of replicates and conditions"))})
            
            shiny::incProgress(3, detail = "Error!")
            
          }
          else{
            data$user_input <- renameAndSort(data = user_input, 
                                             no_cond = input$no_conditions,
                                             no_rep = input$no_replicates,
                                             qValues = input$statistics,
                                             grouped = input$grouped,
                                             log2 = input$log2)
            #By default do not put any normalisation step!
            data$file_indicator <- TRUE
            data$no_cond <- input$no_conditions
            data$no_rep <- input$no_replicates
            data$grouped <- input$grouped
            data$stats <- calculateStatistics(data = data$user_input, 
                                              no_cond = data$no_cond, 
                                              no_rep = data$no_rep,
                                              qValues = input$statistics,
                                              normalize = NULL,
                                              design = input$design)
            
            shiny::incProgress(1, detail = "Statistics calculated.")
            
            #To preserve the column names a separate cbind for matrices and data frames is needed
            data$input_stats_merged <-  isolate(cbind(data$stats[[1]], do.call(what = "cbind", data$stats[2:11])))
            data$no_proteins <- length(data$user_input[,1])
            output$input_file <- renderDataTable({ 
              DT::datatable(data = data$input_stats_merged,
                            options = list(scrollX = TRUE),
                            caption = htmltools::tags$caption(style = "text-align: left; caption-side: initial;",
                                                              'Table 1: ', htmltools::em('User data with calculated statistics 
                                                                                         and changes in protein expression ')))})
          }
          
          shiny::incProgress(1, detail = "Data rendered.")
          shiny::setProgress(message = "Quality control: Finished", value = 4)
          
        })
      }
    }
  )
  
  
  #2. Event handling - load example data set
  observeEvent(
    input$load_example,
    {
      shiny::withProgress(message = "Example data:", min = 0, max = 2, detail = "Loading example data.",value = 1, {
        
        data$file_indicator <- TRUE
        data$user_input <- read.csv("Table S2_Statistics_T-cell_cut.csv")
        data$no_cond <- 4
        data$no_rep <- 2
        data$grouped <- TRUE
        data$stats <- calculateStatistics(data = data$user_input, 
                                          no_cond = data$no_cond, 
                                          no_rep =  data$no_rep,
                                          qValues = FALSE,
                                          normalize = NULL,
                                          design = "unpaired")
        # change rulers
        updateSliderInput(session, "no_conditions",value=data$no_cond)
        updateSliderInput(session, "no_replicates",value=data$no_rep)
        updateCheckboxInput(session, "log2", value=F)
        updateCheckboxInput(session, "grouped", value=T)
        updateCheckboxInput(session, "statistics", value=F)
        updateRadioButtons(session, "design", select="unpaired")
        updateSelectInput(session, "species", select="Mouse")
        
        data$no_proteins <- length(data$user_input[,1])
        #To preserve the column names a separate cbind for matrices and data frames is needed
        data$input_stats_merged <-  cbind(data$stats[[1]], do.call(what = "cbind", data$stats[2:11]))
        output$input_file <- renderDataTable({
          DT::datatable( data$input_stats_merged,
                         options = list(scrollX = TRUE),
                         caption = htmltools::tags$caption(style = "text-align: left; caption-side: initial;",
                                                           'Table 1: ', htmltools::em('User data with calculated statistics and changes in protein expression ')))
          
        })
        
        shiny::incProgress(1, detail = "Data loaded.")
        
      })
    })
  
  #3. Event handling - normalize the data
  observeEvent(
    input$norm_run,
    {
      shiny::withProgress(message = "Normalization:", min = 0, max = 4, detail = "Preparing data.",value = 1, {
        
        normalization_type$type <- input$norm_technique
        
        data$stats <- isolate(calculateStatistics(data = data$user_input, 
                                                  no_cond = data$no_cond, 
                                                  no_rep =  data$no_rep,
                                                  qValues = input$statistics,
                                                  normalize = input$norm_technique,
                                                  design = input$design))
        
        shiny::incProgress(1, detail = "Calculating.")
        
        #To preserve the column names a separate cbind for matrices and data frames is needed
        data$input_stats_norm_merged <-  cbind(data$stats[[1]], do.call(what = "cbind", data$stats[2:11]))
        output$input_file <- renderDataTable({
          DT::datatable(data$input_stats_norm_merged,
                        options = list(scrollX = TRUE),
                        caption = htmltools::tags$caption(style = "text-align: left; caption-side: initial;",
                                                          'Table 1: ', htmltools::em('User data with calculated statistics and changes in protein expression ')))
        })
        
        shiny::incProgress(1, detail = "Data rendered.")
        shiny::setProgress(message = "Normalization: Finished", value = 4)
        
      })
    })
  
  #4. Loading file sent to app via json file
  observeEvent(
    input$extdata,
    { 
      shiny::withProgress(message = "External data:", min = 0, max = 2, detail = "Loading data and design.",value = 1, {
        jsonmessage <- fromJSON(input$extdata)
        # Loading parameters
        NumCond <- jsonmessage[["numcond"]]
        NumReps <- jsonmessage[["numrep"]]
        isPaired <- jsonmessage[["paired"]]
        isGrouped <- jsonmessage[["grouped"]]
        withStats <- jsonmessage[["withstats"]]
        # reading data matrix
        expr_matr <- jsonmessage[["expr_matrix"]]
        print(names(expr_matr))
        # setting data and parameters
        data$file_indicator <- TRUE
        output$fileInText <- renderText({
          isolate({
          validate(need(!is.null(expr_matr), "Uploaded data empty"))
          validate(need(length(expr_matr)>1, "Uploaded data does not contain multiple columns"))
          validate(need(sum(duplicated(expr_matr[[1]]),na.rm=T)==0,"Duplicated feature names in first column!"))
          tdat <- expr_matr[[1]]
          for (i in 2:length(expr_matr)) {
            validate(need(length(expr_matr[[i]]) == length(expr_matr[[1]]),
                          paste("Wrong array length of sample", names(expr_matr)[i])))
            tdat <- data.frame(tdat, as.numeric(expr_matr[[i]]))
          }
          colnames(tdat) <- names(expr_matr)
          
          data$user_input <- renameAndSort(data = tdat, 
                                           no_cond = NumCond,
                                           no_rep = NumReps,
                                           qValues = F,
                                           grouped = isGrouped,
                                           log2 = T)
          
          
          data$no_cond <- NumCond
          data$no_rep <- NumReps
          data$grouped <- isGrouped
          if (withStats) {
            stats <- jsonmessage[["stat_matrix"]]
            # setting data and parameters
            validate(need(!is.null(stats), "Uploaded statistics data empty"))
            tdat <- stats[[1]]
            for (i in 2:length(stats)) {
              validate(need(length(stats[[i]]) == length(stats[[1]]),
                            paste("Wrong array length of sample", names(stats)[i])))
              tdat <- data.frame(tdat, as.numeric(stats[[i]]))
            }
            colnames(tdat) <- names(stats)
            validate(need(nrow(tdat) == nrow(data$user_input), paste("statistical table does not have the same number of rows")))
            data$user_input <- cbind(data$user_input, tdat)
          }            
          data$stats <- calculateStatistics(data = data$user_input, 
                                            no_cond = data$no_cond, 
                                            no_rep =  data$no_rep,
                                            qValues = withStats,
                                            normalize = NULL,
                                            design = ifelse(isPaired, "paired","unpaired"))
          
          # change rulers
          updateSliderInput(session, "no_conditions",value=data$no_cond)
          updateSliderInput(session, "no_replicates",value=data$no_rep)
          updateCheckboxInput(session, "log2", value=T)
          updateCheckboxInput(session, "grouped", value=data$isGrouped)
          updateCheckboxInput(session, "statistics", value=withStats)
          updateRadioButtons(session, "design", select=ifelse(isPaired, "paired", "unpaired"))
          
          
          output$input_file <- renderDataTable({
            DT::datatable( data$input_stats_merged,
                           options = list(scrollX = TRUE),
                           caption = htmltools::tags$caption(style = "text-align: left; caption-side: initial;",
                                                             'Table 1: ', htmltools::em('User data with calculated statistics and changes in protein expression ')))
            
          })
          
          print("Loaded external data")
          return(paste("Loaded external data"))
        })
      })
      
    })
  
  
  shiny::incProgress(1, detail = "Data loaded.")
  
})



################ ################ ################ DATA VISUALISATION ################ ################ ################
################ Tab 1 ################  
#1. Data distribution boxplot
output$input_boxplot <- renderPlotly({
  req(data$stats)
  data$distribution_plot <- distrPlotlyBox(data$stats$absolute_df,
                                           no_rep = data$no_rep,
                                           no_cond = data$no_cond)
  return(data$distribution_plot$plot)
})

#1.1 Download distribution boxplot

#Create the download UI
output$input_boxplot_download_cui <- renderUI({
  
  req(data$distribution_plot$plot)
  
  tags$p(div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("input_boxplot_width", label = "Width: ", min = 0, max = 2500, value = 1000, step = 100, width = "250px")),
         div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("input_boxplot_height", label = "Height: ", min = 0, max = 2500, value = 1000, step = 100, width = "200px")),
         div(style="display: inline-block;margin: 25px 0px 0px 0px;", downloadButton("input_boxplot_download","Download Figure")),
         bsTooltip("input_boxplot_download", title = "Choose the width and height and download the above distribution boxplot in PDF format.", placement = "right", trigger = "hover", options = list(container = "body")))
  
})

#Save distribution boxplot in PDF format.
output$input_boxplot_download <- downloadHandler(
  
  filename = function() {
    
    paste("DistributionLinePlot_", Sys.time(), ".pdf", collapse = "", sep = "")
    
  },
  content = function(file) {
    
    shiny::withProgress(message = "Distribution boxplot download:", min = 0, max = 3, detail = "Preparing data.",value = 1, {
      
      temp_name <- tempfile(pattern = "distPlot", fileext = ".html")
      
      p <- data$distribution_plot$plot
      
      p$width <- input$input_boxplot_width
      p$height <- input$input_boxplot_height
      
      shiny::incProgress(1, detail = "PDF rendering.")
      htmlwidgets::saveWidget(p, temp_name)
      
      webshot2::webshot(url = temp_name, file = file)
      
      shiny::incProgress(1, detail = "PDF file is ready!")
      unlink(temp_name)
      unlink(paste(gsub( ".html", "", temp_name), "_files", collapse = "", sep = ""), recursive = T)
      
      updateNumericInput(session, "input_boxplot_width", value = 1000)
      updateNumericInput(session, "input_boxplot_height", value = 1000)
      
    })
  }
  
)

#2. Missing values barplot
output$NA_barplot <- renderPlotly({
  
  req(NA_barplot_reactive())
  
  return(NA_barplot_reactive())
  
})

#Create plot in reactive expression.
NA_barplot_reactive <- reactive({
  
  req(data$file_indicator == TRUE)
  
  p <- missingValuePlotly(data = data$stats$absolute_df, no_cond = data$no_cond, no_rep = data$no_rep)
  
  return(p)
  
})

#2.1 Download missing values barplot.

#Create the download UI
output$NA_barplot_download_cui <- renderUI({
  
  req(NA_barplot_reactive())
  
  tags$p(div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("NA_barplot_width", label = "Width: ", min = 0, max = 2500, value = 1000, step = 100, width = "250px")),
         div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("NA_barplot_height", label = "Height: ", min = 0, max = 2500, value = 1000, step = 100, width = "200px")),
         div(style="display: inline-block;margin: 25px 0px 0px 0px;", downloadButton("NA_barplot_download","Download Figure")),
         bsTooltip("NA_barplot_download", title = "Choose the width and height and download the above missing values barplot in PDF format.", placement = "right", trigger = "hover", options = list(container = "body")))
  
})

#Save missing values barplot in PDF format.
output$NA_barplot_download <- downloadHandler(
  
  filename = function() {
    
    paste("NABarplot_", Sys.time(), ".pdf", collapse = "", sep = "")
    
  },
  content = function(file) {
    
    shiny::withProgress(message = "Missing value barplot download:", min = 0, max = 3, detail = "Preparing data.",value = 1, {
      temp_name <- tempfile(pattern = "naBarplot", fileext = ".html")
      
      p <- NA_barplot_reactive()
      
      p$width <- input$NA_barplot_width
      p$height <- input$NA_barplot_height
      
      shiny::incProgress(1, detail = "PDF rendering.")
      htmlwidgets::saveWidget(p, temp_name)
      
      webshot2::webshot(url = temp_name, file = file)
      
      shiny::incProgress(1, detail = "PDF file is ready!")
      unlink(temp_name)
      unlink(paste(gsub( ".html", "", temp_name), "_files", collapse = "", sep = ""), recursive = T)
      
      updateNumericInput(session, "NA_barplot_width", value = 1000)
      updateNumericInput(session, "NA_barplot_height", value = 1000)
      
    })
  }
  
)

#3. CV distribution histogram
output$CV_distr <- renderPlotly({
  req(data$stats)
  data$CV_distr <- CVdistrPlotly(data$stats$CV_df, 
                                 CV_cond = input$CV_reference,
                                 col = input$CV_colour)
  
  return(data$CV_distr$plot)
})

#3.1 Download CV distribution histogram

#Create the download UI
output$CV_distr_download_cui <- renderUI({
  
  req(data$CV_distr$plot)
  
  tags$p(div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("CV_distr_width", label = "Width: ", min = 0, max = 2500, value = 1000, step = 100, width = "250px")),
         div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("CV_distr_height", label = "Height: ", min = 0, max = 2500, value = 1000, step = 100, width = "200px")),
         div(style="display: inline-block;margin: 25px 0px 0px 0px;", downloadButton("CV_distr_download","Download Figure")),
         bsTooltip("CV_distr_download", title = "Choose the width and height and download the above Coefficient of variation distribution histogram in PDF format.", placement = "right", trigger = "hover", options = list(container = "body")))
  
})

#Save CV distribution histogram in PDF format.
output$CV_distr_download <- downloadHandler(
  
  filename = function() {
    
    paste("CVDistributionHistogram_", Sys.time(), ".pdf", collapse = "", sep = "")
    
  },
  content = function(file) {
    
    shiny::withProgress(message = "CV histogram download:", min = 0, max = 3, detail = "Preparing data.",value = 1, {
      
      temp_name <- tempfile(pattern = "CVdistPlot", fileext = ".html")
      
      p <- data$CV_distr$plot
      
      p$width <- input$CV_distr_width
      p$height <- input$CV_distr_height
      
      shiny::incProgress(1, detail = "PDF rendering.")
      htmlwidgets::saveWidget(p, temp_name)
      
      webshot2::webshot(url = temp_name, file = file)
      
      shiny::incProgress(1, detail = "PDF file is ready!")
      unlink(temp_name)
      unlink(paste(gsub( ".html", "", temp_name), "_files", collapse = "", sep = ""), recursive = T)
      
      updateNumericInput(session, "CV_distr_width", value = 1000)
      updateNumericInput(session, "CV_distr_height", value = 1000)
      
    })
  }
  
)

#4. CV mean and median - turn to RED if mean CV > 15% in the sample
output$CV_mean_median <- renderText({
  req(data$CV_distr)
  mean <- round(data$CV_distr$mean,3)
  median <- round(data$CV_distr$median,3)
  text <- paste0("Mean - ", mean , "[%]","Median - ", median ,"[%]")
  return(ifelse(mean > 15, yes = paste0("<div style=\"color:red; text-align: center; font-size: 15pt;\">",text,"</div>"),
                no = paste0("<div style=\"text-align: center; font-size: 15pt;\">",text,"</div>")))
})

#5. Correlation scatter plot
output$scatter <- renderPlotly({
  
  req(scatter_reactive())
  
  return(scatter_reactive())
  
})

#Create plot in reactive expression.
scatter_reactive <- reactive({
  
  req(data$input_stats_merged)
  
  x <- log2(data$input_stats_merged[,(input$scatter_c1+1)])
  y <- log2(data$input_stats_merged[,(input$scatter_c2+1)])
  meth <- input$correlation_scatter
  corr <- round(cor(x, y, method = meth, use = "complete.obs"),3)
  p<- plotly::plot_ly(x = x, y = y, type = "scatter", marker = list(size = 3.5), mode = "markers") %>%
    plotly::layout(title = paste(paste(toupper(substr(meth, 1, 1)), substr(meth, 2, nchar(meth)), sep=""),
                                 "correlation between samples", input$scatter_c1, "and", input$scatter_c2, "-", corr, sep =" "),
                   xaxis = list(title = paste("Sample", input$scatter_c1)),
                   yaxis = list(title = paste("Sample", input$scatter_c2))) %>%
    plotly::config(showLink = F, 
                   displaylogo = F,
                   modeBarButtonsToRemove = list('sendDataToCloud',
                                                 'hoverCompareCartesian',
                                                 'hoverClosestCartesian',
                                                 'toggleSpikelines'))
  return(p)
  
})

#5.1 Download Correlation scatter plot

#Create the download UI
output$scatter_download_cui <- renderUI({
  
  req(scatter_reactive())
  
  tags$p(div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("scatter_width", label = "Width: ", min = 0, max = 2500, value = 1000, step = 100, width = "250px")),
         div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("scatter_height", label = "Height: ", min = 0, max = 2500, value = 1000, step = 100, width = "200px")),
         div(style="display: inline-block;margin: 25px 0px 0px 0px;", downloadButton("scatter_download","Download Figure")),
         bsTooltip("scatter_download", title = "Choose the width and height and download the above correlation scatter plot in PDF format.", placement = "right", trigger = "hover", options = list(container = "body")))
  
})

#Save correlation scatter plot in PDF format.
output$scatter_download <- downloadHandler(
  
  filename = function() {
    
    paste("CorScatterPlot_", Sys.time(), ".pdf", collapse = "", sep = "")
    
  },
  content = function(file) {
    
    shiny::withProgress(message = "Coreelations scatter plot download:", min = 0, max = 3, detail = "Preparing data.",value = 1, {
      temp_name <- tempfile(pattern = "qVdistPlot", fileext = ".html")
      
      p <- scatter_reactive()
      
      p$width <- input$scatter_width
      p$height <- input$scatter_height
      
      shiny::incProgress(1, detail = "PDF rendering.")
      htmlwidgets::saveWidget(p, temp_name)
      
      webshot2::webshot(url = temp_name, file = file)
      
      shiny::incProgress(1, detail = "PDF file is ready!")
      unlink(temp_name)
      unlink(paste(gsub( ".html", "", temp_name), "_files", collapse = "", sep = ""), recursive = T)
      
      updateNumericInput(session, "scatter_width", value = 1000)
      updateNumericInput(session, "scatter_height", value = 1000)
    })
  }
  
)

#6. qValue distribution histogram

output$qV_distr <- renderPlotly({
  
  req(qV_distr_reactive())
  return(qV_distr_reactive())
  
})

#Create plot in reactive expression.
qV_distr_reactive <- reactive({
  
  if(data$file_indicator == TRUE){  
    
    p <- qValuePlot(data$stats, condition = input$qV_reference, col = input$qV_colour)
    return(p)
    
  } else {
    
    return(NULL)  
    
  }
  
})

#6.1 Download qValue distribution histogram

#Create the download UI
output$qV_distr_download_cui <- renderUI({
  
  req(qV_distr_reactive())
  
  tags$p(div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("qV_distr_width", label = "Width: ", min = 0, max = 2500, value = 1000, step = 100, width = "250px")),
         div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("qV_distr_height", label = "Height: ", min = 0, max = 2500, value = 1000, step = 100, width = "200px")),
         div(style="display: inline-block;margin: 25px 0px 0px 0px;", downloadButton("qV_distr_download","Download Figure")),
         bsTooltip("qV_distr_download", title = "Choose the width and height and download the above qValue distribution histogram in PDF format.", placement = "right", trigger = "hover", options = list(container = "body")))
  
})

#Save qValue distribution histogram in PDF format.
output$qV_distr_download <- downloadHandler(
  
  filename = function() {
    
    paste("qValueDistributionHistogram_", Sys.time(), ".pdf", collapse = "", sep = "")
    
  },
  content = function(file) {
    
    shiny::withProgress(message = "q-Value distribution plot download:", min = 0, max = 3, detail = "Preparing data.",value = 1, {
      temp_name <- tempfile(pattern = "qVdistPlot", fileext = ".html")
      
      p <- qV_distr_reactive()
      
      p$width <- input$qV_distr_width
      p$height <- input$qV_distr_height
      
      shiny::incProgress(1, detail = "PDF rendering.")
      htmlwidgets::saveWidget(p, temp_name)
      
      webshot2::webshot(url = temp_name, file = file)
      
      shiny::incProgress(1, detail = "PDF file is ready!")
      unlink(temp_name)
      unlink(paste(gsub( ".html", "", temp_name), "_files", collapse = "", sep = ""), recursive = T)
      
      updateNumericInput(session, "qV_distr_width", value = 1000)
      updateNumericInput(session, "qV_distr_height", value = 1000)
      
    })
  }
  
)

#7. Volcano plots
output$volcano <- renderPlotly({
  
  req(volcano_reactive())
  
  return(volcano_reactive())
  
})

#Create plot in reactive expression
volcano_reactive <- reactive({
  
  req(input$volcano_cond>=2 & !is.null(data$stats))
  
  p <- volcanoPlot(data$stats, input$volcano_cond, input$volcano_th)
  
  return(p)
  
})

#7.1 Download volcano plot

#Create the download UI
output$volcano_download_cui <- renderUI({
  
  req(volcano_reactive())
  
  tags$p(div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("volcano_width", label = "Width: ", min = 0, max = 2500, value = 1000, step = 100, width = "250px")),
         div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("volcano_height", label = "Height: ", min = 0, max = 2500, value = 1000, step = 100, width = "200px")),
         div(style="display: inline-block;margin: 25px 0px 0px 0px;", downloadButton("volcano_download","Download Figure")),
         bsTooltip("volcano_download", title = "Choose the width and height and download the above volcano plot in PDF format.", placement = "right", trigger = "hover", options = list(container = "body")))
  
})

#Save volcano plot in PDF format.
output$volcano_download <- downloadHandler(
  
  filename = function() {
    
    paste("VolcanoPlot_", Sys.time(), ".pdf", collapse = "", sep = "")
    
  },
  content = function(file) {
    
    shiny::withProgress(message = "Volcano plot download:", min = 0, max = 3, detail = "Preparing data.",value = 1, {
      temp_name <- tempfile(pattern = "volcano", fileext = ".html")
      
      p <- volcano_reactive()
      
      p$width <- input$volcano_width
      p$height <- input$volcano_height
      
      shiny::incProgress(1, detail = "PDF rendering.")
      htmlwidgets::saveWidget(p, temp_name)
      
      webshot2::webshot(url = temp_name, file = file)
      
      shiny::incProgress(1, detail = "PDF file is ready!")
      unlink(temp_name)
      unlink(paste(gsub( ".html", "", temp_name), "_files", collapse = "", sep = ""), recursive = T)
      
      updateNumericInput(session, "volcano_width", value = 1000)
      updateNumericInput(session, "volcano_height", value = 1000)
    })
  }
  
)

#8. PCA - take absolute values and in the function perform LOG2 transformation
output$pca <- renderPlotly({
  
  req(pca_reactive())
  
  return(pca_reactive())
  
})

#Create plot in reactive expression
pca_reactive <- reactive({
  
  req(data$stats)
  
  p <- plotlyPCA(data = data$stats$absolute_df, no_cond = data$no_cond, no_rep  = data$no_rep)
  
  return(p)
  
})

#8.1 Download PCA plot

#Create the download UI
output$pca_download_cui <- renderUI({
  
  req(pca_reactive())
  
  tags$p(div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("pca_width", label = "Width: ", min = 0, max = 2500, value = 1000, step = 100, width = "250px")),
         div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("pca_height", label = "Height: ", min = 0, max = 2500, value = 1000, step = 100, width = "200px")),
         div(style="display: inline-block;margin: 25px 0px 0px 0px;", downloadButton("pca_download","Download Figure")),
         bsTooltip("pca_download", title = "Choose the width and height and download the above PCA plot in PDF format.", placement = "right", trigger = "hover", options = list(container = "body")))
  
})

#Save PCA plot in PDF format.
output$pca_download <- downloadHandler(
  
  filename = function() {
    
    paste("PCAPlot_", Sys.time(), ".pdf", collapse = "", sep = "")
    
  },
  content = function(file) {
    
    shiny::withProgress(message = "Volcano plot download:", min = 0, max = 3, detail = "Preparing data.",value = 1, {
      
      temp_name <- tempfile(pattern = "pca", fileext = ".html")
      
      p <- pca_reactive()
      
      p$width <- input$pca_width
      p$height <- input$pca_height
      
      shiny::incProgress(1, detail = "PDF rendering.")
      htmlwidgets::saveWidget(p, temp_name)
      
      webshot2::webshot(url = temp_name, file = file)
      
      shiny::incProgress(1, detail = "PDF file is ready!")
      unlink(temp_name)
      unlink(paste(gsub( ".html", "", temp_name), "_files", collapse = "", sep = ""), recursive = T)
      
      updateNumericInput(session, "pca_width", value = 1000)
      updateNumericInput(session, "pca_height", value = 1000)
      
    })
  }
  
)

################ Tab 2 ################    
#1. Main table to display protein complexes. (Body) (Done)
shiny::observeEvent(input$run_analysis, {
  
  output$user_complexes <- DT::renderDataTable({
    
    shiny::req(data$user_input, data$stats)
    
    shiny::withProgress(message = "Analysing protein complexes in your data", min = 0, max = 4, value = 0, {
      
      if(input$database == "CORUM"){
        
        database <- corum_prepared
        
      } else if(input$database == "EBI Complex Portal"){
        
        database <- complex_portal_prepared
        
      } else if(input$database == "User defined database"){
        
        shiny::req(input$user_database$datapath)
        database <- prepareUserDB(input$user_database$datapath)
        
      }
      
      shiny::incProgress(1, detail = "DB established.")
      index_vector <- which(data$stats$absolute_df[,1] %in% unique(unlist(database[database$Organism == input$species,]$Subunits)))
      data$f_stats <- lapply(data$stats, function(x) if(!is.vector(x)){return(x[index_vector,])}else{return(x[index_vector])})
      shiny::incProgress(1, detail = "DB search")
      
      # Enable buttons for sending human proteins to CoExpresso
      if(input$species == "Homo sapiens" | input$species == "Human") {
        
        shinyjs::enable("CoExpresso")
        shinyjs::enable("CoExpressoFull")
        
      } else {
        
        shinyjs::disable("CoExpresso")
        shinyjs::disable("CoExpressoFull")
        
      }
      
      data$f_database <- filterDatabase(f_data = data$f_stats$absolute_df,database = database, organism = input$species)
      
      if (is.null(data$f_database)) {
        
        return(DT::datatable(data.frame(Warning = paste0("No complexes found for ", input$species, "."), stringsAsFactors = F),
                             caption = htmltools::tags$caption(style = "caption-side: top; text-align: left;", "Table 2: ", htmltools::em("Protein complexes found in the input dataset (using 0 proteins)"))) )
        shiny::incProgress(2, "No complexes found.")
        
      } else {
        
        data$no_complexes <- length(data$f_database[,1])  
        data$no_proteins_used <- length(data$f_stats$absolute_df[,1])
        shiny::incProgress(1, "Complexes expression calculation.")
        data$f_db_farms <- cbind(data$f_database, complexDBfarms(f_database = data$f_database, stats = data$f_stats, no_cond = data$no_cond, no_rep = data$no_rep))
        shiny::incProgress(1, "Data aggregation.")
        #Change a vector to string for better display (subunits)
        data$for_display <- concatinateSubunits(filtered_database = data$f_db_farms)
        
        #Hover labels for the table
        container <- generateColLabels(data$no_cond, database = input$database)
        shiny::req(data$for_display)
        
        
        DT::datatable(data$for_display, 
                      selection = list(mode = "single",selected = 1), 
                      height = 400,
                      filter = "top",
                      container = container,
                      caption = htmltools::tags$caption(style = "caption-side: top; text-align: left;", "Table 2: ", htmltools::em(paste0("Protein complexes found in the input dataset", " (using ", data$no_proteins_used, " proteins)"))),
                      options = list(scrollX = TRUE,
                                     scrollY = TRUE,
                                     columnDefs = list(list(targets = c(6,7),
                                                            render = DT::JS("function(data, type, row, meta) {", "return type === 'display' && data.length > 15 ?",
                                                                            "'<span title=\"' + data + '\">' + data.substr(0, 15) + '...</span>' : data;", "}")),
                                                       list(targets = c(1,3,4,5), width = "35px"),
                                                       list(targets = c(2), width = "200px", render = DT::JS("function(data, type, row, meta) {", "return type === 'display' && data.length > 30 ?",
                                                                                                             "'<span title=\"' + data + '\">' + data.substr(0, 30) + '...</span>' : data;", "}")))
                      )
        )
      }
      
    })
  })
})


#2. Star graph complex
output$complex_graph <- networkD3::renderForceNetwork({
  
  req(data$f_stats$FC_df,
      data$f_database,
      input$user_complexes_rows_selected,
      condition = input$star_condition)
  data$significance_level <- ifelse(input$q_values_th, yes = input$significance_level, no = 1)
  data$star_graph <- plotD3complexGraph(stats =  data$f_stats,
                                        f_db = data$f_database, 
                                        row = input$user_complexes_rows_selected, 
                                        condition = input$star_condition, 
                                        q_threshold = data$significance_level,
                                        fc_threhold = input$FC_th)
  
  data$star_graph$star_graph
  
})

#2.1 Download complex star graph

#Create the download UI
output$complex_graph_download_cui <- renderUI({
  
  req(data$star_graph$star_graph)
  
  tags$p(div(style="display: inline-block;margin: 25px 0px 0px 0px;", downloadButton("complex_graph_download","Download Figure")),
         bsTooltip("complex_graph_download", title = "Click the download button to download the above complex graph in PDF format.", placement = "right", trigger = "hover", options = list(container = "body")))
  
})

#Save complex graph in PDF format.
output$complex_graph_download <- downloadHandler(
  
  filename = function() {
    
    paste("ComplexGraph_", Sys.time(), ".pdf", collapse = "", sep = "")
    
  },
  content = function(file) {
    
    shiny::withProgress(message = "Star-graph download:", min = 0, max = 3, detail = "Preparing data.",value = 1, {
      
      temp_name <- tempfile(pattern = "star", fileext = ".html")
      
      p <- data$star_graph$star_graph
      
      p$x$options$opacityNoHover <- T
      p$x$options$opacity <- 1
      p$x$options$opacityNoHover <- 1
      
      shiny::incProgress(1, detail = "PDF rendering.")
      htmlwidgets::saveWidget(p, temp_name)
      
      webshot2::webshot(url = temp_name, file = file)
      
      shiny::incProgress(1, detail = "PDF file is ready!")
      unlink(temp_name)
      unlink(paste(gsub( ".html", "", temp_name), "_files", collapse = "", sep = ""), recursive = T)
      
    })
  }
  
)


#3. Multiline plot
output$multiline_plot <- renderPlotly({
  
  req(data$f_database$NQS[input$user_complexes_rows_selected]>1)
  shiny::validate(need(!is.null(data$f_stats), "No data from statistical tests"))
  data$multiline_plot <- multilinePlot(f_db = data$f_database, 
                                       stats = data$f_stats,
                                       row = input$user_complexes_rows_selected,
                                       no_cond = data$no_cond,
                                       scale = input$multiline_scale)
  
  req(data$multiline_plot$plot)
  return(data$multiline_plot$plot)
  
})


#3.1 Download multiline plot

#Create the download UI
output$multiline_plot_download_cui <- renderUI({
  
  req(data$multiline_plot$plot)
  
  tags$p(div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("multiline_plot_width", label = "Width: ", min = 0, max = 2500, value = 1000, step = 100, width = "250px")),
         div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("multiline_plot_height", label = "Height: ", min = 0, max = 2500, value = 1000, step = 100, width = "200px")),
         div(style="display: inline-block;margin: 25px 0px 0px 0px;", downloadButton("multiline_plot_download","Download Figure")),
         bsTooltip("multiline_plot_download", title = "Choose the width and height and download the above expression profile plot in PDF format.", placement = "right", trigger = "hover", options = list(container = "body")))
  
})

#Save the multiline plot in PDF format.
output$multiline_plot_download <- downloadHandler(
  
  filename = function() {
    
    paste("MultiLinePlot_", Sys.time(), ".pdf", collapse = "", sep = "")
    
  },
  content = function(file) {
    
    shiny::withProgress(message = "Expression line-plot download:", min = 0, max = 3, detail = "Preparing data.",value = 1, {
      
      temp_name <- tempfile(pattern = "multiPlot", fileext = ".html")
      
      p <- data$multiline_plot$plot
      
      p$width <- input$multiline_plot_width
      p$height <- input$multiline_plot_height
      
      shiny::incProgress(1, detail = "PDF rendering.")
      htmlwidgets::saveWidget(p, temp_name)
      
      webshot2::webshot(url = temp_name, file = file)
      
      shiny::incProgress(1, detail = "PDF file is ready!")
      unlink(temp_name)
      unlink(paste(gsub( ".html", "", temp_name), "_files", collapse = "", sep = ""), recursive = T)
      
      updateNumericInput(session, "multiline_plot_width", value = 1000)
      updateNumericInput(session, "multiline_plot_height", value = 1000)
      
    })
  }
  
)

#4. Single subunits expression barplot
output$expression_barplot <- plotly::renderPlotly({
  
  shiny::validate(need(input$node_clicked %in% data$f_stats$absolute_df[,1], "Please click on a protein in the Protein complex visualization panel"))
  req(expression_barplot_reactive())
  return(expression_barplot_reactive())
  
})

#Reactive single subunits expression barplot
expression_barplot_reactive <- reactive({
  
  req(input$node_clicked, data$f_stats)
  
  if(!(as.character(input$node_clicked) %in% as.character(data$f_stats$absolute_df[,1]))){
    return(NULL)
  }
  if(!is.null(data$f_stats)) {
    my_plot <- expressionBarplot(input$node_clicked, f_data = data$f_stats$absolute_df, stat_list = data$f_stats)
  }
})

#4.1 Download single subunits expression barplot

#Create the download UI
output$expression_barplot_download_cui <- renderUI({
  
  req(expression_barplot_reactive())
  
  tags$p(div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("expression_barplot_width", label = "Width: ", min = 0, max = 2500, value = 1000, step = 100, width = "250px")),
         div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("expression_barplot_height", label = "Height: ", min = 0, max = 2500, value = 1000, step = 100, width = "200px")),
         div(style="display: inline-block;margin: 25px 0px 0px 0px;", downloadButton("expression_barplot_download","Download Figure")),
         bsTooltip("expression_barplot_download", title = "Choose the width and height and download the above expression barplot in PDF format.", placement = "right", trigger = "hover", options = list(container = "body")))
  
})

#Save the single subunits expression barplot in PDF format.
output$expression_barplot_download <- downloadHandler(
  
  filename = function() {
    
    paste("ExpressionBarplot_", Sys.time(), ".pdf", collapse = "", sep = "")
    
  },
  content = function(file) {
    
    shiny::withProgress(message = "Protein expression barplot download:", min = 0, max = 3, detail = "Preparing data.",value = 1, {
      
      temp_name <- tempfile(pattern = "expressionBarplot", fileext = ".html")
      
      p <- expression_barplot_reactive()
      
      p$width <- input$expression_barplot_width
      p$height <- input$expression_barplot_height
      
      shiny::incProgress(1, detail = "PDF rendering.")
      htmlwidgets::saveWidget(p, temp_name)
      
      webshot2::webshot(url = temp_name, file = file)
      
      shiny::incProgress(1, detail = "PDF file is ready!")
      unlink(temp_name)
      unlink(paste(gsub( ".html", "", temp_name), "_files", collapse = "", sep = ""), recursive = T)
      
      updateNumericInput(session, "expression_barplot_width", value = 1000)
      updateNumericInput(session, "expression_barplot_height", value = 1000)
      
    })
  }
  
)

#5. Table underneath the barplot
output$fc_table <- renderDataTable({
  req(input$node_clicked, 
      data$f_stats)
  row <- match(input$node_clicked, data$f_stats$absolute_df[,1])
  df <- t(data.frame(data$f_stats$FC_df[row,]))
  rownames(df) <- input$node_clicked
  DT::datatable(df, options = list(dom = 't'))
})

#6. Table underneath the barplot
output$qValue_table <- renderDataTable({
  req(input$node_clicked, data$no_cond, data$no_rep)
  row <- match(input$node_clicked, data$f_stats$absolute_df[,1])
  df <- t(data.frame(data$f_stats$qValue_df[row,]))
  rownames(df) <- input$node_clicked
  DT::datatable(df, options = list(dom = 't'))
})

#7. Co-expression (linearity)
output$Complex_correlation <- renderPlotly({
  
  req(Complex_correlation_reactive())
  return(Complex_correlation_reactive())
  
})

#Reactive co-expression plot
Complex_correlation_reactive <- reactive({
  
  req(data$f_database$NQS[input$user_complexes_rows_selected]>2)
  req(input$Corr_C1, input$Corr_C2)
  plotComplexCorrelation(database = data$f_database,
                         row = input$user_complexes_rows_selected,
                         stats = data$f_stats,
                         cond_1 = input$Corr_C1,
                         cond_2 = input$Corr_C2)
  
})

#7.1 Download complex correlation graph

#Create the download UI
output$Complex_correlation_download_cui <- renderUI({
  
  req(Complex_correlation_reactive())
  
  tags$p(div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("Complex_correlation_width", label = "Width: ", min = 0, max = 2500, value = 1000, step = 100, width = "250px")),
         div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("Complex_correlation_height", label = "Height: ", min = 0, max = 2500, value = 1000, step = 100, width = "200px")),
         div(style="display: inline-block;margin: 25px 0px 0px 0px;", downloadButton("Complex_correlation_download","Download Figure")),
         bsTooltip("Complex_correlation_download", title = "Choose the width and height and download the above complex correlation plot in PDF format.", placement = "right", trigger = "hover", options = list(container = "body")))
  
})

#Save the single subunits expression barplot in PDF format.
output$Complex_correlation_download <- downloadHandler(
  
  filename = function() {
    
    paste("ComplexCorrelationPlot_", Sys.time(), ".pdf", collapse = "", sep = "")
    
  },
  content = function(file) {
    
    shiny::withProgress(message = "Complex correlation plot download:", min = 0, max = 3, detail = "Preparing data.",value = 1, {
      
      temp_name <- tempfile(pattern = "expressionBarplot", fileext = ".html")
      
      p <- Complex_correlation_reactive()
      
      p$width <- input$Complex_correlation_width
      p$height <- input$Complex_correlation_height
      
      shiny::incProgress(1, detail = "PDF rendering.")
      htmlwidgets::saveWidget(p, temp_name)
      
      webshot2::webshot(url = temp_name, file = file)
      
      shiny::incProgress(1, detail = "PDF file is ready!")
      unlink(temp_name)
      unlink(paste(gsub( ".html", "", temp_name), "_files", collapse = "", sep = ""), recursive = T)
      
      updateNumericInput(session, "Complex_correlation_width", value = 1000)
      updateNumericInput(session, "Complex_correlation_height", value = 1000)
      
    })
  }
  
)


#8. Complex information table
output$complex_information <- renderDataTable({
  req(input$database, 
      input$user_complexes_rows_selected)
  if(input$database == "CORUM"){ 
    i <- input$user_complexes_rows_selected
    ComplexID <- as.character(data$f_database$ComplexID[i])
    row <- match(ComplexID, 
                 corum_prepared$ComplexID)
    complex_df <- corum_prepared[row,]
    complex_df <- complex_df %>% 
      dplyr::select(Complex_name = Complex_Name, 
                    ## TODO: add more info from original CORUM download
                    Subunits = Subunits,
                    GO_terms = Gene_ontology,
                    Publication_PubMedID = PubMed.ID)
    # Subunits = subunits.UniProt.IDs., 
    # Subunits_gene = subunits.Gene.name., 
    # Subunits_name = subunits.Protein.name.,
    # FunCat_Description = FunCat.description,
    # Comment = Complex.comment,  
    # Disease  = Disease.comment)
    rownames(complex_df) <- "Additional complex information"
    complex_df$Subunits <- paste0("[",sapply(complex_df$Subunits, function(x) gsub(",","][",x)), "]",collapse="")
    # complex_df$Subunits_gene <- paste0("[",sapply(complex_df$Subunits_gene, function(x) gsub(";","][",x)), "]")
    # complex_df$Subunits_name <- paste0("[",sapply(complex_df$Subunits_name, function(x) gsub(";","][",x)), "]")
    
  }
  else if(input$database == "EBI Complex Portal") {
    i <- input$user_complexes_rows_selected
    ComplexID <- as.character(data$f_database$ComplexID[i])
    row <- match(ComplexID, 
                 complex_portal_prepared[,1])
    complex_df <- complex_portal_prepared[row,]
    complex_df <- complex_df %>% 
      dplyr::select(Complex_name = Complex_Name, 
                    Subunits = Subunits, 
                    # Confidence = Confidence, 
                    GO.annotations = GO_terms) 
    # Disease  = Disease)
    rownames(complex_df) <- "Additional complex information"
    complex_df$Subunits <- paste0("[",paste(unlist(sapply(complex_df$Subunits, function(x) 
      gsub(",","][",x)))), "]",collapse="")
    # complex_df$Protein_subunits <- sapply(complex_df$Subunits_and_stoichiometry, function(x) gsub("|","\r\n",x))
    
  } else if(input$database == "User defined database"){
    
    complex_df <- data.frame(Information = "This tab does not contain additional information for user defined databases")
    
  }
  else if(input$database == "User defined database"){
    complex_df <- data.frame(Information = "This tab does not contain additional information for user defined databases")
  }
  DT::datatable(t(complex_df),
                options = list(scrollX = FALSE,
                               paging = FALSE,
                               scrollY = '50vh',
                               selection = list(mode = "none"),
                               deferRender = FALSE,
                               scrollY = TRUE))
})

#9. Complex names as headers for expression and correlation heatmaps. (Body) (Done)
output$complex_name <- shiny::renderText({
  
  paste0("Complex: ", as.character(data$f_database[input$user_complexes_rows_selected, "Complex_Name"]))
  
})

output$complex_name1 <- shiny::renderText({
  
  paste0("Complex: ", as.character(data$f_database[input$user_complexes_rows_selected, "Complex_Name"]))
  
})

#10. Expression heatmap (Body) (Done)
output$expression_heatmap <- plotly::renderPlotly({
  
  shiny::req(expression_heatmap_reactive())
  return(expression_heatmap_reactive())
  
})

#Reactive protein complex expression heatmap. (Body) (Done)
expression_heatmap_reactive <- shiny::reactive({
  
  shiny::req(data$f_database$NQS[input$user_complexes_rows_selected] >= 2)
  shiny::req(data$no_cond >= 2)
  
  
  if(input$d_measure == "minkowski"){
    
    shiny::req(input$minkowski_p)
    
    p <- plotComplexHeatmap(names_vector = data$multiline_plot$subunits_names,
                            index_vector = data$multiline_plot$index_vector,
                            stats   = data$f_stats,
                            no_cond = data$no_cond,
                            distance_measure = input$d_measure,
                            agg_method = input$agg_method,
                            p = as.numeric(input$minkowski_p))
    
  } else {
    
    p <- plotComplexHeatmap(names_vector = data$multiline_plot$subunits_names,
                            index_vector = data$multiline_plot$index_vector,
                            stats   = data$f_stats,
                            no_cond = data$no_cond,
                            distance_measure = input$d_measure,
                            agg_method = input$agg_method)
    
    
  }
  
  return(p$heatmap)
  
})

#10.1 Download expression heat map in PDF
#Create the download UI
output$expression_heatmap_download_cui <- renderUI({
  
  req(expression_heatmap_reactive())
  
  tags$p(div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("expression_heatmap_width", label = "Width: ", min = 0, max = 2500, value = 1000, step = 100, width = "250px")),
         div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("expression_heatmap_height", label = "Height: ", min = 0, max = 2500, value = 1000, step = 100, width = "200px")),
         div(style="display: inline-block;margin: 25px 0px 0px 0px;", downloadButton("expression_heatmap_download","Download Figure")),
         bsTooltip("expression_heatmap_download", title = "Choose the width and height and download the above expression heatmap in PDF format.", placement = "right", trigger = "hover", options = list(container = "body")))
  
})

#Save the expression heatmap in PDF format.
output$expression_heatmap_download <- downloadHandler(
  
  filename = function() {
    
    paste("ExpressionHeatmap_", Sys.time(), ".pdf", collapse = "", sep = "")
    
  },
  content = function(file) {
    
    shiny::withProgress(message = "Expression heatmap download:", min = 0, max = 3, detail = "Preparing data.",value = 1, {
      
      temp_name <- tempfile(pattern = "exprHeatmap", fileext = ".html")
      
      p <- expression_heatmap_reactive()
      
      p$width <- input$expression_heatmap_width
      p$height <- input$expression_heatmap_height
      
      shiny::incProgress(1, detail = "PDF rendering.")
      htmlwidgets::saveWidget(p, temp_name)
      
      webshot2::webshot(url = temp_name, file = file)
      
      shiny::incProgress(1, detail = "PDF file is ready!")
      unlink(temp_name)
      unlink(paste(gsub( ".html", "", temp_name), "_files", collapse = "", sep = ""), recursive = T)
      
      updateNumericInput(session, "expression_heatmap_width", value = 1000)
      updateNumericInput(session, "expression_heatmap_height", value = 1000)
      
    })
  }
  
)

#11. Co-expression heatmap
output$correlation_heatmap <- renderPlotly({
  
  req(correlation_heatmap_reactive())
  return(correlation_heatmap_reactive())
  
})

#Co-expression heatmap in reactive expression
correlation_heatmap_reactive <- reactive({
  
  req(data$f_database$NQS[input$user_complexes_rows_selected]>=2)
  plotCorrelationHeatmap(names_vector = data$multiline_plot$subunits_names,
                         index_vector = data$multiline_plot$index_vector,
                         correlation_measure = input$correlation_measure,
                         stats = data$f_stats,
                         distance_measure = input$d_measure,
                         agg_method = input$agg_method,
                         p = ifelse(test = input$d_measure == "minkowski", 
                                    yes = input$minkowski_p, 
                                    no = NULL))
  
})

#11.1 Download co-expression heat map in PDF
#Create the download UI
output$correlation_heatmap_download_cui <- renderUI({
  
  req(correlation_heatmap_reactive())
  
  tags$p(div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("correlation_heatmap_width", label = "Width: ", min = 0, max = 2500, value = 1000, step = 100, width = "250px")),
         div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("correlation_heatmap_height", label = "Height: ", min = 0, max = 2500, value = 1000, step = 100, width = "200px")),
         div(style="display: inline-block;margin: 25px 0px 0px 0px;", downloadButton("correlation_heatmap_download","Download Figure")),
         bsTooltip("correlation_heatmap_download", title = "Choose the width and height and download the above co-expression heatmap in PDF format.", placement = "right", trigger = "hover", options = list(container = "body")))
  
})

#Save the co-expression heatmap in PDF format.
output$correlation_heatmap_download <- downloadHandler(
  
  filename = function() {
    
    paste("CoExpressionHeatmap_", Sys.time(), ".pdf", collapse = "", sep = "")
    
  },
  content = function(file) {
    
    shiny::withProgress(message = "Co-expression heatmap download:", min = 0, max = 3, detail = "Preparing data.",value = 1, {
      
      temp_name <- tempfile(pattern = "coExprHeatmap", fileext = ".html")
      
      p <- correlation_heatmap_reactive()
      
      p$width <- input$correlation_heatmap_width
      p$height <- input$correlation_heatmap_height
      
      shiny::incProgress(1, detail = "PDF rendering.")
      htmlwidgets::saveWidget(p, temp_name)
      
      webshot2::webshot(url = temp_name, file = file)
      
      shiny::incProgress(1, detail = "PDF file is ready!")
      unlink(temp_name)
      unlink(paste(gsub( ".html", "", temp_name), "_files", collapse = "", sep = ""), recursive = T)
      
      updateNumericInput(session, "correlation_heatmap_width", value = 1000)
      updateNumericInput(session, "correlation_heatmap_height", value = 1000)
      
    })
  }
  
)

#12. Summary - barplot of changing complexes, according to set thresholds (FC, noise)

output$summary_barplot <- renderPlotly({
  
  req(summary_barplot_reactive())
  return(summary_barplot_reactive())
  
})

#Reactive summary barplot.
summary_barplot_reactive <- reactive({
  
  req(data$f_db_farms, data$no_cond)
  regulatedBarplot(f_db_farms = data$f_db_farms, no_cond = data$no_cond, FC_th = input$FC_th,noise_th = input$noise_th)
  
})

#12.1 Download summary barplot in PDF
#Create the download UI
output$summary_barplot_download_cui <- renderUI({
  
  req(summary_barplot_reactive())
  
  tags$p(div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("summary_barplot_width", label = "Width: ", min = 0, max = 2500, value = 1000, step = 100, width = "250px")),
         div(style="display: inline-block;vertical-align:top; width: 200px;", numericInput("summary_barplot_height", label = "Height: ", min = 0, max = 2500, value = 1000, step = 100, width = "200px")),
         div(style="display: inline-block;margin: 25px 0px 0px 0px;", downloadButton("summary_barplot_download","Download Figure")),
         bsTooltip("summary_barplot_download", title = "Choose the width and height and download the above co-expression heatmap in PDF format.", placement = "right", trigger = "hover", options = list(container = "body")))
  
})

#Save the summary barplot in PDF format.
output$summary_barplot_download <- downloadHandler(
  
  filename = function() {
    
    paste("SummaryBarplot_", Sys.time(), ".pdf", collapse = "", sep = "")
    
  },
  content = function(file) {
    
    shiny::withProgress(message = "Expression heatmap download:", min = 0, max = 3, detail = "Preparing data.",value = 1, {
      
      temp_name <- tempfile(pattern = "summaryBarplot", fileext = ".html")
      
      p <- summary_barplot_reactive()
      
      p$width <- input$summary_barplot_width
      p$height <- input$summary_barplot_height
      
      shiny::incProgress(1, detail = "PDF rendering.")
      htmlwidgets::saveWidget(p, temp_name)
      
      webshot2::webshot(url = temp_name, file = file)
      
      shiny::incProgress(1, detail = "PDF file is ready!")
      unlink(temp_name)
      unlink(paste(gsub( ".html", "", temp_name), "_files", collapse = "", sep = ""), recursive = T)
      
      updateNumericInput(session, "summary_barplot_width", value = 1000)
      updateNumericInput(session, "summary_barplot_height", value = 1000)
      
    })
  }
  
)

#13. Summary - top 5 table (Body) (Done)
output$changing_table <- DT::renderDataTable({
  
  shiny::req(data$f_db_farms, input$summary_cond)
  changingTable(f_db_farms = data$f_db_farms, cond = input$summary_cond, noise_th = input$noise_th, FC_th = input$FC_th)
  
})

#14. Summary - text
output$summary <- renderText({
  req(data$f_db_farms, data$no_cond, data$no_rep, input$summary_cond, input$noise_th)
  complexDBsummary(data$f_db_farms, 
                   no_cond = data$no_cond, 
                   no_rep = data$no_rep, 
                   condition = input$summary_cond, 
                   noise_th = input$noise_th)})


#15. Submission of human uniprot accession to CoExpresso
observeEvent(input$CoExpresso,{
  url <- 'http://computproteomics.bmb.sdu.dk:8192/app_direct/CoExpresso/'
  
  complex_name <- data$f_database$Complex_Name[input$user_complexes_rows_selected]
  subunits <- data$f_database$Subunits[[input$user_complexes_rows_selected]]
  protein_list <- data$f_stats$absolute_df[, 1]
  is_in_input <- subunits %in% protein_list
  present_subunits <- subunits[is_in_input]
  CoExpressoMessage <- toJSON(list(prot_list=present_subunits))
  shinyjs::runjs(paste("send_message(\"",url,"\",",CoExpressoMessage,")",sep=""))
})

observeEvent(input$CoExpressoFull,{
  url <- 'http://computproteomics.bmb.sdu.dk:8192/app_direct/CoExpresso/'
  CoExpressoMessage <- toJSON(list(prot_list=data$f_database$Subunits[input$user_complexes_rows_selected]))
  #print(data$f_database$Subunits[input$user_complexes_rows_selected])
  shinyjs::runjs(paste("send_message(\"",url,"\",",CoExpressoMessage,")",sep=""))
  
})

}