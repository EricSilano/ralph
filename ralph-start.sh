#!/bin/bash
set -e

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Work in project root for git operations, but reference ralph files
cd "$PROJECT_ROOT"

# Set up logging environment
export RALPH_LOG_DIR="$SCRIPT_DIR/logs"
export RALPH_STATUS_FILE="$SCRIPT_DIR/.ralph-status.json"
export RALPH_STATE_FILE="$SCRIPT_DIR/.ralph-state.json"
export RALPH_PROGRESS_FILE="$SCRIPT_DIR/progress.txt"

# Source ralph library for logging
if [[ -f "$SCRIPT_DIR/scripts/ralph-lib.sh" ]]; then
    source "$SCRIPT_DIR/scripts/ralph-lib.sh"
    ralph_setup_logging
fi

PRD_FILE="$SCRIPT_DIR/PRD.md"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"

# Colors for better UX
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🧑‍💻 Ralph Wiggum - Interactive Setup${NC}"
echo "==========================================="
echo ""

# Step 1: Get brief description from user
echo -e "${YELLOW}Step 1: What do you want to build?${NC}"
echo ""
echo "Choose input method:"
echo "  [1] Type/paste directly (press Ctrl+D when done)"
echo "  [2] Open in editor (\$EDITOR)"
echo ""
read -p "Your choice [1]: " input_choice
input_choice=${input_choice:-1}

description=""

case $input_choice in
    2)
        # Use editor
        TEMP_FILE=$(mktemp)
        ${EDITOR:-vim} "$TEMP_FILE"
        description=$(cat "$TEMP_FILE")
        rm -f "$TEMP_FILE"
        ;;
    *)
        # Direct input with Ctrl+D to finish
        echo ""
        echo "Enter your description (paste is OK, press Ctrl+D on new line when done):"
        echo "---"
        description=$(cat)
        echo "---"
        ;;
esac

if [[ -z "$description" ]]; then
    echo "No description provided. Exiting."
    exit 1
fi

echo ""
echo -e "${CYAN}📝 Your description:${NC}"
echo "$description"
echo ""

# Step 2: AI improves the prompt into a full PRD
echo -e "${YELLOW}Step 2: Generating detailed PRD...${NC}"
echo ""

# Load PRD generation prompt from template
prd_prompt=$(ralph_load_template "prd-generation-prompt.md" "USER_DESCRIPTION=$description")

claude -p "$prd_prompt" > "$PRD_FILE"

echo -e "${GREEN}✓ PRD generated!${NC}"
echo ""

# Step 3: Show PRD for validation
echo -e "${YELLOW}Step 3: Review the generated PRD${NC}"
echo "==========================================="
cat "$PRD_FILE"
echo ""
echo "==========================================="
echo ""

# Step 4: Ask for validation
while true; do
    echo -e "${YELLOW}Options:${NC}"
    echo "  [y] Approve and start Ralph"
    echo "  [e] Edit PRD manually (opens in \$EDITOR)"
    echo "  [r] Regenerate with more details"
    echo "  [n] Cancel"
    echo ""
    read -p "Your choice: " choice

    case $choice in
        [Yy]* )
            echo ""
            echo -e "${GREEN}✓ PRD approved!${NC}"
            break
            ;;
        [Ee]* )
            ${EDITOR:-vim} "$PRD_FILE"
            echo ""
            echo -e "${CYAN}Updated PRD:${NC}"
            cat "$PRD_FILE"
            echo ""
            ;;
        [Rr]* )
            echo ""
            echo "Add more details or clarifications (press Ctrl+D when done):"
            echo "---"
            extra=$(cat)
            echo "---"
            description+=$'\n'"Additional details: "$extra
            echo -e "${YELLOW}Regenerating PRD...${NC}"

            # Load PRD generation prompt from template (reuse same template)
            prd_prompt=$(ralph_load_template "prd-generation-prompt.md" "USER_DESCRIPTION=$description")

            claude -p "$prd_prompt" > "$PRD_FILE"
            echo ""
            cat "$PRD_FILE"
            echo ""
            ;;
        [Nn]* )
            echo "Cancelled."
            exit 0
            ;;
        * )
            echo "Please answer y, e, r, or n."
            ;;
    esac
done

# Initialize progress file
echo "# Progress Log" > "$PROGRESS_FILE"
echo "" >> "$PROGRESS_FILE"
echo "Started: $(date)" >> "$PROGRESS_FILE"
echo "" >> "$PROGRESS_FILE"

# Step 5: Ask how to run Ralph
echo ""
echo -e "${YELLOW}How should Ralph work?${NC}"
echo "  [1] Babysitting mode (one task, then stop)"
echo "  [2] AFK mode (specify iterations)"
echo ""
read -p "Your choice: " mode

case $mode in
    1 )
        echo ""
        echo -e "${CYAN}🚀 Starting Ralph (babysitting mode)...${NC}"
        echo ""
        "$SCRIPT_DIR/scripts/ralph-once.sh"
        ;;
    2 )
        read -p "How many iterations? " iterations
        echo ""
        echo -e "${CYAN}🚀 Starting Ralph (AFK mode, $iterations iterations)...${NC}"
        echo -e "${CYAN}🔍 Starting oversight monitor (checks every 10 minutes)...${NC}"
        echo ""

        # Start monitor in background
        "$SCRIPT_DIR/scripts/ralph-monitor.sh" &
        MONITOR_PID=$!
        echo "Monitor started (PID: $MONITOR_PID)"

        # Setup cleanup trap to kill monitor when ralph-afk ends
        cleanup_monitor() {
            if [[ -n "$MONITOR_PID" ]] && kill -0 "$MONITOR_PID" 2>/dev/null; then
                echo ""
                echo -e "${YELLOW}Stopping oversight monitor...${NC}"
                kill "$MONITOR_PID" 2>/dev/null || true
                wait "$MONITOR_PID" 2>/dev/null || true
                echo -e "${GREEN}✓ Monitor stopped${NC}"
            fi
        }
        trap cleanup_monitor EXIT SIGINT SIGTERM

        # Run ralph-afk (this blocks until completion)
        "$SCRIPT_DIR/scripts/ralph-afk.sh" "$iterations"

        # Cleanup monitor after ralph-afk completes
        cleanup_monitor
        trap - EXIT SIGINT SIGTERM
        ;;
    * )
        echo "Invalid choice. You can run $SCRIPT_DIR/scripts/ralph-once.sh or $SCRIPT_DIR/scripts/ralph-afk.sh manually."
        exit 0
        ;;
esac

# Step 6: Run code review and fixes
echo ""
echo -e "${CYAN}🔍 Step 6: Code Review & Quality Check${NC}"
echo "==========================================="
echo ""

REVIEW_LOG="$SCRIPT_DIR/review-results.txt"
FIX_LOG="$SCRIPT_DIR/fix-results.txt"
MAX_FIX_ITERATIONS=3

echo "Running comprehensive code review..."
echo ""

# Get all modified/created files
modified_files=$(git diff --name-only HEAD 2>/dev/null || echo "")
staged_files=$(git diff --name-only --cached 2>/dev/null || echo "")
untracked_files=$(git ls-files --others --exclude-standard 2>/dev/null || echo "")

all_files="$modified_files $staged_files $untracked_files"

if [[ -z "$all_files" ]]; then
    echo -e "${YELLOW}⚠ No new or modified files found to review.${NC}"
else
    # Build file list for Claude
    file_refs="@$PRD_FILE @$PROGRESS_FILE"
    for file in $all_files; do
        if [[ -f "$file" ]] && [[ "$file" != "$REVIEW_LOG" ]] && [[ "$file" != "$FIX_LOG" ]]; then
            file_refs="$file_refs @$file"
        fi
    done

    # Run review-and-fix loop
    for ((fix_iter=1; fix_iter<=MAX_FIX_ITERATIONS; fix_iter++)); do
        echo -e "${YELLOW}Review iteration $fix_iter/$MAX_FIX_ITERATIONS${NC}"
        echo ""

        # Run code review
        # Load code review prompt from template
        review_prompt=$(ralph_load_template "code-review-prompt.md" "PRD_FILE=$PRD_FILE" "PROGRESS_FILE=$PROGRESS_FILE")

        review_output=$(claude --dangerously-skip-permissions "$file_refs

$review_prompt")

        # Save review output
        echo "$review_output" > "$REVIEW_LOG"

        # Check if no issues found
        if echo "$review_output" | grep -q "<promise>NO_ISSUES</promise>"; then
            echo -e "${GREEN}✓ Code review passed! No issues found.${NC}"
            break
        fi

        echo "Issues found. Review summary:"
        echo "----------------------------------------"
        echo "$review_output" | head -30
        echo "----------------------------------------"
        echo ""
        echo "Full review saved to: $REVIEW_LOG"
        echo ""

        # Auto-fix issues
        echo -e "${CYAN}Applying fixes automatically...${NC}"
        echo ""

        # Load fix prompt from template
        fix_prompt=$(ralph_load_template "fix-prompt.md" "REVIEW_LOG=$REVIEW_LOG")

        fix_output=$(claude --dangerously-skip-permissions "$file_refs @$REVIEW_LOG

$fix_prompt")

        echo "$fix_output" > "$FIX_LOG"
        echo "Fix summary:"
        echo "----------------------------------------"
        echo "$fix_output" | head -20
        echo "----------------------------------------"
        echo ""
        echo "Full fix log saved to: $FIX_LOG"
        echo ""

        # Check if fixes are complete
        if echo "$fix_output" | grep -q "<promise>FIXES_COMPLETE</promise>"; then
            echo -e "${GREEN}✓ All fixes applied successfully!${NC}"
            # Continue to next review iteration to verify
        fi

        # If this is the last iteration, warn
        if [[ $fix_iter -eq $MAX_FIX_ITERATIONS ]]; then
            echo -e "${YELLOW}⚠ Reached maximum fix iterations ($MAX_FIX_ITERATIONS)${NC}"
            echo "Some issues may still remain. Review manually if needed."
        fi

        echo ""
    done
fi

# Step 7: Run validation checks
echo ""
echo -e "${CYAN}🧪 Step 7: Running Validation Checks${NC}"
echo "==========================================="
echo ""

validation_passed=true

# Run shellcheck if available
if command -v shellcheck &> /dev/null; then
    echo "Running shellcheck on bash scripts..."
    shellcheck_errors=0
    for file in *.sh; do
        if [[ -f "$file" ]]; then
            if shellcheck "$file" 2>/dev/null; then
                echo -e "  ${GREEN}✓${NC} $file"
            else
                echo -e "  ${RED}✗${NC} $file"
                shellcheck_errors=$((shellcheck_errors + 1))
                validation_passed=false
            fi
        fi
    done
    if [[ $shellcheck_errors -gt 0 ]]; then
        echo -e "${YELLOW}⚠ $shellcheck_errors shellcheck error(s) found${NC}"
    fi
    echo ""
fi

# Syntax check for common file types
echo "Running syntax checks..."
for file in $all_files; do
    if [[ -f "$file" ]]; then
        case "$file" in
            *.sh)
                if bash -n "$file" 2>/dev/null; then
                    echo -e "  ${GREEN}✓${NC} $file (bash syntax)"
                else
                    echo -e "  ${RED}✗${NC} $file (bash syntax error)"
                    validation_passed=false
                fi
                ;;
            *.py)
                if command -v python3 &> /dev/null; then
                    if python3 -m py_compile "$file" 2>/dev/null; then
                        echo -e "  ${GREEN}✓${NC} $file (python syntax)"
                    else
                        echo -e "  ${RED}✗${NC} $file (python syntax error)"
                        validation_passed=false
                    fi
                fi
                ;;
            *.js)
                if command -v node &> /dev/null; then
                    if node --check "$file" 2>/dev/null; then
                        echo -e "  ${GREEN}✓${NC} $file (javascript syntax)"
                    else
                        echo -e "  ${RED}✗${NC} $file (javascript syntax error)"
                        validation_passed=false
                    fi
                fi
                ;;
        esac
    fi
done
echo ""

# Step 8: Final summary
echo ""
echo -e "${CYAN}📊 Final Summary${NC}"
echo "==========================================="
echo ""

if [[ "$validation_passed" == "true" ]]; then
    echo -e "${GREEN}✓ All validation checks passed!${NC}"
else
    echo -e "${YELLOW}⚠ Some validation checks failed. Review the output above.${NC}"
fi

echo ""
echo "Files created/modified:"
git status --short 2>/dev/null || ls -lt | head -10
echo ""

echo -e "${CYAN}Next Steps:${NC}"
echo "  1. Review the implementation:"
echo "     cat ralph/PRD.md"
echo "     cat ralph/progress.txt"
echo ""
echo "  2. Review code changes:"
echo "     git diff"
echo ""
echo "  3. Test your implementation manually"
echo ""
echo "  4. Review the code review results:"
echo "     cat ralph/review-results.txt"
echo ""
echo "  5. When satisfied, commit your changes:"
echo "     git add ."
echo "     git commit -m 'feat: implement [your feature]'"
echo ""
echo -e "${GREEN}✓ Ralph workflow complete!${NC}"
echo ""
