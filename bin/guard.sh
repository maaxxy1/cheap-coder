#!/usr/bin/env bash
# Run all hard guards at once (plan + secrets + protected). Use as a manual gate
# or wire into a pre-commit / CI step.  ~/cheap-coder/bin/guard.sh [base]
set -euo pipefail
CC_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE="${1:-main}"
export PROTECTED_FILE="${PROTECTED_FILE:-$CC_HOME/.protected}"
rc=0
[ -f PLAN.md ] && { python3 "$CC_HOME/guards/check_plan.py" PLAN.md || rc=1; }
python3 "$CC_HOME/guards/scan_secrets.py" "$BASE" || rc=1
python3 "$CC_HOME/guards/check_protected.py" "$BASE" || rc=1
[ $rc -eq 0 ] && echo "==> all guards passed" || echo "==> GUARDS FAILED (rc=$rc)"
exit $rc
