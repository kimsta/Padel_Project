## 02_PLAYER_STATISTICS
##
## Input:  data/padel_clean.csv
## Output: An R object 'leaderboard' created in memory.
##
## This script calculates comprehensive descriptive statistics for each player.
## It processes the clean data to produce a final, ranked leaderboard data frame.

# --------------------------------------------------------------------------
# 1. SETUP & LOAD
# --------------------------------------------------------------------------
library(here)

tryCatch({
  clean_data <- read.csv(here("data", "padel_clean.csv"))
}, error = function(e) {
  stop("Error: 'padel_clean.csv' not found. Run '01_data_wrangling.R' first.")
})

# Filter out only invalid scores. Draws are kept in this data set because
# they contribute to "played" counts.
all_valid_data <- subset(clean_data, Match_Winner != "Invalid_Score")
if (nrow(all_valid_data) < 1) stop("Insufficient data.")


# --------------------------------------------------------------------------
# 2. GET UNIQUE PLAYERS
# --------------------------------------------------------------------------
player_cols <- c("Team1P1", "Team1P2", "Team2P1", "Team2P2")
all_players <- unique(na.omit(unlist(all_valid_data[player_cols])))


# --------------------------------------------------------------------------
# 3. CALCULATE STATISTICS FOR EACH PLAYER
# --------------------------------------------------------------------------
player_stats_list <- list()

for (player_name in all_players) {
  
  # Get all matches the player was in (including draws)
  matches_all <- subset(all_valid_data, 
                        Team1P1 == player_name | Team1P2 == player_name |
                          Team2P1 == player_name | Team2P2 == player_name)
  
  is_on_team1 <- (matches_all$Team1P1 == player_name | matches_all$Team1P2 == player_name)
  is_on_team2 <- (matches_all$Team2P1 == player_name | matches_all$Team2P2 == player_name)
  
  # --- Calculate Counts from All Valid Matches ---
  matches_played <- nrow(matches_all)
  matches_won <- sum((matches_all$Match_Winner == "Team1" & is_on_team1) | (matches_all$Match_Winner == "Team2" & is_on_team2))
  matches_drawn <- sum(matches_all$Match_Winner == "Draw")
  
  sets_played <- sum(matches_all$Team1_Sets_Won + matches_all$Team2_Sets_Won)
  sets_won <- sum(ifelse(is_on_team1, matches_all$Team1_Sets_Won, 0)) + sum(ifelse(is_on_team2, matches_all$Team2_Sets_Won, 0))
  
  games_played <- sum(matches_all$Team1_Total_Games_Won + matches_all$Team2_Total_Games_Won)
  games_won <- sum(ifelse(is_on_team1, matches_all$Team1_Total_Games_Won, 0)) + sum(ifelse(is_on_team2, matches_all$Team2_Total_Games_Won, 0))
  
  tiebreaks_played <- sum(matches_all$Team1_Tiebreaks_Won + matches_all$Team2_Tiebreaks_Won)
  tiebreaks_won <- sum(ifelse(is_on_team1, matches_all$Team1_Tiebreaks_Won, 0)) + sum(ifelse(is_on_team2, matches_all$Team2_Tiebreaks_Won, 0))
  
  # --- Calculate Percentages ---
  # Match Win % uses the "points system" where a draw is worth 0.5 wins.
  match_win_pct <- ifelse(matches_played > 0, ((matches_won + 0.5 * matches_drawn) / matches_played) * 100, NA)
  
  # Other percentages are simple proportions of wins over total played.
  set_win_pct <- ifelse(sets_played > 0, (sets_won / sets_played) * 100, NA)
  game_win_pct <- ifelse(games_played > 0, (games_won / games_played) * 100, NA)
  tiebreak_win_pct <- ifelse(tiebreaks_played > 0, (tiebreaks_won / tiebreaks_played) * 100, NA)
  
  # --- Store the results for this player ---
  player_stats_list[[player_name]] <- data.frame(
    Player = player_name, Matches_Played = matches_played, Match_Win_Pct = round(match_win_pct, 1),
    Sets_Played = sets_played, Set_Win_Pct = round(set_win_pct, 1),
    Games_Played = games_played, Game_Win_Pct = round(game_win_pct, 1),
    Tiebreaks_Played = tiebreaks_played, Tiebreak_Win_Pct = round(tiebreak_win_pct, 1)
  )
}

# --------------------------------------------------------------------------
# 4. CREATE THE FINAL LEADERBOARD OBJECT
# --------------------------------------------------------------------------
# This is the final object this "silent engine" script will produce.
final_stats_df <- do.call(rbind, player_stats_list)
leaderboard <- final_stats_df[order(-final_stats_df$Game_Win_Pct), ]
rownames(leaderboard) <- NULL