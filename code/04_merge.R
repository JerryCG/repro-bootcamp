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

# 1. Setup ------------------------------------------------------------
library(tidyverse)
library(here)
library(countrycode)

vdem <- readRDS(here("data", "clean", "vdem.rds"))
wdi <- readRDS(here("data", "clean", "wdi.rds"))
ucdp <- readRDS(here("data", "clean", "ucdp.rds"))

# 2. Harmonize IDs ----------------------------------------------------
# ISO3 permits the COW, Gleditsch-Ward, and WDI identifiers to refer to the
# same countries without changing V-Dem's country-year master frame.
vdem <- vdem |>
  mutate(
    iso3c = countrycode(
      COWcode, origin = "cown", destination = "iso3c",
      custom_match = c("345" = "SRB", "347" = "XKX")
    )
  )

ucdp <- ucdp |>
  filter(year >= min(vdem$year), year <= max(vdem$year)) |>
  mutate(
    iso3c = countrycode(
      gwno_loc, origin = "gwn", destination = "iso3c",
      custom_match = c("345" = "SRB", "678" = "YEM")
    ),
    country = countrycode(
      gwno_loc, origin = "gwn", destination = "country.name",
      custom_match = c("345" = "Serbia", "678" = "Yemen")
    )
  )

vdem_countries <- vdem |>
  distinct(iso3c)

# Sources include units outside V-Dem's coverage. Report them before the
# master-frame joins, which exclude them without dropping V-Dem observations.
wdi_unmatched <- wdi |>
  distinct(country, iso3c) |>
  anti_join(vdem_countries, by = "iso3c") |>
  transmute(country, code = iso3c, source = "WDI")

ucdp_unmatched <- ucdp |>
  distinct(country, gwno_loc, iso3c) |>
  anti_join(vdem_countries, by = "iso3c") |>
  transmute(country, code = as.character(gwno_loc), source = "UCDP")

unmatched <- bind_rows(wdi_unmatched, ucdp_unmatched) |>
  arrange(source, country, code)
message("Units not matched to a V-Dem country (excluded by master-frame joins):")
print(unmatched, n = Inf)

# 3. Merge ------------------------------------------------------------
# A missing UCDP join means no recorded conflict in a V-Dem country-year;
# missing values from matched records and from every other source stay missing.
panel <- vdem |>
  left_join(wdi, by = c("iso3c", "year")) |>
  left_join(
    select(ucdp, iso3c, year, conflict, n_conflicts, max_intensity),
    by = c("iso3c", "year")
  ) |>
  mutate(
    no_ucdp_record = is.na(conflict),
    conflict = replace_na(conflict, 0L),
    n_conflicts = if_else(no_ucdp_record, 0L, n_conflicts),
    max_intensity = if_else(no_ucdp_record, 0, max_intensity)
  ) |>
  select(-no_ucdp_record)

# 4. Save -------------------------------------------------------------
saveRDS(panel, here("data", "clean", "panel.rds"))
write_csv(panel, here("data", "clean", "panel.csv"), na = "")
message("04_merge.R: ", nrow(panel), " country-years, ",
        n_distinct(panel$country_text_id), " countries, ",
        min(panel$year), "-", max(panel$year))

# 5. Checks -----------------------------------------------------------
# Checks
stopifnot(
  !anyDuplicated(panel[c("country_text_id", "year")]), # unique country-year key
  all(range(panel$year) == c(2000, 2024)),
  nrow(panel) == nrow(vdem),
  !anyNA(panel$conflict)
)
