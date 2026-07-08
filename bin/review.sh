#!/usr/bin/env bash
# REVIEW phase - Claude gates the executor's branch before merge.
# Run from inside your target repo, on the exec branch:  ~/cheap-coder/bin/review.sh [base]
set -euo pipefail
CC_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE="${1:-main}"
export PROTECTED_FILE="${PROTECTED_FILE:-$CC_HOME/.protected}"

echo "==> Running hard guards against $BASE ..."
python3 "$CC_HOME/guards/scan_secrets.py" "$BASE"
python3 "$CC_HOME/guards/check_protected.py" "$BASE"
# The interrogation gate: every task's logic questions must be answered with code.
[ -f PLAN.md ] && [ -f ANSWERS.md ] && \
  python3 "$CC_HOME/guards/check_answers.py" PLAN.md ANSWERS.md || \
  echo "  (note: PLAN.md/ANSWERS.md not both present - skipping answers gate)"

echo "==> Handing the diff to Claude for review ..."
claude "$(cat "$CC_HOME/prompts/reviewer.md")

Review the current branch against '$BASE' in this repo. The diff to review:
  git diff $BASE...HEAD
Go through the checklist, run the full test suite, then give APPROVE / FIX /
REJECT and act on it. Merge to $BASE only on APPROVE (or after you FIX)."
