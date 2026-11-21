# Data provenance

This repository does not store raw course data or confidential information.

- The text analysis uses the six complete novels distributed with the
  `janeaustenr` R package.
- The image-compression example uses R's built-in `volcano` topographic matrix.
- Intermediate co-occurrence matrices and embeddings are generated locally in
  `cache/`, which is excluded from Git.

Run `R/01_build_corpus.R` to reconstruct the text matrix from the packaged
novels. The remaining scripts consume that generated matrix and write compact,
reviewable outputs to `results/` and `figures/`.
