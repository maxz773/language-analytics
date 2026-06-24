library(httr)
library(jsonlite)
library(dplyr)
library(dotenv)
library(readxl)
library(writexl)

# -------- INITIALIZE VARIABLES --------
# Load API key
load_dot_env(".env")
api_key <- Sys.getenv("AIHUBMIX_API_KEY")

# Define endpoint URL
url <- "https://aihubmix.com/v1/chat/completions"

# Read cleaned excel file
df <- read_xlsx("data/cleaned_reviews.xlsx")

# Prepare the (temporary) output csv file
output_file <- "data/results.csv"
if (!file.exists(output_file)) {
  headers <- data.frame(
    Bewertungs_ID = "Bewertungs_ID",
    Specificity_Score = "Specificity_Score",
    Problem_Identification_Score = "Problem_Identification_Score",
    Solution_Offering_Score = "Solution_Offering_Score",
    Explanation_Score = "Explanation_Score",
    stringsAsFactors = FALSE
  )
  write.table(headers,
              file = output_file,
              sep = ",",
              row.names = FALSE,
              col.names = FALSE
              )
}

# Read IDs of already processed data to resume transfer
already_processed_ids <- c()
if (file.exists(output_file) && file.info(output_file)$size > 20) {
  progress_df <- read.csv(output_file, stringsAsFactors = FALSE, header = TRUE)
  already_processed_ids <- progress_df$Bewertungs_ID
}

# -------- PREPARE PROMPTS --------
# System prompt
system_prompt <- r"(
Role: You are an expert annotator coding German customer reviews for an academic text-classification study. Apply the definitions and rules below exactly as written. Do not improvise or add your own criteria. Base every decision only on the review text provided. If you are genuinely uncertain between two scores for a dimension, choose the lower score. Do not guess upward.

Background: Each review is a German-language customer review from a nutrition/supplement online shop. The input will be provided in the format "Titel: [Title], Text: [Body]". Sometimes the Title may be missing. You will rate each review on four independent dimensions of feedback constructiveness.

Scoring scale (applies to every dimension):
1 = low fulfilment (dimension is essentially absent)
2 = partial fulfilment (dimension is present but weak or only implicit)
3 = high fulfilment (dimension is clearly and explicitly present)

--- DEFINITIONS AND RULES ---
DIMENSION 1 — SPECIFICITY
Definition: Specificity is the degree to which a review provides concrete, tangible detail about particular attributes of the product or service experience, rather than a general overall verdict.
Decision rules:
- Score 3: Names one or more concrete, identifiable attributes (e.g., delivery time, packaging, taste, price).
- Score 2: Attribute is only weakly or implicitly referenced.
- Score 1: Gives only a general overall verdict with no concrete attribute (e.g., "alles super", "top").
Note: A review can be positive AND highly specific. Length alone does not equal specificity.

DIMENSION 2 — PROBLEM IDENTIFICATION
Definition: Extent to which a review explicitly names a specific issue, fault, or shortcoming.
Decision rules:
- Score 3: Explicitly names a concrete fault/defect (e.g., damaged package, late delivery).
- Score 2: Problem is weakly implied but not explicitly named.
- Score 1: Names no concrete problem (includes purely positive reviews AND vague dissatisfaction like "war okay, nicht begeistert").
Note: Negative sentiment alone is NOT enough — the specific problem must be named.

DIMENSION 3 — SOLUTION OFFERING
Definition: Extent to which a review explicitly proposes a concrete method, action, or change that the seller or manufacturer should implement to address a problem.
Decision rules:
- Score 3: Explicitly states a concrete action the seller or manufacturer should take (e.g., "needs to change the packaging" or “the instructions should be clearer”).
- Score 2: A suggestion is present but only weakly or indirectly articulated — for example, a desired outcome is named without specifying the action needed to achieve it. (e.g., “the taste is bitter”, “the delivery was slow”, “the medication had no effect”)
- Score 1: Offers no suggestion, or expresses only general dissatisfaction, vague wishes, or implicit improvement hints without naming a specific action (e.g., "I didn’t like it”, “just bad”, “it was okay”)
Note: A solution can be directed either at the merchant (how to fix it) or at future customers (how to deal with it).

DIMENSION 4 - EXPLANATION
Definition: The degree to which a review provides substantive reasons or motives that clarify why the reviewer holds the expressed opinion.
Decision rules:
- Score 3: Provides at least one substantive reason — a motive, mechanism, comparison, consequence, or contextual factor — that explains why something was evaluated positively or negatively (e.g., why a taste was unpleasant, why delivery was considered fast, what effect or lack of effect was observed and under what conditions).
- Score 2: A reason is partially present — for instance, a cause is hinted at but not explained, or the reasoning applies to only one part of the review.
- Score 1: Gives only an evaluative verdict with no supporting reason, or provides only circular justification that merely restates the evaluation in different words (e.g., "top Produkt, weil es sehr gut ist," "schmeckt nicht, gefällt mir nicht").
Note: Length does not guarantee explanation. A long review that repeats the same verdict without reasoning still scores low.

--- OUTPUT FORMAT ---
You MUST output ONLY a valid JSON object.
)"

# Base messages
base_messages <- list(
  list("role" = "system", "content" = system_prompt),
  # Few-Shot
  list("role" = "user", "content" = "Text: Die Lieferung kam in 2 Tagen, die Kapseln waren gut verpackt und der Geschmack ist mild."),
  list("role" = "assistant", "content" = '{"specificity_score": 3, "problem_identification_score": 1, "solution_offering_score": 1, "explanation_score": 1}'),
  list("role" = "user", "content" = "Text: Alles super, gerne wieder."),
  list("role" = "assistant", "content" = '{"specificity_score": 1, "problem_identification_score": 1, "solution_offering_score": 1, "explanation_score": 1}'),
  list("role" = "user", "content" = "Text: Das Paket kam beschädigt an und eine Dose war ausgelaufen."),
  list("role" = "assistant", "content" = '{"specificity_score": 3, "problem_identification_score": 3, "solution_offering_score": 1, "explanation_score": 1}'),
  list("role" = "user", "content" = "Text: Das Paket kam zerdrückt an — bitte stabileres Verpackungsmaterial verwenden."),
  list("role" = "assistant", "content" = '{"specificity_score": 3, "problem_identification_score": 3, "solution_offering_score": 3, "explanation_score": 1}'),
  list("role" = "user", "content" = "Text: Die Verpackung war nicht so toll, da könnte man noch was verbessern."),
  list("role" = "assistant", "content" = '{"specificity_score": 2, "problem_identification_score": 2, "solution_offering_score": 2, "explanation_score": 1}'),
  list("role" = "user", "content" = "Text: Das Produkt ist schlecht, hat mir gar nicht gefallen"),
  list("role" = "assistant", "content" = '{"specificity_score": 1, "problem_identification_score": 1, "solution_offering_score": 1, "explanation_score": 1}')
)

# test_text <- "Titel: Wir haben jetzt unsere 2te 8er Box beste…, Text: Wir haben jetzt unsere 2te 8er Box bestellt und sind total begeistert. Das Essen schmeckt sehr, sehr lecker. Die Lieferung kommt schnell und komplett gefroren. Bei der Zubereitung im Ofen lassen wir die Menues 10 Minuten länger drin damit das Essen überall heiß ist. Von uns gibt es die volle Punkzahl. Über den Kundenservice kann ich nichts sagen weil wir ihn nicht gebraucht haben. Alles super"

# -------- START LLM ANNOTATION LOOP --------
total_rows <- nrow(df)

for (i in 1:total_rows) {

  current_id <- df$Bewertungs_ID[i]
  current_text <- df$Combined_Text[i]

  # Skip if the ID is already processed
  if (current_id %in% already_processed_ids) {
    next
  }

  # Print current progress
  cat(sprintf("[%s] Processing row %d / %d (ID: %s)...\n", Sys.time(), i, total_rows, current_id))

  # Safety mechanism
  row_result <- tryCatch({

    # Dynamically construct messages list
    messages_list <- c(
      base_messages,
      # Real data
      list(list("role" = "user", "content" = current_text))
    )

    # Build request body
    body_data <- list(
      model = "gpt-4o-mini",
      messages = messages_list,
      temperature = 0,
      response_format = list(
        type = "json_schema",
        json_schema = list(
          name = "scores",
          strict = TRUE,
          schema = list(
            type = "object",
            properties = list(
              specificity_score = list(type = "integer", description = "Score for specificity (1-3)"),
              problem_identification_score = list(type = "integer", description = "Score for problem identification (1-3)"),
              solution_offering_score = list(type = "integer", description = "Score for solution offering (1-3)"),
              explanation_score = list(type = "integer", description = "Score for explanation (1-3)")
            ),
            required = list("specificity_score", "problem_identification_score", "solution_offering_score", "explanation_score"),
            additionalProperties = FALSE
          )
        )
      )
    )

    # Send POST request
    response <- POST(
      url = url,
      add_headers("Authorization" = paste("Bearer", api_key)),
      body = body_data,
      encode = "json"
    )

    # Parse response
    if (status_code(response) == 200) {
      result_content <- content(response, as = "parsed", type = "application/json")
      json_res_string <- result_content$choices[[1]]$message$content

      # Convert JSON string into R list
      parsed_scores <- fromJSON(json_res_string)

      # Assemble the result of the current row
      data.frame(
        Bewertungs_ID = current_id,
        Specificity_Score = parsed_scores$specificity_score,
        Problem_Identification_Score = parsed_scores$problem_identification_score,
        Solution_Offering_Score = parsed_scores$solution_offering_score,
        Explanation_Score = parsed_scores$explanation_score,
        stringsAsFactors = FALSE
      )
    } else {
      stop(paste("⚠️ API Error with Status Code:", status_code(response)))
    }
  },

  # Catch potential errors
  error = function(e) {
    cat(sprintf("⚠️ Error on row %d: %s\n", i, e$message))
    data.frame(
      Bewertungs_ID = current_id,
      Specificity_Score = -1,
      Problem_Identification_Score = -1,
      Solution_Offering_Score = -1,
      Explanation_Score = -1,
      stringsAsFactors = FALSE
    )
  })

  # Immediate persistence
  write.table(row_result,
              file = output_file,
              sep = ",",
              append = TRUE,
              row.names = FALSE,
              col.names = FALSE
              )

  Sys.sleep(0.3)
}

cat("=== Annotation of the entire dataset completed! ===\n")
