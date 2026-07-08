#!/usr/bin/env bash
# cheap-coder demo - watch the whole loop on the bundled example. No model calls,
# no key needed. Shows what each phase produces + runs the real gates so you see,
# concretely, what this repo does.
set -uo pipefail
CC_HOME="${CC_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$CC_HOME"
b() { printf '\n\033[1m%s\033[0m\n' "$*"; }

cat <<'EOF'
============================================================
 cheap-coder - what it does, shown on a real example
============================================================
The job: turn "add a slugify() helper" into working, reviewed code -
with Claude only planning + checking, and a CHEAP model doing the typing.
Below is exactly what each phase produces (from examples/).
EOF

b "1) SCOPE  - Claude interrogates YOU, writes what to build:"
sed -n '1,18p' examples/SCOPE.example.md | sed 's/^/    /'

b "2) PLAN   - Claude writes mechanical tasks + the logic questions to answer:"
grep -E '^### T|files|test|verify' examples/PLAN.example.md | sed 's/^/    /'
echo "    -> the gate that keeps the cheap model honest:"
python3 guards/check_plan.py examples/PLAN.example.md | sed 's/^/       /'

b "3) EXECUTE - the CHEAP model writes the code AND explains it (file:line):"
sed -n '4,12p' examples/ANSWERS.example.md | sed 's/^/    /'
echo "    -> the interrogation gate ('yes it works' is rejected):"
python3 guards/check_answers.py examples/PLAN.example.md examples/ANSWERS.example.md | sed 's/^/       /'

b "4) REVIEW - Claude re-checks the answers vs the code, runs the hard guards,"
echo "   and only then merges. Secrets + protected files are blocked at git level."

cat <<'EOF'

============================================================
 In a REAL run you'd type:
   cheap-coder scope "add a slugify helper"   # Claude asks you
   cheap-coder plan  "add a slugify helper"   # Claude plans
   cheap-coder execute                        # MiniMax codes + explains
   cheap-coder review main                    # Claude gates + merges
 You pay Claude for a plan + a review. The cheap model does the rest.
============================================================
EOF
