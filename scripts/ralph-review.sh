#!/bin/bash
# ralph-review.sh - Run comprehensive code review on repository

set -e

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Work in project root for git operations
cd "$PROJECT_ROOT"

# Set up logging environment
export RALPH_LOG_DIR="$SCRIPT_DIR/logs"
export RALPH_STATUS_FILE="$SCRIPT_DIR/.ralph-status.json"

# Source the ralph library for logging
if [[ -f "$SCRIPT_DIR/ralph-lib.sh" ]]; then
    source "$SCRIPT_DIR/ralph-lib.sh"
    ralph_info "Starting code review..."
fi

# Get list of modified files
modified_files=$(git diff --name-only HEAD 2>/dev/null || echo "")
staged_files=$(git diff --name-only --cached 2>/dev/null || echo "")

if [[ -z "$modified_files" && -z "$staged_files" ]]; then
    echo "No modified or staged files to review."
    echo "Tip: Use ralph-review-file.sh to review specific files."
    exit 0
fi

echo "Reviewing modified and staged files..."
echo ""

# Build file contents for Claude
file_contents=""
for file in $modified_files $staged_files; do
    if [[ -f "$file" ]]; then
        file_contents="$file_contents

=== FILE: $file ===
$(cat "$file")
=== END FILE: $file ==="
    fi
done

# Run Claude code review
full_prompt="=== FILES TO REVIEW ===$file_contents

=== REVIEW INSTRUCTIONS ===
You are an expert code reviewer. Review these files for:

1. **Code Quality**: Best practices, readability, maintainability
2. **Bugs & Issues**: Logic errors, edge cases, potential failures
3. **Security**: Vulnerabilities, unsafe patterns, input validation
4. **Performance**: Inefficiencies, optimization opportunities
5. **Documentation**: Comments, function docs, README updates needed

For each issue found:
- Specify the file path and line number
- Explain the issue clearly
- Suggest a specific fix or improvement
- Rate severity: CRITICAL, HIGH, MEDIUM, LOW

Format your response as:
## Summary
[Brief overview]

## Issues Found
### [Severity] - [File:Line]
**Issue**: [Description]
**Fix**: [Suggestion]

## Recommendations
[General improvements]
"

claude --model "$RALPH_MODEL" --dangerously-skip-permissions "$full_prompt"
