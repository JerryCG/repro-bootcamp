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

# 1. Setup ------------------------------------------------------------
library(tidyverse)
library(here)

# The conflict dataset is organized by conflict-year, so location codes
# identify the countries that must be represented in the country-year file.
ucdp_raw <- read_csv(here("data", "raw", "ucdp_acd.csv"), na = "",
                     show_col_types = FALSE)
required_columns <- c("gwno_loc", "year", "conflict_id", "intensity_level")
stopifnot(all(required_columns %in% names(ucdp_raw)))

# 2. One row per country --------------------------------------------
# A conflict can be located in several countries; expand these locations
# before collapsing so each affected country receives a conflict indicator.
ucdp_locations <- ucdp_raw |>
  separate_rows(gwno_loc, sep = ",") |>
  mutate(gwno_loc = as.numeric(str_trim(gwno_loc)))

# 3. Collapse to country-year ---------------------------------------
# Multiple conflicts in a country-year become one observation because the
# confirmatory analysis measures whether any qualifying conflict occurred.
ucdp <- ucdp_locations |>
  group_by(gwno_loc, year) |>
  summarise(
    conflict = 1L,
    n_conflicts = n_distinct(conflict_id),
    max_intensity = max(intensity_level),
    .groups = "drop"
  )

# 4. Save -------------------------------------------------------------
saveRDS(ucdp, here("data", "clean", "ucdp.rds"))
message("03_clean_ucdp.R: ", nrow(ucdp), " country-years, ",
        n_distinct(ucdp$gwno_loc), " countries, ",
        min(ucdp$year), "-", max(ucdp$year))

# 5. Checks -----------------------------------------------------------
# Checks
stopifnot(
  !anyDuplicated(ucdp[c("gwno_loc", "year")]), # unique country-year key
  !anyNA(ucdp$gwno_loc),
  !anyNA(ucdp$year),
  all(ucdp$conflict == 1L),
  all(ucdp$year >= 1946 & ucdp$year <= 2025)
)
