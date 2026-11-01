# luasmith as a Data Point on Minimalist HTML Usage

**Subject:** [luasmith](https://github.com/jaredkrinke/luasmith), commit `1bfab0f` (2026-05-20, tag `0.6-3-g1bfab0f`) · **Measured:** 2026-09-07 · **Against:** [webveld-spec.md](../webveld-spec.md) v0.3.0

*Measured against v0.3.0. Several findings below were resolved in 0.3.1 — notably `<meta name="description">` and `keywords` (§8), which the specification now permits. See the 0.3.1 entry in the specification's Appendix B before treating a finding here as current.*

luasmith is a small static site generator — Lua and C, under 500 KB, zero runtime dependencies — built on md4c for Markdown, etlua for templates, and Scintillua for syntax highlighting. It ships two built-in themes, `blog` and `md2blog`, and generates plain HTML with no client-side script of its own.

It was reviewed here for the same reason as [dillo-assessment.md](dillo-assessment.md) and [webveld-corpus-study.md](webveld-corpus-study.md): as evidence about what people who already care about minimalism actually produce, rather than as a target to conform to. The question is whether WebVeld's allowed-element and allowed-property lists line up with what a tool like this generates by default — and where they don't, whether that is a defect in the tool's templates or a gap in the specification.

## Method

Read the built-in theme templates (`themes/blog/*.etlua`, `themes/md2blog/*.etlua`), both shipped style sheets, the shared Lua helpers, and — because a theme only controls part of the output — the C source of the Markdown-to-HTML renderer (`md4c/src/md4c-html.c`) to see what the underlying library emits for the feature flags luasmith actually enables (`MD_FLAG_TABLES`, `MD_FLAG_STRIKETHROUGH`, `MD_FLAG_PERMISSIVEURLAUTOLINKS`, `MD_FLAG_PERMISSIVEEMAILAUTOLINKS`). No document was rendered; findings are read directly from the source that produces one.

## Findings

Ordered by how much of a generated site each one affects, not by severity of the underlying idea.

### 1. Syntax highlighting emits `<i>`, `<b>`, and `<u>` — none of which WebVeld permits

In `themes/blog/theme.lua` and identically in `themes/md2blog`, highlighted tokens are mapped to elements:

```lua
i = {"comment", "preprocessor", "bold", "italic", "number", "underline", "string"},
b = {"tag", "function", "heading", "label", "annotation", "class", "type", "keyword"},
u = {"link", "list", "error", "regex"},
```

WebVeld's text-level semantics list (spec §4.3) is `a, strong, em, code, kbd, samp, var, abbr, cite, q, mark, small, sub, sup, del, ins, dfn, time, br, wbr, span`. No `i`, `b`, or `u`. Comments, keywords, strings, and numbers are exactly the token kinds present in nearly every highlighted code block, so this fires whenever syntax highlighting is used at all — a headline feature of the tool, in both themes. This is the finding with the widest reach: it does not depend on an author's choices the way most of the rest do.

### 2. Markdown table alignment emits a forbidden `align` attribute

`md4c-html.c`, `render_open_td_block`: a column marked `:---:`, `:---`, or `---:` in source Markdown emits `<th align="center">` / `<td align="left">`. Spec §5.2 permits only `colspan`, `rowspan`, `headers` on `td`/`th`, plus `scope` on `th`. `align` is not among them. This is the normal way to write an aligned Markdown table, not an edge case.

### 3. `md2blog`'s `outer.etlua` emits an unconditional `<script type="application/ld+json">`

Whenever a page has `title`, `description`, and `date` — i.e., essentially every post — the theme embeds a JSON-LD block. Spec §4.4 forbids `script` outright with no exception. Unlike the other findings, this is not conditional on an author's Markdown; the theme does it every time. Of everything found, this is the one that looks disqualifying for `md2blog` on its own.

### 4. `md2blog`'s style sheet uses `:is()`, which is forbidden by name

Spec §6.5 lists `:has()`, `:is()`, `:where()` explicitly as forbidden. `style.css` has `:is(h1, h2, h3, h4, h5) :is(a:link, a:visited) { color: inherit; }`.

### 5. `blog`'s style sheet uses CSS custom properties and `display: table*`

`--lighter: color-mix(in srgb, currentColor 70%, transparent);` plus `var(--lighter)` — custom properties are forbidden (§6.5) and are a Tier 2 roadmap candidate, not part of the specification. Separately, the post-list layout uses `display: table`, `display: table-row`, `display: table-cell`; WebVeld's allowed `display` values are `block, inline, inline-block, none, flex` only (§6.2).

### 6. `md2blog`'s media query names a media type

`@media screen and (max-width: 40em)`. Spec §6.6 permits `width`/`min-width`/`max-width`/`prefers-color-scheme` conditions but is explicit that "neither is `screen`, `print`, or any other media type" permitted.

### 7. The favicon-suppression idiom uses a `data:` URL

`<link rel="icon" href="data:," />`, in both themes — a common trick to stop browsers requesting `/favicon.ico`. Spec §7.1 permits only `http:`, `https:`, `mailto:`. `data:` is not among them.

### 8. `<meta name="description">` and `<meta name="keywords">` fall outside the letter of the specification

Present in both themes' `outer.etlua`, and near-universal practice for SEO and link previews. The current spec wording for `meta` (§5.2) is "`charset` (only `utf-8`); or `name=\"viewport\"` with `content`" — which reads as permitting exactly those two forms. This looks like a specification gap rather than a tool defect: a `name="description"` meta tag costs a renderer nothing, carries no scripting or privacy implication, and is exactly the category of omission that `checked` and the `background` shorthand turned out to be in 0.3.0. Flagged here rather than fixed, since changing the spec is a separate decision.

### 9. Raw HTML in Markdown source passes through unfiltered

`md4c-html.c` treats an HTML block or inline HTML in Markdown source as verbatim passthrough (`MD_BLOCK_HTML` and `MD_TEXT_HTML`). This is ordinary CommonMark behavior, not a luasmith defect, but it means conformance depends on the site author never writing raw HTML directly in a `.md` file.

### 10. What's clean

No JavaScript at all outside the one JSON-LD block in finding 3 — link checking, templating, and syntax highlighting are pure build-time Lua and C; nothing ships to the browser beyond markup and CSS. Ordinary Markdown-to-HTML output — paragraphs, headings with generated `id`s, lists, blockquotes, `pre`/`code`, links, `em`/`strong`, images (`alt` is always emitted, even if empty, directly from the renderer), and `del` from strikethrough — sits entirely inside WebVeld's allowed element set. The `<time datetime="...">` output matches the pattern 0.3.0 now permits exactly. The Atom feed template is XML, not HTML, and is out of scope for the specification; its `<summary>` element is unrelated to HTML's forbidden `<summary>`.

## Assessment

Neither built-in theme conforms to WebVeld 0.3.0 today, `md2blog` more seriously than `blog` because of the unconditional script tag. None of the ten findings looks structural to the tool's design — they are template and CSS choices sitting on top of a pipeline (frontmatter → Markdown → templates → static files) that is otherwise a close match for WebVeld's model. Every finding is fixable by editing an `.etlua` file or a style sheet; none requires touching the Lua pipeline or the C core. A minimal WebVeld-conforming theme built from `blog`'s templates looks like a small, well-defined piece of work: remap the highlighter's element choices to `span` with a class, remove the `data:` favicon link and the custom property, replace `display: table*` with flex, and drop `align()`-producing table syntax or accept a small amount of unavoidable authoring discipline around it.

## Why this belongs in the corpus of evidence

This document, [dillo-assessment.md](dillo-assessment.md), and [webveld-corpus-study.md](webveld-corpus-study.md) are now three independent looks at the same question from different angles: what does a browser already implement, what do minimalist authors' finished pages contain, and what does a tool built specifically to produce lean output generate by default. All three matter for the same reason — WebVeld's credibility rests on not quietly excluding constructs that the audience it is aimed at already relies on, and a single data point cannot tell the difference between a real gap and a coincidence.

One genuine finding survives across the three: something being both minimalist and reasonable is not the same as something WebVeld currently permits. Syntax highlighting via `i`/`b`/`u` is the sharpest example here — a deliberate design decision in luasmith, made explicitly "to support non-CSS browsers (e.g. terminal browsers)," which is close to WebVeld's own stated audience, and it still lands outside the allowed element set.

**Worth doing next:** a short survey of a handful of other minimalist static site generators (candidates: Zola, Hugo's minimal themes, ssg5/blorg-style shell-script generators, Jekyll's minimal themes, Eleventy with a bare template) against the same allowed-element and allowed-property lists, to see whether syntax-highlighting element choices, table alignment attributes, and meta-tag conventions converge the same way here did. A pattern repeating across independently-built tools is much stronger evidence than any one of them alone — the corpus study did exactly this for CSS layout, on real pages rather than on generator output, and a generator-side survey is the natural companion to it. This is recorded as a task in `doc/tasks/future.tm.md`.

## Reproducing this

```
git clone https://github.com/jaredkrinke/luasmith.git && cd luasmith
git log -1 --format='%H %ad' --date=short

# theme templates and style sheets
cat themes/blog/*.etlua themes/blog/style.css
cat themes/md2blog/*.etlua themes/md2blog/style.css
cat themes/blog/theme.lua        # syntax-highlighting element map

# what the Markdown renderer actually emits, for the flags luasmith enables
grep -n 'md_html(' main.c                              # confirms the MD_FLAG_* set in use
grep -n 'case MD_BLOCK_\|case MD_SPAN_\|render_open_td_block\|render_open_img_span' md4c/src/md4c-html.c
```

Findings should be re-checked against a later luasmith release and against whichever WebVeld version is current; several depend on exact spec wording that has already moved once during this project (§6.2, §6.6, §7.1).

## Related measurements

This document, [dillo-assessment.md](dillo-assessment.md), and [webveld-corpus-study.md](webveld-corpus-study.md) are read from primary sources — actual code, actual pages. [minimalist-ssg-audit-review.md](minimalist-ssg-audit-review.md) reviews a secondary-source survey of further generators instead, and is a leads list for extending this kind of review rather than a fourth independent measurement in its own right.
