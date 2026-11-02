/*
/Reports/js/reports.js

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

/** Show or hide the reports in a report list by whether their names contain the filter text and,
 * for reports not for the user's collections, whether those have been asked for.
 * The checked report always stays shown, so the report that will print is never hidden.
 *
 * @param inputId the id of the text input holding the filter text, without a leading # selector.
 * @param showAllId the id of the checkbox that includes reports not shown by default.
 * @param listId the id of the element containing the .report-list-item entries, each with
 *  data-report-name (lower case) and data-default-shown attributes.
 * @param countId the id of the output element that reports how many reports are shown.
 */
function filterReportList(inputId, showAllId, listId, countId) {
	var term = $("#" + inputId).val().trim().toLowerCase();
	var showAll = $("#" + showAllId).prop("checked");
	var items = $("#" + listId).children(".report-list-item");
	var shown = 0;
	var available = 0;
	items.each(function () {
		var item = $(this);
		var included = showAll || item.attr("data-default-shown") == "true";
		if (included) { available = available + 1; }
		// attr, not data(): data() would turn a name that looks like a number into one.
		var matches = term.length == 0 || item.attr("data-report-name").indexOf(term) >= 0;
		var visible = (included && matches) || item.find("input[type=radio]").prop("checked");
		item.toggleClass("d-none", !visible);
		if (visible) { shown = shown + 1; }
	});
	$("#" + countId).text(shown + " of " + available + " reports shown");
}

/** Show the details of the report picked from a report list: its name, its description, the
 * preservation type and part name limits if the report supports them, and enable printing.
 *
 * @param radio the radio input for the picked report, carrying data-report-name-text,
 *  data-preserve-limit and data-part-name-limit attributes.
 * @param targets an object giving the ids, without leading # selectors, of the elements to
 *  update: heading, description, printButton, preserveLimitSection, partNameLimitSection.
 */
function selectReport(radio, targets) {
	var reportName = $(radio).attr("data-report-name-text");
	$("#" + targets.heading).text(reportName);
	$("#" + targets.printButton).prop("disabled", false).removeClass("disabled");
	$("#" + targets.preserveLimitSection).toggleClass("d-none", $(radio).attr("data-preserve-limit") != "true");
	$("#" + targets.partNameLimitSection).toggleClass("d-none", $(radio).attr("data-part-name-limit") != "true");
	$("#" + targets.description).html("<img src='/shared/images/indicator.gif' alt=''> Loading description...");
	$.ajax({
		url: "/component/functions.cfc",
		data: {
			method: "getReportDescription",
			report_id: reportName,
			returnformat: "json",
			queryformat: "column"
		},
		dataType: "json",
		success: function (result) {
			// a slower reply for an earlier pick must not replace the current report's description
			if (!$(radio).prop("checked")) { return; }
			var description = "";
			if (result && result.DATA && result.DATA.DESCRIPTION && result.DATA.DESCRIPTION.length > 0) {
				description = result.DATA.DESCRIPTION[0];
			}
			if (description == null || description.length == 0) {
				$("#" + targets.description).text("No Description");
			} else {
				// descriptions are written as HTML by report managers, as /Reports/listReports.cfm shows them
				$("#" + targets.description).html(description);
			}
		},
		error: function (jqXHR, textStatus, error) {
			$("#" + targets.description).text("Description could not be loaded.");
			handleFail(jqXHR, textStatus, error, "loading the report description");
		}
	});
}

/** Show how many of the specimens in a report's specimen table are included.
 *
 * @param tableId the id of the table whose rows carry an include checkbox, without a leading # selector.
 * @param countId the id of the output element for the count.
 */
function updateIncludedCount(tableId, countId) {
	var boxes = $("#" + tableId + " tbody input[type=checkbox]");
	$("#" + countId).text(boxes.filter(":checked").length + " of " + boxes.length + " specimens included");
}

/** Include or leave out every specimen in a report's specimen table.
 *
 * @param tableId the id of the specimen table, without a leading # selector.
 * @param included true to include every specimen, false to leave every one out.
 * @param countId the id of the output element for the count.
 */
function setAllIncluded(tableId, included, countId) {
	$("#" + tableId + " tbody input[type=checkbox]").prop("checked", included);
	updateIncludedCount(tableId, countId);
}

/** Include or leave out the specimens in a report's specimen table that share the value picked
 * from a select, leaving the others as they are.
 *
 * @param tableId the id of the specimen table, without a leading # selector.
 * @param attributeName the row attribute holding the value, e.g. data-scientific-name.
 * @param selectId the id of the select holding the value to match.
 * @param included true to include the matching specimens, false to leave them out.
 * @param countId the id of the output element for the count.
 */
function setIncludedByValue(tableId, attributeName, selectId, included, countId) {
	var value = $("#" + selectId).val();
	// compared as text rather than built into a selector, as names and places can hold quotes
	$("#" + tableId + " tbody tr").filter(function () {
		return $(this).attr(attributeName) === value;
	}).find("input[type=checkbox]").prop("checked", included);
	updateIncludedCount(tableId, countId);
}

/** Sort the rows of a report table by a row attribute, ascending on the first press of a column's
 * sort button and reversing on each further press, marking the column with aria-sort.
 *
 * @param tableId the id of the table, without a leading # selector.
 * @param button the sort button in the column's header cell.
 * @param attributeName the row attribute to sort by.
 */
function sortReportTable(tableId, button, attributeName) {
	var header = $(button).closest("th");
	var ascending = header.attr("aria-sort") !== "ascending";
	$("#" + tableId + " thead th").removeAttr("aria-sort");
	header.attr("aria-sort", ascending ? "ascending" : "descending");
	var body = $("#" + tableId + " tbody");
	var rows = body.children("tr").get();
	rows.sort(function (a, b) {
		var first = ($(a).attr(attributeName) || "").toLowerCase();
		var second = ($(b).attr(attributeName) || "").toLowerCase();
		var order = first < second ? -1 : (first > second ? 1 : 0);
		return ascending ? order : -order;
	});
	body.append(rows);
}

/** Add a row for an annotation to a report form: the note's text, the catalog numbers it applies to,
 * and a button to remove it.  Rows are numbered in the order added, and the numbers are not reused,
 * so the form's annotationText{n} and annotationScope{n} fields stay paired.
 *
 * @param listId the id of the element holding the annotation rows, with a data-next-number attribute.
 * @param text optional text for the annotation.
 * @param scope optional catalog numbers for the annotation.
 */
function addAnnotation(listId, text, scope) {
	var list = $("#" + listId);
	var number = parseInt(list.attr("data-next-number"), 10) || 1;
	list.attr("data-next-number", number + 1);
	var textId = "annotationText" + number;
	var scopeId = "annotationScope" + number;
	var row = $("<div>").addClass("form-row align-items-end mb-1");
	var textColumn = $("<div>").addClass("col-12 col-md-5");
	textColumn.append($("<label>").addClass("data-entry-label").attr("for", textId).text("Annotation " + number));
	textColumn.append($("<input>").attr({ type: "text", id: textId, name: textId }).addClass("data-entry-input").val(text || ""));
	var scopeColumn = $("<div>").addClass("col-12 col-md-5");
	scopeColumn.append($("<label>").addClass("data-entry-label").attr("for", scopeId).text("Catalog numbers for annotation " + number + " (blank for all)"));
	scopeColumn.append($("<input>").attr({ type: "text", id: scopeId, name: scopeId }).addClass("data-entry-input").val(scope || ""));
	var removeColumn = $("<div>").addClass("col-12 col-md-2");
	var removeButton = $("<button>").attr("type", "button").addClass("btn btn-xs btn-warning").text("Remove annotation " + number);
	removeButton.on("click", function () {
		row.remove();
		list.closest("section").find("button").last().trigger("focus");
	});
	removeColumn.append(removeButton);
	row.append(textColumn, scopeColumn, removeColumn);
	list.append(row);
	if (typeof text === "undefined") {
		$("#" + textId).trigger("focus");
	}
}
