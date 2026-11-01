# Dillo as a WebVeld Reference Point

**Subject:** Dillo 3.3.0-rc1, commit `6856c50` (2026-04-19) · **Measured:** 2026-09-07 · **Against:** [webveld-spec.md](../webveld-spec.md) v0.3.0 and [webveld-roadmap.md](../webveld-roadmap.md)

*Measured against v0.3.0. The porting checklist in section 4 predates the 0.3.1 additions (`outline`, `clip-path`, `align-content`, `list-style`, `calc()`, the universal selector, `@media print`); add those to any current estimate.*

Dillo is the closest thing to a WebVeld browser that exists: a small graphical browser that renders HTML and CSS with images over HTTP and HTTPS and ignores scripting entirely. It was revived in December 2023 by Rodrigo Arias Mallo after years dormant and has shipped steadily since. This document measures it against two questions — whether it supports cardinal rule 2, and how much of the WebVeld roadmap it already implements — and records the gap in both directions.

Reproduction commands are in the last section, so this can be re-run against a later release.

## 1. Size

| Component | Lines |
| --- | --- |
| `dw/` — layout and rendering | 35,844 |
| `src/` core — `html.cc`, `css.cc`, `cssparser.cc`, `styleengine.cc`, `table.cc`, `form.cc` | 10,557 |
| `lout/` — containers and utilities | 4,433 |
| `dpi/`, `dpid/`, `dlib/` — plugin and utility plumbing | 9,325 |
| **All of `src` `dw` `lout` `dlib` `dpi` `dpid`** | **100,439** |
| — of which `src/hsts_preload`, a data file rather than code | 10,050 |

So roughly 90,000 lines of code, of which the engine proper — HTML parsing, CSS, style resolution, layout, rendering — is about 46,000.

What Dillo does *not* write is as important as what it does. It borrows FLTK for the GUI, a system TLS library for transport, and libpng, libjpeg, libwebp and an SVG library for image decoding. Those are the commodity pieces, and they are enormous.

## 2. Does Dillo support cardinal rule 2?

Rule 2 holds that a complete conforming WebVeld browser must remain something a single developer or a small team can write from scratch in months rather than years.

**What Dillo establishes.** The artifact size is plausible. An engine that renders real-world HTML and CSS well enough for daily use, with no scripting, is tens of thousands of lines — not hundreds of thousands, and nowhere near the tens of millions a modern engine requires. Dillo is the strongest available evidence that the rule is describing something achievable rather than something aspirational.

**What Dillo complicates.** Two things. First, the project began in 1999 and turned 25 in 2025; 36,000 lines of layout code is not a months-scale artifact for one person, even granting that the work was volunteer and intermittent. Second, and more usefully, Dillo aims at the live web, which never stops moving — a target WebVeld deliberately does not set.

**What follows for the rule's wording.** Read as "the browser's own engine, assuming commodity libraries for TLS, image decoding, and the GUI toolkit," rule 2 is defensible and Dillo is roughly the right scale. Read as "every line, including transport and widgets," no project in history passes and the rule silently benchmarks OpenSSL. The specification now says which it means.

**The honest version of the claim.** Writing a conforming WebVeld browser from nothing in months is optimistic. *Adapting Dillo* into one plausibly is a months-scale job — see the porting checklist in section 4, which is short.

## 3. Roadmap coverage

Candidates checked against the source. This was measured when all of them were roadmap items; specification 0.3.0 has since adopted eight of them, so most of the "No" rows below have been promoted into the porting checklist in section 4 — they are now conformance requirements Dillo fails, not features it merely lacks. The rows are kept because the measurement is what informed that decision.

| Candidate | Now | In Dillo | Evidence |
| --- | --- | --- | --- |
| Table border properties | in spec | **Yes** | `BORDER_COLLAPSE`, `BORDER_SPACING`, `CAPTION_SIDE`, `EMPTY_CELLS` in the property enum |
| Small element additions | in spec | **Mostly** | `del`, `ins`, `q`, `dfn`, `wbr`, `optgroup` supported; `time`, `col` missing/stubbed |
| `meta name="viewport"` | in spec | No | No viewport handling in `html.cc` |
| `details` / `summary` | deferred | No | Absent from the tag table entirely |
| `:target` | in spec | No | Pseudo-class machinery exists (`SELECT_PSEUDO_CLASS`); this selector does not |
| Media queries | in spec | No | No `@media` handling anywhere |
| Static ARIA attributes | in spec | No | No `aria-*` handling |
| `overflow-wrap`, `word-break` | in spec | No | Absent from the property enum |
| `link rel="icon"`, `rel="alternate"` | in spec | No | `html.cc:3339` accepts only `rel="stylesheet"`, rejecting other values |
| CSS custom properties | candidate | No | No `var()` support |
| Inline `style` attributes | candidate | **Yes** | Parsed at `html.cc:3936` — a feature WebVeld forbids |
| Minimal SVG subset | candidate | **Different axis** | SVG supported as an *image format* via an optional decoder, not as inline markup |
| Bounded CSS grid subset | candidate | No | No grid properties |

Roughly one and a half of the nine items that were Tier 1, and one of the four that were Tier 2 — that one being inline styles, which WebVeld forbids rather than wants. Dillo does implement floats, the one remaining candidate on the roadmap it already has.

## 4. What Dillo lacks that WebVeld already requires

This is the porting checklist, and it is the most actionable result here. These are not roadmap items; they are conformance requirements in the current specification that Dillo does not meet.

**CSS (spec §6.2, §6.3, §6.6):**

- **The entire flexbox model.** No `display: flex`, `flex-direction`, `flex-wrap`, `justify-content`, `align-items`, `flex-grow`, `flex-shrink`, `flex-basis`, or `order`, and no `gap`, `row-gap`, `column-gap`. This is the single largest gap: flexbox is WebVeld's only layout mechanism beyond the box model, and Dillo has none of it.
- `border-radius`
- `box-sizing`
- `opacity`
- `overflow-wrap` and `word-break`
- Media queries — `@media` with `width`, `min-width`, `max-width`, and `prefers-color-scheme`, including the rule that a `url()` value must not appear inside a media block
- The `:target` pseudo-class

**Elements (spec §4.3):** `caption`, `fieldset`, `legend`, and `noscript` are present in the tag table only as stubbed-out entries, alongside `col` and `colgroup`. All are required. `time` is absent entirely.

**Attributes (spec §5.1, §5.2):** `role` and the four permitted `aria-*` attributes, passed through to the platform accessibility layer; `meta name="viewport"` with `content`; and `link rel="icon"` and `rel="alternate"` with `type` and `title` — Dillo currently accepts only `rel="stylesheet"`. `noscript` matters most: spec §2.4 item 8 requires a conforming browser to render its contents as ordinary content, and while Dillo probably displays them today by virtue of unknown elements passing through, that is an accident rather than an implementation.

## 5. What Dillo implements that WebVeld forbids

Removal is the easier half of the work, but it is not nothing. Dillo supports floats and `clear`, `position` with `top`/`right`/`bottom`/`left`, `z-index`, `visibility`, `clip`, counters and `quotes`, `text-indent`, `text-shadow`, `font-variant` and `font-stretch`, inline `style` attributes, and the elements `iframe`, `embed`, `object`, `video`, `audio`, `source`, `map`, `area`, `frame`, `frameset`, `script`, and a long tail of legacy presentational tags (`font`, `center`, `big`, `strike`, `tt`, `dir`, `isindex`).

The shape of the difference is worth stating plainly: **Dillo implements a different subset, not a smaller one** — richer than WebVeld in legacy CSS, poorer in modern layout.

## 6. Incidental findings

- **Credentials are already covered.** `form.cc:467` handles `input type="password"`, and `src/auth.c` implements HTTP authentication. Both paths named in spec §5.2 and §8 exist in the closest thing to a reference implementation.
- **Optional decoders are a model worth borrowing.** WebP and SVG image support are build-time flags (`--disable-webp`, `--disable-svg`). That is a good pattern for formats beyond WebVeld's PNG and JPEG baseline: a browser MAY decode more, a packager decides whether the attack surface is worth it, and no document may depend on it.
- **Dillo's `link` handling already matches WebVeld's.** It accepts only `rel="stylesheet"` — the same restriction §5.2 imposes, arrived at independently.
- **The parser is HTML5-aware** (`DT_HTML` with an `html5` flag affecting base URL handling), so the doctype WebVeld requires is understood rather than tolerated.

## 7. What this suggests

The productive next step is not writing a browser. It is taking Dillo, adding flexbox, a handful of CSS properties, restricted media queries and one selector, implementing six missing or stubbed elements and three attribute behaviors, and running the result against the WebVeld conformance tests once they exist. That exercise would either validate the subset as implementable or expose the places where it is unrealistic, at a fraction of the cost of finding out the hard way — and it would produce a conforming browser as a by-product.

The flexbox gap deserves particular thought before that work starts. WebVeld chose flexbox over floats and positioning on the grounds that it is the simpler layout model, and it is — but Dillo, the only extant minimal engine, implemented floats and positioning instead and has no flexbox at all. That is worth understanding before treating the choice as settled: it may reflect Dillo's age rather than relative difficulty, or it may be evidence that flexbox is harder to retrofit than the specification assumes.

This is one of three independent measurements now feeding the same question — what a minimalist audience already builds with, and where the specification's element and property lists disagree with it. [webveld-corpus-study.md](webveld-corpus-study.md) measures finished pages; [luasmith-assessment.md](luasmith-assessment.md) measures a static site generator's default output. Read together with this document, they are stronger evidence than any one of them alone.

## 8. Reproducing this

```
git clone https://github.com/dillo-browser/dillo.git && cd dillo

# size
find src dw lout dlib dpi dpid -type f \( -name '*.c' -o -name '*.cc' -o -name '*.h' -o -name '*.hh' \) | xargs wc -l | tail -1
find dw -name '*.cc' -o -name '*.hh' | xargs wc -l | tail -1

# supported elements (the tag table)
grep -n 'Tags\[\] *=' src/html.cc              # locate the table, then read the following ~140 lines
sed -n '3483,3620p' src/html.cc | grep -o '{"[a-z0-9]*"' | tr -d '{"'

# stubbed-out elements
sed -n '3483,3620p' src/html.cc | grep '^ */\* [a-z]'

# supported CSS properties
grep -o 'CSS_PROPERTY_[A-Z_]*' src/css.hh | sort -u

# individual features
grep -rn '"rel"' src/html.cc                   # link rel handling
grep -rn '"password"' src/*.cc                 # input types
grep -rniE 'aria-|@media|:target|var\(' src/   # absent features
```

Line numbers drift between releases; locate the tag table by pattern rather than trusting the range above.
