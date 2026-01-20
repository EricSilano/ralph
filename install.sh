#!/bin/bash
set -e

RALPH_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="${1:-./ralph}"

echo "📦 Installing Ralph to $INSTALL_DIR..."
echo ""

# Create ralph directory
mkdir -p "$INSTALL_DIR"

# Copy core scripts
echo "Copying core scripts..."
cp "$RALPH_DIR/ralph-start.sh" "$INSTALL_DIR/"
cp "$RALPH_DIR/ralph-once.sh" "$INSTALL_DIR/"
cp "$RALPH_DIR/ralph-afk.sh" "$INSTALL_DIR/"
cp "$RALPH_DIR/ralph-lib.sh" "$INSTALL_DIR/"

# Copy review scripts
echo "Copying review scripts..."
cp "$RALPH_DIR/ralph-review.sh" "$INSTALL_DIR/"
cp "$RALPH_DIR/ralph-review-file.sh" "$INSTALL_DIR/"
cp "$RALPH_DIR/ralph-review-diff.sh" "$INSTALL_DIR/"
cp "$RALPH_DIR/ralph-review-and-fix.sh" "$INSTALL_DIR/"
cp "$RALPH_DIR/ralph-review-prd.sh" "$INSTALL_DIR/"

# Copy guidelines if exists
if [[ -f "$RALPH_DIR/GUIDELINES.md" ]]; then
    echo "Copying guidelines..."
    cp "$RALPH_DIR/GUIDELINES.md" "$INSTALL_DIR/"
fi

# Copy templates directory if exists
if [[ -d "$RALPH_DIR/templates" ]]; then
    echo "Copying templates..."
    cp -r "$RALPH_DIR/templates" "$INSTALL_DIR/"
fi

# Make all scripts executable
echo "Making scripts executable..."
chmod +x "$INSTALL_DIR"/*.sh

# Create initial files if they don't exist
if [[ ! -f "$INSTALL_DIR/PRD.md" ]]; then
    touch "$INSTALL_DIR/PRD.md"
fi
if [[ ! -f "$INSTALL_DIR/progress.txt" ]]; then
    touch "$INSTALL_DIR/progress.txt"
fi

# Create logs directory
mkdir -p "$INSTALL_DIR/logs"

# Create .gitignore for Ralph directory
cat > "$INSTALL_DIR/.gitignore" <<'EOF'
# Ralph temporary files
review-results.txt
fix-results.txt
prd-review.txt
.ralph-status.json
.ralph-state.json
ralph-summary.txt
progress-archive.txt

# Log files
logs/
*.log

# Backup files
*.bak
*~
EOF

echo ""
echo "✓ Ralph installed successfully to: $INSTALL_DIR"
echo ""
echo "📦 Core Scripts:"
echo "  ✓ ralph-start.sh       - Interactive setup & full workflow"
echo "  ✓ ralph-once.sh        - Run single task"
echo "  ✓ ralph-afk.sh         - Run multiple iterations"
echo "  ✓ ralph-lib.sh         - Shared utility library"
echo ""
echo "🔍 Review Scripts:"
echo "  ✓ ralph-review.sh           - Quick review of modified files"
echo "  ✓ ralph-review-file.sh      - Review specific files"
echo "  ✓ ralph-review-diff.sh      - Review git diff"
echo "  ✓ ralph-review-and-fix.sh   - Auto review & fix loop"
echo "  ✓ ralph-review-prd.sh       - PRD implementation review"
echo ""
echo "📁 Additional Files:"
if [[ -f "$INSTALL_DIR/GUIDELINES.md" ]]; then
    echo "  ✓ GUIDELINES.md        - Coding standards"
fi
if [[ -d "$INSTALL_DIR/templates" ]]; then
    echo "  ✓ templates/           - Code templates"
fi
echo "  ✓ PRD.md               - Product requirements"
echo "  ✓ progress.txt         - Progress tracking"
echo "  ✓ logs/                - Structured logs"
echo "  ✓ .gitignore           - Git ignore rules"
echo ""
echo "🚀 Quick Start:"
echo "  # From project root:"
echo "  ./$INSTALL_DIR/ralph-start.sh"
echo ""
echo "  # Or from inside ralph directory:"
echo "  cd $INSTALL_DIR && ./ralph-start.sh"
echo ""
echo "📚 Usage Examples (from project root):"
echo "  ./$INSTALL_DIR/ralph-start.sh                    # Full interactive workflow"
echo "  ./$INSTALL_DIR/ralph-once.sh                     # Single task execution"
echo "  ./$INSTALL_DIR/ralph-afk.sh 10                   # Run 10 iterations"
echo "  ./$INSTALL_DIR/ralph-review.sh                   # Quick code review"
echo "  ./$INSTALL_DIR/ralph-review-file.sh src/main.js  # Review specific file"
echo "  ./$INSTALL_DIR/ralph-review-and-fix.sh 5         # Review & fix with 5 iterations"
echo ""
echo "💡 Tip: Ralph works in your project root but keeps files in $INSTALL_DIR/"
echo "    All commands can be run from either location."
echo ""
