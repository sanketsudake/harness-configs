---
name: drive-chrome-cdp
description: Use to drive the user's real, already-running local Chrome from the command line via the `chrome-cdp` (alias `cdp`) CLI — list/select tabs, read the page via an accessibility snapshot (with element refs, alerts, and widget state), click/type/`fill` (clear-and-set) form and grid-cell fields by CSS or ARIA accessible name, drive prompt/combobox/cascade widgets with `select`, read tables with `grid`, `scroll` virtualized grids, `wait` for redirects/text/settle, batch commands over one connection with `session`, evaluate JS, screenshot, or call any raw CDP method. Triggers include "click X in my browser", "read what's on my screen", "fill in this form in Chrome", "select the project in this Workday prompt", "automate this web app in my logged-in session". The building block for automating logged-in web apps (Workday, Outlook, internal tools) in the user's own Chrome session; other automation skills follow this to get a driven, logged-in tab. Reuses Chrome's live logins, so it types no credentials.
---

# Drive local Chrome via chrome-cdp

`chrome-cdp` (alias `cdp`) drives the user's **real** Chrome over the DevTools Protocol — their actual tabs, logins, and cookies — from the shell.
Every command speaks a **uniform JSON envelope** and a **stable exit-code contract**, so an agent parses results and branches on failure class instead of scraping prose.
Because it drives the real profile, live logins are reused: **type no credentials** (see [Session & passkeys](#session--passkeys)).

> Binary: `chrome-cdp` on `PATH` (or `$CHROME_CDP_BIN`).
> Use `--json` on every command you parse.

## Setup (once)

1. Confirm the binary and connection: `chrome-cdp doctor --json`.
   - `ok:true` → Path B attach ready; proceed.
   - `ok:false` with `connection_failed` → tell the user to enable **`chrome://inspect/#remote-debugging`** (the one-time toggle), then re-run `doctor`.
     Do **not** work around consent.
2. A background daemon holds the connection, so Chrome's "Allow debugging?" prompt appears once per session, not per command.
   It starts on first use.
   `chrome-cdp daemon status --json` shows it; `--no-daemon` bypasses it.
3. **Avoid re-triggering the consent prompt.**
   A fresh attach (the first command after `daemon stop`, or after a Chrome restart) re-shows Chrome's "Allow remote debugging?" prompt; if it isn't clicked it can wedge Chrome.
   Keep the daemon alive — don't `daemon stop` mid-session.
   If a command returns `connection_failed`, its message now says whether to click the Allow prompt (it can hide behind the window) or restart Chrome.
   To skip the prompt entirely, have the user launch Chrome with `--remote-debugging-port=9222` (e.g. `open -a "Google Chrome" --args --remote-debugging-port=9222`).

## The loop

Work in this cycle, parsing `--json` and branching on the exit code:

```
list ─▶ use ─▶ snap ─▶ act ─▶ verify
```

1. **`list`** — enumerate tabs (`id`, `title`, `url`); pick the one you want (`list --url <substr>` / `--title <substr>` filters, so you don't grep the whole list).
   No tab for the app yet?
   **`open <url>`** creates one, navigates, returns its id, and makes it current.
2. **`use <target>`** — set the sticky current tab (or pass `--target` per command).
   Target grammar: `idprefix | url:<substr> | title:<substr> | @N`.
3. **`snap`** — accessibility-tree snapshot: the reliable way to *see* actionable controls by role + accessible name (it crosses shadow DOM and iframes).
   Orient here before acting.
4. **`act`** — click / type / select / nav (below).
5. **`verify`** — re-`snap`, `wait`, or read `snap.alerts` to confirm the effect before the next step.

## Reading the page

- **`snap`** — roles + accessible names of everything actionable, plus:
  - `alerts` — aria-live / role=alert|status text: the toasts and success banners (e.g. `"Success! Event approved"`).
    **Confirm a write via `snap.alerts` or `wait --text`, not a screenshot.**
  - `focused` — the currently-focused element (`{role,name}`).
  - per node: `states` (`focused`, `expanded`, `checked`, `selected`, `disabled`, `required`, `pressed`) and `value` — so you see widget state without a screenshot.
  - per node: `ref` (`e<id>`) — a stable element ref you can act on later with `--by ref` (no re-snapping by name).
    See [Batch mode & refs](#batch-mode--refs).
  - It crosses shadow DOM + iframes.
  - **Filter server-side** so you get just the relevant nodes, not the whole tree (a page can be hundreds of nodes): `--role <role>`, `--grep <name-regex>`, `--region <container-name>` (scope to a container's subtree), `--dedupe` (collapse identical role+name — for virtualized grids that render an item at several scroll positions).
    E.g. `snap --role button --grep "[AP]M"` to pull just the calendar events.
    `alerts`/`focused` stay page-wide.
- **`value --all "<css>"`** — the value/text of every match as a list (a whole row of hour cells, a set of pills) in one call.
- **`grid [selector]`** — read a table/grid as `{headers, rows, count}` from the accessibility structure.
  Use this for the calendar / task-list / timesheet grids instead of hand-parsing `snap` or screenshotting.
  `selector` optionally picks the grid by accessible name; empty = the first grid.
- `text "<sel>"` / `html "<sel>"` — text / outer-HTML of a selector (or the page).
- `eval "<js>"` — run JS in the top frame (e.g. `eval "location.href"` to read the URL).

## Acting & addressing

Selector syntax is chosen with `--by`:

- **`--by name "<accessible name>"` — prefer this on real apps.**
  Matches by ARIA accessible name via the accessibility tree: it skips hidden/utility nodes (so it won't stall on a hidden "Skip to main content" link), and crosses shadow DOM + same-origin iframes.
  Add `--role button|link|textbox|…` to constrain, and `--nth N` (1-based) to disambiguate duplicates.
  Get the exact names from `snap`.
- **`--match exact|contains|regex`** (with `--by name`) — real apps use verbose names (`"Review Approval: Awaiting Action by …"` vs `"Review"`); `--match contains` (case-insensitive substring) clicks by a fragment without copying the whole name.
  Default is `exact`.
- **`--by ref "e<id>"`** — act on the exact element a prior `snap` reported, without re-resolving by name (the ref is stable for the document's lifetime).
- **`--by cell "[row|]column header"`** — resolve the editable input in a grid cell by its column header (and optional row header): `fill --by cell "Mon, 7/13" "8"`.
  Kills mapping grid inputs by coordinate; use `"Regular|Mon, 7/13"` to disambiguate a row in a multi-row grid.
- **`--by label "<visible label text>"`** — resolve a **form control** (input/select/textarea) by the label text shown next to it, for forms whose labels aren't wired to the control (no `aria-label`, no `<label for>` — e.g. a native `<select>` with a sibling `<span>` label).
  `select --by label "Activity Category" "…"`, `fill --by label "Notes" "…"`.
  Resolves via `querySelector`, so it isn't a11y-throttled on a hidden tab.
  Prefer this over `eval`-ing to find a CSS selector for an unlabelled control.
- **`--in-row "<text>"`** (with `--by name`) — scope the accessible-name match to the table row (`[role=row]`/`<tr>`) whose text contains `<text>`, so a control repeated across rows resolves to the right one: `click --by name "Delete" --in-row "TEST entry" --role button` clicks the Delete in that row, not the first of many.
  Resolves via the DOM (closest-row ancestor), so it isn't a11y-throttled on a hidden tab; it can't combine with `--by ref`/`cell`/`label`.
- `--by search "<text>"` — DevTools text/XPath/CSS search (broad; first match wins — can hit the wrong node on complex pages).
- `--by css` (default) / `--by id` / `--by jspath` — literal selectors; dynamic-id apps make these brittle.
- `--wait visible` (default) `| ready | enabled`; `--no-wait` to fail fast.
  If a read stalls waiting for visibility, retry with `--wait ready`.

Verbs: `open <url>` (new tab → navigate → current), `click`, `type "<sel>" "<text>"` (real keystrokes; **append `\n` to submit** — it presses Enter), `fill "<sel>" "<value>"` (**sets a field, replacing its content** — triple-click-selects then types, so a pre-filled cell showing `0` becomes `8`, not `80`; use this for form/grid fields, `type` only when you mean to append), `select` (see below), `nav <url>` (waits for load), `scroll`, `grid`, `screenshot`, `pdf`, `attr get/list/set/rm`, `cookie …`, `raw <domain.method> [json]` (any CDP method — the escape hatch).

`click`/`type`/`fill`/`select` accept **`--wait-text "<substr>"`**: after the action, block until the page contains the text (a `Saved` toast) — folds act + confirm into one call, e.g. `click --by name "Save and Close" --role button --wait-text "saved"`.

`click`/`type`/`fill` accept **`--on-dialog accept|dismiss`**: auto-handle a **native** JS dialog (`alert`/`confirm`/`prompt`) that the action triggers, and report it in the result — otherwise a native dialog blocks the renderer and **wedges the connection** (every skill warns to avoid this).
Use it defensively on any control that might raise one, e.g. `click --by name "Delete" --in-row "TEST entry" --role button --on-dialog accept`.
Note this only covers *native* dialogs; an **in-page** (React/Angular) "Are you sure?" modal is normal DOM — `snap` surfaces it (often under `alerts`) and you click its `Yes`/`OK` button.

**`click` and `type` drive the element with a coordinate pointer sequence at its live, occlusion-verified centre** (the same primitive as `select`), and bring the tab to the front first.
Two consequences worth knowing:
- They only fire when the centre pixel resolves to the target (or a descendant); a control hidden under an overlay fails fast instead of a click landing on the overlay.
- Chrome drops synthetic input on a background/inactive tab; the built-in bring-to-front handles the normal "switched to another tab" case.
  But `--by name`/`--by ref`/`--by cell` resolve via the accessibility tree, which Chrome **throttles on a tab it can't foreground** — so on a tab that can't be brought forward (e.g. Chrome isn't the frontmost app), those resolutions can stall.
  When that happens the command returns **`tab_hidden: true`** in the error (with an actionable message) rather than a bare timeout — foreground Chrome/the tab, or use `--by css` (it resolves via `querySelector`, which isn't throttled).
  `--by name` also falls back to a DOM accessible-name match on a hidden tab, so it often still works — but **`--by css` is the reliable choice when driving a background tab.**

### `select` — prompt / combobox / cascade widgets

Some widgets (Workday's Time Type cascade, portal menus, native `<select>`) can't be opened by a plain `click`/`type` — the popup mounts collapsed and a single synthetic click closes it.
**`select <field> <option>` encapsulates the whole choreography**: resolve the field, open it, walk the cascade, and commit the value — atomically over one connection.

```sh
# Cascade prompt: field by accessible name, option as a `>`-separated path.
chrome-cdp select "Time Type" "Project Plan Tasks > Acme: Widget Platform > Project > Time Entry" --role textbox --json
# A portal menu (button → menu → option) works too:
chrome-cdp select "Actions" "Enter Time by Type" --role button --json
```

- The field is addressed by accessible name by default (`--role textbox` disambiguates an input from a same-named column header; an explicit `--by` overrides).
- The option is a **`>`-separated cascade path** (`--sep` changes the separator); each segment is matched by **substring** (`--option-match exact|contains|regex`).
  Give every level a real Workday cascade needs — the tree can be several deep, and a segment that resolves to a category rather than a leaf makes `select` **error** (never a false success).
- `--filter "<text>"` types into the prompt to narrow a long list before selecting.
- A native `<select>` is a sub-mode (set by option text).
- Workday's Actions menu anchors inconsistently — `select "Actions" "…"` may return a safe `did not render / settle` (no wrong click); just re-run.

## Waiting

Beyond per-selector auto-wait:

- `wait --url "<substr>"` — until the tab's URL contains a string (redirect settle / leaving an identity host).
- `wait --visible "<sel>"` / `wait --gone "<sel>"` — until an element appears / disappears.
- **`wait --text "<substr>"`** — until the page (accessibility tree, incl. alerts) contains the text, e.g. `wait --text "Success"` right after a write.
- **`wait --stable`** — until the accessibility tree stops changing (the page settled); use it instead of guessing a fixed sleep after an action.
- **`wait --idle`** — until network activity settles; for SPA loads (Outlook, Workday) where the load event fires long before the content is fetched — prefer this over a fixed sleep after `nav`/`open`.
  It also settles when the page holds a **websocket / long-poll / EventSource** stream open (it treats a still-open request as idle once the connection goes quiet for ~2s), so it won't hang on Workday-class apps whose streams never "finish".
  When you need "the content/toast is actually there" rather than "the network went quiet", prefer **`--stable`** (a11y tree stopped changing) or **`--text "<substr>"`** (a specific string appeared).
- `wait --for 3s` — fixed fallback; **prefer a condition** (`--text`/`--stable`/`--idle`) — guessing seconds is slower and flakier.

The command's `--timeout` bounds the wait; a wait that never resolves returns a clean `target/timeout` (exit 4).

## Scrolling

- `scroll --dy <px>` (and `--dx`) — scroll the window (or a selector's scroll box) by a delta; deterministic, and it fires the scroll events virtualized grids render on.
- `scroll "<sel>" --to` — scroll a selector into view.
- `scroll "<sel>" --dy <px> --wheel` — dispatch a real mouse wheel for grids that render on wheel specifically (e.g. Outlook's virtualized calendar).

## Batch mode & refs

For a multi-step flow, `session` avoids a process spawn + reconnect per command:

- **`session`** reads one command per stdin line as a **JSON argv array**, runs each over a single held connection, and emits one JSON envelope per line (NDJSON).
  Comment (`#`) and blank lines are skipped; it exits 0 on clean EOF with per-line status in the envelopes.
- Combine with `snap`'s `ref` and `--by ref` to act on nodes without re-resolving them:

```sh
printf '%s\n' \
  '["use","url:workday"]' \
  '["snap"]' \
  '["click","e42","--by","ref"]' | chrome-cdp session
```

Filling a grid is the natural fit — cell-addressed `fill`s + a single `value --all` read-back over one connection, then act-and-confirm the save:

```sh
printf '%s\n' \
  '["fill","--by","cell","Mon, 7/13","8"]' \
  '["fill","--by","cell","Tue, 7/14","8"]' \
  '["fill","--by","cell","Wed, 7/15","8"]' \
  '["value","--all","input[data-automation-id=numericInput]"]' \
  '["click","--by","name","Save and Close","--role","button","--wait-text","saved"]' \
  | chrome-cdp session
```

## Session & passkeys

`chrome-cdp` drives the real profile, so an app the user is already signed into loads **authenticated** — no credentials typed.
If a `nav` lands on a **login / identity / passkey** page instead (e.g. `login.microsoftonline.com`, a "Face, fingerprint, PIN or security key" screen, or a vendor `*-identity.*` host):

**Stop and ask the user to finish signing in manually in that Chrome tab**, then continue once the app loads.
Never type credentials or drive a passkey.

## Output contract

Every `--json` command emits one envelope:

```json
{ "ok": true, "command": "click", "target": {"id":"…","title":"…","url":"…"},
  "result": { … }, "elapsed_ms": 12 }
```

Failures: same shape with `"ok": false` and `error{code,message,…}`, plus a nonzero exit code — `0` ok · `1` generic · `2` usage · `3` connection · `4` target/timeout · `5` cdp · `6` daemon.
Branch on these, not on message text (`chrome-cdp exit-codes` prints the table).

## Recipes

```sh
# See a page, then click a control by a fragment of its verbose name
chrome-cdp use url:workday
chrome-cdp snap --json                                   # find the name / ref
chrome-cdp click --by name "Review" --match contains --role button --json

# Confirm a write via the toast, no screenshot
chrome-cdp click --by name "Approve" --role button --json
chrome-cdp wait --text "Success" --json

# Drive a Workday cascade prompt that click/type can't open
chrome-cdp select "Time Type" "Project Plan > Acme: Widget Platform > Project > Time Entry" --role textbox --json

# Read a grid instead of screenshotting it
chrome-cdp grid --json

# Navigate and wait for the redirect chain to settle
chrome-cdp nav "$APP_URL" --json
chrome-cdp wait --url "/home" --timeout 15s --json
```

## Safety

- **Review-gate writes.**
  Reads (`list`/`snap`/`grid`/`text`/`eval` reads) are safe; before any state-changing click (submit, approve, delete, pay) or a `select`/`type` that commits data, show the plan and get explicit confirmation (`AskUserQuestion`).
- **Verify after acting** — re-`snap`/`grid`/`list`, or `wait --text`, to confirm; don't assume.
- **Avoid native dialogs** (`alert`/`confirm`/`prompt`): they block CDP.
  In-page app modals are fine.
- A live debug endpoint is full control of that Chrome — loopback-only, and the consent dialog/banner are never suppressed.
