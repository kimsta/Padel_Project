## 04_POWER_ANALYSIS
##
## Input:  data/padel_clean.csv
## Output: An R object 'power_table_wide' created in memory.
##
## This script conducts a post-hoc power analysis to evaluate the sensitivity
## of our hypothesis tests. It calculates the probability of detecting a
## predefined, meaningful effect given our current sample sizes.

# --------------------------------------------------------------------------
# 1. SETUP & LOAD
# --------------------------------------------------------------------------
library(pwr)
library(tidyr)
library(here)

clean_data <- read.csv(here("data", "padel_clean.csv"))

# Create two data subsets to correctly match the hypothesis tests
all_valid_data <- subset(clean_data, Match_Winner != "Invalid_Score")
decisive_data <- subset(all_valid_data, Match_Winner != "Draw")

if (nrow(all_valid_data) < 1) stop("Insufficient data.")
player_cols <- c("Team1P1", "Team1P2", "Team2P1", "Team2P2")
all_players <- unique(na.omit(unlist(all_valid_data[player_cols])))


# --------------------------------------------------------------------------
# 2. DEFINE PARAMETERS AND RUN ANALYSIS
# --------------------------------------------------------------------------

# Define the hypothetical "true" win rate for a player we want to detect.
P1_EFFECT <- 0.55
P2_NULL <- 0.50
EFFECT_SIZE_H <- ES.h(p1 = P1_EFFECT, p2 = P2_NULL)

power_results_list <- list()

for (player_name in all_players) {
  
  matches_all <- subset(all_valid_data, Team1P1 == player_name | Team1P2 == player_name | Team2P1 == player_name | Team2P2 == player_name)
  matches_decisive <- subset(decisive_data, Team1P1 == player_name | Team1P2 == player_name | Team2P1 == player_name | Team2P2 == player_name)
  
  # Helper function to calculate power for a given sample size (n)
  calculate_power <- function(n_played, level) {
    if (n_played == 0) return(data.frame(Level = level, N = n_played, Power = NA))
    power_test <- pwr.p.test(h = EFFECT_SIZE_H, n = n_played, sig.level = 0.05, alternative = "greater")
    data.frame(Level = level, N = n_played, Power = power_test$power)
  }
  
  # --- Get sample sizes (N) for each level ---
  # N for Match/Set power uses DECISIVE matches (draws excluded)
  n_matches <- nrow(matches_decisive)
  n_sets <- sum(matches_decisive$Team1_Sets_Won + matches_decisive$Team2_Sets_Won)
  
  # N for Game/Tiebreak power uses ALL VALID matches (draws included)
  n_games <- sum(matches_all$Team1_Total_Games_Won + matches_all$Team2_Total_Games_Won)
  n_tiebreaks <- sum(matches_all$Team1_Tiebreaks_Won + matches_all$Team2_Tiebreaks_Won)
  
  # --- Run power analysis for each level ---
  power_results_list[[player_name]] <- rbind(
    calculate_power(n_matches, "Match"),
    calculate_power(n_sets, "Set"),
    calculate_power(n_games, "Game"),
    calculate_power(n_tiebreaks, "Tiebreak")
  )
  power_results_list[[player_name]]$Player <- player_name
}

# --------------------------------------------------------------------------
# 3. CREATE FINAL POWER ANALYSIS TABLE OBJECT
# --------------------------------------------------------------------------
# This is the final object this "silent engine" script will produce.
final_power_df <- do.call(rbind, power_results_list)

# Pivot the data into a wide format for easy interpretation in the report
power_table_wide <- pivot_wider(
  final_power_df,
  id_cols = Player,
  names_from = Level,
  values_from = c(N, Power),
  names_glue = "{Level}_{.value}"
)

# Reorder columns for a logical layout and sort by game-level power
power_table_wide <- power_table_wide[order(-power_table_wide$Game_Power), 
                                     c("Player", "Match_N", "Match_Power", "Set_N", "Set_Power", 
                                       "Game_N", "Game_Power", "Tiebreak_N", "Tiebreak_Power")]