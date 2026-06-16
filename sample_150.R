library(readxl)
library(writexl)
library(dplyr)

df <- read_xlsx("cleaned_reviews.xlsx")

set.seed(42)
sampled_df <- df %>%
  slice_sample(n = 150)

final_df <- sampled_df %>%
  select(Bewertungstitel, Bewertungstext) %>%
  mutate(
    Constructivity_Max = NA,
    Constructivity_Gemini = NA,
    Constructivity_Definition = NA
  )

write_xlsx(final_df, "data/sampled_constructivity.xlsx")
