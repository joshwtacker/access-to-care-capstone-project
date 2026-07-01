# Install packages if needed (comment out after first run)
# install.packages(c(
#   "shinydashboard", "leaflet", "sf", "dplyr", "readr",
#   "tigris", "stringr", "plotly", "DT", "viridis"
# ))
#install.packages("shinyjs")
library(shiny)

# Source UI and server definitions
source("ui.R")
source("server.R")

# Launch the app
shinyApp(ui = ui, server = server)