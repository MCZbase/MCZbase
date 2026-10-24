# Tabulator 6.5.2: provenance and review

## Source

- `js/tabulator.min.js`, `css/tabulator_bootstrap4.min.css` and `LICENSE` are
  `package/dist/js/tabulator.min.js`, `package/dist/css/tabulator_bootstrap4.min.css` and
  `package/LICENSE` from the npm release `tabulator-tables@6.5.2` (published 2026-06-23), unmodified.
  The package has no runtime dependencies.
- npm tarball integrity, matching the registry's published value:
  `sha512-cRL3xsaaf5RzND8KPbn4C9Ce5tzyiQUE01E/10zN50MjdRKl/Gl5nXkzLN6cvEyRfWHCPuqBF92y50CBw20WYA==`
- SHA-256 (hex):
  - js/tabulator.min.js `04802e757fa4189342c666d0f970a01d761c312798f31ffc664c24cbccc7ce3e`
  - css/tabulator_bootstrap4.min.css `71b43770c15f521586e75379a6e2a6e3da73b0b9a9bedb8273f276d26bf2c6ba`
- License: MIT (`LICENSE`).
- Added in fa8fbb8aa5 (Redmine 1023); verified again 2026-10-23.

## Use in MCZbase

The pages listed in `TABULATOR_PAGES` in `/shared/_header.cfm` (Projects.cfm so far) load it
themselves, together with `/shared/js/tabulator-common.js`.  It is replacing jqxGrid.

## Review, 2026-10-23

- OSV lists no advisories for tabulator-tables 6.5.2.
- Its only requests are its AJAX module's `fetch` to the `ajaxURL` a page configures (a backing
  `search.cfc` method); it loads no other scripts.  Its built-in Excel download would use SheetJS only
  if a page had loaded it; MCZbase pages use ExcelJS instead (`/lib/ExcelJS/`).
- Tabulator renders cell values as HTML by default.  `tabulator-common.js` provides
  `mczSafeTextFormatter` and `mczSafeLinkFormatter` so cells are set as text.
- Upstream (https://github.com/olifolkerd/tabulator) is actively maintained: 6.5.3, 6.6.x and 6.7.x
  were released 2026-09 and 2026-10.  None of those release notes lists a security fix.

## Revisit

Upgrade when convenient: put the new release in its own `tabulator_ver{version}` directory, retest
the accessibility changes in `tabulator-common.js` (they depend on Tabulator's markup), and record the
new checksums.
