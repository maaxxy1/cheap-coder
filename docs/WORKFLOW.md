# The cheap-coder workflow

## The loop
```
  ┌─ PLAN ────────┐     ┌─ EXECUTE ──────────┐     ┌─ REVIEW ───────┐
  │ Claude (smart)│ ──▶ │ MiniMax (cheap)     │ ──▶ │ Claude (smart) │
  │ writes PLAN.md│     │ runs it on exec/    │     │ gates the diff │
  │ mechanical    │     │ branch, guarded,    │     │ APPROVE/FIX/   │
  │ + testable    │     │ test-per-task       │     │ REJECT + merge │
  └───────────────┘     └────────────────────┘     └────────────────┘
        ▲                                                    │
        └──────────── REJECT: sharpen PLAN.md, re-run ───────┘
```

The handoff between models is **files in the repo** - `PLAN.md` (the contract)
and `STATE.md` (progress + blockers). No live bridge; the filesystem is the API.

## Why each guard exists
Every guard maps to a specific way a cheap model fails:

| Failure mode of a cheap executor | Guard that stops it |
|----------------------------------|---------------------|
| Misreads a vague task, builds the wrong thing | `check_plan.py` rejects vague tasks *before* execution |
| Ships code that breaks the build | `REQUIRE_GREEN` - red test = revert + stop, never commit red |
| Edits files it shouldn't (secrets, infra, CI) | `.protected` + `check_protected.py` |
| Pastes a key it saw in the env into a file | `scan_secrets.py` |
| Works straight on `main` | `execute.sh` forces an `exec/` branch off a clean tree |
| Satisfies the wording but misses the intent | Claude `review.sh` before merge |
| Runs forever / burns budget | `BUDGET_MAX_TASKS` cap |

## The planner's discipline (this is what makes the cheap model work)
A cheap model infers little. The plan must remove all guesswork:
- exact files, exact symbols (verified against source, not memory),
- the exact code or before/after strings,
- one runnable test + an acceptance line per task,
- anything needing judgement is marked **KEEP ON CLAUDE**, not handed down.

A good plan reads like assembly instructions. If a task can't be verified by one
command, it's too big - split it.

## Cost intuition
- Plan: Claude reads context + writes a spec. Bounded, high-leverage.
- Execute: MiniMax writes all the code + runs the test loop. This is the bulk -
  and it's ~10x cheaper per token than Claude.
- Review: Claude reads a focused diff. Small.

Net: you buy Claude for judgement (plan + review) and MiniMax for volume
(execution). The more mechanical the work, the bigger the saving.

## When to skip the loop
For a one-line fix, just do it on Claude - the plan/handoff overhead isn't worth
it. The loop pays off on **multi-task, mechanical** work: migrations, sweeps,
boilerplate, scaffolding, repetitive refactors across many files.
