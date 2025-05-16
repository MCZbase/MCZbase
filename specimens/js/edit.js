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
*/
function createSpecimenEditDialog(dialogId,title,closecallback,max_height=775) {
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
		// cap width at 1200 pixel
		w = 999;
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
			
		},
		close: function(event,ui) {
			console.log("Close called on dialog in div with id: " + dialogId);
			if (jQuery.type(closecallback)==='function')	{
				closecallback();
			}
			$("#"+dialogId+"_div").html("");
			try {
				$("#"+dialogId).dialog('destroy');
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

/** updateIdentifications function 
 * TODO: Work in progress
 *
 * @param identification_id the id of the identification to update
 * @param targetDiv the id of the div in which to display the updated
 *   identifications count without a leading # selector.
 *
 * @see updateIdentifications in specimens/component/functions.cfc
 **/
function updateIdentifications(identification_id,targetDiv) {
   alert("updateIdentifications incomplete implementation");
	// TODO: implement pass update data
	// TODO: probably refactor to update an identification
	jQuery.ajax({
		dataType: "json",
		url: "/specimens/component/functions.cfc",
		data: { 
			method : "updateIdentifications",
			identification_id : idenification_id,
			returnformat : "json",
			queryformat : 'column'
		},
		error: function (jqXHR, status, message) {
			messageDialog("Error updating identifications count: " + status + " " + jqXHR.responseText ,'Error: '+ status);
		},
		success: function (result) {
			if (result.DATA.STATUS[0]==1) {
				var message  = "There are identifications";
	
				$('#' + targetDiv).html(message);
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

function openEditCollectorsDialog(collection_object_id,dialogId,guid,callback) {
	var title = "Edit Collectors for " + guid;
	createSpecimenEditDialog(dialogId,title,callback);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditCollectorsHTML",
			target : "collectors",
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
			target : "preparators",
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
