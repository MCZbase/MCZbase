/** Scripts specific to geological attribute management. **/

/** Add a new geological attribute value 
 *  @param attribute the attribute for which to add a value
 *  @param attribute_value the value to add
 *  @param usable_value_fg is this value accepted for data entry
 *  @param description a description of the attribute value
 *  @param feedback the id of an element in the DOM into which to place feedback without a leading # selector.
 *  @param callback a callback function to invoke on successfull insert
 */
function addGeologicalAttribute(attribute, attribute_value, usable_value_fg, description, feedback, callback) { 
	$('#'+feedback).html('Saving....');
	$('#'+feedback).addClass('text-warning');
	$('#'+feedback).removeClass('text-success');
	$('#'+feedback).removeClass('text-danger');
	$.ajax({
		url: "/vocabularies/component/functions.cfc",
		data: { 
			attribute: attribute, 
			attribute_value: attribute_value, 
			usable_value_fg: usable_value_fg, 
			description: description, 
			returnformat : "json",
			queryformat : "struct",
			method: 'addGeologicalAttribute' 
		},
		dataType: 'json',
		success : function (result) { 
			$('#'+feedback).html(result[0].MESSAGE);
			$('#'+feedback).addClass('text-success');
			$('#'+feedback).removeClass('text-danger');
			$('#'+feedback).removeClass('text-warning');
			if (jQuery.type(callback)==='function') {
				callback();
			}
			if (result[0].STATUS!=1) {
				alert(result[0].MESSAGE);
				$('#'+feedback).addClass('text-danger');
				$('#'+feedback).removeClass('text-success');
				$('#'+feedback).removeClass('text-danger');
			}
		},
		error: function (jqXHR, textStatus, error) {
			$('#'+feedback).addClass('text-danger');
			$('#'+feedback).removeClass('text-success');
			$('#'+feedback).removeClass('text-danger');
			handleFail(jqXHR,textStatus,error, "Error adding geological attribute: "); 
		}
	});
};

/** Merge one geological attribute value into another, updating existing geological attributes as well
 * as the geological attribute hierarchy.
 *  @param nodeToMerge the geological_attribute_hierarchy_id for the node to be merged.
 *  @param mergeTarge the geological_attribute_hierarchy_id for the node into which nodeToMerge is to be merged.
 *  @param feedback the id of an element in the DOM into which to place feedback without a leading # selector.
 *  @param callback a callback function to invoke on successfull insert
 */
function mergeGeologicalAttributes(nodeToMerge, mergeTarget, feedback, callback) { 
	$('#'+feedback).html('Saving....');
	$('#'+feedback).addClass('text-warning');
	$('#'+feedback).removeClass('text-success');
	$('#'+feedback).removeClass('text-danger');
	$.ajax({
		url: "/vocabularies/component/functions.cfc",
		data: { 
			nodeToMerge: nodeToMerge,
			mergeTarget: mergeTarget, 
			returnformat : "json",
			queryformat : "struct",
			method: 'mergeGeologicalAttributes' 
		},
		dataType: 'json',
		success : function (result) { 
			$('#'+feedback).html(result[0].MESSAGE);
			$('#'+feedback).addClass('text-success');
			$('#'+feedback).removeClass('text-danger');
			$('#'+feedback).removeClass('text-warning');
			if (jQuery.type(callback)==='function') {
				callback();
			}
			if (result[0].STATUS!=1) {
				alert(result[0].MESSAGE);
				$('#'+feedback).addClass('text-danger');
				$('#'+feedback).removeClass('text-success');
				$('#'+feedback).removeClass('text-danger');
			}
		},
		error: function (jqXHR, textStatus, error) {
			$('#'+feedback).addClass('text-danger');
			$('#'+feedback).removeClass('text-success');
			$('#'+feedback).removeClass('text-danger');
			handleFail(jqXHR,textStatus,error, "Error merging geological attribute: "); 
		}
	});
};


/** functionChangeGeologicalAttributeLink change the parentage for a specified child node
 * in the geological attribute tree.
 * @param parent the id of the parent node in geology_attribute_hierarchy, if value is 'NULL', removes the 
 *   link from the child to the parent.
 * @param child the id of the child node in the geology_attribute_hierarchy
 * @param feedback the id of an element in the DOM into which to place feedback without a leading # selector.
 * @param callback a callback function to invoke on successfull insert
 */
function changeGeologicalAttributeLink(parent, child, feedback, callback) { 
	$('#'+feedback).html('Saving....');
	$('#'+feedback).addClass('text-warning');
	$('#'+feedback).removeClass('text-success');
	$('#'+feedback).removeClass('text-danger');
	if (parent=='NULL') { 
		$.ajax({
			url: "/vocabularies/component/functions.cfc",
			data: { 
				child: child, 
				returnformat : "json",
				queryformat : "struct",
				method: 'unlinkChildGeologicalAttribute' 
			},
			dataType: 'json',
			success : function (result) { 
				$('#'+feedback).html(result[0].MESSAGE);
				$('#'+feedback).addClass('text-success');
				$('#'+feedback).removeClass('text-danger');
				$('#'+feedback).removeClass('text-warning');
				if (jQuery.type(callback)==='function') {
					callback();
				}
				if (result[0].STATUS!=1) {
					alert(result[0].MESSAGE);
					$('#'+feedback).addClass('text-danger');
					$('#'+feedback).removeClass('text-success');
					$('#'+feedback).removeClass('text-danger');
				}
			},
			error: function (jqXHR, textStatus, error) {
				$('#'+feedback).addClass('text-danger');
				$('#'+feedback).removeClass('text-success');
				$('#'+feedback).removeClass('text-danger');
				handleFail(jqXHR,textStatus,error, "Error linking geological attributes: "); 
			}
		});
   } else { 
		$.ajax({
			url: "/vocabularies/component/functions.cfc",
			data: { 
				parent: parent, 
				child: child, 
				returnformat : "json",
				queryformat : "struct",
				method: 'linkGeologicalAttributes' 
			},
			dataType: 'json',
			success : function (result) { 
				$('#'+feedback).html(result[0].MESSAGE);
				$('#'+feedback).addClass('text-success');
				$('#'+feedback).removeClass('text-danger');
				$('#'+feedback).removeClass('text-warning');
				if (jQuery.type(callback)==='function') {
					callback();
				}
				if (result[0].STATUS!=1) {
					alert(result[0].MESSAGE);
					$('#'+feedback).addClass('text-danger');
					$('#'+feedback).removeClass('text-success');
					$('#'+feedback).removeClass('text-danger');
				}
			},
			error: function (jqXHR, textStatus, error) {
				$('#'+feedback).addClass('text-danger');
				$('#'+feedback).removeClass('text-success');
				$('#'+feedback).removeClass('text-danger');
				handleFail(jqXHR,textStatus,error, "Error linking geological attributes: "); 
			}
		});
	}
};

function refreshGeologyTreeForNode(geology_attribute_hierarchy_id,targetDiv) { 
	$.ajax({
		url: "/vocabularies/component/functions.cfc",
		data: { 
			geology_attribute_hierarchy_id: geology_attribute_hierarchy_id,
			method: 'getNodeInGeologyTreeHtml'
		},
		dataType: 'html',
		success : function (result) { 
			$('#'+targetDiv).html(result)
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error, "Error looking up tree for geological attribute: "); 
		}
	});
};
