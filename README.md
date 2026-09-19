# Do governments censor the internet more during armed conflict?

Author: Hennes Barnehl

A small, fully reproducible research project used in the Math Camp session on reproducible science and coding agents. **Research question:** do governments censor the internet more when they face armed conflict, and is the effect stronger in autocracies? We combine country-year data on internet censorship and regime type (V-Dem), armed conflict (UCDP/PRIO), and GDP and internet use (World Bank WDI), and estimate a two-way fixed-effects model with `fixest`. The analysis is pre-specified in `pap/pre_analysis_plan.md`.

## How to reproduce

```bash
Rscript code/00_download_data.R    # download raw data into data/raw/ (about a minute; skipped if files exist)
Rscript run_all.R                  # clean, merge, analyze, knit paper/paper.html
```

`run_all.R` runs every numbered script in `code/` in order and then knits the paper. (Runtime with data present: about 6 seconds on the instructor's laptop.) Every number, table and figure in the paper is computed by `code/05_analysis.R` and the inline R code in `paper/paper.Rmd`.

## Folder structure

| Path | Role |
|---|---|
| `code/` | numbered scripts, run in order by `run_all.R` (`00` download, `01`-`04` clean and merge into `data/clean/panel.rds`, `05` analysis) |
| `code/extra/` | documentation scripts that `run_all.R` does not run (`make_vdem_extract.R`) |
| `data/raw/` | raw data as downloaded. **Never edit.** Git-ignored; re-created by `code/00_download_data.R` |
| `data/clean/` | cleaned data written by the scripts. Git-ignored; re-created by `run_all.R` |
| `output/tables/`, `output/figures/` | results written by the analysis script |
| `pap/` | pre-analysis plan |
| `paper/` | `paper.Rmd`; every number is computed in code, `paper.html` is knitted (git-ignored) |
| `guides/` | `agent_best_practices.md`, `git_cheatsheet.md` |
| `AGENTS.md`, `CLAUDE.md` | instructions for coding agents (`CLAUDE.md` just imports `AGENTS.md`) |

## Data sources

All raw files come with a provenance record in `data/raw/SOURCES.txt` (URL used, timestamp, MD5). Each download has a fallback copy on this repository's release `data-v1` in case the original source is unavailable.

**V-Dem v16** (Varieties of Democracy Country-Year Dataset, version 16, March 2026). License: **CC BY-SA 4.0** (ShareAlike: the extract we redistribute is CC BY-SA 4.0 too). Citation:
> Coppedge, Michael, John Gerring, Carl Henrik Knutsen, Staffan I. Lindberg, Jan Teorell, David Altman, Fabio Angiolillo, Michael Bernhard, Agnes Cornell, M. Steven Fish, Linnea Fox, Lisa Gastaldi, Haakon Gjerløw, Adam Glynn, Ana Good God, Allen Hicken, Katrin Kinzelbach, Joshua Krusell, Kyle L. Marquardt, Kelly McMann, Valeriya Mechkova, Juraj Medzihorsky, Anja Neundorf, Pamela Paxton, Daniel Pemstein, Josefine Pernes, Johannes von Römer, Brigitte Seim, Rachel Sigman, Svend-Erik Skaaning, Jeffrey Staton, Aksel Sundström, Marcus Tannenberg, Eitan Tzelgov, Yi-ting Wang, Tore Wig, Steven Wilson and Daniel Ziblatt. 2026. "V-Dem Country-Year Dataset v16". Varieties of Democracy (V-Dem) Project. https://doi.org/10.23696/vdemds26

Codebook: https://v-dem.net/documents/70/codebook_v16.pdf. **How `data/raw/vdem.csv` was made:** v-dem.net only offers downloads behind a web form, so there is no script-friendly original. The full dataset (4,618 columns, 34 MB) is published by the V-Dem team in the GitHub repository [vdeminstitute/vdemdata](https://github.com/vdeminstitute/vdemdata) (pinned commit `f4dd269`, "v16 release"). We keep 11 columns and the years 1990-2025 (6,383 rows, 0.4 MB): `country_name, country_text_id, country_id, COWcode, year, v2smgovfilprc, v2smgovshut, v2smgovsmcenprc, v2mecenefi, v2x_regime, v2x_polyarchy`. The exact code is in `code/extra/make_vdem_extract.R`; `00_download_data.R` first fetches the small extract from the release and rebuilds it from the full file if that fails. The extract is what the project treats as raw data.

Variables: `v2smgovfilprc` government Internet filtering in practice (our main measure), `v2smgovshut` government Internet shut down in practice, `v2smgovsmcenprc` government social media censorship in practice, `v2mecenefi` Internet censorship effort, `v2x_regime` Regimes of the World (0 closed autocracy, 1 electoral autocracy, 2 electoral democracy, 3 liberal democracy), `v2x_polyarchy` electoral democracy index. **All four censorship variables are coded "higher = less censorship"**, so `01_clean_vdem.R` reverses them (sign flip: they are interval-scale model outputs) to make higher = more censorship. Note: the variable is `v2smgovshut`, not `v2smgovshutprc` (that name does not exist in v16).

**UCDP/PRIO Armed Conflict Dataset, version 26.1** (conflict-year data, 1946-2025). Source: https://ucdp.uu.se/downloads/ (zip: https://ucdp.uu.se/downloads/ucdpprio/ucdp-prio-acd-261-csv.zip). License: CC BY 4.0. Every row is a conflict with at least 25 battle-related deaths in that year (`intensity_level` 1 = minor, 2 = war). Citations:
> Davies, Shawn, Therese Pettersson, and Magnus Öberg. 2026. "Organized violence 1989-2025, and violent political protests." *Journal of Peace Research* 63(4): 705-723. https://doi.org/10.1093/jopres/xjag046
>
> Gleditsch, Nils Petter, Peter Wallensteen, Mikael Eriksson, Margareta Sollenberg, and Håvard Strand. 2002. "Armed Conflict 1946-2001: A New Dataset." *Journal of Peace Research* 39(5): 615-637. https://doi.org/10.1177/0022343302039005007

UCDP is part of and funded by DEMSCORE, national research infrastructure grant 2021-00162 from the Swedish Research Council. Note: `gwno_loc` (Gleditsch-Ward code of the conflict location) can hold several countries separated by ", ".

**World Development Indicators (WDI)**, World Bank, retrieved through the R package `WDI` (2.8.0) for 2000-2024: `NY.GDP.PCAP.KD` (GDP per capita, constant 2015 US$), `IT.NET.USER.ZS` (individuals using the internet, % of population), `SP.POP.TOTL` (population). https://data.worldbank.org/. Citation: World Bank. World Development Indicators. Washington, DC: The World Bank; accessed via the WDI R package. License: World Bank open data are released under CC BY 4.0 by default. The raw file keeps regional and income aggregates on purpose; `02_clean_wdi.R` removes them. 2025 is excluded because internet-use data exist for only a few economies that year, so the analysis sample is 2000-2024. WDI values are revised over time: the release snapshot is the version the class numbers were computed on.

## Software

R 4.5.3 with `tidyverse` (2.0.0), `here` (1.0.2), `countrycode` (1.8.0), `fixest` (0.14.0), `modelsummary` (2.6.0), `rmarkdown` (2.29), `knitr` (1.50) and `WDI` (2.8.0), and pandoc (bundled with RStudio). Install once:

```r
install.packages(c("tidyverse", "here", "countrycode", "fixest", "modelsummary", "rmarkdown", "knitr", "WDI"))
```

## Guides

- [`guides/agent_best_practices.md`](guides/agent_best_practices.md): ten practices for working with a coding agent (Codex CLI or Claude Code)
- [`guides/git_cheatsheet.md`](guides/git_cheatsheet.md): terminal basics, the git commands used today, undo recipes, checkpoint branches
