---
name: fill-workday-timesheet
description: Use when the user wants to fill in their Workday timesheet for the current week (enter hours per weekday against a project), invoked as /fill-workday-timesheet. Review-first — it shows the planned per-day hours for the whole week and waits for confirmation before saving. Runs in the user's real Chrome via claude-in-chrome (logs in through the login-microsoft-sso skill).
disable-model-invocation: true
---

# Fill Workday Timesheet

Assisted, review-first automation of the Workday **Enter Time** flow, driven by the `claude-in-chrome` extension (the user's real, logged-in Chrome).
For the current week it proposes hours per weekday against a project, **shows the whole-week plan, and only saves after the user confirms**.
Entering time writes real data — never save without explicit confirmation.

> Local skill, maintained in this repo (`.source.json` has `"repo": null`).
> Soft dependency: the `login-microsoft-sso` skill (logged-in tab) and the `claude-in-chrome` extension.

## Approach — enter the whole week at once

The preferred, efficient method is **Actions → Enter Time by Type**, which enters every day of the week in a single dialog and one save — not day-by-day.
The typical week is `DEFAULT_HOURS` (e.g. 8) on each weekday; the only adjustments are the few days the user did not work, which are set to 0.
So: read the current week, propose the full week, confirm it as a whole, then apply once.

## Defaults (local config, never committed)

Read defaults from `~/.config/harness-configs/fill-workday-timesheet/config`; they are user/tenant-specific so they are not hardcoded here:

```bash
. ~/.config/harness-configs/fill-workday-timesheet/config
echo "$WORKDAY_TIMESHEET_TIMETYPE | $WORKDAY_TIMESHEET_PROJECT | $WORKDAY_TIMESHEET_DEFAULT_HOURS"
```

- `WORKDAY_TIMESHEET_TIMETYPE` — e.g. `Project Plan` (the Time Type category).
- `WORKDAY_TIMESHEET_PROJECT` — e.g. `Acme: Sample Project` (the Project; the full leaf is `<project> > Project > Time Entry`).
- `WORKDAY_TIMESHEET_DEFAULT_HOURS` — e.g. `8` (per weekday).

The project/time-type are defaults; let the user override per run.

## Phase 1 — Authenticate

Follow the `login-microsoft-sso` skill first (with app `workday`) to get a logged-in Workday tab; reuse its `tabId`.

## Phase 2 — Open the current week's Enter Time grid

1. Open the **Time** app: `MENU` → "Time", then on the Time landing page click **"This Week (… Hours)"** under "Enter Time".
2. `wait` for the **Enter Time** weekly grid (title "Enter Time", a `Sun … Sat` column header row, each column showing "Hours: N").
3. `screenshot` to read the current state.

## Phase 3 — Read the week and build a full-week plan

- Read each day's current "Hours: N" from the column header (Sun–Sat).
- Note any **"Time Period Lockout"** / locked markers; the lockout date range usually refers to a *closed prior* period — only treat a day as locked if its own date falls in the locked range, and never enter time on a locked day (flag it instead).
- Build the proposed week: `DEFAULT_HOURS` on each weekday (Mon–Fri), 0 on weekends, keeping days that already meet the target unchanged.

## Phase 4 — Confirm the whole week (easy one-tap accept)

Show the proposed full week as one table (with the project/time-type named above it), then make confirming a single, low-effort step:

| Day | Current | Proposed |
|-----|---------|----------|
| Mon 6/29 | 8 | 8 |
| Tue 6/30 | 8 | 8 |
| Wed 7/1 | 0 | 8 |
| Thu 7/2 | 0 | 8 |
| Fri 7/3 | 0 | 8 |

Present it as a quick pick (e.g. an `AskUserQuestion` with an **Accept** option) so the common case is one tap:

- **Accept the week** — apply `DEFAULT_HOURS` on every weekday (the Proposed column) and save.
  This is the default/recommended option.
- **Adjust some days** — the user names only the days that differ; everything else stays at `DEFAULT_HOURS`.

Also accept a compact, forgiving reply typed inline — list only the exceptions, e.g. `Fri 0`, `Wed 4`, `Mon off`, `Thu=6`; apply those and keep the rest at the default.
A bare `accept` / `yes` / `ok` applies the proposed week as-is.
If the user changed anything, re-show the final one-line week (e.g. `Mon 8 · Tue 8 · Wed 8 · Thu 8 · Fri 0 = 32h`) and take a single final yes.

**Do not save until the user accepts.**

## Phase 5 — Enter the time (Enter Time by Type — preferred)

1. Click **Actions**, then **"Enter Time by Type"** to open the week dialog.
2. Set the project once: open the **Time Type** prompt, **type a search term and press Enter** to select the recently-used leaf (e.g. type "Time Entry", Enter → selects `<project> > Project > Time Entry`).
   Drilling the cascade by coordinates is unreliable — prefer search-and-Enter, or click options by their `ref` from `read_page`.
3. Enter the confirmed hours for each day into that day's input.
   Locate inputs by their day/date via `find` / `read_page`; set values with `form_input` (not coordinate typing).
   Do not use the recording's dynamic ids (`#56$…-input` change every session).
4. Only after confirmation, click **"Save and Close"**.

Fallback (one day at a time) if the week dialog isn't usable: click an empty day cell → in the **Enter Time** dialog set Time Type (search + Enter), set **Hours** via `form_input`, click **OK**.
Repeat per day.
This works but is slower and is not the preferred path.

## Phase 6 — Verify

- After saving, re-read the grid: confirm each day shows the intended hours and the weekly total updated.
- Report a summary: per-day hours and weekly total.
  Scope is one week per run.
- Do **not** click "Review"/"Submit" (that submits the timesheet for approval) unless the user explicitly asks.

## Safety

- Never save without the user's explicit confirmation of the per-day plan for the week.
- Never enter time on a locked time period; surface it instead.
- Avoid actions that trigger a native browser dialog (alert/confirm) — they block the extension.
  Prefer in-page controls.
- If a step fails repeatedly or the UI differs from the above, stop and report rather than guessing.
