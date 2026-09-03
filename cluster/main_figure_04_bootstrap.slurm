#!/usr/bin/env bash
#SBATCH --job-name=structured-payment-fig4
#SBATCH --partition=sapphire
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=110
#SBATCH --mem=900000
#SBATCH --time=0-08:00
#SBATCH --output=_aux/slurm-main4-%j.log

set -euo pipefail
job_start_epoch="$(date +%s)"

# Load the exact R interpreter recorded in renv.lock. The project-local package
# library is activated automatically through the root .Rprofile.
module purge
module load R/4.5.3-fasrc01
module list

# The optional renv sandbox is slow when many workers start simultaneously on
# shared cluster storage. The project-local locked library remains active.
export RENV_CONFIG_SANDBOX_ENABLED=FALSE

# Submit from the replication-package root. RSCRIPT_BIN remains available as
# an optional absolute-path override for the executable supplied by the module.
project_dir="${STRUCTURED_PAYMENT_PROJECT_DIR:-${SLURM_SUBMIT_DIR:?Submit from the project root}}"
cd "$project_dir"

if [[ ! -s "_aux/main_figure_04_bootstrap_input.csv" ]]; then
    echo "ERROR: _aux/main_figure_04_bootstrap_input.csv is missing or empty." >&2
    exit 1
fi

rscript_bin="${RSCRIPT_BIN:-Rscript}"
command -v "$rscript_bin" >/dev/null

echo "Cluster job metadata"
echo "Start: $(date)"
echo "Slurm job ID: ${SLURM_JOB_ID:-unknown}"
echo "Node: $(hostname)"
echo "Allocated CPUs: ${SLURM_CPUS_PER_TASK:-unknown}"
if command -v lscpu >/dev/null 2>&1; then
    lscpu | grep -E \
        '^(Architecture|CPU\(s\)|Model name|Socket\(s\)|Core\(s\) per socket|Thread\(s\) per core|NUMA node\(s\)):' \
        || true
fi
grep '^MemTotal:' /proc/meminfo 2>/dev/null || true
"$rscript_bin" --version

# Each PSOCK worker fits one single-threaded forest. Prevent linked numerical
# libraries from silently creating additional threads inside each worker.
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export VECLIB_MAXIMUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

"$rscript_bin" environment/r/verify.R

workers="${SLURM_CPUS_PER_TASK:-1}"
"$rscript_bin" RScripts/btsp_tot_tut_instr.R \
    --reps=5000 \
    --workers="$workers" \
    --production-artifact

if [[ ! -s "_aux/choose_wrong_tot_tut_btsp.rds" ]]; then
    echo "ERROR: The production bootstrap output was not created or is empty." >&2
    exit 1
fi
sha256sum "_aux/choose_wrong_tot_tut_btsp.rds" | \
    tee "_aux/choose_wrong_tot_tut_btsp.rds.sha256"
job_elapsed_seconds=$(( $(date +%s) - job_start_epoch ))
echo "Completed: $(date)"
echo "Total Slurm-script wall time: ${job_elapsed_seconds} seconds"
