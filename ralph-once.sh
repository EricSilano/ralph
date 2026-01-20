#!/bin/bash

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

IS_SANDBOX=1 claude --dangerously-skip-permissions "@$PRD_FILE @$PROGRESS_FILE \
1. Read the PRD and progress file. \
2. Find the next incomplete task and implement it. \
3. Update progress.txt with what you did. \
ONLY DO ONE TASK AT A TIME."