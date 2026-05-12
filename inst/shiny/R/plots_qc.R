distrPlotlyBox <- function(data, no_rep, no_cond) {
  data <- data[, 1:(no_rep * no_cond + 1)]
  data[, -1] <- log2(data[, -1])
  melted_data <- reshape2::melt(data, na.rm = TRUE)
  melted_data <- cbind(
    melted_data,
    reshape2::colsplit(melted_data$variable, pattern = "_", names = c("Condition", "Replicate"))
  )
  colnames(melted_data) <- c("ProteinID", "Sample", "Intensity", "Condition", "Replicate")
  melted_data$Sample <- factor(melted_data$Sample, levels = colnames(data))
  melted_data$Condition <- factor(melted_data$Condition, levels = paste0("C", 1:no_cond))

  list(plot = plotly::plot_ly(
    data = melted_data,
    type = "box",
    y = ~Intensity,
    x = ~Sample,
    color = ~Condition,
    height = 500
  ) %>%
    plotly::layout(title = "Data distribution - log2(Intensity)", hovermode = "x") %>%
    plotly::config(
      showLink = FALSE,
      displaylogo = FALSE,
      modeBarButtonsToRemove = list(
        "sendDataToCloud",
        "hoverCompareCartesian",
        "hoverClosestCartesian",
        "toggleSpikelines"
      )
    ))
}

missingValuePlotly <- function(data, no_cond, no_rep) {
  if (length(data) == 0) {
    return(NULL)
  }

  data <- data[, 2:(no_cond * no_rep + 1)]
  no_na_column <- colSums(is.na(data))
  barplot_df <- data.frame(no_NA = unlist(no_na_column), sample = colnames(data), stringsAsFactors = FALSE)
  barplot_df$sample <- factor(barplot_df$sample, levels = colnames(data))
  total_na <- sum(no_na_column)
  all <- dim(data)[1] * dim(data)[2]

  plotly::plot_ly(
    x = ~barplot_df$sample,
    y = ~barplot_df$no_NA,
    type = "bar",
    color = ~barplot_df$sample,
    text = barplot_df$no_NA,
    textposition = "outside",
    marker = list(line = list(color = "#000000", width = 1))
  ) %>%
    plotly::layout(
      yaxis = list(title = "Number of missing values"),
      xaxis = list(title = "Sample"),
      hovermode = "x",
      title = paste0(
        "Number of missing values in each sample (", total_na,
        " in total out of ", all, " - ", round(total_na / all * 100, 2), "[%])"
      )
    ) %>%
    plotly::config(
      showLink = FALSE,
      displaylogo = FALSE,
      modeBarButtonsToRemove = list(
        "sendDataToCloud",
        "hoverCompareCartesian",
        "hoverClosestCartesian",
        "toggleSpikelines"
      )
    )
}

qValuePlot <- function(stats, condition, col) {
  q_values <- seq(0, 0.1, 0.001)
  no_features <- vapply(q_values, function(x) sum(stats$qValue_df[, condition - 1] < x), numeric(1))

  plotly::plot_ly(
    x = q_values,
    y = no_features,
    type = "scatter",
    mode = "lines+markers",
    line = list(color = col),
    marker = list(size = 4, color = col)
  ) %>%
    plotly::layout(
      title = "Significant features analysis",
      xaxis = list(title = "Statistical value threshold"),
      yaxis = list(title = "Number of significant features")
    )
}

CVdistrPlotly <- function(stats_CV_DF, CV_cond, col) {
  values <- stats_CV_DF[, CV_cond]
  meanV <- mean(values, na.rm = TRUE)
  medianV <- stats::median(values, na.rm = TRUE)
  p <- plotly::plot_ly(
    x = ~values,
    type = "histogram",
    histnorm = "probability",
    marker = list(line = list(color = "#000000", width = 0.5), color = col)
  ) %>%
    plotly::layout(
      yaxis = list(title = "Relative frequency"),
      xaxis = list(title = "Coefficient of variation [%]"),
      title = paste0("CV distribution - condition ", CV_cond)
    ) %>%
    plotly::config(
      showLink = FALSE,
      displaylogo = FALSE,
      modeBarButtonsToRemove = list(
        "sendDataToCloud",
        "hoverCompareCartesian",
        "hoverClosestCartesian",
        "toggleSpikelines"
      )
    )
  list(plot = p, mean = meanV, median = medianV)
}

volcanoPlot <- function(stats, cond, qValue_cutoff) {
  log2ratio <- round(stats$log2_ratios[, cond - 1], 3)
  qValues <- stats$qValue_df[, cond - 1]
  labels <- stats$absolute_df[, 1]
  valid_indexes <- !is.na(qValues)
  log2ratio <- log2ratio[valid_indexes]
  qValues <- qValues[valid_indexes]
  labels <- labels[valid_indexes]
  grouping <- ifelse(qValues < qValue_cutoff, "Significant", "Not significant")
  qValues <- round(-log10(qValues), 3)

  plotly::plot_ly(
    x = log2ratio,
    y = qValues,
    text = labels,
    color = grouping,
    colors = c("#222d32", "#428bca"),
    type = "scatter",
    mode = "markers",
    marker = list(size = 3.5)
  ) %>%
    plotly::layout(
      legend = list(orientation = "h", xanchor = "center", y = 1.1, x = 0.5, font = list(size = 20)),
      xaxis = list(title = paste0("Log2(C", cond, "/C1)")),
      yaxis = list(title = paste0("-Log10(qValue (C", cond, "/C1))"))
    ) %>%
    plotly::config(
      showLink = FALSE,
      displaylogo = FALSE,
      modeBarButtonsToRemove = list(
        "sendDataToCloud",
        "hoverCompareCartesian",
        "hoverClosestCartesian",
        "toggleSpikelines"
      )
    )
}

plotlyPCA <- function(data, no_cond, no_rep) {
  rownames(data) <- data[, 1]
  samples <- colnames(data[, 2:(no_cond * no_rep + 1)])
  data <- log2(data[, 2:(no_cond * no_rep + 1)])
  data[data == -Inf] <- NA
  condition_factors <- paste0("C", rep(1:no_cond, each = no_rep))
  pca <- stats::prcomp(stats::na.omit(data), scale = TRUE, retx = TRUE)
  pca$rotation <- data.frame(pca$rotation, Condition = condition_factors, Sample = samples)
  pca$rotation$Condition <- factor(pca$rotation$Condition, levels = unique(as.character(pca$rotation$Condition)))

  plotly::plot_ly(
    x = round(as.numeric(pca$rotation[, 1]), 3),
    y = round(as.numeric(pca$rotation[, 2]), 3),
    color = pca$rotation[, (length(pca$rotation[1, ]) - 1)],
    text = pca$rotation[, length(pca$rotation[1, ])],
    type = "scatter",
    mode = "markers"
  ) %>%
    plotly::layout(
      title = "Principal Component Analysis",
      xaxis = list(title = paste("Component 1 -", round(pca$sdev[1]^2 / sum(pca$sdev^2), 2) * 100, "[%]")),
      yaxis = list(title = paste("Component 2 -", round(pca$sdev[2]^2 / sum(pca$sdev^2), 2) * 100, "[%]"))
    ) %>%
    plotly::config(
      showLink = FALSE,
      displaylogo = FALSE,
      modeBarButtonsToRemove = list(
        "sendDataToCloud",
        "hoverCompareCartesian",
        "hoverClosestCartesian",
        "toggleSpikelines"
      )
    )
}
