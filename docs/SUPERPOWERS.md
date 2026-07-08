# cheap-coder runs on Superpowers

cheap-coder is not a competing methodology - it is the **Superpowers discipline,
split across two models to save money**. Every phase invokes the matching
Superpowers skill; cheap-coder only adds (a) the cost split - which skill runs on
the smart model vs the cheap one - and (b) guardrails a cheap executor needs.

## Phase -> skill -> model

| cheap-coder phase | Superpowers skill | runs on | why here |
|-------------------|-------------------|---------|----------|
| `scope`  | `brainstorming` | Claude (smart) | explore intent/requirements/design before code - judgement work |
| `plan`   | `writing-plans` | Claude (smart) | the plan an engineer with zero context can execute; high leverage, low tokens |
| `execute`| `executing-plans` + `test-driven-development` | MiniMax (cheap) | follow the rails the smart model laid; TDD per task - bulk typing |
| `execute` (red test) | `systematic-debugging` | MiniMax (cheap) | root cause, not guess-patch |
| `review` | `requesting-code-review` + `verification-before-completion` | Claude (smart) | catch what the cheap model got plausibly-wrong |
| merge    | `finishing-a-development-branch` | Claude (smart) | clean completion |

## The insight
Superpowers already encodes *how* to build well. cheap-coder answers *who pays for
each step*: the phases that need judgement (brainstorm, plan, review) run on the
smart model; the phase that is mostly volume (execute) runs on a cheap one - with
the guards + the code-explanation gate making that safe.

## What cheap-coder adds on top of Superpowers
- **Cost split** - the same skills, but planning/review on Claude and execution on
  a ~10x cheaper model.
- **Mechanical guards** - `check_plan` / `check_answers` / `scan_secrets` /
  `check_protected` + a git pre-commit hook, because a cheap executor needs a
  shorter leash than a smart one.
- **The interrogation gate** - the executor must explain its code (file:line);
  Superpowers verifies-before-completion, cheap-coder makes the *cheap* model
  prove it understands what it built.

Install Superpowers (`obra/superpowers`) and every phase gets the real skill. If
it is not installed, the prompts fall back to the cheap-coder role contracts,
which encode the same steps.
