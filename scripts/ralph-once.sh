#!/bin/bash

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

# Load ralph-once prompt from template
once_prompt=$(ralph_load_template "ralph-once-prompt.md" "PRD_FILE=$PRD_FILE" "PROGRESS_FILE=$PROGRESS_FILE")

# Read file contents
prd_content=$(cat "$PRD_FILE")
progress_content=$(cat "$PROGRESS_FILE")

full_prompt="=== PRD ===
$prd_content

=== PROGRESS ===
$progress_content

=== INSTRUCTIONS ===
$once_prompt"

IS_SANDBOX=1 claude --model "$RALPH_MODEL" --dangerously-skip-permissions "$full_prompt"