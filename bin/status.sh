#!/usr/bin/env bash
# cheap-coder status - where is the current run? Inferred from the artifacts.
set -uo pipefail
CC_HOME="${CC_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"

echo "cheap-coder status   (branch: $branch)"
step() { [ -f "$1" ] && echo "  [x] $2  ($1)" || echo "  [ ] $2"; }
step SCOPE.md   "SCOPE   - build scoped with Claude"
step PLAN.md    "PLAN    - tasks + verify questions written"
step ANSWERS.md "EXECUTE - MiniMax ran + explained the code"

# plan task tally
if [ -f PLAN.md ]; then
  total="$(grep -cE '^###[[:space:]]+T[0-9]+' PLAN.md || echo 0)"
  echo "  tasks in PLAN.md: $total"
fi
# next action hint
if   [ ! -f SCOPE.md ] && [ ! -f PLAN.md ]; then echo "  next: cheap-coder scope \"...\""
elif [ ! -f PLAN.md ];    then echo "  next: cheap-coder plan \"...\""
elif [ ! -f ANSWERS.md ]; then echo "  next: cheap-coder execute"
else echo "  next: cheap-coder review <base>"
fi
