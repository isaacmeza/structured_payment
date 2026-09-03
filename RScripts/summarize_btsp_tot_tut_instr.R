# Purpose: Summarize the Bayesian-bootstrap simulations used by Main Figure 4
# and SA Table 1.
# Default input: _aux/choose_wrong_tot_tut_btsp.rds
# Local input:   _aux/choose_wrong_tot_tut_btsp.local.rds, selected with
#                --local-artifact
# Outputs: _aux/main_figure_04_bootstrap_summary.csv and
#          _aux/cw_cr_tot_tut.csv
# This fast second stage reads the saved draws from btsp_tot_tut_instr.R; it
# does not refit the forests.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
})

source("./RScripts/project_setup.R")

parse_options <- function(arguments) {
  values <- list(expected_reps = NULL, local_artifact = FALSE)
  seen <- character()
  index <- 1L
  while (index <= length(arguments)) {
    argument <- arguments[[index]]

    if (identical(argument, "--local-artifact")) {
      name <- "local_artifact"
      if (name %in% seen) {
        stop("Duplicate option: --local-artifact", call. = FALSE)
      }
      seen <- c(seen, name)
      values[[name]] <- TRUE
      index <- index + 1L
      next
    }

    matched <- regexec("^--expected-reps(?:=([0-9]+))?$", argument)
    pieces <- regmatches(argument, matched)[[1L]]
    if (length(pieces) == 0L) {
      stop("Unknown option: ", argument, call. = FALSE)
    }
    name <- "expected_reps"
    if (name %in% seen) {
      stop("Duplicate option: --expected-reps", call. = FALSE)
    }
    seen <- c(seen, name)
    value <- pieces[[2L]]
    if (identical(value, "")) {
      index <- index + 1L
      if (index > length(arguments) || !grepl("^[0-9]+$", arguments[[index]])) {
        stop("Option --expected-reps requires a positive integer.", call. = FALSE)
      }
      value <- arguments[[index]]
    }
    value <- as.integer(value)
    if (is.na(value) || value < 1L) {
      stop("Option --expected-reps requires a positive integer.", call. = FALSE)
    }
    values[[name]] <- value
    index <- index + 1L
  }
  values
}

options <- parse_options(commandArgs(trailingOnly = TRUE))
expected_reps <- options$expected_reps

input_file <- file.path(
  "_aux",
  if (options$local_artifact) {
    "choose_wrong_tot_tut_btsp.local.rds"
  } else {
    "choose_wrong_tot_tut_btsp.rds"
  }
)
bootstrap_input_file <- file.path("_aux", "main_figure_04_bootstrap_input.csv")
generator_file <- file.path("RScripts", "btsp_tot_tut_instr.R")
lock_file <- "renv.lock"
output_file <- file.path("_aux", "main_figure_04_bootstrap_summary.csv")
sa_output_file <- file.path("_aux", "cw_cr_tot_tut.csv")

if (!file.exists(input_file)) {
  stop(
    "Missing Figure 4 draws at ", input_file, ". Run ",
    "RScripts/btsp_tot_tut_instr.R",
    if (options$local_artifact) {
      " --local-artifact"
    } else {
      " --production-artifact"
    },
    " first.",
    call. = FALSE
  )
}

bootstrap_draws <- readRDS(input_file)
metadata <- attr(bootstrap_draws, "bootstrap_metadata", exact = TRUE)
if (!is.list(metadata)) {
  stop(
    "Figure 4 draws do not contain bootstrap provenance metadata. ",
    "Rebuild them with the current generator.",
    call. = FALSE
  )
}

expected_metadata <- list(
  generator_version = "deterministic-v3",
  input_md5 = unname(tools::md5sum(bootstrap_input_file)),
  script_md5 = unname(tools::md5sum(generator_file)),
  lock_md5 = unname(tools::md5sum(lock_file)),
  r_version = as.character(getRversion()),
  grf_version = as.character(utils::packageVersion("grf"))
)
for (field in names(expected_metadata)) {
  if (!identical(metadata[[field]], expected_metadata[[field]])) {
    stop(
      "Figure 4 bootstrap metadata mismatch for ", field, ". ",
      "Use draws generated from the current cleaned input and environment.",
      call. = FALSE
    )
  }
}

if (!is.numeric(metadata$reps) || length(metadata$reps) != 1L ||
    is.na(metadata$reps) || metadata$reps < 1 ||
    metadata$reps != floor(metadata$reps)) {
  stop("Figure 4 bootstrap metadata has an invalid replication count.", call. = FALSE)
}
n_reps <- as.integer(metadata$reps)
if (!is.null(expected_reps) && !identical(n_reps, expected_reps)) {
  stop(
    "Figure 4 bootstrap contains ", n_reps,
    " replications; this workflow requires ", expected_reps, ".",
    call. = FALSE
  )
}

required_columns <- c(
  "threshold", "cwf", "cwf_choose", "cwf_nonchoose", "iter"
)
missing_columns <- setdiff(required_columns, names(bootstrap_draws))
if (length(missing_columns) > 0L) {
  stop(
    paste("Figure 4 input is missing:", paste(missing_columns, collapse = ", ")),
    call. = FALSE
  )
}

if (!identical(sort(unique(bootstrap_draws$iter)), seq_len(n_reps))) {
  stop("Figure 4 input does not contain its complete replication sequence.", call. = FALSE)
}
expected_thresholds <- seq(-50, 50, by = 5)
if (!identical(sort(unique(bootstrap_draws$threshold)), expected_thresholds) ||
    nrow(bootstrap_draws) != n_reps * length(expected_thresholds) ||
    anyDuplicated(bootstrap_draws[c("iter", "threshold")])) {
  stop("Figure 4 input does not contain the complete threshold grid.", call. = FALSE)
}

# Convert the overall, chooser, and nonchooser error rates to long form, then
# report their bootstrap means and percentile 95% confidence intervals at each
# threshold.
summary_data <- bootstrap_draws |>
  pivot_longer(
    cols = c("cwf", "cwf_choose", "cwf_nonchoose"),
    names_to = "variable",
    values_to = "value"
  ) |>
  group_by(threshold, variable) |>
  summarize(
    mean_value = mean(value),
    lower_ci = quantile(value, 0.025),
    upper_ci = quantile(value, 0.975),
    .groups = "drop"
  )

dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)

# The figure uses chooser and nonchooser summaries; the sensitivity-analysis
# table also uses the overall summary retained in the auxiliary output.
write_csv(filter(summary_data, variable != "cwf"), output_file)
write_csv(summary_data, sa_output_file)
