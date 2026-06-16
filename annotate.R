library(httr)
library(jsonlite)
library(dplyr)
library(dotenv)

# Load API key
load_dot_env(".env")
api_key <- Sys.getenv("AIHUBMIX_API_KEY")

url <- "https://aihubmix.com/v1/chat/completions"

test_text <- "Titel: Wir haben jetzt unsere 2te 8er Box beste…, Text: Wir haben jetzt unsere 2te 8er Box bestellt und sind total begeistert. Das Essen schmeckt sehr, sehr lecker. Die Lieferung kommt schnell und komplett gefroren. Bei der Zubereitung im Ofen lassen wir die Menues 10 Minuten länger drin damit das Essen überall heiß ist. Von uns gibt es die volle Punkzahl. Über den Kundenservice kann ich nichts sagen weil wir ihn nicht gebraucht haben. Alles super"

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

messages_list <- list(
  list("role" = "system", "content" = system_prompt),
  # Few-Shot
  list("role" = "user", "content" = "Text: Die Lieferung kam in 2 Tagen, die Kapseln waren gut verpackt und der Geschmack ist mild."),
  list("role" = "assistant", "content" = '{"specificity_score": 3, "problem_identification_score": 1, "solution_offering_score": 1, "explanation_score": 1}'),
  list("role" = "user", "content" = "Text: Alles super, gerne wieder."),
  list("role" = "assistant", "content" = '{"specificity_score": 1, "problem_identification_score": 1, "solution_offering_score": 1, "explanation_score": 1}'),
  list("role" = "user", "content" = "Text: Das Paket kam beschädigt an und eine Dose war ausgelaufen."),
  list("role" = "assistant", "content" = '{"specificity_score": 3, "problem_identification_score": 3, "solution_offering_score": 1, "explanation_score": 1}'),
  # Real data
  list("role" = "user", "content" = test_text)
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
        required = list("specificity_score","problem_identification_score","solution_offering_score","explanation_score"),
        additionalProperties = FALSE
      )
    )
  )
)

# Initiate the POST request
response <- POST(
  url = url,
  add_headers(
    "Authorization" = paste("Bearer", api_key),
    "Content-Type" = "application/json"
  ),
  body = toJSON(body_data, auto_unbox = TRUE),
  encode = "raw"
)

# Parse and print result
result_content <- content(response, as = "parsed", type = "application/json")

# Error handling
if (status_code(response) == 200) {
  cat("=== Request successful！The returned JSON is as follows: ===\n")
  print(result_content$choices[[1]]$message$content)
} else {
  cat("=== Request failed！Status code:", status_code(response), "===\n")
  print(result_content)
}
