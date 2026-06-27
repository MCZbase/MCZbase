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
							.on('click', function() {
								loadLeafPanel(campusCid, campusLeafDivId, feedbackEl, 1, campusDisplay);
							});
						campusRow.append(campusBrowseBtn);
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
			loadLeafPanel(1, leafPanel, feedbackEl, 1, 'Unplaced collection objects');
		});
		wrapper.append(orphanLeafBtn);
	}

	$('#' + browsePanel).html(wrapper);
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
				$('<span class="badge badge-light border text-muted ml-1"></span>')
					.attr('title', 'Empty container')
					.text('empty')
			);
		}

		/* Misplaced marker: single-occupant type with more than one leaf child */
		if (isSingleOccupant && leafChildren > 1) {
			nodeRow.append(
				$('<span class="badge badge-warning ml-1"></span>')
					.attr('title', 'Single-occupant type with multiple children \u2014 may be misplaced')
					.text('!')
			);
		}

		/* AB shape badge */
		if (leafChildren > 0 && structuralChildren > 0) {
			nodeRow.append(
				$('<span class="badge badge-warning ml-1 tree-leaf-badge"></span>')
					.attr('title', 'Contains both structural containers and collection objects')
					.text('AB')
			);
		}

		/* Leaf count badge (only when no structural children) */
		if (leafChildren > 0 && structuralChildren === 0) {
			nodeRow.append(
				$('<span class="badge badge-secondary ml-1 tree-leaf-badge"></span>')
					.text(leafChildren + ' obj')
			);
		}

		/* Structural count badge */
		if (structuralChildren > 0) {
			nodeRow.append(
				$('<span class="badge badge-light border ml-1 tree-leaf-badge"></span>')
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
				.on('click', function() {
					loadLeafPanel(cid, leafDivId, feedbackId, 1, displayName);
				});
			nodeRow.append(browseBtn);
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
				li.append(
					$('<div class="tree-node-inline-leaf"></div>').append(
						$('<span class="tree-node-leaf-info small text-muted"></span>').text('\u2937 ' + childDisplay)
					)
				);
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
 * @param {number} containerId - the container_id whose leaf children to browse.
 * @param {string} leafPanelId - the id of the div for the leaf panel (without leading #).
 * @param {string} feedbackId - the id of the output element for status feedback (without leading #).
 * @param {number} [page=1] - the page number to load (1-based).
 * @param {string} [containerLabel] - optional display name of the container being browsed.
 */
function loadLeafPanel(containerId, leafPanelId, feedbackId, page, containerLabel) {
	page = page || 1;
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
			var heading = containerLabel
				? 'Contents of ' + containerLabel + ' (' + totalRows + ' collection objects)'
				: 'Contents (' + totalRows + ' collection objects)';
			panel.append($('<h3 class="h5"></h3>').text(heading));

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
					tr.append($('<td></td>').text(row.description));
					tbody.append(tr);
				});
				var table = $('<table class="table table-sm table-striped"></table>');
				table.append('<thead><tr><th>Container</th><th>Description</th></tr></thead>');
				table.append(tbody);
				panel.append(table);

				if (totalRows > pageSize) {
					panel.append(buildPagingNav('mt-2'));
				}
			}

			var leafEl = $('#' + leafPanelId);
			leafEl.removeClass('d-none').html(panel);
			leafEl.off('click.leafpage').on('click.leafpage', '.leaf-page-btn', function() {
				loadLeafPanel($(this).data('cid'), leafPanelId, feedbackId, $(this).data('page'), containerLabel);
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
					crumbLi.addClass('active').attr('aria-current', 'location').text(crumbText);
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
			if (!breadcrumbs || breadcrumbs.length === 0) {
				/* No path — fall back to showing just this node's children */
				$('#containerBrowseContext').text('Exploring: ' + displayName);
				loadContainerNode(containerId, browsePanel, feedbackId);
				return;
			}
			$('#containerBrowseContext').text('Exploring: ' + displayName);
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
 * Results show columns: Type, Name/Barcode, Shape, Structural Children, Leaf Children, Description.
 * Each row has Explore, Browse, and Locate action buttons depending on the node's children.
 * Includes prev/next pagination when totalRows > pageSize.
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
			panel.append($('<h2 class="h4 mt-2"></h2>').text('Search Results (' + totalRows + ' containers found)'));

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

					/* Shape badge */
					var shapeClass = row.shape_class || 'A';
					var shapeBadgeClass = 'badge-secondary';
					if (shapeClass === 'AB') { shapeBadgeClass = 'badge-warning'; }
					if (shapeClass === 'B') { shapeBadgeClass = 'badge-danger'; }
					var shapeBadge = $('<span class="badge"></span>').addClass(shapeBadgeClass).text(shapeClass);

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
						(function(nodeId, nodeName) {
							browseBtn.on('click', function() {
								var leafDivId = 'search-leaf-' + nodeId;
								if ($('#' + leafDivId).length === 0) {
									$('#' + leafPanel).removeClass('d-none').append($('<div></div>').attr('id', leafDivId));
								}
								loadLeafPanel(nodeId, leafDivId, feedbackId, 1, nodeName);
							});
						})(cid, displayName);
						actionCell.append(browseBtn);
					}

					var locateBtn = $('<button class="btn btn-xs btn-outline-info"></button>').text('Locate');
					(function(nodeId, bPanel) {
						locateBtn.on('click', function() {
							showContainerBreadcrumb(nodeId, feedbackId, bPanel);
						});
					})(cid, browsePanel);
					actionCell.append(locateBtn);

					var tr = $('<tr></tr>');
					tr.append($('<td></td>').text(row.container_type));
					tr.append($('<td></td>').text(displayName));
					tr.append($('<td></td>').append(shapeBadge));
					tr.append($('<td class="text-right"></td>').text(structKids));
					tr.append($('<td class="text-right"></td>').text(leafKids));
					tr.append($('<td></td>').text(descText));
					tr.append(actionCell);
					tbody.append(tr);
				});

				var table = $('<table class="table table-sm table-striped table-responsive-md"></table>');
				table.append('<thead><tr><th>Type</th><th>Name / Barcode</th><th>Shape</th><th>Structural</th><th>Objects</th><th>Description</th><th>Actions</th></tr></thead>');
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
