// tabulator-common.js
/**** Shared helpers for pages using the Tabulator grid.
 ******/

window.mczTabulatorInstances = window.mczTabulatorInstances || [];

/**
 * mczRegisterTabulatorInstance adds a Tabulator instance to the shared registry.
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
 * attached to the document, and removes from the registry any instance whose element
 * is no longer in the document.
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
 * mczColumnVisibilityMenu builds a Tabulator column-header menu item list, one item
 * per titled column, each toggling that column's visibility.
 *
 * Tabulator's `headerMenu` column option must be a function, not a static array --
 * it is invoked fresh each time the menu is opened -- so assign a function calling
 * this rather than its return value directly, e.g.
 *   { title: "...", field: "...", headerMenu: function (e, column) {
 *       return mczColumnVisibilityMenu(column.getTable());
 *   } }
 * Known limitation: the checkbox glyph on an already-open menu does not update after
 * a toggle (the menu must be reopened to see it); the underlying visibility change
 * itself is applied immediately either way.
 *
 * Lists every column with a title regardless of that column's current visibility --
 * getColumns() returns hidden columns too, so a column merely given `visible: false`
 * still appears here and can be toggled back on by anyone viewing the menu. A column
 * that must not be shown to some users should not be given a column definition at all
 * for those users, rather than being hidden.
 *
 * @param table the Tabulator instance.
 * @return an array of Tabulator menu item definitions.
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
 * Tabulator's default cell rendering (no formatter set) assigns the raw value to the
 * cell's innerHTML directly, without escaping it; a formatter that returns a plain
 * string is rendered the same unescaped way. This formatter instead returns a <span>
 * element with the value set via textContent, so values are always displayed as
 * literal text, never parsed as markup.
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
 * mczSafeLinkFormatter returns a Tabulator column formatter rendering an <a> element
 * whose visible text is set via textContent -- safe for the same reason described on
 * mczSafeTextFormatter above -- and whose href is built from the row's data by a
 * caller-supplied function.
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
