library(dplyr)
library(readr)
library(readxl)

df_scores <- read.csv("data/results.csv", stringsAsFactors = FALSE)
df_cleaned <- read_xlsx("data/cleaned_reviews.xlsx")

# Data quality check
error_count <- sum(df_scores$Specificity_Score == -1, na.rm = TRUE)

# Add the Bewertung column back
final_df <- df_scores |>
  filter(Specificity_Score != -1) |>
  mutate(across(c(ends_with("_Score"), Constructivity), as.numeric)) |>
  left_join(
    df_cleaned |> select(Bewertungs_ID, Bewertung, Bewertungstext),
    by = "Bewertungs_ID"
  ) |>
  relocate(Bewertung, Bewertungstext, .after = Bewertungs_ID)

# Calculate key statistics
total_reviews <- nrow(final_df)
constructive_count <- sum(final_df$Constructivity == 1, na.rm = TRUE)
non_constructive_count <- total_reviews - constructive_count

# Calculate percentage
percentage <- (constructive_count / total_reviews) * 100

# Print result
cat(sprintf("Total Reviews Analyzed  : %d\n", total_reviews))
cat(sprintf("Failed records (Score=-1) : %d\n", error_count))
cat(sprintf("Constructive (Score=1)  : %d\n", constructive_count))
cat(sprintf("Non-Constructive (Score=0): %d\n", non_constructive_count))
cat(sprintf("=== Proportion of Constructive Reviews: %.2f%% ===\n", percentage))

write_xlsx(final_df, "data/final_results.xlsx")
cat("=== Process completed! Saved clean output to data/final_results.csv ===\n")


