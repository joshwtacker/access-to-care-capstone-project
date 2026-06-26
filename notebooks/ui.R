library(shiny)
library(shinydashboard)
library(leaflet)
library(plotly)
library(DT)

# state_choices is defined in server.R after data is loaded;
# we reference it here via the shared global environment.

ui <- dashboardPage(
  
  dashboardHeader(
    title = "Opioid Access Dashboard"
  ),
  
  dashboardSidebar(
    
    sidebarMenu(
      menuItem("Map",             tabName = "map_tab",      icon = icon("map")),
      menuItem("County Rankings", tabName = "rankings_tab", icon = icon("chart-bar")),
      menuItem("Data Table",      tabName = "data_tab",     icon = icon("table")),
      menuItem("About",           tabName = "about_tab",    icon = icon("circle-info"))
    ),
    
    hr(),
    
    selectInput(
      "metric",
      "Map Variable",
      choices = c(
        "Total Deaths"              = "deaths",
        "Overdose Rate (per 100k)"  = "overdose_rate",
        "Facility Count"            = "facility_count",
        "Facility Rate (per 100k)"  = "facility_rate",
        "Access Gap Score"          = "gap_score",
        "Population"                = "population",
        "Median Income"             = "median_income",
        "Poverty Rate"              = "poverty_rate"
      ),
      selected = "overdose_rate"
    ),
    
    hr(),
    
    # State filter — populated from data in server.R via updateSelectInput,
    # or you can hardcode state_choices here after sourcing server.R first.
    selectizeInput(
      "state_filter",
      "Filter by State",
      choices  = NULL,   # filled in server via updateSelectizeInput
      multiple = TRUE,
      options  = list(placeholder = "All states")
    )
  ),
  
  dashboardBody(
    
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side { background-color: #f4f6f9; }
        .box        { border-radius: 8px; }
        .small-box  { border-radius: 8px; }
        .sidebar-menu .treeview-menu > li > a { padding-left: 30px; }
      "))
    ),
    
    tabItems(
      
      # ---- Map tab ---------------------------------------------------------
      tabItem(
        tabName = "map_tab",
        
        fluidRow(
          valueBoxOutput("total_deaths",      width = 3),
          valueBoxOutput("avg_overdose_rate", width = 3),
          valueBoxOutput("total_facilities",  width = 3),
          valueBoxOutput("avg_income",        width = 3)
        ),
        
        fluidRow(
          box(
            title       = "Interactive County Map",
            width       = 12,
            status      = "primary",
            solidHeader = TRUE,
            leafletOutput("map", height = 700)
          )
        )
      ),
      
      # ---- Rankings tab ----------------------------------------------------
      tabItem(
        tabName = "rankings_tab",
        
        fluidRow(
          box(
            title       = "Top 20 Counties by Selected Metric",
            width       = 12,
            status      = "warning",
            solidHeader = TRUE,
            plotlyOutput("top_counties_plot", height = 600)
          )
        ),
        
        fluidRow(
          box(
            title       = "Counties Most At Risk",
            width       = 12,
            status      = "danger",
            solidHeader = TRUE,
            
            fluidRow(
              column(4,
                     sliderInput(
                       "risk_n",
                       "Number of counties to show:",
                       min   = 5,
                       max   = 100,
                       value = 25,
                       step  = 5
                     )
              ),
              column(8,
                     div(
                       style = "padding-top: 8px; font-size: 13px; color: #555;",
                       strong("How the Risk Score is calculated:"),
                       p("Each county is scored on three equally-weighted components,
                    each normalized 0–1 across all counties with available data:"),
                       tags$ul(
                         tags$li(strong("Overdose Rate (higher = worse):"),
                                 " higher overdose rate per 100k → higher risk"),
                         tags$li(strong("Poverty Rate (higher = worse):"),
                                 " higher poverty rate → higher risk"),
                         tags$li(strong("Facility Rate (lower = worse):"),
                                 " fewer treatment facilities per 100k → higher risk")
                       ),
                       p("Composite Risk Score = average of three normalized components,
                    scaled to 0–100. Counties missing any input are excluded.")
                     )
              )
            ),
            
            DTOutput("risk_table")
          )
        )
      ),
      
      # ---- Data table tab --------------------------------------------------
      tabItem(
        tabName = "data_tab",
        
        fluidRow(
          box(
            title       = "County-Level Dataset",
            width       = 12,
            status      = "info",
            solidHeader = TRUE,
            DTOutput("data_table")
          )
        )
      ),
      
      # ---- About tab -------------------------------------------------------
      tabItem(
        tabName = "about_tab",
        
        fluidRow(
          box(
            title       = "About This Project",
            width       = 8,
            status      = "primary",
            solidHeader = TRUE,
            
            h3("Access to Care: Opioid Overdose Risk and Treatment Availability in the U.S."),
            p(strong("Author:"), " Josh Tacker | Capstone Project"),
            hr(),
            
            h4("Project Overview"),
            p("This dashboard explores the relationship between opioid overdose mortality,
               socioeconomic conditions, and substance abuse treatment access across U.S.
               counties from 2018–2024. The central goal is to identify geographic disparities
               where overdose risk is high but treatment resources are limited."),
            
            h4("Research Questions"),
            tags$ol(
              tags$li("How do socioeconomic factors (income, poverty, unemployment) correlate with opioid overdose mortality rates?"),
              tags$li("Are treatment facilities distributed in proportion to overdose mortality rates?"),
              tags$li("Does treatment access correlate with lower overdose mortality?"),
              tags$li("Which counties show the largest gaps between overdose risk and treatment availability?")
            ),
            
            h4("Data Sources"),
            tags$ul(
              tags$li(tags$a("CDC WONDER", href = "https://wonder.cdc.gov/", target = "_blank"),
                      " — Opioid overdose mortality data, 2018–2024. Age-adjusted death rates
                        per 100,000 population. Counties with fewer than 10 deaths are suppressed
                        per CDC policy and appear as NA in this dataset."),
              tags$li(tags$a("U.S. Census Bureau American Community Survey (ACS)", href = "https://www.census.gov/programs-surveys/acs", target = "_blank"),
                      " — 5-year estimates for median household income, poverty rate,
                        unemployment rate, and county population."),
              tags$li(tags$a("SAMHSA Treatment Facility Locator", href = "https://findtreatment.gov/", target = "_blank"),
                      " — Substance abuse treatment facility locations used to calculate
                        facility counts and rates per 100,000 population by county.")
            ),
            
            h4("Key Metrics"),
            tags$ul(
              tags$li(strong("Overdose Rate:"), " Age-adjusted opioid overdose deaths per 100,000 person-years, aggregated 2018–2024."),
              tags$li(strong("Facility Rate:"), " Number of SAMHSA-listed treatment facilities per 100,000 residents."),
              tags$li(strong("Access Gap Score:"), " Overdose Rate minus Facility Rate. Higher values indicate counties
                      where mortality burden is high relative to available treatment — these are
                      the highest-priority areas for resource allocation.")
            ),
            
            h4("Limitations"),
            tags$ul(
              tags$li("CDC WONDER suppresses death counts for counties with fewer than 10 deaths, creating missing data in rural and low-population areas."),
              tags$li("Facility presence does not capture facility capacity, quality, or whether patients can actually afford or access care."),
              tags$li("Socioeconomic data reflects ACS 5-year estimates and may not perfectly align with the mortality observation period.")
            )
          ),
          
          box(
            title       = "How to Use This Dashboard",
            width       = 4,
            status      = "info",
            solidHeader = TRUE,
            
            h4("Map"),
            p("Use the ", strong("Map Variable"), " dropdown in the sidebar to change what's
               displayed on the choropleth map. Click any county to see a full data popup.
               Hover for a quick label."),
            
            h4("State Filter"),
            p("Use the ", strong("Filter by State"), " control to focus the map,
               rankings chart, and data table on one or more states."),
            
            h4("County Rankings"),
            p("The Rankings tab shows the top 20 counties for whichever metric is selected.
               Use this alongside the Access Gap Score to find the most underserved counties."),
            
            h4("Data Table"),
            p("The Data Table tab shows the full county-level dataset. You can search,
               sort, and export it using the table controls.")
          )
        )
      )
    )
  )
)