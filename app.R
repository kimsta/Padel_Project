## Padel Stats Explorer: Main Application File
##
## This is the main script that launches the Shiny application.
## Its primary role is to load the necessary data and modules, define the
## overall UI structure, and then call the server logic for each module.

# --------------------------------------------------------------------------
# 1. SETUP: LOAD DATA AND MODULES
# --------------------------------------------------------------------------
library(shiny)
library(here)

# Load the clean dataset produced by the analysis pipeline.
clean_data <- read.csv(here("data", "padel_clean.csv"))

# Get a sorted list of unique player names to populate UI dropdowns.
player_cols <- c("Team1P1", "Team1P2", "Team2P1", "Team2P2")
all_players <- sort(unique(na.omit(unlist(clean_data[player_cols]))))

# Source the module file. This loads the UI and server functions.
source(here("modules", "hypothesis_tester_module.R"))


# --------------------------------------------------------------------------
# 2. DEFINE THE MAIN APP USER INTERFACE (UI)
# --------------------------------------------------------------------------
ui <- fluidPage(
  # Custom CSS to ensure text wrapping in the output box.
  tags$head(tags$style(HTML("#tester-test_results_output { white-space: pre-wrap; }"))),
  
  titlePanel("Padel Performance: Statistical Explorer"),
  
  # The main UI is assembled by calling the UI function from our module.
  # Future tabs will be added here.
  hypothesisTesterUI("tester", players = all_players)
)


# --------------------------------------------------------------------------
# 3. DEFINE THE MAIN APP SERVER LOGIC
# --------------------------------------------------------------------------
server <- function(input, output, session) {
  
  # This line calls the server function from our module file.
  hypothesisTesterServer("tester", data = clean_data)
  
}


# --------------------------------------------------------------------------
# 4. RUN THE APPLICATION
# --------------------------------------------------------------------------
shinyApp(ui = ui, server = server)
