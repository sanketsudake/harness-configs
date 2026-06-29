---
name: approve-workday-tasks
description: Use when the user wants to review and approve their pending Workday "My Tasks" approvals via the browser — invoked as /approve-workday-tasks. Lists pending items and approves only the ones the user explicitly selects. Runs in the user's real Chrome via claude-in-chrome (logs in through the login-microsoft-sso skill).
disable-model-invocation: true
---

# Approve Workday Tasks

Assisted, review-first automation of the Workday **My Tasks** approval flow, driven by the `claude-in-chrome` extension (the user's real, logged-in Chrome).
It **lists** the pending items and approves **only** the items the user selects.
Never approve anything the user did not explicitly choose.

> Local skill, maintained in this repo (`.source.json` has `"repo": null`).
> Soft dependency: the `login-microsoft-sso` skill (establishes the logged-in tab) and the `claude-in-chrome` extension.

## Phase 1 — Authenticate

Follow the `login-microsoft-sso` skill first (with app `workday`) to get a logged-in Workday tab; reuse its `tabId` for everything below.

## Phase 2 — Open My Tasks

- `find` the "My Tasks" inbox icon in the top bar (the tray/inbox icon) and click it.
  If it isn't found by name, `read_page` (filter `interactive`) and click the inbox control.
- `wait` ~2–3s, then `screenshot` to confirm the My Tasks list is open.

## Phase 3 — List pending items

- Use `read_page` / `get_page_text` (or `find` "task list items") to enumerate each pending item with its visible title / type / subject / date / amount.
- If the list is empty (Workday shows no items, or the home said "You're all caught up"), report **"No pending tasks"** and stop.
- Otherwise present the items to the user as a numbered list.
- Default action is **list-only**.
  Ask which numbers to approve.

## Phase 4 — Confirm and approve

For each item the user selected, and only those:

1. Click the item to open it, then `find` the "Approve" button and click it.
2. A confirm/submit control may appear (a dialog or banner).
   `read_page`/`find` the actual "Submit"/"OK"/confirm control by its accessible name and click it.
   Do not rely on coordinates or dynamic ids.
3. Re-read the list to verify the item is gone.
   If it isn't, record a failure and move on.

Finish with a summary: approved, skipped, and failed.

## Safety

- Never approve an item the user did not explicitly select.
- Avoid clicking anything that triggers a native browser dialog (alert/confirm); it blocks the extension.
  Prefer in-page controls.
- If login can't be confirmed or a step fails repeatedly, stop and report.
