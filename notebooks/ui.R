library(shiny)
library(shinydashboard)
library(leaflet)
library(plotly)
library(DT)

dashboardPage(
  
  dashboardHeader(
    title = "Opioid Access Dashboard"
  ),
  
  dashboardSidebar(
    
    sidebarMenu(
      menuItem("Map", tabName = "map_tab", icon = icon("map")),
      menuItem("County Rankings", tabName = "rankings_tab", icon = icon("chart-bar")),
      menuItem("Data Table", tabName = "data_tab", icon = icon("table")),
      menuItem("About", tabName = "about_tab", icon = icon("circle-info"))
    ),
    
    hr(),
    
    selectInput(
      "metric",
      "Map Variable",
      choices = c(
        "Deaths" = "deaths",
        "Overdose Rate" = "overdose_rate",
        "Facility Count" = "facility_count",
        "Facility Rate" = "facility_rate",
        "Population" = "population",
        "Median Income" = "median_income",
        "Poverty Rate" = "poverty_rate"
      )
    )
  ),
  
  dashboardBody(
    
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f4f6f9;
        }
        .box {
          border-radius: 8px;
        }
        .small-box {
          border-radius: 8px;
        }
      "))
    ),
    
    tabItems(
      
      tabItem(
        tabName = "map_tab",
        
        fluidRow(
          valueBoxOutput("total_deaths", width = 3),
          valueBoxOutput("avg_overdose_rate", width = 3),
          valueBoxOutput("total_facilities", width = 3),
          valueBoxOutput("avg_income", width = 3)
        ),
        
        fluidRow(
          box(
            title = "Interactive County Map",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            leafletOutput("map", height = 700)
          )
        )
      ),
      
      tabItem(
        tabName = "rankings_tab",
        
        fluidRow(
          box(
            title = "Top 20 Counties by Selected Metric",
            width = 12,
            status = "warning",
            solidHeader = TRUE,
            plotlyOutput("top_counties_plot", height = 600)
          )
        )
      ),
      
      tabItem(
        tabName = "data_tab",
        
        fluidRow(
          box(
            title = "County-Level Dataset",
            width = 12,
            status = "info",
            solidHeader = TRUE,
            DTOutput("data_table")
          )
        )
      ),
      
      tabItem(
        tabName = "about_tab",
        
        fluidRow(
          box(
            title = "About This Project",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            
            h3("Access to Care: Opioid Overdose Risk and Treatment Availability"),
            
            p("This dashboard explores opioid overdose mortality, socioeconomic factors, and substance abuse treatment access across U.S. counties from 2018-2024."),
            
            tags$ul(
              tags$li("CDC opioid overdose mortality data"),
              tags$li("U.S. Census ACS socioeconomic data"),
              tags$li("SAMHSA treatment facility data")
            ),
            
            p("The goal is to identify counties where overdose risk is high and treatment access may be limited.")
          )
        )
      )
    )
  )
)