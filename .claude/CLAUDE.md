## Git

Always use the `git` skill when using git (cloning, committing, opening PRs, pushing, reviewing, etc).

## Writing

Strive to be concise and direct in writing, especially when said writing will be shared with another person (a message or ticket). Keep in mind Orwell's rules for writing:
* Never use a metaphor, simile, or other figure of speech which you are used to seeing in print.
* Never use a long word where a short one will do.
* If it is possible to cut a word out, always cut it out.
* Never use the passive where you can use the active.
* Never use a foreign phrase, a scientific word, or a jargon word if you can think of an everyday English equivalent.
* Break any of these rules sooner than say anything outright barbarous.

## Disk pressure

If the disk fills up (symptoms: "no space left on device", Docker/OrbStack dying mid-run, postgres containers vanishing, builds failing with cache write errors):

1. Run `zsh -ic 'cwclean'` — my cleanup function in `~/.config/zsh/claude.zsh` (zsh -ic because it's loaded from .zshrc). It sweeps clean/idle Claude worktrees plus orphaned worktree dirs, and clears the go build/test, Yarn, goimports, and gopls caches (all safely rebuildable). Add `--docker` to also prune stopped containers/dangling images (never volumes).
   - `cwclean` self-serializes with a lockfile. `cw: another sweep is running — waiting for it to finish...` means another agent holds it — that's expected, not a hang. Let it wait (up to 15m, `CW_LOCK_WAIT` to change); by the time it acquires, most of the work is already done. Never work around it by running the sweep steps by hand.
2. If more is needed, find the hogs with `du -sh ~/Library/Caches/* | sort -rh | head` and `du -sh <repo>/.claude/worktrees/*`.
3. Do NOT delete without asking: OrbStack data / docker volumes (dev databases live there), GOMODCACHE, or any worktree with uncommitted changes or unpushed commits — audit with `git -C <wt> status --porcelain` and `git log origin/main..HEAD` first.
4. Removing a registered worktree never deletes its branch; committed work survives. Orphaned dirs (present on disk, absent from `git worktree list`) have no git safety net — check contents before removal.

