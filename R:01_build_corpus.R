# Build a word co-occurrence matrix from Jane Austen's novels

library(janeaustenr)
library(quanteda)
library(dplyr)
library(here)

set.seed(308)

# Combine all lines within each novel
austen_books_text <- austen_books() |>
  group_by(book) |>
  summarise(
    text = paste(text, collapse = " "),
    .groups = "drop"
  )

# Convert the novels into a quanteda corpus
austen_corpus <- corpus(
  austen_books_text,
  text_field = "text",
  docid_field = "book"
)

# Tokenize and clean the text
austen_tokens <- tokens(
  austen_corpus,
  remove_punct = TRUE,
  remove_numbers = TRUE,
  remove_symbols = TRUE
) |>
  tokens_tolower() |>
  tokens_remove(stopwords("en")) |>
  tokens_select(
    pattern = "^[a-z]+$",
    valuetype = "regex",
    selection = "keep"
  )

# Keep the 3,000 most frequent words
word_counts <- dfm(austen_tokens)
top_vocabulary <- names(topfeatures(word_counts, 3000))

austen_tokens <- tokens_select(
  austen_tokens,
  pattern = top_vocabulary,
  selection = "keep",
  padding = TRUE
)

# Count words appearing within five positions of one another
cooccurrence_matrix <- fcm(
  austen_tokens,
  context = "window",
  window = 5,
  count = "weighted",
  weights = 1 / (1:5),
  tri = FALSE
)

# Save the generated matrix locally
dir.create(here("cache"), showWarnings = FALSE)

saveRDS(
  cooccurrence_matrix,
  here("cache", "austen_fcm.rds")
)

cat(
  "Matrix dimensions:",
  paste(dim(cooccurrence_matrix), collapse = " x "),
  "\n"
)

cat(
  "Non-zero entries:",
  Matrix::nnzero(cooccurrence_matrix),
  "\n"
)