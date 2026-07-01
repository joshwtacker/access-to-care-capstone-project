library(shiny)
library(shinydashboard)
library(shinyjs)
library(leaflet)
library(plotly)
library(DT)

ui <- dashboardPage(
  
  dashboardHeader(title = "Opioid Access Dashboard"),
  
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
        "Total Deaths"                    = "deaths",
        "Overdose Rate (per 100k)"        = "overdose_rate",
        "Facility Count"                  = "facility_count",
        "Facility Rate (per 100k)"        = "facility_rate",
        "Access Gap Score"                = "gap_score",
        "Urban–Rural Class. (RUCC 1–9)"  = "rucc",
        "Population"                      = "population",
        "Median Income"                   = "median_income",
        "Poverty Rate"                    = "poverty_rate"
      ),
      selected = "overdose_rate"
    ),
    
    hr(),
    
    selectizeInput(
      "state_filter",
      "Filter by State",
      choices  = NULL,
      multiple = TRUE,
      options  = list(placeholder = "All states")
    ),
    
    # RUCC / urban-rural filter — only meaningful with RUCC data
    div(
      id = "rucc_filter_box",
      selectInput(
        "rucc_filter",
        "Filter by Urban–Rural Type",
        choices = c(
          "All counties"         = "all",
          "Metro (RUCC 1–3)"     = "metro",
          "Non-metro (RUCC 4–6)" = "nonmetro",
          "Rural (RUCC 7–9)"     = "rural"
        ),
        selected = "all"
      )
    )
  ),
  
  dashboardBody(
    
    useShinyjs(),
    
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side { background-color: #f4f6f9; }
        .box       { border-radius: 8px; }
        .small-box { border-radius: 8px; }
        .sidebar-menu .treeview-menu > li > a { padding-left: 30px; }
        .rucc-legend { font-size: 11px; padding: 4px 8px; background: #fff;
                       border: 1px solid #ddd; border-radius: 4px; }
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
          valueBoxOutput("high_risk_rural",   width = 3)   # NEW: rural high-risk callout
        ),
        
        fluidRow(
          box(
            title       = "Interactive County Map",
            width       = 12,
            status      = "primary",
            solidHeader = TRUE,
            
            # RUCC quick-reference legend shown only when RUCC is selected
            conditionalPanel(
              condition = "input.metric == 'rucc'",
              div(
                class = "rucc-legend",
                strong("RUCC Scale:"),
                " 1–3 = Metro  ·  4–6 = Non-metro  ·  7–9 = Rural/Remote  ·  ",
                "Higher number = more rural"
              )
            ),
            
            leafletOutput("map", height = 680)
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
                       min = 5, max = 100, value = 25, step = 5
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
                    scaled to 0–100. Counties missing any input are excluded."),
                       p(em("Tip: use the Urban–Rural filter in the sidebar to see
                        the most at-risk rural counties specifically."))
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
            
            h4("Key Findings"),
            tags$ul(
              tags$li(strong("Poverty (r = +0.29) and unemployment (r = +0.23)"),
                      " are positively correlated with overdose mortality; income is protective (r = −0.24). All p < 0.001."),
              tags$li(strong("462 counties"), " fall into the 'High Risk, Low Access' quadrant —
                      above-median overdose rates with below-median facility access."),
              tags$li("After controlling for urban–rural classification (RUCC), ",
                      strong("rural counties show significantly higher overdose mortality"),
                      " independent of socioeconomic factors (RUCC coef = −33.4, p < 0.001)."),
              tags$li(strong("McDowell County, WV"), " leads the composite risk score at 91.9/100.
                      West Virginia and Kentucky dominate the top 25 most at-risk counties.")
            ),
            
            h4("Data Sources"),
            tags$ul(
              tags$li(tags$a("CDC WONDER", href = "https://wonder.cdc.gov/", target = "_blank"),
                      " — Opioid overdose mortality data, 2018–2024. Counties with fewer than
                        10 deaths are suppressed per CDC policy and appear as NA."),
              tags$li(tags$a("U.S. Census Bureau ACS", href = "https://www.census.gov/programs-surveys/acs", target = "_blank"),
                      " — 5-year estimates: median household income, poverty rate,
                        unemployment rate, county population."),
              tags$li(tags$a("SAMHSA Treatment Facility Locator", href = "https://findtreatment.gov/", target = "_blank"),
                      " — Substance abuse treatment facility locations used to calculate
                        facility counts and rates per 100,000 population."),
              tags$li(tags$a("USDA Rural-Urban Continuum Codes (2023)", href = "https://www.ers.usda.gov/data-products/rural-urban-continuum-codes/", target = "_blank"),
                      " — 9-category county classification from most urban (1) to most
                        rural/remote (9), used to control for urbanicity in regression analysis.")
            ),
            
            h4("Key Metrics"),
            tags$ul(
              tags$li(strong("Overdose Rate:"), " Age-adjusted opioid overdose deaths per 100,000 person-years, 2018–2024."),
              tags$li(strong("Facility Rate:"), " SAMHSA-listed treatment facilities per 100,000 residents."),
              tags$li(strong("Access Gap Score:"), " Overdose Rate minus Facility Rate. Higher = more unmet need."),
              tags$li(strong("Composite Risk Score:"), " Equal-weighted average of normalized overdose rate, poverty rate,
                      and inverse facility rate, scaled 0–100."),
              tags$li(strong("RUCC:"), " USDA Rural-Urban Continuum Code (1 = largest metro, 9 = most remote rural).")
            ),
            
            h4("Limitations"),
            tags$ul(
              tags$li("CDC WONDER suppresses counties with fewer than 10 deaths — rural low-mortality counties are underrepresented."),
              tags$li("Facility presence does not capture capacity, quality, cost, or actual patient access."),
              tags$li("All findings are correlational, not causal."),
              tags$li("Socioeconomic data reflects ACS 5-year estimates and may not perfectly align with the mortality period.")
            )
          ),
          
          box(
            title       = "How to Use This Dashboard",
            width       = 4,
            status      = "info",
            solidHeader = TRUE,
            
            h4("Map"),
            p("Use the ", strong("Map Variable"), " dropdown to change what's displayed.
               Select ", strong("Urban–Rural Class. (RUCC 1–9)"), " to see the geographic
               distribution of rurality. Click any county for a full data popup."),
            
            h4("Filters"),
            p("Use ", strong("Filter by State"), " and ", strong("Filter by Urban–Rural Type"),
              " together to focus on specific geographies — e.g., select 'Rural (RUCC 7–9)'
               to see only the most remote counties."),
            
            h4("County Rankings"),
            p("The Rankings tab shows top 20 counties for the selected metric,
               and the At-Risk table uses a composite score across overdose rate,
               poverty, and facility access. Try filtering to Rural counties to
               see the most underserved remote areas."),
            
            h4("Data Table"),
            p("Full county dataset with RUCC codes and urban–rural category labels.
               Searchable, sortable, and exportable.")
          )
        )
      )
    )
  )
)