#!/usr/bin/env bash
#
# skills-manager.sh — fetch, list, update, and delete vendored skills.
#
# Each managed skill carries a sidecar at skills/<name>/.source.json recording
# where it came from, so it can be updated when the upstream changes.
#
# Sidecar shapes:
#   remote: {"repo","subpath","ref","commit","fetched_at"}
#   local:  {"repo": null, "note": "..."}
# A skill dir with no .source.json is "unmanaged".
#
# Usage:
#   skills-manager.sh fetch  (--url URL | --repo REPO --subpath SUBPATH) [--ref REF] [--name NAME] [--force]
#   skills-manager.sh list
#   skills-manager.sh update (--name NAME | --all)
#   skills-manager.sh delete --name NAME [--yes]
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

err()  { printf 'error: %s\n' "$*" >&2; }
die()  { err "$*"; exit 1; }
info() { printf '%s\n' "$*" >&2; }

command -v git >/dev/null || die "git is required"
command -v jq  >/dev/null || die "jq is required"

# Temp dirs are tracked globally and cleaned once on exit. A per-function
# RETURN trap would be wrong here: bash traps are global, so it would re-fire
# for callers after the local $tmp went out of scope.
TMPDIRS=()
cleanup_tmpdirs() { local d; for d in "${TMPDIRS[@]:-}"; do [[ -n "$d" ]] && rm -rf "$d"; done; return 0; }
trap cleanup_tmpdirs EXIT
# Create a tracked temp dir, returning its path in $MKTMP_DIR. The path is
# returned via a global rather than command substitution so the registry
# append runs in this shell, not a subshell (where it would be lost).
mktmp() { MKTMP_DIR="$(mktemp -d)"; TMPDIRS+=("$MKTMP_DIR"); }

# --- helpers ---------------------------------------------------------------

# Normalize a repo reference into a clone URL.
#   owner/name            -> https://github.com/owner/name
#   https://..., git@...  -> passed through unchanged
normalize_repo() {
  local repo="$1"
  if [[ "$repo" == *"://"* || "$repo" == git@* ]]; then
    printf '%s' "$repo"
  elif [[ "$repo" =~ ^[^/[:space:]]+/[^/[:space:]]+$ ]]; then
    printf 'https://github.com/%s' "$repo"
  else
    die "cannot interpret repo '$repo' (expected owner/name or a clone URL)"
  fi
}

# Parse a GitHub tree/blob URL into repo|ref|subpath, tab-separated.
#   https://github.com/owner/name/tree/<ref>/<subpath...>
parse_github_url() {
  local url="$1"
  local re='^https?://github\.com/([^/]+)/([^/]+)/(tree|blob)/([^/]+)/(.+)$'
  [[ "$url" =~ $re ]] || die "not a github tree/blob URL: $url"
  printf 'https://github.com/%s/%s\t%s\t%s' \
    "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}"
}

# Shallow sparse-clone <repo> at <ref> (empty ref = default branch) into <dest>.
sparse_clone() {
  local repo="$1" ref="$2" subpath="$3" dest="$4"
  local args=(--depth=1 --filter=blob:none --sparse)
  [[ -n "$ref" ]] && args+=(--branch "$ref")
  git clone "${args[@]}" "$repo" "$dest" >/dev/null 2>&1 \
    || die "clone failed: $repo${ref:+ (ref $ref)}"
  git -C "$dest" sparse-checkout set "$subpath" >/dev/null 2>&1 \
    || die "sparse-checkout failed for subpath: $subpath"
}

# Write a remote sidecar to skills/<name>/.source.json.
write_sidecar() {
  local name="$1" repo="$2" subpath="$3" ref="$4" commit="$5"
  local fetched_at; fetched_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  jq -n \
    --arg repo "$repo" --arg subpath "$subpath" --arg ref "$ref" \
    --arg commit "$commit" --arg fetched_at "$fetched_at" \
    '{repo:$repo, subpath:$subpath, ref:$ref, commit:$commit, fetched_at:$fetched_at}' \
    > "$SKILLS_DIR/$name/.source.json"
}

# --- subcommands -----------------------------------------------------------

cmd_fetch() {
  local url="" repo="" subpath="" ref="" name="" force=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --url)     url="$2"; shift 2 ;;
      --repo)    repo="$2"; shift 2 ;;
      --subpath) subpath="$2"; shift 2 ;;
      --ref)     ref="$2"; shift 2 ;;
      --name)    name="$2"; shift 2 ;;
      --force)   force=1; shift ;;
      *) die "fetch: unknown argument '$1'" ;;
    esac
  done

  # A URL supplies defaults; explicit flags override.
  if [[ -n "$url" ]]; then
    local parsed; parsed="$(parse_github_url "$url")"
    IFS=$'\t' read -r u_repo u_ref u_subpath <<<"$parsed"
    [[ -z "$repo"    ]] && repo="$u_repo"
    [[ -z "$ref"     ]] && ref="$u_ref"
    [[ -z "$subpath" ]] && subpath="$u_subpath"
  fi

  [[ -n "$repo"    ]] || die "fetch: --repo or --url is required"
  [[ -n "$subpath" ]] || die "fetch: --subpath or --url is required"
  subpath="${subpath%/}"
  [[ -n "$name" ]] || name="$(basename "$subpath")"

  local dest="$SKILLS_DIR/$name"
  if [[ -e "$dest" && "$force" -ne 1 ]]; then
    die "skills/$name already exists (use FORCE=1 to overwrite, or skills-update to refresh)"
  fi

  repo="$(normalize_repo "$repo")"
  local tmp; mktmp; tmp="$MKTMP_DIR"

  info "fetching $name from $repo${ref:+ @ $ref} ($subpath)"
  sparse_clone "$repo" "$ref" "$subpath" "$tmp/repo"

  local commit; commit="$(git -C "$tmp/repo" rev-parse HEAD)"
  [[ -n "$ref" ]] || ref="$(git -C "$tmp/repo" rev-parse --abbrev-ref HEAD)"
  [[ -f "$tmp/repo/$subpath/SKILL.md" ]] \
    || die "no SKILL.md at $subpath in $repo — not a skill"

  rm -rf "$dest"
  cp -R "$tmp/repo/$subpath" "$dest"
  write_sidecar "$name" "$repo" "$subpath" "$ref" "$commit"
  info "fetched skills/$name @ ${commit:0:7}"
}

cmd_list() {
  local rows=$'NAME\tSTATUS\tREPO\tSUBPATH\tREF\tCOMMIT\tFETCHED_AT'
  local dir name sidecar repo status subpath ref commit fetched
  for dir in "$SKILLS_DIR"/*/; do
    [[ -d "$dir" ]] || continue
    name="$(basename "$dir")"
    sidecar="$dir.source.json"
    if [[ ! -f "$sidecar" ]]; then
      rows+=$'\n'"$name"$'\tunmanaged\t-\t-\t-\t-\t-'
      continue
    fi
    repo="$(jq -r '.repo // empty' "$sidecar")"
    if [[ -z "$repo" ]]; then
      rows+=$'\n'"$name"$'\tlocal\t-\t-\t-\t-\t-'
      continue
    fi
    subpath="$(jq -r '.subpath // "-"' "$sidecar")"
    ref="$(jq -r '.ref // "-"' "$sidecar")"
    commit="$(jq -r '.commit // "-"' "$sidecar")"
    fetched="$(jq -r '.fetched_at // "-"' "$sidecar")"
    rows+=$'\n'"$name"$'\tremote\t'"$repo"$'\t'"$subpath"$'\t'"$ref"$'\t'"${commit:0:7}"$'\t'"$fetched"
  done
  printf '%s\n' "$rows" | column -t -s $'\t'
}

# Re-fetch one remote skill in place. Returns 0 always; reports via stderr.
update_one() {
  local name="$1"
  local dir="$SKILLS_DIR/$name" sidecar="$SKILLS_DIR/$name/.source.json"
  [[ -d "$dir" ]] || { err "$name: no such skill"; return 1; }
  if [[ ! -f "$sidecar" ]]; then
    info "$name: unmanaged (no .source.json), skipping"
    return 0
  fi
  local repo; repo="$(jq -r '.repo // empty' "$sidecar")"
  if [[ -z "$repo" ]]; then
    info "$name: local skill, nothing to update"
    return 0
  fi
  local subpath ref old_commit
  subpath="$(jq -r '.subpath' "$sidecar")"
  ref="$(jq -r '.ref' "$sidecar")"
  old_commit="$(jq -r '.commit' "$sidecar")"

  local tmp; mktmp; tmp="$MKTMP_DIR"
  sparse_clone "$repo" "$ref" "$subpath" "$tmp/repo"
  local new_commit; new_commit="$(git -C "$tmp/repo" rev-parse HEAD)"

  if [[ "$new_commit" == "$old_commit" ]]; then
    info "$name: up to date (${old_commit:0:7})"
    return 0
  fi
  [[ -f "$tmp/repo/$subpath/SKILL.md" ]] \
    || { err "$name: subpath $subpath no longer has a SKILL.md upstream, skipping"; return 1; }

  rm -rf "$dir"
  cp -R "$tmp/repo/$subpath" "$dir"
  write_sidecar "$name" "$repo" "$subpath" "$ref" "$new_commit"
  info "$name: updated ${old_commit:0:7} -> ${new_commit:0:7}"
}

cmd_update() {
  local name="" all=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name) name="$2"; shift 2 ;;
      --all)  all=1; shift ;;
      *) die "update: unknown argument '$1'" ;;
    esac
  done

  if [[ "$all" -eq 1 ]]; then
    local dir n
    for dir in "$SKILLS_DIR"/*/; do
      [[ -f "$dir.source.json" ]] || continue
      [[ "$(jq -r '.repo // empty' "$dir.source.json")" ]] || continue
      n="$(basename "$dir")"
      update_one "$n" || true
    done
    return 0
  fi

  [[ -n "$name" ]] || die "update: --name NAME or --all is required"
  update_one "$name"
}

cmd_delete() {
  local name="" yes=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name) name="$2"; shift 2 ;;
      --yes)  yes=1; shift ;;
      *) die "delete: unknown argument '$1'" ;;
    esac
  done
  [[ -n "$name" ]] || die "delete: --name NAME is required"
  local dir="$SKILLS_DIR/$name"
  [[ -d "$dir" ]] || die "skills/$name does not exist"

  if [[ "$yes" -ne 1 ]]; then
    local reply
    printf 'Delete skills/%s? [y/N] ' "$name" >&2
    read -r reply </dev/tty || reply=""
    [[ "$reply" == "y" || "$reply" == "Y" ]] || { info "aborted"; return 0; }
  fi
  rm -rf "$dir"
  info "deleted skills/$name"
}

# --- dispatch --------------------------------------------------------------

[[ $# -ge 1 ]] || die "usage: skills-manager.sh {fetch|list|update|delete} ..."
cmd="$1"; shift
case "$cmd" in
  fetch)  cmd_fetch  "$@" ;;
  list)   cmd_list   "$@" ;;
  update) cmd_update "$@" ;;
  delete) cmd_delete "$@" ;;
  *) die "unknown command '$cmd' (expected fetch|list|update|delete)" ;;
esac
