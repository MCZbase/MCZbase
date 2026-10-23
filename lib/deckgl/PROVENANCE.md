# deck.gl 8.9.5: provenance and review

## Source

The three files are the `dist.min.js` browser bundles from these npm releases (published
2023-03-30), renamed and otherwise unmodified.  Each tarball's integrity matches the registry's
published value.

| File | npm release | SHA-256 |
|---|---|---|
| deck.gl.min.js | `deck.gl@8.9.5` | `390299d85c177c00c59cf00277382b6bd6a4ae2fc9ce6c2e6c04f42007beed8c` |
| deckgl-aggregation-layers.min.js | `@deck.gl/aggregation-layers@8.9.5` | `d34920005aa542061925cf8270ca8b93c7a8b7e0c82b45ec6fae0447400a9f11` |
| deckgl-google-maps.min.js | `@deck.gl/google-maps@8.9.5` | `b68e87900c6f39e98f04bbea74db4019fd444f8501509ea376938dd691d075e6` |

- License: MIT (see `/lib/LICENCE.md`; https://github.com/visgl/deck.gl).
- Added in 7fc8791cbb (Redmine 1013) under `/shared/js/`, moved here in ad182133a8; verified
  2026-10-23.

## Use in MCZbase

`/shared/js/mcz-heatmap-distMap.js` draws a heatmap (`HeatmapLayer`) or points (`ScatterplotLayer`)
of georeferenced localities over Google Maps (`GoogleMapsOverlay`), replacing the Google Maps
heatmap layer.  `/shared/_header.cfm` loads it, with the Google Maps API, on `/agents/Agent.cfm` and
`/grouping/showNamedCollection.cfm` (including the `/namedGroup/` route).

## Review, 2026-10-23

- OSV lists no advisories for deck.gl, @deck.gl/core, @deck.gl/aggregation-layers or
  @deck.gl/google-maps 8.9.5, or for the bundled @luma.gl/core and @loaders.gl/core.
- The bundle contains default URLs for fetching code from outside: loaders.gl worker scripts and
  texture decoders from unpkg.com, Draco decoders from www.gstatic.com, and an h3-js script tag that
  appears only in an error message.  These are used only when a layer loads data or textures from
  a URL with those loaders.  MCZbase passes in-memory arrays (`data: data`), so none of them is
  requested.  New uses of deck.gl that load data by URL should set `loadOptions` so nothing is
  fetched from a CDN.
- Upstream is actively maintained (9.4.0, 2026-09-05).  8.9.5 is an early 8.9 release; 8.9.36
  (2024-04-23) is the last 8.x.

## Revisit

Consider 8.9.36 (same major) or 9.x; recheck OSV and record the new checksums here.
