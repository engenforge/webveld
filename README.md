![WebVeld logo](media/logo/webveld-logo.png)

# WebVeld

**Version:** 0.10.1

WebVeld is primarily a specification defining a minimal subset of HTML and CSS. It is not a new markup language, protocol, or URL scheme. Every construct in WebVeld is standard HTML5, CSS, and HTTP. A WebVeld document is an ordinary web page that stays inside a small, verifiable boundary.

---

## Why WebVeld

The web was originally built to deliver hyperlinked documents, but it has grown into an application platform of large scripts, tracking networks, and browsers with tens of millions of lines of code. In short, it's becoming more and more difficult for average users to browse the web in a positive way.  Its also become almost impossible for small teams to develop compatible browsers for the modern web.

Existing minimalist alternatives such as [Gopher](https://en.wikipedia.org/wiki/Gopher_(protocol)) or [Gemini](https://geminiprotocol.net) use protocols and document formats that make them less accessible to typical users. That creates a parallel internet: readers need special software, and publishers have to maintain different copies of their content for different audiences.

WebVeld takes the opposite approach: **a WebVeld page is an ordinary web page**. Chromium, Firefox, and Safari render it today. At the same time, the specification is small enough that one developer or a small team can build a browser for it.

## The cardinal rules

Every constraint in WebVeld follows from three rules (spec §3.1):

1. **Parity** — A WebVeld document looks the same in a WebVeld browser and in an unmodified modern browser, with no plugin, polyfill, or script. WebVeld is a subset of the web, never a fork of it.
2. **Implementability** — The specification stays small enough that one developer or a small team can build a complete browser: about 40,000 lines of engine code.
3. **Privacy and safety of the reader** — These come before author convenience. Anything that creates a tracking signal, a code-execution path, or a new class of untrusted parsing is rejected.

WebVeld restricts syntax; it never redefines behavior.

---

## How to use WebVeld

If you are creating a website or blog, you can use the WebVeld spec to choose which HTML features to use to share your content.  In addition this repository includes scripts that can be used to check your html content to see if it complies with WebVeld and if not, the scripts will identify specific things that are outside WebVeld.

If you want to implement a web browser, the WebVeld spec may be a good target for defining a useful browser that respects user privacy and can be built in a reasonable timeframe.

---

## Example sites that are WebVeld compliant

<https://engenforge.com>

<https://git.engenforge.com/webveld>

---

## Three WebVeld profiles

The are three profiles within WebVeld and the profiles nest: `webveld-pico` ⊂ `webveld-nano` ⊂ `webveld`. A narrower profile only removes features; it never adds syntax or redefines behavior. So every `webveld-pico` document is also a `webveld-nano` and `webveld` document, and every conforming `webveld` browser renders all three.

- [**`webveld`**](doc/webveld-spec.md) (**The default**, ~40,000 lines engine code)
  - **For publishers:** Static sites, documentation, forms.
  - **For browser developers:** A complete minimalist browser.
  - **Capabilities:** Flexbox, a bounded CSS grid subset, tables, accessible forms, `details`/`summary`, media queries, self-hosted fonts. No positioning, floats, or CSS variables.
- [**`webveld-nano`**](doc/profiles/webveld-nano.md) (~20,000 lines engine code)
  - **For publishers:** Styled essays, blogs, and articles.
  - **For browser developers:** A graphical reader without flexbox, grid, tables, or forms.
  - **Capabilities:** Linear-flow box model, typography, colors, same-origin PNG/JPEG images, light/dark color schemes.
- [**`webveld-pico`**](doc/profiles/webveld-pico.md) (~10,000 lines engine code)
  - **For publishers:** Text-first, low-bandwidth, and archival publishing. Similar to gopher and gemini in terms of simplicity.
  - **For browser developers:** A terminal, e-ink, or low-bandwidth reader.
  - **Capabilities:** Headings, paragraphs, lists, quotes, preformatted text, and links. No author CSS, no subresources.

**Which one?** If unsure, choose `webveld`. A `webveld` page is still readable in a pico browser, but choosing `webveld-nano` or `webveld-pico` means your page renders exactly as intended in the smallest browsers.

Engine sizes are rough guides to the browser's own code, not counting standard libraries for TLS, image decoding, fonts, and windowing.

---

## Documentation Guide

The project's design, specification, and empirical research live in [`doc/`](doc/):

### Specification and guides
- **[`doc/webveld-spec.md`](doc/webveld-spec.md)** — **The normative specification** and the only authority on conformance.
- **[`doc/profiles/`](doc/profiles/)** — **The restricted profiles**, each defined purely by removal from the specification:
  - **[`webveld-nano.md`](doc/profiles/webveld-nano.md)** — styled documents.
  - **[`webveld-pico.md`](doc/profiles/webveld-pico.md)** — semantic hypertext.
- **[`doc/webveld-motivation.md`](doc/webveld-motivation.md)** — **Why WebVeld exists**: the problems it addresses, the trade-offs, and the alternatives that were rejected.
- **[`doc/webveld-implementation.md`](doc/webveld-implementation.md)** — **Implementation guide**: engine sizing, architecture, and how to meet the harder requirements.
- **[`doc/webveld-roadmap.md`](doc/webveld-roadmap.md)** — **Roadmap**: the feature freeze, candidate features, and the 1.0.0 exit criteria.
- **[`doc/webveld-related-work.md`](doc/webveld-related-work.md)** — **Related work**: Gemini, Gopher, Dillo, NetSurf, and earlier minimal web profiles.

### Research
- **[`doc/research/implementability-continuum.md`](doc/research/implementability-continuum.md)** — Measurements of eight browser codebases, from Gemini clients (Amfora, Lagrange) to Blitz, Dillo, NetSurf, Servo, and Chromium, behind the implementability budget.
- **[`doc/research/blitz-assessment.md`](doc/research/blitz-assessment.md)** — Assessment of Blitz as an implementation base, empirical rendering diffs, and feature analysis.
- **[`doc/research/blitz-removal.md`](doc/research/blitz-removal.md)** — Research on automated removal of excluded features from a vendored Blitz engine.
- **[`doc/research/dillo-assessment.md`](doc/research/dillo-assessment.md)** — Evaluation of Dillo 3.3.0-rc1 against the implementability budget.
- **[`doc/research/minimalist-ssg-assessment.md`](doc/research/minimalist-ssg-assessment.md)** — Primary-source audit of six minimalist static site generators and Markdown pipelines.
- **[`doc/research/webveld-corpus-study.md`](doc/research/webveld-corpus-study.md)** — Empirical feature usage analysis across 103 size-budget sites.
- **[`doc/research/text-browser-assessment.md`](doc/research/text-browser-assessment.md)** — What Lynx, w3m and Links do with the constructs the profiles argue about, measured rather than assumed.
- **[`doc/tasks/`](doc/tasks/)** — Task management using Taskmark ([`active.tm.md`](doc/tasks/active.tm.md), [`future.tm.md`](doc/tasks/future.tm.md), [`completed.tm.md`](doc/tasks/completed.tm.md)).

---

## Examples & Tooling

- **[`examples/minimal-site/`](examples/minimal-site/)** — A complete multi-page conforming site demonstrating navigation, accessible forms, responsive layout without positioning, and embedded stylesheets.
- **[`examples/payment_processor/`](examples/payment_processor/)** — A scriptless checkout flow demonstrating hosted forms and 3D Secure bank authentication using pure HTML/CSS.
- **[`tools/validator/`](tools/validator/)** — The reference conformance validator (`webveld-validate.lua`), the profile checker for `webveld-pico` and `webveld-nano` (`webveld-profile-check.lua`), and the repository test runner (`check-repo.sh`).
- **[`tools/text-browsers/`](tools/text-browsers/)** — Cases rendered through Lynx, w3m and Links, for what a construct does at the bottom of the implementability continuum. Findings in [`doc/research/text-browser-assessment.md`](doc/research/text-browser-assessment.md).

### Installation and Testing

WebVeld includes a standard POSIX/GNU `Makefile` supporting `PREFIX`, `DESTDIR`, and granular install targets:

```bash
# Verify tools and syntax:
make

# Run the full test suite (validator, profiles, coverage audit, repo conformance):
make test

# Install tools (webveld-validate, webveld-profile-check), specifications, man pages, and completions:
sudo make install

# Or install to a custom directory without root privileges:
make install PREFIX=$HOME/.local

# Build reproducible release tarballs in build/dist/:
#   webveld-<ver>.tar.xz (source) and webveld-<ver>-noarch.tar.xz (installed files)
make dist
make dist-bin
```

`make dist` (source) and `make dist-bin` (installed files) build from the committed `HEAD`, producing byte-identical tarballs listed in `build/dist/SHA256SUMS`. GNU tar and xz are required.

To validate all repository examples against the specification directly:
```bash
tools/validator/check-repo.sh
```

---

## Repositories & Mirrors

Project website: https://git.engenforge.com/webveld

The primary git repository is hosted on Engenforge infrastructure and mirrored to GitLab and GitHub:
- Primary: `https://git.engenforge.com/webveld.git`
- Secondary: `https://gitlab.com/engenforge/webveld.git`
- Secondary: `https://github.com/engenforge/webveld.git`

Release tarballs (`webveld-<ver>.tar.xz` source, `webveld-<ver>-noarch.tar.xz` architecture-independent package, and `SHA256SUMS`) are published for each version (`<ver>`, tagged as `v<ver>`):
- Primary: `https://get.engenforge.com/webveld/<ver>/<filename>`
- Secondary: `https://gitlab.com/engenforge/webveld/-/releases/v<ver>/downloads/<filename>`
- Secondary: `https://github.com/engenforge/webveld/releases/download/v<ver>/<filename>`

---

## License

WebVeld uses a dual-license model (see [`LICENSE`](LICENSE)):
- **Specification and documentation** are licensed under the [Creative Commons Attribution 4.0 International (CC-BY 4.0)](https://creativecommons.org/licenses/by/4.0/) license.
- **Software, tooling, and examples** are licensed under the [MIT License](https://opensource.org/license/mit).
