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
 * Initializes the container browse panel and loads the top-level structural
 * children (container_id=1) on page load.
 * @param {string} browsePanel - the id of the div to render the tree into (without leading #).
 * @param {string} leafPanel - the id of the div for the leaf browser panel (without leading #).
 * @param {string} feedbackEl - the id of the output element for status feedback (without leading #).
 */
function initContainerBrowse(browsePanel, leafPanel, feedbackEl) {
	$(document).ready(function() {
		loadContainerNode(1, browsePanel, feedbackEl);
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
 * Each node is rendered as a treeitem with a toggle button for lazy-loading
 * children and, if the node has leaf children, a "Browse contents" button.
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
		var ctype = node.container_type || '';
		var cid = node.container_id;
		var childUlId = 'ctree-children-' + cid;
		var toggleId = 'ctree-toggle-' + cid;

		var toggle = $('<button></button>')
			.attr('id', toggleId)
			.attr('aria-expanded', 'false')
			.attr('aria-controls', childUlId)
			.addClass('tree-node-toggle btn-link')
			.text(label + ' (' + ctype + ')');

		var childUl = $('<ul></ul>')
			.attr('id', childUlId)
			.addClass('collapse container-tree');

		toggle.on('click', function() {
			var expanded = $(this).attr('aria-expanded') === 'true';
			if (!expanded && $('#' + childUlId).children().length === 0) {
				loadContainerNode(cid, childUlId, feedbackId);
			}
			$('#' + childUlId).toggleClass('collapse');
			$(this).attr('aria-expanded', expanded ? 'false' : 'true');
		});

		var li = $('<li role="treeitem"></li>').append(toggle).append(childUl);

		var browseBtn = $('<button></button>')
			.addClass('btn btn-xs btn-outline-secondary ml-1')
			.text('Browse contents')
			.on('click', function() {
				loadLeafPanel(cid, 'containerLeafPanel', feedbackId, 1);
			});
		li.append(browseBtn);

		ul.append(li);
	});
	$('#' + targetDivId).html(ul);
}

/**
 * Loads the first page of direct collection-object children for containerId
 * from functions.cfc?method=getDirectLeafChildren and renders them as a table
 * in leafPanelId.  Shows the leaf panel; hides it on error.
 * Includes Previous/Next page navigation when totalRows > pageSize.
 * @param {number} containerId - the container_id whose leaf children to browse.
 * @param {string} leafPanelId - the id of the div for the leaf panel (without leading #).
 * @param {string} feedbackId - the id of the output element for status feedback (without leading #).
 * @param {number} [page=1] - the page number to load (1-based).
 */
function loadLeafPanel(containerId, leafPanelId, feedbackId, page) {
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

			var html = '<div class="container-leaf-panel">';
			html += '<h3 class="h5">Contents (' + totalRows + ' collection objects)</h3>';

			if (rows.length === 0) {
				html += '<p class="text-muted">No collection objects found.</p>';
			} else {
				html += '<table class="table table-sm table-striped"><thead><tr>';
				html += '<th>Container ID</th><th>Label</th><th>Barcode</th><th>Description</th>';
				html += '</tr></thead><tbody>';
				$.each(rows, function(i, row) {
					html += '<tr>';
					html += '<td>' + $('<span>').text(row.container_id).html() + '</td>';
					html += '<td>' + $('<span>').text(row.label).html() + '</td>';
					html += '<td>' + $('<span>').text(row.barcode).html() + '</td>';
					html += '<td>' + $('<span>').text(row.description).html() + '</td>';
					html += '</tr>';
				});
				html += '</tbody></table>';
			}

			if (totalRows > pageSize) {
				html += '<div class="mt-2">';
				if (currentPage > 1) {
					html += '<button class="btn btn-xs btn-secondary mr-1" onclick="loadLeafPanel(' + containerId + ',\'' + leafPanelId + '\',\'' + feedbackId + '\',' + (currentPage - 1) + ')">Previous</button>';
				}
				if (currentPage * pageSize < totalRows) {
					html += '<button class="btn btn-xs btn-secondary" onclick="loadLeafPanel(' + containerId + ',\'' + leafPanelId + '\',\'' + feedbackId + '\',' + (currentPage + 1) + ')">Next</button>';
				}
				html += '</div>';
			}

			html += '</div>';
			$('#' + leafPanelId).html(html);
		},
		error: function(jqXHR, textStatus, error) {
			$('#' + leafPanelId).addClass('d-none');
			handleFail(jqXHR, textStatus, error, 'loading leaf container contents');
		}
	});
}
