FROM rocker/shiny
LABEL maintainer="Veit Schwaemmle <veits@bmb.sdu.dk>"
LABEL description="Docker image of ComplexBrowser implementation on top of shiny-server. The number of to-be-installed R packages requires patience when building this image."


RUN apt-get update && apt-get install -y libssl-dev && apt-get clean 


RUN R -e "update.packages(ask=F);source('https://bioconductor.org/biocLite.R'); biocLite(); biocLite(c('dplyr','plotly','networkD3','data.table','stringr','DT','MASS','pracma','preprocessCore','limma','qvalue','colourpicker','shinydashboard','shinyBS','heatmaply','GGally','rmarkdown'))"

RUN rm -rf /srv/shiny-server
RUN mkdir /srv/shiny-server
COPY *R  /srv/shiny-server/
COPY *Rds  /srv/shiny-server/
COPY *csv  /srv/shiny-server/
COPY *pdf  /srv/shiny-server/
COPY styling/ /srv/shiny-server/





