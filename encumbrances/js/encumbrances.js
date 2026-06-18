/**
 * encumbrances/js/encumbrances.js
 *
 * Page-specific JavaScript for the encumbrance search, create/edit, and view pages.
 *
 * Copyright 2008-2017 Contributors to Arctos
 * Copyright 2008-2026 President and Fellows of Harvard College
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* ============================================================
 * Search page (/encumbrances/Encumbrances.cfm)
 * ============================================================ */

/**
 * Show a "Searching..." placeholder while the AJAX request is in flight.
 */
function showSearchingMarker() {
	$('#encumbranceSearchResultsContainer').html(
		'<p class="mt-3 text-muted pl-1">Searching&hellip;</p>'
	);
}

/**
 * Serialise all non-empty search-form inputs into a query string and load
 * results from encumbrances/component/search.cfc via AJAX.
 */
function loadEncumbranceResults() {
	var $form = $('#encumbranceSearchForm');
	var params = [];
	$form.find(':input').not(':disabled').each(function () {
		var $f = $(this);
		var name = $f.attr('name');
		if (!name) { return; }
		var type = ($f.attr('type') || '').toLowerCase();
		if (type === 'submit' || type === 'button' || type === 'reset') { return; }
		if ((type === 'checkbox' || type === 'radio') && !$f.prop('checked')) { return; }
		var val = $.trim($f.val() || '');
		if (val.length > 0) {
			params.push({ name: name, value: val });
		}
	});
	var qs = $.param(params);
	showSearchingMarker();
	$.ajax({
		url: '/encumbrances/component/search.cfc?method=renderEncumbranceSearchResults&returnformat=plain&' + qs,
		type: 'get',
		success: function (data) {
			$('#encumbranceSearchResultsContainer').html(data);
		},
		error: function (jqXHR, textStatus, error) {
			console.error('Encumbrance search error:', error);
			$('#encumbranceSearchResultsContainer').html(
				'<p class="mt-3 text-danger pl-1">Unable to load search results. Please try again.</p>'
			);
		}
	});
}

/**
 * Populates and submits the shared encumbrance action form rendered inside
 * the search results table (returned by search.cfc).  The form targets
 * /encumbrances/Encumbrances.cfm so that the legacy saveEncumbrances / remListedItems
 * actions continue to work while they remain on the root page.
 *
 * @param {string} actionValue      - the action name (e.g. 'saveEncumbrances').
 * @param {string} encumbranceId    - the encumbrance_id to act on.
 * @param {string} collectionObjectId - the collection_object_id context; may be empty.
 */
function submitEncumbranceAction(actionValue, encumbranceId, collectionObjectId) {
	$('#encActionValue').val(actionValue);
	$('#encIdValue').val(encumbranceId);
	$('#encCollObjValue').val(collectionObjectId);
	$('#encumbranceActionForm').submit();
}

/**
 * Asks the user to confirm deletion, then calls deleteEncumbrance on
 * encumbrances/component/functions.cfc via AJAX and refreshes the results.
 *
 * @param {string} encumbranceId      - the ID of the encumbrance to delete.
 * @param {string} collectionObjectId - the collection_object_id context; may be empty.
 */
function confirmDeleteEncumbranceResult(encumbranceId, collectionObjectId) {
	confirmDialog('Are you sure you want to delete this encumbrance? This cannot be undone.', 'Delete Encumbrance?', function() {
		$.ajax({
			url: '/encumbrances/component/functions.cfc',
			data: {
				method: 'deleteEncumbrance',
				returnformat: 'json',
				encumbrance_id: encumbranceId
			},
			type: 'post',
			dataType: 'json',
			success: function (resp) {
				if (resp.STATUS === 'ok' || resp.status === 'ok') {
					loadEncumbranceResults();
				} else if (resp.STATUS === 'blocked' || resp.status === 'blocked') {
					messageDialog('Cannot delete: ' + (resp.MESSAGE || resp.message), 'Cannot Delete');
				} else {
					messageDialog('Error deleting encumbrance: ' + (resp.MESSAGE || resp.message || 'Unknown error.'), 'Error');
				}
			},
			error: function (jqXHR, textStatus, error) {
				console.error('Delete encumbrance error:', error);
				messageDialog('Error deleting encumbrance. Please try again.', 'Error');
			}
		});
	});
}

/* ============================================================
 * Create/edit page (/encumbrances/Encumbrance.cfm)
 * ============================================================ */

/**
 * Validates the create or edit encumbrance form before AJAX submission.
 * Checks that an agent has been resolved and that expiration date and
 * expiration event are not both specified.
 *
 * @param {string} agentIdFieldId - the ID of the hidden agent_id input.
 * @param {string} expDateFieldId - the ID of the expiration_date input.
 * @param {string} expEventFieldId - the ID of the expiration_event input.
 * @return {boolean} false if validation fails, true otherwise.
 */
function validateEncumbranceForm(agentIdFieldId, expDateFieldId, expEventFieldId) {
	if ($.trim($('#' + agentIdFieldId).val()).length === 0) {
		messageDialog('You must pick an Encumbering Agent from the list.', 'Validation Error');
		return false;
	}
	if ($.trim($('#' + expDateFieldId).val()).length > 0 &&
		$.trim($('#' + expEventFieldId).val()).length > 0) {
		messageDialog('You may specify an expiration date or an expiration event, but not both.', 'Validation Error');
		return false;
	}
	return true;
}

/**
 * Submits the create or edit encumbrance form via AJAX to
 * encumbrances/component/functions.cfc and handles the response.
 *
 * @param {string} formId      - the ID of the form element.
 * @param {string} method      - the CFC method: 'createEncumbrance' or 'saveEncumbrance'.
 * @param {string} redirectUrl - URL to redirect to on success (empty = stay on page).
 */
function submitEncumbranceForm(formId, method, redirectUrl) {
	var $form = $('#' + formId);
	var params = $form.serializeArray();
	params.push({ name: 'method', value: method });
	params.push({ name: 'returnformat', value: 'json' });
	$('#encumbranceSaveStatus').html(
		'<span class="text-muted">Saving&hellip;</span>'
	);
	$.ajax({
		url: '/encumbrances/component/functions.cfc',
		data: params,
		type: 'post',
		dataType: 'json',
		success: function (resp) {
			if (resp.STATUS === 'ok' || resp.status === 'ok') {
				if (redirectUrl) {
					window.location.href = redirectUrl.replace(
						'{encumbrance_id}',
						resp.ENCUMBRANCE_ID || resp.encumbrance_id || ''
					);
				} else {
					$('#encumbranceSaveStatus').html(
						'<span class="text-success">Saved successfully.</span>'
					);
				}
			} else {
				$('#encumbranceSaveStatus').html(
					'<span class="text-danger">Error: ' +
					$('<div>').text(resp.MESSAGE || resp.message || 'Unknown error.').html() +
					'</span>'
				);
			}
		},
		error: function (jqXHR, textStatus, error) {
			console.error('Save encumbrance error:', error);
			$('#encumbranceSaveStatus').html(
				'<span class="text-danger">Error saving encumbrance. Please try again.</span>'
			);
		}
	});
}

/* ============================================================
 * View page (/encumbrances/viewEncumbrance.cfm)
 *
 * The view page uses a Bootstrap tab panel with one tab per encumbered
 * object type.  Currently only the "Specimens" tab is active; the
 * "Localities" tab is a stub that will become functional when the
 * locality_encumbrance junction table is implemented.
 *
 * TODO: locality_encumbrance — when that feature is implemented, remove the
 * "not yet implemented" placeholder from the Localities tab and ensure that
 * loadEncumberedObjects('locality') calls getEncumberedObjectsHtml with
 * targetType='locality'.  No JS changes beyond that should be needed because
 * loadEncumberedObjects is already parameterised by targetType.
 * ============================================================ */

/**
 * Loads encumbered objects of a given type into the appropriate tab panel by
 * calling getEncumberedObjectsHtml on encumbrances/component/functions.cfc.
 *
 * @param {string} encumbranceId - the encumbrance_id to look up.
 * @param {string} targetType    - the object type: 'specimen' (default), 'locality' (stub),
 *                                 or a future type like 'media', 'agent', 'transaction'.
 */
function loadEncumberedObjects(encumbranceId, targetType) {
	var containerId = '#encumbered-' + targetType + '-container';
	$(containerId).html('<p class="text-muted">Loading&hellip;</p>');
	$.ajax({
		url: '/encumbrances/component/functions.cfc',
		data: {
			method: 'getEncumberedObjectsHtml',
			returnformat: 'plain',
			encumbrance_id: encumbranceId,
			targetType: targetType
		},
		type: 'get',
		success: function (data) {
			$(containerId).html(data);
		},
		error: function (jqXHR, textStatus, error) {
			console.error('loadEncumberedObjects error (type=' + targetType + '):', error);
			$(containerId).html(
				'<p class="text-danger">Unable to load ' + targetType + ' list. Please try again.</p>'
			);
		}
	});
}

/* ============================================================
 * Edit page (/encumbrances/Encumbrance.cfm?action=edit)
 * ============================================================ */

/**
 * Asks the user to confirm deletion of the currently-displayed encumbrance,
 * then calls deleteEncumbrance on encumbrances/component/functions.cfc via AJAX.
 * On success, redirects to the encumbrance search page.
 *
 * @param {string} encumbranceId - the ID of the encumbrance to delete.
 */
function confirmDeleteEncumbranceFromEditPage(encumbranceId) {
	confirmDialog('Delete this encumbrance? This cannot be undone.', 'Delete Encumbrance?', function() {
		$.ajax({
			url: '/encumbrances/component/functions.cfc',
			data: {
				method: 'deleteEncumbrance',
				returnformat: 'json',
				encumbrance_id: encumbranceId
			},
			type: 'post',
			dataType: 'json',
			success: function (resp) {
				if (resp.STATUS === 'ok' || resp.status === 'ok') {
					window.location.href = '/encumbrances/Encumbrances.cfm';
				} else if (resp.STATUS === 'blocked' || resp.status === 'blocked') {
					messageDialog('Cannot delete: ' + (resp.MESSAGE || resp.message), 'Cannot Delete');
				} else {
					messageDialog('Error deleting encumbrance: ' + (resp.MESSAGE || resp.message || 'Unknown error.'), 'Error');
				}
			},
			error: function (jqXHR, textStatus, error) {
				console.error('Delete encumbrance (edit page) error:', error);
				messageDialog('Error deleting encumbrance. Please try again.', 'Error');
			}
		});
	});
}

/* ============================================================
 * Search form autocompletes (/encumbrances/Encumbrances.cfm)
 * ============================================================ */

/**
 * Attaches a jQuery UI autocomplete to the encumbrance-name search input.
 * Queries getEncumbranceNameAutocomplete in encumbrances/component/search.cfc.
 *
 * @param {string} fieldId - the id of the text input (without leading #).
 */
function makeEncumbranceNameAutocomplete(fieldId) {
	$('#' + fieldId).autocomplete({
		source: function (request, response) {
			$.ajax({
				url: '/encumbrances/component/search.cfc',
				data: { term: request.term, method: 'getEncumbranceNameAutocomplete' },
				dataType: 'json',
				success: function (data) { response(data); },
				error: function (jqXHR, textStatus, error) {
					console.error('Encumbrance name autocomplete error:', error);
					messageDialog('Unable to load encumbrance name suggestions. Please try again.', 'Error');
				}
			});
		},
		minLength: 2
	});
}

/**
 * Attaches a jQuery UI autocomplete to the expiration-event search input.
 * Queries getExpirationEventAutocomplete in encumbrances/component/search.cfc.
 * Includes a special "by date (no event)" option that sets the field value to
 * "NULL"; the search CFC translates this sentinel to IS NULL in the query.
 *
 * @param {string} fieldId - the id of the text input (without leading #).
 */
function makeExpirationEventAutocomplete(fieldId) {
	$('#' + fieldId).autocomplete({
		source: function (request, response) {
			$.ajax({
				url: '/encumbrances/component/search.cfc',
				data: { term: request.term, method: 'getExpirationEventAutocomplete' },
				dataType: 'json',
				success: function (data) { response(data); },
				error: function (jqXHR, textStatus, error) {
					console.error('Expiration event autocomplete error:', error);
					messageDialog('Unable to load expiration event suggestions. Please try again.', 'Error');
				}
			});
		},
		select: function (event, result) {
			event.preventDefault();
			$('#' + fieldId).val(result.item.value);
		},
		minLength: 0
	}).autocomplete('instance')._renderItem = function (ul, item) {
		return $('<li>').append('<span>' + item.label + '</span>').appendTo(ul);
	};
	// Open the autocomplete on focus to show all options (including "by date")
	$('#' + fieldId).on('focus', function () {
		$(this).autocomplete('search', $(this).val());
	});
}
