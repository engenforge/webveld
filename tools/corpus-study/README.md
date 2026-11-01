# Corpus study tooling

Scripts behind [../../doc/research/webveld-corpus-study.md](../../doc/research/webveld-corpus-study.md).

1. `fetch.sh` — builds the three-cohort site list (512kb.club members, curated lite sites, a modern comparison set), fetches each home page and up to three of its style sheets into `${STUDY_DIR_WORK:-/tmp/webveld-corpus-study}`.
2. `analyze.lua` — per-site feature detection over the fetched HTML and CSS; prints the percentage tables and writes `out/rows.tsv`.
3. `classify-floats.lua` — extracts every rule containing `float: left|right` and bins it by selector name.
4. `classify-grid.lua` — assigns each grid-using site to the lowest bounded-subset tier that covers its usage, and reports cumulative coverage per tier. The tiers (T0–T3) are levels of the grid subset defined in the study itself ([webveld-corpus-study.md](../../doc/research/webveld-corpus-study.md)), not the withdrawn profile tiers; the script answers what a subset would have to include to be worth adopting, which is a different question from whether grid is popular. It errs toward a higher tier — a declaration present in a stylesheet counts even where nothing matches it — so read its coverage figures as an upper bound on what a subset must cover.

5. `snapshot.sh` — copies a fetched corpus into a cache outside the repository, fingerprints it, and resolves which corpus the analysers should read.

`fetch.sh` expects `512.html` (from <https://512kb.club/>) and `lite.md` (from the awesome-lite-websites README) to have been downloaded to `${STUDY_INPUT_DIR:-/tmp/webveld-corpus-input}` first. Detection is regex over raw CSS, so read the limitations section of the study before quoting any number.

## The corpus cache

Fetched pages are not kept in this repository. They are third-party content, they are bulky, and they are a working artifact rather than part of the specification. They live instead at `${WEBVELD_CACHE:-~/.cache/webveld}/corpus/<label>/`, one directory per run, holding the pages and style sheets as fetched plus a `MANIFEST.tsv` of per-file SHA-256 hashes and a `FINGERPRINT`.

**The cache is a cache.** Nothing in the repository depends on it, it can be cleared at any time, and every script degrades to a clear message when it is gone — at which point you re-fetch and get a new corpus, with a new fingerprint that says so.

```sh
tools/corpus-study/fetch.sh                 # fetch into the working directory
tools/corpus-study/snapshot.sh save         # freeze it into the cache, labelled by date
tools/corpus-study/snapshot.sh list         # what is cached, and each fingerprint
lua tools/corpus-study/analyze.lua          # reads the newest snapshot automatically
lua tools/corpus-study/classify-grid.lua
```

The analysers resolve their corpus in one order: an explicit `STUDY_DIR` if it holds one, then the newest cached snapshot, then whatever `fetch.sh` last wrote. Each prints the directory and fingerprint it read on stderr before any results.

## Why the fingerprint matters

It is what distinguishes a corrected script from a changed population. Re-run an analyzer after fixing a bug and the fingerprint is unchanged, so the two numbers are comparable and the difference is the fix. Re-fetch and the fingerprint changes, so they are not — sites change, and 512kb.club's membership turns over. Without it, a corrected figure silently replaces an older one with no way to tell which kind of change produced it.

Quote it wherever a number is published: `snapshot.sh verify` re-hashes a snapshot against its manifest and exits non-zero on drift, so a cited fingerprint is checkable rather than decorative.

## Provenance

Snapshots are unmodified home pages and style sheets fetched over HTTP from publicly reachable addresses, retained locally as a research record. They are third-party content, nothing in the cache is covered by this repository's licences, and none of it is redistributed — which is the main reason it lives outside the tree.
