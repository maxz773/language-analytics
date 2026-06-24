library(readr)
library(writexl)
library(dplyr)

df <- read_csv("data/final_results.csv")

set.seed(773)
sampled_df <- df |>
  slice_sample(n = 200)

write_xlsx(sampled_df, "data/sampled_200.xlsx")
