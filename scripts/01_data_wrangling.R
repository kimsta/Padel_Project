## 01_DATA_WRANGLING
##
## Input:  data/padel_scores.csv (raw data with a 'BoN' column)
## Output: data/padel_clean.csv (a structured, analysis-ready data file)
##
## This script is the data cleaning engine for the project. It takes the raw,
## manually entered match data and applies a series of cleaning and logic
## steps to produce a structured dataset with calculated outcomes.

# --------------------------------------------------------------------------
# 1. SETUP & LOAD
# --------------------------------------------------------------------------
library(here)

tryCatch({
  raw_data <- read.csv(here("data", "padel_scores.csv"), stringsAsFactors = FALSE)
}, error = function(e) {
  stop("Error: 'padel_scores.csv' not found. Ensure it is in the 'data' subfolder.")
})

# This function cleans player name strings to ensure consistency 
# (e.g., "kim" and "KIM" both become "Kim").
standardize_name <- function(name_vector) {
  name_vector <- trimws(as.character(name_vector))
  result <- ifelse(nchar(name_vector) == 0, NA, 
                   paste0(toupper(substring(name_vector, 1, 1)), tolower(substring(name_vector, 2))))
  return(result)
}
player_cols <- c("Team1P1", "Team1P2", "Team2P1", "Team2P2")
raw_data[player_cols] <- lapply(raw_data[player_cols], standardize_name)


# --------------------------------------------------------------------------
# 2. ADVANCED SCORING LOGIC
# --------------------------------------------------------------------------
# This function is the core of the wrangling process. It parses a score string 
# (e.g., "7-6;6-2") and the match format (e.g., BoN=3) to calculate all outcomes.
parse_match_data <- function(scores_string, bo_n) {
  
  # Default values to return for any row that fails parsing
  default_output <- c(Match_Winner="Invalid_Score", Team1_Sets_Won=NA, Team2_Sets_Won=NA,
                      Team1_Meaningful_Games_Won=NA, Team2_Meaningful_Games_Won=NA,
                      Team1_Total_Games_Won=NA, Team2_Total_Games_Won=NA, 
                      Team1_Tiebreaks_Won=NA, Team2_Tiebreaks_Won=NA)
  
  sets <- strsplit(as.character(scores_string), ";")[[1]]
  if (length(sets) == 0 || is.na(bo_n) || bo_n <= 0) return(default_output)
  
  # --- Stage 1: Calculate stats from ALL sets played ---
  total_games_t1 <- 0
  total_games_t2 <- 0
  tiebreaks_won_t1 <- 0
  tiebreaks_won_t2 <- 0
  all_set_scores <- list()
  
  for (set in sets) {
    game_scores <- suppressWarnings(as.numeric(strsplit(set, "-")[[1]]))
    if (length(game_scores) != 2 || any(is.na(game_scores))) return(default_output)
    
    total_games_t1 <- total_games_t1 + game_scores[1]
    total_games_t2 <- total_games_t2 + game_scores[2]
    
    if ((game_scores[1] == 7 && game_scores[2] == 6)) {
      tiebreaks_won_t1 <- tiebreaks_won_t1 + 1
    } else if ((game_scores[1] == 6 && game_scores[2] == 7)) {
      tiebreaks_won_t2 <- tiebreaks_won_t2 + 1
    }
    all_set_scores[[length(all_set_scores) + 1]] <- game_scores
  }
  
  # --- Stage 2: Determine official winner and "meaningful" games ---
  # "Meaningful" games are only those played until a winner was decided.
  sets_to_win <- ceiling(bo_n / 2)
  meaningful_games_t1 <- 0
  meaningful_games_t2 <- 0
  sets_won_t1 <- 0
  sets_won_t2 <- 0
  winner_found <- FALSE
  
  for (game_scores in all_set_scores) {
    if (winner_found) break # Stop counting once the match is officially over
    
    meaningful_games_t1 <- meaningful_games_t1 + game_scores[1]
    meaningful_games_t2 <- meaningful_games_t2 + game_scores[2]
    
    if (game_scores[1] > game_scores[2]) {
      sets_won_t1 <- sets_won_t1 + 1
    } else if (game_scores[2] > game_scores[1]) {
      sets_won_t2 <- sets_won_t2 + 1
    }
    # If set scores are equal (e.g., 3-3), it's an unfinished set, so no win is awarded.
    
    if (sets_won_t1 == sets_to_win || sets_won_t2 == sets_to_win) {
      winner_found <- TRUE
    }
  }
  
  match_winner <- if (sets_won_t1 > sets_won_t2) "Team1" else if (sets_won_t2 > sets_won_t1) "Team2" else "Draw"
  
  # Return a single row of all calculated metrics
  return(c(Match_Winner=match_winner, Team1_Sets_Won=sets_won_t1, Team2_Sets_Won=sets_won_t2,
           Team1_Meaningful_Games_Won=meaningful_games_t1, Team2_Meaningful_Games_Won=meaningful_games_t2,
           Team1_Total_Games_Won=total_games_t1, Team2_Total_Games_Won=total_games_t2, 
           Team1_Tiebreaks_Won=tiebreaks_won_t1, Team2_Tiebreaks_Won=tiebreaks_won_t2))
}


# --------------------------------------------------------------------------
# 3. APPLY CLEANING AND SAVE
# --------------------------------------------------------------------------
parsed_data_list <- mapply(parse_match_data, raw_data$Scores, raw_data$BoN, SIMPLIFY = FALSE)
parsed_df <- as.data.frame(do.call(rbind, parsed_data_list))

# Ensure all calculated columns are treated as numeric
numeric_cols <- c("Team1_Sets_Won", "Team2_Sets_Won", "Team1_Meaningful_Games_Won", 
                  "Team2_Meaningful_Games_Won", "Team1_Total_Games_Won", "Team2_Total_Games_Won", 
                  "Team1_Tiebreaks_Won", "Team2_Tiebreaks_Won")
parsed_df[numeric_cols] <- lapply(parsed_df[numeric_cols], as.numeric)

# Combine with original data, removing the now-redundant raw columns
clean_data <- cbind(raw_data[, !(names(raw_data) %in% c("Scores", "BoN"))], parsed_df)

output_path <- here("data", "padel_clean.csv")
write.csv(clean_data, output_path, row.names = FALSE)

# Note: All print() and message() commands have been removed to make this script
# a "silent engine" for the R Markdown report. The Rmd file is responsible for
# all user-facing output.