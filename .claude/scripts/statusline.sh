#!/usr/bin/env bash
# Custom Claude Code status line — adds a line ABOVE the default.
# Shows: branch · worktree (if any)
# (Default line below already shows vim mode, bypass-permissions hint, PR)
#
# Reads JSON from stdin per https://code.claude.com/docs/en/statusline.md

set -uo pipefail

input=$(cat)

cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // ""')
wt_name=$(printf '%s' "$input" | jq -r '.worktree.name // ""')

# Branch: ask git directly so we reflect the *current* branch, not the one
# the worktree was originally created with (worktree.branch in the JSON is stale
# after you switch branches inside the worktree).
branch=""
if [[ -n "$cwd" ]]; then
  branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
fi

# ANSI colors
RESET=$'\e[0m'
DIM=$'\e[2m'
CYAN=$'\e[36m'
GREEN=$'\e[32m'

parts=()

if [[ -n "$branch" ]]; then
  parts+=("${CYAN}${branch}${RESET}")
fi

if [[ -n "$wt_name" ]]; then
  parts+=("${DIM}wt:${RESET}${GREEN}${wt_name}${RESET}")
fi

sep=" ${DIM}·${RESET} "
out=""
for i in "${!parts[@]}"; do
  if [[ $i -gt 0 ]]; then
    out+="$sep"
  fi
  out+="${parts[$i]}"
done

printf '%s' "$out"
