#!/bin/bash

# Sentry Issue and Event Data Fetcher - Alternative approach
# Usage: ./fetch_sentry_data_v2.sh <issue_id> <auth_token>

set -e

# Check arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <issue_id> <auth_token>"
    echo "Example: $0 6513085340 your_sentry_auth_token"
    exit 1
fi

ISSUE_ID="$1"
AUTH_TOKEN="$2"
BASE_URL="https://sentry.io/api/0"

# Function to make authenticated requests
sentry_api() {
    curl -s -H "Authorization: Bearer $AUTH_TOKEN" "$1"
}

echo "Fetching issue data for issue ID: $ISSUE_ID" >&2

# Step 1: Get issue data
echo "Step 1: Fetching issue details..." >&2
ISSUE_DATA=$(sentry_api "$BASE_URL/issues/$ISSUE_ID/")

# Check if issue fetch was successful
if ! echo "$ISSUE_DATA" | jq . > /dev/null 2>&1; then
    echo "Error: Invalid JSON response from issue endpoint" >&2
    echo "Response: $ISSUE_DATA" >&2
    exit 1
fi

if echo "$ISSUE_DATA" | jq -e '.error' > /dev/null 2>&1; then
    echo "Error fetching issue: $(echo "$ISSUE_DATA" | jq -r '.detail // .error')" >&2
    exit 1
fi

# Step 2: Extract project info from issue data
echo "Step 2: Extracting project information..." >&2
PROJECT_SLUG=$(echo "$ISSUE_DATA" | jq -r '.project.slug')
PROJECT_ID=$(echo "$ISSUE_DATA" | jq -r '.project.id')

if [ "$PROJECT_SLUG" = "null" ] || [ "$PROJECT_ID" = "null" ]; then
    echo "Error: Could not extract project information from issue data" >&2
    exit 1
fi

echo "Found project: $PROJECT_SLUG (ID: $PROJECT_ID)" >&2

# Step 3: Extract organization from the issue's permalink URL
echo "Step 3: Extracting organization from permalink..." >&2
PERMALINK=$(echo "$ISSUE_DATA" | jq -r '.permalink')
echo "Permalink: $PERMALINK" >&2

# Extract org from URL like "https://schematic.sentry.io/issues/6513085340/"
ORG_SLUG=$(echo "$PERMALINK" | sed -n 's|https://\([^.]*\)\.sentry\.io/.*|\1|p')

if [ -z "$ORG_SLUG" ]; then
    echo "Error: Could not extract organization from permalink: $PERMALINK" >&2
    exit 1
fi

echo "Found organization: $ORG_SLUG" >&2

# Step 4: Get latest event for the issue
echo "Step 4: Fetching latest event data..." >&2

# Try method 1: /events/latest/
EVENT_URL="$BASE_URL/projects/$ORG_SLUG/$PROJECT_SLUG/issues/$ISSUE_ID/events/latest/"
echo "Trying latest event URL: $EVENT_URL" >&2
EVENT_DATA=$(sentry_api "$EVENT_URL")

if [ -z "$EVENT_DATA" ] || ! echo "$EVENT_DATA" | jq . > /dev/null 2>&1; then
    echo "Method 1 failed, trying method 2: list events and take first..." >&2

    # Try method 2: List events and take the first one
    EVENTS_URL="$BASE_URL/projects/$ORG_SLUG/$PROJECT_SLUG/issues/$ISSUE_ID/events/"
    echo "Trying events list URL: $EVENTS_URL" >&2
    EVENTS_LIST=$(sentry_api "$EVENTS_URL")

    if [ -n "$EVENTS_LIST" ] && echo "$EVENTS_LIST" | jq . > /dev/null 2>&1; then
        # Get the first event ID from the list
        FIRST_EVENT_ID=$(echo "$EVENTS_LIST" | jq -r '.[0].id // empty')

        if [ -n "$FIRST_EVENT_ID" ] && [ "$FIRST_EVENT_ID" != "null" ]; then
            echo "Found first event ID: $FIRST_EVENT_ID" >&2
            # Get the full event details
            EVENT_DETAIL_URL="$BASE_URL/projects/$ORG_SLUG/$PROJECT_SLUG/events/$FIRST_EVENT_ID/"
            echo "Fetching event details: $EVENT_DETAIL_URL" >&2
            EVENT_DATA=$(sentry_api "$EVENT_DETAIL_URL")

            if [ -n "$EVENT_DATA" ] && echo "$EVENT_DATA" | jq . > /dev/null 2>&1; then
                echo "Successfully fetched event details!" >&2
            else
                echo "Failed to fetch event details" >&2
                EVENT_DATA='null'
            fi
        else
            echo "No event ID found in events list" >&2
            EVENT_DATA='null'
        fi
    else
        echo "Failed to fetch events list" >&2
        EVENT_DATA='null'
    fi
fi

echo "Event response length: ${#EVENT_DATA}" >&2

# Check if event fetch was successful and is valid JSON
if [ -z "$EVENT_DATA" ]; then
    echo "Warning: Empty response from events endpoint" >&2
    EVENT_DATA='null'
elif ! echo "$EVENT_DATA" | jq . > /dev/null 2>&1; then
    echo "Warning: Invalid JSON response from events endpoint" >&2
    echo "Full response: $EVENT_DATA" >&2
    EVENT_DATA='null'
elif echo "$EVENT_DATA" | jq -e '.error' > /dev/null 2>&1; then
    echo "Warning: Could not fetch latest event: $(echo "$EVENT_DATA" | jq -r '.detail // .error')" >&2
    EVENT_DATA='null'
else
    echo "Event data appears to be valid JSON" >&2
fi

# Step 5: Combine both datasets into a single JSON object
echo "Step 5: Combining data..." >&2

# Debug: Check if both JSON strings are valid
echo "Checking issue data validity..." >&2
if ! echo "$ISSUE_DATA" | jq . > /dev/null 2>&1; then
    echo "ERROR: Issue data is not valid JSON" >&2
    echo "Issue data: $ISSUE_DATA" >&2
    exit 1
fi

echo "Checking event data validity..." >&2
if [ "$EVENT_DATA" != "null" ] && ! echo "$EVENT_DATA" | jq . > /dev/null 2>&1; then
    echo "ERROR: Event data is not valid JSON" >&2
    echo "Event data: $EVENT_DATA" >&2
    exit 1
fi

echo "Both data sources are valid JSON, combining..." >&2

COMBINED_DATA=$(jq -n \
    --argjson issue "$ISSUE_DATA" \
    --argjson event "$EVENT_DATA" \
    '{
        "issue": $issue,
        "latest_event": $event,
        "metadata": {
            "fetched_at": now | strftime("%Y-%m-%dT%H:%M:%SZ"),
            "organization": $issue.project.slug,
            "project": $issue.project.slug,
            "issue_id": $issue.id
        }
    }')

echo "Successfully fetched and combined data!" >&2
echo "$COMBINED_DATA"
