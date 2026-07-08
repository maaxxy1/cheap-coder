# PLAN

<!-- Filled by the PLANNER (Claude). Validated by guards/check_plan.py before the
     executor runs. Every field below is required. Delete these comments. -->

## Goal
<!-- One or two sentences: what this plan achieves and how you know it's done. -->

## Base branch
<!-- The exact branch the executor branches off. Prove it contains prerequisites. -->
main

## Keep on Claude (do NOT hand to the executor)
<!-- Subtle logic / compliance / ambiguous work. Bullet list, or "none". -->
- none

## Tasks

<!-- Repeat this block per task. Keep tasks small and mechanical. -->

### T1: <short imperative title>
- **files**: `path/to/file.py`
- **change**: <exact edit or exact code to write. Paste before/after strings or
  the full new function. No vague verbs like "update" or "handle".>
- **test**: `python3 -m pytest tests/test_file.py -q`
- **accept**: <the exact expected result, e.g. "3 passed" or "prints OK">

### T2: <short imperative title>
- **files**: `path/to/other.py`
- **change**: <exact edit>
- **test**: `<command>`
- **accept**: <expected result>

## Final verification
<!-- The whole-suite / end-to-end command the reviewer runs before merge. -->
- **command**: `python3 -m pytest -q`
- **accept**: `all pass`
