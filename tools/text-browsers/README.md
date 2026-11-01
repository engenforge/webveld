# Text-browser cases

Conforming documents rendered through Lynx, w3m and Links to characterize what a reader gets from markup alone. Findings are in [`doc/research/text-browser-assessment.md`](../../doc/research/text-browser-assessment.md); this directory is how they are reproduced.

```sh
sh run.sh                  # all cases, width 40
WIDTH=80 sh run.sh
sh run.sh --include-probes # plus ../render-diff/probes/, which no conforming document can reach
```

Lynx and w3m implement no CSS; Links implements a little. That is the point — these are the engines at the bottom of the implementability continuum, and `webveld-pico` names terminal clients as a target audience. What survives here is what survives everywhere.

Every file in this directory conforms to full WebVeld, so `check-repo.sh` covers them with everything else. A case that needs a forbidden construct belongs in [`../render-diff/probes/`](../render-diff/probes/) instead.

| Case | Question |
| --- | --- |
| `pre-long-lines.html` | does a wide code block wrap, or extend the canvas? |
| `pre-overflow-x.html` | the same content with `overflow-x: auto` — does declaring it change anything? |
| `sectioning-semantic.html` / `sectioning-div.html` | identical content, sectioning elements vs `div`; diff the two dumps |
| `hiding.html` | `display: none`, `clip-path`, a 1px `overflow: hidden` box, `aria-hidden` |
| `tabindex-and-style.html` | is `tabindex` in the tab order, and does `<style>` content leak into the text? |

`run.sh` prefixes every dumped line with its length. The behavior that separates these engines is a property of line length, and reading the text alone hides it.
