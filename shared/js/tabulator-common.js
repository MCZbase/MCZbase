// tabulator-common.js
/**** Shared helpers for pages using the Tabulator grid (Redmine 1023, replacing jqxGrid).
 * This file holds the parts of the shared foundation that other shared/js files (in
 * particular wikiDrawer.js's resizeAllGridsToContent()) need to depend on, so that
 * dependency is on one small, stable file rather than on whichever page happens to
 * build a given grid.
 ******/

window.mczTabulatorInstances = window.mczTabulatorInstances || [];

/**
 * mczRegisterTabulatorInstance records a live Tabulator instance so shared code
 * (e.g. the wiki-help drawer's resize handler) can find and redraw it later without
 * every page having to know about every other page's grid(s).
 *
 * @param table the Tabulator instance returned by `new Tabulator(...)`.
 */
function mczRegisterTabulatorInstance(table) {
	if (table) {
		mczTabulatorInstances.push(table);
	}
}

/**
 * mczRedrawAllTabulatorInstances redraws every registered Tabulator instance still
 * attached to the document, pruning any whose element has been removed (e.g. by a
 * prior destroy()) so the registry doesn't grow stale entries across a page's lifetime.
 * Called after any layout change that resizes a grid's container without a window
 * resize event, e.g. the wiki-help sidebar drawer opening or closing.
 */
function mczRedrawAllTabulatorInstances() {
	mczTabulatorInstances = mczTabulatorInstances.filter(function (table) {
		return table && table.element && document.body.contains(table.element);
	});
	mczTabulatorInstances.forEach(function (table) {
		try {
			table.redraw(true);
		} catch (e) {
			console.warn("mczRedrawAllTabulatorInstances: redraw failed", e);
		}
	});
}
