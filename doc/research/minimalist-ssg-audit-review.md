# Reviewing the Minimalist SSG Audit

**Subject:** Historical Minimalist SSG Audit · **Reviewed:** 2026-09-07 · **Against:** [webveld-spec.md](../webveld-spec.md) v0.3.0

*Reviewed against v0.3.0. The `:checked` gap this review surfaced was adopted in 0.3.0; see Appendix B of the specification for what has since changed.*

The archived document is a survey — produced by another model, from training knowledge rather than by inspecting real output — listing static site generators favored by minimalist and low-bandwidth-club authors, and auditing their typical markup patterns against WebVeld. It belongs in the same evidence line as [dillo-assessment.md](dillo-assessment.md), [webveld-corpus-study.md](webveld-corpus-study.md), and [luasmith-assessment.md](luasmith-assessment.md), but it is a different kind of source: those three came from reading actual code or actual pages, this one from a description of tools rather than their output. It is treated here as a list of leads to verify, not as verified fact, and every specific conformance claim it makes is checked against the current spec text below.

## What checks out

- **`<details>`/`<summary>` forbidden (§4.4).** Correct, and already tracked on the roadmap as the first thing to reconsider once an implementation exists.
- **Inline SVG forbidden, and SVG forbidden as an `<img>` source (§4.4, §7.4).** Both citations are accurate against the current text.
- **Inline `style=""` on syntax-highlighted tokens is forbidden (§5.3, §6.1).** Correct, and the same finding the luasmith assessment made independently — some highlighters (Pygments with `-O noclasses` is the classic case) emit `style="color:#xxx"` per token when an author opts out of a stylesheet; the class-based default in most generators avoids this, but a config choice can trip it.
- **Footnote markup (`sup`, `id`-linked `a href="#fn:1"`, `ol`/`li`, ARIA `role="doc-noteref"`/`role="doc-backlink"`) is compatible.** Verified: `role` is a global attribute with no value restriction in §5.1 ("Their meaning is defined by WAI-ARIA and is not restated here"), fragment navigation is normative (§7.1), and every element named is in §4.3. This one holds up.
- **Automatic heading-anchor permalinks are compatible.** Verified against §4.3, §5.1, §5.2, §7.1 as cited.
- **`@media (prefers-color-scheme: dark)` is supported (§6.6).** Correct.

## What's wrong: the checkbox hack does not conform

The audit claims CSS-only theme toggles using `<input type="checkbox">` with the general sibling combinator and `:checked` are "theoretically conformant with §6.2 and §6.3." **This is incorrect.** The general sibling combinator (`~`) is permitted (§6.3), but `:checked` is not in the allowed pseudo-class list, which currently reads: `:hover`, `:focus`, `:active`, `:visited`, `:link`, `:first-child`, `:last-child`, `:nth-child(n)`, `:target`. No form-state pseudo-class is present.

This matters beyond the one example the audit gives. The checkbox hack is not a dark-mode-specific trick — it is *the* general-purpose CSS-only interactivity technique across the entire no-JavaScript web design tradition: accordions, mobile navigation drawers, tab interfaces, and dismissible notices all use the identical `input[type=checkbox] + label` and `:checked ~ .panel { display: block }` pattern. An audit whose purpose is finding where WebVeld disagrees with how minimalists already build things found the single most common scriptless interactivity idiom in that community and reported it as already working. It is currently the opposite: a real, unflagged gap, and probably a more consequential one than `<details>`/`<summary>`, which achieves a narrower slice of the same goal.

There is design history worth connecting here. An earlier design discussion considered "the checkbox hack" as a stand-in for scripted interactivity and separately brainstormed how it could be abused — chaining hundreds of hidden checkboxes with sibling selectors and **custom properties** into a Turing-complete state machine. That risk was specific to combining `:checked` with custom properties (still not adopted — Tier 2 on the roadmap) and, more importantly, with a WASM-driven mechanism that could toggle state at machine speed. WASM is gone entirely as of 0.2.0. Without a runtime, nothing can toggle a checkbox faster than a human clicks one, which removes the layout-thrashing concern that made the earlier discussion nervous. `:checked` in isolation, with no custom properties, is a materially different and much smaller proposal than what was rejected.

## A claim that doesn't hold up on inspection

The audit states generators "commonly" support inline code line-numbering "via HTML `<table>` columns or `data-line` counters," and flags `data-line` as a `data-*` violation (correctly — §5.3 forbids `data-*` outright). Checking this against Hugo's Chroma highlighter specifically: its table-based line numbering (`linenos=table`) puts line numbers in one `<td>` and code in another, with no `data-line` attribute in its default output. The general principle stands — if a generator's configuration does emit `data-*` attributes, that document doesn't conform — but the claim that this is a common default among the generators named is not supported by the one case checked, so it is not carried forward as a finding here.

## Implications for the specification

### `:checked` is worth adding, and the case is unusually clean

Checked against the three cardinal rules directly:

- **Parity** — `:checked` is a universally supported CSS pseudo-class with no polyfill required; a WebVeld document using it renders identically in Chromium, Firefox, and Safari today.
- **Implementability** — cheap relative to nearly everything else under consideration. An engine that supports HTML forms already tracks checkbox and radio state to collect form values; exposing that state to selector matching is a small increment, nowhere near the cost of flexbox or a bounded grid.
- **Privacy and safety** — no new surface. State changes only on direct user interaction with a native form control; nothing can toggle it programmatically, since there is no programming.

This is a stronger admission case than most Tier 2 roadmap candidates, and it buys real capability: toggleable disclosure, simple tab interfaces, and dismissible content, all without a new element and without reopening any of the interactivity debate that led to WASM's removal. It is complementary to `<details>`/`<summary>` rather than a substitute for it — native disclosure carries default accessibility semantics (`aria-expanded`, keyboard activation) that a bare checkbox styled to look like a toggle does not, since CSS-driven visibility changes are invisible to assistive technology unless the author separately manages ARIA state. That trade-off is worth stating in the spec text if `:checked` is adopted, not left implicit.

Worth considering alongside it, for the same reason and at similar cost: `:disabled`, `:required`, `:invalid`, and `:valid` — form-state pseudo-classes that enable CSS-only validation feedback, a pattern at least as common as the checkbox hack in minimalist forms.

### A cheaper subset of the SVG question

The roadmap's SVG candidate is inline SVG — a bounded markup grammar with its own parsing and DOM-integration concerns. The audit's SVG-icon example suggests a narrower and likely cheaper alternative worth recording separately: permitting `.svg` files as an **image source** only, decoded and painted the same way §7.4 already treats PNG and JPEG, with no exposure to the DOM, no CSS targeting of internal elements, and no interaction with `::before`/`::after`. The entity-expansion and node-depth safety work is shared with the inline-SVG candidate either way, but this version avoids the harder half of that candidate's cost — the part where SVG behaves like markup rather than like a raster image. It is a smaller step toward the same author-facing gap (crisp icons and logos) that the roadmap already identifies as the largest one authors feel.

### Nothing else changes

The footnote pattern, anchor permalinks, and `prefers-color-scheme` support were already correct; no spec change follows from them. `<details>`/`<summary>` and `meta name="description"`/`name="keywords"` were already queued from the roadmap and the luasmith review respectively; this audit adds no new argument for either beyond what is already recorded.

## On the reliability of this source

Unlike the Dillo and luasmith assessments, this document's factual claims about specific generators were not independently verified against those generators' actual output — only against general knowledge and, for two claims (Soupault's architecture, Chroma's line-numbering markup), a web search. The tool descriptions read as plausible and the named projects are real, but "plausible" is a lower bar than "read from source." If the SSG-audit task in `doc/tasks/future.tm.md` is picked up, it should verify output from at least `ssg5`, Zola, and Soupault directly — the same method the luasmith assessment used — rather than treat this survey as settled. It should also specifically check how common `:checked`-based interactivity actually is across real minimalist sites; the existing corpus-study tooling in `tools/corpus-study/` could be re-run with a check for `:checked` usage added, which would turn "the most common no-JS interactivity idiom" from an assertion into a measured percentage, the same way the flexbox-versus-floats question was settled.
