#!/bin/bash
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

# Source ralph library for logging
if [[ -f "$SCRIPT_DIR/ralph-lib.sh" ]]; then
    source "$SCRIPT_DIR/ralph-lib.sh"
    ralph_setup_logging
fi

PRD_FILE="$PROJECT_ROOT/PRD.md"
PROGRESS_FILE="$PROJECT_ROOT/progress.txt"

if [ -z "$1" ]; then
  echo "Usage: $0 <iterations>"
  exit 1
fi

# Load ralph-afk prompt from template
afk_prompt=$(ralph_load_template "ralph-afk-prompt.md" "PRD_FILE=$PRD_FILE" "PROGRESS_FILE=$PROGRESS_FILE")

for ((i=1; i<=$1; i++)); do
  result=$(claude --dangerously-skip-permissions -p "@$PRD_FILE @$PROGRESS_FILE

$afk_prompt")

  echo "$result"

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "PRD complete after $i iterations."
    exit 0
  fi
done