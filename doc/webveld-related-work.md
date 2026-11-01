# Related Work

**Companion to:** [webveld-spec.md](webveld-spec.md) · **Status:** Informative · **Surveyed:** September 2026

WebVeld is not the first attempt to make the web smaller. This document surveys the efforts it resembles, borrows from, or deliberately diverges from, and asks one question of each: what does it teach about the three cardinal rules of specification §3.1 — parity with unmodified modern browsers, implementability by a small team, and the privacy and safety of the reader?

Project statuses change. Everything below was checked in September 2026; sources are listed at the end.

## 1. Alternative protocols: Gopher, Gemini, and the smolnet

**What they are.** Gopher (1991) predates the web and survives as a small active community. Gemini (2019) is the modern flagship: a deliberately non-extensible protocol with its own document format, gemtext, and a hard requirement for TLS. Around them sits a cluster of further protocols — Spartan, Nex, Scorpion, Guppy, Titan and others — collectively the "smolnet."

**What they get right.** Gemini's central claim is implementability: a working server or client is a day or two of effort and a few hundred lines. That is the strongest available evidence for WebVeld's rule 2, and it is why the community sustains dozens of independent clients rather than three. Gemini also demonstrates that an audience exists for a deliberately impoverished medium.

**Where WebVeld diverges.** Reach. A Gemini page is invisible to the browser a reader already has; they must install client software before seeing anything at all. Rule 1 is a direct response to that, and it is the single largest design difference between the two projects.

**The other lesson is about austerity.** A 2026 assessment of Gemini notes that its two most-criticized weaknesses are unchanged: mandatory TLS excludes people who might otherwise participate, and gemtext still offers no emphasis and no inline links, requiring each paragraph to be one long line. Gemini is growing but has not set the internet alight. The caution for WebVeld is that a subset can be cut past the point of usefulness, and that authors, not just implementers, have to want to use it. WebVeld keeps the full semantic vocabulary of HTML5 — headings, lists, tables, forms, inline markup — and cuts capability rather than expressiveness.

## 2. Constrained markup profiles inside the web: cHTML, WML, XHTML-MP

**What they were.** The mobile era produced the closest historical analogues to WebVeld. Compact HTML (cHTML) was a subset of HTML 3.2 defined for NTT DoCoMo's i-mode service. Wireless Markup Language (WML) took the other route — a separate language under WAP, reachable only through a gateway. XHTML Mobile Profile, from the Open Mobile Alliance, followed as a middle path. WML and XHTML-MP are both formally obsolete.

**What they teach.** Two things, and the first is encouraging. The subset that was also ordinary markup (cHTML) outlived the one that was a separate language (WML), which is rule 1 restated by history.

The second is a challenge WebVeld has to answer. These profiles died because their justification was device constraint: as phones grew powerful enough to run full browsers, a stripped-down markup language had no remaining reason to exist. If WebVeld's case were "small devices need a small web," it would be on the same road. It is not. WebVeld's case is that engine complexity, surveillance, and attack surface are problems of the *standard*, not of the hardware — and those do not dissolve when the hardware improves. Faster phones did not make fingerprinting rarer.

## 3. AMP: a subset with an owner

**What it was.** Google's Accelerated Mobile Pages defined a restricted HTML subset for speed, and enforced it with a search-ranking incentive and a badge.

**Where it stands.** Google removed AMP as a requirement for Top Stories in the June 2021 Page Experience update and dropped the badge; by 2026 AMP confers no ranking advantage, has shipped no significant features since 2023, and major publishers have migrated off it. Google's position is that it remains supported but is not recommended.

**What it teaches WebVeld.** Three things, all cautionary. First, a subset defined by a platform inherits that platform's interests, and authors correctly treat the constraints as a toll rather than a benefit — WebVeld has no gatekeeper to withdraw its support or to profit from adoption. Second, AMP's restrictions came packaged with a *mandatory JavaScript runtime*, which is a contradiction at the center of a performance subset; WebVeld's restriction and its mechanism point the same direction. Third, an incentive that can be revoked produces adoption that evaporates when it is. WebVeld's only incentives are intrinsic: pages that are cheap to serve, durable, private, and readable everywhere.

## 4. Minimal browser engines: the existence proof for rule 2

These are implementations rather than specifications, and they are the best evidence that a small team can ship a real browser.

- **Dillo** is the closest thing to a WebVeld browser that exists today. It renders HTML and XHTML with CSS and images over HTTP and HTTPS, and ignores scripting entirely. After a long dormancy it was revived in December 2023 by Rodrigo Arias Mallo, with releases through 3.2.0 (January 2025) and 3.3.0 (April 2026). It is the natural starting point for a WebVeld browser, though measurement tempers that: it implements a different subset rather than a smaller one, and lacks flexbox entirely along with several elements WebVeld requires. [dillo-assessment.md](research/dillo-assessment.md) has the detail. What it lacks above all is a specification saying which subset, so that "conforming" is a checkable claim.
- **NetSurf** implements most of HTML 4 and CSS 2.1 on its own bespoke layout engine, with a Duktape-based JavaScript engine that remains incomplete and disabled by default. It is a small-team engine sustained across two decades.
- **Lynx, w3m, and Links/ELinks** are the text-mode ancestors, and they demonstrate the durability of the approach more than its ceiling.
- **Ladybird** is the instructive contrast. It is a genuinely independent engine — no Chromium, WebKit, or Gecko lineage — built by a non-profit founded by Andreas Kling and Chris Wanstrath, with a public alpha targeted for 2026 and, ahead of it, a shift to maintainer-only development. It is years of concentrated effort by a funded organization, and it is still pre-alpha, because it is chasing the whole living standard.

**The pattern that matters.** Dillo and NetSurf prove rule 2 is achievable; Ladybird shows what the same ambition costs when the target is the full web. But Dillo and NetSurf pay a subtler price: because the real-world web is their target and it never stops moving, they are permanently, unavoidably incomplete — every site that fails is their bug, not the site's. This is the gap WebVeld is trying to fill. A bounded, published conformance target is what lets a minimal browser be *finished* rather than perpetually behind, and lets a page be wrong instead of the browser.

## 5. Reader-side stripping: reader modes and lite sites

**What they are.** Firefox's Reader View and its equivalents reconstruct a clean article from a hostile page. Publishers occasionally offer the same thing directly: CNN Lite (`lite.cnn.com`) and NPR's text-only site (`text.npr.org`), both introduced in 2017, strip to headlines and article text and load over almost any connection. Legible News rebuilds the day's events from Wikipedia's current-events record with no alerts and no trackers.

**What they teach.** Demand is not hypothetical — some of the most-praised properties on the web are the ones that had everything removed. But these are either reconstructions performed by the reader's software against the publisher's markup, or one-off side doors a publisher maintains by hand and can quietly retire. Neither is a standard, neither is verifiable, and neither helps the reader who wants a browser that is small in the first place. WebVeld's contribution is to make the stripped version the published artifact and to give it a conformance test.

## 6. Weight budgets and simplicity culture

Size-budget clubs, curated directories of lightweight sites, and long-running experiments in radical frugality — Low-tech Magazine's solar-powered edition being the best-known — form the cultural layer around all of this. They set an example and a target, and they have shifted expectations more than any specification has.

What they do not have is a conformance test. "Under a size budget" is a property of one page at one moment, not a contract between authors and implementers, and it says nothing about what a browser must implement. WebVeld is an attempt to turn the sentiment into something checkable in both directions.

## 7. Where WebVeld sits

| Effort | Approach | Modern browser | Small team can finish | Defined by |
| :--- | :--- | :--- | :--- | :--- |
| Gopher, Gemini | New protocol and format | No (needs new client) | Yes | Community |
| cHTML, XHTML-MP | Constrained markup subset | Yes (historical) | Yes | Carrier consortia |
| WML / WAP | Gateway-based language | No | Yes | Industry consortium |
| AMP | Subset + mandatory JS runtime | Yes | No | Single platform |
| Reader modes | Publisher/browser stripping | Yes | N/A (no specification) | Vendors, publishers |
| Dillo, NetSurf | Minimal engine without spec | N/A (implementation) | Moving target | Maintainers |
| Weight budgets | Convention and examples | Yes | N/A (no specification) | Nobody |
| **WebVeld** | Validatable HTML5/CSS subset | **Yes, by rule** | **Yes, by construction** | **Open specification** |

The combination is what is new, not any single row. A subset of the live web (so reach is free), specified tightly enough to validate documents and finish browsers (so implementation terminates), owned by no platform (so the incentive cannot be revoked), and justified by properties that faster hardware will not erode (so it does not follow XHTML-MP into obsolescence).

## 8. Open questions this survey raises

- **Dillo is the natural reference implementation to test against, and the check has now been run.** [dillo-assessment.md](research/dillo-assessment.md) measures Dillo 3.3.0-rc1 against the specification. The headline: Dillo implements a *different* subset rather than a smaller one — richer than WebVeld in legacy CSS (floats, positioning, `z-index`, counters, inline styles) and poorer in modern layout, with no flexbox whatsoever, no `border-radius`, `box-sizing`, or `opacity`, and `caption`, `fieldset`, `legend`, and `noscript` stubbed out. The porting checklist is short enough to be encouraging, but "already most of a WebVeld browser" was too generous a reading.
- **Gemini's authoring experience is the warning to watch.** Its stagnation is attributed partly to a document format authors find too poor to write in. WebVeld should periodically re-ask whether its own constraints have crossed that line; the strongest candidates on the roadmap (CSS custom properties, a bounded SVG subset) are the ones authors will miss first.
- **The smolnet is a potential ally rather than a competitor.** A WebVeld document is plain HTML over HTTP, so it is complementary to Gemini rather than in tension with it, and multi-protocol clients already exist. Whether WebVeld browsers should also speak `gemini://` is an implementation question the specification deliberately leaves open.

## Sources

- [The Gemini Protocol in 2026 — Kevin Boone](https://kevinboone.me/gemini_2026.html)
- [Gemini protocol specification](https://geminiprotocol.net/docs/protocol-specification.gmi) and [gemtext specification](https://geminiprotocol.net/docs/gemtext-specification.gmi)
- [Gemini (protocol) — Wikipedia](https://en.wikipedia.org/wiki/Gemini_(protocol))
- [SmolNet — Archiveteam wiki](https://wiki.archiveteam.org/index.php/SmolNet)
- [XHTML Mobile Profile — Wikipedia](https://en.wikipedia.org/wiki/XHTML_Mobile_Profile), [Wireless Markup Language — Wikipedia](https://en.wikipedia.org/wiki/Wireless_Markup_Language), [i-mode — Wikipedia](https://en.wikipedia.org/wiki/I-mode)
- [Is Google AMP dead in 2026?](https://wppoland.com/en/is-google-amp-dead-in-2026-and-what-to-use-instead/)
- [Dillo releases](https://dillo-browser.org/release/), [Dillo — Wikipedia](https://en.wikipedia.org/wiki/Dillo), [Dillo Turns 25 — Hackaday](https://hackaday.com/2025/01/19/dillo-turns-25-and-releases-a-new-version/)
- [NetSurf — Wikipedia](https://en.wikipedia.org/wiki/NetSurf), [NetSurf news](https://www.netsurf-browser.org/about/news.html)
- [Ladybird](https://ladybird.org/), [Ladybird development changes ahead of alpha](https://braindetox.kr/en/posts/ladybird_browser_development_changes_2026.html)
- [awesome-lite-websites](https://github.com/mdibaiee/awesome-lite-websites), [A list of text-only and minimalist news sites](https://greycoder.com/a-list-of-text-only-new-sites/)
