Here is the essential command set, grouped by function:

### Setup & Config
-   `git config --global user.name "Your Name"` — Set commit author name
-   `git config --global user.email "you@example.com"` — Set commit author email
-   `git config --global core.editor "code --wait"` — Set default editor (VS Code example)
-   `git config --list` — View all current config

### Repository Initialization
-   `git init` — Create new local repo
-   `git clone <url>` — Clone remote repo to local machine
-   `git remote add origin <url>` — Link local repo to remote
-   `git remote -v` — List configured remotes

### Daily Workflow
-   `git status` — Show working tree state (staged, modified, untracked)
-   `git add <file>` / `git add .` — Stage specific file or all changes
-   `git commit -m "message"` — Commit staged changes with message
-   `git diff` — Show unstaged changes
-   `git diff --staged` — Show staged but uncommitted changes
-   `git log --oneline --graph` — Compact history with branch visualization

### Branching
-   `git branch` — List local branches
-   `git switch -c <branch>` — Create and switch to new branch
-   `git switch <branch>` — Switch to existing branch
-   `git merge <branch>` — Merge specified branch into current branch
-   `git rebase <branch>` — Reapply current branch commits onto target branch
-   `git branch -d <branch>` — Delete merged branch

### Remote Sync
-   `git fetch` — Download remote changes without merging
-   `git pull` — Fetch + merge remote changes
-   `git push` — Upload local commits to remote
-   `git push -u origin <branch>` — Push and set upstream tracking

### Undo & Recovery
-   `git restore <file>` — Discard uncommitted working directory changes
-   `git restore --staged <file>` — Unstage file (keep working dir changes)
-   `git revert <commit>` — Create new commit that undoes specified commit (safe)
-   `git reset --soft <commit>` — Move branch pointer, keep staging + working dir
-   `git reset --mixed <commit>` — Move branch pointer, clear staging, keep working dir (default)
-   `git reset --hard <commit>` — Move branch pointer, discard staging + working dir (**destructive**)
-   `git reflog` — Show all HEAD movements (recovery safety net)
-   `git stash` / `git stash pop` — Temporarily save/restore uncommitted work

### Inspection
-   `git show <commit>` — Display full commit content + diff
-   `git blame <file>` — Line-by-line authorship
-   `git tag -a v1.0 -m "message"` — Create annotated tag

This covers ~95% of daily Git operations. What do you want to drill into?