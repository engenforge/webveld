# WebVeld-Nano Profile

**Version:** 0.8.2 · **Status:** Normative (restriction profile) · **Date:** 2026-10-31  
**Restricts:** [webveld-spec.md](../webveld-spec.md) >= 0.8.0

WebVeld has three profiles: full [`webveld`](../webveld-spec.md), styled [`webveld-nano`](webveld-nano.md), and semantic [`webveld-pico`](webveld-pico.md).

`webveld-nano` is the profile for styled documents: essays, blogs, and articles that want visual identity (typography, colors, images) without requiring a browser to implement flexbox, grid, tables, or forms. As a rough guide, a `webveld-nano` reader is about 20,000 lines of engine code.

## How this profile works

**A `webveld-nano` document is a conforming WebVeld document that also satisfies the restrictions below.** This profile only removes. It adds nothing the specification does not already permit, and it redefines nothing. So:

1. Every `webveld-nano` document is a conforming WebVeld document, and every [`webveld-pico`](webveld-pico.md) document is a `webveld-nano` document.
2. Every conforming WebVeld browser renders every `webveld-nano` document correctly.

Anything not restricted here is governed by the specification unchanged, including the CSS value grammar, units (§6.4), color notations, and `calc()`.

## Restrictions

### R1. Elements

| Category | Elements |
| --- | --- |
| Metadata | `html`, `head`, `body`, `title`, `meta`, `link`, `style` |
| Sectioning | `header`, `main` (max. one per document), `footer`, `nav`, `article`, `section`, `aside` |
| Headings | `h1`, `h2`, `h3`, `h4`, `h5`, `h6` |
| Grouping | `p`, `ul`, `ol`, `li`, `blockquote`, `pre`, `figure`, `figcaption`, `hr`, `div` |
| Text-level | `a`, `strong`, `em`, `i`, `b`, `u`, `code`, `kbd`, `samp`, `var`, `abbr`, `cite` |
| Text-level (continued) | `q`, `mark`, `small`, `sub`, `sup`, `del`, `ins`, `time`, `br`, `span` |
| Embedded | `img` |

Excluded from §4.3: all table elements, all form elements, `details`/`summary`, `dl`/`dt`/`dd`, `dfn`, `wbr`, and `noscript`.

Sectioning elements are kept: they render like `div` but give screen reader users landmarks (`banner`, `navigation`, `main`, `contentinfo`) at no layout cost.

### R2. Attributes

| Scope | Attributes |
| --- | --- |
| Global | `lang`, `id`, `class`, `dir`, `title` |
| Global (ARIA) | `role`, `aria-label`, `aria-labelledby`, `aria-describedby`, `aria-hidden`, `aria-expanded`, `aria-controls` |
| `meta` | `charset` (only `utf-8`); or `name`/`property` with `content` per §5.2 |
| `link` | `rel` (only `stylesheet`, `icon`, or `alternate`), `href` (REQUIRED), `type` |
| `a` | `href` (REQUIRED), `rel`, `hreflang` |
| `img` | `src` (REQUIRED), `alt` (REQUIRED), `width`, `height` |
| `ol` | `start`, `reversed` |
| `blockquote`, `q` | `cite` |
| `abbr` | `title` |
| `del`, `ins` | `datetime`, `cite` |
| `time` | `datetime` |
| `code` | `data-lang` |

Excluded: `tabindex`, and every form and table attribute.

`rel="icon"` is for a PNG site icon (§7.4), and `rel="alternate"` with `type` is for feed autodiscovery. `tabindex` is excluded because R3 excludes `overflow`, so there are no scrollable regions to make focusable.

### R3. Style sheets

Author CSS is permitted via `<link rel="stylesheet">` and `<style>` (§6.1). Inline `style` and author `!important` remain forbidden.

**Properties** are restricted to the following subset of §6.2. Each keeps the values §6.2 assigns it, with one exception named in the list:

- **Box model:** `margin` and its four longhands, `padding` and its four longhands, `width`, `max-width`, `min-width`, `height`, `border` and its `-width`/`-style`/`-color` longhands, the four per-side `border-*` shorthands, `border-radius`, `box-sizing`, `outline` and its longhands, `outline-offset`
- **Typography:** `font-family`, `font-size`, `font-weight`, `font-style`, `line-height`, `text-align`, `text-decoration`, `text-transform`, `letter-spacing`, `word-spacing`, `white-space`, `overflow-wrap`, `word-break`
- **Color:** `color`, `background-color`, `opacity`
- **Lists:** `list-style`, `list-style-type`, `list-style-position`
- **Display:** `display`, **narrowed to the single value `none`**

Excluded from §6.2: `display` values other than `none`, all flexbox and grid properties, `gap`, `order`, all table properties, `background-image` and related properties, `overflow`, `content`, `cursor`, `vertical-align`, `clip-path`, `max-height`, and `min-height`.

**Selectors** are restricted to type, class, ID, and universal selectors; descendant and child combinators; selector lists; and the single pseudo-class **`:focus`**, so authors can style focus indicators (§9). Excluded from §6.3: sibling combinators, attribute selectors, every other pseudo-class, and every pseudo-element.

**At-rules** are restricted to `@media` with the single condition **`prefers-color-scheme`** (`light` or `dark`). `@font-face` is excluded, so fonts are system fonts named in `font-family`. Width-based media queries are excluded so that layout never depends on viewport-driven style changes.

**Focus.** §9 still applies: a document that removes the focus outline in a `:focus` rule must replace it with another visible indicator, such as a `background-color`, `border`, or `color` change.

**Skip links.** Use a visible skip link (`<a href="#content">Skip to content</a>`) at the top of the page. The hidden-until-focused technique in spec Appendix A.5 needs `overflow` and `clip-path`, which this profile excludes.

**Wide preformatted text.** Without `overflow`, a code block cannot scroll by itself. Spec Appendix A.6 gives the recommended technique.

### R4. Subresources

Style sheets, images, and a site icon only, under §7.2's same-origin rule. Images are PNG or JPEG and the icon is PNG (§7.4); inline `data:` image URLs are permitted (§7.1). No web fonts.

## Implementation notes

- **Engine size:** roughly 20,000 lines of engine code.
- **Layout:** block and inline flow with images. No flexbox, grid, table layout, or form controls, and no width-based media queries.
- **Reference point:** Lagrange, a graphical Gemini client ([implementability-continuum.md](../research/implementability-continuum.md)), is much larger, mostly because of features this profile leaves to the platform.
- Even linear flow needs intrinsic sizing, margin collapsing, and image sizing; budget for them.
