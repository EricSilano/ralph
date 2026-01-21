#!/bin/bash
set -e

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Work in project root
cd "$PROJECT_ROOT"

# Set up logging environment
export RALPH_LOG_DIR="$SCRIPT_DIR/logs"
export RALPH_PROMPTS_DIR="$SCRIPT_DIR/prompts"

# Source ralph library for template loading
if [[ -f "$SCRIPT_DIR/scripts/ralph-lib.sh" ]]; then
    source "$SCRIPT_DIR/scripts/ralph-lib.sh"
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

# Create architecture documentation
echo "Generating ARCHITECTURE.md..."

# Load architecture analysis prompt from template
arch_prompt=$(ralph_load_template "architecture-analysis-prompt.md")

if [[ -z "$arch_prompt" ]]; then
    echo -e "${RED}✗ Failed to load architecture analysis prompt template${NC}"
    exit 1
fi

ralph_info "Analyzing codebase architecture (this may take a minute)..."
ralph_claude --capture --label "architecture" \
    --dangerously-skip-permissions "$arch_prompt" > "$CONTEXT_DIR/ARCHITECTURE.md"

if [[ -f "$CONTEXT_DIR/ARCHITECTURE.md" ]] && [[ -s "$CONTEXT_DIR/ARCHITECTURE.md" ]]; then
    echo -e "${GREEN}✓ ARCHITECTURE.md created${NC}"
else
    echo -e "${RED}✗ Failed to create ARCHITECTURE.md${NC}"
fi
echo ""

echo -e "${YELLOW}Step 2: Extracting business rules...${NC}"
echo ""

# Create business rules documentation
echo "Generating BUSINESS_RULES.md..."

# Load business rules analysis prompt from template
business_prompt=$(ralph_load_template "business-rules-analysis-prompt.md")

if [[ -z "$business_prompt" ]]; then
    echo -e "${RED}✗ Failed to load business rules analysis prompt template${NC}"
    exit 1
fi

ralph_info "Extracting business rules and domain logic..."
ralph_claude --capture --label "business-rules" \
    --dangerously-skip-permissions "$business_prompt" > "$CONTEXT_DIR/BUSINESS_RULES.md"

if [[ -f "$CONTEXT_DIR/BUSINESS_RULES.md" ]] && [[ -s "$CONTEXT_DIR/BUSINESS_RULES.md" ]]; then
    echo -e "${GREEN}✓ BUSINESS_RULES.md created${NC}"
else
    echo -e "${RED}✗ Failed to create BUSINESS_RULES.md${NC}"
fi
echo ""

echo -e "${YELLOW}Step 3: Creating general context...${NC}"
echo ""

# Create general documentation
echo "Generating GENERAL.md..."

# Load general context prompt from template
general_prompt=$(ralph_load_template "general-context-prompt.md")

if [[ -z "$general_prompt" ]]; then
    echo -e "${RED}✗ Failed to load general context prompt template${NC}"
    exit 1
fi

ralph_info "Creating general project context documentation..."
ralph_claude --capture --label "general-context" \
    --dangerously-skip-permissions "$general_prompt" > "$CONTEXT_DIR/GENERAL.md"

if [[ -f "$CONTEXT_DIR/GENERAL.md" ]] && [[ -s "$CONTEXT_DIR/GENERAL.md" ]]; then
    echo -e "${GREEN}✓ GENERAL.md created${NC}"
else
    echo -e "${RED}✗ Failed to create GENERAL.md${NC}"
fi
echo ""

echo -e "${YELLOW}Step 4: Generating context index (CLAUDE.md)...${NC}"
echo ""

# Create CLAUDE.md index file
echo "Generating CLAUDE.md..."

# Build context files content
context_content="$(cat "$CONTEXT_DIR/ARCHITECTURE.md" 2>/dev/null || echo "Not available")

---

$(cat "$CONTEXT_DIR/BUSINESS_RULES.md" 2>/dev/null || echo "Not available")

---

$(cat "$CONTEXT_DIR/GENERAL.md" 2>/dev/null || echo "Not available")"

# Load context index prompt from template
index_prompt=$(ralph_load_template "context-index-prompt.md" "PROJECT_NAME=$PROJECT_NAME" "CONTEXT_FILES_CONTENT=$context_content")

if [[ -z "$index_prompt" ]]; then
    echo -e "${RED}✗ Failed to load context index prompt template${NC}"
    exit 1
fi

ralph_info "Generating context documentation index..."
echo "$index_prompt" | ralph_claude --capture --label "context-index" \
    --dangerously-skip-permissions > "$CONTEXT_DIR/CLAUDE.md"

if [[ -f "$CONTEXT_DIR/CLAUDE.md" ]] && [[ -s "$CONTEXT_DIR/CLAUDE.md" ]]; then
    echo -e "${GREEN}✓ CLAUDE.md created${NC}"
else
    echo -e "${RED}✗ Failed to create CLAUDE.md${NC}"
fi
echo ""

# Create .gitignore for context directory
cat > "$CONTEXT_DIR/.gitignore" <<'EOF'
# Context files are generated, not committed
*.md
EOF

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
