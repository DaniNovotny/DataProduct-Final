# Crear Dockerfile 
## Dockerfile - Airflow

Necesitamos crear dos Dockerfiles. Este primero levanta Airflow. El segundo crea un contenedor para correr Shiny App.

```
# VERSION 1.10.9
# AUTHOR: Matthieu "Puckel_" Roisil
# DESCRIPTION: Basic Airflow container
# BUILD: docker build --rm -t puckel/docker-airflow .
# SOURCE: https://github.com/puckel/docker-airflow

FROM python:3.7-slim-buster
LABEL maintainer="Puckel_"

# Never prompt the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
ARG AIRFLOW_VERSION=1.10.15
ARG AIRFLOW_USER_HOME=/usr/local/airflow
ARG AIRFLOW_DEPS=""
ARG PYTHON_DEPS=""
ENV AIRFLOW_HOME=${AIRFLOW_USER_HOME}

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8

COPY requirements.txt .

# Disable noisy "Handling signal" log messages:
# ENV GUNICORN_CMD_ARGS --log-level WARNING

RUN set -ex \
    && buildDeps=' \
        freetds-dev \
        libkrb5-dev \
        libsasl2-dev \
        libssl-dev \
        libffi-dev \
        libpq-dev \
        git \
    ' \
    && apt-get update -yqq \
    && apt-get upgrade -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        freetds-bin \
        build-essential \
        default-libmysqlclient-dev \
        apt-utils \
        curl \
        rsync \
        netcat \
        locales \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_USER_HOME} airflow \
    && pip install -U pip setuptools wheel \
    && pip install 'SQLAlchemy==1.3.15' \
    && pip install pytz \
    && pip install pyOpenSSL \
    && pip install ndg-httpsclient \
    && pip install pyasn1 \
    && pip install 'wtforms==2.3.3' \
    && pip install apache-airflow[crypto,celery,postgres,hive,jdbc,mysql,ssh${AIRFLOW_DEPS:+,}${AIRFLOW_DEPS}]==${AIRFLOW_VERSION} \
    && pip install 'redis==3.2' \
    && pip install -r requirements.txt \
    && if [ -n "${PYTHON_DEPS}" ]; then pip install ${PYTHON_DEPS}; fi \
    && apt-get purge --auto-remove -yqq $buildDeps \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

COPY script/entrypoint.sh /entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_USER_HOME}/airflow.cfg

RUN chown -R airflow: ${AIRFLOW_USER_HOME}
RUN mkdir -p /home/airflow/monitor
RUN chown -R airflow: /home/airflow/monitor

EXPOSE 8088 5555 8793

USER airflow
WORKDIR ${AIRFLOW_USER_HOME}
ENTRYPOINT ["/entrypoint.sh"]
CMD ["webserver"]
``` 


## Dockerfile - Shiny App

El segundo Dockerfile crea un contenedor para correr Shiny App.

```
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

## update system libraries
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean

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


# expose port
#EXPOSE 3838

# run app on container start
#CMD ["R", "-e", "shiny::runApp('/app', host = '0.0.0.0', port = 3838)"]
```

# Construir imagen y correr todos los servicios
Para correr este proyecto se debe ejecutar los sigueintes comandos:
1. Construir imagen
```
docker-compose build
```
2. Iniciar el servicio
```
docker-compose up
```

# Accesar a Airflow
Mediavez se haya levantado el servicio, se debe ingresar a localhost:8080

# Connecciones
Para correr los respectivos DAGs, se debe verificar que tengan las conecciones adecuadas. 
En este caso necesitamos modificamos una conección llamada "fs_default", y creamos una segunda llamda "mydb" para conectarnos a la base de datos. 

# DAGs
Media vez existan las conecciones necesarias, ya podemos correr los DAGs. 
Nosotros creamos cuatro DAGs: 
- `confirmed.py`
- `deaths.py`
- `recovered.py`
- `final.py`
La función de los primeros tres es jalar los datos de los diferentes archivos .csv, transformar estos datos a un formato útil para trabajar, e ingresarlos a diferentes tablas en MySQL Workbench.
El ultimo DAG unifica los tres archivos en una unica tabla.

# Datos
Los archivos que usamos son los siguientes:
- `time_series_covid19_confirmed_global.csv`
- `time_series_covid19_deaths_global.csv`
- `time_series_covid19_recovered_global`

# Shiny
Para la visualización, creamos un Dashboard en R, utilizando ShinyApps. 

Este está conformado por: `ui.R` y `server.R`.

El shiny contiene tablas con los datos, mapas con los que se puede interactuar, graficas entre otros.



