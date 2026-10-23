# ExcelJS 4.4.0: provenance and review

## Source

- `exceljs.min.js` is `package/dist/exceljs.min.js` from the npm release `exceljs@4.4.0`
  (https://registry.npmjs.org/exceljs/-/exceljs-4.4.0.tgz, published 2023-10-19), unmodified.
- Tarball integrity, matching the registry's published value:
  `sha512-XctvKaEMaj1Ii9oDOqbW/6e1gXknSY4g/aLCDicOXqBE4M0nRWkUu0PTp++UPNzoFY12BNHMfs/VadKIS6llvg==`
- `exceljs.min.js` SHA-256:
  `7e49da68588e250dbb8bba190d2caa8ab3787cc0284bda1d8b2f805c4df742c9`
- License: MIT (`LICENSE`).
- Added in 8751b3a4d3 (Redmine 1023); verified against npm 2026-10-23.

## Use in MCZbase

`mczExportRowsToExcel()` in `/shared/js/tabulator-common.js` uses it to export a Tabulator grid's
rows as a one-sheet .xlsx file.  It is loaded from this directory only when a user first chooses an
Excel export, not with the page.  Use is write-only: values are written as text, and no
spreadsheet is ever read or parsed with it.  Projects.cfm is the first page to call it.

## Security review, 2026-10-23

- OSV lists no advisories for exceljs 4.4.0 itself.  Advisories for its Node-only dependency
  `tmp` don't apply to this browser build, which doesn't contain it.
- The browser build bundles `elliptic` 6.5.4 by way of the browserify crypto shim.  Its
  advisories concern ECDSA/EdDSA signing and verification, which ExcelJS never calls.  Dependency
  scanners will still report it.
- The bundle makes no network requests and loads no other scripts.  The URLs in it are XML
  namespace names and links in licenses and error messages.  Its only `new Function` uses are in
  polyfill code that current browsers don't run; they would matter only under a strict
  Content-Security-Policy.
- Upstream (https://github.com/exceljs/exceljs) has been dormant: no release since 4.4.0 and no
  commit since 2024-01.  The fork `exceljs-hardened` reports and patches unpublished upstream
  vulnerabilities (prototype pollution, local file read, decompression bombs, unescaped values in
  formulas and XML).  A review of its patches found each one in code MCZbase doesn't use: reading
  files, `addImage()` with a file path, cell comments, tables, conditional formats, pivot tables,
  merged cells, the streaming writer or ExcelJS's own CSV writer.

## Revisit

- Before using ExcelJS to read uploaded spreadsheets, choose the library again: the unpatched
  problems are on the reading path.
- Around 2027-04, look again at the forks for one with a lasting maintainer.  Candidates in
  2026-10: `exceljs-hardened` (security fixes, one volunteer), `@mui/x-internal-exceljs-fork`
  (MUI, for its own data grid), `devextreme-exceljs-fork` (DevExpress, for its own products) and
  `exceljs-community`.
- Recheck OSV whenever another page starts to use it.
