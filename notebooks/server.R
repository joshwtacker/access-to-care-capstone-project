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

# ---------------------------------------------------------------------------
# Human-readable labels for each metric
# ---------------------------------------------------------------------------
metric_labels <- c(
  deaths         = "Total Opioid Deaths (2018-2024)",
  overdose_rate  = "Overdose Rate (per 100k, age-adjusted)",
  facility_count = "Treatment Facility Count",
  facility_rate  = "Treatment Facility Rate (per 100k)",
  population     = "County Population (single year)",
  median_income  = "Median Household Income ($)",
  poverty_rate   = "Poverty Rate (%)",
  gap_score      = "Access Gap Score (Overdose Rate - Facility Rate)"
)

# ---------------------------------------------------------------------------
# Load and clean data
# ---------------------------------------------------------------------------
master_raw <- read_csv("../data/master_df.csv")

# FIX 1: Only rename Population -> population_7yr if that column actually exists.
# The capital-P Population column may not be present depending on your CDC export.
if ("Population" %in% names(master_raw)) {
  master_raw <- master_raw |> rename(population_7yr = Population)
}

master <- master_raw |>
  # Drop territory/unmatched rows
  filter(!is.na(fips), as.character(fips) != "0") |>
  mutate(
    # FIX 2: Robust FIPS cleaning — handles numeric (1001), float (1001.0),
    # and string ("01001") formats that all come out of Python's to_csv.
    fips = str_pad(
      as.character(as.integer(suppressWarnings(as.numeric(fips)))),
      width = 5, side = "left", pad = "0"
    ),
    state     = str_extract(county_state, "[A-Z]{2}$"),
    gap_score = overdose_rate - facility_rate,
    # FIX 3: Add unemployment_rate as NA if missing (column referenced in
    # popups and data table but not always present in master_df).
    unemployment_rate = if ("unemployment_rate" %in% names(master_raw))
      unemployment_rate
    else
      NA_real_
  )

# ---------------------------------------------------------------------------
# County boundaries from tigris
# ---------------------------------------------------------------------------
counties_sf <- tigris::counties(cb = TRUE, year = 2024)
counties_sf$fips <- paste0(counties_sf$STATEFP, counties_sf$COUNTYFP)

# Merge — left join keeps all counties even if no data match
map_df <- counties_sf |>
  left_join(master, by = "fips")

# Sorted list of states for the sidebar filter
state_choices <- sort(unique(na.omit(master$state)))

# ---------------------------------------------------------------------------
# Server
# ---------------------------------------------------------------------------
server <- function(input, output, session) {
  
  updateSelectizeInput(session, "state_filter", choices = state_choices, server = TRUE)
  
  filtered <- reactive({
    df <- map_df
    if (!is.null(input$state_filter) && length(input$state_filter) > 0) {
      df <- df |> filter(state %in% input$state_filter)
    }
    df
  })
  
  # ---- Value boxes --------------------------------------------------------
  
  output$total_deaths <- renderValueBox({
    valueBox(
      value    = format(sum(filtered()$deaths, na.rm = TRUE), big.mark = ","),
      subtitle = "Total Opioid Deaths (2018-2024)",
      icon     = icon("skull-crossbones"),
      color    = "red"
    )
  })
  
  output$avg_overdose_rate <- renderValueBox({
    valueBox(
      value    = round(mean(filtered()$overdose_rate, na.rm = TRUE), 1),
      subtitle = "Avg Overdose Rate (per 100k)",
      icon     = icon("chart-line"),
      color    = "orange"
    )
  })
  
  output$total_facilities <- renderValueBox({
    valueBox(
      value    = format(sum(filtered()$facility_count, na.rm = TRUE), big.mark = ","),
      subtitle = "Total Treatment Facilities",
      icon     = icon("hospital"),
      color    = "blue"
    )
  })
  
  output$avg_income <- renderValueBox({
    valueBox(
      value    = paste0("$", format(round(mean(filtered()$median_income, na.rm = TRUE)), big.mark = ",")),
      subtitle = "Avg Median Household Income",
      icon     = icon("dollar-sign"),
      color    = "green"
    )
  })
  
  # ---- Choropleth map -----------------------------------------------------
  
  output$map <- renderLeaflet({
    
    df         <- filtered()
    metric_col <- input$metric
    label_text <- metric_labels[[metric_col]]
    
    # Guard: if all values are NA the palette will error
    vals <- df[[metric_col]]
    if (all(is.na(vals))) {
      return(leaflet() |> addProviderTiles(providers$CartoDB.Positron) |>
               fitBounds(lng1 = -128, lat1 = 23, lng2 = -65, lat2 = 50))
    }
    
    pal <- colorNumeric(
      palette  = "viridis",
      domain   = vals,
      na.color = "#d9d9d9"
    )
    
    leaflet(df) |>
      addProviderTiles(providers$CartoDB.Positron) |>
      fitBounds(lng1 = -128, lat1 = 23, lng2 = -65, lat2 = 50) |>
      addPolygons(
        fillColor   = ~pal(get(metric_col)),
        fillOpacity = 0.8,
        weight      = 0.4,
        color       = "white",
        smoothFactor = 0.2,
        label = ~paste0(NAME, ": ", round(get(metric_col), 2)),
        popup = ~paste0(
          "<b>", NAME, "</b>",
          "<br><b>Deaths (2018-2024):</b> ",          ifelse(is.na(deaths), "Suppressed", deaths),
          "<br><b>Overdose Rate (per 100k):</b> ",    ifelse(is.na(overdose_rate), "N/A", round(overdose_rate, 2)),
          "<br><b>Facilities:</b> ",                  ifelse(is.na(facility_count), "N/A", facility_count),
          "<br><b>Facility Rate (per 100k):</b> ",    ifelse(is.na(facility_rate), "N/A", round(facility_rate, 2)),
          "<br><b>Access Gap Score:</b> ",            ifelse(is.na(gap_score), "N/A", round(gap_score, 2)),
          "<br><b>Population:</b> ",                  ifelse(is.na(population), "N/A", format(population, big.mark = ",")),
          "<br><b>Median Income:</b> $",              ifelse(is.na(median_income), "N/A", format(median_income, big.mark = ",")),
          "<br><b>Poverty Rate:</b> ",                ifelse(is.na(poverty_rate), "N/A", paste0(poverty_rate, "%")),
          "<br><b>Unemployment Rate:</b> ",           ifelse(is.na(unemployment_rate), "N/A", paste0(unemployment_rate, "%"))
        ),
        highlightOptions = highlightOptions(
          weight      = 3,
          color       = "#333333",
          bringToFront = TRUE
        )
      ) |>
      addLegend(
        position = "bottomright",
        pal      = pal,
        values   = vals,
        title    = label_text
      )
  })
  
  # ---- Top 20 bar chart ---------------------------------------------------
  
  output$top_counties_plot <- renderPlotly({
    
    metric_col <- input$metric
    label_text <- metric_labels[[metric_col]]
    
    df <- filtered() |>
      st_drop_geometry() |>
      filter(!is.na(.data[[metric_col]])) |>
      arrange(desc(.data[[metric_col]])) |>
      slice_head(n = 20)
    
    plot_ly(
      df,
      x           = ~.data[[metric_col]],
      y           = ~reorder(NAME, .data[[metric_col]]),
      type        = "bar",
      orientation = "h",
      marker      = list(color = "steelblue")
    ) |>
      layout(
        title  = list(text = paste("Top 20 Counties by", label_text), x = 0),
        xaxis  = list(title = label_text),
        yaxis  = list(title = ""),
        margin = list(l = 160)
      )
  })
  
  # ---- At-risk county table -----------------------------------------------
  
  output$risk_table <- renderDT({
    
    df <- filtered() |>
      st_drop_geometry() |>
      filter(
        !is.na(overdose_rate),
        !is.na(poverty_rate),
        !is.na(facility_rate)
      ) |>
      mutate(
        norm_overdose = (overdose_rate - min(overdose_rate)) / (max(overdose_rate) - min(overdose_rate)),
        norm_poverty  = (poverty_rate  - min(poverty_rate))  / (max(poverty_rate)  - min(poverty_rate)),
        norm_low_fac  = 1 - (facility_rate - min(facility_rate)) / (max(facility_rate) - min(facility_rate)),
        risk_score    = round(((norm_overdose + norm_poverty + norm_low_fac) / 3) * 100, 1)
      ) |>
      arrange(desc(risk_score)) |>
      slice_head(n = input$risk_n) |>
      mutate(Rank = row_number()) |>
      select(
        Rank,
        County             = county_state,
        State              = state,
        `Risk Score`       = risk_score,
        `Overdose Rate`    = overdose_rate,
        `Poverty Rate (%)`  = poverty_rate,
        `Facility Rate`    = facility_rate,
        `Facility Count`   = facility_count,
        `Median Income`    = median_income,
        Population         = population
      ) |>
      mutate(
        `Overdose Rate` = round(`Overdose Rate`, 2),
        `Facility Rate` = round(`Facility Rate`, 2)
      )
    
    datatable(
      df,
      rownames = FALSE,
      options  = list(pageLength = 25, scrollX = TRUE, dom = "tip")
    ) |>
      formatStyle(
        "Risk Score",
        background         = styleColorBar(c(0, 100), "rgba(220, 53, 69, 0.25)"),
        backgroundSize     = "100% 90%",
        backgroundRepeat   = "no-repeat",
        backgroundPosition = "center"
      )
  })
  
  # ---- Data table ---------------------------------------------------------
  
  output$data_table <- renderDT({
    
    filtered() |>
      st_drop_geometry() |>
      select(
        County              = county_state,
        State               = state,
        FIPS                = fips,
        Deaths              = deaths,
        `Overdose Rate`     = overdose_rate,
        `Facility Count`    = facility_count,
        `Facility Rate`     = facility_rate,
        `Gap Score`         = gap_score,
        Population          = population,
        `Median Income`     = median_income,
        `Poverty Rate`      = poverty_rate,
        `Unemployment Rate` = unemployment_rate
      ) |>
      mutate(
        `Overdose Rate` = round(`Overdose Rate`, 2),
        `Facility Rate` = round(`Facility Rate`, 2),
        `Gap Score`     = round(`Gap Score`, 2)
      ) |>
      datatable(
        options  = list(pageLength = 15, scrollX = TRUE),
        rownames = FALSE
      )
  })
}