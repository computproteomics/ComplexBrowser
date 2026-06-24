FROM rocker/shiny

LABEL maintainer="Veit Schwaemmle <veits@bmb.sdu.dk>"
LABEL description="Docker image for the packaged ComplexBrowser Shiny app."

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libbz2-dev \
    libcurl4-openssl-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libglpk-dev \
    libicu-dev \
    libjpeg-dev \
    liblzma-dev \
    libpng-dev \
    libssl-dev \
    libtiff-dev \
    libxml2-dev \
    texlive-latex-extra \
    texlive-latex-recommended \
    wget \
  && rm -rf /var/lib/apt/lists/*

RUN Rscript -e "install.packages('BiocManager', repos = 'https://cloud.r-project.org'); \
  BiocManager::install(c( \
    'colourpicker', 'cowplot', 'dplyr', 'DT', 'GGally', 'ggplot2', \
    'gridExtra', 'gtools', 'heatmaply', 'htmlwidgets', 'jsonlite', \
    'knitr', 'networkD3', 'pander', 'plotly', 'PolySTest', 'pracma', \
    'preprocessCore', 'rmarkdown', 'shiny', 'shinyBS', \
    'shinycssloaders', 'shinydashboard', 'shinyjs', 'webshot2' \
  ), ask = FALSE, update = FALSE)"

RUN wget -q "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
  && apt-get update \
  && apt-get install -y --no-install-recommends ./google-chrome-stable_current_amd64.deb \
  && rm google-chrome-stable_current_amd64.deb \
  && rm -rf /var/lib/apt/lists/* \
  && sed -i '${s/$/ --no-sandbox/g}' /opt/google/chrome/google-chrome

WORKDIR /opt/complexbrowser

COPY DESCRIPTION NAMESPACE README.md ./
COPY R ./R
COPY man ./man
COPY inst ./inst
COPY exec ./exec
COPY vignettes ./vignettes

RUN R CMD INSTALL --no-build-vignettes .

RUN rm -rf /srv/shiny-server/* \
  && cp -a "$(Rscript -e 'cat(system.file(\"shiny\", package = \"complexbrowser\"))')"/* /srv/shiny-server/ \
  && chown -R shiny:shiny /srv/shiny-server

EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
