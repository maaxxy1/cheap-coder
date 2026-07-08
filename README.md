# cheap-coder

A **global, project-agnostic** coding loop that keeps the expensive model doing
only the expensive-worthy work and hands the grind to a dirt-cheap one.

> **Claude plans. MiniMax executes. Claude reviews.**

Point it at *any* git repo. The smart model (Claude) writes a rigorous,
mechanical plan and reviews the result; the cheap model (MiniMax) does the bulk
typing. Guardrails stop the cheap model from wrecking anything.

## Why it's cheap
The costly part of AI coding isn't the thinking - it's the **bulk token output**
(writing lots of code) and the read/test churn. So:

| Phase | Model | Cost |
|-------|-------|------|
| **Plan** | Claude (smart) | small output, high value |
| **Execute** | MiniMax (cheap) | all the grind - ~1/10th the price |
| **Review** | Claude (smart) | small - gate the diff |

You pay Claude for a plan + a review. Everything in between runs on MiniMax.

## Why it's tough
A cheap model left alone ships plausible-but-wrong code. This loop assumes that
and boxes it in:

- **Plans are validated** (`guards/check_plan.py`) - every task must name exact
  files, an exact change, a test command, and an acceptance line. Vague tasks are
  rejected before the cheap model ever sees them.
- **The executor runs on its own branch**, never `main`.
- **A red test blocks the commit** - one in-scope fix, else revert + stop.
- **Protected paths are off-limits** (`.protected`) - secrets, infra, CI, and the
  guard system itself. The cheap model can't weaken its own leash.
- **Secrets are scanned out of the diff** (`guards/scan_secrets.py`).
- **Claude reviews before merge** - catches the intent the cheap model missed.

## Setup (once)
```bash
git clone https://github.com/maaxxy1/cheap-coder ~/cheap-coder
cp ~/cheap-coder/config/system.env.example ~/cheap-coder/config/system.env
# edit config/system.env: paste your MiniMax key + confirm the endpoint/model
```
The executor is just Claude Code pointed at MiniMax's Anthropic-compatible
endpoint (`ANTHROPIC_BASE_URL` / `ANTHROPIC_MODEL`) - no extra runtime.

## Use (in any repo)
```bash
cd ~/any-project

~/cheap-coder/bin/plan.sh "add rate limiting to the login endpoint"   # Claude plans
~/cheap-coder/bin/execute.sh                                          # MiniMax executes
~/cheap-coder/bin/review.sh main                                     # Claude reviews + merges
```
`plan.sh` writes `PLAN.md`. `execute.sh` validates it, branches, and runs the
cheap model against it under the guards. `review.sh` runs the hard guards, hands
the diff to Claude, and merges on approval.

## What NOT to hand to the cheap model
The planner flags subtle logic, security/compliance, and ambiguous refactors as
**KEEP ON CLAUDE**. The loop is cheap because the cheap model does *grunt* work -
not *dangerous* work. Plausible-but-wrong on the tricky bits costs more in review
than it saves.

## Layout
```
bin/       plan.sh / execute.sh / review.sh / guard.sh
prompts/   planner.md / executor.md / reviewer.md   (the role contracts)
templates/ PLAN.template.md / STATE.template.md
guards/    check_plan.py / scan_secrets.py / check_protected.py
.protected globs the executor may never touch
config/    system.env(.example)
docs/      WORKFLOW.md
```

See `docs/WORKFLOW.md` for the full loop and the reasoning behind each guard.
