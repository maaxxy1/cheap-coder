# The cheap-coder workflow

## The loop
```
 ┌ SCOPE ───────┐  ┌ PLAN ─────────┐  ┌ EXECUTE ────────┐  ┌ REVIEW ────────┐
 │ Claude asks  │─▶│ Claude writes │─▶│ MiniMax (cheap) │─▶│ Claude checks  │
 │ YOU questions│  │ tasks + the   │  │ codes, tests,   │  │ the ANSWERS vs │
 │ -> SCOPE.md  │  │ verify Qs     │  │ and EXPLAINS    │  │ the real code, │
 │              │  │ -> PLAN.md    │  │ code -> ANSWERS │  │ gates + merges │
 └──────────────┘  └───────────────┘  └─────────────────┘  └────────────────┘
        ▲                                                          │
        └──────── REJECT: answers don't match code, re-run ────────┘
```

The handoff between models is **files in the repo** - `SCOPE.md` (what to build),
`PLAN.md` (the contract), `ANSWERS.md` (the executor's code explanations),
`STATE.md` (progress + blockers). No live bridge; the filesystem is the API.

## The interrogation gate (why cheap execution is safe)
Tests alone don't catch a cheap model that builds the wrong logic but games a
green check. So the loop adds two rounds of questions:
- **Scope questions** (Claude -> you, before building): pin down which surface,
  what "works" means, the edge cases, and how we'll prove it.
- **Verify questions** (Claude -> executor, after building): each task lists logic
  questions ("does the dashboard render with no data - which line?", "what's the
  logic of function X?"). The executor must ANSWER by explaining the actual code
  and citing file:line - "it works" is rejected. Claude then re-derives that logic
  against the source. A cheap model that doesn't understand what it built cannot
  produce answers that survive this.

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
| Passes tests but the logic is actually wrong | `verify` questions + `check_answers.py` - executor must explain the code; Claude checks it |
| Builds the wrong thing from a fuzzy ask | `scope.sh` pins the scope with the user first |
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
