#!/bin/bash
set -e

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Work in project root
cd "$PROJECT_ROOT"

# Set up logging environment
export RALPH_LOG_DIR="$PROJECT_ROOT/logs"
export RALPH_STATUS_FILE="$PROJECT_ROOT/.ralph-status.json"
export RALPH_STATE_FILE="$PROJECT_ROOT/.ralph-state.json"
export RALPH_PROMPTS_DIR="$PROJECT_ROOT/prompts"

# Source ralph library for logging
if [[ -f "$SCRIPT_DIR/ralph-lib.sh" ]]; then
    source "$SCRIPT_DIR/ralph-lib.sh"
    ralph_setup_logging
fi

ralph_info "Starting context documentation generation..."

# Output files
CONTEXT_DIR="$PROJECT_ROOT/context"
ARCH_FILE="$CONTEXT_DIR/ARCHITECTURE.md"
RULES_FILE="$CONTEXT_DIR/BUSINESS_RULES.md"
GENERAL_FILE="$CONTEXT_DIR/GENERAL.md"
INDEX_FILE="$CONTEXT_DIR/CLAUDE.md"

# Load prompts
arch_prompt=$(ralph_load_template "architecture-analysis-prompt.md")
rules_prompt=$(ralph_load_template "business-rules-analysis-prompt.md")
general_prompt=$(ralph_load_template "general-context-prompt.md")

# Create context directory if it doesn't exist
mkdir -p "$CONTEXT_DIR"

# Run 3 claude instances in parallel (capture output to avoid interactive prompts)
ralph_info "Generating context/ARCHITECTURE.md..."
(result1=$(claude --dangerously-skip-permissions "$arch_prompt" 2>&1)) &
pid1=$!

ralph_info "Generating context/BUSINESS_RULES.md..."
(result2=$(claude --dangerously-skip-permissions "$rules_prompt" 2>&1)) &
pid2=$!

ralph_info "Generating context/GENERAL.md..."
(result3=$(claude --dangerously-skip-permissions "$general_prompt" 2>&1)) &
pid3=$!

# Wait for all to complete
ralph_info "Waiting for analysis to complete..."
wait $pid1 $pid2 $pid3

ralph_info "All analysis complete"

# Check if files were created successfully
if [[ ! -f "$ARCH_FILE" ]] || [[ ! -f "$RULES_FILE" ]] || [[ ! -f "$GENERAL_FILE" ]]; then
    ralph_error "One or more context files failed to generate"
    exit 1
fi

# Load context-index prompt
index_prompt=$(ralph_load_template "context-index-prompt.md")

# Generate CLAUDE.md index file
ralph_info "Generating context/CLAUDE.md index..."
result=$(claude --dangerously-skip-permissions "@$ARCH_FILE" "@$RULES_FILE" "@$GENERAL_FILE" "$index_prompt" 2>&1)

if [[ -f "$INDEX_FILE" ]]; then
    ralph_info "Context documentation complete!"
    echo ""
    echo "Generated files:"
    echo "  - $ARCH_FILE"
    echo "  - $RULES_FILE"
    echo "  - $GENERAL_FILE"
    echo "  - $INDEX_FILE"
else
    ralph_error "Failed to generate CLAUDE.md"
    exit 1
fi
