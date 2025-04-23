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

/** updateIdentifications function 
 *
 * @param identification_id
 * @param targetDiv the id

 * @see updateIdentifications in specimens/component/functions.cfc
 **/
function updateIdentifications(identification_id,targetDiv) {
   alert("updateIdentifications incomplete implementation");
	// TODO: implement pass update data
	// TODO: probably refactor to update an identification
	jQuery.ajax(
	{
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
	},
	)
};

/** openEditIdentificationsDialog (plural) open a dialog for editing 
 * identifications for a cataloged item.
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
};


/** openEditNamedGroupsDialog open a dialog for editing 
 * named group membership for a cataloged item.
 * @param collection_object_id for the cataloged_item for which to edit named groups.
 * @param dialogId the id in the dom for the div to turn into the dialog without 
 *  a leading # selector.
 * @param guid the guid of the specimen to display in the dialog title
 * @param callback a callback function to invoke on closing the dialog.
 */
function openEditNamedGroupsDialog(collection_object_id,dialogId,guid,callback) {
	var title = "Edit Named Groups for " + guid;
	createSpecimenEditDialog(dialogId,title,callback);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditNamedGroupsHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + dialogId + "_div").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"opening named groups dialog");
		},
		dataType: "html"
	});
};

function addToNamedGroup(underscore_collection_id,collection_object_id,callback) {
	jQuery.ajax({	
		url: "/specimens/component/functions.cfc",
		data : {
			method : "addToNamedGroup",
			underscore_collection_id: underscore_collection_id,
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			if (result.DATA.STATUS[0]==1) {
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
 **/
function removeFromNamedGroup(underscore_collection_id, collection_object_id) {
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "removeFromNamedGroup",
			underscore_collection_id: underscore_collection_id,
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			if (result.DATA.STATUS[0]==1) {
				var message  = "Removed from named group";
				messageDialog(message,'Success');
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
