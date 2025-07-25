/** edit.js functions for editing specimen records **/

/** 
Copyright 2019-2025 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
**/

/** createSpecimenEditDialog create a dialog for editing portions of specimen records.
 creates a dialog with the given id and title, and a div with the same id with _div appended,
 intended use is to load content into the {dialog_id}_div with ajax after the dialog is created.
 
	@param dialogId the id in the dom for the div to turn into the dialog without leading # selector.
	@param title the title for the dialog
	@param closecallback a callback function to invoke on closing the dialog.
	@param max_height the maximum height for the dialog, optional, default 775
	@param width_cap the maximum width for the dialog when screen is larger 
    than extra large (1333), optional, default 999
*/
function createSpecimenEditDialog(dialogId,title,closecallback,max_height=775,width_cap=999) {
	var content = '<div id="'+dialogId+'_div">Loading...</div>';
	var x=1;
	var h = $(window).height();
	if (h>max_height) { h=max_height; } // cap height default at 775
	var w = $(window).width();
	// full width at less than medium screens
	if (w>414 && w<=1333) { 
		// 90% width up to extra large screens
		w = Math.floor(w *.9);
	} else if (w>1333) { 
		// cap width at specified value, but no more that 95% of the screen width
		if (width_cap < w * .95) {
			w = width_cap;
		}
	}
	console.log("Creating dialog in div with id: " + dialogId);
	var thedialog = $("#"+dialogId).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		height: h,
		width: w,
		minWidth: 320,
		minHeight: 450,
		draggable:true,
		buttons: {
			"Close Dialog": function() {
				console.log("Button calling close on dialog in div with id: " + dialogId);
				$("#"+dialogId).dialog('close');
			}
		},
		open: function (event, ui) {
			// force the dialog to lay above any other elements in the page.
			var maxZindex = getMaxZIndex();
			$('.ui-dialog').css({'z-index': maxZindex + 6 });
			$('.ui-widget-overlay').css({'z-index': maxZindex + 5 });
			// position consistently with top at top of browser window:
			$(this).dialog("option", "position",{ my: "top", at: "top", of: window, collision: "fit" });
		},
		close: function(event,ui) {
			console.log("Close called on dialog in div with id: " + dialogId);
			if (jQuery.type(closecallback)==='function')	{
				closecallback();
			}
			$("#"+dialogId+"_div").html("");
			try {
				if ($("#"+dialogId).hasClass("ui-dialog-content")) {
					$("#"+dialogId).dialog('destroy');
				}
			} catch (e) {
				console.error("Error destroying dialog: " + e);
			}
		}
	});
	thedialog.dialog('open');
}

/** createCitationEditDialog create a dialog for editing citations on a specimen record.
	@param dialogId the id in the dom for the div to turn into the dialog without leading # selector.
	@param title the title for the dialog
	@param closecallback a callback function to invoke on closing the dialog.
	@param max_height the maximum height for the dialog, optional, default 775
	@see createSpecimenEditDialog
*/
function createCitationEditDialog(dialogId,title,closecallback,max_height=775) {
	var content = '<div id="'+dialogId+'_div">Loading...</div>';
	var x=1;
	var h = $(window).height();
	if (h>max_height) { h=max_height; } // cap height, default at 775
	var w = $(window).width();
	// full width at less than medium screens
	if (w>414 && w<=1333) { 
		// 90% width up to extra large screens
		w = Math.floor(w *.9);
	} else if (w>1333) { 
		// cap width at 1200 pixel
		w = 999;
	} 
	var thedialog = $("#"+dialogId).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		height: h,
		width: w,
		minWidth: 320,
		minHeight: 450,
		draggable:true,
		buttons: {
			"Close Dialog": function() {
				$("#"+dialogId).dialog('close');
			}
		},
		open: function (event, ui) {
			// force the dialog to lay above any other elements in the page.
			var maxZindex = getMaxZIndex();
			$('.ui-dialog').css({'z-index': maxZindex + 6 });
			$('.ui-widget-overlay').css({'z-index': maxZindex + 5 });
			
		},
		close: function(event,ui) {
			if (jQuery.type(closecallback)==='function')	{
				closecallback();
			}
			$("#"+dialogId+"_div").html("");
			$("#"+dialogId).dialog('destroy');
		}
	});
	thedialog.dialog('open');
}

/** updateIdentifications update identifications for a collection object in bulk.
 *
 * @param collection_object_id the id of the collection_object for which to update identifications.
 * @param identificationUpdates array of updates to apply to identifications/
 * @param targetDiv the id of the div in which to display the updated
 *   identifications count without a leading # selector.
 * @param callback a callback function to invoke on success.
 *
 **/
function updateIdentifications(collection_object_id, identificationUpdates,targetDiv,callback) {
   alert("updateIdentifications incomplete implementation");
	// TODO: implement pass update data
	jQuery.ajax({
		dataType: "json",
		url: "/specimens/component/functions.cfc",
		data: { 
			method : "updateIdentifications",
			collection_object_id : collection_object_id,
			identificationUpdates : identificationUpdates,
			returnformat : "json",
			queryformat : 'column'
		},
		error: function (jqXHR, status, message) {
			handleFail(jqXHR,status,message,"updating identifications");
		},
		success: function (result) {
			if (callback instanceof Function) {
				callback();
			}
		}
	});
};

/** openEditIdentificationsDialog (plural) open a dialog for editing 
 * identifications for a cataloged item.
 *
 * @param collection_object_id for the cataloged_item for which to edit identifications.
 * @param dialogId the id in the dom for the div to turn into the dialog without 
 *  a leading # selector.
 * @param guid the guid of the specimen to display in the dialog title
 * @param callback a callback function to invoke on closing the dialog.
 */
function openEditIdentificationsDialog(collection_object_id,dialogId,guid,callback) {
	var title = "Edit Identifications for " + guid;
	createSpecimenEditDialog(dialogId,title,callback);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditIdentificationsHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + dialogId + "_div").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"opening edit identifications dialog");
		},
		dataType: "html"
	});
}

/** loadIdentificationsList reload the identifications list for a collection object 
 * @param collection_object_id the id of the collection_object for which to load identifications.
 * @param targetDivId the id of the div in which to load the identifications list without a leading # selector.
 * @param editable boolean indicating whether the identifications should be editable, 
 *		if true, the identifications will be displayed with edit/remove buttons.
 */
function loadIdentificationsList(collection_object_id,targetDivId,editable) { 
	jQuery.ajax({
		url : "/specimens/component/functions.cfc",
		type : "post",
		dataType : "html",
		data: {
			method: "getIdentificationsUnthreadedHTML",
			editable: editable,
			collection_object_id: collection_object_id
		},
		success: function (result) {
			console.log("Reloading identifications dialog content");
			$("#" + targetDivId).html(result);
		},
		error: function(jqXHR,textStatus,error){
			handleFail(jqXHR,textStatus,error,"reloading ideqntifications");
		}
	});
};

/** openEditNamedGroupsDialog open a dialog for editing 
 * named group membership for a cataloged item.
 *
 * @param collection_object_id for the cataloged_item for which to edit named groups.
 * @param dialogId the id in the dom for the div to turn into the dialog without 
 *  a leading # selector.
 * @param guid the guid of the specimen to display in the dialog title
 * @param callback a callback function to invoke on closing the dialog.
 */
function openEditNamedGroupsDialog(collection_object_id,dialogId,guid,callback) {
	var title = "Edit Named Groups for " + guid;
	createSpecimenEditDialog(dialogId,title,callback,450);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditNamedGroupsHTML",
			collection_object_id: collection_object_id
		},
		success: function (result) {
			$("#" + dialogId + "_div").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"opening named groups dialog");
		},
		dataType: "html"
	});
}
/** addToNamedGroup add a cataloged_item to a named group.
 *
 * @param underscore_collection_id the named group to which to add the cataloged_item
 * @param collection_object_id the cataloged_item to add to the named group
 * @param callback a callback function to invoke on success.
 **/
function addToNamedGroup(underscore_collection_id,collection_object_id,callback) {
	jQuery.ajax({	
		url: "/specimens/component/functions.cfc",
		data : {
			method : "addToNamedGroup",
			underscore_collection_id: underscore_collection_id,
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			if (result[0].status=="added") {
				var message  = "Added to named group";
				if (callback instanceof Function) {
					callback();
				}
			}
			else {
				messageDialog("Error adding to named group: " + result.DATA.MESSAGE[0],'Error');
			}
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"adding to named group");
		},
		dataType: "json"
	});
}

/** removeFromNamedGroup remove a cataloged_item from a named group.
 *
 * @param underscore_collection_id the named group from which to remove the cataloged_item
 * @param collection_object_id the cataloged_item to remove from the named group
 * @param callback a callback function to invoke on success.
 **/
function removeFromNamedGroup(underscore_collection_id, collection_object_id,callback) {
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "removeFromNamedGroup",
			underscore_collection_id: underscore_collection_id,
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			if (result[0].status=="removed") {
				if (callback instanceof Function) {
					callback();
				}
				var message  = "Removed from named group";
				console.log(message);
			}
			else {
				messageDialog("Error removing from named group: " + result.DATA.MESSAGE[0],'Error');
			}
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"removing from named group");
		},
		dataType: "json"
	});
}

/** loadNamedGroupsList load the named groups list (with details) for a cataloged_item 
  into a specified div.
	@param collection_object_id the cataloged_item for which to load the named groups list
	@param targetDivId the id of the div in which to load the named groups list.
*/
function loadNamedGroupsList(collection_object_id,targetDivId) {
	jQuery.ajax(
	{
		url: "/specimens/component/functions.cfc",
		data: { 
			method : "getNamedGroupsDetailHTML",
			collection_object_id : collection_object_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"load named groups detail list");
		},
		dataType: "html"
	})
};

/** openEditCollectorsDialog (plural) open a dialog for editing
 * collectors for a cataloged item.
 *
 * @param collection_object_id for the cataloged_item for which to edit collectors.
 * @param dialogId the id in the dom for the div to turn into the dialog without 
 *  a leading # selector.
 * @param guid the guid of the specimen to display in the dialog title
 * @param callback a callback function to invoke on closing the dialog.
 */
function openEditCollectorsDialog(collection_object_id,dialogId,guid,callback) {
	var title = "Edit Collectors for " + guid;
	createSpecimenEditDialog(dialogId,title,callback);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditCollectorsHTML",
			target : "collector",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + dialogId + "_div").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"opening edit Collectors dialog");
		},
		dataType: "html"
	});
};

function openEditPreparatorsDialog(collection_object_id,dialogId,guid,callback) {
	var title = "Edit Preparators for " + guid;
	createSpecimenEditDialog(dialogId,title,callback);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditCollectorsHTML",
			target : "preparator",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + dialogId + "_div").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"opening edit Preparators dialog");
		},
		dataType: "html"
	});
};

/**openEditMediaDialog (plural) open a dialog for editing 
 * media objects for a cataloged item.
 * @param collection_object_id for the cataloged_item for which to edit media.
 * @param dialogId the id in the dom for the div to turn into the dialog without 
 *  a leading # selector.
 * @param guid the guid of the specimen to display in the dialog title
 * @param callback a callback function to invoke on closing the dialog.
 **/
function openEditMediaDialog(collection_object_id,dialogId,guid,callback) {
	var title = "Edit Media for " + guid;
	createSpecimenEditDialog(dialogId,title,callback);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditMediaHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + dialogId + "_div").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"opening edit Media dialog");
		},
		dataType: "html"
	},
	)
};

/** linkMedia function to add a link between a collection_object and a media object.
 * @param collection_object_id the id of the collection_object to which to link the media
 * @param media_id the id of the media object to link to the collection_object
 * @param relationship_type the relationship type to use for the link
 * @param callback a callback function to invoke on success.
*/
function linkMedia(collection_object_id, media_id, relationship_type, callback) { 
   jQuery.ajax({
		dataType: "json",
		url: "/specimens/component/functions.cfc",
		data: { 
			method : "addMediaToCatItem",
			collection_object_id : collection_object_id,
			media_id : media_id,
			relationship_type : relationship_type,
			returnformat : "json",
			queryformat : 'column'
		},
		success: function (result) {
			if (result[0].status=="added") {
				var message  = "Added media to cataloged item";
				console.log(message);
				if (callback instanceof Function) {
					callback();
				}
			}
			else {
				messageDialog("Error adding media to cataloged item: " + result[0].MESSAGE,'Error');
			}
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"adding Media to cataloged item");
		}
	});
}

/** changeMediaRelationshipType function to change the relationship type for a link between a collection_object and a media object.
 * @param relationship_type the new relationship type to use for the link
 * @param media_id the id of the media object to link to the collection_object
 * @param collection_object_id the id of the collection_object to which to link the media
 * @param media_relations_id the id of the media relationship to update
 * @param callback a callback function to invoke on success.
*/
function handleChangeCIMediaRelationshipType(relationship_type,media_id,collection_object_id,media_relations_id,callback) {	
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "changeMediaRelationshipType",
			media_id: media_id,
			collection_object_id: collection_object_id,
			relationship_type: relationship_type,
			media_relations_id: media_relations_id
		},
		success: function (result) {
			if (result[0].status=="changed") {
				var message  = "Updated media relationship type";
				console.log(message);
				if (callback instanceof Function) {
					callback();
				}
			}
			else {
				messageDialog("Error updating media relationship type: " + result[0].message,'Error');
			}
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"updating media relationship type");
		},
		dataType: "json"
	});
}

/** removeMediaRelationship function to remove a link between a collection_object and a media object.
 * @param media_relations_id the id of the media relationship to remove
 * @param callback a callback function to invoke on success.
*/
function removeMediaRelationship(media_relations_id,callback) {
	jQuery.ajax({
		url: "/media/component/functions.cfc",
		data : {
			method : "removeMediaRelation",
			media_relations_id: media_relations_id,
			returnformat : "json",
			queryformat : 'column'
	 	},
		success: function (result) {
			if (result.DATA.STATUS == "1") { 
				var message  = "Removed media relationship";
				console.log(message);
				if (callback instanceof Function) {
					callback();
				}
			}
			else {
				messageDialog("Error removing media relationship: " + result.DATA.message,'Error');
			}
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"removing media relationship");
		},
		dataType: "json"
	});
}

/** openEditOtherIDsDialog (plural) open a dialog for editing 
 * other IDs for a cataloged item.
 *
 * @param collection_object_id for the cataloged_item for which to edit other IDs.
 * @param dialogId the id in the dom for the div to turn into the dialog without 
 *  a leading # selector.
 * @param guid the guid of the specimen to display in the dialog title
 * @param callback a callback function to invoke on closing the dialog.
 */
function openEditOtherIDsDialog(collection_object_id,dialogId,guid,callback) {
	var title = "Edit Other IDs for " + guid;
	createSpecimenEditDialog(dialogId,title,callback);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditOtherIDsHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + dialogId + "_div").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"opening edit Other IDs dialog");
		},
		dataType: "html"
	});
};

/** openEditCatalogDialog open a dialog for editing catalog number and accession
 *  for a cataloged item.
 *
 * @param collection_object_id for the cataloged_item to edit..
 * @param dialogId the id in the dom for the div to turn into the dialog without 
 *  a leading # selector.
 * @param guid the guid of the specimen to display in the dialog title
 * @param callback a callback function to invoke on closing the dialog.
 */
function openEditCatalogDialog(collection_object_id,dialogId,guid,callback) {
	var title = "Edit Catalog Information for " + guid;
	createSpecimenEditDialog(dialogId,title,callback);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditCatalogHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + dialogId + "_div").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"opening edit catalog dialog");
		},
		dataType: "html"
	});
};

/*** reloadOtherIDDialog reload the other ID dialog with a given collection_object_id.
 * @param collection_object_id the id of the collection_object for which to reload the other IDs.
 */
function reloadOtherIDDialog(collection_object_id) { 
	jQuery.ajax({
		url : "/specimens/component/functions.cfc",
		type : "post",
		dataType : "html",
		data: {
			method: "getEditOtherIDsHTML",
			collection_object_id: collection_object_id
		},
		success: function (result) {
			console.log("Reloading other IDs dialog content");
			$("#otherIDsDialog_div").html(result);
		},
		error: function(jqXHR,textStatus,error){
			handleFail(jqXHR,textStatus,error,"reloading Other IDs");
		}
	});
};

/** openEditRemarksDialog open a dialog for editing 
 * remarks for a collection object.
 *
 * @param collection_object_id for the collection object for which to edit remarks.
 * @param dialogId the id in the dom for the div to turn into the dialog without 
 *  a leading # selector.
 * @param guid the guid of the specimen to display in the dialog title
 * @param callback a callback function to invoke on closing the dialog.
 */
function openEditRemarksDialog(collection_object_id,dialogId,guid,callback) {
	var title = "Edit Remarks for " + guid;
	createSpecimenEditDialog(dialogId,title,callback,500);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditRemarksHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + dialogId + "_div").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"opening edit remarks dialog");
		},
		dataType: "html"
	},
	)
};

/** saveRemarks function to save remarks for a collection object.
 * @param collection_object_id the id of the collection object for which to save remarks
 * @param coll_object_remarks the remarks to save for the collection object
 * @param disposition_remarks the disposition remarks to save for the collection object
 * @param habitat the habitat remarks to save for the collection object
 * @param associated_species the associated species remarks to save for the collection object
 * @param callback a callback function to invoke on success.
 * @param feedbackDiv the id of the div in which to display feedback messages
 */
function saveRemarks(collection_object_id,coll_object_remarks,disposition_remarks,habitat,associated_species,callback,feedbackDiv) { 
	setFeedbackControlState(feedbackDiv,"saving")
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "saveRemarks",
			collection_object_id: collection_object_id,
			coll_object_remarks: coll_object_remarks,
			disposition_remarks: disposition_remarks,
			habitat: habitat,
			associated_species: associated_species
		},
		success: function (result) {
			setFeedbackControlState(feedbackDiv,"saved")
			if (result[0].status=="updated") {
				var message  = "Updated remarks";
				console.log(message);
				if (callback instanceof Function) {
					callback();
				}
			}
			else {
				setFeedbackControlState(feedbackDiv,"error")
				messageDialog("Error updating remarks: " + result[0].message,'Error');
			}
		},
		error: function (jqXHR, textStatus, error) {
			setFeedbackControlState(feedbackDiv,"error")
			handleFail(jqXHR,textStatus,error,"updating remarks");
		},
		dataType: "json"
	});
} 

function openEditRelationsDialog(collection_object_id,dialogId,guid,callback) {
	var title = "Edit Relationships for " + guid;
	createSpecimenEditDialog(dialogId,title,callback);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditRelationsHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + dialogId + "_div").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"opening edit Relationships dialog");
		},
		dataType: "html"
	});
};

function openEditAttributesDialog(collection_object_id,dialogId,guid,callback) {
	var title = "Edit Attributes for " + guid;
	createSpecimenEditDialog(dialogId,title,callback);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditAttributesHTML",
			collection_object_id: collection_object_id
		},
		success: function (result) {
			$("#" + dialogId + "_div").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"opening edit Attributes dialog");
		},
		dataType: "html"
	});
};

/** openEditLocalityDialog opens a dialog for editing locality and collecting event
 * for a cataloged item.
 * @param collection_object_id for the cataloged_item for which to edit locality and collecting event.
 * @param dialogId the id in the dom for the div to turn into the dialog without
 *  a leading # selector.
 * @param guid the guid of the specimen to display in the dialog title
 * @param callback a callback function to invoke on closing the dialog.
 */
function openEditLocalityDialog(collection_object_id,dialogId,guid,callback) {
	var title = "Edit Locality and Collecting Event for " + guid;
	createSpecimenEditDialog(dialogId,title,callback,800,1400);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditLocalityHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + dialogId + "_div").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"opening edit Locality dialog");
		},
		dataType: "html"
	});
};

function closeInPage() { 
	$("#InPageEditorDiv").html("");
	$('#SpecimenDetailsDiv').show();
	$('#editControlsBlock').show();
	$("#InPageEditorDiv").removeClass("border");
	$("#InPageEditorDiv").removeClass("border-secondary");
	$("#InPageEditorDiv").removeClass("rounded");
	$("#InPageEditorDiv").removeClass("py-2");
	$("#InPageEditorDiv").removeClass("border-3");
}

function openEditLocalityInPage(collection_object_id,callback) { 
	$('#SpecimenDetailsDiv').hide();
	$('#editControlsBlock').hide();
	$("#InPageEditorDiv").addClass("border");
	$("#InPageEditorDiv").addClass("border-secondary");
	$("#InPageEditorDiv").addClass("rounded");
	$("#InPageEditorDiv").addClass("py-2");
	$("#InPageEditorDiv").addClass("border-3");
	$("#InPageEditorDiv").html("Loading...");
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditLocalityHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#InPageEditorDiv").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"opening edit CollectingEvent/Locality form");
			closeInPage();
		},
		dataType: "html"
	});
}

/** openEditCitationsDialog open a dialog for editing citations for a cataloged item.
 *
 * @param collection_object_id for the cataloged_item for which to edit citations.
 * @param dialogId the id in the dom for the div to turn into the dialog without
 *  a leading # selector.
 * @param guid the guid of the specimen to display in the dialog title
 * @param callback a callback function to invoke on closing the dialog.
 */
function openEditCitationsDialog(collection_object_id,dialogId,guid,callback) {
	var title = "Edit Citations for " + guid;
	createCitationEditDialog(dialogId,title,callback);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditCitationHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + dialogId + "_div").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"opening edit Citations dialog");
		},
		dataType: "html"
	});
};

/** openEditPartsDialog open a dialog for editing parts for a cataloged item.
 *
 * @param collection_object_id for the cataloged_item for which to edit parts.
 * @param dialogId the id in the dom for the div to turn into the dialog without 
 *  a leading # selector.
 * @param guid the guid of the specimen to display in the dialog title
 * @param callback a callback function to invoke on closing the dialog.
 */
function openEditPartsDialog(collection_object_id,dialogId,guid,callback) {
	var title = "Edit Parts for " + guid;
	createSpecimenEditDialog(dialogId,title,callback);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditPartsHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + dialogId + "_div").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"opening edit Parts dialog");
		},
		dataType: "html"
	});
};

/** editPartAttributes opens a dialog for editing attributes of a part.

 * @param part_collection_object_id the id of the part for which to edit attributes.
 * @param callback a callback function to invoke on closing the dialog.
 */
function editPartAttributes(part_collection_object_id,callback) {
	var title = "Edit Part Attributes";
	dialogId = "editPartAttributesDialog";
	max_height = 750;
	width_cap = 1300; 
	console.log("editPartAttributes: part_collection_object_id = " + part_collection_object_id);
	createSpecimenEditDialog(dialogId,title,callback,max_height,width_cap);
	// Call the server-side function to get the edit HTML, load into the dialog
	$.ajax({
		url: '/specimens/component/functions.cfc',
		type: 'POST',
		data: {
			method: 'getEditPartAttributesHTML',
			returnformat: 'plain',
			partID: part_collection_object_id
		},
		success: function(response) {
			console.log("editPartAttributes: success");
			// defer execution to ensure dialog is created before loading content
			setTimeout(function() { $("#" + dialogId + "_div").html(response); }, 0);
		},
		error: function(xhr, status, error) {
			handleError(xhr, status, error);
		}
	});
}

/** handlePartAttributeTypeChange handles the change of part attribute type, changes input controls
 * for value and units field to select (with an appropriate controlled vocabulary) or text input based 
 * on the selected attribute type.
 *
 * @param suffix optional suffix for the attribute fields (e.g., for multiple attributes), assumes that the
 * attribute type is in a select with id = 'attribute_type' or id = 'attribute_type' + suffix.
 * similarly assumes that the value field is in an input with id = 'attribute_value' or id = 'attribute_value' + suffix,
 * and the units field is in an input with id = 'attribute_units' or id = 'attribute_units' + suffix.
 * @param partID the ID of the part to which the attribute belongs
 */
function handlePartAttributeTypeChange(suffix, partID) {
    var selectedType = $('#attribute_type' + suffix).val();
    var valueFieldId = 'attribute_value' + suffix;
    var unitsFieldId = 'attribute_units' + suffix;
	console.log("handlePartAttributeTypeChange: selectedType = " + selectedType + ", partID = " + partID + ", suffix = " + suffix);
    
    // lookup value code table and units code table from ctspec_part_att_att
    $.ajax({
        url: '/specimens/component/functions.cfc',
        type: 'POST',
        dataType: 'json',
        data: {
            partID: partID,
            method: 'getPartAttributeCodeTables',
            attribute_type: selectedType
        },
        success: function(response) {
            console.log(response);
            
            // Handle value field
            if (response[0].value_code_table) {
                // Create select element with label
                var selectHtml = '<select id="' + valueFieldId + '" name="attribute_value" class="data-entry-select reqdClr" required>' +
                               '<option value=""></option>';
                
                // Add options from response
                var values = response[0].value_values.split('|');
                $.each(values, function(index, value) {
                    selectHtml += '<option value="' + value + '">' + value + '</option>';
                });
                selectHtml += '</select>';
                
                // Replace the element content
                $('#' + valueFieldId).html(selectHtml);
            } else {
                // Create text input with label
                var inputHtml = '<input type="text" class="data-entry-input reqdClr" id="' + valueFieldId + '" name="attribute_value" value="" required>';
                
                // Replace the element content
                $('#' + valueFieldId).html(inputHtml);
            }
            
            // Handle units field
            if (response[0].units_code_table) {
                // Create select element with label
                var selectHtml = '<select id="' + unitsFieldId + '" name="attribute_units" class="data-entry-select">' +
                               '<option value=""></option>';
                
                // Add options from response
                $.each(response[0].units_values.split('|'), function(index, value) {
                    selectHtml += '<option value="' + value + '">' + value + '</option>';
                });
                selectHtml += '</select>';
                
                // Replace the element content
                $('#' + unitsFieldId).html(selectHtml);
            } else {
                // Create text input with label (disabled for units when no code table)
                var inputHtml = '<input type="text" class="data-entry-input" id="' + unitsFieldId + '" name="attribute_units" value="" disabled>';
                
                // Replace the element content
                $('#' + unitsFieldId).html(inputHtml);
            }
        },
        error: function(xhr, status, error) {
            handleFail(xhr,status,error,"handling change of part attribute type.");
        }
    });
}
