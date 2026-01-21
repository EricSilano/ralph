#!/bin/bash
set -e

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$RALPH_DIR/.." && pwd)"

# Work in project root
cd "$PROJECT_ROOT"

# Set up logging environment
export RALPH_LOG_DIR="$RALPH_DIR/logs"
export RALPH_STATUS_FILE="$RALPH_DIR/.ralph-status.json"
export RALPH_STATE_FILE="$RALPH_DIR/.ralph-state.json"
export RALPH_PROMPTS_DIR="$RALPH_DIR/prompts"

# Source ralph library for logging
if [[ -f "$RALPH_DIR/scripts/ralph-lib.sh" ]]; then
    source "$RALPH_DIR/scripts/ralph-lib.sh"
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

# Run 3 claude instances in parallel using -p (print mode) for non-interactive execution
ralph_info "Generating context files in parallel..."
ralph_info "  - ARCHITECTURE.md"
ralph_info "  - BUSINESS_RULES.md"
ralph_info "  - GENERAL.md"

claude -p --dangerously-skip-permissions "$arch_prompt" > /dev/null 2>&1 &
pid1=$!

claude -p --dangerously-skip-permissions "$rules_prompt" > /dev/null 2>&1 &
pid2=$!

claude -p --dangerously-skip-permissions "$general_prompt" > /dev/null 2>&1 &
pid3=$!

# Wait for all 3 to complete
ralph_info "Waiting for all analyses to complete..."
wait $pid1 $pid2 $pid3

# Check results
[[ -f "$ARCH_FILE" ]] && ralph_info "✓ ARCHITECTURE.md created" || ralph_warn "✗ ARCHITECTURE.md not found"
[[ -f "$RULES_FILE" ]] && ralph_info "✓ BUSINESS_RULES.md created" || ralph_warn "✗ BUSINESS_RULES.md not found"
[[ -f "$GENERAL_FILE" ]] && ralph_info "✓ GENERAL.md created" || ralph_warn "✗ GENERAL.md not found"

ralph_info "All analysis complete"

# Check if files were created successfully
if [[ ! -f "$ARCH_FILE" ]] || [[ ! -f "$RULES_FILE" ]] || [[ ! -f "$GENERAL_FILE" ]]; then
    ralph_error "One or more context files failed to generate"
    ralph_error "Expected files:"
    ralph_error "  - $ARCH_FILE"
    ralph_error "  - $RULES_FILE"
    ralph_error "  - $GENERAL_FILE"
    exit 1
fi

# Load context-index prompt
index_prompt=$(ralph_load_template "context-index-prompt.md")

# Generate CLAUDE.md index file
ralph_info "Generating context/CLAUDE.md index..."
claude -p --dangerously-skip-permissions "@$ARCH_FILE" "@$RULES_FILE" "@$GENERAL_FILE" "$index_prompt" > /dev/null 2>&1

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
