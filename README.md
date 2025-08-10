# Padel Performance Analysis & Match Prediction

![R](https://img-shields.io/badge/R-276DC3?style=for-the-badge&logo=r&logoColor=white)
![Shiny](https://img.shields.io/badge/Shiny-1A1A1A?style=for-the-badge&logo=shiny&logoColor=white)

This repository contains the complete analysis for a personal data science project aimed at evaluating player performance in the sport of padel. The project serves as a case study in applying a rigorous statistical workflow to a sparse, real-world dataset.

---

## Project Overview

Motivated by friendly post-match debates, this project seeks to answer the question: "Who is actually the best player?" The analysis moves beyond simple win percentages to provide a statistically robust evaluation of player skill. It tackles the common real-world challenge of drawing confident conclusions from limited and messy data.

The analysis is presented in two parallel paradigms:
1.  **Frequentist Analysis**: To provide objective "yes/no" answers about statistical significance.
2.  **Bayesian Analysis**: To quantify our certainty and provide a more intuitive understanding of player skill and uncertainty.

## 🔑 Key Findings (TL;DR)

* **Only two players show statistically significant winning performance.** At the Set and Game levels, the results for players Kim and Anttu are strong enough to confidently rule out random chance.
* **Game-level analysis is the most reliable metric.** Due to its large sample size, it has the highest statistical power. Conclusions from match- or set-level data should be treated with caution.
* **Power analysis confirms the need for more data.** To reliably detect a small winning edge (e.g., a 55% win rate), the analysis shows that over 600 games are needed, explaining why most players did not achieve statistical significance.

## 📊 Methodology

The full analysis is detailed in the **[Statistical Report (`analysis_report.html`)](analysis_report.html)**. The workflow is as follows:

### 1. Data Wrangling
A custom R script (`01_data_wrangling.R`) parses raw, text-based scores. It applies specific game logic to handle best-of-N sets, draws, and tiebreaks, outputting a clean, structured dataset.

### 2. Frequentist Analysis
This approach uses traditional hypothesis testing to evaluate player skill against a 50% baseline.
* **Maximum Likelihood Estimates (MLE)**: Player win percentages are calculated.
* **Hypothesis Testing**: A one-proportion z-test determines if a player's win rate is statistically greater than 50% (α = 0.05).
* **Power Analysis**: A post-hoc power analysis evaluates the sensitivity of the tests.

![Power Curve Plot](plots/power_curve.png)

### 3. Bayesian Analysis
This approach provides a more nuanced view of uncertainty using a Beta-Binomial model.
* **Quantifying Certainty**: The analysis yields direct probabilities (e.g., "There is a 99.4% probability that Kim's true game-win rate is > 50%").

![Bayesian Game-Level Skill Distributions](plots/bayesian_game_plot.png)

## 🛠 Tech Stack

* **Language**: R
* **Core Packages**: Tidyverse, ggplot2, pwr, here
* **Reporting**: R Markdown, knitr

## 📁 Repository Structure

```
├── scripts/               # All silent R scripts for the analysis pipeline
├── data/                  # Raw and cleaned data files
├── plots/                 # Saved plots and visualizations
├── analysis_report.Rmd    # The R Markdown file to generate the report
├── analysis_report.html   # The final, self-contained HTML report
└── README.md              # This file
```

## 🚀 Future Work

This report concludes the full statistical analysis phase of the project. The final phase will focus on predictive modeling and deploying the results as an interactive R Shiny application.

Planned features include:
* **Match Outcome Prediction**: A predictive model will be trained to generate win probabilities for any given matchup.
* **Interactive Player Dashboard**: Users will be able to select a player and view their detailed statistical profile and performance visualizations.
* **Live Demo Link**: [➡️ Live Padel Odds Calculator (Coming Soon)]

## ⚙️ How to Run Locally

1.  Clone this repository.
2.  Open the `.Rproj` file in RStudio.
3.  Install the required packages (e.g., `here`, `knitr`, `pwr`, `ggplot2`, `tidyr`).
4.  Open `analysis_report.Rmd` and click the "Knit" button to reproduce the full report and generate the plots.
