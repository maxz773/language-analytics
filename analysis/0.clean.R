# Load required libraries
library(dplyr)
library(stringr)
library(readxl)
library(writexl)

# Read the dataset (replace with your actual file path if different)
data <- read_xlsx("data/final_results.xlsx")

# Execute baseline data cleaning workflow
cleaned_data <- data |>
  # 1. Handle missing values: Remove rows where critical columns are NA or empty strings
  filter(!is.na(Bewertungstext) & Bewertungstext != "" & !is.na(Bewertung)) |>

  # 2. Ensure accurate data types: Explicitly convert columns to correct formats
  mutate(
    Bewertungs_ID  = as.character(Bewertungs_ID),
    Bewertung      = as.numeric(Bewertung),
    Bewertungstext = as.character(Bewertungstext)
  ) |>

  # 3. Clear extra spaces: Remove leading/trailing spaces and compress multiple spaces into one
  mutate(
    Bewertungstext = str_squish(Bewertungstext)
  )

# Verify the cleaned structure
str(cleaned_data)
head(cleaned_data$Bewertungstext, 5)

# Save cleaned dataset
write_xlsx(cleaned_data, "data/final_results_cleaned.xlsx")
