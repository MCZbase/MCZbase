/*
Bulkloader/js/bulkloader.js

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

Functions for the pages in /Bulkloader/ that pick records by entered by, accession and collection.
*/

/** Keeps the All option of a multiple select exclusive: picking All clears the other choices,
 * picking another value clears All, and clearing every choice selects All again.
 *
 * @param select the select element, whose All option carries data-all="true".
 */
function selectAllOrSome(select) {
	var allOption = $(select).find("option[data-all='true']");
	var others = $(select).find("option:selected").not("[data-all='true']");
	var allWasSelected = $(select).data("allWasSelected") === true;
	if (allOption.prop("selected") && others.length > 0) {
		if (allWasSelected) {
			allOption.prop("selected", false);
		} else {
			others.prop("selected", false);
		}
	}
	if ($(select).find("option:selected").length == 0) {
		allOption.prop("selected", true);
	}
	$(select).data("allWasSelected", allOption.prop("selected"));
}

/** Shows, beside each option of a set of multiple selects, how many records it would match with the
 * choices in the other selects, and how many records the choices made match, disabling the given
 * buttons when that is none.  Options to count carry data-match, the value to compare with the groups,
 * and data-label, the text to show before the count.
 *
 * @param selectIds the ids of the selects, without a leading #; each is also the key of its value in a group.
 * @param groups an array of objects, one per combination of values, each with a value for every select id
 *  and count, the number of records with that combination.
 * @param outputId the id of the output for the number of matching records, without a leading #.
 * @param buttonIds the ids of the buttons to disable when no records match, without a leading #.
 */
function updateSelectionCounts(selectIds, groups, outputId, buttonIds) {
	var chosen = {};
	selectIds.forEach(function(selectId) {
		var values = [];
		$("#" + selectId + " option[data-match]:selected").each(function() {
			values.push($(this).attr("data-match"));
		});
		chosen[selectId] = values;
	});
	var matches = function(group, selectId) {
		return chosen[selectId].length == 0 || chosen[selectId].indexOf(group[selectId]) >= 0;
	};
	selectIds.forEach(function(selectId) {
		var counts = {};
		groups.forEach(function(group) {
			var inOthers = selectIds.every(function(other) { return other == selectId || matches(group, other); });
			if (inOthers) {
				counts[group[selectId]] = (counts[group[selectId]] || 0) + group.count;
			}
		});
		$("#" + selectId + " option[data-match]").each(function() {
			var count = counts[$(this).attr("data-match")] || 0;
			$(this).text($(this).attr("data-label") + " (" + count + ")");
		});
	});
	var total = 0;
	groups.forEach(function(group) {
		if (selectIds.every(function(selectId) { return matches(group, selectId); })) {
			total += group.count;
		}
	});
	if (total == 0) {
		$("#" + outputId).text("No records match these choices; change one of them.").addClass("text-danger");
	} else {
		$("#" + outputId).text(total + " records match.").removeClass("text-danger");
	}
	buttonIds.forEach(function(buttonId) {
		$("#" + buttonId).prop("disabled", total == 0);
	});
}

/** Sets each of a set of multiple selects back to its All option, and updates the counts.
 *
 * @param selectIds the ids of the selects, without a leading #, each with an All option carrying data-all="true".
 * @param groups the combinations of values counted, as for updateSelectionCounts.
 * @param outputId the id of the output for the number of matching records, without a leading #.
 * @param buttonIds the ids of the buttons to disable when no records match, without a leading #.
 * @see updateSelectionCounts
 */
function clearSelections(selectIds, groups, outputId, buttonIds) {
	selectIds.forEach(function(selectId) {
		$("#" + selectId + " option").prop("selected", false);
		$("#" + selectId + " option[data-all='true']").prop("selected", true);
		$("#" + selectId).data("allWasSelected", true);
	});
	updateSelectionCounts(selectIds, groups, outputId, buttonIds);
}
