# ------------------------------------------------------------------
# 04_merge.R
# Purpose: Merge V-Dem, WDI and UCDP into one country-year panel.
#          V-Dem is the master frame: the panel has exactly the
#          country-years that are in data/clean/vdem.rds.
# Inputs:  data/clean/vdem.rds, data/clean/wdi.rds, data/clean/ucdp.rds
# Outputs: data/clean/panel.rds (and panel.csv)
# Author:  Hennes Barnehl
# Date:    2026-09-18
# ------------------------------------------------------------------

# SKELETON: complete the TODOs below, in the style of 01_clean_vdem.R.
# The three sources use three country-ID systems (V-Dem text id / COW code,
# Gleditsch-Ward code, ISO3), so the ID work is the hard part.

message("04_merge.R: TODOs not completed yet")  # TODO 6 removes this line

# 1. Setup ------------------------------------------------------------
# TODO 1: load tidyverse, here and countrycode; read the three .rds files.

# 2. Harmonize IDs ----------------------------------------------------
# TODO 2: give every source the same country key, with V-Dem as the master
#         frame (e.g. ISO3 via countrycode(), or V-Dem's own ids). Print
#         the units of WDI and UCDP that do NOT match a V-Dem country
#         (name, code, source) BEFORE merging, and say how you handle them.

# 3. Merge ------------------------------------------------------------
# TODO 3: left-join WDI and UCDP onto the V-Dem country-years.
#         Set `conflict = 0` (and n_conflicts = 0, max_intensity = 0) ONLY
#         for country-years that are in the V-Dem frame but have no UCDP
#         row. Do not fill any other variable with 0.

# 4. Save -------------------------------------------------------------
# TODO 4: save data/clean/panel.rds and data/clean/panel.csv; print N
#         (country-years), number of countries and years.

# 5. Checks -----------------------------------------------------------
# TODO 5: end with a `# Checks` block of stopifnot(): unique country-year
#         key, expected year range 2000-2024, panel has as many rows as
#         the V-Dem frame, no NA in `conflict`.

# Checks
