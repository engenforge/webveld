# WebVeld validator (rough cut)

`webveld-validate.lua` checks HTML files and style sheets against [`doc/webveld-spec.md`](../../doc/webveld-spec.md). It is the first cut of the reference validator described in spec §2.6, and it is deliberately small.

```
# When installed (via make install):
webveld-validate FILE...
webveld-validate --classify FILE...

# In-tree usage:
lua tools/validator/webveld-validate.lua FILE...
lua tools/validator/webveld-validate.lua --classify FILE...
WEBVELD_SPEC=/path/to/webveld-spec.md lua tools/validator/webveld-validate.lua FILE...
```

Exit status is 0 when every file conforms and 1 otherwise, so it works in a commit hook or CI.

## Conformance checking

Specification §2.6 defines conformance checking for WebVeld subset rules (§§4–9). `check-repo.sh` validates all HTML documents in the repository against the specification's allowlists and rules using `webveld-validate.lua`.

## `--classify`: the three states of §2.6

The default mode answers one question — does this document satisfy §2.3. `--classify` answers the question a browser's indicator asks, reporting each file as **Conforming**, **Extended** or **Non-conforming** per §2.6, and failing the run only on the last of those, since §2.6 requires that Extended not be presented as an error.

It implements the algorithm §2.6 states, which is why that section can claim the states are decidable: strip `script` and `noscript`, run the §2.3 check over what remains, and run the §§4–9 checks over the `noscript` content. A document is Extended only if it has scripting, has a `noscript` whose body conforms, and is otherwise a conforming document — so a page with a clean fallback and a third-party font in its `head` is reported Non-conforming, and the violation is attributed to where it was found:

```
Extended       examples/store.html
Non-conforming examples/leaky.html
  - outside `script` and `noscript`: absolute URL in <link rel="stylesheet"> …
  - inside `noscript`: inline style attribute is forbidden (6.1)
```

Most of the web lands in Non-conforming, because 70% of pages carry a script and 11% carry a `noscript`. That verdict is accurate and it is not a claim that anything is missing — §2.6 forbids the indicator from implying that without grounds, and so does this output.

## Allowlists come from the specification

Element, attribute, CSS property, and input-type allowlists are parsed out of the specification's own tables at run time rather than duplicated here. A change to §4.3, §5.1, §5.2, or §6.2 takes effect on the next run, and the validator cannot quietly disagree with the document it enforces. It prints the sizes of those lists on startup as a sanity check.

The validator checks the full specification. Profiles are checked separately, by `webveld-profile-check.lua` — see below.

## `webveld-profile-check.lua`: the two profiles

```
lua tools/validator/webveld-profile-check.lua [--profile=nano|pico] FILE...
```

`webveld-validate.lua` answers "does this conform to WebVeld." A profile is a restriction *on top of* conformance, so a document can pass the validator while using elements and properties [`webveld-nano`](../../doc/profiles/webveld-nano.md) or [`webveld-pico`](../../doc/profiles/webveld-pico.md) removes. This asks the narrower question, and assumes its input already passed the validator. It takes `.html` and `.css` files; `--profile` defaults to `nano`.

It also checks **value narrowings**, which profiles are permitted to apply (§3.1) and `webveld-nano` R3 applies to exactly one property: `display`, narrowed to `none`. The specification may permit more values for a property than a profile does, so the checker carries a per-profile value map alongside the property list, and the drift guard knows those values are values rather than missing properties.

It came from the `webveld-template` site build, where it was written to keep a two-variant build honest about which profile each variant claimed, and it was nano-only. It was extended to pico on the way in.

**It transcribes the profile lists rather than parsing them**, which is a weaker design than `webveld-validate.lua`'s and is the main thing to improve. The obstacle is that nano R3 names some properties in prose ("and its four longhands", "the four per-side `border-*` shorthands") rather than in backticks, so the property set cannot be read out of the document mechanically the way §6.2's can. What stands in for parsing is a **drift guard**: every run re-reads the profile document's R1 table and R3 property list and warns when the checker and the document disagree. `test-profile-check.lua` treats any drift warning on a positive fixture as a failure, so a profile edit that outruns the checker breaks CI rather than passing quietly. Making nano R3 machine-readable would let the guard become the mechanism.

R4 (subresources) is not checked. For pico, R1 already removes every element that could fetch anything; for nano, what remains is §7.2's same-origin rule, which `webveld-validate.lua` already enforces.

```bash
lua tools/validator/test-profile-check.lua
```

The corpus has four sections: positive fixtures per profile, negative fixtures that must be rejected, **upward validity** — every positive fixture also conforms to full WebVeld, and every pico fixture also conforms to nano, which is the claim both profile documents make by construction — and a check that the negative fixtures are *profile*-negative rather than spec-negative, so they fail for the reason intended. Fixtures live in `tests/profile/`.

## What it checks

Permitted elements and per-element attributes; enumerated attribute values (`tabindex` 0 or -1, `dir` ltr or rtl, permitted `meta` names and `og:*` properties, `link rel` values, `checked` only on checkbox and radio); `details` with `summary` as its first child; restriction of `noscript` to extended documents; inline `style` attributes and author `!important` declarations; permitted CSS properties and §6.2 enumerated values (e.g. `display`, `flex-direction`, `align-items` baseline exclusion, `text-align`, `overflow`, `cursor`, `box-sizing`); property-specific restrictions (`content` only on `::before`/`::after`, `border-radius` without slash syntax, `list-style` without `url()`, `background-image` URL-only, `clip-path` inset/rect/none only, and `fit-content()` exclusion); §6.3 selector allowlist (14 pseudo-classes, 4 pseudo-elements, `:nth-child` argument validation, and rejection of `:not()`, `:nth-of-type()`, `:root`, etc.); §6.4 allowed units (`px`, `pt`, `cm`, `mm`, `in`, `em`, `rem`, `ex`, `ch`, `%`, `vw`, `vh`, `vmin`, `vmax`, `fr`) and rejection of unpermitted units (`q`, `deg`, `s`, etc.); §6.7 forbidden features (`@keyframes`, gradients, `var()` custom properties, `:has()`/`:is()`/`:where()`); `@import` and nested `@media` rules; grid constructs outside the section 6.2 subset; media query features, media types other than `print`, the `not` and `only` modifiers, range syntax, and `prefers-color-scheme` values; the CSS-wide keywords (`inherit`, `initial`, `unset` permitted; `revert` and `revert-layer` rejected); `url()` inside a media-query block; `local()` and cross-origin `src` URLs in `@font-face`; `:visited` color-only declarations (no `background-image`); a `:focus` rule that removes the outline without establishing another indicator (§9); document structure (doctype, `lang`, charset, a single `title`, at most one `main`); heading hierarchy without skipped levels (§9); `alt` on every image; same-origin subresources for `img`, `link rel="stylesheet"`, `link rel="icon"` and CSS `url()`; `data:` in `link href` only for a PNG icon; permitted image formats, including the PNG-only site-icon baseline; `data:` image MIME types; URL schemes by position (`javascript:`/`vbscript:`/`file:`/document `data:` in a link, non-fetchable schemes in a subresource); `action`, an HTTP/HTTPS action scheme, and a GET/POST method on every form; permitted input types; form `pattern` bounds against lookarounds and backreferences; the HTTPS requirement for forms carrying a password; allowed `autocomplete` tokens; and whether there are enough `label` elements for the labelable inputs. HTML comments are stripped before inspecting markup.

## What it does not check

It evaluates regular expressions over source text, not a full HTML tree builder, and it evaluates no CSS cascade. It therefore cannot see whether a `label` is associated with the *right* control, malformed tag nesting that regexes pass over, or complex computed styles. It also cannot resolve a document's own origin, so it reports any absolute subresource URL rather than only genuinely cross-origin ones — use relative URLs for same-origin assets (§7.2 RECOMMENDS this anyway). External style sheets are not fetched, so only embedded `<style>` blocks are inspected. It does not validate full HTML5 structural correctness — run a standard validator for that, as spec §2.6 intends. A clean report here means "nothing detectable is wrong," not "conforming."

Treat it as a fast first filter and a starting point, not as the deliverable §2.6 describes.

## Test corpus

The suite has three sections: positive fixtures that must conform, negative fixtures that must fail with a named rule, and classification fixtures in `tests/classify/` whose filename states the §2.6 state they must be reported as. Every HTML document in the repository conforms, and `check-repo.sh` is how that stays true:

```
tools/validator/check-repo.sh
```

It validates all of them and exits non-zero if any fails.

### Automated checks

To run checks automatically before every local commit, configure git to use the repository's hooks directory:

```bash
git config core.hooksPath .githooks
```

## Conformance test suite

A comprehensive suite of positive and negative fixtures lives under `tools/validator/tests/`:
- `tests/valid/` — positive fixtures covering minimal documents, nested CSS parentheses, spaced attribute values, hidden inputs, full element allowlists, media queries, print stylesheets, password forms, and data URLs with delegated schemes.
- `tests/invalid/` — negative fixtures covering forbidden elements (`script`, `iframe`, `noscript`), forbidden attributes, inline styles, author `!important`, CSS `@import`, `url()` in `@media`, `local()` and remote `@font-face`, `:visited` background images and non-color properties, forbidden CSS properties, enumerated value violations, forbidden pseudo-classes and pseudo-elements, invalid units, gradients, keyframes, `var()`, missing structural tags, image `alt` requirements, cross-origin images, invalid `data:` image MIMEs, form methods/actions, invalid input types, pattern lookaheads, invalid link schemes, and label counts.
- `tests/classify/` — classification fixtures verifying §2.6 Conforming, Extended, and Non-conforming state detection.
- `tests/css/` — standalone style sheet fixtures testing property allowlists and custom properties.
- Automated drift checks verifying that static Section 6.2 enumerated values, Section 6.3 selectors, and Section 6.4 units in the validator match `doc/webveld-spec.md`.

Run the test suite:

```bash
lua tools/validator/test-validator.lua
```

## Render Conformance Coverage Audit

Note that `verify-conformance-coverage.lua` is a specification coverage audit for the **Render Conformance Suite** in `conformance/`, **not** an audit of the validator's own rule enforcement. It scans the visual rendering fixtures in `conformance/` to confirm that every element in §4.3, attribute in §5, property and enumerated value in §6.2, selector in §6.3, unit in §6.4, and media feature in §6.6 is represented in the rendering test pages. The validator's own rule enforcement is tested separately by `test-validator.lua` against the test corpus above.

```bash
lua tools/validator/verify-conformance-coverage.lua
```
