---
name: login-microsoft-sso-cdp
description: Use to ensure an authenticated browser tab for an app behind your organization's Microsoft (Entra) SSO — e.g. Workday, Engage, Outlook — driven by the `chrome-cdp` CLI (the cdp port of login-microsoft-sso). It drives the user's real, already-logged-in Chrome, so it types no credentials; it navigates to the app and, if redirected to a sign-in page, clicks that app's SSO entry, which bounces back in via the live session. A building block for the cdp automation skills — invoke it first (with the target app) so they operate on a logged-in tab. Invoked as /login-microsoft-sso-cdp.
disable-model-invocation: true
---

# Login to an SSO app (Microsoft-federated) — chrome-cdp port

Ensure there is a Chrome tab logged in to an app that authenticates through your organization's **Microsoft (Entra) SSO**, driven by the **`chrome-cdp`** CLI.
It drives the user's real Chrome, which already holds their Microsoft session — so this skill types **no** credentials.

> This is the cdp port of `login-microsoft-sso` (which uses the claude-in-chrome extension). Same behavior, different driver.
> Follow the **`drive-chrome-cdp`** skill for the CLI's setup, output contract, and passkey rule.
> Local skill, maintained in this repo (`.source.json` has `"repo": null`).

## Supported apps & config

The **supported-app list and the config schema are identical to `login-microsoft-sso`** — see that skill for the authoritative list and don't restate it here (it would drift).
Read the same never-committed config at runtime and take the requested app's entries: `~/.config/harness-configs/login-microsoft-sso/config` (`<APP>_HOME_URL`, `<APP>_SSO_BUTTON`). Do not hardcode URLs or button labels.

One behavioral note the steps below rely on: apps like `outlook` have **no** SSO button (`<APP>_SSO_BUTTON` unset) and auto-authenticate via the shared Microsoft session — for those, skip the SSO click and just navigate + verify.

## Steps

All commands take `--json`; parse the envelope and branch on the exit code (see `drive-chrome-cdp`).

1. **Connection.** `chrome-cdp doctor --json`. If `ok:false` (connection_failed), tell the user to enable `chrome://inspect/#remote-debugging`, then re-run. Do not proceed until ready.
2. **Pick a tab.** `chrome-cdp list --json`. Prefer a tab already on the app's host (reuse it in place); otherwise pick one to drive and note its `id`. Set it sticky: `chrome-cdp use <id>` (so later commands need no `--target`). Record that `id` — it is this skill's output.
3. **Config.** Source the config; take `<APP>_HOME_URL` and `<APP>_SSO_BUTTON` for the requested app.
4. **Navigate + settle.** `chrome-cdp nav "$HOME_URL" --json`, then let redirects settle: `chrome-cdp wait --url "<expected app host or path>" --timeout 15s --json`, or `chrome-cdp wait --for 3s --json` if you don't yet know the settled URL.
5. **Check where you landed.** `chrome-cdp eval "location.href" --json` (read `result.value`):
   - **On the app** (not a login/identity page): **done — return the tab id.**
   - **On the app's sign-in page** (a vendor identity host such as a Workday `*-identity.*` domain, or an app `/account/login` page): click that app's SSO entry.
     - `chrome-cdp snap --json` to confirm the button's exact accessible name, then
     - `chrome-cdp click --by name "$SSO_BUTTON" --json` (accessible-name addressing — robust; add `--role button`/`link` if the name is ambiguous). If the app has **no** SSO button (e.g. `outlook`), skip the click.
     - `chrome-cdp wait --url "<app host>" --timeout 15s --json` (or `wait --for 4s`).
6. **Re-check.** `chrome-cdp eval "location.href" --json`:
   - **Back on the app** (left the login/identity host): **done.**
   - **On Microsoft** (`login.microsoftonline.com`, or a passkey "Face, fingerprint, PIN or security key" screen): the SSO session expired.
     **Stop and ask the user to finish signing in manually in that Chrome tab** (their passkey/Touch ID), then continue once the app loads.
     Do not attempt the passkey programmatically.

## Output

The Chrome tab id (from `list`/`use`) logged in to the requested app, for the calling skill to reuse via `--target <id>` (or the sticky `use`).

## Safety

- Never type or handle credentials; the user's live session and passkey do the auth.
- If login can't be confirmed, stop and report — do not click blindly.
- `click --by name` targets the control by its accessible name; if it stalls, re-`snap` and retry (or `--wait ready`) rather than falling back to coordinates.
