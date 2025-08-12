library(shiny)
library(here)

# --------------------------------------------------------------------------
# 1. LOAD DATA AND MODULES
# --------------------------------------------------------------------------
clean_data <- read.csv(here("data", "padel_clean.csv"))
player_cols <- c("Team1P1", "Team1P2", "Team2P1", "Team2P2")
all_players <- sort(unique(na.omit(unlist(clean_data[player_cols]))))

source(here("modules", "hypothesis_tester_module.R"))

# --------------------------------------------------------------------------
# 2. DEFINE THE MAIN APP UI
# --------------------------------------------------------------------------
ui <- fluidPage(
  tags$head(tags$style(HTML("#tester-test_results_output { white-space: pre-wrap; }"))),
  titlePanel("Padel Performance: Statistical Explorer"),
  
  # We will add tabs here later. For now, we just call our one module.
  hypothesisTesterUI("tester", players = all_players)
)

# --------------------------------------------------------------------------
# 3. DEFINE THE MAIN APP SERVER
# --------------------------------------------------------------------------
server <- function(input, output, session) {
  # This line runs the server logic from our module file.
  hypothesisTesterServer("tester", data = clean_data)
}

# --- Run the application ---
shinyApp(ui = ui, server = server)