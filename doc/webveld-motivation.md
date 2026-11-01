# Why WebVeld Exists

**Companion to:** [webveld-spec.md](webveld-spec.md) · **Status:** Informative

This document makes the case for WebVeld: the problems it responds to, what the specification does about each, the trade-offs, and the alternatives that were considered and rejected. Nothing here is normative; the specification alone defines conformance.

---

## 1. The short version

The web was designed to deliver hyperlinked documents and grew into an application platform. WebVeld treats three consequences of that growth as failures, not facts of life:

- **Almost nobody can build a browser any more.** Modern engines run to tens of millions of lines of code. A small team cannot write one, so the web's implementations belong to a few very large companies.
- **Nobody can browse unobserved.** Fingerprinting, third-party beacons, and cross-site state make ordinary reading a tracked activity.
- **Reading a page is a code-execution risk.** Client-side scripts and in-browser media parsers give attackers a large, well-studied surface on every page load.

WebVeld responds by subtraction. It defines a subset of HTML5 and CSS small enough for one developer or a small team to implement completely, with no scripting, no embedded browsing contexts, and no in-browser media decoding.

## 2. What WebVeld is not

WebVeld is not a new protocol, and this is its defining constraint.

Gemini showed that a clean break is possible, and what it costs: Gemini content is invisible to the browser people already have. That is why Gemini remains a subculture rather than an alternative.

WebVeld makes the opposite bet: **a WebVeld page is an ordinary web page**. Every element, attribute, property, and URL scheme in the specification is standard HTML5, CSS, and HTTP. Chromium, Firefox, and Safari render a WebVeld document today, with no plugin, polyfill, or script, and it looks the same as in a WebVeld browser: same content and structure, with differences in details like default fonts and form controls that a reader would struggle to notice. A minimalist WebVeld browser is a second, much smaller way to read the same bytes, never a prerequisite. [webveld-related-work.md](webveld-related-work.md) surveys the wider field.

This is **parity**, the first of the three cardinal rules in spec §3.1, alongside **implementability** and the reader's **privacy and safety**. A proposal that satisfies all three is eligible; a proposal that only works in a WebVeld browser is rejected however attractive it is. §6 records the significant proposals that failed, and §7 the boundary they leave.

WebVeld comes in three nested profiles (`webveld`, `webveld-nano`, and `webveld-pico`), described in the [specification](webveld-spec.md) and the [README](../README.md#the-three-profiles).

## 3. Problems and what the specification does about them

### 3.1 Implementer complexity and engine monoculture

**The problems**

- **Implementation is out of reach.** The living standard is not something one can finish implementing.
- **Monoculture by barrier to entry.** With effectively three engines, independent operating systems and small devices must embed a browser they cannot audit, or give up on the web.
- **Continuous churn.** Every new interface is a permanent addition to the cost of every future implementation.

**What WebVeld does**

- **A bounded grammar.** Elements and CSS properties are listed exhaustively (spec §4.3, §6.2). The whole surface fits in one document a person can read in an afternoon.
- **Simpler layout.** No floats, no positioning, no script-driven changes. Layout is the box model, flexbox, tables, and a bounded grid subset (spec §6.2).
- **A finishable target.** As a rough guide, a complete browser is about 40,000 lines of engine code (spec §3.1), calibrated against engines that exist ([webveld-implementation.md](webveld-implementation.md)).
- **Stability.** Growth follows explicit versioning rules (spec §2.7). After 1.0.0, a conforming document stays conforming across every 1.x release.

### 3.2 Surveillance and fingerprinting

**The problems**

- **Stateless fingerprinting.** Canvas text metrics, WebGL renderer strings, audio analysis, and font enumeration identify a device without storing anything on it.
- **Fonts as a call home.** A page that loads its typeface from a font CDN tells a third party the reader's IP address and the page they are reading.
- **Third-party telemetry.** A single article commonly triggers dozens of requests to ad networks and data brokers.
- **Cross-site leakage.** Shared storage, referrer headers, and timing APIs let one site infer where a reader has been.

**What WebVeld does**

- **No scripting, so no fingerprinting APIs.** Canvas, WebGL, audio, device enumeration, and timing interfaces cannot be called at all (spec §4.4, §5.3).
- **Self-hosted fonts only.** `@font-face` is permitted, but fonts must come from the site's own origin, and `local()` is forbidden because it allows font enumeration even without script (spec §6.5).
- **Same-origin subresources.** Style sheets, images, and fonts must come from the document's origin or be inline `data:` images, and browsers refuse every cross-origin subresource request, even on non-conforming pages (spec §7.2).
- **No client-side storage.** Pages cannot read or write storage, because nothing in a page runs. Third-party cookies are forbidden (spec §8).
- **No fetches that reveal behavior.** Resources load at page load, never on hover, scroll, or a media-query match (spec §6.6, §7.2).

### 3.3 Security attack surface

**The problems**

- **JIT compilers.** Much of the remote-code-execution risk in modern browsers comes from JavaScript JIT compilation and garbage collection.
- **Drive-by execution.** Scripts enable cryptomining, XSS, credential theft, and malvertising.
- **Framing attacks.** `iframe` and `object` bring cross-origin execution contexts and clickjacking.
- **Codec vulnerabilities.** Parsing untrusted media and document formats inside the browser is a recurring source of memory-safety bugs.

**What WebVeld does**

- **No scripting runtime at all** (spec §2.4, §4.4). There is no sandbox to escape, because the code path does not exist.
- **No embedded contexts.** `iframe`, `embed`, and `object` are forbidden (spec §4.4).
- **No in-browser media parsing.** Media is handed to an external application, which never auto-executes anything that could be code (spec §10).
- **A small, auditable input surface.** A page's entire influence on the browser is a bounded HTML grammar and a bounded CSS grammar.

### 3.4 Bloat, latency, and battery

**The problems**

- **Megabytes for kilobytes of text.** Articles routinely ship megabytes of scripts to display a few paragraphs.
- **Idle CPU burn.** Timers, reflows, and animation loops drain batteries long after the reader stops interacting.
- **Fragile rendering.** Client-side hydration leaves blank screens on poor connections.

**What WebVeld does**

- **Static-first delivery.** Documents arrive as complete HTML and paint on arrival (spec §3.2).
- **Cheap rendering.** No animations, transitions, or filters.
- **Idle means idle.** With no scripting, a page cannot use CPU once it has been laid out.

### 3.5 Developer fatigue and fragile toolchains

**The problems**

- **Dependency hell.** Publishing basic markup now involves package managers, bundlers, and transpilers.
- **Framework churn.** Frameworks obsolete themselves on a short cycle.
- **Blurred boundaries.** Splitting state between server and client multiplies failure modes.

**What WebVeld does**

- **No build step required.** Write HTML and CSS and put the files on any static server.
- **One place for state.** The server holds state; the document displays it; a form submission changes it.
- **Durability.** A conforming document depends on nothing that can be deprecated out from under it.

## 4. Quantifying the reduction

Lines of code is a poor measure of quality but a good proxy for the cost of building, auditing, and maintaining a browser. A modern engine such as Chromium is tens of millions of lines. A complete WebVeld browser is roughly 40,000 lines of engine code, because the specification is all there is to implement.

| Surface | Modern web engine | WebVeld | What the reduction removes |
| --- | --- | --- | --- |
| HTML elements | 110+ | A small fixed list (spec §4.3) | Embedded contexts, media elements, web components, obsolete tags |
| CSS properties | 600+ | A small fixed list (spec §6.2) | Animation, positioning, floats, custom properties, filters |
| Scripting runtime | JIT compiler, garbage collector | **None** | Dominant source of browser exploits and fingerprinting surface |
| Script-reachable APIs | 1,000+ interfaces | **None** | Device access, storage, background networking |
| Media decoding | Codecs inside the browser | **None** (delegated, spec §10) | Memory-safety bugs in untrusted binary parsing |
| Layout | Multi-pass with script invalidation | Box model, flexbox, tables, bounded grid | Layout thrashing and unbounded recalculation |

The most important row is the scripting runtime. Removing it removes the dominant class of browser exploits *and* the dominant class of tracking, by deleting what they operate on.

### 4.1 The implementability budget

The budget is the complexity that one developer or a small team can build, audit, and maintain over a year or two. As a rough guide:

| Profile | Engine code (rough guide) | Comparable to |
| :--- | :--- | :--- |
| `webveld` | ~40,000 lines | Blitz, Dillo |
| `webveld-nano` | ~20,000 lines | A minimalist graphical reader |
| `webveld-pico` | ~10,000 lines | A terminal Gemini client such as Amfora |

These figures count the browser's own code: parsing, style, layout, rendering, and navigation. They do not count standard libraries for TLS, image decoding, font rendering, and windowing. The breakdown by component and the measurements behind it are in [webveld-implementation.md](webveld-implementation.md) and [research/implementability-continuum.md](research/implementability-continuum.md).

## 5. Trade-offs, and the honest case against WebVeld

**"You cannot build an application."** Correct: no single-page apps, live dashboards, or games. Every interaction beyond a link or form is a page load. WebVeld's answer is that most of the web is documents dressed as applications. Where a page really is an application, spec §11 defines the escape hatch: one file serving a scripted experience to modern browsers and, inside `noscript`, an equivalent static path for WebVeld browsers. Such a page is explicitly not conforming, which keeps the boundary clear.

**"Media playback is a regression."** Clicking a video link in a WebVeld browser opens a native player instead of playing in the tab. The page stays open behind the player, so closing the player returns the reader to where they were. Inline playback is not supported at all; embedding a player window in the page was investigated and rejected (§6.3).

**"The design space is austere."** No animation, transforms, positioning, or floats, and grid only as a bounded subset. This is a real cost, paid deliberately: layout is a large share of engine complexity, and much of what it buys is decoration.

**"E-commerce and complex forms will be painful."** Yes. Validation is `pattern` and `required`; cart updates are page loads. Transactional flows are the strongest case for the escape hatch.

**"Accessibility without scripting has limits."** Static semantic HTML with required `alt` text, labels, heading order, and declared language is a strong baseline. What is missing is dynamic focus management and live regions, which WebVeld doesn't need because its pages never change after loading.

## 6. Alternatives considered

Most of these were rejected because they broke parity or brought back the complexity WebVeld exists to remove.

### 6.1 Optional WebAssembly

WebAssembly modules drawing to a `<canvas>`, with the browser supplying the imports, cannot work in a modern browser: WebAssembly has no direct access to the DOM, canvas, or network, so every WASM page on the web relies on JavaScript glue. A WebVeld page using WASM would work in a WebVeld browser and fail in Chromium, which is exactly the outcome WebVeld exists to avoid.

Two rescues were considered and rejected:

- **A standard `webveld.js` polyfill.** It restores parity by requiring JavaScript on every page, which brings back the runtime WebVeld removes.
- **Shipping WASM anyway, with a `noscript` fallback.** Content parity survives, but every interactive page now has two versions to author and keep in step.

### 6.2 A sandboxed "HTML in a box"

A browser-drawn region in which a WASM module renders by handing the engine WebVeld HTML. It keeps text selectable and accessible, and makes spoofing obvious. It failed on parity for the same reason as §6.1, and added new problems: layout thrashing as denial of service, render timing as a fingerprinting channel, and a new API to specify and secure.

### 6.3 Inline media via an embedded player window

Keeping `<video>` while a minimalist browser embeds an external player's window would preserve parity in the markup. In practice, reparenting a foreign window into the page is obstructed by modern compositors, pulls in a heavy GUI toolkit, and adds the kind of attack surface WebVeld is shedding. Media stays forbidden; links and external handlers (spec §10) remain the mechanism.

### 6.4 HTMX-style declarative attributes

Attributes that fetch a fragment and swap it into the page would close much of the application gap without a scripting language. But they aren't in HTML5, so a modern browser ignores them, and parity fails on the first click.

### 6.5 Declarative accessibility bindings

Custom attributes such as `aria-bind-toggle` would let markup update ARIA state without script. They aren't in the standard either, so modern browsers would ignore them, leaving screen reader users worse off in the browser most people use.

### 6.6 Dropping `noscript` entirely

`noscript` is forbidden in conforming documents (spec §2.3): with scripting enabled, a modern browser hides its content while a WebVeld browser shows it, which breaks parity. But it is kept for **extended documents** (spec §2.5, §11). A publisher whose page needs something outside WebVeld can serve one file: the scripted flow for modern browsers, and inside `noscript`, a catalog, a phone number, or an order form for readers without scripts. A WebVeld browser must render that content.

### 6.7 Full CSS Grid and custom properties

Both are layout and parsing work with no privacy or security cost, and both are universally supported, so neither breaks parity. The question is cost.

**Grid is admitted as a bounded subset**: explicit tracks with `fr` and `minmax()`, literal `repeat()`, explicit placement, and simple auto-placement, without named areas or subgrid (spec §6.2). This covers most real-world grid use at a modest cost.

**Custom properties (`var()`) are not yet admitted.** They are the strongest candidate on the roadmap and are waiting on an implementation that can measure their cost; see [webveld-roadmap.md](webveld-roadmap.md).

## 7. The boundary as it stands today

What WebVeld leaves out, and why, measured against the three cardinal rules (spec §3.1). No exclusion is permanent: each is out because no known design for it satisfies all three rules, and each entry says what would have to change.

- **Client-side scripting (JavaScript, WebAssembly)**
  - *Out because:* All three rules. WASM requires JS glue; JIT/runtime is huge; source of most exploits and fingerprinting.
  - *What would let it in:* A scripting model modern browsers run without JS, needing no JIT and exposing no new state or timing signals.
- **In-browser audio and video**
  - *Out because:* Implementability and safety. Complex codecs parsing hostile binary data inside the browser engine.
  - *What would let it in:* A single small, bounded, isolated codec (audio is a possible candidate; video is not).
- **Embedded browsing contexts (`iframe`, `embed`, `object`)**
  - *Out because:* Safety and implementability. Clickjacking, phishing, and complex context isolation.
  - *What would let it in:* No credible design exists; least likely to change.
- **SVG**
  - *Out because:* Implementability. General SVG is essentially a second rendering engine.
  - *What would let it in:* A bounded subset without scripts, external references, or animation (a roadmap candidate).
- **CSS custom properties**
  - *Out because:* Implementability against the current code budget.
  - *What would let it in:* Implementation evidence measuring the cascade and memory cost (a roadmap candidate).
- **Inline `style` attributes**
  - *Out because:* Reader style overrides. Hardest to override; easy to admit later (MINOR), costly to forbid later (MAJOR).
  - *What would let it in:* Evidence that external/head style sheets cause substantial friction for authors.
- **Third-party fonts and resources**
  - *Out because:* Privacy. Every cross-origin request identifies the reader to third parties.
  - *What would let it in:* Nothing; self-hosting already provides fonts and assets safely (spec §6.5).

## 8. Summary

| Failure mode | Modern web | WebVeld |
| --- | --- | --- |
| Engine complexity | Tens of millions of lines; three engines | A small, fixed vocabulary; buildable by a small team |
| Tracking | Canvas, font, storage, cross-site fingerprinting | No scripting, no storage, same-origin resources, self-hosted fonts |
| Security | JIT exploits, XSS, malvertising | No scripting runtime |
| Codec flaws | Untrusted parsers inside the browser | Delegation to external applications |
| Performance | CPU burn, battery drain, layout thrashing | Static pages, no animation, bounded layout |
| Developer experience | Toolchains, bundlers, framework churn | Write files, upload to a static server |
| Reach | A new protocol needs new client software | A WebVeld page is an ordinary web page |
