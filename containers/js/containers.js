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
			var totalRows = data.totalRows || 0;
			var pageSize = data.pageSize || 50;
			var currentPage = data.page || 1;
			var totalPages = Math.ceil(totalRows / pageSize);

			var panel = $('<div class="container-leaf-panel"></div>');
			var heading = containerLabel
				? 'Contents of ' + containerLabel + ' (' + totalRows + ' collection objects)'
				: 'Contents (' + totalRows + ' collection objects)';
			panel.append($('<h3 class="h5"></h3>').text(heading));

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
