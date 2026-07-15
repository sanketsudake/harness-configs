---
name: fill-workday-timesheet-cdp
description: Use when the user wants to fill in their Workday timesheet for the current week (hours per weekday against a project) via the chrome-cdp CLI — the cdp port of fill-workday-timesheet, invoked as /fill-workday-timesheet-cdp. Review-first — shows the week's planned hours and waits for confirmation before saving. Drives the user's real Chrome via chrome-cdp (logs in through login-microsoft-sso-cdp).
disable-model-invocation: true
---

# Fill Workday Timesheet — chrome-cdp port

Assisted, review-first automation of the Workday **Enter Time** flow, driven by the **`chrome-cdp`** CLI (the user's real, logged-in Chrome).
For the current week it proposes hours per weekday against a project, **shows the whole-week plan, and only saves after the user confirms**.
Entering time writes real data — never save without explicit confirmation.

> ⚠️ **DRAFT — needs live validation.** cdp port of `fill-workday-timesheet`; the read/propose/confirm/save/verify loop is ported faithfully but not yet validated end-to-end. Go slowly, `snap`-verify each step, and fall back to the original (claude-in-chrome) if a step misbehaves.
> Follow **`drive-chrome-cdp`** for the CLI (setup, `--json`/exit codes, `--by name` addressing, `snap`, `wait`, passkey rule). Soft dep: `login-microsoft-sso-cdp` (logged-in tab, app `workday`).

## Approach — enter the whole week at once

Prefer **Actions → Enter Time by Type**: one dialog, one save, not day-by-day.
Typical week is `DEFAULT_HOURS` on each weekday; only exceptions are days not worked (0).
Read, propose, confirm as a whole, apply once.

## Defaults (local config, never committed)

Same config as the original — cross-reference `fill-workday-timesheet`'s SKILL.md for the schema rather than restating it:

```bash
. ~/.config/harness-configs/fill-workday-timesheet/config
echo "$WORKDAY_TIMESHEET_TIMETYPE | $WORKDAY_TIMESHEET_PROJECT | $WORKDAY_TIMESHEET_DEFAULT_HOURS"
```

The project/time-type are defaults; let the user override per run.

## Phase 1 — Authenticate

Follow **`login-microsoft-sso-cdp`** (app `workday`) to get a logged-in Workday tab; `use` its tab id so later commands need no `--target`.

## Phase 2 — Open the current week's Enter Time grid

1. `snap` for **MENU**'s accessible name, `chrome-cdp click --by name "MENU" --json` → open **Time** → click **"This Week (… Hours)"** under "Enter Time" (confirm names via `snap` — labels vary by tenant).
2. `chrome-cdp wait --visible "Enter Time" --json` (or re-`snap`) for the weekly grid: title "Enter Time", `Sun … Sat` header row, each showing "Hours: N".
3. `chrome-cdp screenshot --json` to read the current state.

## Phase 3 — Read the week and build a full-week plan

- `chrome-cdp snap --json` / `text "<grid selector>" --json` to read each day's current "Hours: N" (Sun–Sat).
- Note any **"Time Period Lockout"** marker; locked only if the day's own date falls in that range — never enter time on a locked day (flag it).
- Proposed week: `DEFAULT_HOURS` Mon–Fri, 0 on weekends, unchanged where a day already meets the target.

## Phase 4 — Confirm the whole week (easy one-tap accept)

Show the proposed full week as one table, with the project/time-type named above it:

| Day | Current | Proposed |
|-----|---------|----------|
| Mon 6/29 | 8 | 8 |
| Wed 7/1 | 0 | 8 |

Present via `AskUserQuestion` with an **Accept** option as the default:

- **Accept the week** — apply `DEFAULT_HOURS` on every weekday (Proposed column) and save.
- **Adjust some days** — the user names only the days that differ; everything else stays at `DEFAULT_HOURS`.

Also accept a compact inline reply naming only exceptions (e.g. `Fri 0`, `Wed 4`, `Mon off`); a bare `accept`/`yes`/`ok` applies as-is.
If anything changed, re-show the final one-line week (e.g. `Mon 8 · Tue 8 · Wed 8 · Thu 8 · Fri 0 = 32h`) and take one final yes.

**Do not save until the user accepts.**

## Phase 5 — Enter the time (Enter Time by Type — preferred)

1. `chrome-cdp click --by name "Actions" --json`, then `chrome-cdp click --by name "Enter Time by Type" --json`.
2. Set the project once: open **Time Type**, type a search term, Enter to select the recently-used leaf: `chrome-cdp type --by name "Time Type" "Time Entry\n" --json` (selects `<project> > Project > Time Entry`). Coordinate-drilling the cascade is unreliable — prefer search-and-Enter.
3. For each day, `snap` for that day's hour-input **accessible name** (never CSS id — ids like `#56$…-input` change per session), then `chrome-cdp type --by name "<name>" "<hours>" --json`.
4. Only after confirmation: `chrome-cdp click --by name "Save and Close" --role button --json`.

Fallback (day-by-day): click an empty day cell → set Time Type (search + Enter) → set **Hours** via `type --by name` → click **OK**. Repeat per day; slower, not preferred.

## Phase 6 — Verify

- `chrome-cdp snap --json` (or `screenshot`) to re-read the grid: confirm each day shows the intended hours and the weekly total updated.
- Report a summary: per-day hours and weekly total. Scope is one week per run.
- Do **not** click **"Review"**/**"Submit"** (submits the timesheet for approval) unless the user explicitly asks.

## Safety

- Never save without the user's explicit confirmation of the per-day plan.
- Never enter time on a locked time period; surface it instead.
- Avoid native browser dialogs (they block cdp); prefer in-page controls.
- If a step fails repeatedly or the UI differs, stop and report — don't guess. As a draft, prefer stopping over improvising.
