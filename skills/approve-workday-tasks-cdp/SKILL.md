---
name: approve-workday-tasks-cdp
description: Use when the user wants to review and approve their pending Workday "My Tasks" approvals via the chrome-cdp CLI — the cdp port of approve-workday-tasks, invoked as /approve-workday-tasks-cdp. Lists pending items and approves only the ones the user explicitly selects. Drives the user's real Chrome via chrome-cdp (logs in through login-microsoft-sso-cdp).
disable-model-invocation: true
---

# Approve Workday Tasks — chrome-cdp port

Assisted, review-first automation of the Workday **My Tasks** approval flow, driven by the **`chrome-cdp`** CLI (the user's real, logged-in Chrome).
It **lists** the pending items and approves **only** the items the user selects.
Never approve anything the user did not explicitly choose.

> ⚠️ **DRAFT — approve path needs live validation.** cdp port of `approve-workday-tasks`. The **list phase is validated live** (2026-07-15: authenticate → open My Tasks via `click --by name "Go to My Tasks (N)"` → enumerate pending items all work). The **approve/submit path (Phase 4) has NOT been exercised** — it writes. On the first real run, `snap`-verify the Approve → Submit/OK step carefully and confirm the item disappears; fall back to the original `approve-workday-tasks` (claude-in-chrome) if it misbehaves.
> Follow the **`drive-chrome-cdp`** skill for the CLI (setup, `--json`/exit codes, `--by name` addressing, `snap`, passkey rule). Soft dep: `login-microsoft-sso-cdp` (logged-in tab).

## Phase 1 — Authenticate

Follow **`login-microsoft-sso-cdp`** (app `workday`) to get a logged-in Workday tab; `use` its tab id.

## Phase 2 — Open My Tasks

- Open the inbox: `chrome-cdp snap --json` to find the top-bar inbox control's accessible name (e.g. "Go to My Tasks (N)" / "My Tasks Items"), then `chrome-cdp click --by name "<that name>" --json`.
- Verify it opened: `chrome-cdp wait --visible "…" --json` or `snap`/`screenshot` to confirm the My Tasks list is showing.

## Phase 3 — List pending items

- Enumerate with `chrome-cdp snap --json` (roles + names of the list items) and/or `chrome-cdp text "<list selector>" --json`. Capture each pending item's visible title / type / subject / date / amount.
- If empty (Workday shows no items, or "You're all caught up"), report **"No pending tasks"** and stop.
- Otherwise present the items to the user as a numbered list. **Default is list-only.** Ask which numbers to approve.

## Phase 4 — Confirm and approve

For each item the user selected, and only those:

1. Open it: `chrome-cdp click --by name "<item title>" --json` (use `snap` to get the exact name; `--nth` if titles repeat).
2. Approve: `chrome-cdp click --by name "Approve" --role button --json`.
3. A confirm/submit control may appear. `snap`/`find` the actual **Submit** / **OK** control by its accessible name and click it: `chrome-cdp click --by name "Submit" --role button --json` (do not rely on coordinates or dynamic ids).
4. Verify: re-`snap` the list — the item should be gone. If it isn't, record a failure and move on.

Finish with a summary: approved, skipped, and failed.

## Safety

- Never approve an item the user did not explicitly select.
- Avoid clicking anything that triggers a native browser dialog (it blocks cdp); prefer in-page controls.
- If login can't be confirmed or a step fails repeatedly, stop and report. Given this is a draft, prefer stopping over improvising.
