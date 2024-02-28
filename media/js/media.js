/** Scripts specific to media pages. **/

/** Make a text media_label aspect control into an autocomplete 
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 */
function makeAspectAutocomplete(valueControl) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/media/component/search.cfc",
				data: { term: request.term, method: 'getAspectAutocomplete' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, status, error) {
					var message = "";
					if (error == 'timeout') { 
						message = ' Server took too long to respond.';
					} else { 
						message = jqXHR.responseText;
					}
					messageDialog('Error:' + message ,'Error: ' + error);
				}
			})
		},
		select: function (event, result) {
			//  on select, set prefix the value with an equals for exact match
			event.preventDefault();
			$('#'+valueControl).val("=" + result.item.value);
		},
      minLength: 3
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta "collection name * (description)" instead of value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};
/** Make an arbitrary media_label control into an autocomplete 
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param media_label the media_label to look up values for
 */
function makeMediaLabelAutocomplete(valueControl,media_label) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/media/component/search.cfc",
				data: { 
					term: request.term, 
					media_label: media_label, 
					method: 'getMediaLabelAutocomplete' 
				},
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, status, error) {
					var message = "";
					if (error == 'timeout') { 
						message = ' Server took too long to respond.';
					} else { 
						message = jqXHR.responseText;
					}
					messageDialog('Error:' + message ,'Error: ' + error);
				}
			})
		},
		select: function (event, result) {
			//  on select, set prefix the value with an equals for exact match
			event.preventDefault();
			$('#'+valueControl).val("=" + result.item.value);
		},
      minLength: 3
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta "collection name * (description)" instead of value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};
/** Make a pair of media_label_type and media_label_values control into an autocomplete 
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param typeControl the id for a select who's selected value is the media_label to lookup values for (without a leading # selector).
 */
function makeAnyMediaLabelAutocomplete(valueControl,typeControl) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			var media_label_val = $('#'+typeControl).val();
			$.ajax({
				url: "/media/component/search.cfc",
				data: { 
					term: request.term, 
					media_label: media_label_val, 
					method: 'getMediaLabelAutocomplete' 
				},
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, status, error) {
					var message = "";
					if (error == 'timeout') { 
						message = ' Server took too long to respond.';
					} else { 
						message = jqXHR.responseText;
					}
					messageDialog('Error:' + message ,'Error: ' + error);
				}
			})
		},
		select: function (event, result) {
			//  on select, set prefix the value with an equals for exact match
			event.preventDefault();
			$('#'+valueControl).val("=" + result.item.value);
		},
      minLength: 3
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta "collection name * (description)" instead of value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};
/** Make an arbitrary media uri component (hostname, path, filename) into an autocomplete 
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param targetField the part of the media_uri (hostname, path, filename) to look up distinct values for
 */
function makeMediaURIPartAutocomplete(valueControl,targetField) {
	var targetMethod = "";
	if (targetField=="hostname") { 
		targetMethod = "getHostnameAutocomplete";
	} else if (targetField=="path") {
		targetMethod = "getPathAutocomplete";
	} else if (targetField=="filename") {
		targetMethod = "getFilenameAutocomplete";
   } else {
		mesageDialog('Error: unrecognized target field','Error: unrecognized target field');
	}
	if (targetMethod != "") {  
		$('#'+valueControl).autocomplete({
			source: function (request, response) { 
				$.ajax({
					url: "/media/component/search.cfc",
					data: { 
						term: request.term, 
						method: targetMethod
					},
					dataType: 'json',
					success : function (data) { response(data); },
					error : function (jqXHR, status, error) {
						var message = "";
						if (error == 'timeout') { 
							message = ' Server took too long to respond.';
						} else { 
							message = jqXHR.responseText;
						}
						messageDialog('Error:' + message ,'Error: ' + error);
					}
				})
			},
			select: function (event, result) {
				//  on select, set prefix the value with an equals for exact match
				// removed the "=" + to the left of result.item.value
				event.preventDefault();
				//	$('#'+valueControl).val("=" + result.item.value);
				$('#'+valueControl).val(result.item.value);
			},
			minLength: 3
		}).autocomplete("instance")._renderItem = function(ul,item) { 
			// override to display meta "collection name * (description)" instead of value in picklist.
			return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
		};
	}
};
function makeAnyMediaRelationAutocomplete(valueControl,typeControl,idControl) { 
	var targetObject = $('#'+typeControl).val().trim().split(" ").pop();
	console.log(targetObject);
	switch (targetObject) {
		case "":
			// blank option selected, remove an autocomplete, but not the values.
			try { 
				$('#'+valueControl).autocomplete("destroy");
			} catch (err) {
				console.log(err);
			}
			break;
		case "agent":
			makeConstrainedAgentPicker(valueControl, idControl, 'media_agent'); 
			break;
		case "cataloged_item":
			makeCatalogedItemAutocompleteMeta(valueControl, idControl);
			break;
		case "collecting_event":
			makeCollectingEventAutocompleteMeta(valueControl, idControl);
			break;
		case "locality":
			makeLocalityAutocompleteMeta(valueControl, idControl);
			break;
		case "underscore_collection":
			makeNamedCollectionPicker(valueControl,idControl);
			break;
		case "publication":
			makePublicationAutocompleteMeta(valueControl, idControl);
			break;
		case "project":
			makeProjectAutocompleteMeta(valueControl, idControl);
			break;
		case "permit":
			if (typeof makePermitPicker === "function") { 
				makePermitPicker(valueControl, idControl);
			}
			break;
		case "loan":
			if (typeof makeLoanPicker === "function") { 
				makeLoanPicker(valueControl, idControl);
			}
			break;
		case "accn":
			if (typeof makeAccessionAutocompleteMeta === "function") { 
				makeAccessionAutocompleteMeta(valueControl, idControl);
			}
			break;
		case "deaccession":
			if (typeof makeDeaccessionAutocompleteMeta === "function") { 
				makeDeaccessionAutocompleteMeta(valueControl, idControl);
			}
			break;
		case "borrow":
			if (typeof makeBorrowAutocompleteMeta === "function") { 
				makeBorrowAutocompleteMeta(valueControl, idControl);
			}
			break;
		default:
			messageDialog("Unknown or not implemented media relationship target, only NULL and NOT NULL values are supported","Error: Unknown");		
	}

}
/** A table with metadata for the media_id
 *  @param media_id for the media.
 *  @param targetDiv id="mediaMetadataBlock#media_id#" for #mediaMetadataBlock#
 */
function getMediaMetadata(targetDiv, media_id) { 
	console.log("Where is it? " + targetDiv);
	jQuery.ajax({
		url: "/media/component/public.cfc",
		data : {
			method : "getMediaMetadata",
			media_id : media_id,
	
		},
		success: function (result) {
			$("#" + targetDiv).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"retrieving metadata block");
		},
		dataType: "html"
	});
};


function getNewMediaMetadata(targetDiv, media_id) { 
	console.log("Where is it? " + targetDiv);
	jQuery.ajax({
		url: "/media/component/function.cfc",
		data : {
			method : "createMedia",
			media_id : media_id,
	
		},
		success: function (result) {
			$("#" + targetDiv).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"retrieving metadata block");
		},
		dataType: "html"
	});
};
/** load images into top position on MediaViewer.cfm from the zoom/related link on related thumbnails (media_widget on search.cfc)
 *  @param media_id for the media.
 *  not working now / not implemented because it wasn't working; problem with calling functon from function probably;
 */
function loadRelatedImages(targetDiv, media_id) { 
	console.log("loadRelatedImages() called for " + targetDiv);
	jQuery.ajax({
		url: "/media/component/public.cfc",
		data : {
			method : "getMediaBlockHtml",
			media_id : media_id,
	
		},
		success: function (result) {
			$("#" + targetDiv).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"retrieving relationship block");
		},
		dataType: "html"
	});
};
/** Functions below are for the edit media page Media.cfm
 *  @param media_id for the media.
 *  not working now - 
 */


/** removeMediaRelation given a media_relations_id delete the referenced row from media_relations, on success
 * invoke reloadMediaRelationships() to reload the media relationships section for the relevant page.
 * @param media_relations_id the primary key of the media relationship record to delete.
 */
function removeMediaRelation(media_relations_id) {
	jQuery.getJSON("/media/component/functions.cfc",
		{
			method : "removeMediaRelation",
			media_relations_id : media_relations_id,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			if (result.DATA.STATUS == "1") { 
				reloadMediaRelationships();
			} else {
				messageDialog("Error removing relationship from media relations: " + result.DATA.MESSAGE, "Error removing relationship");
			}
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"removing relationship from media record");
	});
};

/** function loadRelationsTable request the html to populate a div with an editable table of relationships for a 
 * transaction.
 *
 * Assumes the presence of a change() function defined within scole containg the agent table.
 *
 * @param relationsDiv the id for the div to load the media_relations table into, without a leading # id selector.
 * @param media_id the media_id of the media record for which to load agents.
 * @param containingFormId the id for the form containing the media relationship table, without a leading # id selector.
 * @param changeHandler callback function to pass to monitorForChanges to be called when input values change.
 */
function loadRelationsTable(relationsDiv,media_id,containingFormId,changeHandler){ 
	$('#' + relationsDiv).html(" <div class='my-2 text-center'><img src='/shared/images/indicator.gif'> Loading...</div>");
	jQuery.ajax({
		url : "/media/component/search.cfc",
		type : "get",
		data : {
			method: 'relationsTableHtml',
			media_id: media_id,
			containing_form_id: containingFormId
		},
		success : function (data) {
			$('#' + relationsDiv).html(data);
			monitorForChanges(containingFormId,changeHandler);
		},
		error: function(jqXHR,textStatus,error){
			$('#' + relationsDiv).html('Error loading relationships.');
			var message = "";
			if (error == 'timeout') {
				message = ' Server took too long to respond.';
			} else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
				message = ' Backing method did not return JSON.';
			} else {
				message = jqXHR.responseText;
			}
			if (!error) { error = ""; } 
			messageDialog('Error retrieving relationships for media record: '+message, 'Error: '+error.substring(0,50));
		}
	});
}




function loadMediaRelations(targetDiv, media_id) { 
	console.log("loadMediaRelations() called for " + targetDiv);
	jQuery.ajax({
		url: "/media/component/search.cfc",
		data : {
			method : "getMediaRelationsHtml",
			media_id : media_id,
			media_relationship:media_relationship,
			related_primary_key:related_primary_key,
			media_relations_id:media_relations_id
		},
		success: function (result) {
			$("#" + targetDiv).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"retrieving relationship block");
		},
		dataType: "html"
	});
};




function addMediaRelationshipToForm (media_id,media_relationship,key,formid) {
	if (typeof id == "undefined") {
		id = "";
	 }
	if (typeof media_relationship == "undefined") {
		name = "";
	 }
	if (typeof key == "undefined") {
		role = "";
	 }
	jQuery.getJSON("/media/component/search.cfc",
		{
			method : "getMediaRelationsHtml",
			media_id :media_id,
			media_relationship:media_relationship,
			returnformat : "json",
			queryformat : 'column'
		},
		function (data) {
			var i=parseInt($('#numRelations').val())+1;
			var d= '';
			d+='<div class="row px-0 alert alert-warning my-0 py-1 border-top border-bottom" id="new_media_relations_div_'+i+'">';
			d+='<div class="col-12 col-md-4">';
			d+=' <select name="media_relationship_' + i + '" id="media_relationship_' + i + '" class="data-entry-select data-height">';
			for (a=0; a<data.ROWCOUNT; ++a) {
				d+='<option ';
				if(role==data.DATA.related_primary_key[a]){
					d+=' selected="selected"';
				}
				d+=' value="' + data.DATA.media_relationship[a] + '">'+ data.DATA.media_relationship[a] +'</option>';
			}
			d+=' </select>';
			d+='</div>';
			d+='<div class="col-12 col-md-3">';
			d+=' <button type="button" ';
			d+='   class="btn btn-xs btn-warning float-left"';
			d+='   onClick=\' confirmDialog("Remove not-yet saved new relationship from this media record?", "Confirm Unlink Relation", function() { $("#new_media_relations_div_'+i+'").remove(); } ); \'>Remove</button>';
			d+='</div>';
			d+='</div>';
			$('#numRelations').val(i);
			jQuery('#mediaRelationsTable').append(d);
		}
	).fail(function(jqXHR,textStatus,error){
		var message = "";
		if (error == 'timeout') {
			message = ' Server took too long to respond.';
		} else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
			message = ' Backing method did not return JSON.';
		} else {
			message = jqXHR.responseText;
		}
		if (!error) { error = ""; } 
		messageDialog('Error adding relationships to transaction record: '+message, 'Error: '+error.substring(0,50));
	});
}							
function saveMediaRelationship(targetDiv, media_id,media_relationship) { 
	console.log("loadRelation() called for " + targetDiv);
	jQuery.ajax({
		url: "/media/component/search.cfc",
		data : {
			method : "updateMediaRelationship",
			media_id : media_id,
			media_relationship:media_relationship
		},
		success: function (result) {
			$("#" + targetDiv).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"retrieving relationship block");
		},
		dataType: "html"
	});
};
function createMedia(targetDiv, media_id, media_relations_id) { 
	console.log("loadRelation() called for " + targetDiv);
	jQuery.ajax({
		url: "/media/component/functions.cfc",
		data : {
			method : "createMedia",
			media_id : media_id,
			media_relations_id: media_relations_id
		},
		success: function (result) {
			$("#" + targetDiv).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"retrieving relationship block");
		},
		dataType: "html"
	});
};

