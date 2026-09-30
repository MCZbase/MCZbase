# MCZbase CSS cleanup

Stylesheet debt found while porting Projects.cfm to Tabulator.
Measured on branch `redesign2` at commit `bfa0c9d6c5`.

Scale: 8,162 lines across 5 stylesheets; 275 `!important`; 295 id-bearing
lines in `bootstrap_override.css`.

## Two rules before touching anything

1. **Delete the CSS selector, never the `id` attribute.** `#searchForm`
   appears in both places and they are unrelated. 19 pages carry
   `id="searchForm"` in markup; `Projects.cfm` alone reads it 5 times (submit
   binding, `serializeArray()`, twice for the "Link to this search" URL).
   Removing the attribute breaks search. Removing the stylesheet selector
   changes only appearance.
2. **Adding a class to a form field is safe; removing one is not.**
   `.excludeFromLink` and `.keeponclear` are read by the link builder and the
   reset: `$("#searchForm :input").not(".excludeFromLink")`. Grep before
   pruning anything that looks decorative.

## Specificity: the id-scoped search-form rules

`bootstrap_override.css:1949` and `:1968` put `#searchForm` in the selector
only to win the cascade. At (1,1,2) they outrank Bootstrap's component rules
and every class-based correction since.

### DONE - picker inputs wrapped below their prepended icon

`width: 100%` in the id rule outranked `.input-group > .form-control` (0,2,0),
so the input claimed a whole flex line. Neither `w-auto` (won't shrink) nor
`w-100` (is the bug) helps. Fixed with a scoped exception below the id rule
rather than editing it, so the bare inputs below are unaffected:

```css
.tab-content .input-group > input[type="text"],
#searchForm fieldset .input-group > input[type="text"],
#annotationSearchForm fieldset .input-group > input[type="text"] {
	flex: 1 1 auto;
	width: 1%;
	min-width: 0;
}
```

Also removed `w-auto h-auto` from the three agent pickers on `Projects.cfm`.

### OPEN - 106 text inputs get their width from nowhere else

No `data-entry-input`, `form-control` or width utility, so the id rule is
their only source of `width: 100%`. This blocks everything else in this
section.

| page | inputs |
|---|---|
| Transactions.cfm | 30 |
| Taxa.cfm | 25 |
| media/findMedia.cfm | 25 |
| Publications.cfm | 20 |
| Agents.cfm | 6 |

Next: add `data-entry-input` as each page is ported. Purely additive, no flag
day. `Agents.cfm` is next in the migration and cheapest at 6.

### BLOCKED - `height: 22px` blocks the unified control metric

Both id rules pin `height: 22px`, outranking
`.mcz-app-controls input.data-entry-input:not([type="checkbox"]):not([type="radio"])`
(0,3,1). So `--mcz-control-line` never applies inside `#searchForm` - the form
looks uniform only because those two rules agree with each other. The metric
is doing real work on the results toolbar, which sits outside the form.

Blocked on the 106 bare inputs above.

## Duplication: five vertical metrics for one row of controls

| line | rule | vertical metric |
|---|---|---|
| 390 | `.btn-xs` | pad .15/.22rem, lh 1.2rem |
| 1328 | `.form-control-sm` | height calc(1.15em + .5rem + 2px) |
| 1399 | `.data-entry-input` | pad .2rem, lh 1.15rem |
| 1450 | `select.data-entry-select` | pad .14rem, lh 1.15rem |
| 1949 / 1968 | `#searchForm ...` | height 22px |

`.mcz-app-controls` (line 1474) is the intended correction and needs to be
the only one left. The comment on `.btn-xs` records the cost directly -
padding and font size changed to chase vertical alignment, with
`vertical-align: middle` noted as having failed. That is five rules competing,
not a button problem.

Renaming is not an option: these classes are used ~2,350 times across 120
files. Correcting the values in place is 3 rule blocks. Decide the canonical
metric, then delete the four that disagree.

## `!important` audit (measure, don't fix)

| file | !important | lines |
|---|---|---|
| bootstrap_override.css | 130 | 3,313 |
| custom_styles.css | 116 | 3,831 |
| header_footer_styles.css | 15 | 572 |
| customstyles_jquery-ui.css | 8 | 225 |
| tabulator_overrides.css | 6 | 221 |

Most probably answer a Bootstrap utility that is itself `!important`, which is
legitimate. Split the count into "answers Bootstrap" vs "answers our own
rule" - the second group is the real debt.

## Dead code

`data-entry-select:after` at `bootstrap_override.css:1494` is missing its
leading dot, so it targets a `<data-entry-select>` element that does not
exist. Never rendered.

Adding the dot is not the safe fix - it would put a caret on every select in
the application next to the one the browser already draws. Delete the rule
unless that caret is wanted, in which case it needs the dot *and*
`appearance: none` on the select.

## Pattern and deployment

### Promote the pilot `<style>` block out of Projects.cfm

Holds the results-toolbar layout only: `.mcz-toolbar-group`, its `row-gap`,
the `+` divider, the sub-`xl` wrap. A deliberate styleguide deviation, flagged
in the file, so the pattern could be judged on one page first. Move it to a
shared stylesheet when Agents.cfm gets the same toolbar, and drop the note.

### No version query on shared CSS and JS includes

Already cost two debugging sessions. A new `Projects.cfm` against a cached
`tabulator-common.js` threw `mczClearSelectionStore is not defined` and killed
the search; earlier, a stale copy made the CSV export return only the current
page. Both looked like code bugs and were deployment skew.

Append a version or mtime query to the shared includes in `shared/_header.cfm`.
Until then: any change spanning a page file and a shared file deploys
together, never file by file.

## custom_styles.css is loaded nowhere — 121 rules are dead

`shared/_header.cfm:82` has the link commented out:

```
<!---<link rel="stylesheet" href="/shared/css/custom_styles.css">--->
<link rel="stylesheet" href="/shared/css/bootstrap_override.css">
```

Nothing else links it either - the only remaining reference in the whole codebase is a
stale code comment at `localities/CollectingEvent.cfm:711` pointing at line numbers in
a file that no longer loads.

Selector comparison between the two files:

| | selectors |
|---|---|
| in both, identical | 495 |
| only in bootstrap_override.css (added after the fork) | 71 |
| **only in custom_styles.css (currently applying nowhere)** | **121** |

`bootstrap_override.css` is clearly a fork of `custom_styles.css` that kept going. The
495 overlap is harmless duplication in a file nobody loads. The 121 are the question:
each is a rule that silently stopped applying when the include was commented out.

Some of those 121 are worth checking specifically, because they are not obscure:
`.container`, `.container-wide`, `.container-xl`, `.fas`, `.fixedResults`, `.card-body h5`,
the `.card-header` accordion chevrons, `.flip-card*`, `.accn-icons`, `.formerID:nth-child(n)`.
An override of `.container` existing only in the dead file means pages are getting plain
Bootstrap there.

Two outcomes are possible for each, and they need telling apart:

1. The rule was deliberately retired and the file is simply dead weight - delete it.
2. Something lost its styling and nobody noticed, in which case the rule needs porting
   into `bootstrap_override.css`.

Suggested approach: diff the 121 against what is actually used in markup, since most
will be unused classes. `.wiki-drawer` is a worked example - it appears in both
stylesheets (5 rules in the live one, 6 in the dead one) and is used in
`localities/CollectingEvent.cfm`, `localities/HigherGeography.cfm` and
`shared/functionLib.cfm`, so the live file is probably missing one of its rules.

Do not delete `custom_styles.css` until the 121 have been triaged - it is the only
record of what those rules were.
