library(shiny)
library(leaflet)

fluidPage(
  
  titlePanel(
    "US Opioid Overdose 2024 Deaths and Facility Analysis"
  ),
  
  sidebarLayout(
    
    sidebarPanel(
      
      selectInput(
        "metric",
        "Map Variable",
        
        choices = c(
          "Deaths"="deaths",
          "Overdose Rate"="overdose_rate",
          "Facility Count"="facility_count",
          "Population"="population",
          "Median Income"="median_income",
          "Poverty Rate"="poverty_rate",
          "Male Deaths"="male_deaths",
          "Female Deaths"="female_deaths",
          "Place of Death"="place_of_death_count"
        )
        
      ),
      
      selectInput(
        "gender",
        "Gender",
        
        choices = c(
          "All",
          "Male",
          "Female"
        )
      )
      
    ),
    
    # ← THIS WAS MISSING
    mainPanel(
      
      leafletOutput(
        "map",
        height = 800
      )
      
    )
    
  )
  
)