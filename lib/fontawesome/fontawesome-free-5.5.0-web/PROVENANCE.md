# Font Awesome Free 5.5.0: provenance and review

## Source

- This is the "web" download, https://use.fontawesome.com/releases/v5.5.0/fontawesome-free-5.5.0-web.zip.
  Compared with that zip on 2026-10-23:
  - 1,091 files are identical to it, including everything pages load (`css/all.css` and the
    `webfonts/` it refers to).  No file was modified.
  - Not from the zip: 12 `.css` files in `less/` and `scss/`, which are compiled copies of the
    LESS/SCSS sources there (each opens with the Font Awesome banner).  Nothing loads them.
  - Left out of the commit: `svgs/brands/` and `LICENSE.txt`.
  - The `index.cfm` files are MCZbase's, to stop directory listings.
- The npm release `@fortawesome/fontawesome-free@5.5.0` (tarball integrity matches the registry's
  published value) has the same `css/`, `js/`, `webfonts/` and source files.
- SHA-256: css/all.css `440b5661211b0b6946647e97477e376fdceebb9e698578601e8bba04e1acd255`,
  css/all.min.css `9e4cac65c7a5ee0bd0743afefcabdd3e73854e1284ac9ac433813d6231f550f2`
- License: icons CC BY 4.0, fonts SIL OFL 1.1, code MIT (see `/lib/LICENCE.md`;
  https://fontawesome.com/license/free).
- Added in 15f094f696 (2020-04-03); verified 2026-10-23.

## Use in MCZbase

`/shared/_header.cfm` loads `css/all.css`, which loads the webfonts.

## Review, 2026-10-23

- OSV lists no advisories for @fortawesome/fontawesome-free 5.5.0.
- Pages use only the CSS and fonts, which make no requests beyond the font files in this directory.
- Font Awesome 5 is superseded: its last release was 5.15.4 (2021-08-04), and 7.x is current
  (7.3.1, 2026-07-15).  Icon names changed between majors, so moving up is an upgrade project.

## Revisit

Only `css/`, `webfonts/` and the license are needed at runtime; the rest could be dropped when
upgrading.
