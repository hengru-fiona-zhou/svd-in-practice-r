# Demonstrate image compression with truncated SVD

library(ggplot2)
library(here)

# R's built-in Maunga Whau topographic matrix
image_matrix <- datasets::volcano

# Rescale values to the interval [0, 1]
image_matrix <- (
  image_matrix - min(image_matrix)
) / (
  max(image_matrix) - min(image_matrix)
)

svd_image <- svd(image_matrix)

rank_k_approximation <- function(k, svd_object) {
  u_k <- svd_object$u[, seq_len(k), drop = FALSE]
  
  d_k <- diag(
    svd_object$d[seq_len(k)],
    nrow = k,
    ncol = k
  )
  
  v_k <- svd_object$v[, seq_len(k), drop = FALSE]
  
  approximation <- u_k %*% d_k %*% t(v_k)
  
  pmin(pmax(approximation, 0), 1)
}

rank_values <- c(1, 3, 5, 10, 20, 40, 60)

reconstructed_images <- lapply(
  rank_values,
  rank_k_approximation,
  svd_object = svd_image
)

names(reconstructed_images) <- paste(
  "Rank",
  rank_values
)

# Calculate reconstruction error and storage requirements
original_values <- length(image_matrix)

compression_metrics <- data.frame(
  rank = rank_values,
  relative_error = vapply(
    reconstructed_images,
    function(reconstruction) {
      sqrt(sum((image_matrix - reconstruction)^2)) /
        sqrt(sum(image_matrix^2))
    },
    numeric(1)
  ),
  stored_values = rank_values * (
    nrow(image_matrix) +
      ncol(image_matrix) +
      1
  )
)

compression_metrics$storage_saving <- 1 -
  compression_metrics$stored_values / original_values

compression_metrics$relative_error <- round(
  compression_metrics$relative_error,
  4
)

compression_metrics$storage_saving <- round(
  compression_metrics$storage_saving,
  4
)

print(compression_metrics)

dir.create(
  here("results"),
  showWarnings = FALSE
)

write.csv(
  compression_metrics,
  here("results", "image_compression_metrics.csv"),
  row.names = FALSE
)

# Convert matrices into a format suitable for faceted plotting
matrix_to_data_frame <- function(matrix_object, label) {
  plot_data <- as.data.frame(
    as.table(matrix_object)
  )
  
  names(plot_data) <- c(
    "row",
    "column",
    "value"
  )
  
  plot_data$row <- as.integer(plot_data$row)
  plot_data$column <- as.integer(plot_data$column)
  plot_data$version <- label
  
  plot_data
}

selected_ranks <- c(1, 5, 10, 20, 60)

plot_matrices <- c(
  list("Original" = image_matrix),
  reconstructed_images[
    paste("Rank", selected_ranks)
  ]
)

image_plot_data <- do.call(
  rbind,
  Map(
    matrix_to_data_frame,
    plot_matrices,
    names(plot_matrices)
  )
)

image_plot_data$version <- factor(
  image_plot_data$version,
  levels = names(plot_matrices)
)

compression_plot <- ggplot(
  image_plot_data,
  aes(
    x = column,
    y = row,
    fill = value
  )
) +
  geom_raster() +
  scale_y_reverse() +
  scale_fill_gradient(
    low = "black",
    high = "white",
    limits = c(0, 1),
    guide = "none"
  ) +
  coord_fixed() +
  facet_wrap(
    ~ version,
    ncol = 3
  ) +
  labs(
    title = "Image reconstruction using truncated SVD",
    subtitle = "Higher ranks recover progressively finer topographic detail"
  ) +
  theme_void(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5),
    strip.text = element_text(
      face = "bold",
      margin = margin(6, 0, 6, 0)
    )
  )

ggsave(
  here("figures", "image_compression.png"),
  plot = compression_plot,
  width = 10,
  height = 7,
  dpi = 300
)