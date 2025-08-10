## 05b_POWER_CURVE_FUTURE
##
## Input:  None (parameters are defined in the script)
## Output: An R object 'power_curve_future' created in memory.
##
## This script generates a power curve for a hypothetical future, larger sample
## size to visualize how test sensitivity increases as more data is collected.

# --------------------------------------------------------------------------
# 1. SETUP & DEFINE PARAMETERS
# --------------------------------------------------------------------------
library(pwr)
library(ggplot2)

# --- Define the fixed parameters for our plot ---
# We set a hypothetical future sample size to simulate the analysis.
SAMPLE_SIZE <- 600
ALPHA_LEVEL <- 0.05
NULL_HYPOTHESIS_P <- 0.50

# --- Create a sequence of effect sizes to test ---
# We'll generate a smooth curve by testing a range of hypothetical win rates.
p1_effect_sizes <- seq(0.50, 0.65, by = 0.005)


# --------------------------------------------------------------------------
# 2. CALCULATE POWER FOR EACH EFFECT SIZE
# --------------------------------------------------------------------------

# Convert the win rates (p1) to the effect size 'h' needed by the pwr package
h_values <- ES.h(p1 = p1_effect_sizes, p2 = NULL_HYPOTHESIS_P)

# Calculate the power for each effect size 'h' at our fixed sample size
power_results <- pwr.p.test(
  h = h_values,
  n = SAMPLE_SIZE,
  sig.level = ALPHA_LEVEL,
  alternative = "greater"
)

# Create a data frame for plotting the results
plot_data_future <- data.frame(
  True_Win_Rate = p1_effect_sizes,
  Power = power_results$power
)


# --------------------------------------------------------------------------
# 3. CREATE THE PLOT OBJECT
# --------------------------------------------------------------------------
# This is the final object this "silent engine" script will produce.
# We name it differently to avoid conflicts with the first power curve.
power_curve_future <- ggplot(plot_data_future, aes(x = True_Win_Rate, y = Power)) +
  geom_line(color = "#0072B2", linewidth = 1.2) +
  
  # Add a horizontal line and label for the standard 80% power target
  geom_hline(yintercept = 0.80, linetype = "dashed", color = "red") +
  annotate("text", x = 0.60, y = 0.85, label = "80% Power Target", color = "red", size = 4) +
  
  # Format axes to be clear and readable
  scale_y_continuous(labels = scales::percent, limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  scale_x_continuous(labels = scales::percent) +
  
  # Add informative titles and labels
  labs(title = paste("Power Curve for a Future Sample Size of", SAMPLE_SIZE, "Games"),
       subtitle = paste0("Testing against H0: True Win Rate ≤ ", NULL_HYPOTHESIS_P*100, "% (α = 0.05)"),
       x = "Hypothetical True Win Rate (Effect Size)", 
       y = "Statistical Power") +
  theme_minimal(base_size = 14)