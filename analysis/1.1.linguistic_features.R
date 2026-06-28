# Install libraries
library(udpipe)
library(dplyr)
library(readxl)

# Download the pre-trained German model
# udmodel_german <- udpipe_download_model(language = "german")

# Load the model from drive
udmodel <- udpipe_load_model(file = "german-gsd-ud-2.5-191206.udpipe")

# Load data
df <- read_xlsx("data/final_results_cleaned.xlsx")

# Annotate the text (This performs sentence splitting, tokenization, and POS tagging)
annotation <- udpipe_annotate(udmodel, x = df$Bewertungstext, doc_id = df$Bewertungs_ID)
anno_df <- as.data.frame(annotation)

# Extract the 6 required linguistic features
linguistic_features <- anno_df |>
  group_by(doc_id) |>
  summarise(
    # 1. Number of sub-sentences: taking the max sentence_id per document
    Nsents = max(sentence_id, na.rm = TRUE),

    # 2. Number of words: excluding punctuations (PUNCT) and symbols (SYM)
    Nwords = sum(!upos %in% c("PUNCT", "SYM"), na.rm = TRUE),

    # 3. Number of adjectives (ADJ)
    Nadj   = sum(upos == "ADJ", na.rm = TRUE),

    # 4. Number of adverbs (ADV)
    Nadv   = sum(upos == "ADV", na.rm = TRUE),

    # 5. Number of verbs: including main verbs (VERB) and auxiliary verbs (AUX)
    Nverb  = sum(upos %in% c("VERB", "AUX"), na.rm = TRUE),

    # 6. Number of personal pronouns (PRON)
    Npron  = sum(upos == "PRON", na.rm = TRUE)
  )

# View the final extracted features
print(linguistic_features)
