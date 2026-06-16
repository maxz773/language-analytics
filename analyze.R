library(dplyr)

df <- read.csv("data/final_results.csv", stringsAsFactors = FALSE)

# Calculate key statistics
total_reviews <- nrow(df)
constructive_count <- sum(df$Constructivity == 1, na.rm = TRUE)
non_constructive_count <- total_reviews - constructive_count

# Calculate percentage
percentage <- (constructive_count / total_reviews) * 100

# Print result
cat(sprintf("Total Reviews Analyzed  : %d\n", total_reviews))
cat(sprintf("Constructive (Score=1)  : %d\n", constructive_count))
cat(sprintf("Non-Constructive (Score=0): %d\n", non_constructive_count))
cat(sprintf("=== Proportion of Constructive Reviews: %.2f%% ===\n", percentage))
