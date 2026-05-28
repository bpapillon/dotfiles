# Claude Code helpers — sourced from ~/.zshrc
#
# Note: order matters. The `evilclaude` alias must be defined before `cw`,
# since zsh expands aliases in a function body at parse time.

alias evilclaude="claude --dangerously-skip-permissions"

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
cwsweep() {
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
