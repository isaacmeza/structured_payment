# All active R scripts use paths relative to the replication-package root.
if (!file.exists(file.path("DoFiles", "master.do"))) {
  stop(
    "Run this script from the replication-package root (the structured_payment_replication folder).",
    call. = FALSE
  )
}
