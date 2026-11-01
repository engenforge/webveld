---
project: webveld
status: Active
sprint: Sprint 1.0 (Specification Exit Criteria)
date: 2026-10-31
---

# Active Sprints

## Sprint 1.0: Specification 1.0.0 Exit Criteria

`doc/webveld-roadmap.md` sets three exit criteria for 1.0.0: at least one conforming browser, at least two published multi-page sites by people other than the specification authors, and a stability commitment.

- [ ] (A) +browser @engine Implement first conforming WebVeld browser
    > **Created:** 2026-10-31
    > **Context:** Roadmap exit criterion 1 (implementer proof): a browser that meets every browser requirement of spec §2.4, passes the render conformance suite, and enforces spec §8.
    > **Notes:** Must cover every allowed element (spec §4.3), CSS property (spec §6.2), form handling (spec §5), and the privacy and transport rules (spec §§7–8). Candidates are a vendored and hardened Blitz, or a purpose-built engine of about 40,000 lines (spec §3.1).

- [ ] (A) +tools @authoring Implement a WebVeld authoring adapter
    > **Created:** 2026-10-31
    > **Context:** Supports roadmap exit criterion 2 (author proof), which requires at least two published multi-page sites by people other than the specification authors that declare WebVeld conformance and validate as part of publishing. A ready-made pipeline lowers the barrier for those authors.
    > **Notes:** Integrate WebVeld validation into a minimalist static site generator (e.g. luasmith, Hugo, or Zola) so it emits conforming HTML and CSS.

- [ ] (B) +tools @validator Report the narrowest profile a document satisfies
    > **Created:** 2026-10-31
    > **Context:** `webveld-profile-check` checks a document against a profile you name. Authors would also benefit from being told which profile (`webveld-pico`, `webveld-nano`, or full `webveld`) a document already satisfies.
    > **Notes:** Auto-detect the narrowest profile and report what stands between the document and the next narrower one.

- [ ] (B) +tools @extension Prototype browser preview extension
    > **Created:** 2026-10-31
    > **Context:** Authors benefit from previewing existing documents under WebVeld rules inside standard browsers.
    > **Notes:** Build a lightweight web extension to simulate WebVeld and its profiles by disabling scripts and highlighting non-conforming elements or styles.
