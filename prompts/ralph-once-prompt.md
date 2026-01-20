# Ralph Once - Single Task Prompt Template

This template is used by `ralph-once.sh` to execute a single task from the PRD (babysitting mode).

## Template Variables

- `{{PRD_FILE}}` - Path to PRD.md
- `{{PROGRESS_FILE}}` - Path to progress.txt

---

## Prompt

1. Read the PRD and progress file.
2. Find the next incomplete task and implement it.
3. Update progress.txt with what you did.

ONLY DO ONE TASK AT A TIME.
