#!/usr/bin/env bash
# EXECUTE phase - MiniMax (cheap model) runs PLAN.md on its own branch, guarded.
# Run from inside your target repo, after plan.sh:  ~/cheap-coder/bin/execute.sh
set -euo pipefail
CC_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CFG="$CC_HOME/config/system.env"
[ -f "$CFG" ] || { echo "missing $CFG - copy config/system.env.example and fill EXECUTOR_API_KEY"; exit 1; }
# shellcheck disable=SC1090
source "$CFG"
[ -z "${EXECUTOR_API_KEY:-}" ] && { echo "set EXECUTOR_API_KEY in $CFG"; exit 1; }
[ -f PLAN.md ] || { echo "no PLAN.md here - run plan.sh first"; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not a git repo"; exit 1; }

# Gate 1: the plan must be executor-ready (mechanical, testable).
echo "==> Validating PLAN.md ..."
python3 "$CC_HOME/guards/check_plan.py" PLAN.md || { echo "plan not ready - tighten it"; exit 1; }

# Gate 2: clean tree + isolated branch (never run the cheap model on main).
[ -z "$(git status --porcelain)" ] || { echo "commit/stash your changes first"; exit 1; }
BASE="$(git rev-parse --abbrev-ref HEAD)"
BRANCH="${EXECUTOR_BRANCH_PREFIX:-exec/}$(date +%Y%m%d-%H%M%S)"
git checkout -b "$BRANCH"
echo "==> Executor branch: $BRANCH (base: $BASE)"

# Mechanical enforcement: install the pre-commit guard hook so the cheap model
# CANNOT commit a secret or touch a protected file - git blocks it, not just the
# prompt. Belt-and-suspenders with the executor instructions.
bash "$CC_HOME/bin/install-hook.sh" || echo "  (warning: could not install commit hook)"

# Point Claude Code at the CHEAP MiniMax model just for this launch.
export ANTHROPIC_BASE_URL="$EXECUTOR_BASE_URL"
export ANTHROPIC_AUTH_TOKEN="$EXECUTOR_API_KEY"
export ANTHROPIC_MODEL="$EXECUTOR_MODEL"
export ANTHROPIC_SMALL_FAST_MODEL="${EXECUTOR_SMALL_MODEL:-$EXECUTOR_MODEL}"
export PROTECTED_FILE="${PROTECTED_FILE:-$CC_HOME/.protected}"

echo "==> Executing on $EXECUTOR_MODEL (cheap). Budget: ${BUDGET_MAX_TASKS:-20} tasks."
claude "$(cat "$CC_HOME/prompts/executor.md")

Execute ./PLAN.md now in this repo.
- Branch: $BRANCH   Base: $BASE
- Protected globs file: $PROTECTED_FILE (never touch matches)
- Budget: stop after ${BUDGET_MAX_TASKS:-20} tasks
- REQUIRE_GREEN=${REQUIRE_GREEN:-1} (a red test blocks the commit; revert + log to STATE.md)
Follow the hard rules exactly. When done, stop - do not merge. Claude reviews next."

echo "==> Executor finished. Review before merge:  ~/cheap-coder/bin/review.sh $BASE"
