Help me resolve git merge/rebase conflicts in the current repository.

First, identify the conflicting files:

```bash
git diff --name-only --diff-filter=U
```

For each conflicting file:

1. Read the file to understand the conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
2. Analyze both sides of the conflict:
   - HEAD (current branch): What changes were made and why
   - Incoming (other branch): What changes were made and why
3. Look at surrounding code context to understand the intent of each change
4. Resolve the conflict by combining both changes appropriately, ensuring:
   - No duplicate code
   - Consistent style (imports, naming conventions, etc.)
   - All functionality from both sides is preserved unless one clearly supersedes the other

After resolving each file, run all relevant tests, linters and formatters for the current project to ensure that you have a stable and correctly functioning codebase.

Do not run `git add` or `git rebase --continue` automatically; prompt the user to verify the resolution first.
