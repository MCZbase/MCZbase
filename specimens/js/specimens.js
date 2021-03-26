//function loadCitPubForMedia(publication_id) {
//targetDiv="CitPubFormMedia";
//	console.log(" media in #"+ targetDiv);
//	jQuery.ajax({
//		url: "/specimens/component/functions.cfc",
//		data : {
//			method : "getMediaForCitPub",
//			publication_id: publication_id,
//		},
//		success: function (result) {
//			$("#CitPubFormMedia").html(result);
//		},
//		error: function (jqXHR, textStatus, error) {
//			handleFail(jqXHR,textStatus,error,"removing pub");
//		},
//		dataType: "html"
//	});
//}
//	$(function() {
//     $(".dialog").dialog({
//		open: function(event,ui){},
//        Title: {style:"font-size: 1.3em;"},
//		bgiframe: true,
//        autoOpen: false,
//    	width: '700px',
//    	minWidth: 500,
//    	minHeight: 400,
//		buttons: [
//			{ text: "Cancel", click: function () { $(this).dialog( "close" );}, class: "btn", style:"background: none; border: none;" },
//        	{ text: "Save",  click: function() { alert("save"); }, class:"btn btn-primary"}
//		 ],
//        close: function() {
//            $(this).dialog( "close" );
//        },
//        modal: true
//	 }
//       );
//     $('body')
//      .bind(
//       'click',
//       function(e){
//        if(
//         $('.dialog-ID').dialog('isOpen')
//         && !$(e.target).is('.ui-dialog, button')
//         && !$(e.target).closest('.ui-dialog').length
//        ){
//         $('.dialog').dialog('close');
//        }
//       }
//      );
//    }
//   );
//	$(function() {
//     $(".dialog-locality").dialog({
//		open: function(event,ui){},
//        Title: {style:"font-size: 1.3em;"},
//		bgiframe: true,
//        autoOpen: false,
//    	width: '700px',
//    	minWidth: 500,
//    	minHeight: 400,
//		buttons: [
//			{ text: "Cancel", click: function () { $(this).dialog( "close" );}, class: "btn", style:"background: none; border: none;" },
//        	{ text: "Save",  click: function() { alert("save"); }, class:"btn btn-primary"}
//		 ],
//        close: function() {
//            $(this).dialog( "close" );
//        },
//        modal: true
//	 }
//       );
//     $('body')
//      .bind(
//       'click',
//       function(e){
//        if(
//         $('.dialog-ID').dialog('isOpen')
//         && !$(e.target).is('.ui-dialog, button')
//         && !$(e.target).closest('.ui-dialog').length
//        ){
//         $('.dialog-locality').dialog('close');
//        }
//       }
//      );
//    }
//   );


//function loadLocality(locality_id,form) {
//	jQuery.ajax({
//		url: "/specimens/component/functions.cfc",
//		data : {
//			method : "getLocalityHtml",
//			locality_id: locality_id,
//		},
//		success: function (result) {
//			$("#localityHTML").html(result);
//		},
//		error: function (jqXHR, textStatus, error) {
//			handleFail(jqXHR,textStatus,error,"removing locality");
//		},
//		dataType: "html"
//	});
//};

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

function loadLocality(collecting_event_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/public.cfc",
		data : {
			method : "getLocalityHTML",
			collecting_event_id: collecting_event_id,
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
/** loadIdentifications populate an html block with the identification 
 * history for a cataloged item.
 * @param collection_object_id identifying the cataloged item for which 
 *  to list the identification history.
 * @param targetDivId the id for the div in the dom, without a leading #
 *  selector, for which to replace the html content with the identification 
 *  history.
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
}
/** openEditOtherIDsDialog (plural) open a dialog for editing 
 * identifications for a cataloged item.
 * @param collection_object_id for the cataloged_item for which to edit identifications.
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
			handleFail(jqXHR,textStatus,error,"opening edit identifications dialog");
		},
		dataType: "html"
	});
};

/** createSpecimenEditDialog turn a div on the specimen detail page
 * into a dialog, with a close dialog button and where the 
 * dialog content can be placed in a div within the dialog with
 * the id dialogId + '_div'
 * @param dialogId the id in the dom without a leading # selector
 *  for the div that is to contain the dialog, used to construct
 *  a div with an id dialogId + '_div' into which dialog content 
 *  should be placed.
 * @param title the title to display on the dialog.
 * @param closecalback function to invoke when closing the dialog
 *  for example to ajax reload a related part of a page.
 */
function createSpecimenEditDialog(dialogId,title,closecallback) {
	var content = '<div id="'+dialogId+'_div">Loading....</div>';
	var h = $(window).height();
	if (h>775) { h=775; } // cap height at 775
	var w = $(window).width();
	// full width at less than medium screens
	if (w>414 && w<=1333) { 
		// 90% width up to extra large screens
		w = Math.floor(w *.9);
	} else if (w>1333) { 
		// cap width at 1200 pixel
		w = 1200;
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
