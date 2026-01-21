#!/bin/bash
set -e

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$RALPH_ROOT/.." && pwd)"

# Work in project root
cd "$PROJECT_ROOT"

# Set up logging environment
export RALPH_LOG_DIR="$RALPH_ROOT/logs"
export RALPH_PROMPTS_DIR="$RALPH_ROOT/prompts"

# Source ralph library for logging
if [[ -f "$SCRIPT_DIR/ralph-lib.sh" ]]; then
    source "$SCRIPT_DIR/ralph-lib.sh"
    ralph_setup_logging
else
    echo "Error: ralph-lib.sh not found. Please ensure Ralph is properly installed."
    exit 1
fi

# Colors for better UX
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}📖 Ralph Pre-Start - Context Documentation Generator${NC}"
echo "==========================================="
echo ""

# Create context directory
CONTEXT_DIR="$PROJECT_ROOT/context"
mkdir -p "$CONTEXT_DIR"

echo "Context files will be saved to: $CONTEXT_DIR"
echo ""

# Get project name
PROJECT_NAME=$(basename "$PROJECT_ROOT")

echo -e "${YELLOW}Step 1: Analyzing codebase architecture...${NC}"
echo ""

echo "Generating ARCHITECTURE.md..."
ralph_info "Analyzing codebase architecture (this may take a minute)..."

claude --dangerously-skip-permissions "@$RALPH_PROMPTS_DIR/architecture-analysis-prompt.md" > "$CONTEXT_DIR/ARCHITECTURE.md" 2>&1

if [[ -f "$CONTEXT_DIR/ARCHITECTURE.md" ]] && [[ -s "$CONTEXT_DIR/ARCHITECTURE.md" ]]; then
    echo -e "${GREEN}✓ ARCHITECTURE.md created${NC}"
else
    echo -e "${RED}✗ Failed to create ARCHITECTURE.md${NC}"
fi
echo ""

echo -e "${YELLOW}Step 2: Extracting business rules...${NC}"
echo ""

echo "Generating BUSINESS_RULES.md..."
ralph_info "Extracting business rules and domain logic..."

claude --dangerously-skip-permissions "@$RALPH_PROMPTS_DIR/business-rules-analysis-prompt.md" > "$CONTEXT_DIR/BUSINESS_RULES.md" 2>&1

if [[ -f "$CONTEXT_DIR/BUSINESS_RULES.md" ]] && [[ -s "$CONTEXT_DIR/BUSINESS_RULES.md" ]]; then
    echo -e "${GREEN}✓ BUSINESS_RULES.md created${NC}"
else
    echo -e "${RED}✗ Failed to create BUSINESS_RULES.md${NC}"
fi
echo ""

echo -e "${YELLOW}Step 3: Creating general context...${NC}"
echo ""

echo "Generating GENERAL.md..."
ralph_info "Creating general project context documentation..."

claude --dangerously-skip-permissions "@$RALPH_PROMPTS_DIR/general-context-prompt.md" > "$CONTEXT_DIR/GENERAL.md" 2>&1

if [[ -f "$CONTEXT_DIR/GENERAL.md" ]] && [[ -s "$CONTEXT_DIR/GENERAL.md" ]]; then
    echo -e "${GREEN}✓ GENERAL.md created${NC}"
else
    echo -e "${RED}✗ Failed to create GENERAL.md${NC}"
fi
echo ""

echo -e "${YELLOW}Step 4: Generating context index (CLAUDE.md)...${NC}"
echo ""

echo "Generating CLAUDE.md..."
ralph_info "Generating context documentation index..."

# For the index, we need to pass the context files as references
claude --dangerously-skip-permissions \
    "@$CONTEXT_DIR/ARCHITECTURE.md" \
    "@$CONTEXT_DIR/BUSINESS_RULES.md" \
    "@$CONTEXT_DIR/GENERAL.md" \
    "@$RALPH_PROMPTS_DIR/context-index-prompt.md" > "$CONTEXT_DIR/CLAUDE.md" 2>&1

if [[ -f "$CONTEXT_DIR/CLAUDE.md" ]] && [[ -s "$CONTEXT_DIR/CLAUDE.md" ]]; then
    echo -e "${GREEN}✓ CLAUDE.md created${NC}"
else
    echo -e "${RED}✗ Failed to create CLAUDE.md${NC}"
fi
echo ""

echo ""
echo -e "${GREEN}✓ Context documentation generated successfully!${NC}"
echo ""
echo "📚 Generated Files:"
echo "  ✓ $CONTEXT_DIR/CLAUDE.md          - Index and guide"
echo "  ✓ $CONTEXT_DIR/ARCHITECTURE.md    - System architecture"
echo "  ✓ $CONTEXT_DIR/BUSINESS_RULES.md  - Business logic and rules"
echo "  ✓ $CONTEXT_DIR/GENERAL.md         - General context"
echo ""
echo "💡 Usage:"
echo "  Start with CLAUDE.md to understand what each file contains."
echo "  Reference these files when running Ralph or working on the codebase."
echo ""
echo "🔄 To regenerate context:"
echo "  Run this script again: ./ralph/scripts/ralph-prestart.sh"
echo ""
