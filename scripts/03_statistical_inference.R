## 03_STATISTICAL_INFERENCE
##
## Input:  data/padel_clean.csv
## Output: An R object 'final_results_df' created in memory.
##
## This script performs inferential analysis by testing the hypothesis that each
## player's win probability is significantly greater than 50%. It correctly
## handles draws by using the appropriate data subset for each test.

# --------------------------------------------------------------------------
# 1. SETUP & LOAD
# --------------------------------------------------------------------------
library(here)

tryCatch({
  clean_data <- read.csv(here("data", "padel_clean.csv"))
}, error = function(e) {
  stop("Error: 'padel_clean.csv' not found. Run '01_data_wrangling.R' first.")
})

# Create two data subsets for different analysis needs:
# 1. All valid matches (for game/tiebreak tests, as they always have a winner)
all_valid_data <- subset(clean_data, Match_Winner != "Invalid_Score")
# 2. Only decisive matches (for match/set tests, as they can be draws)
decisive_data <- subset(all_valid_data, Match_Winner != "Draw")

if (nrow(all_valid_data) < 1) stop("Insufficient data.")

player_cols <- c("Team1P1", "Team1P2", "Team2P1", "Team2P2")
all_players <- unique(na.omit(unlist(all_valid_data[player_cols])))


# --------------------------------------------------------------------------
# 2. PERFORM HYPOTHESIS TESTS FOR EACH PLAYER
# --------------------------------------------------------------------------
results_list <- list()

for (player_name in all_players) {
  
  # Get matches from BOTH data subsets
  matches_all <- subset(all_valid_data, 
                        Team1P1 == player_name | Team1P2 == player_name |
                          Team2P1 == player_name | Team2P2 == player_name)
  matches_decisive <- subset(decisive_data,
                             Team1P1 == player_name | Team1P2 == player_name |
                               Team2P1 == player_name | Team2P2 == player_name)
  
  # Helper function to run the proportion test and format results
  run_test <- function(wins, played, level) {
    if (played == 0) {
      return(data.frame(Level = level, Wins = wins, Played = played, P_Value = NA, CI_Lower = NA, CI_Upper = NA, Significant = "N/A"))
    }
    # H0: p <= 0.5 (Win probability is not better than a coin flip)
    # Ha: p > 0.5 (Win probability is significantly better than a coin flip)
    test_result <- prop.test(x = wins, n = played, p = 0.5, alternative = "greater", correct = FALSE)
    data.frame(Level = level, Wins = wins, Played = played, P_Value = test_result$p.value,
               CI_Lower = test_result$conf.int[1], CI_Upper = test_result$conf.int[2],
               Significant = ifelse(test_result$p.value < 0.05, "Yes", "No"))
  }
  
  # --- Get counts for each level using the correct data subset ---
  is_on_team1_decisive <- (matches_decisive$Team1P1 == player_name | matches_decisive$Team1P2 == player_name)
  is_on_team2_decisive <- (matches_decisive$Team2P1 == player_name | matches_decisive$Team2P2 == player_name)
  is_on_team1_all <- (matches_all$Team1P1 == player_name | matches_all$Team1P2 == player_name)
  is_on_team2_all <- (matches_all$Team2P1 == player_name | matches_all$Team2P2 == player_name)
  
  # Match/Set tests use DECISIVE matches (draws excluded)
  matches_won <- sum((matches_decisive$Match_Winner == "Team1" & is_on_team1_decisive) | (matches_decisive$Match_Winner == "Team2" & is_on_team2_decisive))
  matches_played <- nrow(matches_decisive)
  sets_won <- sum(ifelse(is_on_team1_decisive, matches_decisive$Team1_Sets_Won, 0)) + sum(ifelse(is_on_team2_decisive, matches_decisive$Team2_Sets_Won, 0))
  sets_played <- sum(matches_decisive$Team1_Sets_Won + matches_decisive$Team2_Sets_Won)
  
  # Game/Tiebreak tests use ALL VALID matches (draws included)
  games_won <- sum(ifelse(is_on_team1_all, matches_all$Team1_Total_Games_Won, 0)) + sum(ifelse(is_on_team2_all, matches_all$Team2_Total_Games_Won, 0))
  games_played <- sum(matches_all$Team1_Total_Games_Won + matches_all$Team2_Total_Games_Won)
  tiebreaks_won <- sum(ifelse(is_on_team1_all, matches_all$Team1_Tiebreaks_Won, 0)) + sum(ifelse(is_on_team2_all, matches_all$Team2_Tiebreaks_Won, 0))
  tiebreaks_played <- sum(matches_all$Team1_Tiebreaks_Won + matches_all$Team2_Tiebreaks_Won)
  
  # --- Run tests and combine results ---
  results_list[[player_name]] <- rbind(
    run_test(matches_won, matches_played, "Match"),
    run_test(sets_won, sets_played, "Set"),
    run_test(games_won, games_played, "Game"),
    run_test(tiebreaks_won, tiebreaks_played, "Tiebreak")
  )
  results_list[[player_name]]$Player <- player_name
}

# --------------------------------------------------------------------------
# 3. CREATE FINAL RESULTS OBJECT
# --------------------------------------------------------------------------
# This is the final object this "silent engine" script will produce.
final_results_df <- do.call(rbind, results_list)
rownames(final_results_df) <- NULL