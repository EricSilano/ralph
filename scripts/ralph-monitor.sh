#!/bin/bash
# ralph-monitor.sh - Continuous oversight loop that reviews progress every 10 minutes
set -e

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Work in project root for git operations
cd "$PROJECT_ROOT"

# Set up logging environment
export RALPH_LOG_DIR="$PROJECT_ROOT/logs"
export RALPH_STATUS_FILE="$PROJECT_ROOT/.ralph-status.json"
export RALPH_STATE_FILE="$PROJECT_ROOT/.ralph-state.json"
export RALPH_MONITOR_PID_FILE="$PROJECT_ROOT/.ralph-monitor.pid"
export RALPH_PROMPTS_DIR="$PROJECT_ROOT/prompts"

# Source ralph library for logging
if [[ -f "$SCRIPT_DIR/ralph-lib.sh" ]]; then
    source "$SCRIPT_DIR/ralph-lib.sh"
    ralph_setup_logging
fi

PRD_FILE="$PROJECT_ROOT/PRD.md"
PROGRESS_FILE="$PROJECT_ROOT/progress.txt"
MONITOR_LOG="$PROJECT_ROOT/logs/ralph-monitor.log"
CONTEXT_DIR="$PROJECT_ROOT/context"
PROMPTS_DIR="$PROJECT_ROOT/prompts"
MONITOR_TEMPLATE="$PROMPTS_DIR/monitor-review-prompt.md"

# Colors for output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to load and prepare the review prompt template
load_review_prompt() {
    local iteration_num="$1"
    local modified_files_list="$2"

    # Check if template exists, use inline prompt as fallback
    if [[ ! -f "$MONITOR_TEMPLATE" ]]; then
        # Fallback to inline prompt
        cat <<'EOF'
You are Ralph's oversight system - a senior technical reviewer monitoring the implementation.

**Your Role**: Review recent changes and ensure the implementation stays on track.

## Tasks:
1. **Review Recent Changes**: Analyze all modified files
2. **Check PRD Alignment**: Are we implementing what was requested?
3. **Code Quality Check**: Are there obvious bugs, security issues, or anti-patterns?
4. **Context Integration**: If context/ folder exists, ensure implementation aligns with documentation
5. **PRD Adjustment**: If the implementation reveals issues or gaps in the PRD, suggest updates

## Output Format:
### Status: [ON_TRACK | NEEDS_ATTENTION | CRITICAL_ISSUE]

### Summary
[Brief overview of current state]

### Issues Found
[List any problems, or 'None']

### PRD Adjustments Needed
If the PRD needs updating (tasks were unclear, missing requirements discovered, etc.):
- **What to add/change**: [Specific changes]
- **Reason**: [Why this adjustment is needed]

If no PRD changes needed, write: NO_PRD_CHANGES_NEEDED

### Recommendations
[Any guidance for Ralph to improve the implementation]

---
**Important**:
- Only suggest PRD changes if truly needed (unclear requirements, discovered gaps)
- Don't suggest changes for minor code quality issues (let ralph-review-and-fix handle those)
- Focus on high-level alignment and architectural concerns
EOF
        return 0
    fi

    # Load template and replace variables
    local prompt
    prompt=$(cat "$MONITOR_TEMPLATE")

    # Replace template variables
    prompt="${prompt//\{\{PRD_FILE\}\}/$PRD_FILE}"
    prompt="${prompt//\{\{PROGRESS_FILE\}\}/$PROGRESS_FILE}"
    prompt="${prompt//\{\{CONTEXT_DIR\}\}/$CONTEXT_DIR}"
    prompt="${prompt//\{\{ITERATION\}\}/$iteration_num}"

    # Replace modified files (escape newlines)
    local files_formatted
    if [[ -n "$modified_files_list" ]]; then
        files_formatted=$(echo "$modified_files_list" | tr ' ' '\n' | sed 's/^/- /')
    else
        files_formatted="No files changed"
    fi
    prompt="${prompt//\{\{MODIFIED_FILES\}\}/$files_formatted}"

    echo "$prompt"
}

# Store PID for cleanup
echo $$ > "$RALPH_MONITOR_PID_FILE"

# Cleanup on exit
cleanup() {
    ralph_info "Monitor loop terminated"
    rm -f "$RALPH_MONITOR_PID_FILE"
    exit 0
}

trap cleanup SIGTERM SIGINT EXIT

ralph_info "🔍 Ralph Monitor started (PID: $$)"
ralph_info "Waiting 10 minutes before first check to let Ralph make initial progress..."
echo ""

# Wait 10 minutes before first check
sleep 600

ralph_info "Starting monitoring checks every 10 minutes for code quality and PRD alignment"
echo ""

iteration=0

while true; do
    iteration=$((iteration + 1))
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    echo -e "${CYAN}[$timestamp] Monitor Check #$iteration${NC}" | tee -a "$MONITOR_LOG"
    ralph_info "Starting monitor iteration $iteration"

    # Get recent changes
    modified_files=$(git diff --name-only HEAD 2>/dev/null || echo "")
    staged_files=$(git diff --name-only --cached 2>/dev/null || echo "")
    untracked_files=$(git ls-files --others --exclude-standard 2>/dev/null || echo "")

    all_files="$modified_files $staged_files $untracked_files"

    if [[ -z "$all_files" ]]; then
        echo -e "${YELLOW}  ⚠ No changes detected. Skipping review.${NC}" | tee -a "$MONITOR_LOG"
        ralph_info "No changes detected in iteration $iteration"
    else
        echo -e "${GREEN}  ✓ Changes detected. Reviewing...${NC}" | tee -a "$MONITOR_LOG"
        ralph_info "Changes detected: $all_files"

        # Build file references for Claude
        file_refs="@$PRD_FILE @$PROGRESS_FILE"

        # Add changed files
        for file in $all_files; do
            if [[ -f "$file" ]] && [[ "$file" != "$MONITOR_LOG" ]]; then
                file_refs="$file_refs @$file"
            fi
        done

        # Add context folder files if they exist
        if [[ -d "$CONTEXT_DIR" ]]; then
            echo "  📁 Reading context folder..." | tee -a "$MONITOR_LOG"
            while IFS= read -r -d '' context_file; do
                file_refs="$file_refs @$context_file"
            done < <(find "$CONTEXT_DIR" -type f \( -name "*.md" -o -name "*.txt" \) -print0 2>/dev/null)
        fi

        # Run oversight review with Claude
        echo "  🤖 Running oversight review..." | tee -a "$MONITOR_LOG"

        # Load review prompt from template
        review_prompt=$(load_review_prompt "$iteration" "$all_files")

        # Run review with Claude
        review_output=$(claude --dangerously-skip-permissions "$file_refs

$review_prompt" 2>&1) || review_output="ERROR: Claude review failed"

        # Save review output
        echo "---" >> "$MONITOR_LOG"
        echo "$review_output" >> "$MONITOR_LOG"
        echo "---" >> "$MONITOR_LOG"

        # Parse the review status
        if echo "$review_output" | grep -q "Status: CRITICAL_ISSUE"; then
            echo -e "${RED}  ❌ CRITICAL ISSUE DETECTED!${NC}" | tee -a "$MONITOR_LOG"
            ralph_error "Critical issue detected in iteration $iteration"
            # Show first 30 lines of review
            echo "$review_output" | head -30
        elif echo "$review_output" | grep -q "Status: NEEDS_ATTENTION"; then
            echo -e "${YELLOW}  ⚠ Issues need attention${NC}" | tee -a "$MONITOR_LOG"
            ralph_warn "Issues detected in iteration $iteration"
            echo "$review_output" | head -20
        else
            echo -e "${GREEN}  ✓ Implementation on track${NC}" | tee -a "$MONITOR_LOG"
            ralph_info "Implementation on track in iteration $iteration"
        fi

        # Check if PRD needs updating
        if ! echo "$review_output" | grep -q "NO_PRD_CHANGES_NEEDED"; then
            echo -e "${YELLOW}  📝 PRD may need updates${NC}" | tee -a "$MONITOR_LOG"
            ralph_warn "PRD adjustment suggested in iteration $iteration"

            # Extract PRD adjustment section
            prd_adjustments=$(echo "$review_output" | sed -n '/### PRD Adjustments Needed/,/### Recommendations/p' | sed '$d')

            if [[ -n "$prd_adjustments" ]] && [[ "$prd_adjustments" != *"NO_PRD_CHANGES_NEEDED"* ]]; then
                echo "  🔧 Applying PRD adjustments..." | tee -a "$MONITOR_LOG"

                # Load PRD update prompt from template
                prd_update_prompt=$(ralph_load_template "prd-update-prompt.md" \
                    "PRD_FILE=$PRD_FILE" \
                    "PROGRESS_FILE=$PROGRESS_FILE" \
                    "PRD_ADJUSTMENTS=$prd_adjustments")

                # Let Claude update the PRD with context
                claude --dangerously-skip-permissions "@$PRD_FILE @$PROGRESS_FILE

$prd_update_prompt" >/dev/null 2>&1 || ralph_error "Failed to update PRD"

                echo -e "${GREEN}  ✓ PRD updated${NC}" | tee -a "$MONITOR_LOG"
                ralph_info "PRD updated based on oversight review"
            fi
        fi
    fi

    echo "" | tee -a "$MONITOR_LOG"

    # Sleep for 10 minutes (600 seconds)
    ralph_info "Monitor iteration $iteration complete. Sleeping for 10 minutes..."
    sleep 600
done
