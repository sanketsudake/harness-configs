---
name: list-week-meetings
description: Use when the user wants a list of their meetings for a week from the Outlook (Microsoft 365) calendar — invoked as /list-week-meetings. Read-only: it reads the week's events and presents them grouped by day (time, title, organizer, online/in-person, status). Runs in the user's real Chrome via claude-in-chrome (logs in through the login-microsoft-sso skill, app outlook).
disable-model-invocation: true
---

# List Week Meetings

Read-only summary of a week's meetings from the **Outlook** web calendar, driven by the `claude-in-chrome` extension (the user's real, logged-in Chrome).
It reads the calendar's events and presents them grouped by day; it never creates, edits, or deletes anything.

> Local skill, maintained in this repo (`.source.json` has `"repo": null`).
> Soft dependency: the `login-microsoft-sso` skill (app `outlook`) and the `claude-in-chrome` extension.

## Phase 1 — Open the calendar

Follow the `login-microsoft-sso` skill first (with app `outlook`) to get a logged-in Outlook tab on the **week** calendar view (`OUTLOOK_HOME_URL`); reuse its `tabId`.

## Phase 2 — Pick the week

- Default to the **current week**.
- For another week, use the calendar's date navigation: the prev/next arrows beside the date range, or the date-range button (`"… – …, Jump to a specific date or date range."`) / the mini month picker, then `wait` for the grid to reload.
- Note the displayed range (e.g. "28 June – 04 July, 2026") for the report header.
- If a **"Filter applied"** button is present in the ribbon, the calendar is filtered — say so in the report (results reflect the user's active filter).
  Only clear it if the user asks.

## Phase 3 — Extract events (handle virtualization)

The week grid **virtualizes**: only events near the visible time range are in the DOM, so a single read misses off-screen hours.

1. Scroll the grid to the top (early morning): `scroll` up several ticks inside the grid area.
2. `read_page` (filter `interactive`); collect every event button under the `calendar view` region — each has a rich aria-label, e.g. `"Team Standup, 9:00 AM to 9:30 AM, Monday, Jan 5, 2026, By Jane Doe, Recurring event, …"`.
3. `scroll` the grid down ~one viewport and `read_page` again; repeat until the bottom of the day.
4. Also capture all-day / top-banner items (e.g. work-plan, holidays) shown above the timed grid.
5. **Dedupe by aria-label** (the same event renders at multiple scroll positions).

## Phase 4 — Parse and present

Parse each aria-label (comma-separated): **title**, **start–end time**, **day + date**, optional **location / "Microsoft Teams Meeting" / join URL**, **"By <organizer>"**, and **status** (`Tentative` / `Busy` / `Recurring event` / `Exception`).

- Treat "Microsoft Teams Meeting" or a join URL (Teams/Zoom) as **online**; otherwise in-person / no location.
- By default list real **meetings** (timed events on the main Calendar).
  Mention all-day items separately, and exclude Birthdays / holidays calendars unless the user wants them.

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
- Avoid actions that trigger a native browser dialog (alert/confirm) — they block the extension.
- If the grid won't load or reads come back empty after scrolling, stop and report rather than guessing.
