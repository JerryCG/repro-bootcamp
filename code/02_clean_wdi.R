# ------------------------------------------------------------------
# 02_clean_wdi.R
# Purpose: Clean the World Bank WDI snapshot: drop regional and income
#          aggregates (they are not countries), rename the indicators,
#          and take the log of GDP per capita.
# Inputs:  data/raw/wdi.csv
# Outputs: data/clean/wdi.rds
# Author:  Hennes Barnehl
# Date:    2026-09-18
# ------------------------------------------------------------------

# 1. Setup ------------------------------------------------------------
library(tidyverse)
library(here)

# 2. Read -------------------------------------------------------------
# na = "": empty cell = missing. The default would also read Namibia's
# ISO2 code "NA" as missing.
wdi_raw <- read_csv(here("data", "raw", "wdi.csv"), na = "",
                    show_col_types = FALSE)

# 3. Drop aggregates --------------------------------------------------
# WDI mixes countries with aggregates ("World", "Euro area", income groups).
# Most are flagged region == "Aggregates", but 7 have region == NA
# (income groups, "Not classified", and two regional aggregates), so
# region != "Aggregates" alone would miss them, and dplyr::filter() would
# silently drop NAs the other way round. We therefore drop both explicitly
# and print what we drop.
is_aggregate <- is.na(wdi_raw$region) | wdi_raw$region == "Aggregates"

dropped <- wdi_raw |>
  filter(is_aggregate) |>
  distinct(country, iso3c, region, income)
message("Dropping ", nrow(dropped), " aggregates: ",
        str_c(sort(dropped$country), collapse = "; "))

wdi <- wdi_raw |>
  filter(!is_aggregate) |>
  transmute(
    iso3c, country, year, region,
    gdppc        = NY.GDP.PCAP.KD,   # constant 2015 US$
    log_gdppc    = log(NY.GDP.PCAP.KD),
    internet_pct = IT.NET.USER.ZS,   # % of population using the internet
    pop          = SP.POP.TOTL
  )

# 4. Save -------------------------------------------------------------
saveRDS(wdi, here("data", "clean", "wdi.rds"))
message("02_clean_wdi.R: ", nrow(wdi), " country-years, ",
        n_distinct(wdi$iso3c), " countries, ",
        min(wdi$year), "-", max(wdi$year))

# 5. Checks -----------------------------------------------------------
stopifnot(
  # every dropped unit is a genuine aggregate: no income group, or "Aggregates"
  all(is.na(dropped$income) | dropped$income == "Aggregates"),
  !anyNA(wdi$iso3c),
  all(str_detect(wdi$iso3c, "^[A-Z]{3}$")),
  !anyDuplicated(wdi[c("iso3c", "year")]),
  all(wdi$year %in% 2000:2024),
  !any(wdi$region == "Aggregates"),
  all(wdi$gdppc > 0, na.rm = TRUE),
  between(n_distinct(wdi$iso3c), 200, 230)       # ~217 economies expected
)
