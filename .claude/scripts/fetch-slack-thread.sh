#!/bin/bash

# Script to fetch all messages from a Slack thread and output as markdown
# Usage: fetch-slack-thread.sh <slack_thread_url> <slack_token>

set -e

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <slack_thread_url> <slack_token>"
    echo "Example: $0 'https://schematichq.slack.com/archives/C05L377BBS4/p1764695392206959' \$SLACK_TOKEN"
    exit 1
fi

SLACK_URL="$1"
SLACK_TOKEN="$2"

# Parse channel ID and thread timestamp from URL
# URL format: https://workspace.slack.com/archives/CHANNEL_ID/pTIMESTAMP
CHANNEL_ID=$(echo "$SLACK_URL" | sed -E 's|.*/archives/([^/]+)/.*|\1|')
RAW_TS=$(echo "$SLACK_URL" | sed -E 's|.*/p([0-9]+).*|\1|')

# Convert timestamp: p1764695392206959 -> 1764695392.206959
# Insert decimal point 6 digits from the end
LEN=${#RAW_TS}
PREFIX_LEN=$((LEN - 6))
THREAD_TS="${RAW_TS:0:PREFIX_LEN}.${RAW_TS:PREFIX_LEN}"

if [ -z "$CHANNEL_ID" ] || [ -z "$THREAD_TS" ]; then
    echo "Error: Could not parse channel ID or thread timestamp from URL"
    exit 1
fi

# Fetch thread messages
RESPONSE=$(curl -s "https://slack.com/api/conversations.replies?channel=$CHANNEL_ID&ts=$THREAD_TS" \
    -H "Authorization: Bearer $SLACK_TOKEN")

# Check for API errors
OK=$(echo "$RESPONSE" | jq -r '.ok')
if [ "$OK" != "true" ]; then
    ERROR=$(echo "$RESPONSE" | jq -r '.error')
    echo "Error fetching thread: $ERROR"
    exit 1
fi

# Create temp file for user cache
USER_CACHE=$(mktemp)
trap "rm -f $USER_CACHE" EXIT

# Fetch user info for all unique users in the thread
USER_IDS=$(echo "$RESPONSE" | jq -r '.messages[].user // empty' | sort -u)

for USER_ID in $USER_IDS; do
    USER_RESPONSE=$(curl -s "https://slack.com/api/users.info?user=$USER_ID" \
        -H "Authorization: Bearer $SLACK_TOKEN")
    USER_OK=$(echo "$USER_RESPONSE" | jq -r '.ok')
    if [ "$USER_OK" = "true" ]; then
        DISPLAY_NAME=$(echo "$USER_RESPONSE" | jq -r '.user.profile.display_name // .user.profile.real_name // .user.name')
        # Handle empty display_name
        if [ -z "$DISPLAY_NAME" ] || [ "$DISPLAY_NAME" = "null" ]; then
            DISPLAY_NAME=$(echo "$USER_RESPONSE" | jq -r '.user.name // empty')
        fi
    else
        DISPLAY_NAME="$USER_ID"
    fi
    echo "$USER_ID=$DISPLAY_NAME" >> "$USER_CACHE"
done

# Function to look up user name from cache
get_user_name() {
    local user_id="$1"
    local name=$(grep "^${user_id}=" "$USER_CACHE" 2>/dev/null | cut -d= -f2-)
    if [ -n "$name" ]; then
        echo "$name"
    else
        echo "$user_id"
    fi
}

# Output as markdown
echo "# Slack Thread"
echo ""
echo "**Channel:** $CHANNEL_ID"
echo "**Thread:** $THREAD_TS"
echo "**URL:** $SLACK_URL"
echo ""
echo "---"
echo ""

# Process each message
echo "$RESPONSE" | jq -c '.messages[]' | while read -r MSG; do
    USER_ID=$(echo "$MSG" | jq -r '.user // "bot"')
    TS=$(echo "$MSG" | jq -r '.ts')
    TEXT=$(echo "$MSG" | jq -r '.text // ""')

    # Convert Unix timestamp to readable date
    TS_INT=${TS%.*}
    if [[ "$OSTYPE" == "darwin"* ]]; then
        DATE=$(date -r "$TS_INT" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$TS")
    else
        DATE=$(date -d "@$TS_INT" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$TS")
    fi

    # Get display name from cache
    DISPLAY_NAME=$(get_user_name "$USER_ID")

    echo "### $DISPLAY_NAME"
    echo "*$DATE*"
    echo ""
    echo "$TEXT"
    echo ""
    echo "---"
    echo ""
done
