## Padel Stats Explorer: Hypothesis Tester Module
##
## This file defines a self-contained Shiny module for the interactive
## hypothesis testing tab. It includes both the UI (front-end) and the
## Server (back-end) logic for this specific feature.

# --------------------------------------------------------------------------
# 1. DEFINE THE MODULE'S USER INTERFACE (UI)
# --------------------------------------------------------------------------
# The UI function defines the layout and appearance of the module's tab.
# It takes an 'id' to create a namespace, preventing input/output ID conflicts
# with other modules.
hypothesisTesterUI <- function(id, players) {
  # All UI element IDs are wrapped in this namespace function, ns().
  ns <- NS(id)
  
  sidebarLayout(
    sidebarPanel(
      h4("Test Parameters"),
      selectInput(ns("selected_player"), "1. Select Player:", choices = players),
      selectInput(ns("selected_level"), "2. Select Analysis Level:",
                  choices = c("Game", "Set", "Match", "Tiebreak"), selected = "Game"),
      sliderInput(ns("null_hypothesis_p"), "3. Null Hypothesis (H0: p ≤ ...)",
                  min = 0, max = 1, value = 0.5, step = 0.01),
      sliderInput(ns("alpha_level"), "4. Significance Level (α)",
                  min = 0.01, max = 0.20, value = 0.05, step = 0.01)
    ),
    mainPanel(
      h3("Test Results"),
      # This info box provides context and instructions for the user.
      wellPanel(
        h4("How to Interpret These Results"),
        p("This tool performs a one-sided proportion z-test to evaluate a player's performance."),
        tags$ul(
          tags$li(strong("The Hypothesis:"), "The test checks if the player's true win rate (p) is statistically greater than the 'Null Hypothesis' value you set with the slider."),
          tags$li(strong("The Conclusion:"), "If the calculated P-Value is less than your chosen Significance Level (α), we reject the Null Hypothesis. The result is then considered statistically significant at that chosen alpha level."),
          tags$li(strong("The Confidence Interval:"), "This provides a one-sided confidence interval, giving a lower bound for the player's true win rate. The interval's calculation is directly related to the one-sided hypothesis and the chosen alpha level.")
        )
      ),
      # This output will display the formatted text from the server.
      verbatimTextOutput(ns("test_results_output"))
    )
  )
}


# --------------------------------------------------------------------------
# 2. DEFINE THE MODULE'S SERVER LOGIC
# --------------------------------------------------------------------------
# The server function contains all the back-end calculations.
# It is wrapped in moduleServer() to connect it to the main app.
hypothesisTesterServer <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    
    # This reactive expression is the core of the module's logic.
    # It automatically re-runs whenever any of its dependent inputs (e.g.,
    # the selected player or alpha level) are changed by the user.
    reactive_test_results <- reactive({
      
      player_name <- input$selected_player
      level <- input$selected_level
      null_p <- input$null_hypothesis_p
      alpha <- input$alpha_level
      
      # Correctly select the data subset based on the analysis level
      if (level %in% c("Match", "Set")) {
        data_to_use <- subset(data, Match_Winner != "Invalid_Score" & Match_Winner != "Draw")
      } else {
        data_to_use <- subset(data, Match_Winner != "Invalid_Score")
      }
      
      player_matches <- subset(data_to_use, Team1P1 == player_name | Team1P2 == player_name | Team2P1 == player_name | Team2P2 == player_name)
      
      is_on_team1 <- (player_matches$Team1P1 == player_name | player_matches$Team1P2 == player_name)
      is_on_team2 <- (player_matches$Team2P1 == player_name | player_matches$Team2P2 == player_name)
      
      # Use switch() for a clean way to get the correct win/played counts
      counts <- switch(level,
                       "Match" = list(wins = sum((player_matches$Match_Winner == "Team1" & is_on_team1) | (player_matches$Match_Winner == "Team2" & is_on_team2)), played = nrow(player_matches)),
                       "Set" = list(wins = sum(ifelse(is_on_team1, player_matches$Team1_Sets_Won, 0)) + sum(ifelse(is_on_team2, player_matches$Team2_Sets_Won, 0)), played = sum(player_matches$Team1_Sets_Won + player_matches$Team2_Sets_Won)),
                       "Game" = list(wins = sum(ifelse(is_on_team1, player_matches$Team1_Total_Games_Won, 0)) + sum(ifelse(is_on_team2, player_matches$Team2_Total_Games_Won, 0)), played = sum(player_matches$Team1_Total_Games_Won + player_matches$Team2_Total_Games_Won)),
                       "Tiebreak" = list(wins = sum(ifelse(is_on_team1, player_matches$Team1_Tiebreaks_Won, 0)) + sum(ifelse(is_on_team2, player_matches$Team2_Tiebreaks_Won, 0)), played = sum(player_matches$Team1_Tiebreaks_Won + player_matches$Team2_Tiebreaks_Won))
      )
      
      # Perform the test and generate the output text
      if (counts$played > 0) {
        test <- prop.test(x = counts$wins, n = counts$played, p = null_p, 
                          alternative = "greater", correct = FALSE, 
                          conf.level = 1 - alpha)
        
        is_significant <- test$p.value < alpha
        conf_level_pct <- (1 - alpha) * 100
        ci_label <- paste0("\n", conf_level_pct, "% Confidence Interval:")
        conclusion_text <- ifelse(is_significant, 
                                  paste0("Reject H0. The result IS statistically significant at the α = ", alpha, " level."),
                                  paste0("Fail to reject H0. The result IS NOT statistically significant at the α = ", alpha, " level."))
        
        # Assemble the final, formatted text string to be displayed
        paste("Player:", player_name,
              "\nLevel:", level,
              "\n------------------------------------",
              "\nData:", counts$wins, "wins in", counts$played, "decisive events",
              "\nNull Hypothesis (H0): True win rate p <=", null_p,
              "\nSignificance Level (α):", alpha,
              "\n------------------------------------",
              "\nCalculated P-Value:", round(test$p.value, 4),
              ci_label, paste0("[", round(test$conf.int[1], 3), ", ", round(test$conf.int[2], 3), "]"),
              "\n\nConclusion:", conclusion_text)
      } else {
        paste("No data available for", player_name, "at the", level, "level.")
      }
    })
    
    # Assign the reactive output to the UI element
    output$test_results_output <- renderPrint({
      cat(reactive_test_results())
    })
  })
}
