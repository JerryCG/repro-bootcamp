# ------------------------------------------------------------------
# 05_analysis.R
# Purpose: Estimate the single confirmatory model in the pre-analysis
#          plan and save the model, table, and descriptive figure.
# Inputs:  data/clean/panel.rds
# Outputs: output/tables/main_results.rds, output/tables/main_results.html,
#          output/figures/descriptive_censorship_by_conflict.png
# Author:  Hennes Barnehl
# Date:    2026-09-21
# ------------------------------------------------------------------

# 1. Setup ------------------------------------------------------------
library(tidyverse)
library(here)
library(fixest)
library(modelsummary)

dir.create(here("output", "tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("output", "figures"), recursive = TRUE, showWarnings = FALSE)

# 2. Prepare confirmatory sample -------------------------------------
panel <- readRDS(here("data", "clean", "panel.rds"))

# The PAP prespecifies listwise deletion for every variable in the model.
model_variables <- c("censorship", "conflict", "autocracy", "gdppc", "internet_pct")
analysis_panel <- panel |>
  filter(if_all(all_of(model_variables), ~ !is.na(.x)))

message("05_analysis.R: listwise deletion omitted ", nrow(panel) - nrow(analysis_panel),
        " of ", nrow(panel), " country-years.")

# 3. Estimate confirmatory model -------------------------------------
confirmatory_model <- feols(
  censorship ~ conflict + conflict:autocracy + autocracy + log(gdppc) + internet_pct |
    country_text_id + year,
  data = analysis_panel,
  cluster = ~country_text_id
)

coefficient_table <- as.data.frame(coeftable(confirmatory_model)) |>
  rownames_to_column("term") |>
  transmute(
    term,
    estimate = Estimate,
    std_error = `Std. Error`,
    p_value = `Pr(>|t|)`
  ) |>
  left_join(
    as.data.frame(confint(confirmatory_model, level = 0.95)) |>
      rownames_to_column("term") |>
      set_names(c("term", "conf_low", "conf_high")),
    by = "term"
  )

conflict_result <- coefficient_table |>
  filter(term == "conflict")
message("05_analysis.R: N = ", nobs(confirmatory_model), "; conflict = ",
        round(conflict_result$estimate, 4), " (SE = ",
        round(conflict_result$std_error, 4), ", p = ",
        signif(conflict_result$p_value, 4), ").")

# This linear combination is descriptive interpretation of the planned model,
# not an additional hypothesis test. Its uncertainty uses the model's
# country-clustered covariance matrix.
autocratic_terms <- c("conflict", "conflict:autocracy")
autocratic_conflict_effect <- tibble(
  estimate = sum(coef(confirmatory_model)[autocratic_terms]),
  std_error = sqrt(sum(vcov(confirmatory_model)[autocratic_terms, autocratic_terms]))
)

analysis_numbers <- list(
  n = nobs(confirmatory_model),
  countries = n_distinct(analysis_panel$country_text_id),
  first_year = min(analysis_panel$year),
  last_year = max(analysis_panel$year)
)

# 4. Save -------------------------------------------------------------
main_results <- list(
  model = confirmatory_model,
  coefficient_table = coefficient_table,
  analysis_numbers = analysis_numbers,
  autocratic_conflict_effect = autocratic_conflict_effect
)

saveRDS(main_results, here("output", "tables", "main_results.rds"))

modelsummary(
  confirmatory_model,
  output = here("output", "tables", "main_results.html"),
  stars = FALSE,
  gof_map = c("nobs", "r.squared", "within.r.squared")
)

# The figure describes the confirmatory estimation sample without adding a
# second specification or a hypothesis test.
descriptive_data <- analysis_panel |>
  mutate(conflict = factor(conflict, levels = c(0, 1),
                           labels = c("No armed conflict", "Armed conflict"))) |>
  group_by(conflict) |>
  summarise(mean_censorship = mean(censorship), .groups = "drop")

descriptive_figure <- ggplot(descriptive_data,
                             aes(x = conflict, y = mean_censorship, fill = conflict)) +
  geom_col(show.legend = FALSE) +
  labs(
    x = NULL,
    y = "Mean government internet filtering",
    title = "Government internet filtering by armed conflict status"
  ) +
  theme_minimal()

ggsave(
  here("output", "figures", "descriptive_censorship_by_conflict.png"),
  descriptive_figure,
  width = 7,
  height = 5,
  dpi = 300
)

# 5. Checks -----------------------------------------------------------
stopifnot(
  !anyDuplicated(analysis_panel[c("country_text_id", "year")]),
  nobs(confirmatory_model) == nrow(analysis_panel),
  all(complete.cases(analysis_panel[model_variables])),
  all(c("conflict", "conflict:autocracy") %in% coefficient_table$term),
  file.exists(here("output", "tables", "main_results.rds")),
  file.exists(here("output", "tables", "main_results.html")),
  file.exists(here("output", "figures", "descriptive_censorship_by_conflict.png"))
)
