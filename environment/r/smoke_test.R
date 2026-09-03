#!/usr/bin/env Rscript

source("RScripts/project_setup.R")

packages <- c(
  "dplyr", "grf", "readr", "tidyr"
)
stopifnot(all(vapply(packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))))

example_data <- dplyr::tibble(id = 1:3, a = 4:6, b = 7:9)
long_data <- tidyr::pivot_longer(example_data, c("a", "b"))
stopifnot(nrow(long_data) == 6L)

csv_path <- tempfile(fileext = ".csv")
readr::write_csv(example_data, csv_path)
stopifnot(isTRUE(all.equal(
  readr::read_csv(csv_path, show_col_types = FALSE),
  example_data,
  check.attributes = FALSE
)))
unlink(csv_path)

set.seed(1)
x <- matrix(stats::rnorm(600), ncol = 6)
z <- stats::rbinom(nrow(x), 1, 0.5)
w_probability <- stats::plogis(-0.2 + z + 0.2 * x[, 1])
w <- stats::rbinom(nrow(x), 1, w_probability)
y <- x[, 1] + w + stats::rnorm(nrow(x))

regression <- grf::regression_forest(x, y, num.trees = 20, seed = 1)
causal <- grf::causal_forest(x, y, w, num.trees = 20, seed = 1)
instrumental <- grf::instrumental_forest(x, y, w, z, num.trees = 20, seed = 1)
stopifnot(
  length(predict(regression)$predictions) == nrow(x),
  length(predict(causal)$predictions) == nrow(x),
  length(predict(instrumental)$predictions) == nrow(x)
)

cat("R environment smoke test passed.\n")
