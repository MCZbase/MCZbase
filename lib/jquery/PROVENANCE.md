# jQuery 3.7.1: provenance and review

## Source

- `jquery-3.7.1.min.js` is `package/dist/jquery.min.js` from the npm release `jquery@3.7.1`
  (published 2023-08-28), unmodified.  It is also identical to https://code.jquery.com/jquery-3.7.1.min.js.
- npm tarball integrity, matching the registry's published value:
  `sha512-m4avr8yL8kmFN8psrbFFFmB/If14iN5o9nw/NgnnM+kybDJpRsAynV2BsfpTYrTRysYUdADVD7CkUUizgkpLfg==`
- Subresource integrity, matching the value published at https://releases.jquery.com/jquery/:
  `sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=`
- SHA-256 (hex): `fc9a93dd241f6b045cbff0481cf4e1901becd0e12fb45166a8f17f95823f0b1a`
- License: MIT (see `/lib/LICENCE.md`).
- Added in 30ef6ecea9 (Redmine 1037); verified again 2026-10-23.

## Use in MCZbase

Loaded on every page by `/shared/_header.cfm`.

## Review, 2026-10-23

- OSV lists no advisories for jquery 3.7.1.
- It makes no requests of its own; requests happen only when page code calls `$.ajax()`,
  `$.getScript()` and the like.
- Upstream (https://github.com/jquery/jquery, OpenJS Foundation) is actively maintained.  jQuery 4.0.0
  was released 2026-01-18; 3.7.1 is the last 3.x release.

## Revisit

Moving to 4.x is an upgrade project (4.0 removes deprecated APIs), not a drop-in replacement.  Recheck
OSV when upgrading, and record the new release's checksums here.
