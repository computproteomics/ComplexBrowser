source("Functions.R")
#Developed by Wojciech Michalak as MSc thesis project
#"Bioinformatics in Proteomics: A web based platform for supervised analysis focused on protein complexes"
# June 2018


function(input,output,session){
  #Initiate empty reactiveValues object to store all data and results
  data <- reactiveValues()
  user_input <- NULL
  data$file_indicator <- FALSE
  
  ################ ################ ################ DYNAMIC INTERFACE ################ ################ ################
  #Interacive user's interface elements, adjusting to the given input
  
  ################ TAB 1 - QC ################
  #1. Design for statistical test
  output$design <- renderUI({
    req(input$statistics==FALSE)
    radioButtons(inputId = "design", 
                 label = "Choose design for limma",
                 choices = c("unpaired", "paired"),
                 select = "unpaired", inline = TRUE)
  })
  
  #2. Download button - appears after the data is loaded and statistics is calculated  
  output$download_input_stats_merged <- renderUI(
    if(!is.null(data$input_stats_merged)){
      downloadButton("input_stats_download", 
                     "Download table")
  })
  
  #3. Download button for the QC report
  output$QC_report_button <- renderUI({
    req(data$stats)
    downloadButton("QC_report", 
                   "Download QC Report")
  })
  
  
  #4. QValue distribution
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
  
  ################ TAB 2 - Protein complexes ################
  #1. Species selection, depending on the database chosen
  output$species <- renderUI(
    if(input$database == "CORUM"){
      selectInput(inputId = "species",
                  label = "Species",
                  choices = c("Bovine", "Dog", "Hamster", "Human", "Mammalia",
                              "MINK", "Mouse", "Pig", "Rabbit", "Rat"),
                  selected = "Human")
    }
    else if(input$database == "EBI Complex Portal"){ 
      selectInput(inputId = "species",
                  label = "Species",
                  choices =c("Arabidopsis thaliana", "Bos taurus", "Caenorhabditis elegans",
                             "Canis lupus familiaris", "Danio rerio", "Drosophila melanogaster",
                             "Escherichia coli K-12", "Gallus gallus", "Homo sapiens",
                             "Lymnaea stagnalis", "Mus musculus", "Oryctolagus cuniculus",
                             "Pseudomonas aeruginosa PAO1", "Rattus norvegicus", "Saccharomyces cerevisiae S288C",
                             "Schizosaccharomyces pombe 972h", "Sus scrofa", "Tetronarce californica",
                             "Torpedo marmorata", "Xenopus laevis"),
                  selected = "Homo sapiens")}
  )
  
  #2. Numeric input, appearing only if the user want to include a sifnificance threhold in one's analysis
  output$significance_level <- renderUI(
    if(input$q_values_th){
      numericInput(inputId = "significance_level", 
                   label = "Enter q value threshold", 
                   value = 0.05, 
                   step = 0.01, 
                   max = 1, 
                   min = 0)
    })
  #3. Download button for the complex table
  output$download_complex_table <- renderUI(
    if(!is.null(data$for_display)){
      downloadButton("complex_table_DH", 
                     "Download protein complex table")
    })
  #4. Input helpers 
  
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
  #5. Check how many complexes is a protein in 
  output$multiple <- renderUI({
    s <- sum(unlist(data$f_database$Subunits) == input$node_clicked)
    req(s > 1)
    actionButton(inputId = "multiple", 
                 label = paste0("Notice! This protein was found in ", s, " complexes"),
                 icon = icon("exclamation"),
                 style = "background-color: #ffd9b3")
  })
  #6. Create a "GO TO" button, sending the user to the uniprot website of protein ID selected (node)
  output$uniprot <- renderUI({
    req(input$node_clicked)
    actionButton(inputId = "uniprot", 
                 label = "Read more at Uniprot.org",
                 icon = icon("book"),
                 onclick = (paste0("window.open('https://www.uniprot.org/uniprot/",as.character(input$node_clicked),"')")))
  })
  #7. Minkowski distance p - appears if minkowski distance is selected
  output$minkowski_p <- renderUI(
    if(input$d_measure == "minkowski"){
      numericInput(inputId = "minkowski_p",
                   label = "p for Minkowski distance",
                   value = 3,
                   min = 3,
                   max = 100,
                   step = 1)})
  
  #8. Reference condition for the text summary
  output$summary_cond <- renderUI({
    req(data$x)
    sliderInput("complex_summary_reference",
                label = "Condition for the summary information",
                min = 2, 
                max = data$no_cond,
                step = 1)
  })
  #9. Reference for the summary
  output$summary_cond <- renderUI({
    req(data$no_cond)
    sliderInput(inputId = "summary_cond",
                label = "Summary condition",
                min = 2, max = data$no_cond, step = 1, value = 2)
  })
  ################ ################ ################ Download handlers ################ ################ ################
  #1. Input file with calculated statistics (table 1)
  output$input_stats_download <- downloadHandler(
    filename = paste("MSComplexR_Input_WithStats",Sys.time(),".csv",sep=""),
    content = function(file){
      write.csv(data$input_stats_merged, file, row.names = FALSE)
    },
    contentType = "text/csv"
  )
  #2. Protein complex table (table 2)
  output$complex_table_DH <- downloadHandler(
    filename = paste("Protein_complex_resutls",Sys.time(),".csv",sep=""),
    content = function(file) {
      write.csv(data$for_display, file, row.names = FALSE)
    },
    contentType = "text/csv"
  )
  #3. QC report, dependennt on data$stats:
  observeEvent(
    data$stats,
    {
      req(data$no_cond)
      data$QC_report <- generateQCreport(data$stats, no_cond = data$no_cond, no_rep = data$no_rep)
      output$QC_report <- downloadHandler(
        #For PDF output, change this to "report.pdf"
        filename = "QCreport.pdf",
        content = function(file) {
          # Copy the report file to a temporary directory before processing it, in
          # case we don't have write permissions to the current working dir (which
          # can happen when deployed).
          tempReport <- file.path(tempdir(), "QCreport.rmd")
          file.copy("QCreport.rmd", tempReport, overwrite = TRUE)
          # Set up param eters to pass to Rmd document
          params <- list(stats = data$stats, no_cond = data$no_cond, no_rep = data$no_rep, QC_report = data$QC_report)
          # Knit the document, passing in the `params` list, and eval it in a
          # child of the global environment (this isolates the code in the document
          # from the code in this app).
          rmarkdown::render(tempReport, output_file = file,
                            params = params,
                            envir = new.env(parent = globalenv()))
        }
      )
    })
  
  ################ ################ ################ DATA LOADING AND WRANGLING ################ ################ ################
  
  #1. Read in file
  output$input_file <- renderDataTable({
    expr = {
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
    }})
  observeEvent(
    input$run_QC,
    {
      if (!is.null(user_input)) {
        if(ncol(user_input)!= (1+(input$no_conditions*input$no_replicates)) & 
           ncol(user_input)!= (input$no_conditions*(input$no_replicates+1))){
          
          output$input_file <- renderDataTable({
            DT::datatable(data.frame(Error = "Incorrect number of columns! It should be equal to C*R+1 or C*(R+1)"))})
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
      }
    }
  )
  
  
  
  
  
  
  #2. Event handling - load example data set
  observeEvent(
    input$load_example,
    {
      data$file_indicator <- TRUE
      # data$user_input <- readRDS("Myo_sample_BioReps_Qvalues_MSComplexR.Rds")
       data$user_input <- read.csv("Table S2_Statistics_T-cell_cut.csv")
      # data$no_cond <- 6
      # data$no_rep <- 3
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
      
      data$no_proteins <- length(data$user_input[,1])
      #To preserve the column names a separate cbind for matrices and data frames is needed
      data$input_stats_merged <-  cbind(data$stats[[1]], do.call(what = "cbind", data$stats[2:11]))
      output$input_file <- renderDataTable({
        DT::datatable( data$input_stats_merged,
                       options = list(scrollX = TRUE),
                       caption = htmltools::tags$caption(style = "text-align: left; caption-side: initial;",
                                                         'Table 1: ', htmltools::em('User data with calculated statistics and changes in protein expression ')))
      })
    })
  
  #3. Event handling - normalize the data
  observeEvent(
    input$norm_run,
    {
      data$stats <- isolate(calculateStatistics(data = data$user_input, 
                                                no_cond = data$no_cond, 
                                                no_rep =  data$no_rep,
                                                qValues = input$statistics,
                                                normalize = input$norm_technique,
                                                design = input$design))
      #To preserve the column names a separate cbind for matrices and data frames is needed
      data$input_stats_norm_merged <-  cbind(data$stats[[1]], do.call(what = "cbind", data$stats[2:11]))
      output$input_file <- renderDataTable({
        DT::datatable(data$input_stats_norm_merged,
                      options = list(scrollX = TRUE),
                      caption = htmltools::tags$caption(style = "text-align: left; caption-side: initial;",
                                                        'Table 1: ', htmltools::em('User data with calculated statistics and changes in protein expression ')))
      })
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
  
  #2. Missing values barplot
  output$NA_barplot <- renderPlotly({
    req(data$file_indicator == TRUE)
    missingValuePlotly(data = data$stats$absolute_df,
                       no_cond = data$no_cond, 
                       no_rep = data$no_rep)
  })
  
  #3. CV distribution histogram
  output$CV_distr <- renderPlotly({
    req(data$stats)
    data$CV_distr <- CVdistrPlotly(data$stats$CV_df, 
                                   CV_cond = input$CV_reference,
                                   col = input$CV_colour)
    
    return(data$CV_distr$plot)
  })
  
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
    req(data$input_stats_merged)
    x <- log2(data$input_stats_merged[,(input$scatter_c1+1)])
    y <- log2(data$input_stats_merged[,(input$scatter_c2+1)])
    meth <- input$correlation_scatter
    corr <- round(cor(x, y, method = meth, use = "complete.obs"),3)
    plotly::plot_ly(x = x,
                    y = y,
                    type = "scatter",
                    marker = list(size = 3.5)) %>%
      plotly::layout(title = paste(paste(toupper(substr(meth, 1, 1)), substr(meth, 2, nchar(meth)), sep=""),
                                   "correlation between samples", 
                                   input$scatter_c1, 
                                   "and", 
                                   input$scatter_c2, 
                                   "-", corr, 
                                   sep =" "),
                     xaxis = list(title = paste("Sample", input$scatter_c1)),
                     yaxis = list(title = paste("Sample", input$scatter_c2))) %>%
      plotly::config(showLink = F, 
                     displaylogo = F, 
                     collaborate = F,
                     modeBarButtonsToRemove = list('sendDataToCloud',
                                                   'hoverCompareCartesian',
                                                   'hoverClosestCartesian',
                                                   'toggleSpikelines'))
  })
  
  #6. qValue distribution histogram
  output$qV_distr <- renderPlotly(
    if(data$file_indicator == TRUE){
      qValuePlot(data$stats, 
                 condition = input$qV_reference, 
                 col = input$qV_colour)}
    else{
      return(NULL)
    })
  #7. Volcano plots
  output$volcano <- renderPlotly({
    req(input$volcano_cond>=2 & !is.null(data$stats))
    volcanoPlot(data$stats, input$volcano_cond, input$volcano_th)
  })
  
  #8. PCA - take absolute values and in the function perform LOG2 transformation
  output$pca <- renderPlotly({
    req(data$stats)
    plotlyPCA(data = data$stats$absolute_df,
              no_cond = data$no_cond,
              no_rep  = data$no_rep)})
  ################ Tab 2 ################    
  #1. Main table with user complexes
  observeEvent(
    input$run_analysis,
    {
      output$user_complexes <- DT::renderDataTable({
        req(data$user_input, data$stats)
        withProgress(message = 'Analysing protein complexes in your data', value = 0, {
          if(input$database == "CORUM"){
            database <- corum_prepared
          }
          else if(input$database == "EBI Complex Portal"){
            database <- complex_portal_prepared
          }
          incProgress(0.1)
          index_vector <- which(data$stats$absolute_df[,1] %in% unique(unlist(database[database$Organism==input$species,]$Subunits)))
          data$f_stats <- lapply(data$stats, function(x) if(!is.vector(x)){return(x[index_vector,])}else{return(x[index_vector])})
          incProgress(0.1)
          data$f_database <- filterDatabase(f_data = data$f_stats$absolute_df,database = database, organism = input$species)
          data$no_complexes <- length(data$f_database[,1])                                   
          data$no_proteins_used <- length(data$f_stats$absolute_df[,1])
          incProgress(0.3)
          data$f_db_farms <- cbind(data$f_database, complexDBfarms(f_database = data$f_database, stats = data$f_stats, no_cond = data$no_cond, no_rep = data$no_rep))
          incProgress(0.4)
          #Change a vector to string for better display (subunits)
          data$for_display <- concatinateSubunits(data$f_db_farms)
        })
        #Hover labels for the table
        container <- generateColLabels(data$no_cond, database = input$database)
        req(data$for_display)
        DT::datatable(data$for_display , 
                      selection = list(mode = "single",selected = 1), 
                      height = 400,
                      filter = 'top',
                      container = container,
                      extensions = c('ColReorder','Buttons'),
                      caption = htmltools::tags$caption(
                        style = 'caption-side: top; text-align: left;',
                        'Table 2: ', htmltools::em(paste0('Protein complexes found in the input dataset',
                                                          ' (using ', data$no_proteins_used,' proteins)'))),
                      options = list(dom = 'Bfrtip',
                                     scrollX = TRUE,
                                     scrollY = TRUE,
                                     colReorder = TRUE,buttons = list('copy', 'print', list(extend = 'collection',
                                                                                            buttons = c('csv', 'excel', 'pdf'),
                                                                                            text = 'Download')),
                                     columnDefs = list(
                                       list(
                                         targets = c(6,7),
                                         render = JS(
                                           "function(data, type, row, meta) {",
                                           "return type === 'display' && data.length > 15 ?",
                                           "'<span title=\"' + data + '\">' + data.substr(0, 15) + '...</span>' : data;",
                                           "}")),
                                       list(targets = c(1,3,4,5), width = "35px"),
                                       list(targets = c(2), width = "200px",render = JS(
                                         "function(data, type, row, meta) {",
                                         "return type === 'display' && data.length > 30 ?",
                                         "'<span title=\"' + data + '\">' + data.substr(0, 30) + '...</span>' : data;",
                                         "}")))                                 
                      ))})
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
  
  #3. Multiline plot
  output$multiline_plot <- renderPlotly({
    req(data$f_database$NQS[input$user_complexes_rows_selected]>1)
    data$multiline_plot <- multilinePlot(f_db = data$f_database, 
                                         stats = data$f_stats,
                                         row = input$user_complexes_rows_selected,
                                         no_cond = data$no_cond,
                                         scale = input$multiline_scale)
    data$multiline_plot$plot
  })
  
  #4. Single subunits expression barplot
  output$expression_barplot <- renderPlotly({
    req(input$node_clicked, 
        data$f_stats)
    if(!(input$node_clicked %in% data$f_stats$absolute_df[,1])){
      return(NULL)
    }
    my_plot <- expressionBarplot(as.character(input$node_clicked), f_data = data$f_stats$absolute_df, stat_list = data$f_stats)
  })
  
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
    req(data$f_database$NQS[input$user_complexes_rows_selected]>2)
    plotComplexCorrelation(database = data$f_database,
                           row = input$user_complexes_rows_selected,
                           stats = data$f_stats,
                           cond_1 = input$Corr_C1,
                           cond_2 = input$Corr_C2)
  })
  
  #8. Complex information table
  output$complex_information <- renderDataTable({
    req(input$database, 
        input$user_complexes_rows_selected)
    if(input$database == "CORUM"){ 
      i <- input$user_complexes_rows_selected
      ComplexID <- as.character(data$f_database$ComplexID[i])
      row <- match(ComplexID, 
                   corum$ComplexID)
      complex_df <- corum[row,]
      complex_df <- complex_df %>% 
        dplyr::select(Complex_name = ComplexName, 
                      Subunits = subunits.UniProt.IDs., 
                      Subunits_gene = subunits.Gene.name., 
                      Subunits_name = subunits.Protein.name.,
                      FunCat_Description = FunCat.description,
                      Comment = Complex.comment,  
                      Disease  = Disease.comment)
      rownames(complex_df) <- "Additional complex information"
      complex_df$Subunits <- paste0("[",sapply(complex_df$Subunits, function(x) gsub(";","][",x)), "]")
      complex_df$Subunits_gene <- paste0("[",sapply(complex_df$Subunits_gene, function(x) gsub(";","][",x)), "]")
      complex_df$Subunits_name <- paste0("[",sapply(complex_df$Subunits_name, function(x) gsub(";","][",x)), "]")
      
    }
    else if(input$database == "EBI Complex Portal") {
      i <- input$user_complexes_rows_selected
      ComplexID <- as.character(data$f_database$ComplexID[i])
      row <- match(ComplexID, 
                   cp_db[,1])
                   # complex_portal[,1])
      # complex_df <- complex_portal[row,]
      complex_df <- cp_db[row,]
      complex_df <- complex_df %>% 
        dplyr::select(Complex_name = Recommended.name, 
                      Subunits_and_stoichiometry = Identifiers..and.stoichiometry..of.molecules.in.complex, 
                      Confidence = Confidence, 
                      GO_annotations = Go.Annotations,
                      Comment = Description,  
                      Disease  = Disease)
      rownames(complex_df) <- "Additional complex information"
      complex_df$Subunits <- sapply(complex_df$Subunits_and_stoichiometry, function(x) gsub("|","\r\n",x))
    }
    DT::datatable(t(complex_df),
                  options = list(scrollX = FALSE,
                                 paging = FALSE,
                                 scrollY = '50vh',
                                 selection = list(mode = "none"),
                                 deferRender = FALSE,
                                 scrollY = TRUE))
  })
  
  #9. Complex name output - 2, because you cant render the same output twice
  output$complex_name <- renderText({
    as.character(data$f_database[input$user_complexes_rows_selected,"Complex_Name"])
  })
  output$complex_name1 <- renderText({
    as.character(data$f_database[input$user_complexes_rows_selected,"Complex_Name"])
  })
  
  #10. Expression heatmap
  output$expression_heatmap <- renderPlotly({
    req(data$f_database$NQS[input$user_complexes_rows_selected]>=2)
    return(plotComplexHeatmap(names_vector = data$multiline_plot$subunits_names,
                              index_vector = data$multiline_plot$index_vector,
                              stats   = data$f_stats,
                              no_cond = data$no_cond,
                              distance_measure = input$d_measure,
                              agg_method = input$agg_method,
                              p = ifelse(test = input$d_measure == "minkowski", 
                                         yes = input$minkowski_p, 
                                         no = NULL))$heatmap)
  })
  #11. Co-expression heatmap
  output$correlation_heatmap <- renderPlotly({
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
  
  #12. Summary - barplot of changing complexes, according to set thresholds (FC, noise)
  
  output$summary_barplot <- renderPlotly({
    req(data$f_db_farms, data$no_cond)
    regulatedBarplot(f_db_farms = data$f_db_farms, no_cond = data$no_cond, FC_th = input$FC_th,noise_th = input$noise_th)
  })
  #13. Summary - top 5 table
  output$changing_table <- renderDataTable({
    req(data$f_db_farms, input$summary_cond)
    changingTable(f_db_farms = data$f_db_farms,cond = input$summary_cond, noise_th = input$noise_th)
    
  })
  #14. Summary - text
  output$summary <- renderText({
    req(data$f_db_farms, data$no_cond, data$no_rep, input$summary_cond, input$noise_th)
    complexDBsummary(data$f_db_farms, 
                     no_cond = data$no_cond, 
                     no_rep = data$no_rep, 
                     condition = input$summary_cond, 
                     noise_th = input$noise_th)})
}
