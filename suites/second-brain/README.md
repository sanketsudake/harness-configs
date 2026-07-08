# Second Brain

> An Obsidian knowledge base your agent maintains for you.

(Full narrative lands after the generator exists.)

<!-- suite-skills:begin -->
## Skills in this suite

| Skill | Purpose |
|-------|---------|
| [`second-brain`](../../skills/second-brain/SKILL.md) | Set up a new Obsidian knowledge base with the LLM Wiki pattern. |
| [`readwise-second-brain-sync`](../../skills/readwise-second-brain-sync/SKILL.md) | Sync Readwise highlights and Reader documents into the second-brain vault's raw/ folder in Obsidian-Web-Clipper format. |
| [`second-brain-ingest`](../../skills/second-brain-ingest/SKILL.md) | Process raw source documents into wiki pages. |
| [`second-brain-query`](../../skills/second-brain-query/SKILL.md) | Answer questions against the knowledge base wiki. |
| [`second-brain-review`](../../skills/second-brain-review/SKILL.md) | Resurface knowledge from the second-brain wiki — a daily/periodic review of highlights, concepts, and stale pages, replacing Readwise's daily review. |
| [`second-brain-ideate`](../../skills/second-brain-ideate/SKILL.md) | Mine the knowledge-base wiki for strong, defensible content ideas — blog posts, conference talks, internal sessions, threads. |
| [`second-brain-lint`](../../skills/second-brain-lint/SKILL.md) | Health-check the wiki for contradictions, orphan pages, stale claims, and missing cross-references. |

## Install

With the [skills.sh](https://www.skills.sh/) CLI (needs Node.js):

```bash
npx skills add sanketsudake/harness-configs \
  --skill second-brain \
  --skill readwise-second-brain-sync \
  --skill second-brain-ingest \
  --skill second-brain-query \
  --skill second-brain-review \
  --skill second-brain-ideate \
  --skill second-brain-lint \
  -y
```
<!-- suite-skills:end -->
