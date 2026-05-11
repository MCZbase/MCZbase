/** JavaScript functions for handling annotations in MCZbase. **/

jQuery(document).on("click", ".open-reply-annotation-dialog", function() {
	var rootAnnotationId = jQuery(this).attr("data-root-annotation-id");
	return openReplyAnnotationDialog(rootAnnotationId);
});

jQuery(document).on("click", ".open-edit-annotation-dialog", function() {
	var annotationId = jQuery(this).attr("data-edit-annotation-id");
	return openEditResponseAnnotationDialog(annotationId);
});

/** saveThisAnnotation - Save a new annotation via AJAX.
 * Requires user to have a login and have entered name and email.
 * @param feedbackDiv the id of a div element to show status feedback.
 * @param callback optional function to execute on successful save of the annotation.
 * @param idSuffix optional suffix appended to control ids for dialog instance isolation.
 */
function saveThisAnnotation(feedbackDiv,callback=null,idSuffix="") {
	var suffix = (typeof idSuffix === "string" && idSuffix.length > 0) ? idSuffix : "";
	setFeedbackControlState(feedbackDiv,"saving");
	var idType = $("#idtype" + suffix).val();
	var idvalue = $("#idvalue" + suffix).val();
	var annotation = $("#annotation" + suffix).val();
	var motivation = "";
	if ($("#motivation" + suffix).length) { 
		motivation = $("#motivation" + suffix).val();
	}
	if (!annotation || annotation.length==0){
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
	if ($("#mask_annotation_fg" + suffix).length) {
		postData.mask_annotation_fg = $("#mask_annotation_fg" + suffix).val();
	}
	if ($("#root_reviewed_fg" + suffix).length) {
		postData.root_reviewed_fg = $("#root_reviewed_fg" + suffix).val();
	}
	if ($("#root_mask_annotation_fg" + suffix).length) {
		postData.root_mask_annotation_fg = $("#root_mask_annotation_fg" + suffix).val();
	}
	jQuery.ajax({
		url: "/annotations/component/functions.cfc",
		type: "post",
		data: postData,
		success: function(data) {
			messageDialog("<p>Your Annotation has been saved, and the appropriate collections staff will be alerted. Thank you for helping improve MCZbase!</p><p>"+data+"</p><p>You may close the annotation dialog.</p>","Annotation Saved");
			setFeedbackControlState(feedbackDiv,"saved");
			if (typeof callback === "function") {
				callback();
			}
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
			target_id: target_id,
			dialogId: dialogid
		},
		success: function(data) {
			$("#"+dialogid+"_div").html(data);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading annotation dialog");
		}
	});
}

/** Open annotation dialog configured to add a reply to a root annotation.
 * @param rootAnnotationId annotation_id of the root annotation to which to add a reply.
 * @param callback optional function to execute when the dialog closes.
 */
function openReplyAnnotationDialog(rootAnnotationId, callback=null) {
	var parsedRootAnnotationId = parseInt(rootAnnotationId, 10);
	if (!Number.isFinite(parsedRootAnnotationId) || parsedRootAnnotationId <= 0) {
		messageDialog("Unable to open annotation dialog for this reply target.","Reply Annotation");
		return false;
	}
	var dialogId = "annotationDialog_reply_" + String(parsedRootAnnotationId);
	if (!document.getElementById(dialogId)) {
		var dialogElement = document.createElement("div");
		dialogElement.id = dialogId;
		document.body.appendChild(dialogElement);
	}
	openAnnotationsDialog(dialogId, "annotation", parsedRootAnnotationId, callback);
	return true;
}

/** Open annotation dialog configured to review/edit a response annotation.
 * @param annotationId annotation_id of the response annotation to edit.
 * @param callback optional function to execute when the dialog closes.
 */
function openEditResponseAnnotationDialog(annotationId, callback=null) {
	var parsedAnnotationId = parseInt(annotationId, 10);
	if (!Number.isFinite(parsedAnnotationId) || parsedAnnotationId <= 0) {
		messageDialog("Unable to open annotation dialog for this response annotation.","Edit Response Annotation");
		return false;
	}
	var dialogId = "annotationDialog_edit_" + String(parsedAnnotationId);
	if (!document.getElementById(dialogId)) {
		var dialogElement = document.createElement("div");
		dialogElement.id = dialogId;
		document.body.appendChild(dialogElement);
	}
	openAnnotationsDialog(dialogId, "annotation", parsedAnnotationId, callback);
	return true;
}

/** Close a specific annotation dialog by id.
 * @param dialogId html id of the dialog container element.
 */
function closeAnnotationDialogById(dialogId) {
	$("#" + dialogId).dialog("close");
}

/** Save a new reply annotation via AJAX.
 * @param rootAnnotationId annotation_id of the root annotation receiving a new reply annotation.
 * @param rootFeedbackDiv id of element to update with saving/saved/error state.
 * @param callback optional callback after successful save.
 * @param rootState optional state value to apply to the root annotation.
 * @param rootResolution optional resolution value to apply to the root annotation.
 */
function saveReplyAnnotation(rootAnnotationId, rootFeedbackDiv, callback=null, rootState="", rootResolution="") {
	var rootReplyAnnotationFieldId = "root_reply_annotation_" + rootAnnotationId;
	var rootReplyMotivationFieldId = "root_reply_motivation_" + rootAnnotationId;
	var annotation = $("#" + rootReplyAnnotationFieldId).val();
	var motivation = $("#" + rootReplyMotivationFieldId).val();
	if (!annotation || annotation.length === 0) {
		setFeedbackControlState(rootFeedbackDiv,"error");
		messageDialog("You must enter an annotation reply to save.","Reply Required");
		return false;
	}
	if (!motivation || motivation.length === 0) {
		motivation = "commenting";
	}
	if (typeof rootState !== "string") {
		rootState = "";
	}
	if (typeof rootResolution !== "string") {
		rootResolution = "";
	}
	var postData = {
		method: "addAnnotation",
		target_type: "annotation",
		target_id: rootAnnotationId,
		annotation: annotation,
		motivation: motivation,
		returnformat: "json",
		queryformat: "column"
	};
	if (rootState.length > 0) {
		postData.root_state = rootState;
	}
	if (rootResolution.length > 0) {
		postData.root_resolution = rootResolution;
	}
	setFeedbackControlState(rootFeedbackDiv,"saving");
	jQuery.ajax({
		url: "/annotations/component/functions.cfc",
		type: "post",
		data: postData,
		success: function() {
			setFeedbackControlState(rootFeedbackDiv,"saved");
			$("#" + rootReplyAnnotationFieldId).val("");
			if (typeof callback === "function") {
				callback();
			}
		},
		error: function(jqXHR, textStatus, error) {
			setFeedbackControlState(rootFeedbackDiv,"error");
			handleFail(jqXHR,textStatus,error,"saving annotation reply");
		}
	});
	return false;
}

function saveAnnotationReply(rootAnnotationId, rootFeedbackDiv, callback=null, rootState="", rootResolution="") {
	return saveReplyAnnotation(rootAnnotationId, rootFeedbackDiv, callback, rootState, rootResolution);
}


/**
 * setAnnotationMask - Save the visibility (mask_annotation_fg) of an annotation via AJAX.
 * Requires the manage_collection role (enforced server-side).
 * @param annotation_id the numeric primary key of the annotation to update.
 * @param mask_value 0 for Public, 1 for Hidden.
 * @param resultElementId the id of an element to show status feedback, with no leading # selector.
 */
function setAnnotationMask(annotation_id, mask_value, resultElementId) {
	setFeedbackControlState(resultElementId,"saving");
	jQuery.ajax({
		url: "/annotations/component/functions.cfc",
		type: "post",
		dataType: "json",
		data: {
			method: "setAnnotationMask",
			annotation_id: annotation_id,
			mask_annotation_fg: mask_value,
			returnformat: "json"
		},
		success: function(result) {
			var parsed = result;
			if (typeof parsed === "string") {
					parsed = JSON.parse(parsed);
			}
			if (parsed && parsed[0] && parsed[0].status === "updated") {
				setFeedbackControlState(resultElementId,"saved");
			} else {
				setFeedbackControlState(resultElementId,"error");
			}
		},
		error: function(jqXHR, textStatus, error) {
			handleFail(jqXHR, textStatus, error, "setting annotation visibility");
			setFeedbackControlState(resultElementId,"error");
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
			if (typeof callback === "function") {
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
	var reviewer_comment = "";
	var commentEl = document.getElementById("reviewer_comment_" + annotation_id);
	if (commentEl) {
		reviewer_comment = commentEl.value;
	}
	var mask_annotation_fg = "";
	var maskEl = document.getElementById("mask_annotation_fg_" + annotation_id);
	if (maskEl) { mask_annotation_fg = maskEl.value; }
	var feedbackDivId = "feedbackDiv_" + annotation_id;
	updateAnnotationReview(annotation_id, reviewed_fg, reviewer_comment, mask_annotation_fg, feedbackDivId, null);
}
