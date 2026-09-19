# ------------------------------------------------------------------
# 03_clean_ucdp.R
# Purpose: Turn the UCDP/PRIO conflict-year data into a country-year
#          data set: one row per country and year in which at least one
#          armed conflict (>= 25 battle-related deaths) took place there.
# Inputs:  data/raw/ucdp_acd.csv
# Outputs: data/clean/ucdp.rds
# Author:  Hennes Barnehl
# Date:    2026-09-18
# ------------------------------------------------------------------

# SKELETON: complete the TODOs below, in the style of 01_clean_vdem.R
# (numbered sections, here() paths, comments that say WHY).

message("03_clean_ucdp.R: TODOs not completed yet")  # TODO 6 removes this line

# 1. Setup ------------------------------------------------------------
# TODO 1: load tidyverse and here; read data/raw/ucdp_acd.csv
#         (one row per conflict-year; check the columns you need).

# 2. One row per country --------------------------------------------
# TODO 2: `gwno_loc` (Gleditsch-Ward country codes of the conflict's location)
#         can hold several countries, separated by ", ". Split it so that
#         each row is one conflict-year-country. Trim white space and make
#         the codes numeric.

# 3. Collapse to country-year ---------------------------------------
# TODO 3: collapse to one row per country (gwno_loc) and year with
#         `conflict` = 1, `n_conflicts` = number of distinct conflict_id,
#         `max_intensity` = highest intensity_level (1 = minor, 2 = war).

# 4. Save -------------------------------------------------------------
# TODO 4: save the result to data/clean/ucdp.rds and print how many
#         country-years and countries it has.

# 5. Checks -----------------------------------------------------------
# TODO 5: end with a `# Checks` block of stopifnot() (unique country-year
#         key, no NA in `gwno_loc`/`year`, `conflict` is always 1, years
#         within 1946-2025).

# Checks
