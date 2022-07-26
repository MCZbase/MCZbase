// TODO: Rework 
function saveThisAnnotation() {
	var idType = document.getElementById("idtype").value;
	var idvalue = document.getElementById("idvalue").value;
	var annotation = document.getElementById("annotation").value;
	if (annotation.length==0){
		alert('You must enter an annotation to save.');
		return false;
	}
	jQuery.ajax({
		url: "/annotations/component/functions.cfc",
		type: "post",
		data: {
			method : "addAnnotation",
			target_type : idType,
			target_id : idvalue,
			annotation : annotation,
			returnformat : "json",
			queryformat : 'column'
		},
		success: function(data) {
			messageDialog("<p>Your Annotation has been saved, and the appropriate collections staff will be alerted. Thank you for helping improve MCZbase!</p><p>"+data+"</p><p>You may close the annotation dialog.</p>","Annotation Saved");
		},
		error: function (jqXHR, textStatus, error) {
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

