webveld-validate(1) "WebVeld @VERSION@" "User Commands"

# NAME

webveld-validate - reference conformance validator for the WebVeld specification

# SYNOPSIS

*webveld-validate* [*--classify*] [*--css*] [*--format*=_text_|_json_] _FILE_...

# DESCRIPTION

*webveld-validate* checks HTML documents and style sheets against the
normative WebVeld specification. WebVeld is a family of minimal subsets of
HTML5 and CSS for documents that look the same in a purpose-built minimalist
browser and in any modern web browser.

The element, attribute, CSS property, and input-type allowlists are read from
the specification's own tables at run time, so they cannot drift from the
specification. Enumerated values, selectors, and units are checked against
the specification by the test suite.

Spec section 2.6 defines conformance as two passes:

. *HTML5 validity*, checked by a standard validator such as the Nu Html
  Checker (spec section 2.3 item 1).
. *Subset conformance* against spec sections 4 to 9, which this tool checks.

# OPTIONS

*--classify*
	Report each document as one of the three states of spec section 2.6:

	*Conforming*: the document satisfies spec section 2.3.

	*Extended*: the document has scripting, a *noscript* element whose
	content conforms, and is otherwise conforming (spec section 2.5). This is not an
	error.

	*Non-conforming*: everything else.

	In this mode the exit status is non-zero only if a file is
	Non-conforming.

*--css*
	Treat every input as a style sheet rather than a document. Files ending
	in _.css_ are detected without this. The style sheet is wrapped in a
	minimal conforming document, so every finding is the style sheet's own.

*--format*=_text_|_json_
	Output format. *json* emits one record per input with its path, kind,
	state, and findings. The banner showing the allowlist sizes is omitted in
	this mode.

# CHECKS

- Elements (spec section 4.3), attributes (spec sections 5.1 to 5.2), and enumerated
  attribute values: *tabindex*, *dir*, *meta* names and *og:\** properties,
  *link rel*, and *checked* only on checkboxes and radio buttons.
- Document structure: doctype, *lang*, UTF-8 charset, one *title*, at most
  one *main*, and *details* starting with *summary* (spec sections 4.1 to 4.3).
- *noscript* only in extended documents (spec section 2.3 item 7).
- No inline *style* attributes and no author *!important* (spec section 6.1).
- CSS properties and values, including the CSS-wide keywords (spec section 6.2);
  selectors (spec section 6.3); units (spec section 6.4); and the bounded grid subset.
- Media queries: permitted features and *prefers-color-scheme* values,
  only the *print* media type, no *not* or *only*, no range syntax, no
  nesting, and no *url()* inside a query (spec section 6.6).
- Fonts: no *local()* and no cross-origin *src* (spec section 6.5).
- *:visited* limited to color properties (spec section 6.3).
- URLs by position: same-origin subresources, *data:* only for PNG and JPEG
  images and PNG icons, and no *javascript:*, *vbscript:*, *data:*, or
  *file:* links (spec sections 7.1 to 7.2).
- Images are PNG or JPEG, and site icons are PNG (spec section 7.4).
- Forms: HTTP or HTTPS *action*, GET or POST *method*, permitted input
  types, safe *pattern* expressions, HTTPS for password forms, and permitted
  *autocomplete* tokens (spec section 5.2).
- Viewport declarations that disable zoom (spec section 5.2).
- Accessibility: *alt* on images, label counts, heading order, and focus
  outlines that are not removed without a replacement (spec section 9).

A clean report means nothing detectable is wrong. The tool reads source
text with patterns rather than building a full HTML tree, so run an HTML5
validator as well.

# EXIT STATUS

*0*
	Every file conforms (with *--classify*: every file is Conforming or
	Extended).

*1*
	At least one file does not conform (with *--classify*: is
	Non-conforming), or an error occurred.

# ENVIRONMENT

*WEBVELD\_SPEC*
	Path to the WebVeld specification (_webveld-spec.md_). If unset, the
	validator looks in the current directory, next to its install location,
	and in the standard data directories such as
	_/usr/local/share/webveld/doc/webveld-spec.md_.

# EXAMPLES

Validate a document:

```
webveld-validate index.html
```

Classify several documents:

```
webveld-validate --classify site/*.html
```

Validate against a specific copy of the specification:

```
WEBVELD_SPEC=/opt/webveld/webveld-spec.md webveld-validate page.html
```

# SEE ALSO

*webveld-profile-check*(1), *webveld*(7)
