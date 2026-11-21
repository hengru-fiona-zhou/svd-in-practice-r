# Fit SVD-based word embeddings

library(quanteda)
library(irlba)
library(ggplot2)
library(here)

set.seed(308)

# Load the co-occurrence matrix created by 01_build_corpus.R
cooccurrence_matrix <- readRDS(
  here("cache", "austen_fcm.rds")
)

# Apply log(1 + x) only to the non-zero entries
log_cooccurrence <- methods::as(
  cooccurrence_matrix,
  "dgCMatrix"
)

log_cooccurrence@x <- log1p(log_cooccurrence@x)

# Compute the top 100 singular components
svd_model <- irlba(
  log_cooccurrence,
  nv = 100,
  nu = 100
)

# For a symmetric matrix, U * sqrt(D) gives a balanced factorization
alpha <- 0.5

word_embeddings <- sweep(
  svd_model$u,
  MARGIN = 2,
  STATS = svd_model$d^alpha,
  FUN = "*"
)

rownames(word_embeddings) <- featnames(cooccurrence_matrix)

# Normalize each word vector to unit length
row_norms <- sqrt(rowSums(word_embeddings^2))

word_embeddings <- sweep(
  word_embeddings,
  MARGIN = 1,
  STATS = row_norms,
  FUN = "/"
)

# Save embeddings for later analysis
saveRDS(
  list(
    embeddings = word_embeddings,
    singular_values = svd_model$d,
    alpha = alpha
  ),
  here("cache", "austen_embeddings.rds")
)

# Plot the singular values
singular_values_df <- data.frame(
  component = seq_along(svd_model$d),
  singular_value = svd_model$d
)

singular_values_plot <- ggplot(
  singular_values_df,
  aes(x = component, y = singular_value)
) +
  geom_line(color = "#3366AA", linewidth = 0.8) +
  geom_point(color = "#3366AA", size = 1.2) +
  labs(
    title = "Top 100 singular values",
    subtitle = "Jane Austen word co-occurrence matrix",
    x = "Component",
    y = "Singular value"
  ) +
  theme_minimal(base_size = 12)

ggsave(
  here("figures", "singular_values.png"),
  plot = singular_values_plot,
  width = 8,
  height = 5,
  dpi = 300
)

cat(
  "Embedding dimensions:",
  paste(dim(word_embeddings), collapse = " x "),
  "\n"
)