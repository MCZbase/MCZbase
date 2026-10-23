# Bootstrap 4.6.2: provenance and review

## Source

- The 20 files in `css/` and `js/` are `package/dist/` from the npm release `bootstrap@4.6.2`
  (published 2022-07-19), unmodified; the `index.cfm` files are MCZbase's, to stop directory listings.
- npm tarball integrity matches the registry's published value.
- The files the header loads match the subresource integrity values published at
  https://getbootstrap.com/docs/4.6/getting-started/introduction/:
  - css/bootstrap.min.css `sha384-xOolHFLEh07PJGoPkLv1IbcEPTNtaed2xpHsD9ESMhqIYd0nLMwNLD69Npy4HI+N`
  - js/bootstrap.bundle.min.js `sha384-Fy6S3B9q64WdZWQUiU+q4/2Lc9npb8tCaSX9FK7E8HnRr0Jz8D6OP9dO5Vg3Q9ct`
  - js/bootstrap.min.js `sha384-+sLIOodYLS7CIrQpBjl+C7nPvqq+FbNUBDunl/OZv93DB7Ln/533i8e/mZXLi/P+`
- License: MIT (see `/lib/LICENCE.md`).
- Added in 30ef6ecea9 (Redmine 1037); verified again 2026-10-23.

## Use in MCZbase

`/shared/_header.cfm` loads `css/bootstrap.min.css` and `js/bootstrap.bundle.min.js`; the bundle
includes Popper.

## Review, 2026-10-23

- OSV lists no current advisories for bootstrap 4.6.2.  CVE-2024-6531 (GHSA-vc8w-jr9v-vj7f, an XSS
  in the carousel's `data-slide` handling, listed as affecting 4.0.0 to 4.6.2) was withdrawn on
  2025-10-09; some scanners may still report it.
- It makes no requests of its own.  The URLs in it are links in comments and error messages.
- Bootstrap 4 reached end of life on 2023-01-01, and 4.6.2 is its last release.  Bootstrap 5
  (5.3.8, 2025-08-26) is maintained, but moving to it is a redesign-wide upgrade, not a drop-in.

## Revisit

Recheck OSV periodically; Bootstrap 4 receives no fixes.
