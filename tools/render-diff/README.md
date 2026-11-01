# Render Conformance Diff Harness: Blitz vs Chromium (Calibrated via Firefox)

Two tools with different jobs:

| | measures | is a bar? |
| --- | --- | --- |
| `compare_content.lua` | content, structure, geometry | **yes** — this is rule 1 (parity) |
| `run_diff.lua` | pixel difference (AE, RMSE) | no — a diagnostic that localizes a fault |

Spec §3.1 says parity means the same content, structure, and meaning, rendered so a reader would struggle to tell the browsers apart, and that it *"does not mean identical pixels: browsers differ in default fonts, form control chrome, scrollbars, and focus rings."* A pixel metric therefore cannot be the bar: it fails on font rasterization that does not matter and passes a `caption` that vanished. `compare_content.lua` compares what §3.1 names — the text a reader receives, the elements that actually got laid out, and box positions within a tolerance — and `run_diff.lua` remains genuinely useful for looking at *where* a difference is once the first tool says there is one.

```sh
lua tools/render-diff/compare_content.lua conformance/*.html tools/render-diff/fixtures/*.html
```

Automated rendering parity test harness comparing Blitz against headless Chromium to enforce and measure rule 1 (parity), calibrated against a headless Firefox reference noise floor.

## Overview

The harness renders HTML documents through:
1. **Headless Chromium** (`chromium --headless=new --no-sandbox`)
2. **Headless Firefox** (`firefox --headless --screenshot`) — establishing the inter-engine reference noise floor
3. **Blitz** (`conformance_render` offscreen renderer using `anyrender_vello_cpu`)

All engines render at identical viewport dimensions (default 800×1000 at 1.0 scale). The output PNGs are compared pixel-by-pixel using ImageMagick:
- **Absolute Error (AE)** with 5% fuzz (tolerating minor subpixel font rasterization anti-aliasing variations)
- **Root Mean Squared Error (RMSE)** measuring overall visual distortion

## Test Suites

The runner tests these conforming fixtures:
- `conformance/*.html` (section-isolated fixtures covering every WebVeld element, attribute, property, selector, unit, and media query)
- `tools/validator/tests/valid/*.html` (specification-valid document fixtures)
- `tools/render-diff/fixtures/*.html` (conforming fixtures testing known or suspected gaps: `vertical-align`, `caption-side`, `overflow: auto`, `text-transform`, `empty-cells`, `white-space`, form/table elements)
- `tools/render-diff/probes/*.html` (documents that are deliberately not conforming, for characterizing upstream behavior a conforming document cannot reach — run with `--include-probes`; see [`probes/README.md`](probes/README.md))

## Calibration: Firefox Inter-Engine Reference Noise Floor

To determine what visual diff numbers mean in practice, the harness compares Firefox (Gecko) against Chromium (Blink) over the conforming fixtures under identical fontconfig resolution. The table below was measured on 2026-09-08 against the 22 fixtures that existed then. The resulting distributions establish the baseline rasterization noise floor:

| Cohort | Metric | Min | Max | Mean | Median |
| --- | --- | ---: | ---: | ---: | ---: |
| **Valid Fixtures (9)** | **Firefox noise floor** | **0.05%** | **2.31%** | **0.75%** | **0.27%** |
| | Blitz vs Chromium | 0.04% | 1.81% | 0.64% | 0.26% |
| **Conformance Suite (6)** | **Firefox noise floor** | **3.26%** | **8.15%** | **5.30%** | **5.39%** |
| | Blitz vs Chromium | 3.15% | 8.11% | 5.24% | 5.33% |
| **Targeted Gaps (7)** | **Firefox noise floor** | **0.80%** | **3.96%** | **2.29%** | **1.96%** |
| | Blitz vs Chromium | 0.87% | 4.01% | 2.07% | 1.53% |
| **All Conforming (22)** | **Firefox noise floor** | **0.05%** | **8.15%** | **2.48%** | **1.99%** |
| | Blitz vs Chromium | 0.04% | 8.11% | 2.35% | 1.60% |

### Why the Pixel Metric Screens Nothing

1. **Blitz is at or below the inter-engine noise floor:** On valid documents, Blitz differs from Chromium by a median 0.26% (Firefox is 0.27%). On dense conformance fixtures, default UA stylesheets produce a 5.3% floor, which Blitz matches (5.24% mean). Blitz renders supported features as closely to Chromium as Firefox does.
2. **Missing features hide inside the noise floor:** In `fixtures/01-vertical-align.html` (where Blitz has zero vertical-align offset) and `fixtures/02-caption-side.html` (where Blitz drops table captions entirely), Blitz's pixel diff is 0.87% and 1.12%. But Firefox's noise floor on those same files is 0.80% and 1.31%. A fatal structural or styling failure affecting an inline span or caption accounts for < 1.5% of the viewport—completely drowned out by normal inter-engine subpixel antialiasing differences.

Hence, `run_diff.lua` is strictly a visual diagnostic tool, and `compare_content.lua` remains the only valid conformance bar.

## Prerequisites

- **Chromium** (headless)
- **Firefox** (headless)
- **ImageMagick** (`compare`, `magick`)
- **Lua** (5.4+)
- **Rust toolchain** (1.91+) and the `conformance_render` example, whose source is kept in [`blitz-example/`](blitz-example/) and pinned to Blitz commit `a980f318`:
  ```sh
  cp tools/render-diff/blitz-example/conformance_render.rs ../blitz/examples/
  cargo build --release --example conformance_render --manifest-path ../blitz/Cargo.toml
  ```

## Usage

```sh
# Run the entire conforming suite with Firefox calibration
lua tools/render-diff/run_diff.lua

# Include non-conforming probes
lua tools/render-diff/run_diff.lua --include-probes

# Run only the conformance suite
lua tools/render-diff/run_diff.lua --conformance-only

# Run only the validator valid fixtures
lua tools/render-diff/run_diff.lua --valid-only

# Run only the isolated gap fixtures
lua tools/render-diff/run_diff.lua --fixtures-only

# Run without Firefox (skip calibration)
lua tools/render-diff/run_diff.lua --no-firefox

# Run a single fixture
lua tools/render-diff/run_diff.lua --file conformance/section-4.3-elements.html
```

Rendered images and diff masks are saved to `tools/render-diff/output/` alongside a machine-readable `summary.json`.
