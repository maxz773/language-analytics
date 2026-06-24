library(readxl)
library(writexl)
library(dplyr)

file <- "data/2026-05 E-Trusted Reviews Masterarbeit TUM (002).xlsx"

df <- read_xlsx(file, skip = 5)

cleaned_df <- df |>
  # Filter out reviews without comment text
  filter(!is.na(Bewertungstext) & Bewertungstext != "") |>

  # Select only three columns
  select(Bewertungs_ID, Bewertung, Bewertungstitel, Bewertungstext) |>

  mutate(
    # Smartly concatenate title and text
    Combined_Text = ifelse(
      is.na(Bewertungstitel) | trimws(Bewertungstitel) == "",
      paste0("Text: ", Bewertungstext),                                  # If title empty, output Text: xxx
      paste0("Titel: ", Bewertungstitel, ", Text: ", Bewertungstext)     # If title not empty, output Titel: xxx, Text: xxx
    ),

    # Create new columns
    Specificity_Score = NA,
    Problem_Identification_Score = NA,
    Solution_Offering_Score = NA,
    Explanation_Score = NA,
    Total_Score = NA,
    Constructivity = NA
  ) |>

  # Delete Bewerbungstitel and Bewerbungstext
  select(-Bewertungstitel, -Bewertungstext)


write_xlsx(cleaned_df, "data/cleaned_reviews.xlsx")
