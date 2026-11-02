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
