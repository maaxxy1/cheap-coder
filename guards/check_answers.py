#!/usr/bin/env python3
"""Every task's `verify` questions must have a real, code-cited answer in
ANSWERS.md before merge. This catches the cheap executor going green on tests
while not actually understanding (or not actually building) the logic.

An answer only counts if it explains the code and points at it - a bare "yes" or
"it works" is rejected.

Usage: python3 guards/check_answers.py PLAN.md ANSWERS.md
Exit 0 = every task answered substantively. Exit 1 = missing/hand-wavy answers.
"""
import re
import sys

# An answer is substantive if it cites code (a file:line, a path, a function, or
# a `code` span) rather than just asserting success.
CITES_CODE = re.compile(r"[\w/]+\.\w+:\d+|[\w/]+\.(py|js|ts|tsx|go|rs|java|rb|sh)"
                        r"|`[^`]+`|\bline\s+\d+|\bfunction\b|\bdef\b|\breturn\b")
BARE = re.compile(r"^\s*(yes|no|it works|works|done|correct|confirmed)\.?\s*$", re.I)


def task_ids(plan_text):
    return re.findall(r"\n###\s+(T\d+)[:.]", plan_text)


def answered(answers_text, tid):
    # Grab the block under "## <tid>" up to the next "## ".
    m = re.search(rf"##\s+{tid}\b(.*?)(?=\n##\s|\Z)", answers_text, re.S)
    if not m:
        return False, "no section in ANSWERS.md"
    block = m.group(1)
    a_lines = re.findall(r"(?im)^\s*A:\s*(.+)$", block)
    if not a_lines:
        return False, "no 'A:' answer lines"
    for a in a_lines:
        if BARE.match(a) or not CITES_CODE.search(a):
            return False, f"hand-wavy answer, cites no code: {a.strip()[:60]!r}"
    return True, "ok"


def main(plan, answers):
    plan_text = open(plan, encoding="utf-8").read()
    try:
        answers_text = open(answers, encoding="utf-8").read()
    except FileNotFoundError:
        print(f"  [BLOCK] {answers} not found - the executor must explain the code")
        return 1
    problems = 0
    for tid in task_ids(plan_text):
        ok, why = answered(answers_text, tid)
        if not ok:
            print(f"  [BLOCK] {tid}: {why}")
            problems += 1
    if problems:
        print(f"\nANSWERS NOT SUFFICIENT: {problems} task(s) not explained with "
              f"code. The executor must prove the logic, not assert it.")
        return 1
    print("all tasks explained with code-cited answers.")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("usage: python3 guards/check_answers.py PLAN.md ANSWERS.md")
        sys.exit(2)
    sys.exit(main(sys.argv[1], sys.argv[2]))
