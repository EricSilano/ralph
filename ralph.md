# Ralph Scripts Reference

Complete documentation of all Ralph scripts, their purposes, and usage.

---

## Table of Contents

- [Main Entry Points](#main-entry-points)
- [Core Automation Scripts](#core-automation-scripts)
- [Review & Quality Scripts](#review--quality-scripts)
- [Utility Library](#utility-library)
- [AI Prompts](#ai-prompts)
- [Code Templates](#code-templates)
- [File Structure](#file-structure)

---

## Main Entry Points

Scripts in the root directory - your primary interfaces to Ralph.

### ralph-start.sh

**Purpose**: The complete Ralph workflow - interactive setup, PRD generation, implementation, review, fix, and validation.

**What it does**:
1. Prompts user for project description (text or editor)
2. Generates detailed PRD using Claude AI
3. Allows PRD review/editing/regeneration
4. Asks for execution mode (babysitting or AFK)
5. Launches implementation (ralph-once or ralph-afk + monitor)
6. Runs comprehensive code review (3 iteration max)
7. Auto-fixes issues found in review
8. Validates syntax (shellcheck, python, javascript)
9. Provides final summary and next steps

**Usage**:
```bash
./ralph-start.sh
# Interactive prompts guide you through the process
```

**When to use**: Starting a new project or feature from scratch. This is the recommended entry point for most users.

**Environment Variables**:
- `EDITOR` - Your preferred text editor (default: vim)
- `MAX_FIX_ITERATIONS` - Max review/fix cycles (default: 3)

---

### setup.sh

**Purpose**: System-level setup - adds Ralph to your PATH so you can run Ralph commands from anywhere.

**What it does**:
1. Makes all Ralph scripts executable
2. Adds Ralph directory to PATH in ~/.zshrc
3. Provides instructions for activation

**Usage**:
```bash
./setup.sh
# Then restart terminal or: source ~/.zshrc
```

**When to use**: First time using Ralph, or after moving Ralph to a new location.

---

### install.sh

**Purpose**: Install Ralph into another project directory.

**What it does**:
1. Copies Ralph scripts to target directory
2. Creates `scripts/`, `prompts/`, `templates/` folders
3. Sets up PRD.md, progress.txt, logs/
4. Creates .gitignore
5. Makes all scripts executable

**Usage**:
```bash
# Install to new project
cd your-project
/path/to/ralph/install.sh

# Install to specific subdirectory
/path/to/ralph/install.sh ./ralph
```

**When to use**: Setting up Ralph in a different project directory.

---

## Core Automation Scripts

Scripts in the `scripts/` directory that drive Ralph's automation.

### scripts/ralph-once.sh

**Purpose**: Execute exactly one task from the PRD (babysitting mode).

**What it does**:
1. Reads PRD.md and progress.txt
2. Finds the next incomplete task
3. Implements that one task
4. Updates progress.txt
5. Stops and waits for user

**Usage**:
```bash
./scripts/ralph-once.sh
```

**When to use**: When you want to review each task as Ralph completes it. Ideal for learning what Ralph does or maintaining tight control.

**Prompt Template**: `prompts/ralph-once-prompt.md`

---

### scripts/ralph-afk.sh

**Purpose**: Autonomous mode - execute multiple tasks without stopping (AFK = "Away From Keyboard").

**What it does**:
1. Takes iteration count as parameter
2. For each iteration:
   - Finds highest-priority incomplete task
   - Implements the task
   - Runs tests (if configured)
   - Updates PRD and progress.txt
3. Stops when complete or iteration limit reached

**Usage**:
```bash
./scripts/ralph-afk.sh 10    # Run 10 iterations
./scripts/ralph-afk.sh 50    # Run 50 iterations
```

**When to use**: When you want Ralph to work autonomously on multiple tasks. Great for running overnight or during meetings.

**Completion Signal**: Outputs `<promise>COMPLETE</promise>` when PRD is fully implemented.

**Prompt Template**: `prompts/ralph-afk-prompt.md`

---

### scripts/ralph-monitor.sh

**Purpose**: Continuous oversight loop that reviews progress every 10 minutes (runs in parallel with ralph-afk).

**What it does**:
1. Runs in background during AFK mode
2. Every 10 minutes:
   - Detects code changes (git diff)
   - Reviews implementation quality
   - Checks PRD alignment
   - Reads context/ folder (if exists)
   - Suggests PRD updates if needed
   - Automatically updates PRD when issues found
3. Classifies status: ON_TRACK | NEEDS_ATTENTION | CRITICAL_ISSUE
4. Logs all findings to `logs/ralph-monitor.log`

**Usage**:
```bash
# Automatic (started by ralph-start.sh in AFK mode)

# Manual
./scripts/ralph-monitor.sh &
MONITOR_PID=$!
# Stop later: kill $MONITOR_PID
```

**When to use**: Automatically launched by ralph-start.sh in AFK mode. Can be run manually for continuous oversight.

**Review Criteria**:
- PRD alignment
- Code quality (4 severity levels)
- Security vulnerabilities
- Performance issues
- Test coverage
- Documentation

**Prompt Template**: `prompts/monitor-review-prompt.md`

---

### scripts/ralph-lib.sh

**Purpose**: Shared utility library used by all Ralph scripts.

**What it provides**:
- **Logging**: Structured logging with levels (DEBUG, INFO, WARN, ERROR)
- **Timestamps**: ISO 8601 formatted timestamps
- **File Logging**: Daily logs, error logs, metrics logs
- **JSON Functions**: JSON escaping, array building
- **State Management**: Status tracking, progress management
- **Validation**: File checks, git status parsing
- **Output Filtering**: Claude output summarization
- **Template Loading**: Load and process prompt templates
- **Metrics**: Performance tracking, iteration counts

**Key Functions**:
- `ralph_log()` - Log with severity level
- `ralph_info()`, `ralph_warn()`, `ralph_error()` - Convenience logging
- `ralph_setup_logging()` - Initialize logging system
- `ralph_load_template()` - Load AI prompt templates
- `ralph_init_logs()` - Create log directory
- `ralph_json_escape()` - Escape strings for JSON
- `ralph_validate_file()` - Check file existence
- `ralph_get_git_status()` - Parse git status

**Usage**: Automatically sourced by other scripts.

**Size**: ~1700 lines of utilities.

---

## Review & Quality Scripts

Scripts in `scripts/` that handle code review and quality assurance.

### scripts/ralph-review.sh

**Purpose**: Quick review of all modified/staged files in the project.

**What it does**:
1. Detects modified, staged, and untracked files
2. Runs comprehensive code review on all changes
3. Checks against PRD requirements
4. Identifies bugs, security issues, performance problems
5. Outputs review with severity ratings

**Usage**:
```bash
./scripts/ralph-review.sh
```

**When to use**: Before committing changes, or to get a quick quality check on recent work.

**Review Categories**:
- PRD Completeness
- Code Quality
- Bugs & Issues
- Security
- Performance
- Testing
- Documentation

---

### scripts/ralph-review-file.sh

**Purpose**: Review specific files (not all changes).

**What it does**:
1. Takes file paths as arguments
2. Reviews only those specific files
3. Provides detailed feedback per file

**Usage**:
```bash
./scripts/ralph-review-file.sh src/main.js
./scripts/ralph-review-file.sh src/main.js src/utils.js
./scripts/ralph-review-file.sh src/**/*.js
```

**When to use**: When you want to review specific files without reviewing everything.

---

### scripts/ralph-review-diff.sh

**Purpose**: Review git changes (diff) before committing.

**What it does**:
1. Shows git diff (unstaged, staged, or all)
2. Reviews the changes in context
3. Catches issues before they're committed

**Usage**:
```bash
./scripts/ralph-review-diff.sh              # Unstaged changes
./scripts/ralph-review-diff.sh staged       # Staged changes
./scripts/ralph-review-diff.sh all          # All uncommitted
```

**When to use**: As a pre-commit check to catch issues before they enter version control.

---

### scripts/ralph-review-and-fix.sh

**Purpose**: The "magic loop" - review code, find issues, fix them automatically, review again.

**What it does**:
1. Runs code review
2. Finds issues
3. Automatically fixes issues using Claude
4. Reviews again to verify fixes
5. Repeats until clean (max iterations configurable)

**Usage**:
```bash
./scripts/ralph-review-and-fix.sh           # Default 3 iterations
./scripts/ralph-review-and-fix.sh 5         # 5 iterations max
```

**When to use**: When you want Ralph to not just find issues, but fix them automatically. Great for cleaning up code before a PR.

**Iteration Logic**:
- Iteration 1: Review → Fix
- Iteration 2: Review fixes → Fix remaining
- Iteration 3: Final review → Fix critical issues
- If still has issues after max iterations, manual review needed

---

### scripts/ralph-review-prd.sh

**Purpose**: Check if the implementation actually matches what the PRD requested.

**What it does**:
1. Reads PRD.md requirements
2. Reviews implementation
3. Checks completeness (are all tasks done?)
4. Verifies quality (are they done correctly?)
5. Offers to auto-fix any gaps

**Usage**:
```bash
./scripts/ralph-review-prd.sh
```

**When to use**: At the end of development to verify the PRD is fully implemented before delivery.

---

## Utility Library

### scripts/ralph-lib.sh Functions Reference

#### Logging Functions
```bash
ralph_log "LEVEL" "message"           # Core logging
ralph_debug "message"                 # Debug level
ralph_info "message"                  # Info level
ralph_warn "message"                  # Warning level
ralph_error "message"                 # Error level
ralph_setup_logging                   # Initialize logging system
ralph_init_logs                       # Create log directory
```

#### File Logging
```bash
ralph_log_to_file "filename" "msg"    # Log to specific file
ralph_log_daily "LEVEL" "message"     # Log to daily file
ralph_log_error_file "msg" "context"  # Log to error file
ralph_get_daily_log_path              # Get today's log path
```

#### Template Functions
```bash
ralph_load_template "name.md" "VAR=val"  # Load prompt template
ralph_load_template_safe "name" "fallback" "VAR=val"  # Load with fallback
ralph_list_templates                  # List available templates
```

#### JSON Functions
```bash
ralph_json_escape "string"            # Escape for JSON
ralph_json_array "item1,item2"        # Build JSON array
```

#### Utility Functions
```bash
ralph_timestamp                       # ISO 8601 UTC timestamp
ralph_timestamp_local                 # Local timestamp
ralph_date                            # YYYY-MM-DD format
ralph_validate_file "path"            # Check file exists
ralph_get_git_status                  # Parse git status
```

---

## AI Prompts

Templates in `prompts/` folder that define how Claude behaves.

### prompts/prd-generation-prompt.md

**Used by**: ralph-start.sh

**Purpose**: Transform user's brief description into detailed PRD.

**Variables**:
- `{{USER_DESCRIPTION}}` - User's project idea

**Output**: Markdown PRD with:
- Project Overview
- Tech Stack
- Features (prioritized)
- Tasks (atomic, with checkboxes)
- Success Criteria

---

### prompts/code-review-prompt.md

**Used by**: ralph-start.sh (Step 6)

**Purpose**: Comprehensive code review against PRD and quality standards.

**Variables**:
- `{{PRD_FILE}}` - Path to requirements
- `{{PROGRESS_FILE}}` - Path to progress log

**Output**: Structured review with:
- Summary
- Issues Found (by severity)
- Recommendations
- Special marker: `<promise>NO_ISSUES</promise>` if clean

---

### prompts/fix-prompt.md

**Used by**: ralph-start.sh (Step 6)

**Purpose**: Automatically fix issues found during code review.

**Variables**:
- `{{REVIEW_LOG}}` - Path to review results

**Output**: Fix summary with:
- Fixes Applied (file:line)
- Verification results
- Special marker: `<promise>FIXES_COMPLETE</promise>`

---

### prompts/ralph-once-prompt.md

**Used by**: scripts/ralph-once.sh

**Purpose**: Execute single task from PRD.

**Variables**:
- `{{PRD_FILE}}` - Path to requirements
- `{{PROGRESS_FILE}}` - Path to progress log

**Output**: Completed task + updated progress

---

### prompts/ralph-afk-prompt.md

**Used by**: scripts/ralph-afk.sh

**Purpose**: Autonomous multi-task execution.

**Variables**:
- `{{PRD_FILE}}` - Path to requirements
- `{{PROGRESS_FILE}}` - Path to progress log

**Output**: Task completion + special marker `<promise>COMPLETE</promise>` when done

---

### prompts/monitor-review-prompt.md

**Used by**: scripts/ralph-monitor.sh

**Purpose**: Oversight review every 10 minutes (222 lines - most comprehensive).

**Variables**:
- `{{PRD_FILE}}` - Path to requirements
- `{{PROGRESS_FILE}}` - Path to progress
- `{{CONTEXT_DIR}}` - Path to documentation
- `{{MODIFIED_FILES}}` - List of changed files
- `{{ITERATION}}` - Current monitor cycle

**Output**: Detailed oversight with:
- Status classification
- Recent activity analysis
- Issues by severity
- PRD alignment check
- Context compliance
- PRD adjustment recommendations
- Guidance for next iterations

---

### prompts/prd-update-prompt.md

**Used by**: scripts/ralph-monitor.sh

**Purpose**: Update PRD based on oversight findings.

**Variables**:
- `{{PRD_FILE}}` - Path to PRD
- `{{PROGRESS_FILE}}` - Path to progress
- `{{PRD_ADJUSTMENTS}}` - Recommended changes

**Output**: Surgically updated PRD (preserves completed work)

---

## Code Templates

Examples in `templates/` folder for reference.

### templates/bash-function.sh

**Purpose**: Example bash function templates with best practices.

**Contains**:
- Function documentation patterns
- Parameter handling
- Error handling
- Return values

---

### templates/documentation.md

**Purpose**: Documentation template examples.

**Contains**:
- README structures
- API documentation
- Code comments
- User guides

---

### templates/error-handling.sh

**Purpose**: Error handling patterns for bash scripts.

**Contains**:
- set -e usage
- trap handlers
- Error messages
- Exit codes
- Cleanup patterns

---

## File Structure

Complete Ralph directory layout:

```
ralph/
├── ralph-start.sh              # Main entry point
├── setup.sh                    # System setup
├── install.sh                  # Install to other projects
│
├── scripts/                    # Core automation
│   ├── ralph-once.sh           # Single task mode
│   ├── ralph-afk.sh            # Autonomous mode
│   ├── ralph-monitor.sh        # Oversight loop
│   ├── ralph-lib.sh            # Utility library
│   ├── ralph-review.sh         # Quick review
│   ├── ralph-review-file.sh    # Review specific files
│   ├── ralph-review-diff.sh    # Review git changes
│   ├── ralph-review-and-fix.sh # Auto review+fix loop
│   └── ralph-review-prd.sh     # PRD compliance check
│
├── prompts/                    # AI prompt templates
│   ├── prd-generation-prompt.md
│   ├── code-review-prompt.md
│   ├── fix-prompt.md
│   ├── ralph-once-prompt.md
│   ├── ralph-afk-prompt.md
│   ├── monitor-review-prompt.md
│   └── prd-update-prompt.md
│
├── templates/                  # Code templates
│   ├── bash-function.sh
│   ├── documentation.md
│   └── error-handling.sh
│
├── logs/                       # Generated logs
│   ├── ralph-YYYY-MM-DD.log    # Daily logs
│   ├── ralph-errors.log        # Error log
│   ├── ralph-metrics.log       # Metrics (JSON)
│   └── ralph-monitor.log       # Monitor output
│
├── PRD.md                      # Product requirements
├── progress.txt                # Implementation progress
├── GUIDELINES.md               # Coding standards
├── readme.md                   # Main documentation
├── ralph.md                    # This file
└── .gitignore                  # Git ignore rules
```

---

## Common Workflows

### Workflow 1: Start New Project
```bash
./ralph-start.sh
# 1. Describe project
# 2. Review/approve PRD
# 3. Choose AFK mode
# 4. Let Ralph work
# 5. Review results
```

### Workflow 2: Single Task at a Time
```bash
./scripts/ralph-once.sh  # Do task 1
# Review
./scripts/ralph-once.sh  # Do task 2
# Review
# Repeat...
```

### Workflow 3: Autonomous Development
```bash
./scripts/ralph-afk.sh 50
# Come back later
# Ralph completes 50 tasks or until PRD is done
```

### Workflow 4: Code Review Before PR
```bash
./scripts/ralph-review.sh                    # Quick review
./scripts/ralph-review-and-fix.sh 5          # Auto-fix issues
./scripts/ralph-review-prd.sh                # Verify PRD complete
git add . && git commit -m "feat: ..."       # Commit clean code
```

### Workflow 5: Monitor Long-Running Work
```bash
# Terminal 1
./scripts/ralph-afk.sh 100

# Terminal 2 (optional - monitor already runs in AFK mode)
tail -f logs/ralph-monitor.log
```

---

## Environment Variables

### Logging
```bash
export RALPH_LOG_LEVEL=DEBUG              # DEBUG, INFO, WARN, ERROR
export RALPH_LOG_DIR=./logs               # Log directory
export RALPH_FILTER_OUTPUT=true           # Filter verbose output
```

### Templates
```bash
export RALPH_TEMPLATES_DIR=prompts        # Prompt templates location
```

### Behavior
```bash
export RALPH_PROGRESS_MAX_LINES=500       # Auto-summarize progress
export MAX_FIX_ITERATIONS=5               # Review/fix cycles
export EDITOR=vim                         # Preferred editor
```

---

## Exit Codes

Ralph scripts use standard exit codes:
- `0` - Success
- `1` - General error
- `2` - Usage error (wrong parameters)

---

## Special Markers

Ralph uses special markers in output to signal completion:

- `<promise>COMPLETE</promise>` - PRD fully implemented
- `<promise>NO_ISSUES</promise>` - Code review passed
- `<promise>FIXES_COMPLETE</promise>` - All fixes applied
- `NO_PRD_CHANGES_NEEDED` - Monitor found no PRD issues

---

## Tips & Best Practices

1. **Start with ralph-start.sh** - It's the recommended entry point
2. **Use context/ folder** - Add docs for monitor to reference
3. **Customize prompts** - Edit `prompts/*.md` for project needs
4. **Check logs** - `logs/` has detailed execution history
5. **Run setup.sh once** - Add Ralph to PATH for convenience
6. **Review early** - Use ralph-once.sh for first few tasks
7. **Trust AFK mode** - Once comfortable, let Ralph work autonomously
8. **Monitor watches** - In AFK mode, monitor keeps Ralph aligned
9. **Review before commits** - Use ralph-review-and-fix.sh
10. **Read ralph-lib.sh** - Great source of utility functions

---

## Troubleshooting

### Ralph isn't finding prompts
```bash
# Check RALPH_TEMPLATES_DIR
echo $RALPH_TEMPLATES_DIR
# Should be: prompts

# Verify prompts exist
ls -la prompts/
```

### Logging not working
```bash
# Check log directory
ls -la logs/

# If missing, initialize
mkdir -p logs

# Check ralph-lib.sh is sourced
grep ralph_setup_logging your-script.sh
```

### Scripts not executable
```bash
./setup.sh
# or
chmod +x *.sh scripts/*.sh
```

### Monitor not stopping
```bash
# Find monitor PID
ps aux | grep ralph-monitor

# Kill it
kill <PID>

# Or use PID file
cat .ralph-monitor.pid
kill $(cat .ralph-monitor.pid)
```

---

## Version Information

- **Ralph Version**: 2026 Edition
- **Features**: Auto-review, self-healing, parallel monitoring
- **Lines of Code**: ~10,000+ across all scripts
- **Templates**: 7 AI prompts + 3 code templates

---

## See Also

- `readme.md` - Main documentation
- `GUIDELINES.md` - Coding standards
- `prompts/` - Customizable AI prompts
- `templates/` - Code examples

---

*This reference was generated for Ralph Wiggum, Senior Software Engineer.*

*"I'm helping!" - Ralph*
