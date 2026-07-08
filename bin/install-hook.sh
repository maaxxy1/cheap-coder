#!/usr/bin/env bash
# Install the cheap-coder pre-commit hook into the CURRENT repo, so the guards
# enforce at git level. execute.sh calls this automatically on the exec branch;
# you can also run it by hand to protect a repo permanently.
set -euo pipefail
CC_HOME="${CC_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ROOT="$(git rev-parse --show-toplevel)"
mkdir -p "$ROOT/.cheap-coder" "$ROOT/.git/hooks"
echo "$CC_HOME" > "$ROOT/.cheap-coder/home"
cp "$CC_HOME/hooks/pre-commit" "$ROOT/.git/hooks/pre-commit"
chmod +x "$ROOT/.git/hooks/pre-commit"
echo "installed pre-commit guard hook in $ROOT/.git/hooks/pre-commit"
