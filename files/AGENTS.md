## Build & Run

This is a reference playbook (static HTML + Markdown), not a compiled application.

- View locally: open `index.html` in a browser
- No build step, no dependencies, no package manager
- `files/` contains downloadable templates (loop scripts, prompts, AGENTS.md, IMPLEMENTATION_PLAN.md)
- `references/` contains supporting assets (images, supplementary docs)

## Validation

- Links: verify all internal `#anchor` links in `index.html` and `README.md` resolve to existing `id` attributes
- Markdown: ensure code blocks are properly fenced with correct language identifiers
- Files: all files referenced in `index.html` or `README.md` (`files/*`, `references/*`) must exist on disk

## Operational Notes

### Adapting loop.sh for Different CLIs

The template `loop.sh` uses `claude -p` (Claude Code CLI). When adapting for other CLIs:

- **Amp**: `cat "$PROMPT_FILE" | amp -x --dangerously-allow-all -m internal` (flag is `-m`, not `--message`)
- **Codex**: `cat "$PROMPT_FILE" | codex exec --dangerously-auto-approve`
- **Shebang**: always use `#!/usr/bin/env bash` (not `#!/bin/bash`) for portability on NixOS and non-FHS systems
- **Error handling**: use `set -euo pipefail`; wrap fallible commands in subshell guards `(...) || EXIT=$?`

### Prompt Template Conventions

- `@filename.md` references (e.g., `@AGENTS.md`, `@IMPLEMENTATION_PLAN.md`) are file-include directives — the agent loads them into context
- `${WORK_SCOPE}` in `PROMPT_plan_work.md` is a bash env var substituted by `loop.sh` via `envsubst`
- Priority escalation uses ascending 9s pattern (`99999:` important → `999999999:` critical) — these are weights, not step numbers
- Keep prompts brief and deterministic — verbose inputs degrade LLM output quality

### Push and Permissions

- Sandbox/CI environments may lack push rights to upstream repos — verify before relying on auto-push
- Use `LOOP_SKIP_PUSH=1` env var to disable auto-push in dev/test scenarios
- Stage only task-related files — never `git add -A` as it may include unrelated changes

### Spec Authoring

- One topic per spec file — must pass the "one sentence without 'and'" scoping test
- Write specs as behavioral outcomes (what to verify), not implementation details (how to build)
- Code is source of truth — if spec contradicts code, update the spec
- Numbering: `specs/NN-kebab-case.md` (e.g., `01-session-management.md`)
- Mark specs stale and regenerate rather than patching heavily

### AGENTS.md Hygiene

- Keep operational only — status updates and progress belong in `IMPLEMENTATION_PLAN.md`
- A bloated AGENTS.md pollutes every future loop's context window
- Update when you discover correct commands or patterns through trial and error

### Codebase Patterns

- `IMPLEMENTATION_PLAN.md` is shared state between loop iterations — it persists on disk and must be kept current
- `loop.sh` / `loop_streamed.sh` are the outer loop; each iteration = one fresh context session
- `parse_stream.js` formats `--output-format=stream-json` output for readability
- Use subagents for read-heavy work (up to 500 parallel); limit to 1 for writes/builds
- Use Opus subagents for complex reasoning (debugging, architecture); Sonnet for bulk reads/searches

### Lessons Learned

- **Overclaiming in specs**: always `rg`/`grep` the codebase first before claiming functionality is missing
- **Plan is disposable**: regenerate when Ralph circles or plan feels stale — one Planning loop is cheap compared to fighting a bad plan
- **CLI flag discovery**: don't guess CLI flags — scrape `--help` output or docs to confirm valid flags before using them
- **Context fan-out**: spawn subagents for read-heavy investigation to preserve main agent context for decision-making
- **LLM-as-judge backpressure**: for subjective criteria (UX, aesthetics), use LLM-as-judge tests with binary pass/fail
- **Compound inline, not in batch sweeps**: compound learnings at end of each work thread — batch sweeps waste cycles and risk push failures
- **Check git log before sweeping**: `git log --since="24 hours ago"` — exit early if no new commits to compound
