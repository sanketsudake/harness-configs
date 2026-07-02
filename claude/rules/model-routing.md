# Model & effort routing

Route work to the cheapest model that can do it reliably; escalate only when the task genuinely needs judgment.

## Routing table

| Task shape | Model | Typical vehicle |
|------------|-------|-----------------|
| Mechanical, judgment-free: bulk edits, renames, version bumps, applying a decided pattern | haiku | `bulk-mechanic` agent |
| Routine coding, summarization, search fan-outs, PR-loop babysitting | sonnet | `pr-shepherd`, Explore, general subagents |
| Architecture, planning, plan review, security decisions, final review verdicts | inherit (session model) | main loop, `plan-reviewer` |

## Effort

- Default to medium effort; do not raise it out of habit.
- Use low effort for mechanical subagent work (pairs with haiku above).
- Reserve high/xhigh for the hardest verify/judge stages — adversarial verification, subtle-bug hunts, final judge panels.

## Workflow-tool fan-outs

- Pass `model`/`effort` per `agent()` call: haiku+low for mechanical stages, sonnet for judgment stages, inherit only for the few calls that need the session model.
- Inline task constants directly in the workflow script rather than threading them through `args`.

## Rules of thumb

- If the parent already made every decision and the subagent just applies them, it is haiku work.
- If a wrong answer is cheap to detect and retry, prefer the cheaper model and verify.
- If a wrong answer is expensive or silent, pay for the stronger model up front.
