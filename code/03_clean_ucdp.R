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

# 2. Read -------------------------------------------------------------
# Read only the columns we need. gwno_loc is forced to character: it holds
# several codes ("750, 770") in some rows, and a numeric guess would turn
# those rows into NA (or fail) without telling us. na = "" as in 01/02.
ucdp_raw <- read_csv(here("data", "raw", "ucdp_acd.csv"), na = "",
                     col_select = c(conflict_id, year, intensity_level, gwno_loc),
                     col_types = cols(gwno_loc = col_character(),
                                      .default = col_double()))

# 3. One row per country ----------------------------------------------
# gwno_loc (Gleditsch-Ward code of the conflict's location) can list
# several countries, separated by ", ". A conflict located in two countries
# is a conflict in BOTH, so we split into one row per conflict-year-country
# (not: keep the first code, or drop the row).
n_multi <- sum(str_detect(ucdp_raw$gwno_loc, ","))

ucdp_long <- ucdp_raw |>
  separate_longer_delim(gwno_loc, delim = ",") |>
  mutate(gwno_loc = as.numeric(str_trim(gwno_loc)))

message("UCDP: ", nrow(ucdp_raw), " conflict-year rows; ", n_multi,
        " have several countries in gwno_loc; ", nrow(ucdp_long),
        " rows after splitting")

# 4. Collapse to country-year ------------------------------------------
# Every row in the file already has >= 25 battle-related deaths, so
# conflict = 1 for every country-year that appears. Country-years without
# a row are NOT filled with 0 here: only the master frame (V-Dem, in
# 04_merge.R) says which country-years exist.
ucdp <- ucdp_long |>
  summarise(
    conflict      = 1L,
    n_conflicts   = n_distinct(conflict_id),
    max_intensity = max(intensity_level),   # 1 = minor, 2 = war (>= 1,000 deaths)
    .by = c(gwno_loc, year)
  ) |>
  arrange(gwno_loc, year)

# 5. Save -------------------------------------------------------------
saveRDS(ucdp, here("data", "clean", "ucdp.rds"))
message("03_clean_ucdp.R: ", nrow(ucdp), " country-years, ",
        n_distinct(ucdp$gwno_loc), " countries, ",
        min(ucdp$year), "-", max(ucdp$year))

# 6. Checks -----------------------------------------------------------
stopifnot(
  !anyDuplicated(ucdp[c("gwno_loc", "year")]),          # unique key
  !anyNA(ucdp_long$gwno_loc), !anyNA(ucdp$year),        # split/parse lost nothing
  nrow(ucdp_long) == nrow(ucdp_raw) + sum(str_count(ucdp_raw$gwno_loc, ",")),
  all(ucdp$conflict == 1L),
  all(ucdp$max_intensity %in% 1:2),
  all(ucdp$n_conflicts >= 1),
  all(ucdp$year >= 1946 & ucdp$year <= 2025)
)
