# ------------------------------------------------------------------
# 01_clean_vdem.R
# Purpose: Clean the V-Dem extract: keep the analysis years, recode the
#          censorship measures so that HIGHER = MORE censorship, and
#          create the autocracy indicator. V-Dem is the master frame
#          (one row per country-year) for the merge in 04_merge.R.
# Inputs:  data/raw/vdem.csv
# Outputs: data/clean/vdem.rds
# Author:  Hennes Barnehl
# Date:    2026-09-18
# ------------------------------------------------------------------

# 1. Setup ------------------------------------------------------------
library(tidyverse)
library(here)

# Sample window from the PAP. 2024 is the last year with World Bank
# coverage for GDP and internet use (V-Dem itself runs to 2025).
YEAR_MIN <- 2000
YEAR_MAX <- 2024

# 2. Read -------------------------------------------------------------
# na = "": the extract writes missing values as empty cells.
vdem_raw <- read_csv(here("data", "raw", "vdem.csv"), na = "",
                     show_col_types = FALSE)

# 3. Recode -----------------------------------------------------------
# All four V-Dem censorship variables are coded "higher = LESS censorship"
# (codebook v16, e.g. v2smgovfilprc: 0 = filters extremely often ... 4 = never).
# Our hypotheses are about MORE censorship, so we flip the sign. The
# variables we use are the interval-scale measurement-model outputs
# (roughly -4 to +3), so reversing means negating, not 4 - x.
vdem <- vdem_raw |>
  filter(year >= YEAR_MIN, year <= YEAR_MAX) |>
  mutate(
    censorship          = -v2smgovfilprc,   # main DV: internet filtering
    censorship_shutdown = -v2smgovshut,     # alternative: internet shutdowns
    censorship_smcen    = -v2smgovsmcenprc, # alternative: social media censorship
    censorship_media    = -v2mecenefi,      # alternative: internet censorship effort
    # V-Dem Regimes of the World: 0 closed autocracy, 1 electoral autocracy,
    # 2 electoral democracy, 3 liberal democracy. Keep missing as missing
    # (a plain %in% would silently turn NA into FALSE).
    autocracy = if_else(is.na(v2x_regime), NA_integer_,
                        as.integer(v2x_regime %in% c(0, 1)))
  ) |>
  select(country_name, country_text_id, country_id, COWcode, year,
         censorship, censorship_shutdown, censorship_smcen, censorship_media,
         v2x_regime, autocracy, polyarchy = v2x_polyarchy)

# 4. Save -------------------------------------------------------------
saveRDS(vdem, here("data", "clean", "vdem.rds"))
message("01_clean_vdem.R: ", nrow(vdem), " country-years, ",
        n_distinct(vdem$country_text_id), " countries, ",
        min(vdem$year), "-", max(vdem$year))

# 5. Checks -----------------------------------------------------------
stopifnot(
  !anyDuplicated(vdem[c("country_text_id", "year")]),   # unique key
  all(range(vdem$year) == c(YEAR_MIN, YEAR_MAX)),
  all(vdem$censorship >= -3.5 & vdem$censorship <= 4, na.rm = TRUE), # reversed scale
  all(vdem$v2x_regime %in% c(0, 1, 2, 3, NA)),
  identical(is.na(vdem$autocracy), is.na(vdem$v2x_regime)),          # no NA-as-0
  sum(!is.na(vdem$censorship)) > 4000                                # data loaded
)
