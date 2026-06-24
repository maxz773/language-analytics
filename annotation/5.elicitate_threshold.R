library(dplyr)
library(readxl)

# Read final results
final_df <- read_xlsx("data/final_results.xlsx")

# Calculate raw sum (0 - 8)
final_df <- final_df |>
  mutate(
    Raw_Sum = Specificity_Score + Problem_Identification_Score +
      Solution_Offering_Score + Explanation_Score
  )

# 2. Observe the constructivity ratio under different sums
threshold_table <- final_df |>
  group_by(Raw_Sum) |>
  summarise(
    Total_Count = n(),
    Constructive_Count = sum(Constructivity == 1),
    Proportion_of_1 = sum(Constructivity == 1) / n() * 100
  )

print(threshold_table)
