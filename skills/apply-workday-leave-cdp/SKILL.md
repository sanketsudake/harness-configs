---
name: apply-workday-leave-cdp
description: Use when the user wants to apply leave / absence in Workday (sick leave, casual leave, planned leave, comp off, etc.) for one or more days via the chrome-cdp CLI — the cdp port of apply-workday-leave, invoked as /apply-workday-leave-cdp. Review-first — it shows the absence plan (dates, type, hours) and waits for confirmation before submitting, then reconciles the timesheet so the leave day carries no project hours. Drives the user's real Chrome via chrome-cdp (logs in through login-microsoft-sso-cdp).
disable-model-invocation: true
---

# Apply Workday Leave — chrome-cdp port

Assisted, review-first automation of the Workday **Request Absence** flow, driven by the **`chrome-cdp`** CLI (the user's real, logged-in Chrome).
It requests an absence for the given date(s) and type, **shows the plan and only submits after the user confirms**, then checks the timesheet for those days and clears any project hours already entered there.
Submitting an absence writes real data and pings the approver — never submit without explicit confirmation.

> ⚠️ **DRAFT — needs live validation.** This is the cdp port of `apply-workday-leave`. The flow and safety rules are ported faithfully, but the Workday calendar / radio / in-page-modal interactions have **not** yet been validated end-to-end against a live tenant. On the first real run, go slowly, `snap`-and-verify at each step, and fall back to the original `apply-workday-leave` (claude-in-chrome) if a step misbehaves.
> Follow the **`drive-chrome-cdp`** skill for the CLI (setup, `--json`/exit codes, `--by name` addressing, `snap`, `wait`, passkey rule). Soft deps: `login-microsoft-sso-cdp` (logged-in tab) and `fill-workday-timesheet-cdp` (Enter Time grid mechanics, Phase 6).

## Defaults (local config, never committed)

Read defaults from `~/.config/harness-configs/apply-workday-leave/config` (shared with the original skill; user/tenant-specific, not hardcoded):

```bash
. ~/.config/harness-configs/apply-workday-leave/config
echo "$WORKDAY_LEAVE_DEFAULT_TYPE | $WORKDAY_LEAVE_DEFAULT_HOURS"
```

- `WORKDAY_LEAVE_DEFAULT_TYPE` — the Type of Absence used when the user says "sick leave" without naming the tenant's exact type.
- `WORKDAY_LEAVE_DEFAULT_HOURS` — hours per leave day (Workday usually prefills this).

The type is a default; map the user's words to the tenant's absence types (the prompt lists them) and ask if ambiguous.

## Phase 1 — Authenticate

Follow **`login-microsoft-sso-cdp`** (app `workday`) to get a logged-in Workday tab; `use` its tab id so later commands need no `--target`.

## Phase 2 — Open Request Absence

1. Focus the global **Search** and submit: `chrome-cdp type --by name "Search" "Request Absence\n" --json` (the trailing `\n` presses Enter). If the field's accessible name differs, `snap` to find it.
2. On the results page, open the **Request Absence** *task* — **not** a home tile. `snap --json` first: pick the item whose role is `link` under Tasks/Reports, then `chrome-cdp click --by name "Request Absence" --role link --json`. (Tiles like "Requests"/"Request Absence" shift and are easy to mis-hit — the `--role link` + snap check guards against it; use `--nth` if two links share the name.)
3. Wait for the dialog: `chrome-cdp wait --visible "…" --json` (a Request Absence dialog control) or `snap` until the "For <user> (Myself)" dialog with a Calendar / Date Range toggle is present.

## Phase 3 — Select the date(s)

- The calendar opens on the current month; step months with the chevrons: `chrome-cdp click --by name "‹" --json` / `"›"` (or their accessible names from `snap`).
- Click each leave day: `chrome-cdp click --by name "<day, e.g. 3>" --json` (confirm the exact day cell name via `snap`; for a contiguous span the Date Range tab also works).
- `chrome-cdp screenshot -o /tmp/leave-dates.png` and read it back to verify the intended day(s) are highlighted, then `chrome-cdp click --by name "Continue" --role button --json`.

## Phase 4 — Fill the absence form

1. Open the **Type of Absence** prompt and select the type: `chrome-cdp click --by name "<type>" --json` (radio list; default from config).
2. Check **Hours (Daily)** — Workday prefills the full day; adjust only for partial days (read via `snap`/`value`, set with `type` if needed).
3. Leave **Comment** empty unless the user wants one.

## Phase 5 — Confirm, then submit

Show the plan as one table before touching Submit:

| Date | Type | Hours |
|------|------|-------|
| Fri Jul 3 | Casual/Sick Leave (IND) | 8 |

Present it via `AskUserQuestion` with **Submit as-is** recommended, plus "add a comment first" and "don't submit".
**Do not** `click "Submit Request"` until the user accepts. Then: `chrome-cdp click --by name "Submit Request" --role button --json`.
After submitting (no toast), verify via **Manage Absence**: search for it (`type --by name "Search" "Manage Absence\n"`), open it, and `snap`/`screenshot` — the calendar must show the absence block on the date (a clock icon = pending approval) and the Balances panel must reflect the plan.

## Phase 6 — Reconcile the timesheet (clear project hours on the leave day)

An absence does not remove project time already entered for that day — the day would double-count and trip alerts.

1. Open **Time**: `chrome-cdp click --by name "MENU" --json`, then the **Time** app; pick the week containing the leave date (This Week / Last Week / Select Week).
2. On the **Enter Time** grid, read the leave day's column (`snap`/`screenshot`): the absence shows as its own block (e.g. "Casual/Sick Leave (IND) · 8 Hours · Submitted").
3. If the day **also** has a project time block (see `fill-workday-timesheet-cdp`):
   - Click the project block → the **Enter Time** dialog opens.
   - `chrome-cdp click --by name "Delete" --role button --json`, then confirm the in-page **Delete Time Block** modal: `chrome-cdp click --by name "OK" --role button --json` ("you may need to resubmit your time" is expected).
4. Re-read the grid: the day should show only the absence hours; the weekly Summary should be consistent.
5. Do **not** Review/Submit the timesheet unless the user explicitly asks.

## Safety

- Never `click "Submit Request"` (Phase 5) without the user's explicit confirmation of dates, type, and hours.
- Deleting a time block (Phase 6) is destructive — only on the confirmed leave day(s), never elsewhere.
- Pre-existing **"Time Period Lockout"** alerts on other (closed) days are noise — surface, don't act; never enter/delete time on a locked day.
- Avoid actions that trigger a native browser dialog (they block cdp); Workday's own in-page modals (Delete Time Block) are fine.
- If a step fails repeatedly or the UI differs, stop and report — don't guess. Given this is a draft, prefer stopping over improvising.
