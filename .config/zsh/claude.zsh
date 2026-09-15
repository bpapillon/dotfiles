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

# _cw_size <path> — size of <path> in KB. Costs a `du` walk (~3s on a worktree
# with node_modules in it), which is worth paying: the cheap alternative, a df
# reading either side of the delete, reports whatever else touched the disk in
# between — a concurrent `go test` had it claiming 517M for a 120M tree.
_cw_size() { du -sk "$1" 2>/dev/null | awk '{print $1}'; }

# _cw_human <kb> — KB as a short human string, or "?" when the reading failed
# rather than a confident-looking 0.
_cw_human() {
  [ -n "$1" ] || { print -n "?"; return; }
  awk -v k="$1" 'BEGIN {
    if (k < 0) k = 0
    u = "KMGT"; i = 1
    while (k >= 1024 && i < 4) { k /= 1024; i++ }
    printf "%.1f%s", k, substr(u, i, 1)
  }'
}

# _cw_reap_gobuild — delete orphaned `go test` work dirs. `go test` builds every
# test binary into one $TMPDIR/go-build* dir and deletes it only on a normal
# exit. A run killed mid-way (Bash tool timeout, Ctrl-C on the wrong shell)
# leaves 10-15G behind, and macOS sweeps $TMPDIR only on reboot or after 3 idle
# days. Unlike the build cache these are pure garbage — nothing reads them
# again — so reaping them is free.
#
# Age plus argv, not lsof, decides what is live. `lsof +D` reports nothing for a
# work dir that a running `go test` is compiling into right now (reproduced with
# a dozen `compile -o .../go-buildN/...` processes running), so the guard this
# replaces would delete an in-flight run's tree out from under it. Two signals
# that do hold: go stamps the dir every time it mints a b#### subdir, and every
# compile, link and test-binary process carries the dir's name in its argv.
_cw_reap_gobuild() {
  local age="${CW_GOBUILD_AGE:-60}" tmp="${${TMPDIR:-/tmp}%/}" gb
  while IFS= read -r gb; do
    [ -n "$gb" ] || continue
    pgrep -f "${gb:t}" >/dev/null 2>&1 && continue
    rm -rf "$gb" && echo "removed  $gb (orphaned go work dir, idle ${age}m+)"
  done < <(find "$tmp" -maxdepth 1 -type d -name 'go-build*' -mmin +"$age" 2>/dev/null)
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

# _cw_sync — bring the current branch up to date with its upstream before
# handing the worktree to a session (replaces running `g rsr` by hand).
# Hard-resets only when nothing local can be lost:
#   dirty tracked files                  → skip
#   local commit with no upstream patch  → skip (unpushed work)
#   rebased/force-pushed PR branch       → reset (git cherry sees every local
#                                          commit as patch-equivalent upstream)
_cw_sync() {
  git fetch --quiet origin || { echo "cw: fetch failed — using local state" >&2; return 0; }
  git rev-parse --verify --quiet '@{u}' >/dev/null || return 0
  [ "$(git rev-parse HEAD)" = "$(git rev-parse '@{u}')" ] && return 0
  if [ -n "$(git status --porcelain -uno)" ]; then
    echo "cw: branch differs from upstream but tree is dirty — not syncing (g rsr to force)"
  elif git cherry 2>/dev/null | grep -q '^+'; then
    echo "cw: local-only commit(s) not on upstream — not syncing (g rsr to force)"
  else
    git reset --hard --quiet '@{u}' && echo "cw: synced to $(git rev-parse --abbrev-ref '@{u}')"
  fi
}

# cw <branch> [base] [-- claude args...]  — open a branch in a worktree, clean
# up on exit when clean.
#   existing local branch  → check it out
#   branch only on origin   → fetch + create a local tracking branch
#   branch doesn't exist    → create it from [base] (default: origin's default branch)
#   CW_KEEP=1 cw <branch>   → skip cleanup (long-lived worktrees)
#   cw foo -- "/pr-review"  → pass args to claude (e.g. start it on a skill)
# The branch is synced to upstream before claude starts (see _cw_sync).
# git worktree remove never deletes the branch and refuses on a dirty tree, so
# cleanup is risk-free: committed work lives in the branch, WIP keeps the worktree.
cw() {
  local branch="" base="" cargs=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --) shift; cargs=("$@"); break ;;
      *)
        if [ -z "$branch" ]; then branch="$1"
        elif [ -z "$base" ]; then base="$1"
        else echo "usage: cw <branch> [base] [-- claude args...]" >&2; return 1
        fi
        shift ;;
    esac
  done
  [ -z "$branch" ] && { echo "usage: cw <branch> [base] [-- claude args...]" >&2; return 1; }

  local main_wt
  main_wt="$(git worktree list --porcelain | sed -n '1s/^worktree //p')" || return 1
  local dir="$main_wt/.claude/worktrees/${branch//\//-}"
  # A branch can only be checked out once; if some worktree already has it
  # (e.g. an agent-* dir from Claude Code worktree isolation), use that one.
  local existing
  existing="$(git worktree list --porcelain | awk -v b="refs/heads/$branch" '/^worktree /{w=substr($0,10)} $0=="branch "b{print w; exit}')"
  [ -n "$existing" ] && dir="$existing"

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
  _cw_sync
  evilclaude "${cargs[@]}"

  [ -n "$CW_KEEP" ] && return
  cd "$main_wt" || return
  cwdone "$dir"
  # 2 means the tree was dirty and the worktree survives — put you back in it.
  [ $? -eq 2 ] && cd "$dir"
}

# cwdone [-f] [branch|dir]  — tear down one worktree you are finished with,
# instead of waiting for the disk to fill and reaching for cwclean.
#   cwdone             → the worktree you are standing in
#   cwdone <branch>    → the worktree holding that branch
#   cwdone <dir>       → that worktree, by path or by name under .claude/worktrees
#   cwdone -f ...      → discard uncommitted changes too
# Reclaims what actually dies with the worktree: its node_modules (1-2G of the
# ~1.7G a checked-out worktree costs here) plus the orphaned go work dirs in
# $TMPDIR. It deliberately does NOT run `go clean -cache`: the build cache is
# global and shared, so dropping it to retire one branch just makes the next
# build slow in every other worktree. That trade belongs to cwclean, which you
# run when the disk is genuinely full.
# The branch always survives — git worktree remove never deletes it — so the
# only thing at risk is uncommitted work, and that is what -f gates.
cwdone() {
  emulate -L zsh
  local force=0 target=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -f|--force) force=1; shift ;;
      -*) echo "usage: cwdone [-f] [branch|dir]" >&2; return 1 ;;
      *) target="$1"; shift ;;
    esac
  done

  local main_wt
  main_wt="$(git worktree list --porcelain | sed -n '1s/^worktree //p')" || return 1
  main_wt="${main_wt:A}"

  # Resolve target → directory. A bare name can be a branch, a directory under
  # .claude/worktrees, or both; check the branch first since that is what you
  # name when you think in terms of the work rather than the checkout.
  local dir=""
  if [ -z "$target" ]; then
    dir="$(git rev-parse --show-toplevel 2>/dev/null)"
  else
    dir="$(git worktree list --porcelain |
      awk -v b="refs/heads/$target" '/^worktree /{w=substr($0,10)} $0=="branch "b{print w; exit}')"
    [ -z "$dir" ] && [ -d "$main_wt/.claude/worktrees/${target//\//-}" ] &&
      dir="$main_wt/.claude/worktrees/${target//\//-}"
    [ -z "$dir" ] && [ -d "$target" ] && dir="$target"
  fi
  [ -n "$dir" ] || { echo "cwdone: no worktree matching '$target'" >&2; return 1; }
  dir="${dir:A}"

  # Only ever remove something git already tracks as a worktree. An unregistered
  # path that happens to look like one is a plain rm -rf with no safety net, and
  # that is cwclean's orphan pass, run under its own rules.
  local w registered=0
  while IFS= read -r w; do
    [ "${w:A}" = "$dir" ] && { registered=1; break; }
  done < <(git worktree list --porcelain | sed -n 's/^worktree //p')
  (( registered )) || { echo "cwdone: $dir is not a registered worktree" >&2; return 1; }
  [ "$dir" = "$main_wt" ] && { echo "cwdone: that is the main worktree" >&2; return 1; }

  # Step out before the in-use check, or your own shell counts as a user.
  case "$PWD" in "$dir"|"$dir"/*) cd "$main_wt" || return 1 ;; esac

  if [[ -z $_CW_LOCK_FD ]]; then
    _cw_lock || return 1
    trap '_cw_unlock' EXIT
  fi

  if _cw_in_use "$dir"; then
    echo "cwdone: kept $dir — another session or shell is using it."
    return 2
  fi

  local branch upstream ahead
  branch="$(git -C "$dir" symbolic-ref --quiet --short HEAD 2>/dev/null)"
  # Informational only: the branch outlives the worktree, so unpushed commits
  # are not lost here. Worth saying out loud because nothing else will say it.
  # Fall back to origin's default branch when there is no upstream — that is the
  # case where the commits exist nowhere but here, so it is the one worth naming,
  # and it is also the one `@{u}..HEAD` fails silently on.
  upstream="$(git -C "$dir" rev-parse --abbrev-ref --verify --quiet '@{u}' 2>/dev/null)"
  [ -z "$upstream" ] && upstream="$(git -C "$dir" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)"
  ahead="$(git -C "$dir" rev-list --count "$upstream..HEAD" 2>/dev/null)"
  [ "${ahead:-0}" -gt 0 ] &&
    echo "cwdone: '$branch' is $ahead commit(s) ahead of $upstream — kept on the branch."

  local size
  size="$(_cw_size "$dir")"
  if (( force )); then
    git worktree remove --force "$dir" || return 1
  elif ! git worktree remove "$dir" 2>/dev/null; then
    echo "cwdone: kept $dir — uncommitted changes. 'cwdone -f $target' to discard."
    return 2
  fi
  git worktree prune
  _cw_reap_gobuild
  echo "cwdone: removed $dir (branch '$branch' preserved) — $(_cw_human "$size") reclaimed"
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
#   3. build caches: go build/test cache, uv, Yarn, goimports, gopls — all
#      regenerate on next use. GOMODCACHE is kept (cheap to keep, slow to refill).
#      uv matters most here: a uvx-launched MCP server mints a fresh ~300MB
#      environment per launch, which is how ~/.cache/uv reached 361GB unnoticed.
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
  _cw_reap_gobuild
  # prune, not clean: it drops only unreachable entries, so tool installs and
  # project venvs keep the cache entries they hardlink against. `uv cache clean`
  # would force a full re-download of everything still in use.
  command -v uv >/dev/null && uv cache prune 2>/dev/null
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

# _claude_live — "pid<TAB>name<TAB>state<TAB>cwd<TAB>sessionId" for every running
# session. ~/.claude/sessions/<pid>.json is Claude Code's own index and carries
# the session name, so this beats reading cwd out of lsof: two sessions in the
# same repo are indistinguishable by cwd but never by name. Entries are
# cross-checked against pgrep because the json outlives the process it describes.
# _claude_pids — pids of every running `claude`, space-separated.
_claude_pids() {
  ps -Ao pid=,comm= | awk '{n=$2; sub(/.*\//, "", n); if (n == "claude") printf "%s ", $1}'
}

_claude_live() {
  emulate -L zsh
  # ps, not pgrep: BSD pgrep omits its own ancestors, so a `whichclaude` run
  # from inside a session would hide that very session — the worst possible miss.
  local live=" $(_claude_pids) "
  python3 - "$live" <<'PY'
import glob, json, os, sys
live = set(sys.argv[1].split())
for f in glob.glob(os.path.expanduser('~/.claude/sessions/*.json')):
    try:
        d = json.load(open(f))
    except Exception:
        continue
    pid = str(d.get('pid') or '')
    if pid not in live:
        continue
    print('\t'.join((pid, d.get('name') or '-', d.get('status') or '-',
                     d.get('cwd') or '-', d.get('sessionId') or '-')))
PY
}

# whichclaude [pid]  — answer "which session is that, and what is it doing?".
# Every Claude Code process shows up in ps and Activity Monitor as the same
# `claude` line, and cwd alone doesn't separate two sessions open on the same
# repo — the session name does.
#   whichclaude       → all sessions: pid, name, state, uptime, RSS, cwd
#   whichclaude 85944 → that session's name, state, cwd, and transcript path
whichclaude() {
  emulate -L zsh
  local rows; rows="$(_claude_live)"
  [[ -n $rows ]] || { echo "whichclaude: no claude sessions running" >&2; return 1; }

  local pid name state cwd sid etime rss
  if [[ -n $1 ]]; then
    local row; row="$(grep -m1 "^$1	" <<< "$rows")"
    [[ -n $row ]] || { echo "whichclaude: no live session with pid $1" >&2; return 1; }
    IFS=$'\t' read -r pid name state cwd sid <<< "$row"
    print -r -- "name:       $name"
    print -r -- "state:      $state"
    print -r -- "cwd:        $cwd"
    print -r -- "transcript: ~/.claude/projects/${${cwd//\//-}//./-}/$sid.jsonl"
    return
  fi

  # Sort by RSS before formatting — sorting the padded table would key on
  # column position rather than the number.
  {
    while IFS=$'\t' read -r pid name state cwd sid; do
      IFS=' ' read -r etime rss <<< "$(ps -o etime=,rss= -p "$pid" 2>/dev/null)"
      [[ -n $rss ]] && print -r -- "$rss	$pid	$name	$state	$etime	${cwd/#$HOME/~}"
    done <<< "$rows"
  } | sort -rn | {
    printf '%-7s %-34s %-7s %-13s %9s  %s\n' PID NAME STATE UPTIME RSS CWD
    while IFS=$'\t' read -r rss pid name state etime cwd; do
      printf '%-7s %-34s %-7s %-13s %6d MB  %s\n' \
        "$pid" "${name:0:34}" "$state" "$etime" "$((rss / 1024))" "$cwd"
    done
  }
}

# _claude_hogs_py — the analysis behind claudehogs, kept in one place and fed to
# python3 -c by each mode. Modes: table | worst | killlist <pid> | detail <pid>.
_claude_hogs_py() {
  cat <<'PY'
import collections, datetime, glob, json, os, subprocess, sys

mode = sys.argv[1]
target = int(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2] else 0
# Pid of the shell that invoked claudehogs. Run from inside a session, that
# shell is itself one of the session's Bash-tool children, so without this the
# sweep would kill the very command performing it.
self_pid = int(os.environ.get('CLAUDEHOGS_SELF') or 0)

def sh(*cmd, **kw):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=10, **kw).stdout
    except Exception:
        return ''

procs = {}
for line in sh('ps', '-Ao', 'pid=,ppid=,pgid=,rss=,etime=,command=').splitlines():
    f = line.split(None, 5)
    if len(f) < 6:
        continue
    procs[int(f[0])] = dict(ppid=int(f[1]), pgid=int(f[2]), rss=int(f[3]),
                            etime=f[4], cmd=f[5],
                            name=os.path.basename(f[5].split()[0]))

claudes = [p for p, d in procs.items() if d['name'] == 'claude']

# Attribute every process to its NEAREST claude ancestor, so a nested session
# owns its own subtree instead of inflating its parent's — and so a kill aimed
# at the parent can never reach into a child session's work.
# A session's children are two very different populations. The Bash tool runs
# each command under `zsh -c source .../shell-snapshots/snapshot-*`, and that is
# where build storms live. Everything else — gopls, MCP servers, hook runners —
# is long-lived infrastructure the session needs to keep working. Only the
# former is ever killed, so a sweep frees the memory without lobotomising the
# session it spares.
SNAP = 'shell-snapshots/snapshot'

kids = collections.defaultdict(list)
transient = set()
for pid in procs:
    if procs[pid]['name'] == 'claude':
        continue
    o, cur, seen, via_bash = 0, pid, set(), False
    while cur > 1 and cur not in seen and cur in procs:
        seen.add(cur)
        if procs[cur]['name'] == 'claude':
            o = cur
            break
        if SNAP in procs[cur]['cmd']:
            via_bash = True
        cur = procs[cur]['ppid']
    if o:
        kids[o].append(pid)
        if via_bash:
            transient.add(pid)

sessions = {}
for f in glob.glob(os.path.expanduser('~/.claude/sessions/*.json')):
    try:
        d = json.load(open(f))
        sessions[int(d['pid'])] = d
    except Exception:
        pass

def mb(kb):
    return kb / 1024.0

def subtree_kb(p):
    return sum(procs[k]['rss'] for k in kids[p])

# Spare our own ancestors AND our own process group: a pipeline like
# `claudehogs --kill | less` puts the pager in this group, and each Bash call
# gets its own group, so this never shields another session's runaway build.
mine = set()
cur, seen = self_pid, set()
while cur > 1 and cur not in seen and cur in procs:
    seen.add(cur)
    mine.add(cur)
    cur = procs[cur]['ppid']
my_pgid = procs.get(self_pid, {}).get('pgid')
if my_pgid:
    mine |= {p for p, d in procs.items() if d['pgid'] == my_pgid}

def killable(p):
    return [k for k in kids[p] if k in transient and k not in mine]

def killable_kb(p):
    return sum(procs[k]['rss'] for k in killable(p))

ranked = sorted(claudes, key=subtree_kb, reverse=True)

if mode == 'worst':
    # Rank on what a sweep can actually reclaim, not on total footprint.
    best = max(claudes, key=killable_kb, default=0)
    print(best if best and killable_kb(best) else '')
    sys.exit()

if mode == 'killlist':
    print(' '.join(str(k) for k in (kids[target] if os.environ.get('CLAUDEHOGS_ALL')
                                    else killable(target))))
    sys.exit()

if mode == 'table':
    print('%-7s %-30s %-7s %9s %10s %10s  %s' %
          ('PID', 'NAME', 'STATE', 'OWN', 'SPAWNED', 'KILLABLE', 'TOP CHILD'))
    for p in ranked:
        s = sessions.get(p, {})
        top = max(kids[p], key=lambda k: procs[k]['rss'], default=None)
        print('%-7s %-30s %-7s %6.0f MB %7.0f MB %7.0f MB  %s' % (
            p, (s.get('name') or '-')[:30], s.get('status') or '-',
            mb(procs[p]['rss']), mb(subtree_kb(p)), mb(killable_kb(p)),
            '%s (%.0f MB)' % (procs[top]['name'], mb(procs[top]['rss'])) if top else '-'))
    sys.exit()

# detail
if target not in procs or procs[target]['name'] != 'claude':
    sys.stderr.write('claudehogs: pid %d is not a running claude session\n' % target)
    sys.exit(1)
s = sessions.get(target, {})
cwd = s.get('cwd', '')
print('=' * 72)
print('pid %-8s %s' % (target, s.get('name') or '(unnamed)'))
print('  state    %s   up %s   own %.0f MB   spawned %.0f MB across %d proc(s)' % (
    s.get('status') or '?', procs[target]['etime'], mb(procs[target]['rss']),
    mb(subtree_kb(target)), len(kids[target])))
print('  cwd      %s' % (cwd or '?'))

if cwd and os.path.isdir(cwd):
    br = sh('git', '-C', cwd, 'branch', '--show-current').strip()
    dirty = [l for l in sh('git', '-C', cwd, 'status', '--porcelain').splitlines() if l]
    last = sh('git', '-C', cwd, 'log', '-1', '--format=%h %s').strip()
    print('  branch   %s (%d uncommitted file(s))' % (br or '?', len(dirty)))
    print('  head     %s' % last)

sid = s.get('sessionId')
if sid and cwd:
    slug = cwd.replace('/', '-').replace('.', '-')
    tp = os.path.expanduser('~/.claude/projects/%s/%s.jsonl' % (slug, sid))
    if os.path.exists(tp):
        rows = []
        for line in collections.deque(open(tp, errors='replace'), maxlen=3000):
            try:
                rows.append(json.loads(line))
            except Exception:
                pass

        def text(r):
            c = r.get('message', {}).get('content')
            if isinstance(c, str):
                return c
            if isinstance(c, list):
                return ' '.join(b.get('text', '') for b in c
                                if isinstance(b, dict) and b.get('type') == 'text')
            return ''

        users = [r for r in rows if r.get('type') == 'user' and not r.get('isMeta')
                 and text(r).strip() and not text(r).lstrip().startswith(('<', '[Request'))]
        asst = [r for r in rows if r.get('type') == 'assistant' and text(r).strip()]
        if users:
            print('\n  last ask [%s]' % users[-1].get('timestamp', '')[:19].replace('T', ' '))
            print('    %s' % text(users[-1]).strip()[:400].replace('\n', '\n    '))
        if asst:
            print('\n  last reply [%s]' % asst[-1].get('timestamp', '')[:19].replace('T', ' '))
            print('    %s' % text(asst[-1]).strip()[:400].replace('\n', '\n    '))

if kids[target]:
    print('\n  spawned processes  (* = killed by --kill; others are session infrastructure)')
    for k in sorted(kids[target], key=lambda k: procs[k]['rss'], reverse=True):
        print('  %s %-7s %-11s %6.0f MB  %s' % (
            '*' if (k in transient and k not in mine) else ' ', k, procs[k]['etime'],
            mb(procs[k]['rss']),
            ('[this shell] ' if k in mine else '') + procs[k]['cmd'][:88]))
print('=' * 72)
PY
}

# claudehogs [pid] [--kill] [--yes]  — find the session eating the machine, say
# what it was working on, and kill what it spawned.
#
# The session is never the hog: a `claude` process sits at 100-400MB while one
# `go vet ./...` under it forks a compile worker per core at ~500MB each. ps and
# Activity Monitor show those workers as anonymous toolchain processes with no
# hint of which session launched them, so this bills every process to its
# nearest `claude` ancestor and ranks by what each session spawned.
#   claudehogs             → every session, biggest spawn footprint first
#   claudehogs 7307        → what it's working on + what it spawned
#   claudehogs --kill      → same for the worst offender, then kill the spawn
#   claudehogs 7307 -k -y  → target a session, skip the confirmation
# Nothing named `claude` is ever signalled: the session survives, sees its Bash
# call fail, and can retry. Nested sessions own their own subtree, so a kill
# aimed at a parent never reaches a child session's work.
claudehogs() {
  emulate -L zsh
  local kill_mode=0 assume_yes=0 target= a
  for a in "$@"; do
    if [[ $a == (-k|--kill) ]]; then kill_mode=1
    elif [[ $a == (-y|--yes) ]]; then assume_yes=1
    elif [[ $a == <-> ]]; then target=$a
    else echo "usage: claudehogs [pid] [--kill] [--yes]" >&2; return 1
    fi
  done

  local py; py="$(_claude_hogs_py)"
  export CLAUDEHOGS_SELF=$$
  if (( ! kill_mode )); then
    if [[ -n $target ]]; then python3 -c "$py" detail "$target"
    else python3 -c "$py" table
    fi
    return
  fi

  [[ -n $target ]] || target="$(python3 -c "$py" worst)"
  [[ -n $target ]] || { echo "claudehogs: no session has spawned anything" >&2; return 1; }
  python3 -c "$py" detail "$target" || return 1

  local kids; kids="$(python3 -c "$py" killlist "$target")"
  [[ -n ${kids// } ]] || { echo "claudehogs: nothing to kill under $target"; return 0; }

  if (( ! assume_yes )) && [[ -o interactive ]]; then
    read -q "REPLY?kill ${#${=kids}} process(es) under $target, keeping the session? [y/N] " || { echo; return 1; }
    echo
  fi

  # Snapshot the subtree before signalling: a child orphaned by its parent's
  # death reparents to launchd and stops being attributable, so the SIGKILL
  # sweep has to work from this list rather than re-walking the tree.
  kill ${=kids} 2>/dev/null
  sleep 3
  local survivors; survivors="$(ps -o pid= -p ${(j:,:)${=kids}} 2>/dev/null)"
  if [[ -n ${survivors// } ]]; then
    echo "claudehogs: SIGKILL for ${#${=survivors}} survivor(s)"
    kill -9 ${=survivors} 2>/dev/null
  fi
  echo "claudehogs: session $target left running."
}
