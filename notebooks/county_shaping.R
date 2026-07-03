# build_map_data.R
# Run this ONCE locally before deploying to shinyapps.io.
# Produces map_data.rds — a pre-merged, simplified shapefile
# that the app loads instantly without calling tigris at runtime.
#
# Place map_data.rds in the same folder as app.R, server.R, ui.R
# then deploy all four files together.

library(tigris)
library(sf)
library(dplyr)
library(readr)
library(stringr)

options(tigris_use_cache = TRUE)

# ── 1. Download and simplify county boundaries ─────────────────────────────
message("Downloading county boundaries from tigris...")
counties_sf <- tigris::counties(cb = TRUE, year = 2024) |>
  mutate(fips = paste0(STATEFP, COUNTYFP)) |>
  select(fips, NAME, geometry)

message("Simplifying geometry...")
counties_simplified <- st_simplify(
  counties_sf,
  preserveTopology = TRUE,
  dTolerance       = 500
) |>
  st_cast("MULTIPOLYGON")   # ← add this line

# ── 2. Load and clean master data ──────────────────────────────────────────
message("Loading master data...")
data_file <- if (file.exists("../data/master_df_rucc.csv")) {
  "../data/master_df_rucc.csv"
} else {
  message("master_df_rucc.csv not found — falling back to master_df.csv")
  "../data/master_df.csv"
}

master <- read_csv(data_file) |>
  rename(any_of(c(population_7yr = "Population"))) |>
  filter(fips != "00000") |>
  mutate(
    fips      = str_pad(
      as.character(as.integer(as.numeric(fips))),
      width = 5, side = "left", pad = "0"
    ),
    state     = str_extract(county_state, "[A-Z]{2}$"),
    gap_score = overdose_rate - facility_rate
  ) |>
  distinct(fips, .keep_all = TRUE)

# ── 3. Merge geometry with data ────────────────────────────────────────────
message("Merging geometry with county data...")
map_data <- counties_simplified |>
  left_join(master, by = "fips")

message(sprintf("  Total counties in shapefile:  %d", nrow(counties_simplified)))
message(sprintf("  Counties matched with data:   %d", sum(!is.na(map_data$county_state))))
message(sprintf("  Counties unmatched:           %d", sum(is.na(map_data$county_state))))

# ── 4. Save RDS ────────────────────────────────────────────────────────────
saveRDS(map_data, "map_data.rds")

size_mb <- round(file.size("map_data.rds") / 1024 / 1024, 1)
message(sprintf("✅ Saved map_data.rds — %d rows — %s MB", nrow(map_data), size_mb))
message("Deploy app.R, server.R, ui.R, and map_data.rds to shinyapps.io")