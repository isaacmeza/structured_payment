# Main Figure 4: Bayesian-bootstrap uncertainty for the shares of choosers and
# non-choosers who forgo financial savings. By default, this script writes a
# local artifact that cannot overwrite the canonical draws. The cluster must
# pass --production-artifact explicitly to write the production artifact.
# RScripts/summarize_btsp_tot_tut_instr.R constructs the plotted summary.

# Outer PSOCK workers provide the parallelism. Keep numerical libraries from
# starting additional threads inside each worker.
Sys.setenv(
  OMP_NUM_THREADS = "1",
  OPENBLAS_NUM_THREADS = "1",
  MKL_NUM_THREADS = "1",
  VECLIB_MAXIMUM_THREADS = "1",
  NUMEXPR_NUM_THREADS = "1"
)

suppressPackageStartupMessages({
  library(grf)
  library(readr)
})

source("./RScripts/project_setup.R")

# ---- Command-line options ---------------------------------------------------
# The command-line defaults can be overridden for the available hardware.
# Numeric options accept both --name=value and --name value. For a local run:
# Rscript RScripts/btsp_tot_tut_instr.R --local-artifact --reps=100 --workers=12
parse_options <- function(arguments) {
  values <- list(reps = 100L, workers = 12L, local_artifact = TRUE)
  seen <- character()
  index <- 1L
  while (index <= length(arguments)) {
    argument <- arguments[[index]]

    if (argument %in% c("--local-artifact", "--production-artifact")) {
      name <- sub("^--", "", argument)
      if (name %in% seen) {
        stop("Duplicate option: ", argument, call. = FALSE)
      }
      other_name <- if (identical(name, "local-artifact")) {
        "production-artifact"
      } else {
        "local-artifact"
      }
      if (other_name %in% seen) {
        stop(
          "Options --local-artifact and --production-artifact are mutually exclusive.",
          call. = FALSE
        )
      }
      seen <- c(seen, name)
      values$local_artifact <- identical(name, "local-artifact")
      index <- index + 1L
      next
    }

    matched <- regexec("^--(reps|workers)(?:=([0-9]+))?$", argument)
    pieces <- regmatches(argument, matched)[[1L]]
    if (length(pieces) == 0L) {
      stop("Unknown option: ", argument, call. = FALSE)
    }
    name <- pieces[[2L]]
    if (name %in% seen) {
      stop("Duplicate option: --", name, call. = FALSE)
    }
    seen <- c(seen, name)
    value <- pieces[[3L]]
    if (identical(value, "")) {
      index <- index + 1L
      if (index > length(arguments) || !grepl("^[0-9]+$", arguments[[index]])) {
        stop("Option --", name, " requires a positive integer.", call. = FALSE)
      }
      value <- arguments[[index]]
    }
    value <- as.integer(value)
    if (is.na(value) || value < 1L) {
      stop("Option --", name, " requires a positive integer.", call. = FALSE)
    }
    values[[name]] <- value
    index <- index + 1L
  }
  values$workers <- min(values$workers, values$reps)
  values
}

options <- parse_options(commandArgs(trailingOnly = TRUE))
input_file <- "_aux/main_figure_04_bootstrap_input.csv"
artifact_stem <- if (options$local_artifact) {
  "_aux/choose_wrong_tot_tut_btsp.local"
} else {
  "_aux/choose_wrong_tot_tut_btsp"
}
output_file <- paste0(artifact_stem, ".rds")
checkpoint_file <- sprintf("%s.reps-%d.checkpoint.rds", artifact_stem, options$reps)
script_file <- "RScripts/btsp_tot_tut_instr.R"
lock_file <- "renv.lock"
generator_version <- "deterministic-v3"

if (!file.exists(input_file)) {
  stop(
    "Missing ", input_file,
    ". Run DoFiles/cleaning/prepare_data_inst_forest_btsp.do first.",
    call. = FALSE
  )
}

# ---- CHIM common-support trimming ------------------------------------------
# Estimate P(W = 1 | X) and apply the optimal symmetric trimming rule from
# Crump, Hotz, Imbens, and Mitnik (2009), "Dealing with Limited Overlap in
# Estimation of Average Treatment Effects," Biometrika,
# doi:10.1093/biomet/asn055. If the initial rule retains less than 80% of the
# sample, limit the trimming search to alpha <= 0.1.
threshold_loss <- function(alpha, g) {
  lambda <- 1 / (alpha * (1 - alpha))
  inside <- g <= lambda
  if (!any(inside)) {
    return(1e12)
  }
  (2 * mean(g[inside]) - lambda)^2
}

trim_for_overlap <- function(sample, forest_seed) {
  propensity_forest <- grf::regression_forest(
    X = sample$X_covariates,
    Y = sample$W,
    num.threads = 1L,
    seed = forest_seed
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
  if (100 * mean(keep) < 80) {
    alpha <- optimize(
      threshold_loss,
      interval = c(0.001, 0.1),
      g = g
    )$minimum
    keep <- propensity >= alpha & propensity <= 1 - alpha
  }
  sample$X_train <- sample$X[keep, , drop = FALSE]
  sample$Y_train <- sample$Y[keep]
  sample$W_train <- sample$W[keep]
  sample$Z_train <- sample$Z[keep]
  sample$cluster_train <- sample$cluster[keep]
  sample
}

# ---- TOT and TUT comparison samples ----------------------------------------
# TOT compares the status-quo and choice arms; TUT compares the structured and
# choice arms. W records receipt of structure and Z records assignment to the
# choice arm. Both forests later predict effects for borrowers in the choice arm.
prepare_sample <- function(data, product_codes) {
  sample_data <- data[data$t_producto %in% product_codes, , drop = FALSE]
  excluded <- c("cr", "forced", "prenda", "t_producto", "suc_x_dia")
  covariates <- sample_data[setdiff(names(sample_data), excluded)]
  list(
    X_covariates = covariates,
    X = model.matrix(~ ., data = covariates),
    Y = sample_data$cr,
    W = as.numeric(sample_data$forced == 1),
    Z = as.numeric(sample_data$t_producto == 4),
    cluster = sample_data$suc_x_dia,
    prenda = sample_data$prenda,
    t_producto = sample_data$t_producto
  )
}

# ---- Cluster Bayesian bootstrap and instrumental forests -------------------
# Each replication and estimand has its own fixed bootstrap seed. For every
# branch-day cluster, draw Gamma mass with shape equal to its sample size, then
# divide that mass equally among observations in the cluster. The resulting
# weights sum to one and preserve within-cluster dependence.
bootstrap_seed <- function(iteration, outcome_id) {
  as.integer(1000000L + 100L * iteration + 10L * outcome_id + 1L)
}

fit_outcome <- function(sample, iteration, outcome_id) {
  cluster_factor <- factor(sample$cluster_train)
  cluster_sizes <- table(cluster_factor)

  set.seed(bootstrap_seed(iteration, outcome_id))
  cluster_mass <- stats::rgamma(
    length(cluster_sizes),
    shape = as.numeric(cluster_sizes)
  )
  cluster_mass <- cluster_mass / sum(cluster_mass)
  cluster_index <- match(cluster_factor, names(cluster_sizes))
  weights <- cluster_mass[cluster_index] / as.numeric(cluster_sizes[cluster_index])
  weights <- weights / sum(weights)

  # Fit an instrumental forest on the CHIM-trimmed sample and use the cluster
  # bootstrap weights to generate one conditional TOT (CTOT) or TUT (CTUT) draw.
  forest <- grf::instrumental_forest(
    X = sample$X_train,
    Y = sample$Y_train,
    W = sample$W_train,
    Z = sample$Z_train,
    num.trees = 5000L,
    sample.weights = weights,
    clusters = NULL,
    equalize.cluster.weights = FALSE,
    sample.fraction = 0.5,
    min.node.size = 5L,
    honesty = TRUE,
    honesty.fraction = 0.5,
    honesty.prune.leaves = TRUE,
    alpha = 0.05,
    imbalance.penalty = 0,
    stabilize.splits = TRUE,
    ci.group.size = 2L,
    tune.parameters = c("alpha", "imbalance.penalty"),
    tune.num.trees = 500L,
    tune.num.reps = 200L,
    tune.num.draws = 2000L,
    compute.oob.predictions = TRUE,
    num.threads = 1L,
    # Key each forest to its replication number; estimand-specific randomness
    # enters through the independently seeded Bayesian-bootstrap weights above.
    seed = as.integer(iteration)
  )

  prediction <- predict(
    forest,
    sample$X,
    estimate.variance = FALSE
  )$predictions
  choice_arm <- sample$t_producto == 4
  data.frame(
    prenda = sample$prenda[choice_arm],
    forced = sample$W[choice_arm],
    prediction = prediction[choice_arm]
  )
}

# ---- Choice-error rates -----------------------------------------------------
# At threshold t (in CR percentage points), a chooser forgoes savings when
# CTOT < -t/100; a non-chooser forgoes savings when CTUT > t/100. Record the
# combined choice-arm rate and the rates within each observed choice group.
compute_choice_errors <- function(tot_prediction, tut_prediction, iteration) {
  names(tot_prediction)[names(tot_prediction) == "prediction"] <- "inst_hat_1"
  names(tut_prediction)[names(tut_prediction) == "prediction"] <- "inst_hat_0"
  combined <- merge(
    tot_prediction,
    tut_prediction,
    by = "prenda",
    all = TRUE,
    sort = TRUE,
    suffixes = c("_tot", "_tut")
  )
  if (any(is.na(combined$forced_tot)) ||
      any(is.na(combined$forced_tut)) ||
      any(combined$forced_tot != combined$forced_tut)) {
    stop("TOT and TUT choice samples do not agree on observed choices.")
  }
  combined$forced <- combined$forced_tot

  thresholds <- seq(-50, 50, by = 5)
  output <- lapply(thresholds, function(threshold) {
    wrong_chooser <- combined$forced == 1 &
      !is.na(combined$inst_hat_1) &
      combined$inst_hat_1 < -threshold / 100
    wrong_nonchooser <- combined$forced == 0 &
      !is.na(combined$inst_hat_0) &
      combined$inst_hat_0 > threshold / 100
    chooser <- which(combined$forced == 1)
    nonchooser <- which(combined$forced == 0)
    data.frame(
      threshold = threshold,
      cwf = mean(wrong_chooser | wrong_nonchooser, na.rm = TRUE) * 100,
      cwf_choose = mean(wrong_chooser[chooser]) * 100,
      cwf_nonchoose = mean(wrong_nonchooser[nonchooser]) * 100,
      iter = iteration
    )
  })
  do.call(rbind, output)
}

fit_replication <- function(iteration) {
  tot_prediction <- fit_outcome(tot_sample, iteration, 1L)
  tut_prediction <- fit_outcome(tut_sample, iteration, 2L)
  compute_choice_errors(tot_prediction, tut_prediction, iteration)
}

# ---- Deterministic parallel execution --------------------------------------
# A PSOCK worker receives complete numbered replications, while each grf fit
# uses one thread. Because bootstrap and forest seeds are functions of the
# replication number, results do not depend on worker count or scheduling.
initialize_replication_cluster <- function(workers) {
  cluster <- parallel::makePSOCKcluster(workers)
  initialized <- FALSE
  on.exit({
    if (!initialized) parallel::stopCluster(cluster)
  }, add = TRUE)
  parallel::clusterEvalQ(cluster, {
    suppressPackageStartupMessages({
      library(grf)
    })
    NULL
  })
  parallel::clusterExport(
    cluster,
    varlist = c(
      "tot_sample", "tut_sample", "bootstrap_seed", "fit_outcome",
      "compute_choice_errors", "fit_replication"
    ),
    envir = .GlobalEnv
  )
  initialized <- TRUE
  cluster
}

run_replications <- function(iterations, cluster = NULL) {
  if (is.null(cluster)) {
    return(lapply(iterations, fit_replication))
  }
  parallel::parLapply(cluster, iterations, fit_replication)
}

# Emit one durable, log-friendly progress line after each checkpoint. Only the
# coordinator prints, so parallel workers never race to update the console.
format_duration <- function(seconds) {
  seconds <- max(0L, as.integer(round(seconds)))
  sprintf(
    "%02d:%02d:%02d",
    seconds %/% 3600L,
    (seconds %% 3600L) %/% 60L,
    seconds %% 60L
  )
}

format_progress <- function(done, total, session_done, session_seconds,
                            status, width = 30L) {
  fraction <- done / total
  filled <- min(width, floor(width * fraction))
  eta_seconds <- if (session_done > 0L) {
    session_seconds / session_done * (total - done)
  } else {
    NA_real_
  }
  eta <- if (is.finite(eta_seconds)) format_duration(eta_seconds) else "calculating"
  sprintf(
    "Progress [%s%s] %d/%d (%5.1f%%) | elapsed %s | ETA %s | %s",
    strrep("#", filled),
    strrep("-", width - filled),
    done,
    total,
    100 * fraction,
    format_duration(session_seconds),
    eta,
    status
  )
}

# Save through a temporary file so an interruption cannot leave a partial RDS.
atomic_save_rds <- function(object, path) {
  temporary <- tempfile("main_figure_04_", tmpdir = dirname(path))
  previous <- paste0(path, ".previous")
  saveRDS(object, temporary, version = 3L)
  unlink(previous)
  if (file.exists(path) && !file.rename(path, previous)) {
    unlink(temporary)
    stop("Could not rotate the previous checkpoint: ", path, call. = FALSE)
  }
  if (!file.rename(temporary, path)) {
    unlink(temporary)
    if (file.exists(previous)) file.rename(previous, path)
    stop("Could not replace ", path, call. = FALSE)
  }
  unlink(previous)
}

data <- readr::read_csv(input_file, show_col_types = FALSE)
data <- data[order(data$prenda), , drop = FALSE]
if (anyDuplicated(data$prenda)) {
  stop("The bootstrap input does not uniquely identify rows by prenda.", call. = FALSE)
}

# Separate fixed seeds define the TOT and TUT overlap samples.
tot_sample <- trim_for_overlap(
  prepare_sample(data, c(1, 4)),
  570175512L
)
tut_sample <- trim_for_overlap(
  prepare_sample(data, c(2, 4)),
  799129989L
)

message(
  "Running ", options$reps, " deterministic replications with ",
  options$workers, " worker(s); each grf fit uses one thread."
)
input_md5 <- unname(tools::md5sum(input_file))
script_md5 <- unname(tools::md5sum(script_file))
lock_md5 <- unname(tools::md5sum(lock_file))
r_version <- as.character(getRversion())
grf_version <- as.character(utils::packageVersion("grf"))
draws <- NULL

# ---- Restart-safe checkpoints ----------------------------------------------
# After every batch, save completed draws together with the requested number of
# replications, generator version, and input checksum. Resume only when all
# metadata match; otherwise require a fresh run rather than mixing specifications.
checkpoint_previous <- paste0(checkpoint_file, ".previous")
if (!file.exists(checkpoint_file) && file.exists(checkpoint_previous)) {
  if (!file.rename(checkpoint_previous, checkpoint_file)) {
    stop("Could not recover the previous Figure 4 checkpoint.", call. = FALSE)
  }
  message("Recovered the previous Figure 4 checkpoint after an interruption.")
}
if (file.exists(checkpoint_file)) {
  checkpoint <- readRDS(checkpoint_file)
  valid_checkpoint <- is.list(checkpoint) &&
    identical(checkpoint$generator_version, generator_version) &&
    identical(checkpoint$reps, options$reps) &&
    identical(checkpoint$input_md5, input_md5) &&
    identical(checkpoint$script_md5, script_md5) &&
    identical(checkpoint$lock_md5, lock_md5) &&
    identical(checkpoint$r_version, r_version) &&
    identical(checkpoint$grf_version, grf_version) &&
    is.data.frame(checkpoint$draws) &&
    all(c("threshold", "cwf", "cwf_choose", "cwf_nonchoose", "iter") %in%
      names(checkpoint$draws)) &&
    !anyDuplicated(checkpoint$draws[c("iter", "threshold")]) &&
    all(checkpoint$draws$iter %in% seq_len(options$reps)) &&
    all(table(checkpoint$draws$iter) == 21L)
  if (!valid_checkpoint) {
    stop(
      "The Figure 4 checkpoint belongs to a different input/specification. ",
      "Delete ", checkpoint_file, " to restart.",
      call. = FALSE
    )
  }
  draws <- checkpoint$draws
  message(
    "Resuming after ", length(unique(draws$iter)),
    " completed replication(s)."
  )
}

completed <- if (is.null(draws)) integer() else sort(unique(draws$iter))
remaining <- setdiff(seq_len(options$reps), completed)
batch_size <- max(options$workers, 2L * options$workers)
initial_status <- if (length(completed) == 0L) {
  "starting parallel workers."
} else {
  "checkpoint loaded."
}
message(format_progress(
  length(completed),
  options$reps,
  0L,
  0,
  initial_status
))

run_remaining_replications <- function(draws, remaining) {
  cluster <- NULL
  initial_completed <- options$reps - length(remaining)
  progress_started <- proc.time()[["elapsed"]]
  on.exit({
    if (!is.null(cluster)) parallel::stopCluster(cluster)
  }, add = TRUE)
  if (length(remaining) > 0L && options$workers > 1L) {
    cluster <- initialize_replication_cluster(options$workers)
  }
  while (length(remaining) > 0L) {
    batch <- head(remaining, batch_size)
    new_draws <- do.call(rbind, run_replications(batch, cluster))
    draws <- if (is.null(draws)) new_draws else rbind(draws, new_draws)
    draws <- draws[order(draws$iter, draws$threshold), , drop = FALSE]
    row.names(draws) <- NULL
    atomic_save_rds(
      list(
        generator_version = generator_version,
        reps = options$reps,
        input_md5 = input_md5,
        script_md5 = script_md5,
        lock_md5 = lock_md5,
        r_version = r_version,
        grf_version = grf_version,
        draws = draws
      ),
      checkpoint_file
    )
    completed <- sort(unique(draws$iter))
    completed_count <- length(completed)
    session_completed <- completed_count - initial_completed
    session_elapsed <- proc.time()[["elapsed"]] - progress_started
    message(format_progress(
      completed_count,
      options$reps,
      session_completed,
      session_elapsed,
      "checkpoint saved."
    ))
    remaining <- setdiff(seq_len(options$reps), completed)
  }
  draws
}

elapsed <- system.time({
  draws <- run_remaining_replications(draws, remaining)
})
row.names(draws) <- NULL

# Retain the full provenance contract in the portable final RDS. The summarizer
# rejects supplied or locally generated draws if their cleaned input, generator,
# lockfile, R version, or grf version does not match the project.
attr(draws, "bootstrap_metadata") <- list(
  generator_version = generator_version,
  reps = options$reps,
  input_md5 = input_md5,
  script_md5 = script_md5,
  lock_md5 = lock_md5,
  r_version = r_version,
  grf_version = grf_version
)

dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
atomic_save_rds(draws, output_file)
unlink(checkpoint_file)
message(
  "Wrote ", nrow(draws), " rows to ", output_file,
  " in ", round(elapsed[["elapsed"]], 1), " seconds."
)
