#!/bin/bash

# Script to find PR for a given branch name or current branch

if [ "$#" -eq 0 ]; then
    # No arguments provided, use current branch
    BRANCH=$(git branch --show-current)
    echo "Using current branch: $BRANCH"
else
    # Use provided branch name
    BRANCH="$1"
fi

# Search for PR with this branch
PR_JSON=$(gh pr list --search "head:$BRANCH" --json number,title,state,url,body --limit 1)

if [ "$(echo "$PR_JSON" | jq '. | length')" -eq 0 ]; then
    echo "No PR found for branch: $BRANCH"
    exit 1
fi

# Parse and display PR info
PR_NUMBER=$(echo "$PR_JSON" | jq -r '.[0].number')
PR_TITLE=$(echo "$PR_JSON" | jq -r '.[0].title')
PR_STATE=$(echo "$PR_JSON" | jq -r '.[0].state')
PR_URL=$(echo "$PR_JSON" | jq -r '.[0].url')
PR_BODY=$(echo "$PR_JSON" | jq -r '.[0].body')

echo ""
echo "Found PR #$PR_NUMBER"
echo "Title: $PR_TITLE"
echo "State: $PR_STATE"
echo "URL: $PR_URL"
echo ""
echo "Description:"
echo "============"
echo "$PR_BODY"