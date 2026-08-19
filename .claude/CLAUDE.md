## Git

Always use the `git` skill when using git (cloning, committing, opening PRs, pushing, reviewing, etc).

## Response length

Keep responses focused, brief, and concise. Keep disclaimers and caveats short, and spend most of the response on the main answer. When asked to explain something, give a high-level summary unless an in-depth explanation is specifically requested.

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

1. Run `zsh -ic 'cwclean'`, which will clean up unused worktrees, caches, etc.
2. If more is needed, find the hogs with `du -sh ~/Library/Caches/* | sort -rh | head` and `du -sh <repo>/.claude/worktrees/*`.
3. Do NOT delete without asking: OrbStack data / docker volumes (dev databases live there), GOMODCACHE, or any worktree with uncommitted changes or unpushed commits — audit with `git -C <wt> status --porcelain` and `git log origin/main..HEAD` first.
4. Removing a registered worktree never deletes its branch; committed work survives. Orphaned dirs (present on disk, absent from `git worktree list`) have no git safety net — check contents before removal.
