/** containers/js/containers.js

Scripts supporting display of the the MCZbase container heirarchy.

See /containers/Containers.cfm for an overview of the functions 
included herein and how they are intended to be used in the 
container hierarchy tree and leaf browser.

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

/** Make a paired hidden container_id and text container control into an autocomplete container picker that displays meta 
 *  on picklist and value on selection.
 *  @param nameControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected container_id (without a leading # selector).
 *  @param clear, optional, default false, set to true for data entry controls to clear both controls when change
 *   is made other than selection from picklist.
 */
function makeContainerAutocompleteMeta(nameControl, idControl, clear=false) {
	console.log("Element ["+nameControl+"] exists:", $('#'+nameControl).length > 0);
	$('#'+nameControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/containers/component/search.cfc",
				data: { term: request.term, method: 'getContainerAutocompleteMeta' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"looking up containers for an autocomplete");
				}
			})
		},
		select: function (event, result) {
			$('#'+idControl).val(result.item.id);
		},
		change: function(event,ui) { 
			if(!ui.item && clear){
				// handle a change that isn't a selection from the pick list, clear both controls.
				$('#'+idControl).val("");
				$('#'+nameControl).val("");
			} else if(!ui.item && !clear){
				// support use with searches
				// handle a change that isn't a selection from the pick list, clear just the id control.
				$('#'+idControl).val("");
			}
		},
		minLength: 3
	});
	// Set the custom render item after autocomplete is initialized
   $('#'+nameControl).autocomplete("instance")._renderItem = function(ul, item) {
      // override to display meta "matched name * (preferred name)" instead of value in picklist.
      return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
   };

};

/** Make a paired hidden container_id and text container control into an autocomplete container picker that displays meta 
 *  on picklist and value on selection, limiting matches to non-collection object containers.
 *  @param nameControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected container_id (without a leading # selector).
 *  @param clear, optional, default false, set to true for data entry controls to clear both controls when change
 *   is made other than selection from picklist.
 */
function makeContainerAutocompleteMetaExcludeCO(nameControl, idControl, clear=false) { 
	console.log("Element ["+nameControl+"] exists:", $('#'+nameControl).length > 0);
	$('#'+nameControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/containers/component/search.cfc",
				data: { 
					term: request.term, 
					exclude_coll_objects: 'true',
					method: 'getContainerAutocompleteMeta' 
				},
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"looking up containers for an autocomplete");
				}
			})
		},
		select: function (event, result) {
			$('#'+idControl).val(result.item.id);
		},
		change: function(event,ui) { 
			if(!ui.item && clear){
				// handle a change that isn't a selection from the pick list, clear both controls.
				$('#'+idControl).val("");
				$('#'+nameControl).val("");
			} else if(!ui.item && !clear){
				// support use with searches
				// handle a change that isn't a selection from the pick list, clear just the id control.
				$('#'+idControl).val("");
			}
		},
		minLength: 3
	});
	// Set the custom render item after autocomplete is initialized
	$('#'	+nameControl).autocomplete("instance")._renderItem = function(ul, item) {
		// override to display meta "matched name * (preferred name)" instead of value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};

/** Make a paired hidden container_id and text container control with limits into an autocomplete container picker that displays meta 
 *  on picklist and value on selection.
 *  @param nameControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected container_id (without a leading # selector).
 *  @param typeControl the id of a select/input that provides an optional container_type filter.
 *  @param ancestorControl the id of a hidden input that provides an optional ancestor container_id filter.
 *  @param labelContainsControl the id of an optional text input for label substring filtering.
 *  @param descriptionContainsControl the id of an optional text input for description substring filtering.
 *  @param clear, optional, default false, set to true for data entry controls to clear both controls when change
 *   is made other than selection from picklist.
 */
function makeContainerAutocompleteLimitedMeta(nameControl, idControl, typeControl, ancestorControl, labelContainsControl, descriptionContainsControl, clear=false) {
	if (typeof labelContainsControl === 'boolean') {
		clear = labelContainsControl;
		labelContainsControl = '';
		descriptionContainsControl = '';
	} else if (typeof descriptionContainsControl === 'boolean') {
		clear = descriptionContainsControl;
		descriptionContainsControl = '';
	}
	labelContainsControl = labelContainsControl || '';
	descriptionContainsControl = descriptionContainsControl || '';
	console.log("Element ["+nameControl+"] exists:", $('#'+nameControl).length > 0);
	$('#'+nameControl).autocomplete({
		source: function (request, response) { 
			var labelContainsValue = '';
			var descriptionContainsValue = '';
			if (labelContainsControl && $('#' + labelContainsControl).length > 0) {
				labelContainsValue = $('#' + labelContainsControl).val();
			}
			if (descriptionContainsControl && $('#' + descriptionContainsControl).length > 0) {
				descriptionContainsValue = $('#' + descriptionContainsControl).val();
			}
			$.ajax({
				url: "/containers/component/search.cfc",
				data: { 
					term: request.term, 
					type: $('#'+typeControl).val(),
					ancestor_container_id: $('#'+ancestorControl).val(),
					label_contains: labelContainsValue,
					description_contains: descriptionContainsValue,
					method: 'getContainerAutocompleteLimited' 
				},
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"looking up containers for an autocomplete");
				}
			})
		},
		select: function (event, result) {
			$('#'+idControl).val(result.item.id);
		},
		change: function(event,ui) { 
			if(!ui.item && clear){
				// handle a change that isn't a selection from the pick list, clear both controls.
				$('#'+idControl).val("");
				$('#'+nameControl).val("");
			} else if(!ui.item && !clear){
				// support use with searches
				// handle a change that isn't a selection from the pick list, clear just the id control.
				$('#'+idControl).val("");
			}
		},
		minLength: 3
	});
	// Set the custom render item after autocomplete is initialized
   $('#'+nameControl).autocomplete("instance")._renderItem = function(ul, item) {
      // override to display meta "matched name * (preferred name)" instead of value in picklist.
      return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
   };

};

/**
 * Fallback copy of ctcontainer_type role metadata. The live values are loaded from
 * functions.cfc?method=getContainerTypeMetadata and replace this map at runtime.
 */
var FALLBACK_CONTAINER_TYPE_METADATA = {
	'collection object': { role: 'leaf', expects_leaf_child_count: 0 },
	'cryovial': { role: 'proxy', expects_leaf_child_count: 1 },
	'pin': { role: 'proxy', expects_leaf_child_count: 1 },
	'slide': { role: 'proxy', expects_leaf_child_count: 1 },
	'envelope': { role: 'proxy', expects_leaf_child_count: 1 },
	'glass vial': { role: 'proxy', expects_leaf_child_count: 1 },
	'jar': { role: 'leafbearer', expects_leaf_child_count: 2 },
	'compartment': { role: 'leafbearer', expects_leaf_child_count: 2 },
	'tank': { role: 'leafbearer', expects_leaf_child_count: 2 },
	'institution': { role: 'structural', expects_leaf_child_count: 0 },
	'campus': { role: 'structural', expects_leaf_child_count: 0 },
	'cryovat': { role: 'structural', expects_leaf_child_count: 0 },
	'building': { role: 'structural', expects_leaf_child_count: 0 },
	'floor': { role: 'structural', expects_leaf_child_count: 2 },
	'room': { role: 'structural', expects_leaf_child_count: 2 },
	'freezer': { role: 'structural', expects_leaf_child_count: 2 },
	'freezer rack': { role: 'structural', expects_leaf_child_count: 0 },
	'freezer box': { role: 'structural', expects_leaf_child_count: 2 },
	'grouping': { role: 'structural', expects_leaf_child_count: 2 },
	'set': { role: 'structural', expects_leaf_child_count: 2 },
	'fixture': { role: 'structural', expects_leaf_child_count: 2 },
	'rack slot': { role: 'structural', expects_leaf_child_count: 0 },
	'position': { role: 'structural', expects_leaf_child_count: 2 }
};
var containerTypeMetadataByType = $.extend(true, {}, FALLBACK_CONTAINER_TYPE_METADATA);
var containerTypeMetadataLoaded = false;
var containerTypeMetadataLoading = false;
var containerTypeMetadataCallbacks = [];
var SINGLE_OCCUPANT_TYPES = [];

/** Default page size for container search results and leaf browser. */
var CONTAINER_PAGE_SIZE = 50;

/** Whether the current session can use edit affordances (Edit, Create Child) rendered by this
 * file's search/browse builder functions -- false unless the including page overrides it after
 * computing its own manage_container check server-side (only Containers.cfm does, today). */
var canEditContainers = false;

/** Maximum description length (characters) shown in search result rows. */
var MAX_DESCRIPTION_LENGTH = 80;

/** Lowercased trigger-match message for locked-position placement blocks. */
var LOCKED_PLACEMENT_BLOCK_MESSAGE_LOWER = 'this position is locked and cannot be moved.';

/** Wildcard token used to force opening full autocomplete suggestions with active filters. */
var AUTOCOMPLETE_OPEN_WILDCARD = '%%%';

/** Shared container-type keys used in search/browse action gating. */
var ROOT_INSTITUTION_CONTAINER_TYPE = 'institution';
var COLLECTION_OBJECT_CONTAINER_TYPE = 'collection object';
var ROOT_PARENT_CONTAINER_ID = 0;

/**
 * Human-readable labels for the A/B/AB shape classification used internally.
 * A  - container holds only structural (sub-container) children (expected for structural type).  
 * B  - container holds one to a large number of collection objects directly (no structural children).
 * 	expected for proxy and leafbearer types, but may also occur for structural types in some cases.
 * AB - container holds both structural children and collection objects directly (mixed).
 * 	may occur for structural types in some cases, but is not expected for proxy or leafbearer types.
 * These are observed classifications, and may or may not match container types.
 */
var SHAPE_LABELS = { A: 'Structural', B: 'Object-bearing', AB: 'Mixed' };

/**
 * Normalizes a container type string for case-insensitive metadata lookups.
 * @param {string} containerType - the container type label to normalize.
 * @returns {string} lowercase type key, or an empty string when no type was provided.
 */
function normalizeContainerTypeKey(containerType) {
	return (containerType || '').toLowerCase();
}

/**
 * Rebuilds the cached list of single-occupant container types from the active metadata map.
 */
function rebuildSingleOccupantTypes() {
	SINGLE_OCCUPANT_TYPES = [];
	$.each(containerTypeMetadataByType, function(containerType, meta) {
		if (parseInt(meta.expects_leaf_child_count, 10) === 1) {
			SINGLE_OCCUPANT_TYPES.push(containerType);
		}
	});
}

/**
 * Opens the shared rich picker dialog, prefiltered to leaf containers, and places a selected leaf into a parent container.
 * @param {number|string} parentContainerId - destination parent container_id.
 * @param {string} parentDisplayLabel - display label for dialog title and success feedback.
 * @param {string} institutionAcronym - optional institution acronym used to scope picker search.
 * @param {string} feedbackId - optional feedback output element id.
 * @param {string} contentsTargetDivId - optional contents target to reload after successful placement.
 * @returns {void}
 */
function openPlaceLeafIntoContainerDialog(parentContainerId, parentDisplayLabel, institutionAcronym, feedbackId, contentsTargetDivId) {
	var display = parentDisplayLabel || '';
	openContainerPickerDialog({
		mode: 'child',
		dialogTitle: 'Place Leaf into ' + (display || 'Container'),
		parentContainerIdForValidation: parentContainerId,
		pickLeaves: true,
		institutionAcronym: institutionAcronym || '',
		feedbackId: feedbackId,
		onSelect: function(selectedId, selectedLabel, wrapper, controls) {
			$.ajax({
				url: '/containers/component/public.cfc',
				type: 'post',
				dataType: 'json',
				data: {
					method: 'moveContainerById',
					returnformat: 'json',
					child_container_id: selectedId,
					parent_container_id: parentContainerId
				},
				success: function(result) {
					if (result && result.status === 'moved') {
						if (feedbackId) {
							setFeedbackControlState(feedbackId, 'saved', 'Container placed.');
						}
						wrapper.dialog('close');
						if (contentsTargetDivId) {
							loadContainerContentsSection(parentContainerId, contentsTargetDivId, feedbackId);
						}
					} else {
						var message = (result && result.message) ? result.message : 'Unable to place selected container.';
						if (feedbackId) {
							setFeedbackControlState(feedbackId, 'error', message);
						}
						$('#' + controls.validationControlId).html($('<div class="alert alert-danger py-1 px-2 mb-0"></div>').text(message));
					}
				},
				error: function(jqXHR, textStatus, error) {
					handleFail(jqXHR, textStatus, error, 'placing leaf container');
				}
			});
		}
	});
}

/** function applyContainerTypeMetadata(data) 
 * Applies the container type metadata returned from getContainerTypeMetadata to the 
 * containerTypeMetadataByType map, replacing the fallback values.  Rebuilds the
 * SINGLE_OCCUPANT_TYPES array from the new metadata.	
 * @param {Object} data - response from getContainerTypeMetadata, expected to have a "byType" property.
 */
function applyContainerTypeMetadata(data) {
	containerTypeMetadataByType = $.extend(true, {}, FALLBACK_CONTAINER_TYPE_METADATA);
	if (data && data.byType) {
		$.each(data.byType, function(containerType, meta) {
			containerTypeMetadataByType[normalizeContainerTypeKey(containerType)] = {
				role: (meta.role || '').toLowerCase() || 'structural',
				expects_leaf_child_count: parseInt(meta.expects_leaf_child_count, 10) || 0
			};
		});
	}
	rebuildSingleOccupantTypes();
}

/** function flushContainerTypeMetadataCallbacks()
 * Invokes all callbacks that were queued while container type metadata was loading.
 */
function flushContainerTypeMetadataCallbacks() {
	var callbacks = containerTypeMetadataCallbacks.slice(0);
	containerTypeMetadataCallbacks = [];
	$.each(callbacks, function(i, callback) {
		if (typeof callback === 'function') {
			callback();
		}
	});
}

/** on page load, rebuild the SINGLE_OCCUPANT_TYPES array from the fallback metadata. */
rebuildSingleOccupantTypes();

/** function ensureContainerTypeMetadata(callback)
 * Ensures that container type metadata is loaded from the server.  If it is already
 * loaded, the callback is invoked immediately.  If it is still loading, the callback
 * is queued to be invoked when loading completes.  If it is not yet loaded, an AJAX
 * request is made to load it, and the callback is queued to be invoked when loading completes.
 * @param {function} callback - function to invoke when container type metadata is available.
 */
function ensureContainerTypeMetadata(callback) {
	if (typeof callback === 'function') {
		containerTypeMetadataCallbacks.push(callback);
	}
	if (containerTypeMetadataLoaded) {
		flushContainerTypeMetadataCallbacks();
		return;
	}
	if (containerTypeMetadataLoading) {
		return;
	}
	containerTypeMetadataLoading = true;
	$.ajax({
		url: '/containers/component/public.cfc',
		data: { method: 'getContainerTypeMetadata' },
		dataType: 'json',
		success: function(data) {
			containerTypeMetadataLoading = false;
			containerTypeMetadataLoaded = true;
			applyContainerTypeMetadata(data || {});
			flushContainerTypeMetadataCallbacks();
		},
		error: function(jqXHR, textStatus, error) {
			containerTypeMetadataLoading = false;
			containerTypeMetadataLoaded = true;
			applyContainerTypeMetadata({});
			flushContainerTypeMetadataCallbacks();
			handleFail(jqXHR, textStatus, error, 'loading container type metadata');
		}
	});
}


/**
 * Returns a URL to the fixed specimen search pre-filtered by container barcode.
 * Opens Specimens.cfm in fixed-search mode for all specimens in containers
 * that are hierarchically under the container with the given barcode.
 * Returns empty string when barcode is empty.
 * @param {string} barcode - the container barcode to search within.
 * @returns {string} URL string with barcode prefixed with = for an exact match, or '' when barcode is falsy.
 */
function specimenSearchUrl(barcode) {
	if (!barcode) { return ''; }
	return '/Specimens.cfm?action=fixedSearch&execute=true&root_container_barcode=%3D' + encodeURIComponent(barcode);
}

/** 
 * Returns a URL to the allContainerLeafNodes.cfm page for the given container_id.
 * URL is for a page that lists all collection objects that are descendants of the 
 * given container, link includes limitation to initially show only immediate children 
 * of the container.
 * @param {number} container_id - the container_id to list leaf nodes for.
 * @returns {string} URL string to allContainerLeafNodes.cfm with container_id and show=immediate, or '' when container_id is empty.
 */
function allContainerLeafNodesUrl(container_id) {
	if (!container_id) { return ''; }
	return '/containers/allContainerLeafNodes.cfm?container_id=' + encodeURIComponent(container_id) + '&show=immediate';
}

/**
 * Normalizes parent placement context from a container search result row.
 * @param {Object} row - one row from searchContainers.
 * @returns {Object} placement flags describing whether the container is rooted
 *  directly under parent_container_id = 0 or directly under an institution node.
 */
function getSearchResultParentInfo(row) {
	var rawParentContainerId = row.parent_container_id;
	var hasParentContainerId = rawParentContainerId !== null && typeof rawParentContainerId !== 'undefined';
	var parentContainerId = hasParentContainerId ? parseInt(rawParentContainerId, 10) : null;
	var parentContainerType = (row.parent_container_type || '').toLowerCase();
	return {
		hasRootParent: hasParentContainerId && !isNaN(parentContainerId) && parentContainerId === ROOT_PARENT_CONTAINER_ID,
		hasInstitutionParent: parentContainerType === ROOT_INSTITUTION_CONTAINER_TYPE
	};
}

/**
 * Builds and returns a jQuery element for the Specimens button/link.
 * When barcode is absent or hasLeafDescendants is 0, returns null.
 * When directLeafChildren > 0 the node certainly contains specimens: returns
 * a plain anchor link that opens immediately.
 * Otherwise (only structural children present), returns a button that triggers
 * a lazy AJAX check via checkHasLeafDescendants on first click; if no specimen
 * descendants exist the button is updated to a disabled "No Specimens" label.
 * @param {number} nodeId - container_id of the node.
 * @param {string} barcode - node barcode for the specimen search URL.
 * @param {number} directLeafChildren - count of direct collection-object children.
 * @param {number} hasLeafDescendants - 1 when node has any children (fast proxy), 0 if empty.
 * @returns {jQuery|null} jQuery element to append to the node row, or null.
 */
function buildSpecimensButton(nodeId, barcode, directLeafChildren, hasLeafDescendants) {
	if (!hasLeafDescendants || !barcode) { return null; }
	var specUrl = specimenSearchUrl(barcode);
	if (directLeafChildren > 0) {
		/* Direct collection object children confirmed: link opens without a pre-check */
		return $('<a class="btn btn-xs btn-outline-info ml-1" target="_blank" rel="noopener noreferrer"></a>')
			.attr('href', specUrl)
			.attr('title', 'Search for specimens in this container')
			.text('Specimens');
	}
	/* Only structural children: lazy check for specimen descendants on first click */
	var specBtn = $('<button class="btn btn-xs btn-outline-info ml-1"></button>').text('Specimens');
	specBtn.on('click', function() {
		var btn = $(this);
		if (btn.data('checked')) {
			window.open(specUrl, '_blank', 'noopener,noreferrer');
			return;
		}
		btn.prop('disabled', true).text('Checking\u2026');
		$.ajax({
			url: '/containers/component/public.cfc',
			data: { method: 'checkHasLeafDescendants', container_id: nodeId },
			dataType: 'json',
			success: function(data) {
				btn.prop('disabled', false);
				if (parseInt(data.has_leaf_descendants, 10) > 0) {
					btn.data('checked', true).text('Specimens');
					window.open(specUrl, '_blank', 'noopener,noreferrer');
				} else {
					btn.text('No Specimens')
						.removeClass('btn-outline-info')
						.addClass('btn-outline-secondary')
						.prop('disabled', true);
				}
			},
			error: function(jqXHR, textStatus, error) {
				btn.prop('disabled', false).text('Specimens');
				handleFail(jqXHR, textStatus, error, 'checking for specimen descendants');
			}
		});
	});
	return specBtn;
}

/** Formats a container display string from barcode and label.  
 * If both are present and different, returns "barcode (label)".  
 * If only one is present, returns that.  If neither is present, returns "(unknown container)".
 * @param {string} barcode - the container barcode.
 * @param {string} label - the container label.
 * @returns {string} formatted display string.
*/
function formatContainerDisplay(barcode, label) {
	var b = barcode || '';
	var l = label || '';
	if (b && l && b !== l) {
		return b + ' (' + l + ')';
	}
	return b || l || '(unknown container)';
}


var TREE_ACTION_SPACING_CLASS = 'ml-1';
var TABLE_ACTION_SPACING_CLASS = 'mr-1 mb-1';

/** Builds a CSS class string for a container action button, combining a base class with an optional spacing class.
 * @param {string} baseClass - the base CSS class for the button (e.g., 'btn btn-xs btn-outline-primary').
 * @param {string} spacingClass - optional additional CSS class for spacing (e.g., 'ml-1').
 * @returns {string} combined CSS class string.
 */
function buildContainerActionClass(baseClass, spacingClass) {
	return baseClass + (spacingClass ? ' ' + spacingClass : '');
}

/** Builds a jQuery button element for the "Details" action in the container tree.
 * @param {number} containerId - the container_id to load details for.
 * @param {string} displayName - optional display name to append to the dialog title.
 * @param {string} feedbackId - optional id of the feedback element to use for status messages.
 * @param {string} spacingClass - optional additional CSS class for spacing (e.g., 'ml-1').
 * @returns {jQuery} jQuery button element with click handler to open the details dialog.
 */
function buildContainerDetailsButton(containerId, displayName, feedbackId, spacingClass) {
	return $('<button type="button"></button>')
		.addClass(buildContainerActionClass('btn btn-xs btn-outline-info', spacingClass || TREE_ACTION_SPACING_CLASS))
		.text('Details')
		.on('click', function() {
			openContainerDetailsDialog(containerId, displayName, feedbackId, false);
		});
}

/**
 * Abandons the current search results (if any) and returns to the default container
 * hierarchy view, clearing the subordinate leaf panel.
 * @param {string} browsePanel - the id of the div to render the tree into (without leading #).
 * @param {string} leafPanel - the id of the div for the leaf browser panel (without leading #).
 * @param {string} feedbackEl - the id of the output element for status feedback (without leading #).
 */
function browseContainerHierarchy(browsePanel, leafPanel, feedbackEl) {
	initContainerBrowse(browsePanel, leafPanel, feedbackEl);
	$('#' + leafPanel).addClass('d-none').html('');
}

/**
 * Initializes the container browse panel.  Calls getTopLevelBrowse to retrieve
 * institution nodes (pre-opened to campus level) plus counts of orphaned nodes,
 * then delegates rendering to renderTopLevelBrowse.
 * @param {string} browsePanel - the id of the div to render the tree into (without leading #).
 * @param {string} leafPanel - the id of the div for the leaf browser panel (without leading #).
 * @param {string} feedbackEl - the id of the output element for status feedback (without leading #).
 */
function initContainerBrowse(browsePanel, leafPanel, feedbackEl) {
	$(document).ready(function() {
		ensureContainerTypeMetadata(function() {
			$('#containerBrowseContext').text('Container Hierarchy');
			$('#' + browsePanel).html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading...</div>');
			$.ajax({
				url: '/containers/component/public.cfc',
				data: { method: 'getTopLevelBrowse' },
				dataType: 'json',
				success: function(data) {
					renderTopLevelBrowse(data, browsePanel, leafPanel, feedbackEl);
				},
				error: function(jqXHR, textStatus, error) {
					handleFail(jqXHR, textStatus, error, 'loading top-level container browse');
				}
			});
		});
	});
}


/**
 * Loads the direct structural children of containerId into targetDivId via
 * an AJAX call to functions.cfc?method=getDirectStructuralChildren.
 * Shows a loading spinner while loading; on success calls renderTreeNodes.
 * @param {number} containerId - the container_id whose children to load.
 * @param {string} targetDivId - the id of the div to render results into (without leading #).
 * @param {string} feedbackId - the id of the output element for status feedback (without leading #).
 */
function loadContainerNode(containerId, targetDivId, feedbackId, parentContainerType) {
	$('#' + targetDivId).html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading...</div>');
	$.ajax({
		url: '/containers/component/public.cfc',
		data: { method: 'getDirectStructuralChildren', container_id: containerId },
		dataType: 'json',
		success: function(data) {
			renderTreeNodes(data, targetDivId, feedbackId, false, parentContainerType, containerId);
		},
		error: function(jqXHR, textStatus, error) {
			handleFail(jqXHR, textStatus, error, 'loading container children');
		}
	});
}


/**
 * Shows the breadcrumb path for a given container in both the containerBrowseContext
 * paragraph and prominently in the browse panel.
 * Calls getContainerBreadcrumb in search.cfc and renders the full path from root to container.
 * @param {number} containerId - the container_id to show the breadcrumb for.
 * @param {string} feedbackId - the id of the feedback output element (without leading #).
 * @param {string} [browsePanel] - optional id of the browse panel div (without leading #).
 *   Defaults to 'containerBrowsePanel'.
 */
function showContainerBreadcrumb(containerId, feedbackId, browsePanel) {
	var targetPanel = browsePanel || 'containerBrowsePanel';
	$('#' + targetPanel).html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading location\u2026</div>');
	$.ajax({
		url: '/containers/component/search.cfc',
		data: { method: 'getContainerBreadcrumb', container_id: containerId },
		dataType: 'json',
		success: function(data) {
			$('#containerBrowseContext').text('Location');

			var breadcrumbDiv = $('<ol class="breadcrumb bg-light border rounded p-2 my-2 flex-wrap"></ol>');
			var placementBadgeId = 'placementBadgeInBreadcrumb-' + targetPanel;
			var targetNode = (data && data.length > 0) ? data[data.length - 1] : {};
			var parentContainerId = parseInt(targetNode.parent_container_id, 10);
			if (isNaN(parentContainerId)) {
				parentContainerId = 0;
			}
			$.each(data, function(i, node) {
				var display = formatContainerDisplay(node.barcode, node.label);
				var crumbText = node.container_type + ': ' + display;
				var crumbLi = $('<li class="breadcrumb-item"></li>');
				if (i === data.length - 1) {
					crumbLi.addClass('active').attr('aria-current', 'page').text(crumbText);
					crumbLi.append($('<span class="ml-1"></span>').attr('id', placementBadgeId));
				} else {
					crumbLi.text(crumbText);
				}
				breadcrumbDiv.append(crumbLi);
			});
			$('#' + targetPanel).html(breadcrumbDiv);
			loadPlacementWarningBadge(containerId, parentContainerId, placementBadgeId);
			$('#' + feedbackId).text('');
		},
		error: function(jqXHR, textStatus, error) {
			handleFail(jqXHR, textStatus, error, 'loading container breadcrumb');
		}
	});
}

/**
 * Opens the full container hierarchy tree, expands the path from the root down to
 * containerId, and highlights the target node.  Used by the Explore button in search
 * results to give the full tree context for a found container.
 * @param {number} containerId - the container_id to explore.
 * @param {string} displayName - human-readable name for the container (for context label).
 * @param {string} browsePanel - the id of the browse panel div (without leading #).
 * @param {string} leafPanel - the id of the leaf panel div (without leading #).
 * @param {string} feedbackId - the id of the feedback output element (without leading #).
 */
function exploreContainerInTree(containerId, displayName, browsePanel, leafPanel, feedbackId) {
	$('#' + browsePanel).html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading\u2026</div>');
	$('#' + leafPanel).addClass('d-none').html('');
	$.ajax({
		url: '/containers/component/search.cfc',
		data: { method: 'getContainerBreadcrumb', container_id: containerId },
		dataType: 'json',
		success: function(breadcrumbs) {
			var browseContext = $('#containerBrowseContext');
			browseContext.empty().append($('<span></span>').text('Exploring: ' + displayName));
			if (!breadcrumbs || breadcrumbs.length === 0) {
				renderUnplacedContainerNode(containerId, breadcrumbs, browsePanel, feedbackId);
				return;
			}
			$.ajax({
				url: '/containers/component/public.cfc',
				data: { method: 'getTopLevelBrowse' },
				dataType: 'json',
				success: function(data) {
					var rootNodeId = breadcrumbs[0].container_id;
					var expandExplorePath = function() {
						expandBreadcrumbPath(breadcrumbs, 0, feedbackId, containerId);
					};
					var showViewLocation = function() {
						browseContext.find('.container-view-location-link').remove();
						browseContext.append(
							$('<a href="#" class="ml-2 container-view-location-link">[View location]</a>').on('click', function(e) {
								if ($('#ctree-children-' + rootNodeId).closest('#ctree-orphan-structural-panel').length > 0) {
									ensureStructuralOrphanPanelVisible(feedbackId, function(foundPanel) {
										if (foundPanel) {
											expandExplorePath();
										}
									});
								} else {
									expandExplorePath();
								}
								e.preventDefault();
							})
						);
					};
					renderTopLevelBrowse(data, browsePanel, leafPanel, feedbackId);
					var expandAndShowLocation = function() {
						expandExplorePath();
						showViewLocation();
					};
					if ($('#ctree-children-' + rootNodeId).length > 0) {
						expandAndShowLocation();
						return;
					}
					ensureStructuralOrphanPanelVisible(feedbackId, function(foundPanel) {
						if (foundPanel && $('#ctree-children-' + rootNodeId).length > 0) {
							expandAndShowLocation();
							return;
						}
						renderUnplacedContainerNode(containerId, breadcrumbs, browsePanel, feedbackId);
					});
				},
				error: function(jqXHR, textStatus, error) {
					handleFail(jqXHR, textStatus, error, 'loading top-level container browse for exploration');
				}
			});
		},
		error: function(jqXHR, textStatus, error) {
			handleFail(jqXHR, textStatus, error, 'loading container breadcrumb for exploration');
		}
	});
}

/**
 * Renders an unplaced container (one without a campus ancestor) as a standalone
 * expandable node in the browse panel.  Fetches child counts via getNodeShape, then
 * uses renderTreeNodes to display the container as a single top-level tree node that
 * can be expanded by the user.
 * @param {number} containerId - the container_id to render.
 * @param {Array} breadcrumbs - breadcrumb path from getContainerBreadcrumb; the last
 *   element is the target container itself.
 * @param {string} browsePanel - the id of the browse panel div (without leading #).
 * @param {string} feedbackId - the id of the feedback output element (without leading #).
 */
function renderUnplacedContainerNode(containerId, breadcrumbs, browsePanel, feedbackId) {
	var containerNode = (breadcrumbs && breadcrumbs.length > 0)
		? breadcrumbs[breadcrumbs.length - 1]
		: { container_id: containerId, container_type: '', label: '', barcode: '' };
	$.ajax({
		url: '/containers/component/public.cfc',
		data: { method: 'getNodeShape', container_id: containerId },
		dataType: 'json',
		success: function(shapeData) {
			var structKids = parseInt(shapeData.direct_structural_children, 10) || 0;
			var leafKids = parseInt(shapeData.direct_leaf_children, 10) || 0;
			var nodeArr = [{
				container_id: containerId,
				container_type: containerNode.container_type || '',
				label: containerNode.label || '',
				barcode: containerNode.barcode || '',
				description: '',
				direct_structural_children: structKids,
				direct_leaf_children: leafKids,
				has_leaf_descendants: (structKids > 0 || leafKids > 0) ? 1 : 0,
				single_child_barcode: '',
				single_child_label: ''
			}];
			var targetDivId = 'ctree-standalone-' + containerId;
			var wrapper = $('<div></div>');
			wrapper.append($('<div></div>').attr('id', targetDivId));
			$('#' + browsePanel).html(wrapper);
			renderTreeNodes(nodeArr, targetDivId, feedbackId);
			/* Highlight the target node after a brief delay to allow renderTreeNodes to complete */
			setTimeout(function() {
				var targetLi = $('#ctree-children-' + containerId).closest('li');
				if (targetLi.length === 0) {
					/* Fallback: find li via toggle when no children ul exists */
					targetLi = $('#ctree-toggle-' + containerId).closest('li');
				}
				clearTargetHighlightState();
				highlightTargetNode(targetLi, containerNode);
			}, 50);
		},
		error: function(jqXHR, textStatus, error) {
			handleFail(jqXHR, textStatus, error, 'loading unplaced container info');
		}
	});
}

/** 
 * Prepends a right-arrow symbol to the target row to indicate it is the selected node.
 * @param {jQuery} targetRow - the jQuery object for the target row to highlight.
 */
function addTargetArrow(targetRow) {
	if (targetRow.find('.tree-node-target-arrow').length > 0) {
		return;
	}
	var arrow = $('<span class="tree-node-target-arrow" aria-hidden="true">\u21d2 </span>');
	var toggleBtn = targetRow.find('.tree-node-toggle').first();
	if (toggleBtn.length) {
		arrow.insertAfter(toggleBtn);
	} else {
		targetRow.prepend(arrow);
	}
}

/**
 * Removes the current highlighted-tree selection state before a new target is marked.
 */
function clearTargetHighlightState() {
	$('.tree-node-target-arrow').remove();
	$('.tree-node-highlighted').removeClass('tree-node-highlighted');
	$('.container-selected-status').remove();
}

/**
 * Highlights one rendered tree node, adds the target arrow, and scrolls it into view.
 * @param {jQuery} targetLi - the tree-node list item to highlight.
 * @param {Object} targetNode - breadcrumb/search metadata for the selected node.
 */
function highlightTargetNode(targetLi, targetNode) {
	if (targetLi.length === 0) {
		return;
	}
	var targetRow = targetLi.children('.tree-node-row');
	var targetLabel = targetRow.find('.tree-node-label').first();
	targetLabel.addClass('tree-node-highlighted');
	addTargetArrow(targetRow);
	if (targetNode) {
		var targetDisplay = formatContainerDisplay(targetNode.barcode, targetNode.label);
		targetLi.prepend($('<span class="sr-only container-selected-status" role="status"></span>').text('Selected container: ' + targetDisplay));
	}
	var el = targetLabel[0];
	if (el) {
		el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
	}
}

/**
 * Checks whether a container is already present in the rendered browse tree.
 * @param {number} containerId - the container_id to look for in the DOM.
 * @returns {boolean} true when the node already exists in the rendered tree.
 */
function isTreeNodeRendered(containerId) {
	return $('#ctree-children-' + containerId).closest('li').length > 0;
}

/**
 * Recursively expands tree nodes along a breadcrumb path, loading children on demand,
 * until the target node is visible and highlighted.
 * Called after the top-level browse has been rendered by renderTopLevelBrowse.
 * @param {Array} breadcrumbs - ordered array of path nodes (root first, target last).
 *   Each element has container_id, container_type, label, barcode.
 * @param {number} index - current position in the breadcrumbs array.
 * @param {string} feedbackId - the id of the feedback output element (without leading #).
 * @param {number} targetId - container_id of the final node to highlight.
 */
function expandBreadcrumbPath(breadcrumbs, index, feedbackId, targetId) {
	if (index === 0) {
		clearTargetHighlightState();
	}
	/* When we reach the last breadcrumb (the target itself), highlight it */
	if (index >= breadcrumbs.length - 1) {
		ensureTreeSectionVisibleForNode(targetId);
		/* The target node's li contains #ctree-children-{targetId} as a descendant */
		var targetLi = $('#ctree-children-' + targetId).closest('li');
		highlightTargetNode(targetLi, breadcrumbs[breadcrumbs.length - 1]);
		return;
	}

	var node = breadcrumbs[index];
	var nodeId = node.container_id;
	ensureTreeSectionVisibleForNode(nodeId);
	var childListIdPrefix = 'ctree-children-';
	var childDivId = childListIdPrefix + nodeId;
	var childDiv = $('#' + childDivId);
	var nextBreadcrumb = breadcrumbs[index + 1];
	var nextNodeId = nextBreadcrumb ? nextBreadcrumb.container_id : null;

	if (childDiv.length === 0) {
		/* Node is not in the DOM — cannot expand further */
		return;
	}

	/* Un-collapse this node's children list */
	childDiv.removeClass('collapse');
	var toggle = $('#ctree-toggle-' + nodeId);
	if (toggle.length > 0) {
		toggle.attr('aria-expanded', 'true');
	}

	if (!nextNodeId) {
		return;
	}

	if (isTreeNodeRendered(nextNodeId)) {
		ensureTreeSectionVisibleForNode(nextNodeId);
		/* The next breadcrumb node is already rendered — proceed to it. */
		expandBreadcrumbPath(breadcrumbs, index + 1, feedbackId, targetId);
		return;
	}

	/* Load missing direct structural children, appending them when some children
	   are already pre-rendered (for example, institution campuses). */
	var existingChildCount = childDiv.children('li').length;
	if (existingChildCount === 0) {
		childDiv.html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading\u2026</div>');
	}
	$.ajax({
		url: '/containers/component/public.cfc',
		data: { method: 'getDirectStructuralChildren', container_id: nodeId },
		dataType: 'json',
		success: function(data) {
			var childNodes = data || [];
			if (existingChildCount > 0) {
				var renderedChildIds = {};
				childDiv.find('li[data-parent-container-id="' + nodeId + '"][data-container-id]').each(function() {
					var renderedId = $(this).attr('data-container-id');
					if (renderedId) {
						renderedChildIds[renderedId] = true;
					}
				});
				childNodes = $.grep(childNodes, function(childNode) {
					return !renderedChildIds[childNode.container_id];
				});
			}
			if (childNodes.length > 0 || existingChildCount === 0) {
				renderTreeNodes(childNodes, childDivId, feedbackId, existingChildCount > 0, node.container_type, nodeId);
			}
			expandBreadcrumbPath(breadcrumbs, index + 1, feedbackId, targetId);
		},
		error: function(jqXHR, textStatus, error) {
			handleFail(jqXHR, textStatus, error, 'loading container children for exploration');
		}
	});
}


/**
 * Submits the container create or edit form via AJAX to
 * containers/component/functions.cfc and handles the response.
 *
 * When method is 'createContainer' and the save succeeds, redirects to
 * viewContainer.cfm?container_id=N (or to redirectUrl if provided).
 * When method is 'saveContainer', stays on page and uses setFeedbackControlState()
 * on feedbackId to report saving/saved/error state.
 *
 * @param {string} formId - the id of the form element.
 * @param {string} method - 'createContainer' or 'saveContainer'.
 * @param {string} feedbackId - the id of the output/element for status feedback (without leading #).
 * @param {string} [redirectUrl] - optional URL to redirect to on create success.
 * @param {string} [breadcrumbFeedbackId] - optional feedback element id for breadcrumb refresh after save.
 * @param {string} [breadcrumbTargetId] - optional target element id for breadcrumb refresh after save.
 */
/**
 * Updates Container.cfm's "Positions" summary box/link/create-prompt after Number of Positions
 * changes, from either a plain Save or the positions-change dialog's Grow/Shrink -- shared so
 * both entry points leave the summary in the same state instead of drifting apart.
 * @param {number|string} containerId - container_id the summary box belongs to.
 * @param {number|string} numberPositions - the container's current declared Number of Positions.
 * @param {boolean} [recordsExist] - whether container_type='position' records already exist for
 *	this container -- false (a plain Save, which can only ever change a still-zero record count,
 *	since saveContainer blocks changing this field at all once real records exist) renders the
 *	"Create N Positions" prompt into #containerPositionsCreateArea; true (Grow/Shrink, where
 *	records already existed beforehand and still do) just updates the summary text/link. Reset
 *	isn't handled here at all -- it reloads the page immediately instead, since it flips whether
 *	records exist to none, which changes this field's own markup (plain input vs. locked display
 *	+ Change button) in a way only the server-rendered page can redraw.
 */
function updateContainerPositionsSummary(containerId, numberPositions, recordsExist) {
	var $positionsSummary = $('#containerPositionsSummary');
	var $positionsLink = $('#containerPositionsLink');
	var $createArea = $('#containerPositionsCreateArea');
	if ($positionsSummary.length === 0 || $positionsLink.length === 0) {
		return;
	}
	var numericNumberPositions = parseInt(numberPositions, 10);
	var numericContainerId = parseInt(containerId, 10);
	if (!isNaN(numericNumberPositions) && numericNumberPositions > 0 && !isNaN(numericContainerId)) {
		var positionWord = numericNumberPositions === 1 ? 'position' : 'positions';
		$positionsSummary.removeClass('d-none');
		if (recordsExist) {
			$positionsLink.attr('href', '/containers/viewContainer.cfm?container_id=' + encodeURIComponent(containerId) + '#containerPositionsHeading_page').removeClass('d-none');
			// the accurate created/occupied counts are only known server-side; this falls back to
			// this generic text rather than the fuller message shown on page load, until the next
			// Save Changes reloads the page (see the pending-reload flag in Container.cfm)
			$('#containerPositionsSummaryText').text('This container declares ' + numericNumberPositions + ' ' + positionWord + '.');
			$createArea.empty();
		} else {
			// no position records exist yet -- nothing for View/Edit Positions to show on
			// viewContainer.cfm, so it stays hidden until Create actually makes some
			$positionsLink.addClass('d-none');
			$('#containerPositionsSummaryText').text('This container declares ' + numericNumberPositions + ' ' + positionWord + ', but none have been created yet.');
			if ($createArea.length) {
				// reload rather than updating the summary in place -- position records now exist,
				// so the Number of Positions field needs to switch to its locked display + Change
				// button, which only the server-rendered markup knows how to do.
				renderCreatePositionsPrompt(numericNumberPositions, 'containerPositionsCreateArea', null, numericContainerId, true, null, function() {
					window.location.reload();
				});
			}
		}
	} else {
		$positionsSummary.addClass('d-none');
		$createArea.empty();
	}
}

/**
 * Applies a Grow/Shrink queued by the "Change Positions" dialog (see openPositionsChangeDialog),
 * then reloads the page -- called from saveContainerForm's success handler once Container.cfm's
 * own regular Save Changes has already gone through, so the queued position-count change and
 * whatever else was just edited land together rather than the position change committing the
 * instant Grow/Shrink is clicked. Shows #containerSavingOverlay for this extra round trip, since
 * it happens after the page's own "Saved." feedback would otherwise already read as done.
 * @param {number|string} containerId - container_id to apply the queued change to.
 * @param {Object} pendingAction - {action: 'grow'|'shrink', params} from openPositionsChangeDialog.
 */
function applyPendingPositionsAction(containerId, pendingAction) {
	var $overlay = $('#containerSavingOverlay');
	$overlay.removeClass('d-none');
	var method = pendingAction.action === 'grow' ? 'growContainerPositions' : 'trimContainerPositions';
	var data = $.extend({ method: method, returnformat: 'json', container_id: containerId }, pendingAction.params);
	var revertPreview = function() {
		var actualValue = $.trim($('#number_positions').val());
		$('#number_positions_display').val(actualValue);
		$('#changePositionsBtn').prop('disabled', false);
		updateContainerPositionsSummary(containerId, actualValue, true);
	};
	$.ajax({
		url: '/containers/component/functions.cfc',
		type: 'post',
		dataType: 'json',
		data: data,
		success: function(result) {
			if (result.status === 'created' || result.status === 'trimmed') {
				window.location.reload();
				return;
			}
			$overlay.addClass('d-none');
			revertPreview();
			messageDialog('Your other changes were saved, but applying the queued position change failed: ' + (result.message || 'Unknown error.') + ' Reopen Change to retry.', 'Error Applying Position Change');
		},
		error: function(jqXHR, textStatus, error) {
			$overlay.addClass('d-none');
			revertPreview();
			handleFail(jqXHR, textStatus, error, 'applying the queued position change');
		}
	});
}

/**
 * Loads Container.cfm's Container Check Log history table.
 * @param {number|string} containerId - container_id whose check history to load.
 */
function loadContainerCheckHistory(containerId) {
	$('#containerCheckHistory').html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading...</div>');
	$.ajax({
		url: '/containers/component/public.cfc',
		data: { method: 'getContainerCheckHistoryHtml', container_id: containerId },
		success: function(html) {
			$('#containerCheckHistory').html(html);
		},
		error: function(jqXHR, textStatus, error) {
			$('#containerCheckHistory').html('<p class="text-danger small mb-0">Unable to load check history.</p>');
			handleFail(jqXHR, textStatus, error, 'loading container check history');
		}
	});
}

/**
 * Logs a container check from Container.cfm's Container Check Log section, then clears the
 * Remark field and refreshes the history table. Checked By is read-only and purely informational
 * on this page -- logContainerCheck (functions.cfc) always resolves the actual logged-in user
 * server-side, so nothing from this field is sent.
 * @param {number|string} containerId - container_id being checked.
 */
function logContainerCheck(containerId) {
	var checkDate = $.trim($('#checkDate').val());
	var checkRemark = $.trim($('#checkRemark').val());
	if (!checkDate) {
		setFeedbackControlState('containerCheckStatus', 'error');
		messageDialog('Check Date is required.', 'Validation Error');
		return;
	}
	setFeedbackControlState('containerCheckStatus', 'saving');
	$.ajax({
		url: '/containers/component/functions.cfc',
		type: 'post',
		dataType: 'json',
		data: {
			method: 'logContainerCheck',
			returnformat: 'json',
			container_id: containerId,
			check_date: checkDate,
			check_remark: checkRemark
		},
		success: function(result) {
			if (result.status === 'logged') {
				setFeedbackControlState('containerCheckStatus', 'saved');
				$('#checkRemark').val('');
				loadContainerCheckHistory(containerId);
			} else {
				setFeedbackControlState('containerCheckStatus', 'error');
				messageDialog('Error: ' + (result.message || 'Unable to log check.'), 'Error Logging Check');
			}
		},
		error: function(jqXHR, textStatus, error) {
			setFeedbackControlState('containerCheckStatus', 'error');
			handleFail(jqXHR, textStatus, error, 'logging container check');
		}
	});
}

function saveContainerForm(formId, method, feedbackId, redirectUrl, breadcrumbFeedbackId, breadcrumbTargetId) {
	var $form = $('#' + formId);
	var containerType = $.trim($form.find('[name=container_type]').val());
	var label = $.trim($form.find('[name=label]').val());
	var parentContainerId = $.trim($form.find('[name=parent_container_id]').val());
	var params = $form.serializeArray();

	if (containerType.length === 0 || label.length === 0 || parentContainerId.length === 0) {
		setFeedbackControlState(feedbackId, 'error');
		messageDialog('Container Type, Label, and Parent Container are required.', 'Validation Error');
		return;
	}

	params.push({ name: 'method', value: method });
	params.push({ name: 'returnformat', value: 'json' });
	setFeedbackControlState(feedbackId, 'saving');

	$.ajax({
		url: '/containers/component/functions.cfc',
		type: 'post',
		dataType: 'json',
		data: params,
		success: function(resp) {
			var status = resp.status || resp.STATUS || '';
			var message = resp.message || resp.MESSAGE || 'Unknown error.';
			var responseContainerId = resp.container_id || resp.CONTAINER_ID || '';
			var fallbackContainerId = $.trim($form.find('[name=container_id]').val()) || '';
			var containerId = responseContainerId || fallbackContainerId;
			var numericContainerId = parseInt(containerId, 10);
			if (status === 'created') {
				window.location.href = redirectUrl || '/containers/viewContainer.cfm?container_id=' + encodeURIComponent(containerId);
			} else if (status === 'saved') {
				if (typeof pendingPositionsAction !== 'undefined' && pendingPositionsAction) {
					var queuedPositionsAction = pendingPositionsAction;
					pendingPositionsAction = null;
					applyPendingPositionsAction(containerId, queuedPositionsAction);
					return;
				}
				var shouldRefreshBreadcrumb = breadcrumbFeedbackId && breadcrumbTargetId;
				setFeedbackControlState(feedbackId, 'saved');
				updateContainerPositionsSummary(containerId, $.trim($form.find('[name=number_positions]').val()));
				if (shouldRefreshBreadcrumb) {
					if (!isNaN(numericContainerId)) {
						if (!responseContainerId && fallbackContainerId) {
							console.warn('saveContainer did not return container_id; using form value to refresh the container breadcrumb.');
						}
						showContainerBreadcrumb(numericContainerId, breadcrumbFeedbackId, breadcrumbTargetId);
					} else if (!containerId) {
						console.warn('Unable to refresh container breadcrumb after save: missing container_id.');
					} else {
						console.warn('Unable to refresh container breadcrumb after save: non-numeric container_id "' + containerId + '".');
					}
				}
			} else {
				setFeedbackControlState(feedbackId, 'error');
				if (resp.trimmable) {
					// every excess position beyond the requested count is unoccupied -- offer to
					// trim them and retry the same save automatically, instead of just naming the
					// block and leaving the user to go find a "Trim" control on their own.
					var trimContainerId = containerId;
					var excessCount = parseInt(resp.excess_count, 10) || 0;
					var trimNewCount = resp.new_count;
					confirmDialog(
						'Cannot reduce Number of Positions to ' + trimNewCount + ' -- ' + excessCount + ' empty position(s) beyond that count still exist. Trim them and save?',
						'Trim Positions',
						function() {
							$.ajax({
								url: '/containers/component/functions.cfc',
								type: 'post',
								dataType: 'json',
								data: {
									method: 'trimContainerPositions',
									returnformat: 'json',
									container_id: trimContainerId,
									new_count: trimNewCount
								},
								success: function(trimResp) {
									if (trimResp.status === 'trimmed') {
										saveContainerForm(formId, method, feedbackId, redirectUrl, breadcrumbFeedbackId, breadcrumbTargetId);
									} else {
										setFeedbackControlState(feedbackId, 'error');
										messageDialog('Error: ' + (trimResp.message || 'Unable to trim positions.'), 'Error Trimming Positions');
									}
								},
								error: function(jqXHR, textStatus, error) {
									setFeedbackControlState(feedbackId, 'error');
									handleFail(jqXHR, textStatus, error, 'trimming container positions');
								}
							});
						}
					);
				} else {
					messageDialog('Error: ' + message, 'Error Saving Container');
				}
			}
		},
		error: function(jqXHR, textStatus, error) {
			setFeedbackControlState(feedbackId, 'error');
			handleFail(jqXHR, textStatus, error, 'saving container');
		}
	});
}

/**
 * Shows a confirmation dialog before deleting a container.
 * On confirm, POSTs to deleteContainer in functions.cfc.
 * On success redirects to containers/Containers.cfm.
 * On error calls setFeedbackControlState and handleFail.
 *
 * @param {number} containerId - the container_id to delete.
 * @param {string} feedbackId - the id of the output element for status feedback.
 */
function confirmDeleteContainer(containerId, feedbackId) {
	confirmDialog('Delete this container? This cannot be undone.', 'Delete Container', function() {
		setFeedbackControlState(feedbackId, 'saving');
		$.ajax({
			url: '/containers/component/functions.cfc',
			type: 'post',
			dataType: 'json',
			data: {
				method: 'deleteContainer',
				returnformat: 'json',
				container_id: containerId
			},
			success: function(resp) {
				var status = resp.status || resp.STATUS || '';
				var message = resp.message || resp.MESSAGE || 'Unknown error.';
				if (status === 'deleted') {
					window.location.href = '/containers/Containers.cfm';
				} else {
					setFeedbackControlState(feedbackId, 'error');
					messageDialog('Error: ' + message, 'Error Deleting Container');
				}
			},
			error: function(jqXHR, textStatus, error) {
				setFeedbackControlState(feedbackId, 'error');
				handleFail(jqXHR, textStatus, error, 'deleting container');
			}
		});
	});
}

/**
 * Confirm and move a container back into a parent from placement history.
 * @param {number|string} childContainerId - container_id of the container being moved.
 * @param {number|string} parentContainerId - historical parent container_id to move into.
 * @param {string} parentDisplay - user-facing parent container text for confirmation.
 * @param {string} feedbackId - id of output element for status feedback.
 * @param {Function} onPlaced - optional callback invoked after a successful move.
 * @returns {void}
 */
function putContainerBackFromHistory(childContainerId, parentContainerId, parentDisplay, feedbackId, onPlaced) {
	var safeParentDisplay = parentDisplay || 'selected parent container';
	confirmDialog('Place this container back into ' + safeParentDisplay + '?', 'Put Back Here', function() {
		if (feedbackId) {
			setFeedbackControlState(feedbackId, 'saving', 'Moving...');
		}
		$.ajax({
			url: '/containers/component/public.cfc',
			type: 'post',
			dataType: 'json',
			data: {
				method: 'moveContainerById',
				returnformat: 'json',
				child_container_id: childContainerId,
				parent_container_id: parentContainerId
			},
			success: function(result) {
				if (result && result.status === 'moved') {
					if (feedbackId) {
						setFeedbackControlState(feedbackId, 'saved', 'Container moved.');
					}
					if (onPlaced) {
						onPlaced(result);
					}
				} else {
					var message = (result && result.message) ? result.message : 'Unable to move container.';
					if (feedbackId) {
						setFeedbackControlState(feedbackId, 'error', message);
					}
				}
			},
			error: function(jqXHR, textStatus, error) {
				if (feedbackId) {
					setFeedbackControlState(feedbackId, 'error');
				}
				handleFail(jqXHR, textStatus, error, 'moving container from history');
			}
		});
	});
}

/**
 * Toggle a detail row showing breadcrumb location for a historical parent container.
 * If the detail row already exists, this toggles its visibility; otherwise it creates
 * the row, asynchronously loads breadcrumb data from search.cfc, and expands the row.
 * @param {HTMLElement} triggerButton - button element that launched the locate action.
 * @param {number|string} parentContainerId - container_id to locate.
 * @param {string} detailRowId - unique id for the inserted detail row.
 * @returns {void}
 */
function toggleHistoryParentLocate(triggerButton, parentContainerId, detailRowId) {
	var button = $(triggerButton);
	var currentRow = button.closest('tr');
	var existingDetail = $('#' + detailRowId);
	if (existingDetail.length > 0) {
		existingDetail.toggleClass('d-none');
		if (existingDetail.hasClass('d-none')) {
			button.attr('aria-expanded', 'false').text('Locate');
		} else {
			button.attr('aria-expanded', 'true').text('Hide Location');
		}
		return;
	}
	var colspan = currentRow.children('td,th').length;
	var detailRow = $('<tr></tr>').attr('id', detailRowId).addClass('locate-detail-row');
	var detailCell = $('<td></td>').attr('colspan', colspan).addClass('bg-light p-2 small');
	detailRow.append(detailCell);
	currentRow.after(detailRow);
	button.attr('aria-expanded', 'true').text('Hide Location');
	detailCell.html('<span aria-live="polite"><img src="/shared/images/indicator.gif" alt="Loading"> Loading location…</span>');
	$.ajax({
		url: '/containers/component/search.cfc',
		data: { method: 'getContainerBreadcrumb', container_id: parentContainerId },
		dataType: 'json',
		success: function(breadcrumbs) {
			var breadcrumbNav = $('<nav aria-label="Container location breadcrumb"></nav>');
			var breadcrumbEl = $('<ol class="breadcrumb bg-transparent p-0 m-0 flex-wrap"></ol>');
			$.each(breadcrumbs, function(index, crumb) {
				var display = formatContainerDisplay(crumb.barcode, crumb.label);
				var crumbLi = $('<li class="breadcrumb-item small"></li>');
				if (index === 0) {
					crumbLi.addClass('arrowprefix');
				}
				crumbLi.append(document.createTextNode(crumb.container_type + ': '));
				if (index === breadcrumbs.length - 1) {
					crumbLi.addClass('active').attr('aria-current', 'page').append(document.createTextNode(display));
				} else {
					var link = document.createElement('a');
					// execute=true runs the hierarchy search view for the selected breadcrumb container.
					var params = new URLSearchParams({ execute: 'true', container_id: crumb.container_id });
					link.href = '/containers/Containers.cfm?' + params.toString();
					link.appendChild(document.createTextNode(display));
					crumbLi.append(link);
				}
				breadcrumbEl.append(crumbLi);
			});
			breadcrumbNav.append(breadcrumbEl);
			detailCell.html(breadcrumbNav);
		},
		error: function(jqXHR, textStatus, error) {
			detailCell.html('<span class="text-danger" role="alert">Failed to load location.</span>');
			handleFail(jqXHR, textStatus, error, 'loading container breadcrumb');
		}
	});
}

/**
 * Loads the HTML fragment for a container's read-only details into targetDivId.
 * Calls getContainerDetailsHtml in functions.cfc.
 *
 * @param {number} containerId - the container_id to display.
 * @param {string} targetDivId - the id of the div to render into (without leading #).
 * @param {string} feedbackId - the id of the output element for status feedback (without leading #).
 * @param {boolean} [showBrowseAction] - whether to show the Browse in Hierarchy button in the fragment.
 */
function loadContainerDetails(containerId, targetDivId, feedbackId, showBrowseAction) {
	var browseActionEnabled = typeof showBrowseAction === 'undefined' ? true : !!showBrowseAction;
	$('#' + targetDivId).html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading...</div>');
	$.ajax({
		url: '/containers/component/public.cfc',
		type: 'get',
		data: {
			method: 'getContainerDetailsHtml',
			returnformat: 'plain',
			container_id: containerId,
			displayMode: 'dialog',
			idSuffix: targetDivId,
			showBrowseAction: browseActionEnabled ? 'true' : 'false'
		},
		success: function(data) {
			$('#' + targetDivId).html(data);
		},
		error: function(jqXHR, textStatus, error) {
			if (feedbackId) {
				setFeedbackControlState(feedbackId, 'error');
			}
			handleFail(jqXHR, textStatus, error, 'loading container details');
		}
	});
}

/**
 * Loads the Contents section fragment for one container details rendering.
 * @param {number|string} containerId - the container_id whose contents should be rendered.
 * @param {string} targetDivId - id of the container contents target element.
 * @param {string} feedbackId - optional feedback output element id for AJAX failures.
 * @returns {void}
 */
function loadContainerContentsSection(containerId, targetDivId, feedbackId) {
	if (!targetDivId) {
		return;
	}
	var target = $('#' + targetDivId);
	if (!target.length) {
		return;
	}
	target.html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading...</div>');
	$.ajax({
		url: '/containers/component/public.cfc',
		type: 'get',
		data: {
			method: 'getContainerContentsHtml',
			returnformat: 'plain',
			container_id: containerId
		},
		success: function(data) {
			target.html(data);
		},
		error: function(jqXHR, textStatus, error) {
			if (feedbackId) {
				setFeedbackControlState(feedbackId, 'error');
			}
			handleFail(jqXHR, textStatus, error, 'loading container contents');
		}
	});
}



/**
 * Returns role metadata for one container type, falling back to structural defaults.
 * @param {string} containerType - the container type to look up.
 * @returns {Object} metadata object with role and expects_leaf_child_count properties.
 */
function getContainerTypeMetadataEntry(containerType) {
	var typeKey = normalizeContainerTypeKey(containerType);
	return containerTypeMetadataByType[typeKey] || { role: 'structural', expects_leaf_child_count: 0 };
}

/**
 * Resolves the functional role for a container type.
 * @param {string} containerType - the container type to evaluate.
 * @returns {string} one of proxy, leafbearer, structural, or leaf, defaulting to structural.
 */
function getContainerRole(containerType) {
	return getContainerTypeMetadataEntry(containerType).role || 'structural';
}

/**
 * Determines whether the current container type may create child containers.
 * @param {string} containerType - the container type to evaluate.
 * @returns {boolean} true when the node should show create-child actions.
 */
function canCreateChildContainer(containerType) {
	var role = getContainerRole(containerType);
	return role !== 'proxy' && role !== 'leaf';
}

/**
 * Builds the role badge HTML used beside container types in trees and tables.
 * @param {string} containerType - the container type whose role should be displayed.
 * @returns {string} badge markup for the resolved role.
 */
function getContainerRoleBadgeHtml(containerType) {
	var role = getContainerRole(containerType);
	var labelMap = { proxy: 'Proxy', leafbearer: 'Leaf bearer', structural: 'Structural', leaf: 'Leaf' };
	return '<span class="badge badge-pill container-role-badge container-role-' + role + '">' + (labelMap[role] || role) + '</span>';
}

/**
 * Builds the combined container-type and role-badge element for rendered nodes.
 * @param {string} containerType - the container type text to display.
 * @returns {jQuery} span element containing the type label and role badge.
 */
function buildContainerTypeMeta(containerType) {
	var safeType = containerType || 'Unknown';
	var meta = $('<span class="tree-node-type text-muted small mx-1"></span>').text('[' + safeType + ']');
	meta.append(' ');
	meta.append($(getContainerRoleBadgeHtml(containerType)));
	return meta;
}

/**
 * Builds the table-layout Details button using the shared container action styling.
 * @param {number} containerId - the container_id whose details should be opened.
 * @param {string} displayName - the display name to include in the dialog title.
 * @param {string} feedbackId - optional feedback element id for AJAX failures.
 * @returns {jQuery} details button configured for table action cells.
 */
function buildContainerDetailsActionButton(containerId, displayName, feedbackId) {
	return buildContainerDetailsButton(containerId, displayName, feedbackId, TABLE_ACTION_SPACING_CLASS);
}

/**
 * Builds a View link to the standalone container page.
 * @param {number} containerId - the container_id to open.
 * @param {string} spacingClass - optional spacing class override for the action element.
 * @returns {jQuery} anchor element that opens viewContainer.cfm in a new tab.
 */
function buildContainerViewLink(containerId, spacingClass) {
	return $('<a target="_blank" rel="noopener noreferrer"></a>')
		.addClass(buildContainerActionClass('btn btn-xs btn-info', spacingClass || TABLE_ACTION_SPACING_CLASS))
		.attr('href', '/containers/viewContainer.cfm?container_id=' + encodeURIComponent(containerId))
		.text('View');
}

/**
 * Builds an Edit link to the standalone container edit page.
 * Returns null when the current session lacks edit rights (see canEditContainers).
 * @param {number} containerId - the container_id to edit.
 * @param {string} spacingClass - optional spacing class override for the action element.
 * @returns {jQuery|null} anchor element that opens the edit form in a new tab, or null.
 */
function buildContainerEditLink(containerId, spacingClass) {
	if (!canEditContainers) {
		return null;
	}
	return $('<a target="_blank" rel="noopener noreferrer"></a>')
		.addClass(buildContainerActionClass('btn btn-xs btn-secondary', spacingClass || TABLE_ACTION_SPACING_CLASS))
		.attr('href', '/containers/Container.cfm?action=edit&container_id=' + encodeURIComponent(containerId))
		.text('Edit');
}

/**
 * Builds an "Add Child Container" link button that opens the new-container form
 * in a new tab with the given container pre-set as the parent.
 * Returns null when containerType is a proxy or collection object type, as those
 * nodes cannot have child containers added to them, or when the current session
 * lacks edit rights (see canEditContainers).
 *
 * @param {number} containerId   - the container_id to use as the parent.
 * @param {string} containerType - the container_type of the current node.
 * @returns {jQuery|null} an anchor element, or null if not applicable.
 */
function buildAddChildContainerLink(containerId, containerType, spacingClass) {
	if (!canEditContainers || !canCreateChildContainer(containerType)) {
		return null;
	}
	return $('<a target="_blank" rel="noopener noreferrer"></a>')
		.addClass(buildContainerActionClass('btn btn-xs btn-secondary', spacingClass || TABLE_ACTION_SPACING_CLASS))
		.attr('href', '/containers/Container.cfm?action=new&parent_container_id=' + encodeURIComponent(containerId))
		.text('Create Child');
}

/**
 * Builds the legacy combined specimen summary cell for orphan result tables.
 * @param {Object} row - one orphan-table row returned from the server.
 * @param {string} occupantBarcode - fallback barcode for the occupying container.
 * @param {string} occupantLabel - fallback label for the occupying container.
 * @returns {jQuery} table cell containing specimen or occupant summary text.
 */
function renderSpecimenCell(row, occupantBarcode, occupantLabel) {
	var specTd = $('<td></td>');
	if (row.cat_num && row.collection_cde && row.institution_acronym) {
		var guidText = row.institution_acronym + ':' + row.collection_cde + ':' + row.cat_num;
		var guidUrl = '/guid/' + guidText;
		specTd.append(
			$('<a target="_blank" rel="noopener noreferrer"></a>')
				.attr('href', guidUrl)
				.attr('title', 'View specimen record')
				.text(guidText)
		);
		if (row.scientific_name) {
			specTd.append($('<br>')).append($('<em class="small text-muted"></em>').text(row.scientific_name));
		}
		if (row.part_name) {
			specTd.append($('<span class="small text-muted ml-1"></span>').text('(' + row.part_name + ')'));
		}
	} else if (occupantBarcode || occupantLabel) {
		specTd.append($('<span class="small text-muted"></span>').text(formatContainerDisplay(occupantBarcode, occupantLabel)));
	}
	return specTd;
}

/**
 * Builds the GUID column cell for browsed container contents.
 * @param {Object} row - one leaf-child row returned from the server.
 * @param {string} occupantBarcode - fallback barcode when no GUID is available.
 * @param {string} occupantLabel - fallback label when no GUID is available.
 * @returns {jQuery} table cell containing a GUID link or fallback container display.
 */
/**
 * Builds a "Place Part" action link opening containers/placePartInContainer.cfm prefilled (by
 * guid) for a row's cataloged item, for tables listing collection-object occupants.
 * @param {Object} row - must carry cat_num, collection_cde, and institution_acronym.
 * @returns {?jQuery} the link, or null if the row doesn't carry enough specimen identity.
 */
function buildPlacePartLink(row) {
	if (!row || !row.cat_num || !row.collection_cde || !row.institution_acronym) {
		return null;
	}
	var guidText = row.institution_acronym + ':' + row.collection_cde + ':' + row.cat_num;
	return $('<a class="btn btn-xs btn-outline-info mr-1 mb-1" target="_blank" rel="noopener noreferrer"></a>')
		.attr('href', '/containers/placePartInContainer.cfm?guid=' + encodeURIComponent(guidText) + '&execute=true')
		.attr('title', "Place this specimen's parts into a container")
		.text('Place Part');
}

function buildSpecimenGuidCell(row, occupantBarcode, occupantLabel) {
	var guidTd = $('<td></td>');
	if (row.cat_num && row.collection_cde && row.institution_acronym) {
		var guidText = row.institution_acronym + ':' + row.collection_cde + ':' + row.cat_num;
		var guidUrl = '/guid/' + guidText;
		guidTd.append(
			$('<a target="_blank" rel="noopener noreferrer"></a>')
				.attr('href', guidUrl)
				.attr('title', 'View specimen record')
				.text(guidText)
		);
	} else if (occupantBarcode || occupantLabel) {
		guidTd.append($('<span class="small text-muted"></span>').text(formatContainerDisplay(occupantBarcode, occupantLabel)));
	} else {
		guidTd.append($('<span class="text-muted"></span>').text('—'));
	}
	return guidTd;
}

/**
 * Builds the current-identification cell for a specimen row.
 * @param {Object} row - one leaf-child row returned from the server.
 * @returns {jQuery} table cell containing scientific name text or an em dash placeholder.
 */
function buildSpecimenIdentificationCell(row) {
	var identificationTd = $('<td></td>');
	if (row.scientific_name) {
		identificationTd.append($('<em></em>').text(row.scientific_name));
	} else {
		identificationTd.append($('<span class="text-muted"></span>').text('—'));
	}
	return identificationTd;
}

/**
 * Builds the part-type cell for a specimen row.
 * @param {Object} row - one leaf-child row returned from the server.
 * @returns {jQuery} table cell containing part-type text or an em dash placeholder.
 */
function buildSpecimenPartCell(row) {
	var partTd = $('<td></td>');
	if (row.part_name) {
		partTd.text(row.part_name);
	} else {
		partTd.append($('<span class="text-muted"></span>').text('—'));
	}
	return partTd;
}

/**
 * Builds the preservation cell for a specimen row.
 * @param {Object} row - one leaf-child row returned from the server.
 * @returns {jQuery} table cell containing preservation text or an em dash placeholder.
 */
function buildSpecimenPreservationCell(row) {
	var preservationTd = $('<td></td>');
	if (row.preserve_method) {
		preservationTd.text(row.preserve_method);
	} else {
		preservationTd.append($('<span class="text-muted"></span>').text('—'));
	}
	return preservationTd;
}

/**
 * Builds the reusable first/previous/next/last pager used by container tables.
 * @param {number} currentPage - the page currently being displayed.
 * @param {number} totalPages - total number of available pages.
 * @param {string} className - optional classes for the nav wrapper.
 * @param {string} pageClass - class to add to enabled paging buttons for delegated click handling.
 * @returns {jQuery} navigation element containing the pager buttons.
 */
function buildPagedNav(currentPage, totalPages, className, pageClass) {
	var nav = $('<nav></nav>').attr('aria-label', 'Page navigation').addClass('d-flex flex-wrap' + (className ? ' ' + className : ''));
	var firstBtn = $('<button class="btn btn-xs btn-secondary mr-1">« First</button>').attr('type', 'button');
	var prevBtn = $('<button class="btn btn-xs btn-secondary mr-1">‹ Prev</button>').attr('type', 'button');
	var nextBtn = $('<button class="btn btn-xs btn-secondary mr-1">Next ›</button>').attr('type', 'button');
	var lastBtn = $('<button class="btn btn-xs btn-secondary">Last »</button>').attr('type', 'button');
	if (currentPage <= 1) {
		firstBtn.prop('disabled', true);
		prevBtn.prop('disabled', true);
	} else {
		firstBtn.addClass(pageClass).data('page', 1);
		prevBtn.addClass(pageClass).data('page', currentPage - 1);
	}
	if (currentPage >= totalPages) {
		nextBtn.prop('disabled', true);
		lastBtn.prop('disabled', true);
	} else {
		nextBtn.addClass(pageClass).data('page', currentPage + 1);
		lastBtn.addClass(pageClass).data('page', totalPages);
	}
	return nav.append(firstBtn, prevBtn, nextBtn, lastBtn);
}

/**
 * Opens the shared modal dialog that hosts the container details fragment.
 * @param {number} containerId - the container_id whose details should be loaded.
 * @param {string} displayName - optional display name to include in the dialog title.
 * @param {string} feedbackId - optional feedback element id for AJAX failures.
 * @param {boolean} showBrowseAction - true to keep the Browse in Hierarchy action visible.
 */
function openContainerDetailsDialog(containerId, displayName, feedbackId, showBrowseAction) {
	var dialogId = 'containerDetailsDialog';
	var contentId = 'containerDetailsDialogContent';
	var dialogEl = $('#' + dialogId);
	var dialogWidth = Math.max(320, Math.min($(window).width() - 40, 1280));
	var dialogHeight = Math.max(320, Math.min($(window).height() - 40, 700));
	var dialogTitle = 'Container Details';
	var browseActionEnabled = typeof showBrowseAction === 'undefined' ? true : !!showBrowseAction;
	if (!dialogEl.length) {
		dialogEl = $('<div id="' + dialogId + '"></div>').appendTo('body');
	}
	if (displayName) {
		dialogTitle += ': ' + displayName;
	}
	if (dialogEl.hasClass('ui-dialog-content')) {
		dialogEl.dialog('destroy');
	}
	dialogEl.html('<div id="' + contentId + '"></div>').dialog({
		modal: true,
		title: dialogTitle,
		width: dialogWidth,
		height: dialogHeight,
		dialogClass: 'dialog_fixed ui-widget-header',
		close: function() {
			$('#' + contentId).html('');
			$(this).dialog('destroy');
		}
	});
	dialogEl.dialog('open');
	dialogEl.dialog('moveToTop');
	loadContainerDetails(containerId, contentId, feedbackId, browseActionEnabled);
}

/**
 * Renders the paged table for top-level single-occupant proxy orphans.
 * @param {Object} data - paged orphan payload from getOrphanedSingleOccupantContainers.
 * @param {string} targetDivId - id of the panel that should receive the rendered table.
 * @param {string} feedbackId - optional feedback element id for delegated actions.
 * @param {number} page - current page number when re-rendering after navigation.
 */
function renderOrphanedSingleOccupantTable(data, targetDivId, feedbackId, page) {
	var rows = data.rows || [];
	var totalRows = parseInt(data.totalRows, 10) || 0;
	var pageSize = parseInt(data.pageSize, 10) || CONTAINER_PAGE_SIZE;
	var currentPage = parseInt(data.page, 10) || page || 1;
	var totalPages = Math.max(1, Math.ceil(totalRows / pageSize));
	var target = $('#' + targetDivId);
	var panel = $('<div class="container-leaf-panel"></div>');
	var headingDiv = $('<div class="d-flex align-items-center flex-wrap mb-1"></div>');
	headingDiv.append($('<h3 class="h5 mr-2 mb-0"></h3>').text('Single-occupant orphans (' + totalRows + ')'));
	panel.append(headingDiv);
	if (totalPages > 1) {
		panel.append($('<p class="small text-muted mb-1"></p>').text('Page ' + currentPage + ' of ' + totalPages));
		panel.append(buildPagedNav(currentPage, totalPages, 'mb-1', 'orphan-single-page-btn'));
	}
	if (rows.length === 0) {
		panel.append($('<p class="text-muted mb-0"></p>').text('No orphaned single-occupant containers found.'));
	} else {
		var tbody = $('<tbody></tbody>');
		$.each(rows, function(i, row) {
			var displayName = formatContainerDisplay(row.barcode, row.label);
			var actionTd = $('<td></td>');
			actionTd.append(buildContainerDetailsActionButton(row.container_id, displayName, feedbackId));
			actionTd.append(buildContainerViewLink(row.container_id));
			actionTd.append(buildAddChildContainerLink(row.container_id, row.container_type));
			var occupantSpecUrl = specimenSearchUrl(row.occupant_barcode || '');
			if (occupantSpecUrl) {
				actionTd.append(
					$('<a class="btn btn-xs btn-outline-info mr-1 mb-1" target="_blank" rel="noopener noreferrer"></a>')
						.attr('href', occupantSpecUrl)
						.text('View specimen')
				);
			}
			var placePartLink = buildPlacePartLink(row);
			if (placePartLink) {
				actionTd.append(placePartLink);
			}
			var typeTd = $('<td></td>').text(row.container_type || '');
			typeTd.append(' ');
			typeTd.append($(getContainerRoleBadgeHtml(row.container_type)));
			typeTd.append(' ');
			typeTd.append(buildHighLevelOrphanBadge('High-level single-occupant proxy orphan', 'ml-1'));
			var tr = $('<tr></tr>');
			tr.append(typeTd);
			tr.append($('<td></td>').text(displayName));
			tr.append(renderSpecimenCell(row, row.occupant_barcode, row.occupant_label));
			tr.append($('<td></td>').text(row.description || ''));
			tr.append(actionTd);
			tbody.append(tr);
		});
		var table = $('<table class="table table-sm table-striped"></table>');
		table.append('<thead><tr><th>Type</th><th>Container</th><th>Specimen</th><th>Description</th><th>Actions</th></tr></thead>');
		table.append(tbody);
		panel.append(table);
		if (totalPages > 1) {
			panel.append(buildPagedNav(currentPage, totalPages, 'mt-2', 'orphan-single-page-btn'));
		}
	}
	target.removeClass('d-none').html(panel);
	target.off('click.orphansingle').on('click.orphansingle', '.orphan-single-page-btn', function() {
		loadOrphanedSingleOccupantPage(targetDivId, feedbackId, $(this).data('page'));
	});
}

/**
 * Loads one page of the single-occupant orphan table and renders it into place.
 * @param {string} targetDivId - id of the panel that should receive the rendered table.
 * @param {string} feedbackId - optional feedback element id for AJAX failures.
 * @param {number} page - page number to request.
 * @param {function} onLoaded - optional callback invoked after a successful render.
 */
function loadOrphanedSingleOccupantPage(targetDivId, feedbackId, page, onLoaded) {
	var target = $('#' + targetDivId);
	target.data('loading', true);
	target.removeClass('d-none').html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading...</div>');
	$.ajax({
		url: '/containers/component/public.cfc',
		data: {
			method: 'getOrphanedSingleOccupantContainers',
			page: page || 1,
			pageSize: CONTAINER_PAGE_SIZE
		},
		dataType: 'json',
		success: function(data) {
			target.data('loaded', true).data('loading', false);
			renderOrphanedSingleOccupantTable(data, targetDivId, feedbackId, page || 1);
			if (onLoaded) {
				onLoaded();
			}
		},
		error: function(jqXHR, textStatus, error) {
			target.data('loading', false);
			if (feedbackId) {
				setFeedbackControlState(feedbackId, 'error');
			}
			handleFail(jqXHR, textStatus, error, 'loading orphaned single-occupant containers');
		}
	});
}

/**
 * Renders one page of the leaf (collection-object) orphan table -- containers of type
 * 'collection object' placed directly under an institution, or with no parent container at all,
 * rather than under a proper campus/building/etc. hierarchy. Mirrors
 * renderOrphanedSingleOccupantTable, but a leaf orphan IS the specimen's own container (no
 * separate "occupant" to look up), so the specimen columns come straight off the row.
 * @param {Object} data - payload from getOrphanedLeafContainers.
 * @param {string} targetDivId - id of the panel that should receive the rendered table.
 * @param {string} feedbackId - optional feedback element id for AJAX failures.
 * @param {number} page - the page currently being displayed.
 */
function renderOrphanedLeafTable(data, targetDivId, feedbackId, page) {
	var rows = data.rows || [];
	var totalRows = parseInt(data.totalRows, 10) || 0;
	var pageSize = parseInt(data.pageSize, 10) || CONTAINER_PAGE_SIZE;
	var currentPage = parseInt(data.page, 10) || page || 1;
	var totalPages = Math.max(1, Math.ceil(totalRows / pageSize));
	var target = $('#' + targetDivId);
	var panel = $('<div class="container-leaf-panel"></div>');
	var headingDiv = $('<div class="d-flex align-items-center flex-wrap mb-1"></div>');
	headingDiv.append($('<h3 class="h5 mr-2 mb-0"></h3>').text('Leaf orphans (' + totalRows + ')'));
	panel.append(headingDiv);
	if (totalPages > 1) {
		panel.append($('<p class="small text-muted mb-1"></p>').text('Page ' + currentPage + ' of ' + totalPages));
		panel.append(buildPagedNav(currentPage, totalPages, 'mb-1', 'orphan-leaf-page-btn'));
	}
	if (rows.length === 0) {
		panel.append($('<p class="text-muted mb-0"></p>').text('No orphaned collection-object containers found.'));
	} else {
		var tbody = $('<tbody></tbody>');
		$.each(rows, function(i, row) {
			var displayName = formatContainerDisplay(row.barcode, row.label);
			var actionTd = $('<td></td>');
			actionTd.append(buildContainerDetailsActionButton(row.container_id, displayName, feedbackId));
			actionTd.append(buildContainerViewLink(row.container_id));
			var placePartLink = buildPlacePartLink(row);
			if (placePartLink) {
				actionTd.append(placePartLink);
			}
			var typeTd = $('<td></td>').text(row.container_type || '');
			typeTd.append(' ');
			typeTd.append($(getContainerRoleBadgeHtml(row.container_type)));
			typeTd.append(' ');
			typeTd.append(buildHighLevelOrphanBadge('High-level collection-object orphan', 'ml-1'));
			var tr = $('<tr></tr>');
			tr.append(typeTd);
			tr.append($('<td></td>').text(displayName));
			tr.append(renderSpecimenCell(row, row.barcode, row.label));
			tr.append($('<td></td>').text(row.description || ''));
			tr.append(actionTd);
			tbody.append(tr);
		});
		var table = $('<table class="table table-sm table-striped"></table>');
		table.append('<thead><tr><th>Type</th><th>Container</th><th>Specimen</th><th>Description</th><th>Actions</th></tr></thead>');
		table.append(tbody);
		panel.append(table);
		if (totalPages > 1) {
			panel.append(buildPagedNav(currentPage, totalPages, 'mt-2', 'orphan-leaf-page-btn'));
		}
	}
	target.removeClass('d-none').html(panel);
	target.off('click.orphanleaf').on('click.orphanleaf', '.orphan-leaf-page-btn', function() {
		loadOrphanedLeafPage(targetDivId, feedbackId, $(this).data('page'));
	});
}

/**
 * Loads one page of the leaf orphan table and renders it into place.
 * @param {string} targetDivId - id of the panel that should receive the rendered table.
 * @param {string} feedbackId - optional feedback element id for AJAX failures.
 * @param {number} page - page number to request.
 * @param {function} onLoaded - optional callback invoked after a successful render.
 */
function loadOrphanedLeafPage(targetDivId, feedbackId, page, onLoaded) {
	var target = $('#' + targetDivId);
	target.data('loading', true);
	target.removeClass('d-none').html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading...</div>');
	$.ajax({
		url: '/containers/component/public.cfc',
		data: {
			method: 'getOrphanedLeafContainers',
			page: page || 1,
			pageSize: CONTAINER_PAGE_SIZE
		},
		dataType: 'json',
		success: function(data) {
			target.data('loaded', true).data('loading', false);
			renderOrphanedLeafTable(data, targetDivId, feedbackId, page || 1);
			if (onLoaded) {
				onLoaded();
			}
		},
		error: function(jqXHR, textStatus, error) {
			target.data('loading', false);
			if (feedbackId) {
				setFeedbackControlState(feedbackId, 'error');
			}
			handleFail(jqXHR, textStatus, error, 'loading orphaned leaf containers');
		}
	});
}

/**
 * Builds the warning badge used to label top-level orphan table rows.
 * @param {string} label - badge text to display.
 * @param {string} extraClasses - optional additional classes for spacing or layout.
 * @returns {jQuery} badge element describing the orphan classification.
 */
function buildHighLevelOrphanBadge(label, extraClasses) {
	return $('<span class="badge badge-pill badge-warning small"></span>').addClass(extraClasses || '').text(label);
}

/**
 * Renders the paged table for top-level empty proxy orphans.
 * @param {Object} data - paged orphan payload from getOrphanedEmptyProxyContainers.
 * @param {string} targetDivId - id of the panel that should receive the rendered table.
 * @param {string} feedbackId - optional feedback element id for delegated actions.
 * @param {number} page - current page number when re-rendering after navigation.
 */
function renderOrphanedEmptyProxyTable(data, targetDivId, feedbackId, page) {
	var rows = data.rows || [];
	var totalRows = parseInt(data.totalRows, 10) || 0;
	var pageSize = parseInt(data.pageSize, 10) || CONTAINER_PAGE_SIZE;
	var currentPage = parseInt(data.page, 10) || page || 1;
	var totalPages = Math.max(1, Math.ceil(totalRows / pageSize));
	var target = $('#' + targetDivId);
	var panel = $('<div class="container-leaf-panel"></div>');
	var headingDiv = $('<div class="d-flex align-items-center flex-wrap mb-1"></div>');
	headingDiv.append($('<h3 class="h5 mr-2 mb-0"></h3>').text('Empty proxy orphans (' + totalRows + ')'));
	panel.append(headingDiv);
	if (totalPages > 1) {
		panel.append($('<p class="small text-muted mb-1"></p>').text('Page ' + currentPage + ' of ' + totalPages));
		panel.append(buildPagedNav(currentPage, totalPages, 'mb-1', 'orphan-empty-page-btn'));
	}
	if (rows.length === 0) {
		panel.append($('<p class="text-muted mb-0"></p>').text('No orphaned empty proxy containers found.'));
	} else {
		var tbody = $('<tbody></tbody>');
		$.each(rows, function(i, row) {
			var displayName = formatContainerDisplay(row.barcode, row.label);
			var typeTd = $('<td></td>').text(row.container_type || '');
			typeTd.append(' ');
			typeTd.append($(getContainerRoleBadgeHtml(row.container_type)));
			typeTd.append(' ');
			typeTd.append(buildHighLevelOrphanBadge('High-level empty proxy orphan', 'ml-1'));
			var actionTd = $('<td></td>');
			actionTd.append(buildContainerDetailsActionButton(row.container_id, displayName, feedbackId));
			actionTd.append(buildContainerViewLink(row.container_id));
			actionTd.append(buildAddChildContainerLink(row.container_id, row.container_type));
			tbody.append(
				$('<tr></tr>')
					.append(typeTd)
					.append($('<td></td>').text(displayName))
					.append($('<td></td>').text('Empty'))
					.append($('<td></td>').text(row.description || ''))
					.append(actionTd)
			);
		});
		var table = $('<table class="table table-sm table-striped"></table>');
		table.append('<thead><tr><th>Type</th><th>Container</th><th>Status</th><th>Description</th><th>Actions</th></tr></thead>');
		table.append(tbody);
		panel.append(table);
		if (totalPages > 1) {
			panel.append(buildPagedNav(currentPage, totalPages, 'mt-2', 'orphan-empty-page-btn'));
		}
	}
	target.removeClass('d-none').html(panel);
	target.off('click.orphanempty').on('click.orphanempty', '.orphan-empty-page-btn', function() {
		loadOrphanedEmptyProxyPage(targetDivId, feedbackId, $(this).data('page'));
	});
}

/**
 * Loads one page of the empty-proxy orphan table and renders it into place.
 * @param {string} targetDivId - id of the panel that should receive the rendered table.
 * @param {string} feedbackId - optional feedback element id for AJAX failures.
 * @param {number} page - page number to request.
 * @param {function} onLoaded - optional callback invoked after a successful render.
 */
function loadOrphanedEmptyProxyPage(targetDivId, feedbackId, page, onLoaded) {
	var target = $('#' + targetDivId);
	target.data('loading', true);
	target.removeClass('d-none').html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading...</div>');
	$.ajax({
		url: '/containers/component/public.cfc',
		data: {
			method: 'getOrphanedEmptyProxyContainers',
			page: page || 1,
			pageSize: CONTAINER_PAGE_SIZE
		},
		dataType: 'json',
		success: function(data) {
			target.data('loaded', true).data('loading', false);
			renderOrphanedEmptyProxyTable(data, targetDivId, feedbackId, page || 1);
			if (onLoaded) {
				onLoaded();
			}
		},
		error: function(jqXHR, textStatus, error) {
			target.data('loading', false);
			if (feedbackId) {
				setFeedbackControlState(feedbackId, 'error');
			}
			handleFail(jqXHR, textStatus, error, 'loading orphaned empty proxy containers');
		}
	});
}

/**
 * Toggles a lazily rendered browse section open or closed beneath its trigger button.
 * @param {HTMLElement|jQuery} buttonEl - the button controlling the section; normalized to a jQuery object internally.
 * @param {string} panelId - id of the section panel to show or hide.
 * @param {function} loadFn - optional loader invoked the first time the panel opens.
 */
function toggleBrowseSection(buttonEl, panelId, loadFn) {
	var btn = $(buttonEl);
	var panel = $('#' + panelId);
	if (panel.length === 0) {
		return;
	}
	if (!panel.hasClass('d-none')) {
		panel.addClass('d-none');
		btn.attr('aria-expanded', 'false');
		return;
	}
	btn.attr('aria-expanded', 'true');
	if (panel.data('loaded')) {
		panel.removeClass('d-none');
		return;
	}
	if (panel.data('loading')) {
		return;
	}
	/* loadFn is optional for sections whose contents were pre-rendered up front. */
	if (loadFn) {
		loadFn();
	}
}

/**
 * Ensures the structural-orphan section is visible before Explore continues into it.
 * @param {string} feedbackId - optional feedback element id for AJAX failures.
 * @param {function} onReady - callback invoked with true/false once the panel is ready or unavailable.
 */
function ensureStructuralOrphanPanelVisible(feedbackId, onReady) {
	var buttonId = 'ctree-orphan-structural-btn';
	var panelId = 'ctree-orphan-structural-panel';
	var panel = $('#' + panelId);
	var button = $('#' + buttonId);
	if (panel.length === 0 || button.length === 0) {
		if (onReady) {
			onReady(false);
		}
		return;
	}
	button.attr('aria-expanded', 'true');
	if (panel.data('loaded')) {
		panel.removeClass('d-none');
		if (onReady) {
			onReady(true);
		}
		return;
	}
	if (panel.data('loading')) {
		var callbacks = panel.data('loadCallbacks') || [];
		callbacks.push(onReady);
		panel.data('loadCallbacks', callbacks);
		return;
	}
	panel.data('loadCallbacks', [onReady]);
	loadStructuralOrphanPanel(panelId, feedbackId);
}

/**
 * Loads the top-level structural orphan tree into its toggle panel.
 * @param {string} targetDivId - id of the panel that should receive the rendered tree.
 * @param {string} feedbackId - optional feedback element id for AJAX failures.
 */
function loadStructuralOrphanPanel(targetDivId, feedbackId) {
	var target = $('#' + targetDivId);
	target.data('loading', true);
	target.removeClass('d-none').html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading…</div>');
	$.ajax({
		url: '/containers/component/public.cfc',
		data: { method: 'getOrphanedTopLevelStructural' },
		dataType: 'json',
		success: function(nodes) {
			var callbacks = target.data('loadCallbacks') || [];
			target.data('loaded', true).data('loading', false);
			renderTreeNodes(nodes, targetDivId, feedbackId);
			$.each(callbacks, function(i, callback) {
				if (callback) {
					callback(true);
				}
			});
			target.removeData('loadCallbacks');
		},
		error: function(jqXHR, textStatus, error) {
			var callbacks = target.data('loadCallbacks') || [];
			target.data('loading', false);
			$.each(callbacks, function(i, callback) {
				if (callback) {
					callback(false);
				}
			});
			target.removeData('loadCallbacks');
			handleFail(jqXHR, textStatus, error, 'loading orphaned structural containers');
		}
	});
}

/**
 * Open the shared rich picker dialog to select a child container and place it into an empty position.
 * @param {number|string} positionContainerId - container_id for the empty position container.
 * @param {string} positionLabel - display label for the position container.
 * @param {string} targetDivId - id of the positions panel to refresh after placement.
 * @param {string} feedbackId - optional feedback element id for status updates.
 * @param {Function} onPlaced - optional callback invoked after a successful placement.
 * @returns {void}
 */
function openPositionPlacementDialog(positionContainerId, positionLabel, targetDivId, feedbackId, onPlaced) {
	openContainerPickerDialog({
		mode: 'child',
		dialogTitle: 'Place Container into Position ' + (positionLabel || ''),
		childContainerIdForValidation: null,
		parentContainerIdForValidation: positionContainerId,
		feedbackId: feedbackId,
		onSelect: function(selectedId, selectedLabel, wrapper, controls) {
			$.ajax({
				url: '/containers/component/public.cfc',
				type: 'post',
				dataType: 'json',
				data: {
					method: 'moveContainerById',
					returnformat: 'json',
					child_container_id: selectedId,
					parent_container_id: positionContainerId
				},
				success: function(result) {
					if (result && result.status === 'moved') {
						if (feedbackId) {
							setFeedbackControlState(feedbackId, 'saved', 'Container placed.');
						}
						wrapper.dialog('close');
						if (onPlaced) {
							onPlaced();
						}
					} else {
						var message = (result && result.message) ? result.message : 'Unable to place selected container.';
						if (feedbackId) {
							setFeedbackControlState(feedbackId, 'error', message);
						}
						$('#' + controls.validationControlId).html($('<div class="alert alert-danger py-1 px-2 mb-0"></div>').text(message));
					}
				},
				error: function(jqXHR, textStatus, error) {
					handleFail(jqXHR, textStatus, error, 'placing container into position');
				}
			});
		}
	});
}

/**
 * Opens the shared rich picker dialog and places a selected child into a parent container.
 * @param {number|string} parentContainerId - destination parent container_id.
 * @param {string} parentDisplayLabel - display label for dialog title and success feedback.
 * @param {string} institutionAcronym - optional institution acronym used to scope picker search.
 * @param {string} feedbackId - optional feedback output element id.
 * @param {string} contentsTargetDivId - optional contents target to reload after successful placement.
 * @returns {void}
 */
function openPlaceChildIntoContainerDialog(parentContainerId, parentDisplayLabel, institutionAcronym, feedbackId, contentsTargetDivId) {
	var display = parentDisplayLabel || '';
	openContainerPickerDialog({
		mode: 'child',
		dialogTitle: 'Place Child into ' + (display || 'Container'),
		parentContainerIdForValidation: parentContainerId,
		institutionAcronym: institutionAcronym || '',
		feedbackId: feedbackId,
		onSelect: function(selectedId, selectedLabel, wrapper, controls) {
			$.ajax({
				url: '/containers/component/public.cfc',
				type: 'post',
				dataType: 'json',
				data: {
					method: 'moveContainerById',
					returnformat: 'json',
					child_container_id: selectedId,
					parent_container_id: parentContainerId
				},
				success: function(result) {
					if (result && result.status === 'moved') {
						if (feedbackId) {
							setFeedbackControlState(feedbackId, 'saved', 'Container placed.');
						}
						wrapper.dialog('close');
						if (contentsTargetDivId) {
							loadContainerContentsSection(parentContainerId, contentsTargetDivId, feedbackId);
						}
					} else {
						var message = (result && result.message) ? result.message : 'Unable to place selected container.';
						if (feedbackId) {
							setFeedbackControlState(feedbackId, 'error', message);
						}
						$('#' + controls.validationControlId).html($('<div class="alert alert-danger py-1 px-2 mb-0"></div>').text(message));
					}
				},
				error: function(jqXHR, textStatus, error) {
					handleFail(jqXHR, textStatus, error, 'placing child container');
				}
			});
		}
	});
}

/**
 * Handles a barcode scanned or typed into an empty position's input on the positions grid.
 * Looks the barcode up server-side and, if it matches an existing container, places that
 * container into the given position, then reloads the grid and moves focus to the next
 * remaining empty position's input so a user can keep scanning without touching the mouse.
 * If that was the last empty position, there is no next input to focus, so focus moves instead to the
 * positions heading, whose text loadPositionsGrid has already updated to note none remain.
 *
 * @param {jQuery} inputEl - jQuery-wrapped input element that received the scanned barcode.
 * @param {number|string} positionContainerId - container_id of the empty position being filled.
 * @param {number|string} containerId - container_id of the container whose positions are shown.
 * @param {number} numPositions - declared position count, used to choose the grid layout on reload.
 * @param {string} targetDivId - id of the panel the positions grid is rendered into.
 * @param {string} feedbackId - optional feedback element id for transport-failure reporting.
 * @param {boolean} canEditPositions - whether scan-to-place inputs should render after reload.
 * @param {string} headingId - id of the "Positions" heading, focused as a fallback when no
 *	empty position remains to receive focus after this scan.
 * @returns {void}
 */
function handlePositionBarcodeScan(inputEl, positionContainerId, containerId, numPositions, targetDivId, feedbackId, canEditPositions, headingId) {
	var barcode = $.trim(inputEl.val());
	var errorTarget = inputEl.closest('td, .positions-grid-cell').find('.positions-grid-barcode-error');
	errorTarget.text('');
	if (!barcode) {
		return;
	}
	inputEl.prop('disabled', true);
	$.ajax({
		url: '/containers/component/functions.cfc',
		type: 'post',
		dataType: 'json',
		data: {
			method: 'placeContainerIntoPositionByBarcode',
			returnformat: 'json',
			barcode: barcode,
			position_container_id: positionContainerId
		},
		success: function(result) {
			if (result && result.status === 'moved') {
				loadPositionsGrid(containerId, numPositions, targetDivId, feedbackId, canEditPositions, headingId, function() {
					var nextInput = $('#' + targetDivId + ' .positions-grid-barcode-input:enabled').first();
					if (nextInput.length) {
						nextInput.trigger('focus');
					} else if (headingId) {
						$('#' + headingId).trigger('focus');
					}
				});
			} else {
				var message = (result && result.message) ? result.message : 'Unable to place scanned container.';
				errorTarget.text(message);
				inputEl.prop('disabled', false);
				inputEl.trigger('focus');
				inputEl.trigger('select');
			}
		},
		error: function(jqXHR, textStatus, error) {
			inputEl.prop('disabled', false);
			handleFail(jqXHR, textStatus, error, 'placing scanned container into position');
		}
	});
}

/**
 * Renders a positions grid or fallback table for one container. Empty positions render as a
 * read-only "Empty" cell with a Place… action, unless canEditPositions is true, in which case
 * they also render a barcode-scan input bound to handlePositionBarcodeScan (the Place… action
 * and the bold position number are unchanged either way).
 * @param {Array} positions - ordered position rows returned from getContainerPositionsGrid.
 * @param {number} numPositions - declared position count used to choose a known layout.
 * @param {string} targetDivId - id of the panel that should receive the rendered layout.
 * @param {string} feedbackId - optional feedback element id for details-dialog failures.
 * @param {number|string} containerId - container_id whose positions are being rendered.
 * @param {boolean} canEditPositions - whether to render scan-to-place inputs for empty positions.
 * @param {string} headingId - id of the "Positions" heading, forwarded to reload calls
 *	triggered from within this grid so its "(all occupied)" text stays current.
 */
/**
 * Function renderCreatePositionsPrompt renders a "Create N Positions" button, for a container
 * that declares a non-zero number_positions but has no container_type='position' children yet.
 * Reached only from Container.cfm's edit-page Positions summary box -- creation is not offered
 * from viewContainer.cfm, which shows a plain "edit to add" message instead once declared.
 * createContainerPositions only supports a handful of known box/rack presets, so a non-"created"
 * response is handled inline rather than assumed to always succeed: "unsupported" offers a
 * columns count to lay out an arbitrary grid instead, and "exists" (the container already holds
 * content directly, not via positions) offers Retrofit.
 * @param {number} numPositions - declared position count.
 * @param {string} targetDivId - id of the panel to render into.
 * @param {string} feedbackId - optional feedback element id, forwarded to the grid reload.
 * @param {number|string} containerId - container_id to create positions for.
 * @param {boolean} canEditPositions - forwarded to the grid reload once positions exist.
 * @param {string} headingId - forwarded to the grid reload so its heading text stays current.
 * @param {Function} [onCreated] - called instead of reloading the positions grid once creation
 *	succeeds -- Container.cfm has no grid on the page to reload, so it uses this to update its
 *	own Positions summary text/link instead.
 */
function renderCreatePositionsPrompt(numPositions, targetDivId, feedbackId, containerId, canEditPositions, headingId, onCreated) {
	var target = $('#' + targetDivId);
	var wrapper = $('<div></div>');
	var $errorDiv = $('<div class="small text-danger mb-2 d-none" role="alert"></div>');
	var $followUpDiv = $('<div class="mb-2"></div>');
	var $createBtn = $('<button class="btn btn-xs btn-primary" type="button"></button>').text('Create ' + numPositions + ' Positions');

	var refresh = function() {
		loadPositionsGrid(containerId, numPositions, targetDivId, feedbackId, canEditPositions, headingId);
	};

	// shared by the "unsupported" (createContainerPositions) and "needs_columns"
	// (retrofitContainerPositions) cases -- neither knows a physical layout for this
	// type/count combination without an explicit columns count from the user. A dialog
	// (rather than an inline prompt) since the explanatory message is long enough to want
	// its own space, and Cancel needs to mean "never mind" rather than just "clear this field".
	var promptForColumnsDialog = function(message, onColumnsChosen) {
		var inputId = 'positionsColumnsDialogInput_' + targetDivId;
		var $body = $('<div></div>');
		$body.append($('<p class="mb-3"></p>').text(message));
		var $row = $('<div class="form-row align-items-center mb-2"></div>');
		$row.append(
			$('<div class="col-auto"></div>').append(
				$('<label class="data-entry-label mb-0"></label>').attr('for', inputId).text('Columns')
			)
		);
		var $columnsInput = $('<input type="text" inputmode="numeric" class="data-entry-input" style="width:5em;">').attr('id', inputId);
		$row.append($('<div class="col-auto"></div>').append($columnsInput));
		$body.append($row);
		var $columnsError = $('<p class="small text-danger mb-0 d-none" role="alert"></p>');
		$body.append($columnsError);

		var submit = function() {
			var columns = parseInt($columnsInput.val(), 10);
			if (!columns || columns < 1) {
				$columnsError.text('Enter a positive number of columns.').removeClass('d-none');
				return;
			}
			$body.dialog('destroy');
			onColumnsChosen(columns);
		};
		$columnsInput.on('keydown', function(event) {
			if (event.which === 13) {
				event.preventDefault();
				submit();
			}
		});

		$body.dialog({
			modal: true,
			resizable: false,
			draggable: true,
			width: 'auto',
			minWidth: 340,
			title: 'Columns Needed',
			buttons: {
				Continue: submit,
				Cancel: function() {
					$(this).dialog('destroy');
				}
			},
			close: function() {
				$(this).dialog('destroy');
			},
			open: function() {
				var maxZindex = getMaxZIndex();
				$('.ui-dialog').css({ 'z-index': maxZindex + 6 });
				$('.ui-widget-overlay').css({ 'z-index': maxZindex + 5 });
				$columnsInput.trigger('focus');
			}
		});
	};

	var createPositions = function(columns) {
		$createBtn.prop('disabled', true);
		$errorDiv.addClass('d-none').text('');
		var data = { method: 'createContainerPositions', container_id: containerId };
		if (columns) {
			data.columns = columns;
		}
		$.ajax({
			url: '/containers/component/functions.cfc',
			method: 'POST',
			data: data,
			dataType: 'json',
			success: function(result) {
				$createBtn.prop('disabled', false);
				if (result.status === 'created') {
					if (typeof onCreated === 'function') {
						onCreated(result);
					} else {
						refresh();
					}
					return;
				}
				if (result.status === 'unsupported') {
					promptForColumnsDialog(result.message || 'Provide a columns count to lay out an arbitrary grid.', createPositions);
					return;
				}
				$errorDiv.text(result.message || 'Unable to create positions.').removeClass('d-none');
				if (result.status === 'exists') {
					offerRetrofit();
				}
			},
			error: function(jqXHR, textStatus, error) {
				handleFail(jqXHR, textStatus, error, 'creating container positions');
				$createBtn.prop('disabled', false);
			}
		});
	};

	var retrofitPositions = function(columns) {
		$errorDiv.addClass('d-none').text('');
		var data = { method: 'retrofitContainerPositions', container_id: containerId };
		if (columns) {
			data.columns = columns;
		}
		$.ajax({
			url: '/containers/component/functions.cfc',
			method: 'POST',
			data: data,
			dataType: 'json',
			success: function(result) {
				if (result.status === 'retrofitted') {
					var childrenFound = parseInt(result.children_found, 10) || 0;
					var childrenReparented = parseInt(result.children_reparented, 10) || 0;
					var childrenUnmatched = childrenFound - childrenReparented;
					var summary = 'Created ' + result.positions_created + ' position(s).';
					if (childrenFound > 0) {
						summary += ' Placed ' + childrenReparented + ' of ' + childrenFound + ' existing item(s) into their matching position automatically.';
					}
					if (childrenUnmatched > 0) {
						// no trailing digits found in that item's label or barcode to match it to a
						// position number -- nothing left to guess, so it stays where it is until
						// someone moves it by hand.
						summary += ' ' + childrenUnmatched + ' item(s) had no recognizable position number in their label or barcode and were left in place -- find the still-empty position(s) below and use its "Place…" button to move each one in manually.';
					}
					messageDialog(summary, 'Retrofit Complete');
					refresh();
					return;
				}
				if (result.status === 'needs_columns') {
					promptForColumnsDialog(result.message || 'Provide a columns count to lay out an arbitrary grid.', retrofitPositions);
					return;
				}
				$errorDiv.text(result.message || 'Unable to retrofit positions.').removeClass('d-none');
			},
			error: function(jqXHR, textStatus, error) {
				handleFail(jqXHR, textStatus, error, 'retrofitting container positions');
			}
		});
	};

	var offerRetrofit = function() {
		$followUpDiv.empty();
		var $retrofitBtn = $('<button class="btn btn-xs btn-secondary" type="button"></button>').text('Retrofit Existing Contents into Positions');
		$retrofitBtn.on('click', function() {
			confirmDialog(
				'This will create ' + numPositions + ' position container(s) and move this container\'s existing numbered contents into the matching position. Continue?',
				'Retrofit into Positions',
				function() {
					retrofitPositions();
				}
			);
		});
		$followUpDiv.append($retrofitBtn);
	};

	$createBtn.on('click', function() {
		$followUpDiv.empty();
		createPositions();
	});
	wrapper.append($createBtn).append($errorDiv).append($followUpDiv);
	target.html(wrapper);
}

function renderPositionsGrid(positions, numPositions, targetDivId, feedbackId, containerId, canEditPositions, headingId) {
	var target = $('#' + targetDivId);
	var layoutClassMap = {
		25: 'positions-grid-5x5',
		81: 'positions-grid-9x9',
		100: 'positions-grid-10x10',
		48: 'positions-grid-12x4',
		33: 'positions-grid-11x3'
	};
	var layoutClass = layoutClassMap[parseInt(numPositions, 10)] || '';
	if (!positions || positions.length === 0) {
		if (parseInt(numPositions, 10) > 0) {
			var $notCreatedMsg = $('<p class="text-muted mb-0"></p>').text('This container declares ' + numPositions + ' position(s), but none have been created yet.');
			if (canEditPositions) {
				$notCreatedMsg.append(' ').append(
					$('<a></a>')
						.attr('href', '/containers/Container.cfm?action=edit&container_id=' + encodeURIComponent(containerId))
						.text('Edit to add.')
				);
			}
			target.html($notCreatedMsg);
		} else {
			target.html('<p class="text-muted mb-0">No position containers found.</p>');
		}
		return;
	}
	if (!layoutClass) {
		var tbody = $('<tbody></tbody>');
		$.each(positions, function(i, position) {
			var detailContainerId = position.content_container_id || position.position_id;
			var isEmptyPosition = !position.content_container_id;
			var occupantDisplay = position.content_container_id
				? formatContainerDisplay(position.content_barcode, position.content_label)
				: 'Empty';
			var inputId = 'positionsGridFallbackInput_' + targetDivId + '_' + position.position_id;
			var labelCell = $('<td></td>');
			var occupantCell = $('<td></td>');
			if (isEmptyPosition && canEditPositions) {
				labelCell.append($('<label></label>').attr('for', inputId).text(position.position_label || ''));
				occupantCell.append(
					$('<input type="text" class="positions-grid-barcode-input data-entry-input">')
						.attr('id', inputId)
						.attr('placeholder', 'Empty')
						.on('change', function() {
							handlePositionBarcodeScan($(this), position.position_id, containerId, numPositions, targetDivId, feedbackId, canEditPositions, headingId);
						})
				);
				occupantCell.append($('<div class="small text-danger positions-grid-barcode-error" role="alert"></div>'));
			} else {
				labelCell.text(position.position_label || '');
				occupantCell.text(occupantDisplay);
			}
			var actionCell = $('<td></td>');
			if (isEmptyPosition) {
				actionCell.append(
					$('<button class="btn btn-xs btn-primary" type="button"></button>')
						.attr('aria-label', 'Place a container into this position')
						.text('Place…')
						.on('click', function() {
							openPositionPlacementDialog(position.position_id, position.position_label, targetDivId, feedbackId, function() {
								loadPositionsGrid(containerId, numPositions, targetDivId, feedbackId, canEditPositions, headingId);
							});
						})
				);
				actionCell.append(
					$('<button class="btn btn-xs btn-outline-info ml-1" type="button"></button>')
						.text('Details')
						.on('click', function() {
							openContainerDetailsDialog(detailContainerId, occupantDisplay, feedbackId, false);
						})
				);
			} else {
				actionCell.append(
					$('<button class="btn btn-xs btn-outline-info" type="button"></button>')
						.text('Details')
						.on('click', function() {
							openContainerDetailsDialog(detailContainerId, occupantDisplay, feedbackId, false);
						})
				);
			}
			var tr = $('<tr></tr>');
			tr.append(labelCell);
			tr.append(occupantCell);
			tr.append($('<td></td>').text(position.content_container_type || ''));
			tr.append(actionCell);
			tbody.append(tr);
		});
		var table = $('<table class="table table-sm table-striped positions-grid-fallback"></table>');
		table.append('<thead><tr><th>Position</th><th>Occupant</th><th>Occupant Type</th><th>Actions</th></tr></thead>');
		table.append(tbody);
		target.html(table);
		return;
	}
	var wrapper = $('<div class="positions-grid-wrapper"></div>');
	var grid = $('<div class="positions-grid"></div>').addClass(layoutClass);
	$.each(positions, function(i, position) {
		var detailContainerId = position.content_container_id || position.position_id;
		var isEmptyPosition = !position.content_container_id;
		var occupantDisplay = position.content_container_id
			? formatContainerDisplay(position.content_barcode, position.content_label)
			: 'Empty';
		var inputId = 'positionsGridBarcodeInput_' + targetDivId + '_' + position.position_id;
		if (isEmptyPosition && canEditPositions) {
			var cell = $('<div class="positions-grid-cell positions-grid-cell-empty"></div>');
			cell.append(
				$('<label class="positions-grid-label"></label>')
					.attr('for', inputId)
					.text(position.position_label || '')
					.on('click', function(event) {
						event.stopPropagation();
					})
			);
			cell.append(
				$('<input type="text" class="positions-grid-barcode-input data-entry-input">')
					.attr('id', inputId)
					.attr('placeholder', 'Empty')
					.on('click', function(event) {
						event.stopPropagation();
					})
					.on('change', function() {
						handlePositionBarcodeScan($(this), position.position_id, containerId, numPositions, targetDivId, feedbackId, canEditPositions, headingId);
					})
			);
			cell.append($('<div class="small text-danger positions-grid-barcode-error" role="alert"></div>'));
			var openPlacementDialog = function() {
				openPositionPlacementDialog(position.position_id, position.position_label, targetDivId, feedbackId, function() {
					loadPositionsGrid(containerId, numPositions, targetDivId, feedbackId, canEditPositions, headingId);
				});
			};
			cell.append(
				$('<span class="positions-grid-type small"></span>')
					.text('Place container')
					.attr('role', 'button')
					.attr('tabindex', '0')
					.on('keydown', function(event) {
						if (event.key === 'Enter' || event.key === ' ' || event.key === 'Spacebar') {
							event.preventDefault();
							event.stopPropagation();
							openPlacementDialog();
						}
					})
			);
			cell.on('click', openPlacementDialog);
			grid.append(cell);
		} else {
			var cell = $('<button class="positions-grid-cell" type="button"></button>');
			if (isEmptyPosition) {
				cell.addClass('positions-grid-cell-empty');
				var positionLabelText = position.position_label || 'this position';
				cell.attr('aria-label', 'Empty position ' + positionLabelText);
				cell.attr('title', 'Place a container into this empty position');
			}
			cell.append($('<span class="positions-grid-label"></span>').text(position.position_label || ''));
			cell.append($('<span class="positions-grid-occupant small text-muted"></span>').text(occupantDisplay));
			if (position.content_container_type) {
				cell.append($('<span class="positions-grid-type small text-muted"></span>').text(position.content_container_type));
			}
			if (isEmptyPosition) {
				cell.append($('<span class="positions-grid-type small"></span>').text('Place container'));
				cell.on('click', function() {
					openPositionPlacementDialog(position.position_id, position.position_label, targetDivId, feedbackId, function() {
						loadPositionsGrid(containerId, numPositions, targetDivId, feedbackId, canEditPositions, headingId);
					});
				});
			} else {
				cell.on('click', function() {
					openContainerDetailsDialog(detailContainerId, occupantDisplay, feedbackId, false);
				});
			}
			grid.append(cell);
		}
	});
	wrapper.append(grid);
	target.html(wrapper);
}

/**
 * Loads the positions payload for one container and renders the matching grid/table view. Also
 * updates the "Positions" heading to note when every position is occupied, since this is the
 * one place that both refetches current occupancy and knows which heading goes with it -- this
 * runs on every load, regardless of why the grid is loading, so the heading is always accurate.
 * @param {number} containerId - the container_id whose positions should be loaded.
 * @param {number} numPositions - fallback declared position count from the initial page payload.
 * @param {string} targetDivId - id of the panel that should receive the rendered layout.
 * @param {string} feedbackId - optional feedback element id for AJAX failures.
 * @param {boolean} canEditPositions - whether to render scan-to-place inputs for empty positions.
 * @param {string} headingId - optional id of the "Positions" heading to keep in sync with
 *	occupancy; when omitted the heading text is left alone.
 * @param {Function} onRendered - optional callback invoked after the grid/table has been rendered.
 */
function loadPositionsGrid(containerId, numPositions, targetDivId, feedbackId, canEditPositions, headingId, onRendered) {
	$('#' + targetDivId).html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading...</div>');
	$.ajax({
		url: '/containers/component/public.cfc',
		data: {
			method: 'getContainerPositionsGrid',
			container_id: containerId
		},
		dataType: 'json',
		success: function(data) {
			var positions = data.positions || [];
			renderPositionsGrid(positions, parseInt(data.number_positions, 10) || numPositions, targetDivId, feedbackId, containerId, canEditPositions, headingId);
			if (headingId) {
				var allOccupied = positions.length > 0 && positions.every(function(position) {
					return !!position.content_container_id;
				});
				$('#' + headingId).text(allOccupied ? 'Positions (all occupied)' : 'Positions');
			}
			if (typeof onRendered === 'function') {
				onRendered();
			}
		},
		error: function(jqXHR, textStatus, error) {
			if (feedbackId) {
				setFeedbackControlState(feedbackId, 'error');
			}
			handleFail(jqXHR, textStatus, error, 'loading container positions');
		}
	});
}

/**
 * Known (number_positions, container_type) presets with established physical dimensions --
 * mirrors containers/component/functions.cfc's createContainerPositions preset table, so the
 * positions-change dialog can warn that growing/shrinking a standard box/rack's position count
 * usually isn't what's wanted, since that physical hardware has a fixed number of slots.
 */
var KNOWN_POSITION_PRESETS = [
	{ containerType: 'freezer box', numberPositions: 100 },
	{ containerType: 'freezer box', numberPositions: 81 },
	{ containerType: 'freezer box', numberPositions: 25 },
	{ containerType: 'freezer', numberPositions: 48 },
	{ containerType: 'freezer', numberPositions: 33 }
];

/**
 * Opens a dialog with Grow/Shrink/Reset controls for one container's positions -- reached from
 * Container.cfm's "Change..." button next to the Number of Positions field. Deliberately not
 * shown inline on the edit form or on the read-only positions grid (viewContainer.cfm).
 * Grow and Shrink don't commit anything here -- when onChanged is supplied, clicking either one
 * just validates, reports the pending change back to the caller, and closes the dialog, leaving
 * the actual growContainerPositions/trimContainerPositions call for the caller to run whenever it
 * sees fit (Container.cfm defers it to its own Save Changes button). Reset is the exception: it
 * still commits immediately from within this dialog (it's confirmDialog-gated and destructive
 * enough that queuing it doesn't make sense the same way).
 * @param {number|string} containerId - container_id whose positions are being managed.
 * @param {Function} [onChanged] - called with a descriptor once Grow, Shrink, or Reset succeeds:
 *	{action: 'grow'|'shrink', previewCount, params} for Grow/Shrink (not yet applied -- params is
 *	the argument object the caller should eventually POST to growContainerPositions/
 *	trimContainerPositions), or {action: 'reset'} for Reset (already applied).
 */
function openPositionsChangeDialog(containerId, onChanged) {
	var wrapper = $('#positionsChangeDialogWrapper');
	if (!wrapper.length) {
		wrapper = $('<div id="positionsChangeDialogWrapper"></div>').appendTo('body');
	}
	wrapper.html('<div class="text-center my-2"><img src="/shared/images/indicator.gif"> Loading…</div>');
	wrapper.dialog({
		title: 'Change Positions',
		modal: true,
		width: 420,
		autoOpen: true,
		buttons: {
			Close: function() {
				$(this).dialog('close');
			}
		},
		open: function() {
			var maxZindex = getMaxZIndex();
			$('.ui-dialog').css({ 'z-index': maxZindex + 6 });
			$('.ui-widget-overlay').css({ 'z-index': maxZindex + 5 });
		}
	});

	var render = function() {
		$.ajax({
			url: '/containers/component/public.cfc',
			data: {
				method: 'getContainerPositionsGrid',
				container_id: containerId
			},
			dataType: 'json',
			success: function(data) {
				var positions = data.positions || [];
				var numberPositions = parseInt(data.number_positions, 10) || 0;
				var occupiedCount = positions.filter(function(position) {
					return !!position.content_container_id;
				}).length;
				var allEmpty = positions.length > 0 && occupiedCount === 0;
				// trimContainerPositions removes from the highest-numbered position down, so
				// shrinking by even 1 is only ever possible when that last position is empty.
				var canShrink = positions.length > 0 && !positions[positions.length - 1].content_container_id;
				var isKnownPreset = KNOWN_POSITION_PRESETS.some(function(preset) {
					return preset.containerType === data.container_type && preset.numberPositions === numberPositions;
				});

				var content = $('<div></div>');
				content.append(
					$('<p class="small mb-2"></p>').text(
						numberPositions + ' position(s) declared; ' + positions.length + ' created' +
						(positions.length > 0 ? ' (' + occupiedCount + ' occupied)' : '') + '.'
					)
				);
				if (isKnownPreset) {
					content.append(
						$('<div class="alert alert-warning small py-1 px-2"></div>').text(
							'This is a standard ' + numberPositions + '-position ' + data.container_type +
							' -- growing or shrinking it usually isn\'t what you want, since the physical hardware has a fixed number of slots.'
						)
					);
				}

				var $error = $('<div class="small text-danger mb-2 d-none" role="alert"></div>');

				var $growInput = $('<input type="text" inputmode="numeric" class="data-entry-input mr-1" style="width:5em;">').attr('aria-label', 'Number of positions to add');
				var $growBtn = $('<button class="btn btn-xs btn-secondary" type="button"></button>').text('Grow');
				$growBtn.on('click', function() {
					var additionalCount = parseInt($growInput.val(), 10);
					if (!additionalCount || additionalCount < 1) {
						$error.text('Enter a positive number of positions to add.').removeClass('d-none');
						return;
					}
					if (onChanged) {
						// defer the actual growContainerPositions call to Save Changes instead of
						// committing it the moment Grow is clicked -- the caller (Container.cfm)
						// queues this and applies it after the regular field save succeeds.
						onChanged({
							action: 'grow',
							previewCount: numberPositions + additionalCount,
							params: { additional_count: additionalCount }
						});
						wrapper.dialog('close');
						return;
					}
					$growBtn.prop('disabled', true);
					$.ajax({
						url: '/containers/component/functions.cfc',
						type: 'post',
						dataType: 'json',
						data: {
							method: 'growContainerPositions',
							returnformat: 'json',
							container_id: containerId,
							additional_count: additionalCount
						},
						success: function(result) {
							$growBtn.prop('disabled', false);
							if (result.status === 'created') {
								render();
							} else {
								$error.text(result.message || 'Unable to grow positions.').removeClass('d-none');
							}
						},
						error: function(jqXHR, textStatus, error) {
							$growBtn.prop('disabled', false);
							handleFail(jqXHR, textStatus, error, 'growing container positions');
						}
					});
				});
				var growRow = $('<div class="d-flex align-items-center mb-2"></div>')
					.append($('<label class="mb-0 mr-1"></label>').text('Add:'))
					.append($growInput)
					.append($growBtn);

				var $shrinkInput = $('<input type="text" inputmode="numeric" class="data-entry-input mr-1" style="width:5em;">').attr('aria-label', 'Number of empty positions to remove from the end');
				var $shrinkBtn = $('<button class="btn btn-xs btn-secondary" type="button"></button>').text('Shrink');
				if (!canShrink) {
					$shrinkInput.prop('disabled', true);
					$shrinkBtn.prop('disabled', true);
				}
				$shrinkBtn.on('click', function() {
					var removeCount = parseInt($shrinkInput.val(), 10);
					if (!removeCount || removeCount < 1) {
						$error.text('Enter a positive number of positions to remove.').removeClass('d-none');
						return;
					}
					var newCount = numberPositions - removeCount;
					if (newCount < 0) {
						$error.text('Cannot remove more positions than currently declared.').removeClass('d-none');
						return;
					}
					if (onChanged) {
						// see the matching comment in the Grow handler above -- defer the actual
						// trimContainerPositions call to Save Changes instead of committing now.
						onChanged({
							action: 'shrink',
							previewCount: newCount,
							params: { new_count: newCount }
						});
						wrapper.dialog('close');
						return;
					}
					$shrinkBtn.prop('disabled', true);
					$.ajax({
						url: '/containers/component/functions.cfc',
						type: 'post',
						dataType: 'json',
						data: {
							method: 'trimContainerPositions',
							returnformat: 'json',
							container_id: containerId,
							new_count: newCount
						},
						success: function(result) {
							$shrinkBtn.prop('disabled', false);
							if (result.status === 'trimmed') {
								render();
							} else {
								$error.text(result.message || 'Unable to shrink positions.').removeClass('d-none');
							}
						},
						error: function(jqXHR, textStatus, error) {
							$shrinkBtn.prop('disabled', false);
							handleFail(jqXHR, textStatus, error, 'shrinking container positions');
						}
					});
				});
				var shrinkRow = $('<div class="d-flex align-items-center mb-2"></div>')
					.append($('<label class="mb-0 mr-1"></label>').text('Remove from end:'))
					.append($shrinkInput)
					.append($shrinkBtn);

				content.append(growRow).append(shrinkRow);
				if (!canShrink) {
					content.append(
						$('<p class="small text-muted mb-2"></p>').text(
							positions.length === 0
								? 'Nothing to shrink -- no positions exist yet.'
								: 'Cannot shrink -- the last position is occupied. Move its contents first.'
						)
					);
				}
				content.append($error);

				// only offer Reset when it could actually succeed -- resetContainerPositions
				// itself refuses outright if even one position is occupied.
				if (allEmpty) {
					var $resetBtn = $('<button class="btn btn-xs btn-warning" type="button"></button>').text('Reset Positions');
					$resetBtn.on('click', function() {
						confirmDialog(
							'This will permanently delete all ' + numberPositions + ' position record(s) for this container and clear its Number of Positions. Continue?',
							'Reset Positions',
							function() {
								$resetBtn.prop('disabled', true);
								$.ajax({
									url: '/containers/component/functions.cfc',
									type: 'post',
									dataType: 'json',
									data: {
										method: 'resetContainerPositions',
										returnformat: 'json',
										container_id: containerId
									},
									success: function(result) {
										$resetBtn.prop('disabled', false);
										if (result.status === 'reset') {
											// unlike Grow/Shrink, Reset still commits immediately from
											// within the dialog (it's already confirmDialog-gated and
											// wipes the positions outright) -- the caller reloads the
											// page right away rather than queuing anything for Save.
											if (onChanged) {
												onChanged({ action: 'reset' });
											}
											wrapper.dialog('close');
										} else {
											messageDialog('Error: ' + (result.message || 'Unable to reset positions.'), 'Error Resetting Positions');
										}
									},
									error: function(jqXHR, textStatus, error) {
										$resetBtn.prop('disabled', false);
										handleFail(jqXHR, textStatus, error, 'resetting container positions');
									}
								});
							}
						);
					});
					content.append($('<div class="mt-2"></div>').append($resetBtn));
				}

				wrapper.html(content);
			},
			error: function(jqXHR, textStatus, error) {
				wrapper.html('<p class="text-danger small mb-0">Unable to load position information.</p>');
				handleFail(jqXHR, textStatus, error, 'loading container positions for the change dialog');
			}
		});
	};
	render();
}

/* These placement-heavy structural levels were explicitly requested to keep direct
   proxy/leaf-bearing child containers hidden behind nested browse toggles. */
var PLACED_CHILD_SECTION_TYPES = ['campus', 'building', 'floor', 'room'];

/**
 * Determines whether direct placed children should be hidden behind secondary toggle sections.
 * @param {string} parentContainerType - type of the structural parent being rendered.
 * @returns {boolean} true for placement-heavy structural levels that group non-structural children.
 */
function shouldGroupPlacedChildNodes(parentContainerType) {
	return PLACED_CHILD_SECTION_TYPES.indexOf((parentContainerType || '').toLowerCase()) !== -1;
}

/**
 * Splits child nodes into structural, empty placed, and occupied placed groups for rendering.
 * @param {Array} nodes - child nodes returned for one structural parent.
 * @param {string} parentContainerType - type of the structural parent being rendered.
 * @returns {Object} grouped node arrays keyed as structuralNodes, emptyPlacedNodes, and occupiedPlacedNodes.
 */
function splitPlacedChildNodes(nodes, parentContainerType) {
	var grouped = {
		structuralNodes: nodes || [],
		emptyPlacedNodes: [],
		occupiedPlacedNodes: []
	};
	if (!shouldGroupPlacedChildNodes(parentContainerType)) {
		return grouped;
	}
	grouped.structuralNodes = [];
	$.each(nodes || [], function(i, node) {
		var role = getContainerRole(node.container_type || '');
		var structuralChildren = parseInt(node.direct_structural_children, 10) || 0;
		var leafChildren = parseInt(node.direct_leaf_children, 10) || 0;
		if (role === 'structural') {
			grouped.structuralNodes.push(node);
		} else if (structuralChildren === 0 && leafChildren === 0) {
			grouped.emptyPlacedNodes.push(node);
		} else {
			grouped.occupiedPlacedNodes.push(node);
		}
	});
	return grouped;
}

/**
 * Builds the button label for a grouped placed-child section.
 * @param {string} parentContainerType - type of the structural parent being rendered.
 * @param {string} sectionKind - grouping key, currently empty or occupied.
 * @param {Array} nodes - nodes that will be revealed by the section toggle.
 * @returns {string} human-readable section label with node count.
 */
function getPlacedChildSectionLabel(parentContainerType, sectionKind, nodes) {
	var parentType = parentContainerType || 'container';
	if (sectionKind === 'empty') {
		return 'Placed to ' + parentType + ' empty (' + nodes.length + ')';
	}
	var allProxy = $.grep(nodes, function(node) {
		return getContainerRole(node.container_type || '') === 'proxy';
	}).length === nodes.length;
	return 'Placed to ' + parentType + ' ' + (allProxy ? 'single-occupant' : 'occupied') + ' (' + nodes.length + ')';
}

/**
 * Opens any hidden grouped sections that contain a target node already rendered in the DOM.
 * @param {number} containerId - the container_id whose ancestor section wrappers should be shown.
 */
function ensureTreeSectionVisibleForNode(containerId) {
	var nodePanel = $('#ctree-children-' + containerId);
	if (nodePanel.length === 0) {
		return;
	}
	nodePanel.parents('.container-tree-section-panel.d-none').each(function() {
		var sectionPanel = $(this);
		sectionPanel.removeClass('d-none');
		var toggleButton = $('[aria-controls="' + sectionPanel.attr('id') + '"]');
		if (toggleButton.length > 0) {
			toggleButton.attr('aria-expanded', 'true');
		}
	});
}

/**
 * Renders the top-level browse view, including institutions and orphan toggle sections.
 * @param {Object} data - payload returned from getTopLevelBrowse.
 * @param {string} browsePanel - id of the main hierarchy panel to populate.
 * @param {string} leafPanel - id of the leaf/table panel used by subordinate browse actions.
 * @param {string} feedbackEl - optional feedback element id for AJAX failures.
 */
function renderTopLevelBrowse(data, browsePanel, leafPanel, feedbackEl) {
	var institutions = data.institutions || [];
	var orphanStructCount = parseInt(data.orphaned_structural_count, 10) || 0;
	var orphanEmptyProxyCount = parseInt(data.orphaned_empty_proxy_count, 10) || 0;
	var orphanSingleCount = parseInt(data.orphaned_single_occupant_count, 10) || 0;
	var orphanLeafCount = parseInt(data.orphaned_leaf_count, 10) || 0;
	var topLevelOther = data.top_level_other || [];
	var orphanStructDivId = 'ctree-orphan-structural-panel';
	var wrapper = $('<div></div>');
	if (institutions.length === 0 && orphanStructCount === 0 && orphanEmptyProxyCount === 0 && orphanSingleCount === 0 && orphanLeafCount === 0 && topLevelOther.length === 0) {
		wrapper.html('<p class="text-muted my-2">No containers found.</p>');
		$('#' + browsePanel).html(wrapper);
		return;
	}
	if (institutions.length > 0) {
		var instUl = $('<ul class="container-tree" role="tree"></ul>');
		$.each(institutions, function(idx, inst) {
			var instDisplay = formatContainerDisplay(inst.barcode, inst.label);
			var instCid = inst.container_id;
			var campuses = inst.campus_children || [];
			var childUlId = 'ctree-children-' + instCid;
			var toggleId = 'ctree-toggle-' + instCid;
			var nodeRow = $('<div class="d-flex align-items-center flex-wrap tree-node-row"></div>');
			if (parseInt(inst.direct_structural_children, 10) > 0) {
				var instToggle = $('<button type="button"></button>')
					.attr('id', toggleId)
					.attr('aria-expanded', 'true')
					.attr('aria-controls', childUlId)
					.attr('aria-label', 'Collapse ' + instDisplay)
					.addClass('tree-node-toggle btn btn-xs btn-link mr-1');
				instToggle.on('click', function() {
					var expanded = $(this).attr('aria-expanded') === 'true';
					if (!expanded && $('#' + childUlId).children().length === 0) {
						loadContainerNode(instCid, childUlId, feedbackEl, inst.container_type);
					}
					$('#' + childUlId).toggleClass('collapse');
					$(this).attr('aria-expanded', expanded ? 'false' : 'true');
					$(this).attr('aria-label', expanded ? 'Expand ' + instDisplay : 'Collapse ' + instDisplay);
				});
				nodeRow.append(instToggle);
			}
			nodeRow.append($('<span class="tree-node-label"></span>').text(instDisplay));
			nodeRow.append(buildContainerTypeMeta(inst.container_type));
			nodeRow.append(buildContainerDetailsButton(instCid, instDisplay, feedbackEl));
			nodeRow.append(buildAddChildContainerLink(instCid, inst.container_type, TREE_ACTION_SPACING_CLASS));
			var instLeafDiv = null;
			if (parseInt(inst.direct_leaf_children, 10) > 0) {
				// REGRESSION FIX: unlike every other node type in this tree (campus nodes below,
				// and the generic renderTreeNodes() path used for root-level "external" containers),
				// this institution loop never checked direct_leaf_children at all -- an institution
				// with collection objects placed directly under it (misplaced, bypassing
				// campus/building/etc.) had NO way to browse them, even though the count was already
				// being computed and sent by getTopLevelBrowse. For the Museum of Comparative
				// Zoology institution node specifically, this count is ~170,000 -- that many
				// specimens' containers were unreachable through this page with no button anywhere
				// to get to them. Do not remove this block without providing an equivalent way to
				// browse an institution's own direct leaf children.
				var instLeafDivId = 'ctree-leaf-' + instCid;
				instLeafDiv = $('<div class="d-none mt-1"></div>').attr('id', instLeafDivId);
				var instBrowseBtn = $('<button type="button"></button>')
					.addClass('btn btn-xs btn-outline-secondary ml-1')
					.text('Browse contents')
					.on('click', (function(nodeId, nodeName, nodeBarcode, panelId) {
						return function() {
							var btn = $(this);
							var panel = $('#' + panelId);
							if (panel.hasClass('d-none')) {
								if (!btn.data('loaded')) {
									loadLeafPanel(nodeId, panelId, feedbackEl, 1, nodeName, nodeBarcode);
									btn.data('loaded', true);
								} else {
									panel.removeClass('d-none');
								}
								btn.text('Hide contents');
							} else {
								panel.addClass('d-none');
								btn.text('Browse contents');
							}
						};
					})(instCid, instDisplay, inst.barcode || '', instLeafDivId));
				nodeRow.append(instBrowseBtn);
			}
			var campusUl = $('<ul></ul>').attr('id', childUlId).addClass('container-tree');
			if (campuses.length > 0) {
				$.each(campuses, function(ci, campus) {
					var campusDisplay = formatContainerDisplay(campus.barcode, campus.label);
					var campusCid = campus.container_id;
					var campusChildId = 'ctree-children-' + campusCid;
					var campusTogId = 'ctree-toggle-' + campusCid;
					var campusRow = $('<div class="d-flex align-items-center flex-wrap tree-node-row"></div>');
					if (parseInt(campus.direct_structural_children, 10) > 0) {
						var campusToggle = $('<button type="button"></button>')
							.attr('id', campusTogId)
							.attr('aria-expanded', 'false')
							.attr('aria-controls', campusChildId)
							.attr('aria-label', 'Expand ' + campusDisplay)
							.addClass('tree-node-toggle btn btn-xs btn-link mr-1');
						campusToggle.on('click', function() {
							var expanded = $(this).attr('aria-expanded') === 'true';
							if (!expanded && $('#' + campusChildId).children().length === 0) {
								loadContainerNode(campusCid, campusChildId, feedbackEl, campus.container_type);
							}
							$('#' + campusChildId).toggleClass('collapse');
							$(this).attr('aria-expanded', expanded ? 'false' : 'true');
							$(this).attr('aria-label', expanded ? 'Expand ' + campusDisplay : 'Collapse ' + campusDisplay);
						});
						campusRow.append(campusToggle);
					}
					campusRow.append($('<span class="tree-node-label"></span>').text(campusDisplay));
					campusRow.append(buildContainerTypeMeta(campus.container_type));
					campusRow.append(buildContainerDetailsButton(campusCid, campusDisplay, feedbackEl));
					campusRow.append(buildAddChildContainerLink(campusCid, campus.container_type, TREE_ACTION_SPACING_CLASS));
					var campusLeafDiv = null;
					if (parseInt(campus.direct_leaf_children, 10) > 0) {
						var campusLeafDivId = 'ctree-leaf-' + campusCid;
						campusLeafDiv = $('<div class="d-none mt-1"></div>').attr('id', campusLeafDivId);
						var campusBrowseBtn = $('<button type="button"></button>')
							.addClass('btn btn-xs btn-outline-secondary ml-1')
							.text('Browse contents')
							.on('click', (function(nodeId, nodeName, nodeBarcode, panelId) {
								return function() {
									var btn = $(this);
									var panel = $('#' + panelId);
									if (panel.hasClass('d-none')) {
										if (!btn.data('loaded')) {
											loadLeafPanel(nodeId, panelId, feedbackEl, 1, nodeName, nodeBarcode);
											btn.data('loaded', true);
										} else {
											panel.removeClass('d-none');
										}
										btn.text('Hide contents');
									} else {
										panel.addClass('d-none');
										btn.text('Browse contents');
									}
								};
							})(campusCid, campusDisplay, campus.barcode || '', campusLeafDivId));
						campusRow.append(campusBrowseBtn);
					}
					var campusSpecEl = buildSpecimensButton(campusCid, campus.barcode || '', parseInt(campus.direct_leaf_children, 10) || 0, parseInt(campus.has_leaf_descendants, 10));
					if (campusSpecEl) { campusRow.append(campusSpecEl); }
					var campusChildUl = $('<ul></ul>').attr('id', campusChildId).addClass('collapse container-tree');
					var campusLi = $('<li role="treeitem"></li>')
						.attr('data-container-id', campusCid)
						.attr('data-parent-container-id', instCid)
						.append(campusRow);
					if (campusLeafDiv) {
						campusLi.append(campusLeafDiv);
					}
					campusLi.append(campusChildUl);
					campusUl.append(campusLi);
				});
			} else if (parseInt(inst.direct_structural_children, 10) > 0) {
				campusUl.addClass('collapse');
			}
			var instLi = $('<li role="treeitem"></li>').append(nodeRow);
			if (instLeafDiv) {
				instLi.append(instLeafDiv);
			}
			instLi.append(campusUl);
			instUl.append(instLi);
		});
		wrapper.append(instUl);
	}
	if (orphanStructCount > 0) {
		var orphanStructLabel = 'Structural orphans (' + orphanStructCount + ')';
		var orphanStructWrap = $('<div class="mt-2"></div>');
		var orphanStructBtn = $('<button class="btn btn-xs btn-outline-secondary" type="button"></button>')
			.attr('id', 'ctree-orphan-structural-btn')
			.attr('aria-expanded', 'false')
			.attr('aria-controls', orphanStructDivId)
			.text(orphanStructLabel);
		var orphanStructDiv = $('<div class="d-none mt-1" id="' + orphanStructDivId + '"></div>');
		orphanStructBtn.on('click', function() {
			toggleBrowseSection(this, orphanStructDivId, function() {
				loadStructuralOrphanPanel(orphanStructDivId, feedbackEl);
			});
		});
		orphanStructWrap.append(orphanStructBtn);
		orphanStructWrap.append($('<span class="small text-muted ml-1"></span>').text('Unplaced containers.'));
		orphanStructWrap.append(orphanStructDiv);
		wrapper.append(orphanStructWrap);
	}
	if (orphanEmptyProxyCount > 0) {
		var orphanEmptyDivId = 'ctree-orphan-empty';
		var orphanEmptyWrap = $('<div class="mt-2"></div>');
		var orphanEmptyBtn = $('<button class="btn btn-xs btn-outline-secondary mr-1" type="button"></button>')
			.attr('aria-expanded', 'false')
			.attr('aria-controls', orphanEmptyDivId)
			.text('Empty proxy orphans (' + orphanEmptyProxyCount + ')');
		var orphanEmptyDiv = $('<div class="d-none mt-1" id="' + orphanEmptyDivId + '"></div>');
		orphanEmptyBtn.on('click', function() {
			toggleBrowseSection(this, orphanEmptyDivId, function() {
				loadOrphanedEmptyProxyPage(orphanEmptyDivId, feedbackEl, 1);
			});
		});
		orphanEmptyWrap.append(orphanEmptyBtn);
		orphanEmptyWrap.append($('<span class="small text-muted ml-1"></span>').text('e.g. unplaced pins with no specimen.'));
		orphanEmptyWrap.append(orphanEmptyDiv);
		wrapper.append(orphanEmptyWrap);
	}
	if (orphanSingleCount > 0) {
		var orphanSingleDivId = 'ctree-orphan-single';
		var orphanSingleWrap = $('<div class="mt-2"></div>');
		var orphanSingleBtn = $('<button class="btn btn-xs btn-outline-secondary mr-1" type="button"></button>')
			.attr('aria-expanded', 'false')
			.attr('aria-controls', orphanSingleDivId)
			.text('Single-occupant orphans (' + orphanSingleCount + ')');
		var orphanSingleDiv = $('<div class="d-none mt-1" id="' + orphanSingleDivId + '"></div>');
		orphanSingleBtn.on('click', function() {
			toggleBrowseSection(this, orphanSingleDivId, function() {
				loadOrphanedSingleOccupantPage(orphanSingleDivId, feedbackEl, 1);
			});
		});
		orphanSingleWrap.append(orphanSingleBtn);
		orphanSingleWrap.append($('<span class="small text-muted ml-1"></span>').text('e.g. unplaced pin with a specimen.'));
		orphanSingleWrap.append(orphanSingleDiv);
		wrapper.append(orphanSingleWrap);
	}
	if (orphanLeafCount > 0) {
		// REGRESSION FIX: getTopLevelBrowse has computed orphaned_leaf_count all along, via the
		// same query shape as orphaned_structural_count/orphaned_empty_proxy_count/
		// orphaned_single_occupant_count above -- all three of which already had a working toggle
		// section. This one didn't: it was silently dropped on the floor client-side, so
		// collection-object containers with NO parent at all (not even an institution above them)
		// had zero path to reach them anywhere in this UI, not even indirectly through an
		// institution row (that gap is fixed separately, above, for the institution-child case).
		// Do not remove this section without another way to browse truly parentless leaf containers.
		var orphanLeafDivId = 'ctree-orphan-leaf';
		var orphanLeafWrap = $('<div class="mt-2"></div>');
		var orphanLeafBtn = $('<button class="btn btn-xs btn-outline-secondary mr-1" type="button"></button>')
			.attr('aria-expanded', 'false')
			.attr('aria-controls', orphanLeafDivId)
			.text('Leaf orphans (' + orphanLeafCount + ')');
		var orphanLeafDiv = $('<div class="d-none mt-1" id="' + orphanLeafDivId + '"></div>');
		orphanLeafBtn.on('click', function() {
			toggleBrowseSection(this, orphanLeafDivId, function() {
				loadOrphanedLeafPage(orphanLeafDivId, feedbackEl, 1);
			});
		});
		orphanLeafWrap.append(orphanLeafBtn);
		orphanLeafWrap.append($('<span class="small text-muted ml-1"></span>').text('Parts not in any container.'));
		orphanLeafWrap.append(orphanLeafDiv);
		wrapper.append(orphanLeafWrap);
	}
	var rootOtherDivId = 'ctree-root-other';
	if (topLevelOther.length > 0) {
		var rootOtherDiv = $('<div class="mt-3"></div>');
		rootOtherDiv.append($('<h3 class="h5 text-muted"></h3>').text('Other Top-Level Containers'));
		rootOtherDiv.append($('<div></div>').attr('id', rootOtherDivId));
		wrapper.append(rootOtherDiv);
	}
	$('#' + browsePanel).html(wrapper);
	if (topLevelOther.length > 0) {
		renderTreeNodes(topLevelOther, rootOtherDivId, feedbackEl);
	}
}

/**
 * Renders a container subtree and pre-renders any hidden placed-child sections beneath it.
 * @param {Array} nodes - nodes to render at the current tree level.
 * @param {string} targetDivId - id of the DOM container that should receive the tree markup.
 * @param {string} feedbackId - optional feedback element id for delegated AJAX failures.
 * @param {boolean} appendToExisting - true to append children instead of replacing the target contents.
 * @param {string} parentContainerType - type of the parent container whose children are being rendered.
 * @param {number} parentContainerId - container_id of the parent container, when applicable.
 */
function renderTreeNodes(nodes, targetDivId, feedbackId, appendToExisting, parentContainerType, parentContainerId) {
	var splitNodes = splitPlacedChildNodes(nodes || [], parentContainerType);
	var treeNodes = splitNodes.structuralNodes;
	var deferredSections = [];
	if (treeNodes.length === 0 && splitNodes.emptyPlacedNodes.length === 0 && splitNodes.occupiedPlacedNodes.length === 0) {
		if (!appendToExisting) {
			$('#' + targetDivId).html('<p class="text-muted my-2">No structural containers found.</p>');
		}
		return;
	}
	var ul = $('<ul class="container-tree" role="tree"></ul>');
	$.each(treeNodes, function(idx, node) {
		var label = node.label || '';
		var barcode = node.barcode || '';
		var ctype = node.container_type || '';
		var cid = node.container_id;
		var structuralChildren = parseInt(node.direct_structural_children, 10) || 0;
		var leafChildren = parseInt(node.direct_leaf_children, 10) || 0;
		var hasLeafDescendants = parseInt(node.has_leaf_descendants, 10) > 0;
		var nodeDescription = node.description || '';
		var childUlId = 'ctree-children-' + cid;
		var toggleId = 'ctree-toggle-' + cid;
		var role = getContainerRole(ctype);
		var isProxy = role === 'proxy';
		var displayName = formatContainerDisplay(barcode, label);
		var nodeRow = $('<div class="d-flex align-items-center flex-wrap tree-node-row"></div>');
		if (structuralChildren > 0) {
			var toggle = $('<button type="button"></button>')
				.attr('id', toggleId)
				.attr('aria-expanded', 'false')
				.attr('aria-controls', childUlId)
				.attr('aria-label', 'Expand ' + displayName)
				.addClass('tree-node-toggle btn btn-xs btn-link mr-1');
			toggle.on('click', function() {
				var expanded = $(this).attr('aria-expanded') === 'true';
				if (!expanded && $('#' + childUlId).children().length === 0) {
					loadContainerNode(cid, childUlId, feedbackId, ctype);
				}
				$('#' + childUlId).toggleClass('collapse');
				$(this).attr('aria-expanded', expanded ? 'false' : 'true');
				$(this).attr('aria-label', expanded ? 'Expand ' + displayName : 'Collapse ' + displayName);
			});
			nodeRow.append(toggle);
		}
		nodeRow.append($('<span class="tree-node-label"></span>').text(displayName));
		nodeRow.append(buildContainerTypeMeta(ctype));
		nodeRow.append(buildContainerDetailsButton(cid, displayName, feedbackId));
		nodeRow.append(buildAddChildContainerLink(cid, ctype, TREE_ACTION_SPACING_CLASS));
		if (structuralChildren === 0 && leafChildren === 0) {
			nodeRow.append($('<span class="badge badge-pill badge-light border text-muted small ml-1"></span>').attr('title', 'Empty container — no children').text('empty'));
		}
		if (isProxy && leafChildren > 1) {
			nodeRow.append($('<span class="badge badge-pill badge-warning ml-1 small"></span>').attr('title', 'Single-occupant type with multiple children — may be misplaced').text('!'));
		}
		if (leafChildren > 0 && structuralChildren > 0) {
			nodeRow.append($('<span class="badge badge-pill badge-warning ml-1 small"></span>').attr('title', 'Contains both structural containers and collection objects (mixed)').text('Mixed'));
		}
		if (leafChildren > 0 && structuralChildren === 0) {
			nodeRow.append($('<span class="badge badge-pill badge-info ml-1 small"></span>').text(leafChildren + ' obj'));
		}
		if (structuralChildren > 0) {
			nodeRow.append($('<span class="badge badge-pill badge-light border text-muted ml-1 small"></span>').text(structuralChildren + ' containers'));
		}
		var nodeLeafDiv = null;
		if (leafChildren > 0 && !isProxy) {
			var leafDivId = 'ctree-leaf-' + cid;
			nodeLeafDiv = $('<div class="d-none mt-1"></div>').attr('id', leafDivId);
			var browseBtn = $('<button type="button"></button>')
				.addClass('btn btn-xs btn-outline-secondary ml-1')
				.text('Browse contents')
				.on('click', (function(nodeId, nodeName, nodeBarcode, panelId) {
					return function() {
						var btn = $(this);
						var panel = $('#' + panelId);
						if (panel.hasClass('d-none')) {
							if (!btn.data('loaded')) {
								loadLeafPanel(nodeId, panelId, feedbackId, 1, nodeName, nodeBarcode);
								btn.data('loaded', true);
							} else {
								panel.removeClass('d-none');
							}
							btn.text('Hide contents');
						} else {
							panel.addClass('d-none');
							btn.text('Browse contents');
						}
					};
				})(cid, displayName, barcode, leafDivId));
			nodeRow.append(browseBtn);
		}
		var specEl = buildSpecimensButton(cid, barcode, leafChildren, hasLeafDescendants ? 1 : 0);
		if (specEl) { nodeRow.append(specEl); }
		var childUl = $('<ul></ul>').attr('id', childUlId).addClass('collapse container-tree');
		var li = $('<li role="treeitem"></li>')
			.attr('data-container-id', cid)
			.attr('data-parent-container-id', parentContainerId || '')
			.append(nodeRow);
		if (nodeDescription) {
			li.append($('<div class="tree-node-desc small text-muted fst-italic"></div>').text(nodeDescription));
		}
		if (nodeLeafDiv) {
			li.append(nodeLeafDiv);
		}
		li.append(childUl);
		if (isProxy && leafChildren > 0) {
			var parsedChildContainerId = parseInt(node.single_child_container_id, 10);
			var hasValidChildContainerId = !isNaN(parsedChildContainerId) && parsedChildContainerId > 0;
			var childBarcode = node.single_child_barcode || '';
			var childLabel = node.single_child_label || '';
			if (childBarcode || childLabel) {
				var childDisplay = formatContainerDisplay(childBarcode, childLabel);
				var inlineLeafDiv = $('<div class="tree-node-inline-leaf"></div>');
				inlineLeafDiv.append($('<span class="tree-node-leaf-info small text-muted"></span>').text('⤷ ' + childDisplay));
				inlineLeafDiv.append($('<span class="badge badge-pill badge-success ml-1 small"></span>').text('leaf'));
				inlineLeafDiv.append(
					$('<button class="btn btn-outline-info btn-xs p-0 ml-1" type="button"></button>')
						.text('Details')
						.on('click', function() {
							var detailContainerId = hasValidChildContainerId ? parsedChildContainerId : cid;
							openContainerDetailsDialog(detailContainerId, childDisplay, feedbackId, false);
						})
				);
				var childSpecUrl = specimenSearchUrl(childBarcode);
				if (childSpecUrl) {
					inlineLeafDiv.append(
						$('<a class="btn btn-xs btn-outline-info ml-1" target="_blank" rel="noopener noreferrer"></a>')
							.attr('href', childSpecUrl)
							.attr('title', 'View this specimen in the specimen search')
							.text('View specimen')
					);
				}
				li.append(inlineLeafDiv);
			}
		}
		ul.append(li);
	});
	$.each([
		{ kind: 'empty', nodes: splitNodes.emptyPlacedNodes },
		{ kind: 'occupied', nodes: splitNodes.occupiedPlacedNodes }
	], function(i, section) {
		if (!section.nodes || section.nodes.length === 0) {
			return;
		}
		var sectionParentKey = parentContainerId || targetDivId;
		var sectionPanelId = 'ctree-placed-' + section.kind + '-' + sectionParentKey;
		var sectionLabel = getPlacedChildSectionLabel(parentContainerType, section.kind, section.nodes);
		var sectionButton = $('<button class="btn btn-xs btn-outline-secondary mt-1" type="button"></button>')
			.attr('aria-expanded', 'false')
			.attr('aria-controls', sectionPanelId)
			.text(sectionLabel)
			.on('click', function() {
				toggleBrowseSection(this, sectionPanelId);
			});
		var sectionPanel = $('<div class="d-none mt-1 container-tree-section-panel"></div>').attr('id', sectionPanelId);
		var sectionLi = $('<li role="treeitem" class="container-tree-section"></li>')
			.append(sectionButton)
			.append(sectionPanel);
		ul.append(sectionLi);
		deferredSections.push({ panelId: sectionPanelId, nodes: section.nodes });
	});
	if (appendToExisting) {
		$('#' + targetDivId).append(ul.children());
	} else {
		$('#' + targetDivId).html(ul);
	}
	/* Pre-render hidden placed-child sections so Explore can reveal and highlight
	   targets nested behind these buttons without waiting for a user click. */
	$.each(deferredSections, function(i, section) {
		/* Reset parentContainerType here so the already-grouped placed children render
		   as direct nodes inside the hidden section instead of being regrouped again. */
		renderTreeNodes(section.nodes, section.panelId, feedbackId, false, null, parentContainerId);
		$('#' + section.panelId).data('loaded', true);
	});
}

/**
 * Loads and renders a paged contents table for one non-proxy container.
 * @param {number} containerId - the container_id whose direct leaf children should be loaded.
 * @param {string} leafPanelId - id of the panel that should receive the rendered contents table.
 * @param {string} feedbackId - optional feedback element id for AJAX failures.
 * @param {number} page - page number to request.
 * @param {string} containerLabel - display label used in the table heading.
 * @param {string} containerBarcode - barcode used to build the all-specimens search link.
 */
function loadLeafPanel(containerId, leafPanelId, feedbackId, page, containerLabel, containerBarcode) {
	page = page || 1;
	containerBarcode = containerBarcode || '';
	$('#' + leafPanelId).removeClass('d-none').html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading...</div>');
	$.ajax({
		url: '/containers/component/public.cfc',
		data: { method: 'getDirectLeafChildren', container_id: containerId, page: page },
		dataType: 'json',
		success: function(data) {
			var rows = data.rows || [];
			var totalRows = parseInt(data.totalRows, 10) || 0;
			var pageSize = parseInt(data.pageSize, 10) || 50;
			var currentPage = parseInt(data.page, 10) || 1;
			var totalPages = Math.max(1, Math.ceil(totalRows / pageSize));
			var panel = $('<div class="container-leaf-panel"></div>');
			var headingDiv = $('<div class="d-flex align-items-center flex-wrap mb-1"></div>');
			var heading = containerLabel ? 'Contents of ' + containerLabel + ' (' + totalRows + ' collection objects)' : 'Contents (' + totalRows + ' collection objects)';
			headingDiv.append($('<h3 class="h5 mr-2 mb-0"></h3>').text(heading));
			var allSpecUrl = specimenSearchUrl(containerBarcode);
			if (allSpecUrl && totalRows > 0) {
				headingDiv.append(
					$('<a class="btn btn-xs btn-outline-info" target="_blank" rel="noopener noreferrer"></a>')
						.attr('href', allSpecUrl)
						.attr('title', 'View all specimens in this container in the specimen search')
						.text('View all in Specimen Search')
				);
				// construct a direct link to the allContainerLeafNodes.cfm page for this container,
				// limited to just immediate children as this table is.
				var listLeafUrl = allContainerLeafNodesUrl(containerId);
				headingDiv.append(
					$('<a class="btn btn-xs btn-outline-info" target="_blank" rel="noopener noreferrer"></a>')
						.attr('href', listLeafUrl)
						.attr('title', 'List all collection object leaf nodes in this container')
						.text('Leaf Nodes')
				);
			}
			panel.append(headingDiv);
			if (totalPages > 1) {
				panel.append($('<p class="small text-muted mb-1"></p>').text('Page ' + currentPage + ' of ' + totalPages));
				panel.append(buildPagedNav(currentPage, totalPages, 'mb-1', 'leaf-page-btn'));
			}
			if (rows.length === 0) {
				panel.append('<p class="text-muted">No collection objects found.</p>');
			} else {
				var tbody = $('<tbody></tbody>');
				$.each(rows, function(i, row) {
					var rowDisplay = formatContainerDisplay(row.barcode, row.label);
					var tr = $('<tr></tr>');
					tr.append($('<td></td>').text(rowDisplay));
					tr.append(buildSpecimenGuidCell(row, row.barcode, row.label));
					tr.append(buildSpecimenIdentificationCell(row));
					tr.append(buildSpecimenPartCell(row));
					tr.append(buildSpecimenPreservationCell(row));
					var actionTd = $('<td></td>');
					actionTd.append(buildContainerDetailsActionButton(row.container_id, rowDisplay, feedbackId));
					actionTd.append(buildContainerViewLink(row.container_id));
					var rowSpecUrl = specimenSearchUrl(row.barcode);
					if (rowSpecUrl) {
						actionTd.append(
							$('<a class="btn btn-xs btn-outline-info mr-1 mb-1" target="_blank" rel="noopener noreferrer"></a>')
								.attr('href', rowSpecUrl)
								.attr('title', 'View this specimen in the specimen search')
								.text('View specimen')
						);
					}
					var placePartLink = buildPlacePartLink(row);
					if (placePartLink) {
						actionTd.append(placePartLink);
					}
					tr.append(actionTd);
					tbody.append(tr);
				});
				var table = $('<table class="table table-sm table-striped"></table>');
				table.append('<thead><tr><th>Container</th><th>GUID</th><th>Current Identification</th><th>Part Type</th><th>Preservation</th><th>Actions</th></tr></thead>');
				table.append(tbody);
				panel.append(table);
				if (totalPages > 1) {
					panel.append(buildPagedNav(currentPage, totalPages, 'mt-2', 'leaf-page-btn'));
				}
			}
			var leafEl = $('#' + leafPanelId);
			leafEl.removeClass('d-none').html(panel);
			leafEl.off('click.leafpage').on('click.leafpage', '.leaf-page-btn', function() {
				loadLeafPanel(containerId, leafPanelId, feedbackId, $(this).data('page'), containerLabel, containerBarcode);
			});
		},
		error: function(jqXHR, textStatus, error) {
			$('#' + leafPanelId).addClass('d-none');
			if (feedbackId) {
				setFeedbackControlState(feedbackId, 'error');
			}
			handleFail(jqXHR, textStatus, error, 'loading leaf container contents');
		}
	});
}

/**
 * Swaps the Contains field back from its read-only "N items from a Search" summary
 * to the editable GUID input, clearing whichever hidden id-list field it was standing in for.
 * @param {string} inputId - id of the Contains GUID text input.
 * @param {string[]} hiddenFieldIds - ids of the hidden fields (contains_result_id,
 *   contains_collection_object_ids) to clear.
 * @param {string} summaryId - id of the summary div shown in place of the input.
 * @param {string} labelId - id of the label for the GUID input.
 */
function clearContainsResultSummary(inputId, hiddenFieldIds, summaryId, labelId) {
	hiddenFieldIds.forEach(function(hiddenFieldId) {
		$('#' + hiddenFieldId).val('');
	});
	$('#' + summaryId).addClass('d-none');
	$('#' + inputId).removeClass('d-none');
	$('#' + labelId).removeClass('d-none');
	$('#' + inputId).val('').focus();
}

/**
 * Swaps the Loan/Accession/Deaccession Number fields back from their read-only transaction
 * summary to the editable inputs, clearing the transaction_id it was standing in for.
 * @param {string} fieldsContainerId - id of the div wrapping the three number inputs.
 * @param {string} hiddenFieldId - id of the hidden transaction_id field.
 * @param {string} summaryId - id of the summary div shown in place of the inputs.
 */
function clearTransactionSummary(fieldsContainerId, hiddenFieldId, summaryId) {
	$('#' + hiddenFieldId).val('');
	$('#' + summaryId).addClass('d-none');
	$('#' + fieldsContainerId).removeClass('d-none');
}

/**
 * Opens the location breadcrumb detail row for one search result container, inserting it
 * immediately below the given row if not already present. Leaves an already-open row as is,
 * so it can be called repeatedly (e.g. once per row from "Locate All") without re-fetching.
 * @param {number|string} containerId - container_id to show the breadcrumb for.
 * @param {jQuery} currentRow - the result row (<tr>) to insert the detail row after.
 */
function openLocateDetailRow(containerId, currentRow) {
	var detailRowId = 'locate-detail-' + containerId;
	var existingDetail = $('#' + detailRowId);
	if (existingDetail.length > 0) {
		existingDetail.removeClass('d-none');
		return;
	}
	var detailRow = $('<tr></tr>').attr('id', detailRowId).addClass('locate-detail-row');
	var detailCell = $('<td></td>').attr('colspan', '5').addClass('bg-light p-2 small');
	detailRow.append(detailCell);
	currentRow.after(detailRow);
	detailCell.html('<img src="/shared/images/indicator.gif"> Loading location…');
	$.ajax({
		url: '/containers/component/search.cfc',
		data: { method: 'getContainerBreadcrumb', container_id: containerId },
		dataType: 'json',
		success: function(breadcrumbs) {
			var breadcrumbEl = $('<ol class="breadcrumb bg-transparent p-0 m-0 flex-wrap"></ol>');
			$.each(breadcrumbs, function(j, crumb) {
				var display = formatContainerDisplay(crumb.barcode, crumb.label);
				var crumbLi = $('<li class="breadcrumb-item small"></li>');
				if (j === 0) {
					crumbLi.addClass('arrowprefix');
					crumbLi.append($('<span class="sr-only">Contained within: </span>'));
				}
				crumbLi.append(document.createTextNode(crumb.container_type + ': '));
				if (j === breadcrumbs.length - 1) {
					crumbLi.addClass('active').attr('aria-current', 'page').append(document.createTextNode(display));
				} else {
					var link = document.createElement('a');
					link.classList.add('pl-1');
					var params = new URLSearchParams({ execute: 'true', container_id: crumb.container_id });
					link.href = '/containers/Containers.cfm?' + params.toString();
					link.appendChild(document.createTextNode(display));
					crumbLi.append(link);
				}
				breadcrumbEl.append(crumbLi);
			});
			detailCell.html(breadcrumbEl);
		},
		error: function(jqXHR, textStatus, error) {
			detailCell.html('<span class="text-danger" role="alert">Failed to load location.</span>');
			handleFail(jqXHR, textStatus, error, 'loading container breadcrumb');
		}
	});
}

/**
 * Executes the container search form and renders the paged results table.
 * @param {string} browsePanel - id of the main results panel to populate.
 * @param {string} leafPanel - id of the shared subordinate leaf/table panel.
 * @param {string} feedbackId - optional feedback element id for AJAX failures.
 * @param {number} page - page number to request.
 */
function executeContainerSearch(browsePanel, leafPanel, feedbackId, page) {
	page = page || 1;
	var searchTerm = $('#search_term').val() || '';
	var containerType = $('[name=container_type]:not(:disabled)').val() || '';
	var barcode = $('#barcode').val() || '';
	var description = $('#description').val() || '';
	var department = $('#department').val() || '';
	var treeProperty = $('#tree_property').val() || '';
	var hasPositions = $('#has_positions').val() || '';
	var positionFilter = $('#position_filter').val() || '';
	var containsGuids = $('#contains_guids').val() || '';
	var containsResultId = $('#contains_result_id').val() || '';
	var containsCollectionObjectIds = $('#contains_collection_object_ids').val() || '';
	var loanNumber = $('#loan_number').val() || '';
	var accnNumber = $('#accn_number').val() || '';
	var deaccNumber = $('#deacc_number').val() || '';
	var transactionId = $('#transaction_id').val() || '';
	$('#' + browsePanel).html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Searching...</div>');
	$('#containerBrowseContext').text('Search results');
	$('#' + leafPanel).addClass('d-none').html('');
	ensureContainerTypeMetadata(function() {
		$.ajax({
			url: '/containers/component/search.cfc',
			data: {
				method: 'searchContainers',
				search_term: searchTerm,
				container_type: containerType,
				barcode: barcode,
				description: description,
				department: department,
				tree_property: treeProperty,
				has_positions: hasPositions,
				position_filter: positionFilter,
				contains_guids: containsGuids,
				contains_result_id: containsResultId,
				contains_collection_object_ids: containsCollectionObjectIds,
				loan_number: loanNumber,
				accn_number: accnNumber,
				deacc_number: deaccNumber,
				transaction_id: transactionId,
				page: page,
				pageSize: CONTAINER_PAGE_SIZE
			},
			dataType: 'json',
			success: function(data) {
			var rows = data.rows || [];
			var totalRows = parseInt(data.totalRows, 10) || 0;
			var pageSize = parseInt(data.pageSize, 10) || CONTAINER_PAGE_SIZE;
			var currentPage = parseInt(data.page, 10) || 1;
			var totalPages = Math.max(1, Math.ceil(totalRows / pageSize));
			var panel = $('<div></div>');
			var searchLinkParts = ['execute=true'];
			if (containerType) { searchLinkParts.push('container_type=' + encodeURIComponent(containerType)); }
			if (searchTerm) { searchLinkParts.push('search_term=' + encodeURIComponent(searchTerm)); }
			if (barcode) { searchLinkParts.push('barcode=' + encodeURIComponent(barcode)); }
			if (description) { searchLinkParts.push('description=' + encodeURIComponent(description)); }
			if (department) { searchLinkParts.push('department=' + encodeURIComponent(department)); }
			if (treeProperty) { searchLinkParts.push('tree_property=' + encodeURIComponent(treeProperty)); }
			if (hasPositions) { searchLinkParts.push('has_positions=' + encodeURIComponent(hasPositions)); }
			if (positionFilter) { searchLinkParts.push('position_filter=' + encodeURIComponent(positionFilter)); }
			if (containsResultId) {
				searchLinkParts.push('result_id=' + encodeURIComponent(containsResultId));
			} else if (containsCollectionObjectIds) {
				searchLinkParts.push('collection_object_id=' + encodeURIComponent(containsCollectionObjectIds));
			} else if (containsGuids) {
				searchLinkParts.push('contains_guids=' + encodeURIComponent(containsGuids));
			}
			if (transactionId) {
				searchLinkParts.push('transaction_id=' + encodeURIComponent(transactionId));
			} else {
				if (loanNumber) { searchLinkParts.push('loan_number=' + encodeURIComponent(loanNumber)); }
				if (accnNumber) { searchLinkParts.push('accn_number=' + encodeURIComponent(accnNumber)); }
				if (deaccNumber) { searchLinkParts.push('deacc_number=' + encodeURIComponent(deaccNumber)); }
			}
			var searchLinkUrl = '/containers/Containers.cfm?' + searchLinkParts.join('&');
			var headerDiv = $('<div class="d-flex align-items-center flex-wrap mb-1"></div>');
			headerDiv.append($('<h2 class="h4 mt-2 mr-2 mb-0"></h2>').text('Search Results (' + totalRows + ' containers found)'));
			headerDiv.append(
				$('<a class="small ml-1 mt-1 mr-2"></a>')
					.attr('href', searchLinkUrl)
					.attr('title', 'Link to this search (opens in new tab)')
					.text('Link to this search')
			);
			panel.append(headerDiv);
			if (totalPages > 1) {
				panel.append($('<p class="small text-muted mb-1"></p>').text('Page ' + currentPage + ' of ' + totalPages));
				panel.append(buildPagedNav(currentPage, totalPages, 'mb-2', 'search-page-btn'));
			}
			if (rows.length === 0) {
				panel.append('<p class="text-muted my-2">No containers matched your search.</p>');
			} else {
				var tbody = $('<tbody></tbody>');
				$.each(rows, function(i, row) {
					var cid = row.container_id;
					var structKids = parseInt(row.direct_structural_children, 10) || 0;
					var leafKids = parseInt(row.direct_leaf_children, 10) || 0;
					var containerTypeKey = (row.container_type || '').toLowerCase();
					var role = getContainerRole(row.container_type);
					var isProxy = role === 'proxy';
					var parentInfo = getSearchResultParentInfo(row);
					/* Collection objects are leaf-only results, while root-parent and
					   institution-parent proxies are the two top-level orphan-table cases. */
					var isTopLevelProxyTableRow = isProxy && (parentInfo.hasRootParent || parentInfo.hasInstitutionParent);
					var isLeafRow = containerTypeKey === COLLECTION_OBJECT_CONTAINER_TYPE;
					var canExplore = !isLeafRow && !isTopLevelProxyTableRow;
					var parentContainerId = parseInt(row.parent_container_id, 10);
					var displayName = formatContainerDisplay(row.barcode, row.label);
					var descText = row.description || '';
					if (descText.length > MAX_DESCRIPTION_LENGTH) {
						descText = descText.substring(0, MAX_DESCRIPTION_LENGTH) + '…';
					}
					var shapeClass = row.shape_class || 'A';
					var shapeLabel = SHAPE_LABELS[shapeClass] || shapeClass;
					var shapeBadgeClass = shapeClass === 'AB' ? 'badge-warning' : (shapeClass === 'B' ? 'badge-info' : 'badge-light border text-muted');
					var shapeBadge = $('<span class="badge badge-pill small"></span>').addClass(shapeBadgeClass).text(shapeLabel);
					var actionCell = $('<td></td>');
					actionCell.append(buildContainerDetailsActionButton(cid, displayName, feedbackId));
					actionCell.append(buildContainerViewLink(cid));
					actionCell.append(buildAddChildContainerLink(cid, row.container_type));
					actionCell.append(buildContainerEditLink(cid));
					var locateBtn = $('<button class="btn btn-xs btn-outline-secondary mr-1 mb-1 locate-row-btn" type="button"></button>')
						.text('Locate')
						.attr('data-container-id', cid);
					(function(nodeId) {
						locateBtn.on('click', function() {
							var currentRow = $(this).closest('tr');
							var existingDetail = $('#locate-detail-' + nodeId);
							if (existingDetail.length > 0 && !existingDetail.hasClass('d-none')) {
								existingDetail.addClass('d-none');
								locateBtn.text('Locate');
								return;
							}
							openLocateDetailRow(nodeId, currentRow);
							locateBtn.text('Hide Location');
						});
					})(cid);
					actionCell.append(locateBtn);
					if (canExplore) {
						actionCell.append(
							$('<button class="btn btn-xs btn-outline-primary mr-1 mb-1" type="button"></button>')
								.text('Explore')
								.on('click', function() {
									exploreContainerInTree(cid, displayName, browsePanel, leafPanel, feedbackId);
								})
						);
					} else if (isLeafRow) {
						if (!isNaN(parentContainerId) && parentContainerId > 0) {
							actionCell.append(
								$('<button class="btn btn-xs btn-outline-primary mr-1 mb-1" type="button"></button>')
									.text('Explore Parent')
									.attr('title', 'Explore this collection object’s parent container in the hierarchy')
									.on('click', function() {
										exploreContainerInTree(parentContainerId, 'parent of ' + displayName, browsePanel, leafPanel, feedbackId);
									})
							);
						} else {
							actionCell.append(
								$('<button class="btn btn-xs btn-outline-primary mr-1 mb-1" type="button" disabled></button>')
									.text('Explore')
									.attr('title', 'This collection object has no parent container to explore')
							);
						}
					} else {
						actionCell.append(
							$('<button class="btn btn-xs btn-outline-primary mr-1 mb-1" type="button" disabled></button>')
								.text('Explore')
								.attr('title', 'This top-level orphan row is already shown in context; there is no hierarchy position to explore')
						);
					}
					if (leafKids > 0 && !isProxy) {
						actionCell.append(
							$('<button class="btn btn-xs btn-outline-secondary mr-1 mb-1" type="button"></button>')
								.text('Browse')
								.on('click', function() {
									var leafDivId = 'search-leaf-' + cid;
									if ($('#' + leafDivId).length === 0) {
										$('#' + leafPanel).removeClass('d-none').append($('<div></div>').attr('id', leafDivId));
									}
									loadLeafPanel(cid, leafDivId, feedbackId, 1, displayName, row.barcode || '');
								})
						);
					}
					if ((leafKids > 0 || structKids > 0) && row.barcode) {
						actionCell.append(
							$('<a class="btn btn-xs btn-outline-info mr-1 mb-1" target="_blank" rel="noopener noreferrer"></a>')
								.attr('href', specimenSearchUrl(row.barcode))
								.attr('title', 'View specimens in this container in the specimen search')
								.text('Specimens')
						);
					}
					var contentsTd = $('<td></td>').append(shapeBadge);
					if (structKids > 0) {
						contentsTd.append($('<span class="ml-1 small text-muted"></span>').text(structKids + ' containers'));
					}
					if (leafKids > 0) {
						contentsTd.append($('<span class="ml-1 small text-muted"></span>').text(leafKids + ' obj'));
					}
					var typeTd = $('<td></td>').text(row.container_type || '');
					typeTd.append(' ');
					typeTd.append($(getContainerRoleBadgeHtml(row.container_type)));
					var tr = $('<tr></tr>').attr('data-container-id', cid);
					tr.append(typeTd);
					tr.append($('<td></td>').text(displayName));
					tr.append(contentsTd);
					tr.append($('<td></td>').text(descText));
					tr.append(actionCell);
					tbody.append(tr);
				});
				headerDiv.append(
					$('<button class="btn btn-xs btn-outline-secondary mt-1 ml-1" type="button"></button>')
						.text('Locate All')
						.attr('title', 'Show the location breadcrumb for every container in these search results')
						.on('click', function() {
							var locateAllBtn = $(this);
							var opening = locateAllBtn.text() !== 'Hide Locations';
							tbody.find('tr[data-container-id]').each(function() {
								var row = $(this);
								var containerId = row.attr('data-container-id');
								var detail = $('#locate-detail-' + containerId);
								var isOpen = detail.length > 0 && !detail.hasClass('d-none');
								if (opening) {
									openLocateDetailRow(containerId, row);
									row.find('.locate-row-btn').text('Hide Location');
								} else if (isOpen) {
									detail.addClass('d-none');
									row.find('.locate-row-btn').text('Locate');
								}
							});
							locateAllBtn.text(opening ? 'Hide Locations' : 'Locate All');
						})
				);
				var table = $('<table class="table table-sm table-striped table-responsive-md"></table>');
				table.append('<thead><tr><th>Type</th><th>Name / Barcode</th><th>Contents</th><th>Description</th><th>Actions</th></tr></thead>');
				table.append(tbody);
				panel.append(table);
				if (totalPages > 1) {
					panel.append(buildPagedNav(currentPage, totalPages, 'mt-2', 'search-page-btn'));
				}
			}
			var browsePanelEl = $('#' + browsePanel);
			browsePanelEl.html(panel);
			browsePanelEl.off('click.searchpage').on('click.searchpage', '.search-page-btn', function() {
				executeContainerSearch(browsePanel, leafPanel, feedbackId, $(this).data('page'));
			});
		},
		error: function(jqXHR, textStatus, error) {
			if (feedbackId) {
				setFeedbackControlState(feedbackId, 'error');
			}
			handleFail(jqXHR, textStatus, error, 'searching containers');
		}
	});
	});
}


var CONTAINER_TYPE_META = null;

/**
 * Load ctcontainer_type metadata used by placement helpers.
 * @param {function} callback - optional callback invoked after metadata load attempt.
 * @returns {void}
 */
function loadContainerTypeMetadata(callback) {
	$.ajax({
		url: '/containers/component/search.cfc',
		type: 'get',
		dataType: 'json',
		data: {
			method: 'getContainerTypeMetadata',
			returnformat: 'json'
		},
		success: function(data) {
			CONTAINER_TYPE_META = data;
			if ($.isFunction(callback)) {
				callback();
			}
		},
		error: function(jqXHR, textStatus, error) {
			console.warn('Unable to load container type metadata.', error || textStatus);
			CONTAINER_TYPE_META = null;
			if ($.isFunction(callback)) {
				callback();
			}
		}
	});
}

/**
 * Get normalized type metadata for a container type.
 * @param {string} containerType - container_type name to resolve.
 * @returns {Object} metadata object with role, parent expectations, and rank fields.
 */
function getContainerTypeMeta(containerType) {
	var normalized = (containerType || '').toLowerCase();
	var defaults = {
		container_type: containerType || '',
		role: 'structural',
		expects_leaf_child_count: 0,
		expected_parent_types: 'any',
		force_expected_parent_type: 0,
		rank_order: null,
		variable_rank: 0,
		description: ''
	};
	if (CONTAINER_TYPE_META && $.isArray(CONTAINER_TYPE_META)) {
		for (var i = 0; i < CONTAINER_TYPE_META.length; i++) {
			var row = CONTAINER_TYPE_META[i] || {};
			if (((row.container_type || '').toLowerCase()) === normalized) {
				return {
					container_type: row.container_type || containerType || '',
					role: row.role || 'structural',
					expects_leaf_child_count: parseInt(row.expects_leaf_child_count, 10) || 0,
					expected_parent_types: row.expected_parent_types || 'any',
					force_expected_parent_type: parseInt(row.force_expected_parent_type, 10) || 0,
					rank_order: row.rank_order,
					variable_rank: parseInt(row.variable_rank, 10) || 0,
					description: row.description || ''
				};
			}
		}
	}
	var CONTAINER_ROLE_MAP = {
		'collection object': 'leaf',
		'cryovial': 'proxy',
		'pin': 'proxy',
		'slide': 'proxy',
		'envelope': 'proxy',
		'glass vial': 'proxy',
		'jar': 'leafbearer',
		'compartment': 'leafbearer',
		'tank': 'leafbearer',
		'institution': 'structural',
		'campus': 'structural',
		'cryovat': 'structural',
		'building': 'structural',
		'floor': 'structural',
		'room': 'structural',
		'freezer': 'structural',
		'freezer rack': 'structural',
		'freezer box': 'structural',
		'grouping': 'structural',
		'set': 'structural',
		'fixture': 'structural',
		'rack slot': 'structural',
		'position': 'structural'
	};
	defaults.role = CONTAINER_ROLE_MAP[normalized] || 'structural';
	return defaults;
}

/**
 * Validate a proposed placement and render severity messages in the dialog.
 * @param {number|string} childContainerId - container_id being moved.
 * @param {number|string} proposedParentContainerId - target parent container_id (0 for root).
 * @param {string} validationDivId - id of the target element for validation output.
 * @param {string} confirmButtonId - id of the confirm button to enable/disable.
 * @returns {void}
 */
function checkAndRenderPlacementValidation(childContainerId, proposedParentContainerId, validationDivId, confirmButtonId) {
	var validationDiv = $('#' + validationDivId);
	var confirmButton = $('#' + confirmButtonId);
	var updatePickerSelectVisualState = function(enabled) {
		if (confirmButton.hasClass('pick-container-select-btn')) {
			confirmButton.toggleClass('btn-primary', enabled);
			confirmButton.toggleClass('btn-outline-secondary', !enabled);
		}
	};
	validationDiv.html('<div class="small text-muted"><img src="/shared/images/indicator.gif"> Checking placement…</div>');
	if (!childContainerId || parseInt(childContainerId, 10) === 0) {
		validationDiv.empty();
		confirmButton.prop('disabled', false);
		updatePickerSelectVisualState(true);
		return;
	}
	$.ajax({
		url: '/containers/component/public.cfc',
		type: 'get',
		dataType: 'json',
		data: {
			method: 'validateContainerPlacement',
			returnformat: 'json',
			child_container_id: childContainerId,
			proposed_parent_container_id: proposedParentContainerId
		},
		success: function(result) {
			var severity = (result && result.severity) ? result.severity : 'ok';
			if (severity === 'ok') {
				validationDiv.html('<span class="text-success small">✓ Placement is within expectations</span>');
			} else if (severity === 'warn') {
				var warningList = $('<ul class="mb-0"></ul>');
				$.each(result.warnings || [], function(i, warning) {
					warningList.append($('<li></li>').text(warning));
				});
				validationDiv.html('').append(
					$('<div class="alert alert-warning py-1 px-2 small mb-0"></div>')
						.append('<strong>⚠ Placement warning</strong>')
						.append(warningList)
				);
			} else {
				var blockList = $('<ul class="mb-0"></ul>');
				$.each(result.blocks || [], function(i, block) {
					blockList.append($('<li></li>').text(block));
				});
				validationDiv.html('').append(
					$('<div class="alert alert-danger py-1 px-2 small mb-0"></div>')
						.append('<strong>✗ Placement not allowed</strong>')
						.append(blockList)
				);
			}
			confirmButton.prop('disabled', !(result && result.allowed === true));
			updatePickerSelectVisualState(result && result.allowed === true);
		},
		error: function(jqXHR, textStatus, error) {
			handleFail(jqXHR, textStatus, error, 'validating container placement');
			confirmButton.prop('disabled', true);
			updatePickerSelectVisualState(false);
		}
	});
}

/**
 * Render a compact placement badge (ok/warn/block) for existing placements.
 * @param {Object} validationResult - response object from validateContainerPlacement.
 * @param {string} targetDivId - id of the target element to render badge content into.
 * @returns {void}
 */
function renderPlacementWarningBadge(validationResult, targetDivId) {
	var target = $('#' + targetDivId);
	var detailId = 'pd-' + targetDivId;
	var warnings = (validationResult && validationResult.warnings) ? validationResult.warnings : [];
	var blocks = (validationResult && validationResult.blocks) ? validationResult.blocks : [];
	var expected = (validationResult && validationResult.expected_parent_types) ? validationResult.expected_parent_types : 'any';
	var forceExpected = parseInt((validationResult && validationResult.force_expected_parent_type) || 0, 10);
	var isRoot = !!(validationResult && validationResult.is_root_placement);
	var rootWarnText = 'Container is being placed at the root level. Containers of type ' + (validationResult.child_type || 'this type') + ' are normally placed inside a ' + expected + '.';
	var buildCollapse = function(className, labelText, items) {
		var wrapper = $('<span></span>');
		var badge = $('<span class="badge"></span>').addClass(className).css('cursor', 'pointer')
			.attr('data-toggle', 'collapse')
			.attr('data-target', '#' + detailId)
			.attr('role', 'button')
			.attr('tabindex', '0')
			.attr('aria-expanded', 'false')
			.attr('aria-controls', detailId)
			.text(labelText)
			.on('keydown', function(event) {
				if (event.key === 'Enter' || event.key === ' ' || event.key === 'Spacebar') {
					event.preventDefault();
					$(this).trigger('click');
				}
			})
			.on('click', function() {
				$(this).attr('aria-expanded', $(this).attr('aria-expanded') === 'true' ? 'false' : 'true');
			});
		var detail = $('<div class="collapse small mt-1"></div>').attr('id', detailId);
		var list = $('<ul class="list-unstyled mb-0"></ul>');
		$.each(items, function(i, item) {
			list.append($('<li></li>').text(item));
		});
		detail.append(list);
		wrapper.append(badge).append(detail);
		return wrapper;
	};

	target.empty();
	if (isRoot && expected === 'none' && forceExpected === 1) {
		target.append($('<span class="badge badge-success"></span>').text('✓ Root container (expected)'));
		return;
	}
	if (isRoot && expected === 'none' && forceExpected === 0) {
		target.append(buildCollapse('badge-warning', '⚠ Root container', ['Containers of this type are expected to be root containers.']));
		return;
	}
	if (isRoot && expected !== 'none' && expected !== 'any') {
		target.append(buildCollapse('badge-warning', '⚠ placement warning', [rootWarnText]));
		return;
	}

	if (validationResult && validationResult.severity === 'ok') {
		target.append($('<span class="badge badge-success"></span>').text('✓ placement ok'));
	} else if (validationResult && validationResult.severity === 'warn') {
		target.append(buildCollapse('badge-warning', '⚠ placement warning', warnings));
	} else {
		var blockedLabel = '✗ placement blocked';
		var hasLockedBlock = false;
		$.each(blocks, function(i, item) {
			var blockMessage = $.trim((item || '').toLowerCase());
			if (blockMessage === LOCKED_PLACEMENT_BLOCK_MESSAGE_LOWER) {
				hasLockedBlock = true;
				return false;
			}
		});
		if (hasLockedBlock) {
			blockedLabel = '✗ placement locked';
		}
		target.append(buildCollapse('badge-danger', blockedLabel, blocks));
	}
}

/**
 * Load validation for an existing placement and render badge output.
 * @param {number|string} containerContainerId - child container_id to validate.
 * @param {number|string} parentContainerId - parent container_id to validate against.
 * @param {string} targetDivId - id of the target element for badge output.
 * @returns {void}
 */
function loadPlacementWarningBadge(containerContainerId, parentContainerId, targetDivId) {
	var target = $('#' + targetDivId);
	target.html('<span class="small text-muted"><img src="/shared/images/indicator.gif"> Checking…</span>');
	$.ajax({
		url: '/containers/component/public.cfc',
		type: 'get',
		dataType: 'json',
		data: {
			method: 'validateContainerPlacement',
			returnformat: 'json',
			child_container_id: containerContainerId,
			proposed_parent_container_id: parentContainerId
		},
		success: function(result) {
			renderPlacementWarningBadge(result, targetDivId);
		},
		error: function(jqXHR, textStatus, error) {
			handleFail(jqXHR, textStatus, error, 'loading placement warning badge');
			target.empty();
		}
	});
}

/**
 * Open the shared rich container picker dialog for parent/child/find contexts.
 * @param {Object} options - dialog configuration.
 * @param {string} options.mode - picker mode: parent, child, or find.
 * @param {string} options.dialogTitle - title for the modal dialog.
 * @param {number|string} options.childContainerIdForValidation - child id for parent-mode validation.
 * @param {number|string} options.parentContainerIdForValidation - parent id for child-mode validation.
 * @param {string} options.childContainerType - child container_type for parent-mode type preselection.
 * @param {string} options.preselectType - optional explicit type value to preselect.
 * @param {boolean} options.pickLeaves - when true in child mode, preselect collection object candidates.
 * @param {string} options.institutionAcronym - optional institution acronym to scope autocomplete.
 * @param {string} options.feedbackId - optional feedback output id.
 * @param {Function} options.onSelect - callback(selectedId, selectedLabel, wrapper, controls, selectedItem) on Select.
 * @returns {void}
 */
function openContainerPickerDialog(options) {
	options = options || {};
	var mode = options.mode || 'find';
	var id_suffix = '_' + Date.now();
	var wrapper = $('#placementDialogWrapper');
	if (!wrapper.length) {
		wrapper = $('<div id="placementDialogWrapper"></div>').appendTo('body');
	}
	wrapper.html('<div class="text-center my-2"><img src="/shared/images/indicator.gif"> Loading…</div>');
	wrapper.dialog({
		title: options.dialogTitle || 'Select Container',
		modal: true,
		width: 540,
		autoOpen: true
	});

	var preselectType = options.preselectType || '';
	if (!preselectType && mode === 'parent' && options.childContainerType) {
		var expected = getContainerTypeMeta(options.childContainerType).expected_parent_types || '';
		if (expected && expected !== 'any' && expected !== 'none') {
			preselectType = $.trim((expected + '').split(',')[0]);
		}
	}

	$.ajax({
		url: '/containers/component/search.cfc',
		type: 'get',
		dataType: 'html',
		data: {
			method: 'pickContainerDialogHtml',
			returnformat: 'plain',
			dialog_mode: mode,
			child_container_id: options.childContainerIdForValidation || '',
			preselect_type: preselectType,
			pick_leaves: options.pickLeaves ? 1 : 0,
			institution_acronym: options.institutionAcronym || '',
			id_suffix: id_suffix
		},
		success: function(html) {
			var controls = {
				ancestorControlId: 'pickContainerAncestor' + id_suffix,
				ancestorIdControlId: 'pickContainerAncestorId' + id_suffix,
				searchControlId: 'pickContainerSearch' + id_suffix,
				searchIdControlId: 'pickContainerSearchId' + id_suffix,
				searchOpenControlId: 'pickContainerSearchOpen' + id_suffix,
				typeControlId: 'pickContainerType' + id_suffix,
				labelContainsControlId: 'pickContainerLabelContains' + id_suffix,
				descriptionContainsControlId: 'pickContainerDescriptionContains' + id_suffix,
				validationControlId: 'pickContainerValidation' + id_suffix,
				confirmControlId: 'pickContainerConfirm' + id_suffix,
				cancelControlId: 'pickContainerCancel' + id_suffix
			};
			wrapper.html(html);
			makeContainerAutocompleteMeta(controls.ancestorControlId, controls.ancestorIdControlId);
			makeContainerAutocompleteLimitedMeta(
				controls.searchControlId,
				controls.searchIdControlId,
				controls.typeControlId,
				controls.ancestorIdControlId,
				controls.labelContainsControlId,
				controls.descriptionContainsControlId
			);
			var setDialogSelectButtonEnabled = function(enabled) {
				var confirmButton = $('#' + controls.confirmControlId);
				confirmButton.prop('disabled', !enabled);
				confirmButton.toggleClass('btn-primary', enabled);
				confirmButton.toggleClass('btn-outline-secondary', !enabled);
			};
			var searchIdInput = $('#' + controls.searchIdControlId);
			var selectedItem = null;
			var suppressNextAutocompleteChange = false;
			var suppressAutocompleteChangeForActivation = function() {
				suppressNextAutocompleteChange = true;
			};
			var resetAutocompleteChangeSuppression = function() {
				suppressNextAutocompleteChange = false;
			};
			var bindActivationSuppression = function(controlId) {
				var control = $('#' + controlId);
				control.on('mousedown', suppressAutocompleteChangeForActivation);
				control.on('mouseup', resetAutocompleteChangeSuppression);
			};
			var updateSearchOpenButtonState = function() {
				var searchOpenLink = $('#' + controls.searchOpenControlId);
				var hasAnyFilterValue = false;
				wrapper.find('.pick-container-filter-control').each(function() {
					var control = $(this);
					if ($.trim(control.val()).length > 0) {
						hasAnyFilterValue = true;
						return false;
					}
				});
				searchOpenLink.attr('aria-disabled', !hasAnyFilterValue);
				searchOpenLink.attr('tabindex', hasAnyFilterValue ? '0' : '-1');
				searchOpenLink.toggleClass('disabled', !hasAnyFilterValue);
			};
			setDialogSelectButtonEnabled(false);
			var refreshDialogAutocomplete = function() {
				searchIdInput.val('');
				setDialogSelectButtonEnabled(false);
				$('#' + controls.validationControlId).empty();
				makeContainerAutocompleteLimitedMeta(
					controls.searchControlId,
					controls.searchIdControlId,
					controls.typeControlId,
					controls.ancestorIdControlId,
					controls.labelContainsControlId,
					controls.descriptionContainsControlId
				);
				updateSearchOpenButtonState();
			};
			$('#' + controls.typeControlId + ', #' + controls.ancestorControlId).on('change', refreshDialogAutocomplete);
			var filterInputTimer = null;
			var filterInputs = $('#' + controls.labelContainsControlId + ', #' + controls.descriptionContainsControlId);
			filterInputs.on('change', refreshDialogAutocomplete);
			filterInputs.on('input', function() {
				if (filterInputTimer) {
					window.clearTimeout(filterInputTimer);
				}
				filterInputTimer = window.setTimeout(refreshDialogAutocomplete, 250);
			});
			wrapper.find('.pick-container-filter-control').on('change input autocompleteselect autocompletechange', function() {
				updateSearchOpenButtonState();
			});
			$('#' + controls.searchOpenControlId).on('click', function(event) {
				event.preventDefault();
				if ($(this).hasClass('disabled')) {
					return false;
				}
				var searchInput = $('#' + controls.searchControlId);
				// Use wildcard token to trigger broad autocomplete results with active filters.
				// This codebase uses "%%%" as a broad wildcard term for container autocomplete lookups.
				// Keep it visible so users can see/edit the seeded search term.
				searchInput.val(AUTOCOMPLETE_OPEN_WILDCARD);
				searchIdInput.val('');
				setDialogSelectButtonEnabled(false);
				$('#' + controls.validationControlId).empty();
				searchInput.focus();
				if (searchInput.autocomplete('instance')) {
					searchInput.autocomplete('search', AUTOCOMPLETE_OPEN_WILDCARD);
				}
				return false;
			});

			var runValidationForSelection = function(selectedId) {
				if (!selectedId) {
					setDialogSelectButtonEnabled(false);
					$('#' + controls.validationControlId).empty();
					return;
				}
				if (mode === 'parent' && options.childContainerIdForValidation) {
					checkAndRenderPlacementValidation(options.childContainerIdForValidation, selectedId, controls.validationControlId, controls.confirmControlId);
				} else if (mode === 'child' && options.parentContainerIdForValidation) {
					checkAndRenderPlacementValidation(selectedId, options.parentContainerIdForValidation, controls.validationControlId, controls.confirmControlId);
				} else {
					setDialogSelectButtonEnabled(true);
					$('#' + controls.validationControlId).empty();
				}
			};
			var applyAutocompleteSelection = function(ui, preserveExistingSelection) {
				var selectedId = '';
				if (ui && ui.item) {
					selectedId = ui.item.id || '';
					selectedItem = ui.item;
					searchIdInput.val(selectedId);
				} else {
					selectedItem = null;
				}
				if (!selectedId && preserveExistingSelection) {
					selectedId = searchIdInput.val();
				}
				if (!selectedId) {
					searchIdInput.val('');
					setDialogSelectButtonEnabled(false);
					$('#' + controls.validationControlId).empty();
					return;
				}
				runValidationForSelection(selectedId);
			};
			$('#' + controls.searchControlId).on('autocompleteselect', function(event, ui) {
				// Keep existing hidden selection as fallback for select events.
				applyAutocompleteSelection(ui, true);
			});
			$('#' + controls.searchControlId).on('autocompletechange', function(event, ui) {
				if (suppressNextAutocompleteChange) {
					resetAutocompleteChangeSuppression();
					return;
				}
				// Do not preserve hidden selection after free-text changes.
				applyAutocompleteSelection(ui, false);
			});
			$('#' + controls.searchControlId).on('change input', function() {
				if (!searchIdInput.val()) {
					setDialogSelectButtonEnabled(false);
					$('#' + controls.validationControlId).empty();
				}
			});
			bindActivationSuppression(controls.confirmControlId);
			$('#' + controls.confirmControlId).on('click', function() {
				resetAutocompleteChangeSuppression();
				var selectedId = searchIdInput.val();
				var selectedLabel = $('#' + controls.searchControlId).val();
				if (!selectedId) {
					return;
				}
				if ($.isFunction(options.onSelect)) {
					options.onSelect(selectedId, selectedLabel, wrapper, controls, selectedItem);
				}
			});
			bindActivationSuppression(controls.cancelControlId);
			var handleCancelActivation = function(event) {
				if (event) {
					if (event.type === 'keydown') {
						var closeKey = event.key || '';
						var isCloseKey = closeKey === 'Enter' || closeKey === ' ';
						if (!isCloseKey) {
							return;
						}
					}
					event.preventDefault();
					event.stopPropagation();
				}
				resetAutocompleteChangeSuppression();
				wrapper.dialog('close');
				return false;
			};
			$('#' + controls.cancelControlId).on('mousedown', handleCancelActivation);
			$('#' + controls.cancelControlId).on('keydown', handleCancelActivation);
		},
		error: function(jqXHR, textStatus, error) {
			handleFail(jqXHR, textStatus, error, 'loading placement dialog');
		}
	});
}

/**
 * Open the constrained parent-container selection dialog.
 * @param {number|string} childContainerId - child container_id being moved.
 * @param {string} childContainerType - child container_type used for default filtering.
 * @param {string} childInstitutionAcronym - institution acronym used to scope search.
 * @param {string} targetIdFieldId - id of hidden field to receive selected parent container_id.
 * @param {string} targetLabelFieldId - id of text field to receive selected parent label.
 * @param {string} feedbackId - id of feedback output control for status updates.
 * @returns {void}
 */
function openPlacementDialog(childContainerId, childContainerType, childInstitutionAcronym, targetIdFieldId, targetLabelFieldId, feedbackId) {
	openContainerPickerDialog({
		mode: 'parent',
		dialogTitle: 'Select Parent Container',
		childContainerIdForValidation: childContainerId,
		childContainerType: childContainerType,
		institutionAcronym: childInstitutionAcronym,
		feedbackId: feedbackId,
		onSelect: function(selectedId, selectedLabel, wrapper) {
			$('#' + targetIdFieldId).val(selectedId);
			$('#' + targetLabelFieldId).val(selectedLabel);
			setFeedbackControlState(feedbackId, 'saved');
			wrapper.dialog('close');
		}
	});
}

/**
 * Add a dialog-launch button adjacent to a parent-container text field.
 * @param {string} textFieldId - id of the text field that displays selected parent container.
 * @param {string} idFieldId - id of the hidden field for selected parent container_id.
 * @param {number|string} childContainerId - child container_id being moved.
 * @param {string} childContainerType - child container_type used for dialog defaults.
 * @param {string} childInstitutionAcronym - institution acronym used to scope search.
 * @param {string} feedbackId - id of feedback output control for status updates.
 * @returns {void}
 */
function addPlacementDialogButton(textFieldId, idFieldId, childContainerId, childContainerType, childInstitutionAcronym, feedbackId) {
	if ($('#chooseBtn-' + textFieldId).length > 0) {
		return;
	}
	var textField = $('#' + textFieldId);
	var pickerRow = textField.closest('.parent-container-picker-row');
	var buttonContainer = pickerRow.length > 0 ? pickerRow : textField.parent();
	$('<button type="button" class="btn btn-xs btn-secondary ml-1"></button>')
		.attr('id', 'chooseBtn-' + textFieldId)
		.text('Choose…')
		.on('click', function() {
			openPlacementDialog(childContainerId, childContainerType, childInstitutionAcronym, idFieldId, textFieldId, feedbackId);
		})
		.appendTo(buttonContainer);
}

/** Switch the container_type field on the Containers.cfm search form back from the comma-list
 * text input (used to show a multi-value container_type carried in from a link such as
 * browseContainers.cfm's department picker) to the single-value picklist, blanking the list value.
 * Only one of the two controls is ever enabled at a time -- a disabled field doesn't submit --
 * so this both blanks and re-enables/hides the pair rather than editing form values directly.
 * @param {string} selectId - id of the container_type <select>.
 * @param {string} textInputId - id of the container_type comma-list text <input>.
 * @param {string} listGroupId - id of the row containing the text input and this Clear button,
 *  hidden along with the input so the button disappears with it.
 * @returns {void}
 */
function clearContainerTypeList(selectId, textInputId, listGroupId) {
	$('#' + textInputId).val('').prop('disabled', true);
	$('#' + listGroupId).addClass('d-none');
	$('#' + selectId).val('').prop('disabled', false).removeClass('d-none');
}
