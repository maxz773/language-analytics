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
              file = output_file,Explanation_Score
              sep = ",",
              row.names = FALSE,
              col.names = FALSE
              )
}

# Read IDs of already processed data to resume transfer
already_processed_ids <- c()
if (file.exists(output_file) && file.info(output_file)$size > 20) {
  progress_df <- read.csv(output_file, stringsAsFactors = FALSE)
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
Definition: Extent to which a review offers a suggestion, recommendation, or remedy for the business to improve, or for other customers to consider.
Decision rules:
- Score 3: Explicitly proposes a concrete solution, improvement suggestion, or actionable workaround.
- Score 2: A desire for a solution is weakly implied, or a vague wish is expressed without a concrete proposal.
- Score 1: Offers no solution or suggestion at all.
Note: A solution can be directed either at the merchant (how to fix it) or at future customers (how to deal with it).

DIMENSION 4 - EXPLANATION
Definition: The degree to which a review explains the underlying reasons, causes, or context behind the user's evaluation or the problem identified.
Decision rules:
- Score 3: Clearly explains why something was good or bad, providing the context or causal mechanism.
- Score 2: Provides a weak, superficial, or incomplete explanation.
- Score 1: States a fact, verdict, or problem with absolutely no explanation or reasoning.
Note: Explanation focuses on the cause/reason behind the outcome, helping the reader understand the "why" rather than just the "what".

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
  list("role" = "assistant", "content" = '{"specificity_score": 3, "problem_identification_score": 3, "solution_offering_score": 1, "explanation_score": 1}')
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
      add_headers(
        "Authorization" = paste("Bearer", api_key),
        "Content-Type" = "application/json"
      ),
      body = toJSON(body_data, auto_unbox = TRUE),
      encode = "raw"
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

  Sys.sleep(0.5)
}

cat("=== Annotation of the entire dataset completed! ===\n")
