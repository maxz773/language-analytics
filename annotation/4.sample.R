library(readxl)
library(writexl)
library(dplyr)

df <- read_xlsx("data/final_results.xlsx")

set.seed(773)
sampled_df <- df |>
  slice_sample(n = 200)

write_xlsx(sampled_df, "data/sampled_200.xlsx")
