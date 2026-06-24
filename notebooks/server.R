library(shiny)
library(shinydashboard)
library(leaflet)
library(sf)
library(dplyr)
library(readr)
library(tigris)
library(stringr)
library(plotly)
library(DT)
library(viridis)

options(tigris_use_cache = TRUE)

# Load data
master <- read_csv("../data/master_df.csv")

master$fips <- master$fips |>
  as.character() |>
  str_pad(width = 5, side = "left", pad = "0")

# County boundaries
counties_sf <- tigris::counties(
  cb = TRUE,
  year = 2024
)

counties_sf$fips <- paste0(
  counties_sf$STATEFP,
  counties_sf$COUNTYFP
)

# Merge data with geography
map_df <- counties_sf |>
  left_join(master, by = "fips")

function(input, output, session) {
  
  filtered <- reactive({
    map_df
  })
  
  output$total_deaths <- renderValueBox({
    valueBox(
      value = format(sum(filtered()$deaths, na.rm = TRUE), big.mark = ","),
      subtitle = "Total Opioid Deaths",
      icon = icon("skull-crossbones"),
      color = "red"
    )
  })
  
  output$avg_overdose_rate <- renderValueBox({
    valueBox(
      value = round(mean(filtered()$overdose_rate, na.rm = TRUE), 1),
      subtitle = "Average Overdose Rate",
      icon = icon("chart-line"),
      color = "orange"
    )
  })
  
  output$total_facilities <- renderValueBox({
    valueBox(
      value = format(sum(filtered()$facility_count, na.rm = TRUE), big.mark = ","),
      subtitle = "Total Facilities",
      icon = icon("hospital"),
      color = "blue"
    )
  })
  
  output$avg_income <- renderValueBox({
    valueBox(
      value = paste0("$", format(round(mean(filtered()$median_income, na.rm = TRUE)), big.mark = ",")),
      subtitle = "Average Median Income",
      icon = icon("dollar-sign"),
      color = "green"
    )
  })
  
  output$map <- renderLeaflet({
    
    df <- filtered()
    
    pal <- colorNumeric(
      palette = "viridis",
      domain = df[[input$metric]],
      na.color = "#d9d9d9"
    )
    
    leaflet(df) |>
      addProviderTiles(providers$CartoDB.Positron) |>
      fitBounds(
        lng1 = -128,
        lat1 = 23,
        lng2 = -65,
        lat2 = 50
      ) |>
      addPolygons(
        fillColor = ~pal(get(input$metric)),
        fillOpacity = 0.8,
        weight = 0.4,
        color = "white",
        smoothFactor = 0.2,
        
        label = ~paste0(
          NAME,
          ": ",
          round(get(input$metric), 2)
        ),
        
        popup = ~paste0(
          "<b>", NAME, "</b>",
          "<br><b>Deaths:</b> ", deaths,
          "<br><b>Overdose Rate:</b> ", round(overdose_rate, 2),
          "<br><b>Facilities:</b> ", facility_count,
          "<br><b>Facility Rate:</b> ", round(facility_rate, 2),
          "<br><b>Population:</b> ", format(population, big.mark = ","),
          "<br><b>Median Income:</b> $", format(median_income, big.mark = ","),
          "<br><b>Poverty Rate:</b> ", poverty_rate, "%"
        ),
        
        highlightOptions = highlightOptions(
          weight = 3,
          color = "#333333",
          bringToFront = TRUE
        )
      ) |>
      addLegend(
        position = "bottomright",
        pal = pal,
        values = df[[input$metric]],
        title = input$metric
      )
  })
  
  output$top_counties_plot <- renderPlotly({
    
    df <- filtered() |>
      st_drop_geometry() |>
      filter(!is.na(.data[[input$metric]])) |>
      arrange(desc(.data[[input$metric]])) |>
      slice_head(n = 20)
    
    plot_ly(
      df,
      x = ~.data[[input$metric]],
      y = ~reorder(NAME, .data[[input$metric]]),
      type = "bar",
      orientation = "h"
    ) |>
      layout(
        title = paste("Top 20 Counties by", input$metric),
        xaxis = list(title = input$metric),
        yaxis = list(title = "")
      )
  })
  
  output$data_table <- renderDT({
    
    filtered() |>
      st_drop_geometry() |>
      datatable(
        options = list(
          pageLength = 15,
          scrollX = TRUE
        )
      )
  })
}