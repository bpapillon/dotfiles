Please fetch Sentry data using the following command:

```bash
~/.claude/scripts/fetch-sentry-data.sh "$ARGUMENTS" "$SENTRY_API_TOKEN"
```

This will return a combined JSON object containing both the issue summary and the latest event details including POST bodies, headers, stack traces, and all context data visible in the Sentry UI.

Do not immediately attempt to fix the error; instead, review the Sentry data and prompt the user for a next step.
