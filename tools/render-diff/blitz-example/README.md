# `conformance_render`

The offscreen renderer the diff harness drives Blitz through. It is WebVeld's code, not Blitz's — it lives here so that the findings in [`../../../doc/research/blitz-assessment.md`](../../../doc/research/blitz-assessment.md) §4 can be reproduced, which they could not while it existed only as an untracked file in a sibling checkout.

**Pinned against Blitz commit `a980f318`** ("Upgrade to Winit 0.31-beta.3s", 2026-09-08), the commit the assessment names as its subject. It uses `anyrender_vello_cpu` so rendering is deterministic and needs no GPU.

```sh
cp tools/render-diff/blitz-example/conformance_render.rs ../blitz/examples/
cargo build --release --example conformance_render --manifest-path ../blitz/Cargo.toml
```

Usage: `conformance_render <input_html_or_url> <output_png> [width=800] [height=600] [scale=1.0]`

If it stops compiling against a newer Blitz, that is worth recording rather than silently fixing: the assessment's measurements belong to the pinned commit, and a rebuild against a different one is a different measurement.
