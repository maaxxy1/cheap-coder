#!/usr/bin/env bash
# cheap-coder doctor - is everything ready to run the loop?
set -uo pipefail
CC_HOME="${CC_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ok=0; bad=0
check() { if eval "$2" >/dev/null 2>&1; then echo "  ok   $1"; ok=$((ok+1)); else echo "  MISS $1  -> $3"; bad=$((bad+1)); fi; }

echo "cheap-coder doctor"
check "claude CLI on PATH"       "command -v claude"          "install Claude Code"
check "python3 present"          "command -v python3"         "install python3"
check "git present"              "command -v git"             "install git"
check "inside a git repo"        "git rev-parse --is-inside-work-tree" "cd into your project"
check "config/system.env exists" "[ -f '$CC_HOME/config/system.env' ]" "cp config/system.env.example config/system.env"
if [ -f "$CC_HOME/config/system.env" ]; then
  # shellcheck disable=SC1090
  . "$CC_HOME/config/system.env"
  check "EXECUTOR_API_KEY set"   "[ -n \"\${EXECUTOR_API_KEY:-}\" ]" "paste your MiniMax key into config/system.env"
  check "EXECUTOR_BASE_URL set"  "[ -n \"\${EXECUTOR_BASE_URL:-}\" ]" "set the MiniMax endpoint"
  check "EXECUTOR_MODEL set"     "[ -n \"\${EXECUTOR_MODEL:-}\" ]"    "set the model (e.g. MiniMax-M2)"
fi
check ".protected present"       "[ -f '$CC_HOME/.protected' ] || [ -f .protected ]" "cheap-coder init"
echo
[ $bad -eq 0 ] && echo "READY ($ok checks passed)." || echo "$bad thing(s) to fix before the loop runs ($ok ok)."
exit $([ $bad -eq 0 ] && echo 0 || echo 1)
