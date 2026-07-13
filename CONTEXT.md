# harness-configs

Domain glossary for this repo.
Currently scoped to the skill-provisioning model, since that is where the terminology is load-bearing.

## Language

### Skill provenance

**Vendored skill**: A skill under `skills/` whose files originate from an upstream git repo.
Its sidecar records a non-null `repo`; prose calls it vendored, the machine field calls it `remote`.
_Avoid_: external skill, third-party skill.

**Authored skill**: A skill written in this repo with no upstream — this repo is its only home, so it is always committed.
Its sidecar records `"repo": null`; the machine field calls it `local`.
_Avoid_: own skill, first-party skill.

### Vendoring model

**Manifest**: The single committed file `skills/vendored.json` — the whole list of vendored skills, each entry carrying `name`, `repo`, `subpath`, `ref`, `commit`, `category`, and a cached `description`.
The desired state a human edits, and the only place a vendored skill is recorded once its files stop being committed.
The cached `description` and `category` exist so the catalog renders on a fresh clone without materializing.

**Pin**: The exact upstream commit SHA a vendored skill is fetched at, recorded so every install of the same manifest reproduces the same bytes.
Re-resolving a `ref` to a newer commit and rewriting the pin is the deliberate act of "getting latest".
_Avoid_: version, tag (a pin is always a full commit SHA, not a human ref).

**Materialize**: To fetch a vendored skill's files from its pinned commit into the working `skills/` tree at install time.
The inverse of committing the files: the tree is reconstructed from the manifest rather than stored.
_Avoid_: install (overloaded with the symlink step), copy.
