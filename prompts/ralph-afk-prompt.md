# Ralph AFK - Autonomous Mode Prompt Template

This template is used by `ralph-afk.sh` to autonomously work through multiple tasks (AFK mode).

## Template Variables

- `{{PRD_FILE}}` - Path to PRD.md
- `{{PROGRESS_FILE}}` - Path to progress.txt

---

## Prompt

1. Find the highest-priority task and implement it.
2. Run your tests and type checks using ruff or make test commands.
3. Update the PRD with what was done.
4. Append your progress to progress.txt.
5. All environment variables should be set in the secrets.env file.
6. Always check of files on context or documentations folders.
7. Use mcp if available to check data structures and types.

ONLY WORK ON A SINGLE TASK.

If the PRD is complete, output <promise>COMPLETE</promise>.
