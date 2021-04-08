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

/** loadIdentifications populate an html block with the identification 
* history for a cataloged item.
* @param collection_object_id identifying the cataloged item for which 
*  to list the identification history.
* @param targetDivId the id for the div in the dom, without a leading #
*  selector, for which to replace the html content with the identification 
*  history.
*/
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
			collection_object_id: collection_object_id,
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
	createSpecimenEditDialog(dialogId,title,callback);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditPublicationHTML",
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

function openEditPartsDialog(part_id,dialogId,guid,callback) {
	var title = "Edit Parts for " + guid;
	createSpecimenEditDialog(dialogId,title,callback);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getEditPartsHTML",
			part_id: part_id,
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
			"Close Dialog": function() {
				$("#"+dialogId).dialog('close');
			},
			"Save": function() {
				$("#"+dialogId).dialog('submit');
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