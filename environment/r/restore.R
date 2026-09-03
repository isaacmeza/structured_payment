#!/usr/bin/env Rscript

# Restore the exact package versions recorded in renv.lock.
project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(project_root, "DoFiles", "master.do"))) {
  stop("Run environment/r/restore.R from the replication-package root.", call. = FALSE)
}

renv::restore(project = project_root, prompt = FALSE)
message("Project-local R environment restored from renv.lock.")
