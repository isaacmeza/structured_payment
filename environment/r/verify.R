#!/usr/bin/env Rscript

project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(project_root, "DoFiles", "master.do"))) {
  stop("Run environment/r/verify.R from the replication-package root.", call. = FALSE)
}

expected_packages <- c(
  "dplyr",
  "grf",
  "readr",
  "renv",
  "tidyr"
)

active_project <- normalizePath(renv::project(), winslash = "/", mustWork = TRUE)
if (!identical(active_project, project_root)) {
  stop("renv is not active for this replication package.", call. = FALSE)
}

project_library <- normalizePath(renv::paths$library(), winslash = "/", mustWork = TRUE)
active_library <- normalizePath(.libPaths()[1], winslash = "/", mustWork = TRUE)
if (!identical(active_library, project_library)) {
  stop("The first R library path is not the project-local renv library.", call. = FALSE)
}

available <- vapply(
  expected_packages,
  requireNamespace,
  quietly = TRUE,
  FUN.VALUE = logical(1)
)
if (any(!available)) {
  stop(
    "Missing project packages: ",
    paste(names(available)[!available], collapse = ", "),
    call. = FALSE
  )
}

lock <- renv::lockfile_read(file.path(project_root, "renv.lock"))
not_locked <- setdiff(expected_packages, names(lock$Packages))
if (length(not_locked)) {
  stop(
    "Packages absent from renv.lock: ",
    paste(not_locked, collapse = ", "),
    call. = FALSE
  )
}

locked_r <- lock$R$Version
running_r <- paste(R.version$major, R.version$minor, sep = ".")
if (!identical(running_r, locked_r)) {
  stop(
    "R version mismatch: running ", running_r,
    "; lockfile records ", locked_r, ".",
    call. = FALSE
  )
}

locked_versions <- vapply(
  lock$Packages,
  function(record) record$Version,
  FUN.VALUE = character(1)
)
installed_versions <- vapply(
  names(locked_versions),
  function(package) {
    if (!requireNamespace(package, quietly = TRUE)) return(NA_character_)
    as.character(packageVersion(package))
  },
  FUN.VALUE = character(1)
)
normalized_locked_versions <- vapply(
  locked_versions,
  function(version) as.character(numeric_version(version)),
  FUN.VALUE = character(1)
)
version_mismatch <- is.na(installed_versions) |
  installed_versions != normalized_locked_versions
if (any(version_mismatch)) {
  details <- paste0(
    names(locked_versions)[version_mismatch],
    " (locked ", locked_versions[version_mismatch],
    ", installed ", installed_versions[version_mismatch], ")"
  )
  stop("Lockfile/library mismatch: ", paste(details, collapse = "; "), call. = FALSE)
}

dependency_paths <- c("RScripts", "environment/r")
dependency_paths <- dependency_paths[file.exists(dependency_paths)]
dependencies <- do.call(
  rbind,
  lapply(
    dependency_paths,
    renv::dependencies,
    root = project_root,
    progress = FALSE
  )
)
discovered <- sort(unique(stats::na.omit(dependencies$Package)))
base_packages <- rownames(installed.packages(priority = "base"))
unexpected <- setdiff(discovered, c(expected_packages, base_packages))
if (length(unexpected)) {
  stop(
    "Unexpected direct R dependencies: ",
    paste(unexpected, collapse = ", "),
    call. = FALSE
  )
}

cat("R environment verified.\n")
cat("Project:", active_project, "\n")
cat("Library:", active_library, "\n")
cat("R version:", running_r, "\n")
cat("Direct packages:\n")
versions <- vapply(
  expected_packages,
  function(package) as.character(packageVersion(package)),
  FUN.VALUE = character(1)
)
print(data.frame(package = names(versions), version = unname(versions)), row.names = FALSE)
