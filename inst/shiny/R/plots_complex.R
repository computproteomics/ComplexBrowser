plotD3complexGraph <- function(stats, f_db, row, condition, q_threshold, fc_threhold) {
  subunits <- f_db$Subunits[[row]]
  colours <- matrix(ncol = 6, nrow = 1)
  colnames(colours) <- c(
    paste("Complex:", as.character(f_db$Complex_Name[row], collapse = "", sep = "")),
    "Downregulated", "Upregulated", "Not quantified", "Not changing", "NA"
  )
  colours[1, ] <- c("#9ea4d1", "#e22200", "#25d14a", "#afafaf", "#428bca", "#f83581")
  no_subunits <- length(subunits)
  node_names <- c(as.character(f_db$Complex_Name[row]), subunits)
  fc_vector <- numeric(no_subunits)
  qValue_vector <- numeric(no_subunits)
  index_vector <- numeric(no_subunits)
  proteinIDs <- as.character(stats$absolute_df$ProteinID)
  stats$FC_df <- as.matrix(stats$FC_df)

  for (subunit in seq_len(no_subunits)) {
    subunit_name <- subunits[subunit]
    if (subunit_name %in% proteinIDs) {
      index_vector[subunit] <- match(subunit_name, proteinIDs)
      fc_vector[subunit] <- stats$FC_df[index_vector[subunit], condition - 1]
      qValue_vector[subunit] <- if (!is.vector(stats$qValue_df)) {
        stats$qValue_df[index_vector[subunit], condition - 1]
      } else {
        stats$qValue_df[index_vector[subunit]]
      }
    } else {
      index_vector[subunit] <- 0
      fc_vector[subunit] <- 0
      qValue_vector[subunit] <- 1
    }
  }

  links <- data.frame(source = seq_len(no_subunits), target = 0, value = qValue_vector)
  node_grouping <- c(
    paste("Complex: ", node_names[1], collapse = "", sep = ""),
    vapply(fc_vector, function(x) {
      if (is.na(x)) {
        "NA"
      } else if (x < -fc_threhold) {
        "Downregulated"
      } else if (x == 0) {
        "Not quantified"
      } else if (x > fc_threhold) {
        "Upregulated"
      } else {
        "Not changing"
      }
    }, character(1))
  )
  colour_order <- vapply(unique(node_grouping), function(x) colours[1, x], character(1))
  colour_js <- paste(paste('d3.scaleOrdinal(["', paste(colour_order, collapse = '","'), '"])'), collapse = "")
  nodes <- data.frame(name = node_names, group = node_grouping, size = c(80, 50 * abs(fc_vector)))

  list(
    star_graph = networkD3::forceNetwork(
      Links = links, Nodes = nodes, Source = "source", Target = "target",
      Value = "value", NodeID = "name", Group = "group", Nodesize = "size",
      zoom = FALSE, legend = TRUE,
      linkDistance = htmlwidgets::JS(paste('function(d) { if(d.value <', q_threshold, '){ return 100} else { return(70)}}', collapse = "")),
      linkWidth = htmlwidgets::JS(paste('function(d) { if(d.value <', q_threshold, '){ return 3} else { return(1)}}', collapse = "")),
      colourScale = colour_js,
      clickAction = 'Shiny.onInputChange("node_clicked", d.name)',
      fontSize = 32,
      bounded = TRUE
    ),
    subunit_indexes = index_vector,
    qValues = qValue_vector
  )
}

expressionBarplot <- function(proteinID, f_data, stat_list) {
  if (!(proteinID %in% f_data$ProteinID)) {
    return(NULL)
  }

  index <- match(x = proteinID, table = f_data$ProteinID)
  abs_vals <- as.vector(stat_list$absolute_df[index, -1], mode = "numeric")
  means <- stat_list$means_df[index, ]
  SDs <- stat_list$SD_df[index, ]
  no_conditions <- length(means)
  no_reps <- length(abs_vals) / no_conditions
  bar_labels <- paste("C", 1:no_conditions, "")
  abs_labels <- rep(bar_labels, each = no_reps)
  df <- data.frame(x = bar_labels, y = means, sd = SDs)
  df1 <- data.frame(x = abs_labels, y = as.vector(abs_vals))

  plotly::plot_ly(
    data = df,
    x = ~x,
    y = ~y,
    color = ~x,
    error_y = list(array = ~sd, color = "#000000"),
    type = "bar",
    marker = list(line = list(color = "#000000", width = 1))
  ) %>%
    plotly::layout(
      title = paste("Expression of", proteinID, "protein", collapse = " "),
      yaxis = list(
        title = "Absolute intensity",
        exponentformat = "E",
        showticklabels = TRUE,
        tickfont = list(family = "Arial, sans-serif", size = 10.5, color = "black")
      ),
      xaxis = list(title = "Condition", categoryorder = "array", categoryarray = df$x),
      showlegend = FALSE
    ) %>%
    plotly::add_trace(data = df1, x = ~x, y = ~y, type = "scatter", mode = "markers", color = ~x, marker = list(size = 6)) %>%
    plotly::config(
      showLink = FALSE,
      displaylogo = FALSE,
      modeBarButtonsToRemove = list("sendDataToCloud", "hoverCompareCartesian", "hoverClosestCartesian", "toggleSpikelines")
    )
}

multilinePlot <- function(f_db, stats, row, no_cond, scale = c("Log2 Intensity", "zScore")) {
  complex_name <- f_db$Complex_Name[row]
  subunits <- f_db$Subunits[[row]]
  protein_list <- stats$absolute_df[, 1]
  present_subunits <- subunits[subunits %in% protein_list]
  no_subunits <- length(present_subunits)
  x_sequence <- seq_len(no_cond)
  mx <- data.frame(matrix(nrow = length(x_sequence), ncol = no_subunits))
  index_vector <- numeric(no_subunits)

  for (protein in seq_len(no_subunits)) {
    index_vector[protein] <- match(present_subunits[protein], protein_list)
    if (scale == "zScore") {
      mx[, protein] <- unlist(stats$zScore[index_vector[protein], ])
    } else if (scale == "Log2 Intensity") {
      mx[, protein] <- unlist(stats$log2_means[index_vector[protein], ])
      mx[, protein] <- mx[, protein] - mean(mx[, protein], na.rm = TRUE)
    }
  }

  colnames(mx) <- present_subunits
  if (ncol(mx) >= 2) {
    mx[apply(mx, 1, stats::sd, na.rm = TRUE) == 0, 1] <- mx[apply(mx, 1, stats::sd, na.rm = TRUE) == 0, 1] + 0.0001
    farms <- complexbrowser_plot_fast_farms(probes = t(mx))
    probes_adj <- (farms$loadings * mx) / sum(farms$loadings, na.rm = TRUE)
    complex_expr <- rowSums(probes_adj, na.rm = TRUE)
  }

  p <- plotly::plot_ly(x = x_sequence, y = mx[, 1], type = "scatter", mode = "lines+markers", name = present_subunits[1]) %>%
    plotly::layout(
      title = complex_name,
      yaxis = list(title = scale),
      xaxis = list(title = "Condition", ticktext = paste0("C", 1:no_cond), tickvals = 1:no_cond, tickmode = "array")
    ) %>%
    plotly::config(showLink = FALSE, displaylogo = FALSE, modeBarButtonsToRemove = list("sendDataToCloud", "hoverCompareCartesian", "hoverClosestCartesian", "toggleSpikelines"))

  for (protein in 2:no_subunits) {
    p <- plotly::add_trace(p, x = x_sequence, y = mx[, protein], type = "scatter", mode = "lines+markers", name = present_subunits[protein])
  }
  if (ncol(mx) >= 2) {
    p <- plotly::add_trace(
      p, x = x_sequence, y = complex_expr, type = "scatter", mode = "lines+markers", name = "Complex",
      line = list(color = ggplot2::alpha("blue", 0.9), width = 4),
      marker = list(color = ggplot2::alpha("blue", 0.9), size = 9)
    )
  }

  list(plot = p, subunits_names = present_subunits, index_vector = index_vector)
}

plotComplexHeatmap <- function(names_vector, index_vector, stats, no_cond, distance_measure, agg_method, p = 4) {
  expr_array <- stats$log2_means[index_vector, , drop = FALSE]
  expr_array[is.na(expr_array)] <- 0
  norm_expr_array <- round(t(apply(expr_array, 1, function(x) x - mean(x, na.rm = TRUE))), 4)
  rownames(norm_expr_array) <- names_vector
  colnames(norm_expr_array) <- paste0("Norm. log2(R) C", 1:no_cond)

  row_dend <- if (distance_measure != "minkowski") {
    stats::as.dendrogram(stats::hclust(d = stats::dist(norm_expr_array, method = distance_measure), method = agg_method))
  } else {
    stats::as.dendrogram(stats::hclust(d = stats::dist(norm_expr_array, method = distance_measure, p = p), method = agg_method))
  }

  list(
    heatmap = heatmaply::heatmaply(
      norm_expr_array,
      Colv = FALSE,
      Rowv = row_dend,
      xlab = "Condition",
      ylab = "ProteinID",
      main = "Protein expression heatmap - normalized mean log2 intensities",
      fontsize_row = 6,
      fontsize_col = 6,
      margins = c(80, 80, NA, 0),
      col = heatmaply::cool_warm
    ),
    expr_array = expr_array
  )
}

plotCorrelationHeatmap <- function(names_vector, index_vector, stats, correlation_measure, distance_measure, agg_method, p = 4) {
  means_array <- stats$log2_means[index_vector, ]
  means_array <- round(t(apply(means_array, 1, function(x) x - mean(x, na.rm = TRUE))), 4)
  rownames(means_array) <- names_vector
  colnames(means_array) <- vapply(colnames(means_array), function(x) gsub("intensity", "", x), character(1))
  for (row in seq_len(nrow(means_array))) {
    if (length(unique(means_array[row, ])) == 1) {
      means_array[row, 1] <- means_array[row, 1] + 0.0001
    }
  }
  correlation_matrix <- stats::cor(x = t(means_array), use = "na.or.complete", method = correlation_measure)

  if (distance_measure != "minkowski") {
    return(heatmaply::heatmaply_cor(
      x = correlation_matrix,
      dist_method = distance_measure,
      hclust_method = agg_method,
      xlab = "ProteinID",
      ylab = "ProteinID",
      main = "Correlation map",
      margins = c(80, 80, 50, 10),
      fontsize_row = 7,
      fontsize_col = 6
    ))
  }

  row_dend <- stats::as.dendrogram(stats::hclust(stats::dist(correlation_matrix, method = "minkowski", p = p)))
  heatmaply::heatmaply_cor(
    x = correlation_matrix,
    Rowv = row_dend,
    hclust_method = agg_method,
    xlab = "ProteinID",
    ylab = "ProteinID",
    main = "Correlation map",
    margins = c(80, 80, 50, 10),
    fontsize_row = 7,
    fontsize_col = 6
  )
}

plotComplexCorrelation <- function(database, row, stats, cond_1, cond_2) {
  subunits <- database[row, ]$Subunits[[1]]
  proteins <- stats$absolute_df[, 1]
  subunits <- subunits[subunits %in% proteins]
  if (length(subunits) <= 1) {
    return(NULL)
  }

  s_indices <- vapply(subunits, function(x) match(x, proteins), integer(1))
  means1 <- stats$log2_means[s_indices, cond_1]
  means2 <- stats$log2_means[s_indices, cond_2]
  mdl <- pracma::odregress(x = means1, y = means2)
  tot <- sum((means2 - mean(means2))^2)
  res <- sum(mdl$resid^2)
  r2 <- 1 - res / tot

  plotly::plot_ly(x = means1, y = means2, type = "scatter", mode = "markers") %>%
    plotly::add_lines(x = means1, y = as.vector(mdl$fitted)) %>%
    plotly::layout(
      title = paste0(" R2 =", round(r2, 4)),
      showlegend = FALSE,
      yaxis = list(title = paste0("Condition ", cond_1)),
      xaxis = list(title = paste0("Condition ", cond_2))
    ) %>%
    plotly::config(showLink = FALSE, displaylogo = FALSE, modeBarButtonsToRemove = list("sendDataToCloud", "hoverCompareCartesian", "hoverClosestCartesian", "toggleSpikelines"))
}

generateColLabels <- function(no_cond, database) {
  colname_v <- c("No", "ComplexID", "Complex_Name", "NUS", "NQS", "Coverage", "Subunits", "GO_terms", "PubMedID")
  if (database != "CORUM") {
    colname_v[9] <- "Stoichiometry"
  }
  hover_labels <- c(
    "Row numbers", "", "", "Number of unique subunits in the complex",
    "Number of unique quantified subunits of the complex found in the input dataset",
    "Percentage of complex subunits found in the input data set",
    "Names of unique subunits", "GO annotation of the complex", "PubMedID of the reference paper"
  )
  fc <- paste0("FC C", 2:no_cond, "/C1")
  final_v2 <- c(colname_v, fc, "Noise")
  title_v <- c(hover_labels, fc, "Noise level in coexpression. Value between 0 (best) and 1 (worst). Indicates how trustworthy are the fold changes calculated. Is higher for complexes with few quantified subunits.")
  htmltools::withTags(table(class = "display", thead(tr(lapply(seq_along(final_v2), function(x) th(colspan = 1, final_v2[x], title = title_v[x], style = "text-align:center"))))))
}

regulatedBarplot <- function(f_db_farms, no_cond, FC_th, noise_th) {
  f_db_farms_fc <- f_db_farms[, -c(1:8), drop = FALSE]
  f_db_farms_fc <- dplyr::filter(f_db_farms_fc, Noise <= noise_th)
  up <- colSums(f_db_farms_fc[, 1:(no_cond - 1), drop = FALSE] > FC_th, na.rm = TRUE)
  down <- colSums(f_db_farms_fc[, 1:(no_cond - 1), drop = FALSE] < -FC_th, na.rm = TRUE)
  df <- data.frame(Upregulated = up, Downregulated = down, Condition = names(up), stringsAsFactors = FALSE)

  plotly::plot_ly(df, x = ~Condition, y = ~Upregulated, type = "bar", name = "Upregulated", text = df$Upregulated, textposition = "outside") %>%
    plotly::add_trace(y = ~Downregulated, name = "Downregulated", text = df$Downregulated, textposition = "outside") %>%
    plotly::layout(
      barmode = "group",
      title = "Regulated complexes",
      yaxis = list(title = "Number of complexes"),
      xaxis = list(title = "Condition", categoryorder = "array", categoryarray = df$Condition),
      legend = list(orientation = "h")
    ) %>%
    plotly::config(showLink = FALSE, displaylogo = FALSE, modeBarButtonsToRemove = list("sendDataToCloud", "hoverCompareCartesian", "hoverClosestCartesian", "toggleSpikelines"))
}

changingTable <- function(f_db_farms, cond, noise_th, FC_th) {
  top5 <- if (requireNamespace("complexbrowser", quietly = TRUE)) {
    complexbrowser::complexbrowser_changing_table_data(f_db_farms, cond, noise_th, FC_th)
  } else {
    complexbrowser_changing_table_data(f_db_farms, cond, noise_th, FC_th)
  }

  DT::datatable(
    data = top5,
    rownames = FALSE,
    extensions = "Buttons",
    options = list(
      dom = "Bfrtip",
      scrollY = "300px",
      scrollX = TRUE,
      searching = FALSE,
      pageLength = 12,
      lengthChange = FALSE,
      buttons = list("copy", "print", list(extend = "collection", buttons = c("csv", "excel", "pdf"), text = "Download"))
    )
  ) %>%
    DT::formatStyle(colnames(top5), height = 20) %>%
    DT::formatStyle(colnames(top5)[1], target = "row", backgroundColor = DT::styleEqual(c("Top5 Up", "Top5 Down"), c(ggplot2::alpha("green", 0.2), ggplot2::alpha("red", 0.2)))) %>%
    DT::formatStyle(
      colnames(top5)[1 + cond], colnames(top5)[1],
      backgroundColor = DT::styleEqual(
        setdiff(top5[, 1], c("Top5 Up", "Top5 Down")),
        rep(ggplot2::alpha("yellow", 0.2), length(unique(setdiff(top5[, 1], c("Top5 Up", "Top5 Down")))))
      )
    )
}

complexDBsummary <- function(f_db_farms, no_cond, no_rep, condition, noise_th) {
  if (requireNamespace("complexbrowser", quietly = TRUE)) {
    return(complexbrowser::complexbrowser_complex_summary(f_db_farms, no_cond, no_rep, condition, noise_th))
  }
  complexbrowser_complex_summary(f_db_farms, no_cond, no_rep, condition, noise_th)
}

complexbrowser_plot_fast_farms <- function(probes, weight = 0.1, mu = 0.1, max_iter = 1000,
                                           force_iter = FALSE, min_noise = 0.0001, fill_nan = 0) {
  readouts <- as.matrix(probes)
  readouts[is.na(readouts)] <- fill_nan
  x <- t(readouts)
  x <- t(t(x) - colMeans(x, na.rm = TRUE))
  xsd <- apply(x, 2, function(col) stats::sd(col, na.rm = TRUE) * sqrt((length(col) - 1) / length(col)))
  xsd[xsd < min_noise] <- 1
  x <- t(t(x) / xsd)
  x[!is.finite(x)] <- 0

  cmat <- crossprod(x, x) / nrow(x)
  cmat <- (cmat + t(cmat)) / 2
  cmat[cmat < 0] <- 0
  svd_result <- svd(cmat)
  s <- svd_result$d
  s[s < min_noise] <- min_noise
  cmat <- svd_result$u %*% diag(s) %*% t(svd_result$v)
  diag(cmat)[diag(cmat) < 0] <- 0

  lambda <- sqrt(0.75 * diag(cmat))
  psi <- diag(cmat) - lambda^2
  old_psi <- psi
  alpha <- weight * ncol(x)
  expected <- 1
  for (iteration in seq_len(max_iter)) {
    phi <- (1 / psi) * lambda
    a <- as.vector(1 + crossprod(lambda, phi))
    eta <- phi / a
    zeta <- cmat %*% eta
    expected <- 1 - as.vector(eta) %*% lambda + as.vector(eta) %*% zeta
    lambda <- zeta / (c(expected) + as.vector(psi) * alpha)
    psi <- diag(cmat) - as.vector(zeta)[1] * lambda + psi * alpha * lambda * (mu - lambda)
    psi[psi < min_noise^2] <- min_noise^2
    if (!force_iter && max(abs(psi - old_psi)) / max(abs(old_psi)) < min_noise / 10) {
      break
    }
    old_psi <- psi
  }

  loading <- as.vector(sqrt(expected)) * lambda
  phi <- loading / psi
  list(loadings = loading / max(loading), noise = 1 / as.vector(1 + crossprod(loading, phi)))
}
