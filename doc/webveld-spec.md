# WebVeld Specification

**Version:** 0.10.1 · **Status:** Normative · **Date:** 2026-10-31

WebVeld is a family of minimal subsets of HTML5 and CSS for documents that look the same in a purpose-built minimalist browser and in any modern web browser, with no plugins, polyfills, or scripts.

This document is normative and self-contained: it defines what a conforming WebVeld document and a conforming WebVeld browser are, and it is the only authority on conformance. The companion documents are informative: the motivation in [webveld-motivation.md](webveld-motivation.md), implementation guidance in [webveld-implementation.md](webveld-implementation.md), future candidates in [webveld-roadmap.md](webveld-roadmap.md), and a survey of related efforts in [webveld-related-work.md](webveld-related-work.md).

WebVeld has **three profiles**:

1. [**`webveld`**](webveld-spec.md) (full) — defined by this document. Flexbox, a bounded CSS grid subset, tables, accessible forms, `details`/`summary` disclosure, media queries, and self-hosted fonts.
2. [**`webveld-nano`**](profiles/webveld-nano.md) (styled documents) — for essays, blogs, and articles that want visual identity: linear-flow box model, typography, colors, same-origin PNG/JPEG images, and light/dark color schemes. No flexbox, grid, tables, or forms.
3. [**`webveld-pico`**](profiles/webveld-pico.md) (semantic hypertext) — headings, paragraphs, lists, quotes, preformatted text, and links. No author style sheets and no subresources. The scope of Gemini's gemtext, in standard HTML5.

The profiles nest: `webveld-pico` ⊂ `webveld-nano` ⊂ `webveld`. A narrower profile only removes features from this specification; it never adds syntax and never redefines behavior. So every `webveld-pico` document is also a `webveld-nano` and `webveld` document, and every conforming `webveld` browser renders all three.

- **Publishers:** if unsure, choose `webveld`. Choose `webveld-nano` or `webveld-pico` if you don't need the extra features and want your pages to render exactly as intended in the smallest browsers.
- **Browser developers:** each profile is a useful place to stop. As a rough guide, a `webveld-pico` reader is about 10,000 lines of engine code, a `webveld-nano` reader about 20,000, and a full `webveld` browser about 40,000 (§3.1).

---

## 1. Scope

WebVeld defines:

- A subset of HTML5 elements and attributes (§§4 and 5).
- A subset of CSS properties, selectors, and units (§6).
- Resource, transport, security, and accessibility requirements (§§7–9).
- Optional delegation of non-document content to external applications (§10).

WebVeld does not define a new markup language, a new transport protocol, or a new URL scheme. Every construct in this specification is standard HTML5, CSS, and HTTP. A WebVeld document is an ordinary web page that stays inside a small, verifiable boundary.

What this version leaves out, and why, is recorded in [webveld-motivation.md](webveld-motivation.md) §7. Candidates for future versions are in [webveld-roadmap.md](webveld-roadmap.md).

## 2. Conformance

### 2.1 Requirement keywords

The key words MUST, MUST NOT, REQUIRED, SHALL, SHALL NOT, SHOULD, SHOULD NOT, RECOMMENDED, MAY, and OPTIONAL in this document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174) when, and only when, they appear in all capitals.

### 2.2 Normative and informative content

§§1–11 are normative. Appendices are informative: they illustrate the normative text and never extend or override it.

### 2.3 Conforming document

A document conforms to WebVeld if all of the following hold:

1. It is valid HTML5.
2. It uses ONLY the elements listed in §4.3 and the attributes listed in §5.
3. It uses ONLY the CSS properties, selectors, units, and at-rules listed in §6.
4. Author style sheets contain no `!important` declarations (§6.1).
5. It is encoded in UTF-8 and declares that encoding (§4.2).
6. It contains no client-side scripting of any kind (no JavaScript, no WebAssembly).
7. It contains no `noscript` element (§4.3; `noscript` is for extended documents only).
8. Form controls comply with the labeling requirements of §9.
9. Form `pattern` attributes contain no lookahead, lookbehind, or backreference regular expression constructs (§5.2).
10. Any form containing a password field specifies an action that resolves to an `https://` URL (§5.2).
11. Every `img` element carries an `alt` attribute (§§5.2, 9).
12. All web fonts declared via `@font-face` resolve to the document's own origin and do not use `local()` (§6.5).
13. Style sheets contain no `url()` values inside `@media` query blocks (§6.6).
14. Its URLs use only the schemes §7.1 permits for their position: `http://`, `https://`, or an image `data:` URL for a subresource; `http://` or `https://` for a form `action`; and for an `a href`, any registered scheme except `javascript:`, `vbscript:`, `data:`, and `file:`.
15. All embedded subresources (style sheets, images, fonts) are same-origin with the document or inline `data:` image URLs (§7.2).
16. Images are PNG or JPEG, and a site icon (`<link rel="icon">`) is PNG (§7.4).
17. It satisfies the accessibility requirements of §9.
18. Grid track lists stay within the size bound of §6.2: no `repeat()` count and no resolved explicit track count exceeds 10,000.
19. It satisfies every other document requirement in this specification.

### 2.4 Conforming browser

A browser conforms to WebVeld if all of the following hold:

1. It correctly renders every element listed in §4.3.
2. It correctly applies every CSS property, selector, unit, and at-rule listed in §6.
3. It ignores or strips elements, attributes, and properties that this specification forbids, without failing to render the rest of the document.
4. It submits forms using GET and POST.
5. It resolves links and performs navigation. Browsers MUST permit cross-origin navigation initiated by reader actions (§7.3).
6. It decodes documents as UTF-8.
7. It executes no client-side code under any circumstance.
8. It renders the contents of `noscript` as ordinary document content whenever encountered (§§4.3, 11).
9. It supports HTTPS and verifies transport security (§8).
10. It refuses to submit a form containing a password field over plain HTTP (§5.2).
11. It refuses every cross-origin subresource request: style sheets, images, and fonts (§7.2).
12. It re-evaluates media conditions when the viewport is resized or system preferences change (§6.6).
13. Its resource fetching does not depend on dynamic reader or device properties (§7.2).
14. It decodes PNG and JPEG image formats (§7.4).
15. It satisfies every other browser requirement in this specification.

A conforming browser MAY additionally implement external application handlers (§10). A browser that surfaces a conformance indicator SHOULD show the specification version it targets (e.g. "WebVeld 0.10") in its chrome (§2.6). Nothing in this list requires a browser to recover from malformed or non-conforming input; see §3.1.

### 2.5 Extended documents

An *extended document* is a document that satisfies all three of the following:

1. It contains at least one `script` element.
2. It contains a `noscript` element whose content satisfies §§4–9 — that is, the content a WebVeld browser will render is itself WebVeld content.
3. Removing its `script` and `noscript` elements leaves a document that satisfies §2.3.

Extended documents are NOT WebVeld-conforming, but they remain usable and legible in a WebVeld browser, and §11 states the requirements that apply to them.

Clause 3 stops a page with a clean `noscript` fallback from hiding, say, a third-party font in its `head`. An extended document differs from a conforming one only by its scripting.

### 2.6 Validation

Conformance is machine-checkable in two passes:

1. A standard HTML5 validator, for structural validity.
2. A WebVeld validator, for subset conformance (§§4–9).

A reference validator is a deliverable of this project.

A browser MAY show the result of the second pass while browsing, and is encouraged to: it already parses everything the validator inspects, so the check is nearly free. Where a browser does so, the following apply.

The result MUST be reported as one of three states, never as a score. A document with five hundred conforming elements and one `script` is not "99.8% conforming"; it is an extended document, which is a different kind of thing.

1. **Conforming** — the document satisfies all requirements of §2.3.
2. **Extended** — the document satisfies §2.5: it carries scripting, it carries a `noscript` whose content conforms, and it is otherwise a conforming document. This is the progressive enhancement escape hatch working as designed and MUST NOT be presented as an error.
3. **Non-conforming** — everything else.

All three are decidable from the document alone. A browser reaches state 2 by removing the `script` and `noscript` elements, running the §2.3 check over what remains, and running the §§4–9 checks over the `noscript` content.

State 3 is the most common result. Most of the web carries a script and no `noscript`, and many of those pages are still complete and readable. **The indicator MUST NOT state or imply that the reader is missing content unless the document gives grounds to believe it.** "This document does not conform" is true of all of them; "you may not be seeing everything" is true of very few, and an indicator that cries wolf teaches readers to ignore it. The reasons belong in the detailed view below.

A browser SHOULD offer a detailed view listing each violation with its element, its location in the source, and the section of this specification it departs from.

Two requirements protect the reader. The indicator MUST be drawn in browser chrome that page content cannot influence or imitate, since a conformance claim a page can forge is worse than none. And validation MUST be performed locally: a browser MUST NOT transmit the document, its URL, or any digest of either to a validation service.

### 2.7 Versioning

This specification uses Semantic Versioning 2.0.0, where the "public API" is the set of documents and browsers that conform to it:

- **MAJOR** — a breaking change: removing an allowed element, attribute, property, or value; adding a restriction that makes conforming documents non-conforming; or breaking a core browser requirement such as baseline security behavior.
- **MINOR** — a backward-compatible addition: a newly allowed element, attribute, property, or value, or a new baseline requirement for browsers (such as decoding another image format). Documents written to X.Y.Z stay conforming in X.(Y+1).0. A browser that conforms to X.Y.Z still renders every document written up to X.Y.Z; to claim the newer version, its implementer updates it.
- **PATCH** — editorial changes, clarifications, and corrections that do not change conformance.

Versions below 1.0.0 are drafts; any release MAY change conformance until 1.0.0 is published. Every change requires a new tag under the rules above.

**Profiles version independently of this specification.** A profile ([`profiles/`](profiles/)) is a separate normative document with its own version, and it declares the minimum specification version it restricts:

```
webveld-nano 0.8.0 · restricts webveld >= 0.8.0
```

A profile's version follows the same three categories:

- **MAJOR** — the profile removes something it previously admitted. Documents break.
- **MINOR** — the profile admits something it previously removed. Documents stay conforming, but browsers that implement the profile must be updated. Relaxing a profile is a new obligation on every engine that implements it.
- **PATCH** — editorial.

Because a profile lists what it permits, a MINOR here that adds an element, attribute, or property does not enter a profile by itself; admitting it is a separate profile MINOR. **A MINOR here that adds a *value* does enter every profile** that admits the property or attribute and does not narrow its values. For example, `webveld-nano` permits `width` without narrowing it, so it admitted `max-content` when this specification did (§6.2).

Advancing this specification from draft status to **1.0.0** is governed by explicit exit criteria (implementer proof, author proof, and stability commitment) defined in [webveld-roadmap.md](webveld-roadmap.md).

## 3. Design principles

### 3.1 Cardinal rules

Three rules govern WebVeld. They produced every constraint in this specification, and they are the test that any proposed change must pass.

1. **Parity** — A WebVeld document MUST look the same in a WebVeld browser and in an unmodified modern web browser, with no plugin, polyfill, or script. WebVeld is a subset of the existing web, never a fork of it.
2. **Implementability** — This specification MUST stay small enough that one developer or a small team can build a complete, conforming browser. As a rough guide, that is about 40,000 lines of engine code (parsing, style, layout, and rendering), not counting standard libraries for TLS, image decoding, fonts, and windowing. Every addition is charged against this budget.
3. **Privacy and safety of the reader** — These take precedence over the convenience of authors, designers, and implementers. A capability that creates a tracking signal, a code-execution path, or a new class of untrusted parsing is not adopted.

No exclusion is permanent. A capability is absent because no known design for it satisfies all three rules, and any capability that does MAY be adopted in a future version. The rationale for each exclusion is in [webveld-motivation.md](webveld-motivation.md) §7.

**WebVeld restricts syntax and never redefines behavior.** A version MAY narrow what a document can use (fewer elements, properties, or values), because a document inside the narrower set is still an ordinary web page. It MUST NOT change what an allowed construct means. A redefinition doesn't announce itself: the document still renders in both browsers, just differently, which is the worst way for rule 1 to fail.

**What parity means.** The reader gets the same content, structure, and meaning, and the two renderings are visually identical in the sense that a reader would struggle to tell them apart. Parity does not mean identical pixels: browsers differ in default fonts, form control chrome, scrollbars, and focus rings. A WebVeld browser MUST NOT drop, reorder, or alter what a conforming document says. Parity also does not require the same user-interface affordances: a WebVeld browser MAY hand a linked media file to an external application (§10) where a modern browser plays it in the tab.

Parity covers **conforming documents** (§2.3) only. A WebVeld browser MAY reject malformed or non-conforming input, or render what it can, and need not match what another browser does with it. In particular, **a WebVeld browser is NOT required to implement the HTML5 parser's error-recovery algorithm**, which exists to cope with decades of malformed markup and is one of the larger parts of a modern browser. Authors get parity by writing conforming documents and checking them with the validator (§2.6).

Implementability (rule 2) constrains **this specification**, not how a browser is built: an implementer MAY reuse an existing engine, and §2.4 asks only that the result behave correctly. Sizing guidance is in [webveld-implementation.md](webveld-implementation.md).

### 3.2 Working principles

These follow from the cardinal rules and decide the smaller questions:

1. **No client-side scripting** — Documents MUST work with no JavaScript and no WebAssembly. In this version the exclusion is absolute (§§2.3, 4.4).
2. **Semantic HTML** — Structure carries meaning; presentation is secondary and separable.
3. **Privacy by default** — Minimal tracking surface; no third-party resources.
4. **Accessibility** — All content is reachable by assistive technology.
5. **Simplicity** — Easy to implement, and equally important, easy to validate.
6. **Static-first** — Servers serve static documents; interaction is a request away, not a runtime.

## 4. Document structure

### 4.1 Minimum document

Every WebVeld document MUST have this shape:

```html
<!DOCTYPE html>
<html lang="[language-code]">
  <head>
    <meta charset="utf-8" />
    <title>[Document Title]</title>
  </head>
  <body>
    [content]
  </body>
</html>
```

The `lang` attribute on `html` is REQUIRED. Exactly one `title` element is REQUIRED.

### 4.2 Character encoding

UTF-8 is the ONLY allowed character encoding. Documents MUST include `<meta charset="utf-8">`, and browsers MUST decode documents as UTF-8.

### 4.3 Allowed elements

| Category | Elements |
| --- | --- |
| Metadata | `html`, `head`, `body`, `title`, `meta`, `link`, `style`, `noscript` (extended documents only) |
| Sectioning | `header`, `main` (max. one per document), `footer`, `nav`, `article`, `section`, `aside` |
| Headings | `h1`, `h2`, `h3`, `h4`, `h5`, `h6` |
| Grouping | `p`, `ul`, `ol`, `li`, `dl`, `dt`, `dd`, `blockquote`, `pre`, `figure`, `figcaption`, `hr`, `div` |
| Text-level | `a`, `strong`, `em`, `i`, `b`, `u`, `code`, `kbd`, `samp`, `var`, `abbr`, `cite` |
| Text-level (continued) | `q`, `mark`, `small`, `sub`, `sup`, `del`, `ins`, `dfn`, `time`, `br`, `wbr`, `span` |
| Tables | `table`, `caption`, `colgroup`, `col`, `thead`, `tbody`, `tfoot`, `tr`, `th`, `td` |
| Forms | `form`, `label`, `input`, `textarea`, `button`, `select`, `option`, `optgroup`, `fieldset`, `legend` |
| Interactive | `details`, `summary` |
| Embedded | `img` |

`div` and `span` are generic containers and SHOULD be used only where no semantic element applies.

`details` and `summary` are the specification's disclosure primitive. A `details` element MUST contain exactly one `summary` as its first child; a browser MUST render the summary, MUST render the remaining content only while the element is open, and MUST toggle that state when the reader activates the summary by pointer or by keyboard. The state is ephemeral: it lives for as long as the document is displayed, is not persisted across navigation, and is not client-side storage under §8.

Two further requirements apply. Toggling MUST expose the disclosure state to the platform accessibility layer; this is what sets `details` apart from the `:checked` pattern of §6.3. And **content inside a closed `details` MUST be fetched at document load, as if it were open.** Deferring the fetch until the reader opens it would tell the server when the reader interacted (see §7.2).

`noscript` MUST NOT appear in a conforming document: a modern browser with scripting enabled hides its content, so the two browsers would show different things. It is permitted only in extended documents (§§2.5, 11), where it carries the content meant for scriptless readers. A WebVeld browser has no scripting, so it MUST render `noscript` content as ordinary content and MUST NOT hide or skip it.

### 4.4 Forbidden elements

| Element | Reason |
| --- | --- |
| `script` | All client-side scripting is forbidden |
| `iframe`, `embed`, `object` | No embedded browsing contexts |
| `video`, `audio`, `track`, `source` | No in-document multimedia; see §10 |
| `canvas` | No programmatic drawing surface |
| `svg` | No inline SVG (a minimal subset is a roadmap candidate) |
| `dialog` | No modal or top-layer widgets; `details` (§4.3) covers disclosure |
| `template`, `slot` | No web components |
| Any deprecated HTML element | Removed from the living standard |

Browsers MUST ignore or strip forbidden elements rather than reject the document:
- `script`, `template`, and `slot` MUST be discarded with all their contents, never rendered or executed.
- For `object`, `embed`, `canvas`, `video`, and `audio`, browsers SHOULD drop the element itself and render any conforming fallback content inside it.
- An element that is neither allowed nor forbidden (such as a newer HTML element like `search`) MUST be treated as an unknown HTML element: an inline container whose contents render normally.

## 5. Attributes

### 5.1 Global attributes

Allowed on any element: `id`, `class`, `lang`, `title`, `dir` (`ltr` or `rtl`), `tabindex` (only `0` or `-1`).

`tabindex="0"` adds an element (such as a scrollable container) to the keyboard tab order; `tabindex="-1"` makes it focusable by fragment navigation without adding it to the tab order. Positive values are FORBIDDEN, because custom tab orders harm accessibility.

Also allowed on any element, for accessibility: `role`, `aria-label`, `aria-labelledby`, `aria-describedby`, `aria-hidden`, `aria-expanded`, and `aria-controls`, with their WAI-ARIA meanings. They cost a renderer nothing (they pass straight to the platform accessibility layer) and express what markup alone cannot, such as naming an icon-only link. Authors SHOULD prefer a semantic element to a `role` wherever one exists.

### 5.2 Element-specific attributes

| Element | Attributes |
| --- | --- |
| `a` | `href` (REQUIRED), `rel`, `hreflang` |
| `img` | `src` (REQUIRED), `alt` (REQUIRED), `width`, `height` (pixels, unitless) |
| `ol` | `start`, `reversed` |
| `blockquote`, `q` | `cite` (source URL) |
| `abbr` | `title` (full expansion) |
| `form` | `action` (REQUIRED), `method` (`get` or `post`; default `get`) |
| `input` | `type`, `name` (REQUIRED for submission), `value`, `checked` (`checkbox` and `radio` only) |
| `input` (continued) | `placeholder`, `required`, `readonly`, `disabled`, `maxlength`, `pattern`, `min`, `max`, `step`, `autocomplete` |
| `textarea` | `name` (REQUIRED for submission), `rows`, `cols`, `placeholder`, `required`, `readonly`, `disabled`, `maxlength` |
| `button` | `type` (`submit`, `reset`, `button`), `name`, `value`, `disabled` |
| `select` | `name` (REQUIRED for submission), `required`, `disabled`, `multiple`, `size` |
| `option` | `value`, `selected`, `disabled` |
| `label` | `for` |
| `th`, `td` | `colspan`, `rowspan`, `headers` |
| `th` | `scope` (`row`, `col`, `rowgroup`, `colgroup`) |
| `code` | `data-lang` |
| `link` | `rel` (`stylesheet`, `icon`, or `alternate`), `href` (REQUIRED), `type`, `title` |
| `meta` | `charset` (only `utf-8`), `content` |
| `meta` (continued) | `name` (`viewport`, `description`, `keywords`, `author`, etc.), `property` (`og:*` tokens) with `content` |
| `time` | `datetime` |
| `del`, `ins` | `datetime`, `cite` |
| `colgroup`, `col` | `span` |
| `details` | `open` |
| `optgroup` | `label` (REQUIRED), `disabled` |
| `style` | none |

Allowed `input` types: `text` (default), `password`, `email`, `url`, `tel`, `number`, `date`, `checkbox`, `radio`, `submit`, `reset`, `hidden`. A browser MUST mask the value of a `password` field as it is typed.

**Passwords.** A form containing a `password` field MUST have an `action` that resolves to an `https://` URL (absolute, or relative on an HTTPS document). A browser MUST refuse to submit such a form over `http://` and MUST tell the reader why.

**Autocomplete.** An `input` MAY carry `autocomplete` with one of the values `username`, `current-password`, `new-password`, or `off`. This is the one exception to the ban in §5.3, and it applies to any `input`. Password managers are the reader's own tool, and the hint helps them. Every other token (card, address, and contact values) is excluded because **autofill harvesting needs no script**: a page can hide extra fields tagged `cc-number` or `address-line1`, and a reader who submits the form sends data they never saw. Mainstream browsers defend against this with heuristics a minimal browser won't have, and a validator can't check for them.

**Pattern.** Browsers MUST evaluate `pattern` in linear time (for example, Thompson NFA/DFA simulation) or with a bounded step limit, to prevent catastrophic backtracking. Conforming documents MUST NOT use lookahead (`(?=...)`, `(?!...)`), lookbehind (`(?<=...)`, `(?<!...)`), or backreferences (`\1`, `\2`, etc.). A browser that meets one MUST do what HTML5 specifies for a pattern it cannot compile, which is also what modern browsers do: ignore the attribute for validation and allow submission. A browser showing the conformance indicator (§2.6) SHOULD report it.

**Details.** The `open` attribute sets the initial state of `details`. A browser toggles that state on activation and MUST NOT write the change back into the document. The `name` attribute (exclusive accordions) is not permitted.

**Icons.** A `link rel="icon"` MUST reference a PNG image (§7.4).

**Code.** `data-lang` on `code` names the language of a code block, for syntax highlighting, without opening up custom data attributes in general.

**Metadata.** The table lists the permitted `meta` names. Open Graph `og:*` properties are permitted for link previews on other platforms. They cause no requests and run nothing on the reader's device, so URLs inside them (such as the absolute URL `og:image` requires) are not subresources and are exempt from §7.2. No other `meta` names or properties, and no `http-equiv`, are permitted. A `viewport` declaration MUST NOT set `user-scalable` or `maximum-scale`: readers must always be able to zoom.

### 5.3 Forbidden attributes

- Event handlers (`onclick`, `onload`, and every other `on*` attribute).
- `style` — inline styles are forbidden; use `link` or `style` (§6.1).
- `data-*` — no custom data attributes, except for `data-lang` on `code` elements (§5.2).
- `contenteditable`, `draggable` — no editing, no drag and drop.
- `hidden` — use CSS `display: none`.
- `autofocus`, `spellcheck` — no implicit browser behaviors. `autocomplete` is forbidden on every element except `input`, where it is permitted with the four values listed in §5.2.
- **Every attribute the HTML Living Standard lists as obsolete**, including the presentational table attributes (`align`, `valign`, `bgcolor`, `border`, `cellpadding`, `cellspacing`, `nowrap`, `rules`, `frame`, `summary`), `hspace`, `vspace`, and `compact`. CSS `text-align` and the §6.2 table properties reach everything in this set.

## 6. Style sheets

### 6.1 Integration

CSS MAY be supplied two ways:

1. External style sheet: `<link rel="stylesheet" href="styles.css">`
2. Embedded style sheet: `<style>...</style>`

Inline `style` attributes and `!important` in author style sheets are FORBIDDEN in conforming documents. The reason is reader control: an author's `!important` outranks a reader's ordinary user style sheet (large type, high contrast, an accessibility theme), forcing the reader to fight back with `!important` of their own. Browsers MUST still implement `!important`, for user style sheets and non-conforming documents; the restriction applies only to documents.

Per-instance values that cannot be enumerated in advance — a bar width, a swatch color, a computed dimension — are expressed by generating a `style` element that targets the elements by `id`. See Appendix A.4.

### 6.2 Allowed properties

**Box model:** `margin`, `margin-top`, `margin-right`, `margin-bottom`, `margin-left`, `padding`, `padding-top`, `padding-right`, `padding-bottom`, `padding-left`, `width`, `max-width`, `min-width`, `height`, `max-height`, `min-height`, `border`, `border-width`, `border-style`, `border-color`, `border-top`, `border-right`, `border-bottom`, `border-left`, `border-radius` (1 to 4 values for per-corner radii; no slash syntax for elliptical radii), `box-sizing`, `outline`, `outline-width`, `outline-style`, `outline-color`, `outline-offset`

**Display and layout:** `display` (`block`, `inline`, `inline-block`, `none`, `flex`, `grid`), `flex` (shorthand for `flex-grow`, `flex-shrink`, and `flex-basis`), `flex-direction` (`row`, `column`, `row-reverse`, `column-reverse`), `flex-wrap` (`nowrap`, `wrap`, `wrap-reverse`), `justify-content` (`flex-start`, `flex-end`, `center`, `space-between`, `space-around`), `align-items` (`flex-start`, `flex-end`, `center`, `stretch`), `align-content` (`flex-start`, `flex-end`, `center`, `space-between`, `space-around`, `stretch`), `flex-grow`, `flex-shrink`, `flex-basis`, `order`, `gap`, `row-gap`, `column-gap`, `grid-template-columns`, `grid-template-rows`, `grid-column`, `grid-row`, `grid-column-start`, `grid-column-end`, `grid-row-start`, `grid-row-end`

**Typography:** `font-family`, `font-size`, `font-weight` (100-900, `normal`, `bold`), `font-style` (`normal`, `italic`), `line-height`, `text-align` (`left`, `right`, `center`, `justify`, `start`, `end`), `text-decoration` (`none`, `underline`, `line-through`), `text-transform` (`none`, `uppercase`, `lowercase`, `capitalize`), `letter-spacing`, `word-spacing`, `white-space` (`normal`, `nowrap`, `pre`, `pre-wrap`, `pre-line`), `overflow-wrap` (`normal`, `break-word`, `anywhere`), `word-break` (`normal`, `break-all`, `keep-all`)

**Color and background:** `background` (shorthand; only the color, image, repeat, and position components are permitted, matching the longhands below), `color`, `background-color`, `background-image` (URL only), `background-repeat` (`repeat`, `repeat-x`, `repeat-y`, `no-repeat`), `background-position`, `opacity`

**Lists:** `list-style` (shorthand; only the `list-style-type` and `list-style-position` components are permitted, matching the longhands below — a `list-style-image` component or any `url()` value is FORBIDDEN), `list-style-type`, `list-style-position` (`inside`, `outside`)

**Tables:** `border-collapse` (`collapse`, `separate`), `border-spacing`, `caption-side` (`top`, `bottom`), `empty-cells` (`show`, `hide`)

**Other:** `overflow`, `overflow-x`, `overflow-y` (`visible`, `hidden`, `scroll`, `auto`), `content` (on `::before` and `::after` only; a quoted string, `none`, or `normal` — URL, attr, and counter values are FORBIDDEN), `cursor` (`auto`, `default`, `pointer`, `text`), `vertical-align` (`baseline`, `top`, `middle`, `bottom`, `sub`, `super`), `clip-path` (`none`, or the basic shapes `inset` and `rect` only)

`clip-path: none` releases an active clip, allowing elements clipped in one state (such as an accessible skip link) to be revealed on focus. See Appendix A.5.

Generated content produced by `content` is decorative. Authors MUST NOT place meaning there that is unavailable elsewhere in the document: assistive technology exposes it inconsistently, and §9 requires all content to be reachable.

Baseline alignment is excluded from `align-items`, and `align-self` is not permitted: independent implementations easily disagree on baselines, which would break rule 1.

**Grid is a bounded subset.** A track list in `grid-template-columns` or `grid-template-rows` MAY use lengths, percentages, `fr` values, `auto`, `min-content`, `max-content`, `minmax()` over any of those, and `repeat()` with a literal integer count. Items MAY be placed by line number or `span <integer>` through `grid-column`, `grid-row`, and their `-start`/`-end` longhands; unplaced items use the default row-major auto-placement.

The count in `repeat()`, and the total number of explicit tracks on either axis, MUST NOT exceed **10,000**, so that a document cannot exhaust a browser's memory.

Everything else in CSS Grid is FORBIDDEN: `grid-template-areas` and named lines, `grid-auto-columns`, `grid-auto-rows`, `grid-auto-flow`, `repeat()` with `auto-fill` or `auto-fit`, `fit-content()`, `subgrid`, baseline alignment across grid items, and `display: inline-grid` (just as `inline-flex` is absent).

*Value syntax:* Except where a property explicitly restricts its allowed values (such as `display`, `cursor`, or `content`), any valid CSS value composed of permitted units (§6.4), colors (named colors, hex codes, `rgb()`, `rgba()`, `hsl()`, `hsla()`, `currentColor`), and the property's standard keywords is permitted. The CSS-wide keywords `inherit`, `initial`, and `unset` are permitted on every property, including those with restricted values; `revert` and `revert-layer` are not. The `calc()` mathematical function is permitted for length, percentage, and numeric values using basic arithmetic operators (`+`, `-`, `*`, `/`).

*Intrinsic sizing keywords:* Sizing properties (`width`, `min-width`, `max-width`, `height`, `min-height` and `max-height`) MAY take `min-content` and `max-content` in addition to lengths, percentages, `auto`, and `calc()`. `fit-content()` is FORBIDDEN everywhere.

### 6.3 Allowed selectors

- Type, class, ID, and universal selectors: `p`, `.classname`, `#idname`, `*`
- Combinators: descendant (`div p`), child (`div > p`), adjacent sibling (`h1 + p`), general sibling (`h1 ~ p`)
- Selector lists: comma-separated selectors sharing a declaration block (`h1, h2, h3`)
- Attribute selectors: `[href]`, `[href="v"]`, `[href^="v"]`, `[href$="v"]`, `[href*="v"]`
- Pseudo-classes: `:hover`, `:focus`, `:active`, `:visited`, `:link`, `:first-child`, `:last-child`, `:nth-child(an+b)` (accepting `odd`, `even`, integers, and `an+b` formulas), `:target`, `:checked`, `:disabled`, `:required`, `:valid`, `:invalid`
- Pseudo-elements: `::before`, `::after`, `::first-line`, `::first-letter`

`:checked` matches checked `checkbox` and `radio` inputs. With `:disabled`, `:required`, `:valid`, and `:invalid`, it styles form state without scripting. Combined with the sibling combinators (`~`, `+`), it can also drive disclosure patterns such as tabs and menus. Authors SHOULD prefer `details` and `summary` (§4.3) for disclosure, because those expose their state to assistive technology and the `:checked` pattern does not. Where `:checked` is used anyway, authors SHOULD give clear visual indicators and keep the content legible in linear reading order.

`:checked` SHOULD NOT be used for a site-wide color scheme toggle, because its state does not survive navigation. Use `prefers-color-scheme` (§6.6, Appendix A.7).

`:visited` rules MAY set only `color`, `background-color`, `border-color`, and `outline-color`; `background-image` is FORBIDDEN there. Background images are fetched at load, not when a pseudo-class matches (§7.2).

### 6.4 Allowed units

- Absolute: `px`, `pt`, `cm`, `mm`, `in`
- Relative: `em`, `rem`, `ex`, `ch`, `%`
- Viewport: `vw`, `vh`, `vmin`, `vmax`
- Grid tracks: `fr` (in `grid-template-columns` and `grid-template-rows` track lists only; §6.2)

### 6.5 Web fonts

A document MAY define web fonts with `@font-face`, using the `font-family`, `src`, `font-weight`, and `font-style` descriptors. Every URL in `src` MUST resolve to the origin of the document that references it: a document MAY serve its own fonts, and MUST NOT direct the browser to fetch a font from another host. Browsers refuse cross-origin font requests (§7.2) and fall back to the next family in the stack, so every `font-family` declaration SHOULD end in a generic family.

A conforming browser MUST support `@font-face` with the WOFF2 format, and MAY also support WOFF and TTF/OTF. Format hints in `src` (such as `format('woff2')`) are permitted.

The `local()` function is FORBIDDEN in `src`. Paired with a `url()` fallback, whether the fallback is fetched tells the server whether a font is installed: font-enumeration fingerprinting without any script. System fonts are still available by naming them in `font-family`.

### 6.6 Media queries

A style sheet MAY use `@media` with a restricted set of features:

- Dimension constraints: `min-width`, `max-width`, and exact `width` in length units (e.g. `(min-width: 600px)`). Media Queries Level 4 comparison operators (`<=`, `>=`, `<`, `>`) are FORBIDDEN; queries MUST use the prefix form.
- Color scheme: `prefers-color-scheme` (`light` or `dark`)

Conditions MAY be combined with `and` (e.g. `(min-width: 600px) and (prefers-color-scheme: dark)`), or listed as comma-separated alternative queries (logical OR).

The only permitted media type is `print` (`@media print`). Other media types (such as `screen` or `all`), the `not` and `only` modifiers, and nested `@media` rules are FORBIDDEN.

**A `url()` value MUST NOT appear inside a media-query block.** A resource fetched only when a condition matches would tell the server the reader's viewport size or color scheme (rule 3).

A browser MUST re-evaluate media conditions when the viewport is resized or the color scheme preference changes.

### 6.7 Forbidden features

Anything not listed in §§6.2–6.6 is forbidden. Notable exclusions:

- Animations and transitions (`@keyframes`, `animation`, `transition`, `transform`)
- Grid beyond the bounded subset of §6.2: `grid-template-areas`, `grid-auto-columns`, `grid-auto-rows`, `grid-auto-flow`, `repeat()` with `auto-fill` or `auto-fit`, `fit-content()`, `subgrid`, and `display: inline-grid`
- The `position` property, in every form (`static` is the default and never needs declaring)
- `float` and `clear` (use flexbox)
- Multi-column layout
- Filters and gradients
- Custom properties (CSS variables)
- Advanced selectors (`:has()`, `:is()`, `:where()`, `:not()`, `:root`)
- `@import` rules

## 7. Resources and transport

### 7.1 URL schemes

A URL appears in one of three positions:

- A **subresource position** (`src`, `url()`, and the `href` of `link`) makes the browser fetch something and put it in the page. Permitted schemes: `http://`, `https://`, `data:image/png` and `data:image/jpeg` in `src` or `url()`, and `data:image/png` for a `link rel="icon"`. Every other `data:` URL is FORBIDDEN.
- A **form `action`** MUST be `http://` or `https://` (`https://` when the form has a password field, §5.2).
- A **navigation position** (the `href` of `a`) does nothing until the reader activates it. It accepts `http://`, `https://`, and any other registered scheme (`mailto:`, `tel:`, `gemini:`, `irc:`, `magnet:`, and so on), except those below. Linking to another network is what hypertext is for.

Exceptions in every position:

- `javascript:` and `vbscript:` are FORBIDDEN: they are script execution in a URL.
- `data:` is FORBIDDEN in navigation positions.
- `file:` is FORBIDDEN in documents, and a browser MUST NOT navigate to it from a document loaded over `http://` or `https://`. Mainstream browsers already block this.

When the reader activates a link with a scheme the browser doesn't load itself, the browser either hands it to an external handler after prompting (§10), or tells the reader it has no handler. Either way it MUST NOT fail silently and MUST NOT navigate away from the current document. Because the URL is attacker-controlled text, a browser MUST pass it to the handler as opaque data and MUST NOT expand, split, or interpret it as command arguments.

A URL MAY carry a fragment identifier or consist of one alone (`href="#section"`). Following it is same-document navigation: the browser MUST move to the element whose `id` matches, without a network request, and MUST update `:target` (§6.3) so that only that element matches it.

### 7.2 Resource loading

All embedded subresources (style sheets, images, fonts) MUST be same-origin with the document or inline `data:` image URLs (§7.1). Cross-origin subresources are FORBIDDEN in documents, and browsers MUST refuse to fetch them in any document, conforming or not, including when a same-origin request redirects to another origin. Relative URLs are RECOMMENDED. Subdomains and CDNs (such as `static.example.com`) are cross-origin.

*Badges and webrings:* A cross-origin badge image would expose the reader's IP address and the page they are on to another host (rule 3). Self-host the image, inline it as a `data:` URL, or use an ordinary link instead.

*Fetch timing:* Whether a browser fetches a subresource MUST NOT depend on reader interaction or environment: viewport size, color scheme, scroll position, or pseudo-class matches (`:hover`, `:focus`, `:active`, `:target`, `:checked`). Background images for elements present in the document, including those in pseudo-class rules, MUST be fetched at document load. A browser MAY skip resources in rules whose selectors match no element in the document, since that reveals nothing about the reader.

### 7.3 Privacy requirements

- Third-party embedded resources are FORBIDDEN (§7.2).
- Tracking pixels MUST NOT be used.
- Fonts MUST be either system fonts or self-hosted web fonts (§6.5). Third-party font services MUST NOT be referenced: a font request is a request, and it identifies the reader to whoever serves it.
- Browsers MUST permit cross-origin navigation initiated by reader actions (such as activating links or submitting forms). Referrers and cookies follow §8.

### 7.4 Image formats

A conforming browser MUST decode PNG and JPEG. A browser MAY optionally decode GIF and WebP (typically behind a build configuration flag or in an isolated decoder process); if GIF is decoded, rendering only the first frame is permitted and animation is not required.

A conforming document MUST NOT reference images in any format other than PNG and JPEG; SVG is not permitted in `img` either.

A site icon (`<link rel="icon">`) MUST be PNG, and a browser that displays site icons MUST decode it. A browser MAY also decode ICO files (still common at `/favicon.ico`), but a document MUST NOT depend on that: ICO would add a second binary parser (rule 3), and every current browser renders PNG icons.

### 7.5 HTTP transport profile

Conforming browsers MUST implement an HTTP client adhering to the following baseline profile:

- **Redirects:** Browsers MUST follow standard HTTP redirects (status codes `301`, `302`, `303`, `307`, and `308`) across `http:` and `https:`, with a redirect hop limit of at least 5 to prevent redirect loops. A redirect from `https:` to `http:` MUST NOT be followed when submitting credentials.
- **Content-Encoding:** Browsers SHOULD support standard HTTP decompression for `gzip` and `deflate` (and MAY support `br`), sending appropriate `Accept-Encoding` request headers.
- **Status codes:** Browsers MUST handle standard HTTP response statuses. Successful responses (`200 OK`) MUST be rendered; client errors (`4xx`) and server errors (`5xx`) MUST be surfaced with a clear user-facing error indication rather than failing silently.
- **Caching:** Browsers MAY cache responses in accordance with standard HTTP `Cache-Control` and `ETag` / `If-None-Match` validators, but MUST NOT use cached entities as a cross-origin tracking mechanism.

## 8. Security considerations

- No JavaScript or WebAssembly is executed, under any configuration.
- No plugin execution.
- No embedded browsing contexts (`iframe`, `embed`, `object`).
- Form submissions use unmodified HTTP GET and POST.
- Browsers MUST support HTTPS, and SHOULD let the reader accept a self-signed certificate, so self-hosted sites can use TLS without a commercial certificate authority.
- A conforming browser already enforces the equivalent of `script-src 'none'; frame-src 'none'; object-src 'none'`. Browsers SHOULD also honor `Content-Security-Policy` directives that restrict fetching further (such as `default-src`, `img-src`, `style-src`, `font-src`, and `form-action`).
- A form with a password field MUST be submitted over HTTPS (§5.2). HTTP authentication (Basic or Digest) over TLS is an alternative: its prompt is drawn in browser chrome, where a page cannot imitate it. It offers no logout and cannot be styled.
- Browsers MUST check the grid track bound (§6.2) before allocating per-track storage. A browser that allocates first can be exhausted by a document it was about to reject.
- Browsers MUST NOT offer page-accessible client-side storage, and MUST NOT store or send third-party cookies. First-party cookies are permitted.
- Browsers SHOULD enforce a privacy-preserving referrer policy (such as `strict-origin-when-cross-origin` or `no-referrer`), and MUST NOT send path or query parameters in `Referer` headers across origins.
- Browsers SHOULD present a simplified, standardized `User-Agent` string to minimize reader fingerprinting.

## 9. Accessibility requirements

- Every `img` MUST have an `alt` attribute.
- Every form control (with the exception of `input type="hidden"`, `input type="submit"`, `input type="reset"`, and `button`, which provide their own accessible name or have no visual presentation) MUST be associated with a `label` element, either via a `for` attribute referencing the control's `id` or by enclosing the control.
- Documents MUST use a correct heading hierarchy (no skipped levels).
- **A browser MUST draw a visible focus indicator** on the interactive element (link or form control) matching `:focus`, whether or not the document styles one.
- **A document MUST NOT remove that indicator without replacing it.** A rule matching `:focus` MUST NOT declare `outline: none`, `outline-style: none`, or `outline-width: 0` unless the same declaration block establishes another visible indicator — a `background-color`, `border`, or `color` change, for instance. A document SHOULD additionally satisfy itself that the browser's own indicator stays visible against any background it sets, which no validator can check.
- Tables SHOULD use `th` with an appropriate `scope`.
- The document language MUST be declared on the `html` element.

The document focus rule is limited to `outline`-removing declarations so that a validator can check it (§2.6).

Contrast cannot be checked from markup, so **authors SHOULD check contrast against WCAG 2.2** with dedicated tools. Because author `!important` is forbidden (§6.1), a reader's high-contrast style sheet can always take precedence.

## 10. External application handlers

A WebVeld browser MAY delegate content types it does not render to an external application on the user's operating system. This keeps codecs and document parsers out of the browser binary.

This section is OPTIONAL for browsers and places no requirements on documents. A browser that implements external handlers MUST follow it.

### 10.1 Principles

1. **User control** — the user decides whether delegation happens at all.
2. **Security first** — never auto-execute a file that could be code.
3. **Flexibility** — support the user's preferred applications.
4. **Transparency** — make it clear when content leaves the browser.
5. **Delegation** — specialized tools handle specialized formats.

### 10.2 Configuration

A browser implementing external handlers MUST offer at least three modes per content type:

1. **Always open** — open with the configured application.
2. **Always ask** — prompt the user each time (RECOMMENDED default).
3. **Never open** — download the file; do not launch anything.

### 10.3 Content types

Browsers MAY offer handlers for: `video/*`; `audio/*`; `application/pdf`; office document types; `text/plain`; archive types (`application/zip`, `application/x-tar`, `application/gzip`, `application/x-bzip2`); and the `mailto:` and `tel:` URL schemes. Browsers MAY support additional types based on platform capability.

### 10.4 Behavior

Handlers apply ONLY to direct links whose target is the file itself (`<a href="video.mp4">`), never to content embedded in the document.

- **Always open** — subject to the prohibitions in §10.5, which override any user configuration: download to a secure temporary location, notify the user, launch the configured application, keep the document open and functional, and clean up the temporary file when the application exits where the platform permits.
- **Always ask** — prompt with at least "open", "download", and "cancel", and offer to remember the choice for that content type.
- **Never open** — download to the user's download location and notify them.

The document remains loaded in the background in every mode; delegation MUST NOT navigate away from the current document.

### 10.5 Security requirements

- **No auto-execution** — browsers MUST NOT launch files that are or may be executable code: executables (`.exe`, `.app`, `.dmg`, `.msi`, `.run`, `.sh`, `.bat`, `.cmd`, `.com`), scripts (`.js`, `.py`, `.rb`, `.pl`, `.php`), system libraries (`.dll`, `.so`, `.dylib`), and unknown or unrecognized MIME types including `application/octet-stream`. These MUST only be downloaded, regardless of user configuration.
- **Staging** — files MUST be downloaded to a secure temporary location before launch, and browsers SHOULD apply the platform's quarantine attributes.
- **MIME validation** — browsers MUST check the declared MIME type against the file extension and warn the user on a mismatch.
- **First use** — the first time a supported content type is opened, the browser MUST warn the user. For unknown or unrecognized MIME types, the browser MUST ask before downloading and MUST NOT offer to open or launch them.
- **Limits** — browsers MAY refuse to open files above a size limit or from untrusted origins.
- **Isolation** — no browser state (history, cookies, referrer) is passed to the external application.

### 10.6 Platform integration

Browsers SHOULD discover installed applications through platform conventions: XDG MIME associations and desktop entries on Linux/BSD, Launch Services on macOS, and registry file associations on Windows. Custom protocol handlers (`magnet:`, `ssh:`, `irc:`, and similar) MAY be supported, but MUST prompt before launching and MUST receive the URL as opaque data (§7.1).

### 10.7 User interface

- The browser MUST indicate when an external application is being launched.
- Handler settings MUST be reachable from browser preferences.
- Prompts MUST be keyboard navigable, MUST activate the primary action on Enter, MUST cancel on Escape, and MUST be announced to assistive technology.

## 11. Progressive enhancement (escape hatch)

An author MAY publish an extended document (§2.5) that offers a scripted experience to modern browsers while remaining usable in WebVeld browsers. Because a conforming browser ignores forbidden elements (§2.4), no additional browser behavior is required.

Requirements for extended documents:

1. The document MUST place content intended for WebVeld users in a `noscript` element, which a modern browser with scripting hides and a WebVeld browser renders (§4.3). This also lets a validator classify the document (§2.6).
2. That content MUST convey the same information and offer a usable path to the same outcome as the scripted experience. Parity of information is REQUIRED; parity of interaction is not.
3. The document MUST NOT depend on scripting to render its primary content in a WebVeld browser.
4. The document MUST NOT be advertised as WebVeld-conforming; it is an extended document.

A single-file example is in Appendix A.3.

---

## Appendix A. Examples (informative)

A complete multi-page conforming site is in [`examples/minimal-site/`](../examples/minimal-site/README.md), and a scriptless payment and authentication flow is in [`examples/payment_processor/`](../examples/payment_processor/README.md). The snippets below illustrate specific patterns.

### A.1 Minimal document

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Hello WebVeld</title>
  </head>
  <body>
    <h1>Welcome</h1>
    <p>This is a WebVeld document.</p>
  </body>
</html>
```

### A.2 Document with styling

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Styled Example</title>
    <style>
      body {
        font-family: sans-serif;
        max-width: 800px;
        margin: 0 auto;
        padding: 1rem;
        line-height: 1.6;
      }
      h1 {
        color: #333;
        border-bottom: 2px solid #666;
      }
      nav ul {
        list-style-type: none;
        padding: 0;
      }
      nav li {
        display: inline-block;
        margin-right: 1rem;
      }
    </style>
  </head>
  <body>
    <header>
      <h1>My WebVeld Site</h1>
      <nav>
        <ul>
          <li><a href="/">Home</a></li>
          <li><a href="/about">About</a></li>
          <li><a href="/contact">Contact</a></li>
        </ul>
      </nav>
    </header>
    <main>
      <article>
        <h2>Article Title</h2>
        <p>Article content goes here.</p>
      </article>
    </main>
    <footer>
      <p><small>&copy; 2026 Example Site</small></p>
    </footer>
  </body>
</html>
```

### A.3 Extended document (escape hatch)

This document is NOT WebVeld-conforming. It serves an interactive storefront to modern browsers and a static catalog to WebVeld browsers, from one file. It satisfies all three clauses of §2.5: it carries a `script`, it carries a `noscript` whose content is itself conforming, and removing both leaves a document that satisfies §2.3.

```html
<!DOCTYPE html>
<html lang="en" class="webveld-view">
  <head>
    <meta charset="utf-8" />
    <title>Store</title>
    <style>
      body { font-family: sans-serif; max-width: 800px; margin: 0 auto; }
      .shared { border-bottom: 1px solid #ccc; padding-bottom: 1rem; }
      .modern-app { display: none; }
      .modern-view .modern-app { display: block; }
      .modern-view .webveld-only { display: none; }
    </style>
    <!-- Modern browsers execute this; WebVeld browsers ignore it -->
    <script>
      document.documentElement.className = 'modern-view';
    </script>
  </head>
  <body>
    <header class="shared">
      <h1>Our Products</h1>
      <p>High-quality widgets for your daily needs.</p>
    </header>

    <main class="modern-app">
      <h2>Interactive Storefront</h2>
      <div id="cart-root"></div>
      <script src="storefront.js"></script>
    </main>

    <noscript>
      <div class="webveld-only">
        <h2>Catalog</h2>
        <table>
          <caption>Products and how to order</caption>
          <tr><th scope="col">Item</th><th scope="col">Price</th><th scope="col">Order</th></tr>
          <tr><td>Widget A</td><td>$10.00</td><td>Call 555-0199</td></tr>
        </table>
        <p>Or download our <a href="order-form.pdf">order form</a>.</p>
      </div>
    </noscript>
  </body>
</html>
```

### A.4 Per-instance values without inline styles

A generated document computes per-element values into an embedded style sheet rather than a `style` attribute. The values stay overridable by a user style sheet, and the document stays conforming.

```html
<style>
  .bar-row { display: flex; align-items: center; gap: 0.5rem; }
  .bar { display: inline-block; background-color: #446; height: 1rem; }
  #bar-q1 { width: 45%; }
  #bar-q2 { width: 52%; }
  #bar-q3 { width: 68%; }
</style>

<div class="bar-row"><span>Q1</span><span class="bar" id="bar-q1"></span><span>$45,000</span></div>
<div class="bar-row"><span>Q2</span><span class="bar" id="bar-q2"></span><span>$52,000</span></div>
<div class="bar-row"><span>Q3</span><span class="bar" id="bar-q3"></span><span>$68,000</span></div>
```

### A.5 An accessible skip link

A skip link is available to keyboard and assistive-technology users but hidden from the visual layout until focused. Without `position` (§6.7), the obvious construction is broken, so the working one is shown here.

```html
<style>
  .skip-link {
    display: inline-block;
    width: 1px;
    height: 1px;
    overflow: hidden;
    clip-path: inset(50%);
    white-space: nowrap;
  }
  .skip-link:focus {
    width: auto;
    height: auto;
    overflow: visible;
    clip-path: none;
    padding: 0.5em 1em;
    background-color: #fff;
    color: #000;
  }
</style>

<a class="skip-link" href="#content">Skip to content</a>
<nav>…</nav>
<main id="content">…</main>
```

- **`display: inline-block` is required.** `width`, `height`, and `overflow` don't apply to an inline box, so without it the link is invisible but still leaves a gap the width of its text. (The common version of this technique uses `position: absolute`, which has the same effect as a side effect.) `display: block` also works.
- **`width`/`height`/`overflow` collapse the box; `clip-path` hides the text.** Each needs the other: `clip-path` alone leaves the gap, and the box alone lets the text paint over what follows.
- **Release the clip with `clip-path: none`, not `inset(0)`.** `inset(0)` clips to the border box, which also clips away the focus outline that §9 requires.
- **`display: none` doesn't work.** It removes the link from the accessibility tree too.

**A visible skip link is also correct.** A plain `<a href="#content">Skip to content</a>` as the first focusable element gives keyboard users the same shortcut. Where a profile lacks the properties above (`webveld-nano` keeps only `display: none` and has no `overflow` or `clip-path`), use the visible form. It has one more advantage: if it breaks, someone will notice.

#### Ordering against a `:checked` control

The `:checked` disclosure pattern (§6.3) needs its `input` to come before what it styles, and a checkbox is focusable, so it can take the first tab stop the skip link needs. The input only has to precede *what it styles*, so put the skip link first and the input right after it:

```html
<body>
  <a class="skip-link" href="#content">Skip to content</a>
  <input type="checkbox" id="nav-toggle" />
  <label for="nav-toggle">Menu</label>
  <nav>…</nav>
  <main id="content">…</main>
</body>
```

`#nav-toggle:checked ~ nav` still matches, and the skip link keeps the first tab stop. The same ordering works for accordions and tab sets.

Don't use `tabindex="-1"` on the input to get it out of the way. A `label` is not focusable, so this leaves the control reachable only by pointer.

A control that styles the whole page can't be ordered this way, because the skip link would sit inside what it styles. For the most common case, a color scheme toggle, see Appendix A.7.

### A.6 Wide preformatted text without `overflow`

In the full profile, use `overflow-x: auto` on wide code blocks: the block scrolls and the page stays still. The technique below is for profiles without `overflow`, such as `webveld-nano`.

```css
pre {
  white-space: pre;       /* do not wrap */
  width: max-content;     /* the box grows with the longest line */
  min-width: 100%;        /* ...but never narrower than the column */
  box-sizing: border-box; /* so min-width accounts for the padding */
}
```

Prose still wraps to the column; only the page scrolls sideways. All four declarations matter: with `white-space: pre` alone, the block's background stops at the column edge while its text runs past it, and `max-content` alone shrinks short blocks narrower than the prose.

The costs: scrolling right moves the prose off-screen too, nothing shows which block is wide, and the widest line on the page sets the scroll range for the whole page. With `<meta name="viewport" content="width=device-width, initial-scale=1">`, the initial render on small screens is unaffected.

### A.7 Light and dark color schemes

A color scheme belongs to the reader, and the reader has already set it in their operating system or browser. §§5.2 and 6.6 provide the two halves:

```html
<meta name="color-scheme" content="light dark" />
```

```css
html {
  color: #1a1a1a;
  background-color: #fdfdfd;
}
a:link    { color: #0b4f9c; }
a:visited { color: #5c3d99; }

@media (prefers-color-scheme: dark) {
  html {
    color: #e6e6e6;
    background-color: #16181a;
  }
  a:link    { color: #8ab4f8; }
  a:visited { color: #c8a8f0; }
}
```

This persists across pages, reloads, and restarts with no script, cookie, or server state. Points to get right:

- **Include the `meta`.** CSS doesn't reach form controls, scrollbars, or the canvas painted before the style sheet loads; without `color-scheme`, those stay light on a dark page. Declare `light dark` only if you style both.
- **Write `html`, not `:root`.** `:root` is not in §6.3's list. It is the most likely way for a copied snippet to break conformance.
- **Put light outside the query and dark inside.** A reader with no preference reports `light` and gets the unconditional styles.
- **Set link colors in both blocks.** Default link colors assume a light background. Check both schemes against WCAG 2.2 (§9).
- **Fetch nothing inside the query.** §6.6 forbids `url()` there, because a fetch on `prefers-color-scheme: dark` would reveal the reader's preference to the server.

**Why there's no toggle.** A `:checked` toggle resets on every navigation, can't easily invert the system preference without custom properties or `:not()`, and competes with the skip link (A.5) for the first tab stop.

**What's missing.** There is no per-site override. A first-party cookie set by a form POST could provide one, and it is conforming, but it isn't recommended: it needs a dynamic server, every HTML response needs `Vary: Cookie`, and it puts a per-reader bit on every request.

**Profiles.** This appendix applies unchanged to [`webveld-nano`](profiles/webveld-nano.md). [`webveld-pico`](profiles/webveld-pico.md) has no author style sheets and leaves colors to the reader's browser.

## Appendix B. Version history (informative)

| Version | Date | Status | Key Changes |
| :--- | :--- | :--- | :--- |
| **0.10.1** | 2026-11-01 | Current | Editorial: fixed section reference and version example |
| **0.10.0** | 2026-10-31 | Draft | Viewport declarations may not disable zoom (§5.2) |
| **0.9.0** | 2026-10-31 | Draft | Refuse cross-origin subresources (§7.2); CSS-wide keywords (§6.2); parity defined |
| **0.8.3** | 2026-09-13 | Draft | Editorial refinements; §6.3 `:checked`, skip-link (A.5), color schemes (A.7) |
| **0.8.2** | 2026-09-13 | Draft | Added visible skip link accessibility pattern to Appendix A.5 |
| **0.8.1** | 2026-09-13 | Draft | Corrected skip link box model in Appendix A.5 (`display: inline-block`) |
| **0.8.0** | 2026-09-13 | Draft | Decoupled profile versions (§2.7); intrinsic sizing keywords; focus indicator |
| **0.7.0** | 2026-09-13 | Draft | Added `clip-path: none` (§6.2); clarified contrast scope (§9) |
| **0.6.0** | 2026-09-12 | Draft | Recast profiles as restrictions; bounded grid tracks to 10,000 (§6.2) |
| **0.5.0** | 2026-09-08 | Draft | Tightened extended document definition (§2.5) with noscript fallback |
| **0.4.0** | 2026-09-08 | Draft | Admitted details/summary (§4.3) and bounded CSS Grid subset (§6.2) |
| **0.3.0** | 2026-09-08 | Draft | Core baseline: element and property allowlists, parity, semver rules |

---

### 0.10.1 — 2026-11-01

- §2.4: updated the example version string; §2.6: fixed a section reference. No conformance change.

### 0.10.0 — 2026-10-31

- §5.2: a `viewport` declaration MUST NOT set `user-scalable` or `maximum-scale`. This restricts documents (it would be MAJOR after 1.0.0).

### 0.9.0 — 2026-10-31

- §2.4, §7.2: browsers MUST refuse every cross-origin subresource request, in any document and after redirects, not only fonts.
- §6.2: `inherit`, `initial`, and `unset` are permitted on every property; `revert` and `revert-layer` are not.
- §2.3: `data:` is forbidden in links; site icons are PNG only (matching §5.2, §7.4).
- §3.1: parity means the same content, visually identical to a reader, not identical pixels. Added an approximate implementability budget.
- §5.2: `autocomplete` table entry now matches the prose (any `input`, credential tokens only).
- §6.3: dropped the advice to pair `aria-expanded` with `:checked`, which goes stale without script.
- §6.5: `@font-face` with WOFF2 is required of every conforming browser, matching §2.4.
- §7.1: restructured by URL position; listed `data:` and `file:` exclusions explicitly; a site icon may be an inline `data:image/png` URL.
- §8: browsers SHOULD honor CSP directives that restrict fetching, instead of MUST honor the whole header; first-party cookies are permitted without the "session continuity" qualifier.
- Appendix A: tightened A.5–A.7.

### 0.8.3 — 2026-09-13

- Updated §6.3 guidance to advise against using `:checked` for site-wide color scheme toggling (pointing to `@media (prefers-color-scheme)`).
- Documented keyboard tab ordering for skip links and preceding-sibling disclosures in Appendix A.5.
- Added Appendix A.7 documenting pure-CSS light and dark color schemes via `prefers-color-scheme`.

### 0.8.2 — 2026-09-13

- Added guidance on visible skip links for constrained profiles (`webveld-nano`) in Appendix A.5.

### 0.8.1 — 2026-09-13

- Corrected skip link example in Appendix A.5 to include `display: inline-block` for inline `<a>` box collapsing.

### 0.8.0 — 2026-09-13

- Decoupled profile versioning (§2.7) so profiles version independently from the base specification.
- Admitted `min-content` and `max-content` intrinsic sizing keywords to width and height properties (§6.2).
- Split §9 focus indicator obligations into explicit browser drawing requirements and document preservation requirements.
- Added Appendix A.6 documenting preformatted code blocks using `width: max-content` in profiles without `overflow`.
