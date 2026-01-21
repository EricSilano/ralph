#!/bin/bash
set -e

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

for ((i=1; i<=$1; i++)); do
  ralph_info "Starting iteration $i/$1..."

  # Call claude with prompt file - NO -p flag because we need Claude to execute tools
  result=$(claude --dangerously-skip-permissions "@$PRD_FILE" "@$PROGRESS_FILE" "@$AFK_PROMPT" 2>&1)

  # Check for completion marker
  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo ""
    echo "PRD complete after $i iterations."
    exit 0
  fi

  ralph_info "Iteration $i complete"
  echo ""
done