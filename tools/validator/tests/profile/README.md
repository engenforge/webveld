# Profile fixtures

Corpus for [`webveld-profile-check.lua`](../../webveld-profile-check.lua). Run it with [`test-profile-check.lua`](../../test-profile-check.lua).

| Fixture | Must |
| --- | --- |
| `pico-pass.html` | conform to pico (every R1 element and permitted viewport) |
| `nano-pass.html` + `nano-pass.css` | conform to nano (all R3 groups, selectors, ARIA, and color schemes) |
| `pico-fail-elements.html` | be rejected by pico (`div`, `span`, `img`, `link`, `style`) |
| `pico-fail-attributes.html` | be rejected by pico (`class`, `dir`, `title`, non-viewport `meta`) |
| `pico-fail-viewport.html` | be rejected by pico (invalid viewport parameters) |
| `nano-fail-elements.html` | be rejected by nano (sectioning, table, form, `details`) |
| `nano-fail-attributes.html` | be rejected by nano (`tabindex`, inline `style`, forbidden attrs) |
| `nano-fail.css` | be rejected by nano (`@font-face`, width query, forbidden CSS) |

**The negative fixtures are profile-negative, not spec-negative.** Every one of them uses constructs the full specification permits and a profile removes, and the test runner asserts that by validating them against `webveld-validate.lua` too. A fixture that failed the specification would test nothing about the profile. `nano-fail-attributes.html` is the one exception, named in the runner rather than quietly excluded: it carries an inline `style` attribute, which §6.1 forbids outright.

The three `nano-fail-*` fixtures came from the `webveld-template` site build with the checker; `nano-fail-elements.html` gained a `label` on the way in, because §9 requires one and the fixture was failing the specification for a reason unrelated to what it tests.

**0.8.0 moved four of these.** `rel="icon"`, `rel="alternate"`, the ARIA set and the sectioning elements were negative fixtures until the profile admitted them, and `@media` went from wholly excluded to admitted for one condition. The negatives were rewritten rather than deleted: a fixture that tests a construct the profile now permits is worse than no fixture, because it passes for the wrong reason and nobody notices.
