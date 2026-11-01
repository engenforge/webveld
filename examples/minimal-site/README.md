# Minimal site

A four-page site that conforms to the [WebVeld specification](../../doc/webveld-spec.md): a home page, two content pages, and an order form. Names, products, and descriptions are fictional.

It doubles as the validator's test corpus and should always pass:

```
lua tools/validator/webveld-validate.lua examples/minimal-site/*.html
```

`checkout.html` is worth reading for the pattern in its payment fieldset. Rather than becoming an extended document (spec §11), it offers the reader a scripted external processor *or* an invoice, each labelled with what it requires. The page stays fully conforming, and the divergence is a choice the reader makes with full information.
