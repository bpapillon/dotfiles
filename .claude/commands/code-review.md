Please review the changes on the current branch relative to the main branch. In your review, only take into account changes on the current branch; please do not make any comments about existing code that is unchanged.

First, check if a Linear ticket ID was provided as an argument. If not, try to extract it from the current git branch name (which often follows the pattern {username}/{linear-ticket}-{title}).

Consider:
* If a Linear ticket ID is available (either from $ARGUMENTS or parsed from the branch name):
  - Get the issue details including comments using: `linear issue view {ticket-id}`
  - Look for any image URLs (screenshots, GIFs, etc.) in the issue description or comments. If found, download them to a temporary location and use the Read tool to view them visually
  - Note any Loom video links found in the ticket. While you cannot watch the videos, acknowledge their presence and consider asking the user for a summary if the video content seems critical to understanding the requirements
  - Look for any Sentry links in the issue description or comments. If found, extract the Sentry issue ID and fetch the data using: `~/.claude/scripts/fetch_sentry_data.sh "{sentry-issue-id}" "$SENTRY_API_TOKEN"`
  - How well do the changes fulfill the requirements from the Linear ticket?
* Consider the code quality, readability, maintainability, performance, and security.
* Are there any potential bugs or issues?
* Is the code readable? Will it be easy to maintain?
* Review the CLAUDE.md file for the project - if this file specifies conventions for the code base, does this PR follow them?
* Are there any tests? Do they cover the new code?
* Are there any signs of possible AI-generated slop that should be removed (e.g. excess unhelpful comments)?