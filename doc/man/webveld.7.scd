webveld(7) "WebVeld @VERSION@" "Standards and Conventions"

# NAME

webveld - minimal subsets of HTML5 and CSS for resilient and verifiable web documents

# DESCRIPTION

WebVeld is a family of minimal subsets of HTML5 and CSS for documents that look
the same in a purpose-built minimalist browser and in any modern web browser,
with no plugins, polyfills, or scripts. It is not a new markup language,
protocol, or URL scheme: every construct is standard HTML5, CSS, and HTTP.

# CARDINAL RULES

All WebVeld constraints follow from three cardinal rules:

*1. Parity*
	A WebVeld document looks the same in a WebVeld browser and in an
	unmodified modern web browser, with no plugin, polyfill, or script. Parity
	means the same content and structure, rendered so a reader would struggle
	to tell the browsers apart; it does not mean identical pixels.

*2. Implementability*
	The specification stays small enough that one developer or a small team
	can build a complete browser: about 40,000 lines of engine code.

*3. Privacy and safety of the reader*
	These come before author convenience. Anything that creates a tracking
	signal, a code-execution path, or a new class of untrusted parsing is
	rejected.

# PROFILES

The profiles nest: every webveld-pico document is a webveld-nano document, and every webveld-nano document is a webveld document.

*webveld*
	The full specification. Flexbox, a bounded CSS grid subset, tables,
	accessible forms, details/summary, media queries, and self-hosted fonts.
	About 40,000 lines of engine code.

*webveld-nano*
	Styled documents. Linear-flow box model, typography, colors, same-origin
	PNG/JPEG images, and light/dark color schemes. No flexbox, grid, tables,
	or forms. About 20,000 lines of engine code.

*webveld-pico*
	Semantic hypertext. Headings, paragraphs, lists, quotes, preformatted
	text, and links. No author CSS and no subresources. About 10,000 lines of
	engine code.

# TOOLS

*webveld-validate*(1)
	Reference validator for WebVeld conformance and classification.

*webveld-profile-check*(1)
	Checker for the webveld-nano and webveld-pico profile restrictions.

# FILES

_/usr/local/share/webveld/doc/webveld-spec.md_
	The normative WebVeld specification.

_/usr/local/share/webveld/doc/profiles/_
	The webveld-nano and webveld-pico profile documents.

_/usr/local/share/webveld/conformance/_
	The render conformance test suite.

_/usr/local/share/doc/webveld/_
	Documentation and examples.

# SEE ALSO

*webveld-validate*(1), *webveld-profile-check*(1)
