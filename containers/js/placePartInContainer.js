/**
 * Backing JS for containers/placePartInContainer.cfm -- loads the specimen-search results and the
 * New Part dialog as server-rendered HTML from containers/component/functions.cfc's
 * getPartsForContainerPlacementHTML/getNewPartFormHTML (the same pattern
 * specimens/component/functions.cfc's getEditPartsHTML/getPartContainersHTML already use), then
 * runs placement/retype preflight and commit against the small JSON+badge convention already
 * established by moveContainer.cfm and bulkModifyContainers.cfm (renderPlacementWarningBadge).
 */

var placePartState = {
	currentParentType: '',
	part1Preflight: null,
	part2Preflight: null,
	retypeChecked: false
};

/**
 * Loads the specimen-search results (specimen context, Part selects, placement controls) as one
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
		placePartState.part1Preflight = null;
		placePartState.part2Preflight = null;
		placePartState.currentParentType = '';
		area.html(html);
		previewCurrentPlacement();
	}).fail(function() {
		area.html('<p class="text-danger">Error: could not reach the server.</p>');
	});
}

/**
 * When exactly one part was found, its current-container breadcrumb is shown with its own
 * placement badge -- checks that part's existing placement against its actual current parent
 * (reusing the same preflight/badge convention as a proposed move), so a pre-existing placement
 * problem is visible without having to enter a Parent Unique Identifier first.
 * @returns {void}
 */
function previewCurrentPlacement() {
	var badge = $('#currentPlacementBadge');
	if (!badge.length) {
		return;
	}
	var partId = badge.data('partId');
	var currentParentBarcode = badge.data('currentParentBarcode');
	if (!partId || !currentParentBarcode) {
		return;
	}
	runPartPreflight(partId, currentParentBarcode, 'currentPlacementBadge', function() {});
}

/**
 * Shows/hides the Part 2 select based on the "move a second part" checkbox.
 * @returns {void}
 */
function toggleSecondPart() {
	if ($('#useSecondPart').prop('checked')) {
		$('#secondPartWrap').show();
	} else {
		$('#secondPartWrap').hide();
		$('#part_name_2').val('');
		$('#part2Badge').empty();
		placePartState.part2Preflight = null;
	}
	updateMoveButtonState();
}

/**
 * Parent Barcode change handler -- previews the placement (and any pending retype) without
 * committing anything.
 * @returns {void}
 */
function onParentBarcodeChange() {
	previewPlacement();
}

/**
 * Runs placement preflight for part 1 (and part 2, if selected) against the current Parent
 * Barcode, rendering badges and updating the current-type display and Move button state.
 * @returns {void}
 */
function previewPlacement() {
	var parentBarcode = $('#parent_barcode').val();
	var part1Id = $('#part_name').val();
	if (!parentBarcode || !part1Id) {
		return;
	}
	runPartPreflight(part1Id, parentBarcode, 'part1Badge', function(result) {
		placePartState.part1Preflight = result;
		if (result && result.status === 'ok') {
			placePartState.currentParentType = result.parent_type || '';
			$('#currentParentType').text(placePartState.currentParentType || '(none)');
			if ($('#keepCurrentType').prop('checked')) {
				$('#new_container_type').val(placePartState.currentParentType);
			}
		}
		updateMoveButtonState();
	});
	var part2Id = $('#useSecondPart').prop('checked') ? $('#part_name_2').val() : '';
	if (part2Id) {
		runPartPreflight(part2Id, parentBarcode, 'part2Badge', function(result) {
			placePartState.part2Preflight = result;
			updateMoveButtonState();
		});
	} else {
		$('#part2Badge').empty();
		placePartState.part2Preflight = null;
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
	var parentContainerId = placePartState.part1Preflight ? placePartState.part1Preflight.parent_container_id : null;
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
 * Enables the Move button only when part 1's placement is allowed (and part 2's, if selected),
 * and the retype (if one is pending) is itself allowed.
 * @returns {void}
 */
function updateMoveButtonState() {
	var ok = !!(placePartState.part1Preflight && placePartState.part1Preflight.allowed);
	if ($('#useSecondPart').prop('checked')) {
		ok = ok && !!(placePartState.part2Preflight && placePartState.part2Preflight.allowed);
	}
	if (!$('#keepCurrentType').prop('checked') && $('#new_container_type').val() !== placePartState.currentParentType) {
		ok = ok && placePartState.retypeChecked;
	}
	$('#moveBtn').prop('disabled', !ok);
}

/**
 * Explicit commit: retypes the parent (if requested) then moves part 1 and, if selected, part 2,
 * each independently, appending a Move Log entry per outcome.
 * @returns {void}
 */
function commitPlacement() {
	var parentBarcode = $('#parent_barcode').val();
	var part1Id = $('#part_name').val();
	if (!parentBarcode || !part1Id) {
		return;
	}
	$('#moveBtn').prop('disabled', true);
	var keepType = $('#keepCurrentType').prop('checked');
	var newType = $('#new_container_type').val();
	var needsRetype = !keepType && newType && newType !== placePartState.currentParentType;
	var parentContainerId = placePartState.part1Preflight ? placePartState.part1Preflight.parent_container_id : null;

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
				movePartsAfterRetype(parentBarcode, part1Id);
			} else {
				appendMoveLogEntry('Retype failed: ' + ((result && result.message) || 'unknown error') + ' -- move not attempted.', false);
				$('#moveBtn').prop('disabled', false);
			}
		}).fail(function() {
			appendMoveLogEntry('Retype failed: could not reach the server -- move not attempted.', false);
			$('#moveBtn').prop('disabled', false);
		});
	} else {
		movePartsAfterRetype(parentBarcode, part1Id);
	}
}

/**
 * Moves part 1 (and part 2, if selected), called after any requested retype has succeeded (or
 * was not requested at all).
 * @param {string} parentBarcode
 * @param {string} part1Id
 * @returns {void}
 */
function movePartsAfterRetype(parentBarcode, part1Id) {
	var part1Name = $('#part_name option:selected').text();
	movePart(part1Id, part1Name, parentBarcode, function() {
		var part2Id = $('#useSecondPart').prop('checked') ? $('#part_name_2').val() : '';
		if (part2Id) {
			var part2Name = $('#part_name_2 option:selected').text();
			movePart(part2Id, part2Name, parentBarcode, function() {
				$('#moveBtn').prop('disabled', false);
				searchSpecimenParts();
			});
		} else {
			$('#moveBtn').prop('disabled', false);
			searchSpecimenParts();
		}
	});
}

/**
 * AJAX call to placePartByBarcode, appending a Move Log entry with the outcome.
 * @param {string} partId
 * @param {string} partName - display text of the part, read from its select option.
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
		} else {
			appendMoveLogEntry('Failed to move ' + partName + ': ' + ((result && result.message) || 'unknown error'), false);
		}
		callback();
	}).fail(function() {
		appendMoveLogEntry('Failed to move ' + partName + ': could not reach the server.', false);
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
