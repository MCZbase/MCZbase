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

/**
 * mczColumnVisibilityMenu builds the item list for a Tabulator column's `headerMenu`
 * function, replacing jqxGrid's bespoke jqxListBox-in-a-jqxDialog column chooser with
 * Tabulator's built-in header menu. Assign the RETURN VALUE OF THIS FUNCTION CALL's
 * wrapper, not this function itself, to `headerMenu` -- headerMenu must be a function
 * so the checked/unchecked state is rebuilt fresh each time the menu opens, e.g.:
 *
 *   { title: "...", field: "...", headerMenu: function (e, column) {
 *       return mczColumnVisibilityMenu(column.getTable());
 *   } }
 *
 * @param table the Tabulator instance (a column's headerMenu callback receives the
 *   column component, not the table, so call column.getTable() to get this).
 * @return an array of Tabulator menu item definitions, one per column that declares
 *   a `title`, each toggling that column's visibility via column.toggle(). Known
 *   cosmetic limitation: the checkbox glyph on an already-open menu doesn't update
 *   itself after a toggle (only a fresh open of the menu re-renders it) -- the
 *   underlying visibility change is applied immediately either way.
 */
function mczColumnVisibilityMenu(table) {
	return table.getColumns().filter(function (column) {
		return column.getDefinition().title;
	}).map(function (column) {
		return {
			label: (column.isVisible() ? "☑ " : "☐ ") + column.getDefinition().title,
			action: function (e, menuColumn) {
				/* stopPropagation keeps the menu open after toggling one column, so a
				   user checking/unchecking several columns doesn't have to reopen the
				   menu each time; it still closes normally on an outside click. */
				e.stopPropagation();
				column.toggle();
			}
		};
	});
}

/**
 * mczSafeTextFormatter is a Tabulator cell formatter for plain text values.
 *
 * Tabulator's own default rendering, with no formatter at all, sets the cell's
 * innerHTML directly from the raw value (confirmed by reading tabulator.min.js's
 * _generateContents): a project name, agent name, or any other user-editable text
 * containing "<" is rendered as markup, not escaped. Use this formatter (or
 * mczSafeLinkFormatter below) on every column showing such text instead of leaving
 * the column formatter-less.
 *
 * @param cell the Tabulator cell component passed into a column's formatter.
 * @return a <span> Node with the cell's value set via textContent.
 */
function mczSafeTextFormatter(cell) {
	var span = document.createElement("span");
	span.textContent = cell.getValue();
	return span;
}

/**
 * mczSafeLinkFormatter returns a Tabulator column formatter rendering an <a> whose
 * visible text comes from a row field via textContent (safe for the same reason
 * mczSafeTextFormatter is) and whose href is built by the caller from the row's data,
 * kept separate from the escaped text rather than string-concatenated with it.
 *
 * @param textField field name on the row's data to use as the link's visible text.
 * @param hrefFn function(rowData) returning the href for a given row.
 * @param className optional CSS class string to add to the <a>.
 * @return a formatter function usable as a column's `formatter` option.
 */
function mczSafeLinkFormatter(textField, hrefFn, className) {
	return function (cell) {
		var rowData = cell.getRow().getData();
		var a = document.createElement("a");
		a.href = hrefFn(rowData);
		if (className) {
			a.className = className;
		}
		a.textContent = rowData[textField];
		return a;
	};
}
