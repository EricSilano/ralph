#!/bin/bash
set -e

# Get the absolute path to the ralph directory
RALPH_DIR="$(cd "$(dirname "$0")" && pwd)"
ZSHRC="$HOME/.zshrc"

echo "🔧 Setting up Ralph..."
echo ""
echo "Ralph directory: $RALPH_DIR"
echo "Target file: $ZSHRC"
echo ""

# Make all scripts executable
echo "Making scripts executable..."
chmod +x "$RALPH_DIR"/*.sh
chmod +x "$RALPH_DIR"/scripts/*.sh 2>/dev/null || true
echo "✓ All scripts are now executable"
echo ""

# Create .zshrc if it doesn't exist
if [[ ! -f "$ZSHRC" ]]; then
    echo "Creating $ZSHRC..."
    touch "$ZSHRC"
fi

# Check if PATH entry already exists
if grep -q "export PATH=\"\$PATH:$RALPH_DIR\"" "$ZSHRC"; then
    echo "✓ PATH entry already exists in $ZSHRC"
    echo "  No changes needed."
else
    echo "Adding Ralph to PATH..."
    echo "" >> "$ZSHRC"
    echo "# Ralph automation system" >> "$ZSHRC"
    echo "export PATH=\"\$PATH:$RALPH_DIR\"" >> "$ZSHRC"
    echo ""
    echo "✓ Successfully added Ralph to PATH in $ZSHRC"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "To use Ralph commands from anywhere:"
echo "  1. Restart your terminal, or"
echo "  2. Run: source $ZSHRC"
echo ""
echo "Then you can run Ralph commands like:"
echo "  ralph-start.sh              # Main entry point"
echo "  scripts/ralph-once.sh       # Run one task"
echo "  scripts/ralph-afk.sh 10     # Run 10 iterations"
echo "  scripts/ralph-review.sh     # Review code"
echo ""
