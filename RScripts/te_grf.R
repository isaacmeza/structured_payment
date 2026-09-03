suppressPackageStartupMessages({
  library(dplyr)
  library(grf)
  library(readr)
})

source("./RScripts/project_setup.R")

# Main Figure 3: estimate conditional average treatment effects with a causal
# forest and predict them for every observation in the analysis sample.

# Fixed seeds make the propensity and causal forests independent of unrelated
# random-number calls elsewhere in the replication pipeline.
propensity_seed <- 570175512L
causal_seed <- 1L

# Select the symmetric propensity-score trimming threshold proposed by Crump,
# Hotz, Imbens, and Mitnik (2009), "Dealing with limited overlap in estimation
# of average treatment effects," Biometrika, doi:10.1093/biomet/asn055.
threshold_loss <- function(alpha, g) {
  lambda <- 1 / (alpha * (1 - alpha))
  inside <- g <= lambda
  (2 * sum(inside * g) / sum(inside) - lambda)^2
}

# Load the canonical forest input and select the designated training sample.
data <- read_csv(
  "_aux/main_figure_03_cate.csv",
  show_col_types = FALSE
) |>
  arrange(prenda)

training <- filter(data, insample == 1)
excluded <- c("cr", "fee_arms", "prenda", "insample")
X <- select(training, -all_of(excluded))
Y <- training$cr
W <- as.numeric(training$fee_arms == 1)

# Estimate treatment propensities. Exact boundary predictions are clipped only
# to avoid division by zero when constructing the overlap criterion. The
# optimized alpha retains observations with propensities in [alpha, 1 - alpha].
propensity_forest <- regression_forest(X, W, seed = propensity_seed)
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

X <- X[keep, , drop = FALSE]
Y <- Y[keep]
W <- W[keep]

# Train the causal forest on the overlap-trimmed training sample.
forest <- causal_forest(
  X = model.matrix(~ ., data = X),
  Y = data.matrix(Y),
  W = W,
  Y.hat = NULL,
  W.hat = NULL,
  clusters = NULL,
  num.trees = 5000,
  sample.weights = NULL,
  equalize.cluster.weights = FALSE,
  sample.fraction = 0.5,
  mtry = min(ceiling(sqrt(ncol(X)) + 20), ncol(X)),
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
  seed = causal_seed
)

# Apply the fitted forest to the complete analysis sample and save one estimated
# conditional treatment effect per loan.
test_X <- select(data, -all_of(excluded))
prediction <- predict(
  forest,
  model.matrix(~ ., data = test_X)
)

dir.create("Results/forest", recursive = TRUE, showWarnings = FALSE)
write_csv(
  transmute(
    data,
    prenda,
    tau_hat_eff = prediction$predictions
  ),
  "Results/forest/main_figure_03_cate.csv"
)
