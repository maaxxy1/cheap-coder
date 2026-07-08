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
ln -s ~/cheap-coder/bin/cheap-coder ~/.local/bin/cheap-coder   # one CLI on PATH
cd ~/your-project
cheap-coder init        # scaffolds config + .protected into the repo
# paste your MiniMax key into ~/cheap-coder/config/system.env
cheap-coder doctor      # checks claude CLI, key, git, python are ready
```
The executor is just Claude Code pointed at MiniMax's Anthropic-compatible
endpoint (`ANTHROPIC_BASE_URL` / `ANTHROPIC_MODEL`) - no extra runtime.

## One CLI
```
cheap-coder init | doctor | status         # setup + where am I
cheap-coder scope   "..."                   # Claude interrogates you
cheap-coder plan    "..."                   # Claude plans + verify questions
cheap-coder execute                         # MiniMax executes + explains
cheap-coder review  main                    # Claude gates the answers + merges
```
`cheap-coder status` infers the phase from the artifacts in the repo and tells
you the next command. See `examples/` for a real PLAN + ANSWERS pair that pass
the guards.

## Use (in any repo)
```bash
cd ~/any-project

~/cheap-coder/bin/scope.sh   "make the dashboard work"   # Claude interrogates YOU -> SCOPE.md
~/cheap-coder/bin/plan.sh    "make the dashboard work"   # Claude plans (+ verify questions) -> PLAN.md
~/cheap-coder/bin/execute.sh                            # MiniMax executes + explains -> ANSWERS.md
~/cheap-coder/bin/review.sh  main                       # Claude interrogates the answers + merges
```
- **scope** - Claude asks *you* questions until the build is unambiguous (which
  dashboard, what "work" means, the edge cases, how we'll prove it). A fuzzy
  scope is what a cheap executor turns into wasted work.
- **plan** - Claude writes mechanical tasks AND, per task, the **logic questions**
  the executor must answer to prove it really works.
- **execute** - MiniMax makes the change, runs the test, and answers each logic
  question by **explaining the actual code and citing file:line** (in
  `ANSWERS.md`). "It works" is rejected; it has to point at the lines.
- **review** - Claude checks those explanations against the real source (catches
  a cheap model that passes tests while misunderstanding its own code), runs the
  hard guards, and merges on approval.

The interrogation is the teeth: a passing test is necessary but not sufficient -
the executor has to *logically explain why the code is correct*, and Claude
verifies that explanation against the code.

## What NOT to hand to the cheap model
The planner flags subtle logic, security/compliance, and ambiguous refactors as
**KEEP ON CLAUDE**. The loop is cheap because the cheap model does *grunt* work -
not *dangerous* work. Plausible-but-wrong on the tricky bits costs more in review
than it saves.

## Layout
```
bin/       scope.sh / plan.sh / execute.sh / review.sh / guard.sh
prompts/   scoper.md / planner.md / executor.md / reviewer.md   (the role contracts)
templates/ PLAN.template.md / STATE.template.md
guards/    check_plan.py / check_answers.py / scan_secrets.py / check_protected.py
.protected globs the executor may never touch
config/    system.env(.example)
docs/      WORKFLOW.md
```

## How it compares
cheap-coder borrows the good ideas from the popular agent frameworks and adds the
two they mostly skip - a **cost split** and a **code-explanation gate**.

| Framework | Core idea | cheap-coder takes / differs |
|-----------|-----------|------------------------------|
| **Superpowers** (obra) | process *skills* (plan → TDD → verify) | same discipline, encoded as the scope/plan/execute/review contracts |
| **Aider** | git-native pair-programmer, repo map | git-native too; planner reads the real source before writing tasks |
| **Task Master** | PRD → task graph | plan = mechanical, testable tasks with acceptance lines |
| **OpenHands / SWE-agent** | autonomous agent in a sandbox | branch isolation + guards instead of a full sandbox |
| **Cline / Roo** | explicit plan / act modes | plan (Claude) and act (MiniMax) are literally *different models* |

**What's unique here:**
- **Cost split** - the smart model only plans + reviews; a ~10x cheaper model does
  the execution. Most frameworks run one model for everything.
- **Interrogation gate** - the executor must *explain its code and cite file:line*,
  and the reviewer re-derives that logic against the source. Tests alone don't
  catch a model that misunderstands what it built; this does.
- **A cheap model on a short leash** - every guard exists because a cheap executor
  fails in a specific way (see the table in `docs/WORKFLOW.md`).

See `docs/WORKFLOW.md` for the full loop and the reasoning behind each guard.
