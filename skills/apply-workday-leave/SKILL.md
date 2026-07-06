---
name: apply-workday-leave
description: Use when the user wants to apply leave / absence in Workday (sick leave, casual leave, planned leave, comp off, etc.) for one or more days, invoked as /apply-workday-leave. Review-first — it shows the absence plan (dates, type, hours) and waits for confirmation before submitting, then reconciles the timesheet so the leave day carries no project hours. Runs in the user's real Chrome via claude-in-chrome (logs in through the login-microsoft-sso skill).
disable-model-invocation: true
---

# Apply Workday Leave

Assisted, review-first automation of the Workday **Request Absence** flow, driven by the `claude-in-chrome` extension (the user's real, logged-in Chrome).
It requests an absence for the given date(s) and type, **shows the plan and only submits after the user confirms**, then checks the timesheet for those days and clears any project hours already entered there.
Submitting an absence writes real data and pings the approver — never submit without explicit confirmation.

> Local skill, maintained in this repo (`.source.json` has `"repo": null`).
> Soft dependencies: the `login-microsoft-sso` skill (logged-in tab), the `claude-in-chrome` extension, and `fill-workday-timesheet` (Enter Time grid mechanics referenced in Phase 6).

## Defaults (local config, never committed)

Read defaults from `~/.config/harness-configs/apply-workday-leave/config`; they are user/tenant-specific so they are not hardcoded here:

```bash
. ~/.config/harness-configs/apply-workday-leave/config
echo "$WORKDAY_LEAVE_DEFAULT_TYPE | $WORKDAY_LEAVE_DEFAULT_HOURS"
```

- `WORKDAY_LEAVE_DEFAULT_TYPE` — e.g. `Casual/Sick Leave (IND)` (the Type of Absence used when the user says "sick leave" without naming the tenant's exact type).
- `WORKDAY_LEAVE_DEFAULT_HOURS` — e.g. `8` (hours per leave day; Workday usually prefills this).

The type is a default; map the user's words to the tenant's absence types (the prompt lists them, e.g. Bereavement Leave, Casual/Sick Leave, Compensatory Off Time Off, Floating Holiday, Loss of Pay Leave, Paternity Leave, Planned Leave, Voting Time Off) and ask if ambiguous.

## Phase 1 — Authenticate

Follow the `login-microsoft-sso` skill first (with app `workday`) to get a logged-in Workday tab; reuse its `tabId`.

## Phase 2 — Open Request Absence

1. Click the global **Search** bar, type `Request Absence`, press Enter.
2. On the search results page, under **Tasks and Reports**, click the **Request Absence** *task* link (use `find`; don't click by coordinates — the home page's "Your Top Apps" tiles shift positions and neighbor apps like "Requests" are easy to hit by mistake).
3. `wait` for the **Request Absence** dialog ("For <user> (Myself)" with a **Calendar** / **Date Range** toggle).

## Phase 3 — Select the date(s)

- The calendar opens on the current month; use the `‹` / `›` chevrons to reach the target month.
- Click each leave day (selected days show highlighted); for a contiguous multi-day span the **Date Range** tab also works.
- `screenshot` to verify the intended day(s) are highlighted, then click **Continue**.

## Phase 4 — Fill the absence form

The per-request form shows the chosen date(s) as the title (e.g. "Fri, Jul 3"):

1. Open the **Type of Absence** prompt and select the type (radio list; default from config).
2. Check **Hours (Daily)** — Workday prefills the full day (e.g. 8); adjust only for partial days ("Edit Individual Days" handles per-day differences).
3. Leave **Comment** empty unless the user wants one.

## Phase 5 — Confirm, then submit

Show the plan as one table before touching Submit:

| Date | Type | Hours |
|------|------|-------|
| Fri Jul 3 | Casual/Sick Leave (IND) | 8 |

Present it as a quick pick (e.g. `AskUserQuestion` with **Submit as-is** as the recommended option, plus "add a comment first" and "don't submit").
**Do not click Submit Request until the user accepts.**
After submitting, the dialog closes with no toast — verify via **Manage Absence** (search for it, or the link on the search results page): the calendar must show the absence block on the date (a clock icon = pending approval) and the Balances panel reflects the plan.

## Phase 6 — Reconcile the timesheet (clear project hours on the leave day)

An absence does not remove project time already entered for that day — the day would double-count (e.g. 16 hours) and trip alerts.

1. Open the **Time** app (MENU → Time) and pick the week containing the leave date: **This Week**, **Last Week**, or **Select Week**.
2. On the **Enter Time** grid, read the leave day's column: the absence shows as its own block (e.g. "Casual/Sick Leave (IND) · 8 Hours · Submitted").
3. If the day **also** has a project time block (see `fill-workday-timesheet` for the grid's anatomy):
   - Click the project block → the **Enter Time** dialog opens (Time Type, Hours, Status).
   - Click **Delete**, then **OK** on the "Delete Time Block" confirmation ("you may need to resubmit your time for approval" is expected).
4. Re-read the grid: the day should now show only the absence hours, and the weekly **Summary** (Project Hours / Time Off / Total) should be consistent (e.g. 4×8 project + 8 time off = 40).
5. Do **not** click "Review"/"Submit" on the timesheet unless the user explicitly asks.

## Safety

- Never click **Submit Request** (Phase 5) without the user's explicit confirmation of dates, type, and hours.
- Deleting a time block (Phase 6) is destructive to entered data — only delete blocks on the confirmed leave day(s), never elsewhere.
- Pre-existing page alerts about **"Time Period Lockout"** on other (closed) days are noise — surface them, don't act on them; never enter or delete time on a locked day.
- Avoid actions that trigger a native browser dialog (alert/confirm) — they block the extension. Workday's own modals (Delete Time Block) are in-page and fine.
- If a step fails repeatedly or the UI differs from the above, stop and report rather than guessing.
