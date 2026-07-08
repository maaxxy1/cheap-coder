#!/usr/bin/env bash
# cheap-coder selftest - prove the install + guards work end to end without
# calling any model. Runs the bundled example through every guard and asserts the
# right pass/fail. Run after install or after editing a guard.
set -uo pipefail
CC_HOME="${CC_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$CC_HOME"
pass=0; fail=0
expect() {  # expect <desc> <expected-rc> <cmd...>
  local desc="$1" want="$2"; shift 2
  "$@" >/dev/null 2>&1; local got=$?
  if [ "$got" -eq "$want" ]; then echo "  ok   $desc"; pass=$((pass+1))
  else echo "  FAIL $desc (rc=$got, want $want)"; fail=$((fail+1)); fi
}

echo "cheap-coder selftest"
# the bundled example must pass both plan + answers guards
expect "example PLAN passes check_plan"       0 python3 guards/check_plan.py examples/PLAN.example.md
expect "example ANSWERS pass check_answers"   0 python3 guards/check_answers.py examples/PLAN.example.md examples/ANSWERS.example.md

# a vague plan must be rejected
printf '# PLAN\n## Goal\nx\n## Base branch\nmain\n## Tasks\n### T1: fix it\n- **files**: `a.py`\n- **change**: fix as appropriate\n- **test**: run it\n- **accept**: works\n- **verify**: does it work?\n## Final verification\n- **command**: `x`\n- **accept**: ok\n' > /tmp/cc_vague.md
expect "vague plan is rejected"               1 python3 guards/check_plan.py /tmp/cc_vague.md

# a hand-wavy answer must be rejected
printf '# PLAN\n### T1: x\n' > /tmp/cc_p.md
printf '## T1\nQ: ok?\nA: yes it works\n' > /tmp/cc_a.md
expect "hand-wavy answer is rejected"         1 python3 guards/check_answers.py /tmp/cc_p.md /tmp/cc_a.md

# python guards import/parse clean
expect "guards are valid python"              0 python3 -m py_compile guards/check_plan.py guards/check_answers.py guards/scan_secrets.py guards/check_protected.py

echo
[ $fail -eq 0 ] && echo "SELFTEST PASSED ($pass checks)." || echo "SELFTEST FAILED ($fail of $((pass+fail)))."
exit $([ $fail -eq 0 ] && echo 0 || echo 1)
