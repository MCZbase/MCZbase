/** Functions used (only) on the specimen details page.  **/
/** These functions should be only load functions for public and non-privileged users **/
/** Reusable functions should be in specimens.js **/
/** Edit functions should be in edit.js **/
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

function loadSummaryHeaderHTML(collection_object_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		data : {
			method : "getSummaryHeaderHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading header of Specimen Details");
		},
		dataType: "html"
	});
};
/** loadMedia populate an html block with the media for 
 * a cataloged item
 * @param collection_object_id for the cataloged item for which
 *   to look up media
 * @param targetDivId the id for the div in the dom, without a leading #
 *  selector, for which to replace the html content with the response
 **/
function loadMedia(collection_object_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		data : {
			method : "getMediaHTML",
			collection_object_id: collection_object_id,
			relationship_type: "shows" 
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading specimen media");
		},
		dataType: "html"
	});
};
function loadSummaryHeader(collection_object_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		data : {
			method : "getSummaryHeaderHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading specimen summary header");
		},
		dataType: "html"
	});
};
function loadIdentifiers(collection_object_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		data : {
			method : "getIdentifiersHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading specimen identifiers");
		},
		dataType: "html"
	});
};
function loadLedger(collection_object_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		data : {
			method : "getMediaHTML",
			collection_object_id: collection_object_id,
			relationship_type: "documents" 
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading ledger media");
		},
		dataType: "html"
	});
};

function loadNamedGroups(collection_object_id,targetDivId) {
	jQuery.ajax(
	{
		dataType: "json",
		url: "/specimens/component/public.cfc",
		data: { 
			method : "getNamedGroupsHTML",
			collection_object_id : collection_object_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"load named groups");
		},
		dataType: "html"
	})
};

function loadMeta(collection_object_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		data : {
			method : "getMetaHTML",
			collection_object_id: collection_object_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"load metadata");
		},
		dataType: "html"
	});
};
function loadAnnotations(collection_object_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		data : {
			method : "getAnnotationsHTML",
			collection_object_id: collection_object_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading annotations");
		},
		dataType: "html"
	});
};
/** TODO: Document this function **/ 
function removeMedia(media_id,form) {
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "removeMedia",
			media_id: media_id,
		},
		success: function (result) {
			$("#mediaHTML").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"removing media");
		},
		dataType: "html"
	});
};

// TODO: Fix documentation and uncomment, or remove if not needed 
/** loadMedia populate an html block with the media 
 * @param collection_object_id identifying the cataloged item
 * @param targetDivId the id for the div in the dom, without a leading #
 *  selector, for which to replace the html content with the identification 
 *  history.
 **/
//function getMediaBlock(media_id,displayAs) { 
//	jQuery.ajax({
//		url: "/media/component/public.cfc",
//		data : {
//			method : "getMediaBlockHtml",
//			media_id: media_id,
//		},
//		error: function (jqXHR, textStatus, error) {
//			handleFail(jqXHR,textStatus,error,"loading media");
//		},
//		dataType: "html"
//	}
//	)
//}


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

/** updateMedia function 
 * @method getMedia in functions.cfc
 * @param media_id
 * @param targetDiv the id
 **/
function updateMedia(media_id,targetDiv) {
	jQuery.ajax(
	{
		dataType: "json",
		url: "/specimens/component/search.cfc",
		data: { 
			method : "getMediaHtml",
			media_id : media_id,
			returnformat : "json",
			queryformat : 'column'
		},
		error: function (jqXHR, status, message) {
			messageDialog("Error updating item count: " + status + " " + jqXHR.responseText ,'Error: '+ status);
		},
		success: function (result) {
			if (result.DATA.STATUS[0]==1) {
				var message  = "There are Media";
	
				$('#' + targetDiv).html(message);
			}
		}
	},
	)
};

/** loadIdentifications populate an html block with the identification 
 * history for a cataloged item.
 * @param collection_object_id identifying the cataloged item for which 
 *  to list the identification history.
 * @param targetDivId the id for the div in the dom, without a leading #
 *  selector, for which to replace the html content with the identification 
 *  history.
 **/
function loadIdentifications(collection_object_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		data : {
			method : "getIdentificationsHTML",
			collection_object_id: collection_object_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading identifications");
		},
		dataType: "html"
	});
};

/** loadOtherIDs populate an html block with the other IDs for a cataloged item.
* @param collection_object_id identifying the cataloged item for which 
*  to list the ientifiers.
* @param targetDivId the id for the div in the dom, without a leading #
*  selector, for which to replace the html content 
*/
function loadOtherIDs(collection_object_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		data : {
			method : "getOtherIDsHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading other ids");
		},
		dataType: "html"
	});
};

function updateOtherID(coll_obj_other_id_num_id,targetDiv) {
	jQuery.ajax(
	{
		dataType: "json",
		url: "/transactions/component/functions.cfc",
		data: { 
			method : "updateOID",
			coll_obj_other_id_num_id : coll_obj_other_id_num_id,
			returnformat : "json",
			queryformat : 'column'
		},
		error: function (jqXHR, status, message) {
			messageDialog("Error updating item count: " + status + " " + jqXHR.responseText ,'Error: '+ status);
		},
		success: function (result) {
			if (result.DATA.STATUS[0]==1) {
				var message  = "There are otherIDs";
				$('#' + targetDiv).html(message);
			}
		}
	},
	)
};

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



function removeCitation(cited_taxon_name_id,form) {
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "removeMedia",
			publication_id: publication_id,
			cited_taxon_name_id: cited_taxon_name_id,
		},
		success: function (result) {
			$("#citationsHTML").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"removing citations");
		},
		dataType: "html"
	});
};


function loadCitations(collection_object_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		data : {
			method : "getCitationsHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading citations");
		},
		dataType: "html"
	});
}
function loadCitationMedia(collection_object_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		data : {
			method : "getCitationMediaHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading citation media");
		},
		dataType: "html"
	});
}

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

function getCatalogedItemCitation (id,type) {
	var collection_id = document.getElementById('collection').value;
	var el = document.getElementById(id);
	el.className='red';
	var theNum = el.value;
	jQuery.getJSON("/specimens/component/functions.cfc",
		{
			method : "getCatalogedItemCitation",
			collection_id : collection_id,
			theNum : theNum,
			type : type,
			returnformat : "json",
			queryformat : 'column'
		},
		success_getCatalogedItemCitation
	);
}

function success_getCatalogedItemCitation (r) {
	var result=r.DATA;
	//alert(result);
	if (r.ROWCOUNT > 1){
		alert('Multiple matches.');
	} else {
		if (r.ROWCOUNT==1) {
			var scientific_name=result.SCIENTIFIC_NAME[0];
			var collection_object_id=result.COLLECTION_OBJECT_ID[0];
			var cat_num=result.CAT_NUM[0];
			if (collection_object_id < 0) {
				alert('error: ' + scientific_name);
			} else {
				var sn = document.getElementById('scientific_name');
				var co = document.getElementById('collection_object_id');
				var c = document.getElementById('collection');
				var cn = document.getElementById('cat_num');
				cn.className='reqdClr';
				if (document.getElementById('custom_id')) {
					var cusn = document.getElementById('custom_id');
					cusn.className='';
				}
				co.value=collection_object_id;
				sn.value=scientific_name;
				cn.value=cat_num;
				//c.style.background='#8BFEB9';
				//cn.style.background='#8BFEB9';
			}
		} else {
			alert('Specimen not found.');
		}
	}
}

function loadParts(collection_object_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		data : {
			method : "getPartsHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading parts");
		},
		dataType: "html"
	});
}
function loadPartCount(collection_object_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		data : {
			method : "getPartCount",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			console.log(result);
			var count = result[0].ct;
			$("#" + targetDivId ).html(count);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading part count");
		},
		dataType: "json"
	});
}

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

function loadRelations(collection_object_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		data : {
			method : "getRelationsHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading other ids");
		},
		dataType: "html"
	});
}

function showLLFormat(orig_units) {
		//alert(orig_units);
		var llMeta = document.getElementById('llMeta');
		var decdeg = document.getElementById('decdeg');
		var utm = document.getElementById('utm');
		var ddm = document.getElementById('ddm');
		var dms = document.getElementById('dms');
		llMeta.style.display='none';
		decdeg.style.display='none';
		utm.style.display='none';
		ddm.style.display='none';
		dms.style.display='none';
		//alert('everything off');
		if (orig_units.length > 0) {
			//alert('got soemthing');
			llMeta.style.display='';
			if (orig_units == 'decimal degrees') {
				decdeg.style.display='';
			}
			else if (orig_units == 'UTM') {
				//alert(utm.style.display);
				utm.style.display='';
				//alert(utm.style.display);
			}
			else if (orig_units == 'degrees dec. minutes') {
				ddm.style.display='';
			}
			else if (orig_units == 'deg. min. sec.') {
				dms.style.display='';
			}
			else {
				alert('I have no idea what to do with ' + orig_units);
			}
		}
	}

function addIdentAgentToForm (id,name,formid) {
	if (typeof id == "undefined") {
		id = "";
	 }
	if (typeof name == "undefined") {
		name = "";
	 }
	jQuery.getJSON("/specimens/component/functions.cfc",
		{
			method : "getAgentIdentifiers",
			id : id,
			returnformat : "json",
			queryformat : 'column'
		},
		function (data) {
			var i=parseInt($('#numAgents').val())+1;
			var d= '';
			d+='<div id="IdTr_#i#_#idnum#">';
			d+='<div class="col-12">';
			d+='<label for="IdBy_#i#_#idnum#">Identified By hi';
			d+='<h5 id="IdBy_#i#_#idnum#_view" class="d-inline infoLink">&nbsp;&nbsp;&nbsp;&nbsp;</h5>';
			d+='</label>';
			d+='<div class="col-6 px-0">';
			d+='<div class="input-group">';
			d+='<div class="input-group-prepend"> <span class="input-group-text smaller bg-lightgreen" id="IdBy_#i#_#idnum#_icon">';
			d+='<i class="fa fa-user" aria-hidden="true"></i></span> </div>';
			d+='<input type="text" name="IdBy_#i#_#idnum#" id="IdBy_#i#_#idnum#" value="#encodeForHTML(agent_name)#" class="reqdClr data-entry-input form-control" >';
			d+='</div><input type="hidden" name="IdBy_#i#_#idnum#_id" id="IdBy_#i#_#idnum#_id" value="#agent_id#" >';
			d+='<input type="hidden" name="identification_agent_id_#i#_#idnum#" id="identification_agent_id_#i#_#idnum#" value="#identification_agent_id#">';
			d+='</div></div>';
			d+='<div class="col-12 col-md-3">';
			d+='<button type="button" class="btn btn-xs btn-warning float-left"';
			d+='onClick=\' confirmDialog("Remove not-yet saved new agent from this transaction?", "Confirm Unlink Agent", function()$("#new_trans_agent_div_'+i+'").remove(); } ); \'>Remove</button>';
			d+='</div>';
			d+='<script>';
			d+='$(document).ready(function() {';
			d+='$(makeRichTransAgentPicker("trans_agent_'+i+'","agent_id_'+i+'","agent_icon_'+i+'","agentViewLink_'+i+'",'+id+'));';
			d+='});';
			d+='</script>';
			d+='</div>';
			$('#numAgents').val(i);
			jQuery('#newID').append(d);
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
		messageDialog('Error adding agents to transaction record: '+message, 'Error: '+error.substring(0,50));
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

function loadAttributes(collection_object_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		data : {
			method : "getAttributesHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading attributes");
		},
		dataType: "html"
	});
}

function openEditAttributesDialog(collection_object_id,dialogId,guid,callback) {
	var title = "Edit Attributes for " + guid;
	createSpecimenEditDialog(dialogId,title,callback);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditAttributesHTML",
			collection_object_id: collection_object_id,
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

function loadLocality(collection_object_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		data : {
			method : "getLocalityHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading locality");
		},
		dataType: "html"
	});
}

function openEditLocalityDialog(collection_object_id,dialogId,guid,callback) {
	var title = "Edit Locality and Collecting Event for " + guid;
	createSpecimenEditDialog(dialogId,title,callback);
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

function loadTransactions(collection_object_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		data : {
			method : "getTransactionsHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading transactions");
		},
		dataType: "html"
	});
}

function openEditTransactionsDialog(collection_object_id,dialogId,guid,callback) {
	var title = "Edit Transactions for " + guid;
	createSpecimenEditDialog(dialogId,title,callback);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditTransactionsHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + dialogId + "_div").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"opening edit Transactions dialog");
		},
		dataType: "html"
	});
};

function loadPreparators(collection_object_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		data : {
			method : "getPreparatorsHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading collectors");
		},
		dataType: "html"
	});
}

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

function createSpecimenEditDialog(dialogId,title,closecallback) {
	var content = '<div id="'+dialogId+'_div">Loading...</div>';
	var x=1;
	var h = $(window).height();
	if (h>775) { h=775; } // cap height at 775
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
			//"Save": function() {
			//	$("#"+dialogId).dialog('submit');
			//},
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

function createCitationEditDialog(dialogId,title,closecallback) {
	var content = '<div id="'+dialogId+'_div">Loading...</div>';
	var x=1;
	var h = $(window).height();
	if (h>775) { h=775; } // cap height at 775
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

function openItemConditionHistoryDialog(collection_object_id, dialogId) { 
	var title = "Part/Preparation Condition History.";
	var content = '<div id="'+dialogId+'_div">Loading....</div>';
	var thedialog = $("#"+dialogId).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		//stack: true,
		height: 900,
		width: 900,
		minWidth: 400,
		minHeight: 400,
		draggable:true,
		buttons: {
			"Close Dialog": function() {
				$(this).dialog('close');
				//$("#"+dialogId).dialog('close');
			}
		},
		open: function (event, ui) {
			// force the dialog to lay above any other elements in the page.
			var maxZindex = getMaxZIndex();
			$('.ui-dialog').css({'z-index': maxZindex + 6 });
			$('.ui-widget-overlay').css({'z-index': maxZindex + 5 });
		},
		close: function(event,ui) {
			$("#"+dialogId+"_div").html("");
			$("#"+dialogId).empty();
			try {
				$("#"+dialogId).dialog('destroy');
			} catch (err) {
				console.log(err);
			}
		}
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		type: "get",
		data: {
			method: 'getPartConditionHistoryHTML',
			returnformat: "plain",
			collection_object_id: collection_object_id
		},
		success: function(data) {
			$("#"+dialogId+"_div").html(data);
		},
		error: function (jqXHR, textStatus, error) { 
			handleFail(jqXHR,textStatus,error,"removing looking up condition history");
		}
	});
}

function localityMapSetup(){
	/*map customization and polygon functionality commented  out for now. This will be useful as we implement more features -bkh*/
	$("input[id^='coordinates_']").each(function(e){
		var locid=this.id.split('_')[1];
		var coords=this.value;
		var bounds = new google.maps.LatLngBounds();
		var polygonArray = [];
		var ptsArray=[];
		var lat=coords.split(',')[0];
		var lng=coords.split(',')[1];
		var errorm=$("#error_" + locid).val();
		var mapOptions = {
			zoom: 1,
			center: new google.maps.LatLng(lat, lng),
			mapTypeId: google.maps.MapTypeId.ROADMAP,
			panControl: true,
			scaleControl: false,
			controlSize: 30,
			fullscreenControl: true,
			zoomControl: true
		};
		var map = new google.maps.Map(document.getElementById("mapdiv_" + locid), mapOptions);

		var center=new google.maps.LatLng(lat,lng);
		var marker = new google.maps.Marker({
			position: center,
			map: map,
			zIndex: 10
		});
		bounds.extend(center);
		if (parseInt(errorm)>0){
			var circleoptn = {
				strokeColor: '#FF0000',
				strokeOpacity: 0.8,
				strokeWeight: 2,
				fillColor: '#FF0000',
				fillOpacity: 0.15,
				map: map,
				center: center,
				radius: parseInt(errorm),
				zIndex:-99
			};
			crcl = new google.maps.Circle(circleoptn);
			bounds.union(crcl.getBounds());
		}
		// WKT can be big and slow, so async fetch
		$.get( "/localities/component/georefUtilities.cfc?returnformat=plain&method=getGeogWKT&locality_id=" + locid, function( wkt ) {
			  if (wkt.length>0){
				var regex = /\(([^()]+)\)/g;
				var Rings = [];
				var results;
				while( results = regex.exec(wkt) ) {
					Rings.push( results[1] );
				}
				for(var i=0;i<Rings.length;i++){
					// for every polygon in the WKT, create an array
					var lary=[];
					var da=Rings[i].split(",");
					for(var j=0;j<da.length;j++){
						// push the coordinate pairs to the array as LatLngs
						var xy = da[j].trim().split(" ");
						var pt=new google.maps.LatLng(xy[1],xy[0]);
						lary.push(pt);
						//console.log(lary);
						bounds.extend(pt);
					}
					// now push the single-polygon array to the array of arrays (of polygons)
					ptsArray.push(lary);
				}
				var poly = new google.maps.Polygon({
					paths: ptsArray,
					strokeColor: '#1E90FF',
					strokeOpacity: 0.8,
					strokeWeight: 2,
					fillColor: '#1E90FF',
					fillOpacity: 0.35
				});
				poly.setMap(map);
				polygonArray.push(poly);
				// END this block build WKT
				} else {
					$("#mapdiv_" + locid).addClass('noWKT');
				}
				if (bounds.getNorthEast().equals(bounds.getSouthWest())) {
				   var extendPoint1 = new google.maps.LatLng(bounds.getNorthEast().lat() + 0.05, bounds.getNorthEast().lng() + 0.05);
				   var extendPoint2 = new google.maps.LatLng(bounds.getNorthEast().lat() - 0.05, bounds.getNorthEast().lng() - 0.05);
				   bounds.extend(extendPoint1);
				   bounds.extend(extendPoint2);
				}
				map.fitBounds(bounds);
				for(var a=0; a<polygonArray.length; a++){
					if  (! google.maps.geometry.poly.containsLocation(center, polygonArray[a]) ) {
						$("#mapdiv_" + locid).addClass('uglyGeoSPatData');
					} else {
						$("#mapdiv_" + locid).addClass('niceGeoSPatData');
					}
				}
			});
			map.fitBounds(bounds);
	});
}

/** Create a dialog for displaying history of a specimen part. 
  * 
  * @param collection_object_id the specimen part for which to retrieve the history.
  * @param dialogid the id of the div that is to contain the dialog, without a leading # selector.
  */
function openHistoryDialog(collection_object_id, dialogid) { 
	var title = "Part Preparation and Condition History.";
	var content = '<div id="'+dialogid+'_div" class="col-12 px-1 px-xl-2">Loading....</div>';
	var thedialog = $("#"+dialogid).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'ui-widget-header left-3',
		modal: false,
		stack: true,
		height: 'auto',
		width: 'auto',
		maxWidth: 600,
		minHeight: 500,
		draggable:true,
		buttons: {
			"Close Dialog": function() {
				$("#"+dialogid).dialog('close');
			}
		},
		open: function (event, ui) {
			// force the dialog to lay above any other elements in the page.
			var maxZindex = getMaxZIndex();
			$('.ui-dialog').css({'z-index': maxZindex + 6 });
			$('.ui-widget-overlay').css({'z-index': maxZindex + 5 });
		},
		close: function(event,ui) {
			$("#"+dialogid+"_div").html("");
			$("#"+dialogid).dialog('destroy');
		}
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		type: "get",
		data: {
			method: "getHistoryHTML",
			returnformat: "plain",
			collection_object_id: collection_object_id
		},
		success: function(data) {
			$("#"+dialogid+"_div").html(data);
		},
		error: function (jqXHR, status, error) {
			var message = "";
			if (error == 'timeout') { 
				message = ' Server took too long to respond.';
			} else { 
				message = jqXHR.responseText;
			}
			$("#"+dialogid+"_div").html("Error (" + error + "): " + message );
		}
	});
}
