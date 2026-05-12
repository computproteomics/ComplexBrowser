selectizeTooltip <- function(id, choice, title, placement = "bottom", trigger = "hover", options = NULL) {
  options <- shinyBS:::buildTooltipOrPopoverOptionsList(title, placement, trigger, options)
  options <- paste0("{'", paste(names(options), options, sep = "': '", collapse = "', '"), "'}")
  bsTag <- shiny::tags$script(shiny::HTML(paste0("
    $(document).ready(function() {
      var opts = $.extend(", options, ", {html: true});
      var selectizeParent = document.getElementById('", id, "').parentElement;
      var observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation){
          $(mutation.addedNodes).filter('div').filter(function(){return(this.getAttribute('data-value') == '", choice, "');}).each(function() {
            $(this).tooltip('destroy');
            $(this).tooltip(opts);
          });
        });
      });
      observer.observe(selectizeParent, { subtree: true, childList: true });
    });
  ")))
  htmltools::attachDependencies(bsTag, shinyBS:::shinyBSDep)
}

complexbrowser_species_selection <- function(database, stats = NULL, preferred = NULL) {
  choices <- unique(database$Organism)
  selected <- if (!is.null(preferred) && preferred %in% choices) preferred else choices[[1]]
  if (is.null(stats) || is.null(stats$absolute_df) || nrow(stats$absolute_df) == 0) {
    return(list(choices = choices, selected = selected))
  }

  protein_ids <- as.character(stats$absolute_df[, 1])
  match_counts <- vapply(choices, function(organism) {
    organism_database <- database[database$Organism == organism, , drop = FALSE]
    accessions <- unique(as.character(unlist(organism_database$Subunits)))
    sum(protein_ids %in% accessions)
  }, integer(1))

  if (max(match_counts) > 0) {
    selected <- choices[[which.max(match_counts)]]
  }
  list(choices = choices, selected = selected)
}
