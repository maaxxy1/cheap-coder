#!/usr/bin/env bash
# SCOPE phase - Claude interrogates YOU to understand the build, writes SCOPE.md.
# Run first, inside your target repo:  ~/cheap-coder/bin/scope.sh "make the dashboard work"
set -euo pipefail
CC_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REQUEST="${*:-}"
command -v claude >/dev/null || { echo "claude CLI not found"; exit 1; }

echo "==> Scoping with Claude. Answer its questions; it writes SCOPE.md ..."
claude "$(cat "$CC_HOME/prompts/scoper.md")

Interrogate me until the build scope is unambiguous, then write ./SCOPE.md in
this repo. Do NOT start planning or coding yet.

WHAT I WANT (rough):
${REQUEST:-<the user will describe it>}"
