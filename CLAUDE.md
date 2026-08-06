# MCZbase development guidance

## Project context

MCZbase is a ColdFusion web application backed by an Oracle database, used for
natural science collections data management at the Museum of Comparative
Zoology, Harvard University.

**Authoritative developer's guide:** the full developer's guide lives at
[`/documentation/README.md`](https://github.com/MCZbase/MCZbase/blob/master/documentation/README.md)
in this repository. That document is the source of truth — the guidance below
is extracted from it and kept close to its original wording, but the
developer's guide itself governs anything not covered here or where the two
seem to disagree. RFC 2119 keywords (MUST, SHOULD, MAY, etc.) below are used
exactly as they are in the source document.

@documentation/README.md

## Your role on this project

You are acting as a skilled software engineer with detailed working
knowledge of:

- ColdFusion web applications
- Oracle databases and SQL
- JavaScript and AJAX for dynamic web pages
- CSS style management
- Bootstrap
- Web accessibility standards
- jQuery, jQuery UI, and the jqxWidgets library

Write code that follows the practices below rather than generic
ColdFusion/JS idioms that conflict with local patterns.

## Redesign in progress: target architecture

MCZbase is being migrated off an older pattern and onto a new one. When
adding or modifying user-facing pages, prefer the **new** pattern below. When
you're only touching legacy code and a full migration isn't in scope, match
the surrounding legacy conventions instead of mixing patterns in the same
file.

This "match surrounding conventions" allowance is scoped to genuinely
**legacy** files (the `/includes/`-pattern files described below) -- it does
NOT extend to pre-existing quirks or inconsistencies inside files that are
already part of the target pattern (e.g. `/{concept}/component/*.cfc`,
`/{concept}/js/*.js`). Those files ARE the standard to match. A pre-existing
deviation from this guide inside one of them is a bug to flag (or fix, if
you're already touching that exact code) -- not a precedent for new code.

**Legacy pattern (being phased out):**
- Pages include `/includes/_header.cfm`
- Shared JavaScript lives in large monolithic files, e.g. `/includes/ajax.js`
- Shared ColdFusion backing logic lives in `/includes/functionLib.cfm`

**Target pattern (use for new/redesigned pages):**
- Pages include `/shared/_header.cfm`
- JavaScript is organized per concept: `/{concept}/js/`
- ColdFusion backing components are organized per concept:
  - `/{concept}/component/search.cfc` — backing methods for the search page, role=public
  - `/{concept}/component/functions.cfc` — other backing methods (create/edit), typically role=manage_{concept}
- Avoid introducing new uses of jqxWidgets.

Use file/directory names such that redesign files can coexist with the files
they replace (e.g. `/shared/` replaces `/includes/`, `/Taxa.cfm` replaces
`/Taxonomy.cfm`).

## File naming

- **Search-with-results pages** (plural noun, capitalized): `/Transactions.cfm`
- **Details pages** (read-only, lowercase verb + noun): `/taxonomy/showTaxonomy.cfm`
- **Edit/create pages**:
  - Multiple actions in one file -> capitalized noun: `/taxonomy/Taxonomy.cfm`
  - Single action -> lowercase verb + noun: `/foo/editFoo.cfm`

For a given concept there SHOULD be three .cfm files representing four page
types: search-with-results, details ("show..."), and edit/create.

## Directory organization

- `.cfc` component files SHOULD be in a `component/` directory.
- `.cfc` custom tag files MUST be in `/CustomTags/`.
- Widely reused ColdFusion/JS/CSS files SHOULD be in `/shared/`, `/shared/js/`, `/shared/css/`.
- Included libraries (jQuery, etc.) MUST be in `/lib/`, loaded from local copies -- MUST NOT load libraries from external URLs.
- A JS function used **outside its own concept** -> put it in `/shared/js/` and include it from `/shared/_header.cfm`.
- A JS function used **only within its own concept** -> put it in `/{concept}/js/`, include from `/shared/_header.cfm` gated on a check for that `/concept/` path.

## Page header block

Every new page MUST start with a copyright comment block:

```coldfusion
<!--
{filename}.{extension}

Copyright {current year} President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->
```

On pages **modified from existing MCZbase code**, use this copyright instead:

```
Copyright 2008-2017 Contributors to Arctos
Copyright 2008-{current year} President and Fellows of Harvard College
```

## Line endings and indentation

- Files MUST use **Unix line endings**. Never commit CRLF. Exceptions: `.cfr` report files, `.png` files, and files under `/lib/` (retain original line endings).
- Indentation MUST use **tabs**, one tab per nesting level -- this applies uniformly across ColdFusion, embedded HTML, JS, and SQL nested inside `<cfquery>`.
- `<cftry>`/`<cfcatch>` nest at the same indentation level.
- Don't nest `<input>` inside `<label>` -- use `for`/`id` instead.

## Variable naming and scopes

- Non-database variables (ColdFusion or JS): `camelCase`.
- Variables/form fields/IDs that map 1:1 to a database field: use the **exact lowercase field name** (e.g. `higher_geography`) -- this keeps the name consistent across the whole stack.
- DOM element IDs referenced from JS: `camelCase`.
- Use long, descriptive names; loop counters may be single letters (`i`, `j`).

Scopes -- **all of these must be explicit**, no implicit scope resolution:
- `cgi`, `url`, `form`, `cookie`, `file`, `client` MUST be referenced explicitly.
- GET/`url` and POST/`form` parameters MUST be declared with `<cfparam>` and moved into `variables.*` or referenced with their full scope -- never relied on implicitly.
- **Forms and their handlers MUST match GET/POST correctly.** ColdFusion's old GET/POST-agnostic behavior MUST be corrected wherever found (needed for future upgrade compatibility).
- Avoid the `request` scope for passing parameters between files, except `pageTitle` before including `_header.cfm`.
- Pass variables to `.cfc` methods explicitly via `<cfargument>`, not via ambient scope.
- In cfcomponent methods, use `arguments` scope, not `url`/`form`.
- Inside `<cfthread>`, pass values in as **thread attributes** rather than relying on `variables` scope, to avoid cross-thread mutation/deadlocks.

## SQL / cfqueryparam (security-critical)

- **Every query parameter MUST use `<cfqueryparam>` -- no exceptions.** User-provided content MUST NOT reach the database except through `<cfqueryparam>`.
- Queries MUST be built inside an actual `<cfquery>` block -- MUST NOT be assembled as a string and passed in.
- `<cfif>` logic can be embedded inside `<cfquery>` blocks for conditional SQL.
- SQL reserved words in upper case; each clause starts on a new line, indented.
- Named queries: give the `result` attribute the query name + `_result` (e.g. `result="getCounts_result"`).
- When passing user credentials into a query, pull them from `session` (`session.dbuser`, `session.epw` decrypted with `cookie.cfid`) via the `user_login` datasource -- don't store credentials locally.

## Output encoding (security-critical)

- Wrap user-provided values in `encodeForHtml()` before rendering into HTML, and `encodeForUrl()` before placing into URLs -- the developer's guide shows this pattern throughout form fields, e.g. `value="#encodeForHtml(anyName)#"`.
- The "link to this search" URL parameters MUST be wrapped in `urlencode()`/`htmlencode()` as appropriate when re-emitted.
- Treat every `url.*` and `form.*` value as untrusted until encoded for its output context.

## Comments

- ColdFusion comments MUST use `<!--- --->` (non-rendering) -- never `<!-- -->` inside `.cfm` files, which renders into the HTML output.
- JavaScript comments should use `//` and `/* */` normally and MUST NOT be wrapped in `<!--- --->` when the JS is emitted from ColdFusion, or they'll be hidden from the rendered JS.
- Comment on *why*, not a line-by-line narration of *what*. Document functions in Javadoc style (`@param`, `@return`, `@see`) for both ColdFusion and JS functions.

## JavaScript conventions

- Prefer inline `onClick` handlers over bound click events, to keep the event -> handler path easy to trace. This applies to ColdFusion-templated markup (HTML built as strings/tags in `.cfm`/`.cfc` output). For JS that builds a widget by constructing DOM elements with jQuery (`$('<div>...</div>')`/`.append()` chains, e.g. the redesign's dynamically-rendered grids and tables) rather than templating HTML strings, bind with `.on(...)` instead and match whatever the surrounding function in that same file already does -- don't mix inline-attribute handlers into an otherwise jQuery-constructed element tree.
- Wrap `<script>` blocks in `<cfoutput>` and **double any `#`** used in jQuery selectors (`$('##someId')`) or ColdFusion will misinterpret them.
- Pass DOM element IDs as parameters into handler functions rather than hardcoding IDs downstream (avoid "magic" element names buried in function bodies).
- Prefer jQuery selectors (`$("#id")`) over `document.getElementById()`.

## Semantic HTML / page structure

- Exactly **one `<main id="content">` per page**; `<main>` MUST NOT carry `role="main"`; `<section>` MUST NOT carry `role="region"`.
- `<header>` and `<footer>` come from `/shared/_header.cfm` / `/shared/_footer.cfm` -- pages MUST NOT add a second instance.
- Heading levels MUST start at `<h1>` and MUST NOT skip levels; use Bootstrap classes (e.g. `class="h3"` on an `<h1>`) to control visual size independent of semantic level. If a heading can't be kept in strict nesting order (e.g., a tab button that's also a heading), use `aria-level="n"` instead.
- Search/results pages MUST use the `overlaycontainer` -> `<main>` -> search `<section role="search">` + results `<section>` structure so the loading overlay doesn't cover the header/footer.

## Behaviors

- **Relational integrity MUST be enforced at the database level** (PK/FK/NOT NULL constraints) -- never relied on solely at the ColdFusion/JS layer. Client-side `required` attributes are a UX nicety on top, not a substitute.
- Search pages MUST support a GET-parameter API: populating the form via URL params plus `execute=true` MUST auto-run the search on load.
- Edit pages SHOULD save via AJAX POST to a backing `.cfc` method with partial-page reload, not a full-form POST/reload.
- New-record pages SHOULD POST the create form to a handler that then shows/redirects to the edit page for the new record.
- Any AJAX-loaded region needs a loading indicator (`/shared/images/indicator.gif` pattern) -- and be aware a stuck spinner usually means broken JS, not a slow load.

## Accessibility

- Every input needs exactly **one** accessible name mechanism -- a `<label for>`, `aria-labelledby`, `title`, or `aria-label`. **Never stack more than one** on the same field; a screen reader will read the name redundantly for each mechanism present.
- Prefer a real `<label for>` over ARIA attributes where possible; only reach for `aria-label`/`aria-labelledby` when there's no visible label.
- The "skip to main content" link in `/shared/_header.cfm` targets `id="content"` -- every page including that header MUST carry `id="content"` on its `<main>`.

## Buttons -- color/semantic conventions

| Purpose | Class |
|---|---|
| Save / Create / Execute search | `btn btn-xs btn-primary` |
| Delete a standalone record | `btn btn-xs btn-danger` |
| Remove a relationship / Reset / New Search | `btn btn-xs btn-warning` |
| View details / Print (page-level button) | `btn btn-xs btn-info` |
| Add relationship / Edit / Create-new-{object} from search page | `btn btn-xs btn-secondary` |
| Edit link from a results grid | `btn-xs btn-outline-primary` |

## CSS

- Prefer Bootstrap classes over inline styles or hand-written CSS wherever a Bootstrap utility covers the need (e.g. `<h1 class="h3">`, not inline `font-size`).
- Shared styles -> `/shared/css/`; concept-specific styles -> that concept's own stylesheet, not inline in the `.cfm`.

## When in doubt

If a task isn't clearly covered by this file or the developer's guide, say so
explicitly and propose an approach consistent with the target architecture
and security requirements above, rather than silently falling back to
generic ColdFusion defaults.

## Verifying your work

Before treating a change as finished, re-read the diff against this file and
the developer's guide's security and accessibility sections specifically --
adherence should be checked deliberately against the written rules, not
assumed from having kept them in mind while writing the code. This file is
dense enough that specific rules (Javadoc completeness, an exact button
class, an accessible-name mechanism) can go unchecked simply because the
task's framing made other rules more salient. In particular:

- Don't relax a security-critical rule (`<cfqueryparam>`, `encodeForHtml()`,
  role checks on a mutating remote method, etc.) because the current call
  path happens to make it seem redundant -- see Output encoding above.
- Don't extend the legacy-file "match surrounding conventions" allowance to
  pre-existing quirks in target-pattern files -- see Redesign in progress
  above.
- If you deviate from a specific rule (a button color, an ARIA pattern, an
  event-binding style) for a good local reason, say so explicitly -- with a
  comment in the code, and a mention in your response or commit message --
  rather than silently matching nearby code and letting the deviation go
  unstated.
