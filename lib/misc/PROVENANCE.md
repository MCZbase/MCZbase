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

## multizoom/

- Original: Multi-Zoom (John Davenport Scheuer, 2012) with Dynamic Drive's Featured Image Zoomer,
  from https://www.dynamicdrive.com/dynamicindex4/multizoom.js.  That site is gone (the domain is
  parked).  The first copy, committed as `includes/js/multizoom/` in 77a7317306 (2015-06-29):
  - `multizoom.js` is identical (apart from line endings) to the Internet Archive's snapshots of
    the original from 2015-08-13 and 2017-08-03 (and later ones checked), so it was the
    current release when copied.
  - `spinningred.gif` is identical to the 2015-09-19 snapshot.
  - `multizoom.css` started from the original (2013-03-14 snapshot) and has MCZbase's sizing and
    class-name changes (c21187c1d6 onward).
- MCZbase changes since: jQuery 3 compatibility (2023-03-09) and the `executeMultizoom` switch
  (0cea7e77bb).
- SHA-256 now: multizoom.js `c884c9757d5960f93201e0439d09049ed2056df3870a49e6d981a9bd9f50fba7`,
  multizoom.css `c3e4d4a7c9d9b0bc7d4a061b912859d22d819a4780edb2d8af3b9099b5b13b1b`,
  spinningred.gif `13ba8183b164cd9dfac87ba272700552f0efb110f3b627dc1e3bc6071a99f31b`
- Licence: not an open-source licence.  The script's notice "must remain for legal use", and
  Dynamic Drive's terms of use (revision of 2015-07-07, as archived) allow free use and
  modification on any site, but not redistributing the scripts for download.
- Loaded on every page by `/shared/_header.cfm`.  It requests only the images a page gives it.
