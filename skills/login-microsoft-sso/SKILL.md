---
name: login-microsoft-sso
description: Use to ensure an authenticated browser tab for an app behind your organization's Microsoft (Entra) SSO — e.g. Workday, Engage, Outlook — via the claude-in-chrome extension, which reuses the user's real, already-logged-in Chrome session. A building block for the other automation skills — invoke it first (with the target app) so they operate in a logged-in tab. Invoked as /login-microsoft-sso.
disable-model-invocation: true
---

# Login to an SSO app (Microsoft-federated)

Ensure there is a browser tab logged in to an app that authenticates through your organization's **Microsoft (Entra) SSO**, using the `claude-in-chrome` extension.
The extension drives the user's real Chrome, which already holds their Microsoft session — so this skill types **no** credentials.
It navigates to the app's home and, if redirected to a sign-in page, clicks that app's SSO entry, which bounces straight back in via the live session.

Supported apps (the caller passes one; add more in the local config):

- `workday` — Workday (My Tasks, timesheet).
- `engage` — Engage (activity/points platform).
- `outlook` — Outlook web (mail/calendar, Microsoft 365).
  Auto-authenticates via the shared Microsoft session — there is **no** app SSO button; just navigate and verify.

> Local skill, maintained in this repo (`.source.json` has `"repo": null`).
> Soft dependency: the `claude-in-chrome` skill/extension.
> The app domains must be permitted in the extension.

## Background (why this shape)

`agent-browser` and other fresh-profile browsers can't be used: the org's tenant forces a passkey login with no password fallback, and a separate browser can't inherit Chrome's encrypted session or platform passkey.
Driving the user's own Chrome via `claude-in-chrome` sidesteps login entirely; all these apps share the one Microsoft session.

## Prerequisites

App URLs and SSO button labels are org/tenant-specific, so they live in a local config that is never committed: `~/.config/harness-configs/login-microsoft-sso/config`.
Read the entries for the requested app at runtime; do not hardcode them here.

```bash
. ~/.config/harness-configs/login-microsoft-sso/config
# workday: $WORKDAY_HOME_URL / $WORKDAY_SSO_BUTTON
# engage:  $ENGAGE_HOME_URL  / $ENGAGE_SSO_BUTTON
# outlook: $OUTLOOK_HOME_URL  (no SSO button — auto-auth via the Microsoft session)
```

## Steps

1. Load the `claude-in-chrome` skill, then call `tabs_context_mcp` to get (or create) a tab.
   Use that `tabId` for everything below.
2. Pick the home URL and SSO button label for the requested app from the config (`<APP>_HOME_URL`, `<APP>_SSO_BUTTON`).
3. `navigate` the tab to the app's home URL, then `wait` ~3s for it to settle.
4. Check the tab's URL:
   - On the app (not a login/identity page): **done — return the tabId.**
   - Redirected to the app's sign-in page (a vendor identity host such as a Workday `*-identity.*` domain, or an app `/account/login` page): `find` the link/button matching the app's SSO button label and click it, then `wait` ~4s.
     If the app has no SSO button (e.g. `outlook`, which redirects straight to Microsoft), skip the click — the live session bounces in automatically; just `wait`.
5. Re-check the URL:
   - Back on the app (left the login/identity host): **done.**
   - Landed on Microsoft (`login.microsoftonline.com` / a passkey "Face, fingerprint, PIN or security key" screen): the SSO session expired.
     **Stop and ask the user to finish signing in manually in that Chrome tab** (their passkey/Touch ID), then continue once the app loads.
     Do not attempt the passkey programmatically.

## Output

A `claude-in-chrome` tab (its `tabId`) logged in to the requested app, for the calling skill to reuse.

## Safety

- Never type or handle credentials; the user's live session and passkey do the auth.
- If login can't be confirmed, stop and report — do not click blindly.
