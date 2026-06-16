
library(dplyr)
library(readr)

df <- read.csv("data/results.csv", stringsAsFactors = FALSE)

# Threshold
threshold <- 7

# Check how many rows failed during the annotation
error_count <- sum(df$Specificity_Score == -1, na.rm = TRUE)

if (error_count > 0) {
  cat(sprintf("\nATTENTION: Found %d failed records.\n", error_count))
} else {
  cat("\nPERFECT: 0 failed records!")
}

# Feature engineering
final_df <- df |>
  filter(Specificity_Score != -1) |>
  mutate(
    # Convert the four score columns to numeric
    across(ends_with("_Score"), as.numeric),
    # Calculate the raw sum (4-12)
    Raw_Sum = Specificity_Score + Problem_Identification_Score + Solution_Offering_Score + Explanation_Score,
    # Scale the sum to a 0-10 range
    Total_Score = round((Raw_Sum - 4) / (12 - 4) * 10, 2),
    # Apply threshold for Constructivity
    Constructivity = ifelse(Total_Score >= threshold, 1, 0)
  ) |>
  select(-Raw_Sum)

print(head(final_df, 5))

write.csv(final_df, "data/final_results.csv", row.names = FALSE)

cat("\n=== Calculation completed! Saved to final_results.csv ===\n")

