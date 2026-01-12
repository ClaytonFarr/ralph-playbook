# The Ralph Playbook

December 2025 boiled [Ralph's](https://ghuntley.com/ralph/) powerful yet dumb little face to the top of most AI-related timelines.

I try to pay attention to the crazy-smart insights [@GeoffreyHuntley](https://x.com/GeoffreyHuntley) shares, but I can't say Ralph really clicked for me this summer. Now, all of the recent hubbub has made it hard to ignore.

[@mattpocockuk](https://x.com/mattpocockuk/status/2008200878633931247) and [@ryancarson](https://x.com/ryancarson/status/2008548371712135632)'s overviews helped a lot - right until Geoff came in and [said 'nah'](https://x.com/GeoffreyHuntley/status/2008731415312236984).

<img src="references/nah.png" alt="nah" width="500" />

## So what is the optimal way to Ralph?

Many folks seem to be getting good results with various shapes - but I wanted to read the tea leaves as closely as possible from the person who not only captured this approach but also has had the most ass-time in the seat putting it through its paces.

So I dug in to really _RTFM_ on [recent videos](https://www.youtube.com/watch?v=O2bBWDoxO4s) and Geoff's [original post](https://ghuntley.com/ralph/) to try and untangle for myself what works best.

Below is the result - a (likely OCD-fueled) Ralph Playbook that organizes the miscellaneous details for putting this all into practice w/o hopefully neutering it in the process.

> Digging into all of this has also brought to mind some possibly valuable [additional enhancements](#enhancements) to the core approach that aim to stay aligned with the guidelines that make Ralph work so well.

> [!TIP]
> [📖 View as Formatted Guide →](https://ClaytonFarr.github.io/ralph-playbook/)

---

## Table of Contents

- [Workflow](#workflow)
- [Key Principles](#key-principles)
- [Loop Mechanics](#loop-mechanics)
- [Files](#files)
- [Enhancements?](#enhancements)

---

## Workflow

A picture is worth a thousand tweets and an hour-long video. Geoff's [overview here](https://ghuntley.com/ralph/) (sign up to his newsletter to see full article) really helped clarify the workflow details for moving from 1) idea → 2) individual JTBD-aligned specs → 3) comprehensive implementation plan → 4) Ralph work loops.

![ralph-diagram.png](references/ralph-diagram.png)

### 🗘 Three Phases, Two Prompts, One Loop

This diagram clarified for me that Ralph isn't just "a loop that codes." It's a funnel with 3 Phases, 2 Prompts, and 1 Loop.

#### Phase 1. Define Requirements (LLM conversation)

- Discuss project ideas → identify Jobs to Be Done (JTBD)
- Break individual JTBD into topic(s) of concern
- Use subagents to load info from URLs into context
- LLM understands JTBD topic of concern: subagent writes `specs/FILENAME.md` for each topic

#### Phase 2 / 3. Run Ralph Loop (two modes, swap `PROMPT.md` as needed)

Same loop mechanism, different prompts for different objectives:

| Mode       | When to use                            | Prompt focus                                            |
| ---------- | -------------------------------------- | ------------------------------------------------------- |
| _PLANNING_ | No plan exists, or plan is stale/wrong | Generate/update `IMPLEMENTATION_PLAN.md` only           |
| _BUILDING_ | Plan exists                            | Implement from plan, commit, update plan as side effect |

_Prompt differences per mode:_

- 'PLANNING' prompt does gap analysis (specs vs code) and outputs a prioritized TODO list—no implementation, no commits.
- 'BUILDING' prompt assumes plan exists, picks tasks from it, implements, runs tests (backpressure), commits.

_Why use the loop for both modes?_

- BUILDING requires it: inherently iterative (many tasks × fresh context = isolation)
- PLANNING uses it for consistency: same execution model, though often completes in 1-2 iterations
- Flexibility: if plan needs refinement, loop allows multiple passes reading its own output
- Simplicity: one mechanism for everything; clean file I/O; easy stop/restart

_Context loaded each iteration:_ `PROMPT.md` + `AGENTS.md`

_PLANNING mode loop lifecycle:_

1. Subagents study `specs/*` and existing `/src`
2. Compare specs against code (gap analysis)
3. Create/update `IMPLEMENTATION_PLAN.md` with prioritized tasks
4. No implementation

_BUILDING mode loop lifecycle:_

1. _Orient_ – subagents study `specs/*` (requirements)
2. _Read plan_ – study `IMPLEMENTATION_PLAN.md`
3. _Select_ – pick the most important task
4. _Investigate_ – subagents study relevant `/src` ("don't assume not implemented")
5. _Implement_ – N subagents for file operations
6. _Validate_ – 1 subagent for build/tests (backpressure)
7. _Update `IMPLEMENTATION_PLAN.md`_ – mark task done, note discoveries/bugs
8. _Update `AGENTS.md`_ – if operational learnings
9. _Commit_
10. _Loop ends_ → context cleared → next iteration starts fresh

#### Concepts

| Term                    | Definition                                                      |
| ----------------------- | --------------------------------------------------------------- |
| _Job to be Done (JTBD)_ | High-level user need or outcome                                 |
| _Topic of Concern_      | A distinct aspect/component within a JTBD                       |
| _Spec_                  | Requirements doc for one topic of concern (`specs/FILENAME.md`) |
| _Task_                  | Unit of work derived from comparing specs to code               |

_Relationships:_

- 1 JTBD → multiple topics of concern
- 1 topic of concern → 1 spec
- 1 spec → multiple tasks (specs are larger than tasks)

_Example:_

- JTBD: "Help designers create mood boards"
- Topics: image collection, color extraction, layout, sharing
- Each topic → one spec file
- Each spec → many tasks in implementation plan

_Topic Scope Test: "One Sentence Without 'And'"_

- Can you describe the topic of concern in one sentence without conjoining unrelated capabilities?
  - ✓ "The color extraction system analyzes images to identify dominant colors"
  - ✗ "The user system handles authentication, profiles, and billing" → 3 topics
- If you need "and" to describe what it does, it's probably multiple topics

---

## Key Principles

### ⏳ Context Is _Everything_

- When 200K+ tokens advertised = ~176K truly usable
- And 40-60% context utilization for "smart zone"
- Tight tasks + 1 task per loop = _100% smart zone context utilization_

This informs and drives everything else:

- _Use the main agent/context as a scheduler_
  - Don't allocate expensive work to main context; spawn subagents whenever possible instead
- _Use subagents as memory extension_
  - Each subagent gets ~156kb that's garbage collected
  - Fan out to avoid polluting main context
- _Simplicity and brevity win_
  - Applies to number of parts in system, loop config, and content
  - Verbose inputs degrade determinism
- _Prefer Markdown over JSON_
  - To define and track work, for better token efficiency

### 🧭 Steering Ralph: Patterns + Backpressure

Creating the right signals & gates to steer Ralph's successful output is **critical**. You can steer from two directions:

- _Steer upstream_
  - Ensure deterministic setup:
    - Allocate first ~5,000 tokens for specs
    - Every loop's context is allocated with the same files so model starts from known state (`PROMPT.md` + `AGENTS.md`)
  - Your existing code shapes what gets used and generated
  - If Ralph is generating wrong patterns, add/update utilities and existing code patterns to steer it toward correct ones
- _Steer downstream_
  - Create backpressure via tests, typechecks, lints, builds, etc. that will reject invalid/unacceptable work
  - Prompt says "run tests" generically. `AGENTS .md` specifies actual commands to make backpressure project-specific
  - Backpressure can extend beyond code validation: some acceptance criteria resist programmatic checks - creative quality, aesthetics, UX feel. LLM-as-judge tests can provide backpressure for subjective criteria with binary pass/fail. ([More detailed thoughts below](#non-deterministic-backpressure) on how to approach this with Ralph.)
- _Remind Ralph to create/use backpressure_
  - Remind Ralph to use backpressure when implementing: "Important: When authoring documentation, capture the why — tests and implementation importance."

### 🙏 Let Ralph Ralph

Ralph's effectiveness comes from how much you trust it do the right thing (eventually) and engender its ability to do so.

- _Let Ralph Ralph_
  - Lean into LLM's ability to self-identify, self-correct and self-improve
  - Applies to implementation plan, task definition and prioritization
  - Eventual consistency achieved through iteration
- _Use protection_
  - To operate autonomously, Ralph requires `--dangerously-skip-permissions` - asking for approval on every tool call would break the loop. This bypasses Claude's permission system entirely - so a sandbox becomes your only security boundary.
  - Philosophy: "It's not if it gets popped, it's when. And what is the blast radius?"
  - Running without a sandbox exposes credentials, browser cookies, SSH keys, and access tokens on your machine
  - Run in isolated environments with minimum viable access:
    - Only the API keys and deploy keys needed for the task
    - No access to private data beyond requirements
    - Restrict network connectivity where possible
  - Options: Docker sandboxes (local), Fly Sprites/E2B/etc. (remote/production) - [additional notes](references/sandbox-environments.md)
  - Additional escape hatches: Ctrl+C stops the loop; `git reset --hard` reverts uncommitted changes; regenerate plan if trajectory goes wrong

### 🚦 Move Outside the Loop

To get the most out of Ralph, you need to get out of his way. Ralph should be doing _all_ of the work, including decided which planned work to implement next and how to implement it. Your job is now to sit on the loop, not in it - to engineer the setup and environment that will allow Ralph to succeed.

_Observe and course correct_ – especially early on, sit and watch. What patterns emerge? Where does Ralph go wrong? What signs does he need? The prompts you start with won't be the prompts you end with - they evolve through observed failure patterns.

_Tune it like a guitar_ – instead of prescribing everything upfront, observe and adjust reactively. When Ralph fails a specific way, add a sign to help him next time.

But signs aren't just prompt text. They're _anything_ Ralph can discover:

- Prompt guardrails - explicit instructions like "don't assume not implemented"
- `AGENTS .md` - operational learnings about how to build/test
- Utilities in your codebase - when you add a pattern, Ralph discovers it and follows it
- Other discoverable, relevant inputs…

And remember, _the plan is disposable:_

- If it's wrong, throw it out, and start over
- Regeneration cost is one Planning loop; cheap compared to Ralph going in circles
- Regenerate when:
  - Ralph is going off track (implementing wrong things, duplicating work)
  - Plan feels stale or doesn't match current state
  - Too much clutter from completed items
  - You've made significant spec changes
  - You're confused about what's actually done

---

## Loop Mechanics

### Outer Loop Control

Geoff's initial minimal form of `loop.sh` script:

```bash
while :; do cat PROMPT.md | claude ; done
```

_Note:_ The same approach can be used with other CLIs; e.g. `amp`, `codex`, `opencode`, etc.

_What controls task continuation?_

The continuation mechanism is elegantly simple:

1. _Bash loop runs_ → feeds `PROMPT.md` to claude
2. _PROMPT.md instructs_ → "Study IMPLEMENTATION_PLAN.md and choose the most important thing"
3. _Agent completes one task_ → updates IMPLEMENTATION_PLAN.md on disk, commits, exits
4. _Bash loop restarts immediately_ → fresh context window
5. _Agent reads updated plan_ → picks next most important thing

_Key insight:_ The IMPLEMENTATION_PLAN.md file persists on disk between iterations and acts as shared state between otherwise isolated loop executions. Each iteration deterministically loads the same files (`PROMPT.md` + `AGENTS.md` + `specs/*`) and reads the current state from disk.

_No sophisticated orchestration needed_ - just a dumb bash loop that keeps restarting the agent, and the agent figures out what to do next by reading the plan file each time.

### Inner Loop Control (Task Execution)

A single task execution has no hard technical limit. Control relies on:

- _Scope discipline_ - PROMPT.md instructs "one task" and "commit when tests pass"
- _Backpressure_ - tests/build failures force the agent to fix issues before committing
- _Natural completion_ - agent exits after successful commit

_Ralph can go in circles, ignore instructions, or take wrong directions_ - this is expected and part of the tuning process. When Ralph "tests you" by failing in specific ways, you add guardrails to the prompt or adjust backpressure mechanisms. The nondeterminism is manageable through observation and iteration.

### Enhanced Loop Example

Wraps core loop with mode selection (plan/build), max-iterations support, and git push after each iteration.

_This enhancement uses two saved prompt files:_

- `PROMPT_plan.md` - Planning mode (gap analysis, generates/updates plan)
- `PROMPT_build.md` - Building mode (implements from plan)

```bash
#!/bin/bash
# Usage: ./loop.sh [plan] [max_iterations]
# Examples:
#   ./loop.sh              # Build mode, unlimited iterations
#   ./loop.sh 20           # Build mode, max 20 iterations
#   ./loop.sh plan         # Plan mode, unlimited iterations
#   ./loop.sh plan 5       # Plan mode, max 5 iterations

# Parse arguments
if [ "$1" = "plan" ]; then
    # Plan mode
    MODE="plan"
    PROMPT_FILE="PROMPT_plan.md"
    MAX_ITERATIONS=${2:-0}
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    # Build mode with max iterations
    MODE="build"
    PROMPT_FILE="PROMPT_build.md"
    MAX_ITERATIONS=$1
else
    # Build mode, unlimited (no arguments or invalid input)
    MODE="build"
    PROMPT_FILE="PROMPT_build.md"
    MAX_ITERATIONS=0
fi

ITERATION=0
CURRENT_BRANCH=$(git branch --show-current)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Mode:   $MODE"
echo "Prompt: $PROMPT_FILE"
echo "Branch: $CURRENT_BRANCH"
[ $MAX_ITERATIONS -gt 0 ] && echo "Max:    $MAX_ITERATIONS iterations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Verify prompt file exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: $PROMPT_FILE not found"
    exit 1
fi

while true; do
    if [ $MAX_ITERATIONS -gt 0 ] && [ $ITERATION -ge $MAX_ITERATIONS ]; then
        echo "Reached max iterations: $MAX_ITERATIONS"
        break
    fi

    # Run Ralph iteration with selected prompt
    # -p: Headless mode (non-interactive, reads from stdin)
    # --dangerously-skip-permissions: Auto-approve all tool calls (YOLO mode)
    # --output-format=stream-json: Structured output for logging/monitoring
    # --model opus: Primary agent uses Opus for complex reasoning (task selection, prioritization)
    #               Can use 'sonnet' in build mode for speed if plan is clear and tasks well-defined
    # --verbose: Detailed execution logging
    cat "$PROMPT_FILE" | claude -p \
        --dangerously-skip-permissions \
        --output-format=stream-json \
        --model opus \
        --verbose

    # Push changes after each iteration
    git push origin "$CURRENT_BRANCH" || {
        echo "Failed to push. Creating remote branch..."
        git push -u origin "$CURRENT_BRANCH"
    }

    ITERATION=$((ITERATION + 1))
    echo -e "\n\n======================== LOOP $ITERATION ========================\n"
done
```

_Mode selection:_

- No keyword → Uses `PROMPT_build.md` for building (implementation)
- `plan` keyword → Uses `PROMPT_plan.md` for planning (gap analysis, plan generation)

_Max-iterations:_

- Limits the _outer loop_ (number of tasks attempted; NOT tool calls within a single task)
- Each iteration = one fresh context window = one task from IMPLEMENTATION_PLAN.md = one commit
- `./loop.sh` runs unlimited (manual stop with Ctrl+C)
- `./loop.sh 20` runs max 20 iterations then stops

_Claude CLI flags:_

- `-p` (headless mode): Enables non-interactive operation, reads prompt from stdin
- `--dangerously-skip-permissions`: Bypasses all permission prompts for fully automated runs
- `--output-format=stream-json`: Outputs structured JSON for logging/monitoring/visualization
- `--model opus`: Primary agent uses Opus for task selection, prioritization, and coordination (can use `sonnet` for speed if tasks are clear)
- `--verbose`: Provides detailed execution logging

---

## Files

```
project-root/
├── loop.sh                         # Ralph loop script
├── PROMPT_build.md                 # Build mode instructions
├── PROMPT_plan.md                  # Plan mode instructions
├── AGENTS.md                       # Operational guide loaded each iteration
├── IMPLEMENTATION_PLAN.md          # Prioritized task list (generated/updated by Ralph)
├── specs/                          # Requirement specs (one per JTBD topic)
│   ├── [jtbd-topic-a].md
│   └── [jtbd-topic-b].md
├── src/                            # Application source code
└── src/lib/                        # Shared utilities & components
```

### `loop.sh`

The outer loop script that orchestrates Ralph iterations.

See [Loop Mechanics](#loop-mechanics) section for detailed implementation examples and configuration options.

_Setup:_ Make the script executable before first use:

```bash
chmod +x loop.sh
```

_Core function:_ Continuously feeds prompt file to claude, manages iteration limits, and pushes changes after each task completion.

### PROMPTS

The instruction set for each loop iteration. Swap between PLANNING and BUILDING versions as needed.

_Prompt Structure:_

| Section                | Purpose                                               |
| ---------------------- | ----------------------------------------------------- |
| _Phase 0_ (0a, 0b, 0c) | Orient: study specs, source location, current plan    |
| _Phase 1-4_            | Main instructions: task, validation, commit           |
| _999... numbering_     | Guardrails/invariants (higher number = more critical) |

_Key Language Patterns_ (Geoff's specific phrasing):

- "study" (not "read" or "look at")
- "don't assume not implemented" (critical - the Achilles' heel)
- "using parallel subagents" / "up to N subagents"
- "only 1 subagent for build/tests" (backpressure control)
- "Think extra hard" (now "Ultrathink)
- "capture the why"
- "keep it up to date"
- "if functionality is missing then it's your job to add it"
- "resolve them or document them"

#### `PROMPT_plan.md` Template

_Notes:_

- Update [project-specific goal] placeholder below.
- Current subagents names presume using Claude.

```
0a. Study `specs/*` with up to 250 parallel Sonnet subagents to learn the application specifications.
0b. Study @IMPLEMENTATION_PLAN.md (if present) to understand the plan so far.
0c. Study `src/lib/*` with up to 250 parallel Sonnet subagents to understand shared utilities & components.
0d. For reference, the application source code is in `src/*`.

1. Study @IMPLEMENTATION_PLAN.md (if present; it may be incorrect) and use up to 500 Sonnet subagents to study existing source code in `src/*` and compare it against `specs/*`. Use an Opus subagent to analyze findings, prioritize tasks, and create/update @IMPLEMENTATION_PLAN.md as a bullet point list sorted in priority of items yet to be implemented. Ultrathink. Consider searching for TODO, minimal implementations, placeholders, skipped/flaky tests, and inconsistent patterns. Study @IMPLEMENTATION_PLAN.md to determine starting point for research and keep it up to date with items considered complete/incomplete using subagents.

IMPORTANT: Plan only. Do NOT implement anything. Do NOT assume functionality is missing; confirm with code search first. Treat `src/lib` as the project's standard library for shared utilities and components. Prefer consolidated, idiomatic implementations there over ad-hoc copies.

ULTIMATE GOAL: We want to achieve [project-specific goal]. Consider missing elements and plan accordingly. If an element is missing, search first to confirm it doesn't exist, then if needed author the specification at specs/FILENAME.md. If you create a new element then document the plan to implement it in @IMPLEMENTATION_PLAN.md using a subagent.
```

#### `PROMPT_build.md` Template

_Note:_ Current subagents names presume using Claude.

```
0a. Study `specs/*` with up to 500 parallel Sonnet subagents to learn the application specifications.
0b. Study @IMPLEMENTATION_PLAN.md.
0c. For reference, the application source code is in `src/*`.

1. Your task is to implement functionality per the specifications using parallel subagents. Follow @IMPLEMENTATION_PLAN.md and choose the most important item to address. Before making changes, search the codebase (don't assume not implemented) using Sonnet subagents. You may use up to 500 parallel Sonnet subagents for searches/reads and only 1 Sonnet subagent for build/tests. Use Opus subagents when complex reasoning is needed (debugging, architectural decisions).
2. After implementing functionality or resolving problems, run the tests for that unit of code that was improved. If functionality is missing then it's your job to add it as per the application specifications. Ultrathink.
3. When you discover issues, immediately update @IMPLEMENTATION_PLAN.md with your findings using a subagent. When resolved, update and remove the item.
4. When the tests pass, update @IMPLEMENTATION_PLAN.md, then `git add -A` then `git commit` with a message describing the changes. After the commit, `git push`.

99999. Important: When authoring documentation, capture the why — tests and implementation importance.
999999. Important: Single sources of truth, no migrations/adapters. If tests unrelated to your work fail, resolve them as part of the increment.
9999999. As soon as there are no build or test errors create a git tag. If there are no git tags start at 0.0.0 and increment patch by 1 for example 0.0.1  if 0.0.0 does not exist.
99999999. You may add extra logging if required to debug issues.
999999999. Keep @IMPLEMENTATION_PLAN.md current with learnings using a subagent — future work depends on this to avoid duplicating efforts. Update especially after finishing your turn.
9999999999. When you learn something new about how to run the application, update @AGENTS.md using a subagent but keep it brief. For example if you run commands multiple times before learning the correct command then that file should be updated.
99999999999. For any bugs you notice, resolve them or document them in @IMPLEMENTATION_PLAN.md using a subagent even if it is unrelated to the current piece of work.
999999999999. Implement functionality completely. Placeholders and stubs waste efforts and time redoing the same work.
9999999999999. When @IMPLEMENTATION_PLAN.md becomes large periodically clean out the items that are completed from the file using a subagent.
99999999999999. If you find inconsistencies in the specs/* then use an Opus 4.5 subagent with 'ultrathink' requested to update the specs.
999999999999999. IMPORTANT: Keep @AGENTS.md operational only — status updates and progress notes belong in `IMPLEMENTATION_PLAN.md`. A bloated AGENTS.md pollutes every future loop's context.
```

### `AGENTS.md`

Single, canonical "heart of the loop" - a concise, operational "how to run/build" guide.

- NOT a changelog or progress diary
- Describes how to build/run the project
- Captures operational learnings that improve the loop
- Keep brief (~60 lines)

Status, progress, and planning belong in `IMPLEMENTATION_PLAN.md`, not here.

_Loopback / Immediate Self-Evaluation:_

AGENTS.md should contain the project-specific commands that enable loopback - the ability for Ralph to immediately evaluate his work within the same loop. This includes:

- Build commands
- Test commands (targeted and full suite)
- Typecheck/lint commands
- Any other validation tools

The BUILDING prompt says "run tests" generically; AGENTS.md specifies the actual commands. This is how backpressure gets wired in per-project.

#### Example

```
## Build & Run

Succinct rules for how to BUILD the project:

## Validation

Run these after implementing to get immediate feedback:

- Tests: `[test command]`
- Typecheck: `[typecheck command]`
- Lint: `[lint command]`

## Operational Notes

Succinct learnings about how to RUN the project:

...

### Codebase Patterns

...
```

### `IMPLEMENTATION_PLAN.md`

Prioritized bullet-point list of tasks derived from gap analysis (specs vs code) - generated by Ralph.

- _Created_ via PLANNING mode
- _Updated_ during BUILDING mode (mark complete, add discoveries, note bugs)
- _Can be regenerated_ – Geoff: "I have deleted the TODO list multiple times" → switch to PLANNING mode
- _Self-correcting_ – BUILDING mode can even create new specs if missing

The circularity is intentional: eventual consistency through iteration.

_No pre-specified template_ - let Ralph/LLM dictate and manage format that works best for it.

### `specs/*`

One markdown file per topic of concern. These are the source of truth for what should be built.

- Created during Requirements phase (human + LLM conversation)
- Consumed by both PLANNING and BUILDING modes
- Can be updated if inconsistencies discovered (rare, use subagent)

_No pre-specified template_ - let Ralph/LLM dictate and manage format that works best for it.

### `src/` and `src/lib/`

Application source code and shared utilities/components.

Referenced in `PROMPT.md` templates for orientation steps.

---

## Enhancements?

I'm (Clayton) still determining the value/viability of these possible enhancements, but the opportunities sound promising.

I'm still determining the value/viability of these, but the opportunities sound promising:

- [Claude's AskUserQuestionTool for Planning](#use-claudes-askuserquestiontool-for-planning) - use Claude's built-in interview tool to systematically clarify JTBD, edge cases, and acceptance criteria for specs.
- [Acceptance-Driven Backpressure](#acceptance-driven-backpressure) - Derive test requirements during planning from acceptance criteria. Prevents "cheating" - can't claim done without appropriate tests passing.
- [Non-Deterministic Backpressure](#non-deterministic-backpressure) - Using LLM-as-judge for tests against subjective tasks (tone, aesthetics, UX). Binary pass/fail reviews that iterate until pass.
- [Ralph-Friendly Work Branches](#ralph-friendly-work-branches) - Asking Ralph to "filter to feature X" at runtime is unreliable. Instead, create scoped plan per branch upfront.
- [JTBD → Story Map → SLC Release](#jtbd--story-map--slc-release) - Push the power of "Letting Ralph Ralph" to connect JTBD's audience and activities to Simple/Lovable/Complete releases.

---

### Use Claude's AskUserQuestionTool for Planning

During Phase 1 (Define Requirements), use Claude's built-in `AskUserQuestionTool` to systematically explore JTBD, topics of concern, edge cases, and acceptance criteria through structured interview before writing specs.

_When to use:_ Minimal/vague initial requirements, need to clarify constraints, or multiple valid approaches exist.

_Invoke:_ "Interview me using AskUserQuestion to understand [JTBD/topic/acceptance criteria/...]"

Claude will ask targeted questions to clarify requirements and ensure alignment before producing `specs/*.md` files.

_Flow:_

1. Start with known information →
2. _Claude interviews via AskUserQuestion_ →
3. Iterate until clear →
4. Claude writes specs with acceptance criteria →
5. Proceed to planning/building

No code or prompt changes needed - this simply enhances Phase 1 using existing Claude Code capabilities.

_Inspiration_ - [Thariq's X post](https://x.com/trq212/status/2005315275026260309):

---

### Acceptance-Driven Backpressure

Geoff's Ralph _implicitly_ connects specs → implementation → tests through emergent iteration. This enhancement would make that connection _explicit_ by deriving test requirements during planning, creating a direct line from "what success looks like" to "what verifies it."

This enhancement connects acceptance criteria (in specs) directly to test requirements (in implementation plan), improving backpressure quality by:

- _Preventing "no cheating"_ - Can't claim done without required tests derived from acceptance criteria
- _Enabling TDD workflow_ - Test requirements known before implementation starts
- _Improving convergence_ - Clear completion signal (required tests pass) vs ambiguous ("seems done?")
- _Maintaining determinism_ - Test requirements in plan (known state) not emergent (probabilistic)

#### Compatibility with Core Philosophy

| Principle             | Maintained? | How                                                         |
| --------------------- | ----------- | ----------------------------------------------------------- |
| Monolithic operation  | ✅ Yes      | One agent, one task, one loop at a time                     |
| Backpressure critical | ✅ Yes      | Tests are the mechanism, just derived explicitly now        |
| Context efficiency    | ✅ Yes      | Planning decides tests once vs building rediscovering       |
| Deterministic setup   | ✅ Yes      | Test requirements in plan (known state) not emergent        |
| Let Ralph Ralph       | ✅ Yes      | Ralph still prioritizes and chooses implementation approach |
| Plan is disposable    | ✅ Yes      | Wrong test requirements? Regenerate plan                    |
| "Capture the why"     | ✅ Yes      | Test intent documented in plan before implementation        |
| No cheating           | ✅ Yes      | Required tests prevent placeholder implementations          |

#### The Prescriptiveness Balance

The critical distinction:

_Acceptance criteria_ (in specs) = Behavioral outcomes, observable results, what success looks like

- ✅ "Extracts 5-10 dominant colors from any uploaded image"
- ✅ "Processes images <5MB in <100ms"
- ✅ "Handles edge cases: grayscale, single-color, transparent backgrounds"

_Test requirements_ (in implementation plan) = Verification points derived from acceptance criteria

- ✅ "Required tests: Extract 5-10 colors, Performance <100ms, Handle grayscale edge case"

_Implementation approach_ (up to Ralph) = Technical decisions about how to achieve it

- ❌ "Use K-means clustering with 3 iterations and LAB color space conversion"

The key: _Specify WHAT to verify (outcomes), not HOW to implement (approach)_

This maintains "Let Ralph Ralph" principle - Ralph decides implementation details while having clear success signals.

#### Architecture: Three-Phase Connection

```
Phase 1: Requirements Definition
    specs/*.md + Acceptance Criteria
    ↓
Phase 2: Planning (derives test requirements)
    IMPLEMENTATION_PLAN.md + Required Tests
    ↓
Phase 3: Building (implements with tests)
    Implementation + Tests → Backpressure
```

#### Phase 1: Requirements Definition

During the human + LLM conversation that produces specs:

- Discuss JTBD and break into topics of concern
- Use subagents to load external context as needed
- _Discuss and define acceptance criteria_ - what observable, verifiable outcomes indicate success
- Keep criteria behavioral (outcomes), not implementation (how to build it)
- LLM writes specs including acceptance criteria however makes most sense for the spec
- Acceptance criteria become the foundation for deriving test requirements in planning phase

#### Phase 2: Planning Mode Enhancement

Modify `PROMPT_plan.md` instruction 1 to include test derivation. Add after the first sentence:

```markdown
For each task in the plan, derive required tests from acceptance criteria in specs - what specific outcomes need verification (behavior, performance, edge cases). Tests verify WHAT works, not HOW it's implemented. Include as part of task definition.
```

#### Phase 3: Building Mode Enhancement

Modify `PROMPT_build.md` instructions:

_Instruction 1:_ Add after "choose the most important item to address":

```markdown
Tasks include required tests - implement tests as part of task scope.
```

_Instruction 2:_ Replace "run the tests for that unit of code" with:

```markdown
run all required tests specified in the task definition. All required tests must exist and pass before the task is considered complete.
```

_Prepend new guardrail_ (in the 9s sequence):

```markdown
999. Required tests derived from acceptance criteria must exist and pass before committing. Tests are part of implementation scope, not optional. Test-driven development approach: tests can be written first or alongside implementation.
```

---

### Non-Deterministic Backpressure

Some acceptance criteria resist programmatic validation:

- _Creative quality_ - Writing tone, narrative flow, engagement
- _Aesthetic judgments_ - Visual harmony, design balance, brand consistency
- _UX quality_ - Intuitive navigation, clear information hierarchy
- _Content appropriateness_ - Context-aware messaging, audience fit

These require human-like judgment but need backpressure to meet acceptance criteria during building loop.

_Solution:_ Add LLM-as-Judge tests as backpressure with binary pass/fail.

LLM reviews are non-deterministic (same artifact may receive different judgments across runs). This aligns with Ralph philosophy: "deterministically bad in an undeterministic world." The loop provides eventual consistency through iteration—reviews run until pass, accepting natural variance.

#### What Needs to Be Created (First Step)

Create two files in `src/lib/`:

```
src/lib/
  llm-review.ts          # Core fixture - single function, clean API
  llm-review.test.ts     # Reference examples showing the pattern (Ralph learns from these)
```

##### `llm-review.ts` - Binary pass/fail API Ralph discovers:

```typescript
interface ReviewResult {
  pass: boolean;
  feedback?: string; // Only present when pass=false
}

function createReview(config: {
  criteria: string; // What to evaluate (behavioral, observable)
  artifact: string; // Text content OR screenshot path
  intelligence?: "fast" | "smart"; // Optional, defaults to 'fast'
}): Promise<ReviewResult>;
```

_Multimodal support:_ Both intelligence levels would use multimodal model (text + vision). Artifact type detection is automatic:

- Text evaluation: `artifact: "Your content here"` → Routes as text input
- Vision evaluation: `artifact: "./tmp/screenshot.png"` → Routes as vision input (detects .png, .jpg, .jpeg extensions)

_Intelligence levels_ (quality of judgment, not capability type):

- `fast` (default): Quick, cost-effective models for straightforward evaluations
  - Example: Gemini 3.0 Flash (multimodal, fast, cheap)
- `smart`: Higher-quality models for nuanced aesthetic/creative judgment
  - Example: GPT 5.1 (multimodal, better judgment, higher cost)

The fixture implementation selects appropriate models. (Examples are current options, not requirements.)

##### `llm-review.test.ts` - Shows Ralph how to use it (text and vision examples):

```typescript
import { createReview } from "@/lib/llm-review";

// Example 1: Text evaluation
test("welcome message tone", async () => {
  const message = generateWelcomeMessage();
  const result = await createReview({
    criteria:
      "Message uses warm, conversational tone appropriate for design professionals while clearly conveying value proposition",
    artifact: message, // Text content
  });
  expect(result.pass).toBe(true);
});

// Example 2: Vision evaluation (screenshot path)
test("dashboard visual hierarchy", async () => {
  await page.screenshot({ path: "./tmp/dashboard.png" });
  const result = await createReview({
    criteria:
      "Layout demonstrates clear visual hierarchy with obvious primary action",
    artifact: "./tmp/dashboard.png", // Screenshot path
  });
  expect(result.pass).toBe(true);
});

// Example 3: Smart intelligence for complex judgment
test("brand visual consistency", async () => {
  await page.screenshot({ path: "./tmp/homepage.png" });
  const result = await createReview({
    criteria:
      "Visual design maintains professional brand identity suitable for financial services while avoiding corporate sterility",
    artifact: "./tmp/homepage.png",
    intelligence: "smart", // Complex aesthetic judgment
  });
  expect(result.pass).toBe(true);
});
```

_Ralph learns from these examples:_ Both text and screenshots work as artifacts. Choose based on what needs evaluation. The fixture handles the rest internally.

_Future extensibility:_ Current design uses single `artifact: string` for simplicity. Can expand to `artifact: string | string[]` if clear patterns emerge requiring multiple artifacts (before/after comparisons, consistency across items, multi-perspective evaluation). Composite screenshots or concatenated text could handle most multi-item needs.

#### Integration with Ralph Workflow

_Planning Phase_ - Update `PROMPT_plan.md`:

After:

```
...Study @IMPLEMENTATION_PLAN.md to determine starting point for research and keep it up to date with items considered complete/incomplete using subagents.
```

Insert this:

```
When deriving test requirements from acceptance criteria, identify whether verification requires programmatic validation (measurable, inspectable) or human-like judgment (perceptual quality, tone, aesthetics). Both types are equally valid backpressure mechanisms. For subjective criteria that resist programmatic validation, explore src/lib for non-deterministic evaluation patterns.
```

_Building Phase_ - Update `PROMPT_build.md`:

Prepend new guardrail (in the 9s sequence):

```markdown
9999. Create tests to verify implementation meets acceptance criteria and include both conventional tests (behavior, performance, correctness) and perceptual quality tests (for subjective criteria, see src/lib patterns).
```

_Discovery, not documentation:_ Ralph learns LLM review patterns from `llm-review.test.ts` examples during `src/lib` exploration (Phase 0c). No AGENTS.md updates needed - the code examples are the documentation.

#### Compatibility with Core Philosophy

| Principle             | Maintained? | How                                                                                                                                          |
| --------------------- | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Backpressure critical | ✅ Yes      | Extends backpressure to non-programmatic acceptance                                                                                          |
| Deterministic setup   | ⚠️ Partial  | Criteria in plan (deterministic), evaluation non-deterministic but converges through iteration. Intentional tradeoff for subjective quality. |
| Context efficiency    | ✅ Yes      | Fixture reused via `src/lib`, small test definitions                                                                                         |
| Let Ralph Ralph       | ✅ Yes      | Ralph discovers pattern, chooses when to use, writes criteria                                                                                |
| Plan is disposable    | ✅ Yes      | Review requirements part of plan, regenerate if wrong                                                                                        |
| Simplicity wins       | ✅ Yes      | Single function, binary result, no scoring complexity                                                                                        |
| Add signs for Ralph   | ✅ Yes      | Light prompt additions, learning from code exploration                                                                                       |

---

### Ralph-Friendly Work Branches

_The Critical Principle:_ Geoff's Ralph works from a single, disposable plan where Ralph picks "most important." To use branches with Ralph while maintaining this pattern, you must scope at plan creation, not at task selection.

_Why this matters:_

- ❌ _Wrong approach_: Create full plan, then ask Ralph to "filter" tasks at runtime → unreliable (70-80%), violates determinism
- ✅ _Right approach_: Create a scoped plan upfront for each work branch → deterministic, simple, maintains "plan is disposable"

_Solution:_ Add a `plan-work` mode to create a work-scoped IMPLEMENTATION_PLAN.md on the current branch. User creates work branch, then runs `plan-work` with a natural language description of the work focus. The LLM uses this description to scope the plan. Post planning, Ralph builds from this already-scoped plan with zero semantic filtering - just picks "most important" as always.

_Terminology:_ "Work" is intentionally broad - it can describe features, topics of concern, refactoring efforts, infrastructure changes, bug fixes, or any coherent body of related changes. The work description you pass to `plan-work` is natural language for the LLM - it can be prose, not constrained by git branch naming rules.

#### Design Principles

- ✅ _Each Ralph session operates monolithically_ on ONE body of work per branch
- ✅ _User creates branches manually_ - full control over naming conventions and strategy (e.g. worktrees)
- ✅ _Natural language work descriptions_ - pass prose to LLM, unconstrained by git naming rules
- ✅ _Scoping at plan creation_ (deterministic) not task selection (probabilistic)
- ✅ _Single plan per branch_ - one IMPLEMENTATION_PLAN.md per branch
- ✅ _Plan remains disposable_ - regenerate scoped plan when wrong/stale for a branch
- ✅ No dynamic branch switching within a loop session
- ✅ Maintains simplicity and determinism
- ✅ Optional - main branch workflow still works
- ✅ No semantic filtering at build time - Ralph just picks "most important"

#### Workflow

_1. Full Planning (on main branch)_

```bash
./loop.sh plan
# Generate full IMPLEMENTATION_PLAN.md for entire project
```

_2. Create Work Branch_

User performs:

```bash
git checkout -b ralph/user-auth-oauth
# Create branch with whatever naming convention you prefer
# Suggestion: ralph/* prefix for work branches
```

_3. Scoped Planning (on work branch)_

```bash
./loop.sh plan-work "user authentication system with OAuth and session management"
# Pass natural language description - LLM uses this to scope the plan
# Creates focused IMPLEMENTATION_PLAN.md with only tasks for this work
```

_4. Build from Plan (on work branch)_

```bash
./loop.sh
# Ralph builds from scoped plan (no filtering needed)
# Picks most important task from already-scoped plan
```

_5. PR Creation (when work complete)_

User performs:

```bash
gh pr create --base main --head ralph/user-auth-oauth --fill
```

#### Work-Scoped Loop Script

Extends the base enhanced loop script to add work branch support with scoped planning:

```bash
#!/bin/bash
set -euo pipefail

# Usage:
#   ./loop.sh [plan] [max_iterations]       # Plan/build on current branch
#   ./loop.sh plan-work "work description"  # Create scoped plan on current branch
# Examples:
#   ./loop.sh                               # Build mode, unlimited
#   ./loop.sh 20                            # Build mode, max 20
#   ./loop.sh plan 5                        # Full planning, max 5
#   ./loop.sh plan-work "user auth"         # Scoped planning

# Parse arguments
MODE="build"
PROMPT_FILE="PROMPT_build.md"

if [ "$1" = "plan" ]; then
    # Full planning mode
    MODE="plan"
    PROMPT_FILE="PROMPT_plan.md"
    MAX_ITERATIONS=${2:-0}
elif [ "$1" = "plan-work" ]; then
    # Scoped planning mode
    if [ -z "$2" ]; then
        echo "Error: plan-work requires a work description"
        echo "Usage: ./loop.sh plan-work \"description of the work\""
        exit 1
    fi
    MODE="plan-work"
    WORK_DESCRIPTION="$2"
    PROMPT_FILE="PROMPT_plan_work.md"
    MAX_ITERATIONS=${3:-5}  # Default 5 for work planning
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    # Build mode with max iterations
    MAX_ITERATIONS=$1
else
    # Build mode, unlimited
    MAX_ITERATIONS=0
fi

ITERATION=0
CURRENT_BRANCH=$(git branch --show-current)

# Validate branch for plan-work mode
if [ "$MODE" = "plan-work" ]; then
    if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
        echo "Error: plan-work should be run on a work branch, not main/master"
        echo "Create a work branch first: git checkout -b ralph/your-work"
        exit 1
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Mode:    plan-work"
    echo "Branch:  $CURRENT_BRANCH"
    echo "Work:    $WORK_DESCRIPTION"
    echo "Prompt:  $PROMPT_FILE"
    echo "Plan:    Will create scoped IMPLEMENTATION_PLAN.md"
    [ "$MAX_ITERATIONS" -gt 0 ] && echo "Max:     $MAX_ITERATIONS iterations"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Warn about uncommitted changes to IMPLEMENTATION_PLAN.md
    if [ -f "IMPLEMENTATION_PLAN.md" ] && ! git diff --quiet IMPLEMENTATION_PLAN.md 2>/dev/null; then
        echo "Warning: IMPLEMENTATION_PLAN.md has uncommitted changes that will be overwritten"
        read -p "Continue? [y/N] " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    fi

    # Export work description for PROMPT_plan_work.md
    export WORK_SCOPE="$WORK_DESCRIPTION"
else
    # Normal plan/build mode
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Mode:   $MODE"
    echo "Branch: $CURRENT_BRANCH"
    echo "Prompt: $PROMPT_FILE"
    echo "Plan:   IMPLEMENTATION_PLAN.md"
    [ "$MAX_ITERATIONS" -gt 0 ] && echo "Max:    $MAX_ITERATIONS iterations"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

# Verify prompt file exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: $PROMPT_FILE not found"
    exit 1
fi

# Main loop
while true; do
    if [ "$MAX_ITERATIONS" -gt 0 ] && [ "$ITERATION" -ge "$MAX_ITERATIONS" ]; then
        echo "Reached max iterations: $MAX_ITERATIONS"

        if [ "$MODE" = "plan-work" ]; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Scoped plan created: $WORK_DESCRIPTION"
            echo "To build, run:"
            echo "  ./loop.sh 20"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        fi
        break
    fi

    # Run Ralph iteration with selected prompt
    # -p: Headless mode (non-interactive, reads from stdin)
    # --dangerously-skip-permissions: Auto-approve all tool calls (YOLO mode)
    # --output-format=stream-json: Structured output for logging/monitoring
    # --model opus: Primary agent uses Opus for complex reasoning (task selection, prioritization)
    #               Can use 'sonnet' for speed if plan is clear and tasks well-defined
    # --verbose: Detailed execution logging

    # For plan-work mode, substitute ${WORK_SCOPE} in prompt before piping
    if [ "$MODE" = "plan-work" ]; then
        envsubst < "$PROMPT_FILE" | claude -p \
            --dangerously-skip-permissions \
            --output-format=stream-json \
            --model opus \
            --verbose
    else
        cat "$PROMPT_FILE" | claude -p \
            --dangerously-skip-permissions \
            --output-format=stream-json \
            --model opus \
            --verbose
    fi

    # Push to current branch
    CURRENT_BRANCH=$(git branch --show-current)
    git push origin "$CURRENT_BRANCH" || {
        echo "Failed to push. Creating remote branch..."
        git push -u origin "$CURRENT_BRANCH"
    }

    ITERATION=$((ITERATION + 1))
    echo -e "\n\n======================== LOOP $ITERATION ========================\n"
done
```

#### `PROMPT_plan_work.md` Template

_Note:_ Identical to `PROMPT_plan.md` but with scoping instructions and `WORK_SCOPE` env var substituted (automatically by the loop script).

```
0a. Study `specs/*` with up to 250 parallel Sonnet subagents to learn the application specifications.
0b. Study @IMPLEMENTATION_PLAN.md (if present) to understand the plan so far.
0c. Study `src/lib/*` with up to 250 parallel Sonnet subagents to understand shared utilities & components.
0d. For reference, the application source code is in `src/*`.

1. You are creating a SCOPED implementation plan for work: "${WORK_SCOPE}". Study @IMPLEMENTATION_PLAN.md (if present; it may be incorrect) and use up to 500 Sonnet subagents to study existing source code in `src/*` and compare it against `specs/*`. Use an Opus subagent to analyze findings, prioritize tasks, and create/update @IMPLEMENTATION_PLAN.md as a bullet point list sorted in priority of items yet to be implemented. Ultrathink. Consider searching for TODO, minimal implementations, placeholders, skipped/flaky tests, and inconsistent patterns. Study @IMPLEMENTATION_PLAN.md to determine starting point for research and keep it up to date with items considered complete/incomplete using subagents.

IMPORTANT: This is SCOPED PLANNING for "${WORK_SCOPE}" only. Create a plan containing ONLY tasks directly related to this work scope. Be conservative - if uncertain whether a task belongs to this work, exclude it. The plan can be regenerated if too narrow. Plan only. Do NOT implement anything. Do NOT assume functionality is missing; confirm with code search first. Treat `src/lib` as the project's standard library for shared utilities and components. Prefer consolidated, idiomatic implementations there over ad-hoc copies.

ULTIMATE GOAL: We want to achieve the scoped work "${WORK_SCOPE}". Consider missing elements related to this work and plan accordingly. If an element is missing, search first to confirm it doesn't exist, then if needed author the specification at specs/FILENAME.md. If you create a new element then document the plan to implement it in @IMPLEMENTATION_PLAN.md using a subagent.
```

#### Compatibility with Core Philosophy

| Principle              | Maintained? | How                                                                      |
| ---------------------- | ----------- | ------------------------------------------------------------------------ |
| Monolithic operation   | ✅ Yes      | Ralph still operates as single process within branch                     |
| One task per loop      | ✅ Yes      | Unchanged                                                                |
| Fresh context          | ✅ Yes      | Unchanged                                                                |
| Deterministic          | ✅ Yes      | Scoping at plan creation (deterministic), not runtime (prob.)            |
| Simple                 | ✅ Yes      | Optional enhancement, main workflow still works                          |
| Plan-driven            | ✅ Yes      | One IMPLEMENTATION_PLAN.md per branch                                    |
| Single source of truth | ✅ Yes      | One plan per branch - scoped plan replaces full plan on branch           |
| Plan is disposable     | ✅ Yes      | Regenerate scoped plan anytime: `./loop.sh plan-work "work description"` |
| Markdown over JSON     | ✅ Yes      | Still markdown plans                                                     |
| Let Ralph Ralph        | ✅ Yes      | Ralph picks "most important" from already-scoped plan - no filter        |

---

### JTBD → Story Map → SLC Release

#### Topics of Concern → Activities

Geoff's [suggested workflow](https://ghuntley.com/content/images/size/w2400/2025/07/The-ralph-Process.png) already aligns planning with Jobs-to-be-Done — breaking JTBDs into topics of concern, which in turn become specs. I love this and I think there's an opportunity to lean further into the product benefits this approach affords by reframing _topics of concern_ as _activities_.

Activities are verbs in a journey ("upload photo", "extract colors") rather than capabilities ("color extraction system"). They're naturally scoped by user intent.

> Topics: "color extraction", "layout engine" → capability-oriented
> Activities: "upload photo", "see extracted colors", "arrange layout" → journey-oriented

#### Activities → User Journey

Activities — and their constituent steps — sequence naturally into a user flow, creating a _journey structure_ that makes gaps and dependencies visible. A _[User Story Map](https://www.nngroup.com/articles/user-story-mapping/)_ organizes activities as columns (the journey backbone) with capability depths as rows — the full space of what _could_ be built:

```
UPLOAD    →   EXTRACT    →   ARRANGE     →   SHARE

basic         auto           manual          export
bulk          palette        templates       collab
batch         AI themes      auto-layout     embed
```

#### User Journey → Release Slices

Horizontal slices through the map become candidate releases. Not every activity needs new capability in every release — some cells stay empty, and that's fine if the slice is still coherent:

```
                  UPLOAD    →   EXTRACT    →   ARRANGE     →   SHARE

Release 1:        basic         auto                           export
                  ───────────────────────────────────────────────────
Release 2:                      palette        manual
                  ───────────────────────────────────────────────────
Release 3:        batch         AI themes      templates       embed
```

#### Release Slices → SLC Releases

The story map gives you _structure_ for slicing. Jason Cohen's _[Simple, Lovable, Complete (SLC)](https://longform.asmartbear.com/slc/)_ gives you _criteria_ for what makes a slice good:

- _Simple_ — Narrow scope you can ship fast. Not every activity, not every depth.
- _Complete_ — Fully accomplishes a job within that scope. Not a broken preview.
- _Lovable_ — People actually want to use it. Delightful within its boundaries.

_Why SLC over MVP?_ MVPs optimize for learning at the customer's expense — "minimum" often means broken or frustrating. SLC flips this: learn in-market _while_ delivering real value. If it succeeds, you have optionality. If it fails, you still treated users well.

Each slice can become a release with a clear value and identity:

```
                  UPLOAD    →   EXTRACT    →   ARRANGE     →   SHARE

Palette Picker:   basic         auto                           export
                  ───────────────────────────────────────────────────
Mood Board:                     palette        manual
                  ───────────────────────────────────────────────────
Design Studio:    batch         AI themes      templates       embed
```

- _Palette Picker_ — Upload, extract, export. Instant value from day one.
- _Mood Board_ — Adds arrangement. Creative expression enters the journey.
- _Design Studio_ — Professional features: batch processing, AI themes, embeddable output.

---

#### Operationalizing with Ralph

The concepts above — activities, story maps, SLC releases — are the _thinking tools_. How do we translate them into Ralph's workflow?

_Default Ralph approach:_

1. _Define Requirements_: Human + LLM define JTBD topics of concern → `specs/*.md`
2. _Create Tasks Plan_: LLM analyzes all specs + current code → `IMPLEMENTATION_PLAN.md`
3. _Build_: Ralph builds against full scope

This works well for capability-focused work (features, refactors, infrastructure). But it doesn't naturally produce valuable (SLC) product releases - it produces "whatever the specs describe".

_Activities → SLC Release approach:_

To get SLC releases, we need to ground activities in audience context. Audience defines WHO has the JTBDs, which in turn informs WHAT activities matter and what "lovable" means.

```
Audience (who)
    └── has JTBDs (why)
            └── fulfilled by Activities (how)
```

##### Workflow

_I. Requirements Phase (2 steps):_

Still performed in LLM conversations with the human, similar to the default Ralph approach.

1. _Define audience and their JTBDs_ — WHO are we building for and what OUTCOMES do they want?

   - Human + LLM discuss and determine the audience(s) and their JTBDs (outcomes they want)
   - May contain multiple connected audiences (e.g. "designer" creates, "client" reviews)
   - Generates `AUDIENCE_JTBD.md`

2. _Define activities_ — WHAT do users do to accomplish their JTBDs?

   - Informed by `AUDIENCE_JTBD.md`
   - For each JTBD, identify activities necessary to accomplish it
   - For each activity, determine:
     - Capability depths (basic → enhanced) — levels of sophistication
     - Desired outcome(s) at each depth — what does success look like?
   - Generates `specs/*.md` (one per activity)

   The discrete steps within activities are implicit and LLM can infer them during planning.

_II. Planning Phase:_

Performed in Ralph loop with _updated_ planning prompt.

- LLM analyzes:
  - `AUDIENCE_JTBD.md` (who, desired outcomes)
  - `specs/*` (what could be built)
  - Current code state (what exists)
- LLM determines next SLC slice (which activities, at what capability depths) and plans tasks for that slice
- LLM generates `IMPLEMENTATION_PLAN.md`
- _Human verifies_ plan before building:
  - Does the scope represent a coherent SLC release?
  - Are the right activities included at the right depths?
  - If wrong → re-run planning loop to regenerate plan, optionally updating inputs or planning prompt
  - If right → proceed to building

_III. Building Phase:_

Performed in Ralph loop with standard building prompt.

##### Updated Planning Prompt

Variant of `PROMPT_plan.md` that adds audience context and SLC-oriented slice recommendation.

_Notes:_

- Unlike the default template, this does not have a `[project-specific goal]` placeholder — the goal is implicit: recommend the most valuable next release for the audience.
- Current subagents names presume using Claude.

```
0a. Study @AUDIENCE_JTBD.md to understand who we're building for and their Jobs to Be Done.
0b. Study `specs/*` with up to 250 parallel Sonnet subagents to learn JTBD activities.
0c. Study @IMPLEMENTATION_PLAN.md (if present) to understand the plan so far.
0d. Study `src/lib/*` with up to 250 parallel Sonnet subagents to understand shared utilities & components.
0e. For reference, the application source code is in `src/*`.

1. Sequence the activities in `specs/*` into a user journey map for the audience in @AUDIENCE_JTBD.md. Consider how activities flow into each other and what dependencies exist.

2. Determine the next SLC release. Use up to 500 Sonnet subagents to compare `src/*` against `specs/*`. Use an Opus subagent to analyze findings. Ultrathink. Given what's already implemented recommend which activities (at what capability depths) form the most valuable next release. Prefer thin horizontal slices - the narrowest scope that still delivers real value. A good slice is Simple (narrow, achievable), Lovable (people want to use it), and Complete (fully accomplishes a meaningful job, not a broken preview).

3. Use an Opus subagent (ultrathink) to analyze and synthesize the findings, prioritize tasks, and create/update @IMPLEMENTATION_PLAN.md as a bullet point list sorted in priority of items yet to be implemented for the recommended SLC release. Begin plan with a summary of the recommended SLC release (what's included and why), then list prioritized tasks for that scope. Consider TODOs, placeholders, minimal implementations, skipped tests - but scoped to the release. Note discoveries outside scope as future work.

IMPORTANT: Plan only. Do NOT implement anything. Do NOT assume functionality is missing; confirm with code search first. Treat `src/lib` as the project's standard library for shared utilities and components. Prefer consolidated, idiomatic implementations there over ad-hoc copies.

ULTIMATE GOAL: We want to achieve the most valuable next release for the audience in @AUDIENCE_JTBD.md. Consider missing elements and plan accordingly. If an element is missing, search first to confirm it doesn't exist, then if needed author the specification at specs/FILENAME.md. If you create a new element then document the plan to implement it in @IMPLEMENTATION_PLAN.md using a subagent.
```

##### Notes

_Why `AUDIENCE_JTBD.md` as a separate artifact:_

- Single source of truth — prevents drift across specs
- Enables holistic reasoning: "What does this audience need MOST?"
- JTBDs captured alongside audience (the "why" lives with the "who")
- Referenced twice: during spec creation AND SLC planning
- Keeps activity specs focused on WHAT, not repeating WHO

_Cardinalities:_

- One audience → many JTBDs ("Designer" has "capture space", "explore concepts", "present to client")
- One JTBD → many activities ("capture space" includes upload, measurements, room detection)
- One activity → can serve multiple JTBDs ("upload photo" serves both "capture" and "gather inspiration")
