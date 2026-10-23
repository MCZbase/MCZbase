# lib/misc: provenance

Small scripts with no current release to check against.  Each was compared with its original, and
the differences are MCZbase's own changes, recorded in this repository's history.  Verified
2026-10-23.

## sorttable.js

- Original: Stuart Langridge's sorttable (version 1), http://www.kryogenix.org/code/browser/sorttable/,
  MIT licence.  The first copy, committed as `includes/sorttable.js` in 425173a4be (2012-10-16), is
  identical (apart from line endings) to the Internet Archive's 2006-12-30 snapshot of
  http://kryogenix.org/code/browser/sorttable/sorttable.js.
- MCZbase changes since: a usage comment, the sort arrows shown, and sorting by a cell's selected
  `<select>` option (a97af0265e, 1efd377806).
- SHA-256 now: `5c8fa9c8686edd2ada34fce795b2b6744104d2ca1ea6b358e39595eae234f98f`
- Used by pages with `<table class="sortable">`.  It makes no requests.

## jquery.jfeed.js

- Original: jFeed by Jean-François Hovinne, https://github.com/jfhovinne/jFeed (archived;
  last change 2017), dual MIT/GPL.  The first copy, committed as `includes/js/jfeed/jquery.jfeed.js`
  in 5a5c0fa0ae (2015-07-13), is upstream's `build/dist/jquery.jfeed.js` with an `author` field on
  items and a console log of feed errors added.  No upstream version contains those additions, so
  they appear to have been made when it was first committed.
- MCZbase changes since: the Internet Explorer branches, which used `jQuery.browser`, removed
  (8f617510f2).
- SHA-256 now: `74a67dca3bf9fdb122628eabee043f7129adc144c7fbc96cbd3d3c85d4f6605a`
- Loaded by `/shared/_header.cfm` when a page sets `addheaderresource` to `feedreader`.  It
  requests only the feed URL the page gives it.

multizoom (Dynamic Drive's Featured Image Zoomer), formerly here, was replaced in 2026-10 by
`/shared/js/media-zoom.js`, as its terms of use don't allow redistribution.
