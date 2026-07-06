---
name: record-engage-activity
description: Use when the user wants to record an activity in Engage (the org's activity/points platform) — e.g. a billed work week, a phone interview, or an attended course/class (ImprovingU, Udemy) — invoked as /record-engage-activity. Fills the Add Activity form (category, type, date, quantity, notes) and submits only after the user confirms; can derive a class's date and hours from the user's Outlook calendar. Runs in the user's real Chrome via claude-in-chrome (logs in through the login-microsoft-sso skill).
disable-model-invocation: true
---

# Record Engage Activity

Assisted, review-first automation of the Engage **Add Activity** form, driven by the `claude-in-chrome` extension (the user's real, logged-in Chrome).
It fills category, type, date, quantity, and notes, then **shows the entry and the points it will add, and submits only after the user confirms** — submitting writes real data and points.

> Local skill, maintained in this repo (`.source.json` has `"repo": null`).
> Soft dependency: the `login-microsoft-sso` skill (logged-in tab) and the `claude-in-chrome` extension.

## Defaults & presets (local config, never committed)

Read from `~/.config/harness-configs/record-engage-activity/config` (user/tenant-specific, so not hardcoded here):

```bash
. ~/.config/harness-configs/record-engage-activity/config
# $ENGAGE_ACTIVITY_URL, and presets ENGAGE_PRESET_<NAME>="<Category> > <Type>"
```

- `ENGAGE_ACTIVITY_URL` — the Add Activity page.
- `ENGAGE_PRESET_*` — named presets, each `"<Category> > <Type>"`, e.g.:
  - `ENGAGE_PRESET_BILLED_WEEK="Direct Revenue > 40 Billable Hour Week"`
  - `ENGAGE_PRESET_PHONE_INTERVIEW="Recruiting > Interview - Phone"`
  - `ENGAGE_PRESET_COURSE_ATTENDED="Education/Coaching > ImprovingU Attendance"`

Presets are conveniences; the user can also pick any category/type from the live dropdowns.
A `billed-week` activity corresponds to a fully-filled Workday timesheet week (40+ billable hours) — it pairs naturally with the `fill-workday-timesheet` skill: a week filled there is reportable here.

### Education/Coaching (course attendance)

- The category's types include `ImprovingU Attendance` (per the form's guidance, Udemy courses also count under it), plus course-prep/facilitation/instructor variants — `read_page` the type select for the live list.
- **Quantity** is in *class hours*: record each **full** hour spent in a session (a 1.5 h class → 1).
- **Notes** must name the class (e.g. `<course name> - <session name with instructor>`).
- **Date** is the day attended.
  If the user doesn't state it, find the class event in their Outlook calendar (via `login-microsoft-sso` with app `outlook`; the week view's event button exposes `<title>, <start> to <end>, <weekday, date>` — `find` it) and take the date and duration from the event.

## Phase 1 — Authenticate

Follow the `login-microsoft-sso` skill first (with app `engage`) to get a logged-in Engage tab; reuse its `tabId`.

## Phase 2 — Open the Add Activity form

- `navigate` the tab to `ENGAGE_ACTIVITY_URL`, `wait` ~3s, then `read_page` (filter `interactive`) to locate the form: **Activity Category** select, **Activity Type** select, **Date**, **Quantity**, **Notes**, and the submit button (labelled "Add N points").

## Phase 3 — Gather the entry

Determine, asking the user where not implied:

- **Activity** — a preset name (e.g. `billed-week`, `phone-interview`) or an explicit category + type.
  Resolve a preset to its `<Category>` / `<Type>`.
- **Notes** — required free text (e.g. `"22-26 work week"`, or the candidate/round for an interview).
- **Date** — default today; accept an override.
- **Quantity** — default 1.

## Phase 4 — Fill the form

1. Set **Activity Category**: `form_input` the category select with the exact option label (e.g. `Direct Revenue`).
   The category list is fixed; if the user's term doesn't match, `read_page` the select's options and pick the closest, confirming with the user.
2. `wait` briefly — the **Activity Type** select populates from the chosen category — then `form_input` it with the type label (e.g. `40 Billable Hour Week`).
   Re-`read_page` the type options first if unsure of exact wording.
3. Set **Date** (`form_input`, format `MM/DD/YYYY`) only if different from the default; **Quantity** (`form_input`, default 1); **Notes** (`form_input`).
   - Caveat — the one-day shift applies to **both** input methods (`form_input` *and* the date-picker UI): the widget stores local midnight, the server converts to UTC, so in a behind-UTC timezone the stored date is the **previous day**.
     To land on an exact day, **set the field to target date + 1** (e.g. pick `07/02` to record `07/01`) and verify the submitted row's Date column afterwards.
     For a weekly activity the exact in-week day is immaterial, so no compensation is needed.
   - The shift can also trip validation: the server checks the (UTC) date against the selected **Reporting Period**, so an uncompensated date at a quarter boundary fails with *"Activity Date is not within the Reporting Period"* — fix by compensating +1 as above, not by switching the period.
   - The date-picker sometimes ignores the first click on a day (it only highlights); re-check the field value and click the day again if unchanged.

## Phase 5 — Review and submit

- Re-`read_page`/`screenshot`: the submit button now reads **"Add N points"** — N is the points the chosen type grants.
- Show the user the full entry: category, type, date, quantity, notes, **and N points**.
- **Wait for explicit confirmation**, then click the submit button.
- `wait`, then verify the new row appears at the top of **Current Activities** (matching category/type/date/notes).
  Report a summary.

## Safety

- Never submit ("Add N points") without the user's explicit confirmation of the entry.
- Pick category/type by their visible label, not by position/index (the recording's `5: Object` indices are opaque and order can change).
- Avoid actions that trigger a native browser dialog (alert/confirm) — they block the extension.
- If a step fails repeatedly or the form differs from the above, stop and report rather than guessing.
