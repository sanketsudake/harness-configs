---
name: drive-chrome-cdp
description: Use to drive the user's real, already-running local Chrome from the command line via the `chrome-cdp` (alias `cdp`) CLI — list/select tabs, read the page via an accessibility snapshot, click/type by CSS or ARIA accessible name, wait for redirects, evaluate JS, screenshot, or call any raw CDP method. Triggers include "click X in my browser", "read what's on my screen", "fill in this form in Chrome", "automate this web app in my logged-in session". The building block for automating logged-in web apps (Workday, Outlook, internal tools) in the user's own Chrome session; other automation skills follow this to get a driven, logged-in tab. Reuses Chrome's live logins, so it types no credentials.
---

# Drive local Chrome via chrome-cdp

`chrome-cdp` (alias `cdp`) drives the user's **real** Chrome over the DevTools Protocol — their actual tabs, logins, and cookies — from the shell.
Every command speaks a **uniform JSON envelope** and a **stable exit-code contract**, so an agent parses results and branches on failure class instead of scraping prose.
Because it drives the real profile, live logins are reused: **type no credentials** (see [Session & passkeys](#session--passkeys)).

> Binary: `chrome-cdp` on `PATH` (or `$CHROME_CDP_BIN`). Use `--json` on every command you parse.

## Setup (once)

1. Confirm the binary and connection: `chrome-cdp doctor --json`.
   - `ok:true` → Path B attach ready; proceed.
   - `ok:false` with `connection_failed` → tell the user to enable **`chrome://inspect/#remote-debugging`** (the one-time toggle), then re-run `doctor`. Do **not** work around consent.
2. A background daemon holds the connection, so Chrome's "Allow debugging?" prompt appears once per session, not per command. It starts on first use. `chrome-cdp daemon status --json` shows it; `--no-daemon` bypasses it.

## The loop

Work in this cycle, parsing `--json` and branching on the exit code:

```
list ─▶ use ─▶ snap ─▶ act ─▶ verify
```

1. **`list`** — enumerate tabs (`id`, `title`, `url`); pick the one you want.
2. **`use <target>`** — set the sticky current tab (or pass `--target` per command). Target grammar: `idprefix | url:<substr> | title:<substr> | @N`.
3. **`snap`** — accessibility-tree snapshot: the reliable way to *see* actionable controls by role + accessible name (it crosses shadow DOM and iframes). Orient here before acting.
4. **`act`** — click / type / nav (below).
5. **`verify`** — re-`snap` or `list`, or `wait`, to confirm the effect before the next step.

## Reading the page

- **`snap`** — roles + accessible names of everything actionable. Prefer this to raw HTML for "what can I click?" It sees shadow DOM + iframes.
- `text "<sel>"` / `html "<sel>"` — text / outer-HTML of a selector (or the page).
- `eval "<js>"` — run JS in the top frame (e.g. `eval "location.href"` to read the URL).

## Acting & addressing

Selector syntax is chosen with `--by`:

- **`--by name "<accessible name>"` — prefer this on real apps.** Matches by ARIA accessible name via the accessibility tree: it skips hidden/utility nodes (so it won't stall on a hidden "Skip to main content" link), and crosses shadow DOM + same-origin iframes. Add `--role button|link|textbox|…` to constrain, and `--nth N` (1-based) to disambiguate duplicates. Get the exact names from `snap`.
- `--by search "<text>"` — DevTools text/XPath/CSS search (broad; first match wins — can hit the wrong node on complex pages).
- `--by css` (default) / `--by id` / `--by jspath` — literal selectors; dynamic-id apps make these brittle.
- `--wait visible` (default) `| ready | enabled`; `--no-wait` to fail fast. If a click/read stalls waiting for visibility, retry with `--wait ready`.

Verbs: `click`, `type "<sel>" "<text>"` (real keystrokes; **append `\n` to submit** — it presses Enter), `nav <url>` (waits for load), `screenshot`, `pdf`, `attr get/list/set/rm`, `cookie …`, `raw <domain.method> [json]` (any CDP method — the escape hatch).

## Waiting

Beyond per-selector auto-wait:

- `wait --url "<substr>"` — until the tab's URL contains a string (redirect settle / leaving an identity host).
- `wait --visible "<sel>"` / `wait --gone "<sel>"` — until an element appears / disappears.
- `wait --for 3s` — fixed fallback; prefer a condition.

The command's `--timeout` bounds the wait; a wait that never resolves returns a clean `target/timeout` (exit 4).

## Session & passkeys

`chrome-cdp` drives the real profile, so an app the user is already signed into loads **authenticated** — no credentials typed.
If a `nav` lands on a **login / identity / passkey** page instead (e.g. `login.microsoftonline.com`, a "Face, fingerprint, PIN or security key" screen, or a vendor `*-identity.*` host):

**Stop and ask the user to finish signing in manually in that Chrome tab**, then continue once the app loads. Never type credentials or drive a passkey.

## Output contract

Every `--json` command emits one envelope:

```json
{ "ok": true, "command": "click", "target": {"id":"…","title":"…","url":"…"},
  "result": { … }, "elapsed_ms": 12 }
```

Failures: same shape with `"ok": false` and `error{code,message,…}`, plus a nonzero exit code — `0` ok · `1` generic · `2` usage · `3` connection · `4` target/timeout · `5` cdp · `6` daemon. Branch on these, not on message text (`chrome-cdp exit-codes` prints the table).

## Recipes

```sh
# See a page, then click a control by its accessible name
chrome-cdp use url:workday
chrome-cdp snap --json                                   # find the exact name
chrome-cdp click --by name "Request Absence" --role button --json

# Type into a field and submit
chrome-cdp type "#search" "Request Absence\n" --json     # \n presses Enter

# Navigate and wait for the redirect chain to settle
chrome-cdp nav "$APP_URL" --json
chrome-cdp wait --url "/home" --timeout 15s --json
```

## Safety

- **Review-gate writes.** Reads (`list`/`snap`/`text`/`eval` reads) are safe; before any state-changing click (submit, approve, delete, pay) show the plan and get explicit confirmation (`AskUserQuestion`).
- **Verify after acting** — re-`snap`/`list` to confirm, don't assume.
- **Avoid native dialogs** (`alert`/`confirm`/`prompt`): they block CDP. In-page app modals are fine.
- A live debug endpoint is full control of that Chrome — loopback-only, and the consent dialog/banner are never suppressed.
