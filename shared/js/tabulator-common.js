/**  tabulator-common.js
 * Shared helpers for pages using the Tabulator grid. Included on every page from
 * /shared/_header.cfm; defining these functions has no effect on pages that don't
 * call them (the Tabulator library itself is loaded only by pages that use it).

Copyright 2026 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

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

/**
 * mczToNativePromise wraps a jqXHR (or any jQuery Deferred/promise) in a native
 * Promise, for use as the return value of a Tabulator `ajaxRequestFunc`.
 *
 * Tabulator chains .finally() onto whatever ajaxRequestFunc returns (confirmed against
 * source: DataLoader.load() ends in `.finally(...)`, and the table's own initial load
 * ends in `.finally(...)` before dispatching "tableBuilt"). jQuery 3.x Deferreds have
 * then()/catch() but no finally(), so returning a bare $.ajax() result throws a
 * TypeError partway through Tabulator's setup: the rows still render (they are drawn
 * from an earlier then()), but "tableBuilt" never fires, and anything hung off it
 * (e.g. a column chooser) silently never runs. Always return
 * mczToNativePromise($.ajax(...)) from an ajaxRequestFunc instead.
 *
 * @param jqPromise a jqXHR or other jQuery promise.
 * @return a native Promise that settles the same way.
 */
function mczToNativePromise(jqPromise) {
	return Promise.resolve(jqPromise);
}

/**
 * mczFetchColumnOrder retrieves a page's persisted column order from
 * /shared/component/functions.cfc's getGridColumnOrder method -- the same backend and
 * storage format the jqxGrid pages (Taxa.cfm, Agents.cfm, Specimens.cfm) use via
 * saveColumnOrder()/loadColumnOrder(): a JSON array of [field, position] pairs.
 *
 * @param pageFilePath the page path settings are stored under (e.g. cgi.script_name).
 * @param label settings label; the app-wide convention is "Default".
 * @return a Promise resolving to a {field: position} object, or {} if nothing has been
 *   saved yet or the lookup fails.
 */
function mczFetchColumnOrder(pageFilePath, label) {
	return mczToNativePromise(jQuery.ajax({
		dataType: "json",
		url: "/shared/component/functions.cfc",
		data: {
			method: "getGridColumnOrder",
			page_file_path: pageFilePath,
			label: label,
			returnformat: "json",
			queryformat: "column"
		}
	})).then(function (result) {
		var settings = result && result[0];
		var order = {};
		if (settings && settings.column_order) {
			try {
				JSON.parse(settings.column_order).forEach(function (pair) {
					if (Array.isArray(pair) && pair.length === 2 && pair[0]) {
						order[pair[0]] = parseInt(pair[1], 10);
					}
				});
			} catch (e) {
				console.warn("mczFetchColumnOrder: could not parse saved order", e);
			}
		}
		return order;
	}, function (error) {
		console.warn("mczFetchColumnOrder: lookup failed", error);
		return {};
	});
}

/**
 * mczApplyColumnOrder reorders an array of Tabulator column definitions (in place, and
 * also returned) to match a saved {field: position} order from mczFetchColumnOrder.
 * Columns with no saved position keep their original position relative to each other,
 * placed by their original index. Any column definition marked `frozen: true` is kept
 * ahead of every unfrozen one: Tabulator treats a frozen column that follows an
 * unfrozen one as frozen to the right edge instead of the left, and logs a warning
 * when range selection is on and the first column isn't the frozen one.
 *
 * @param columns array of column definition objects (each with a `field`).
 * @param order {field: position} object; {} leaves the array unchanged.
 * @return the same columns array, reordered.
 */
function mczApplyColumnOrder(columns, order) {
	if (!order || Object.keys(order).length === 0) {
		return columns;
	}
	var keyed = columns.map(function (col, index) {
		var position = order.hasOwnProperty(col.field) && !isNaN(order[col.field]) ? order[col.field] : index;
		return { col: col, frozen: col.frozen ? 0 : 1, position: position, index: index };
	});
	keyed.sort(function (a, b) {
		return (a.frozen - b.frozen) || (a.position - b.position) || (a.index - b.index);
	});
	keyed.forEach(function (entry, i) {
		columns[i] = entry.col;
	});
	return columns;
}

/**
 * mczSaveTableColumnOrder persists a table's current column order through the shared
 * saveColumnOrder() function in /shared/js/shared-scripts.js, in the same
 * [field, position] format the jqxGrid pages write.
 *
 * @param table the Tabulator instance.
 * @param pageFilePath the page path settings are stored under (e.g. cgi.script_name).
 * @param label settings label; the app-wide convention is "Default".
 * @param feedbackDiv optional id (no leading #) of an element to show save feedback in.
 */
function mczSaveTableColumnOrder(table, pageFilePath, label, feedbackDiv) {
	var columnMap = new Map();
	var position = 0;
	/* Count only columns with a field, so a checkbox row-selection column (which has
	   none) doesn't shift the saved positions. */
	table.getColumns().forEach(function (column) {
		var field = column.getField();
		if (field) {
			columnMap.set(field, position);
			position++;
		}
	});
	saveColumnOrder(pageFilePath, columnMap, label, feedbackDiv);
}

/**
 * mczBuildExportRows turns an array of row data objects into an array of arrays (a
 * header row, then one array per data row) using a Tabulator table's column
 * definitions for the header text, column order, and any per-column accessorDownload
 * -- so a caller can export rows fetched separately from the server (e.g. every
 * matching row, in remote pagination mode, where table.download() would only see the
 * one page currently loaded), or the table's own selected rows.
 *
 * Columns without a field, or with `download: false`, are always left out. Hidden
 * columns are included when includeHidden is true, matching the jqxGrid pages'
 * exportGridToCSV(), which exports hidden columns too.
 *
 * @param table the Tabulator instance whose columns describe the export.
 * @param rows array of row data objects, keyed by field.
 * @param includeHidden true to include hidden columns.
 * @return array of arrays; element 0 is the header row.
 */
function mczBuildExportRows(table, rows, includeHidden) {
	var columns = table.getColumns().filter(function (column) {
		var def = column.getDefinition();
		return def.field && def.download !== false && (includeHidden || column.isVisible());
	});
	var result = [columns.map(function (column) {
		var def = column.getDefinition();
		return def.titleDownload || def.title || def.field;
	})];
	rows.forEach(function (row) {
		result.push(columns.map(function (column) {
			var def = column.getDefinition();
			var value = row[def.field];
			if (typeof def.accessorDownload === "function") {
				value = def.accessorDownload(value, row, "download", def.accessorDownloadParams || {}, column);
			}
			return (value === null || value === undefined) ? "" : value;
		}));
	});
	return result;
}

/**
 * mczBuildCsv builds CSV text from an array of row data objects; see
 * mczBuildExportRows for which columns are included and how values are taken.
 *
 * @param table the Tabulator instance whose columns describe the export.
 * @param rows array of row data objects, keyed by field.
 * @param includeHidden true to include hidden columns.
 * @return CSV text (no byte order mark; exportToCSV() in shared-scripts.js adds one).
 */
function mczBuildCsv(table, rows, includeHidden) {
	function escapeCsv(value) {
		var text = String(value);
		if (/[",\r\n]/.test(text)) {
			text = '"' + text.replace(/"/g, '""') + '"';
		}
		return text;
	}
	return mczBuildExportRows(table, rows, includeHidden).map(function (line) {
		return line.map(escapeCsv).join(",");
	}).join("\r\n");
}

/**
 * mczLoadScriptOnce loads a script by adding a <script> element, at most once per src,
 * so a large library only a few users need (e.g. ExcelJS for Excel export) is fetched
 * on first use instead of on every page load.
 *
 * @param src the script URL.
 * @return a Promise resolved once the script has loaded.
 */
var mczLoadedScripts = {};
function mczLoadScriptOnce(src) {
	if (!mczLoadedScripts[src]) {
		mczLoadedScripts[src] = new Promise(function (resolve, reject) {
			var script = document.createElement("script");
			script.src = src;
			script.onload = function () { resolve(); };
			script.onerror = function () {
				delete mczLoadedScripts[src];
				reject(new Error("Could not load " + src));
			};
			document.head.appendChild(script);
		});
	}
	return mczLoadedScripts[src];
}

/** Path of the vendored ExcelJS browser build (MIT license), loaded on first use. */
var mczExcelJsSrc = "/lib/ExcelJS/exceljs_ver4.4.0/exceljs.min.js";

/**
 * mczExportRowsToExcel downloads rows as an .xlsx workbook with one worksheet, using
 * ExcelJS (loaded on first use). Takes the same inputs as mczBuildCsv. Values are
 * written as text, as they appear in the grid, so identifiers such as catalog
 * numbers keep leading zeros instead of being converted to numbers by Excel.
 *
 * @param table the Tabulator instance whose columns describe the export.
 * @param rows array of row data objects, keyed by field.
 * @param includeHidden true to include hidden columns.
 * @param filename download filename, ending in .xlsx.
 * @param sheetName worksheet name (Excel allows at most 31 characters).
 * @return a Promise resolved once the download has been started.
 */
function mczExportRowsToExcel(table, rows, includeHidden, filename, sheetName) {
	var aoa = mczBuildExportRows(table, rows, includeHidden).map(function (line) {
		return line.map(function (value) { return String(value); });
	});
	return mczLoadScriptOnce(mczExcelJsSrc).then(function () {
		var workbook = new ExcelJS.Workbook();
		var sheet = workbook.addWorksheet(String(sheetName || "Results").substring(0, 31));
		sheet.addRows(aoa);
		sheet.getRow(1).font = { bold: true };
		sheet.views = [{ state: "frozen", ySplit: 1 }];
		return workbook.xlsx.writeBuffer();
	}).then(function (buffer) {
		var blob = new Blob([buffer], { type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" });
		var link = document.createElement("a");
		link.href = URL.createObjectURL(blob);
		link.download = filename;
		document.body.appendChild(link);
		link.click();
		document.body.removeChild(link);
		setTimeout(function () { URL.revokeObjectURL(link.href); }, 10000);
	});
}

/**
 * mczExportFilename builds a download filename in the pattern the jqxGrid pages use
 * (see gridLoaded() in Taxa.cfm): {searchType}_results_{timestamp}.{extension}.
 *
 * @param searchType e.g. "project".
 * @param extension "csv" or "xlsx".
 * @return the filename.
 */
function mczExportFilename(searchType, extension) {
	return searchType + "_results_" + new Date().toISOString().replace(/[^0-9TZ]/g, "_") + "." + extension;
}

/**
 * mczIsDataColumn reports whether a column definition describes a column holding a
 * row's data, as opposed to one holding a control (a details button, an edit link).
 *
 * Control columns are marked by a field name beginning "_mcz" -- a name no query
 * returns, so it cannot collide with a real database field. The test is on the field
 * name rather than on `download: false` because those mean different things:
 * `download: false` means only "leave this column out of CSV/Excel exports", which a
 * genuine data column may legitimately want, and using it as a proxy for "not data"
 * silently drops such a column from the row details dialog too -- the one place it
 * would still be wanted. A purpose-built column-definition property would read better
 * but is not usable here: Tabulator's OptionsList.generate() console.warns on any
 * column key it does not recognize (gated on debugInvalidOptions, which defaults to
 * true), once per offending column on every build -- and these tables rebuild on every
 * search and every selection-mode change. (Note for anyone chasing that message: the
 * method named checkDefinition(), whose text reads "Invalid column definition option
 * in 'X' column", appears exactly once in tabulator.min.js and is never called. The
 * warning that actually fires is OptionsList.generate()'s shorter one.)
 *
 * @param definition a Tabulator column definition, as column.getDefinition() returns.
 * @return true if the column holds row data.
 */
function mczIsDataColumn(definition) {
	return !!(definition && definition.field && definition.title
		&& definition.field.indexOf("_mcz") !== 0);
}

/**
 * mczHideableColumns returns the columns a user can show or hide: every column with a
 * title, which is what the Select Columns chooser lists and therefore what a
 * "show hidden columns" control has to be able to bring back.
 *
 * @param table the Tabulator instance.
 * @return an array of ColumnComponents.
 */
function mczHideableColumns(table) {
	return table.getColumns().filter(function (column) {
		return !!column.getDefinition().title;
	});
}

/**
 * mczShowAllColumns makes every hidden column visible again.
 *
 * This needs a control of its own because "Hide column" in a column's header menu
 * removes the very header that menu lives in, leaving no way back from the control
 * that did the hiding; without this, a user has to already know that the Select
 * Columns dialog lists hidden columns as well as shown ones.
 *
 * @param table the Tabulator instance.
 * @return the number of columns made visible.
 */
function mczShowAllColumns(table) {
	var shown = 0;
	mczHideableColumns(table).forEach(function (column) {
		if (!column.isVisible()) {
			column.show();
			shown++;
		}
	});
	return shown;
}

/**
 * mczRefreshShowHiddenColumnsButton matches a "show hidden columns" button to the
 * table's current state: hidden when nothing is hidden, otherwise shown and labelled
 * with the count, so the button states what it will actually do. Set as text, never
 * markup.
 *
 * @param table the Tabulator instance.
 * @param buttonId id (no leading #) of the button element.
 */
function mczRefreshShowHiddenColumnsButton(table, buttonId) {
	var hidden = mczHideableColumns(table).filter(function (column) {
		return !column.isVisible();
	}).length;
	var button = jQuery("#" + buttonId);
	if (hidden === 0) {
		button.hide();
		return;
	}
	button.text("Show " + hidden + " Hidden Column" + (hidden === 1 ? "" : "s"));
	button.show();
}

/**
 * mczShowRowDetailsDialog opens a jQuery UI dialog listing every column's title and
 * value for one row, including hidden columns -- the Tabulator counterpart of
 * createRowDetailsDialog() in shared-scripts.js used by the jqxGrid pages' row
 * details. Values are inserted as text, never as markup.
 *
 * @param table the Tabulator instance.
 * @param row the RowComponent to show.
 * @param title optional dialog title; defaults to "Record Details".
 */
function mczShowRowDetailsDialog(table, row, title) {
	var data = row.getData();
	var list = document.createElement("dl");
	list.className = "mb-0";
	table.getColumns().forEach(function (column) {
		var def = column.getDefinition();
		if (!mczIsDataColumn(def)) {
			return;
		}
		var value = data[def.field];
		if (typeof def.accessorDownload === "function") {
			value = def.accessorDownload(value, data, "download", def.accessorDownloadParams || {}, column);
		}
		var term = document.createElement("dt");
		term.textContent = def.title;
		var detail = document.createElement("dd");
		detail.className = "mb-2";
		detail.textContent = (value === null || value === undefined || value === "") ? "—" : value;
		list.appendChild(term);
		list.appendChild(detail);
	});
	var dialog = document.createElement("div");
	dialog.appendChild(list);
	var width = Math.max(300, Math.min(600, Math.round(table.element.offsetWidth / 2)));
	jQuery(dialog).dialog({
		title: title || "Record Details",
		width: width,
		modal: false,
		closeOnEscape: true,
		buttons: [{ text: "Ok", click: function () { jQuery(this).dialog("close"); } }],
		close: function () { jQuery(this).dialog("destroy").remove(); }
	});
}

/**
 * mczDetailsButtonColumn returns a column definition for a narrow, unsortable,
 * non-exported column holding a button that opens mczShowRowDetailsDialog for its row.
 *
 * @param dialogTitle optional title for the details dialog.
 * @return a column definition object.
 */
function mczDetailsButtonColumn(dialogTitle) {
	return {
		title: "Details",
		field: "_mczDetails",
		width: 80,
		headerSort: false,
		download: false,
		hozAlign: "center",
		formatter: function () {
			var button = document.createElement("button");
			button.type = "button";
			/* btn-outline-primary: the style the developer's guide gives buttons inside a
			   results grid cell. */
			button.className = "btn btn-xs btn-outline-primary py-0";
			button.setAttribute("aria-label", "Show all values for this row");
			/* fa-list-ul rather than fa-info-circle: the dialog is this row's fields as a
			   list, and an "i" in a circle is the web-wide convention for help or an
			   explanation of a feature, which is not what this opens. Avoid fa-eye (already
			   the hide-search-form toggle), fa-file-alt (reads as the CSV/Excel downloads)
			   and any magnifier (reads as search on a search page). */
			button.innerHTML = '<i class="fas fa-list-ul" aria-hidden="true"></i>';
			return button;
		},
		cellClick: function (e, cell) {
			mczShowRowDetailsDialog(cell.getTable(), cell.getRow(), dialogTitle);
		}
	};
}

/**
 * mczStandardHeaderMenu returns a Tabulator `headerMenu` (a function, so the items
 * reflect the column's state each time the menu opens) offering: sort ascending,
 * sort descending, hide this column, and "Select Columns...".
 *
 * @param options object with optional callbacks:
 *   onColumnHidden(column) -- called after "Hide column" (e.g. to persist visibility);
 *   onChooseColumns() -- called by "Select Columns..." (e.g. to open the chooser dialog).
 * @return a function usable as a column's headerMenu option.
 */
function mczStandardHeaderMenu(options) {
	options = options || {};
	return function (e, column) {
		var items = [];
		if (column.getDefinition().headerSort !== false) {
			items.push({
				label: '<i class="fas fa-sort-alpha-down mr-2" aria-hidden="true"></i>Sort ascending',
				action: function (e, col) { col.getTable().setSort(col.getField(), "asc"); }
			});
			items.push({
				label: '<i class="fas fa-sort-alpha-up mr-2" aria-hidden="true"></i>Sort descending',
				action: function (e, col) { col.getTable().setSort(col.getField(), "desc"); }
			});
			items.push({ separator: true });
		}
		items.push({
			label: '<i class="fas fa-eye-slash mr-2" aria-hidden="true"></i>Hide column',
			action: function (e, col) {
				col.hide();
				if (options.onColumnHidden) { options.onColumnHidden(col); }
			}
		});
		if (options.onChooseColumns) {
			items.push({
				label: '<i class="fas fa-columns mr-2" aria-hidden="true"></i>Select Columns...',
				action: function () { options.onChooseColumns(); }
			});
		}
		return items;
	};
}

/**
 * mczHeaderFilterParams converts Tabulator's remote-mode filter list
 * ([{field, type, value}], sent when filterMode is "remote") into flat request
 * parameters named {prefix}{field}, keeping only fields in allowedFields -- flat
 * name/value pairs are what a ColdFusion cfargument can read, unlike the nested
 * filter[0][field]=... form jQuery would otherwise serialize the array into.
 *
 * @param filters the `filter` array from Tabulator's request params (may be undefined).
 * @param allowedFields array of field names the backing search method accepts.
 * @param prefix parameter name prefix, e.g. "filter_".
 * @return an object of {prefix+field: value}.
 */
function mczHeaderFilterParams(filters, allowedFields, prefix) {
	var result = {};
	(filters || []).forEach(function (filter) {
		if (filter && allowedFields.indexOf(filter.field) !== -1 && filter.value !== null && filter.value !== undefined && String(filter.value).trim() !== "") {
			result[prefix + filter.field] = String(filter.value).trim();
		}
	});
	return result;
}

/**
 * mczHeaderFilterLabel returns headerFilterParams giving a column's header filter input
 * an accessible name ("Filter {title}"). Tabulator's header filter inputs otherwise
 * have only a placeholder, which the developer's guide doesn't accept as a label.
 * aria-label is the one naming mechanism used, since the input has no visible label.
 *
 * @param columnTitle the column's title as shown in its header.
 * @return an object usable as a column's headerFilterParams.
 */
function mczHeaderFilterLabel(columnTitle) {
	return { elementAttributes: { "aria-label": "Filter " + columnTitle } };
}

/**
 * mczMakeHeaderMenuButtonsAccessible makes each column's header menu button (the ⋮
 * that headerMenu adds, which Tabulator renders as a plain <span>) reachable and
 * operable from the keyboard, and gives it an accessible name. Call on "tableBuilt",
 * and again after anything that rebuilds a column header (e.g. updateDefinition).
 *
 * @param table the Tabulator instance.
 */
function mczMakeHeaderMenuButtonsAccessible(table) {
	table.getColumns().forEach(function (column) {
		var title = column.getDefinition().title;
		var button = column.getElement().querySelector(".tabulator-header-popup-button");
		if (!button || !title || button.getAttribute("data-mcz-accessible")) {
			return;
		}
		button.setAttribute("data-mcz-accessible", "true");
		button.setAttribute("role", "button");
		button.setAttribute("tabindex", "0");
		button.setAttribute("aria-label", "Column options for " + title);
		button.setAttribute("aria-haspopup", "menu");
		button.addEventListener("keydown", function (e) {
			if (e.key === "Enter" || e.key === " ") {
				e.preventDefault();
				e.stopPropagation();
				button.click();
			}
		});
	});
}
