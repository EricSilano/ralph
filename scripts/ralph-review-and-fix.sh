#!/bin/bash
# ralph-review-and-fix.sh - Review code and automatically fix issues

set -e

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Work in project root for git operations
cd "$PROJECT_ROOT"

# Set up logging environment
export RALPH_LOG_DIR="$SCRIPT_DIR/logs"

# Configuration
MAX_ITERATIONS="${1:-3}"
REVIEW_LOG="$SCRIPT_DIR/review-results.txt"
FIX_LOG="$SCRIPT_DIR/fix-results.txt"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Source the ralph library for logging and RALPH_MODEL
if [[ -f "$SCRIPT_DIR/ralph-lib.sh" ]]; then
    source "$SCRIPT_DIR/ralph-lib.sh"
fi

echo -e "${CYAN}🔍 Ralph Review & Fix - Automated Code Quality Loop${NC}"
echo "==========================================="
echo "Max iterations: $MAX_ITERATIONS"
echo ""

for ((iteration=1; iteration<=MAX_ITERATIONS; iteration++)); do
    echo -e "${YELLOW}Iteration $iteration/$MAX_ITERATIONS${NC}"
    echo ""

    # Step 1: Run code review
    echo -e "${CYAN}Step 1: Running code review...${NC}"

    # Get list of modified files
    modified_files=$(git diff --name-only HEAD 2>/dev/null || echo "")
    staged_files=$(git diff --name-only --cached 2>/dev/null || echo "")

    if [[ -z "$modified_files" && -z "$staged_files" ]]; then
        echo -e "${GREEN}✓ No modified files to review.${NC}"
        break
    fi

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

    # Run code review and capture output
    full_review_prompt="=== FILES TO REVIEW ===$file_contents

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

If NO issues are found, respond with: <promise>NO_ISSUES</promise>

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

    review_output=$(claude --model "$RALPH_MODEL" --dangerously-skip-permissions "$full_review_prompt" 2>&1)

    # Save review output
    echo "$review_output" > "$REVIEW_LOG"
    echo ""
    echo "Review results:"
    echo "----------------------------------------"
    echo "$review_output"
    echo "----------------------------------------"
    echo ""

    # Check if no issues found
    if echo "$review_output" | grep -q "<promise>NO_ISSUES</promise>"; then
        echo -e "${GREEN}✓ No issues found! Code quality is good.${NC}"
        ralph_info "Code review passed with no issues after $iteration iteration(s)"
        break
    fi

    # Step 2: Fix the issues
    echo -e "${CYAN}Step 2: Fixing issues automatically...${NC}"

    review_log_content=$(cat "$REVIEW_LOG")
    full_fix_prompt="=== FILES TO FIX ===$file_contents

=== REVIEW RESULTS ===
$review_log_content

=== FIX INSTRUCTIONS ===
You are an expert software engineer. A code review was performed and issues were found.

Review the code review results above and fix ALL issues found.

IMPORTANT: Do NOT modify the PRD.md file. The PRD is the source of truth and should not be changed.

For each issue:
1. Read the affected file
2. Understand the problem
3. Implement the suggested fix or a better solution
4. Test your changes (syntax check, basic validation)
5. Update the file

After fixing all issues, provide a summary:
## Fixes Applied
- [File:Line] - [What was fixed]

## Verification
- [Any tests or checks performed]

Be thorough and fix every issue mentioned in the review.
"

    fix_output=$(claude --model "$RALPH_MODEL" --dangerously-skip-permissions "$full_fix_prompt" 2>&1)

    # Save fix output
    echo "$fix_output" > "$FIX_LOG"
    echo ""
    echo "Fix results:"
    echo "----------------------------------------"
    echo "$fix_output"
    echo "----------------------------------------"
    echo ""

    # Run validation if available
    if command -v shellcheck &> /dev/null; then
        echo -e "${CYAN}Running shellcheck validation...${NC}"
        for file in *.sh; do
            if [[ -f "$file" ]]; then
                if shellcheck "$file" 2>/dev/null; then
                    echo -e "${GREEN}✓${NC} $file"
                else
                    echo -e "${RED}✗${NC} $file"
                fi
            fi
        done
        echo ""
    fi

    ralph_info "Completed fix iteration $iteration"

    # If this is the last iteration, warn user
    if [[ $iteration -eq $MAX_ITERATIONS ]]; then
        echo -e "${YELLOW}⚠ Reached maximum iterations ($MAX_ITERATIONS)${NC}"
        echo "Run the script again if more fixes are needed."
    fi

    echo ""
done

echo ""
echo -e "${GREEN}✓ Review & Fix cycle complete!${NC}"
echo ""
echo "Files created:"
echo "  - $REVIEW_LOG (last review results)"
echo "  - $FIX_LOG (last fix results)"
echo ""
echo "Next steps:"
echo "  1. Review the changes: git diff"
echo "  2. Test your code"
echo "  3. Commit: git add . && git commit -m 'fix: automated code review fixes'"
