# Ralph Wiggum, Senior Software Engineer 🧑‍💻

  1. Press Esc key
  2. Type :wq and press Enter
    - :w = write (save)
    - :q = quit

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

## What's Inside?

### Core Loop Scripts
- **`ralph-start.sh`** – The full Ralph experience: PRD generation → implementation → review → fix → validate. One command, production-ready code.
- **`scripts/ralph-monitor.sh`** – **NEW!** Oversight loop that runs in parallel with AFK mode. Checks every 10 minutes for PRD alignment and code quality.
- **`scripts/gen-prd.sh`** – Ralph writes a beautiful PRD (usually better than the ones from your last architecture review).
- **`PRD.md`** – The single source of truth. Ralph treats it like his Valentine from Lisa.
- **`progress.txt`** – Ralph's little diary: "Today I made the button work. I'm special!"
- **`scripts/ralph-once.sh`** – Do exactly one task. Perfect for watching Ralph think.
- **`scripts/ralph-afk.sh`** – Fire and forget. Give it a number and go touch grass. Ralph doesn't need breaks.

### NEW: Self-Review & Auto-Fix Scripts
Ralph learned to review his own code! (Unlike certain devs who think code review is optional.)

- **`scripts/ralph-review.sh`** – Ralph reviews all his changes. Finds bugs, security issues, bad patterns. No coffee breaks, just fixes.
- **`scripts/ralph-review-file.sh`** – Review specific files. Point Ralph at your suspicious code.
- **`scripts/ralph-review-diff.sh`** – Review git changes before commit. Ralph reads the diff so you don't have to.
- **`scripts/ralph-review-and-fix.sh`** – The magic loop: review → find issues → fix them → review again. Runs until code is clean.
- **`scripts/ralph-review-prd.sh`** – Checks if Ralph actually implemented what the PRD asked for. (He usually does.)

### Quality & Utilities
- **`scripts/ralph-lib.sh`** – 1700+ lines of bash utilities. Logging, metrics, JSON, validation, template loading. Ralph's utility belt.
- **`logs/`** – Structured JSON logs. Track every iteration, error, and fix. Ralph keeps receipts.
- **`install.sh`** – One-command setup for any repo. Ralph travels light.
- **`setup.sh`** – Sets up Ralph for your system (adds to PATH).
- **`prompts/`** – Customizable AI prompt templates for all Ralph interactions.
- **`templates/`** – Code templates and examples (bash functions, documentation, error handling).

## Installation

### For New Projects
```bash
git clone https://github.com/your-username/ralph.git
cd your-new-project
/path/to/ralph/install.sh
cd ralph
```

### For Existing Projects
```bash
cd your-existing-project
/path/to/ralph/install.sh .
# Creates ./ralph/ with all scripts
```

### Quick Setup
```bash
# Clone and run setup in one command
git clone https://github.com/your-username/ralph.git
cd ralph
./setup.sh
```

## Quick Start - The Full Ralph Experience

**New in 2026**: Ralph now includes auto-review and self-healing!

1. **Start the interactive workflow:**
   ```bash
   # From project root
   ./ralph/ralph-start.sh

   # OR from inside ralph directory
   cd ralph && ./ralph-start.sh
   ```

2. **What happens next:**
   - Ralph asks what you want to build
   - Claude generates a detailed PRD
   - You approve it (or edit, or regenerate)
   - Ralph implements ALL tasks (babysitting or AFK mode)
   - **NEW: In AFK mode, Ralph Monitor runs in parallel** (checks every 10 minutes)
   - **Monitor reviews progress, checks PRD alignment, adjusts if needed**
   - **Ralph reviews his own code** for bugs, security, quality
   - **Ralph fixes issues automatically** (up to 3 review cycles)
   - **Ralph validates** syntax, runs linters
   - You get production-ready code with logs and metrics

3. **Done!** Review the results:
   ```bash
   cat ralph/progress.txt
   cat ralph/review-results.txt
   git diff
   ```

**Note**: Ralph works in your project root but keeps its files in the `ralph/` directory. You can run scripts from either location.

## Classic Quick Start (Original Ralph Loop)

1. Make sure you have the Claude CLI installed and an API key.
2. Generate the PRD:
   ```bash
   ./scripts/gen-prd.sh
   ```
   (Edit the prompt inside for your own project — Ralph is very flexible.)

3. Try one step (babysitting mode):
   ```bash
   ./scripts/ralph-once.sh
   ```
   Watch Ralph pick a task, implement it, and update progress.

4. Go full Ralph (AFK mode):
   ```bash
   ./scripts/ralph-afk.sh 50
   ```
   Come back later to a (hopefully) finished app. If Ralph says `<promise>COMPLETE</promise>`, he's done!

5. **NEW**: Review & fix automatically:
   ```bash
   ./scripts/ralph-review-and-fix.sh 5
   ```
   Ralph finds all issues and fixes them. Senior dev energy, intern pricing.

## Code Review Examples

Ralph now reviews his own work! Here's what he checks:

### Quick Review (Modified Files)
```bash
./scripts/ralph-review.sh
# Reviews all modified/staged files in your project
# Finds: bugs, security issues, performance problems, missing tests
```

### Review Specific Files
```bash
./scripts/ralph-review-file.sh src/main.js src/utils.js
./scripts/ralph-review-file.sh src/**/*.js
```

### Review Git Changes
```bash
./scripts/ralph-review-diff.sh              # Unstaged changes
./scripts/ralph-review-diff.sh staged       # Staged changes
./scripts/ralph-review-diff.sh all          # All uncommitted changes
```

### Auto-Fix Loop (The Good Stuff)
```bash
./scripts/ralph-review-and-fix.sh
# Finds issues → fixes them → reviews again → repeat
# Runs 3 cycles by default. Ralph doesn't quit.
```

### PRD Compliance Check
```bash
./scripts/ralph-review-prd.sh
# Did Ralph actually implement the PRD?
# Checks completeness, quality, security, tests
# Then offers to auto-fix any issues
```

## What Ralph Reviews

1. **PRD Completeness** – Did he finish what you asked?
2. **Code Quality** – Best practices, readability, maintainability
3. **Bugs & Logic Errors** – Edge cases, null checks, error handling
4. **Security** – SQL injection, XSS, command injection, secrets in code
5. **Performance** – Inefficient loops, N+1 queries, memory leaks
6. **Testing** – Missing tests, insufficient coverage
7. **Documentation** – Code comments, README, API docs

Ralph finds issues, rates severity (CRITICAL/HIGH/MEDIUM/LOW), and suggests specific fixes.
Then **he fixes them himself**. No need to assign tickets or schedule sprints.

## Ralph Monitor - Autonomous Oversight (NEW!)

**The Problem**: Ralph AFK mode can implement 50+ tasks while you sleep. But what if he goes off track? What if the PRD was unclear?

**The Solution**: Ralph Monitor runs in parallel, checking every 10 minutes.

### How It Works

When you select **AFK mode** in `ralph-start.sh`, two processes run simultaneously:

1. **Ralph AFK** (implementation loop) - Cranks out tasks from the PRD
2. **Ralph Monitor** (oversight loop) - Reviews progress every 10 minutes

The monitor:
- ✅ Reviews all recent code changes
- ✅ Checks if implementation aligns with PRD requirements
- ✅ Looks for bugs, security issues, anti-patterns
- ✅ Reads files in `context/` folder if it exists (documentation, specs, examples)
- ✅ **Adjusts the PRD automatically** if requirements were unclear or incomplete
- ✅ Terminates automatically when AFK mode completes or is interrupted

### Why This Matters

Ralph Monitor acts as a **senior technical reviewer** catching issues before they compound:
- PRD was ambiguous? Monitor clarifies it.
- Implementation diverged from requirements? Monitor corrects the PRD.
- Missing requirements discovered? Monitor adds them.
- Code quality issues? Monitor flags them for the review cycle.

It's like having a staff engineer watching over Ralph while you sleep.

### Using the context/ Folder

Create a `context/` folder in your project root with:
- Architecture docs
- API specifications
- Design mockups
- Code examples
- Business rules

The monitor reads these files every cycle to ensure alignment with documentation.

### Monitor Logs

Check what the monitor found:
```bash
cat ralph/logs/ralph-monitor.log
```

The log shows:
- Timestamp of each check
- Changes detected
- Issues found
- PRD adjustments made

### Manual Monitor Usage

You can also run the monitor manually:
```bash
# Start monitor (checks every 10 minutes)
./scripts/ralph-monitor.sh &
MONITOR_PID=$!

# Stop when done
kill $MONITOR_PID
```

## Tips for Maximum Ralph

- **Write a rock-solid PRD first.** Chat with Claude normally, then paste the final version.
- **Keep tasks tiny and testable** — that's how Ralph stays on track.
- **Use `ralph-start.sh` for new projects** — full workflow with auto-review built in.
- **NEW: Create a context/ folder** — Add docs, specs, examples. The monitor reads them every 10 minutes.
- **NEW: Use AFK mode for large projects** — The monitor keeps Ralph aligned while you're away.
- **Watch the first few runs** with `scripts/ralph-once.sh`. If Ralph starts writing placeholder code, gently remind him in the PRD.
- **Check the logs** in `logs/` — Ralph logs everything in JSON for metrics.
- **Check monitor logs** in `logs/ralph-monitor.log` — See what oversight caught.
- **Let Ralph review before you review** — run `scripts/ralph-review-and-fix.sh` before PR submission.
- **Trust the validation** — Ralph runs shellcheck, syntax checks, linters automatically.
- Unlike certain senior engineers, Ralph actually reads the error messages.

## Advanced Features

### Customizing Prompts with Templates

**All Ralph prompts are now customizable templates!** Every Claude interaction uses a template from the `prompts/` folder, allowing you to tailor Ralph's behavior to your project.

#### Available Templates

| Template | Used By | Purpose |
|----------|---------|---------|
| `prd-generation-prompt.md` | ralph-start.sh | Generate initial PRD from description |
| `code-review-prompt.md` | ralph-start.sh | Review code quality and completeness |
| `fix-prompt.md` | ralph-start.sh | Fix issues found in review |
| `ralph-once-prompt.md` | ralph-once.sh | Single task execution |
| `ralph-afk-prompt.md` | ralph-afk.sh | Autonomous multi-task execution |
| `monitor-review-prompt.md` | ralph-monitor.sh | Oversight review (10 min cycles) |
| `prd-update-prompt.md` | ralph-monitor.sh | Update PRD based on findings |

#### Common Variables

All templates support variable substitution using `{{VARIABLE_NAME}}` syntax:
- `{{PRD_FILE}}` - Path to PRD.md
- `{{PROGRESS_FILE}}` - Path to progress.txt
- `{{USER_DESCRIPTION}}` - User's project description
- `{{REVIEW_LOG}}` - Path to review results
- `{{CONTEXT_DIR}}` - Path to context/ folder
- `{{MODIFIED_FILES}}` - List of changed files
- `{{ITERATION}}` - Current iteration number

#### Example Customizations

**Add project-specific requirements**:
```bash
# Edit the PRD generation template
vim prompts/prd-generation-prompt.md

# Add requirements like:
# - Must use TypeScript
# - Follow company style guide
# - Include accessibility requirements
# - Add monitoring and observability
```

**Customize code review focus**:
```bash
# Edit the code review template
vim prompts/code-review-prompt.md

# Add checks for:
# - Database migration safety
# - API backward compatibility
# - Performance benchmarks
# - Specific security standards (HIPAA, PCI-DSS)
```

**Adjust AFK mode behavior**:
```bash
# Edit the AFK prompt template
vim prompts/ralph-afk-prompt.md

# Modify instructions:
# - Always run specific test suites
# - Check for memory leaks
# - Update specific documentation
```

#### Template Loading

Ralph uses the `ralph_load_template()` function from `ralph-lib.sh`:
```bash
# Load template with variable substitution
prompt=$(ralph_load_template "template-name.md" "VAR1=value1" "VAR2=value2")
```

All prompts have fallback behavior - if a prompt template is missing, Ralph uses a built-in default prompt.

**Note**: The `templates/` folder contains code templates (bash functions, documentation examples, error handling patterns), while the `prompts/` folder contains AI prompt templates.

### Structured Logging
```bash
# View metrics
cat logs/ralph-metrics.log | jq

# Count successful iterations
cat logs/ralph-metrics.log | jq 'select(.type=="iteration" and .status=="success")' | wc -l

# Track errors
cat logs/ralph-errors.log
```

### Environment Variables
```bash
export RALPH_LOG_LEVEL=DEBUG              # DEBUG, INFO, WARN, ERROR
export RALPH_FILTER_OUTPUT=true           # Filter verbose Claude output
export RALPH_PROGRESS_MAX_LINES=500       # Auto-summarize progress
export MAX_FIX_ITERATIONS=5               # More review cycles
```

### CI/CD Integration
```yaml
# .github/workflows/ralph-review.yml
- name: Ralph Code Review
  run: |
    cd ralph
    ./scripts/ralph-review-diff.sh all
```

Ralph may not be the smartest dev on the block, but he **never gives up**.
And now he reviews his own code, fixes his mistakes, and validates everything.
That's more than you can say for half the staff+ titles out there.

Happy looping! 🎉

## License

MIT License

Copyright (c) 2026 luisbebop

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.