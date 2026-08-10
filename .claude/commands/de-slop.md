# De-Slop Command

Remove AI-generated artifacts before PR submission.

## Workflow

### 1. Context & Comparison

**Ask:** Compare against base branch or PR?
```bash
# If base branch
git diff --name-status $(git remote show origin | grep "HEAD branch" | cut -d ":" -f 2 | xargs)...HEAD

# If PR number provided
gh pr view {PR_NUMBER} --json baseRefName -q .baseRefName
git diff {BASE}...HEAD
```

### 2. Scan for Slop (Always Dry Run)

#### A. Unnecessary Markdown Files
Flag: NOTES.md, PLAN.md, ARCHITECTURE.md, THOUGHTS.md, IDEAS.md, SCRATCH.md, TEMP.md, TODO.md
Ignore: README.md, CONTRIBUTING.md, CHANGELOG.md, docs/**/*.md

#### B. Redundant Comments
```python
# Create user  ← Just restates next line
user = User()
```

#### C. AI TODOs
```python
# TODO: Add error handling
# TODO: Consider edge cases
```

#### D. Excessive Docstrings
Simple getter with 10-line docstring

#### E. Mock-Heavy Tests
```python
@patch @patch @patch  # >3 mocks, tests nothing real
```
Note: CLAUDE.md says "no mocking in tests"

#### F. Fake Data
Suspiciously specific metrics without citation, made-up case studies

#### G. Dangling Plan/Spec/Ticket References
Comments pointing at artifacts outside the code — plans, specs, design docs, ticket/PR numbers, phase names — with no meaning to a code reader.
```python
# Per the migration plan, phase 2
# As described in SCH-1234
# See the spec doc for why
```
A bare ticket/PR reference is slop. Keep one only when it adds context the code can't — explaining a non-obvious workaround, or tracking a real follow-up. The reason belongs in the comment, not the reference.

#### H. Temporary-Condition Comments
Comments explaining a transient state that won't need explaining once the reader sees the code as it is.
```python
# For now, we only support Stripe
# Temporarily disabled until the new flow lands
# This used to call the old API
```
Contrast a *legitimate footgun* — a persistent, non-obvious hazard (ordering dependency, sharp API edge, "do not reorder these calls"). Keep the footgun; cut the running commentary on how the code got here.

#### I. Overly Verbose Comments
The best comments are short. For any comment longer than one sentence, ask whether one sentence — or none — would do. Tighten or remove multi-sentence prose that re-explains the code or pads a simple point.

#### J. Repetitive Comments
A comment on nearly every line of a function, narrating each step. The density is the smell. Keep the one or two that explain *why*; delete the play-by-play.
```python
# increment the counter
count += 1
# check the limit
if count > limit:
    # return an error
    raise LimitError()
```

### 3. Present Findings

```
🔍 Found X slop patterns

[1] NOTES.md (45 lines)
    → Delete: Unnecessary markdown

[2] src/user.py:23-28
    → Remove redundant comments:
    # Create user
    user = User()

[3] src/api.py:15-25
    → Simplify excessive docstring

[4] tests/test_user.py:50-70
    → Flag: Mock-heavy (5 mocks)

Enter numbers (1 2 4), range (1-4), 'all', or 'none':
```

### 4. Execute Selection

**File deletions:**
```bash
git rm {FILE}
```

**Code cleanup:** Use Edit tool, show before/after

**Flag-only items:** Show location, ask if open file

### 5. Summary

```
✅ Cleaned: 2 files deleted, 12 comments removed, 3 docstrings simplified
⚠️  Flagged: tests/test_user.py:50-70 (mock-heavy)

Next: Review flagged items, run tests, commit
```

## Detection Patterns

**Markdown files to flag:**
`NOTES|PLAN|ARCHITECTURE|THOUGHTS|IDEAS|SCRATCH|TEMP|TODO` (case-insensitive)

**Comment patterns:**
- Restates next line exactly
- `# TODO: (Add|Consider|Might|Should)`
- Emoji in code comments
- >3 line docstring for <5 line function
- References a plan/spec/design-doc/ticket/PR/phase that adds nothing to a code reader (`per the plan`, `phase 2`, `see SCH-`, `as in the spec`) — keep only when it explains a non-obvious choice
- Narrates a temporary state (`for now`, `temporarily`, `until ... lands`, `used to`) — keep only genuine persistent footguns
- More than one sentence where one (or none) would do
- A comment on nearly every line of a function — keep the one or two that explain *why*

**Test patterns:**
- >3 `@patch` decorators per test
- No assertions on real behavior

**Fake data:**
- Specific percentages without source
- "According to studies" without citation

## Safety

- Always dry run first with numbered selection
- Never remove: README.md, CONTRIBUTING.md, CHANGELOG.md, docs/**
- When unsure: flag, don't delete
- Confirm if deleting >5 files or >50 lines

## Usage

```bash
/de-slop              # Compare against base
/de-slop 123          # Compare against PR #123
```

## Unresolved Questions

- Threshold for "excessive" docstring?
- Check commit messages for slop?
