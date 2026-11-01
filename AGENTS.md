# Agent instructions

Guidance for any AI agent working on WebVeld. Read this before changing the specification, profiles, documentation, or validator.

## Commands

- Syntax-check all Lua tools: `make`
- Full test suite (run before every commit): `make test`
- Validator tests only: `lua tools/validator/test-validator.lua`
- Profile checker tests only: `lua tools/validator/test-profile-check.lua`
- Validate files: `lua tools/validator/webveld-validate.lua FILE...` (add `--classify` for Conforming / Extended / Non-conforming)
- Check a profile: `lua tools/validator/webveld-profile-check.lua --profile=nano|pico FILE...`
- Every HTML page in the repository: `tools/validator/check-repo.sh`
- Regenerate man pages from their scdoc sources: `make man` (requires `scdoc >= 1.11.5`)
- Reproducible source tarball in `build/dist/`: `make dist`
- Reproducible installed-image tarball in `build/dist/`: `make dist-bin`

## Boundaries

- **Always:** run `make test` before committing; keep the validator and the spec in agreement; follow spec §2.7 when a change affects conformance.
- **Ask first:** any normative change to the spec or profiles; any change to a cardinal rule or to the fixed decisions below; adding a dependency; anything the spirit test below doesn't settle.
- **Never:** push or tag without being asked; commit scratch notes or chat transcripts; add files specific to one AI tool (this file is the single, tool-neutral source of agent guidance).

## Sources of truth

1. **[`doc/webveld-spec.md`](doc/webveld-spec.md)** is the only normative authority for the full `webveld` profile. **[`doc/profiles/`](doc/profiles/)** are normative for `webveld-nano` and `webveld-pico`.
2. **[`tools/validator/`](tools/validator/)** must enforce exactly what the spec says. If the validator and the spec disagree, that is a bug in one of them. Report it and fix one side; don't leave them apart.
3. Everything else (README, motivation, implementation guide, roadmap, related work, man pages, tool READMEs) is informative and **follows** the spec. Never introduce a requirement, number, or claim in a companion document that the spec doesn't make. Restate it and cite the spec section instead.

When a companion document disagrees with the spec, change the companion document unless the user says otherwise.

When the spec or a profile changes, check everything that describes it, not just the Markdown documents: `README.md`, `doc/*.md`, the man page sources (`doc/man/*.scd`, then `make man`), task tracking in `doc/tasks/`, tool and test READMEs, the explanatory text in `conformance/` and `examples/` pages, and the bash completions. Search with `rg` across the whole repository for the old wording.

Documents in `doc/research/` are dated snapshots: each states the spec version it was measured against. Don't rewrite their measurements to match later decisions; if a claim no longer holds, add a short dated note at the top pointing to the current spec.

## Resolving ambiguity: the "spirit" test

When the spec is unclear, or two readings are both defensible, prefer the option that:

- **costs nothing to implement**: it uses machinery a browser already needs, adds no new algorithm or parser, and
- **is neutral or positive for parity and for privacy and safety** (the three cardinal rules, spec §3.1): no new request, no new tracking signal, no new code path.

Anything that adds engine work, a fetch, or a parser is a **candidate**, not a clarification, and goes through the feature freeze in [`doc/webveld-roadmap.md`](doc/webveld-roadmap.md). The roadmap's four tests for a "completion" spell this out.

Worked examples from past decisions:

- CSS-wide keywords: `inherit`, `initial`, and `unset` are permitted on every property (cascade engines already need them). `revert` is not, because it needs origin tracking.
- `data:image/png` is permitted for `link rel="icon"`: it saves a request and reuses the PNG decoder.
- Browsers refuse **all** cross-origin subresources, not just fonts. Privacy wins over convenience.

If the reasoning doesn't settle it, ask the user. Don't guess on normative changes.

## Fixed decisions

- WebVeld has **three profiles**: `webveld` (full), `webveld-nano`, and `webveld-pico`. Never call them tiers.
- **Parity** means visually identical *to a reader* (same content and structure, hard to tell apart), **not** pixel-identical. Don't write "render identically" or "100% parity".
- **Implementability numbers are rough guides.** Use the canonical wording everywhere: about 40,000 / 20,000 / 10,000 lines of engine code for full / nano / pico, not counting standard libraries for TLS, image decoding, fonts, and windowing. Don't add component breakdowns, "assembled" totals, or more precise figures.
- **Don't repeat counts** (number of elements, properties, input types, fixtures) in prose. The validator prints them; prose copies go stale.
- `webveld-pico` admits exactly one `meta name`: `viewport`, with content `width=device-width, initial-scale=1`, so pico pages are readable on phones in mainstream browsers. No other `meta` names. In every profile, a viewport may not disable zoom (`user-scalable`, `maximum-scale`).
- A profile only removes features from the spec; it never adds syntax or redefines behavior.

## Writing style

- Simple, clear text over exhaustive prose. One idea per sentence; cut rhetorical flourishes.
- Each fact lives in one place. Elsewhere, link to it rather than restating it in different words.
- American spelling (`color`, `behavior`), matching CSS.
- In the spec, cite sections as `§6.2` (`§§4–9` for ranges). In companion documents, write `spec §6.2`.
- Name the cardinal rules as "rule 1 (parity)", "rule 2", or "rule 3", not "Cardinal Rule 1".
- BCP 14 keywords (MUST, SHOULD, MAY) belong in normative documents only. In informative documents, either restate a spec requirement with its citation or use lowercase.
- Markdown paragraphs are one line each; don't hard-wrap.
- Man pages are written in scdoc: edit `doc/man/*.scd`, never the generated roff, then run `make man` and commit both. Keep them ASCII (write "spec section 2.6", not `§2.6`), because roff is not reliably UTF-8. `make test` checks that committed roff matches its scdoc source, skipping the check if `scdoc` is missing or older than 1.11.5.

## Editing traps

The validator and its tests **parse the spec at run time**. Before editing these parts, check what reads them:

| Spec text | Read by | What to watch |
| --- | --- | --- |
| §4.3 (whole section) | validator, coverage audit | Every backticked word becomes an allowed element; do not backtick other words. |
| §5.1 (whole section) | validator | Every backticked word becomes a global attribute. |
| §5.2 table and input types | validator | Parenthetical text in table cells is ignored. |
| §6.2 bold groups (`**Name:** ...`) | validator, drift tests | Property lists and `prop` (`value`, ...) enumerations are parsed. |
| §6.3 selectors, §6.4 units | drift tests | Must match validator static tables. |
| Profiles: R1 table, R3 properties | profile checker guard | Must match checker transcribed lists. |

Validator messages cite spec item numbers (e.g. `2.3.7`, `2.3.15`). Don't renumber the §2.3 and §2.4 lists without updating the messages and fixtures.

## Validator changes

- Work test-first: add a fixture under `tools/validator/tests/invalid/` with an `expect:` comment holding the exact message (and a positive case under `tests/valid/` if the check could over-reject), watch it fail, then implement.
- Every HTML document in the repository must conform; `check-repo.sh` checks this. A new check that rejects existing repository pages has found a spec question, not just a bad page. Settle it with the spirit test above.
- The repository's pre-commit hook runs the repository checks once enabled with `git config core.hooksPath .githooks`.

## Versioning

Follow spec §2.7. Editorial changes are PATCH. A newly permitted value or a new browser requirement is MINOR. Removing or restricting anything is MAJOR (any release may change conformance before 1.0.0, but say so). Bump the spec version and date, add a row and a bullet list to Appendix B, then run `make man` (the man pages take their version from the spec) and commit the regenerated pages. Profiles carry their own versions.

## Repository notes

- `make dist` and `make dist-bin` build only from the committed `HEAD`; uncommitted and untracked files never ship, so commit first.
- `make dist` produces `webveld-<ver>.tar.xz` (source) and `make dist-bin` produces `webveld-<ver>-noarch.tar.xz` (the installed files; nothing is compiled, so they are architecture-independent), updating `SHA256SUMS`. `<ver>` is the tag without its `v` if `HEAD` is tagged, otherwise `<spec version>-g<commit>`. The tarballs are reproducible: the same commit always gives byte-identical files. Keep it that way: don't add timestamps, hostnames, or anything else that varies between builds. It needs GNU tar and xz.
- `build/` and `tmp/` are generated.
- Use rg (ripgrep) for searching; BusyBox grep lacks some GNU options.
