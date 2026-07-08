#!/usr/bin/env bash
# PLAN phase - Claude (your smart default model) writes PLAN.md for a request.
# Run from inside your target repo:  ~/cheap-coder/bin/plan.sh "add X to Y"
set -euo pipefail
CC_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

REQUEST="${*:-}"
[ -z "$REQUEST" ] && { echo "usage: plan.sh \"<what you want built>\""; exit 1; }
command -v claude >/dev/null || { echo "claude CLI not found"; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "run this inside a git repo (the project you want to change)"; exit 1; }

cp -n "$CC_HOME/templates/PLAN.template.md" PLAN.template.ref 2>/dev/null || true

echo "==> Planning with Claude (smart model). Producing PLAN.md ..."
claude "$(cat "$CC_HOME/prompts/planner.md")

The template to fill is at: $CC_HOME/templates/PLAN.template.md
Write the finished plan to ./PLAN.md in this repo, then run:
  python3 $CC_HOME/guards/check_plan.py PLAN.md
and fix anything it flags before you finish.

REQUEST:
$REQUEST"
