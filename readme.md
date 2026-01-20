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
- **`gen-prd.sh`** – Ralph writes a beautiful PRD (usually better than the ones from your last architecture review).
- **`PRD.md`** – The single source of truth. Ralph treats it like his Valentine from Lisa.
- **`progress.txt`** – Ralph's little diary: "Today I made the button work. I'm special!"
- **`ralph-once.sh`** – Do exactly one task. Perfect for watching Ralph think.
- **`ralph-afk.sh`** – Fire and forget. Give it a number and go touch grass. Ralph doesn't need breaks.

### NEW: Self-Review & Auto-Fix Scripts
Ralph learned to review his own code! (Unlike certain devs who think code review is optional.)

- **`ralph-review.sh`** – Ralph reviews all his changes. Finds bugs, security issues, bad patterns. No coffee breaks, just fixes.
- **`ralph-review-file.sh`** – Review specific files. Point Ralph at your suspicious code.
- **`ralph-review-diff.sh`** – Review git changes before commit. Ralph reads the diff so you don't have to.
- **`ralph-review-and-fix.sh`** – The magic loop: review → find issues → fix them → review again. Runs until code is clean.
- **`ralph-review-prd.sh`** – Checks if Ralph actually implemented what the PRD asked for. (He usually does.)

### Quality & Utilities
- **`ralph-lib.sh`** – 1500+ lines of bash utilities. Logging, metrics, JSON, validation. Ralph's utility belt.
- **`logs/`** – Structured JSON logs. Track every iteration, error, and fix. Ralph keeps receipts.
- **`install.sh`** – One-command setup for any repo. Ralph travels light.

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
   ./gen-prd.sh
   ```
   (Edit the prompt inside for your own project — Ralph is very flexible.)

3. Try one step (babysitting mode):
   ```bash
   ./ralph-once.sh
   ```
   Watch Ralph pick a task, implement it, and update progress.

4. Go full Ralph (AFK mode):
   ```bash
   ./ralph-afk.sh 50
   ```
   Come back later to a (hopefully) finished app. If Ralph says `<promise>COMPLETE</promise>`, he's done!

5. **NEW**: Review & fix automatically:
   ```bash
   ./ralph-review-and-fix.sh 5
   ```
   Ralph finds all issues and fixes them. Senior dev energy, intern pricing.

## Code Review Examples

Ralph now reviews his own work! Here's what he checks:

### Quick Review (Modified Files)
```bash
./ralph/ralph-review.sh
# Reviews all modified/staged files in your project
# Finds: bugs, security issues, performance problems, missing tests
```

### Review Specific Files
```bash
./ralph/ralph-review-file.sh src/main.js src/utils.js
./ralph/ralph-review-file.sh src/**/*.js
```

### Review Git Changes
```bash
./ralph/ralph-review-diff.sh              # Unstaged changes
./ralph/ralph-review-diff.sh staged       # Staged changes
./ralph/ralph-review-diff.sh all          # All uncommitted changes
```

### Auto-Fix Loop (The Good Stuff)
```bash
./ralph/ralph-review-and-fix.sh
# Finds issues → fixes them → reviews again → repeat
# Runs 3 cycles by default. Ralph doesn't quit.
```

### PRD Compliance Check
```bash
./ralph/ralph-review-prd.sh
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

## Tips for Maximum Ralph

- **Write a rock-solid PRD first.** Chat with Claude normally, then paste the final version.
- **Keep tasks tiny and testable** — that's how Ralph stays on track.
- **Use `ralph-start.sh` for new projects** — full workflow with auto-review built in.
- **Watch the first few runs** with `ralph-once.sh`. If Ralph starts writing placeholder code, gently remind him in the PRD.
- **Check the logs** in `logs/` — Ralph logs everything in JSON for metrics.
- **Let Ralph review before you review** — run `ralph-review-and-fix.sh` before PR submission.
- **Trust the validation** — Ralph runs shellcheck, syntax checks, linters automatically.
- Unlike certain senior engineers, Ralph actually reads the error messages.

## Advanced Features

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
    ./ralph-review-diff.sh all
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