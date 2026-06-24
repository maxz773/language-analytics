library(readxl)
library(writexl)
library(dplyr)

file <- "data/2026-05 E-Trusted Reviews Masterarbeit TUM (002).xlsx"

df <- read_xlsx(file, skip = 5)

cleaned_df <- df |>
  # Filter out reviews without comment text
  filter(!is.na(Bewertungstext) & Bewertungstext != "") |>

  # Select only three columns
  select(Bewertungs_ID, Bewertung, Bewertungstext) |>

  # Create new columns
  mutate(
    Specificity_Score = NA,
    Problem_Identification_Score = NA,
    Solution_Offering_Score = NA,
    Explanation_Score = NA,
    Constructivity = NA
  )


write_xlsx(cleaned_df, "data/cleaned_reviews.xlsx")
