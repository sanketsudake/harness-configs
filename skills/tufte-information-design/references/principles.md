# Tufte's Principles: Full Reference

Organized by the seven principles in SKILL.md, drawing on *The Visual Display of Quantitative Information* (VDQI, 1983/2001), *Envisioning Information* (1990), *Visual Explanations* (1997), and *Beautiful Evidence* (2006).

## 1. Show the evidence

### The data-ink ratio (VDQI)

```
Data-ink ratio = ink presenting information / total ink in the display
```

Data-ink is the non-erasable core — ink whose removal loses information.
Target a ratio approaching 1.0; every remaining element must earn its place.

### The five data-ink laws

1. Above all else, show the data.
2. Maximize the data-ink ratio, within reason.
3. Erase non-data-ink.
4. Erase redundant data-ink — if bars are labeled, the y-axis may be redundant; if lines are labeled, the legend is.
5. Revise and edit — displays improve by iteration, and each pass should raise the ratio.

### Standard redesign moves

- Range-frame axes: draw the axis only across the range of the data, turning a frame into information about minimum and maximum.
- Direct labels: put names on the data, not in a legend.
- Erase the box: an open frame reads cleaner than a closed one and loses nothing.
- White space as separator: use spacing, not rules or borders, to group.

## 2. Tell the truth about it

### The Lie Factor (VDQI)

```
Lie Factor = size of effect shown in graphic / size of effect in data
```

| Lie Factor | Reading |
|-----------|---------|
| 1.0 | truthful representation |
| 0.95 – 1.05 | acceptable range |
| < 0.95 or > 1.05 | distortion present |
| > 2.0 | serious distortion |

Common causes: area or volume encoding a one-dimensional change (a doubled value drawn as a doubled height *and* width quadruples the visual effect), truncated baselines presented as full bars, inconsistent scales between compared panels, and 3-D perspective.

### The six principles of graphical integrity (VDQI)

1. **Proportional representation.**
   The physical measure on the graphic must be directly proportional to the quantity represented.
   If a shape encodes a value, vary exactly one dimension.
2. **Clear, detailed, thorough labeling.**
   Write explanations on the graphic itself; label important events in the data; state units, sources, and transformations.
3. **Show data variation, not design variation.**
   Keep the design constant across a series so the only thing that changes is the data.
4. **Standardized units for money over time.**
   Use deflated, constant-currency values; note the base year; consider per-capita normalization.
5. **Dimensional matching.**
   The number of information-carrying dimensions must not exceed the dimensions in the data — no 3-D bars for 1-D values, no size *and* color both encoding the same variable.
6. **Context preservation.**
   Do not quote data out of context: show the full relevant range, include baselines and comparisons, note sample sizes, and never cherry-pick the window that flatters the narrative.

## 3. Erase what doesn't inform

### The three species of chartjunk (VDQI)

1. **Moiré vibration** — cross-hatching, fine parallel lines, and tight patterns that shimmer.
   Fix: solid, muted fills.
2. **The grid** — heavy or dense gridlines competing with data.
   Fix: lighten to a whisper, thin the divisions, or delete; if kept, run the grid *behind* the data.
3. **The duck** — decoration that has become the display, named for a duck-shaped building.
   3-D effects, gradient fills, drop shadows, mascots, and "creative" chart types are ducks.
   Fix: let the data drive the form.

Chartjunk is not a style crime but a credibility cost: viewers discount displays that appear to be selling something.

## 4. Layer and separate

From *Envisioning Information*.

### 1 + 1 = 3

Two elements placed together produce a third visual effect — the shape of the space between them.
Every box, border, and rule multiplies this noise.
The cure is almost always to remove the separator and let alignment and white space do the work.

### Muted structure, emphasized content

- Structural elements (grids, axes, boxes, connectors) belong in light gray tints; content belongs in full intensity.
- Color works as a quiet signal: small amounts of intense color on a muted ground; never large fields of saturated color.
- Negative space is an active element — protect it rather than filling it.

### Micro/macro readings

Well-designed dense displays reward two readings: pattern at a distance, detail up close.
Do not destroy the micro level to make the macro level "clean" — that is deleting content, not designing it.

## 5. Enable comparison

"Compared to what?" is the fundamental analytical question (*Envisioning Information*, *Visual Explanations*).

### Small multiples

A series of the same design repeated with different data slices, arranged within one eye span.

Requirements:

- Identical design and identical scales across every panel — variation must mean data variation.
- Clear per-panel labels.
- Logical ordering: time, magnitude, or category — never arbitrary.
- Panels small enough to compare, large enough to read.

### Parallelism

Comparable things must be presented in parallel form — same units, same order, same phrasing — in layout and in prose alike.
Breaking parallelism forces the viewer to normalize in their head, which is design work pushed onto the audience.

## 6. Integrate evidence with narrative

From *Visual Explanations* and *Beautiful Evidence*.

### Words, numbers, images together

Evidence belongs in the flow of the argument, not in an appendix of exhibits.

- Label data directly on the graphic; annotate the interesting points ("strike begins here").
- Avoid the "see figure 3" round trip; place the exhibit at the point of the claim.
- Every exhibit should stand alone: title states the finding, source is cited, units are on the display.

### Sparklines (Beautiful Evidence)

Word-sized, data-intense graphics embedded in text or tables.

- Show shape and trend, not precise values; no axes, legends, or labels beyond an anchoring number.
- Use for context at the point of reading: `latency 34 ms ▁▂▂▃▂▆▂` beats a chart three paragraphs away.

### Show causality, not just numbers (Visual Explanations)

The Challenger and John Snow cases teach the same move: order the evidence by the causal variable.

- Snow's cholera map put deaths where the pump was — the spatial ordering *was* the argument.
- The Challenger engineers had the O-ring data but ordered it by flight number instead of temperature; ordered by temperature, the risk is unmistakable.
- When arguing cause, put the suspected cause on the ordering axis and show the full range of cases, not just the failures.

### Documentation is credibility

Cite sources on the display, note who made it and when, and show the assumptions.
Undocumented evidence reads as advertising.

## 7. Respect the audience

From *Beautiful Evidence* and "The Cognitive Style of PowerPoint".

### The cognitive-style critique

Tufte's charge against slideware defaults: low resolution per view, fragmented hierarchies of grammarless bullets, forced sequentiality, and a foregrounding of format over content.
The failure is not the medium but the default style — it presents *at* people instead of reasoning *with* them.

### Constructive alternatives

- To clarify, add detail: the fix for a confusing display is usually higher content resolution, not less content.
- Replace fragment bullets with sentences; a sentence forces the author to state the relationship a bullet hides.
- For deep material, hand out a high-resolution document and use the meeting to discuss it, rather than paging through low-resolution slides.
- Show the complexity well: audiences reading dense, well-layered displays (timetables, weather maps, financial pages) do so daily without training.

### The sentence test

If a display's title is a topic ("Q3 Revenue") rather than a finding ("Q3 revenue recovered to the pre-launch trend"), the author has not yet decided what the evidence says — and the viewer is left to guess.
