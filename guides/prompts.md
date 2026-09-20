# Prompts and commands for the session

Everything you need to copy during the session is in this file, in the order we use it.
Copy from here instead of retyping from the slides.

Open it in RStudio (Files pane > `guides` > `prompts.md`), or read it on GitHub.

Legend:
- **Terminal** = the RStudio Terminal tab (Tools > Terminal > New Terminal; on Windows it must say Git Bash).
- **Console** = the RStudio R Console tab.
- **Agent** = the prompt box of `codex` (or `claude`) running in the Terminal.
- `Pn` = the numbered prompts on the slides.

Rules of the day:
1. Two-minute rule: nothing gets debugged for more than 2 minutes. Sticky note on the lid, take the catch-up command (section 10), we fix it at the break.
2. One primary agent: Codex. Claude Code works too; the prompts are identical.
3. Never `--dangerously-bypass-approvals-and-sandbox`, never Full Access.

---

## 1. Terminal (Block 2)

```bash
pwd
ls
cd ..
ls
```

`Tab` completes names, `↑` repeats the last command, `Ctrl-C` stops a running command.

---

## 2. Git and GitHub (Block 3)

On GitHub: `hbarnehl/repro-bootcamp` > **Use this template** > Create a new repository.
Owner = your account, name `repro-bootcamp`, and **tick "Include all branches"** (easy to miss).

Terminal, replacing `<YOUR-USERNAME>`:

```bash
git clone https://github.com/<YOUR-USERNAME>/repro-bootcamp.git
cd repro-bootcamp
git branch -r
```

`git branch -r` must list `origin/cp1-pap`, `origin/cp2-clean-data`, `origin/cp3-paper`,
`origin/solution`. If it lists only `origin/main`, you missed the tick box: see
`guides/git_cheatsheet.md` section 4 for the three-command fix, and do it now.

Then in RStudio: File > Open Project > `repro-bootcamp.Rproj`.

Edit `README.md`: replace `<your name>` on the `Author:` line with your name. Save. Then:

```bash
git status
git diff
git add README.md
git commit -m "Add author name"
git push
```

Done when: you refresh your repo on GitHub and see the commit.

---

## 3. Pre-analysis plan (Block 4)

`pap/pre_analysis_plan.md` is **already filled in, except for the research question**. Everything
else is fixed for today: your agent will faithfully implement whatever model your PAP contains, so
if you change it, your numbers will not match anyone else's this afternoon.

**Your task:** open the file, read it, and write the research question in one sentence in your own
words (replace the `<!-- ... -->` line under `## Research question`). Then commit and tag.

Read for these five decisions - each one is a place where a later choice could have been made to
suit the result:

1. **DV sign.** `censorship = -v2smgovfilprc`: V-Dem codes *higher = less* filtering, so the sign is
   reversed. A coding decision like this belongs in the PAP, not in a footnote discovered later.
2. **IV threshold.** `conflict` = 1 if at least one UCDP conflict with >= 25 battle deaths is
   located in the country that year. 25 is a choice; 1000 would be another.
3. **Sample.** V-Dem country-years, 2000-2024, V-Dem as the master frame. Which units are dropped,
   and where `conflict = 0` is created, is written down.
4. **Estimation.** One model: `censorship ~ conflict + conflict:autocracy + autocracy + log(gdppc) +
   internet_pct | country + year`, `fixest::feols(..., cluster = ~country)`, listwise deletion.
5. **Inference criteria.** Two-sided, alpha = 0.05, and what counts as support for H1 and H2 -
   written before the estimate exists, so "p = 0.06 is marginally significant" is not available later.

Commit the plan and tag it:

```bash
git add pap/pre_analysis_plan.md
git commit -m "Add the research question to the pre-analysis plan"
git tag pap-v1
git push
git push --tags
git log --oneline --decorate
```

Done when: `git log` shows `(tag: pap-v1)` on your PAP commit, and the tag is visible on GitHub
under Releases/Tags. Forgetting `git push --tags` is the usual mistake.

**Only now** download the data (about a minute; it can finish during the break):

```bash
Rscript code/00_download_data.R
```

Expected last line: `00_download_data.R: all raw data present.` — `[try ]` and `failed:` lines
above it are normal (automatic fallback to a snapshot).

Then, once, in the same Terminal and project folder:

```bash
Rscript -e 'library(fixest)'
```

Why: `fixest` writes a user config file the first time it is loaded in a new project folder, and
the agent's sandbox cannot write there. Without this step the agent's `run_all.R` fails later at
`05_analysis.R`.

---

## 4. Launching the agent (Block 5)

In the project folder:

```bash
codex
```

Claude Code users:

```bash
claude --permission-mode default
```

Permission modes: Codex `/permissions` (Read Only / Default / Full Access — never Full Access
here). Claude Code: `Shift+Tab` cycles modes; read the mode at the bottom of the screen.
Fresh session: `/new` (Codex), `/clear` (Claude Code).

**P1** (read-only, first prompt) — paste into the agent:

```
Read README.md, AGENTS.md and the list of files in code/. Explain in at most 10 lines what this repository does and how to run it. Don't change any files and don't run any code.
```

Done when: it answers, and `git status` in a second Terminal tab says "working tree clean".

---

## 5. Conventions in AGENTS.md (Block 7)

In RStudio, open `AGENTS.md` and replace the line `<!-- In class we'll add ... -->` under
`## Project conventions` with this block (by hand — do not let the agent or `/init` do it):

```markdown
**Folders**
- `data/raw/` holds raw data exactly as downloaded (read-only, git-ignored, created by `code/00_download_data.R`). `data/clean/` holds cleaned data written by the scripts (git-ignored). `output/tables/` and `output/figures/` hold results. `pap/` holds the pre-analysis plan. `paper/` holds `paper.Rmd`.
- Scripts live in `code/`, are numbered (`00_`, `01_`, ...) and run in that order. `code/extra/` is never run by `run_all.R`.
- `Rscript run_all.R` reproduces everything from `data/raw/` to `paper/paper.html`. It is the only verification command; do not add other entry points.

**Scripts**
- Every script starts with a header block: purpose, inputs, outputs, author, date. Numbered sections, comments that explain why (not what).
- Each script (except `00_download_data.R`, which writes `data/raw/`) reads from `data/raw/` or `data/clean/` and writes to `data/clean/` or `output/`. No script writes anywhere else.
- Every script ends with `stopifnot()` checks (unique keys, expected ranges, no missing values silently turned into 0).
- Style: tidyverse, `|>` pipe, `snake_case` names. Model scripts to imitate: `code/01_clean_vdem.R`, `code/02_clean_wdi.R`.
- Read CSVs with `na = ""`. Never drop or recode rows silently: print what you drop (for example unmatched country codes).

**Analysis and paper**
- The confirmatory analysis is exactly the model in `pap/pre_analysis_plan.md`. Do not add specifications, controls or subsamples. Anything else is exploratory and goes under "Exploratory analyses" in the paper.
- Every number in the paper is inline R code (`` `r ...` ``) computed from saved results, never typed by hand.
```

Then commit:

```bash
git add AGENTS.md
git commit -m "Add file-management conventions to AGENTS.md"
git push
```

**Restart the agent afterwards** (exit and relaunch `codex` / `claude`): the context file is read
at session start, so a session that began before your edit does not know the new rules.

---

## 6. Data pipeline: `03_clean_ucdp.R` (Block 8a)

Before every agent task:

```bash
git status          # must say: nothing to commit, working tree clean
```

**P2** (plan only; start a new session first):

```
Read AGENTS.md, pap/pre_analysis_plan.md, code/03_clean_ucdp.R and (as the style model) code/01_clean_vdem.R. Give a short plan to complete only the TODOs in code/03_clean_ucdp.R, including the checks you will run. Don't edit any files yet.
```

**P3** (implement):

```
Implement the approved plan only in code/03_clean_ucdp.R. Don't modify data/raw/, the PAP, or any other file. Run Rscript run_all.R and summarize what the script printed and which checks you added.
```

Then read the diff yourself:

```bash
git diff
```

**P4** (verification, ask the agent):

```
How many rows of data/raw/ucdp_acd.csv have several countries in gwno_loc, how many rows are there after splitting, and how did you handle them? Tell me how you know each number.
```

Check independently, in the **Console**:

```r
library(tidyverse)
raw <- read_csv("data/raw/ucdp_acd.csv", na = "", col_types = cols(.default = "c"))
sum(str_detect(raw$gwno_loc, ","))                          # should be 159
nrow(raw) + sum(str_count(raw$gwno_loc, ","))               # rows after splitting: 2,990
nrow(readRDS("data/clean/ucdp.rds"))                        # country-years: 2,112
```

Commit:

```bash
git add code/03_clean_ucdp.R
git commit -m "Complete 03_clean_ucdp.R with the agent"
git push
```

If the agent fails the same way two or three times (Practice 8): `git restore .`, `/new` or
`/clear`, and prompt again with the file names and the exact error text.

---

## 7. Data pipeline: `04_merge.R` (Block 8b)

Commit first, `git status` clean, and start a **new session** (`/new` or `/clear`).

**P5** (plan only):

```
Read AGENTS.md, pap/pre_analysis_plan.md, code/04_merge.R, and the headers of code/01_clean_vdem.R, code/02_clean_wdi.R and code/03_clean_ucdp.R. Give a short plan to complete only the TODOs in code/04_merge.R: which key you will use, how you will handle country codes that do not match, where (if anywhere) missing values become 0, and which checks you will run. Don't edit any files yet.
```

**P6** (implement):

```
Implement the approved plan only in code/04_merge.R. Don't modify data/raw/, the PAP, or any other file. Run Rscript run_all.R and report: the number of rows, countries and years in the panel, the number of country-years with conflict = 1, and every unit that did not match a V-Dem country.
```

`git diff`, then:

**P7** (verification, ask the agent; read-only):

```
Which country codes from UCDP and WDI failed to match a V-Dem country, and what did you do with each? Where in the code do missing values become 0, and for which variables? Then compare the panel with data/clean/ucdp.rds: for 2000-2024, is every country-year with conflict in ucdp.rds also a country-year with conflict = 1 in the panel? List any that are not, and explain why. Don't edit any files.
```

Check independently, in the **Console**:

```r
library(tidyverse)
panel <- readRDS("data/clean/panel.rds"); vdem <- readRDS("data/clean/vdem.rds")
nrow(panel); n_distinct(panel$country_text_id)   # 4,457 rows; 179 countries
sum(is.na(panel$iso3c))                   # if the panel has an iso3c column: 0
nrow(panel) == nrow(vdem)                 # TRUE: panel = V-Dem frame
sum(panel$conflict)                       # 763
sum(is.na(panel$gdppc))                   # 169: WDI gaps must NOT be 0
```

(Your panel may name the country ID differently: check `names(panel)`.)

Unmatched UCDP codes before any custom fix:

```r
u <- readRDS("data/clean/ucdp.rds")
u$iso3c <- countrycode::countrycode(u$gwno_loc, "gwn", "iso3c", warn = FALSE)
u |> filter(is.na(iso3c) | !iso3c %in% vdem$country_text_id) |> count(gwno_loc)
```

Commit:

```bash
git add code/04_merge.R
git commit -m "Complete 04_merge.R with the agent"
git push
```

---

## 8. Analysis script and paper (Block 9)

Commit first, new session.

**P8** (plan only, analysis script):

```
Read pap/pre_analysis_plan.md, AGENTS.md, code/04_merge.R (for the columns of the panel it saves) and code/01_clean_vdem.R (as the style model). Give a short plan to create only code/05_analysis.R so that it estimates the confirmatory model exactly as specified in the PAP and saves results to output/. Don't add specifications and don't choose anything by significance. Don't edit any files yet.
```

**P9** (implement):

```
Implement the approved plan by creating only code/05_analysis.R. Estimate the confirmatory model exactly as specified in the PAP (no extra specifications, controls or subsamples, nothing chosen by significance). Save (1) output/tables/main_results.rds: a list with the fitted model, the coefficient table (estimate, standard error, p-value, confidence interval) and the numbers the paper needs (N, number of countries, first and last year); (2) a regression table made with modelsummary in output/tables/; (3) one descriptive figure in output/figures/. Don't modify any other file. Run Rscript run_all.R and report the N, and the coefficient on conflict with its standard error and p-value.
```

`git diff`, then commit:

```bash
git add code/05_analysis.R
git commit -m "Add 05_analysis.R: confirmatory model from the PAP"
git push
```

New session.

**P10** (plan only, paper):

```
Read paper/paper.Rmd, pap/pre_analysis_plan.md, AGENTS.md and code/05_analysis.R. List the marked TODOs in paper/paper.Rmd and, for each, say what you will write and which saved value it will use. Don't edit any files yet.
```

**P11** (implement):

```
Implement the approved plan only in paper/paper.Rmd: complete only the marked TODOs. Every number in the text must come from the saved results via inline R code, not be typed by hand. Don't modify any other file. Run Rscript run_all.R, tell me the path of the knitted HTML, and list any number in the text that is still typed by hand.
```

`git diff`, open `paper/paper.html` (Files pane > View in Web Browser), then:

```bash
git add paper/paper.Rmd
git commit -m "Complete paper.Rmd: results as inline R"
git push
```

Untracked files under `output/` are fine; do not `git add` them. Modified *tracked* files are what
matters.

---

## 9. Reproducibility swap (Block 11)

Push your work, then swap repository URLs with your neighbor:

```bash
git status
git push
```

In a folder **outside** your own project:

```bash
git clone https://github.com/<NEIGHBOR-USERNAME>/repro-bootcamp.git repro-check
cd repro-check
Rscript code/00_download_data.R
Rscript run_all.R
```

If your neighbor worked on a checkpoint branch, clone that branch:
`git clone -b cp3-paper <URL> repro-check`.

Open `paper/paper.html` and compare N, the number of countries, and the `conflict` coefficient.

If it fails, open an issue on their repo (GitHub > Issues > New issue):

```
Title: run_all.R fails on a fresh clone
What I did: git clone, Rscript code/00_download_data.R, Rscript run_all.R
What I expected: paper/paper.html with N = ...
What happened: <paste the last lines of the error>
My setup: <R version from sessionInfo(), OS>
```

---

## 10. Catch-up commands

Run from the project folder. Commit or discard local changes first (`git status`), otherwise
`git switch` refuses.

```bash
git switch cp1-pap          # after the PAP block
git switch cp2-clean-data   # after the data pipeline
git switch cp3-paper        # after the paper block
git switch solution         # final state
```

A branch is a named copy of the project at a checkpoint; switching replaces your files with that
checkpoint. Your own uncommitted edits are gone, which is fine — you are catching up.
`data/raw/` and `data/clean/` are git-ignored, so the data stay: check with `ls data/raw`
(3 csv files plus `SOURCES.txt`). If they are missing, run `Rscript code/00_download_data.R`.

Checkpoint branches have unrelated histories: switching works, merging between them does not.

---

## 11. Where things are

- `guides/agent_best_practices.md` — the ten practices, in full
- `guides/git_cheatsheet.md` — terminal, git commands, undo recipes, the "Include all branches" fix
- `AGENTS.md` — the context file the agent reads at session start
- `pap/pre_analysis_plan.md` — your pre-analysis plan
- `run_all.R` — reproduces everything from `data/raw/` to `paper/paper.html`
