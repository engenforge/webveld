---
project: webveld
status: Baseline
date: 2026-10-31
---

# Specification Milestones

- [x] (A) +spec Establish WebVeld normative specification and cardinal rules
    > **Completed:** 2026-09-12
    > **Context:** Formalized `doc/webveld-spec.md` governed by Parity, Implementability, and Reader Privacy/Safety.

- [x] (A) +spec Formalize Pico and Nano restriction profiles
    > **Completed:** 2026-09-12
    > **Context:** Established the restriction profiles `webveld-pico` (semantic text) and `webveld-nano` (styled document flow).

- [x] (A) +tools Reference conformance validator and profile checker
    > **Completed:** 2026-09-15
    > **Context:** Built reference implementation `tools/validator/webveld-validate.lua` and `tools/validator/webveld-profile-check.lua` parsing allowlists directly from spec text.

- [x] (A) +conformance Render conformance test harness and coverage suite
    > **Completed:** 2026-09-15
    > **Context:** Created section-by-section conformance pages covering every allowed element, attribute, CSS property, selector, unit, and media query, with a coverage audit.
