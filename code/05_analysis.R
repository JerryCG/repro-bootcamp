# ------------------------------------------------------------------
# 05_analysis.R
# Purpose: Estimate the ONE confirmatory model of the pre-analysis plan
#          (pap/pre_analysis_plan.md), exactly as specified, and save the
#          results for the paper. No other specifications are run here:
#          anything else would be exploratory and belongs in the paper's
#          "Exploratory analyses" section.
# Inputs:  data/clean/panel.rds
# Outputs: output/tables/main_results.rds   (model, coefficients, sample sizes)
#          output/tables/main_results.md    (regression table)
#          output/figures/censorship_by_conflict.png
# Author:  Hennes Barnehl
# Date:    2026-09-18
# ------------------------------------------------------------------

# 1. Setup ------------------------------------------------------------
library(tidyverse)
library(here)
library(fixest)
library(modelsummary)

ALPHA <- 0.05  # two-sided, from the PAP

panel <- readRDS(here("data", "clean", "panel.rds"))

# 2. Confirmatory model -----------------------------------------------
# Exactly the PAP: TWFE, SEs clustered by country. fixest drops country-years
# with a missing value in any model variable (listwise deletion, as in the PAP).
model <- feols(
  censorship ~ conflict + conflict:autocracy + autocracy + log(gdppc) + internet_pct |
    country + year,
  data = panel, cluster = ~country
)
print(model)

# 3. Extract what the paper needs ---------------------------------------
# Tidy coefficient table. p-values use the t distribution with (clusters - 1)
# degrees of freedom, the fixest default for clustered SEs.
coef_table <- coeftable(model)
coefs <- tibble(
  term      = rownames(coef_table),
  estimate  = coef_table[, "Estimate"],
  std_error = coef_table[, "Std. Error"],
  statistic = coef_table[, "t value"],
  p_value   = coef_table[, "Pr(>|t|)"]
) |>
  bind_cols(as_tibble(confint(model, level = 1 - ALPHA)) |>
              set_names(c("conf_low", "conf_high")))

# Implied conflict effect in autocracies (conflict + conflict:autocracy),
# reported for interpretation only (PAP, "Inference criteria").
b <- coef(model)[c("conflict", "conflict:autocracy")]
v <- vcov(model)[c("conflict", "conflict:autocracy"), c("conflict", "conflict:autocracy")]
effect_autocracy <- tibble(
  estimate  = sum(b),
  std_error = sqrt(sum(v)),           # var(b1) + var(b2) + 2 cov(b1, b2)
  p_value   = 2 * pt(-abs(estimate / std_error), df = degrees_freedom(model, "t"))
)

# The estimation sample: which panel rows did the model actually use?
used <- panel[obs(model), ]

results <- list(
  model            = model,
  coefs            = coefs,
  effect_autocracy = effect_autocracy,
  alpha            = ALPHA,
  n_obs            = nobs(model),                        # estimation sample
  n_countries      = n_distinct(used$country),
  year_min         = min(used$year),
  year_max         = max(used$year),
  n_panel          = nrow(panel),                        # V-Dem master frame
  n_panel_countries = n_distinct(panel$country),
  n_dropped        = nrow(panel) - nobs(model),          # listwise deletion
  n_conflict_obs   = sum(used$conflict == 1),
  n_autocracy_obs  = sum(used$autocracy == 1),
  # table layout, shared with the paper
  coef_map = c(
    "conflict"           = "Conflict",
    "conflict:autocracy" = "Conflict x autocracy",
    "autocracy"          = "Autocracy",
    "log(gdppc)"         = "log GDP per capita",
    "internet_pct"       = "Internet users (% of population)"
  ),
  gof_map   = c("nobs", "r.squared", "r2.within", "FE: country", "FE: year"),
  statistic = c("({std.error})", "p = {p.value}"),
  fmt       = 4
)

# 4. Save -------------------------------------------------------------
saveRDS(results, here("output", "tables", "main_results.rds"))

modelsummary(list("Censorship" = model),
             coef_map = results$coef_map, gof_map = results$gof_map,
             statistic = results$statistic, fmt = results$fmt, stars = FALSE,
             title = "Confirmatory model: conflict and internet censorship",
             notes = "Higher censorship = more internet filtering. Standard errors clustered by country.",
             output = here("output", "tables", "main_results.md"))

# Figure: descriptive (not part of the confirmatory test). Mean censorship in
# country-years with and without conflict, by regime type; dot size = number
# of country-years behind each mean (some cells are small).
fig_data <- panel |>
  filter(!is.na(autocracy), !is.na(censorship)) |>
  mutate(regime   = if_else(autocracy == 1, "Autocracies", "Democracies"),
         conflict = factor(conflict, levels = 0:1, labels = c("No conflict", "Conflict"))) |>
  summarise(mean_censorship = mean(censorship), n = n(), .by = c(year, regime, conflict))

fig <- ggplot(fig_data, aes(year, mean_censorship, colour = conflict)) +
  geom_line(linewidth = 0.6) +
  geom_point(aes(size = n)) +
  facet_wrap(~regime) +
  scale_x_continuous(breaks = c(2000, 2010, 2020)) +
  scale_colour_manual(values = c("No conflict" = "#0072B2", "Conflict" = "#D55E00")) +
  scale_size_continuous(range = c(0.8, 3.5), name = "Country-years") +
  labs(x = NULL, y = "Mean censorship (higher = more filtering)", colour = NULL,
       title = "Internet censorship by conflict status and regime type") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

ggsave(here("output", "figures", "censorship_by_conflict.png"), fig,
       width = 8, height = 4.2, dpi = 150, bg = "white")

message("05_analysis.R: N = ", results$n_obs, ", ", results$n_countries,
        " countries, ", results$year_min, "-", results$year_max)

# 5. Checks -----------------------------------------------------------
stopifnot(
  identical(names(coef(model)),
            c("conflict", "autocracy", "log(gdppc)", "internet_pct", "conflict:autocracy")),
  identical(all.vars(model$fml_all$fixef), c("country", "year")),  # PAP fixed effects
  results$n_obs == nrow(drop_na(panel, censorship, conflict, autocracy, gdppc, internet_pct)),
  results$n_obs + results$n_dropped == nrow(panel),
  all(is.finite(coefs$std_error)), all(coefs$std_error > 0),
  file.exists(here("output", "tables", "main_results.rds")),
  file.exists(here("output", "figures", "censorship_by_conflict.png"))
)
