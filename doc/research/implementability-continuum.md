# The Implementability Continuum

**Subject:** Empirical evaluation of browser and document engine implementability · **Measured:** 2026-09-08 · **Supporting:** [webveld-spec.md](../webveld-spec.md) §3.1 (rule 2)

*Measured against the spec as of 2026-09-08. The spec now states the budget as a rough guide of about 40,000 lines of engine code (spec §3.1), and no longer quotes the assembled total; the figures below are the measurements behind that guide, and the rule 2 wording quoted next is from that time.*

Cardinal Rule 2 mandates:
> *"This specification MUST remain small enough that a complete, conforming WebVeld browser stays within reach of a single developer or a small team working over a year or two, rather than requiring an organization working over a decade. What is measured is the browser's own engine — parsing, style resolution, layout, rendering — assuming commodity libraries for TLS, image decoding, and the platform's widget toolkit."*

Specification v0.3.1 originally framed this budget as "months of work rather than years." In v0.3.2, that wording was corrected to "a year or two" based on a first cut of repository histories in [blitz-assessment.md](blitz-assessment.md) §2a. Because §3.1 now cites this empirical baseline as the reason an implementer can verify the budget rather than take it on faith, this document establishes a rigorous, standardized **Implementability Continuum** across eight reference points spanning from minimalist single-document clients to commercial full-web engines.

---

## 1. Methodology

To prevent numbers from being artifacts of ad-hoc scripts or divergent line-counting heuristics, two standardized metrics are applied uniformly across all measured codebases:

1. **Standardized Artifact Size (`tokei` 15.0.0):**
   - Code lines are measured using the standard `tokei` code counter, recording pure source code lines (excluding blank lines, comments, documentation comments, and embedded markup).
   - Test suites (`tests/`, `test/`, `wpt/`), benchmarks (`benches/`), standalone examples (`examples/`), build caches (`target/`), and raw data tables (such as preload lists or translation catalogs) are strictly excluded from engine totals.
2. **Standardized Development History (`git log`):**
   - **Total Commits:** Total non-merge changesets across the repository lineage.
   - **Core Authors:** Distinct contributors who authored **≥ 20 commits** (filtering out transient typo fixes and dependency bumps to reveal the real human engineering core).
   - **Dominant Author Concentration:** Percentage of all commits authored by the #1 contributor and top 3 contributors.
   - **Active Calendar Months:** Total distinct calendar months (`YYYY-MM`) with commit activity, measuring sustained human attention across calendar time.
   - **Historical Span:** Date of root commit to latest recorded commit.

---

## 2. The Implementability Continuum Table

The table below places engines in order of engine artifact size and structural complexity:

- **Amfora** (Gemini TUI client in Go, terminal cell grid)
  - *Engine Code:* **6,774** LOC (`tokei`) | *Total Repo:* 7,710 LOC
  - *History:* 553 commits across 40 active months (2020–2026)
  - *Authors:* 2 core authors (top author: 76.9%, top 3: 85.4%)
- **Blitz (own crates)** (Scriptless HTML/CSS engine: DOM, paint, glue in Rust)
  - *Engine Code:* **36,112** LOC (`tokei`) | *Total Repo:* 37,577 LOC
  - *History:* 1,890 commits across 35 active months (2023–2026)
  - *Authors:* 2 core authors (top author: 89.0%, top 3: 93.1%)
- **Dillo (engine)** (Monolithic graphical browser in C/C++, `dw/` + `src/` core)
  - *Engine Code:* **60,902** LOC (`tokei`) | *Total Repo:* 83,504 LOC
  - *History:* 5,119 commits across 141 active months (1999/2007–2026)
  - *Authors:* 7 core authors (top author: 44.4%, top 3: 77.0%)
- **Lagrange** (Rich Gemini GUI client in C/SDL, custom text layout)
  - *Engine Code:* **92,104** LOC (`tokei`) | *Total Repo:* 140,041 LOC
  - *History:* 6,041 commits across 73 active months (2020–2026)
  - *Authors:* 13 core authors (top author: 86.6%, top 3: 89.3%)
- **NetSurf (engine)** (Lightweight multiplatform web browser in C, `content/`)
  - *Engine Code:* **126,212** LOC (`tokei`) | *Total Repo:* 297,314 LOC
  - *History:* 15,040 commits across 274 active months (2002–2026)
  - *Authors:* 20 core authors (top author: 22.1%, top 3: 52.6%)
- **Blitz (assembled tree)** (Blitz crates + Taffy + Parley + html5ever + Stylo)
  - *Engine Code:* **209,391** LOC (`tokei`) | *Total Repo:* 213,800 LOC
  - *History:* ~18,100 commits across 145 active months (2014–2026)
  - *Authors:* ~119 core authors (composite distribution)
- **Servo (engine)** (Parallel modern browser engine in Rust, `components/`)
  - *Engine Code:* **415,332** LOC (`tokei`) | *Total Repo:* 463,902 LOC
  - *History:* 58,017 commits across 176 active months (2012/2018–2026)
  - *Authors:* 201 core authors (top author: 15.5%, top 3: 25.3%)
- **Chromium (Blink)** (Commercial web engine, Blink core layout/DOM/paint)
  - *Engine Code:* **~5,000,000** LOC | *Total Repo:* ~36,000,000 LOC
  - *History:* >1,000,000 commits across >210 active months (2008–2026)
  - *Authors:* >4,000 core authors (top author: < 1%, top 3: < 2%)

*Notes on counts:*
- **Lagrange:** Excludes 43,700 lines of gettext `.po` localization strings.
- **Dillo:** Engine code isolates `dw/` (layout/rendering: 23,401 LOC) and `src/` core (HTML/CSS parsing & style: 37,501 LOC). Git history covers 2007–2026; the codebase began in 1999 under CVS.
- **NetSurf:** Engine code isolates `content/` (HTML parser, CSS engine, box tree, and text layout: 126,212 LOC); the remaining 162,102 LOC comprise frontends (GTK, Amiga, RISC OS, framebuffer) and toolkit glue.
- **Blitz (assembled tree):** Measures the combined engine surface: Blitz crates (37,577), Taffy layout (19,323), Parley text (22,854), html5ever (16,921), and Stylo `style`+`selectors` (112,716), excluding Stylo's optional `gecko` binding.
- **Servo:** Engine code isolates `components/` (style, layout, script, constellation, gfx, net). Excludes Web Platform Tests (`tests/wpt/`).
- **Chromium:** Published open source figures. Blink layout, DOM, CSS, and paint comprise roughly 4.5–5.5M lines of C++ (excluding V8 JS engine at ~2M LOC and Skia 2D at ~1.5M LOC).

---

## 3. Detailed Anchor Point Analysis

### 3.1 The Minimal Document Tier: Gemini (Amfora & Lagrange)

The simplest hypertext model on the modern internet is the Gemini protocol (`gemtext`). Gemtext has no nested block containers, no inline styling elements, no CSS cascade, no reflow, and no form submission model.

- **Amfora (7,710 LOC, 553 commits, 40 active months):** A terminal client written in Go. A single lead author contributed 76.9% of all commits over 3.3 years. Terminal rendering delegates character wrapping and cell grid display to curses/tcell libraries. Even with zero layout algorithms, building a solid reader with bookmarks, history, tabs, and TLS configuration required 40 months of sustained attention.
- **Lagrange (92,104 LOC, 6,041 commits, 73 active months):** A graphical client written in C with SDL2. To provide proportional fonts, smooth scrolling, multiple tabs, split views, inline image decoding, and keyboard navigation, Lagrange wrote 92,104 lines of C. It is 86.6% the work of one developer across 6.1 years.

*Finding:* When a client renders graphics directly rather than in a terminal grid, even a language as simple as Gemtext demands ~90,000 lines of code and multi-year solo effort.

### 3.2 The Minimalist Web Tier: Dillo & Blitz (Own Crates)

This tier represents standalone HTML/CSS rendering engines that discard client-side scripting and modern corporate extensions.

- **Dillo (60,902 LOC engine, 5,119 commits, 141 active months):** Dillo proved that a graphical HTML/CSS engine can render the static web in tens of thousands of lines rather than millions. However, Dillo's history reveals the lower bound for an independent C/C++ engine: it required 7 core developers across 25 years of project lineage. Furthermore, Dillo implements an older web subset: it features floats and absolute positioning, but lacks flexbox, modern CSS media queries, and standard box-sizing.
- **Blitz's Own Crates (36,112 LOC, 1,890 commits, 35 active months):** Blitz's own workspace (`blitz-dom`, `blitz-paint`, `blitz-html`, `blitz-net`, `blitz-shell`, `stylo_taffy`) is roughly 36,000 lines of Rust. One developer contributed 89.0% of all commits across 35 active months (~3 years). It achieves high visual fidelity on scriptless pages by assembling modular commodity crates.

### 3.3 The Independent CSS/Layout Tier: NetSurf

- **NetSurf (126,212 LOC engine, 15,040 commits, 274 active months):** NetSurf is the critical bridge between Dillo and full-scale modern engines. Unlike Dillo, NetSurf implemented a complete CSS 2.1 cascade engine (`libcss`), custom layout tree (`content/`), and multiple frontend targets. It was sustained by 20 core developers over more than 22 years (274 distinct active months). The top author accounts for only 22.1% of commits. NetSurf represents the true cost of writing a custom, independent CSS parser, box layout algorithm, and renderer without reusing third-party CSS frameworks.

### 3.4 The Assembled Modern Engine: Blitz Ecosystem

When Blitz's underlying engine dependencies are counted together, the total engine surface reaches **209,391 lines of code**:

| Component | Role | Code LOC (`tokei`) | Commits | Core Authors | Top Author % | Active Months |
| :--- | :--- | ---: | ---: | ---: | ---: | ---: |
| `blitz` crates | DOM, forms, painting, shell glue | 37,577 | 1,890 | 2 | 89.0% | 35 |
| `taffy/src` | Flexbox, grid, and box layout | 19,323 | 1,086 | 5 | 42.6% | 75 |
| `parley` | Unicode text shaping & inline layout | 22,854 | 561 | 9 | 21.6% | 40 |
| `html5ever` | Spec-compliant HTML5 parser | 16,921 | 1,461 | 12 | 27.6% | 119 |
| `stylo` (`style`+`selectors`) | CSS parser, cascade, selectors | 112,716 | 13,124 | 91 | 19.9% | 145 |
| **Total Assembled** | | **209,391** | **~18,100** | **~119** | — | **145** |

*Finding:* Blitz is uniquely positioned on the continuum. It was built by one dominant developer (Nico Burns), who is also the primary author of Taffy (42.6% of commits). By authoring roughly 56,900 lines of code across Blitz and Taffy over 50 combined months, and reusing pre-existing production crates for text (Parley), parsing (html5ever), and style cascade (Stylo), a single developer achieved what historically required an organization.

### 3.5 The Full Modern Browser: Servo & Chromium

- **Servo (415,332 LOC engine, 58,017 commits, 201 core authors, 176 active months):** A full modern parallel engine implementing HTML, CSS, WebGL, WebSockets, DOM APIs, and SpiderMonkey JavaScript bindings. Supported by Mozilla, the Linux Foundation, Igalia, and over 1,800 contributors. Even with Rust's modern concurrency, a browser that handles dynamic scripting and modern web standards requires over 400,000 lines of engine code and hundreds of person-years.
- **Chromium / Blink (~5,000,000 LOC engine, >1,000,000 commits, >4,000 authors):** The commercial web extreme. Blink alone is roughly 50 times larger than Dillo, requiring tens of thousands of person-years of corporate maintenance.

---

## 4. Consequences for Cardinal Rule 2

The continuum settles the standing of Cardinal Rule 2 and confirms the specification's budget:

```
[Amfora]        [Blitz own]     [Dillo]        [Lagrange]      [NetSurf]       [Blitz tree]    [Servo]         [Chromium]
 6.8k LOC        36.1k LOC       60.9k LOC      92.1k LOC       126.2k LOC      209.4k LOC      415.3k LOC      5.0M+ LOC
 1 dev           1 dev           7 devs         1 dev           20 devs         assembled       201 devs        corporate
 40 mo           35 mo           141 mo         73 mo           274 mo          145 mo          176 mo          200+ mo
    |               |               |              |               |               |               |               |
    +---------------+---------------+--------------+---------------+---------------+---------------+---------------+
                    ▲                                              ▲
                    │                                              │
              Modular Assembly                                From Scratch
           (Crates: 1-2 years solo)                      (Custom: 1-2 years small team)
```

### 1. "Months" is Demonstrably False

Across the entire continuum, **not a single graphical engine was built in months**.
- Amfora took 40 months just to render text lines in a terminal.
- Lagrange took 73 months to render styled Gemini pages in SDL.
- Blitz required 35 months to author its 36k lines of glue code, even with layout, parsing, and style resolution already solved.
The specification's original pre-v0.3.2 phrasing ("months of work rather than years") was an error of 3× to 4×. Rejecting it was necessary: an implementation budget that contradicts every real-world project discredits the specification.

### 2. Confirmation of the Specification's §3.1 Budget

Section 3.1 states:
> *"This specification MUST remain small enough that a complete, conforming WebVeld browser stays within reach of a single developer or a small team working over a year or two, rather than requiring an organization working over a decade."*

The subject of that sentence matters and earlier revisions of this document got it wrong, paraphrasing the rule as *"a complete, conforming WebVeld browser MUST remain something a single developer can write."* That is the reading §3.1 explicitly corrected in 0.3.2: rule 2 constrains **this specification**, not any particular browser. An addition is priced as though the engine were being written from scratch, but a conforming browser MAY be built on an existing engine, and §2.4 asks only that the result behave correctly. The measurements below price the specification; they do not impose a construction method on any implementer.

The continuum confirms that this budget is neither fantasy nor trivial:
1. **Via Modular Assembly (The Blitz Path):** A single developer working for ~2 to 3 years (35 active months) can build a complete, highly conforming browser engine by composing modular crates (html5ever + Stylo + Taffy + Parley).
2. **From Scratch (The Pure Engine Path):** NetSurf spent 22 years and 20 core developers writing 126k lines of C because it had to implement CSS 2.1 floats, table quirks, complex box positioning, and historical HTML edge cases. WebVeld eliminates most of these: no floats, no positioning, no inline styles, no script runtime, and no CSS 2.1 table quirks. It does require block flow, flexbox, table layout, and the §6.2 bounded grid subset. A from-scratch WebVeld engine requires roughly 35,000–40,000 lines of code — achievable by a small team (2–3 developers) over 1 to 2 years. See §5.2 for the breakdown and for the two items in it that are estimated rather than measured.

The budget in §3.1 accurately defines the boundary between a document-oriented web (achievable by individuals and small teams) and the application web (requiring corporations).

---

## 5. The WebVeld-Shaped Subset on the Continuum

Section 1 and Section 2 measure the full Blitz tree at **209,391 LOC**. WebVeld forbids 2D/3D transforms, animations, filters, masks, container queries, custom properties, non-static positioning, floats, multi-column layout, `canvas`, `iframe`, inline `svg`, and client-side scripting (§4.4, §6.7), and it admits CSS Grid only as the bounded subset of §6.2.

Counting the entire Blitz tree therefore overstates what a WebVeld engine must contain, just as counting Blitz's custom crates alone (37,577 LOC) understates the full engine surface. By quantifying what WebVeld excludes component by component across the tree, we determine the conforming remainder and place both an assembled and a from-scratch WebVeld browser on the continuum.

> [!IMPORTANT]
> **Corrected 0.6.0.** Through 0.5.2 this section subtracted CSS Grid as excluded surface, citing a §6.7 exclusion that **0.4.0 lifted**. Grid has been mandatory since that release. The census below restores it, which raises the assembled remainder from the previously published ~168,800 to **~177,000** and the from-scratch estimate from ~30,000–35,000 to **~35,000–40,000**. Every figure quoted elsewhere in the repository has been updated to match. The methodology is unchanged; only the exclusion set was stale.

### 5.1 Excluded Surface Census

| Component | Full Code (`tokei`) | Excluded Surface | Excluded Code (`tokei`) | Conforming Remainder |
| :--- | ---: | :--- | ---: | ---: |
| **Blitz Crates** (`packages/`) | 37,577 | Boa JS, Dioxus glue, `iframe`, SVG, forbidden paint | **7,490** | 30,087 |
| **Taffy** (`taffy/src`) | 19,323 | Float layout only — grid is required | **483** | 18,840 |
| **Stylo** (`style` + `selectors`) | 112,716 | 436 excluded properties, transforms, anim, CQ, at-rules | **~24,400** | ~88,300 |
| **Parley** | 22,854 | *(None — 100% conforming typography)* | **0** | 22,854 |
| **html5ever** | 16,921 | *(None in assembled engine)* | **0** | 16,921 |
| **Total Assembled Tree** | **209,391** | | **~32,400** | **~177,000** |

1. **Blitz Crates: 7,490 LOC Excluded (19.9%).** Boa JS integration (`blitz-vibey-script`: 4,688 LOC) is already compiled out by default. Dioxus reactivity glue (`dioxus-native*`: 2,217 LOC) is unneeded for a static reader. `iframe` handling (141 LOC), inline SVG (123 LOC), and forbidden paint passes (321 LOC for filters, transforms, masks, and shadows) complete the excluded surface, leaving **30,087 LOC** in Blitz's conforming core.
2. **Taffy: 483 LOC Excluded (2.5%).** Only CSS float layout (`compute/float.rs`: 483 LOC) is excluded, by §6.7. The CSS Grid solver (`compute/grid/` and `style/grid.rs`: 6,991 LOC) **is required** and can no longer be compiled out behind Cargo `feature = "grid"`. This leaves an **18,840 LOC** conforming core (Grid 6,991 LOC, Flexbox 3,744 LOC, Block layout 1,326 LOC, Tree/cache 6,779 LOC).

   Note that §6.2 admits only a *bounded* grid subset, while Taffy is charged here at full price. That is deliberate and not a rounding error: Taffy's grid solver is not decomposable by feature, so an implementer who vendors it takes named areas, `auto-fill`/`auto-fit`, `fit-content()`, and dense packing whether the specification permits them or not. The assembled path therefore carries capability the specification does not grant. This costs nothing in correctness — a conforming browser MAY implement more than it must (§2.4) — but it means the assembled figure is an upper bound on what the specification obliges, not a measurement of it.
3. **Stylo: ~24,400 LOC Excluded (21.7%).** Stylo implements 523 properties; WebVeld §6.2 permits 87 (16.6%), excluding 436 properties (83.4%). Direct value parsing and at-rule modules account for 13,942 LOC (Transforms: 2,376; Animations/Transitions: 1,885; Filters/Masks: 502; SVG: 1,424; Custom Properties: 1,955; Container Queries: 2,639; Positioning insets: 2,555; Multi-column: 36; `@layer`/`@scope`: 570). Stylo's grid property parsing (1,068 LOC) is now **required** and no longer subtracted. Excluded shorthand parsers, cascade tables, computed style storage, and invalidation rules contribute ~10,500 LOC. The conforming Stylo core is **~88,300 LOC**.
4. **Parley & html5ever: 0 LOC Excluded.** Text shaping, BiDi, and font fallback (Parley: 22,854 LOC) are 100% required for conforming typography. HTML5 parsing and tokenization (html5ever: 16,921 LOC) are fully utilized.

### 5.2 The Two Honest Size Claims

Subtracting the ~32,400 lines of excluded surface yields a conforming WebVeld-shaped assembled remainder of **~177,000 LOC**. This clarifies the two legitimate implementation paths:

```
[Amfora]   [WebVeld Scratch] [Dillo]     [Lagrange]    [NetSurf]    [WebVeld Assembled] [Servo]       [Chromium]
 6.8k LOC   35k–40k LOC       60.9k LOC   92.1k LOC     126.2k LOC   ~177k LOC           415.3k LOC    5.0M+ LOC
 1 dev      small team        7 devs      1 dev         20 devs      1 dev + crates      201 devs      corporate
 40 mo      1-2 yrs           141 mo      73 mo         274 mo       35 mo custom        176 mo        200+ mo
    |            |               |           |             |                |               |             |
    +------------+---------------+-----------+-------------+----------------+---------------+-------------+
                 ▲                                                          ▲
                 │                                                          │
          From Scratch                                              Modular Assembly
    (Tailored engine: 1-2 yrs)                                (Vendored core: 30.1k custom)
```

1. **The Modular Assembly Path (~177k LOC assembled tree, ~30,100 LOC custom code):**
   An implementer who vendors existing production-grade crates inherits a conforming tree of ~177k LOC. However, the custom engineering surface that the developer actually writes and maintains is only Blitz's conforming core: **30,087 LOC**. SVG (123 LOC) is compiled out via a Cargo feature flag, JS is unreferenced, and `iframe`/paint patches are minor (< 500 LOC). Grid is no longer compiled out — it is inherited whole, at no cost in custom code. One developer working for 35 active months achieved full visual parity with Chromium within the Gecko noise floor.

   This is the path the correction favors. Grid moving from the excluded column to the required one adds ~8,000 lines to the vendored tree and **zero** lines to what the implementer writes, which is a fair summary of why modular assembly is the cheaper route for anyone starting today.

2. **The From-Scratch Engine Path (~35,000–40,000 LOC total engine):**
   Why is an assembled engine ~177k LOC while a from-scratch engine is only ~35k–40k LOC?
   Because Stylo and html5ever were architected for full-web engines (Firefox and Servo). Stylo's generic cascade, rule tree, style sharing cache, and typed computed values architecture carry immense infrastructure scaffolding even when 436 properties are unneeded.
   A from-scratch engine written specifically for WebVeld's normative subset does not need that scaffolding:
   - **Parser (~4,000 LOC):** Standard HTML5 tokenizer and simple tree builder without adoption agency algorithm error recovery (eliminated per §3.1).
   - **Style engine (~8,000 LOC):** Flat selector matching (no container queries, `@layer`, `@scope`), cascade sorting for 87 properties directly to layout styles (no `var()` or property registration; `calc()` is a single arithmetic pass over static lengths).
   - **Layout engine (~12,000–13,000 LOC):** Block flow, Flexbox, table layout, and the §6.2 bounded grid subset. No floats, no absolute or relative positioning, no CSS 2.1 legacy table quirks, no named areas, implicit tracks, `auto-flow`, `auto-fill`/`auto-fit`, `fit-content()`, or subgrid.
   - **Text shaping glue (~5,000 LOC):** Off-the-shelf HarfBuzz/rustybuzz and BiDi glue with simple line-breaker.
   - **DOM & Painting (~5,000–8,000 LOC):** Box tree, form controls, basic stacking context, rasterizer calls.
   - **Total from scratch:** **~35,000–40,000 LOC**.

   **Two caveats on the layout line, stated rather than buried.** Its grid increment is the one number here that is estimated rather than measured: Taffy prices *full* CSS Grid at 6,991 LOC, §6.2 admits perhaps two-thirds of that algorithm by weight, and nothing has yet implemented the bounded subset to report what it actually cost. And table layout has never been budgeted in this breakdown at all, despite §4.3 admitting ten table elements and §6.2 four table properties; there is no comparable crate to measure it against, because Taffy does not implement it. Both belong in the layout line, and the first implementation to attempt either should correct this figure the way 0.3.2 corrected its predecessor.

This estimate is anchored by Dillo (60.9k LOC) and NetSurf (126.2k LOC). Both spent the majority of their complexity on floats, positioning insets, legacy table formatting, inline style attributes, and CSS 2.1 quirks — all of which WebVeld forbids. Stripping those historical burdens brings a tailored WebVeld engine to ~35k–40k LOC, still comfortably below Dillo.

Both paths confirm Cardinal Rule 2: whether assembled from commodity crates (30.1k custom LOC) or written from scratch (35k–40k total LOC), a complete conforming WebVeld browser is within reach of a single developer or small team working over a year or two. The correction moved the figures without moving the conclusion — but the conclusion is worth less than the figures, and the figures are what an implementer checks.

---

## 6. Reproducing the Census

All metrics can be reproduced from clean checkouts in under two minutes:

```sh
# 1. Install tokei (standard code counter)
# Arch: pacman -S tokei | Cargo: cargo install tokei

# 2. Measure artifact size (pure source lines, excluding tests/benches/examples)
tokei -e tests -e benches -e examples -e wpt -e target path/to/repo

# 3. Measure specific component subsets (e.g. Taffy grid vs box)
tokei taffy/src/compute/grid taffy/src/style/grid.rs
tokei taffy/src/compute/float.rs

# 4. Measure development history via git log
# Total commits
git -C path/to/repo log --format=%ae | wc -l

# Core authors (>= 20 commits) and author concentration
git -C path/to/repo log --format=%ae | sort | uniq -c | sort -rn | awk '$1 >= 20 {core++} END {print "Core authors:", core+0}'
git -C path/to/repo log --format=%ae | sort | uniq -c | sort -rn | head -n 5

# Active calendar months
git -C path/to/repo log --format='%ad' --date=format:%Y-%m | sort -u | wc -l

# Historical date span
git -C path/to/repo log --max-parents=0 --format=%ad --date=short   # first commit
git -C path/to/repo log -n 1 --format=%ad --date=short             # latest commit
```
