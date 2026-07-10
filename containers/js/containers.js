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
 *  @param clear, optional, default false, set to true for data entry controls to clear both controls when change
 *   is made other than selection from picklist.
 */
function makeContainerAutocompleteLimitedMeta(nameControl, idControl, typeControl, ancestorControl, clear=false) {
	console.log("Element ["+nameControl+"] exists:", $('#'+nameControl).length > 0);
	$('#'+nameControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/containers/component/search.cfc",
				data: { 
					term: request.term, 
					type: $('#'+typeControl).val(),
					ancestor_container_id: $('#'+ancestorControl).val(),
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

/** Maximum description length (characters) shown in search result rows. */
var MAX_DESCRIPTION_LENGTH = 80;

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
		url: '/containers/component/functions.cfc',
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
			url: '/containers/component/functions.cfc',
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
				url: '/containers/component/functions.cfc',
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
		url: '/containers/component/functions.cfc',
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
			var parts = [];
			$.each(data, function(i, node) {
				var display = formatContainerDisplay(node.barcode, node.label);
				parts.push(node.container_type + ': ' + display);
			});
			var pathText = parts.join(' \u203a ');
			$('#containerBrowseContext').text('Location');

			var panel = $('<div></div>');
			panel.append($('<h2 class="h4 mt-2"></h2>').text('Container Location'));
			var breadcrumbDiv = $('<ol class="breadcrumb bg-light border rounded p-2 my-2 flex-wrap"></ol>');
			$.each(data, function(i, node) {
				var display = formatContainerDisplay(node.barcode, node.label);
				var crumbText = node.container_type + ': ' + display;
				var crumbLi = $('<li class="breadcrumb-item"></li>');
				if (i === data.length - 1) {
					crumbLi.addClass('active').attr('aria-current', 'page').text(crumbText);
				} else {
					crumbLi.text(crumbText);
				}
				breadcrumbDiv.append(crumbLi);
			});
			panel.append(breadcrumbDiv);
			$('#' + targetPanel).html(panel);
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
				url: '/containers/component/functions.cfc',
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
		url: '/containers/component/functions.cfc',
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
		url: '/containers/component/functions.cfc',
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
				var shouldRefreshBreadcrumb = breadcrumbFeedbackId && breadcrumbTargetId;
				setFeedbackControlState(feedbackId, 'saved');
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
				messageDialog('Error: ' + message, 'Error Saving Container');
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
		url: '/containers/component/functions.cfc',
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
 * @param {number} containerId - the container_id to edit.
 * @param {string} spacingClass - optional spacing class override for the action element.
 * @returns {jQuery} anchor element that opens the edit form in a new tab.
 */
function buildContainerEditLink(containerId, spacingClass) {
	return $('<a target="_blank" rel="noopener noreferrer"></a>')
		.addClass(buildContainerActionClass('btn btn-xs btn-secondary', spacingClass || TABLE_ACTION_SPACING_CLASS))
		.attr('href', '/containers/Container.cfm?action=edit&container_id=' + encodeURIComponent(containerId))
		.text('Edit');
}

/**
 * Builds an "Add Child Container" link button that opens the new-container form
 * in a new tab with the given container pre-set as the parent.
 * Returns null when containerType is a proxy or collection object type, as those
 * nodes cannot have child containers added to them.
 *
 * @param {number} containerId   - the container_id to use as the parent.
 * @param {string} containerType - the container_type of the current node.
 * @returns {jQuery|null} an anchor element, or null if not applicable.
 */
function buildAddChildContainerLink(containerId, containerType, spacingClass) {
	if (!canCreateChildContainer(containerType)) {
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
	var dialogWidth = Math.max(320, Math.min($(window).width() - 40, 1000));
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
		url: '/containers/component/functions.cfc',
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
		url: '/containers/component/functions.cfc',
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
		url: '/containers/component/functions.cfc',
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
 * Renders a read-only positions grid or fallback table for one container.
 * @param {Array} positions - ordered position rows returned from getContainerPositionsGrid.
 * @param {number} numPositions - declared position count used to choose a known layout.
 * @param {string} targetDivId - id of the panel that should receive the rendered layout.
 * @param {string} feedbackId - optional feedback element id for details-dialog failures.
 */
function renderPositionsGrid(positions, numPositions, targetDivId, feedbackId) {
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
		target.html('<p class="text-muted mb-0">No position containers found.</p>');
		return;
	}
	if (!layoutClass) {
		var tbody = $('<tbody></tbody>');
		$.each(positions, function(i, position) {
			var detailContainerId = position.content_container_id || position.position_id;
			var occupantDisplay = position.content_container_id
				? formatContainerDisplay(position.content_barcode, position.content_label)
				: 'Empty';
			var actionBtn = $('<button class="btn btn-xs btn-outline-info" type="button"></button>')
				.text('Details')
				.on('click', function() {
					openContainerDetailsDialog(detailContainerId, occupantDisplay, feedbackId, false);
				});
			var tr = $('<tr></tr>');
			tr.append($('<td></td>').text(position.position_label || ''));
			tr.append($('<td></td>').text(occupantDisplay));
			tr.append($('<td></td>').text(position.content_container_type || ''));
			tr.append($('<td></td>').append(actionBtn));
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
		var occupantDisplay = position.content_container_id
			? formatContainerDisplay(position.content_barcode, position.content_label)
			: 'Empty';
		var cell = $('<button class="positions-grid-cell" type="button"></button>');
		if (!position.content_container_id) {
			cell.addClass('positions-grid-cell-empty');
		}
		cell.append($('<span class="positions-grid-label"></span>').text(position.position_label || ''));
		cell.append($('<span class="positions-grid-occupant small text-muted"></span>').text(occupantDisplay));
		if (position.content_container_type) {
			cell.append($('<span class="positions-grid-type small text-muted"></span>').text(position.content_container_type));
		}
		cell.on('click', function() {
			openContainerDetailsDialog(detailContainerId, occupantDisplay, feedbackId, false);
		});
		grid.append(cell);
	});
	wrapper.append(grid);
	target.html(wrapper);
}

/**
 * Loads the positions payload for one container and renders the matching grid/table view.
 * @param {number} containerId - the container_id whose positions should be loaded.
 * @param {number} numPositions - fallback declared position count from the initial page payload.
 * @param {string} targetDivId - id of the panel that should receive the rendered layout.
 * @param {string} feedbackId - optional feedback element id for AJAX failures.
 */
function loadPositionsGrid(containerId, numPositions, targetDivId, feedbackId) {
	$('#' + targetDivId).html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading...</div>');
	$.ajax({
		url: '/containers/component/functions.cfc',
		data: {
			method: 'getContainerPositionsGrid',
			container_id: containerId
		},
		dataType: 'json',
		success: function(data) {
			renderPositionsGrid(data.positions || [], parseInt(data.number_positions, 10) || numPositions, targetDivId, feedbackId);
		},
		error: function(jqXHR, textStatus, error) {
			if (feedbackId) {
				setFeedbackControlState(feedbackId, 'error');
			}
			handleFail(jqXHR, textStatus, error, 'loading container positions');
		}
	});
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
	var topLevelOther = data.top_level_other || [];
	var orphanStructDivId = 'ctree-orphan-structural-panel';
	var wrapper = $('<div></div>');
	if (institutions.length === 0 && orphanStructCount === 0 && orphanEmptyProxyCount === 0 && orphanSingleCount === 0 && topLevelOther.length === 0) {
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
			instUl.append($('<li role="treeitem"></li>').append(nodeRow).append(campusUl));
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
		orphanSingleWrap.append(orphanSingleDiv);
		wrapper.append(orphanSingleWrap);
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
			var childBarcode = node.single_child_barcode || '';
			var childLabel = node.single_child_label || '';
			if (childBarcode || childLabel) {
				var childDisplay = formatContainerDisplay(childBarcode, childLabel);
				var inlineLeafDiv = $('<div class="tree-node-inline-leaf"></div>');
				inlineLeafDiv.append($('<span class="tree-node-leaf-info small text-muted"></span>').text('⤷ ' + childDisplay));
				inlineLeafDiv.append(
					$('<button class="btn btn-outline-info btn-xs p-0 ml-1" type="button"></button>')
						.text('Details')
						.on('click', function() {
							openContainerDetailsDialog(cid, displayName, feedbackId, false);
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
		url: '/containers/component/functions.cfc',
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
 * Executes the container search form and renders the paged results table.
 * @param {string} browsePanel - id of the main results panel to populate.
 * @param {string} leafPanel - id of the shared subordinate leaf/table panel.
 * @param {string} feedbackId - optional feedback element id for AJAX failures.
 * @param {number} page - page number to request.
 */
function executeContainerSearch(browsePanel, leafPanel, feedbackId, page) {
	page = page || 1;
	var searchTerm = $('#search_term').val() || '';
	var containerType = $('#container_type').val() || '';
	var barcode = $('#barcode').val() || '';
	var description = $('#description').val() || '';
	var department = $('#department').val() || '';
	var treeProperty = $('#tree_property').val() || '';
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
			var searchLinkUrl = '/containers/Containers.cfm?' + searchLinkParts.join('&');
			var headerDiv = $('<div class="d-flex align-items-center flex-wrap mb-1"></div>');
			headerDiv.append($('<h2 class="h4 mt-2 mr-2 mb-0"></h2>').text('Search Results (' + totalRows + ' containers found)'));
			headerDiv.append(
				$('<a class="small ml-1 mt-1 mr-2" target="_blank" rel="noopener noreferrer"></a>')
					.attr('href', searchLinkUrl)
					.attr('title', 'Link to this search (opens in new tab)')
					.text('Link to this search')
			);
			headerDiv.append(
				$('<button class="btn btn-xs btn-outline-secondary mt-1" type="button"></button>')
					.text('⌂ Browse Hierarchy')
					.attr('title', 'Return to the default container hierarchy view')
					.on('click', function() {
						initContainerBrowse(browsePanel, leafPanel, feedbackId);
						$('#' + leafPanel).addClass('d-none').html('');
					})
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
					var canExplore = containerTypeKey !== COLLECTION_OBJECT_CONTAINER_TYPE && !isTopLevelProxyTableRow;
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
					var locateBtn = $('<button class="btn btn-xs btn-outline-secondary mr-1 mb-1" type="button"></button>').text('Locate');
					(function(nodeId) {
						locateBtn.on('click', function() {
							var btn = $(this);
							var currentRow = btn.closest('tr');
							var detailRowId = 'locate-detail-' + nodeId;
							var existingDetail = $('#' + detailRowId);
							if (existingDetail.length > 0) {
								existingDetail.toggleClass('d-none');
								return;
							}
							var detailRow = $('<tr></tr>').attr('id', detailRowId).addClass('locate-detail-row');
							var detailCell = $('<td></td>').attr('colspan', '5').addClass('bg-light p-2 small');
							detailRow.append(detailCell);
							currentRow.after(detailRow);
							detailCell.html('<img src="/shared/images/indicator.gif"> Loading location…');
							$.ajax({
								url: '/containers/component/search.cfc',
								data: { method: 'getContainerBreadcrumb', container_id: nodeId },
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
									detailCell.html('<span class="text-danger">Failed to load location.</span>');
									handleFail(jqXHR, textStatus, error, 'loading container breadcrumb');
								}
							});
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
					var tr = $('<tr></tr>');
					tr.append(typeTd);
					tr.append($('<td></td>').text(displayName));
					tr.append(contentsTd);
					tr.append($('<td></td>').text(descText));
					tr.append(actionCell);
					tbody.append(tr);
				});
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
