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

# Same sample window as 01_clean_vdem.R (the PAP window).
YEAR_MIN <- 2000
YEAR_MAX <- 2024

vdem <- readRDS(here("data", "clean", "vdem.rds"))
wdi  <- readRDS(here("data", "clean", "wdi.rds"))
ucdp <- readRDS(here("data", "clean", "ucdp.rds"))

# 2. Harmonize IDs ----------------------------------------------------
# The three sources use three ID systems. We map everything to ISO3
# (`iso3c`), with V-Dem as the master frame:
#   V-Dem: country_text_id is ISO3, except three sub-national units
#          (Gaza PSG, Somaliland SML, Zanzibar ZZB) that have no ISO3 code.
#   WDI:   iso3c already.
#   UCDP:  Gleditsch-Ward (GW) numeric codes -> ISO3 with countrycode().
# We do not merge on V-Dem's COWcode: COW and GW codes differ for some
# countries (e.g. Yemen: COW 679, GW 678) and the merge would lose them silently.
vdem <- vdem |> mutate(iso3c = country_text_id)

# countrycode() does not know a few GW codes that continue into today's
# countries. Each case is resolved by hand:
gw_custom_match <- c(
  "678" = "YEM",  # GW "Yemen Arab Republic" is unified Yemen from 1990 on
  "345" = "SRB",  # Yugoslavia / Serbia and Montenegro / Serbia
  "347" = "XKX",  # Kosovo (no conflict rows in this UCDP version; listed for completeness)
  "816" = "VNM"   # GW 816 is North Vietnam until 1975, then unified Vietnam
)
# Not resolved on purpose: states that no longer exist and have no
# country in the V-Dem frame (GW 680 South Yemen, 817 South Vietnam,
# 751 Hyderabad; GW 55 Grenada is not in V-Dem). Their conflicts are all
# before 1990, outside the sample. Kosovo, South Sudan (626 -> SSD) and
# Taiwan (713 -> TWN) match by default.

ucdp <- ucdp |>
  mutate(iso3c_default = countrycode(gwno_loc, "gwn", "iso3c", warn = FALSE),
         iso3c = countrycode(gwno_loc, "gwn", "iso3c",
                             custom_match = gw_custom_match, warn = FALSE))

# List every unit that cannot be matched to the V-Dem frame, BEFORE merging.
report_unmatched <- function(df, code, name, key, label) {
  out <- df |>
    filter(is.na({{ key }}) | !({{ key }} %in% vdem$iso3c)) |>
    summarise(n_rows = n(),
              n_rows_in_sample = sum(year >= YEAR_MIN & year <= YEAR_MAX),
              .by = c({{ code }}, {{ name }})) |>
    arrange(desc(n_rows_in_sample), desc(n_rows))
  message("\n", label, ": ", nrow(out), " unmatched units")
  if (nrow(out) > 0) print(as.data.frame(out), row.names = FALSE)
  invisible(out)
}

ucdp <- ucdp |> mutate(country = countrycode(gwno_loc, "gwn", "country.name", warn = FALSE))
unm_ucdp_before <- report_unmatched(mutate(ucdp, iso3c = iso3c_default),
                                    gwno_loc, country, iso3c,
                                    "UCDP (GW code -> ISO3), before custom_match")
unm_ucdp_after  <- report_unmatched(ucdp, gwno_loc, country, iso3c,
                                    "UCDP (GW code -> ISO3), after custom_match")

# WDI units with no V-Dem counterpart are outside the master frame and are
# dropped on purpose (mostly microstates: Aruba, Andorra, Tonga, ...).
unm_wdi <- report_unmatched(wdi, iso3c, country, iso3c, "WDI units not in V-Dem (dropped)")

# The other direction: V-Dem country-years stay in the panel, with missing
# WDI values. Taiwan is not covered by WDI; V-Dem splits Palestine into West
# Bank (PSE, matches WDI's "West Bank and Gaza") and Gaza (PSG, no WDI row).
no_wdi <- vdem |> filter(!iso3c %in% wdi$iso3c) |> distinct(iso3c, country_name)
message("\nV-Dem countries without any WDI row (kept, controls missing): ",
        str_c(no_wdi$country_name, " (", no_wdi$iso3c, ")", collapse = "; "))

# UCDP rows that fall in the sample window must all have found a V-Dem country
# and a V-Dem country-year; otherwise conflicts would be dropped silently.
ucdp_in_sample <- ucdp |> filter(year >= YEAR_MIN, year <= YEAR_MAX)
stopifnot(!anyNA(ucdp_in_sample$iso3c))
no_frame_row <- anti_join(ucdp_in_sample, vdem, by = c("iso3c", "year"))
if (nrow(no_frame_row) > 0) print(no_frame_row)
stopifnot(nrow(no_frame_row) == 0)

# 3. Merge ------------------------------------------------------------
# Left joins from the V-Dem frame: no country-year can be added or lost.
wdi_vars  <- wdi  |> select(iso3c, year, gdppc, log_gdppc, internet_pct, pop)
ucdp_vars <- ucdp_in_sample |> select(iso3c, year, conflict, n_conflicts, max_intensity)
stopifnot(!anyDuplicated(ucdp_vars[c("iso3c", "year")]))  # two GW codes -> one ISO3?

panel <- vdem |>
  left_join(wdi_vars,  by = c("iso3c", "year")) |>
  left_join(ucdp_vars, by = c("iso3c", "year")) |>
  # A V-Dem country-year without a UCDP row is a year without armed conflict:
  # here (and only here) missing means 0. WDI variables stay NA if missing.
  mutate(across(c(conflict, n_conflicts, max_intensity), \(x) replace_na(x, 0))) |>
  transmute(iso3c, country = country_name, year,
            censorship, censorship_shutdown, censorship_smcen, censorship_media,
            v2x_regime, autocracy, polyarchy,
            conflict = as.integer(conflict), n_conflicts = as.integer(n_conflicts),
            max_intensity = as.integer(max_intensity),
            gdppc, log_gdppc, internet_pct, pop) |>
  arrange(iso3c, year)

# 4. Save -------------------------------------------------------------
saveRDS(panel, here("data", "clean", "panel.rds"))
write_csv(panel, here("data", "clean", "panel.csv"), na = "")
message("\n04_merge.R: ", nrow(panel), " country-years, ",
        n_distinct(panel$iso3c), " countries, ",
        min(panel$year), "-", max(panel$year), "; ",
        sum(panel$conflict), " with conflict")

# 5. Checks -----------------------------------------------------------
stopifnot(
  !anyDuplicated(panel[c("iso3c", "year")]),                  # unique key
  all(range(panel$year) == c(YEAR_MIN, YEAR_MAX)),
  nrow(panel) == nrow(vdem),                                  # master frame kept as is
  identical(panel$iso3c, arrange(vdem, iso3c, year)$iso3c),
  n_distinct(panel$country) == n_distinct(panel$iso3c),
  !anyNA(panel$conflict), all(panel$conflict %in% 0:1),      # no NA left in conflict
  all(panel$n_conflicts >= panel$conflict),
  sum(panel$conflict) == nrow(ucdp_in_sample),                # every UCDP country-year landed
  identical(is.na(panel$autocracy), is.na(panel$v2x_regime)), # no NA-as-0
  sum(is.na(panel$gdppc)) > 0,                                # WDI gaps were NOT filled with 0
  all(panel$gdppc > 0, na.rm = TRUE), all(panel$internet_pct >= 0, na.rm = TRUE)
)
