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
 * mczPreventSelectRangeNativeSelection stops Tabulator's SelectRange module from
 * hijacking the browser's native selection (window.getSelection()) for its own cell-
 * focus tracking, on one specific table instance.
 *
 * The module's initializeFocus(cell) method (confirmed against source) does two
 * things: calls restoreFocus() (just table.rowManager.element.focus(), needed for
 * keyboard arrow-key navigation between cells) and, separately, wraps a cell's DOM
 * element in a native Range and adds it via window.getSelection().addRange(). Manual
 * testing traced a real bug to that second part: once a table has done this even once
 * (including just auto-focusing the first cell with no click at all), a later,
 * separately-built Tabulator instance on the same page -- even one with no selection
 * module enabled -- can no longer support native drag-to-select-text, and this
 * persists until a full page reload. Neither an explicit
 * window.getSelection().removeAllRanges() nor a capture-phase event interceptor
 * (both tried first) fixed it, and no matching issue turned up in Tabulator's own
 * issue tracker, so rather than clean up after the fact, this replaces
 * initializeFocus on the instance (shadowing the class's prototype method for this
 * table only, standard JS prototype-shadowing -- every rebuilt table needs this
 * called again, same as any other per-instance setup here) with a version that keeps
 * the restoreFocus() call but skips the native-selection manipulation entirely, since
 * this app has its own CSS-based selection highlighting and doesn't rely on that
 * native selection for anything.
 *
 * Safe to call on any table regardless of whether SelectRange is actually active --
 * every module is always instantiated, just not necessarily initialized, so
 * table.modules.selectRange exists either way.
 *
 * @param table the Tabulator instance to patch.
 */
function mczPreventSelectRangeNativeSelection(table) {
	if (table && table.modules && table.modules.selectRange) {
		table.modules.selectRange.initializeFocus = function () {
			this.restoreFocus();
		};
	}
}

/**
 * mczClearStaleRangeSelectionClass removes the "tabulator-ranges" CSS class from a
 * table's container element.
 *
 * Root cause of a real bug (confirmed against source, not a guess): Tabulator's
 * SelectRange module adds "tabulator-ranges" to the container element the first time
 * cell/range selection initializes (`classList.add("tabulator-ranges")`), and nothing
 * in the library ever removes it again -- not on destroy(), not on tableDestroyed().
 * The bundled theme CSS has `.tabulator.tabulator-ranges .tabulator-cell:not(.tabulator-
 * editing){user-select:none}`, at higher specificity than this app's own
 * `.mcz-text-select-mode .tabulator-cell{user-select:text}` override (see
 * tabulator_overrides.css). So once a container has ever hosted a range-selection-mode
 * table, native text selection stays impossible for every table rebuilt into that same
 * container afterward, including plain "text" mode ones, until a full page reload
 * clears the DOM. Call this right after destroy()ing the old instance and before
 * constructing the next one on the same container.
 *
 * @param container a DOM element, or a jQuery/CSS selector string for one.
 */
function mczClearStaleRangeSelectionClass(container) {
	jQuery(container).removeClass("tabulator-ranges");
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
 * mczEnableClipboardCopy wires a single, page-wide Ctrl/Cmd+C keydown handler so a
 * user's own copy keystroke actually copies the current selection in any registered
 * Tabulator instance.
 *
 * This is necessary because Tabulator's own clipboard-on-copy-event listener (enabled
 * via the `clipboard: "copy"` table option) only ever runs when triggered through the
 * table's `copyToClipboard()` function -- a plain browser Ctrl+C never reaches it, and
 * instead falls through to whatever native text selection happens to exist (confirmed
 * against source: the listener's own logic is gated on a `blocked` flag that only
 * `copyToClipboard()` clears).
 *
 * Row selection (SelectRow) and cell/range selection (SelectRange) also aren't handled
 * by the same code path -- SelectRange's active ranges are never fed into the
 * clipboard module's export at all, only row-level "selected"/"active" ranges are -- so
 * this checks which one is active and handles each directly: row selection goes through
 * table.copyToClipboard("selected") (Tabulator's own formatted row export); range
 * selection is built from table.getRangesData() and written via the Clipboard Web API,
 * since Tabulator has no built-in path for it.
 *
 * Listens on `document`, not a specific table's element, and iterates the shared
 * mczTabulatorInstances registry rather than taking a table argument -- a table's own
 * element (or which descendant of it currently holds focus) isn't reliable to attach
 * to, since a rebuilt table is a new element each time and different selection modes
 * move focus differently. Safe to call more than once; only attaches the listener the
 * first time.
 */
var mczClipboardCopyListenerAttached = false;
function mczEnableClipboardCopy() {
	if (mczClipboardCopyListenerAttached) {
		return;
	}
	mczClipboardCopyListenerAttached = true;
	document.addEventListener("keydown", function (e) {
		var isCopy = (e.ctrlKey || e.metaKey) && (e.key === "c" || e.key === "C");
		if (!isCopy) {
			return;
		}
		var copied = mczCopySelectedFromAllInstances();
		if (copied) {
			e.preventDefault();
		}
	});
}

/**
 * mczCopySelectedFromAllInstances copies the current selection (rows or a cell range)
 * from every registered, still-attached Tabulator instance to the clipboard -- the
 * logic mczEnableClipboardCopy's keydown handler uses, factored out so a plain button
 * (for anyone not using Ctrl/Cmd+C, or where a browser's own context menu doesn't offer
 * a "Copy" item for a non-native selection) can trigger the same behavior directly.
 *
 * @return true if a selection was found and copied in any instance, false otherwise.
 */
function mczCopySelectedFromAllInstances() {
	var copiedAny = false;
	mczTabulatorInstances.forEach(function (table) {
		if (!table || !table.element || !document.body.contains(table.element)) {
			return;
		}
		var selectedRows = table.getSelectedRows();
		if (selectedRows && selectedRows.length) {
			table.copyToClipboard("selected");
			copiedAny = true;
			return;
		}
		var ranges = table.getRangesData ? table.getRangesData() : [];
		if (ranges && ranges.length) {
			var text = ranges.map(function (rangeRows) {
				return rangeRows.map(function (row) {
					return Object.keys(row).map(function (field) { return row[field]; }).join("\t");
				}).join("\n");
			}).join("\n");
			if (navigator.clipboard && navigator.clipboard.writeText) {
				navigator.clipboard.writeText(text);
				copiedAny = true;
			}
		}
	});
	return copiedAny;
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

/**
 * mczAddPageJumpControl replaces a Tabulator grid's native numbered page buttons with a
 * single <select> listing every page, matching the pull-down page selector this app's
 * other (jqxGrid-based) search grids use. The native buttons only ever show a small
 * sliding window around the current page (5 by default), with no way to jump straight to
 * a distant page in a large result set -- there is no documented option to disable just
 * that piece of the built-in pager, so the numbered buttons are hidden via a scoped CSS
 * rule instead (see tabulator_overrides.css) and this control is inserted in their place.
 *
 * @param table the Tabulator instance to add the control to.
 * @param selectId id to give the <select> (without a leading # selector) -- passed in
 *   rather than hardcoded, since a page with more than one Tabulator grid would otherwise
 *   end up with duplicate ids.
 */
function mczAddPageJumpControl(table, selectId) {
	var wrapper = document.createElement("span");
	wrapper.className = "tabulator-page-jump-wrapper";
	var label = document.createElement("label");
	label.setAttribute("for", selectId);
	label.textContent = "Page:";
	var select = document.createElement("select");
	select.id = selectId;
	select.className = "tabulator-page-jump";
	select.addEventListener("change", function () {
		table.setPage(parseInt(select.value, 10));
	});
	wrapper.appendChild(label);
	wrapper.appendChild(select);

	/* Tried on every call below, not just once on "tableBuilt" -- exactly when the
	   pager's own DOM (.tabulator-pages) exists relative to "tableBuilt" firing wasn't
	   reliable in testing, so this keeps retrying (cheaply; a no-op once inserted)
	   rather than depending on one specific event ordering. */
	function ensureInserted() {
		if (wrapper.parentNode) {
			return;
		}
		var pagesElement = table.element.querySelector(".tabulator-pages");
		if (pagesElement && pagesElement.parentNode) {
			pagesElement.parentNode.insertBefore(wrapper, pagesElement);
		}
	}

	function refresh() {
		ensureInserted();
		var lastPage = table.getPageMax ? table.getPageMax() : 1;
		var currentPage = table.getPage ? table.getPage() : 1;
		var html = "";
		for (var page = 1; page <= lastPage; page++) {
			html += "<option value='" + page + "'" + (page === currentPage ? " selected" : "") + ">" + page + "</option>";
		}
		select.innerHTML = html;
	}

	table.on("tableBuilt", refresh);
	/* Fires on every completed load in remote pagination mode -- the initial one, a
	   page/size/sort change, and a fresh search's setPage(1) call alike (confirmed
	   against source) -- so this single handler keeps the option list and selected
	   value correct in every case, not just an actual page-number change. */
	table.on("pageLoaded", refresh);
}
