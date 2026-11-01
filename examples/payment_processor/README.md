# Payment processor

Two sample pages showing what a payment flow looks like as conforming WebVeld, with no client-side scripting:

- `payment-processor-page.html` — a hosted checkout page: order summary, card fields, cardholder details, billing address.
- `3ds-authentication-page.html` — the bank authentication step that follows.

Both conform to the [WebVeld specification](../../doc/webveld-spec.md):

```
lua tools/validator/webveld-validate.lua examples/payment_processor/*.html
```

The checkout flow demonstrates hosted forms and 3D Secure bank authentication using pure HTML and CSS without client-side scripts. WebVeld permits `autocomplete` with `username`, `current-password`, `new-password`, and `off` (spec §5.2).
