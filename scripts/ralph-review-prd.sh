#!/bin/bash
# ralph-review-prd.sh - Review PRD implementation and fix issues

set -e

# Get script directory, ralph folder, and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$RALPH_DIR/.." && pwd)"

# Work in project root for file operations
cd "$PROJECT_ROOT"

# Set up logging environment (logs are in ralph folder)
export RALPH_LOG_DIR="$RALPH_DIR/logs"

# PRD.md and progress.txt are always inside the ralph folder (not project root)
PRD_FILE="${1:-$RALPH_DIR/PRD.md}"
PROGRESS_FILE="${2:-$RALPH_DIR/progress.txt}"
REVIEW_LOG="$RALPH_DIR/prd-review.txt"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Source the ralph library
if [[ -f "$SCRIPT_DIR/ralph-lib.sh" ]]; then
    source "$SCRIPT_DIR/ralph-lib.sh"
fi

echo -e "${CYAN}🔍 Ralph PRD Review & Quality Check${NC}"
echo "==========================================="
echo ""

if [[ ! -f "$PRD_FILE" ]]; then
    echo "Error: PRD file not found: $PRD_FILE"
    exit 1
fi

echo -e "${YELLOW}Step 1: Reviewing implementation against PRD...${NC}"
echo ""

# Get all source files (customize based on your project)
source_files=$(find . -type f \( -name "*.sh" -o -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.rb" \) ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | head -20)

file_refs="@$PRD_FILE @$PROGRESS_FILE"
for file in $source_files; do
    file_refs="$file_refs @$file"
done

# Run comprehensive review
review_output=$(claude --model "$RALPH_MODEL" -p --dangerously-skip-permissions "$file_refs

You are a senior software architect and code reviewer.

Review the current implementation against the PRD requirements:

1. **PRD Completeness**: Are all tasks from the PRD implemented?
2. **Code Quality**: Best practices, maintainability, readability
3. **Bugs & Issues**: Logic errors, edge cases, potential failures
4. **Security**: Vulnerabilities, unsafe patterns
5. **Performance**: Inefficiencies, bottlenecks
6. **Testing**: Test coverage, missing tests
7. **Documentation**: Code comments, README, user docs

For each issue:
- Severity: CRITICAL, HIGH, MEDIUM, LOW
- File and line number
- Clear description
- Specific fix recommendation

If everything is perfect, respond with: <promise>EXCELLENT</promise>

Format:
## PRD Status
[Completion percentage and missing features]

## Critical Issues
[Must fix before deployment]

## Code Quality Issues
[Improvements needed]

## Recommendations
[Next steps]
")

echo "$review_output" > "$REVIEW_LOG"
echo "$review_output"
echo ""

# Check if excellent
if echo "$review_output" | grep -q "<promise>EXCELLENT</promise>"; then
    echo -e "${GREEN}✓ Implementation is excellent! No issues found.${NC}"
    exit 0
fi

# Ask user if they want to auto-fix
echo ""
echo -e "${YELLOW}Issues found. Options:${NC}"
echo "  [f] Fix issues automatically"
echo "  [v] View review log only"
echo "  [q] Quit"
echo ""
read -p "Your choice: " choice

case "$choice" in
    [Ff]*)
        echo ""
        echo -e "${CYAN}Fixing issues automatically...${NC}"

        claude --model "$RALPH_MODEL" -p --dangerously-skip-permissions "$file_refs @$REVIEW_LOG

You are an expert software engineer.

A comprehensive code review found issues in the implementation.
Review the findings in $REVIEW_LOG and fix ALL issues.

IMPORTANT: Do NOT modify the PRD.md file. The PRD is the source of truth and should not be changed.

Priority:
1. Fix CRITICAL issues first
2. Fix HIGH severity issues
3. Fix MEDIUM and LOW issues
4. Improve code quality

For each fix:
1. Read and understand the code
2. Implement the fix properly
3. Update tests if needed
4. Verify the fix works

After fixing, update progress.txt with what was fixed.

Provide a summary:
## Fixes Applied
- [File] - [Issue fixed]

## Tests Updated
- [Test changes]

## Verification
- [How you verified fixes work]
"

        echo ""
        echo -e "${GREEN}✓ Fixes applied!${NC}"
        echo ""
        echo "Review changes: git diff"
        ;;
    [Vv]*)
        echo "Review log saved to: $REVIEW_LOG"
        ;;
    *)
        echo "Exiting."
        ;;
esac
