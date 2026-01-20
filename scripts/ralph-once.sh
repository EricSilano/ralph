#!/bin/bash

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

# Load ralph-once prompt from template
once_prompt=$(ralph_load_template "ralph-once-prompt.md" "PRD_FILE=$PRD_FILE" "PROGRESS_FILE=$PROGRESS_FILE")

IS_SANDBOX=1 claude --dangerously-skip-permissions "@$PRD_FILE @$PROGRESS_FILE

$once_prompt"