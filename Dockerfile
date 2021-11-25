# Base image https://hub.docker.com/u/rocker/
FROM obedaeg/shiny

# system libraries of general use
## install debian packages
RUN apt-get update -qq && apt-get -y --no-install-recommends install \
    libxml2-dev \
    libcairo2-dev \
    libsqlite3-dev \
    libmariadbd-dev \
    libpq-dev \
    libssh2-1-dev \
    unixodbc-dev \
    libcurl4-openssl-dev \
    libssl-dev
    # mysql-client \
    # libmariadb-dev \
    # && ln -s /usr/bin/mariadb_config /usr/bin/mysql_config

## update system libraries
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean

# copy necessary files
## app folder
#COPY /example-app ./app
## renv.lock file
#COPY /example-app/renv.lock ./renv.lock

# install renv & restore packages
#RUN Rscript -e 'install.packages("renv")'
RUN Rscript -e 'install.packages("maps")'
RUN Rscript -e 'install.packages("shinythemes")'
RUN Rscript -e 'install.packages("viridis")'
RUN Rscript -e 'install.packages("mapproj")'
RUN Rscript -e 'install.packages("ggrepel")'
RUN Rscript -e 'install.packages("plotly")'
RUN Rscript -e 'install.packages("RMySQL")'
RUN Rscript -e 'install.packages("dygraphs")'
RUN Rscript -e 'install.packages("xts")'
RUN Rscript -e 'install.packages("readr")'
RUN Rscript -e 'install.packages("dplyr")'
RUN Rscript -e 'install.packages("ggplot2")'
RUN Rscript -e 'install.packages("DT")'
RUN Rscript -e 'install.packages("imputeTS")'
RUN Rscript -e 'install.packages("lubridate")'
RUN Rscript -e 'install.packages("formattable")'



#RUN Rscript -e 'renv::consent(provided = TRUE)'
#RUN Rscript -e 'renv::restore()'

# expose port
#EXPOSE 3838

# run app on container start
#CMD ["R", "-e", "shiny::runApp('/app', host = '0.0.0.0', port = 3838)"]