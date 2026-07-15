---
name: approve-workday-tasks-cdp
description: Use when the user wants to review and approve their pending Workday "My Tasks" approvals via the chrome-cdp CLI — the cdp port of approve-workday-tasks, invoked as /approve-workday-tasks-cdp. Lists pending items and approves only the ones the user explicitly selects. Drives the user's real Chrome via chrome-cdp (logs in through login-microsoft-sso-cdp).
disable-model-invocation: true
---

# Approve Workday Tasks — chrome-cdp port

Assisted, review-first automation of the Workday **My Tasks** approval flow, driven by the **`chrome-cdp`** CLI (the user's real, logged-in Chrome).
It **lists** the pending items and approves **only** the items the user selects.
Never approve anything the user did not explicitly choose.

> ✅ **Validated live end-to-end (2026-07-15)** — two real Time Entry approvals went through: authenticate → open My Tasks via `click --by name "Go to My Tasks (N)"` → enumerate → (Review →) Approve → "Success! Event approved". cdp port of `approve-workday-tasks`. Fall back to the original (claude-in-chrome) if a run misbehaves.
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

1. Open it: `chrome-cdp click --by name "<item title>" --json` (`snap` for the exact name; `--nth` if titles repeat). This may land on a **View Event** page whose only action is **Review** — its *accessible name* is verbose, e.g. `"Review Approval: Awaiting Action by <You>"` (the visible text is just "Review"), so **take the exact name from `snap`** and `chrome-cdp click --by name "Review Approval: Awaiting Action by <You>" --role button --json` to enter the approval task. (After approving one item, the queue often auto-advances to the next already-open with its Approve button — no re-open needed.)
2. Approve: `chrome-cdp click --by name "Approve" --role button --json`. For a **Time Entry Approval** this finalizes it — there is **no** separate Submit. Other task types *may* show a Submit/OK; `snap` and click it by its exact name only if present.
3. Verify by the **"Success! Event approved"** message / the event's **Overall Status → "Successfully Completed"** — NOT the top-bar My Tasks badge, which lags. Then move to the next item.

> Naming note: exact accessible-name matching (`--by name`) means the string must match what `snap` reports, not the visible label (they differ, as with "Review"). Always `snap` first; use `--nth` to disambiguate duplicates.

Finish with a summary: approved, skipped, and failed.

## Safety

- Never approve an item the user did not explicitly select.
- Avoid clicking anything that triggers a native browser dialog (it blocks cdp); prefer in-page controls.
- If login can't be confirmed or a step fails repeatedly, stop and report rather than improvising.
