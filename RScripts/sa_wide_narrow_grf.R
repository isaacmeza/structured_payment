# Purpose: Estimate the wide and narrow CATE specifications used by SA Figure 1
# and SA Table 1. This script fits each specification once; the seeded repeated
# targeting exercise is performed later by wide_narrow_forests.do.
# Input:  _aux/main_figure_03_cate.csv
# Output: _aux/sa_wide_narrow_grf.csv

suppressPackageStartupMessages({
  library(dplyr)
  library(grf)
  library(readr)
})

source("./RScripts/project_setup.R")

input_file <- "_aux/main_figure_03_cate.csv"
output_file <- "_aux/sa_wide_narrow_grf.csv"

# Fixed seeds and a single thread make both forests independent of unrelated
# random-number calls and machine-specific thread scheduling.
propensity_seed <- 570175512L
causal_seed <- 1L

threshold_loss <- function(alpha, g) {
  lambda <- 1 / (alpha * (1 - alpha))
  inside <- g <= lambda
  (2 * sum(g[inside]) / sum(inside) - lambda)^2
}

# Estimate conditional treatment effects after trimming observations with
# limited treatment overlap using the CHIM rule. The threshold follows Crump,
# Hotz, Imbens, and Mitnik (2009), "Dealing with limited overlap in estimation
# of average treatment effects," Biometrika 96(1): 187--199.
fit_effects <- function(data, covariates) {
  # Fit on the experimental estimation sample, then predict every eligible row
  # so Stata can merge the CATEs back to the cleaned master data by pawn ID.
  training <- filter(data, insample == 1)
  X_train <- select(training, all_of(covariates))
  X_test <- select(data, all_of(covariates))
  Y <- training$cr
  W <- as.numeric(training$fee_arms == 1)

  propensity_forest <- regression_forest(
    X_train,
    W,
    num.threads = 1L,
    seed = propensity_seed
  )
  propensity <- predict(propensity_forest)$predictions
  propensity[propensity == 1] <- 0.99
  propensity[propensity == 0] <- 0.01
  g <- 1 / (propensity * (1 - propensity))
  alpha <- optimize(
    threshold_loss,
    interval = c(0.001, 0.499),
    g = g
  )$minimum
  keep <- propensity >= alpha & propensity <= 1 - alpha

  X_train <- X_train[keep, , drop = FALSE]
  Y <- Y[keep]
  W <- W[keep]

  # Estimate the CATEs with the same tuned, honest GRF specification for both
  # covariate sets. Single-threaded fits plus fixed seeds make results portable.
  forest <- causal_forest(
    X = model.matrix(~ ., data = X_train),
    Y = data.matrix(Y),
    W = W,
    Y.hat = NULL,
    W.hat = NULL,
    clusters = NULL,
    num.trees = 5000,
    sample.weights = NULL,
    equalize.cluster.weights = FALSE,
    sample.fraction = 0.5,
    mtry = min(ceiling(sqrt(ncol(X_train)) + 20), ncol(X_train)),
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
    num.threads = 1L,
    seed = causal_seed
  )

  prediction <- predict(
    forest,
    model.matrix(~ ., data = X_test),
    estimate.variance = TRUE,
    num.threads = 1L
  )

  tibble(
    prenda = data$prenda,
    estimate = prediction$predictions,
    variance = prediction$variance.estimates
  )
}

# Fix the observation order before the seeded forest fits and require the pawn
# identifier used by the Stata merge to be unique.
data <- read_csv(input_file, show_col_types = FALSE) |>
  arrange(prenda)

stopifnot(!anyDuplicated(data$prenda))

outcome_and_design <- c("cr", "fee_arms", "prenda", "insample")

# The wide specification uses every prepared covariate; the narrow
# specification uses loan size and four baseline borrower characteristics.
wide_covariates <- setdiff(names(data), outcome_and_design)
narrow_covariates <- c("prestamo", "edad", "genero", "pres_antes", "masqueprepa")

# Define the narrow-forest sample: require reported age and at least one of the
# three binary covariates. Code any remaining missing binary covariate as 2 so
# that missing responses form a separate category from 0 and 1.
narrow_data <- data |>
  filter(
    na_edad == 0,
    !(na_genero == 1 & na_pres_antes == 1 & na_masqueprepa == 1)
  ) |>
  mutate(
    genero = if_else(na_genero == 1, 2, genero),
    pres_antes = if_else(na_pres_antes == 1, 2, pres_antes),
    masqueprepa = if_else(na_masqueprepa == 1, 2, masqueprepa)
  )

wide <- fit_effects(data, wide_covariates)
narrow <- fit_effects(narrow_data, narrow_covariates) |>
  rename(
    tau_hat_eff_narrow = estimate,
    var_hat_eff_narrow = variance
  )

# Store both sets of predictions in one file. Rows outside the prespecified
# narrow sample retain missing narrow estimates and are omitted from its plot.
wide |>
  rename(tau_hat_eff = estimate, var_hat_eff = variance) |>
  left_join(narrow, by = "prenda") |>
  write_csv(output_file, na = "")
