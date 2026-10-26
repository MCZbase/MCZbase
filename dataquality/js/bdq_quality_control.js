/*
bdq_quality_control.js

Copyright 2022-2026 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Loading and display of the results of TDWG BDQ tests run on MCZbase records
by the backing methods in /dataquality/component/functions.cfc.
*/

var BDQ_STANDARD_URL = "https://bdq.tdwg.org/draft/";
// each test in the list of BDQ tests has an anchor of bdqtest_ followed by its guid
var BDQ_TEST_LIST_URL = "https://bdq.tdwg.org/draft/docs/list/bdqtest/#bdqtest_";
var BDQ_INTERNAL_PREREQUISITES_NOT_MET = "INTERNAL_PREREQUISITES_NOT_MET";
// rule at the left of the columns of each phase, setting pre-amendment results apart from post-amendment
var BDQ_PHASE_START_CLASS = "border-left border-dark";

/**
 * function bdqEscapeHtml encodes a value for placement in html element content, as test labels,
 * values, and comments from the QC libraries can contain text from the record under test.
 *
 * @param value the value to encode, null and undefined become an empty string.
 * @return the value with html special characters replaced by character references.
 */
function bdqEscapeHtml(value) {
	if (value === null || value === undefined) { return ""; }
	return String(value)
		.replace(/&/g, "&amp;")
		.replace(/</g, "&lt;")
		.replace(/>/g, "&gt;")
		.replace(/"/g, "&quot;")
		.replace(/'/g, "&#39;");
}

/**
 * function loadQC runs one of the QC reports on a record and displays the results.
 *
 * @param method the backing method in /dataquality/component/functions.cfc to invoke.
 * @param target the kind of record identified by target_id, e.g. FLAT, LOCALITY, TAXONOMY, COLLEVENT.
 * @param target_id the primary key of the record to test.
 * @param category a label for the tests, e.g. Event, Taxon Name, Geospatial.
 * @param targetDivId the id of an element in the DOM of which to replace the content with the results,
 *  without a leading # selector.
 * @param focusOnLoad if true, move focus to the heading of the results when they are displayed, pass
 *  true for only one report when several are run together.
 * @see displayQCResult
 */
function loadQC(method, target, target_id, category, targetDivId, focusOnLoad) {
	$("#" + targetDivId).attr("aria-busy", "true");
	$("#" + targetDivId).html("<div class='my-2 text-center'><img src='/shared/images/indicator.gif' alt=''> Running " + bdqEscapeHtml(category) + " tests...</div>");
	$.ajax({
		url: "/dataquality/component/functions.cfc",
		type: "get",
		data: {
			method: method,
			returnformat: "json",
			target: target,
			target_id: target_id
		},
		success: function (datareturn) {
			var data = JSON.parse(datareturn);
			if (data.STATUS == "success") {
				displayQCResult(data, category, targetDivId, focusOnLoad);
			} else {
				$("#" + targetDivId).html("<h2>Error:</h2><div>" + bdqEscapeHtml(data.ERROR) + "</div>");
			}
			$("#" + targetDivId).attr("aria-busy", "false");
		},
		error: function (jqXHR, textStatus, error) {
			$("#" + targetDivId).html("Error running " + bdqEscapeHtml(category) + " tests.");
			$("#" + targetDivId).attr("aria-busy", "false");
			handleFail(jqXHR, textStatus, error, "running " + category + " quality control tests");
		}
	});
}

/**
 * function loadEventQC runs the BDQ event (TIME) tests on a cataloged item or a collecting event.
 *
 * @param collection_object_id of the collection object to run the tests on, selects target FLAT if specified.
 * @param collecting_event_id of the collecting event to run the tests on, selects target COLLEVENT if
 *  provided and collection_object_id is empty.
 * @param targetDivId the id of an element in the DOM of which to replace the content with the results.
 * @param focusOnLoad optional, if true move focus to the results when they are displayed.
 */
function loadEventQC(collection_object_id, collecting_event_id, targetDivId, focusOnLoad) {
	if (collection_object_id && String(collection_object_id).length > 0) {
		loadQC("getEventQCReportFlat", "FLAT", String(collection_object_id), "Event", targetDivId, focusOnLoad);
	} else if (collecting_event_id && String(collecting_event_id).length > 0) {
		loadQC("getEventQCReportFlat", "COLLEVENT", String(collecting_event_id), "Event", targetDivId, focusOnLoad);
	} else {
		$("#" + targetDivId).html("Error: Neither a collection_object_id nor a collecting_event_id was provided." );
	}
}

/**
 * function loadNameQC runs the BDQ taxon name (NAME) tests on a cataloged item or a taxonomy record.
 *
 * @param collection_object_id of the collection object to run the tests on, selects target FLAT if specified.
 * @param taxon_name_id of the taxonomy record to run the tests on, used if collection_object_id is empty.
 * @param targetDivId the id of an element in the DOM of which to replace the content with the results.
 * @param focusOnLoad optional, if true move focus to the results when they are displayed.
 */
function loadNameQC(collection_object_id, taxon_name_id, targetDivId, focusOnLoad) {
	if (collection_object_id && String(collection_object_id).length > 0) {
		loadQC("getNameQCReport", "FLAT", String(collection_object_id), "Taxon Name", targetDivId, focusOnLoad);
	} else if (taxon_name_id && String(taxon_name_id).length > 0) {
		loadQC("getNameQCReport", "TAXONOMY", String(taxon_name_id), "Taxon Name", targetDivId, focusOnLoad);
	} else {
		$("#" + targetDivId).html("Error: Neither a collection_object_id nor a taxon_name_id was provided." );
	}
}

/**
 * function loadSpaceQC runs the BDQ georeference (SPACE) tests on a cataloged item or a locality.
 *
 * @param collection_object_id of the collection object to run the tests on, selects target FLAT if specified.
 * @param locality_id of the locality to run the tests on, selects target LOCALITY if provided and
 *  collection_object_id is empty.
 * @param targetDivId the id of an element in the DOM of which to replace the content with the results,
 *  without a leading # selector.
 * @param focusOnLoad optional, if true move focus to the results when they are displayed.
 */
function loadSpaceQC(collection_object_id, locality_id, targetDivId, focusOnLoad) {
	if (collection_object_id && String(collection_object_id).length > 0) {
		loadQC("getSpaceQCReport", "FLAT", String(collection_object_id), "Geospatial", targetDivId, focusOnLoad);
	} else if (locality_id && String(locality_id).length > 0) {
		loadQC("getSpaceQCReport", "LOCALITY", String(locality_id), "Geospatial", targetDivId, focusOnLoad);
	} else {
		$("#" + targetDivId).html("Error: Neither a collection_object_id nor a locality_id was provided." );
	}
}

/**
 * function bdqResultHtml formats a single test response as html, showing Response.result when the test
 * ran (Response.status RUN_HAS_RESULT) and Response.status otherwise, in BDQ terms, with emphasis and
 * color that repeat but do not replace the words.
 *
 * @param response a test response with STATUS and VALUE, or undefined if the test was not run.
 * @return html for the response.
 */
function bdqResultHtml(response) {
	if (!response || !response.STATUS) { return "<span class='text-muted'>not run</span>"; }
	var text = response.STATUS;
	var cssClass = "text-muted";
	if (response.STATUS == "RUN_HAS_RESULT") {
		text = response.VALUE;
		cssClass = "";
		if (response.VALUE == "COMPLIANT" || response.VALUE == "NOT_ISSUE") { cssClass = "font-weight-bold text-success"; }
		if (response.VALUE == "NOT_COMPLIANT" || response.VALUE == "IS_ISSUE") { cssClass = "font-weight-bold text-danger"; }
		if (response.VALUE == "POTENTIAL_ISSUE") { cssClass = "font-weight-bold"; }
	} else if (response.STATUS == "EXTERNAL_PREREQUISITES_NOT_MET" || response.STATUS == "AMENDED" || response.STATUS == "FILLED_IN") {
		cssClass = "font-weight-bold";
	}
	return "<span class='" + cssClass + "'>" + bdqEscapeHtml(text) + "</span>";
}

/**
 * function bdqTestHeaderHtml formats the row header naming a test, linked to its definition in the
 * draft BDQ standard.
 *
 * @param guid the guid of the test.
 * @param response the response of the test, its LABEL is the description used by the backing method,
 *  which may name the source authority consulted.
 * @param tests the TESTS struct from the backing method, test metadata keyed by guid.
 * @return html for a th element.
 */
function bdqTestHeaderHtml(guid, response, tests) {
	var test = tests[guid] || {};
	var name = test.NAME || guid;
	var description = test.DESCRIPTION || response.LABEL;
	// the backing methods replace a generic source authority in the description with the one consulted
	if (response.LABEL && /sourceAuthority/.test(description)) { description = response.LABEL; }
	return "<th scope='row' class='font-weight-normal'><a href='" + BDQ_TEST_LIST_URL + encodeURIComponent(guid) + "' target='_blank' rel='noopener'>" + bdqEscapeHtml(name) + "</a>"
		+ "<div class='small'>" + bdqEscapeHtml(description) + "</div></th>";
}

/**
 * function bdqSortOrder orders tests so that results needing attention come first.
 *
 * @param response a test response with STATUS and VALUE.
 * @return a number, lower sorts first.
 */
function bdqSortOrder(response) {
	if (response.STATUS == "RUN_HAS_RESULT") {
		if (response.VALUE == "NOT_COMPLIANT" || response.VALUE == "IS_ISSUE") { return 0; }
		if (response.VALUE == "POTENTIAL_ISSUE") { return 1; }
		return 3;
	}
	if (response.STATUS == "AMENDED" || response.STATUS == "FILLED_IN") { return 0; }
	if (response.STATUS == "EXTERNAL_PREREQUISITES_NOT_MET") { return 2; }
	if (response.STATUS == BDQ_INTERNAL_PREREQUISITES_NOT_MET) { return 5; }
	return 4;
}

/**
 * function bdqSortedGuids lists the guids of a phase's responses in display order.
 *
 * @param responses struct of test responses keyed by guid.
 * @param tests the TESTS struct from the backing method, used to sort by test name within a group.
 * @return array of guids.
 */
function bdqSortedGuids(responses, tests) {
	return Object.keys(responses).sort(function (a, b) {
		var order = bdqSortOrder(responses[a]) - bdqSortOrder(responses[b]);
		if (order != 0) { return order; }
		var nameA = (tests[a] && tests[a].NAME) || a;
		var nameB = (tests[b] && tests[b].NAME) || b;
		return nameA < nameB ? -1 : (nameA > nameB ? 1 : 0);
	});
}

/**
 * function bdqTableHtml assembles a table of responses under its own heading, with rows that only
 * report INTERNAL_PREREQUISITES_NOT_MET hidden until all tests are shown.
 *
 * @param headingId id for the heading that names the table.
 * @param heading text of the heading.
 * @param columns array of the columns after the Test column, each either a column header text or
 *  a group { group: header text for the group, columns: array of column header texts }, groups are
 *  set off by a rule at their left, which the rows' first cell in each group should repeat.
 * @param rows array of { html: tr content, hideable: boolean }.
 * @return html for the heading and table, empty if there are no rows.
 */
function bdqTableHtml(headingId, heading, columns, rows) {
	if (rows.length == 0) { return ""; }
	var hiddenCount = 0;
	var body = "";
	for (var i = 0; i < rows.length; i++) {
		if (rows[i].hideable) {
			hiddenCount++;
			body = body + "<tr class='bdqHideable d-none'>" + rows[i].html + "</tr>";
		} else {
			body = body + "<tr>" + rows[i].html + "</tr>";
		}
	}
	var html = "<h3 class='h4 mt-3' id='" + headingId + "'>" + bdqEscapeHtml(heading) + "</h3>";
	if (hiddenCount == rows.length) {
		html = html + "<p class='bdqHiddenNote small'>Only " + BDQ_INTERNAL_PREREQUISITES_NOT_MET + " responses (" + hiddenCount + "), shown with Show All Tests.</p>";
	}
	var grouped = false;
	for (var j = 0; j < columns.length; j++) {
		if (columns[j].group) { grouped = true; }
	}
	// with groups, a first header row names each group and a second names the columns within them
	var groupRow = "";
	var columnRow = "";
	for (var k = 0; k < columns.length; k++) {
		if (columns[k].group) {
			groupRow = groupRow + "<th scope='colgroup' colspan='" + columns[k].columns.length + "' class='" + BDQ_PHASE_START_CLASS + "'>" + bdqEscapeHtml(columns[k].group) + "</th>";
			for (var m = 0; m < columns[k].columns.length; m++) {
				columnRow = columnRow + "<th scope='col'" + (m == 0 ? " class='" + BDQ_PHASE_START_CLASS + "'" : "") + ">" + bdqEscapeHtml(columns[k].columns[m]) + "</th>";
			}
		} else if (grouped) {
			groupRow = groupRow + "<th scope='col' rowspan='2'>" + bdqEscapeHtml(columns[k]) + "</th>";
		} else {
			columnRow = columnRow + "<th scope='col'>" + bdqEscapeHtml(columns[k]) + "</th>";
		}
	}
	html = html + "<table class='table table-sm table-striped table-responsive d-xl-table border' aria-labelledby='" + headingId + "'>";
	if (grouped) {
		// scope='colgroup' headers apply to the columns of a colgroup element
		html = html + "<colgroup><col></colgroup>";
		for (var n = 0; n < columns.length; n++) {
			html = html + (columns[n].group ? "<colgroup span='" + columns[n].columns.length + "'></colgroup>" : "<colgroup><col></colgroup>");
		}
	}
	html = html + "<thead>";
	if (grouped) {
		html = html + "<tr><th scope='col' rowspan='2'>Test</th>" + groupRow + "</tr><tr>" + columnRow + "</tr>";
	} else {
		html = html + "<tr><th scope='col'>Test</th>" + columnRow + "</tr>";
	}
	return html + "</thead><tbody>" + body + "</tbody></table>";
}

/**
 * function bdqToggleAll shows or hides the responses that only report INTERNAL_PREREQUISITES_NOT_MET.
 *
 * @param targetDivId the id of the element holding the results, without a leading # selector.
 * @param buttonId the id of the toggle button, without a leading # selector.
 */
function bdqToggleAll(targetDivId, buttonId) {
	var showing = $("#" + buttonId).attr("aria-pressed") == "true";
	$("#" + targetDivId + " .bdqHideable").toggleClass("d-none", showing);
	$("#" + targetDivId + " .bdqHiddenNote").toggleClass("d-none", !showing);
	$("#" + buttonId).attr("aria-pressed", showing ? "false" : "true");
}

/**
 * function bdqCountsHtml summarizes the validation results of one phase.
 *
 * @param phaseLabel the name of the phase, e.g. Pre-amendment.
 * @param responses struct of test responses keyed by guid.
 * @return html for a list item with the count of each Response.result or Response.status.
 */
function bdqCountsHtml(phaseLabel, responses) {
	var counts = {};
	var examples = {};  // a response with each result or status, to sort and format the counts
	var order = [];
	for (var guid in responses) {
		var response = responses[guid];
		if (response.TYPE != "VALIDATION") { continue; }
		var key = response.STATUS == "RUN_HAS_RESULT" ? response.VALUE : response.STATUS;
		if (!(key in counts)) { counts[key] = 0; examples[key] = response; order.push(key); }
		counts[key]++;
	}
	order.sort(function (a, b) { return bdqSortOrder(examples[a]) - bdqSortOrder(examples[b]); });
	var parts = [];
	for (var i = 0; i < order.length; i++) {
		parts.push(counts[order[i]] + " " + bdqResultHtml(examples[order[i]]));
	}
	if (parts.length == 0) { parts.push("none run"); }
	return "<li>" + bdqEscapeHtml(phaseLabel) + " validations: " + parts.join(", ") + "</li>";
}

/**
 * function displayQCResult renders the results of a QC report in html, as validations, measures and
 * issues (each pre- and post-amendment), and amendments, in the terms of the BDQ standard.
 *
 * @param data the data object returned from an ajax call to a qc backing method, containing GUID,
 *  MECHANISM, PREAMENDMENT, AMENDMENT, POSTAMENDMENT, and TESTS.
 * @param category a label for the test category, e.g. Event, Taxon Name, Geospatial of which
 *  these are the results.
 * @param targetDivId the id of a div in the DOM for which to replace the html content of with
 *   the test results, specified without a leading # selector.
 * @param focusOnLoad if true, move focus to the heading of the results.
 */
function displayQCResult(data, category, targetDivId, focusOnLoad) {
	var pre = data.PREAMENDMENT || {};
	var post = data.POSTAMENDMENT || {};
	var amend = data.AMENDMENT || {};
	var tests = data.TESTS || {};
	var headingId = targetDivId + "Heading";
	var buttonId = targetDivId + "ShowAll";

	// validations, measures, and issues, each with its pre- and post-amendment response
	var validationRows = [];
	var otherRows = [];
	var guids = bdqSortedGuids(pre, tests);
	for (var i = 0; i < guids.length; i++) {
		var guid = guids[i];
		var before = pre[guid];
		var after = post[guid];
		var hideable = before.STATUS == BDQ_INTERNAL_PREREQUISITES_NOT_MET && (!after || after.STATUS == BDQ_INTERNAL_PREREQUISITES_NOT_MET);
		var afterComment = "";
		if (after) {
			afterComment = after.COMMENT == before.COMMENT ? "<span class='text-muted'>as before</span>" : bdqEscapeHtml(after.COMMENT);
		}
		var row = bdqTestHeaderHtml(guid, before, tests)
			+ "<td class='" + BDQ_PHASE_START_CLASS + "'>" + bdqResultHtml(before) + "</td><td class='small'>" + bdqEscapeHtml(before.COMMENT) + "</td>"
			+ "<td class='" + BDQ_PHASE_START_CLASS + "'>" + bdqResultHtml(after) + "</td><td class='small'>" + afterComment + "</td>";
		if (before.TYPE == "VALIDATION") {
			validationRows.push({ html: row, hideable: hideable });
		} else {
			otherRows.push({ html: row, hideable: hideable });
		}
	}

	// amendments, with the terms and values each proposes
	var amendmentRows = [];
	var amendGuids = bdqSortedGuids(amend, tests);
	for (var j = 0; j < amendGuids.length; j++) {
		var amendment = amend[amendGuids[j]];
		var proposed = "";
		if (amendment.VALUES) {
			for (var term in amendment.VALUES) {
				proposed = proposed + "<div>" + bdqEscapeHtml(term) + ": " + bdqEscapeHtml(amendment.VALUES[term]) + "</div>";
			}
		} else {
			proposed = bdqEscapeHtml(amendment.VALUE);
		}
		amendmentRows.push({
			html: bdqTestHeaderHtml(amendGuids[j], amendment, tests) + "<td>" + bdqResultHtml(amendment) + "</td><td>" + proposed + "</td><td class='small'>" + bdqEscapeHtml(amendment.COMMENT) + "</td>",
			hideable: amendment.STATUS == BDQ_INTERNAL_PREREQUISITES_NOT_MET
		});
	}

	var hiddenCount = 0;
	var allRows = validationRows.concat(otherRows, amendmentRows);
	for (var k = 0; k < allRows.length; k++) { if (allRows[k].hideable) { hiddenCount++; } }

	var display = "<section aria-labelledby='" + headingId + "'>";
	display = display + "<h2 class='h3' id='" + headingId + "' tabindex='-1'>BDQ " + bdqEscapeHtml(category) + " Tests for " + bdqEscapeHtml(data.GUID) + "</h2>";
	display = display + "<p class='small mb-1'>Tests from the <a href='" + BDQ_STANDARD_URL + "' target='_blank' rel='noopener'>TDWG Biodiversity Data Quality (BDQ) draft standard</a>, run with " + bdqEscapeHtml(data.MECHANISM) + ".</p>";
	display = display + "<p class='small mb-1'>Pre-amendment phase: the tests run on the values in the record. "
		+ "Amendment phase: changes proposed to those values. "
		+ "Post-amendment phase: the same tests run again on the values with the proposed changes applied.</p>";
	display = display + "<ul class='list-unstyled small mb-1'>" + bdqCountsHtml("Pre-amendment", pre) + bdqCountsHtml("Post-amendment", post) + "</ul>";
	if (hiddenCount > 0) {
		display = display + "<button type='button' class='btn btn-xs btn-secondary' id='" + buttonId + "' aria-pressed='false' onClick=\"bdqToggleAll('" + bdqEscapeHtml(targetDivId) + "','" + bdqEscapeHtml(buttonId) + "');\">Show All Tests</button>";
		display = display + " <span class='small'>" + BDQ_INTERNAL_PREREQUISITES_NOT_MET + " responses hidden: " + hiddenCount + ".</span>";
	}
	var responseColumns = [
		{ group: "Pre-amendment phase", columns: ["Response", "Response.comment"] },
		{ group: "Post-amendment phase", columns: ["Response", "Response.comment"] }
	];
	display = display + bdqTableHtml(targetDivId + "Validations", "Validations", responseColumns, validationRows);
	display = display + bdqTableHtml(targetDivId + "MeasuresIssues", "Measures and Issues", responseColumns, otherRows);
	if (amendmentRows.length > 0) {
		display = display + bdqTableHtml(targetDivId + "Amendments", "Amendment Phase", ["Response.status", "Response.result (proposed values)", "Response.comment"], amendmentRows);
	} else {
		display = display + "<h3 class='h4 mt-3'>Amendment Phase</h3><p>No amendments proposed.</p>";
	}
	display = display + "</section>";

	$("#" + targetDivId).html(display);
	if (focusOnLoad) {
		$("#" + headingId).focus();
	}
}
