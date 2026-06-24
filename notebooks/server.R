library(shiny)
library(leaflet)
library(sf)
library(dplyr)
library(readr)
library(tigris)
library(stringr)

options(
  tigris_use_cache = TRUE
)

# LOAD DATA

master <-
  read_csv(
    "../data/master_df.csv"
  )

master$fips <-
  master$fips |>
  as.character() |>
  str_pad(
    width = 5,
    pad = "0"
  )

# COUNTY SHAPES

counties_sf <-
  tigris::counties(
    cb = TRUE,
    year = 2024
  )

counties_sf$fips <-
  paste0(
    counties_sf$STATEFP,
    counties_sf$COUNTYFP
  )

# MERGE
map_df <-
  
  counties_sf |>
  
  left_join(
    master,
    by = "fips"
  )

# SERVER

function(
    input,
    output,
    session
){
  
  # FILTER
  
  filtered <- reactive({
    
    df <- map_df
    
    if(
      input$gender=="Male"
    ){
      
      if(
        "sex" %in% names(df)
      ){
        
        df <-
          df[
            df$sex=="Male",
          ]
        
      }
      
    }
    
    if(
      input$gender=="Female"
    ){
      
      if(
        "sex" %in% names(df)
      ){
        
        df <-
          df[
            df$sex=="Female",
          ]
        
      }
      
    }
    
    df
    
  })
  
  # MAP
  
  output$map <-
    
    renderLeaflet({
      
      df <-
        
        filtered()
      
      pal <-
        
        colorNumeric(
          
          palette="viridis",
          
          domain=
            df[[input$metric]],
          
          na.color=
            "#d9d9d9"
          
        )
      
      leaflet(
        df
      ) |>
        
        addProviderTiles(
          providers$CartoDB.Positron
        ) |>
        
        fitBounds(
          
          lng1=-128,
          lat1=23,
          
          lng2=-65,
          lat2=50
          
        ) |>
        
        addPolygons(
          
          fillColor=
            ~pal(
              get(
                input$metric
              )
            ),
          
          fillOpacity=.8,
          
          weight=.5,
          
          color="white",
          
          smoothFactor=.2,
          
          label=
            ~paste0(
              NAME,
              ": ",
              round(
                get(
                  input$metric
                ),
                1
              )
            ),
          
          popup=
            ~paste0(
              
              "<b>",
              
              NAME,
              
              "</b>",
              
              "<br><b>Deaths:</b> ",
              deaths,
              
              "<br><b>Population:</b> ",
              format(
                population,
                big.mark=","
              ),
              
              "<br><b>Income:</b> $",
              format(
                median_income,
                big.mark=","
              ),
              
              "<br><b>Poverty:</b> ",
              poverty_rate,
              
              "%",
              
              "<br><b>Overdose Rate:</b> ",
              round(
                overdose_rate,
                1
              )
              
            ),
          
          highlightOptions=
            highlightOptions(
              
              weight=3,
              
              bringToFront=TRUE
              
            )
          
        ) |>
        
        addLegend(
          
          position=
            "bottomright",
          
          pal=
            pal,
          
          values=
            df[[input$metric]],
          
          title=
            input$metric
          
        )
      
    })
  
}