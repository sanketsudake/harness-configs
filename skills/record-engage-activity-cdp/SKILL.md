---
name: record-engage-activity-cdp
description: Use when the user wants to record an activity in Engage (the org's activity/points platform) — e.g. a billed work week, a phone interview, or an attended course/class (e.g. ImprovingU) — via the chrome-cdp CLI; the cdp port of record-engage-activity, invoked as /record-engage-activity-cdp. Fills the Add Activity form (category, type, date, quantity, notes) and submits only after user confirmation; can derive a class's date/hours from Outlook. Drives the user's real Chrome via chrome-cdp (logs in through login-microsoft-sso-cdp).
disable-model-invocation: true
---

# Record Engage Activity — chrome-cdp port

Assisted, review-first automation of the Engage **Add Activity** form, driven by the **`chrome-cdp`** CLI (the user's real, logged-in Chrome).
It fills category, type, date, quantity, and notes, then **shows the entry and the points it will add, and submits only after the user confirms** — submitting writes real data and points.

> ⚠️ **DRAFT — needs live validation.** cdp port of `record-engage-activity`; ported faithfully (category/type select, date-shift caveat, confirm-then-submit) but not yet validated against a live tenant — Category/Type may be native `<select>`s, which cdp's click-based selection drives less reliably than a custom listbox. Go slowly, `snap`-verify; fall back to `record-engage-activity` (claude-in-chrome) if a step misbehaves.
> Follow **`drive-chrome-cdp`** for the CLI (`--json`/exit codes, `--by name`, `snap`, `wait`, passkey rule). Soft dep: **`login-microsoft-sso-cdp`** (app `engage`).

## Defaults & presets (local config, never committed)

Read from the **same config as `record-engage-activity`** — `~/.config/harness-configs/record-engage-activity/config` (shared; user/tenant-specific, not hardcoded here):

```bash
. ~/.config/harness-configs/record-engage-activity/config
# $ENGAGE_ACTIVITY_URL, and ENGAGE_PRESET_<NAME> presets
```

Schema (`ENGAGE_ACTIVITY_URL`, `ENGAGE_PRESET_*`) is identical to `record-engage-activity` — see that skill for the authoritative list; don't restate it here (it would drift). Presets are conveniences; the user can also pick any category/type from the live controls. A `billed-week` pairs with `fill-workday-timesheet-cdp`.

### Education/Coaching (course attendance)

- Types include `ImprovingU Attendance` plus prep/facilitation/instructor variants — `snap` the type control for the live list (each shows its own guidance once selected).
- **Quantity** is *class hours* (1.5 h class → 1); **Notes** names the class (`<course> - <session, instructor>`).
- **Date** is the day attended; if unstated, find the class via Outlook (`login-microsoft-sso-cdp` app `outlook`; `snap` the week view for `<title>, <start> to <end>, <date>`) for date/duration.

## Phase 1 — Authenticate

Follow **`login-microsoft-sso-cdp`** (app `engage`) to get a logged-in Engage tab; `chrome-cdp use <id>` so later commands need no `--target`.

## Phase 2 — Open the Add Activity form

`chrome-cdp nav "$ENGAGE_ACTIVITY_URL" --json`, `wait --for 3s`, then `snap --json` to locate: **Activity Category**, **Activity Type**, **Date**, **Quantity**, **Notes**, and the submit button (labelled "Add N points").

## Phase 3 — Gather the entry

Determine, asking where not implied: **Activity** — preset name (e.g. `billed-week`, `phone-interview`) or explicit category + type, resolving a preset to its `<Category>` / `<Type>`; **Notes** — required free text (e.g. `"22-26 work week"`, or the candidate/round); **Date** — default today; **Quantity** — default 1.

## Phase 4 — Fill the form

1. **Activity Category**: click `--by name "Activity Category"` to open it, then `--by name "<Category label>" --role option` (snap first for exact wording — the list is fixed).
2. `wait --for 1s` (Type repopulates from the chosen category), then set **Activity Type** the same way: click the control, `snap` its options, click `--by name "<Type label>" --role option`.
3. **Date** (only if not default), **Quantity**, **Notes**: `chrome-cdp type --by name "<field>" "<value>" --json` (no trailing `\n` — none of these submit).
   - **Timezone shift**: the widget stores local midnight, converted to UTC server-side — in a behind-UTC timezone the stored date is the **previous day**. Set the field to **target date + 1** to land exactly (weekly activities need no compensation); verify the submitted row's Date column after.
   - A date-picker click is sometimes ignored (only highlights); re-check and click again if unchanged.

## Phase 5 — Review and submit

- Re-`snap` (or `screenshot`): the submit button now reads **"Add N points"** — N is the points the chosen type grants.
- Present the full entry — category, type, date, quantity, notes, **and N points** — via `AskUserQuestion`, submit recommended alongside "edit first" / "don't submit".
- Only on explicit confirmation: `chrome-cdp click --by name "Add N points" --role button --json` (exact label read above).
- `wait --for 2s`, then re-`snap`/`text` **Current Activities** to confirm the new row (matching category/type/date/notes) is at the top. Report a summary.

## Safety

- Never submit ("Add N points") without the user's explicit confirmation of the entry.
- Pick category/type by visible accessible name, not position/index — order can change.
- Avoid actions that trigger a native browser dialog (`alert`/`confirm`); they block cdp.
- If a step fails repeatedly, or a control is a native `<select>` click-based selection can't drive, stop and report — fall back to `record-engage-activity`.
