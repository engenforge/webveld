webveld-profile-check(1) "WebVeld @VERSION@" "User Commands"

# NAME

webveld-profile-check - profile conformance checker for webveld-nano and webveld-pico

# SYNOPSIS

*webveld-profile-check* [*--profile*=_nano_|_pico_] _FILE_...

# DESCRIPTION

*webveld-profile-check* checks HTML and CSS files against the WebVeld
restriction profiles:

*webveld-nano*
	Styled documents: linear-flow box model, typography, colors, same-origin
	PNG/JPEG images, and light/dark color schemes. No flexbox, grid, tables,
	forms, or width-based media queries.

*webveld-pico*
	Semantic hypertext: headings, paragraphs, lists, quotes, preformatted
	text, and links. No author CSS and no subresources.

A profile only removes features from the WebVeld specification; it never
adds or redefines anything, so every conforming profile document is also a
conforming WebVeld document. *webveld-profile-check* assumes its input
already passes *webveld-validate*(1), and checks the profile's further
restrictions:

- *R1 Elements*: elements outside the profile are rejected.
- *R2 Attributes*: attributes outside the profile are rejected. In pico,
  the only *meta* name is *viewport*, with exactly
  _width=device-width, initial-scale=1_.
- *R3 Style sheets*: in pico, author style sheets are rejected entirely. In
  nano, properties, selectors, and at-rules outside the profile are
  rejected, and narrowed values (*display: none* only) are enforced.

On every run, a drift guard compares the checker's lists with the profile
documents and warns if they disagree.

# OPTIONS

*--profile*=_nano_|_pico_
	The profile to check against. The default is *nano*.

# EXIT STATUS

*0*
	Every file conforms to the profile.

*1*
	At least one file breaks a profile restriction, or the options were
	invalid.

# ENVIRONMENT

*WEBVELD\_PROFILE\_DOC*
	Path to the profile document used by the drift guard.

# EXAMPLES

Check a document and a style sheet against nano:

```
webveld-profile-check page.html style.css
```

Check a document against pico:

```
webveld-profile-check --profile=pico text-only.html
```

# SEE ALSO

*webveld-validate*(1), *webveld*(7)
