#!/usr/bin/env bash
# cheap-coder abort - bail out of a run cleanly. Drops the exec branch and the
# per-run artifacts, returns you to the base branch. Nothing is merged.
set -euo pipefail
CC_HOME="${CC_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BASE="${1:-main}"
CUR="$(git rev-parse --abbrev-ref HEAD)"
echo "aborting run on '$CUR' -> back to '$BASE'"
git checkout -- . 2>/dev/null || true
rm -f SCOPE.md PLAN.md ANSWERS.md STATE.md
git checkout "$BASE"
case "$CUR" in
  exec/*) git branch -D "$CUR" && echo "deleted exec branch $CUR" ;;
  *) echo "not on an exec/ branch ($CUR) - left it alone" ;;
esac
echo "aborted. clean."
