---
name: dwysywd
description: Do What You Say You Will Do. Read Ben's Granola meetings from the last 24 hours, extract every commitment Ben made, then check GitHub, Linear, Slack, Calendar, and Drive for evidence of follow-through. Reports what is still open. Use on "/dwysywd", "what did I say I would do", "what did I commit to", "am I dropping any balls".
argument-hint: "[window, default 24h — e.g. 48h, 'since monday', a date]"
allowed-tools: Bash(date:*), Bash(gh api:*), Bash(gh pr view:*), Bash(gh search:*), mcp__granola__list_meetings, mcp__granola__get_meetings, mcp__granola__get_meeting_transcript, mcp__granola__query_granola_meetings, mcp__linear__list_issues, mcp__linear__get_issue, mcp__linear__list_comments, mcp__slack__slack_search_public_and_private, mcp__slack__slack_read_thread, mcp__slack__slack_read_channel, mcp__claude_ai_Google_Calendar__list_events, mcp__claude_ai_Google_Calendar__search_events, mcp__claude_ai_Google_Drive__search_files, mcp__claude_ai_Google_Drive__list_recent_files
---

# Do What You Say You Will Do

Find every commitment Ben made out loud in a meeting, then decide which ones he has kept. The goal
is to catch dropped balls before the team notices them.

This skill is read-only. Never create tickets, send messages, or schedule events unless Ben asks
after he sees the report.

## Operating principles

- **Only Ben's commitments.** Skip what other people promised, unless Ben is the person who must
  chase it. Those go in a separate short list (see Step 5).
- **A commitment needs an owner and an action.** "I'll send you the deck" counts. "We should look
  into that" does not, unless Ben then claims it ("yeah, I'll take that").
- **Evidence must postdate the commitment.** A PR merged before the meeting does not satisfy a
  promise made in the meeting.
- **Every verdict traces to an artifact.** Cite the PR, ticket, Slack message, event, or doc. If no
  artifact exists, say "no evidence" and never guess "probably done".
- **Query in parallel.** The evidence sources are independent. Fan them out in one message.
- **Terse.** Orwell rules from the global CLAUDE.md. One line per item.

## Step 0 — Resolve the window

The default window is the last 24 hours, ending now. If Ben gives an argument, use it instead.

```bash
date "+%Y-%m-%dT%H:%M:%S%z"           # now, local
date -v-24H "+%Y-%m-%dT%H:%M:%S%z"    # window start (macOS)
```

Ben is Pacific (`America/Los_Angeles`). Keep every timestamp in local time in the report.

If the Granola tools are not available in the session, stop and tell Ben. The Granola MCP server is
`https://mcp.granola.ai/mcp`. Add it at user scope with
`claude mcp add --scope user --transport http granola https://mcp.granola.ai/mcp`.

## Step 1 — Pull the meetings

```
list_meetings(time_range="custom", custom_start=<window start>, custom_end=<now>)
get_meetings(meeting_ids=[...])              # all of them, one call: summaries, attendees, notes
get_meeting_transcript(meeting_id=...)       # one call per meeting, in parallel
```

Read the transcript, not only the summary. Granola summaries compress "I'll do X by Friday" into
"Next steps: X" and often drop the owner. The transcript has the owner and the exact words.

Granola labels the local microphone as Ben ("Me" / "You") and system audio as the other side
("Them"). In an in-person meeting, everyone shares the microphone. In that case, use context and
the summary to decide who spoke.

Granola also captures solo recordings (Looms, walkthroughs). Include them. Ben makes promises to
the camera too ("I'll fix that before the release").

## Step 2 — Extract the commitments

Scan Ben's lines for these patterns:

- First-person future: "I'll", "I will", "I'm going to", "let me", "I can", "I'll take that".
- Accepted asks: someone says "Ben, can you…" and Ben agrees ("yep", "sure", "on it").
- Follow-up promises: "I'll send", "I'll share", "I'll loop in", "I'll set up time", "I'll write it
  up", "I'll file a ticket", "I'll check with", "I'll get back to you".
- Deadlines: "by Friday", "tomorrow", "before the call", "end of week", "this sprint".

Also read the summary's action items. Keep any item the summary assigns to Ben.

For each commitment, record:

| Field    | Content                                                    |
| -------- | ---------------------------------------------------------- |
| What     | The action, as a short imperative ("Send Gio the deck")    |
| To whom  | The person or team waiting on it                           |
| Due      | The stated deadline, or "none stated"                      |
| Meeting  | Title and local start time                                 |
| Quote    | Ben's words, verbatim, at most one sentence                |
| Kind     | code, ticket, message, meeting, doc, decision, or offline  |

Merge duplicates. Ben often repeats one promise in two meetings. Keep the earliest timestamp and
the tightest deadline.

Drop vague intent with no action ("I've been meaning to think about pricing"). Drop jokes.

## Step 3 — Gather evidence

Search each source for activity after the window start. Run every query in one message.

### GitHub

Ben is `bpapillon`. GitHub date filters use UTC, so query today and yesterday in UTC, then filter
by the local timestamp.

```bash
gh api -X GET search/issues -f q="author:bpapillon updated:>=<window start date> is:pr" -f per_page=100 \
  --jq '.items[] | "\(.repository_url|split("/")|.[-2:]|join("/"))#\(.number) [\(.state)] \(.title) | created:\(.created_at) updated:\(.updated_at)"'

gh api -X GET search/commits -f q="author:bpapillon author-date:>=<window start date>" -f per_page=100 \
  --jq '.items[] | "\(.repository.full_name) \(.commit.author.date) \(.commit.message|split("\n")[0])"'

gh api -X GET search/issues -f q="commenter:bpapillon updated:>=<window start date>" -f per_page=50 \
  --jq '.items[] | "\(.repository_url|split("/")|.[-2:]|join("/"))#\(.number) \(.title)"'
```

### Linear

Assignee-scoped queries undercount Ben. Run both queries.

```
list_issues(assignee="me", updatedAt=<window start>, fields=[title,url,status,updatedAt,createdAt])
list_issues(updatedAt=<window start>, limit=100, fields=[title,url,status,assignee,createdBy,createdAt])
```

Keep rows that Ben created or that Ben is assigned. A ticket Ben filed satisfies "I'll file a
ticket". A ticket alone does not satisfy "I'll fix it".

### Slack

Ben's user ID is `U03PH41TWNA`. Re-derive it with `slack_search_users` if a search returns nothing.

```
slack_search_public_and_private(query="from:<@U03PH41TWNA> after:<day before window start>",
  sort="timestamp", sort_dir="asc", limit=20, include_context=false)
```

Paginate to the end. Follow `cursor` in `pagination_info` until no pages remain.

For each "message" commitment, also search for the recipient by name or user ID in Ben's messages.
Read the thread with `slack_read_thread` when the reply decides whether the item closed.

### Calendar

```
list_events(startTime=<window start>, endTime=<now + 14 days>, orderBy="startTime")
```

An event that Ben created after the meeting, with the right attendee, satisfies "I'll set up time".
Look ahead 14 days, because the scheduled meeting itself is usually in the future.

### Drive

```
list_recent_files()
search_files(query=<keywords from the commitment>)
```

A doc that Ben created or edited after the meeting, and that matches the topic, satisfies "I'll
write it up". Check the share list when the promise was to share it.

## Step 4 — Judge each commitment

Give each commitment exactly one verdict:

- **Done.** An artifact after the commitment completes the action. Cite it.
- **Started.** An artifact shows progress, but the action is not complete. Examples: a draft PR, a
  ticket filed for a promised fix, a doc that Ben has not shared yet.
- **Open.** No artifact found, and the action is one that would leave a trace.
- **Unverifiable.** The action leaves no digital trace (a phone call, an in-person word, an email,
  which this skill cannot search). Say so in one clause. Never guess.

Match by meaning, not by keyword. "Send Fynn the pricing numbers" matches a Slack DM to Fynn with a
spreadsheet link, even if the word "pricing" does not appear.

If a deadline has passed and the verdict is Open or Started, mark the item **overdue**.

## Step 5 — Report in chat

Lead with what is still owed. Order the Open and Started items by due date, overdue first. Items
with no stated deadline go last.

```markdown
**Still owed (3)**

1. **Send Gio the Q4 pricing deck** — overdue, due today 12pm. No evidence.
   Gio sync, Mon 2:00pm: "I'll get you the deck before lunch tomorrow."
2. **Fix the trial-expiry webhook bug** — Started. Ticket SCH-8201 filed, no PR yet.
   Eng standup, Mon 9:30am: "Yeah, I'll take that one."
3. **Set up time with Acme's CTO** — Open, no deadline. No calendar event found.
   Acme call, Mon 4:00pm: "Let me find time with your CTO next week."

**Done (4)**

- Share the on-call doc with Chris — shared in #eng at 3:12pm
- File a ticket for the sitemap bug — SCH-8199
- …

**Can't verify (1)**

- Call the accountant about the 409A — offline

**Waiting on others (2)**

- Chris owes the on-call rota draft (Eng standup)
- …
```

Rules for the report:

- Quote Ben verbatim in the Still owed list. The quote reminds him of the context fast.
- Keep the Done list to one line per item, with its artifact.
- Keep "Waiting on others" short. Include only items where Ben is the natural person to chase.
- If no meetings fall in the window, say so in one line and stop.
- If a meeting had no transcript, say which meeting, and use its summary alone.

End with one line that offers next steps: draft the Slack follow-ups, file Linear tickets, or
create calendar holds for the open items. Do nothing until Ben picks one.
