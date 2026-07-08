#!/usr/bin/env python3
"""Reject a PLAN.md that a cheap executor could misread. A plan only passes when
every task is mechanical: exact files, an exact change, a test command, and an
acceptance line. This is the gate that makes the loop tough - the executor never
sees an ambiguous task.

Usage: python3 guards/check_plan.py PLAN.md
Exit 0 = plan is executor-ready. Exit 1 = fix the flagged tasks first.
"""
import re
import sys

VAGUE = re.compile(r"\b(update|handle|improve|refactor|fix|adjust|clean up|"
                   r"as appropriate|as needed|etc\.?|and so on|somehow)\b", re.I)
REQUIRED_SECTIONS = ["## Goal", "## Base branch", "## Tasks", "## Final verification"]


def fail(msg):
    print(f"  [BLOCK] {msg}")


def main(path):
    text = open(path, encoding="utf-8").read()
    problems = 0

    for sec in REQUIRED_SECTIONS:
        if sec not in text:
            fail(f"missing required section: {sec}")
            problems += 1

    # Split into task blocks: "### T<n>: title"
    tasks = re.split(r"\n###\s+T\d+[:.]?", text)
    task_titles = re.findall(r"\n###\s+(T\d+[:.]?.*)", text)
    bodies = tasks[1:]                       # drop the preamble
    if not bodies:
        fail("no tasks found (need '### T1: ...' blocks)")
        return 1

    for title, body in zip(task_titles, bodies):
        tid = title.split(":")[0].strip()
        low = body.lower()
        # Each task needs the four fields.
        for field in ("files", "change", "test", "accept"):
            if f"**{field}**" not in low and f"- **{field}**" not in low:
                fail(f"{tid}: missing '**{field}**:' field")
                problems += 1
        # The change must not be vague.
        change_match = re.search(r"\*\*change\*\*:(.*?)(?=\n- \*\*|\Z)", body,
                                 re.I | re.S)
        change = change_match.group(1) if change_match else ""
        if VAGUE.search(change) and "`" not in change:
            fail(f"{tid}: vague change with no exact code/strings "
                 f"(uses a hand-wavy verb and shows no ` code `)")
            problems += 1
        if len(change.strip()) < 15:
            fail(f"{tid}: change is too thin to be unambiguous")
            problems += 1
        # The test field must be a runnable command (has a backtick command).
        test_match = re.search(r"\*\*test\*\*:(.*)", body, re.I)
        if test_match and "`" not in test_match.group(1):
            fail(f"{tid}: test is not a runnable command (wrap it in ` `)")
            problems += 1

    n = len(bodies)
    if problems:
        print(f"\nPLAN NOT READY: {problems} issue(s) across {n} task(s). "
              f"Tighten these before the executor runs.")
        return 1
    print(f"PLAN OK: {n} task(s), all mechanical and testable. Executor-ready.")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("usage: python3 guards/check_plan.py PLAN.md")
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
