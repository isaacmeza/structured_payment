suppressPackageStartupMessages({
  library(dplyr)
  library(grf)
  library(readr)
})

source("./RScripts/project_setup.R")

# Main Figure 3: estimate heterogeneous treatment-on-the-treated (ToT) and
# treatment-on-the-untreated (TuT) effects with instrumental forests.

# Separate fixed seeds define the ToT and TuT overlap forests and make their
# samples independent of unrelated random-number calls.
overlap_seeds <- c(tot = 570175512L, tut = 799129989L)
instrumental_seed <- 1L

# Select the symmetric propensity-score trimming threshold proposed by Crump,
# Hotz, Imbens, and Mitnik (2009), "Dealing with limited overlap in estimation
# of average treatment effects," Biometrika, doi:10.1093/biomet/asn055.
threshold_loss <- function(alpha, g) {
  lambda <- 1 / (alpha * (1 - alpha))
  inside <- g <= lambda
  (2 * sum(inside * g) / sum(inside) - lambda)^2
}

trim_for_overlap <- function(X, W, Y, Z, seed) {
  # Estimate treatment propensities. Exact boundary predictions are clipped
  # only to avoid division by zero in the overlap criterion.
  propensity_forest <- regression_forest(X, W, seed = seed)
  propensity <- predict(propensity_forest)$predictions
  propensity[propensity == 1] <- 0.99
  propensity[propensity == 0] <- 0.01
  g <- 1 / (propensity * (1 - propensity))

  # Retain propensities in [alpha, 1 - alpha]. If this trims more than 20% of
  # the sample, restrict the threshold search to alpha no larger than 0.10.
  alpha <- optimize(
    threshold_loss,
    interval = c(0.001, 0.499),
    g = g
  )$minimum
  keep <- propensity >= alpha & propensity <= 1 - alpha
  if (100 * mean(keep) < 80) {
    alpha <- optimize(
      threshold_loss,
      interval = c(0.001, 0.1),
      g = g
    )$minimum
    keep <- propensity >= alpha & propensity <= 1 - alpha
  }
  list(X = X[keep, , drop = FALSE], W = W[keep], Y = Y[keep], Z = Z[keep])
}

prepare_sample <- function(data, product_codes) {
  # Form the relevant product comparison. W records treatment received and Z
  # indicates assignment to product 4, the instrument used by the forest.
  sample <- filter(data, t_producto %in% product_codes)
  excluded <- c("cr", "forced", "prenda", "t_producto")
  X <- select(sample, -all_of(excluded))
  list(
    data = sample,
    excluded = excluded,
    X = X,
    W = as.numeric(sample$forced == 1),
    Y = sample$cr,
    Z = as.numeric(sample$t_producto == 4)
  )
}

fit_forest <- function(sample, trimmed, name, seed) {
  # Train on the overlap-trimmed observations.
  forest <- instrumental_forest(
    X = model.matrix(~ ., data = trimmed$X),
    Y = data.matrix(trimmed$Y),
    W = trimmed$W,
    Z = trimmed$Z,
    num.trees = 5000,
    sample.weights = NULL,
    clusters = NULL,
    equalize.cluster.weights = FALSE,
    sample.fraction = 0.5,
    min.node.size = 5,
    honesty = TRUE,
    honesty.fraction = 0.5,
    honesty.prune.leaves = TRUE,
    alpha = 0.05,
    imbalance.penalty = 0,
    stabilize.splits = TRUE,
    ci.group.size = 2,
    tune.parameters = c("alpha", "imbalance.penalty"),
    tune.num.trees = 500,
    tune.num.reps = 200,
    tune.num.draws = 2000,
    compute.oob.predictions = TRUE,
    num.threads = NULL,
    seed = seed
  )

  # Predict effects for every observation in the corresponding untrimmed ToT
  # or TuT comparison sample, retaining identifiers for the figure output.
  test_X <- select(sample$data, -all_of(sample$excluded))
  prediction <- predict(
    forest,
    model.matrix(~ ., data = test_X)
  )
  tibble(
    prenda = sample$data$prenda,
    t_producto = sample$data$t_producto,
    estimate = prediction$predictions,
    panel = name
  )
}

data <- read_csv(
  "_aux/main_figure_03_instr.csv",
  show_col_types = FALSE
) |>
  arrange(prenda)

tot_sample <- prepare_sample(data, c(1, 4))
tut_sample <- prepare_sample(data, c(2, 4))

tot_trimmed <- trim_for_overlap(
  tot_sample$X,
  tot_sample$W,
  tot_sample$Y,
  tot_sample$Z,
  overlap_seeds[["tot"]]
)
tut_trimmed <- trim_for_overlap(
  tut_sample$X,
  tut_sample$W,
  tut_sample$Y,
  tut_sample$Z,
  overlap_seeds[["tut"]]
)

tot <- fit_forest(tot_sample, tot_trimmed, "tot", instrumental_seed)
tut <- fit_forest(tut_sample, tut_trimmed, "tut", instrumental_seed)

dir.create("Results/forest", recursive = TRUE, showWarnings = FALSE)
write_csv(
  bind_rows(tot, tut),
  "Results/forest/main_figure_03_instr.csv"
)
