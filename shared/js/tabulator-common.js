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
 * mczFetchColumnVisibility retrieves persisted column-visibility settings for a page
 * from /shared/component/functions.cfc's getGridColumnHiddenSettings method -- the
 * same backend Taxa.cfm/Agents.cfm's jqxGrid column choosers already persist to, keyed
 * by page_file_path + username + label, so a Tabulator page's settings live in the same
 * place and under the same key shape ({field: hiddenBoolean}) those pages use.
 *
 * Returns a Promise rather than writing to a global (contrast the older jqxGrid pages'
 * window.columnHiddenSettings), so a caller can build a table's columns with the
 * correct initial visibility already applied instead of building with defaults and
 * correcting after the fact.
 *
 * @param pageFilePath the page path settings are stored under (e.g. cgi.script_name).
 * @param label settings label; the app-wide convention is "Default".
 * @return a Promise resolving to a {field: hiddenBoolean} object, or {} if nothing has
 *   been saved yet or the lookup fails.
 */
function mczFetchColumnVisibility(pageFilePath, label) {
	return jQuery.ajax({
		dataType: "json",
		url: "/shared/component/functions.cfc",
		data: {
			method: "getGridColumnHiddenSettings",
			page_file_path: pageFilePath,
			label: label,
			returnformat: "json",
			queryformat: "column"
		}
	}).then(function (result) {
		var settings = result && result[0];
		if (settings && settings.columnhiddensettings) {
			try {
				return JSON.parse(settings.columnhiddensettings);
			} catch (e) {
				console.warn("mczFetchColumnVisibility: could not parse saved settings", e);
			}
		}
		return {};
	}, function (jqXHR, status, error) {
		console.warn("mczFetchColumnVisibility: lookup failed", status, error);
		return {};
	});
}

/**
 * mczEnableClipboardCopy wires a Ctrl/Cmd+C keydown handler on a Tabulator instance so
 * a user's own copy keystroke actually copies the current selection.
 *
 * This is necessary because Tabulator's own clipboard-on-copy-event listener (enabled
 * via the `clipboard: "copy"` table option) only ever runs when triggered through the
 * table's `copyToClipboard()` function -- a plain browser Ctrl+C never reaches it, and
 * instead falls through to whatever native text selection happens to exist, which for
 * a row-selection grid is normally nothing, or leftover selection unrelated to the row
 * click (confirmed against source: the listener's own logic is gated on a `blocked`
 * flag that only `copyToClipboard()` clears).
 *
 * Row selection (SelectRow) and cell/range selection (SelectRange) also aren't handled
 * by the same code path -- SelectRange's active ranges are never fed into the
 * clipboard module's export at all, only row-level "selected"/"active" ranges are -- so
 * this checks which one is active and handles each directly: row selection goes through
 * table.copyToClipboard("selected") (Tabulator's own formatted row export); range
 * selection is built from table.getRangesData() and written via the Clipboard Web API,
 * since Tabulator has no built-in path for it.
 *
 * @param table the Tabulator instance to wire up.
 */
function mczEnableClipboardCopy(table) {
	table.element.addEventListener("keydown", function (e) {
		var isCopy = (e.ctrlKey || e.metaKey) && (e.key === "c" || e.key === "C");
		if (!isCopy) {
			return;
		}
		var selectedRows = table.getSelectedRows();
		if (selectedRows && selectedRows.length) {
			e.preventDefault();
			table.copyToClipboard("selected");
			return;
		}
		var ranges = table.getRangesData ? table.getRangesData() : [];
		if (ranges && ranges.length) {
			e.preventDefault();
			var text = ranges.map(function (rangeRows) {
				return rangeRows.map(function (row) {
					return Object.keys(row).map(function (field) { return row[field]; }).join("\t");
				}).join("\n");
			}).join("\n");
			if (navigator.clipboard && navigator.clipboard.writeText) {
				navigator.clipboard.writeText(text);
			}
		}
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
