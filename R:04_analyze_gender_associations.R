# Analyze gender associations in the embedding space

library(ggplot2)
library(here)

embedding_object <- readRDS(
  here("cache", "austen_embeddings.rds")
)

word_embeddings <- embedding_object$embeddings
vocabulary <- rownames(word_embeddings)

# Use several reference pairs instead of relying only on woman - man
gender_pairs <- data.frame(
  female = c(
    "woman", "women", "girl", "mother",
    "wife", "sister", "lady", "daughter"
  ),
  male = c(
    "man", "men", "boy", "father",
    "husband", "brother", "gentleman", "son"
  )
)

# Keep only pairs present in the vocabulary
valid_pairs <- gender_pairs[
  gender_pairs$female %in% vocabulary &
    gender_pairs$male %in% vocabulary,
]

pair_directions <- t(
  vapply(
    seq_len(nrow(valid_pairs)),
    function(i) {
      word_embeddings[valid_pairs$female[i], ] -
        word_embeddings[valid_pairs$male[i], ]
    },
    numeric(ncol(word_embeddings))
  )
)

# Give each pair equal weight
pair_norms <- sqrt(rowSums(pair_directions^2))

pair_directions <- sweep(
  pair_directions,
  MARGIN = 1,
  STATS = pair_norms,
  FUN = "/"
)

gender_direction <- colMeans(pair_directions)
gender_direction <- gender_direction /
  sqrt(sum(gender_direction^2))

analysis_words <- c(
  "marriage", "family", "home", "house",
  "money", "fortune", "property", "education",
  "reading", "music", "beauty", "handsome",
  "sensible", "clever", "rich", "poor",
  "kind", "amiable", "accomplished", "independent",
  "business", "work", "authority", "society"
)

analysis_words <- analysis_words[
  analysis_words %in% vocabulary
]

projection_scores <- as.numeric(
  word_embeddings[analysis_words, , drop = FALSE] %*%
    gender_direction
)

association_results <- data.frame(
  word = analysis_words,
  projection = round(projection_scores, 4)
)

association_results <- association_results[
  order(association_results$projection),
]

print(association_results)

dir.create(
  here("results"),
  showWarnings = FALSE
)

write.csv(
  association_results,
  here("results", "gender_associations.csv"),
  row.names = FALSE
)

plot_data <- association_results

plot_data$word <- factor(
  plot_data$word,
  levels = plot_data$word
)

plot_data$direction <- ifelse(
  plot_data$projection >= 0,
  "Female reference direction",
  "Male reference direction"
)

gender_plot <- ggplot(
  plot_data,
  aes(
    x = word,
    y = projection,
    fill = direction
  )
) +
  geom_col(width = 0.75) +
  geom_hline(
    yintercept = 0,
    color = "gray35",
    linewidth = 0.5
  ) +
  coord_flip() +
  scale_fill_manual(
    values = c(
      "Female reference direction" = "#9C6ADE",
      "Male reference direction" = "#E07A3F"
    )
  ) +
  labs(
    title = "Gender associations in Jane Austen word embeddings",
    subtitle = "Associations reflect patterns in the corpus, not inherent traits",
    x = NULL,
    y = "Projection onto the gender direction",
    fill = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "bottom"
  )

ggsave(
  here("figures", "gender_associations.png"),
  plot = gender_plot,
  width = 8,
  height = 7,
  dpi = 300
)