---
name: list-week-meetings-cdp
description: Use when the user wants a list of their meetings for a week from the Outlook (Microsoft 365) calendar via the chrome-cdp CLI — the cdp port of list-week-meetings, invoked as /list-week-meetings-cdp. Read-only: it reads the week's events and presents them grouped by day (time, title, organizer, online/in-person, status). Drives the user's real Chrome via chrome-cdp (logs in through login-microsoft-sso-cdp, app outlook).
disable-model-invocation: true
---

# List Week Meetings — chrome-cdp port

Read-only summary of a week's meetings from the **Outlook** web calendar, driven by the **`chrome-cdp`** CLI (the user's real, logged-in Chrome).
It reads the calendar's events and presents them grouped by day; it never creates, edits, or deletes anything.

> ✅ **Validated live (2026-07-15).** cdp port of `list-week-meetings`. The full flow was exercised against real Outlook: reuse the authenticated tab → `snap` reads events by accessible name → `eval` scroll + re-`snap` + dedupe catches virtualized off-screen events. If a run misbehaves, fall back to `list-week-meetings` (claude-in-chrome).
> Follow the **`drive-chrome-cdp`** skill for the CLI (setup, `--json`/exit codes, `--by name` addressing, `snap`, `wait`, passkey rule). Soft dep: **`login-microsoft-sso-cdp`** (app `outlook`) — Outlook has **no** SSO button and auto-authenticates via the shared Microsoft session, so login is just navigate + verify.

## Phase 1 — Open the calendar

Follow **`login-microsoft-sso-cdp`** (app `outlook`) to get a logged-in Outlook tab on the **week** calendar view (`OUTLOOK_HOME_URL`); `use` its tab id so later commands need no `--target`.

## Phase 2 — Pick the week

- Default to the **current week**.
- For another week: `chrome-cdp snap --json` to get the exact accessible names of the prev/next arrows and the date-range button (e.g. `"… – …, Jump to a specific date or date range."`), then `chrome-cdp click --by name "<name>" --role button --json`, and `chrome-cdp wait --for 2s --json` (or `--visible "<sel>"`) for the grid to reload.
- Note the displayed range (via `snap`/`text` on the date heading, e.g. "28 June – 04 July, 2026") for the report header.
- If a **"Filter applied"** button shows up in a `snap`, the calendar is filtered — say so in the report (results reflect the user's active filter). Only clear it if the user asks.

## Phase 3 — Extract events (handle virtualization)

The week grid **virtualizes**: only events near the visible time range are in the DOM, so a single read misses off-screen hours. `chrome-cdp` has no dedicated scroll verb, so drive the scroll via `eval` (a native `scroll` event fires even when `scrollTop` is set from JS, so virtualization still re-renders).

1. Scroll the grid to the top (early morning): `chrome-cdp eval "<js setting the grid container's scrollTop to 0>" --json`.
2. `chrome-cdp snap --json` — the accessibility snapshot, direct analog of `read_page` filtered to interactive: collect every event button under the calendar-view region, each with a rich accessible name, e.g. `"Team Standup, 9:00 AM to 9:30 AM, Monday, Jan 5, 2026, By Jane Doe, Recurring event, …"`.
3. Scroll the grid down ~one viewport (`eval`, bump `scrollTop`) and `snap` again; repeat to the bottom of the day. If `eval` doesn't trigger a re-render, fall back to `chrome-cdp raw Input.dispatchMouseWheel '{"x":…,"y":…,"deltaY":600}' --json` (a real wheel event over the grid).
4. Also capture all-day / top-banner items (work-plan, holidays) above the timed grid — same `snap`, or `chrome-cdp text "<banner selector>" --json`.
5. **Dedupe by accessible name** (the same event renders at multiple scroll positions).

## Phase 4 — Parse and present

Parse each accessible name (comma-separated): **title**, **start–end time**, **day + date**, optional **location / "Microsoft Teams Meeting" / join URL**, **"By <organizer>"**, and **status** (`Tentative` / `Busy` / `Recurring event` / `Exception`).

- Treat "Microsoft Teams Meeting" or a join URL (Teams/Zoom) as **online**; otherwise in-person / no location.
- By default list real **meetings** (timed events on the main Calendar). Mention all-day items separately, and exclude Birthdays / holidays calendars unless the user wants them.

Present grouped by day, sorted by start time, e.g.:

```
Mon, Jan 5
  09:00–09:30  Team Standup                 (recurring)
  15:00–15:30  1:1 with Manager             By Jane Doe · tentative
Wed, Jan 7
  16:00–16:30  Project Review               By A. Colleague · Teams
  …
```

End with a count (e.g. "9 meetings across the week") and note the week range, any active filter, and excluded categories.

## Safety

- Read-only — do not click into events to modify them, and do not change calendar settings or the active filter unless asked.
- Avoid actions that trigger a native browser dialog (alert/confirm) — they block `chrome-cdp`.
- If the grid won't load or `snap` reads come back empty after scrolling, stop and report rather than guessing.
