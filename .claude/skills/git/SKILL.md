---
name: git
description: Git workflow conventions — commits, branches, PRs, rebasing. Use whenever committing, branching, pushing, opening PRs, or rebasing.
allowed-tools: Read, Grep, Glob, Bash(git *), Bash(gh *), mcp__linear__get_issue, mcp__linear__list_issues
---

# Git Workflow Conventions

Follow these conventions for all git operations in this repo.

## Commits

### Message format

Use conventional-commit-style prefixes. The default is a bare description:

```
add webhook batching for large payloads
```

Use `chore(scope):` for non-functional changes like:
- test-only changes
- CI/workflow changes
- formatting / linting fixes
- dependency bumps
- documentation

```
chore(ci): pin actions/checkout to v4
chore(tests): add coverage for webhook retry logic
```

### Subject and body

- Subject: imperative mood, lowercase, no trailing period, ≤50 characters where possible.
- Most commits need no body. Add one only when the why isn't obvious from the diff — then explain why, not what, and wrap at 72 characters.

### Commit scope

Keep commits focused. One logical change per commit. Don't bundle unrelated fixes.

## Branches

### Naming

**From a Linear ticket:** use the branch name Linear provides. It follows the pattern:
```
{username}/{ticket-id}-{slug}
```
Example: `bpapillon/sch-5960-migrate-webhook_events-from-postgresql-to-clickhouse`

If the ticket ID is known but the Linear-provided branch name isn't available, fetch it via the Linear MCP (`get_issue`).

**From a Sentry issue (no Linear ticket):** use the Sentry short ID:
```
sentry-API-1FB
```

**From a Fencer vulnerability (no Linear ticket):** use the Fencer vuln ID:
```
fencer-VULN-HWS
```
If fixing multiple related Fencer vulns in one PR, use a descriptive name instead.

**Otherwise:** use a short, descriptive kebab-case name:
```
fix-stripe-invoice-sync
add-plan-entitlement-cache
```

**Worktree branches:** never push using the auto-generated worktree branch name. Always rename to a meaningful name before pushing:
```bash
git checkout -b <meaningful-name>
```

### One branch per ticket

Each Linear ticket gets its own branch and PR whenever possible.

## Pull Requests

When opening pull requests on behalf of a developer, open the PR a draft unless otherwise instructed, so that the developer can review the PR before others on the team.

### Description

Keep it minimal. The PR description exists so reviewers understand intent and approach — nothing more.

- State what the PR does and why, concisely.
- Don't add testing plans, checklists, emoji headers, or filler sections.
- Don't write the commit message summary — let the dev write their own unless it's a simple `fixes {url}`.
- If the PR fixes a Sentry issue, the **first line** of the body must be `fixes {sentry-url}`. This auto-resolves the issue on merge.
- If the PR fixes a Fencer vulnerability, the **first line** of the body must be `fixes {fencer-url}`. For multiple related Fencer vulns, list one `fixes {fencer-url}` per line at the top of the body.
- Linear ticket links are handled automatically by the Linear integration when the branch name matches — no need to add them manually.

### Example (Sentry fix)

```
fixes https://sentry.io/organizations/schematic/issues/API-1FB/

Null pointer on webhook event when the linked company has been deleted.
Guard the dereference and skip processing if the company is gone.
```

### Example (feature work)

```
Add batched webhook delivery for high-volume accounts.

Events are buffered per-endpoint and flushed every 5s or at 100 events,
whichever comes first. Adds a new `webhook_batches` table and a flush
goroutine in the event processor.
```

## Rebase & Merge

### Before branching

Always pull main before creating a new branch:
```bash
git checkout main && git pull
```

### Keeping branches current

Rebase feature branches onto main regularly. Don't let them drift:
```bash
git fetch origin && git rebase origin/main
```

Prefer rebase over merge to keep history linear.

### Conflicts

Resolve conflicts during rebase rather than creating merge commits. If conflicts are complex, ask the dev before making judgment calls about which side to keep.

## Code Review and Comments

When asked to approve a PR, do it with no comments, unless expressly asked to leave comments.

Never leave any GitHub comments unless directed to do so by the developer.
