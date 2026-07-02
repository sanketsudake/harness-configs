# Git hygiene

- Never `git add -A` or `git add .` — stage explicit paths so unrelated or generated files never ride along.
- Before any commit, verify no secrets, tokens, or `.env` files are staged (`git diff --cached --name-only` plus a look at anything suspicious).
- No `Claude-Session:` or similar tracking trailers in commit messages.
- Push the branch and let the user open the PR themselves, unless the project's CLAUDE.md or memory explicitly allows creating PRs.
- Never force-push or rewrite published history unless explicitly asked.
- Keep commits small and scoped; one logical change per commit so any regression is attributable and revertable.
