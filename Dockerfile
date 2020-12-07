FROM rocker/shiny
LABEL maintainer="Veit Schwaemmle <veits@bmb.sdu.dk>"
LABEL description="Docker image of ComplexBrowser implementation on top of shiny-server. The number of to-be-installed R packages requires patience when building this image."

#RUN  sudo mount -o ro,remount /sys && sudo  mount -o rw,remount /sys
#RUN echo N | tee /sys/module/overlay/parameters/metacopy
#RUN rm -rf /var/cache/apt/* /var/lib/apt/lists/* /tmp/* /var/tmp/*
#RUN apt-get clean && apt-get update && apt-get install -y apt-utils

RUN apt-get update && apt-get install -y libssl-dev liblzma-dev libbz2-dev libicu-dev libxml2 libxml2-dev libglpk-dev texlive-latex-recommended texlive-latex-extra  && apt-get clean 

RUN R -e "install.packages('BiocManager', repos='http://cran.us.r-project.org'); \
  update.packages(ask=F); \
  BiocManager::install(c('dplyr','plotly'),ask=F)"
RUN R -e "library(BiocManager); BiocManager::install(c('networkD3','data.table','stringr','DT','MASS','pracma','preprocessCore','limma','qvalue','colourpicker',\
  'shinydashboard','rmarkdown','shinyBS','heatmaply','devtools','GGally','shinycssloaders','cowplot','pander','tinytex','colourpicker','biomaRt'),ask=F)"
#RUN R -e "library(devtools);install_version('rmarkdown', version = '1.8')"
# get recent libraries for figure download and report
RUN R -e "remotes::install_github('rstudio/webshot2'); tinytex::install_tinytex()"

# needs google-chrome to run the webshot
RUN wget "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
RUN apt-get install -y ./google-chrome-stable_current_amd64.deb && rm google-chrome-stable_current_amd64.deb 
RUN sed -i '${s/$/ --no-sandbox/g}'  /opt/google/chrome/google-chrome

#RUN R -e "install.packages('BiocManager', repos='http://cran.us.r-project.org'); \
#  update.packages(ask=F); \
#  BiocManager::install();\
#  BiocManager::install(c('gclus'),ask=F)"


RUN rm -rf /srv/shiny-server
RUN mkdir /srv/shiny-server
COPY *R  /srv/shiny-server/
COPY *Rds  /srv/shiny-server/
COPY *csv  /srv/shiny-server/
COPY *pdf  /srv/shiny-server/
COPY *.rmd /srv/shiny-server/
RUN mkdir /srv/shiny-server/styling
RUN mkdir /srv/shiny-server/www
COPY www/* /srv/shiny-server/www/
COPY styling/* /srv/shiny-server/styling/

