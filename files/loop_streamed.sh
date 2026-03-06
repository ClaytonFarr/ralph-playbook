#!/bin/bash
set -o pipefail

# Usage: ./loop_streamed.sh [plan|build] [max_iterations]
# Examples:
#   ./loop_streamed.sh              # Build mode, unlimited iterations
#   ./loop_streamed.sh 20           # Build mode, max 20 iterations
#   ./loop_streamed.sh build 20     # Build mode, max 20 iterations
#   ./loop_streamed.sh plan         # Plan mode, unlimited iterations
#   ./loop_streamed.sh plan 5       # Plan mode, max 5 iterations

# Setup needed to make Ctrl-C exit this script properly
set -m
PIPELINE_PID=""
stop_pipeline() {
    if [ -n "$PIPELINE_PID" ] && kill -0 "$PIPELINE_PID" 2>/dev/null; then
        kill -TERM -- "-$PIPELINE_PID" 2>/dev/null || kill -TERM "$PIPELINE_PID" 2>/dev/null || true
        wait "$PIPELINE_PID" 2>/dev/null || true
    fi
}
handle_interrupt() {
    trap - INT TERM
    echo ""
    echo "Interrupted. Stopping loop."
    stop_pipeline
    exit 130
}
trap handle_interrupt INT TERM

# Parse arguments
if [ "$1" = "plan" ]; then
    # Plan mode
    MODE="plan"
    PROMPT_FILE="PROMPT_plan.md"
    MAX_ITERATIONS=${2:-0}
elif [ "$1" = "build" ]; then
    # Explicit build mode (with optional max iterations)
    MODE="build"
    PROMPT_FILE="PROMPT_build.md"
    MAX_ITERATIONS=${2:-0}
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    # Build mode with max iterations (bare number)
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
    # -p: Headless mode (non-interactive, prints output and exits)
    # --dangerously-skip-permissions: Auto-approve all tool calls (YOLO mode)
    # --model opus: Primary agent uses Opus for complex reasoning
    # --verbose: Detailed execution logging
    # --output-format stream-json: Structured output piped to parse_stream.js
    # --include-partial-messages: Stream partial tool results for live feedback

    FULL_PROMPT="$(cat "$PROMPT_FILE")

Execute the instructions above."

    echo "⏳ Running Claude..."
    echo ""

    # Stream JSON with partial messages, parse for readable output
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    (
        claude -p "$FULL_PROMPT" \
            --dangerously-skip-permissions \
            --model opus \
            --verbose \
            --output-format stream-json \
            --include-partial-messages | node "$SCRIPT_DIR/parse_stream.js"
    ) &

    # Wait on Claude/Node pipeline and print exit status code on exit
    PIPELINE_PID=$!
    wait "$PIPELINE_PID"
    PIPELINE_STATUS=$?
    PIPELINE_PID=""
    if [ $PIPELINE_STATUS -ne 0 ]; then
        echo ""
        echo "Pipeline exited with non-zero status ($PIPELINE_STATUS). Stopping loop."
        exit $PIPELINE_STATUS
    fi
    
    echo ""
    echo "✅ Claude iteration complete"

    # Push changes after each iteration
    git push origin "$CURRENT_BRANCH" || {
        echo "Failed to push. Creating remote branch..."
        git push -u origin "$CURRENT_BRANCH"
    }

    ITERATION=$((ITERATION + 1))
    echo -e "\n\n======================== LOOP $ITERATION ========================\n"
done