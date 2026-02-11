Use `git diff main...HEAD` to get the changes on the current branch relative to the main branch; we only take into account changes on the current branch. Please do not make any comments about existing code that is unchanged.

**PART 1**
First, review the code changes against the following criteria:

Code quality:

- Is the code high-quality, well-structured, and maintainable?
- Will it be easy for another developer to read this code later and understand what it is doing?
- Review the CLAUDE.md file for the project - if this file specifies conventions for the code base, does this PR follow them?
- Are there any signs of possible AI-generated slop that should be removed (e.g. excess unhelpful comments)?

Performance:

- Is there any code that could be optimized for better performance?
- Look for N+1 queries, inefficient loops, or other performance issues.

Testing and bugs:

- Do you see any potential bugs or issues?
- Are there any tests? Do they cover the new code?
- If it is Go code, is there any risk of nil pointer errors?

Security:

- Are there any queries that do not filter by account_id and environment_id?
- Are there any security concerns such as hardcoded secrets, sensitive data exposure, or insecure dependencies?

**PART 2**

Attempt to get some information about the requirements of the PR.

First, check if a Linear ticket ID was provided as an argument. If not, try to extract it from the current git branch name (which often follows the pattern {username}/{linear-ticket}-{title}).

You can also look for a Github PR description using the following script:

```bash
~/.claude/scripts/fetch-github-pr.sh
```

The Github PR may contain some additional information about the requirements or implementation, and may be particularly useful in the case where a Linear ticket is not present.

If a linear ticket was found:

- Get the issue details including comments using: `linear issue view {ticket-id}`
- Look for any Sentry links in the issue description or comments. If found, extract the Sentry issue ID and fetch the data using: `~/.claude/scripts/fetch-sentry-data.sh "{sentry-issue-id}" "$SENTRY_API_TOKEN"`
- How well do the changes fulfill the requirements from the Linear ticket?

If a Linear ticket cannot be found, you can prompt me for additional information about the requirements.
