# Ten practices for working with a coding agent

An agent is a language model in a loop: it reads your files, runs shell commands, edits files, and sees the results. You stay the author. These ten practices keep that true. (The numbers match the slides.)

**Commands in this guide** (checked September 2026; agents change fast, check `/help` if something differs).
Codex CLI: `/permissions` (what it may do), `/new` (fresh session), `/init`, `/diff`, `/status`. Claude Code: `Shift+Tab` (cycle permission modes, incl. plan mode), `/clear` (fresh session), `/init`, `/permissions`.

## Safety net (1, 7, 8)

**1. Work only inside a git repo, and commit before every agent task.**
*Why:* a clean commit turns any bad edit into a one-line undo.
*Do:* `git status` (must be clean), then `git commit -am "checkpoint before agent"`. Undo everything since: `git restore .`, and `git clean -n` to see untracked files the agent created (`git clean -f` deletes them).
*Both agents:* the same. Neither agent's own undo replaces git.

**7. Least privilege.**
*Why:* anything the agent can read is sent to the vendor, and anything it can write it may overwrite.
*Do:* stay in the default mode where it asks before running commands or leaving the repo. Never run with full access from your home directory. No IRB-restricted data, no credentials in its reach.
*Codex:* `codex` starts in the default mode (workspace-write, network off); switch with `/permissions`. Do not use `--dangerously-bypass-approvals-and-sandbox`.
*Claude Code:* `claude --permission-mode default` shows every approval; the start mode on some plans is `auto`, so check the mode shown at the bottom.

**8. Know when to reset.**
*Why:* a confused agent that loops burns your credits and adds junk.
*Do:* if it fails the same way 2-3 times: `git restore .`, start a new session, and re-prompt with the missing context (file names, the exact error, what not to touch).
*Codex:* `/new`. *Claude Code:* `/clear`.

## Steering (2, 3, 4)

**2. Write a context file.**
*Why:* the agent starts every session knowing nothing about your project.
*Do:* keep conventions, commands and hard rules in `AGENTS.md` (Codex reads it; `CLAUDE.md` contains `@AGENTS.md`, so Claude Code reads the same file). Example rule: "Never modify anything in data/raw/."
*Careful:* `/init` generates or rewrites such a file. Here it already exists, so edit it by hand.

**3. Plan before code.**
*Why:* a wrong plan costs a sentence to fix; wrong code costs a review.
*Do:* *"Read AGENTS.md, the PAP, and code/03_clean_ucdp.R. Give a short plan to complete only the TODOs in 03_clean_ucdp.R, including the checks you'll run. Don't edit files yet."* Correct the plan, then say "implement the plan".
*Claude Code:* `Shift+Tab` into plan mode does this mechanically. *Codex:* ask in the prompt, as above.

**4. Small, scoped tasks.**
*Why:* a one-file change is a diff you can read; a 10-file change is not.
*Do:* name the files to read, the one file to change, what not to touch, and what to report back. One task, then commit; new session when the topic changes.

## Owning the output (5, 6)

**5. Read every diff.**
*Why:* you are the author of every line in your replication package.
*Do:* `git diff` before you commit. If you cannot explain a line, ask the agent to explain it or delete it.
*Both:* `git diff`; Codex also has `/diff`.

**6. Verify with independent checks.**
*Why:* agents fail silently: they drop unmatched rows and turn missing into 0, and report success.
*Do:* ask *"How many conflict-years had several countries in gwno_loc, and how did you handle them? Which countries failed to match in countrycode?"* Then check yourself: `nrow()`, `anti_join()`, `stopifnot()`, and `Rscript run_all.R`.

## Integrity (9, 10)

**9. Agents p-hack eagerly.**
*Why:* running 200 specifications costs them a minute; if you ask for significance, they will find some.
*Do:* the pre-analysis plan defines the confirmatory model. Report it whatever the result. Everything else goes in the paper under "Exploratory analyses", labeled as such. Never ask an agent to "make it significant".

**10. Disclose AI use.**
*Why:* journals and departments increasingly require it, and readers should know who wrote the code.
*Do:* follow the journal and department policy; a line in the README or the paper's reproducibility statement (which agent, for which files) is a good default.

## How the six rules in `AGENTS.md` map to the practices

| `AGENTS.md` rule | Practice |
|---|---|
| 1. Work only inside this repository; never modify `data/raw/` | 1 (git repo as safety net), 7 (least privilege) |
| 2. Use `here::here()`, never `setwd()` or absolute paths | 2 (context file: conventions) |
| 3. State a plan and the files you will change before editing | 3 (plan before code) |
| 4. Smallest change that solves the named task; never edit the PAP | 4 (small tasks), 9 (the PAP is the confirmatory anchor) |
| 5. Run `Rscript run_all.R` after edits; report failures honestly | 6 (verify), 5 (you read the result) |
| 6. No installs, network, credentials or files outside the repo without permission | 7 (least privilege) |
