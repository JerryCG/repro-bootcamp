# Project context for coding agents
This is a political science research project: do governments censor the internet more when they face armed conflict, and is the effect stronger in autocracies?
Language: R (tidyverse). Paper: paper/paper.Rmd (RMarkdown). Verify with: Rscript run_all.R

## Rules
1. Work only inside this repository. Never modify anything in data/raw/.
2. Use here::here() for paths. Never use setwd() or absolute paths.
3. Before editing, state a short plan and list the files you will change.
4. Make the smallest change that solves the named task. Never edit pap/pre_analysis_plan.md.
5. After edits, run `Rscript run_all.R` and report failures honestly.
6. Do not install packages, access the network, read credentials, or touch files outside the repo without explicit permission.

## Project conventions
**Folders**
- `data/raw/` holds raw data exactly as downloaded (read-only, git-ignored, created by `code/00_download_data.R`). `data/clean/` holds cleaned data written by the scripts (git-ignored). `output/tables/` and `output/figures/` hold results. `pap/` holds the pre-analysis plan. `paper/` holds `paper.Rmd`.
- Scripts live in `code/`, are numbered (`00_`, `01_`, ...) and run in that order. `code/extra/` is never run by `run_all.R`.
- `Rscript run_all.R` reproduces everything from `data/raw/` to `paper/paper.html`. It is the only verification command; do not add other entry points.

**Scripts**
- Every script starts with a header block: purpose, inputs, outputs, author, date. Numbered sections, comments that explain why (not what).
- Each script (except `00_download_data.R`, which writes `data/raw/`) reads from `data/raw/` or `data/clean/` and writes to `data/clean/` or `output/`. No script writes anywhere else.
- Every script ends with `stopifnot()` checks (unique keys, expected ranges, no missing values silently turned into 0).
- Style: tidyverse, `|>` pipe, `snake_case` names. Model scripts to imitate: `code/01_clean_vdem.R`, `code/02_clean_wdi.R`.
- Read CSVs with `na = ""`. Never drop or recode rows silently: print what you drop (for example unmatched country codes).

**Analysis and paper**
- The confirmatory analysis is exactly the model in `pap/pre_analysis_plan.md`. Do not add specifications, controls or subsamples. Anything else is exploratory and goes under "Exploratory analyses" in the paper.
- Every number in the paper is inline R code (`` `r ...` ``) computed from saved results, never typed by hand.
