## Padel Stats Explorer: Main Application File
##
## This is the main script that launches the Shiny application.
## Its primary role is to load the necessary data and modules, define the
## overall UI structure (e.g., the layout of tabs), and then call the
## server logic for each module.

# --------------------------------------------------------------------------
# 1. SETUP: LOAD DATA AND MODULES
# --------------------------------------------------------------------------
# This section runs only once when the application starts.
library(shiny)
library(here)

# Load the clean dataset produced by the analysis pipeline.
clean_data <- read.csv(here("data", "padel_clean.csv"))

# Get a sorted list of unique player names to populate UI dropdowns.
player_cols <- c("Team1P1", "Team1P2", "Team2P1", "Team2P2")
all_players <- sort(unique(na.omit(unlist(clean_data[player_cols]))))

# Source the module file. This loads the UI and server functions for the
# hypothesis testing tab, making them available to the main app.
source(here("modules", "hypothesis_tester_module.R"))


# --------------------------------------------------------------------------
# 2. DEFINE THE MAIN APP USER INTERFACE (UI)
# --------------------------------------------------------------------------
# The UI defines the layout and appearance of the application.
ui <- fluidPage(
  # This custom CSS ensures that long lines of text in the output box will wrap.
  tags$head(tags$style(HTML("#tester-test_results_output { white-space: pre-wrap; }"))),
  
  titlePanel("Padel Performance: Statistical Explorer"),
  
  # The main UI is assembled by calling the UI function from our module.
  # The first argument ("tester") is a unique ID for this module instance.
  # Future tabs will be added here.
  hypothesisTesterUI("tester", players = all_players)
)


# --------------------------------------------------------------------------
# 3. DEFINE THE MAIN APP SERVER LOGIC
# --------------------------------------------------------------------------
# The server function contains the instructions for building the outputs.
server <- function(input, output, session) {
  
  # This line calls the server function from our module file, passing in the
  # unique ID and the clean dataset. This is where all the reactive calculations happen.
  hypothesisTesterServer("tester", data = clean_data)
  
}


# --------------------------------------------------------------------------
# 4. RUN THE APPLICATION
# --------------------------------------------------------------------------
shinyApp(ui = ui, server = server)
