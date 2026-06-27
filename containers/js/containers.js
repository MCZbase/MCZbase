/**
 * Scripts related to the container heirarchy.

Copyright 2023 President and Fellows of Harvard College

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
 * Container types that are expected to hold exactly one collection object each.
 * Nodes of these types have their contained collection object shown inline
 * automatically in the tree, without requiring a "Browse contents" button click.
 */
var SINGLE_OCCUPANT_TYPES = ['pin', 'slide', 'cryovial'];

/** Default page size for container search results and leaf browser. */
var CONTAINER_PAGE_SIZE = 50;

/** Maximum description length (characters) shown in search result rows. */
var MAX_DESCRIPTION_LENGTH = 80;

/**
 * Human-readable labels for the A/B/AB shape classification used internally.
 * A  - container holds only structural (sub-container) children.
 * B  - container holds a large number of collection objects directly (no structural children).
 * AB - container holds both structural children and collection objects directly (mixed).
 */
var SHAPE_LABELS = { A: 'Structural', B: 'Object-bearing', AB: 'Mixed' };

/**
 * Returns a URL to the fixed specimen search pre-filtered by container barcode.
 * Opens Specimens.cfm in fixed-search mode for all specimens in containers
 * that are hierarchically under the container with the given barcode.
 * Returns empty string when barcode is empty.
 * @param {string} barcode - the container barcode to search within.
 * @returns {string} URL string, or '' when barcode is falsy.
 */
function specimenSearchUrl(barcode) {
	if (!barcode) { return ''; }
	return '/Specimens.cfm?action=fixedSearch&execute=true&root_container_barcode=' + encodeURIComponent(barcode);
}

/**
 * Formats a container's display name using barcode as the primary identifier,
 * appending the label in parentheses when it differs from the barcode.
 * Falls back to label alone, or to '(unknown container)' if both are empty.
 * @param {string} barcode - the container's barcode value.
 * @param {string} label - the container's label/name value.
 * @returns {string} a human-readable display name for the container.
 */
function formatContainerDisplay(barcode, label) {
	var b = barcode || '';
	var l = label || '';
	if (b && l && b !== l) {
		return b + ' (' + l + ')';
	}
	return b || l || '(unknown container)';
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
}

/**
 * Renders the initial top-level browse view returned by getTopLevelBrowse.
 * Shows institution nodes pre-expanded to display their campus children.
 * Appends a button to browse orphaned structural nodes (if any) and a button
 * to browse orphaned top-level collection objects (if any).
 *
 * Orphaned structural nodes are non-campus structural containers placed directly
 * under an institution node instead of under a campus.  They are loaded on demand
 * via getOrphanedTopLevelStructural and rendered with renderTreeNodes.
 * Orphaned leaf nodes are collection-object containers placed directly under an
 * institution; they are browsed via loadLeafPanel (same pattern as the Browse contents button).
 *
 * @param {Object} data - response from getTopLevelBrowse.
 * @param {string} browsePanel - id of the container browse panel div.
 * @param {string} leafPanel - id of the leaf browser panel div.
 * @param {string} feedbackEl - id of the status feedback output element.
 */
function renderTopLevelBrowse(data, browsePanel, leafPanel, feedbackEl) {
	var institutions = data.institutions || [];
	var orphanStructCount = parseInt(data.orphaned_structural_count, 10) || 0;
	var orphanLeafCount   = parseInt(data.orphaned_leaf_count, 10) || 0;
	var topLevelOther     = data.top_level_other || [];
	var orphanStructDivId = 'ctree-orphan-structural';
	var wrapper = $('<div></div>');

	if (institutions.length === 0 && orphanStructCount === 0 && orphanLeafCount === 0) {
		wrapper.html('<p class="text-muted my-2">No containers found.</p>');
		$('#' + browsePanel).html(wrapper);
		return;
	}

	/* Institution tree */
	if (institutions.length > 0) {
		var instUl = $('<ul class="container-tree" role="tree"></ul>');
		$.each(institutions, function(idx, inst) {
			var instDisplay = formatContainerDisplay(inst.barcode, inst.label);
			var instCid     = inst.container_id;
			var campuses    = inst.campus_children || [];
			var childUlId   = 'ctree-children-' + instCid;
			var toggleId    = 'ctree-toggle-' + instCid;
			var nodeRow     = $('<div class="d-flex align-items-center flex-wrap tree-node-row"></div>');

			/* Expand toggle — shown only when institution has structural children */
			if (parseInt(inst.direct_structural_children, 10) > 0) {
				var instToggle = $('<button></button>')
					.attr('id', toggleId)
					.attr('aria-expanded', 'true')
					.attr('aria-controls', childUlId)
					.attr('aria-label', 'Collapse ' + instDisplay)
					.addClass('tree-node-toggle btn btn-xs btn-link mr-1');
				instToggle.on('click', function() {
					var expanded = $(this).attr('aria-expanded') === 'true';
					if (!expanded && $('#' + childUlId).children().length === 0) {
						loadContainerNode(instCid, childUlId, feedbackEl);
					}
					$('#' + childUlId).toggleClass('collapse');
					$(this).attr('aria-expanded', expanded ? 'false' : 'true');
				});
				nodeRow.append(instToggle);
			}

			nodeRow.append($('<span class="tree-node-label"></span>').text(instDisplay));
			nodeRow.append($('<span class="tree-node-type text-muted small mx-1"></span>').text('[' + inst.container_type + ']'));

			/* Campus children pre-rendered (institution starts expanded) */
			var campusUl = $('<ul></ul>').attr('id', childUlId).addClass('container-tree');
			if (campuses.length > 0) {
				$.each(campuses, function(ci, campus) {
					var campusDisplay = formatContainerDisplay(campus.barcode, campus.label);
					var campusCid     = campus.container_id;
					var campusChildId = 'ctree-children-' + campusCid;
					var campusTogId   = 'ctree-toggle-' + campusCid;
					var campusRow     = $('<div class="d-flex align-items-center flex-wrap tree-node-row"></div>');

					if (parseInt(campus.direct_structural_children, 10) > 0) {
						var campusToggle = $('<button></button>')
							.attr('id', campusTogId)
							.attr('aria-expanded', 'false')
							.attr('aria-controls', campusChildId)
							.attr('aria-label', 'Expand ' + campusDisplay)
							.addClass('tree-node-toggle btn btn-xs btn-link mr-1');
						campusToggle.on('click', function() {
							var expanded = $(this).attr('aria-expanded') === 'true';
							if (!expanded && $('#' + campusChildId).children().length === 0) {
								loadContainerNode(campusCid, campusChildId, feedbackEl);
							}
							$('#' + campusChildId).toggleClass('collapse');
							$(this).attr('aria-expanded', expanded ? 'false' : 'true');
						});
						campusRow.append(campusToggle);
					}

					campusRow.append($('<span class="tree-node-label"></span>').text(campusDisplay));
					campusRow.append($('<span class="tree-node-type text-muted small mx-1"></span>').text('[' + campus.container_type + ']'));

					var campusLeafDiv = null;
					if (parseInt(campus.direct_leaf_children, 10) > 0) {
						var campusLeafDivId = 'ctree-leaf-' + campusCid;
						campusLeafDiv = $('<div class="d-none mt-1"></div>').attr('id', campusLeafDivId);
						var campusBrowseBtn = $('<button></button>')
							.addClass('btn btn-xs btn-outline-secondary ml-1')
							.text('Browse contents')
								.on('click', (function(ncid, nlabel, nbcode, ldivId) {
									return function() {
										var btn = $(this);
										var panel = $('#' + ldivId);
										if (panel.hasClass('d-none')) {
											if (!btn.data('loaded')) {
												loadLeafPanel(ncid, ldivId, feedbackEl, 1, nlabel, nbcode);
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

						/* Specimen search link: campus node with leaf descendants at any depth */
						if (parseInt(campus.has_leaf_descendants, 10) > 0 && campus.barcode) {
							var campusSpecUrl = specimenSearchUrl(campus.barcode);
							campusRow.append(
								$('<a class="btn btn-xs btn-outline-info ml-1" target="_blank" rel="noopener noreferrer"></a>')
									.attr('href', campusSpecUrl)
									.attr('title', 'Search for specimens in this campus')
									.text('Specimens')
							);
						}

					var campusChildUl = $('<ul></ul>').attr('id', campusChildId).addClass('collapse container-tree');
					var campusLi = $('<li role="treeitem"></li>').append(campusRow);
					if (campusLeafDiv) {
						campusLi.append(campusLeafDiv);
					}
					campusLi.append(campusChildUl);
					campusUl.append(campusLi);
				});
			} else if (parseInt(inst.direct_structural_children, 10) > 0) {
				/* Institution has structural children but none are campuses; mark for lazy load */
				campusUl.addClass('collapse');
			}

			var instLi = $('<li role="treeitem"></li>').append(nodeRow).append(campusUl);
			instUl.append(instLi);
		});
		wrapper.append(instUl);
	}

	/* Button: browse orphaned structural nodes */
	if (orphanStructCount > 0) {
		var orphanStructLabel = 'Browse ' + orphanStructCount + ' other structural container' + (orphanStructCount !== 1 ? 's' : '') + ' not placed under a campus';
		var orphanStructDiv = $('<div class="mt-2" id="' + orphanStructDivId + '"></div>');
		var orphanStructBtn = $('<button class="btn btn-xs btn-outline-secondary"></button>').text(orphanStructLabel);
		orphanStructBtn.on('click', function() {
			var btn = $(this);
			btn.prop('disabled', true).text('Loading\u2026');
			$.ajax({
				url: '/containers/component/functions.cfc',
				data: { method: 'getOrphanedTopLevelStructural' },
				dataType: 'json',
				success: function(nodes) {
					btn.remove();
					renderTreeNodes(nodes, orphanStructDivId, feedbackEl);
				},
				error: function(jqXHR, textStatus, error) {
					btn.prop('disabled', false).text(orphanStructLabel);
					handleFail(jqXHR, textStatus, error, 'loading orphaned structural containers');
				}
			});
		});
		orphanStructDiv.append(orphanStructBtn);
		wrapper.append(orphanStructDiv);
	}

	/* Button: browse orphaned leaf nodes (collection objects at root level) */
	if (orphanLeafCount > 0) {
		var orphanLeafLabel = 'Browse ' + orphanLeafCount + ' unplaced collection object' + (orphanLeafCount !== 1 ? 's' : '');
		var orphanLeafBtn = $('<button class="btn btn-xs btn-outline-secondary mt-2"></button>').text(orphanLeafLabel);
		orphanLeafBtn.on('click', function() {
			loadLeafPanel(1, leafPanel, feedbackEl, 1, 'Unplaced collection objects', '');
		});
		wrapper.append(orphanLeafBtn);
	}

	/* Root-level non-institution containers (e.g., Deaccessioned campus at root level)
	   Build the container div and append it to wrapper BEFORE inserting wrapper into the
	   DOM so that renderTreeNodes (which selects by DOM id) can find the element. */
	var rootOtherDivId = 'ctree-root-other';
	if (topLevelOther.length > 0) {
		var rootOtherDiv = $('<div class="mt-3"></div>');
		rootOtherDiv.append($('<h3 class="h5 text-muted"></h3>').text('Other Top-Level Containers'));
		var rootOtherUlDiv = $('<div></div>').attr('id', rootOtherDivId);
		rootOtherDiv.append(rootOtherUlDiv);
		wrapper.append(rootOtherDiv);
	}

	/* Insert wrapper into the DOM first, then call renderTreeNodes so the target div exists. */
	$('#' + browsePanel).html(wrapper);

	if (topLevelOther.length > 0) {
		renderTreeNodes(topLevelOther, rootOtherDivId, feedbackEl);
	}
}

/**
 * Loads the direct structural children of containerId into targetDivId via
 * an AJAX call to functions.cfc?method=getDirectStructuralChildren.
 * Shows a loading spinner while loading; on success calls renderTreeNodes.
 * @param {number} containerId - the container_id whose children to load.
 * @param {string} targetDivId - the id of the div to render results into (without leading #).
 * @param {string} feedbackId - the id of the output element for status feedback (without leading #).
 */
function loadContainerNode(containerId, targetDivId, feedbackId) {
	$('#' + targetDivId).html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading...</div>');
	$.ajax({
		url: '/containers/component/functions.cfc',
		data: { method: 'getDirectStructuralChildren', container_id: containerId },
		dataType: 'json',
		success: function(data) {
			renderTreeNodes(data, targetDivId, feedbackId);
		},
		error: function(jqXHR, textStatus, error) {
			handleFail(jqXHR, textStatus, error, 'loading container children');
		}
	});
}

/**
 * Renders an array of node objects as a tree list inside targetDivId.
 * Each node row shows an optional expand toggle button, the container barcode/name
 * as selectable text, the container type in brackets as separate metadata, and an
 * optional "Browse contents" button. The lazy-loaded child list expands below that
 * row so buttons are never displaced.
 * The expand toggle is only shown when direct_structural_children > 0.
 * The "Browse contents" button is only shown for non-single-occupant nodes when
 * direct_leaf_children > 0. For single-occupant container types (pin, slide,
 * cryovial) the contained collection object is shown inline using data already
 * returned by getDirectStructuralChildren — no additional AJAX request is needed.
 * Badges are added to indicate empty nodes, misplaced items, AB shape,
 * leaf counts, and structural counts.
 * @param {Array} nodes - array of node objects from getDirectStructuralChildren.
 * @param {string} targetDivId - the id of the element to render into (without leading #).
 * @param {string} feedbackId - the id of the output element for status feedback (without leading #).
 */
function renderTreeNodes(nodes, targetDivId, feedbackId) {
	if (!nodes || nodes.length === 0) {
		$('#' + targetDivId).html('<p class="text-muted my-2">No structural containers found.</p>');
		return;
	}
	var ul = $('<ul class="container-tree" role="tree"></ul>');
	$.each(nodes, function(idx, node) {
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
		var isSingleOccupant = SINGLE_OCCUPANT_TYPES.indexOf(ctype) !== -1;

		/* Display barcode as the primary identifier; append label in parens if it differs. */
		var displayName = formatContainerDisplay(barcode, label);

		/* nodeRow holds the expand toggle, name text, type metadata, and Browse button on
		   one line; childUl is a sibling below so expanding never displaces the buttons. */
		var nodeRow = $('<div class="d-flex align-items-center flex-wrap tree-node-row"></div>');

		if (structuralChildren > 0) {
			var toggle = $('<button></button>')
				.attr('id', toggleId)
				.attr('aria-expanded', 'false')
				.attr('aria-controls', childUlId)
				.attr('aria-label', 'Expand ' + displayName)
				.addClass('tree-node-toggle btn btn-xs btn-link mr-1');

			toggle.on('click', function() {
				var expanded = $(this).attr('aria-expanded') === 'true';
				if (!expanded && $('#' + childUlId).children().length === 0) {
					loadContainerNode(cid, childUlId, feedbackId);
				}
				$('#' + childUlId).toggleClass('collapse');
				$(this).attr('aria-expanded', expanded ? 'false' : 'true');
			});

			nodeRow.append(toggle);
		}

		/* Container name as selectable text, separate from the toggle button. */
		nodeRow.append($('<span class="tree-node-label"></span>').text(displayName));
		/* Container type as secondary metadata. */
		nodeRow.append($('<span class="tree-node-type text-muted small mx-1"></span>').text('[' + ctype + ']'));

		/* Empty node marker */
		if (structuralChildren === 0 && leafChildren === 0) {
			nodeRow.append(
				$('<span class="badge badge-light border text-muted small ml-1"></span>')
					.attr('title', 'Empty container — no children')
					.text('empty')
			);
		}

		/* Misplaced marker: single-occupant type with more than one leaf child */
		if (isSingleOccupant && leafChildren > 1) {
			nodeRow.append(
				$('<span class="badge badge-warning ml-1 small"></span>')
					.attr('title', 'Single-occupant type with multiple children \u2014 may be misplaced')
					.text('!')
			);
		}

		/* Mixed node badge: has both structural children and collection objects */
		if (leafChildren > 0 && structuralChildren > 0) {
			nodeRow.append(
				$('<span class="badge badge-warning ml-1 small"></span>')
					.attr('title', 'Contains both structural containers and collection objects (mixed)')
					.text('Mixed')
			);
		}

		/* Leaf count badge (only when no structural children) */
		if (leafChildren > 0 && structuralChildren === 0) {
			nodeRow.append(
				$('<span class="badge badge-info ml-1 small"></span>')
					.text(leafChildren + ' obj')
			);
		}

		/* Structural count badge */
		if (structuralChildren > 0) {
			nodeRow.append(
				$('<span class="badge badge-light border text-muted ml-1 small"></span>')
					.text(structuralChildren + ' containers')
			);
		}

		var nodeLeafDiv = null;
		if (leafChildren > 0 && !isSingleOccupant) {
			var leafDivId = 'ctree-leaf-' + cid;
			nodeLeafDiv = $('<div class="d-none mt-1"></div>').attr('id', leafDivId);
			var browseBtn = $('<button></button>')
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

		/* Specimen search link: any node with leaf descendants at any depth and a barcode. */
		if (hasLeafDescendants && barcode) {
			var specUrl = specimenSearchUrl(barcode);
			nodeRow.append(
				$('<a class="btn btn-xs btn-outline-info ml-1" target="_blank" rel="noopener noreferrer"></a>')
					.attr('href', specUrl)
					.attr('title', 'Search for specimens in this container')
					.text('Specimens')
			);
		}

		var childUl = $('<ul></ul>')
			.attr('id', childUlId)
			.addClass('collapse container-tree');

		var li = $('<li role="treeitem"></li>').append(nodeRow);

		/* Description line below the node row */
		if (nodeDescription) {
			li.append(
				$('<div class="tree-node-desc small text-muted fst-italic"></div>').text(nodeDescription)
			);
		}

		if (nodeLeafDiv) {
			li.append(nodeLeafDiv);
		}
		li.append(childUl);

		/* For single-occupant container types, render the contained collection object
		   inline using data already returned by getDirectStructuralChildren — no extra
		   AJAX request required. Only render if child data is present. */
		if (isSingleOccupant && leafChildren > 0) {
			var childBarcode = node.single_child_barcode || '';
			var childLabel = node.single_child_label || '';
			if (childBarcode || childLabel) {
				var childDisplay = formatContainerDisplay(childBarcode, childLabel);
				var inlineLeafDiv = $('<div class="tree-node-inline-leaf"></div>');
				inlineLeafDiv.append(
					$('<span class="tree-node-leaf-info small text-muted"></span>').text('\u2937 ' + childDisplay)
				);
				/* Link to specimen search using the collection object container's own barcode.
					   Only show when the child barcode is known; do not fall back to the parent
					   barcode as that would search the entire parent hierarchy. */
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
	$('#' + targetDivId).html(ul);
}


/**
 * Loads the first page of direct collection-object children for containerId
 * from functions.cfc?method=getDirectLeafChildren and renders them as a table
 * in leafPanelId.  Shows the leaf panel; hides it on error.
 * Includes First/Previous/Next/Last page navigation both above and below the
 * table when totalRows > pageSize.
 * Each collection-object row includes a Specimen column showing the GUID link
 * (institution_acronym:collection_cde:cat_num), scientific name, and part name when
 * the container is linked to a cataloged specimen, plus a link to the specimen search.
 * @param {number} containerId - the container_id whose leaf children to browse.
 * @param {string} leafPanelId - the id of the div for the leaf panel (without leading #).
 * @param {string} feedbackId - the id of the output element for status feedback (without leading #).
 * @param {number} [page=1] - the page number to load (1-based).
 * @param {string} [containerLabel] - optional display name of the container being browsed.
 * @param {string} [containerBarcode] - optional barcode of the parent container, used to generate
 *   a "View all specimens" link for all objects in the container hierarchy.
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
			var totalPages = Math.ceil(totalRows / pageSize);

			var panel = $('<div class="container-leaf-panel"></div>');
			var headingDiv = $('<div class="d-flex align-items-center flex-wrap mb-1"></div>');
			var heading = containerLabel
				? 'Contents of ' + containerLabel + ' (' + totalRows + ' collection objects)'
				: 'Contents (' + totalRows + ' collection objects)';
			headingDiv.append($('<h3 class="h5 mr-2 mb-0"></h3>').text(heading));
			/* "View all specimens" link when the container has a barcode */
			var allSpecUrl = specimenSearchUrl(containerBarcode);
			if (allSpecUrl && totalRows > 0) {
				headingDiv.append(
					$('<a class="btn btn-xs btn-outline-info" target="_blank" rel="noopener noreferrer"></a>')
						.attr('href', allSpecUrl)
						.attr('title', 'View all specimens in this container in the specimen search')
						.text('View all in Specimen Search')
				);
			}
			panel.append(headingDiv);

			if (totalPages > 1) {
				panel.append(
					$('<p class="small text-muted mb-1"></p>').text('Page ' + currentPage + ' of ' + totalPages)
				);
			}

			/* Builds a First/Prev/Next/Last navigation bar. */
			function buildPagingNav(extraClass) {
				var nav = $('<nav></nav>')
					.attr('aria-label', 'Page navigation')
					.addClass('d-flex flex-wrap' + (extraClass ? ' ' + extraClass : ''));
				var firstBtn = $('<button class="btn btn-xs btn-secondary mr-1">\u00ab First</button>').attr('aria-label', 'Go to first page');
				var prevBtn  = $('<button class="btn btn-xs btn-secondary mr-1">\u2039 Prev</button>').attr('aria-label', 'Go to previous page');
				var nextBtn  = $('<button class="btn btn-xs btn-secondary mr-1">Next \u203a</button>').attr('aria-label', 'Go to next page');
				var lastBtn  = $('<button class="btn btn-xs btn-secondary">Last \u00bb</button>').attr('aria-label', 'Go to last page');
				if (currentPage <= 1) {
					firstBtn.prop('disabled', true);
					prevBtn.prop('disabled', true);
				} else {
					firstBtn.addClass('leaf-page-btn').data('cid', containerId).data('page', 1);
					prevBtn.addClass('leaf-page-btn').data('cid', containerId).data('page', currentPage - 1);
				}
				if (currentPage >= totalPages) {
					nextBtn.prop('disabled', true);
					lastBtn.prop('disabled', true);
				} else {
					nextBtn.addClass('leaf-page-btn').data('cid', containerId).data('page', currentPage + 1);
					lastBtn.addClass('leaf-page-btn').data('cid', containerId).data('page', totalPages);
				}
				nav.append(firstBtn).append(prevBtn).append(nextBtn).append(lastBtn);
				return nav;
			}

			if (rows.length === 0) {
				panel.append('<p class="text-muted">No collection objects found.</p>');
			} else {
				if (totalRows > pageSize) {
					panel.append(buildPagingNav('mb-1'));
				}

				var tbody = $('<tbody></tbody>');
				$.each(rows, function(i, row) {
					var rowDisplay = formatContainerDisplay(row.barcode, row.label);
					var tr = $('<tr></tr>');
					tr.append($('<td></td>').text(rowDisplay));
					/* Specimen info cell: GUID link + taxon name + part name */
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
					}
					tr.append(specTd);
					tr.append($('<td></td>').text(row.description));
					var actionTd = $('<td></td>');
					/* Link to specimen search using this collection object's own barcode */
					var rowSpecUrl = specimenSearchUrl(row.barcode);
					if (rowSpecUrl) {
						actionTd.append(
							$('<a class="btn btn-xs btn-outline-info" target="_blank" rel="noopener noreferrer"></a>')
								.attr('href', rowSpecUrl)
								.attr('title', 'View this specimen in the specimen search')
								.text('View specimen')
						);
					}
					tr.append(actionTd);
					tbody.append(tr);
				});
				var table = $('<table class="table table-sm table-striped"></table>');
				table.append('<thead><tr><th>Container</th><th>Specimen</th><th>Description</th><th>Actions</th></tr></thead>');
				table.append(tbody);
				panel.append(table);

				if (totalRows > pageSize) {
					panel.append(buildPagingNav('mt-2'));
				}
			}

			var leafEl = $('#' + leafPanelId);
			leafEl.removeClass('d-none').html(panel);
			leafEl.off('click.leafpage').on('click.leafpage', '.leaf-page-btn', function() {
				loadLeafPanel($(this).data('cid'), leafPanelId, feedbackId, $(this).data('page'), containerLabel, containerBarcode);
			});
		},
		error: function(jqXHR, textStatus, error) {
			$('#' + leafPanelId).addClass('d-none');
			handleFail(jqXHR, textStatus, error, 'loading leaf container contents');
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
			$('#containerBrowseContext').text('Exploring: ' + displayName);
			/* Detect "unplaced" containers: those without a campus ancestor.
			   These are not in the pre-rendered institution/campus tree so trying to
			   expand the breadcrumb path in the full tree would silently fail.
			   Instead, render the container as a standalone expandable node. */
			var hasCampusAncestor = breadcrumbs && breadcrumbs.some(function(b) { return b.container_type === 'campus'; });
			if (!breadcrumbs || breadcrumbs.length === 0 || !hasCampusAncestor) {
				renderUnplacedContainerNode(containerId, breadcrumbs, browsePanel, feedbackId);
				return;
			}
			$.ajax({
				url: '/containers/component/functions.cfc',
				data: { method: 'getTopLevelBrowse' },
				dataType: 'json',
				success: function(data) {
					renderTopLevelBrowse(data, browsePanel, leafPanel, feedbackId);
					/* Expand each ancestor level then highlight the target */
					expandBreadcrumbPath(breadcrumbs, 0, feedbackId, containerId);
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
				var label = $('#ctree-children-' + containerId).closest('li')
					.children('.tree-node-row').find('.tree-node-label').first();
				if (label.length > 0) {
					label.addClass('tree-node-highlighted');
					var el = label[0];
					if (el) { el.scrollIntoView({ behavior: 'smooth', block: 'nearest' }); }
				}
			}, 50);
		},
		error: function(jqXHR, textStatus, error) {
			handleFail(jqXHR, textStatus, error, 'loading unplaced container info');
		}
	});
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
	/* When we reach the last breadcrumb (the target itself), just highlight it */
	if (index >= breadcrumbs.length - 1) {
		/* The target node's li contains #ctree-children-{targetId} as a descendant */
		var targetLi = $('#ctree-children-' + targetId).closest('li');
		if (targetLi.length > 0) {
			var targetLabel = targetLi.children('.tree-node-row').find('.tree-node-label').first();
			targetLabel.addClass('tree-node-highlighted');
			var el = targetLabel[0];
			if (el) {
				el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
			}
		}
		return;
	}

	var node = breadcrumbs[index];
	var nodeId = node.container_id;
	var childDivId = 'ctree-children-' + nodeId;
	var childDiv = $('#' + childDivId);

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

	/* If children are not yet loaded (no li children), load them first */
	if (childDiv.children('li').length === 0) {
		childDiv.html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif"> Loading\u2026</div>');
		$.ajax({
			url: '/containers/component/functions.cfc',
			data: { method: 'getDirectStructuralChildren', container_id: nodeId },
			dataType: 'json',
			success: function(data) {
				renderTreeNodes(data, childDivId, feedbackId);
				expandBreadcrumbPath(breadcrumbs, index + 1, feedbackId, targetId);
			},
			error: function(jqXHR, textStatus, error) {
				handleFail(jqXHR, textStatus, error, 'loading container children for exploration');
			}
		});
	} else {
		/* Children already loaded — proceed to next level */
		expandBreadcrumbPath(breadcrumbs, index + 1, feedbackId, targetId);
	}
}

/**
 * Submits the container search form fields to searchContainers in search.cfc and
 * renders the results as a table in the browse panel.
 * Results show columns: Type, Name/Barcode, Contents, Description, Actions.
 * Each row has Explore, Browse, Specimens, and Locate action buttons as applicable.
 * Includes prev/next pagination when totalRows > pageSize.
 * A "Browse Hierarchy" button allows the user to return to the default tree view.
 * @param {string} browsePanel - the id of the container browse panel div (without leading #).
 * @param {string} leafPanel - the id of the leaf panel div (without leading #).
 * @param {string} feedbackId - the id of the feedback output element (without leading #).
 * @param {number} [page=1] - page number (1-based).
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
			var totalPages = Math.ceil(totalRows / pageSize);

			var panel = $('<div></div>');

				/* Build "link to this search" URL from current form values */
				var searchLinkParts = ['execute=true'];
				if (containerType) { searchLinkParts.push('container_type=' + encodeURIComponent(containerType)); }
				if (searchTerm)    { searchLinkParts.push('search_term=' + encodeURIComponent(searchTerm)); }
				if (barcode)       { searchLinkParts.push('barcode=' + encodeURIComponent(barcode)); }
				if (description)   { searchLinkParts.push('description=' + encodeURIComponent(description)); }
				if (department)    { searchLinkParts.push('department=' + encodeURIComponent(department)); }
				if (treeProperty)  { searchLinkParts.push('tree_property=' + encodeURIComponent(treeProperty)); }
				var searchLinkUrl = '/containers/Containers.cfm?' + searchLinkParts.join('&');

				/* Header row: title + link to this search + Browse Hierarchy button */
				var headerDiv = $('<div class="d-flex align-items-center flex-wrap mb-1"></div>');
				headerDiv.append($('<h2 class="h4 mt-2 mr-2 mb-0"></h2>').text('Search Results (' + totalRows + ' containers found)'));
				headerDiv.append(
					$('<a class="small ml-1 mt-1 mr-2" target="_blank" rel="noopener noreferrer"></a>')
						.attr('href', searchLinkUrl)
						.attr('title', 'Link to this search (opens in new tab)')
						.text('Link to this search')
				);
				var browseHierarchyBtn = $('<button class="btn btn-xs btn-outline-secondary mt-1"></button>')
					.text('\u2302 Browse Hierarchy')
					.attr('title', 'Return to the default container hierarchy view')
					.on('click', function() {
						initContainerBrowse(browsePanel, leafPanel, feedbackId);
						$('#' + leafPanel).addClass('d-none').html('');
					});
				headerDiv.append(browseHierarchyBtn);
				panel.append(headerDiv);

			if (totalPages > 1) {
				panel.append(
					$('<p class="small text-muted mb-1"></p>').text('Page ' + currentPage + ' of ' + totalPages)
				);
			}

			/* Inline pagination nav builder */
			function buildSearchNav(extraClass) {
				var nav = $('<nav></nav>')
					.attr('aria-label', 'Search results page navigation')
					.addClass('d-flex flex-wrap' + (extraClass ? ' ' + extraClass : ''));
				var prevBtn = $('<button class="btn btn-xs btn-secondary mr-1">\u2039 Prev</button>').attr('aria-label', 'Previous page');
				var nextBtn = $('<button class="btn btn-xs btn-secondary">Next \u203a</button>').attr('aria-label', 'Next page');
				if (currentPage <= 1) {
					prevBtn.prop('disabled', true);
				} else {
					prevBtn.addClass('search-page-btn').data('page', currentPage - 1);
				}
				if (currentPage >= totalPages) {
					nextBtn.prop('disabled', true);
				} else {
					nextBtn.addClass('search-page-btn').data('page', currentPage + 1);
				}
				nav.append(prevBtn).append(nextBtn);
				return nav;
			}

			if (rows.length === 0) {
				panel.append('<p class="text-muted my-2">No containers matched your search.</p>');
			} else {
				if (totalRows > pageSize) {
					panel.append(buildSearchNav('mb-2'));
				}

				var tbody = $('<tbody></tbody>');
				$.each(rows, function(i, row) {
					var cid = row.container_id;
					var structKids = parseInt(row.direct_structural_children, 10) || 0;
					var leafKids = parseInt(row.direct_leaf_children, 10) || 0;
					var isSingle = SINGLE_OCCUPANT_TYPES.indexOf(row.container_type) !== -1;
					var displayName = formatContainerDisplay(row.barcode, row.label);
					var descText = row.description || '';
					if (descText.length > MAX_DESCRIPTION_LENGTH) {
						descText = descText.substring(0, MAX_DESCRIPTION_LENGTH) + '\u2026';
					}

					/* Contents summary badge: show user-friendly shape label */
					var shapeClass = row.shape_class || 'A';
					var shapeLabel = SHAPE_LABELS[shapeClass] || shapeClass;
						var shapeBadgeClass;
					if (shapeClass === 'AB') { shapeBadgeClass = 'badge-warning'; }
					else if (shapeClass === 'B') { shapeBadgeClass = 'badge-info'; }
					else { shapeBadgeClass = 'badge-light border text-muted'; }
					var shapeBadge = $('<span class="badge small"></span>').addClass(shapeBadgeClass).text(shapeLabel);

					var actionCell = $('<td></td>');

					if (structKids > 0) {
						var exploreBtn = $('<button class="btn btn-xs btn-outline-primary mr-1"></button>').text('Explore');
						(function(nodeId, nodeName) {
							exploreBtn.on('click', function() {
								exploreContainerInTree(nodeId, nodeName, browsePanel, leafPanel, feedbackId);
							});
						})(cid, displayName);
						actionCell.append(exploreBtn);
					}

					if (leafKids > 0 && !isSingle) {
						var browseBtn = $('<button class="btn btn-xs btn-outline-secondary mr-1"></button>').text('Browse');
						(function(nodeId, nodeName, nodeBarcode) {
							browseBtn.on('click', function() {
								var leafDivId = 'search-leaf-' + nodeId;
								if ($('#' + leafDivId).length === 0) {
									$('#' + leafPanel).removeClass('d-none').append($('<div></div>').attr('id', leafDivId));
								}
								loadLeafPanel(nodeId, leafDivId, feedbackId, 1, nodeName, nodeBarcode);
							});
						})(cid, displayName, row.barcode || '');
						actionCell.append(browseBtn);
					}

					/* Specimens link: any row with any children (direct or structural) and a barcode.
						   For direct leaf children the link is certain to return results; for containers
						   with only structural children it is a best-effort proxy — the search may return
						   0 results if the subtree contains no specimens, but most structural containers
						   in a collection management system do contain specimens. */
						if ((leafKids > 0 || structKids > 0) && row.barcode) {
						var specUrl = specimenSearchUrl(row.barcode);
						actionCell.append(
							$('<a class="btn btn-xs btn-outline-info mr-1" target="_blank" rel="noopener noreferrer"></a>')
								.attr('href', specUrl)
								.attr('title', 'View specimens in this container in the specimen search')
								.text('Specimens')
						);
					}

					var locateBtn = $('<button class="btn btn-xs btn-outline-secondary"></button>').text('Locate');
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
								success: function(data) {
									var breadcrumbEl = $('<ol class="breadcrumb bg-transparent p-0 m-0 flex-wrap"></ol>');
									$.each(data, function(i, node) {
										var display = formatContainerDisplay(node.barcode, node.label);
										var crumbText = node.container_type + ': ' + display;
										var crumbLi = $('<li class="breadcrumb-item small"></li>');
										if (i === data.length - 1) {
											crumbLi.addClass('active').attr('aria-current', 'page').text(crumbText);
										} else {
											crumbLi.text(crumbText);
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

					/* Contents summary cell: shape badge + child counts */
					var contentsTd = $('<td></td>');
					contentsTd.append(shapeBadge);
					if (structKids > 0) {
						contentsTd.append($('<span class="ml-1 small text-muted"></span>').text(structKids + ' containers'));
					}
					if (leafKids > 0) {
						contentsTd.append($('<span class="ml-1 small text-muted"></span>').text(leafKids + ' obj'));
					}

					var tr = $('<tr></tr>');
					tr.append($('<td></td>').text(row.container_type));
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

				if (totalRows > pageSize) {
					panel.append(buildSearchNav('mt-2'));
				}
			}

			var browsePanelEl = $('#' + browsePanel);
			browsePanelEl.html(panel);
			browsePanelEl.off('click.searchpage').on('click.searchpage', '.search-page-btn', function() {
				executeContainerSearch(browsePanel, leafPanel, feedbackId, $(this).data('page'));
			});
		},
		error: function(jqXHR, textStatus, error) {
			handleFail(jqXHR, textStatus, error, 'searching containers');
		}
	});
}
