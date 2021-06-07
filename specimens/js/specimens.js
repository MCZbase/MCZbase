function checkFormValidity(form) { 
	var result = false;
	if (!form.checkValidity || form.checkValidity()) { 
		result = true;
	} else { 
		var message = "Form Input validation problem.<br><dl>";
		for(var i=0; i < form.elements.length; i++){
			var element = form.elements[i];
			if (element.checkValidity() == false) { 
				var label = $( "label[for=" + element.id + "] ").text();
				if (label==null || label=='') { label = element.id; }
					message = message + "<dt>" + label + ":</dt> <dd>" + element.validationMessage + "</dd>";
				}
			}
			message = message + "</dl>"
			messageDialog(message,'Unable to Save');
		}
	return result;
};

/** loadIdentification populate an html block with the identification 
* history for a cataloged item.
* @param identification_id 
* @param form
**/
function loadIdentification(identification_id,form) {
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getIdentificationHtml",
			identification_id: identification_id,
		},
		success: function (result) {
			$("#identificationHTML").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"removing identification");
		},
		dataType: "html"
	});
};

/** updateIdentifications function 
 * @method getIdentification in functions.cfc
 * @param identification_id
 * @param targetDiv the id
 **/
function updateIdentifications(identification_id,targetDiv) {
	jQuery.ajax(
	{
		dataType: "json",
		url: "/transactions/component/functions.cfc",
		data: { 
			method : "getIdentification",
			identification_id : idenification_id,
			returnformat : "json",
			queryformat : 'column'
		},
		error: function (jqXHR, status, message) {
			messageDialog("Error updating item count: " + status + " " + jqXHR.responseText ,'Error: '+ status);
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
}

/** updateIdentifications function 
 * @method updateOID in functions.cfc
 * @param identification_id
 * @param targetDiv the id
 **/
function updateIdentifications(identification_id,targetDiv) {
	jQuery.ajax(
	{
		dataType: "json",
		url: "/transactions/component/functions.cfc",
		data: { 
			method : "updateOID",
			identification_id : idenification_id,
			returnformat : "json",
			queryformat : 'column'
		},
		error: function (jqXHR, status, message) {
			messageDialog("Error updating item count: " + status + " " + jqXHR.responseText ,'Error: '+ status);
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



/** loadOtherID populate an html block with the other IDs for a cataloged item.
* @param collection_object_id identifying the cataloged item for which 
*  to list the identification history.
* @param targetDivId the id for the div in the dom, without a leading #
*  selector, for which to replace the html content 
*/
function loadOtherID(coll_obj_other_id_num_id,form) {
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getOtherIDHtml",
			coll_obj_other_id_num_id: coll_obj_other_id_num_id,
		},
		success: function (result) {
			$("#otherIDsHTML").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"removing Other IDs");
		},
		dataType: "html"
	});
};

function updateOtherIDs(coll_obj_other_id_num_id,targetDiv) {
	jQuery.ajax(
	{
		dataType: "json",
		url: "/transactions/component/functions.cfc",
		data: { 
			method : "getOtherIDsHTML",
			coll_obj_other_id_num_id : coll_obj_other_id_num_id,
			returnformat : "json",
			queryformat : 'column'
		},
		error: function (jqXHR, status, message) {
			messageDialog("Error updating item count: " + status + " " + jqXHR.responseText ,'Error: '+ status);
		},
		success: function (result) {
			if (result.DATA.STATUS[0]==1) {
				var message  = "There are ";
				$('#' + targetDiv).html(message);
			}
		}
	},
	)
};

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
}

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



function loadMedia(media_id,form) {
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getMediaHtml",
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

/** loadMedia populate an html block with the media 
 * @method getMediaHTML
 * @param collection_object_id 
 * @param targetDivId 
 **/
function loadMedia(collection_object_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		data : {
			method : "getMediaHTML",
			collection_object_id: collection_object_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading media");
		},
		dataType: "html"
	});
};
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
	});
};
function openEditMediaDetailsDialog(media_id,dialogId,callback) {
	var title = "Edit Media";
	createSpecimenEditDialog(dialogId,title,callback);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditMediaDetailsHTML",
			media_id: media_id,
		},
		success: function (result) {
			$("#" + dialogId + "_div").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"opening edit Media dialog");
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

function loadCitation(collection_object_id,form) {
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getCitationHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#citationHTML").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"removing citation");
		},
		dataType: "html"
	});
};

function openEditCitationsDialog(collection_object_id,dialogId,guid,callback) {
	var title = "Edit Citations for " + guid;
	createCitationEditDialog(dialogId,title,callback);
	jQuery.ajax({
		url: "/specimens/Citations.cfm",
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
function loadCollectors(collection_object_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		data : {
			method : "getCollectorsHTML",
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
function openEditCollectorsDialog(collection_object_id,dialogId,guid,callback) {
	var title = "Edit Collectors and Preparators for " + guid;
	createSpecimenEditDialog(dialogId,title,callback);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditCollectorsHTML",
			collection_object_id: collection_object_id,
		},
		success: function (result) {
			$("#" + dialogId + "_div").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"opening edit Collectors and Preparators dialog");
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
		stack: true,
		minWidth: 550,
		minHeight: 200,
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
