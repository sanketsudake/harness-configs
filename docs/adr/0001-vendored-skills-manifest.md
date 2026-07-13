---
status: accepted
---

# Vendored skills are recorded in a manifest, not committed as source

Vendored skills (`repo != null`) stop having their files committed to this repo.
Instead a single committed manifest, `skills/vendored.json`, pins each one to an upstream `repo`/`subpath`/`commit` (plus cached `category` and `description`), and `make install` materializes the files from those pins into a gitignored `skills/<name>/` tree.
We did this so our git history stops carrying — and reviewing — copies of upstream source we don't author, while `make skills-update-all` re-resolving the pins gives deliberate, one-commit "get latest".
Authored skills (`repo: null`) are out of scope: this repo is their only home, so they stay committed exactly as before.

## Considered options

- **Keep committing vendored source (status quo)** — reproducible and offline, but every `skills-update` rewrites foreign files as large diffs, and ours-vs-theirs is muddled in history.
  Rejected: that review/maintenance noise is the pain we set out to remove.
- **Floating HEAD on every install** — truly "always latest" with no lock, but non-reproducible across machines/time and skills change under you silently.
  Rejected: reproducibility is the core value of a config repo; "latest" is instead an explicit `skills-update-all`.
- **Per-skill committed sidecar (`.source.json` only) instead of one manifest** — reuses the existing sidecar-walking tooling almost unchanged, but spreads the "list" across 25 files with no single review surface.
  Rejected: a single manifest better matches the "just maintain a list of skills" intent.
- **Commit `SKILL.md` + sidecar, gitignore only heavy bundled assets** — keeps the catalog trivial and sheds the ~93% of bytes that are docx/pptx/xlsx assets, but still tracks and diffs the skill's source text.
  Rejected: the driver was provenance, not size, so half-vendoring the text misses the point.

## Consequences

- A fresh clone needs network for `make install` to materialize vendored skills; offline, authored skills still work and missing vendored ones are reported as skipped.
- The catalog (`skills/README.md`) and `skills-doctor` render from committed state because the manifest caches each vendored skill's `category` and `description` — no materialization required to check catalog freshness.
- `resource-manager.sh` makes `skills/vendored.json` the source of truth for vendored skills; `fetch`/`update`/`list`/`category`/`delete`/`catalog`/`doctor` re-point to it, and a new materialize step reconstructs the tree.
- Migration is gated by a byte-identity check: materializing from the manifest into a clean tree must diff-clean against today's committed vendored files before the cutover merges.
