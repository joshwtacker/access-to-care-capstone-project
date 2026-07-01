library(shiny)
library(shinydashboard)
library(shinyjs)
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
  deaths         = "Total Opioid Deaths (2018–2024)",
  overdose_rate  = "Overdose Rate (per 100k, age-adjusted)",
  facility_count = "Treatment Facility Count",
  facility_rate  = "Treatment Facility Rate (per 100k)",
  population     = "County Population (single year)",
  median_income  = "Median Household Income ($)",
  poverty_rate   = "Poverty Rate (%)",
  gap_score      = "Access Gap Score (Overdose Rate − Facility Rate)",
  rucc           = "Urban–Rural Classification (RUCC 1–9)"
)

rucc_labels <- c(
  "1" = "Metro >1M",
  "2" = "Metro 250k–1M",
  "3" = "Metro <250k",
  "4" = "Non-metro, adj to large metro",
  "5" = "Non-metro, adj to small metro",
  "6" = "Non-metro, not adj to metro",
  "7" = "Rural, adj to metro",
  "8" = "Rural, adj to small metro",
  "9" = "Rural, remote"
)

# ---------------------------------------------------------------------------
# Load and clean data
# ---------------------------------------------------------------------------
data_file <- if (file.exists("../data/master_df_rucc.csv")) {
  "../data/master_df_rucc.csv"
} else {
  message("master_df_rucc.csv not found — falling back to master_df.csv (no RUCC data)")
  "../data/master_df.csv"
}

master_raw <- read_csv(data_file) |>
  rename(
    population_7yr = any_of("Population"),
    population     = any_of("population")
  ) |>
  filter(fips != "00000") |>
  mutate(
    fips      = str_pad(
      as.character(as.integer(as.numeric(fips))),
      width = 5, side = "left", pad = "0"
    ),
    state     = str_extract(county_state, "[A-Z]{2}$"),
    gap_score = overdose_rate - facility_rate
  ) |>
  # Deduplicate — keep one row per county (duplicates can arise from the RUCC merge)
  distinct(fips, .keep_all = TRUE)

# Check for RUCC outside mutate so we never reference '.' inside if()
has_rucc <- "rucc" %in% names(master_raw) && !all(is.na(master_raw$rucc))

master <- if (has_rucc) {
  master_raw |>
    mutate(
      rucc       = as.integer(rucc),
      is_rural   = as.integer(rucc >= 4),
      rucc_label = rucc_labels[as.character(rucc)]
    )
} else {
  master_raw |>
    mutate(
      rucc       = NA_integer_,
      is_rural   = NA_integer_,
      rucc_label = NA_character_
    )
}

# ---------------------------------------------------------------------------
# County boundaries from tigris
# ---------------------------------------------------------------------------
counties_sf <- tigris::counties(cb = TRUE, year = 2024)
counties_sf$fips <- str_pad(
  paste0(counties_sf$STATEFP, counties_sf$COUNTYFP),
  width = 5, side = "left", pad = "0"
)

map_df <- counties_sf |>
  left_join(master, by = "fips")

state_choices <- sort(unique(na.omit(master$state)))

# ---------------------------------------------------------------------------
# Server
# ---------------------------------------------------------------------------
server <- function(input, output, session) {
  
  updateSelectizeInput(session, "state_filter", choices = state_choices, server = TRUE)
  
  observe({
    if (!has_rucc) shinyjs::hide("rucc_filter_box")
  })
  
  # ---- Reactive filtered dataset ------------------------------------------
  filtered <- reactive({
    df <- map_df
    
    if (!is.null(input$state_filter) && length(input$state_filter) > 0) {
      df <- df |> filter(state %in% input$state_filter)
    }
    
    if (has_rucc && !is.null(input$rucc_filter) && input$rucc_filter != "all") {
      df <- df |> filter(
        case_when(
          input$rucc_filter == "metro"    ~ rucc %in% 1:3,
          input$rucc_filter == "nonmetro" ~ rucc %in% 4:6,
          input$rucc_filter == "rural"    ~ rucc %in% 7:9,
          TRUE                            ~ TRUE
        )
      )
    }
    
    df
  })
  
  # ---- Value boxes --------------------------------------------------------
  
  output$total_deaths <- renderValueBox({
    valueBox(
      value    = format(sum(filtered()$deaths, na.rm = TRUE), big.mark = ","),
      subtitle = "Total Opioid Deaths (2018–2024)",
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
  
  output$high_risk_rural <- renderValueBox({
    df      <- filtered() |> st_drop_geometry()
    od_med  <- median(df$overdose_rate, na.rm = TRUE)
    fac_med <- median(df$facility_rate,  na.rm = TRUE)
    n <- if (has_rucc) {
      sum(df$rucc >= 4 & df$overdose_rate > od_med &
            df$facility_rate < fac_med, na.rm = TRUE)
    } else {
      sum(df$overdose_rate > od_med & df$facility_rate < fac_med, na.rm = TRUE)
    }
    valueBox(
      value    = format(n, big.mark = ","),
      subtitle = if (has_rucc) "Rural Counties: High Risk & Low Access"
      else "Counties: High Risk & Low Access",
      icon     = icon("triangle-exclamation"),
      color    = "red"
    )
  })
  
  # ---- Choropleth map -----------------------------------------------------
  
  output$map <- renderLeaflet({
    
    df         <- filtered()
    metric_col <- input$metric
    label_text <- metric_labels[[metric_col]]
    
    if (metric_col == "rucc") {
      rucc_vals <- sort(na.omit(unique(df[["rucc"]])))
      pal <- colorFactor(
        palette  = "RdYlBu",
        domain   = rucc_vals,
        na.color = "#d9d9d9",
        reverse  = TRUE
      )
    } else {
      pal <- colorNumeric(
        palette  = "viridis",
        domain   = df[[metric_col]],
        na.color = "#d9d9d9"
      )
    }
    
    leaflet(df) |>
      addProviderTiles(providers$CartoDB.Positron) |>
      fitBounds(lng1 = -128, lat1 = 23, lng2 = -65, lat2 = 50) |>
      addPolygons(
        fillColor    = ~pal(get(metric_col)),
        fillOpacity  = 0.8,
        weight       = 0.4,
        color        = "white",
        smoothFactor = 0.2,
        
        label = ~if (metric_col == "rucc") {
          paste0(NAME, ": ", rucc_labels[as.character(get(metric_col))])
        } else {
          paste0(NAME, ": ", round(get(metric_col), 2))
        },
        
        popup = ~paste0(
          "<b>", NAME, "</b>",
          "<br><b>Deaths (2018–2024):</b> ", deaths,
          "<br><b>Overdose Rate (per 100k):</b> ", round(overdose_rate, 2),
          "<br><b>Facilities:</b> ", facility_count,
          "<br><b>Facility Rate (per 100k):</b> ", round(facility_rate, 2),
          "<br><b>Access Gap Score:</b> ", round(gap_score, 2),
          if (has_rucc) paste0("<br><b>Urban–Rural (RUCC):</b> ", rucc_label) else "",
          "<br><b>Population:</b> ", format(population, big.mark = ","),
          "<br><b>Median Income:</b> $", format(median_income, big.mark = ","),
          "<br><b>Poverty Rate:</b> ", poverty_rate, "%",
          "<br><b>Unemployment Rate:</b> ", unemployment_rate, "%"
        ),
        
        highlightOptions = highlightOptions(
          weight       = 3,
          color        = "#333333",
          bringToFront = TRUE
        )
      ) |>
      addLegend(
        position  = "bottomright",
        pal       = pal,
        values    = if (metric_col == "rucc") rucc_vals else df[[metric_col]],
        title     = label_text,
        labFormat = if (metric_col == "rucc") {
          labelFormat(transform = function(x) rucc_labels[as.character(x)])
        } else {
          labelFormat()
        }
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
        Population         = population,
        any_of("rucc_label")
      ) |>
      rename(any_of(c("rucc_label" = "Urban–Rural"))) |>
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
        `Unemployment Rate` = unemployment_rate,
        any_of("rucc"),
        any_of("rucc_label"),
        any_of("is_rural")
      ) |>
      rename(any_of(c(
        "rucc"       = "RUCC Code",
        "rucc_label" = "Urban–Rural Category",
        "is_rural"   = "Is Rural (1=yes)"
      ))) |>
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
