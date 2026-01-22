# Ralph

Meet Ralph Wiggum — Senior Software Engineer, 15+ years of experience, expert in cloud-native paste-eating architectures, former Staff Engineer at Crayons.io, and current holder of the world record for "most consecutive all-nighters without ever asking for a promotion."

While real senior devs are busy:
- Writing 47-page design docs nobody reads
- Arguing about dependency injection in Slack
- Quietly pushing `console.log("works on my machine")` to production
- Demanding bonus and unlimited PTO

Ralph just **loops**.  
Fail → fix → fail → fix → commit → repeat.  
No ego. No standups. No "let me circle back on that."  
Just pure, adorable, unstoppable persistence powered by Claude and a couple of bash scripts.

This is the **original external Ralph Loop** — the one that keeps sessions fresh, avoids context drift, and turns your AI into a gremlin that codes while you sleep. Because why pay a senior six figures when Ralph will do it for API credits and a gold star?

![Ralph Wiggum, Senior Software Engineer](ralph.png)

## Prerequisites

- [Claude CLI](https://docs.anthropic.com/en/docs/claude-code) installed and configured with an API key
- Bash shell (macOS/Linux)

## Installation

```bash
# 1. Clone the repository
git clone https://github.com/EricSilano/ralph.git

# 2. Run setup to add ralph to your PATH
cd ralph
./setup.sh

# 3. Go to the project where you want to use Ralph
cd /path/to/your-project

# 4. Install Ralph into your project
install.sh

# 5. Start Ralph
./ralph/ralph-start.sh
```

## What Happens

When you run `./ralph/ralph-start.sh`:
1. Ralph asks what you want to build
2. Generates a PRD (Product Requirements Document)
3. You approve, edit, or regenerate the PRD
4. Ralph implements all tasks (babysitting or AFK mode)
5. Reviews the code for issues
6. Auto-fixes problems found during review

### Individual Scripts

| Script | Description |
|--------|-------------|
| `scripts/gen-prd.sh` | Generate a PRD from a description |
| `scripts/ralph-once.sh` | Execute a single task from the PRD |
| `scripts/ralph-afk.sh <n>` | Run up to `n` iterations autonomously |
| `scripts/ralph-review.sh` | Review all modified files |
| `scripts/ralph-review-file.sh <files>` | Review specific files |
| `scripts/ralph-review-diff.sh [staged\|all]` | Review git changes |
| `scripts/ralph-review-and-fix.sh [n]` | Review and auto-fix in a loop (default: 3 cycles) |
| `scripts/ralph-review-prd.sh` | Check implementation against PRD |
| `scripts/ralph-monitor.sh` | Oversight loop for AFK mode (runs every 10 min) |

### Examples

**Run 50 iterations autonomously:**
```bash
./scripts/ralph-afk.sh 50
```

**Review and fix all issues:**
```bash
./scripts/ralph-review-and-fix.sh
```

**Review only staged changes:**
```bash
./scripts/ralph-review-diff.sh staged
```

## Key Files

| File | Purpose |
|------|---------|
| `PRD.md` | Product requirements document (source of truth for tasks) |
| `progress.txt` | Tracks completed work and current state |
| `logs/` | JSON logs for metrics, errors, and monitor activity |
| `prompts/` | Customizable prompt templates for Claude interactions |
| `context/` | Optional folder for docs/specs the monitor reads |

## AFK Mode with Monitor

When running in AFK mode via `ralph-start.sh`, a monitor process runs in parallel:
- Checks progress every 10 minutes
- Validates implementation against PRD
- Adjusts PRD if requirements were unclear
- Logs findings to `logs/ralph-monitor.log`

To use additional context, create a `context/` folder with architecture docs, API specs, or examples.

## Configuration

**Environment variables:**
```bash
RALPH_LOG_LEVEL=DEBUG|INFO|WARN|ERROR   # Log verbosity
RALPH_FILTER_OUTPUT=true                 # Filter verbose output
RALPH_PROGRESS_MAX_LINES=500             # Auto-summarize threshold
MAX_FIX_ITERATIONS=5                     # Review/fix cycle limit
```

**Customizing prompts:**

Edit templates in `prompts/` to customize Claude's behavior. Templates use `{{VARIABLE}}` syntax for substitution.
