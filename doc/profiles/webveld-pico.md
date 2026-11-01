# WebVeld-Pico Profile

**Version:** 0.8.0 · **Status:** Normative (restriction profile) · **Date:** 2026-10-31  
**Restricts:** [webveld-spec.md](../webveld-spec.md) >= 0.8.0

WebVeld has three profiles: full [`webveld`](../webveld-spec.md), styled [`webveld-nano`](webveld-nano.md), and semantic [`webveld-pico`](webveld-pico.md).

`webveld-pico` is the most restrictive profile: semantic text and hyperlinks, nothing else. It has the scope of Gemini's gemtext, in standard HTML5 over HTTP, for terminal clients, e-ink readers, screen readers, slow networks, and long-term archives. As a rough guide, a `webveld-pico` reader is about 10,000 lines of engine code.

## How this profile works

**A `webveld-pico` document is a conforming WebVeld document that also satisfies the restrictions below.** This profile only removes. It adds nothing the specification does not already permit, and it redefines nothing. So:

1. Every `webveld-pico` document is a `webveld-nano` document and a conforming WebVeld document.
2. Every conforming WebVeld browser renders every `webveld-pico` document correctly.

Anything not restricted here is governed by the specification unchanged, including the cardinal rules (§3.1), encoding (§4.2), URL schemes (§7.1), transport (§7.5), security (§8), accessibility (§9), and versioning (§2.7).

## Restrictions

### R1. Elements

| Category | Elements |
| --- | --- |
| Metadata | `html`, `head`, `body`, `title`, `meta` |
| Headings | `h1`, `h2`, `h3`, `h4`, `h5`, `h6` |
| Grouping | `p`, `ul`, `ol`, `li`, `blockquote`, `pre`, `hr` |
| Text-level | `a`, `code` |

Every other element in §4.3 is excluded, including `link`, `style`, `img`, `div`, `span`, all sectioning elements, tables, forms, and `details`/`summary`.

**Content outside the profile.** A `webveld-pico` browser MAY render elements outside this profile however it can. It SHOULD keep their text readable, and MUST NOT display the contents of `style`, `script`, or `template`. This is what lets a reader open a full WebVeld page in a pico browser and still read it, though without its intended layout.

### R2. Attributes

| Scope | Attributes |
| --- | --- |
| Global | `lang`, `id` |
| `meta` | `charset` (only `utf-8`); or `name` (only `viewport`) with `content` (only `width=device-width, initial-scale=1`) |
| `a` | `href` (REQUIRED), `title` |

Every other attribute in §5 is excluded, including `class`, `dir`, `tabindex`, and the WAI-ARIA set. `id` is kept so that fragment links (`href="#section"`, §7.1) and tables of contents work.

The viewport declaration is admitted because without it, mainstream phone browsers lay a page out at desktop width and shrink it, so pico text would be tiny on phones. A pico browser already wraps text to its screen and can ignore it. It changes nothing about the content.

### R3. Style sheets

Author style sheets are excluded entirely: `<link rel="stylesheet">`, `<style>`, and the `style` attribute MUST NOT appear, and §6 does not apply. Documents render with the browser's default styles or the reader's own theme.

A browser MUST still draw a visible focus indicator on links (§9). In a terminal, the platform's cursor or cell inversion is enough.

### R4. Subresources

A `webveld-pico` document makes **no subresource requests**: no images, style sheets, fonts, or icons. Links are the only network feature, and they do nothing until the reader follows one. This removes the need for an image decoder, font loading, or a fetch queue.

## Implementation notes

- **Engine size:** roughly 10,000 lines of engine code.
- **Layout:** a single pass of text with word wrapping. No cascade, box model, or intrinsic sizing.
- **Reference point:** Amfora, a terminal Gemini client ([implementability-continuum.md](../research/implementability-continuum.md)), is of similar size. Parsing HTML is more work than parsing gemtext, but this profile removes everything else.
