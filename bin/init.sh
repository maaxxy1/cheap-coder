#!/usr/bin/env bash
# cheap-coder init - scaffold the loop into the CURRENT repo.
set -euo pipefail
CC_HOME="${CC_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "run inside a git repo"; exit 1; }

# 1. config lives in CC_HOME (holds the key) - create it if missing.
if [ ! -f "$CC_HOME/config/system.env" ]; then
  cp "$CC_HOME/config/system.env.example" "$CC_HOME/config/system.env"
  echo "created $CC_HOME/config/system.env  (paste your MiniMax key into it)"
fi

# 2. a project-local .protected the executor obeys here (merged with the default).
if [ ! -f .protected ]; then
  cp "$CC_HOME/.protected" .protected
  echo "created ./.protected  (add this project's sensitive paths)"
fi

# 3. keep the per-run artifacts out of the target repo's git.
for f in SCOPE.md PLAN.md ANSWERS.md STATE.md .cheap-coder/; do
  grep -qxF "$f" .gitignore 2>/dev/null || echo "$f" >> .gitignore
done
mkdir -p .cheap-coder
echo "added SCOPE/PLAN/ANSWERS/STATE + .cheap-coder/ to .gitignore"

echo
echo "initialised. next:"
echo "  cheap-coder doctor        # check the key + tools"
echo "  cheap-coder scope \"...\"    # start a build"
