# Probes

Documents that are **deliberately not WebVeld-conforming**, used to characterize another engine's behavior on constructs the specification forbids. `check-repo.sh` excludes this directory for that reason, and excludes nothing else outside the validator's negative fixtures.

A file belongs here only if the behavior it examines cannot be reached by a conforming document. Anything a conforming document *can* contain belongs in `../fixtures/`, where it is validated with the rest of the repository.

The engine under examination need not be Blitz. `../../text-browsers/run.sh --include-probes` renders this directory through Lynx, w3m and Links for the same reason the render-diff harness renders it through Blitz.

- `position-static.html` — Blitz maps `position: static` to `taffy::Position::Relative` (`stylo_taffy/src/convert.rs:254`), so declared insets shift the box instead of being ignored. Section 6.2 does not list `position`, so no conforming document can trigger this. It is an upstream bug worth reporting, not a WebVeld gap.
- `forbidden-hidden-attribute.html` — section 5.3 forbids the `hidden` attribute and directs authors to CSS `display: none`. Lynx, w3m and Links ignore both and render the content either way, so the replacement §5.3 offers is not one at that end of the continuum. Recorded in [`doc/research/text-browser-assessment.md`](../../../doc/research/text-browser-assessment.md) §3.
