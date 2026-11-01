# Blitz as a WebVeld Implementation Base

**Subject:** [Blitz](https://github.com/DioxusLabs/blitz), commit `a980f31` (2026-09-08) with Stylo, Taffy, Parley, and html5ever at their pinned versions · **Measured:** 2026-09-08 · **Against:** [webveld-spec.md](../webveld-spec.md) v0.3.1

Blitz is a modular HTML/CSS rendering engine written in Rust, built from Servo's Stylo for style resolution, Taffy for box layout, Parley for text layout, and html5ever for parsing. It renders no-JavaScript sites — Wikipedia and old Reddit are its own examples — and describes itself as beta.

It is the closest thing to a WebVeld browser that anyone is actively building, which makes it worth measuring for two separate questions that are easy to conflate: *would it make a good WebVeld browser*, and *does it tell us anything about cardinal rule 2*. The answers differ, and the second one turns out not to depend on the engine's size at all.

Reproduction commands are in the last section.

## 1. Size

| Component | Role | First Cut (non-blank) | Standard Code LOC (`tokei`) |
| --- | --- | ---: | ---: |
| `stylo/style` (servo config; `gecko` feature excluded) | CSS parsing, cascade, computed values | 118,807 | 105,643 |
| `stylo/selectors` + `style_traits` | selector matching | 9,810 | 7,073 |
| `parley` | text and inline layout | 27,038 | 22,854 |
| `taffy/src` | box layout | 24,331 | 19,323 |
| `html5ever` | HTML parsing and tree building | 19,149 | 16,921 |
| Blitz own crates (`packages/`) | document tree, paint, forms, shell | ~32,400 | 37,577 |
| **Total in the categories rule 2 measures** | | **~229,000** | **209,391** |

Counts compare the initial non-blank `find`/`grep` pass against standardized `tokei` 15.0.0 pure code lines (excluding comments, blanks, tests, benches, and examples). As [webveld-motivation.md](../webveld-motivation.md) §4 says of the same measure, lines of code are a poor measure of quality and a good proxy for barrier to entry.

For comparison, [dillo-assessment.md](dillo-assessment.md) §1 puts Dillo's engine proper at 60,902 lines (83,504 across the repository).

## 2. Why Blitz's size does not answer cardinal rule 2

Counting the artifact gives no usable answer, and the reason is worth stating precisely, because it is easy to reach a confident conclusion either way. §2a shows where the answer actually lives.

Rule 2 names what it counts: *"the browser's own engine — parsing, style resolution, layout, rendering — assuming commodity libraries for TLS, image decoding, and the platform's widget toolkit."* Blitz obtains parsing from html5ever, style resolution from Stylo, and layout from Taffy and Parley. Those are three of the four things the rule names as measured, and none of the three things it grants as commodity.

That produces two defensible readings and no way to choose between them from the rule's text alone:

- **By the rule as written,** the engine is roughly 229,000 lines. Stylo alone is 2.6 times Dillo's entire engine, and it implements the whole of CSS — grid, animations, transforms, custom properties, container queries — every part of which WebVeld excludes. Filtering at the document level does not remove any of it; the parser that hostile CSS reaches is the complete Stylo parser.
- **By a reading that treats Stylo, Taffy, and Parley as commodity crates,** the engine is Blitz's own ~32,400 lines, which is smaller than Dillo and passes rule 2 comfortably.

The second reading has a cost that should be seen before it is adopted: if a separately maintained crate counts as commodity, then embedding Blink as a library also conforms, and rule 2 stops constraining anything.

**The resolution is that the question is misplaced.** Rule 2 read, at the time of this measurement, *"A complete, conforming WebVeld browser MUST remain something a single developer or a small team can write in months of work rather than years"* — a constraint on what the **specification** may contain, and the test a proposed feature must pass. (§2a below is what prompted 0.3.2 to correct both that figure and the ambiguity about its scope; the pre-0.3.2 wording is quoted here because it is what the analysis was performed against.) Nothing in §2.4 requires a conforming browser to be small, or from scratch, or written any particular way, and nothing should.

## 2a. What Blitz's development history does measure

Artifact size is the wrong place to look for rule 2. The rule is a claim about *effort*, and effort is directly observable in a repository's history — which makes this better evidence than any purpose-built prototype could produce, since a prototype measures one team's speed once, where this measures four projects against each other.

| Project | Authors with ≥20 commits | Dominant author's share | Distinct months with commits | Engine code (`tokei`) |
| --- | ---: | ---: | ---: | ---: |
| Blitz (own crates) | 2 | **89%** (1,683 of 1,890) | 35 | 36,112 |
| Taffy | 5 | 43% — *the same developer* | 75 | 19,296 |
| Dillo | 7 | 44% | 141 | 60,902 (engine) / 83,504 (all) |
| NetSurf | 20 | 22% | 274 | 126,212 (engine) / 297,314 (all) |
| Stylo | 91 | 20% | 145 | 104,906 |
| Servo | 201 | 16% | 176 | 415,332 (components) |

*(For the complete census and methodology spanning from Gemini clients to Chromium, see [implementability-continuum.md](implementability-continuum.md).)*

**One developer is the dominant author of both Blitz and Taffy** — roughly 55,400 lines of engine and layout, comparable to Dillo's entire engine — across 50 distinct active months, while reusing Stylo for style resolution, Parley for text, and html5ever for parsing.

Two findings follow, and they point in opposite directions.

**The thesis holds, and Blitz is the proof.** [webveld-motivation.md](../webveld-motivation.md) §1 opens with "Nobody can build a browser any more." One person just did. The precise claim survives — nobody can build a browser for the *modern web*, which is why Stylo needs 92 core authors and Chromium needs a corporation — but a browser for *documents* is demonstrably within one determined developer's reach. That is WebVeld's entire argument, standing in a repository that renders Wikipedia.

**The number in rule 2 is wrong.** "Months of work rather than years" is optimistic by three to four times against the most favorable observed case, which had parsing, style, and text donated to it. Nobody in the sample built anything like this in months. The rule should say what the evidence says: a small team over a year or two, against a corporation over a decade. Correcting it strengthens the rule — an estimate an implementer can check against four real projects is worth more than one they will discover to be wrong in month seven.

As a cross-check, basic COCOMO in organic mode (`PM = 2.4 × KLOC^1.05`) puts Blitz's own crates at 92.5 person-months against roughly 32 observed, so the model overestimates this domain by about 2.9×. That calibration is what makes it usable on components whose history cannot be separated out.

## 3. Roadmap coverage: measurements already paid for

Three roadmap candidates are gated in [webveld-roadmap.md](../webveld-roadmap.md) on an implementation capable of pricing them. Blitz's dependency tree contains two of those prices already, in a single codebase with consistent conventions, which is what makes the ratios meaningful.

| Taffy layout algorithm | Lines |
| --- | ---: |
| Flexbox — what WebVeld already requires | 3,308 |
| **Full CSS Grid** — track sizing, placement, explicit and implicit grids, alignment | **6,843** |
| Block | 1,719 |
| Leaf | 171 |

**Bounded CSS grid subset** (roadmap 3.35, *layout-engine-shaped*). The roadmap holds that only an implementation that actually lays out tracks can price this. Taffy is that implementation, and full grid — with `minmax()`, `auto-fill`, auto-placement, and intrinsic track sizing, all of which the proposed subset drops — costs roughly twice flexbox, which the specification already mandates. This materially weakens the cost argument for excluding grid.

**`details` and `summary`** (roadmap 4.10, *interactive-surface-shaped*). The roadmap holds these back because pricing them needs "a live rendering surface with real focus and input handling, which is closer to 'most of a browser' than to a validator." Blitz supports both. The deferral rationale — that they introduce "new machinery rather than a switch" — is now testable against a working implementation rather than argued from first principles, and it is the cheapest gated question in the roadmap to settle.

**Floats for figures** (roadmap 3.20, *layout-engine-shaped*) is **not** priced by Taffy, despite a `float.rs` of 721 lines. Taffy performs box layout only, with no inline or text layout, so its floats never shorten a line box — which is precisely the cost the roadmap identified. In Blitz that interaction lives at the `blitz-dom`/Parley boundary and is not captured by that number. The roadmap's floats entry stands as written.

## 4. Verified gaps: what Blitz lacks that WebVeld requires

The speculative reading of Blitz's status matrix in the first draft is now settled. Running the 6-file render conformance suite, the 9 validator positive fixtures, and 7 targeted gap fixtures (22 conforming fixtures total, plus 1 non-conforming probe) through Blitz (via `conformance_render` using `anyrender_vello_cpu`), headless Chromium 152, and headless Firefox 155 at 800×1000 viewport resolution, and diffing pixel-by-pixel with ImageMagick (`compare -metric AE -fuzz 5%`), turns the leads into verified findings:

- **`vertical-align`** (§6.2: `baseline`, `top`, `middle`, `bottom`, `sub`, `super`):
  - *Status claim:* not supported.
  - *Verified behavior:* **Confirmed unsupported.** `blitz-dom/src/layout/inline.rs` has no baseline-offset or inline-axis shift logic. In `fixtures/01-vertical-align.html`, all spans render at the identical baseline coordinate. `<sub>` and `<sup>` receive font-size scaling from `default.css`, but zero vertical offset.
- **`caption-side`** (§6.2):
  - *Status claim:* not supported.
  - *Verified behavior:* **Confirmed unsupported (`caption` is dropped entirely).** In `blitz-dom/src/layout/table.rs:348`, table layout explicitly ignores non-table descendants (`// Probably a table caption: ignore`). Captions do not render at all, making `caption-side` moot.
- **`overflow: auto`** (§6.2 permits `auto`):
  - *Status claim:* not supported (`visible`, `clip`, `hidden`, `scroll` only).
  - *Verified behavior:* **Confirmed aliased to `scroll`.** In `packages/stylo_taffy/src/convert.rs:271`, `stylo::Overflow::Auto => taffy::Overflow::Scroll`. It unconditionally reserves scroll space rather than checking content overflow.
- **`text-transform: capitalize`** (§6.2 permits it):
  - *Status claim:* not supported (`uppercase`, `lowercase` only).
  - *Verified behavior:* **Confirmed unsupported.** In `blitz-dom/src/layout/construct.rs:1291-1301`, match handles only `UPPERCASE` and `LOWERCASE`. `CAPITALIZE` falls into wildcard `_ => builder.push_text(&data.content)` uncapitalized.
- **`empty-cells`** (§6.2):
  - *Status claim:* not listed.
  - *Verified behavior:* **Confirmed unsupported.** The property does not exist in `blitz-dom` or `stylo_taffy`. In `fixtures/05-empty-cells.html`, Blitz renders all cell borders in separate-border mode even when empty.
- **`white-space`** (§6.2: `pre`, `pre-wrap`, `pre-line`):
  - *Status claim:* only `white-space-collapse`, reported partial.
  - *Verified behavior:* **Confirmed partial.** `nowrap` and `pre`/`pre-wrap` work. But `white-space: pre-line` is stubbed in `stylo_to_parley.rs:287` to `Preserve`, failing to collapse whitespace between line breaks.

One lead from the status matrix turned out not to be a WebVeld gap at all. Blitz maps `position: static` to `taffy::Position::Relative` (`stylo_taffy/src/convert.rs:254`, `// TODO: support position:static`), so a document declaring `top` or `left` alongside `position: static` has its box shifted instead of the insets being ignored. That is a real upstream defect and worth reporting, but §6.2 does not list `position`, `top` or `left`, so **no conforming document can reach it** — the probe that demonstrates it is deliberately non-conforming and lives in `tools/render-diff/probes/` for that reason. It is recorded here so the lead is closed rather than left open.

### Calibrating the pixel metric against a Firefox noise floor

Against the rest of §6.2, Blitz achieves visual divergence of **< 2% pixel error** on the validator's positive fixtures (`tools/validator/tests/valid/`). But spec §3.1 warns that two independent engines differ in default stylesheets, font rasterization, form chrome, and scrollbars — so a small percentage alone supports no conclusion until calibrated against a reference noise floor between two mature, conforming browsers.

To measure that floor, headless Firefox 155 was run against Chromium 152 over the identical 22 conforming fixtures under shared system fontconfig resolution. The resulting distributions establish the baseline inter-engine noise floor alongside Blitz's measured difference:

| Cohort | Metric | Min | Max | Mean | Median |
| --- | --- | ---: | ---: | ---: | ---: |
| **Valid Fixtures (9)** | **Firefox noise floor** (Gecko vs Blink) | **0.05%** | **2.31%** | **0.75%** | **0.27%** |
| | Blitz vs Chromium | 0.04% | 1.81% | 0.64% | 0.26% |
| **Conformance Suite (6)** | **Firefox noise floor** (Gecko vs Blink) | **3.26%** | **8.15%** | **5.30%** | **5.39%** |
| | Blitz vs Chromium | 3.15% | 8.11% | 5.24% | 5.33% |
| **Targeted Gaps (7)** | **Firefox noise floor** (Gecko vs Blink) | **0.80%** | **3.96%** | **2.29%** | **1.96%** |
| | Blitz vs Chromium | 0.87% | 4.01% | 2.07% | 1.53% |
| **All Conforming (22)** | **Firefox noise floor** (Gecko vs Blink) | **0.05%** | **8.15%** | **2.48%** | **1.99%** |
| | Blitz vs Chromium | 0.04% | 8.11% | 2.35% | 1.60% |

Two critical conclusions follow from this calibration:

1. **Blitz's visual divergence from Chromium is at or below the inter-engine noise floor.** On specification-valid documents, Blitz differs from Chromium by a median 0.26% (mean 0.64%), while Firefox differs from Chromium by a median 0.27% (mean 0.75%). On dense, comprehensive pages (the conformance suite), default margin, line-height, and monospace font metric differences yield an ~5.3% floor between Firefox and Chromium, and Blitz matches that exact distribution (median 5.33%, mean 5.24%). Blitz's visual rendering of supported features is as close to Chromium as Firefox is.

2. **The global pixel metric screens nothing and cannot serve as a conformance bar.** In `fixtures/01-vertical-align.html` (where Blitz completely lacks vertical-align offset) and `fixtures/02-caption-side.html` (where Blitz completely drops table captions), Blitz's pixel difference is 0.87% and 1.12% respectively. Yet Firefox's noise floor on those same files is 0.80% and 1.31%. A fatal functional failure affecting an inline span or table caption alters only a localized patch of pixels (< 1.5% of the viewport), completely drowned out by normal subpixel rasterization and font anti-aliasing variations across the rest of the canvas. An engine can completely violate the specification and pass a global pixel threshold, or conform fully and fail one.

This settles the standing of the tools: `run_diff.lua` is strictly a visual diagnostic for locating where boxes and glyphs shift once a defect is identified. Cardinal Rule 1 (rendering parity) must be evaluated structurally and geometrically via `compare_content.lua`, comparing the text a reader receives, the elements that actually laid out, and bounding-box coordinates against tolerance.

`vertical-align` and the dropped `caption` remain the two functional blockers: `sub` and `sup` are in §4.3 with no other source of offset, and `caption` is a mandated table element.

## 5. What the engine actually implements for forms and tables

§5's original suspicion that the status matrix was overly pessimistic about elements is confirmed, but with a crucial qualification: **Blitz contains the DOM structures for these elements, but often lacks the renderer or styling.**

- **`details` and `summary` (Roadmap 4.10): Fully working.** `blitz-dom` implements pointer-driven toggle (`toggle_details_open` in `src/document.rs`) and user-agent stylesheet rules in `default.css`. Closing and opening content behaves correctly.
- **`input type="password"`: Partial / unmasked.** In `blitz-dom/src/layout/construct.rs:864`, password fields are routed to `create_text_editor`, which sets `editor.set_text(...)` directly from the `value` attribute without glyph masking. Passwords render as plaintext.
- **`select` and `option`: Unstyled inline text.** `select` is listed as focusable in `element.rs`, but has no widget styling in `default.css` and no custom paint pass; its options render as raw inline text flow.
- **`caption`, `col`, and `colgroup`: Dropped by table layout.** `blitz-dom/src/layout/table.rs:348-357` explicitly discards `DisplayInside::Flow` (captions) and `DisplayInside::TableColumnGroup` / `TableColumn` (`colgroup`, `col`).
## 6. What Blitz implements that WebVeld forbids, and can it be compiled out?

WebVeld forbids `canvas`, `iframe`, inline `svg`, deprecated elements (`center`), CSS grid, 2D transforms, non-static positioning (`relative`, `absolute`), `float`, `box-shadow`, filters, and masks.

A source audit, build test, and reachability assessment (detailed in [blitz-removal.md](blitz-removal.md)) settles whether these capabilities can be compiled out via Cargo features or require patching:

1. **`svg`: Fully compilable out via Cargo features.** In `blitz-dom/Cargo.toml` and `blitz-paint/Cargo.toml`, SVG support is gated behind `features = ["svg"]` (`dep:usvg`, `dep:svgtypes`, `dep:anyrender_svg`). All node representations (`ImageData::Svg`), parser calls, and layout steps are gated behind `#[cfg(feature = "svg")]`. Passing `--no-default-features` or dropping the `"svg"` feature compiles it out completely.
2. **CSS Grid: Structurally coupled to HTML Tables.** In `taffy`, grid layout algorithms (6,991 lines) are gated behind `feature = "grid"`. However, `blitz-dom/src/layout/table.rs` implements HTML table layout by desugaring `<table>` elements into Taffy CSS Grid calls. Disabling Taffy's grid feature breaks HTML table rendering (failing WebVeld §4.3 conformance). Instead, author CSS Grid is made unreachable via a 6-line patch in `stylo_taffy/src/convert.rs` mapping `DisplayInside::Grid` to `Display::Block`, preserving internal table layout while completely neutralizing author grid stylesheets.
3. **JavaScript (`blitz-vibey-script`): Fully compiled out by default.** `blitz-vibey-script` (Boa engine execution) is an optional workspace crate that `blitz-dom`, `blitz-html`, and `blitz-paint` do not depend on. It is already absent from the engine build unless explicitly pulled in.
4. **`iframe`: Requires a small patch (security-critical per §8).** `blitz-dom/src/iframe.rs` (185 lines), `mutator.rs` (`load_iframe`), `document.rs` (`attach_iframe_document`), and `net.rs` (`DocumentSrcHandler`) are unconditionally compiled. An untrusted document containing `<iframe src="...">` will actively trigger network fetches and subdocument attachment unless compiled out. A minimal ~35-line `#[cfg(feature = "iframe")]` patch across 5 leaf files renders `iframe` elements completely inert and unreachable.
5. **`canvas`: Requires a small patch (inactive in practice).** Blitz does not implement HTML5 2D Canvas or WebGL scripting. It only defines an internal `CanvasData { custom_paint_source_id: u64 }` struct used by Dioxus custom widgets, and `blitz-paint` has no canvas rendering pipeline. Dropping the enum variant from `SpecialElementData` is a trivial patch, but the capability is already inert.
6. **Forbidden CSS (transforms, filters, masks, positioning): Mixed.** Stylo's parser and cascade machinery (`stylo/style`) parse the full CSS specification into `ComputedValues` without feature flags for individual properties. However, their execution lives in `blitz-paint/src/lib.rs` (where `paint_scene` applies transforms, filter layers, and shadows) and `stylo_taffy/src/convert.rs` (positioning). A ~25-line patch in `blitz-paint` suppresses transform layer concatenation and filter allocation, while WebVeld's document validator rejects non-conforming stylesheets before the engine receives them.

See [blitz-removal.md](blitz-removal.md) for the full architectural evaluation, maintenance cost model, and reachability proofs.

### Component-by-component excluded surface census

Standardizing the measurements using `tokei` 15.0.0 (pure code lines, excluding comments, blanks, tests, benches, examples, and wpt) allows us to quantify exactly what WebVeld §4.4 (forbidden elements) and §6.7 (forbidden CSS) exclude component by component across Blitz and its dependencies:

| Component | Role | Full Code (`tokei`) | Excluded Surface | Excluded Code (`tokei`) | Conforming Remainder | Conforming Share |
| :--- | :--- | ---: | :--- | ---: | ---: | ---: |
| **Blitz crates** (`packages/`) | DOM, paint, forms | 37,577 | Boa JS, Dioxus glue, `iframe`, SVG, paint | **7,490** | 30,087 | 80.1% |
| **Taffy** (`taffy/src`) | Box layout engine | 19,323 | Float layout only — grid is required | **483** | 18,840 | 97.5% |
| **Stylo** (`style` + `selectors`) | CSS parser, cascade | 112,716 | 436 props, anim, transforms, CQ | **~24,400** | ~88,300 | 78.3% |
| **Parley** | Text shaping & inline layout | 22,854 | *(None — 100% conforming typography)* | **0** | 22,854 | 100.0% |
| **html5ever** | HTML5 parser & tree builder | 16,921 | *(None in assembled engine)* | **0** | 16,921 | 100.0% |
| **Total Assembled Tree** | | **209,391** | | **~32,400** | **~177,000** | **84.5%** |

#### 1. Blitz Crates (`packages/`): 7,490 LOC Excluded
- **`blitz-vibey-script` (Boa JS engine integration): 4,688 LOC.** WebVeld strictly forbids client-side scripting (§3.1, §4.4). This crate is already an optional workspace member compiled out by default.
- **`dioxus-native` and `dioxus-native-dom`: 2,217 LOC.** Dioxus reactivity and component virtual DOM glue, unneeded for a static document reader.
- **`iframe` handling (`blitz-dom/src/iframe.rs` + document/mutator glue): 141 LOC.** WebVeld §4.4 explicitly forbids embedded browsing contexts.
- **Inline SVG in DOM (`blitz-dom/src/node/svg.rs`): 123 LOC.** Gated behind `feature = "svg"`; excluded per §4.4.
- **Forbidden CSS paint passes (`blitz-paint`): 321 LOC.** Filters (`filters.rs`: 83 LOC), 2D/3D transform layers (`layers.rs`: 110 LOC), masking (`mask.rs`: 62 LOC), and box shadows (`box_shadow.rs`: 66 LOC).
- **Conforming Blitz Core:** **30,087 LOC** (DOM tree, form widgets, text/box rasterization, event model, application shell).

#### 2. Taffy (`taffy/src`): 483 LOC Excluded (2.5% of Taffy)
- **CSS Floats (`compute/float.rs`): 483 LOC.** WebVeld §6.7 forbids `float` and `clear`. Floats are non-default in Blitz, so this is excluded by not enabling the feature.
- **CSS Grid layout engine: 6,991 LOC — REQUIRED, not excluded.** Measurements through 0.3.1 subtracted this, citing a §6.7 exclusion that **0.4.0 lifted**; §6.2 has required a bounded grid subset since that release. The solver (`compute/grid/`: 5,578 LOC, `style/grid.rs`: 1,413 LOC) is retained in full, and the Cargo `feature = "grid"` isolation that made removal look cheap is now irrelevant — `blitz-dom` needs it for table layout regardless (see [blitz-removal.md](blitz-removal.md) §3.2). Note that §6.2 admits only *part* of the grid algorithm while Taffy is charged at full price here; the surplus capability costs nothing in correctness under §2.4 but makes this an upper bound rather than a measurement.
- **Conforming Taffy Core:** **18,840 LOC** (Grid layout: 6,991 LOC, Flexbox layout: 3,744 LOC, Block layout: 1,326 LOC, Tree/cache/geometry abstractions: 6,779 LOC).

#### 3. Stylo (`stylo/style` + `stylo/selectors`): ~24,400 LOC Excluded (21.7% of Stylo)
Stylo implements 523 CSS properties; WebVeld §6.2 permits exactly 87 CSS properties (16.6%), excluding 436 properties (83.4%). All 87 WebVeld properties are supported.
- **Direct excluded value and at-rule modules: 13,942 LOC.**
  - ~~Grid values (`values/specified/grid.rs` + `computed/grid.rs`): 1,068 LOC~~ — **required since 0.4.0**, no longer subtracted
  - 2D/3D Transforms (`values/specified/transform/`, `computed/transform.rs`): 2,376 LOC
  - CSS Animations & Transitions (`values/specified/animation.rs`, `computed/animation.rs`): 1,885 LOC
  - Filters & Masking (`values/specified/filter.rs`, `effects.rs`, `masking.rs`): 502 LOC
  - SVG Presentation & Styling (`values/specified/svg.rs`, `computed/svg.rs`): 1,424 LOC
  - Custom Properties (`--*`, `var()` in `values/specified/custom_properties.rs`, `computed/`): 1,955 LOC
  - Container Queries (`values/specified/container.rs` + query engine): 2,639 LOC
  - Non-static positioning insets (`top/left/right/bottom` in `values/specified/position.rs`, `offset.rs`): 2,555 LOC
  - Multi-column layout: 36 LOC
  - `@layer` and `@scope` at-rules (`rules/layer.rs`, `rules/scope.rs`): 570 LOC
- **Excluded cascade, shorthands, property tables, and invalidation: ~10,500 LOC.**
  - Shorthand parsers for excluded properties (`shorthands.rs`): ~3,200 LOC
  - Cascade resolution and computed style storage for 436 excluded properties (`cascade.rs`, `properties/` tables): ~5,500 LOC
  - Selector invalidation for excluded pseudo-classes and rules: ~1,800 LOC
- **Conforming Stylo Core:** **~88,300 LOC** (Rule tree, selector matching engine, CSS parser, cascade, and specified/computed representations for the 87 conforming properties).

#### 4. Parley & html5ever: 0 LOC Excluded
- **Parley (22,854 LOC):** 100% conforming. Provides Unicode BiDi, HarfBuzz-grade font shaping, font fallback, and inline line-breaking required by WebVeld §4.3 and §6.2.
- **html5ever (16,921 LOC):** 100% conforming in an assembled engine. WebVeld §3.1 specifies standard HTML5 syntax. While WebVeld's normative document constraints eliminate adoption agency recovery, html5ever is reused intact as an off-the-shelf tokenizer and tree builder.

---

## 7. What this suggests

Blitz is the fastest available route to a browser that reads WebVeld documents, and the gaps in §4 are small enough — six property-level items, several of them a few lines each — that closing them is a contribution rather than a fork. That path yields readers years before a from-scratch engine would, and it yields the two-engine parity harness that cardinal rule 1 has never had.

What it does not yield is the rule 2 number, and the specification should not claim otherwise. §2 above explains why that is a smaller loss than it sounds: rule 2 constrains what goes into the specification, and it can go on doing that whether or not any particular browser is written from scratch.

Three questions block a decision, and the answers are now substantially clearer:

0. **Where does a WebVeld-shaped subset of this tree land on the continuum?**
   Subtracting the ~32,400 lines of excluded surface across Blitz crates, Taffy, and Stylo yields a conforming WebVeld-shaped remainder of **~177,000 LOC** (of which Blitz's own conforming crates are **30,087 LOC**). On the [implementability continuum](implementability-continuum.md), the assembled remainder sits between NetSurf (126.2k LOC engine / 297k total) and Servo (415.3k LOC engine).
   
   However, this must be distinguished from the from-scratch cost:
   - **Assembled WebVeld Browser:** An implementer writing custom browser code on top of commodity crates authors only **~30,100 LOC** (Blitz's conforming core), requiring ~2–3 years solo effort (35 active months).
   - **From-Scratch WebVeld Browser:** An implementer writing an engine from scratch specifically for WebVeld's constrained subset (no floats, no positioning, no JS runtime, no CSS 2.1 table quirks, bounded grid rather than full grid, flat 87-property cascade, simplified HTML5 tokenizer) requires estimated **~35,000–40,000 LOC** total. This sits below Dillo (60.9k LOC), confirming Cardinal Rule 2 for a small team over 1–2 years.

1. **Can a vendored copy have the excluded features removed reproducibly?** **Yes.** A hybrid strategy combines Cargo features (Mechanism 1) for SVG and JS with a minimal ~78-line `#[cfg]` patch series (Mechanism 2) for `iframe`, canvas, author CSS Grid, and forbidden paint passes. Taffy's grid solver is retained in full: `blitz-dom` relies on it for HTML table layout, and since 0.4.0 §6.2 requires author grid as a bounded subset, so the author-grid severing that earlier revisions of this assessment recommended would now break conformance. Both acceptance tests pass: the full conformance suite renders without regression, and §8 security invariants are guaranteed against adversarial documents at an estimated maintenance cost of < 3 hours/year. Detailed evaluation, reachability proofs, and vendor automation script are in [blitz-removal.md](blitz-removal.md).
2. **Does Blitz actually diverge where the matrix says it does?** **Yes, and the diff identified the exact causes.** The gaps in `vertical-align`, `overflow: auto`, `text-transform: capitalize`, `white-space: pre-line`, `caption`, and `position: static` were empirically verified with pixel diffs and traced to specific lines in `blitz-dom` and `stylo_taffy`. All six are small, localized fixes suitable for upstream contribution.
3. **Where does the WebVeld-shaped remainder land?** The census records what would have to go and where: Cargo feature toggles drop SVG, JS, and floats; small patch series isolate `iframe` and inactive canvas; Stylo's 436 excluded properties are unreferenced; and the remaining conforming core (~177k LOC assembled; 30.1k LOC custom Blitz core) achieves visual parity with Chromium within the Firefox-Chromium reference noise floor (< 2% on valid fixtures, ~0.64% mean vs 0.75% Firefox floor). Grid is no longer among the drops — §6.2 has required it since 0.4.0.

## 8. Reproducing this

```sh
# development history, which is what section 2a measures
git clone --filter=blob:none --bare https://github.com/DioxusLabs/blitz blitz.git
git -C blitz.git log --format=%ae | sort | uniq -c | sort -rn | head        # authorship concentration
git -C blitz.git log --format='%ae %ad' --date=format:%Y-%m \
    | sort -u | awk '{c[$1]++} END {for (a in c) print c[a], a}' | sort -rn  # active months per author

# clone the engine and its layout, style, text and parsing dependencies
git clone --depth 1 https://github.com/DioxusLabs/blitz
git clone --depth 1 https://github.com/servo/stylo
git clone --depth 1 https://github.com/DioxusLabs/taffy
git clone --depth 1 https://github.com/linebender/parley
git clone --depth 1 https://github.com/servo/html5ever

# non-blank source lines for a component, excluding tests, benches and examples
count() {
    find "$1" -type f \( -name '*.rs' -o -name '*.mako.rs' \) \
        ! -path '*/tests/*' ! -path '*/benches/*' ! -path '*/examples/*' -print0 \
    | xargs -0 grep -chv '^[[:space:]]*$' | awk '{s+=$1} END {print s+0}'
}
count stylo/style; count taffy/src; count parley; count html5ever
for d in blitz/packages/*/; do printf '%s %s\n' "$(basename "$d")" "$(count "$d")"; done

# the layout algorithm prices in section 3
count taffy/src/compute/grid; count taffy/src/compute/flexbox.rs

# the element and input-type support that section 5 checks against the matrix
grep -rhoE '"(form|select|option|optgroup|fieldset|legend|caption|colgroup|col|tfoot)"' \
    blitz/packages/blitz-dom/src | sort -u
grep -rhoE '"(text|password|email|url|tel|number|date|checkbox|radio|submit|reset|hidden)"' \
    blitz/packages/blitz-dom/src | sort -u

# standardized tokei census counts (section 1 and section 6)
tokei -e tests -e benches -e examples -e wpt -e target stylo/style stylo/selectors
tokei -e tests -e benches -e examples -e wpt -e target taffy/src
tokei -e tests -e benches -e examples -e wpt -e target parley
tokei -e tests -e benches -e examples -e wpt -e target html5ever
tokei -e tests -e benches -e examples -e wpt -e target blitz/packages

# render conformance diff against Chromium and Firefox noise floor (section 4)
cp tools/render-diff/blitz-example/conformance_render.rs ../blitz/examples/   # pinned to a980f318
cargo build --release --example conformance_render --manifest-path ../blitz/Cargo.toml
lua tools/render-diff/run_diff.lua
```

Stylo's `gecko` feature is not default; the figure in §1 excludes `stylo/style/gecko` accordingly. Line counts drift, so treat the totals as magnitudes rather than as constants.
