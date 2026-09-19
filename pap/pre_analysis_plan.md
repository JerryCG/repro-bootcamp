# Pre-analysis plan

Anything that is not written here is exploratory.

## Research question
Do governments censor the internet more when armed conflict takes place on their territory, and is this effect stronger in autocracies?

## Hypotheses
- **H1:** Armed conflict increases government internet filtering: country-years with an armed conflict have higher censorship than the same country in years without one. (In the model below, H1 is tested on the effect of conflict where `autocracy` = 0, i.e. in electoral and liberal democracies; see Inference criteria.)
- **H2:** The effect of conflict on censorship is larger in autocracies than in democracies.

## Data & sample
- **Sources:** V-Dem Country-Year Dataset v16 (censorship, regime type; the master frame), UCDP/PRIO Armed Conflict Dataset 26.1 (conflict), World Bank WDI (GDP per capita, internet users).
- **Unit:** country-year, keyed on the V-Dem country. Sample: all country-years covered by V-Dem, **2000-2024**. 2024 is the last year with World Bank coverage of the controls (V-Dem and UCDP run to 2025).
- **Countries in UCDP or WDI but not in V-Dem are excluded** (the WDI units are mostly microstates). V-Dem country-years without a UCDP conflict record are coded as no conflict (`conflict` = 0). No other variable is filled in.

## Variables
- **Dependent variable (DV):** `censorship` = `-v2smgovfilprc` (V-Dem: government Internet filtering in practice). V-Dem codes this variable **higher = less filtering** (codebook v16: 0 = extremely often ... 4 = never), so the sign is reversed: **higher `censorship` = more filtering**. We use the interval-scale measurement-model output of V-Dem, not the ordinal version.
- **Main independent variable (IV):** `conflict` = 1 if at least one UCDP/PRIO armed conflict with at least 25 battle-related deaths in that year is located in the country (Gleditsch-Ward location code, `gwno_loc`; a conflict located in several countries counts for each), otherwise 0.
- **Moderator:** `autocracy` = 1 if V-Dem Regimes of the World `v2x_regime` is 0 (closed autocracy) or 1 (electoral autocracy), 0 if 2 (electoral democracy) or 3 (liberal democracy); missing if `v2x_regime` is missing.
- **Controls:** GDP per capita, constant 2015 US$ (`gdppc`, WDI `NY.GDP.PCAP.KD`), entering as `log(gdppc)`; internet users in % of the population (`internet_pct`, WDI `IT.NET.USER.ZS`).

## Estimation
```r
fixest::feols(
  censorship ~ conflict + conflict:autocracy + autocracy + log(gdppc) + internet_pct | country + year,
  data = panel, cluster = ~country
)
```
Two-way fixed effects (country and year), standard errors clustered by country. Missing data: **listwise deletion** (country-years with a missing value in any model variable are dropped; no imputation). There is one confirmatory model.

## Inference criteria
- Both tests are **two-sided** with **alpha = 0.05**, on the country-clustered standard errors. No multiple-testing correction; both results are reported in full.
- **H1 is supported** if the coefficient on `conflict` (the conflict effect where `autocracy` = 0) is positive and p < 0.05.
- **H2 is supported** if the coefficient on `conflict:autocracy` is positive and p < 0.05.
- The implied conflict effect in autocracies (`conflict` + `conflict:autocracy`, from the same model, with its standard error) is reported for interpretation only; it is not a separate test.
- Anything else, including a null result on either hypothesis, is reported as it is. Other censorship measures (`censorship_shutdown`, `censorship_smcen`, `censorship_media`), other controls, lags or subsamples are not part of the confirmatory analysis.

## Deviations
Any departure from this plan (variables, sample, model, tests) is listed in a "Deviations from the pre-analysis plan" paragraph in the paper, with the reason and the changed result next to the planned one. This file is not edited after the tag; a change would be a new commit and a new tag (`pap-v2`), with the original kept in git history. Analyses that are not in this plan go under "Exploratory analyses" in the paper and are labeled as such.

## Date & git tag
2026-09-18. Tag: `pap-v1`.
