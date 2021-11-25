# install.packages("shinythemes")
# install.packages("maps")
# install.packages("viridis")
# install.packages("mapproj")
# install.packages("ggrepel")
# install.packages("plotly")
#install.packages("RMySQL")
#install.packages("dygraphs")
#install.packages("xts")

library(shiny)
library(shinythemes)
library(ggplot2)
library(dplyr)
#library(readr)
library(maps)
library(viridis)
library(mapproj)
library(ggrepel)
library(plotly)
library(DT)
library(RMySQL)
library(dygraphs)
library(xts)
library(lubridate)
library(formattable)


# setwd("~/Documents/8vo_semestre/Data_Product/Final_Proyecto")
# confirmed <- read_csv("confirmed.csv")
# deaths <- read_csv("deaths.csv")
# recovered <- read_csv("recovered.csv")
# junto <- read_csv("junto.csv")
# mundo <- map_data("world")


# Coneccion SQL -----------------------------------------------------------

drv<- dbDriver("MySQL")
con <- dbConnect(drv,
               dbname= 'test',
               host= 'db',
               port= 3306,
               user= 'test',
              password= 'test123')

mundo <- map_data("world")

confirmed <- dbGetQuery(con,"SELECT * FROM test.confirmed")
deaths <- dbGetQuery(con,"SELECT * FROM test.deaths")
recovered <- dbGetQuery(con,"SELECT * FROM test.recovered")
junto <- dbGetQuery(con,"SELECT * FROM test.junto")


#head(cbind(cbind(confirmed,deaths$valor)),recovered$valor)
#uno <- merge(confirmed,deaths[,c(3,6,7)], by= c("country","fecha"))
#head(merge(uno, recovered[,c(3,6,7)], by= c("country","fecha")))

recovered[,"fecha"] <- date(recovered[,"fecha"])
deaths[,"fecha"] <- date(deaths[,"fecha"])
confirmed[,"fecha"] <- date(confirmed[,"fecha"])

# names(confirmed)[6]<-"confirmed"
# names(deaths)[6]<- "deaths"
# names(recovered)[6]<- "recovered"

# recovered %>% left_join(deaths, by= c("country","fecha"))
# merge(recovered,deaths[,c(2,5,6)], by= c("country","fecha"), all = TRUE)


paises <- unique(deaths$country)

shinyUI(navbarPage(
  theme = shinytheme("darkly"),
  "COVID 19",

# Inicio ------------------------------------------------------------------

  tabPanel("Inicio", 
           h1(strong("Inicio")), 
           br(),h3("Examen Final"),
           p("Este es nuestro proyecto final para Data Product. Se trata de la creacion de un Dashboard.
             Sin embargo, el trabajo no es simplemente una visualizacion de analisis y de datos, sino que 
             es todo un proceso automatizado."), br(),
           h3("Ingesta de datos"),
           p("Para la ingesta de datos levantamos Airflow a partir de Pycharm, pero utilizando Docker. 
             A travez de Airflow por medio de DAGs, programamos la lectura de datos de tres diferentes 
             archivos csv, junto con su respectiva transformacion para que de resultado obtuvieramos 
             tablas que nos fueran utiles para nuestro trabajo."),br(),
           h3("Datos"),p("Los tres archivos csv continen informacion sobre COVID-19, de contagios del
                         virus, muertes, y de recuperaciones. Estos tienen informacion sobre diferentes
                         paises y regiones a travez del tiempo, comenzando desde enero del año 2020, 
                         que es justo para inicios de pandemia, hasta fechas recientes."),br(),
           h3("Docker"),p("En Docker creamos una instancia de Airflow. La base de datos que decidimos 
                          utilizar, MySQL, tambien corre atravez de Docker. Finalmente, para ejecutar 
                          el dashboard tambien se debe correr con Docker. El Shiny App debe poder 
                          hacer la coneccion con la base de datos, de forma que no se tenga que ingresar
                          manualmente los archivos csv con los que trabajaremos. "), br()
           ),

# Integrantes -------------------------------------------------------------


  tabPanel("Integrantes del grupo", h1(strong("Integrantes del grupo")), br(),
           p("Daniela Dominguez     -   20180365"),
           p("Luis Pedro Zenteno    -   20190516"),
           p("Luis Javier Samayoa   -   20190613"),
           br(),
           uiOutput("image1", click = "MyImage"), br(), br()),

# Datos -------------------------------------------------------------------


  tabPanel("Datos",
           h1("Presentacion de Datos"),br(),
           tabsetPanel(
             tabPanel("Datos",
                      dataTableOutput('Datos'),
                      h1("Data agrupada"),br(),
                      p("Estos son los tres archivos de confirmados, muertes, y recuperados 
                        de COVID-19, agrupados en una misma tabla."), br(),
                      dataTableOutput('tabla_j')),
             tabPanel("Confirmed",
                      dataTableOutput('Confirmed'),
                      h1("Confirmed"),br(),
                      dataTableOutput('tabla_c')),
             tabPanel("Deaths",
                      dataTableOutput('Deaths'),
                      h1("Deaths"),br(),
                      dataTableOutput('tabla_d')),
             tabPanel("Recovered",
                      dataTableOutput('Recoverd'),
                      h1("Recovered"),br(),
                      dataTableOutput('tabla_r')))),

# Mapa --------------------------------------------------------------------

  tabPanel("Bubble Map",
           h1("Bubble Map"),br(), 
           p("Las tres gráficas se tardan un poco en cargar, por favor espere un momento."), br(),
           
           tabsetPanel(
             tabPanel("Confirmed", br(),
                      sidebarLayout(
                        sidebarPanel(
                          h2("Mapa de confirmados"),
                          dateInput("datum","Seleccione la fecha que desee consultar:",
                                    format = "yyyy-mm-dd",
                                    value = "2020-01-23",
                                    min = "2020-01-23",
                                    max = "2021-12-31"),
                          br(),hr(),br(),
                          h2("Contagiados por pais"),
                          selectInput('pais','Seleccione un pais para consultar su total de contagios para la fecha determinada',
                                      choices = paises,selected = "Guatemala"),
                          h4("Total de contagiados:"),
                          verbatimTextOutput("total"),
                          br(),h5("Pais seleccionado"),
                          verbatimTextOutput("output_select1"),
                          h5("Fecha seleccionada"),
                          verbatimTextOutput("output_select2")),
                        mainPanel(p("Favor esperar a que cargue la grafica."), br(),
                          plotOutput('grafica1')))),
             tabPanel("Deaths", br(), p("Favor esperar a que cargue la grafica."), br(),
                      sidebarLayout(
                        sidebarPanel(
                          h2("Mapa de muertes"),
                          dateInput("datum2","Seleccione la fecha que desee consultar:",
                                    format = "yyyy-mm-dd",
                                    value = "2020-01-23",
                                    min = "2020-01-23",
                                    max = "2021-12-31"),
                          br(),hr(),br(),
                          h2("Muertes por pais"),
                          selectInput('pais2','Seleccione un pais para consultar su total de muertes para la fecha determinada',
                                      choices = paises,selected = "Guatemala"),
                          h4("Total de muertes:"),
                          verbatimTextOutput("total2"),
                          br(),h5("Pais seleccionado"),
                          verbatimTextOutput("output_select12"),
                          h5("Fecha seleccionada"),
                          verbatimTextOutput("output_select22")
                        ),
                        mainPanel(plotOutput('grafica2')))),
             tabPanel("Recovered", br(), p("Favor esperar a que cargue la grafica."), br(),
                      sidebarLayout(
                        sidebarPanel(
                          h2("Mapa de recuperados"),
                          dateInput("datum3","Seleccione la fecha que desee consultar:",
                                    format = "yyyy-mm-dd",
                                    value = "2020-01-23",
                                    min = "2020-01-23",
                                    max = "2021-12-31"),
                          br(),hr(),br(),
                          h2("Recuperados por pais"),
                          selectInput('pais3','Seleccione un pais para consultar su total de recuperados para la fecha determinada',
                                      choices = paises,selected = "Guatemala"),
                          h4("Total de recuperados:"),
                          verbatimTextOutput("total3"),
                          br(),h5("Pais seleccionado"),
                          verbatimTextOutput("output_select13"),
                          h5("Fecha seleccionada"),
                          verbatimTextOutput("output_select23")
                        ),
                        mainPanel(plotOutput('grafica3')))))),

# Casos por fecha ---------------------------------------------------------

  tabPanel("Casos por fechas",
           p("(En esta gráfica usted podra ver el comportamiento de los casos confirmados a lo 
             largo del tiempo, por el pais que seleccione."),
           p("Funcionamiento: si le interesa ver un detalle de la grafica, puede seleccionar el
             area sobre la grafica para indicar el intervalo de tiempo que le gustaria 
             para poder ampliar la graafica."), br(),
           selectInput('pais3','Seleccione un pais',
                       choices = paises,
                       selected = "Guatemala"),
           p("Por favor espere a que carge la grafica)."),
           dygraphOutput("dygraph")),

# Comparacion entre paises ------------------------------------------------

  tabPanel("Comparacion entre paises",
           h1("Bubble Map"),br(), 
           p("Las tres gráficas se tardan un poco en cargar, por favor espere un momento."), br(),
           
           tabsetPanel(
             tabPanel("Confirmados",
           sidebarLayout(
             sidebarPanel(
               p("Aqui podra elegir varios paises de su intres para que graficamente pueda
                 visualizar el total de casos confirmados historicamente por cada pais."),
               selectInput('pais4','Seleccione los paises que le interesa analizar:',
                           choices = paises,selected = c("Guatemala","China","Australia","Norway"),
                           multiple = TRUE)),
             mainPanel(
               plotOutput('grafica4')
             ))
           ),tabPanel("Muertes",
                      sidebarLayout(
                        sidebarPanel(
                          p("Aqui podra elegir varios paises de su intres para que graficamente pueda
                            visualizar el total de muertes historicamente por cada pais."),
                          selectInput('pais5','Seleccione los paises que le interesa analizar:',
                                      choices = paises,selected = c("Guatemala","China","Australia","Norway"),
                                      multiple = TRUE)),
                        mainPanel(
                          plotOutput('grafica42')
                        ))
                      ),
           tabPanel("Recuperados",
                    sidebarLayout(
                      sidebarPanel(
                        p("Aqui podra elegir varios paises de su intres para que graficamente pueda
                          visualizar el total de recuperados historicamente por cada pais."),
                        selectInput('pais6','Seleccione los paises que le interesa analizar:',
                                    choices = paises,selected = c("Guatemala","China","Australia","Norway"),
                                    multiple = TRUE)),
                      mainPanel(
                        plotOutput('grafica43')
                      ))
                    )
           )),

# Estadisticas ------------------------------------------------------------

  tabPanel("Estadisticas",
           tabsetPanel(
             tabPanel("Top 10 +muertes",
                      h1("Paises con mas muertes en el mundo"),br(),
                      p("Estos son los diez paises con mas muertes."), br(),
                      dataTableOutput('tabla04')),
             tabPanel("Resumen de paises",
                      h1("Resumen de paises"),br(),
                      p("Esta tabla devuelve el total de personas contagiadas, total de fallecidos,
                        y total de recuperados por pais."), br(),
                      dataTableOutput('tabla01')),
             tabPanel("Muertes por paises",
                      h1("Ratios de muertes por paises"),br(),
                      p("Este es un listado por pais, en el que se muestra que porcentaje de
                        fallecidos, en comparacion a cuantos confirmados hubo en el pais."), br(),
                      dataTableOutput('tabla02')),
             tabPanel("Recuperados por paises",
                      h1("Ratio de recuperados por paises"),br(),
                      dataTableOutput('tabla03'))
             
           ))


  )
)



