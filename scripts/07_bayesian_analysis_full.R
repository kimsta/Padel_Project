## 07_BAYESIAN_ANALYSIS_FULL
##
## Input:  data/padel_clean.csv
## Output: R objects created in memory:
##         - Four plot objects ('bayesian_plot_game', 'bayesian_plot_set', etc.)
##         - A summary data frame ('bayesian_summary_table')
##
## This script uses a Beta-Binomial model to estimate the true win probability
## for each player at all four analysis levels.

# --------------------------------------------------------------------------
# 1. SETUP & LOAD
# --------------------------------------------------------------------------
library(here)
library(ggplot2)
library(tidyr)

tryCatch({
  clean_data <- read.csv(here("data", "padel_clean.csv"))
}, error = function(e) {
  stop("Error: 'padel_clean.csv' not found. Run '01_data_wrangling.R' first.")
})

stats_data <- subset(clean_data, Match_Winner != "Invalid_Score")
if (nrow(stats_data) < 1) stop("Insufficient data.")
player_cols <- c("Team1P1", "Team1P2", "Team2P1", "Team2P2")
all_players <- unique(na.omit(unlist(stats_data[player_cols])))

# --------------------------------------------------------------------------
# 2. DEFINE PRIOR AND CALCULATE POSTERIORS
# --------------------------------------------------------------------------

# Define our Prior Belief using a Beta distribution.
# A Beta(2, 2) is a weakly informative prior, centered at 50%. It acts as a
# small nudge towards the average for players with very little data, which
# makes the model more stable. The data will quickly overwhelm this prior.
prior_alpha <- 2
prior_beta <- 2

results_list <- list()

for (player_name in all_players) {
  matches_all <- subset(stats_data, 
                        Team1P1 == player_name | Team1P2 == player_name |
                          Team2P1 == player_name | Team2P2 == player_name)
  
  is_on_team1 <- (matches_all$Team1P1 == player_name | matches_all$Team1P2 == player_name)
  is_on_team2 <- (matches_all$Team2P1 == player_name | matches_all$Team2P2 == player_name)
  
  # Helper function to apply the Bayesian update rule: Posterior = Prior + Data
  calculate_posterior <- function(wins, played, level) {
    losses <- played - wins
    data.frame(Player = player_name, Level = level, 
               Alpha = prior_alpha + wins, Beta = prior_beta + losses)
  }
  
  # Get counts for all levels
  matches_played <- nrow(matches_all); matches_won <- sum((matches_all$Match_Winner == "Team1" & is_on_team1) | (matches_all$Match_Winner == "Team2" & is_on_team2))
  sets_played <- sum(matches_all$Team1_Sets_Won + matches_all$Team2_Sets_Won); sets_won <- sum(ifelse(is_on_team1, matches_all$Team1_Sets_Won, 0)) + sum(ifelse(is_on_team2, matches_all$Team2_Sets_Won, 0))
  games_played <- sum(matches_all$Team1_Total_Games_Won + matches_all$Team2_Total_Games_Won); games_won <- sum(ifelse(is_on_team1, matches_all$Team1_Total_Games_Won, 0)) + sum(ifelse(is_on_team2, matches_all$Team2_Total_Games_Won, 0))
  tiebreaks_played <- sum(matches_all$Team1_Tiebreaks_Won + matches_all$Team2_Tiebreaks_Won); tiebreaks_won <- sum(ifelse(is_on_team1, matches_all$Team1_Tiebreaks_Won, 0)) + sum(ifelse(is_on_team2, matches_all$Team2_Tiebreaks_Won, 0))
  
  results_list[[player_name]] <- rbind(
    calculate_posterior(matches_won, matches_played, "Match"),
    calculate_posterior(sets_won, sets_played, "Set"),
    calculate_posterior(games_won, games_played, "Game"),
    calculate_posterior(tiebreaks_won, tiebreaks_played, "Tiebreak")
  )
}
posterior_df_full <- do.call(rbind, results_list)

# --------------------------------------------------------------------------
# 3. CREATE PLOT OBJECTS FOR EACH LEVEL
# --------------------------------------------------------------------------
# First, create a "tidy" data frame suitable for plotting all distribution curves.
plot_data <- data.frame()
p_sequence <- seq(0, 1, by = 0.001) # This is the x-axis for our plots

for (i in 1:nrow(posterior_df_full)) {
  row <- posterior_df_full[i, ]
  if(is.na(row$Alpha) || is.na(row$Beta) || (row$Alpha + row$Beta - 2 <= 0) ) next
  # The dbeta() function calculates the height (density) of the Beta curve
  # at each point along our x-axis sequence.
  densities <- dbeta(p_sequence, shape1 = row$Alpha, shape2 = row$Beta)
  plot_data <- rbind(plot_data, data.frame(Player = row$Player, Level = row$Level, P = p_sequence, Density = densities))
}

# This loop creates 4 separate ggplot objects, one for each level.
levels <- c("Game", "Set", "Match", "Tiebreak")
for (lvl in levels) {
  level_plot_data <- subset(plot_data, Level == lvl)
  plot_obj <- ggplot(level_plot_data, aes(x = P, y = Density, color = Player)) +
    geom_line(linewidth = 1.2) +
    geom_vline(xintercept = 0.5, linetype = "dashed", color = "black") +
    scale_x_continuous(labels = scales::percent) +
    labs(title = paste(lvl, "Level Skill Distributions"),
         subtitle = "Wider distributions indicate greater uncertainty",
         x = "True Win Probability (p)", y = "Probability Density") +
    theme_minimal(base_size = 14) +
    theme(legend.position = "bottom")
  
  # Assign the plot to a unique name in memory (e.g., 'bayesian_plot_game')
  assign(paste0("bayesian_plot_", tolower(lvl)), plot_obj)
}

# --------------------------------------------------------------------------
# 4. CREATE THE BAYESIAN SUMMARY TABLE OBJECT
# --------------------------------------------------------------------------
# The pbeta() function calculates the area under the curve of the Beta
# distribution, which gives us a direct probability.
posterior_df_full$Prob_gt_50_Pct <- pbeta(0.5, 
                                          shape1 = posterior_df_full$Alpha, 
                                          shape2 = posterior_df_full$Beta, 
                                          lower.tail = FALSE) # We want P(X > 0.5)

summary_table_wide <- pivot_wider(posterior_df_full, id_cols = Player, names_from = Level, values_from = Prob_gt_50_Pct)
bayesian_summary_table <- summary_table_wide[order(-summary_table_wide$Game), ]