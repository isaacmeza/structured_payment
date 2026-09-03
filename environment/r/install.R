#!/usr/bin/env Rscript

# Build a fresh project-local R library and record its exact package versions.
project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(project_root, "DoFiles", "master.do"))) {
  stop("Run environment/r/install.R from the replication-package root.", call. = FALSE)
}

options(
  repos = c(CRAN = "https://cloud.r-project.org"),
  timeout = max(600, getOption("timeout"))
)

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv")
}

if (!file.exists(file.path(project_root, "renv", "activate.R"))) {
  renv::init(
    project = project_root,
    bare = TRUE,
    restart = FALSE,
    repos = getOption("repos")
  )
}

# Keep this working copy self-contained. A future restore may still use the
# normal user-level renv cache because this setting is deliberately not saved.
renv::settings$use.cache(FALSE, project = project_root, persist = FALSE)

direct_packages <- c(
  "dplyr",
  "grf",
  "readr",
  "tidyr"
)

renv::install(direct_packages, project = project_root)
renv::snapshot(
  project = project_root,
  packages = c("renv", direct_packages),
  prompt = FALSE
)

message("Project-local R environment installed and locked.")
