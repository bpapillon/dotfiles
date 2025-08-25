#!/bin/bash

# ntfy notification script for Claude Code
# Sends a notification when Claude Code stops

# Configure your ntfy server and topic here
NTFY_SERVER="${NTFY_SERVER:-https://ntfy.sh}"  # Default public server, or set NTFY_SERVER env var
NTFY_TOPIC="${NTFY_TOPIC:-}"  # Set NTFY_TOPIC env var to your unique topic

# Exit if no topic is configured
if [ -z "$NTFY_TOPIC" ]; then
    exit 0
fi

# Get the notification type from the first argument
NOTIFICATION_TYPE="${1:-notification}"

# Send notification to ntfy
curl -H "Title: Claude Code Stopped" \
     -H "Priority: default" \
     -H "Tags: robot" \
     -d "Claude Code has finished running on $(hostname)" \
     "${NTFY_SERVER}/${NTFY_TOPIC}"