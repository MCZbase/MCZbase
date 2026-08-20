/** containers/js/placePartInContainer.js

Scripts supporting the placePartInContainer.cfm page for putting parts 
from a cataloged item into containers.

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
/**
 * Backing JS for containers/placePartInContainer.cfm -- loads the specimen-search results (a
 * table of every part found, each with a checkbox to include it in the move) and the New Part
 * dialog as server-rendered HTML from containers/component/functions.cfc's
 * getPartsForContainerPlacementHTML/getNewPartFormHTML (the same pattern
 * specimens/component/functions.cfc's getEditPartsHTML/getPartContainersHTML already use), then
 * runs placement/retype preflight and commit against the small JSON+badge convention already
 * established by moveContainer.cfm and bulkModifyContainers.cfm (renderPlacementWarningBadge).
 */

var placePartState = {
	currentParentType: '',
	partPreflights: {},
	retypeChecked: false
};

/**
 * Loads the specimen-search results (specimen context, parts table, placement controls) as one
 * server-rendered HTML fragment.
 * @returns {void}
 */
function searchSpecimenParts() {
	var collectionId = $('#collection_id').val();
	var otherIdType = $('#other_id_type').val();
	var oidnum = $('#oidnum').val();
	if (!collectionId || !otherIdType || !oidnum) {
		return;
	}
	var area = $('#specimenResultsArea');
	area.html('<p class="text-muted">Searching...</p>');
	$.get('/containers/component/functions.cfc', {
		method: 'getPartsForContainerPlacementHTML',
		collection_id: collectionId,
		other_id_type: otherIdType,
		oidnum: oidnum,
		noBarcode: $('#noBarcode').prop('checked'),
		noSubsample: $('#noSubsample').prop('checked')
	}, function(html) {
		placePartState.partPreflights = {};
		placePartState.currentParentType = '';
		area.html(html);
		previewCurrentPlacement();
	}).fail(function() {
		area.html('<p class="text-danger">Error: could not reach the server.</p>');
	});
}

/**
 * Every found part's row starts out showing a placement badge for its existing (pre-move)
 * placement, checked against its actual current parent -- so a pre-existing placement problem is
 * visible before anything is selected to move.
 * @returns {void}
 */
function previewCurrentPlacement() {
	$('[id^="currentPlacementBadge_"]').each(function() {
		var badge = $(this);
		var partId = badge.data('partId');
		var currentParentBarcode = badge.data('currentParentBarcode');
		if (!partId || !currentParentBarcode) {
			return;
		}
		runPartPreflight(partId, currentParentBarcode, badge.attr('id'), function() {});
	});
}

/**
 * Parent Barcode change handler -- looks up the target container's current type (independent of
 * whether any part is checked yet, since the per-part preflight that would otherwise report it
 * only runs once a part is selected), then previews the placement for every currently-selected
 * part, without committing anything.
 * @returns {void}
 */
function onParentBarcodeChange() {
	lookupContainerType();
	previewPlacement();
}

/**
 * Looks up the current Parent Barcode's container type and updates the Container Type display
 * (and the New Container Type select, if "Keep current type" is still checked), plus the
 * disposition-guidance hint for whatever gets placed there.
 * @returns {void}
 */
function lookupContainerType() {
	var parentBarcode = $('#parent_barcode').val();
	if (!parentBarcode) {
		return;
	}
	$.getJSON('/containers/component/functions.cfc', {
		method: 'getContainerByBarcode',
		barcode: parentBarcode,
		returnformat: 'json'
	}, function(result) {
		if (result && result.status === 'ok') {
			updateCurrentParentType({parent_type: result.container_type});
			$('#dispositionHint').text(result.expected_disposition_message || '');
		}
	});
}

/**
 * Opens the shared container picker dialog (containers.js), matching moveContainer.cfm's "Choose
 * Parent" convention, to choose the container to place the part(s) into.
 * @returns {void}
 */
function openParentContainerPicker() {
	openContainerPickerDialog({
		mode: 'find',
		dialogTitle: 'Select Container to Place Into',
		onSelect: function(selectedId, selectedLabel, wrapper, controls, selectedItem) {
			var barcode = (selectedItem && selectedItem.barcode) ? $.trim(selectedItem.barcode) : '';
			var label = (selectedItem && selectedItem.label) ? $.trim(selectedItem.label) : '';
			var valueToSet = barcode || label || $.trim(selectedLabel || '');
			$('#parent_barcode').val(valueToSet).trigger('change').focus();
			wrapper.dialog('close');
		}
	});
}

/**
 * A part's "include in move" checkbox changed -- if a Parent Barcode is already entered, preview
 * the proposed placement for just that part; otherwise revert its badge to showing its existing
 * (pre-move) placement.
 * @param {HTMLElement} checkboxEl
 * @returns {void}
 */
function onPartSelectionChange(checkboxEl) {
	var checkbox = $(checkboxEl);
	var partId = checkbox.val();
	var badgeId = 'currentPlacementBadge_' + partId;
	if (checkbox.prop('checked')) {
		var parentBarcode = $('#parent_barcode').val();
		if (parentBarcode) {
			runPartPreflight(partId, parentBarcode, badgeId, function(result) {
				placePartState.partPreflights[partId] = result;
				if (result && result.status === 'ok') {
					updateCurrentParentType(result);
				}
				updateMoveButtonState();
			});
		}
	} else {
		delete placePartState.partPreflights[partId];
		var currentParentBarcode = $('#' + badgeId).data('currentParentBarcode');
		if (currentParentBarcode) {
			runPartPreflight(partId, currentParentBarcode, badgeId, function() {});
		} else {
			$('#' + badgeId).empty();
		}
	}
	updateMoveButtonState();
}

/**
 * Runs placement preflight for every currently-selected part against the current Parent Barcode,
 * updating each row's badge and the current-type display.
 * @returns {void}
 */
function previewPlacement() {
	var parentBarcode = $('#parent_barcode').val();
	var selected = $('.part-select-checkbox:checked');
	if (!parentBarcode || !selected.length) {
		return;
	}
	selected.each(function() {
		var partId = $(this).val();
		runPartPreflight(partId, parentBarcode, 'currentPlacementBadge_' + partId, function(result) {
			placePartState.partPreflights[partId] = result;
			if (result && result.status === 'ok') {
				updateCurrentParentType(result);
			}
			updateMoveButtonState();
		});
	});
}

/**
 * Records the proposed parent's current type from a preflight result and, if "Keep current type"
 * is still checked, keeps the New Container Type select in sync with it.
 * @param {Object} result
 * @returns {void}
 */
function updateCurrentParentType(result) {
	placePartState.currentParentType = result.parent_type || '';
	$('#currentParentType').text(placePartState.currentParentType || '(none)');
	if ($('#keepCurrentType').prop('checked')) {
		$('#new_container_type').val(placePartState.currentParentType);
	}
}

/**
 * AJAX call to preflightPlacePartByBarcode, rendering the result as a placement badge via the
 * shared renderPlacementWarningBadge convention (containers.js).
 * @param {string} partId - specimen_part collection_object_id.
 * @param {string} parentBarcode - candidate parent container barcode.
 * @param {string} badgeId - id (no leading #) of the div to render the badge into.
 * @param {Function} callback - called with the parsed result.
 * @returns {void}
 */
function runPartPreflight(partId, parentBarcode, badgeId, callback) {
	$.getJSON('/containers/component/functions.cfc', {
		method: 'preflightPlacePartByBarcode',
		part_collection_object_id: partId,
		parent_barcode: parentBarcode,
		returnformat: 'json'
	}, function(result) {
		if (result && result.status === 'ok') {
			renderPlacementWarningBadge(result, badgeId);
		} else {
			$('#' + badgeId).html('<span class="badge badge-danger">' + ((result && result.message) || 'Error') + '</span>');
		}
		callback(result);
	}).fail(function() {
		$('#' + badgeId).html('<span class="badge badge-danger">Error checking placement</span>');
		callback(null);
	});
}

/**
 * "Keep current type" checkbox handler.
 * @returns {void}
 */
function onKeepCurrentTypeChange() {
	var keep = $('#keepCurrentType').prop('checked');
	$('#new_container_type').toggle(!keep);
	if (keep) {
		$('#new_container_type').val(placePartState.currentParentType);
		$('#retypeBadge').empty();
		placePartState.retypeChecked = false;
	} else {
		onNewContainerTypeChange();
	}
	updateMoveButtonState();
}

/**
 * New Container Type select change handler -- runs retype validation only when a type
 * different from the parent's current type has been chosen.
 * @returns {void}
 */
function onNewContainerTypeChange() {
	var newType = $('#new_container_type').val();
	if ($('#keepCurrentType').prop('checked') || !newType || newType === placePartState.currentParentType) {
		$('#retypeBadge').empty();
		placePartState.retypeChecked = false;
		updateMoveButtonState();
		return;
	}
	var parentContainerId = firstSelectedParentContainerId();
	if (!parentContainerId) {
		return;
	}
	$.getJSON('/containers/component/functions.cfc', {
		method: 'validateContainerRetype',
		container_id: parentContainerId,
		new_container_type: newType,
		returnformat: 'json'
	}, function(result) {
		renderPlacementWarningBadge(result, 'retypeBadge');
		placePartState.retypeChecked = !!(result && result.allowed);
		updateMoveButtonState();
	}).fail(function() {
		$('#retypeBadge').html('<span class="badge badge-danger">Error checking retype</span>');
		placePartState.retypeChecked = false;
		updateMoveButtonState();
	});
}

/**
 * Returns the proposed parent_container_id from any one selected part's stored preflight -- they
 * all target the same Parent Barcode, so any of them will do.
 * @returns {?number}
 */
function firstSelectedParentContainerId() {
	var found = null;
	$('.part-select-checkbox:checked').each(function() {
		if (found) {
			return;
		}
		var preflight = placePartState.partPreflights[$(this).val()];
		if (preflight && preflight.parent_container_id) {
			found = preflight.parent_container_id;
		}
	});
	return found;
}

/**
 * Enables the Move button only when at least one part is selected, every selected part's
 * placement preflight is allowed, and the retype (if one is pending) is itself allowed.
 * @returns {void}
 */
function updateMoveButtonState() {
	var selected = $('.part-select-checkbox:checked');
	$('#selectedPartCount').text(selected.length);
	var ok = selected.length > 0;
	selected.each(function() {
		var preflight = placePartState.partPreflights[$(this).val()];
		if (!preflight || !preflight.allowed) {
			ok = false;
		}
	});
	if (!$('#keepCurrentType').prop('checked') && $('#new_container_type').val() !== placePartState.currentParentType) {
		ok = ok && placePartState.retypeChecked;
	}
	$('#moveBtn').prop('disabled', !ok);
}

/**
 * Explicit commit handler for the Move button -- confirms first if any selected part's placement
 * came back as a warning, or if a part is currently filed more than one level below root/an
 * institution container (moving it out of what's likely a deliberate, specific location), then
 * proceeds to the actual retype/move sequence.
 * @returns {void}
 */
function commitPlacement() {
	var parentBarcode = $('#parent_barcode').val();
	var selected = $('.part-select-checkbox:checked');
	if (!parentBarcode || !selected.length) {
		return;
	}
	var messageList = $('<ul class="mb-0 pl-3"></ul>');
	selected.each(function() {
		var checkbox = $(this);
		var preflight = placePartState.partPreflights[checkbox.val()];
		if (!preflight) {
			return;
		}
		var partName = checkbox.data('partName') || 'this part';
		if (preflight.severity === 'warn') {
			messageList.append($('<li></li>').text('This part (' + partName + ') has a placement warning -- proceed anyway?'));
		}
		if (preflight.current_depth > 2) {
			messageList.append($('<li></li>').text('This part (' + partName + ') is currently filed several levels below the root/institution container. Move it from its current container?'));
		}
	});
	if (messageList.children().length) {
		confirmDialog($('<div></div>').append(messageList).html(), 'Confirm Move', function() {
			doCommitPlacement(parentBarcode);
		});
	} else {
		doCommitPlacement(parentBarcode);
	}
}

/**
 * Retypes the parent (if requested) then moves every currently-selected part, called directly by
 * commitPlacement, or after the user confirms a warning/depth prompt.
 * @param {string} parentBarcode
 * @returns {void}
 */
function doCommitPlacement(parentBarcode) {
	$('#moveBtn').prop('disabled', true);
	var keepType = $('#keepCurrentType').prop('checked');
	var newType = $('#new_container_type').val();
	var needsRetype = !keepType && newType && newType !== placePartState.currentParentType;
	var parentContainerId = firstSelectedParentContainerId();

	if (needsRetype && parentContainerId) {
		$.getJSON('/containers/component/functions.cfc', {
			method: 'applyBulkRetypeContainer',
			container_id: parentContainerId,
			new_container_type: newType,
			returnformat: 'json'
		}, function(result) {
			if (result && result.status === 'updated') {
				appendMoveLogEntry('Parent container retyped to ' + newType + '.', true);
				placePartState.currentParentType = newType;
				moveSelectedParts(parentBarcode);
			} else {
				appendMoveLogEntry('Retype failed: ' + ((result && result.message) || 'unknown error') + ' -- move not attempted.', false);
				$('#moveBtn').prop('disabled', false);
			}
		}).fail(function() {
			appendMoveLogEntry('Retype failed: could not reach the server -- move not attempted.', false);
			$('#moveBtn').prop('disabled', false);
		});
	} else {
		moveSelectedParts(parentBarcode);
	}
}

/**
 * Moves every currently-selected part into the Parent Barcode, one at a time, each independently
 * (one failing doesn't block the rest), appending a Move Log entry per outcome.
 * @param {string} parentBarcode
 * @returns {void}
 */
function moveSelectedParts(parentBarcode) {
	var queue = [];
	$('.part-select-checkbox:checked').each(function() {
		queue.push({id: $(this).val(), name: $(this).data('partName')});
	});
	var advance = function(index) {
		if (index >= queue.length) {
			$('#moveBtn').prop('disabled', false);
			searchSpecimenParts();
			return;
		}
		movePart(queue[index].id, queue[index].name, parentBarcode, function() {
			advance(index + 1);
		});
	};
	advance(0);
}

/**
 * AJAX call to placePartByBarcode, appending a Move Log entry with the outcome.
 * @param {string} partId
 * @param {string} partName - display text of the part, read from its checkbox's data attribute.
 * @param {string} parentBarcode
 * @param {Function} callback - called once the move attempt completes (success or failure).
 * @returns {void}
 */
function movePart(partId, partName, parentBarcode, callback) {
	$.getJSON('/containers/component/functions.cfc', {
		method: 'placePartByBarcode',
		part_collection_object_id: partId,
		parent_barcode: parentBarcode,
		returnformat: 'json'
	}, function(result) {
		if (result && result.status === 'moved') {
			appendMoveLogEntry('Moved ' + partName + ' into ' + parentBarcode + '.', true);
			applyDispositionChange(partId, partName, callback);
		} else {
			appendMoveLogEntry('Failed to move ' + partName + ': ' + ((result && result.message) || 'unknown error'), false);
			callback();
		}
	}).fail(function() {
		appendMoveLogEntry('Failed to move ' + partName + ': could not reach the server.', false);
		callback();
	});
}

/**
 * Applies the "Change Disposition of Selected Parts" select's value (if any) to one just-moved
 * part, appending a Move Log entry with the outcome. No-ops immediately if no disposition change
 * was requested. Calls specimens/component/functions.cfc's updatePartDisposition, not
 * containers/component/functions.cfc, since a part's disposition isn't container-entangled.
 * @param {string} partId
 * @param {string} partName
 * @param {Function} callback
 * @returns {void}
 */
function applyDispositionChange(partId, partName, callback) {
	var disposition = $('#change_disposition').val();
	if (!disposition) {
		callback();
		return;
	}
	$.getJSON('/specimens/component/functions.cfc', {
		method: 'updatePartDisposition',
		part_collection_object_id: partId,
		disposition: disposition,
		returnformat: 'json'
	}, function(result) {
		if (result && result.status === 'updated') {
			appendMoveLogEntry('Set disposition of ' + partName + ' to ' + disposition + '.', true);
		} else {
			appendMoveLogEntry('Failed to set disposition of ' + partName + ': ' + ((result && result.message) || 'unknown error'), false);
		}
		callback();
	}).fail(function() {
		appendMoveLogEntry('Failed to set disposition of ' + partName + ': could not reach the server.', false);
		callback();
	});
}

/**
 * Appends one entry to the on-page Move Log.
 * @param {string} text
 * @param {boolean} success
 * @returns {void}
 */
function appendMoveLogEntry(text, success) {
	var entry = $('<div></div>').addClass(success ? 'text-success' : 'text-danger').text(text);
	$('#moveLog').prepend(entry);
}

/**
 * Opens the New Part dialog, loading this specimen's collection-specific form fields as one
 * server-rendered HTML fragment.
 * @returns {void}
 */
function openNewPartDialog() {
	var collectionId = $('#collection_id').val();
	if (!collectionId) {
		return;
	}
	var area = $('#newPartFormArea');
	$.get('/containers/component/functions.cfc', {
		method: 'getNewPartFormHTML',
		collection_id: collectionId
	}, function(html) {
		area.html(html);
		$('#newPartDialog').dialog({
			modal: true,
			width: 500,
			title: 'New Part'
		});
	}).fail(function() {
		area.html('<p class="text-danger">Error loading part form.</p>');
	});
}

/**
 * Submits the New Part dialog to specimens/component/functions.cfc's createSpecimenPart, then
 * refreshes the parts list on success.
 * @returns {void}
 */
function submitNewPart() {
	$('#newPartFeedback').text('Saving...');
	$.getJSON('/specimens/component/functions.cfc', {
		method: 'createSpecimenPart',
		derived_from_cat_item: $('#catalogedItemId').val(),
		part_name: $('#npart_name').val(),
		preserve_method: $('#npreserve_method').val(),
		lot_count: $('#nlot_count').val(),
		lot_count_modifier: $('#nlot_count_modifier').val(),
		coll_obj_disposition: $('#ncoll_obj_disposition').val(),
		condition: $('#ncondition').val(),
		condition_remarks: $('#ncondition_remarks').val(),
		coll_object_remarks: $('#ncoll_object_remarks').val(),
		returnformat: 'json'
	}, function(result) {
		var row = (result && result[0]) ? result[0] : null;
		if (row && row.status === 'saved') {
			$('#newPartDialog').dialog('close');
			searchSpecimenParts();
		} else {
			$('#newPartFeedback').text('Error creating part.');
		}
	}).fail(function() {
		$('#newPartFeedback').text('Error creating part.');
	});
}
