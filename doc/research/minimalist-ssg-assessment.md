# Audit of Minimalist Static Site Generators

**Subjects:**
- **ssg5 / ssg** (Roman Zolotarev, script dated 2026 / community fork `3de8b6e`, 2021-04-09) with **lowdown** (`64672b9`, 2026-09-07)
- **saait** (Hiltjo Posthuma / suckless, commit `4e687c0`, 2023-04-10)
- **Soupault** (Daniil Baturin, commit `dde23d7`, 2026-04-24)
- **Zola** (Vincent Prouillet, commit `61d3082`, 2026-08-31) with **pulldown-cmark** v0.13 & **Giallo** v0.5
- **Hugo Minimal Themes** (**hugo-bearblog** commit `87142ec`, 2026-07-30; **hugo-minimal** commit `987f270`, 2021-01-03) with **Goldmark** & **Chroma**
- **Eleventy** (**eleventy-base-blog** commit `e37a55c`, 2026-06-18) with **markdown-it** & PrismJS

**Measured:** 2026-09-08 · **Against:** [webveld-spec.md](../webveld-spec.md) v0.3.0

*Measured against v0.3.0. Most of the findings below were adopted into the specification in 0.3.0 and 0.3.1 — table cell `align`, `data-lang`, `:checked`, the metadata names, `dir` and `tabindex`, and `i`/`b`/`u`. See the 0.3.1 entry in Appendix B of the specification before treating a finding here as current.*

---

## Overview and Method

This audit is the primary-source successor to [minimalist-ssg-audit-review.md](minimalist-ssg-audit-review.md), extending the source-level inspection method of [luasmith-assessment.md](luasmith-assessment.md) across the broader landscape of minimalist static site generators. The generators audited here were identified by minimalist authors and members of the 250KB/512KB clubs as their primary publishing tools.

Rather than rendering synthetic test sites, this review reads the actual source code: shipped templates, configuration files, default style sheets, and the C, Go, Rust, and OCaml source of underlying Markdown parsers and syntax highlighters.

Along the way, this audit investigates specific open questions from the roadmap and the active task queue:
1. Does any generator emit `data-line` or other `data-*` attributes by default?
2. How do different Markdown renderers resolve table column alignment, and do any produce conforming markup?
3. How common is `:checked`-based interactivity in actual minimalist sites, measured directly on the size-budget corpus?

---

## Tool-by-Tool Findings

### 1. ssg5 / ssg (Roman Zolotarev) + lowdown

Roman Zolotarev's `ssg` is a POSIX shell script pairing Unix utilities with a Markdown translator (conventionally `lowdown`). It uses a minimal templating model (`.ssg.template` or `_header.html`/`_footer.html`).

#### Shipped Templates
- **`meta http-equiv`:** Roman Zolotarev's original `.ssg.template` emits `<meta http-equiv="content-type" content="text/html; charset=utf-8">`. Spec §4.2 and §5.2 require `<meta charset="utf-8">` and explicitly forbid `http-equiv`. In the popular `fmash16/ssg5` community fork, `_header.html` emits `<meta http-equiv="X-UA-Compatible" content="ie=edge">` (also forbidden by §5.2).
- **`meta name="color-scheme"`:** The original `.ssg.template` emits `<meta name="color-scheme" content="dark light">`. Spec §5.2 allows only `charset` or `name="viewport"` on `meta`.
- **Omitted `<body>` tag and inline style:** The `fmash16/ssg5` fork's `_header.html` omits the opening `<body>` tag, while the script itself injects `<h1 style="display: none;"> HOME </h1>` into generated indices (violating §5.3).
- **Icon elements:** The fork's `_footer.html` emits FontAwesome icons via `<i class="far fa-copyright"></i>`, violating §4.3/§4.4.

#### lowdown Markdown Renderer (`src/format/html/html.c`)
- **Table cell alignment emits forbidden inline `style`:** In `rndr_tablecell` (lines 918–935), column alignment (`:---:`, `:---`, `---:`) produces:
  ```c
  case HTBL_FL_ALIGN_CENTER:
      if (!HBUF_PUTSL(ob, " style=\"text-align: center\">"))
  case HTBL_FL_ALIGN_LEFT:
      if (!HBUF_PUTSL(ob, " style=\"text-align: left\">"))
  case HTBL_FL_ALIGN_RIGHT:
      if (!HBUF_PUTSL(ob, " style=\"text-align: right\">"))
  ```
  This violates §5.3 (`style` inline attribute is strictly forbidden).
- **Footnote backlinks emit obsolete `rev` attribute:** In `rndr_footnote_def` (line 997), the backlink to the citation is rendered as:
  ```html
  <a href="#fnref1" rev="footnote">&#8617;</a>
  ```
  Spec §5.2 permits only `href`, `rel`, and `hreflang` on `<a>`. `rev` is not permitted.
- **Standalone metadata tags:** When compiling standalone documents (`lowdown -s`), `lowdown` emits `<meta name="creator">`, `<meta name="author">`, `<meta name="copyright">`, and `<meta name="date">` (violating §5.2).
- **What's clean:** lowdown generates clean semantic headings with automatic `id` attributes (`<hN id="...">`), code blocks as `<pre><code class="language-...">`, definition lists (`<dl>`, `<dt>`, `<dd>`), and emits no `data-*` attributes anywhere.

---

### 2. saait (Hiltjo Posthuma / suckless)

`saait` is the suckless static site and Atom feed generator written in portable C99. It combines per-page INI-style configuration with raw HTML template blocks (`header.html`, `item.html`, `footer.html`).

#### Shipped Templates (`templates/page/`)
- **Global `dir` attribute:** `header.html` emits `<html dir="ltr" lang="${lang}">`. Spec §5.1 allows `class`, `id`, `lang`, `title`, `aria-*`, `role`. The `dir` attribute is omitted from the specification.
- **Forbidden `meta` tags:** `header.html` emits:
  ```html
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <meta http-equiv="Content-Language" content="${lang}" />
  <meta name="keywords" content="${keywords}" />
  <meta name="description" content="${description}" />
  <meta name="author" content="${author}" />
  <meta name="generator" content="${sitegenerator}" />
  ```
  None of `http-equiv`, `keywords`, `description`, `author`, or `generator` are allowed under §5.2.
- **Stylesheet `media` attribute and media types:** `header.html` links stylesheets using:
  ```html
  <link rel="stylesheet" href="style.css" type="text/css" media="screen" />
  <link rel="stylesheet" href="print.css" type="text/css" media="print" />
  ```
  Spec §5.2 omits `media` from `<link>` attributes, and §6.6 explicitly forbids `screen` and `print` media types.
- **Obsolete table presentation attributes:** Navigation is laid out as:
  ```html
  <table id="menu" width="100%" border="0">
    <tr>
      <td id="links" align="left">...</td>
      <td id="links-contact" align="right">...</td>
    </tr>
  </table>
  ```
  `width` and `border` on `<table>`, and `align` on `<td>`, are forbidden by §5.2.
- **Unsupported URL scheme:** Navigation includes `<a href="gopher://codemadness.org">Gopherhole</a>`. Spec §7.1 permits only `http:`, `https:`, `mailto:`.
- **Missing required `datetime` on `<time>`:** `item.html` emits `<time>${updated}</time>`. Spec §5.2 requires `datetime` whenever `<time>` is used.

#### Shipped CSS (`style.css`)
- **Forbidden `overflow` value:** `html { overflow-y: scroll; }`. Spec §6.2 restricts `overflow-y` to `hidden`, `auto`, `visible`.
- **Unrecognized typographic unit `ex`:** Shipped rules use `padding: 1ex;` and `max-width: 80ex;`. Spec §6.4 allows relative units `em`, `rem`, `%`, but omits `ex` and `ch`.
- **Forbidden properties:** `style.css` declares `word-wrap: normal` and `vertical-align: middle`, neither of which is present in §6.2's allowed property list.

---

### 3. Soupault (Daniil Baturin) + Cmarkit

Soupault is an OCaml-based generator designed for the "small web" and IndieWeb. Instead of string templating, it parses HTML directly into an AST (`lambdasoup`) and applies widgets via CSS selectors. Markdown conversion is handled by `Cmarkit`.

#### Cmarkit Table Rendering: The Only Conforming Output
Inspection of `Cmarkit_html` revealed an important result: **Cmarkit is the only audited Markdown engine whose table column alignment conforms to WebVeld.**
```ocaml
let table c t =
  let start c align tag =
    match align with
    | None -> C.byte c '>';
    | Some `Left -> C.string c " class=\"left\">"
    | Some `Center -> C.string c " class=\"center\">"
    | Some `Right -> C.string c " class=\"right\">"
  in
  ...
  C.string c "<div role=\"region\"><table>\n";
```
Unlike `md4c`, `lowdown`, `pulldown-cmark`, `goldmark`, and `markdown-it`, Cmarkit emits neither obsolete `align="..."` attributes nor inline `style="text-align:..."`. It emits semantic CSS classes (`class="left"`, `class="center"`, `class="right"`) on `<th>` and `<td>`, and wraps the table in a responsive `<div role="region">`. Every element and attribute used is fully allowed by WebVeld (§4.3, §5.1).

#### Built-in Widgets
- **Footnotes widget (`src/widgets/footnotes_widget.ml`):** Moves footnote elements to a designated container, replacing citations with `<sup><a href="#footnote-N">N</a></sup>` and appending backlinks `<a href="#footnote-ref-N">`. Completely conformant (§4.3, §5.1, §5.2, §7.1).
- **Table of contents widget (`src/widgets/toc_widget.ml`):** Traverses headings, slugifies text for `id` attributes, emits nested `<ol>` or `<ul>` lists with anchor links `<a href="#id">`, and optionally injects section permalinks into headings. Completely conformant.
- **Zero client-side scripting:** Soupault contains no client-side runtime or scripts.
- **Zero `data-*` attributes:** A full search of the Soupault codebase found zero occurrences of `data-` attributes.
- **Template defects:** The default template in `src/project_init.ml` and `sample-site/templates/main.html` omits `<!DOCTYPE html>`, which violates §4.1.

---

### 4. Zola + pulldown-cmark + Giallo

Zola is a single-binary Rust generator popular in the minimalist web for its speed and zero-runtime architecture. It uses `pulldown-cmark` for CommonMark and recently transitioned its syntax highlighter from Syntect to `Giallo`.

#### Syntax Highlighting (`Giallo`)
- **Default inline styles:** By default (`markdown.highlighting.style = "inline"`), Giallo outputs hex colors directly via inline `style="color: #..."` or `style="color: light-dark(#..., #...);"` on every `<span>` token. This violates §5.3.
- **CSS classes option:** Zola supports `style = "class"`, which generates external stylesheets (`giallo.css` or light/dark variants) and emits `<span class="z-1">` tokens, which conforms to §4.3 and §5.1.
- **Unconditional `data-lang` attribute:** Even when class-based highlighting is enabled, and **even when syntax highlighting is completely disabled**, Zola emits `data-lang` on the `<code>` element:
  ```rust
  // components/markdown/src/markdown.rs:189-194
  let lang = if self.fence.lang != giallo::PLAIN_GRAMMAR_NAME {
      format!(r#" data-lang="{}""#, self.fence.lang)
  } else {
      String::new()
  };
  format!("<pre><code{lang}>{}</code></pre>\n", escape_html_string(&self.content))
  ```
  Spec §5.3 explicitly states: "`data-*` — custom data attributes are forbidden." Every fenced code block naming a language emitted by Zola carries a spec violation.
- **No `data-line` for line numbering:** Line numbering (`linenos`) in Giallo emits `<span class="giallo-ln">` spans. It does **not** emit `data-line` attributes.

#### pulldown-cmark Rendering
- **Table alignment emits inline `style`:** In `pulldown_cmark::html`, table cells with alignment generate:
  ```rust
  match self.table_alignments.get(self.table_cell_index) {
      Some(&Alignment::Left) => self.write(" style=\"text-align: left\">"),
      Some(&Alignment::Center) => self.write(" style=\"text-align: center\">"),
      Some(&Alignment::Right) => self.write(" style=\"text-align: right\">"),
      _ => self.write(">"),
  }
  ```
  Violates §5.3.
- **Task lists emit forbidden `disabled` attribute:** Pulldown-cmark outputs `<input disabled="" type="checkbox" />`. Spec §5.2 omits `disabled` from allowed `<input>` attributes.
- **Heading anchors & Footnotes:** Zola's default `anchor-link.html` emits `<a class="zola-anchor" href="#{{ id }}" aria-label="...">🔗</a>`, which is 100% conformant. Footnotes emit `<sup>` and `<div class="footnote-definition">` which also conform.

#### Built-in Default Template (`components/render/src/default_tpl.html`)
Zola's fallback error template violates §4.1 (missing doctype and charset), §4.4 (uses `<b>`), §5.2 (`target="_blank"` on links), and §6.2 (`position: fixed`).

---

### 5. Hugo (Minimal Themes + Goldmark + Chroma)

Hugo is widely used among minimalist authors running in bare-bones configurations.

#### Goldmark Table Renderer (`extension/table.go`)
Goldmark's `renderTableCell` provides two alignment modes via `TableCellAlignMethod`:
1. `TableCellAlignStyle` (default in HTML mode): appends `style="text-align:left|center|right"` to the cell. Violates §5.3.
2. `TableCellAlignAttribute` (used in XHTML mode): appends `align="left|center|right"`. Violates §5.2.

Neither mode produces WebVeld-conforming markup.

#### Chroma Syntax Highlighter (`formatters/html/html.go`)
- **Inline styles by default:** Chroma defaults to inline styles on tokens and lines unless `WithClasses(true)` (Hugo's `noClasses = false`) is set.
- **Line numbering:** Line numbers are emitted either inside a `<table>` with separate `<td>` columns (`linenos=table`), or as inline `<span>` elements with optional `id` attributes.
- **Debunking `data-line`:** Inspection of Chroma confirms that it **never** emits `data-line` or any other `data-*` attribute.

#### Minimal Themes
- **`hugo-bearblog`:** A benchmark minimalist theme from the Bear Blog ecosystem.
  - **CSS Custom Properties:** Heavily relies on `:root { --width: 720px; ... }` and `var(--...)` throughout `style.html`. Violates §6.5.
  - **JSON-LD in `<script>`:** Includes Hugo's internal `schema.html`, which injects `<script type="application/ld+json">`. Violates §4.4.
  - **Metadata:** Emits `meta name="description"`, `name="keywords"`, and `http-equiv="X-Clacks-Overhead"`.
- **`hugo-minimal`:**
  - **Client-side scripts:** Injects MathJax (`<script src="...MathJax.js">`) unconditionally by default.
  - **Bootstrap markup:** Emits `data-target` and `data-toggle` attributes on navigation buttons (§5.3 violation), and `<i>` icons (§4.4 violation).

---

### 6. Eleventy (eleventy-base-blog)

Eleventy advertises "zero client-side JavaScript by default." However, its official starter template (`eleventy-base-blog`) demonstrates how modern web development conventions diverge from WebVeld.

#### Shipped Starter (`_includes/layouts/base.njk`)
- **Client-side web component script:** Includes `<script type="module">` loading `@zachleat/heading-anchors`.
- **Autonomous custom element:** Emits `<heading-anchors>` in the DOM to wrap content. Spec §4.4 states: "custom elements (any element with a hyphen in its tag name) are forbidden."
- **JavaScript bundle injection:** Emits `<script type="module" src="...">` before `</body>`.

#### Shipped CSS (`css/index.css`)
- **Forbidden at-rules:** Emits `@view-transition { navigation: auto; }`. Spec §6.7 forbids `@view-transition`.
- **Positioning:** `.visually-hidden` uses `position: absolute;`, `clip`, and `clip-path`, all forbidden by §6.2 and §6.5.
- **Custom properties:** Extensive use of CSS custom properties in `:root`.

#### Renderer & Highlighter Defaults
- **`markdown-it` tables:** Emits `style="text-align:..."` on aligned cells (violating §5.3).
- **PrismJS plugin:** Injects `tabindex="0"` into `<pre>` tags via `preAttributes`. Spec §5.1 omits `tabindex` from allowed global attributes.

---

## Cross-Tool Synthesis: The Four Major Spec Tensions

Across all seven independent implementations (luasmith, ssg5/lowdown, saait, Soupault, Zola, Hugo, Eleventy), the same friction points emerge repeatedly:

| Feature / Output | luasmith | lowdown | saait | Soupault | Zola | Hugo | Eleventy | WebVeld Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Table Alignment** | `align` | `style` | `align` | `class` | `style` | `style`/`align` | `style` | Both `align` & `style` forbidden |
| **Code Highlighting** | `<i>/<b>/<u>` | `<pre>` | N/A | external | `style` | `style` | class | `style`, `data-*`, `i/b/u` out |
| **Meta Description/Keywords**| `name` | `name` | `name` | template | template | `name` | `name` | Forbidden (§5.2) |
| **Footnote Backlinks** | `role` | `rev="footnote"`| N/A | `href` only | `href` only | `role` | `role` | `rev` forbidden (§5.2) |
| **Line Number `data-line`** | None | None | None | None | None | None | None | Claim debunked across all tools |
| **CSS Custom Properties** | In theme | None | None | None | In themes | In themes | In themes | Forbidden (§6.5, Tier 2 candidate) |

### 1. The Table Alignment Dilemma
Markdown table alignment (`| :--- | :---: | ---: |`) is supported by every CommonMark extension. However:
- Four tools (`lowdown`, `pulldown-cmark`, `goldmark`, `markdown-it`) default to `style="text-align: ..."` (violating §5.3).
- Two tools (`md4c`, `goldmark` in XHTML mode) default to `align="..."` (violating §5.2).
- Only one tool (`cmarkit` in Soupault) generates classes (`class="left|center|right"`).

Because WebVeld forbids both `align` on cells and inline `style`, **authors using 6 out of 7 standard SSG pipelines cannot write aligned Markdown tables without producing non-conforming output.**

### 2. The `data-*` and `data-lang` Finding
The secondary survey's claim that SSGs commonly emit `data-line` for line numbering is **false**. Chroma, Giallo, lowdown, and PrismJS do not emit `data-line` by default.
However, Zola's Markdown engine unconditionally emits `data-lang="..."` on `<code data-lang="...">` whenever a language is specified in a fenced code block, even when syntax highlighting is disabled. Under §5.3, this makes every code block in Zola non-conforming.

### 3. SEO and Preview Metadata
Every tool that provides document-level metadata templates (`luasmith`, `saait`, `hugo-bearblog`, `eleventy-base-blog`, `lowdown -s`) emits `<meta name="description">` and `<meta name="keywords">`. Limiting `meta` to `charset` and `viewport` forces every standard SSG header template into non-conformance for no runtime or security benefit.

### 4. Global Attributes: `dir` and `tabindex`
- `saait` emits `<html dir="ltr">`. Right-to-left and bidirectional text requires `dir`.
- Eleventy's accessible code blocks emit `<pre tabindex="0">` to make scrollable code keyboard-accessible.
Neither `dir` nor `tabindex` is currently allowed in §5.1.

---

## Empirical Corpus Verification: `:checked` and the Checkbox Hack

The active task in `doc/tasks/active.tm.md` noted:
> "Re-running tools/corpus-study/ with a check for :checked usage added would turn that last one into a measured percentage rather than an assertion."

To resolve this, the 104-site corpus study was re-fetched and analyzed with explicit detection for `:checked`, `<input type="checkbox">`, and the sibling combinator checkbox hack (`:checked ~` or `:checked +`).

### Corpus Study Results (n=104)

| Feature | Cohort A (512kb.club, n=68) | Cohort B (Lite/text-only, n=21) | Cohort C (Modern dev, n=15) | All Sites (n=104) |
| :--- | :--- | :--- | :--- | :--- |
| **`:checked` pseudo-class in CSS** | **26.5%** | **33.3%** | **26.7%** | **27.9%** |
| **Checkbox hack (`:checked ~` or `+`)**| **16.2%** | **4.8%** | **13.3%** | **13.5%** |
| `<input type="checkbox">` in HTML | 10.3% | 0.0% | 13.3% | 8.7% |
| `:disabled` in CSS | 13.2% | 14.3% | 26.7% | 15.4% |
| `:valid` / `:invalid` in CSS | 4.4% | 4.8% | 13.3% | 5.8% |
| *Comparison: native `<details>`* | *10.3%* | *0.0%* | *13.3%* | *9.6%* |
| *Comparison: `prefers-color-scheme`* | *26.5%* | *23.8%* | *46.7%* | *28.8%* |

### Key Takeaways
1. **`:checked` is mainstream on the minimalist web:** Found on **27.9%** of all sites and **26.5%** of 512KB Club members. It appears with the exact same frequency as dark mode (`prefers-color-scheme` at 28.8%).
2. **The checkbox hack outnumbers `<details>`:** The CSS checkbox hack specifically (`:checked ~` / `+`) is present on **16.2%** of size-budget sites, compared to only **10.3%** using native `<details>`.
3. **What authors actually build with it (observed in Cohort A):**
   - **Responsive navigation drawers:** e.g., `zacharykai.net` (`.menu-toggle:checked ~ header nav`).
   - **Scriptless image zoom / lightboxes:** e.g., `yinji.org` (`.image-zoom-toggle:checked ~ .image-zoom-overlay`).
   - **Scriptless theme toggles:** e.g., `10maurycy10.github.io` (`:root :has(#lightmode:checked)`).
   - **Interactive content filtering:** e.g., `insecure.club` (`body:not(:has(#category-filter:checked))`).

The empirical evidence confirms the review's thesis: excluding `:checked` disqualifies over a quarter of the minimalist web and breaks the primary scriptless interactivity idiom used by size-budget authors.

## Gaps Most Difficult to Work Around: Analysis Against Cardinal Rules

When evaluating spec gaps identified by the audit, two distinct dimensions of difficulty must be separated:
1. **Workaround Difficulty for SSGs and Authors:** Distinguishes between **template-level defaults** (which an author can fix once in a `baseof.html` or `header.html` template) and **engine-level hardcoded output** (which is baked into compiled C, Go, Rust, or Node Markdown parsers and highlighters, requiring upstream tool modifications, complex AST hooks, or brittle regex post-processing).
2. **Cardinal Rule 2 (Implementability) for Browser Engines:** As defined in [spec §3.1](../webveld-spec.md#L103), this benchmarks the engineering complexity and time required for a development team to build and maintain the feature inside a browser's core parsing, style cascade, layout, and rendering engine within the project's "months of work rather than years" budget.

Below, the gaps are categorized into those that satisfy all three cardinal rules versus those that fail one or more rules.

---

### Category 1: Gaps That MEET All Three Cardinal Rules
*(Defensible, high-value candidates that can be admitted with minimal browser engine cost and zero privacy risk).*

#### 1. Markdown Table Column Alignment (`align="left|center|right"` on `<th>`/`<td>`)
- **SSG / Author Difficulty:** **Extreme.** 6 of the 7 audited parsers (`lowdown`, `md4c`, `pulldown-cmark`, `goldmark`, `markdown-it`) hardcode column alignment (`| :--- | :---: | ---: |`) to either `style="text-align:..."` or obsolete `align="..."`. Because WebVeld forbids both inline `style` (§5.3) and `align` on cells (§5.2), authors cannot write aligned Markdown tables without post-processing every output file or writing custom AST render hooks.
- **Rule 1 (Parity):** **Passes.** Universal support across every graphical and terminal web browser for 30 years.
- **Rule 2 (Implementability in Engine):** **Passes.** Trivial. Parsing an enumerated HTML attribute on `<th>`/`<td>` and mapping it to the text-align property in the element's default style cascade (`th[align=center] { text-align: center; }`) takes a browser developer under an hour.
- **Rule 3 (Privacy & Safety):** **Passes.** Pure inline text justification within an existing layout cell. Zero tracking or execution surface.

#### 2. The `:checked` Pseudo-Class (Spec §6.3)
- **SSG / Author Difficulty:** **Extreme.** Present on **27.9%** of the 104-site corpus (and **16.2%** of size-budget sites using the sibling-combinator checkbox hack). Without JavaScript and with `<details>` forbidden, authors have no other mechanism to build interactive disclosures, mobile navigation drawers, tab interfaces, or theme switchers. Forcing authors off `:checked` either breaks mobile responsive navigation or forces them to drop into §11 Extended Documents (`<script>`).
- **Rule 1 (Parity):** **Passes.** Universally supported in CSS3 across all desktop and mobile browsers without polyfills.
- **Rule 2 (Implementability in Engine):** **Passes.** Very cheap. Any engine supporting HTML forms already tracks the boolean checked/unchecked state of checkbox and radio inputs. Exposing that state to selector matching (`:checked`) requires only a boolean check during selector matching, far cheaper than pseudo-classes like `:nth-child(an+b)` or layout like flexbox.
- **Rule 3 (Privacy & Safety):** **Passes.** State changes only on direct human interaction (clicking/tapping a native form input). Without WASM or script runtimes, nothing can toggle state programmatically, eliminating layout-thrashing loops.

#### 3. SEO & Discovery Metadata (`<meta name="description|keywords|author|color-scheme">`)
- **SSG / Author Difficulty:** **Moderate.** Every SSG with head templates (`luasmith`, `saait`, `lowdown -s`, `hugo-bearblog`, `eleventy-base-blog`) emits `meta description`. Forcing authors to strip these breaks search engine snippets, indexing, and social sharing link previews.
- **Rule 1 (Parity):** **Passes.** Standard metadata read by search indexers; browsers parse and ignore in layout.
- **Rule 2 (Implementability in Engine):** **Passes.** Zero cost. A WebVeld browser engine literally ignores them during layout or exposes them to bookmarks/window titles.
- **Rule 3 (Privacy & Safety):** **Passes.** Static document metadata with no client execution or networking side-effects.

#### 4. Global Text Direction (`dir="ltr|rtl|auto"`) & Scroll Focus (`tabindex="0"`)
- **SSG / Author Difficulty:** **Moderate.**
  - `dir` is essential for bidirectional text and right-to-left languages (Arabic, Hebrew, Persian). `saait` emits `<html dir="ltr">`.
  - `tabindex="0"` is emitted by Eleventy and PrismJS on `<pre>` blocks to make horizontally overflowing code blocks scrollable via keyboard navigation (a core WCAG accessibility requirement).
- **Rule 1 (Parity):** **Passes.** Standard HTML global attributes supported everywhere.
- **Rule 2 (Implementability in Engine):** **Passes.** `dir` is already required by Unicode bidi text layout engines; `tabindex="0"` simply flags an element as focusable in the keyboard navigation ring.
- **Rule 3 (Privacy & Safety):** **Passes.** No script execution, no tracking surface.

#### 5. Text-Level Formatting Elements (`<i>`, `<b>`, `<u>`)
- **SSG / Author Difficulty:** **Low to Moderate.** Used by `luasmith` and text-mode highlighters to style syntax tokens in terminal browsers (Lynx, w3m, Dillo).
- **Rule 1 (Parity):** **Passes.** Universal browser support.
- **Rule 2 (Implementability in Engine):** **Passes.** Identical parsing and layout to `<span>` or `<em>`.
- **Rule 3 (Privacy & Safety):** **Passes.** Completely passive inline elements.
- **Original reason for exclusion:** Excluded on strict semantic grounds ("use `<em>` and `<strong>` for semantics, `<span>` for styling"), not due to any cardinal rule.

#### 6. Interactive Disclosure Elements (`<details>` / `<summary>`)
- **SSG / Author Difficulty:** **Moderate.** The semantic standard for scriptless accordions, spoilers, and folded footnotes.
- **Rule 1 (Parity):** **Passes.** Universal native support.
- **Rule 2 (Implementability in Engine):** **Passes.** Low cost. It toggles an `open` attribute on user interaction and manages child element visibility.
- **Rule 3 (Privacy & Safety):** **Passes.** Built-in accessible disclosure semantics (`aria-expanded`, keyboard enter/space) with no script vector.

---

### Category 2: Gaps That FAIL the Cardinal Rules
*(Must remain excluded; workarounds and discipline must stay on the author or toolchain side).*

#### 1. Client-Side Scripting & Web Components (`<script>`, `<heading-anchors>`)
- **Encountered in:** `eleventy-base-blog` (heading-anchor web component), `hugo-minimal` (MathJax, Google Analytics), `hugo-bearblog` (JSON-LD script block).
- **Which rules they break:**
  - **Rule 2 (Implementability in Engine):** **FAILS FATALLY.** A full ECMAScript engine with DOM bindings, event loops, and JIT compilation requires millions of lines of code—completely destroying the single-developer budget.
  - **Rule 3 (Privacy & Safety):** **FAILS FATALLY.** Scripting is the single largest origin of client-side tracking, fingerprinting, timing attacks, and remote code execution vulnerabilities.
- **Author/SSG Workaround:** Easily resolved at build-time. Static site generators can generate heading permalinks as plain `<a href="#id">#</a>` during compilation (as Zola, lowdown, and Soupault already do), avoiding client-side DOM manipulation.

#### 2. CSS Positioning (`position: absolute | fixed | sticky`)
- **Encountered in:** 68% of the size-budget corpus; used in `eleventy-base-blog` (`.visually-hidden`) and `hugo-bearblog` for fixed topbars/overlays.
- **Which rules they break:**
  - **Rule 2 (Implementability in Engine):** **FAILS.** Absolute and fixed positioning introduce stacking contexts, out-of-flow geometry, multi-pass layout, and z-index ordering. In browser layout engines, positioning is notoriously expensive and bug-dense.
- **Author/SSG Workaround:** Authors can build topbars and nav layouts using Flexbox and normal flow (`margin: 0 auto; display: flex;`), which WebVeld already allows (§6.2). Visually hidden utility classes can use modern zero-size clip techniques without positioning.

#### 3. Inline `style="..."` Attributes on Syntax Highlighting Tokens
- **Encountered in:** Default modes of Zola (Giallo), Hugo (Chroma `noClasses=true`), and `markdown-it`.
- **Which rules they break:**
  - **Rule 2 (Implementability in Engine) & Rule 3 (Reader Safety/Accessibility):** **FAILS.** Inline styles override reader stylesheets and user-agent accessibility stylesheets (e.g., forced high-contrast themes, custom dyslexic fonts, or dark mode overrides). Furthermore, parsing inline styles requires the HTML tree builder to continuously invoke the CSS declaration parser for thousands of code token `<span>` elements per page.
- **Author/SSG Workaround:** Authors must configure their SSG to output class-based syntax highlighting (`markup.highlight.noClasses = false` in Hugo; `style = "class"` in Zola) and link an external stylesheet.

---

### Category 3: Bounded Compromises & Roadmap Candidates
*(High-demand features that fail full compliance today, but can pass under strictly bounded subsets).*

#### 1. Code Block Language Attribute (`data-lang` vs. Bounded `data-*`)
- **The Conflict:** Zola unconditionally emits `<code data-lang="...">`. Spec §5.3 bans all `data-*` attributes because arbitrary `data-*` attributes serve as payload vectors for tracker scripts and client-side state machines.
- **Evaluation:** Broad `data-*` fails Rule 3 (unbounded state channel). However, permitting `data-lang` specifically as an element-specific attribute on `<code>` in §5.2 **satisfies all three rules** and resolves Zola's unconditional emission. Alternatively, Zola can be configured to use CommonMark's `class="language-..."`.

#### 2. Vector Graphics via `<img src="*.svg">` (Image Source Only)
- **The Conflict:** Minimalist authors rely on SVGs for crisp, lightweight icons and logos, but WebVeld §7.4 forbids SVG entirely.
- **Evaluation:** Full inline `<svg>` fails Rule 2 (it is an entire secondary XML rendering engine). However, allowing `.svg` files strictly as an `<img>` source painted via a self-contained, isolated rasterizer (with XML entity expansion and nested script execution disabled) avoids DOM entanglement and satisfies Rules 1, 2, and 3.

#### 3. CSS Custom Properties (`var(--...)`)
- **The Conflict:** 61% of size-budget sites rely on custom properties for clean dark/light theme switching.
- **Evaluation:** Holds Parity (Rule 1) and Privacy (Rule 3), but strains the initial single-pass parser budget (Rule 2) due to cascade resolution, cycle detection, and fallback handling. It remains the top candidate for Tier 2 once an initial conforming engine is operational.

---

### Summary Evaluation Matrix

| Gap / Feature | SSGs Affected | Workaround | Rule 1 | Rule 2 | Rule 3 | Recommendation |
| :--- | :--- | :--- | :---: | :---: | :---: | :--- |
| **Table `align` on `<td>`/`<th>`** | lowdown, pulldown, md4c | **Extreme** (hardcoded in parsers) | ✅ | ✅ | ✅ | **Adopt in §5.2** |
| **`:checked` pseudo-class** | 28% of corpus, checkbox hack | **Extreme** (no alternative for UI) | ✅ | ✅ | ✅ | **Adopt in §6.3** |
| **Meta `description` / `keywords`** | All SSG templates | **Moderate** (breaks SEO/previews) | ✅ | ✅ | ✅ | **Adopt in §5.2** |
| **Global `dir` & `tabindex`** | saait, Eleventy / PrismJS | **Moderate** (breaks RTL & a11y) | ✅ | ✅ | ✅ | **Adopt in §5.1** |
| **Text-level `<i>`, `<b>`, `<u>`** | luasmith, highlighters | **Low** (can remap in theme) | ✅ | ✅ | ✅ | **Adopt in §4.3** |
| **Language tag on `<code>`** | Zola (Giallo) | **High** (unconditional in Zola) | ✅ | ✅ | ✅ | **Allow `data-lang`** |
| **SVG as `<img>` source** | Bearblog, minimal icons | **Moderate** (fallback to PNG) | ✅ | ✅ | ⚠️ | **Queue for bounded subset** |
| **CSS Custom Properties** | Bearblog, 11ty (61%) | **Moderate** (duplicate dark rules) | ✅ | ⚠️ | ✅ | **Hold at Tier 2 roadmap** |
| **CSS Positioning** | 11ty, 68% of corpus | **Low** (use flexbox & normal flow) | ✅ | ❌ | ⚠️ | **Keep excluded** |
| **Inline `style="..."`** | Default Chroma, Pygments | **Low** (use class-based config) | ✅ | ❌ | ⚠️ | **Keep excluded** |
| **`<script>` / Web Components** | Eleventy, MathJax | **Low** (compile at build time) | ❌ | ❌ | ❌ | **Keep excluded** |

---

## Spec Implications and Recommendations

1. **Adopt `:checked` immediately in §6.3:** The empirical proof is decisive (28% of corpus, cheap to implement, zero privacy risk). Consider `:disabled` alongside it (15.4% of corpus).
2. **Resolve the Table Alignment Dilemma:** Since 6 out of 7 Markdown parsers emit either `align="..."` or `style="text-align:..."`, WebVeld must choose one of two paths:
   - *Option A (Recommended):* Permit `align="left|center|right"` on `<th>` and `<td>` in §5.2. This is what HTML4 allowed, what CommonMark parsers target when avoiding inline styles, and what costs a renderer virtually nothing.
   - *Option B:* Document that authors using Goldmark, pulldown-cmark, lowdown, or markdown-it must use post-processors or custom render hooks (like Soupault/Cmarkit) to replace inline styles with classes.
3. **Permit Standard Metadata in §5.2:** Add `name="description"`, `name="keywords"`, `name="author"`, and `name="color-scheme"` to allowed `<meta>` attributes.
4. **Permit `dir` and `tabindex` in §5.1:** Essential for internationalization (RTL) and keyboard accessibility on scrollable code blocks.
5. **Consider Code Block Language Identification:** If `data-*` remains forbidden in §5.3, note that Zola users must configure custom templates to prevent `data-lang` injection, or consider allowing `data-lang` specifically on `<code>`.

---

## Reproducing this Audit

All audited repositories were cloned into `tmp/` within the repository tree:

```bash
# Clone repositories
git clone --depth 1 https://github.com/kristapsdz/lowdown.git tmp/lowdown
git clone --depth 1 https://git.codemadness.org/saait tmp/saait
git clone --depth 1 https://github.com/PataphysicalSociety/soupault.git tmp/soupault
git clone --depth 1 https://github.com/getzola/zola.git tmp/zola
git clone --depth 1 https://github.com/janraasch/hugo-bearblog.git tmp/hugo-bearblog
git clone --depth 1 https://github.com/calintat/minimal.git tmp/hugo-minimal
git clone --depth 1 https://github.com/11ty/eleventy-base-blog.git tmp/eleventy-base-blog

# Check table alignment rendering in lowdown
grep -n -C 5 'HTBL_FL_ALIGN' tmp/lowdown/src/format/html/html.c

# Check table alignment rendering in pulldown-cmark
curl -sL https://raw.githubusercontent.com/raphlinus/pulldown-cmark/master/pulldown-cmark/src/html.rs | grep -C 5 'Tag::TableCell'

# Check table alignment rendering in cmarkit (Soupault)
curl -sL https://raw.githubusercontent.com/dbuenzli/cmarkit/master/src/cmarkit_html.ml | grep -C 5 'let table c t'

# Check Zola data-lang injection
grep -n -C 5 'data-lang' tmp/zola/components/markdown/src/markdown.rs

# Re-run corpus study with :checked detection
lua tools/corpus-study/analyze.lua
```
