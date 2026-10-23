/**  tabulator-common.js
 * Shared helpers for pages using the Tabulator grid. Included from /shared/_header.cfm
 * on the pages listed in TABULATOR_PAGES there (the Tabulator library itself is loaded
 * by each of those pages).

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
 * changing the browser's native text selection on one table.
 *
 * SelectRange's initializeFocus() focuses the table, which arrow-key navigation needs,
 * and also adds the cell to window.getSelection(). After that has happened once, other
 * Tabulator tables on the page lose drag-to-select-text until the page is reloaded;
 * removeAllRanges() does not fix it. This replaces initializeFocus on this instance
 * only, keeping the focus call and dropping the selection change. MCZbase highlights
 * selections with CSS, so nothing depends on the native selection.
 *
 * Call it on every newly built table. It is safe whether or not SelectRange is
 * enabled, because table.modules.selectRange always exists.
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
 * mczClearStaleRangeSelectionClass removes the "tabulator-ranges" class from a table's
 * container.
 *
 * SelectRange adds that class and never removes it, not even on destroy(). The theme
 * CSS then turns off text selection in the container, overriding
 * .mcz-text-select-mode (tabulator_overrides.css), so any table later rebuilt there
 * cannot have its text selected. Call this after destroy() and before building the
 * next table in the same container.
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
 * mczFetchColumnVisibility gets a page's saved column visibility from
 * getGridColumnHiddenSettings in /shared/component/functions.cfc, the same storage
 * the jqxGrid pages (Taxa.cfm, Agents.cfm) use. It returns a Promise so the caller
 * can build columns with the saved visibility instead of correcting it afterwards.
 *
 * @param pageFilePath the page path settings are stored under (e.g. cgi.script_name).
 * @param label settings label; the app-wide convention is "Default".
 * @return a Promise resolving to {field: hidden}, or {} if nothing is saved or the
 *   lookup fails.
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
 * mczEnableClipboardCopy makes Ctrl/Cmd+C copy the selection in any registered
 * Tabulator table.
 *
 * With `clipboard: "copy"`, Tabulator copies only when copyToClipboard() is called; a
 * plain Ctrl+C never reaches it. The listener is on document, not a table, because a
 * rebuilt table is a new element and the selection modes move focus differently. Safe
 * to call more than once; the listener is attached only the first time.
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
 * mczCopySelectedFromAllInstances copies the selected rows or cell range from every
 * registered table still on the page. Used by the Ctrl+C handler and by a Copy button.
 *
 * Selected rows go through copyToClipboard("selected"). Tabulator's clipboard ignores
 * cell ranges, so a range is built from getRangesData() and written with the browser's
 * Clipboard API.
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
 * mczSafeTextFormatter is a Tabulator cell formatter that shows a value as text.
 * Tabulator's default rendering, and a formatter returning a string, put the value into
 * innerHTML unescaped; this sets textContent instead.
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
 * mczSafeLinkFormatter returns a Tabulator formatter that renders a link, with its text
 * set as textContent (see mczSafeTextFormatter) and its href built from the row data.
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
 * mczOverflowTooltip is a Tabulator column `tooltip` that shows a cell's full text, but
 * only when the cell is too narrow to show all of it. Returns an element with the text
 * set as textContent, because Tabulator puts a returned string into innerHTML
 * unescaped. Returns null for no tooltip; a returned false would be shown as "false".
 *
 * @param e the mouse event.
 * @param cell the CellComponent under the pointer.
 * @return a <div> holding the cell's text, or null if nothing is cut off.
 */
function mczOverflowTooltip(e, cell) {
	var element = cell.getElement();
	var text = element.textContent;
	if (!text || element.scrollWidth <= element.clientWidth) {
		return null;
	}
	var tooltip = document.createElement("div");
	tooltip.textContent = text;
	return tooltip;
}

/* Escape closes an open Tabulator tooltip (WCAG 1.4.13: content shown on hover must be
   dismissible without moving the pointer). Tabulator's own Escape check compares e.key
   to 27, so never matches; its tooltips do close on a mousedown outside them, so that is
   sent instead. */
document.addEventListener("keydown", function (e) {
	if (e.key === "Escape" && document.querySelector(".tabulator-tooltip")) {
		document.body.dispatchEvent(new MouseEvent("mousedown", { bubbles: true }));
	}
});

/**
 * mczPaginationRowsCounter is a Tabulator `paginationCounter`: "Showing 1-50 of 173
 * rows", as Tabulator's own "rows" counter, but correct when the page size is All.
 * Tabulator's version computes the last row as first + pageSize - 1, and with All the
 * page size is true, which counts as 1, so 3 rows showed as "Showing 1-1 of 3 rows".
 *
 * @param pageSize rows per page, or true for All.
 * @param currentRow number of the first row on the page.
 * @param currentPage current page number (unused).
 * @param totalRows rows in the whole result.
 * @param totalPages number of pages (unused).
 * @return the counter text.
 */
function mczPaginationRowsCounter(pageSize, currentRow, currentPage, totalRows, totalPages) {
	if (!totalRows) {
		return "Showing 0 rows";
	}
	var lastRow = (pageSize === true) ? totalRows : Math.min(currentRow + pageSize - 1, totalRows);
	return "Showing " + currentRow + "-" + lastRow + " of " + totalRows + " rows";
}

/**
 * mczAddPageJumpControl adds a select listing every page in place of Tabulator's
 * numbered page buttons, which show only about 5 pages around the current one. The
 * jqxGrid pages have the same page select. The buttons are hidden in
 * tabulator_overrides.css, since Tabulator has no option to turn them off.
 *
 * @param table the Tabulator instance to add the control to.
 * @param selectId id (no leading #) to give the select; unique per grid on the page.
 */
function mczAddPageJumpControl(table, selectId) {
	var wrapper = document.createElement("span");
	wrapper.className = "tabulator-page-jump-wrapper";
	var label = document.createElement("label");
	label.setAttribute("for", selectId);
	/* Matches the "Page Size" label beside it, which is styled in tabulator_overrides.css. */
	label.className = "font-weight-lessbold";
	label.textContent = "Page:";
	var select = document.createElement("select");
	select.id = selectId;
	select.className = "tabulator-page-jump";
	select.addEventListener("change", function () {
		table.setPage(parseInt(select.value, 10));
	});
	wrapper.appendChild(label);
	wrapper.appendChild(select);

	/* Tried on every refresh: the pager is not reliably in the page by "tableBuilt".
	   Does nothing once inserted. */
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
	/* With remote paging this fires after every load: page, size or sort change, or a
	   new search. */
	table.on("pageLoaded", refresh);
}

/**
 * mczToNativePromise wraps a jQuery promise (such as $.ajax()) in a native Promise.
 * An ajaxRequestFunc must return one: Tabulator calls .finally() on the result, which
 * jQuery promises lack. With a bare $.ajax() the rows still show, but "tableBuilt"
 * never fires, so nothing attached to it runs.
 *
 * @param jqPromise a jqXHR or other jQuery promise.
 * @return a native Promise that settles the same way.
 */
function mczToNativePromise(jqPromise) {
	return Promise.resolve(jqPromise);
}

/**
 * mczFetchColumnOrder gets a page's saved column order from getGridColumnOrder in
 * /shared/component/functions.cfc, stored as the jqxGrid pages store it: a JSON array
 * of [field, position] pairs.
 *
 * @param pageFilePath the page path settings are stored under (e.g. cgi.script_name).
 * @param label settings label; the app-wide convention is "Default".
 * @return a Promise resolving to {field: position}, or {} if nothing is saved or the
 *   lookup fails.
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
 * mczApplyColumnOrder reorders column definitions, in place, to a saved order from
 * mczFetchColumnOrder. Columns with no saved position keep their original index.
 * Frozen columns stay ahead of the rest: Tabulator freezes a frozen column that
 * follows an unfrozen one to the right edge.
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
 * mczSaveTableColumnOrder saves a table's column order with saveColumnOrder() in
 * /shared/js/shared-scripts.js, as the jqxGrid pages do.
 *
 * @param table the Tabulator instance.
 * @param pageFilePath the page path settings are stored under (e.g. cgi.script_name).
 * @param label settings label; the app-wide convention is "Default".
 * @param feedbackDiv optional id (no leading #) of an element to show save feedback in.
 */
function mczSaveTableColumnOrder(table, pageFilePath, label, feedbackDiv) {
	var columnMap = new Map();
	var position = 0;
	/* Skip columns without a field, such as the row-selection checkboxes. */
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
 * mczExportColumns returns the columns an export includes, in their current order:
 * every column with a field and without `download: false`, and hidden columns only
 * when includeHidden is true.
 *
 * @param table the Tabulator instance whose columns describe the export.
 * @param includeHidden true to include hidden columns.
 * @return an array of ColumnComponents.
 */
function mczExportColumns(table, includeHidden) {
	return table.getColumns().filter(function (column) {
		var def = column.getDefinition();
		return def.field && def.download !== false && (includeHidden || column.isVisible());
	});
}

/**
 * mczExportValue returns one row's value for one column, passed through the column's
 * accessorDownload if it has one, with null and undefined as "".
 *
 * @param column the ColumnComponent.
 * @param row the row data object, keyed by field.
 * @return the value to export.
 */
function mczExportValue(column, row) {
	var def = column.getDefinition();
	var value = row[def.field];
	if (typeof def.accessorDownload === "function") {
		value = def.accessorDownload(value, row, "download", def.accessorDownloadParams || {}, column);
	}
	return (value === null || value === undefined) ? "" : value;
}

/**
 * mczBuildExportRows turns row data into a header row followed by one array per row,
 * using the table's columns for titles, order and values. Unlike table.download(),
 * which sees only the loaded page under remote paging, it can export rows fetched
 * separately from the server.
 *
 * @param table the Tabulator instance whose columns describe the export.
 * @param rows array of row data objects, keyed by field.
 * @param includeHidden true to include hidden columns.
 * @return array of arrays; element 0 is the header row.
 */
function mczBuildExportRows(table, rows, includeHidden) {
	var columns = mczExportColumns(table, includeHidden);
	var result = [columns.map(function (column) {
		var def = column.getDefinition();
		return def.titleDownload || def.title || def.field;
	})];
	rows.forEach(function (row) {
		result.push(columns.map(function (column) {
			return mczExportValue(column, row);
		}));
	});
	return result;
}

/**
 * mczBuildJson builds JSON text: an array of records keyed by field name rather than
 * column title, with the same columns and values as mczBuildCsv.
 *
 * @param table the Tabulator instance whose columns describe the export.
 * @param rows array of row data objects, keyed by field.
 * @param includeHidden true to include hidden columns.
 * @return JSON text.
 */
function mczBuildJson(table, rows, includeHidden) {
	var columns = mczExportColumns(table, includeHidden);
	return JSON.stringify(rows.map(function (row) {
		var record = {};
		columns.forEach(function (column) {
			record[column.getField()] = mczExportValue(column, row);
		});
		return record;
	}), null, 2);
}

/**
 * mczBuildHtmlDocument builds a standalone HTML page holding the rows as a table, with
 * every title and value escaped.
 *
 * @param table the Tabulator instance whose columns describe the export.
 * @param rows array of row data objects, keyed by field.
 * @param includeHidden true to include hidden columns.
 * @param title text for the document's title and heading.
 * @return HTML text.
 */
function mczBuildHtmlDocument(table, rows, includeHidden, title) {
	function escapeHtml(value) {
		return String(value)
			.replace(/&/g, "&amp;")
			.replace(/</g, "&lt;")
			.replace(/>/g, "&gt;")
			.replace(/"/g, "&quot;")
			.replace(/'/g, "&#39;");
	}
	var lines = mczBuildExportRows(table, rows, includeHidden);
	var header = lines.shift();
	var html = "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n" +
		"<title>" + escapeHtml(title) + "</title>\n" +
		"<style>body{font-family:sans-serif;font-size:14px;}" +
		"table{border-collapse:collapse;}" +
		"th,td{border:1px solid #bac5c6;padding:4px 6px;text-align:left;vertical-align:top;}" +
		"th{background:#deebec;}</style>\n</head>\n<body>\n" +
		"<h1>" + escapeHtml(title) + "</h1>\n<table>\n<thead>\n<tr>";
	header.forEach(function (cell) {
		html += "<th scope=\"col\">" + escapeHtml(cell) + "</th>";
	});
	html += "</tr>\n</thead>\n<tbody>\n";
	lines.forEach(function (line) {
		html += "<tr>" + line.map(function (cell) {
			return "<td>" + escapeHtml(cell) + "</td>";
		}).join("") + "</tr>\n";
	});
	return html + "</tbody>\n</table>\n</body>\n</html>\n";
}

/**
 * mczDownloadBlob starts a browser download of a Blob.
 *
 * @param blob the content to download.
 * @param filename download filename.
 */
function mczDownloadBlob(blob, filename) {
	var link = document.createElement("a");
	link.href = URL.createObjectURL(blob);
	link.download = filename;
	document.body.appendChild(link);
	link.click();
	document.body.removeChild(link);
	setTimeout(function () { URL.revokeObjectURL(link.href); }, 10000);
}

/**
 * mczBuildCsv builds CSV text from row data; see mczBuildExportRows.
 *
 * @param table the Tabulator instance whose columns describe the export.
 * @param rows array of row data objects, keyed by field.
 * @param includeHidden true to include hidden columns.
 * @return CSV text (no byte order mark; exportToCSV() in shared-scripts.js adds one).
 */
function mczBuildCsv(table, rows, includeHidden) {
	function escapeCsv(value) {
		var text = String(value);
		/* A leading ' keeps spreadsheets from running a value as a formula (CSV injection). */
		if (/^[=+\-@\t\r]/.test(text)) {
			text = "'" + text;
		}
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
 * mczLoadScriptOnce loads a script the first time it is needed, at most once per src,
 * so a large library such as ExcelJS is not fetched on every page load.
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
 * mczExportRowsToExcel downloads rows as a one-sheet .xlsx file using ExcelJS. Values
 * are written as text so identifiers such as catalog numbers keep leading zeros.
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
		mczDownloadBlob(new Blob([buffer], { type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }), filename);
	});
}

/**
 * mczExportFilename builds a download filename in the pattern the jqxGrid pages use
 * (see gridLoaded() in Taxa.cfm): {searchType}_results_{timestamp}.{extension}.
 *
 * @param searchType e.g. "project".
 * @param extension "csv", "xlsx", "json" or "html".
 * @return the filename.
 */
function mczExportFilename(searchType, extension) {
	return searchType + "_results_" + new Date().toISOString().replace(/[^0-9TZ]/g, "_") + "." + extension;
}

/**
 * mczAttachSelectionStore keeps a grid's selected rows in a Map, so the selection
 * survives paging, sorting and filtering; with remote paging Tabulator drops it on every
 * page load. The Map holds each row's data, so an export can include rows from other
 * pages. In memory only. The table's `index` option must be idField.
 *
 * @param table the Tabulator instance.
 * @param selectionMap a Map owned and read by the caller, keyed by the idField value.
 * @param idField row field holding a stable unique id (the table's index field).
 * @param persistAcrossPages true to keep the selection across pages; false to keep only
 *   the loaded page. Use false for single-row selection, which Tabulator enforces only
 *   within the loaded page.
 * @param onChange optional; called with the Map after every change.
 */
function mczAttachSelectionStore(table, selectionMap, idField, persistAcrossPages, onChange) {
	/* Re-ticking rows fires rowSelected per row; report once instead. */
	var reapplying = false;

	function changed() {
		if (!reapplying && onChange) {
			onChange(selectionMap);
		}
	}

	table.on("rowSelected", function (row) {
		var data = row.getData();
		selectionMap.set(String(data[idField]), data);
		changed();
	});
	table.on("rowDeselected", function (row) {
		selectionMap.delete(String(row.getData()[idField]));
		changed();
	});
	/* Fires after every load, when the checkboxes need re-ticking. */
	table.on("dataProcessed", function () {
		if (!persistAcrossPages) {
			/* Tabulator has already dropped the previous page's selection. */
			selectionMap.clear();
			changed();
			return;
		}
		if (selectionMap.size) {
			reapplying = true;
			table.getRows().forEach(function (row) {
				if (selectionMap.has(String(row.getData()[idField])) && !row.isSelected()) {
					row.select();
				}
			});
			reapplying = false;
		}
		changed();
	});
}

/**
 * mczClearSelectionStore empties a selection store and deselects the loaded rows. Call
 * it on a new search, so an export cannot include rows from earlier results.
 *
 * @param table the Tabulator instance, or null if it no longer exists.
 * @param selectionMap the Map passed to mczAttachSelectionStore.
 * @param onChange optional; called with the emptied Map.
 */
function mczClearSelectionStore(table, selectionMap, onChange) {
	selectionMap.clear();
	if (table) {
		table.deselectRow();
	}
	if (onChange) {
		onChange(selectionMap);
	}
}

/**
 * mczRefreshSelectionCount shows how many rows are selected, including rows on other
 * pages.
 *
 * @param selectionMap the Map passed to mczAttachSelectionStore.
 * @param elementId id (no leading #) of the element to write the count into.
 */
function mczRefreshSelectionCount(selectionMap, elementId) {
	var count = selectionMap.size;
	jQuery("#" + elementId).text(count ? count + (count === 1 ? " row selected" : " rows selected") : "");
}

/**
 * mczIsDataColumn reports whether a column holds row data rather than a control.
 * Control columns have fields starting "_mcz"; a custom column property would make
 * Tabulator log a warning.
 *
 * @param definition a Tabulator column definition, as column.getDefinition() returns.
 * @return true if the column holds row data.
 */
function mczIsDataColumn(definition) {
	return !!(definition && definition.field && definition.title
		&& definition.field.indexOf("_mcz") !== 0);
}

/**
 * mczHideableColumns returns the columns a user can show or hide: the data columns,
 * not control columns such as Details and Edit.
 *
 * @param table the Tabulator instance.
 * @return an array of ColumnComponents.
 */
function mczHideableColumns(table) {
	return table.getColumns().filter(function (column) {
		return mczIsDataColumn(column.getDefinition());
	});
}

/**
 * mczShowAllColumns makes every hidden column visible again. A column hidden from its
 * header menu takes that menu with it, so this is the way back.
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
 * mczRefreshShowHiddenColumnsButton hides the "show hidden columns" button when no
 * column is hidden, and otherwise shows it with the count in its label.
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
 * mczShowRowDetailsDialog opens a dialog listing every column's title and value for
 * one row, including hidden columns, like createRowDetailsDialog() on the jqxGrid
 * pages. Values are inserted as text.
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
 * mczDetailsButtonColumn returns a column with a button that opens
 * mczShowRowDetailsDialog for its row; not sortable or exported.
 *
 * @param dialogTitle optional title for the details dialog.
 * @param nameField optional field naming the row (e.g. "project_name"), so each button
 *   is read as "Details for <name>" rather than the same name on every row.
 * @return a column definition object.
 */
function mczDetailsButtonColumn(dialogTitle, nameField) {
	return {
		title: "Details",
		field: "_mczDetails",
		width: 80,
		headerSort: false,
		download: false,
		hozAlign: "center",
		formatter: function (cell) {
			var button = document.createElement("button");
			button.type = "button";
			/* The developer's guide style for buttons in a results grid. */
			button.className = "btn btn-xs btn-outline-primary py-0";
			var name = nameField ? cell.getRow().getData()[nameField] : "";
			button.setAttribute("aria-label", name ? "Details for " + name : "Show all values for this row");
			/* Not fa-eye, which the hide-search-form toggle uses. */
			button.innerHTML = '<i class="fas fa-list-ul" aria-hidden="true"></i>';
			return button;
		},
		cellClick: function (e, cell) {
			mczShowRowDetailsDialog(cell.getTable(), cell.getRow(), dialogTitle);
		}
	};
}

/**
 * mczColumnTitle returns a column's title for a field, falling back to the field name.
 *
 * @param table the Tabulator instance.
 * @param field a column field name.
 * @return the column's title, or the field name.
 */
function mczColumnTitle(table, field) {
	var title = field;
	table.getColumns().forEach(function (column) {
		if (column.getField() === field) {
			title = column.getDefinition().title || field;
		}
	});
	return title;
}

/**
 * mczGroupHeaderElement builds a group header reading "Column: value (n)". It returns
 * elements, not a string, because Tabulator puts a string into innerHTML unescaped.
 *
 * @param table the Tabulator instance.
 * @param group the GroupComponent Tabulator passes to groupHeader.
 * @param value the value the group collects.
 * @param count rows in the group.
 * @return a DocumentFragment holding the header content.
 */
function mczGroupHeaderElement(table, group, value, count) {
	/* A real button, so a group can be opened and closed from the keyboard: Tabulator's
	   own toggle is the arrow, which only takes a click. Tabulator rebuilds this header
	   each time the group opens or closes, so aria-expanded is read fresh, and focus is
	   put back on the new button after a toggle. */
	var toggle = document.createElement("button");
	toggle.type = "button";
	toggle.className = "mcz-group-toggle btn btn-link p-0 text-left text-reset text-decoration-none";
	toggle.setAttribute("aria-expanded", String(group.isVisible()));
	toggle.addEventListener("click", function (e) {
		e.stopPropagation();
		var key = group.getKey();
		group.toggle();
		/* Toggling replaces Tabulator's group objects, so find this group again by its
		   key, after the redraw, and focus its new button. */
		setTimeout(function () {
			table.getGroups().some(function (current) {
				if (current.getKey() !== key) {
					return false;
				}
				var element = current.getElement();
				var rebuilt = element && element.querySelector ? element.querySelector(".mcz-group-toggle") : null;
				if (rebuilt) {
					rebuilt.focus();
				}
				return true;
			});
		}, 0);
	});
	/* Screen readers only: "Grouped by Start Date: 2018-08-01 (3)", so the button says
	   what it is; the visible header stays "Start Date: 2018-08-01 (3)". */
	var prefix = document.createElement("span");
	prefix.className = "sr-only";
	prefix.textContent = "Grouped by ";
	var label = document.createElement("span");
	label.className = "font-weight-lessbold";
	label.textContent = mczColumnTitle(table, group.getField()) + ": ";
	var shown = document.createElement("span");
	shown.textContent = (value === null || value === undefined || value === "")
		? "(no value)"
		: String(value);
	var tally = document.createElement("span");
	tally.className = "text-muted ml-1";
	tally.textContent = "(" + count + ")";
	toggle.appendChild(prefix);
	toggle.appendChild(label);
	toggle.appendChild(shown);
	toggle.appendChild(tally);
	return toggle;
}

/**
 * mczPopulateGroupByPicker fills a <select> with the table's data columns, plus a
 * no-grouping choice.
 *
 * @param table the Tabulator instance.
 * @param selectId id (no leading #) of the select element.
 * @param currentField field currently grouped by, or a falsy value for none.
 */
function mczPopulateGroupByPicker(table, selectId, currentField) {
	var select = document.getElementById(selectId);
	if (!select) {
		return;
	}
	select.innerHTML = "";
	var none = document.createElement("option");
	none.value = "";
	none.textContent = "(none)";
	select.appendChild(none);
	mczHideableColumns(table).forEach(function (column) {
		var definition = column.getDefinition();
		var option = document.createElement("option");
		option.value = definition.field;
		option.textContent = definition.title;
		select.appendChild(option);
	});
	select.value = currentField || "";
}

/**
 * mczRenderGroupChip shows a removable chip naming the active grouping, as jqxGrid's
 * groups bar did, or empties its container when nothing is grouped.
 *
 * @param containerId id (no leading #) of the element holding the chip.
 * @param label column title to name in the chip, or a falsy value to clear it.
 * @param onRemove click handler for the chip's remove button.
 */
function mczRenderGroupChip(containerId, label, onRemove) {
	var container = document.getElementById(containerId);
	if (!container) {
		return;
	}
	container.innerHTML = "";
	if (!label) {
		container.style.display = "none";
		return;
	}
	container.style.display = "";
	var chip = document.createElement("span");
	chip.className = "mcz-group-chip";
	var text = document.createElement("span");
	text.textContent = label;
	var remove = document.createElement("button");
	remove.type = "button";
	remove.className = "mcz-group-chip-remove";
	remove.setAttribute("aria-label", "Stop grouping by " + label);
	remove.innerHTML = '<i class="fas fa-times" aria-hidden="true"></i>';
	remove.addEventListener("click", onRemove);
	chip.appendChild(text);
	chip.appendChild(remove);
	container.appendChild(chip);
}

/**
 * mczStandardHeaderMenu returns a headerMenu offering sort ascending, sort descending,
 * move left, move right, hide column and "Select Columns...". It is a function so the
 * items are built each time the menu opens.
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
		/* Move left / Move right: the keyboard alternative to dragging a header (WCAG
		   2.1.1). Only among visible, unfrozen data columns -- frozen columns must stay
		   together at the left edge, and control columns (Details, Edit) stay put. Moving
		   fires columnMoved, as a drag does, so pages
		   that save column order save this too. */
		if (!column.getDefinition().frozen) {
			var movable = column.getTable().getColumns().filter(function (other) {
				return other.isVisible() && mczIsDataColumn(other.getDefinition()) && !other.getDefinition().frozen;
			});
			var position = movable.map(function (other) { return other.getField(); }).indexOf(column.getField());
			var previous = position > 0 ? movable[position - 1] : null;
			var next = position >= 0 && position < movable.length - 1 ? movable[position + 1] : null;
			items.push({
				label: '<i class="fas fa-arrow-left mr-2" aria-hidden="true"></i>Move left',
				disabled: !previous,
				action: function (e, col) { col.move(previous, false); }
			});
			items.push({
				label: '<i class="fas fa-arrow-right mr-2" aria-hidden="true"></i>Move right',
				disabled: !next,
				action: function (e, col) { col.move(next, true); }
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
 * mczHeaderFilterParams turns Tabulator's remote filter list ([{field, type, value}])
 * into flat {prefix}{field} parameters that a cfargument can read, keeping only fields
 * in allowedFields.
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
 * mczHeaderFilterLabel returns headerFilterParams giving a header filter input an
 * accessible name ("Filter {title}") and the data-entry-input class.
 *
 * @param columnTitle the column's title as shown in its header.
 * @return an object usable as a column's headerFilterParams.
 */
function mczHeaderFilterLabel(columnTitle) {
	return {
		elementAttributes: {
			"aria-label": "Filter " + columnTitle,
			"class": "data-entry-input"
		}
	};
}

/**
 * mczUseTableRoles changes a read-only grid's roles from grid/gridcell to table/cell, so
 * screen readers treat it as a data table. With role="grid", NVDA could not find or
 * navigate the table. Call on "tableBuilt".
 *
 * Tabulator creates new cells whenever it renders rows, so a MutationObserver relabels
 * them. A table rebuilt in the same element reuses the observer.
 *
 * @param table the Tabulator instance.
 */
function mczUseTableRoles(table) {
	var element = table.element;
	function relabel(node) {
		if (node.nodeType !== 1) {
			return;
		}
		var role = node.getAttribute("role");
		if (role === "grid") {
			node.setAttribute("role", "table");
		} else if (role === "gridcell") {
			node.setAttribute("role", "cell");
		}
		node.querySelectorAll('[role="grid"], [role="gridcell"]').forEach(relabel);
	}
	relabel(element);
	if (element.mczTableRoleObserver) {
		return;
	}
	element.mczTableRoleObserver = new MutationObserver(function (mutations) {
		mutations.forEach(function (mutation) {
			if (mutation.type === "attributes") {
				relabel(mutation.target);
			} else {
				mutation.addedNodes.forEach(relabel);
			}
		});
	});
	element.mczTableRoleObserver.observe(element, {
		childList: true,
		subtree: true,
		attributes: true,
		attributeFilter: ["role"]
	});
}

/**
 * mczKeepControlsOutOfTable keeps a grid relabelled by mczUseTableRoles a valid table,
 * which may hold only rows and row groups: it moves the pagination footer to a wrapper
 * just after the grid, and takes the scrollable body (.tabulator-tableholder) out of the
 * Tab order, as every row's own controls already reach and scroll it.  It also drops the
 * page size select's title, which repeats its aria-label.  Call on "tableBuilt", after
 * mczUseTableRoles.
 *
 * @param table the Tabulator instance.
 */
function mczKeepControlsOutOfTable(table) {
	var element = table.element;
	var holder = element.querySelector(".tabulator-tableholder");
	if (holder) {
		holder.removeAttribute("tabindex");
	}
	var footer = element.querySelector(":scope > .tabulator-footer");
	if (!footer) {
		return;
	}
	/* The wrapper carries the tabulator class so the theme's footer styles still apply.
	   A table rebuilt in the same element reuses it, replacing the old footer. */
	var wrapper = element.mczFooterWrapper;
	if (!wrapper || !document.body.contains(wrapper)) {
		wrapper = document.createElement("div");
		wrapper.className = "tabulator mcz-tabulator-footer-wrapper";
		element.parentNode.insertBefore(wrapper, element.nextSibling);
		element.mczFooterWrapper = wrapper;
	}
	wrapper.replaceChildren(footer);
	footer.querySelectorAll("select.tabulator-page-size[aria-label][title]").forEach(function (select) {
		select.removeAttribute("title");
	});
}

/**
 * mczMakeHeaderMenuButtonsAccessible makes each column's ⋮ menu button, a plain span
 * in Tabulator, keyboard-operable and gives it an accessible name. Call on
 * "tableBuilt" and after anything that rebuilds a header (e.g. updateDefinition).
 * mczSetUpOpenMenu handles the menu itself.
 *
 * @param table the Tabulator instance.
 */
function mczMakeHeaderMenuButtonsAccessible(table) {
	/* Once per table: this function runs again whenever headers are rebuilt. */
	if (!table.mczMenuEventsBound) {
		table.mczMenuEventsBound = true;
		table.on("menuOpened", function () {
			if (table.mczMenuOpener && document.body.contains(table.mczMenuOpener)) {
				mczSetUpOpenMenu(table.mczMenuOpener);
			}
		});
		table.on("menuClosed", function () {
			var opener = table.mczMenuOpener;
			table.mczMenuOpener = null;
			if (!opener) {
				return;
			}
			/* Unless the action moved focus (e.g. opened a dialog), return it to the ⋮,
			   or to the grid if the action hid that column. */
			setTimeout(function () {
				var active = document.activeElement;
				if (active && active !== document.body && document.body.contains(active)) {
					return;
				}
				/* A hidden column's ⋮ is still in the page but cannot take focus. */
				if (document.body.contains(opener) && opener.getClientRects().length) {
					opener.focus();
				} else {
					/* tabindex -1: focusable from script only, not a Tab stop. */
					table.element.setAttribute("tabindex", "-1");
					table.element.focus();
				}
			}, 0);
		});
	}
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
		/* Remember which ⋮ opened the menu. Capture phase, because Tabulator stops the
		   click at the ⋮. */
		column.getElement().addEventListener("click", function (e) {
			if (button.contains(e.target)) {
				table.mczMenuOpener = button;
			}
		}, true);
	});
}

/**
 * mczSetUpOpenMenu fixes the menu a ⋮ has just opened.
 *
 * Position: Tabulator places the menu at the click's coordinates, which a keyboard or
 * screen-reader click lacks, so it is moved to just below the ⋮.
 *
 * Keyboard (WAI-ARIA menu pattern): Tabulator's menu items cannot take focus, and its
 * Escape check never matches. Focus starts on the first item; Up/Down (wrapping) and
 * Home/End move; Enter or Space chooses; Escape or Tab closes.
 *
 * @param button the ⋮ that opened the menu.
 */
function mczSetUpOpenMenu(button) {
	var menus = document.querySelectorAll(".tabulator-menu");
	var menu = menus[menus.length - 1];
	if (!menu || menu.getAttribute("role")) {
		return;
	}
	var parent = menu.offsetParent || document.body;
	var buttonRect = button.getBoundingClientRect();
	var parentRect = parent.getBoundingClientRect();
	var scrollTop = parent === document.body ? 0 : parent.scrollTop;
	var scrollLeft = parent === document.body ? 0 : parent.scrollLeft;
	menu.style.top = (buttonRect.bottom - parentRect.top + scrollTop) + "px";
	menu.style.left = (buttonRect.left - parentRect.left + scrollLeft) + "px";

	menu.setAttribute("role", "menu");
	menu.querySelectorAll(".tabulator-menu-separator").forEach(function (separator) {
		separator.setAttribute("role", "separator");
	});
	var items = Array.prototype.slice.call(menu.querySelectorAll(".tabulator-menu-item"));
	items.forEach(function (item) {
		item.setAttribute("role", "menuitem");
		item.setAttribute("tabindex", "-1");
		if (item.classList.contains("tabulator-menu-item-disabled")) {
			item.setAttribute("aria-disabled", "true");
		}
	});
	var enabled = items.filter(function (item) {
		return !item.classList.contains("tabulator-menu-item-disabled");
	});
	if (!enabled.length) {
		return;
	}
	menu.addEventListener("keydown", function (e) {
		var index = enabled.indexOf(document.activeElement);
		var next = null;
		switch (e.key) {
			case "ArrowDown": next = enabled[(index + 1) % enabled.length]; break;
			case "ArrowUp": next = enabled[(index - 1 + enabled.length) % enabled.length]; break;
			case "Home": next = enabled[0]; break;
			case "End": next = enabled[enabled.length - 1]; break;
			case "Enter":
			case " ":
				e.preventDefault();
				e.stopPropagation();
				if (index >= 0) {
					enabled[index].click();
				}
				return;
			case "Escape":
			case "Tab":
				e.preventDefault();
				e.stopPropagation();
				/* A click on the menu closes it at once. */
				menu.click();
				return;
			default:
				return;
		}
		e.preventDefault();
		e.stopPropagation();
		next.focus();
	});
	enabled[0].focus();
}
