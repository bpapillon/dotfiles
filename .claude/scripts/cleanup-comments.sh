#!/bin/bash
# Prompt Claude to clean up unnecessary comments after modifying code

# Check if we're in a git repository
git rev-parse --git-dir > /dev/null 2>&1 || exit 0

# Check if any source files have been modified
MODIFIED_FILES=$(git diff --name-only HEAD 2>/dev/null | head -30)
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null | head -30)
ALL_MODIFIED=$(echo -e "$MODIFIED_FILES\n$STAGED_FILES" | sort -u | grep -v '^$')

if [ -z "$ALL_MODIFIED" ]; then
    exit 0
fi

# Filter for source code files only
SOURCE_FILES=""
for file in $ALL_MODIFIED; do
    if [[ "$file" =~ \.(go|js|jsx|ts|tsx|py|java|c|cpp|cc|h|hpp|cs|rb|php|swift|kt|rs|scala|m|mm)$ ]]; then
        if [ -f "$file" ]; then
            SOURCE_FILES="$SOURCE_FILES $file"
        fi
    fi
done

if [ -z "$SOURCE_FILES" ]; then
    exit 0
fi

# Count the number of modified source files
FILE_COUNT=$(echo "$SOURCE_FILES" | wc -w | tr -d ' ')

# If source files were modified, prompt for cleanup
echo "You've modified $FILE_COUNT source file(s). Please review your work and remove any unnecessary comments that were added during implementation."
echo ""
echo "Remove:"
echo "• Implementation placeholders or TODOs without specific action items"
echo "• Work-in-progress notes or process narration"
echo "• Self-referential comments mentioning Claude or AI"
echo "• Empty comment lines"
echo "• Obvious comments that just restate what the code does"
echo ""
echo "Keep only:"
echo "• Function/class/module documentation (godoc, JSDoc, docstrings, etc.)"
echo "• Comments explaining complex, non-obvious, or tricky logic"
echo "• Important warnings or gotchas for future developers"
echo "• License headers and copyright notices"
echo "• TODO/FIXME comments"
echo ""
echo "Review and clean up comments in the modified files, then confirm when done."

exit 0
