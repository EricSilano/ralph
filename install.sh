#!/bin/bash
set -e

RALPH_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="${1:-./ralph}"

# Pull latest changes from Ralph repository
echo "🔄 Updating Ralph from git..."
if git -C "$RALPH_DIR" pull --quiet; then
    echo "✓ Ralph updated to latest version"
else
    echo "⚠️  Could not update Ralph (offline or not a git repo)"
fi
echo ""

echo "📦 Installing Ralph to $INSTALL_DIR..."
echo ""

# Create ralph directory
mkdir -p "$INSTALL_DIR"

# Copy main entry points
echo "Copying main scripts..."
cp "$RALPH_DIR/ralph-start.sh" "$INSTALL_DIR/"
cp "$RALPH_DIR/setup.sh" "$INSTALL_DIR/"

# Copy scripts directory
echo "Copying scripts directory..."
mkdir -p "$INSTALL_DIR/scripts"
cp "$RALPH_DIR/scripts/"*.sh "$INSTALL_DIR/scripts/"

# Copy guidelines if exists
if [[ -f "$RALPH_DIR/GUIDELINES.md" ]]; then
    echo "Copying guidelines..."
    cp "$RALPH_DIR/GUIDELINES.md" "$INSTALL_DIR/"
fi

# Copy prompts directory (AI prompt templates)
if [[ -d "$RALPH_DIR/prompts" ]]; then
    echo "Copying prompts..."
    cp -r "$RALPH_DIR/prompts" "$INSTALL_DIR/"
fi

# Copy templates directory (code templates)
if [[ -d "$RALPH_DIR/templates" ]]; then
    echo "Copying templates..."
    cp -r "$RALPH_DIR/templates" "$INSTALL_DIR/"
fi

# Make all scripts executable
echo "Making scripts executable..."
chmod +x "$INSTALL_DIR"/*.sh
chmod +x "$INSTALL_DIR/scripts/"*.sh 2>/dev/null || true

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

# Add ralph/ to repository's .gitignore if not already present
echo "Checking repository .gitignore..."
REPO_ROOT="$(cd "$INSTALL_DIR/.." && pwd)"
REPO_GITIGNORE="$REPO_ROOT/.gitignore"

# Determine the relative path entry to add
RALPH_BASENAME="$(basename "$INSTALL_DIR")"

if [[ -f "$REPO_GITIGNORE" ]]; then
    # Check if ralph/ is already in .gitignore (with or without trailing slash)
    if grep -q "^${RALPH_BASENAME}/\?$" "$REPO_GITIGNORE" 2>/dev/null; then
        echo "✓ $RALPH_BASENAME/ already in repository .gitignore"
    else
        echo "Adding $RALPH_BASENAME/ to repository .gitignore..."
        echo "" >> "$REPO_GITIGNORE"
        echo "# Ralph AI assistant directory" >> "$REPO_GITIGNORE"
        echo "$RALPH_BASENAME/" >> "$REPO_GITIGNORE"
        echo "✓ Added $RALPH_BASENAME/ to repository .gitignore"
    fi

else
    echo "Creating repository .gitignore with $RALPH_BASENAME/..."
    cat > "$REPO_GITIGNORE" <<EOF
# Ralph AI assistant directory
$RALPH_BASENAME/
EOF
    echo "✓ Created repository .gitignore with $RALPH_BASENAME/"
fi

echo ""
echo "✓ Ralph installed successfully to: $INSTALL_DIR"
echo ""
echo "📦 Main Scripts:"
echo "  ✓ ralph-start.sh       - Interactive setup & full workflow"
echo "  ✓ setup.sh             - System setup (adds to PATH)"
echo ""
echo "📂 Scripts Directory (scripts/):"
echo "  ✓ ralph-prestart.sh    - Generate context documentation"
echo "  ✓ ralph-once.sh        - Run single task"
echo "  ✓ ralph-afk.sh         - Run multiple iterations"
echo "  ✓ ralph-monitor.sh     - Oversight monitoring"
echo "  ✓ ralph-lib.sh         - Shared utility library"
echo "  ✓ ralph-review*.sh     - Code review scripts"
echo ""
echo "📁 Additional Directories:"
if [[ -d "$INSTALL_DIR/prompts" ]]; then
    echo "  ✓ prompts/             - AI prompt templates"
fi
if [[ -d "$INSTALL_DIR/templates" ]]; then
    echo "  ✓ templates/           - Code templates"
fi
if [[ -f "$INSTALL_DIR/GUIDELINES.md" ]]; then
    echo "  ✓ GUIDELINES.md        - Coding standards"
fi
echo "  ✓ PRD.md               - Product requirements"
echo "  ✓ progress.txt         - Progress tracking"
echo "  ✓ logs/                - Structured logs"
echo "  ✓ .gitignore           - Git ignore rules"
echo ""
echo "🚀 Quick Start:"
echo "  # From project root:"
echo "  $INSTALL_DIR/ralph-start.sh"
echo ""
echo "📚 Usage Examples (from project root):"
echo "  $INSTALL_DIR/scripts/ralph-prestart.sh             # Generate context documentation"
echo "  $INSTALL_DIR/ralph-start.sh                        # Full interactive workflow"
echo "  $INSTALL_DIR/scripts/ralph-once.sh                 # Single task execution"
echo "  $INSTALL_DIR/scripts/ralph-afk.sh 10               # Run 10 iterations"
echo "  $INSTALL_DIR/scripts/ralph-review.sh               # Quick code review"
echo "  $INSTALL_DIR/scripts/ralph-review-file.sh src/main.js  # Review specific file"
echo "  $INSTALL_DIR/scripts/ralph-review-and-fix.sh 5     # Review & fix with 5 iterations"
echo ""
echo "💡 Tip: Ralph works in your project root but keeps files in $INSTALL_DIR/"
echo "    All commands can be run from either location."
echo ""
