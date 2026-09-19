# ------------------------------------------------------------------
# run_all.R
# Purpose: Reproduce the whole project: data -> clean data -> paper.
# Inputs:  nothing (code/00_download_data.R fetches the raw data if needed)
# Outputs: data/clean/*, output/*, paper/paper.html
# Usage:   Rscript run_all.R     (from anywhere inside the project)
# Author:  Hennes Barnehl
# Date:    2026-09-18
# ------------------------------------------------------------------

library(here)

t0 <- Sys.time()

# 1. Raw data ---------------------------------------------------------
# 00 is idempotent: it does NOT touch the network if data/raw/ is filled.
source(here("code", "00_download_data.R"), local = new.env())

# 2. Cleaning, merging, analysis --------------------------------------
# Every numbered script except 00, in order. Each runs in a fresh
# environment, so scripts cannot depend on leftovers from earlier ones.
scripts <- sort(list.files(here("code"), pattern = "^[0-9]{2}_.*\\.R$",
                           full.names = TRUE))
scripts <- scripts[basename(scripts) != "00_download_data.R"]

for (s in scripts) {
  message("\n==> ", basename(s))
  source(s, local = new.env())
}

# 3. Paper ------------------------------------------------------------
message("\n==> paper/paper.Rmd")
out <- rmarkdown::render(here("paper", "paper.Rmd"), quiet = TRUE)
message("Paper written to: ", out)

message(sprintf("\nrun_all.R finished OK in %.1f seconds.",
                as.numeric(difftime(Sys.time(), t0, units = "secs"))))
