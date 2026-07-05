# Applying the Principles by Medium

Each section: what the principles mean in this medium, the top moves, the common failure pattern, and where construction mechanics live.

## Slides & decks

A slide is a low-resolution display with a captive audience — the medium most punished by clutter and most tempted by decoration.

**Top moves:**

1. One claim per slide; if a slide carries two independent claims, split it.
2. Make the title the finding, not the topic — "Churn is concentrated in month one", not "Churn analysis".
3. Direct-label everything; a legend on a slide costs the audience the speaker's next two sentences.
4. Kill the template: default backgrounds, logos on every slide, and decorative dividers are all non-data-ink.
5. For deep or data-heavy material, present a one-page high-resolution handout and discuss it, instead of serializing it across ten low-resolution slides.

**Bullet points:** fragments hide the relationships between ideas.
Prefer a full sentence (states a claim), a small table (states a comparison), or a diagram (states a structure).
If bullets remain, keep them flat — nested bullets are an outline pretending to be an argument.

**Failure pattern:** the "agenda deck" — every slide a topic title plus 5 nested bullets, the finding nowhere.

**Mechanics:** file operations, layouts, and speaker notes belong to the `pptx` skill.

## Documents & blog posts

Prose is the highest-resolution medium available — use that resolution instead of fragmenting into slide-style lists.

**Top moves:**

1. Front-load the claim; the first paragraph should survive being the only paragraph read.
2. Integrate exhibits at the point of the claim — no "see figure 3" round trips; the figure sits next to the sentence it supports.
3. Give numbers context inline: "p95 latency fell 38% (210 ms → 130 ms)" beats a chart for a single comparison; use a sparkline-style inline exhibit for a trend.
4. Every figure stands alone: caption states the finding, axes carry units, source is cited.
5. Use headings as layered structure (macro reading) — a reader skimming only headings should get the argument's skeleton.

**Tables vs prose:** three or more numbers being compared belong in a table, not a sentence.

**Failure pattern:** the "chart dump" — figures exported from a tool with default styling, no annotation, captioned by topic, stranded between unrelated paragraphs.

**Mechanics:** Hugo publishing belongs to `write-hugo-blog-post`; Word deliverables to `docx`.

## Dashboards & HTML artifacts

Density is a feature here — a dashboard exists to support micro/macro reading — but only if layering carries it.

**Top moves:**

1. Mute the chrome: panel borders, card shadows, and headers in light gray; full intensity reserved for data and alerts.
2. Shared scales across comparable panels; small multiples for the same metric across segments.
3. Every stat tile answers "compared to what?" — pair the number with its prior period, target, or trend sparkline.
4. Color signals state, sparingly: one intense accent on a muted ground; a dashboard that is all red and green says nothing.
5. Reveal detail on demand (tooltips, drill-downs) rather than deleting it — protect the micro level.

**Failure pattern:** the "wall of equal tiles" — twenty identically-loud KPI cards with no hierarchy, no comparisons, and no way to see what changed.

**Mechanics:** chart marks, palettes, and accessibility belong to a dedicated dataviz skill when one is available; overall page aesthetics to `frontend-design`.

## Tables

Tufte's most rehabilitated form: for lookup and for precise values, a table beats a chart.

**Top moves:**

1. Minimal rules — light horizontal rules only (header and footer; group separators if long); never vertical rules or full grids.
2. Right-align numbers on the decimal, left-align text; never center data.
3. Units and scale in the header ("Revenue, $M"), not repeated in every cell.
4. Order rows by meaning — magnitude, time, or grouping — not alphabetically by default.
5. No zebra striping unless rows are long enough to need tracking; white space groups better than fills.

**Failure pattern:** the "spreadsheet screenshot" — full grid, centered everything, units in cells, alphabetical order.

**Mechanics:** spreadsheet file operations belong to `xlsx`.

## Diagrams

A diagram is an argument about structure; every visual choice should encode a real relationship.

**Top moves:**

1. Layout direction follows the logic: time and process flow left→right or top→bottom, consistently.
2. Label the edges, not just the nodes — the relationships are usually the point.
3. Mute the boxes, emphasize the flow: light borders, meaningful arrow weight.
4. One relationship type per diagram; a graph mixing data-flow, ownership, and sequence arrows is three diagrams in a trench coat.
5. Cut decorative icons unless they disambiguate node types.

**Failure pattern:** the "everything map" — every component and every kind of edge in one diagram, readable only by its author.

**Mechanics:** mermaid syntax, sizing, and color palette belong to `author-mermaid-diagram`.

## Email & short-form

The scarcest attention budget of any medium; assume the first line is all that gets read.

**Top moves:**

1. The claim or ask in the first sentence; context after, never before.
2. At most one exhibit, inline, cropped to the relevant range.
3. Three or more numbers → a small table; prose lists of figures are unreadable on phones.
4. Direct answers over hedged narration: "Deploy is blocked by the failing migration (details below)".
5. Strip forwarding chains, banners, and signature noise from anything quoted.

**Failure pattern:** the "scroll-to-find-the-ask" — three paragraphs of background before the one sentence that needed sending.
