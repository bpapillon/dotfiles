Please fetch the Slack thread using the following command:

```bash
~/.claude/scripts/fetch-slack-thread.sh "$ARGUMENTS" "$SLACK_TOKEN"
```

This will return all messages in the thread formatted as markdown, including:
- User display names (resolved from user IDs)
- Timestamps for each message
- Full message text

After fetching, summarize the key points of the discussion.
