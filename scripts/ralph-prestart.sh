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

# Prompt files
ARCH_PROMPT="$RALPH_DIR/prompts/architecture-analysis-prompt.md"
RULES_PROMPT="$RALPH_DIR/prompts/business-rules-analysis-prompt.md"
GENERAL_PROMPT="$RALPH_DIR/prompts/general-context-prompt.md"
INDEX_PROMPT="$RALPH_DIR/prompts/context-index-prompt.md"

# Create context directory if it doesn't exist
mkdir -p "$CONTEXT_DIR"

# Track what needs to be generated
need_arch=false
need_rules=false
need_general=false
pids=()

# Check which files need to be generated and run in parallel
if [[ -f "$ARCH_FILE" ]]; then
    ralph_info "✓ ARCHITECTURE.md already exists, skipping"
else
    ralph_info "Generating context/ARCHITECTURE.md..."
    need_arch=true
    claude --model "$RALPH_MODEL" -p --dangerously-skip-permissions "@$ARCH_PROMPT" > /dev/null 2>&1 &
    pids+=($!)
fi

if [[ -f "$RULES_FILE" ]]; then
    ralph_info "✓ BUSINESS_RULES.md already exists, skipping"
else
    ralph_info "Generating context/BUSINESS_RULES.md..."
    need_rules=true
    claude --model "$RALPH_MODEL" -p --dangerously-skip-permissions "@$RULES_PROMPT" > /dev/null 2>&1 &
    pids+=($!)
fi

if [[ -f "$GENERAL_FILE" ]]; then
    ralph_info "✓ GENERAL.md already exists, skipping"
else
    ralph_info "Generating context/GENERAL.md..."
    need_general=true
    claude --model "$RALPH_MODEL" -p --dangerously-skip-permissions "@$GENERAL_PROMPT" > /dev/null 2>&1 &
    pids+=($!)
fi

# Wait for all parallel jobs to complete (if any)
if [[ ${#pids[@]} -gt 0 ]]; then
    ralph_info "Waiting for ${#pids[@]} generation(s) to complete..."
    wait "${pids[@]}"
fi

# Check results for newly generated files
[[ "$need_arch" == "true" ]] && { [[ -f "$ARCH_FILE" ]] && ralph_info "✓ ARCHITECTURE.md created" || ralph_warn "✗ ARCHITECTURE.md not found"; }
[[ "$need_rules" == "true" ]] && { [[ -f "$RULES_FILE" ]] && ralph_info "✓ BUSINESS_RULES.md created" || ralph_warn "✗ BUSINESS_RULES.md not found"; }
[[ "$need_general" == "true" ]] && { [[ -f "$GENERAL_FILE" ]] && ralph_info "✓ GENERAL.md created" || ralph_warn "✗ GENERAL.md not found"; }

ralph_info "Analysis phase complete"

# Check if all required files exist
if [[ ! -f "$ARCH_FILE" ]] || [[ ! -f "$RULES_FILE" ]] || [[ ! -f "$GENERAL_FILE" ]]; then
    ralph_error "One or more context files failed to generate"
    ralph_error "Expected files:"
    ralph_error "  - $ARCH_FILE"
    ralph_error "  - $RULES_FILE"
    ralph_error "  - $GENERAL_FILE"
    exit 1
fi

# Generate CLAUDE.md index file (only if missing or any source file is newer)
if [[ -f "$INDEX_FILE" ]] && [[ "$INDEX_FILE" -nt "$ARCH_FILE" ]] && [[ "$INDEX_FILE" -nt "$RULES_FILE" ]] && [[ "$INDEX_FILE" -nt "$GENERAL_FILE" ]]; then
    ralph_info "✓ CLAUDE.md already exists and is up to date, skipping"
else
    ralph_info "Generating context/CLAUDE.md index..."
    claude --model "$RALPH_MODEL" -p --dangerously-skip-permissions "@$INDEX_PROMPT" > /dev/null 2>&1

    if [[ -f "$INDEX_FILE" ]]; then
        ralph_info "✓ CLAUDE.md created"
    else
        ralph_error "Failed to generate CLAUDE.md"
        exit 1
    fi
fi

ralph_info "Context documentation complete!"
echo ""
echo "Generated files:"
echo "  - $ARCH_FILE"
echo "  - $RULES_FILE"
echo "  - $GENERAL_FILE"
echo "  - $INDEX_FILE"
