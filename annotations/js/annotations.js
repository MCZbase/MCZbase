/** JavaScript functions for handling annotations in MCZbase. **/

/** saveThisAnnotation - Save a new annotation via AJAX.
 * Requires user to have a login and have entered name and email.
 * @param feedbackDiv the id of a div element to show status feedback.
 */
function saveThisAnnotation(feedbackDiv) {
	setFeedbackControlState(feedbackDiv,"saving");
	var idType = $("#idtype").val();
	var idvalue = $("#idvalue").val();
	var annotation = $("#annotation").val();
	var motivation = "";
	if ($("#motivation").length) { 
		motivation = $("#motivation").val();
	}
	if (annotation.length==0){
		alert('You must enter an annotation to save.');
		return false;
	}
	var postData = {
		method : "addAnnotation",
		target_type : idType,
		target_id : idvalue,
		annotation : annotation,
		motivation : motivation,
		returnformat : "json",
		queryformat : 'column'
	};
	if ($("#mask_annotation_fg").length) {
		postData.mask_annotation_fg = $("#mask_annotation_fg").val();
	}
	jQuery.ajax({
		url: "/annotations/component/functions.cfc",
		type: "post",
		data: postData,
		success: function(data) {
			messageDialog("<p>Your Annotation has been saved, and the appropriate collections staff will be alerted. Thank you for helping improve MCZbase!</p><p>"+data+"</p><p>You may close the annotation dialog.</p>","Annotation Saved");
			setFeedbackControlState(feedbackDiv,"saved");
		},
		error: function (jqXHR, textStatus, error) {
			setFeedbackControlState(feedbackDiv,"error");
			handleFail(jqXHR,textStatus,error,"saving annotation");
		}
	});
}

/** Create and open a dialog to list existing annotations and annotate a data object.
 * @param dialogid the id of a div in the dom which is to contain the dialog, without a leading # selector.
 * @param target_type the type of entity which is to be annotated (collection_object, taxon_name, publication, project).
 * @param target_id the surrogate numeric primary key for the target_type table identifying the row to be annotated.
 * @param callback function to execute on closing the dialog.
 */
function openAnnotationsDialog(dialogid, target_type, target_id, callback) { 
	var title = "Annotations";
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
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
	var thedialog = $("#"+dialogid).html(content)
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
			if (jQuery.type(callback)==='function') callback();
			$("#"+dialogid+"_div").html("");
			$("#"+dialogid).dialog('destroy');
		}
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/annotations/component/functions.cfc",
		type: "get",
		data: {
			method: "getAnnotationDialogHtml",
			returnformat: "plain",
			target_type: target_type,
			target_id: target_id
		},
		success: function(data) {
			$("#"+dialogid+"_div").html(data);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading annotation dialog");
		}
	});
}


/**
 * setAnnotationMask - Save the visibility (mask_annotation_fg) of an annotation via AJAX.
 * Requires the manage_collection role (enforced server-side).
 * @param annotation_id the numeric primary key of the annotation to update.
 * @param mask_value 0 for Public, 1 for Hidden.
 * @param resultElementId the id of a span element to show status feedback.
 */
function setAnnotationMask(annotation_id, mask_value, resultElementId) {
	var resultEl = document.getElementById(resultElementId);
	if (resultEl) { resultEl.textContent = "Saving..."; }
	jQuery.ajax({
		url: "/annotations/component/functions.cfc",
		type: "post",
		data: {
			method: "setAnnotationMask",
			annotation_id: annotation_id,
			mask_annotation_fg: mask_value,
			returnformat: "json"
		},
		success: function(data) {
			if (resultEl) {
				if (data && data[0] && data[0].status === "updated") {
					resultEl.textContent = "Saved";
				} else {
					resultEl.textContent = "Error";
				}
			}
		},
		error: function(jqXHR, textStatus, error) {
			handleFail(jqXHR, textStatus, error, "setting annotation visibility");
			if (resultEl) { resultEl.textContent = "Error"; }
		}
	});
}

function updateAnnotationReview(annotation_id,reviewed_fg,reviewer_comment,mask_annotation_fg,feedbackDiv,callback=null) { 
	setFeedbackControlState(feedbackDiv,"saving")
	jQuery.ajax({
		dataType: "json",
		url: "/annotations/component/functions.cfc",
		data: { 
			method : "updateAnnotationReview",
			annotation_id : annotation_id,
			reviewed_fg: reviewed_fg,
			reviewer_comment: reviewer_comment,
			mask_annotation_fg: mask_annotation_fg,
			returnformat : "json",
			queryformat : 'column'
		},
		error: function (jqXHR, status, message) {
			handleFail(jqXHR,status,message,"updating annotation review");
			setFeedbackControlState(feedbackDiv,"error")
		},
		success: function (result) {
			if (callback instanceof Function) {
				callback();
			}
			setFeedbackControlState(feedbackDiv,"saved")
		}
	});
}


/** doAnnotationUpdate reads review form field values for a given annotation and
 * calls updateAnnotationReview() to save the review via ajax.
 *
 * @param annotation_id the numeric primary key of the annotation to update.
 */
function doAnnotationUpdate(annotation_id) {
	var reviewed_fg = $("#reviewed_fg_" + annotation_id).val();
	var reviewer_comment = $("#reviewer_comment_" + annotation_id).val();
	var mask_annotation_fg = "";
	var maskEl = document.getElementById("mask_annotation_fg_" + annotation_id);
	if (maskEl) { mask_annotation_fg = maskEl.value; }
	var feedbackDivId = "feedbackDiv_" + annotation_id;
	updateAnnotationReview(annotation_id, reviewed_fg, reviewer_comment, mask_annotation_fg, feedbackDivId, null);
}
