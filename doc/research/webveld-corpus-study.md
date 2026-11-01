# What Minimalist Sites Actually Use

**Against:** [webveld-spec.md](../webveld-spec.md) v0.5.2 · **Status:** Informative · **Run:** 2026-09-08 · **Sample:** 103 sites · **Corpus fingerprint:** `cbd19335ae5584c8`

WebVeld's layout rules were chosen from first principles: flexbox in, floats and positioning out. The one existing minimal browser, Dillo, implements the opposite — floats and positioning, no flexbox — but its engine predates flexbox, so its choice is evidence about 2005 rather than about cost ([dillo-assessment.md](dillo-assessment.md) §2).

This study asks the empirical question instead: what do the sites WebVeld is aimed at actually use? Tooling to re-run it is in [`tools/corpus-study/`](../../tools/corpus-study/).

Every figure below comes from the snapshot named in the header. `tools/corpus-study/snapshot.sh verify 2026-09-08` re-hashes it, so any number here can be traced to the bytes it was computed from. That matters because the alternative is indistinguishable from noise: a revised figure could mean a corrected script or a changed population, and without a fingerprint nothing says which.

A first run on 2026-09-07 predates snapshotting and its population cannot be recovered. Where its numbers differed materially they are noted; nothing it concluded was overturned, which is the most that can be said for it.

## Method

113 home pages were attempted and 103 fetched, along with up to three linked style sheets each, and the combined CSS and HTML tested with regular expressions for each feature. Three cohorts, chosen so that ideology and cost can be told apart:

- **A — size-budget web (n=67).** Members of 512kb.club: sites that have committed to a page-weight budget. This is WebVeld's most likely constituency.
- **B — lite and text-only (n=21).** Curated minimal sites, including publisher text-only editions such as `lite.cnn.com` and `text.npr.org`.
- **C — modern comparison (n=15).** Lightweight developer and documentation sites built with current tooling, plus a few conventional ones, as a control for what "normal modern" looks like.

Median page size: 11.9 KB (A), 4.7 KB (B), 22.0 KB (C).

## The hypothesis this was meant to test

The suspicion going in was that the small web might use retro CSS because "new" is associated with bloat — in which case its float usage would reflect taste, not cost, and would be worthless as evidence for WebVeld's layout model.

**The data does not support that hypothesis.** In the size-budget cohort, flexbox appears on 64% of sites and floats on 37%; grid, the newest and heaviest layout model, appears on 33%, roughly matching floats. Only 12% of cohort A use floats as their primary layout mechanism. These sites are not retro. They use modern CSS and keep the *weight* down — which is a different discipline, and a more interesting one.

## Results

Percentage of sites in which each feature was detected.

| Feature | A (n=67) | B (n=21) | C (n=15) | All |
| --- | --- | --- | --- | --- |
| `meta viewport` | 87% | 76% | 93% | 85% |
| Media queries | 78% | 76% | 93% | 80% |
| `position: absolute\|fixed\|sticky` | 67% | 62% | 73% | 67% |
| Any `<script>` | 70% | 67% | 73% | 70% |
| `border-radius` | 58% | 71% | 80% | 64% |
| Flexbox | 64% | 38% | 87% | 62% |
| Transitions, animations, transforms | 60% | 71% | 67% | 63% |
| CSS custom properties | 60% | 33% | 67% | 55% |
| `box-sizing` | 54% | 48% | 67% | 54% |
| Floats | 37% | 33% | 80% | 43% |
| `gap` | 42% | 19% | 53% | 39% |
| ARIA attributes or `role` | 46% | 10% | 47% | 39% |
| `@font-face` | 36% | 52% | 27% | 38% |
| Inline `<svg>` | 37% | 10% | 60% | 35% |
| CSS grid | 33% | 19% | 53% | 33% |
| `prefers-color-scheme` | 25% | 24% | 47% | 28% |
| `:checked` | 25% | 33% | 27% | 27% |
| `loading="lazy"` | 13% | 0% | 33% | 14% |
| Checkbox hack (`:checked ~` or `+`) | 15% | 5% | 13% | 13% |
| `<table>` | 9% | 24% | 0% | 11% |
| `srcset` | 7% | 5% | 33% | 11% |
| `<details>` | 10% | 0% | 13% | 9% |
| Google Fonts | 7% | 0% | 0% | 5% |

Primary layout model, assigned by precedence (grid, then flex, then float, then none):

| Primary model | A | B | C | All |
| --- | --- | --- | --- | --- |
| Grid | 33% | 19% | 53% | 33% |
| Flexbox | 31% | 24% | 33% | 30% |
| Floats | 12% | 24% | 13% | 15% |
| Normal flow only | 24% | 33% | 0% | 22% |

Grid's row repeats its detection figure exactly, because the precedence rule assigns grid first: any site touching grid at all is counted grid-primary. Read it as "uses grid", not as "is laid out by grid".

## Floats: who uses them, and for what

Floats appear on 44 of the 103 sites, in 191 distinct rules. Binning those rules by selector name:

| Bin | Rules | Share |
| --- | --- | --- |
| Layout containers (`nav`, `header`, `sidebar`, `col`, `left`, `right`, …) | 82 | 43% |
| Unclassified | 73 | 38% |
| Figures (`img`, `figure`, `photo`, `thumb`, `logo`, `aside`, pull quotes) | 29 | 15% |
| Clearfix | 7 | 4% |

And floats are usually a supplement rather than a foundation: of 25 float-using sites in cohort A, 17 also use flexbox. In cohort C, 10 of 12 do.

Treat the 15% figure share as a floor, not an estimate. Utility classes named `.left` and `.right` are frequently applied to images inside article text, and this classifier counts those as layout. The unclassified 40% is large enough that the real figure share could be double.

## Grid: which bounded subset would actually serve anyone

Detecting grid answers "is it used". It does not answer the question the roadmap needs, which is whether a *subset* of grid would serve the people using it — a subset most grid users could not adopt would buy far less than 33% suggests. [webveld-roadmap.md](../webveld-roadmap.md) defines four tiers under "Bounded CSS grid subset", each adding one identifiable algorithm to the one below, and `classify-grid.lua` assigns each grid-using site to the lowest tier that covers its usage.

34 of the 103 sites use grid: 22 in A, 4 in B, 8 in C.

| Subset drawn at | A | B | C | All |
| --- | ---: | ---: | ---: | ---: |
| **T0** — fixed tracks, literal `repeat()`, explicit line placement | 18% | 0% | 0% | 12% |
| **T0–T1** — adds row auto-placement | 36% | 50% | 25% | 35% |
| **T0–T2** — adds `minmax()` and the intrinsic keywords | 59% | 75% | 50% | 59% |
| **T0–T3** — adds `auto-fill` / `auto-fit` | 86% | 100% | 62% | 82% |

Which features the 34 grid users actually reach for:

| Feature | A (n=22) | B (n=4) | C (n=8) | All (n=34) |
| --- | ---: | ---: | ---: | ---: |
| No explicit placement — items are auto-flowed | 59% | 100% | 50% | 62% |
| `minmax()` | 50% | 25% | 38% | 44% |
| Explicit line placement | 41% | 0% | 50% | 38% |
| `auto`, `min-content`, `max-content` tracks | 23% | 25% | 38% | 26% |
| `repeat(auto-fill \| auto-fit, …)` | 27% | 25% | 12% | 24% |
| `grid-template-areas` | 9% | 0% | 12% | 9% |
| `grid-auto-rows` / `grid-auto-columns` | 5% | 0% | 12% | 6% |
| `dense` or column flow | 0% | 0% | 12% | 3% |
| `fit-content()` | 0% | 0% | 12% | 3% |
| `subgrid` | 0% | 0% | 0% | 0% |

Three things follow.

**T0 is not worth having.** The roadmap's original proposal — fixed tracks with every item explicitly placed — covers 18% of grid users in the target cohort and 12% overall. It is the cheapest tier by a wide margin and it serves almost nobody, which is the worst combination available.

**`minmax()` is the single most-used grid feature, at 50% of cohort A** — ahead of explicit placement, ahead of `auto-fill`. It is also the expensive one, because it is what drags in intrinsic track sizing. The cheapest large gain and the largest cost increment are the same rung, which is the whole difficulty in one number.

**Nobody needs full grid.** Only 18% of grid usage falls outside all four tiers, and it is concentrated in features that are genuinely rare: named areas at 9%, implicit tracks at 6%, dense packing and `fit-content()` at 3%, subgrid at 0%. Whatever line is drawn, it does not have to be drawn at "all of CSS Grid".

## Findings

1. **Flexbox is the right choice, and the corpus is decisive about it.** In the population WebVeld targets, flexbox outnumbers floats 64% to 37%, and float-primary sites are 12%. Aligning the spec with Dillo's float model would have matched roughly one site in eight against the majority. This is the answer to the question the study was run for.
2. **Floats have a real but secondary role.** Seventeen of cohort A's 25 float users also use flexbox, so floats are supplementing rather than structuring. That is exactly the shape of the "floats for figures" proposal — though the selector analysis is too crude to prove that figure wrapping is what most of them do.
3. **`meta viewport` at 85% is the strongest single confirmation in the study.** WebVeld initially forbade it in 0.2.0, scored it highest on the roadmap, and adopted it in 0.3.0 (spec §5.2). Nothing else validated so cleanly.
4. **Positioning is the largest gap between the spec and practice.** `position: absolute|fixed|sticky` appears on 67% of sites, more than flexbox — and WebVeld forbids all of it. It is not currently a roadmap candidate. Animations and transforms are a similar case at 63%, though more plausibly cosmetic.
5. **Custom properties are mainstream even at 512 KB** — 60% in cohort A, well ahead of floats. The roadmap's assessment that this is the strongest gated candidate on author value holds up.
6. **`<details>` demand is weak, and the workaround outnumbers it.** 10% in cohort A and 0% in B, against 15% for the checkbox hack in the same cohort. Since `:checked` was adopted in 0.3.0, authors already have a scriptless disclosure primitive and more of them use it — so the case for `details` rests on the accessibility semantics the hack cannot provide, not on demand.
7. **`srcset` at 7% and `loading="lazy"` at 13% confirm their low ranking.** The population that most needs bandwidth savings is largely not using either.
8. **The font rule is validated precisely.** 36-52% of sites use `@font-face`, while only 5-7% touch Google Fonts. Minimal sites want custom typefaces and already self-host them, which is exactly the line spec §6.5 draws — permit the capability, forbid the third-party request.
9. **Extended documents are the norm, not the exception.** 70% of these sites carry a `<script>` element, even in the size-budget cohort. A conformance indicator that shows most of the small web as "extended" is reporting accurately, and spec §11's escape hatch is a main road rather than a side door.
10. **A real WebVeld-shaped population exists.** In cohort A, 20 of 67 sites use no script at all; 11 use no script, no flexbox, and no grid; 7 add no positioning either. Cohort B is denser still by proportion — 7 of 21, 5, and 4. These sites would be close to conforming today.
11. **A grid subset has to reach T2 to be worth adopting.** T0 serves 18% of cohort A's grid users and T1 serves 36%, while T2 — which adds the intrinsic track sizing the roadmap was right to be wary of — reaches 59%. The cheap tiers are the ones nobody can use.

## Limitations

- **Regex detection over raw CSS.** No cascade evaluation, no dead-rule elimination. A framework's stylesheet may declare `float` in rules the site never triggers, so usage is systematically over-counted, most likely for legacy properties.
- **Home pages only, one page per site.** Article pages are where figure floats would appear, which probably under-counts exactly the case finding 2 concerns.
- **Up to three style sheets per site.** Sites splitting CSS across more files are partly measured.
- **512kb.club is a self-selected list** whose membership criterion is page weight, not authoring philosophy. It is the best available proxy for WebVeld's constituency, not a random sample of the small web.
- **Cohort C is small (n=15) and hand-picked**, useful as a directional control only.
- **Detection cannot see purpose.** That flexbox is present says nothing about whether the layout needed it.
- **The grid tiers are an upper bound.** `classify-grid.lua` errs toward a higher tier: a `minmax()` anywhere in a stylesheet moves the site to T2 even if the rule containing it never matches. Read the coverage figures as the most a subset would have to include, not the least.
- **The 2026-09-07 run is not reproducible.** It predates snapshotting, so where this run differs there is no way to tell drift from correction. Everything from this run forward is fingerprinted.

## What changed as a result

- Flexbox stays as WebVeld's layout model; the question is closed on evidence rather than on Dillo's precedent.
- Floats for figures added to the roadmap as a scored candidate.
- `<details>` author and reader scores lowered; static ARIA author score raised, on the strength of findings 6 and 8.
- Positioning recorded as the largest unaddressed gap between the specification and observed practice.
- The roadmap's bounded grid subset scored against measured coverage: Tier 2 (T2) covers 59% of grid usage in the size-budget cohort, supporting explicit track sizing and placement while bounding engine complexity. Native `<details>` and `<summary>` disclosure elements are supported on the strength of finding 6.
- Every run from 2026-09-08 forward carries a corpus fingerprint, so a revised figure can be attributed to a corrected script or to a changed population.

## Related measurements

This document measures finished pages. [dillo-assessment.md](dillo-assessment.md) measures a browser's existing implementation, and [luasmith-assessment.md](luasmith-assessment.md) measures a static site generator's default output — a third angle on the same underlying question, since a generator's templates are themselves a compressed statement of what its authors consider normal minimalist HTML. Read together, the three are meant to catch a gap that any one alone would read as noise: a construct several independently-built minimalist tools rely on, that WebVeld's allowed-element or allowed-property lists happen to exclude.

A fourth document, [minimalist-ssg-audit-review.md](minimalist-ssg-audit-review.md), reviews a secondary-source survey of the minimalist SSG landscape rather than adding a fourth independent measurement — but it surfaced the same kind of gap the other three exist to catch: the CSS checkbox hack, arguably the single most common no-JavaScript interactivity idiom, depends on `:checked`, supported in §6.3.
