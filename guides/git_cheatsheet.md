# Git and terminal cheat sheet

## 1. Terminal survival kit
Open it in RStudio: **Tools > Terminal > New Terminal** (or the *Terminal* tab next to *Console*; shortcut Alt+Shift+R on Windows/Linux, Option+Shift+R on Mac [UNVERIFIED]). On Windows it should be *Git Bash* (Tools > Global Options > Terminal > New terminals open with: Git Bash).

| Command / key | Does |
|---|---|
| `pwd` | print the folder you are in |
| `ls` | list files here (`ls -la` shows hidden ones too) |
| `cd folder` | go into `folder` |
| `cd ..` | go up one folder |
| `cd ~` | go to your home folder |
| Tab | complete a file or folder name |
| Up arrow | previous command |
| Ctrl-C | stop whatever is running |

Pasting into Git Bash on Windows: right-click, or Shift+Insert (Ctrl+V may not work in a stand-alone Git Bash window; test in RStudio's Terminal tab) [UNVERIFIED, test on Windows].

## 2. The loop used today
```bash
git status                       # what changed?
git diff                         # what exactly changed?
git add file1 file2              # stage what you want in the next commit (or: git add .)
git commit -m "Short message"    # save a checkpoint
git push                         # send it to GitHub

git log --oneline                # history, one line per commit
git tag pap-v1                   # name this commit
git push --tags                  # send tags to GitHub
git clone https://github.com/<you>/<repo>.git    # copy a repo to your machine
```

## 3. Undo recipes
| I want to... | Command |
|---|---|
| discard my changes to one file | `git restore path/to/file` |
| undo everything since the last commit | `git restore .`, then `git clean -n` (preview) and `git clean -f` to delete untracked files |
| unstage a file (keep the edits) | `git restore --staged path/to/file` |
| fix the last commit message (not yet pushed) | `git commit --amend -m "New message"` |
| undo an old commit by adding a new one | `git revert <hash>` (find `<hash>` with `git log --oneline`) |

`git restore` and `git clean -f` cannot be undone. Commit before you let an agent work.

## 4. Branches and checkpoints
A branch is a named line of history. Our repo has checkpoint branches you can jump to if you fall behind:
```bash
git switch cp2-clean-data        # (cp1-pap, cp2-clean-data, cp3-paper, solution)
```
This replaces your working files with that checkpoint's. Commit or `git restore .` first.

**No checkpoint branches in your copy?** You forgot to tick "Include all branches" when using the template. Fix:
```bash
git remote add upstream https://github.com/hbarnehl/repro-bootcamp.git
git fetch upstream
git switch -c cp2-clean-data upstream/cp2-clean-data
```

## 5. GitHub vocabulary
| Term | Meaning |
|---|---|
| repository (repo) | a project folder plus its full history |
| commit | a saved snapshot with a message |
| remote | the copy of the repo on GitHub (usually called `origin`) |
| clone | copy a remote repo to your machine |
| push / pull | send your commits to / get new commits from the remote |
| branch | a named line of history (`main` is the default) |
| template vs. fork | a template gives you a fresh copy with no link to the original; a fork stays linked |
| issue | a note on a repo: bug report, question, to-do |
| pull request | a proposal to merge one branch into another, with review |
