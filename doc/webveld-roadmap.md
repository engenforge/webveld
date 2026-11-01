# WebVeld Roadmap

**Companion to:** [webveld-spec.md](webveld-spec.md) · **Status:** Informative

Candidates for future versions of WebVeld, organized by *readiness*: what could be added, and what has to happen first. Scores draw on [webveld-corpus-study.md](research/webveld-corpus-study.md), a survey of what about a hundred minimalist sites actually use. Nothing here is a commitment; the specification is the only authority on conformance.

What is currently out, and why, is in [webveld-motivation.md](webveld-motivation.md) §7; rejected designs are in §6 of the same document. No exclusion is permanent: a capability is out only until a design for it satisfies the cardinal rules.

## Feature freeze

**WebVeld is feature-frozen: no candidate below is added until an implementation exists that can measure its cost.** "Gated" means excluded until that measurement happens.

The reason is rule 2. Parity (rule 1) can be tested against Chromium, Firefox, and Safari in an afternoon, and privacy and safety (rule 3) is desk work. But implementation cost can only be measured by implementing, and a requirement nobody has tried to implement tends to be ambiguous.

"An implementation" means something built to attempt the specific feature and report its cost. The existing validator (`tools/validator/`) doesn't count by itself: it checks documents against lists, which is different from pricing an algorithm. Each candidate says what kind of implementation it needs:

- **Validator-shaped** — a tool that parses and evaluates the construct, with no rendering. CSS custom properties and SVG parser safety are this kind.
- **Layout-engine-shaped** — only an engine that lays out boxes can price it, because the cost *is* the layout. Floats and `auto-fill`/`auto-fit` grids are this kind.

The freeze lifts per candidate as the matching kind of implementation becomes available.

### What the freeze does not govern

The freeze governs **candidates**: new capabilities, each with an entry below. It does not govern **completions**: fixing defects, settling ambiguous grammar, or filling a hole another rule created. Holding those back would mean shipping 1.0 with known defects.

A change is a completion only if all four of these hold; otherwise it is a candidate:

1. **It closes a gap in the specification**: a missing shorthand, an implied value, an unstated grammar, a contradiction, or a capability another exclusion removed without replacement.
2. **It clears the three cardinal rules on paper**, with no measurement needed.
3. **It adds no new algorithm** beyond what browsers already must implement.
4. **It is additive** (spec §2.7): nothing conforming stops conforming.

## Admission

A candidate must clear the three cardinal rules of spec §3.1, plus one procedural bar. These are gates, not scores: failing any one removes the candidate.

1. **Parity** (rule 1) — it renders natively in current Chromium, Firefox, and Safari with no script or polyfill.
2. **Implementability** (rule 2) — it keeps a complete browser within the rough budget of spec §3.1.
3. **Privacy and safety** (rule 3) — it introduces no fingerprinting signal, no third-party request, no persistent client state, and no new parser for untrusted binary input.
4. **Additive** (spec §2.7) — it can land as a MINOR release, leaving every existing conforming document and browser conforming.

A candidate that fails as proposed may pass as a bounded subset, as long as the subset restricts syntax without redefining behavior (spec §3.1).

## 1.0.0 exit criteria

To keep draft versions from drifting indefinitely, **1.0.0** requires:

1. **Implementer proof:** at least one conforming browser (new, or a hardened existing engine) that meets every browser requirement of spec §2.4, passes the whole render conformance suite, and enforces spec §8. Its rendering of conforming documents must be visually identical to Chromium and Firefox in the sense of spec §3.1: a reader would struggle to tell them apart.
2. **Author proof:** at least **two published multi-page websites with real content**, by people other than the specification authors, that declare WebVeld conformance and validate against it as part of publishing. Pages that happen to conform by accident don't count.
3. **Stability commitment:** 1.0.0 ends the draft period. Conforming 1.0 documents stay conforming in every 1.x release, and nothing permitted may be removed or restricted without a 2.0.0 release.

## Gated on a first implementation

- **CSS custom properties** (3.95) — *validator-shaped.* The strongest candidate: used on about 60% of size-budget sites in the corpus study. Parity is free and rule 3 is untouched, since nothing can read them back without script. The cost is inheritance, `var()` substitution with fallbacks, and cycle detection. The tricky part is "invalid at computed-value time": `width: var(--w)` can't be checked against the allowlist until after substitution, so validation moves later in the pipeline. A validator that can do that is enough to price it. Substitution must follow CSS exactly, not a simplified version (spec §3.1).
- **Minimal SVG subset** (3.35) — *validator-shaped* for the risk that gates it. The largest gap authors feel: no crisp logos or icons, and inline `<svg>` appears on about a third of size-budget sites. The grammar to start from is **SVG Tiny Portable/Secure** (the profile BIMI uses for email logos), which already forbids scripts, external references, animation, and foreign objects, and has existing validation tools. Drop its BIMI-specific size limit and `baseProfile` token so files stay ordinary SVG. It is effectively a second rendering model, so it is expensive.

  Six questions must be settled, in order:

  1. **Position.** `img` only, or inline too? An SVG loaded through `img` is isolated (mainstream browsers already block its scripts and fetches) and fits spec §7.2 unchanged; inline `<svg>` joins the document and has a different threat model. `img` only is the likely answer, and `data:image/svg+xml` needs a decision at the same time (spec §7.1 allows only PNG and JPEG `data:` URLs).
  2. **Gradients.** SVG Tiny P/S allows them, but spec §6.7 forbids CSS gradients, and an SVG used as a `background-image` would reintroduce them. Either the SVG subset drops gradients or §6.7's exclusion is reconsidered on its own merits.
  3. **Text.** Exclude `text` and require paths. Text in SVG renders differently depending on installed fonts and needs a second text layout engine. The cost: diagrams lose selectable, accessible labels.
  4. **XML.** Make dangerous constructs impossible rather than checked: no `<!DOCTYPE>` (so no entity expansion), only the five predefined entities and numeric references, no processing instructions or CDATA, and only the SVG namespace on the root. Then the parser is a small recognizer for a fixed grammar rather than a general XML parser.
  5. **Renderer coverage.** The validated grammar must be a subset of what the chosen renderer actually implements, checked rather than assumed.
  6. **Divergence.** Identify where two renderers may quietly disagree (`fill-rule`, miter limits, gradient interpolation, thin-stroke antialiasing) and exclude or accept each explicitly. `tools/render-diff/` can test this. The spec excluded flexbox baseline alignment on exactly this ground (spec §6.2), so SVG needs the same treatment.
- **Floats for figures** (3.20) — *layout-engine-shaped.* `float: left|right` with `clear`, limited to images and figures in flowing text. It does something flexbox can't: wrap text around an image. The cost is easy to underestimate: floats shorten every line box they intrude on and interact with margin collapsing. The corpus study found floats on about a third of size-budget sites, but most of those also use flexbox, and only a small share of float rules are clearly for figures.

## Gated on evidence

- **Inline `style` attributes** (3.55). No cardinal rule bars them and they are trivial to implement. They are held because a `style` attribute is the hardest declaration for a reader's style sheet to override (spec §6.1), and because allowing them later is MINOR while forbidding them later would be MAJOR. What would change this is evidence from authors that the generated style sheet pattern (spec Appendix A.4) is real friction.

## Unlikely

- **`auto-fill` and `auto-fit` in `repeat()`** — *layout-engine-shaped.* The natural next step for the grid subset, covering most remaining grid use in the corpus and giving responsive grids without media queries. Held because resolving the repeat count needs another sizing pass. Revisit once an implementation reports the cost.
- **`srcset` and `sizes`** (2.75). Saves bandwidth, but which image the browser requests reveals the viewport size and pixel density to the server. Few size-budget sites use it.
- **WebP** (2.70). Browsers may already decode WebP as an option (spec §7.4), as Dillo does behind a build flag. The candidate is letting *documents* use it, which would force every browser to carry the decoder: new hostile-input parsing inside the browser, which rule 3 exists to prevent. libwebp's CVE-2023-4863 was exploited in the wild across every major browser in 2023.
- **Decentralized certificate verification** (2.25). Self-signed certificates are already allowed (spec §8); what's missing is a way to trust one without a central authority. Research, not a feature request.
- **Audio element with a single codec** (1.95). Reopens in-browser media decoding for something external handlers already cover (spec §10).

## Closed

- **`loading="lazy"`** — rejected. In a browser with no scripts, storage, or beacons, lazy loading would be the main remaining way for a server to observe reading: request timing reveals how far the reader scrolled.
- **WebAssembly and the WASM sandbox, embedded media windows, DOM-swapping attributes, custom accessibility bindings, and a JavaScript polyfill** — rejected for the reasons in [webveld-motivation.md](webveld-motivation.md) §6. A materially different design would be judged on its own merits.

## Scoring

Candidates that pass admission are ranked on four axes, scored 1 to 5 and weighted:

| Axis | Weight | 5 means |
| --- | --- | --- |
| Reader value | 0.25 | readers notice its absence on ordinary pages |
| Author value | 0.20 | authors hit the gap constantly |
| Ease of implementation | 0.30 | a few hundred lines on top of existing machinery |
| Privacy and safety | 0.25 | no new surface of any kind |

Ease and privacy together outweigh demand on purpose: the cardinal rules decide what is admissible, and cost and safety keep deciding after that. The weights are a statement of values, published so that disagreements are about the right thing.

| Candidate | Reader | Author | Ease | Privacy | Score |
| --- | --- | --- | --- | --- | --- |
| CSS custom properties | 2 | 5 | 4 | 5 | **3.95** |
| Inline `style` attributes | 1 | 4 | 5 | 4 | **3.55** |
| Minimal SVG subset | 4 | 5 | 2 | 3 | **3.35** |
| Floats for figures | 3 | 3 | 2 | 5 | **3.20** |
| `srcset` / `sizes` | 3 | 3 | 3 | 2 | **2.75** |
| WebP | 4 | 3 | 2 | 2 | **2.70** |
| Decentralized certificate verification | 2 | 1 | 1 | 5 | **2.25** |
| Audio element with a single codec | 3 | 2 | 1 | 2 | **1.95** |

One finding sits outside the table: the corpus study found `position: absolute|fixed|sticky` on about two thirds of size-budget sites (more than use flexbox), and transitions and transforms on more than half. WebVeld forbids all of them, and neither is likely to become a candidate, since positioning brings stacking contexts and animation brings a compositor. They are the largest measured gap between WebVeld and what minimal sites actually do.
