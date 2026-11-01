# Text Browsers as a WebVeld Reference Point

**Subjects:** Lynx 2.9.3 (2026-05-26), w3m 0.5.6, Links 2.30 · **Measured:** 2026-09-13 · **Against:** [webveld-spec.md](../webveld-spec.md) 0.6.0, [webveld-nano.md](../profiles/webveld-nano.md), [webveld-pico.md](../profiles/webveld-pico.md)

[webveld-related-work.md](../webveld-related-work.md) §4 calls Lynx, w3m and Links "the text-mode ancestors," which "demonstrate the durability of the approach more than its ceiling." This document measures what they actually do, because for several open questions they are not just ancestors — they are the only shipped evidence about what happens to a construct at the bottom of the implementability continuum. `webveld-pico` names "terminal clients" as a target audience in its opening line; these are those clients.

Lynx and w3m implement no CSS at all. Links has a partial CSS engine. None of the three has an accessibility tree, media queries, or an element-level scroll container. So the question they answer is not "does this render correctly" but **"what does a reader get from the markup alone, and is it survivable"** — which is the question every exclusion in the two profiles is a bet about.

Reproduction is `sh tools/text-browsers/run.sh`; the cases are in that directory and every one of them conforms to full WebVeld, so they are validated with the rest of the repository. Widths below are 40 columns, which makes wrapping unmistakable; 80 shows the same behavior less starkly.

## 1. Preformatted text: the one that decides something

This is the sharpest result, and it bears directly on whether `overflow-x` belongs in `webveld-nano`.

Rendering a C function whose lines run to 126 characters, at a 40-column render width:

| Browser | `pre` behavior | Longest emitted line |
| --- | --- | --- |
| Lynx 2.9.3 | hard-wraps at the render width | 40 |
| w3m 0.5.6 | does not wrap; extends the canvas | 126 |
| Links 2.30 | does not wrap; extends the canvas | 127 |

**Two of the three refuse to wrap preformatted text**, and instead build a canvas wider than the terminal and let the reader scroll it. w3m documents four keys for this in `/usr/share/w3m/w3mhelp.html` — `>` and `<` shift the screen right and left, `.` and `,` shift one column — and Links' own `-help` text says the dump width is one the document "can still be wider" than.

**Lynx wraps, and the result is not merely untidy.** It breaks mid-token:

```
static int webveld_validate_document(str
uct wv_parser *p, const struct wv_profil
e *profile, unsigned int flags, char **e
rrmsg)
```

`struct` becomes `str` + `uct`; at 80 columns `errmsg` becomes `errms` + `g`. The identifiers are destroyed, not just the indentation, and the text cannot be copied out correctly. Every continuation also resumes at column zero, so a wrapped statement reads as a new one.

**What this settles and what it does not.** It settles that wrapping is the wrong answer for preformatted text: the two engines with more layout machinery both rejected it, and the one that chose it produces corrupt output. It does **not** settle that element-level scroll containers are needed, because what w3m and Links implement is *uncontained, page-level* horizontal scroll — which is exactly what `webveld-nano` produces today, since it permits `white-space: pre` and has no `overflow` property, so the initial `visible` applies and the viewport scrolls. Two mature text browsers independently chose nano's current behavior and have shipped it for decades.

The honest reading is that nano's fallback is survivable and well-precedented, and that the failure mode worth avoiding is Lynx's. Anyone arguing for `overflow-x` in nano should argue from the styled-document case, not from this evidence, which is at best neutral on the prescription.

**One result does favor the addition.** `pre-overflow-x.html` and `pre-long-lines.html` produce byte-identical output in all three browsers: `overflow-x: auto` is ignored and the document degrades to precisely the current behavior. Admitting the property cannot break a minimal reader, because not implementing it *is* the status quo.

## 2. Sectioning elements are free, and mostly invisible

`sectioning-semantic.html` and `sectioning-div.html` carry identical content, one with `header`/`nav`/`main`/`article`/`section`/`aside`/`footer` and one with `div` throughout.

- **w3m:** byte-identical output.
- **Links:** byte-identical output.
- **Lynx:** differs on one line — it centers the `h1` in the semantic version and left-aligns it in the `div` version.

So the cost of the sectioning elements at this end of the continuum is zero or negative: the only observed difference favors the semantic markup, and it is a quirk of Lynx's `div` handling rather than a cost of `header` and friends. `webveld-nano.md` R1 excludes them "for layout budget," and no budget is being spent here.

The corresponding caution is that their *value* is also nil here. Landmarks are an accessibility-tree concept, and none of these browsers has one — a screen reader pointed at a terminal reads characters. The case for the sectioning elements is a case about assistive technology on a graphical browser, and should be made as one.

**Skip links work, and are visible.** All three render `<a href="#content">Skip to content</a>` as an ordinary numbered link; Lynx lists it as `[1]` in its `References` block. The skip link is a native text-browser affordance, which is where the idiom came from. None of the CSS machinery for hiding it (§6.2's `clip-path`, or the `width: 1px` idiom) has any effect here, so the question of which technique works correctly is a graphical-browser question entirely.

## 3. Nothing hides

`hiding.html` exercises every mechanism the specification and the profiles offer. All three browsers render every one of them:

```
VISIBLE-BASELINE
DISPLAY-NONE-TEXT
CLIPPATH-VISUALLY-HIDDEN-TEXT
OVERFLOW-HIDDEN-1PX-TEXT
ARIA-HIDDEN-TEXT
```

`tools/render-diff/probes/forbidden-hidden-attribute.html` adds the one construct a conforming document cannot contain, and the result is the same: **all three ignore the HTML `hidden` attribute too.** That is worth recording, because §5.3 forbids `hidden` and points authors at CSS `display: none` instead, and at this end of the continuum the two are indistinguishable — both do nothing.

Two consequences.

First, the tradeoff §5.3 records is not a tradeoff for these readers, so the `webveld-nano` contradiction — `hidden` forbidden on the grounds that `display: none` replaces it, and `display` excluded in every form — costs a terminal reader nothing. It is a real defect in the profile, and it is a graphical-browser defect.

Second, and more generally: **hiding is a CSS-only capability, and a whole class of conforming browsers cannot perform it.** Nothing safety-relevant may depend on content being hidden. A document that puts something in a `display: none` block because the reader should not see it is publishing it in plain text to every reader on this page.

## 4. `tabindex` is inert; `<style>` does not leak

`tabindex="0"` on a `div` puts it nowhere. Lynx numbers only genuine links — `[1] [2] [3]`, in document order, with a `References` list — and the `tabindex` element is plain text between them. Tab order is the document order of interactive elements in all three, and no attribute changes it.

This is the capability §5.1 admits `tabindex` for ("such as a scrollable container"), and it does not exist here, which follows from §1: there are no element-level scroll containers to put in the tab order.

No `<style>` element content leaked into the rendered text in any browser. Worth knowing, since older text browsers were notorious for it and §6.1 makes embedded style sheets one of only two ways to carry CSS.

## 5. Focus indication, color, and what pico gets right

None of these browsers lets a document affect focus indication. The current link is drawn in reverse video or a configured color, as a property of the renderer, and no markup or style sheet reaches it.

This is exactly the model `webveld-nano.md` claims in its closing note — "that indicator is supplied by the browser, and this profile forbids authors from suppressing it, which they have no mechanism to do anyway" — and it is exactly the model [`webveld-pico.md`](../profiles/webveld-pico.md) R3 states: "In a terminal client this is the cell inversion or cursor position the platform already supplies."

**The difference is that pico's version is true and nano's is not.** Lynx's link highlight is safe from authors because Lynx honors no author colors at all. `webveld-nano` permits `color` and `background-color` unrestricted, so an author can choose a background the browser's default focus ring disappears against — without suppressing anything, and with no remedy available, since the profile excludes `:focus`. The argument was sound at the tier that has no CSS and was carried up one tier without its precondition.

Links and ELinks both ship a "use document colors" toggle, and readers turn it off when an author palette renders badly. That is the same answer §6.1 already gives for author `!important` — **reader override rather than author obligation** — and it is the historical precedent for treating contrast as out of scope in §9 while saying so explicitly.

## 6. Summary

| Construct | Lynx | w3m | Links | Bearing on the specification |
| --- | --- | --- | --- | --- |
| Long lines in `pre` | wraps, splits tokens | canvas + scroll | canvas + scroll | wrapping fails; page-level scroll is well-precedented |
| `overflow-x: auto` | ignored | ignored | ignored | degrades to the status quo; cannot break a minimal reader |
| Sectioning elements | ~identical to `div` | identical to `div` | identical to `div` | free at this tier, and worth nothing at it |
| Skip links | visible link | visible link | visible link | native affordance; the CSS hiding question is graphical-only |
| `display: none` | rendered | rendered | rendered | hiding is CSS-only; never rely on it |
| `clip-path` visually-hidden | rendered | rendered | rendered | likewise |
| `aria-hidden` | rendered | rendered | rendered | no accessibility tree exists |
| `hidden` attribute | rendered | rendered | rendered | §5.3's replacement is no replacement here |
| `tabindex` | inert | inert | inert | no scroll containers to order |
| `<style>` contents | not leaked | not leaked | not leaked | §6.1 embedded sheets are safe |
| Focus indication | renderer-owned | renderer-owned | renderer-owned | pico's rationale holds; nano's does not |

## 7. Reproduction

```sh
sh tools/text-browsers/run.sh                  # all cases, width 40
WIDTH=80 sh tools/text-browsers/run.sh         # the usual terminal width
sh tools/text-browsers/run.sh --include-probes # plus the forbidden-construct probes
```

Each dumped line is prefixed with its length, because the behavior that distinguishes these engines is a property of line length and is invisible when you only read the text.

**What was not measured.** The horizontal scrolling in §1 was established from canvas width and from w3m's documented keybindings, not observed interactively — `-dump` has no terminal. Links' partial CSS support was not characterized; the claim here is only that it ignored every property in these cases. Color rendering was not measured at all, since `-dump` strips it; §5's claims about author colors rest on the absence of a CSS engine in Lynx and w3m, which is documented rather than tested.
