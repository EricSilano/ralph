#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

# Get script directory, ralph folder, and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$RALPH_DIR/.." && pwd)"

# Work in project root for git operations
cd "$PROJECT_ROOT"

# Set up logging environment (logs and state files are in ralph folder)
export RALPH_LOG_DIR="$RALPH_DIR/logs"
export RALPH_STATUS_FILE="$RALPH_DIR/.ralph-status.json"
export RALPH_STATE_FILE="$RALPH_DIR/.ralph-state.json"
export RALPH_PROMPTS_DIR="$RALPH_DIR/prompts"

# Create logs directory if it doesn't exist
mkdir -p "$RALPH_LOG_DIR"

# AFK-specific log file
AFK_LOG="$RALPH_LOG_DIR/ralph-afk.log"

# Source ralph library for logging
if [[ -f "$SCRIPT_DIR/ralph-lib.sh" ]]; then
    source "$SCRIPT_DIR/ralph-lib.sh"
    ralph_setup_logging
fi

# PRD.md and progress.txt are always inside the ralph folder (not project root)
PRD_FILE="$RALPH_DIR/PRD.md"
PROGRESS_FILE="$RALPH_DIR/progress.txt"
AFK_PROMPT="$RALPH_DIR/prompts/ralph-afk-prompt.md"

if [ -z "$1" ]; then
  echo "Usage: $0 <iterations>"
  exit 1
fi

# Log startup info
echo "" >> "$AFK_LOG"
echo "========================================" >> "$AFK_LOG"
echo "AFK Session Started: $(date)" >> "$AFK_LOG"
echo "========================================" >> "$AFK_LOG"

echo -e "${CYAN}Ralph AFK Mode${NC}"
echo "========================================"
echo ""

# Debug: Show paths and verify files exist
echo -e "${DIM}Configuration:${NC}"
echo -e "  Working directory: ${CYAN}$(pwd)${NC}"
echo -e "  RALPH_DIR:         ${CYAN}$RALPH_DIR${NC}"
echo -e "  PROJECT_ROOT:      ${CYAN}$PROJECT_ROOT${NC}"
echo ""

echo -e "${DIM}Input files:${NC}"

# Check PRD file
if [[ -f "$PRD_FILE" ]]; then
    prd_lines=$(wc -l < "$PRD_FILE")
    echo -e "  PRD_FILE:     ${GREEN}EXISTS${NC} ($prd_lines lines) - $PRD_FILE"
else
    echo -e "  PRD_FILE:     ${RED}MISSING${NC} - $PRD_FILE"
    echo "ERROR: PRD file not found!" >> "$AFK_LOG"
    exit 1
fi

# Check progress file
if [[ -f "$PROGRESS_FILE" ]]; then
    progress_lines=$(wc -l < "$PROGRESS_FILE")
    echo -e "  PROGRESS:     ${GREEN}EXISTS${NC} ($progress_lines lines) - $PROGRESS_FILE"
else
    echo -e "  PROGRESS:     ${YELLOW}MISSING${NC} (will be created) - $PROGRESS_FILE"
    echo "# Progress Log" > "$PROGRESS_FILE"
    echo "" >> "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
fi

# Check prompt file
if [[ -f "$AFK_PROMPT" ]]; then
    prompt_lines=$(wc -l < "$AFK_PROMPT")
    echo -e "  AFK_PROMPT:   ${GREEN}EXISTS${NC} ($prompt_lines lines) - $AFK_PROMPT"
    echo "" >> "$AFK_LOG"
    echo "Prompt file contents:" >> "$AFK_LOG"
    cat "$AFK_PROMPT" >> "$AFK_LOG"
    echo "" >> "$AFK_LOG"
else
    echo -e "  AFK_PROMPT:   ${RED}MISSING${NC} - $AFK_PROMPT"
    echo "ERROR: AFK prompt file not found!" >> "$AFK_LOG"
    exit 1
fi

echo ""
echo -e "${DIM}Log file: $AFK_LOG${NC}"
echo ""
echo "========================================"
echo ""

for ((i=1; i<=$1; i++)); do
  echo -e "${YELLOW}Iteration $i/$1${NC}"
  echo "----------------------------------------"

  # Log iteration start
  echo "" >> "$AFK_LOG"
  echo "--- Iteration $i/$1 started at $(date) ---" >> "$AFK_LOG"

  # Read file contents
  prd_content=$(cat "$PRD_FILE")
  progress_content=$(cat "$PROGRESS_FILE")
  prompt_content=$(cat "$AFK_PROMPT")

  # Build the full prompt
  full_prompt="$prompt_content"

  # Show the command being run
  echo -e "${DIM}Running: claude --dangerously-skip-permissions \"\$full_prompt\"${NC}"
  echo "Command: claude --dangerously-skip-permissions \"\$full_prompt\"" >> "$AFK_LOG"
  echo "Full prompt content:" >> "$AFK_LOG"
  echo "$full_prompt" >> "$AFK_LOG"

  # Call claude with combined prompt - pass as direct string like gen-prd.sh
  # Capture both stdout and stderr, and track exit code
  set +e
  result=$(claude --dangerously-skip-permissions "$full_prompt" 2>&1)
  exit_code=$?
  set -e

  # Log results
  result_length=${#result}
  echo "Exit code: $exit_code" >> "$AFK_LOG"
  echo "Result length: $result_length chars" >> "$AFK_LOG"
  echo "Result (first 2000 chars):" >> "$AFK_LOG"
  echo "${result:0:2000}" >> "$AFK_LOG"
  echo "" >> "$AFK_LOG"

  # Show summary
  echo ""
  echo -e "  Exit code:     ${exit_code}"
  echo -e "  Output length: ${result_length} chars"

  if [[ $exit_code -ne 0 ]]; then
    echo -e "  ${RED}Claude exited with error code $exit_code${NC}"
    echo ""
    echo -e "${DIM}First 500 chars of output:${NC}"
    echo "${result:0:500}"
    echo ""
  fi

  # Check for empty result
  if [[ -z "$result" ]] || [[ $result_length -lt 50 ]]; then
    echo -e "  ${RED}WARNING: Result is empty or very short!${NC}"
    echo "  This may indicate the prompt was not processed correctly."
    echo ""
    echo -e "${DIM}Full output:${NC}"
    echo "$result"
    echo ""
  fi

  # Check for completion marker
  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo ""
    echo -e "${GREEN}PRD complete after $i iterations.${NC}"
    echo "PRD marked COMPLETE at $(date)" >> "$AFK_LOG"
    exit 0
  fi

  echo -e "  ${GREEN}Iteration $i complete${NC}"
  echo "--- Iteration $i completed at $(date) ---" >> "$AFK_LOG"
  echo ""
done

echo ""
echo -e "${CYAN}All $1 iterations complete.${NC}"
echo "Check $AFK_LOG for detailed logs."
echo ""