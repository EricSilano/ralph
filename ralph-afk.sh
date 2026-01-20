#!/bin/bash
set -e

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Work in project root for git operations
cd "$PROJECT_ROOT"

# Set up logging environment
export RALPH_LOG_DIR="$SCRIPT_DIR/logs"
export RALPH_STATUS_FILE="$SCRIPT_DIR/.ralph-status.json"
export RALPH_STATE_FILE="$SCRIPT_DIR/.ralph-state.json"

PRD_FILE="$SCRIPT_DIR/PRD.md"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"

if [ -z "$1" ]; then
  echo "Usage: $0 <iterations>"
  exit 1
fi

for ((i=1; i<=$1; i++)); do
  result=$(claude --dangerously-skip-permissions -p "@$PRD_FILE @$PROGRESS_FILE \
  1. Find the highest-priority task and implement it. \
  2. Run your tests and type checks using ruff or make test commands. \
  3. Update the PRD with what was done. \
  4. Append your progress to progress.txt. \
  5. All environment variables should be set in the secrets.env file.
  6. Always check of files on context or documentations folders.
  7. Use mcp if available to check data structures and types.
  ONLY WORK ON A SINGLE TASK. \
  If the PRD is complete, output <promise>COMPLETE</promise>.")

  echo "$result"

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "PRD complete after $i iterations."
    exit 0
  fi
done