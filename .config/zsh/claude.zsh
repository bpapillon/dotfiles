# Claude Code helpers — sourced from ~/.zshrc
#
# Note: order matters. The `evilclaude` alias must be defined before `cw`,
# since zsh expands aliases in a function body at parse time.

alias evilclaude="claude --dangerously-skip-permissions"

# kcunlock — unlock the login keychain. SSH sessions get a separate security
# session where the keychain is locked, so Claude Code can't read its
# credentials and thinks you're logged out. Run this (it prompts for your
# macOS account password) before starting claude over SSH.
alias kcunlock="security unlock-keychain ~/Library/Keychains/login.keychain-db"

# _cw_cwds — print the current working directory of every running process.
_cw_cwds() { lsof -d cwd -Fn 2>/dev/null | sed -n 's/^n//p'; }

# _cw_in_use <dir> [cwd-list]  — true if any process has its cwd at or under
# <dir> (an active claude session, a shell you're sitting in, an editor, etc.).
# Boundary-safe: a process in sibling "<dir>-foo" does not count.
_cw_in_use() {
  local dir="$1" cwd list="${2:-$(_cw_cwds)}"
  while IFS= read -r cwd; do
    [ "$cwd" = "$dir" ] && return 0
    case "$cwd" in "$dir"/*) return 0 ;; esac
  done <<< "$list"
  return 1
}

# Sweep lock. Concurrent agents both reach for cwclean, and two sweeps racing
# corrupt each other's view: whoever loses `git worktree remove` reports "kept
# (uncommitted changes)" for a worktree that was simply already gone, and
# `go clean -cache` collides with itself. Waiting costs nothing — the second run
# finds the work already done. flock lives on the fd, so the kernel releases it
# if a run is killed; there is no stale lock to clean up.
#
# Fixed path, not $TMPDIR: agents can be launched with different TMPDIRs and
# must contend on one file. CW_LOCK_WAIT caps the wait (default 15m).
_CW_LOCK="$HOME/.cache/cwclean.lock"

# _cw_lock — block until the sweep lock is ours. Callers guard on $_CW_LOCK_FD
# first (see cwsweep/cwclean): flock is per-fd, so re-locking in a shell that
# already holds it would deadlock against itself.
_cw_lock() {
  zmodload zsh/system 2>/dev/null || {
    echo "cw: zsh/system unavailable — sweeping without a lock" >&2
    return 0
  }
  # flock opens the file, it never creates it — make sure one exists first, and
  # keep creation failures separate from contention so the wait below only ever
  # means "someone else is sweeping".
  mkdir -p "${_CW_LOCK:h}" && : >>"$_CW_LOCK" || {
    echo "cw: cannot create $_CW_LOCK — sweeping without a lock" >&2
    return 0
  }
  zsystem flock -t 0 -f _CW_LOCK_FD "$_CW_LOCK" 2>/dev/null && return 0

  local t0=$SECONDS
  echo "cw: another sweep is running — waiting for it to finish..."
  zsystem flock -t "${CW_LOCK_WAIT:-900}" -f _CW_LOCK_FD "$_CW_LOCK" || {
    echo "cw: gave up after ${CW_LOCK_WAIT:-900}s waiting on $_CW_LOCK" >&2
    return 1
  }
  echo "cw: lock acquired after $((SECONDS - t0))s"
}

_cw_unlock() {
  [[ -n $_CW_LOCK_FD ]] || return 0
  zsystem flock -u "$_CW_LOCK_FD" 2>/dev/null
  unset _CW_LOCK_FD
}

# _cw_copy_includes <main_wt> <dest>  — copy gitignored files listed in
# <main_wt>/.worktreeinclude into <dest>, mirroring `claude --worktree`.
# Replicates the rule from code.claude.com/docs/en/worktrees: a file is copied
# only if it matches a .worktreeinclude pattern AND is gitignored, so tracked
# files are never duplicated. ls-files --others handles the "untracked" half;
# check-ignore enforces the "also gitignored" half. NUL-delimited for safety.
_cw_copy_includes() {
  local main_wt="$1" dest="$2" inc="$1/.worktreeinclude"
  [ -f "$inc" ] || return 0
  local f d n=0
  while IFS= read -r -d '' f; do
    git -C "$main_wt" check-ignore -q -- "$f" || continue
    d="$(dirname -- "$f")"
    mkdir -p "$dest/$d" && cp -p "$main_wt/$f" "$dest/$f" && n=$((n + 1))
  done < <(git -C "$main_wt" ls-files -z --others --ignored --exclude-from="$inc")
  [ "$n" -gt 0 ] && echo "cw: copied $n gitignored file(s) per .worktreeinclude"
}

# cw <branch> [base]  — open a branch in a worktree, clean up on exit when clean.
#   existing local branch  → check it out
#   branch only on origin   → fetch + create a local tracking branch
#   branch doesn't exist    → create it from [base] (default: origin's default branch)
#   CW_KEEP=1 cw <branch>   → skip cleanup (long-lived worktrees)
# git worktree remove never deletes the branch and refuses on a dirty tree, so
# cleanup is risk-free: committed work lives in the branch, WIP keeps the worktree.
cw() {
  local branch="$1" base="$2"
  [ -z "$branch" ] && { echo "usage: cw <branch> [base]" >&2; return 1; }

  local main_wt
  main_wt="$(git worktree list --porcelain | sed -n '1s/^worktree //p')" || return 1
  local dir="$main_wt/.claude/worktrees/${branch//\//-}"

  if [ ! -d "$dir" ]; then
    git fetch --quiet origin || return 1
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      git worktree add "$dir" "$branch" || return 1
    elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
      git worktree add --track -b "$branch" "$dir" "origin/$branch" || return 1
    else
      local start="${base:-$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)}"
      git worktree add -b "$branch" "$dir" "$start" || return 1
    fi
    _cw_copy_includes "$main_wt" "$dir"
  fi

  cd "$dir" || return 1
  evilclaude

  [ -n "$CW_KEEP" ] && return
  cd "$main_wt" || return
  if _cw_in_use "$dir"; then
    echo "cw: kept worktree — another session or shell is using it."
  elif git worktree remove "$dir" 2>/dev/null; then
    echo "cw: removed clean worktree (branch '$branch' preserved)"
  else
    cd "$dir"
    echo "cw: kept worktree — uncommitted changes; you're back in it."
    echo "    'git worktree remove --force $dir' to discard."
  fi
}

# cwsweep — remove clean, idle worktrees under .claude/worktrees/. Keeps any
# with uncommitted changes or an active session/shell (a process cwd inside it).
# Serialized against other sweeps; a no-op when cwclean already holds the lock.
cwsweep() {
  emulate -L zsh
  if [[ -z $_CW_LOCK_FD ]]; then
    _cw_lock || return 1
    trap '_cw_unlock' EXIT
  fi

  local main_wt cwds
  main_wt="$(git worktree list --porcelain | sed -n '1s/^worktree //p')" || return 1
  cwds="$(_cw_cwds)"   # snapshot once, reuse for every worktree
  git worktree list --porcelain | sed -n 's/^worktree //p' | while read -r wt; do
    case "$wt" in
      "$main_wt/.claude/worktrees/"*)
        if _cw_in_use "$wt" "$cwds"; then
          echo "in use   $wt"
        elif git worktree remove "$wt" 2>/dev/null; then
          echo "removed  $wt"
        else
          echo "kept     $wt (uncommitted changes)"
        fi ;;
    esac
  done
  git worktree prune   # drop admin entries for dirs deleted by hand
}

# cwclean [--docker]  — free disk when it's full (Claude sessions dying, Docker
# crashing, "no space left on device"). Composes the safe, rebuildable wins:
#   1. cwsweep (if inside a git repo) — remove clean, idle worktrees
#   2. orphaned dirs under .claude/worktrees — leftovers from pruned or
#      interrupted removals that `git worktree list` no longer knows about.
#      Deleted only if idle AND missing a .git file (nothing recoverable);
#      unregistered dirs that still have a .git file are reported, not deleted.
#   3. build caches: go build/test cache, Yarn, goimports, gopls — all
#      regenerate on next use. GOMODCACHE is kept (cheap to keep, slow to refill).
#   --docker  also `docker system prune -f` (stopped containers, dangling
#      images, build cache — never volumes, so dev DBs are safe).
# Never touches: OrbStack/docker volumes, GOMODCACHE, dirty or in-use worktrees.
# Holds the sweep lock for the whole run — a concurrent cwclean waits its turn
# rather than racing this one's worktree removals and cache deletes.
cwclean() {
  emulate -L zsh
  local dockerprune=0 a
  for a in "$@"; do [[ $a == --docker ]] && dockerprune=1; done

  if [[ -z $_CW_LOCK_FD ]]; then
    _cw_lock || return 1
    trap '_cw_unlock' EXIT
  fi

  echo "before: $(df -h / | tail -1 | awk '{print $4}') free"

  if git rev-parse --git-dir >/dev/null 2>&1; then
    cwsweep
    local main_wt cwds d
    main_wt="$(git worktree list --porcelain | sed -n '1s/^worktree //p')"
    cwds="$(_cw_cwds)"
    for d in "$main_wt/.claude/worktrees"/*(N/); do
      git worktree list --porcelain | grep -qxF "worktree $d" && continue
      if _cw_in_use "$d" "$cwds"; then
        echo "in use   $d (orphaned dir, kept)"
      elif [ -e "$d/.git" ]; then
        echo "kept     $d (orphaned dir with .git — inspect by hand)"
      else
        rm -rf "$d" && echo "removed  $d (orphaned dir)"
      fi
    done
  else
    echo "cwclean: not in a git repo — skipping worktree sweep"
  fi

  command -v go >/dev/null && go clean -cache -testcache 2>/dev/null
  rm -rf ~/Library/Caches/Yarn ~/Library/Caches/goimports ~/Library/Caches/gopls
  (( dockerprune )) && docker system prune -f

  echo "after:  $(df -h / | tail -1 | awk '{print $4}') free"
}

# sbclaude <vm-or-slug> [claude args...]  — start a Claude Code session inside an
# exe.dev sandbox VM via run-claude.sh (loads the API key + MCP tokens, cds into
# the api repo). Accepts the slug ("smoke") or full name ("sb-smoke").
#   sbclaude smoke                 → interactive session in sb-smoke
#   sbclaude smoke -p "do a thing" → headless one-shot (args pass through, quoted)
# -t gives Claude the interactive TTY it needs.
sbclaude() {
  emulate -L zsh
  local name="${1:?usage: sbclaude <vm-or-slug> [claude args...]}"; shift
  local vm="sb-${name#sb-}"   # accept "smoke" or "sb-smoke"
  ssh -t "${vm}.exe.xyz" "~/schematic-sandbox/exe/run-claude.sh ${(j: :)${(q)@}}"
}

# Location of the schematic-sandbox checkout (holds exe/new-task.sh). Override
# via $SCHEMATIC_SANDBOX if you keep it elsewhere.
: ${SCHEMATIC_SANDBOX:=$HOME/projects/schematic/schematic-sandbox}

# sbnew <slug> [description]  — clone the golden base into a fresh task VM
# (sb-<slug>): branch, start the native stack, expose HTTPS. Runs from anywhere.
#   sbnew sch-6549 "fix the thing"
sbnew() {
  emulate -L zsh
  : "${1:?usage: sbnew <slug> [description]}"
  "$SCHEMATIC_SANDBOX/exe/new-task.sh" "$@"
}

# sbgo <slug> [description]  — spin up a fresh task VM AND drop into Claude in it.
#   sbgo sch-6549 "fix the thing"
sbgo() {
  emulate -L zsh
  local slug="${1:?usage: sbgo <slug> [description]}"
  sbnew "$@" || return
  sbclaude "$slug"
}

# sbpause <slug> [--hard]  — quiesce a task VM to free the exe.dev memory pool
# while keeping ALL disk state (restored DB in the docker volume, repo, branch,
# built binary). exe.dev has no native pause verb; for our VMs the thing eating
# the 16GB concurrency cap is the running stack, so "pause" = stop it.
#   default  stop the stack (mprocs tmux 'sch' + datastores) → VM idles, releases
#            its working RAM. Resume is a warm ~30s restart.
#   --hard   ALSO resize the VM to 1cpu/1GB and power-cycle it, guaranteeing it's
#            off the concurrency cap. Heavier: sbresume must resize back up.
# Disk persists either way — never destructive (that's `ssh exe.dev rm`).
sbpause() {
  emulate -L zsh
  local hard=0 args=() a
  for a in "$@"; do [[ $a == --hard ]] && hard=1 || args+=("$a"); done
  local name="${args[1]:?usage: sbpause <slug> [--hard]}"
  local vm="sb-${name#sb-}"   # accept "smoke" or "sb-smoke"
  ssh "${vm}.exe.xyz" '~/schematic-sandbox/exe/pause-task.sh' || return
  if (( hard )); then
    echo "==> hard pause: resize $vm -> 1cpu/1GB + power-cycle"
    ssh exe.dev resize "$vm" --cpu=1 --memory=1 || return
    ssh exe.dev restart "$vm"
  fi
}

# sbresume <slug> [--hard]  — bring a paused task VM back up (warm; ~30s to API
# health). Mirror of sbpause:
#   default  just restart the stack.
#   --hard   first resize the VM back to 4cpu/8GB and power-cycle it, wait for
#            SSH, then start the stack. Use this only if you paused with --hard.
sbresume() {
  emulate -L zsh
  local hard=0 args=() a
  for a in "$@"; do [[ $a == --hard ]] && hard=1 || args+=("$a"); done
  local name="${args[1]:?usage: sbresume <slug> [--hard]}"
  local vm="sb-${name#sb-}"
  if (( hard )); then
    echo "==> hard resume: resize $vm -> 4cpu/8GB + power-cycle"
    ssh exe.dev resize "$vm" --cpu=4 --memory=8 || return
    ssh exe.dev restart "$vm" || return
    echo "==> waiting for SSH to come back..."
    local i
    for i in {1..60}; do
      ssh -o ConnectTimeout=5 -o BatchMode=yes "${vm}.exe.xyz" true 2>/dev/null && break
      sleep 2
    done
  fi
  ssh "${vm}.exe.xyz" '~/schematic-sandbox/exe/resume-task.sh'
}
