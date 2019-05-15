library(dplyr)
library(plotly)
library(networkD3)
library(data.table)
library(stringr)
library(DT)
library(MASS)
library(pracma)
library(preprocessCore)
library(limma)
library(qvalue)

################ ################ ################ Updating complex portal, preparing databases ################ ################ ################

#1. Connects to complex portal and downloads all the .tsv files with complex information
updateComplexPortal <- function(){
  if(!require("curl")){
    install.packages("curl")
  }
  url <- "ftp://ftp.ebi.ac.uk/pub/databases/intact/complex/current/complextab/"
  h <- new_handle(dirlistonly = TRUE)  
  con <- curl(url, "r", h)
  tbl <- read.table(con, stringsAsFactors = TRUE, fill = TRUE)
  close(con)
  urls <- paste0(url,tbl[1:length(tbl[,1]),1])
  files <- basename(urls)
  for (file in 1:length(urls)){
    curl_fetch_disk(url = urls[file],
                    path = files[file])
  }
}

#2. Merges all the .tsv files into one big data frame and writes it to an Rds file for quick access. (0.42s for csv and 0.02s for Rds!!!)
mergeComplexPortal <- function(filepath = getwd()){
  file_list <- list.files(filepath, 
                          pattern = ".tsv", 
                          full.names = TRUE)
  dbData <- lapply(X = file_list, 
                   function(x) read.csv(x,
                                        sep = "\t", 
                                        stringsAsFactors = TRUE))
  complex_Portal_file <- Reduce(function(x,y) {rbind(x,y)},dbData)
  saveRDS(object = complex_Portal_file,
          file = ("Complex_Portal.Rds"))
}
#3. Preparation of Complex Portal - Reorder steps to separate things first and do dplyr selection 
# as the last step
prepareComplexPortalDB <- function(RDSfilename = "Complex_Portal.Rds", 
                                   taxonomyDF = "taxonomyRDS.Rds" ){
  if(!require("dplyr")){
    install.packages("dplyr")
  }
  if(!require("stringr")){
    install.packages("stringr")
  }
  cp_db <- readRDS(RDSfilename) #"Complex_Portal.Rds"
  taxonomy <- readRDS(taxonomyDF) #"taxonomyRDS.Rds"
  cp_db$Taxonomy.identifier <- sapply(cp_db$Taxonomy.identifier, function(x) x<-taxonomy[,2][taxonomy[1]==as.character(x)])
  cp_db <- cp_db %>%
    dplyr::select(ComplexID = contains("Complex.ac"),
                  Complex_Name = Recommended.name,
                  Organism = Taxonomy.identifier,
                  NUS = Description,
                  Subunits = Identifiers..and.stoichiometry..of.molecules.in.complex,
                  GO_terms = Go.Annotations, 
                  Complex_assembly = Complex.assembly)
  list_of_accesions <- lapply(cp_db$Subunits, 
                              FUN =  function(x) gsub(pattern = "\\([[:digit:]]\\)", replacement = "", x))
  list_of_accesion_vectors <- sapply(list_of_accesions, 
                                     FUN = function(x) strsplit(x[[1]], split = "\\|"))
  list_of_accesion_vectors <- sapply(list_of_accesion_vectors, function(x) unique(x))
  NUS <- sapply(list_of_accesion_vectors, 
                FUN = function(x) length(x))
  cp_db$NUS <- NUS
  cp_db$Subunits <- list_of_accesion_vectors
  saveRDS(object = cp_db,
          file = "Complex_Portal_Prepared.Rds")
}
#4. Preparation of CORUM
prepareCorumDB <- function(RDSfilename){
  corum <- readRDS(RDSfilename)
  subunits_lists_v <- sapply(corum$subunits.UniProt.IDs., 
                             FUN = function(x) strsplit(as.character(x),";"))
  NUS <- sapply(subunits_lists_v, 
                FUN = function(x) length(x))
  corum$subunits.UniProt.IDs. <- subunits_lists_v
  corum <- cbind(corum,NUS)
  return(corum %>%
           dplyr::select(ComplexID, 
                         Complex_Name = ComplexName, 
                         Organism,
                         NUS, 
                         Subunits = subunits.UniProt.IDs.,
                         GO_terms = GO.ID,
                         PubMed.ID))
}
#4. Preparation of user defined database
prepareUserDB <- function(csvFilePath){
  db <- read.csv(csvFilePath, header = TRUE)
  subunits_lists_v <- sapply(db$Subunits, 
                             FUN = function(x) strsplit(as.character(x),";"))
  NUS <- sapply(subunits_lists_v, 
                FUN = function(x) length(x))
  db$Subunits <- subunits_lists_v
  db <- cbind(db,NUS)
  return(db %>%
           dplyr::select(ComplexID, 
                         Complex_Name, 
                         Organism,
                         NUS,
                         Subunits,
                         GO_terms,
                         Comment))
}

################ ################ ################ DATA WRANGLING ################ ################ ################
#1. Renaming and sorting the columns + transform to absolute intensities 
renameAndSort <- function(data, 
                          no_cond, 
                          no_rep, 
                          log2 = TRUE, 
                          grouped = FALSE, 
                          qValues = TRUE){
  #Mixedsort is able to sort Samples like C1, C2, C11 (instead of putting it to C1 C11 C2)
  if(!require("gtools")){
    install.packages("gtools")
  }
  columns <- no_cond*no_rep+1 #Without q values
  columns_full <- columns+no_cond-1
  if(log2){
    data[,2:columns] <- 2^data[,2:columns]
  }
  column_names <- vector(mode = "character", 
                         length = columns-1) #Only Columns besides Protein
  if(grouped){
    for(x in 1:no_cond){
      column_names[(((x-1)*no_rep)+1):(x*no_rep)] <- paste(paste("C",x, sep = ""),1:no_rep, sep = "_")
    }
  }
  else{
    for(x in 1:no_rep){
      column_names[(((x-1)*no_cond)+1):(x*no_cond)] <- paste(paste("C",1:no_cond,sep = ""),x, sep = "_")
    }
  }
  if(qValues){
    if (ncol(data) < columns_full) 
      return(NULL)
    column_names_final <- c("ProteinID", column_names, paste("qValue C", 2:no_cond, sep = ""))
    colnames(data) <- column_names_final
    data <- data[,c("ProteinID",mixedsort(colnames(data)[2:columns]),colnames(data)[(columns+1):columns_full])]
  }
  else{
    column_names_final <- c("ProteinID", column_names)
    colnames(data) <- column_names_final
    data <- data[,c("ProteinID", mixedsort(colnames(data)[2:columns]))]
  }
  return(data)
}
#2 Normalization - total intensity, mean, median, quantile - to be used within a different function, works with numeric data
normalize <- function(data_num, no_cond, no_rep, method = c("TotalIntensity", "Mean", "Median", "Quantile")){
  if(!require("preprocessCore")){
    install.packages("preprocessCore")
  }
  #Initiate df
  normalized_values <- as.matrix(data_num)
  normalized_values[normalized_values == 0] <- NA
  if (method == "Total Intensity"){
    totals<- colSums(normalized_values, na.rm = TRUE)
    normalized_values <- data.frame(apply(normalized_values, 2, function(x) (x/sum(x, na.rm = TRUE))*mean(totals)))
  }
  else if(method == "Mean"){
    totals <- colSums(normalized_values, na.rm = TRUE)
    normalized_values <- data.frame(apply(normalized_values, 2, function(x) (x/mean(x, na.rm = TRUE)*mean(totals))))
  }
  else if(method == "Median"){
    totals <- colSums(normalized_values, na.rm = TRUE)
    normalized_values <- data.frame(apply(normalized_values, 2, function(x) (x/median(x, na.rm = TRUE)*median(totals))))
  }
  else if(method == "Quantile"){
    #Normalize within conditions
    for(x in 1:no_cond){
      normalized_values[,((x-1)*no_rep+1):(x*no_rep)] <- normalize.quantiles(normalized_values[,((x-1)*no_rep+1):(x*no_rep)])
    }
    #Normalize total intensity
    totals<- colSums(normalized_values, na.rm = TRUE)
    normalized_values <- data.frame(apply(normalized_values, 2, function(x) (x/sum(x, na.rm = TRUE))*mean(totals)))
  }
  colnames(normalized_values) <- colnames(data_num)
  return(normalized_values)
}
#3. Z-score standarization
zScoreNormalization <- function(numeric_vector){
  normalized <- (numeric_vector-mean(numeric_vector))/sd(numeric_vector)
  return(normalized)
}
#4. Implementation of unpaired LIMMA test for grouped replicates
limma_unpaired <- function(data, no_cond, no_rep, reference = 1){
  if(!require("limma")){
    install.packages("limma")
  }
  if(!require("qvalue")){
    install.packages("qvalue")
  }
  data_num <- log2(data[,2:(no_cond*no_rep+1)])
  data_num[(data_num)==(-Inf)]<-NA
  rownames(data_num) <- data[,1]
  samples <- rep(1:no_cond,each = no_rep)
  design <- model.matrix(~0+factor(samples-1))
  colnames(design) <- paste0("C", 1:no_cond)
  contrasts<-NULL
  for (condition in (1:no_cond)[-reference]){ 
    contrasts<-append(contrasts,paste(colnames(design)[condition],"-",colnames(design)[reference],sep=""))
  }
  contrast.matrix<- limma::makeContrasts(contrasts=contrasts,levels=design)
  lm.fitted <- lmFit(data_num,design)
  lm.contr <- contrasts.fit(lm.fitted,contrast.matrix)
  lm.bayes<-eBayes(lm.contr)
  pvalues <- lm.bayes$p.value
  qlvalues <- matrix(NA,nrow=nrow(pvalues),ncol=ncol(pvalues),dimnames=dimnames(pvalues))
  for (i in 1:ncol(pvalues)) {
    tqs <- qvalue::qvalue(na.omit(pvalues[,i]))$qvalues
    qlvalues[names(tqs),i] <- tqs
  }
  return(qlvalues)
}
#5. Implementation of paired LIMMA test for grouped replicates
limma_paired <- function(data,no_cond,no_rep) {
  no_samples <- no_cond*no_rep
  data_num <- data[,2:(no_cond*no_rep+1)]
  data_num <- log2(data[,2:(no_cond*no_rep+1)])
  data_num[(data_num)==(-Inf)]<-NA
  rownames(data_num) <- data[,1]
  ratios_df <- matrix(nrow = length(data[,1]))
  for (x in 1:no_rep){
    indexes <- seq(x,(no_samples - no_rep + x), by = no_rep)
    ratios_df <- cbind(ratios_df, data_num[,indexes[-1]]-data_num[,indexes[1]])
  }
  ratios_df <- ratios_df[,-1]
  rownames(ratios_df)<-rownames(data)
  des  <-rep(1:(no_cond-1),no_rep)
  #limma with ratios
  design<-pvalues<-NULL
  for (c in (1:(no_cond-1))) {
    design<-cbind(design,as.numeric(des==c))
  }
  lm.fittedMA <- lmFit(ratios_df,design)
  lm.bayesMA<-eBayes(lm.fittedMA)
  pvalues <- lm.bayesMA$p.value
  qvalues <- matrix(NA,nrow=nrow(pvalues),ncol=ncol(pvalues),dimnames=dimnames(pvalues))
  # qvalue correction
  for (i in 1:ncol(pvalues)) {
    tqs <- qvalue(na.omit(pvalues[,i]))$qvalues
    qvalues[names(tqs),i] <- tqs
  }
  return(qvalues)
}

#6. Calculating statistics - Intensity, Log2(I), SD, CV, Ratio, FC, log(Ratio), Qvalues
# Include calls for calculating qvalues and normalisation
calculateStatistics <- function(data, no_cond, no_rep, qValues = TRUE, 
                                normalize = c(NULL,"Total Intensity", "Mean", "Median", "Quantile"), design = c(NULL, "paired", "unpaired")){
  columns <- no_cond * no_rep + 1
  absolute_df <- data[,2:columns]
  absolute_df[absolute_df == 0] <- NA
  # rename cells with empty protein ids
  data[is.na(data[,1]),1] <- "No ID"
  data[data[,1] == "",1] <- "No ID"
  ProteinID <- data[,1]
  log2_absolute_df <- log2(absolute_df)
  log2_absolute_df <- as.matrix(log2_absolute_df)
  log2_absolute_df[(log2_absolute_df)==(-Inf)]<-NA
  colnames(log2_absolute_df) <- paste0("Log2(Int) ", colnames(absolute_df[,]))
  #qValues provided, no normalization
  if(qValues & is.null(normalize)){
    qValue_df <- data[,c(-(1:columns))]
  }
  #Calculate qValues, no normalization
  if(!qValues & is.null(normalize)){
    if(design == "unpaired"){
      qValue_df <- limma_unpaired(data, no_cond, no_rep, reference = 1)
    }
    else{
      qValue_df <- limma_paired(data, no_cond, no_rep)
    }
    colnames(qValue_df) <- paste("qValue C", 2:no_cond, sep = "")
  }
  #WILL NEED TO INCLUDE THE DESIGN HERE AS ANOTHER BRANCHING
  if(!is.null(normalize)){
    absolute_df <- normalize(absolute_df, no_cond, no_rep, normalize)
    data[,-1] <- absolute_df
    if(design == "unpaired"){
      qValue_df <- limma_unpaired(data, no_cond, no_rep, reference = 1)
    }
    else{
      qValue_df <- limma_paired(data, no_cond, no_rep)
    }
    colnames(qValue_df) <- paste("qValue C", 2:no_cond, sep = "")
  }
  #Initialize empty matrixes for faster calculations. Do not keep protein IDs in them!
  sd_df <- matrix(nrow = length(ProteinID), ncol = no_cond)
  cv_df <- sd_df
  means_df <- cv_df
  log2_means_df <- means_df
  ratios_df <- as.matrix(means_df[,-1])     #Ratios matrix is one column shorter than means
  FC_df <- ratios_df
  #SD
  for (condition in 0:(no_cond-1)){
    start <- condition*no_rep+1
    stop  <- start+no_rep-1
    sd_df[,condition+1] <- apply(absolute_df, 1, function(x) sd(x[start:stop],na.rm = TRUE))
  }
  colnames(sd_df)[1:no_cond] <- paste("Condition",c(1:(no_cond)),"SD", sep = "_")
  #Means
  for (condition in 0:(no_cond-1)){
    start <- condition*no_rep+1
    stop  <- start+no_rep-1
    means_df[,condition+1] <- apply(absolute_df, 1, function(x) mean(x[start:stop],na.rm = TRUE))
  }
  colnames(means_df)[1:no_cond]  <- paste("Mean intensity C",(1:(no_cond)), sep = "")
  #CVs 
  cv_df <- (sd_df/means_df)*100
  colnames(cv_df)[1:no_cond] <- paste("Condition",c(1:(no_cond)),"CV", sep = "_")
  #Log2 means 
  log2_means_df <- log2(means_df)
  colnames(log2_means_df)[1:no_cond] <- paste("Log2 intensity C",c(1:(no_cond)), sep = "")
  #zScores
  zScore_normalized <- t(apply(log2_means_df, 1, function(x) (x-mean(x))/sd(x)))
  colnames(zScore_normalized) <- paste("Z-Score C",1:no_cond,sep="")
  #Ratios - create a DF with 1 less column than previos ones
  for (ratio in 1:(no_cond-1)){
    ratios_df[,ratio] <- means_df[,(ratio+1)]/means_df[,1]
  }
  ratios_df <- round(x = ratios_df, digits = 3)
  colnames(ratios_df) <- paste("Ratio C",2:no_cond,"/C1",sep="")
  #Fold changes
  FC_df <- apply(ratios_df, c(1,2), function(x) ifelse(x >= 1, yes = x, no = (-1/x)))
  FC_df <- as.matrix(FC_df)
  colnames(FC_df) <- paste("Fold change C",2:no_cond,"/C1",sep="")
  #Log2 ratios
  log2_ratios <- log2(ratios_df)
  colnames(log2_ratios) <- paste("Log2(ratio) C", 2:no_cond,"/C1",sep="")
  absolute_df <- cbind(ProteinID, round(absolute_df,3))
  colnames(absolute_df)[1] <- "ProteinID"
  return(list(absolute_df = absolute_df,
              log2_absolute_df =round(log2_absolute_df, 2),
              means_df = signif(means_df, 4),
              SD_df = signif(sd_df,3), 
              CV_df = signif(cv_df,4),
              qValue_df= apply(qValue_df, c(1,2),function(x) ifelse(x<0.00001, yes = 0.00001, no = round(x,5))),
              log2_means= round(log2_means_df,3), 
              zScore= round(zScore_normalized,3),
              ratios = round(as.matrix(ratios_df),3),
              FC_df = round(as.matrix(FC_df), 3),
              log2_ratios = round(log2_ratios, 3)))
}
#7. Filtering the data according to species and proteins present in complexes
filterData <- function(data, database, organism){
  database <- database %>%
    filter(Organism == organism)
  unique_accesions <- as.character(unique(unlist(database$Subunits)))
  filtered_data <- data %>%
    filter(ProteinID %in% unique_accesions)
  return(filtered_data)
}

#8. Filtering the database according to the proteins found adding scores
filterDatabase <- function(f_data, database, organism){
  if(!require("dplyr")){
    install.packages("dplyr")
  }
  #Filter for species
  database <- database %>%
    filter(Organism == organism)
  #Get indexes of rows to keep
  indicator_v <- sapply(database$Subunits, function(x) sum(x %in% f_data[,1]))
  logic_v <- indicator_v > 0
  database <- database[logic_v,]
  if (nrow(database) > 0)  {
    rownames(database) <- 1:length(database[,1])
    #Number of quantified subunits
    NQS <- sapply(database$Subunits, function(x) sum(x %in% f_data[,1]))
    Coverage <- (NQS/database$NUS)*100
    database <- cbind(database,NQS, Coverage = round(Coverage, 2))
    database <- database[,c(1,2,4, 8, 9,5:7)]
    return(database)
  } else {
    return(NULL)
  }
}

#9. Quality report
generateQCreport <- function(stats, no_cond, no_rep){
  #Decide for the amount of rows/columns in R plots for the QC report
  if(no_cond == 2){
    r = 1
    c = 2
  }
  else if(no_cond == 3){
    r = 1
    c = 3
  }
  else if(no_cond == 4){
    r = 2
    c = 2
  }
  else if(no_cond >4 & no_cond%%3!=0){
    c = 3
    r = no_cond%/%3+1
  }
  else{
    c = 3
    r = no_cond%/%3
  }
  # Tables - log2 values
  VAL_min <- sapply(1:no_cond, function(x) min(stats$log2_means[,x], na.rm = TRUE))
  VAL_mean <- sapply(1:no_cond, function(x) mean(stats$log2_means[,x], na.rm = TRUE))
  VAL_med <- sapply(1:no_cond, function(x) median(stats$log2_means[,x], na.rm = TRUE))
  VAL_max <- sapply(1:no_cond, function(x) max(stats$log2_means[,x], na.rm = TRUE))
  VAL_table <- rbind(VAL_min, VAL_mean, VAL_med, VAL_max)
  VAL_table <- round(VAL_table, 3)
  colnames(VAL_table) <- paste0("Cond. ", 1:no_cond)
  rownames(VAL_table) <- c("Min", "Mean", "Median", "Max")
  #CV
  CV_min <- sapply(1:no_cond, function(x) min(stats$CV_df[,x], na.rm = TRUE))
  CV_mean <- sapply(1:no_cond, function(x) mean(stats$CV_df[,x], na.rm = TRUE))
  CV_med <- sapply(1:no_cond, function(x) median(stats$CV_df[,x], na.rm = TRUE))
  CV_max <- sapply(1:no_cond, function(x) max(stats$CV_df[,x], na.rm = TRUE))
  CV_table <- rbind(CV_min, CV_mean, CV_med, CV_max)
  CV_table <- round(CV_table, 3)
  colnames(CV_table) <- paste0("Cond. ", 1:no_cond)
  rownames(CV_table) <- c("Min", "Mean", "Median", "Max")
  #qValues
  qValue_min <- sapply(1:(no_cond-1), function(x) min(stats$qValue_df[,x], na.rm = TRUE))
  qValue_mean <- sapply(1:(no_cond-1), function(x) mean(stats$qValue_df[,x], na.rm = TRUE))
  qValue_med <- sapply(1:(no_cond-1), function(x) median(stats$qValue_df[,x], na.rm = TRUE))
  qValue_max <- sapply(1:(no_cond-1), function(x) max(stats$qValue_df[,x], na.rm = TRUE))
  qValue_table <- rbind(qValue_min, qValue_mean, qValue_med, qValue_max)
  qValue_table <- round(qValue_table, 4)
  colnames(qValue_table) <- paste0("qValue C", 2:no_cond, "/C1")
  rownames(qValue_table) <- c("Min", "Mean", "Median", "Max")
  #Fold changes
  FC_min <- sapply(1:(no_cond-1), function(x) min(stats$FC_df[,x], na.rm = TRUE))
  FC_mean <- sapply(1:(no_cond-1), function(x) mean(stats$FC_df[,x], na.rm = TRUE))
  FC_med <- sapply(1:(no_cond-1), function(x) median(stats$FC_df[,x], na.rm = TRUE))
  FC_max <- sapply(1:(no_cond-1), function(x) max(stats$FC_df[,x], na.rm = TRUE))
  FC_table <- rbind(FC_min, FC_mean, FC_med, FC_max)
  FC_table <- round(FC_table, 3)
  colnames(FC_table) <- paste0("FC C", 2:no_cond, "/C1")
  rownames(FC_table) <- c("Min", "Mean", "Median", "Max")
  return(list(r = r, c = c, VAL_t= VAL_table, CV_t = CV_table, fc_t = FC_table, qValue_t = qValue_table))
}

################ ################ ################ DATA VISUALIZATION - QC ################ ################ ################

#1 Interactive boxplots
distrPlotlyBox <- function(data, no_rep, no_cond){
  if(!require(reshape2)){
    return(NULL)
  }
  if(!require(plotly)){
    return(NULL)
  }
  #Read only protein IDs and intensities
  data <- data[,1:(no_rep*no_cond+1)]
  data[,-1] <- log2(data[,-1])
  #Initialize the vector for sample column names
  columns <- colnames(data[,2:(no_cond*no_rep+1)])
  melted_data <- reshape2::melt(data, na.rm = TRUE)
  melted_data <- cbind(melted_data, 
                       colsplit(melted_data$variable, 
                                pattern = "_", 
                                names = c("Condition", "Replicate")))
  colnames(melted_data) <- c("ProteinID", 
                             "Sample",
                             "Intensity",
                             "Condition",
                             "Replicate")
  return(list( plot = plotly::plot_ly(data = melted_data, 
                                      type = "box", 
                                      y = ~Intensity, 
                                      x = ~Sample, 
                                      color = ~Condition,
                                      height = 500) %>%
                 plotly::layout(title = "Data distribution - log2(Intensity)",
                                hovermode = "x") %>%
                 plotly::config(showLink = F, 
                                displaylogo = F, 
                                collaborate = F,
                                modeBarButtonsToRemove = list('sendDataToCloud',
                                                              'hoverCompareCartesian',
                                                              'hoverClosestCartesian',
                                                              'toggleSpikelines'))))
  
}

#2. Barplot with information about missing values
missingValuePlotly <- function(data, no_cond, no_rep){
  data <- data[,2:(no_cond*no_rep+1)]
  no_na_column <- colSums(is.na(data))
  barplot_df <- data.frame(no_NA = unlist(no_na_column), sample = colnames(data))
  total_na <- sum(no_na_column)
  all <- dim(data)[1] * dim(data)[2]
  return(plotly::plot_ly(x = ~barplot_df$sample, 
                         y = ~barplot_df$no_NA,
                         type = "bar",
                         color = ~barplot_df$sample,
                         text = barplot_df$no_NA,
                         textposition = 'outside',
                         marker = list(line = list(color = '#000000', width = 1))) %>%
           plotly::layout(yaxis = list(title = "Number of missing values"),
                          xaxis = list(title = "Sample"),
                          hovermode = "x",
                          title = paste0("Number of missing values in each sample (", total_na, " in total out of ", all," - ",round(total_na/all*100,2),"[%])")) %>%
           plotly::config(showLink = F, 
                          displaylogo = F, 
                          collaborate = F,
                          modeBarButtonsToRemove = list('sendDataToCloud',
                                                        'hoverCompareCartesian',
                                                        'hoverClosestCartesian',
                                                        'toggleSpikelines')))
}

#3. q Value vs no. significant features plot
qValuePlot <- function(stats, condition, col){
  q_values <- seq(0,0.1,0.001)
  no_features <- q_values
  for(x in 1:101){
    no_features[x] <- sum(stats$qValue_df[,condition-1]<q_values[x])
  }
  print(no_features)
  p <- plotly::plot_ly(x = q_values, 
                       y = (no_features),
                       type = "scatter",
                       mode = "lines+markers",
                       line = list(color = col),
                       marker = list(size = 4, color = col)) 
  p <-   plotly::layout(p , title = "Significant features analysis",
                        xaxis = list(title = "Statistical value threshold"),
                        yaxis = list(title = "Number of significant features"))
  return(p)
}

#4. CV distribution - histogram
CVdistrPlotly <- function(stats_CV_DF, CV_cond, col){
  column_number <- CV_cond #There is no CV_cond = 1, starts from 2.
  values <- stats_CV_DF[,column_number]
  meanV <- mean(values, na.rm = TRUE)
  medianV <- median(values, na.rm = TRUE)
  p <- plotly::plot_ly(x = ~values, 
                       type = "histogram",
                       histnorm = "probability", 
                       marker = list(line = list(color = '#000000', width = 0.5), color = col)) %>%
    plotly::layout(yaxis = list(title = "Relative frequency"),
                   xaxis = list(title = "Coefficient of variation [%]"),
                   title = paste0("CV distribution - condition ", CV_cond)) %>%
    plotly::config(showLink = F, 
                   displaylogo = F, 
                   collaborate = F,
                   modeBarButtonsToRemove = list('sendDataToCloud',
                                                 'hoverCompareCartesian',
                                                 'hoverClosestCartesian',
                                                 'toggleSpikelines'))
  return(list(plot = p, mean = meanV, median = medianV))
}

#5. Volcano plots
volcanoPlot <- function(stats, cond, qValue_cutoff){
  log2ratio <- round(stats$log2_ratios[,cond-1],3)
  qValues <- stats$qValue_df[,cond-1]
  labels <- stats$absolute_df[,1]
  #Take only valid qValues
  valid_indexes <- !is.na(qValues)
  log2ratio <- log2ratio[valid_indexes]
  qValues <- qValues[valid_indexes]
  labels <- labels[valid_indexes]
  grouping <- log2ratio
  grouping <- sapply(1:length(grouping), function(x) if(qValues[x]<qValue_cutoff){return ("Significant")} 
                     else{return("Not significant")})
  qValues <- round(-log10(qValues),3)
  plotly::plot_ly(x = log2ratio,
                  y = qValues,
                  text = labels,
                  color = grouping,
                  colors = c("#222d32", "#428bca"),
                  type = "scatter",
                  marker = list(size = 3.5))%>%
    plotly::layout(legend = list(orientation = 'h', xanchor = "center", y =1.1,x=0.5, font = list(size = 20)),
                   xaxis = list(title = paste0("Log2(C", cond, "/C1)")),
                   yaxis = list(title = paste0("-Log10(qValue (C", cond, "/C1))"))) %>%
    plotly::config(showLink = F, 
                   displaylogo = F, 
                   collaborate = F,
                   modeBarButtonsToRemove = list('sendDataToCloud',
                                                 'hoverCompareCartesian',
                                                 'hoverClosestCartesian',
                                                 'toggleSpikelines'))
}

#6. PCA - first two compnents 
plotlyPCA <- function(data, no_cond, no_rep){
  rownames(data) <- data[,1]
  samples <- colnames(data[,2:(no_cond*no_rep+1)])
  data <- data[,2:(no_cond*no_rep+1)]
  data <- log2(data)
  data[data==-Inf] <- NA
  condition_factors <- paste("C",rep(1:no_cond, each = no_rep), sep = "")
  pca <- prcomp(stats::na.omit(data), scale = TRUE, retx = TRUE)
  pca$rotation <- data.frame(pca$rotation, Condition = condition_factors, Sample = samples)
  return(plotly::plot_ly(x = round(as.numeric(pca$rotation[,1]),3), 
                         y = round(as.numeric(pca$rotation[,2]),3),
                         color = pca$rotation[,(length(pca$rotation[1,])-1)],
                         text = pca$rotation[,length(pca$rotation[1,])],
                         type = "scatter") %>%
           plotly::layout(title = "Principal Component Analysis",
                          xaxis = list(title = paste("Component 1 -", round(pca$sdev[1]^2/(sum(pca$sdev^2)), 2),"[%]")),
                          yaxis = list(title = paste("Component 2 -", round(pca$sdev[2]^2/(sum(pca$sdev^2)), 2),"[%]"))) %>%
           plotly::config(showLink = F, 
                          displaylogo = F, 
                          collaborate = F,
                          modeBarButtonsToRemove = list('sendDataToCloud',
                                                        'hoverCompareCartesian',
                                                        'hoverClosestCartesian',
                                                        'toggleSpikelines')))
}

################ ################ ################ PROTEIN COMPLEX ANALYSIS ################ ################ ################ 

#1. Complex star graph. 
plotD3complexGraph <- function(stats, f_db, row, condition, q_threshold, fc_threhold){
  #Get subunit names
  subunits <- f_db$Subunits[[row]]
  #Create a color dictionary
  colours <- matrix(ncol = 6, nrow = 1)
  colnames(colours) <- c("Complex", "Downregulated", "Upregulated", "Not quantified", "Not changing", "NA")
  colours[1,] <- c("#9ea4d1", "#e22200", "#25d14a", "#afafaf", "#428bca", "#f83581")
  no_subunits <- length(f_db$Subunits[[row]])
  node_names <- c(as.character(f_db$Complex_Name[row]), subunits)
  fc_vector <- vector(mode = 'numeric', length = no_subunits)
  qValue_vector <- vector(mode = 'numeric', length = no_subunits)
  #Get indexes of subunits in the filtered input dataset
  index_vector <- vector(mode = 'numeric', length = no_subunits)
  proteinIDs <- as.character(stats$absolute_df$ProteinID)
  # ensure that stats$FC_df is matrix
  stats$FC_df <- as.matrix(stats$FC_df)
  #Fill in the links characteristics                         
  for (subunit in 1:no_subunits){
    subunit_name <- subunits[subunit]
    if(subunit_name %in% proteinIDs){
      index_vector[subunit] <- match(subunit_name, proteinIDs)
      fc_vector[subunit] <- (stats$FC_df[index_vector[subunit],(condition-1)])
      #Cover the fact that qValue_df may be a vector if no_cond = 2
      if(!is.vector(stats$qValue_df)){
        qValue_vector[subunit] <- stats$qValue_df[index_vector[subunit],(condition-1)]
      }
      else{
        qValue_vector[subunit] <- (stats$qValue_df[index_vector[subunit]])
      }
    }
    else{
      index_vector[subunit] <- 0
      fc_vector[subunit] <- 0
      qValue_vector[subunit] <- 1 
    }
  }
  links <- data.frame(source = 1:no_subunits, target = 0, value = qValue_vector)
  #Change fold changes into grouping - 
  node_grouping <- c("Complex", sapply(fc_vector, 
                                       function(x) ifelse(is.na(x), yes = "NA", 
                                                          no = ifelse(x < -fc_threhold, yes = "Downregulated" ,
                                                                      no = ifelse(x == 0, yes = "Not quantified", 
                                                                                  no = ifelse(x > fc_threhold, yes = "Upregulated", no = "Not changing"))))))
  #Adjusting colour order
  exp_order <- unique(node_grouping)
  colour_order <- NULL
  for(x in exp_order){
    colour_order <- c(colour_order, colours[1,x])
  }
  #function to provide coloring in the correct order (of appearence)
  colour_js <- paste(paste('d3.scaleOrdinal(["',paste(colour_order, collapse = '","'), '"])'), collapse = "")
  node_sizes <- c(80, 50*abs(fc_vector))
  nodes <- data.frame(name = node_names, group = node_grouping, size = node_sizes)
  return(list(star_graph = forceNetwork(Links = links, Nodes = nodes,
                                        Source = "source", Target = "target",
                                        Value = "value", NodeID = "name",
                                        Group = "group", Nodesize = "size", zoom = FALSE, legend = TRUE, 
                                        linkDistance = JS(paste('function(d) { if(d.value <', q_threshold, '){ return 100} else { return(70)}}', collapse = "")),
                                        linkWidth = JS(paste('function(d) { if(d.value <', q_threshold, '){ return 3} else { return(1)}}', collapse = "")),
                                        colourScale = colour_js,
                                        clickAction = 'Shiny.onInputChange("node_clicked", d.name)',
                                        fontSize = 32, 
                                        bounded = TRUE), subunit_indexes = index_vector, qValues = qValue_vector))
}

#2. Barplot for 1 protein (subunit) expression levels among samples, showing upon selecting a node
expressionBarplot <- function(proteinID, f_data, stat_list){
  if(!(proteinID %in% f_data$ProteinID)){
    return(NULL)
  }
  index <- match(x = proteinID, 
                 table = f_data$ProteinID)
  means <- stat_list$means_df[index,]
  SDs <- stat_list$SD_df[index,]
  no_conditions <- length(means)
  bar_labels <- paste("C",1:no_conditions,"")
  df <- data.frame(x = bar_labels, 
                   y = means, 
                   sd = SDs)
  #p for plot
  p <- plot_ly(data = df,
               x = ~x,
               y = ~y, 
               color = ~x,
               error_y = list(array = ~sd, color = '#000000'),
               type = "bar",
               marker = list(line = list(color = '#000000', width = 1))) %>%
    plotly::layout(title = paste("Expression of", proteinID, "protein", collapse = " "),
                   yaxis = list(title = "Absolute intensity", 
                                exponentformat  = "E",
                                showticklabels = TRUE,
                                tickfont  = list (family = "Arial, sans-serif",
                                                  size = 10.5,
                                                  color = "black")),
                   xaxis = list(title = "Condition"), 
                   showlegend = FALSE) %>%
    #Adjusting icons 
    plotly::config(showLink = F, 
                   displaylogo = F, 
                   collaborate = F,
                   modeBarButtonsToRemove = list('sendDataToCloud',
                                                 'hoverCompareCartesian',
                                                 'hoverClosestCartesian',
                                                 'toggleSpikelines'))
  return(p)
}


#3. Complex subunits expression multiline plot
multilinePlot <- function(f_db, stats, row, no_cond, scale = c("Log2 Intensity", "zScore")){
  
  complex_name <- f_db$Complex_Name[row]
  subunits <- f_db$Subunits[[row]]
  protein_list <- stats$absolute_df[,1]
  is_in_input <- subunits %in% protein_list
  present_subunits <- subunits[is_in_input]
  no_subunits <- length(present_subunits)

  x_sequence <- 1:no_cond
  
  mx <- data.frame(matrix(nrow = length(x_sequence), ncol = no_subunits))
  
  index_vector <- vector(mode = "numeric", length = no_subunits)
  
  for (protein in 1:no_subunits){
    
    index_vector[protein] <- match(present_subunits[protein], protein_list)
    if(scale == "zScore"){
      
      mx[,protein] <- unlist(stats$zScore[index_vector[protein],])
      
    }
    else if(scale == "Log2 Intensity"){
      
      mx[,protein] <- unlist(stats$log2_means[index_vector[protein],])
      mx[,protein] <- mx[,protein] - mean(mx[,protein], na.rm = TRUE)
      
    }
  }
  
  colnames(mx) <- present_subunits

  p <- plot_ly(x = x_sequence,
               y = mx[,1],
               type = "scatter", 
               mode = "lines+markers", 
               name = present_subunits[1]) %>%
  plotly::layout(title = complex_name,  
                   yaxis = list(title = scale), 
                   xaxis = list(title = "Condition")) %>%
  plotly::config(showLink = F, 
                   displaylogo = F, 
                   collaborate = F,
                   modeBarButtonsToRemove = list('sendDataToCloud',
                                                 'hoverCompareCartesian',
                                                 'hoverClosestCartesian',
                                                 'toggleSpikelines'))
  
  for(protein in 2:no_subunits){
    
    p <- add_trace(p, x = x_sequence, y = mx[,protein], type = "scatter", mode = "lines+markers", name = present_subunits[protein])
    
  }
  
  return(list(plot = p, subunits_names = present_subunits, index_vector = index_vector))
  
}

#4. Small helper - Collapse a vector to a string for better visualization in the DT cell in shiny
concatinateSubunits <- function(filtered_database){
  filtered_database$Subunits <- sapply(filtered_database$Subunits, function(x) paste(x, collapse = ", "))
  return(filtered_database)
}

#5. Log2(R), mean normalized (row-wise) heat map with custom colour palette
plotComplexHeatmap <- function(names_vector, index_vector, stats, no_cond, distance_measure, agg_method, p=2){
  expr_array <- stats$log2_means[index_vector,,drop=F]
  expr_array[is.na(expr_array)] <- 0
  norm_expr_array <- round(t(apply(expr_array, 1, function(x) x-mean(x, na.rm = TRUE))),4)
  if (length(expr_array)>0) {
    rownames(norm_expr_array) <- names_vector
    colnames(norm_expr_array) <- paste0("Norm. log2(R) C", 1:no_cond)
    if(distance_measure != "minkowski"){
      return(list(heatmap = heatmaply::heatmaply(norm_expr_array, 
                                                 dist_method = distance_measure, 
                                                 hclust_method = agg_method,
                                                 Colv = FALSE,
                                                 xlab = "Condition",
                                                 ylab = "ProteinID",
                                                 main = "Protein expression heatmap - normalized mean log2 intensities",
                                                 fontsize_row = 6,
                                                 fontsize_col = 6,
                                                 margins = c(80,80,NA,0),
                                                 col = cool_warm), expr_array = expr_array
      ))
    }
    else{
      row_dend  <- expr_array %>% 
        dist(method = "minkowski", p = p) %>% 
        hclust %>% as.dendrogram
      return(list(heatmap = heatmaply::heatmaply(norm_expr_array, 
                                                 hclust_method = agg_method,
                                                 Colv = FALSE,
                                                 Rowv = row_dend,
                                                 xlab = "Condition",
                                                 ylab = "ProteinID",
                                                 main = "Protein expression heatmap - normalized mean log2 intensities",
                                                 fontsize_row = 6,
                                                 fontsize_col = 6,
                                                 margins = c(80,80,NA,0),
                                                 col = cool_warm, expr_array = expr_array)))
    }
  }
}

#6. Heatmap of correlation (co-expression) between subunits of 1 selected complex
plotCorrelationHeatmap <- function(names_vector, index_vector, stats, correlation_measure, distance_measure, agg_method, p=2){
  means_array <- stats$log2_means[index_vector,]
  means_array <- round(t(apply(means_array, 1, function(x) x-mean(x, na.rm = TRUE))),4)
  rownames(means_array) <- names_vector
  colnames(means_array) <- sapply(colnames(means_array), 
                                  FUN = function(x) gsub("intensity", "", x))
  #Introduce variance
  for(row in 1:length(means_array[,1])){
    if(length(unique(means_array[row,]))==1){
      means_array[row,1] <- means_array[row,1]+0.0001
    }
  }
  means_array <- t(means_array)
  correlation_matrix <- cor(x = means_array, use="na.or.complete",
                            method = correlation_measure)
  
  if(distance_measure != "minkowski"){
    return(heatmaply_cor(x = correlation_matrix,
                         dist_method = distance_measure, 
                         hclust_method = agg_method,
                         xlab = "ProteinID",
                         ylab = "ProteinID", 
                         main = "Correlation map",
                         margins = c(80,80,50,10),
                         fontsize_row = 7,
                         fontsize_col = 6))}
  else{
    row_dend  <- correlation_matrix %>% 
      dist(method = "minkowski", p = p) %>% 
      hclust %>% as.dendrogram
    return(heatmaply_cor(x = correlation_matrix,
                         Rowv = row_dend,
                         hclust_method = agg_method,
                         xlab = "ProteinID",
                         ylab = "ProteinID", 
                         main = "Correlation map",
                         margins = c(80,80,50,10),
                         fontsize_row = 7,
                         fontsize_col = 6))
  }
}

#7. Using orthagonal distance regression to dalculate "global" change of expression of a complex - not used in current setup
calcComplexCorrelation <- function(database_row, stats, no_cond){
  if(database_row$NQS < 3){
    return(rep(NA, ((no_cond-1)*2)))
  }
  proteins <- stats$absolute_df[,1]
  subunits <- database_row$Subunits[[1]]
  present_subunits <- subunits[subunits %in% proteins]
  subunit_indexes <- sapply(present_subunits, function(x) match(x, proteins))
  means_log2 <- stats$log2_means[subunit_indexes,]
  results <- vector(mode = "numeric", length = (no_cond-1)*2)
  control <- means_log2[,1]
  for (x in 2:no_cond){
    mdl <- odregress(control, means_log2[,x]) #odregress returns a list, $coeff[1] = a, $coeff[2] = b
    #Modeling as log(y) = a*log(x) + b; if a=1, then the derrivative is = 2^b and y/x is linear. 
    b <- mean(means_log2[,x] - control)
    FC <- 2^b
    #Forcing the a = 1 we assume log(y)= log(x) + b =>y/x = 2^b, so mean b = mean(log(y) - log(x))
    #results[(2*x-3):(2*x-2)]  <- c(ifelse(slope >= 1, yes = slope, no = -1/slope), mdl$coefficients[2])
    results[(2*x-3):(2*x-2)] <- c(ifelse(FC >= 1, yes = FC, no = -1/FC), mdl$coeff[1])
  }
  return(results)
}

#8. More global function to use in order to calculate complex fold changes for all present complexes - not used in current setup
calcComplexDBCorrelations <- function(filtered_database, stats, no_cond){
  l <- length(filtered_database[,1])
  result <- round(as.data.frame(t(sapply(1:l, function(x) calcComplexCorrelation(filtered_database[x,], stats, no_cond)))),3)
  colnames(result) <- as.vector(sapply(2:no_cond, function(x) c(paste0("FC C",x), paste0("R2 C",x))))
  return(cbind(filtered_database, result))
}

#9. Plot for individual complexe and its expressions in two conditions + a LM on top. 
plotComplexCorrelation <- function(database, row,stats, cond_1, cond_2){
  subunits <- database[row,]$Subunits[[1]]
  proteins <- stats$absolute_df[,1]
  subunits <- subunits[subunits %in% proteins]
  if(length(subunits) <=1){
    return(NULL)
  }
  s_indices <- sapply(subunits, function(x) match(x, proteins))
  means1 <- stats$log2_means[s_indices, cond_1]
  means2 <- stats$log2_means[s_indices, cond_2]
  mdl <- odregress(x = means1, y=means2)
  tot <- sum((means2-mean(means2))^2)
  res <- sum(mdl$resid^2)
  r2 <- 1-res/tot
  p <- plotly::plot_ly( x = means1,
                        y = means2,
                        type = "scatter",
                        mode = "markers") %>%
    plotly::add_lines(x = means1, y = as.vector(mdl$fitted)) %>%
    plotly::layout(title = paste0(" R2 =", round(r2,4)), showlegend = FALSE, 
                   yaxis = list(title = paste0("Condition ", cond_1)),
                   xaxis = list(title = paste0("Condition ", cond_2)))%>%
    #Adjusting icons 
    plotly::config(showLink = F, 
                   displaylogo = F, 
                   collaborate = F,
                   modeBarButtonsToRemove = list('sendDataToCloud',
                                                 'hoverCompareCartesian',
                                                 'hoverClosestCartesian',
                                                 'toggleSpikelines'))
  return(p)
}
#10. Provides column labels for DT of protein complexes.
generateColLabels <- function(no_cond, database){
  colname_v <- c("No","ComplexID", "Complex_Name", "NUS", "NQS", "Coverage", "Subunits", "GO_terms", "PubMedID")
  if(database != "CORUM"){
    colname_v[9] <- "Stoichiometry"
  }
  hover_labels <- c("Row numbers", "", "", "Number of unique subunits in the complex", 
                    'Number of unique quantified subunits of the complex found in the input dataset', 'Percentage of complex subunits found in the input data set',
                    'Names of unique subunits', "GO annotation of the complex", "PubMedID of the reference paper")
  fc <- paste0("FC C", 2:no_cond,"/C1")
  noise <- "Noise"
  cols2 <- c(fc, noise)
  title2 <- c(fc, "Noise level in coexpression. Value between 0 (best) and 1 (worst). Indicates how trustworthy are the fold changes calculated. Is higher for complexes with few quantified subunits.")
  length
  final_v2 <- c(colname_v, cols2)
  title_v  <- c(hover_labels, title2)
  total_len <- length(final_v2)
  container <- htmltools::withTags(
    table(
      class = 'display',
      thead(
        tr(
          lapply(1:total_len, function(x) th(colspan = 1, 
                                             final_v2[x], 
                                             title = title_v[x],
                                             style="text-align:center"))
        ))))
  return(container)
}

#11. FARMS
#Function that performs fast farm as it is implemented in Diffacto.
fast.Farms <- function(probes, weight = 0.1 , mu = 0.1, max_iter = 1000, 
                       force_iter =  FALSE, min_noise = 0.0001, fill_nan = 0){
  readouts <- as.matrix(probes)
  readouts[is.na(readouts)] <- fill_nan
  #Normalize and transform X
  X <- t(readouts)
  X <- t(t(X) - colMeans(X, na.rm = T))
  xsd <- apply(X, 2, function(x) sd(x, na.rm = T) * sqrt((length(x) - 1) / length(x)))
  xsd[xsd < min_noise] <- 1
  X <- t(t(X)/xsd)
  X[!is.finite(X)] <- 0
  n_samples <- nrow(X)
  n_features <- ncol(X)
  C <- crossprod(X, X)/n_samples
  #Positive definite
  C <- (C+t(C))/2
  C[which(C < 0)] <- 0
  #robustness
  SVD <- svd(C)
  U <- SVD$u
  s <- SVD$d
  V <- t(SVD$v)
  s[s<min_noise] <- min_noise
  C <- U %*% diag(s) %*% V
  diag(C)[(diag(C)<0)] <- 0
  #initiation
  lamda <- sqrt(0.75*diag(C))
  psi <- diag(C) - lamda^2
  old_psi <- psi
  alpha <- weight * n_features
  E <- 1
  for(i in 1:max_iter){
    #E Step
    phi <- (1/psi)*lamda
    a <- as.vector(1+crossprod(lamda,phi))
    eta <- phi/a
    zeta <- C %*% eta
    E <- 1 - as.vector(eta) %*% lamda + as.vector(eta) %*% zeta
    #M Step
    lamda = zeta/(c(E) + as.vector(psi)*alpha)
    psi <- diag(C) - as.vector(zeta)[1] * lamda + psi * alpha * lamda * (mu - lamda)
    psi[psi < min_noise^2] <- min_noise^2
    if(!force_iter){
      if(max(abs(psi-old_psi))/max(abs(old_psi)) < min_noise/10){
        break
      }
    }
    old_psi <- psi
  }
  loading <- as.vector(sqrt(E))*lamda
  phi <- loading/psi
  weights <- loading/max(loading)
  noise <- 1/as.vector(1+crossprod(loading,phi))
  loading.noise <- list("loadings" = weights, "noise" = noise)
  return(loading.noise)
}
#12. FARMS for 1 complex
complexFCfarms <- function(f_database, stats, proteins, row, no_cond, no_rep){
  if(f_database[row,"NQS"]>=3){
    subunits <- f_database[row,]$Subunits[[1]]
    subunits <- subunits[subunits %in% proteins]
    subunits_indexes <- sapply(subunits, function(x) match(x, proteins))
    probes <- log2(stats$absolute_df[subunits_indexes,-1])
    
    #It could be also:
    #probes <- stats$log2_absolute_df[subunits_indexes,]
    
    probes[(probes)==(-Inf)]<-NA
    probes <- data.frame(t(apply(probes, 1, function(x)  
      #Introduce variance if all intensities are the same
      if(length(unique(unlist(x)))==1){
        x[1] <- x[1]*1.0001
        return(x)
      }
      else{
        return(x)
      })))
    
    FARMS <- fast.Farms(probes)
    
    #Adjusted probes should be scaled by weights sum.
    probes_adj <- (FARMS$loadings * probes)/sum(FARMS$loadings, na.rm = T)

    FC <- vector(mode = "numeric", length = no_cond-1)
    #Calculate ratio changes in reference to codition 1
    #FC <- sapply(2:(no_cond), function(x) {FC[x-1] <- mean(colSums(2^probes_adj[,((x-1)*no_rep+1):(x*no_rep)]), na.rm = TRUE)/mean(colSums(2^probes_adj[,1:no_rep]), na.rm = TRUE)})
    
    #Calculate log2 FC
    FC <- sapply(2:(no_cond), function(x) {FC[x-1] <- mean(colSums(probes_adj[,((x-1)*no_rep+1):(x*no_rep)]), na.rm = TRUE) - mean(colSums(probes_adj[,1:no_rep]), na.rm = TRUE)})
    #Turn log2 FC to FC since the input thresholds that affect star plot and bar plot, and also regulation summary are in FC scale.
    FC <- 2^FC
    
    #Transform to FC (FC = R for R>=1 or -1/R for FC < 1) 
    FC <- sapply(FC, function(x) ifelse(x>=1, yes = x, no = -1/x))
    noise <- FARMS$noise
    result <- c(FC, noise)
    names(result) <- c(paste0("FC C", 2:no_cond, "/C1"), "Noise")
    result <- round(result, 3)
    return(result)
    #### Try to figure out a way that will deal with proteins missing in all 3 replicates 
  }
  else{
    result <- rep(NA, no_cond)
    names(result) <- c(paste0("FC C", 2:no_cond, "/C1"), "Noise")
    return(result)
  }
}
#13. FARMS - for database
complexDBfarms <- function(f_database, stats, no_cond, no_rep){
  
  indexes <- 1:length(f_database[,1])
  proteins <- stats$absolute_df[,1]
  
  result_df <- t(sapply(indexes, function(x) complexFCfarms(f_database = f_database, 
                                                            stats = stats, 
                                                            row = x , 
                                                            proteins = proteins, 
                                                            no_cond = no_cond, 
                                                            no_rep = no_rep)))
  
  
  return(result_df)
}
#14. Text summary
complexDBsummary <- function(f_db_farms, no_cond, no_rep, condition, noise_th){
  n <- length(f_db_farms[,1])
  n3 <- sum(f_db_farms$NQS >=3)
  fc_col_index <- 8+condition-1
  if(noise_th != 1){
    f_db_farms <- dplyr::filter(f_db_farms, Noise <= noise_th)
  }
  fc_col <- f_db_farms[,fc_col_index]
  #Check for errors from value rouding etc. 
  max_v <- max(fc_col, na.rm = TRUE)
  max_index <- match(max_v,f_db_farms[,fc_col_index])
  max_row <- f_db_farms[max_index,]
  min_v <- min(fc_col, na.rm = TRUE)
  min_index <- match(min_v,f_db_farms[,fc_col_index])
  min_row <- f_db_farms[min_index,]
  summary_text <- paste0(
    "We have found ",
    n, 
    " protein complexes in your dataset and ",
    n3, 
    " among them with at least 3 quantified subunits. In condition ",
    condition,
    " the most upragulated protein complex in is ",
    max_row$Complex_Name,
    " with a fold change of ",
    max_row[fc_col_index],
    ", ",
    max_row$NQS,
    " quantified subunits and noise level of ",
    max_row$Noise,
    ". The most downregulated protein complex is ",
    min_row$Complex_Name,
    " with a fold change of ", 
    min_row[fc_col_index],
    ", " ,
    min_row$NQS,
    " quantified subunits and noise level of ",
    min_row$Noise,
    "."
  )
  return(summary_text)
}

#15. Summary function for regulated complexes
regulatedBarplot <- function(f_db_farms, no_cond, FC_th, noise_th){ #LOWEST EXPRESSED! NOT UNDER THRESHOLD!
  f_db_farms_fc <- f_db_farms[,-c(1:8),drop=F]
  f_db_farms_fc <- filter(f_db_farms_fc, Noise <= noise_th)
  up <- colSums(f_db_farms_fc[,1:(no_cond-1),drop=F] > FC_th, na.rm = TRUE)
  down <- colSums(f_db_farms_fc[,1:(no_cond-1),drop=F] < -FC_th, na.rm = TRUE)
  df <- data.frame(Upregulated = up, 
                   Downregulated = down, 
                   Condition = names(up))
  p <- plot_ly(df, x = ~Condition, 
               y = ~Upregulated, 
               type = "bar", 
               name = "Upregulated",
               text = df$Upregulated,
               textposition = 'outside') %>%
    add_trace(y = ~Downregulated, 
              name = "Downregulated", 
              text = df$Downregulated, 
              textposition = 'outside') %>%
    layout(barmode = "group", 
           title = "Regulated complexes", 
           yaxis = list(title = "Number of complexes"),
           legend = list(orientation = 'h')) %>%
    plotly::config(showLink = F, 
                   displaylogo = F, 
                   collaborate = F,
                   modeBarButtonsToRemove = list('sendDataToCloud',
                                                 'hoverCompareCartesian',
                                                 'hoverClosestCartesian',
                                                 'toggleSpikelines'))
}

#16. Top 5 up/down
changingTable <- function(f_db_farms, cond, noise_th){
  # Include noise threshold
  f_db_farms_n <- filter(f_db_farms, Noise <= noise_th)
  bottom5_indexes <- order(f_db_farms_n[,(8+(cond-1))])[5:1]
  top5_indexes <- order(f_db_farms_n[,(8+(cond-1))], decreasing = TRUE)[1:5]
  top_changing <- c(top5_indexes, bottom5_indexes)
  n_col <- length(f_db_farms_n[1,])
  complex_table <- f_db_farms_n[top_changing,c(2,4,9:n_col)]
  n_col <- length(complex_table)
  top_table <- DT::datatable(data = complex_table, rownames = FALSE, extensions = 'Buttons',
                             options = list(dom = 'Bfrtip',
                                            scrollY="300px", 
                                            scrollX = TRUE, 
                                            searching = FALSE,
                                            buttons = list('copy', 'print', list(extend = 'collection',
                                                                                 buttons = c('csv', 'excel', 'pdf'),
                                                                                 text = 'Download'))))
  return(top_table)
}




