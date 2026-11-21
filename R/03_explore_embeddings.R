# Explore nearest neighbours in the embedding space

library(here)

embedding_object <- readRDS(
  here("cache", "austen_embeddings.rds")
)

word_embeddings <- embedding_object$embeddings

most_similar <- function(target_word, embeddings, n = 10) {
  target_word <- tolower(target_word)
  
  if (!target_word %in% rownames(embeddings)) {
    stop(
      paste("Word not found in vocabulary:", target_word)
    )
  }
  
  # Rows are normalized, so inner products equal cosine similarities
  similarities <- as.numeric(
    embeddings %*% embeddings[target_word, ]
  )
  
  names(similarities) <- rownames(embeddings)
  similarities[target_word] <- -Inf
  
  top_matches <- sort(
    similarities,
    decreasing = TRUE
  )[seq_len(n)]
  
  data.frame(
    target = target_word,
    word = names(top_matches),
    similarity = round(as.numeric(top_matches), 4),
    row.names = NULL
  )
}

target_words <- c(
  "love",
  "marriage",
  "woman",
  "man",
  "elizabeth",
  "darcy"
)

nearest_neighbors <- do.call(
  rbind,
  lapply(
    target_words,
    most_similar,
    embeddings = word_embeddings,
    n = 10
  )
)

print(nearest_neighbors)

dir.create(
  here("results"),
  showWarnings = FALSE
)

write.csv(
  nearest_neighbors,
  here("results", "nearest_neighbors.csv"),
  row.names = FALSE
)