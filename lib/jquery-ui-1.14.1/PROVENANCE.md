# jQuery UI 1.14.1: provenance and review

## Source

- The files here come from https://jqueryui.com/resources/download/jquery-ui-1.14.1.zip, the full
  build with the base theme (published 2024-10-30), unmodified.  Left out: the zip's `index.html`
  demo page, `package.json` and `external/` (its bundled jQuery).
- The download zip has no published checksum, so it was cross-checked against two other sources:
  - `jquery-ui.js` and `jquery-ui.min.js` are identical to https://code.jquery.com/ui/1.14.1/ and to
    `dist/` in the npm release `jquery-ui@1.14.1`.  The npm tarball's integrity matches the registry's
    published value:
    `sha512-DhzsYH8VeIvOaxwi+B/2BCsFFT5EGjShdzOcm5DssWjtcpGWIMsn66rJciDA6jBruzNiLf1q0KvwMoX1uGNvnQ==`
  - `jquery-ui.min.js` matches the subresource integrity value published at
    https://releases.jquery.com/ui/: `sha256-AlTido85uXPlSyyaZNsjJXeCs07eSv3r43kyCVc8ChI=`
  - The stylesheets differ from code.jquery.com's copies only in their ThemeRoller comment header,
    which the download builder writes.
- SHA-256 (hex):
  - jquery-ui-1.14.1.zip `e1d2031e6b33dcdc6b09e3cf1b838d9e0dfba20862e4cb248afb614dd4f04986`
  - jquery-ui.js `f739630caa44fe643199a47857670655a43b6ab17709c5f16abbe0afb4a3f147`
  - jquery-ui.min.js `0254e2768f39b973e54b2c9a64db23257782b34ede4afdebe3793209573c0a12`
  - jquery-ui.min.css `059cc2d2dad0a15d7b393b8b90f88c550f2661fd3927f84437e96cdfa7a66ccc`
- License: `LICENSE.txt` (see `/lib/LICENCE.md`).
- Added in 30ef6ecea9 (Redmine 1037); verified again 2026-10-23.

## Use in MCZbase

`/shared/_header.cfm` loads `jquery-ui.js`; a few pages load `jquery-ui.min.js` and
`jquery-ui.min.css`.

## Review, 2026-10-23

- OSV lists no advisories for jquery-ui 1.14.1.
- It makes no requests of its own.  The URLs in it are documentation and bug-tracker links in comments.
- Upstream (https://github.com/jquery/jquery-ui) is in maintenance mode: it keeps compatibility with
  new jQuery releases and fixes security issues, but has no new feature work planned.  1.14.2 was
  released 2026-01-29.

## Revisit

Consider 1.14.2 or later; replace every file from the new release and record its checksums here.
