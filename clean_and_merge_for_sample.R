library(readxl)
library(writexl)
library(dplyr)

file1 <- "etrusted_reviews_2026-05-06_09-37.xlsx"
file2 <- "etrusted_reviews_2026-05-08_14-08.xlsx"


df1 <- read_xlsx(file1, skip = 5)
df2 <- read_xlsx(file2, skip = 5)


cleaned_df <- bind_rows(df1, df2) %>%
  filter(!is.na(Bewertungstext) & Bewertungstext != "")

write_xlsx(cleaned_df, "cleaned_reviews.xlsx")