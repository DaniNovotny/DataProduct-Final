# install.packages("maps")
# install.packages("viridis")
# install.packages("mapproj")
# install.packages("ggrepel")
# install.packages("plotly")
# install.packages("imputeTS")
library(shiny)
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
library(imputeTS)
library(lubridate)
library(formattable)


# setwd("~/Documents/8vo_semestre/Data_Product/Final_Proyecto")
# confirmed <- read_csv("confirmed.csv")
# deaths <- read_csv("deaths.csv")
# recovered <- read_csv("recovered.csv")
# junto <- read_csv("junto.csv")
# 
# mundo <- map_data("world")


# Conexion SQL ------------------------------------------------------------

drv<- dbDriver("MySQL")
con<-dbConnect(drv,
               dbname= 'test',
               host= 'db',
               port= 3306,
               user= 'test',
               password= 'test123')

mundo <- map_data("world")

confirmed <- dbGetQuery(con,"SELECT * FROM test.confirmed")
deaths <- dbGetQuery(con,"SELECT * FROM test.deaths")
recovered<- dbGetQuery(con,"SELECT * FROM test.recovered")
junto <- dbGetQuery(con,"SELECT * FROM test.junto")


# Server ------------------------------------------------------------------


shinyServer(function(input, output, session) {
  
  output$image1<- renderUI({
    imgurl2 <- "https://www.who.int/images/default-source/mca/mca-covid-19/coronavirus-2.tmb-1200v.jpg?Culture=en&sfvrsn=4dba955c_6"
    tags$img(src=imgurl2)
  })
  
  output$tabla_j <- renderDataTable({
    todo <- junto
    colnames(todo) <- paste0('<span style="color:',"white",'">',
                                     colnames(todo),'</span>')
    datatable(todo,escape=F)
  })
  
  output$tabla_c <- renderDataTable({
    confirmada <- confirmed
    colnames(confirmada) <- paste0('<span style="color:',"white",'">',
                             colnames(confirmada),'</span>')
    datatable(confirmada,escape=F)
  })
  
  output$tabla_d <- renderDataTable({
    muertes <- deaths 
    colnames(muertes) <- paste0('<span style="color:',"white",'">',
                             colnames(muertes),'</span>')
    datatable(muertes,escape=F)
  })
  
  output$tabla_r <- renderDataTable({
    recuperados <- recovered
    colnames(recuperados) <- paste0('<span style="color:',"white",'">',
                             colnames(recuperados),'</span>')
    datatable(recuperados,escape=F)
  })
  
  output$grafica1 <- renderPlot({
    confirmed %>%
      arrange(valor) %>%
      mutate(country=factor(country,unique(country))) %>%
      filter(fecha == input$datum) %>% 
      ggplot() + 
      geom_polygon(data = mundo, aes(x=long, y=lat, group = group), fill= "grey", alpha=0.3) + 
      geom_point(aes(x=lng, y=lat, size=valor, color=valor), alpha=0.9) +
      scale_size_continuous(range=c(1,12),limits = c(0,max(confirmed$valor))) +
      scale_color_viridis(trans="log") +
      theme_void() +
      coord_map() +
      theme(plot.background = element_rect(fill = "#222222", color=NA),
            panel.background = element_rect(fill='#222222', color=NA),
            legend.text = element_text(color = "white"))
  })
  
  
  output$grafica2 <- renderPlot({
    deaths %>% 
      arrange(valor) %>% 
      mutate(country=factor(country,unique(country)))  %>% 
      filter(fecha == input$datum2) %>% 
      ggplot() +
      geom_polygon(data = mundo, aes(x=long, y=lat, group = group), fill= "grey", alpha=0.3) +
      geom_point(aes(x=lng, y=lat, size=valor, color=valor), alpha=0.9) +
      scale_size_continuous(range=c(1,12),limits = c(0,max(deaths$valor))) +
      scale_color_viridis(trans="log") +
      theme_void() +
      coord_map() + 
      theme(plot.background = element_rect(fill = "#222222", color=NA),
            panel.background = element_rect(fill='#222222', color=NA),
            legend.text = element_text(color = "white"))
  })
  
  output$grafica3 <- renderPlot({
    recovered %>% 
      arrange(valor) %>% 
      mutate(country=factor(country,unique(country)))  %>% 
      filter(fecha == input$datum3) %>% 
      ggplot() +
      geom_polygon(data = mundo, aes(x=long, y=lat, group = group), fill= "grey", alpha=0.3) +
      geom_point(aes(x=lng, y=lat, size=valor, color=valor), alpha=0.9) +
      scale_size_continuous(range=c(1,12),limits = c(0,max(recovered$valor))) +
      scale_color_viridis(trans="log") +
      theme_void() +
      coord_map() + 
      theme(plot.background = element_rect(fill = "#222222", color=NA),
            panel.background = element_rect(fill='#222222', color=NA),
            legend.text = element_text(color = "white"))
  })
  
  output$total <- renderPrint(
    paste(
      confirmed[which(confirmed$country==input$pais & confirmed$fecha==input$datum),"valor"]
      )
  )
  
  output$output_select1<-renderPrint({
    out<-input$pais
    print(out)
  })
  
  output$output_select2<-renderPrint({
    out<-input$datum
    print(out)
  })
  
  output$total2 <- renderPrint(
    paste(
      deaths[which(deaths$country==input$pais2 & deaths$fecha==input$datum2),"valor"]
    )
  )
  
  output$output_select12<-renderPrint({
    out<-input$pais2
    print(out)
  })
  
  output$output_select22<-renderPrint({
    out<-input$datum2
    print(out)
  })
  
  output$total3 <- renderPrint(
    paste(
      recovered[which(recovered$country==input$pais3 & recovered$fecha==input$datum3),"valor"]
    )
  )
  
  output$output_select13<-renderPrint({
    out<-input$pais3
    print(out)
  })
  
  output$output_select23<-renderPrint({
    out<-input$datum3
    print(out)
  })
  

  output$dygraph <- renderDygraph({
    prueba<-confirmed %>%
      group_by(fecha,country) %>%
      summarise(cases=sum(valor)) %>%
      filter(country==input$pais3,fecha>= "2020-10-22",fecha<="2021-10-22")
    
    prueba <- xts(x = prueba$cases, order.by = as.Date(prueba$fecha))
    #prueba <- ts_ts(ts_long(prueba))
    
    dygraph(main = "Casos Confirmados de Covid-19",prueba) %>%
      dyOptions( drawPoints = TRUE, pointSize = 2 ,fillGraph = TRUE,axisLabelColor = "white") %>% 
      dySeries(label = "Cases") %>% 
      dyRangeSelector() %>% 
      dyCrosshair(direction = "vertical") %>%
      dyHighlight(highlightCircleSize = 5, highlightSeriesBackgroundAlpha = 1, 
                  hideOnMouseOut = FALSE) 

  })
  
  output$grafica4 <- renderPlot({
    prueba2<-confirmed %>% 
      group_by(country) %>%
      summarise(cases=sum(valor)/1000000) 
    #vector<-c("Guatemala","Honduras", "Costa Rica")
    prueba2<-prueba2[prueba2$country %in% input$pais4,]
    
    p2<-ggplot(prueba2, aes(x=country, y=cases, fill=cases)) +
    ggtitle("Casos Confirmados Covid-19 por paises (Cifras en Millones)")+
    geom_bar(stat="identity")+theme_minimal()
    p2
  })
  
  
  output$grafica42 <- renderPlot({
    prueba2<-deaths %>% 
      group_by(country) %>%
      summarise(cases=sum(valor)/1000000) 
    #vector<-c("Guatemala","Honduras", "Costa Rica")
    prueba2<-prueba2[prueba2$country %in% input$pais5,]
    
    p2<-ggplot(prueba2, aes(x=country, y=cases, fill=cases)) +
      ggtitle("Total fallecidos por Covid-19 por paises (Cifras en Millones)")+
      geom_bar(stat="identity")+theme_minimal()
    p2
  })
  
  output$grafica43 <- renderPlot({
    prueba2<-recovered %>% 
      group_by(country) %>%
      summarise(cases=sum(valor)/1000000) 
    #vector<-c("Guatemala","Honduras", "Costa Rica")
    prueba2<-prueba2[prueba2$country %in% input$pais6,]
    
    p2<-ggplot(prueba2, aes(x=country, y=cases, fill=cases)) +
      ggtitle("Total fallecidos por Covid-19 por paises (Cifras en Millones)")+
      geom_bar(stat="identity")+theme_minimal()
    p2
  })
  

# Stats -------------------------------------------------------------------
  junto <- na.replace(junto, 0)
  CountryStats<- junto %>%
    group_by(country) %>%
    summarise(confirmedcs = sum(confirmed), deathscs = sum(deaths),recoveredcs = sum(recovered))
  RatDtc <- CountryStats %>%
    group_by(country) %>%
    summarise(DtC= deathscs/confirmedcs) %>%
    arrange(-DtC)
  RatDtc$DtC <- formattable::percent(RatDtc$DtC)
  RatRtc <- CountryStats %>%
    group_by(country) %>%
    summarise(RtC= (recoveredcs/confirmedcs)) %>%
    filter(RtC<1) %>%
    arrange(-RtC)
  RatRtc$RtC <- formattable::percent(RatRtc$RtC)
  TopMuertes <- CountryStats %>%
    group_by(country) %>%
    summarise(Topdeaths = sum(deathscs)) %>%
    arrange(-Topdeaths) %>%
    head(10)
  TopConfirmados <- CountryStats %>%
    group_by(country) %>%
    summarise(Topconf = sum(confirmedcs)) %>%
    arrange(-Topconf) %>%
    head(10)
  TopRecup <- CountryStats %>%
    group_by(country) %>%
    summarise(TopRecovered = sum(recoveredcs)) %>%
    arrange(-TopRecovered) %>%
    head(10)
  Totales <- junto %>%
    summarise(ConfirmedCases = sum(confirmed), DeathCases = sum(deaths), RecoveredCases = sum(recovered))
  FechaTop <- junto %>%
    group_by(fecha) %>%
    summarise(Confirmados = sum(confirmed), Muertes = sum(deaths), Recuperados = sum(recovered))
  
  
  output$tabla01 <- renderDataTable({
    tabla01 <- CountryStats
    colnames(tabla01) <- paste0('<span style="color:',"white",'">',colnames(tabla01),'</span>')
    datatable(tabla01,escape=F)
  })
  
  output$tabla02 <- renderDataTable({
    tabla02 <- RatDtc 
    colnames(tabla02) <- paste0('<span style="color:',"white",'">',colnames(tabla02),'</span>')
    datatable(tabla02,escape=F)
  })
  
  output$tabla03 <- renderDataTable({
    tabla03 <- RatRtc
    colnames(tabla03) <- paste0('<span style="color:',"white",'">',colnames(tabla03),'</span>')
    datatable(tabla03,escape=F)
  })
  
  output$tabla04 <- renderDataTable({
    tabla04 <- TopMuertes
    colnames(tabla04) <- paste0('<span style="color:',"white",'">',colnames(tabla04),'</span>')
    datatable(tabla04,escape=F)
  })
  
})











