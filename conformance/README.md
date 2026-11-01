# WebVeld Render Conformance Suite

The Render Conformance Suite provides visual rendering fixtures covering the complete WebVeld document and styling specification ([doc/webveld-spec.md](../doc/webveld-spec.md)).

While `tools/validator/` checks semantic syntactic conformance according to the grammar and allowlists, this suite exercises what an engine actually paints on screen. It serves as the baseline for rendering diffs against reference engines (e.g. headless Chromium) to enforce **rule 1 (parity)** (spec §3.1).

## Design Principles

1. **Section Isolation:** Each fixture corresponds to one specification section, isolating feature sets so that any visual difference in a diff localizes the fault to a specific capability.
2. **Exaggerated Visual Presentation:** A render fixture must fail *visibly*. Tests employ exaggerated values (e.g. 16px `letter-spacing`, 40px `word-spacing`, 16px `border-spacing`, 60px line-height containers with baseline reference lines for `vertical-align`, high-contrast borders and backgrounds) so that partial or missing implementations cannot hide in sub-pixel subtleties.
3. **Strict Document Conformance:** Every test page in this directory is itself a conforming WebVeld document, validated locally by `tools/validator/webveld-validate.lua` and included in the repository check suite (`tools/validator/check-repo.sh`).

## Test Fixtures

- [`section-4.3-elements.html`](section-4.3-elements.html) (§4.3 Allowed Elements) — All allowed elements across metadata, sectioning, tables, and forms.
- [`section-5-attributes.html`](section-5-attributes.html) (§5 Attributes) — Global (§5.1) and element-specific (§5.2) attributes, all input types.
- [`section-6.2-properties.html`](section-6.2-properties.html) (§6.2 Allowed Properties) — Permitted CSS properties, values, box model, flexbox, and grid.
- [`section-6.3-selectors.html`](section-6.3-selectors.html) (§6.3 Allowed Selectors) — All selectors, combinators, pseudo-classes, and pseudo-elements.
- [`section-6.4-units.html`](section-6.4-units.html) (§6.4 Allowed Units) — Absolute, relative, viewport units, and calc() expressions.
- [`section-6.6-media-queries.html`](section-6.6-media-queries.html) (§6.6 Media Queries) — Dimension features, prefers-color-scheme, and media types.

## Verification Tools

To verify that the suite fully complies with the specification:

```sh
# Validate document structure and rules across the repository
tools/validator/check-repo.sh

# Run comprehensive coverage audit (asserts 100% feature coverage)
lua tools/validator/verify-conformance-coverage.lua
```
