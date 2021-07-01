/**
 * Place scripts that should be available only to authenticated users here.
*/

/**
 * Given an url and a window name, either load the url in an existing window of that name, 
 * or open a new window of that name and load the url in that window.
 * 
 * @param url the IRI to load into the window.
 * @param name the name of the window.
 * @param args, if opening a new window the additional arguments to pass to window.open().
 */
function windowOpener(url, name, args) {
	popupWins = [];
	if ( typeof( popupWins[name] ) != "object" ){
		popupWins[name] = window.open(url,name,args);
	} else {
		if (!popupWins[name].closed){
			popupWins[name].location.href = url;
		} else {
			popupWins[name] = window.open(url, name,args);
		}
	}
	popupWins[name].focus();
}
/**
 * Obtain the (internal) MCZbase documentation given a wiki page and heading.
 * 
 * @param url the wiki page name to retrieve
 * @param anc an anchor tag on that wiki page, or null
 *
 */
function getMCZDocs(url,anc) {
	var url;
	var anc;
	var baseUrl = "https://code.mcz.harvard.edu/wiki/index.php/";
	var extension = "";
	var fullURL = baseUrl + url + extension;
	if (anc != null) {
		fullURL += "#" + anc;
	}
	siteHelpWin=windowOpener(fullURL,"HelpWin","width=1024,height=640, resizable,scrollbars,location,toolbar");
}

// Check the validity of a form for submission return true if valid, false if not, and if 
// not valid, popup a message dialog listing the problem form elements and their validation messages.
// @param form DOM node of a form to validate
// @return true if the provided node has checkValidity() of true or if the node lacks the checkValidity method.\
//         false otherwise.
// Example usage in onClick event of a button in a form: if (checkFormValidity($('#formId')[0])) { submit();  }  
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

/** openlinkmediadialog, create and open a dialog to find and link existing media records with a provided relationship
 * @param dialogid id to give to the dialog
 * @param related_value human readable name of the object to link the media to
 * @param related_id primary key valuue of the object to link the media to
 * @param relationship type of relationship to create
 * @param okcallback callback function to invoke on closing dialog
 */
function openlinkmediadialog(dialogid, related_value, related_id, relationship, okcallback) {
	var title = "Link Media record to " + related_value;
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = $(window).height();
	var w = $(window).width();
	w = Math.floor(w *.9);
	var thedialog = $("#"+dialogid).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true, 
		stack: true, 
		zindex: 2000,
		height: h,
		width: w,
		minWidth: 320,
		minHeight: 450,
		draggable:true,
		buttons: {
			"Close Dialog": function() {
				$(this).dialog('close'); 
			}
		}, 
		close: function(event,ui) {
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
			$("#"+dialogid+"_div").html("");
	 		$("#"+dialogid).dialog('destroy');
		}
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/shared/component/functions.cfc",
		type: "post",
		data: {
			method: "linkMediaHtml",
			returnformat: "plain",
			relationship: relationship,
			related_value: related_value,
			related_id: related_id
		},
		success: function (data) {
			$("#"+dialogid+"_div").html(data);
		}, 
		error : function (jqXHR, status, error) {
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

/** opencreatemediadialog Create and open a dialog to create a new media record adding a provided relationship to the media record 
 *
 * @param dialogid id to give to the dialog
 * @param related_value human readable name of the object to link the media to
 * @param related_id primary key valuue of the object to link the media to
 * @param relationship type of relationship to create
 * @param okcallback callback function to invoke on closing dialog, for example to ajax reload a list of linked media objects.
 */
function opencreatemediadialog(dialogid, related_value, related_id, relationship, okcallback) { 
	var title = "Add new Media record to " + related_value;
	console.log("TODO: Redesign opencreatemediadialog()");
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = $(window).height();
	var w = $(window).width();
	w = Math.floor(w *.9);
	var thedialog = $("#"+dialogid).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		zindex: 2000,
		height: h,
		width: w,
		minWidth: 320,
		minHeight: 450,
		draggable:true,
		buttons: {
			"Save Media Record": function(){ 
				if (jQuery.type(okcallback)==='function') {
					if ($('#newMedia')[0].checkValidity()) {
						$.ajax({
							url: '/media/component/functions.cfc',
							type: 'post',
		  					returnformat: 'plain',
							data: $('#newMedia').serialize(),
							success: function(data) { 
								okcallback();
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
					} else { 
						messageDialog('Missing required elements in form.  Fill in all yellow boxes. ','Form Submission Error, missing required values');
					}
				}
			},
			"Close Dialog": function() { 
				$(this).dialog('close'); 
			}
	  },
	  close: function(event,ui) {
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
			if (dialogid.startsWith("addMediaDlg")) { 
				$("#"+dialogid+"_div").remove();
			  	$("#"+dialogid).empty();
			  	$("#"+dialogid).remove();
			} else { 
				$("#"+dialogid+"_div").html("");
				$("#"+dialogid).dialog('destroy');
			}
	 	}
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/shared/component/functions.cfc",
		type: "get",
		data: {
			method: "createMediaHtml",
			returnformat: "plain",
			relationship: relationship,
			related_value: related_value,
			related_id: related_id
		}, 
		success: function (data) { 
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

/** Add a set of fields for entering a media relationship to a form, the fields
  * comprise inputs for relationship__{n}, related_value__{n}, and related_id__{n}
  * in a div with id relationshipDiv__{n}, the div is attached to an element in the
  * dom with id relationships.
  *
  * @param n the serial integer that identifies the set of relationship fields.
  * @depricated
  */
function addRelation (n) {
	addRelationTo(n,"relationships");
}

/** Add a set of fields for entering a media relationship to a form, the fields
  * comprise inputs for relationship__{n}, related_value__{n}, and related_id__{n}
  * in a div with id relationshipDiv__{n}, the div is attached to a specified element
  * in the dom
  *
  * @param n the serial integer that identifies the set of relationship fields.
  * @param targetId the id of the element in the dom to which to attach the created div, 
  *   not including a leading # selector.
  */
function addRelationTo (n,targetId) {
	var pDiv=document.getElementById(targetId);
	var nDiv = document.createElement('div');
	nDiv.id='relationshipDiv__' + n;
	pDiv.appendChild(nDiv);
	var n1=n-1;
	var selName='relationship__' + n1;
	var nSel = document.getElementById(selName).cloneNode(true);
	nSel.name="relationship__" + n;
	nSel.id="relationship__" + n;
	nSel.value='';
	nDiv.appendChild(nSel);

	c = document.createElement("textNode");
	c.innerHTML="";
	nDiv.appendChild(c);

	var n1=n-1;
	var inpName='related_value__' + n1;
	var nInp = document.getElementById(inpName).cloneNode(true);
	nInp.name="related_value__" + n;
	nInp.id="related_value__" + n;
	nInp.value='';
	nDiv.appendChild(nInp);

	var hName='related_id__' + n1;
	var nHid = document.getElementById(hName).cloneNode(true);
	nHid.name="related_id__" + n;
	nHid.id="related_id__" + n;
	nDiv.appendChild(nHid);

	var mS = document.getElementById('addRelationship');
	pDiv.removeChild(mS);
	var np1=n+1;
	var oc="addRelation(" + np1 + ")";
	mS.setAttribute("onclick",oc);
	pDiv.appendChild(mS);

	var cc=document.getElementById('number_of_relations');
	cc.value=parseInt(cc.value)+1;
}


/** Add a set of fields for entering a media label to a form, the fields
  * comprise inputs for label__{n} and label_value__{n}, 
  * in a div with id labelDiv__{n} the div is attached to the element in 
  * the dom with the specified id.
  *
  * @param n the serial integer that identifies the set of label fields.
  * @param targetId the id of the element in the dom to which to attach the created div, 
  *   not including a leading # selector.
  * @param buttonId the id of the add label button in the dom which is linked to this function 
  *   not including a leading # selector.
  */
function addLabelTo (n,targetId,buttonId) {
	// Note: addLabel() conflcits with a name in an included library.
	var pDiv=document.getElementById(targetId);
	var nDiv = document.createElement('div');
	nDiv.id='labelsDiv__' + n;
	pDiv.appendChild(nDiv);
	var n1=n-1;
	var selName='label__' + n1;
	var nSel = document.getElementById(selName).cloneNode(true);
	nSel.name="label__" + n;
	nSel.id="label__" + n;
	nSel.value='';
	nDiv.appendChild(nSel);

	c = document.createElement("textNode");
	c.innerHTML="";
	nDiv.appendChild(c);

	var inpName='label_value__' + n1;
	var nInp = document.getElementById(inpName).cloneNode(true);
	nInp.name="label_value__" + n;
	nInp.id="label_value__" + n;
	nInp.value='';
	nDiv.appendChild(nInp);

	var mS = document.getElementById(buttonId);
	//pDiv.removeChild(mS);
	mS.remove();
	var np1=n+1;
	var oc="addLabelTo(" + np1 + ",\'" +targetId + "\',\'" +buttonId+ "\');";
	mS.setAttribute("onclick",oc);
	pDiv.appendChild(mS);

	var cc=document.getElementById('number_of_labels');
	cc.value=parseInt(cc.value)+1;
}


/** Given the id for a relationship select, set up associated related_id and related_value inputs
  * as pickers for the specified relationship.   Assumes a select element with the id provided in 
  * the id parameter, who's name ends with __{n}, where n is 0 or a positive integer, and corresponding
  * text and hidden imputs with ids related_id__{n} and related_value__{n}.
  *
  <pre>
		<select name="relationship__0" id="relationship__0" class="data-entry-select col-6" size="1"  onchange="pickedRelationship(this.id)">
			...
		</select>
		<input type="text" name="related_value__0" id="related_value__0" class="data-entry-input col-6">
		<input type="hidden" name="related_id__0" id="related_id__0">
  </pre>
  *
  * @param id the id of a select element in the dom that is a media relationship type select where the id ends with __ and 
  * an integer > -1, does not include a leading # selector.  
  */
function pickedRelationship (id){
	var relationship=document.getElementById(id).value;
	var formName=document.getElementById(id).form.getAttribute('name');
	var ddPos = id.lastIndexOf('__');
	var elementNumber=id.substring(ddPos+2,id.length);
	var relatedTableAry=relationship.split(" ");
	var relatedTable=relatedTableAry[relatedTableAry.length-1];
	var idInputName = 'related_id__' + elementNumber;
	var dispInputName = 'related_value__' + elementNumber;
	var hid=document.getElementById(idInputName);
	hid.value='';
	var inp=document.getElementById(dispInputName);
	inp.value='';
	console.log(relatedTable);
	if (relatedTable=='') {
		// do nothing, cleanup already happened
	} else if (relatedTable=='agent'){
		$('#'+dispInputName).attr("readonly", false);
		makeAgentAutocompleteMeta(dispInputName, idInputName);
	} else if (relatedTable=='loan'){
		$('#'+dispInputName).attr("readonly", false);
		makeLoanPicker(dispInputName, idInputName);
	} else if (relatedTable=='permit'){
		$('#'+dispInputName).attr("readonly", false);
		makePermitPicker(dispInputName, idInputName);
	} else if (relatedTable=='accn'){
		$('#'+dispInputName).attr("readonly", false);
		makeAccessionAutocompleteMeta(dispInputName, idInputName);
	} else if (relatedTable=='deaccession'){
		$('#'+dispInputName).attr("readonly", false);
		makeDeaccessionAutocompleteMeta(dispInputName, idInputName);
	} else if (relatedTable=='borrow'){
		$('#'+dispInputName).attr("readonly", false);
		makeBorrowAutocompleteMeta(dispInputName, idInputName);
	} else if (relatedTable=='media'){
		$('#'+dispInputName).attr("readonly", false);
		makeMediaAutocompleteMeta(dispInputName, idInputName);
	} else if (relatedTable=='publication'){
		$('#'+dispInputName).attr("readonly", false);
		makePublicationAutocompleteMeta(dispInputName, idInputName);
	} else if (relatedTable=='cataloged_item'){
		$('#'+dispInputName).attr("readonly", false);
		makeCatalogedItemAutocompleteMeta(dispInputName, idInputName);
	} else if (relatedTable=='locality'){
		$('#'+dispInputName).attr("readonly", false);
		makeLocalityAutocompleteMeta(dispInputName, idInputName);
	} else if (relatedTable=='collecting_event'){
		$('#'+dispInputName).attr("readonly", false);
		makeCollectingEventAutocompleteMeta(dispInputName, idInputName);
	} else if (relatedTable=='taxonomy'){
		$('#'+dispInputName).attr("readonly", false);
		makeScientificNameAutocompleteMeta(dispInputName, idInputName);
	} else if (relatedTable=='project'){
		$('#'+dispInputName).attr("readonly", false);
		makeProjectAutocompleteMeta(dispInputName, idInputName);
	} else if (relatedTable=='delete'){
		$('#'+dispInputName).attr("readonly", true);
		$('#'+dispInputName).value='Marked for deletion.....';
	} else {
		messageDialog('Handling of relationships to ' + relatedTable + ' not yet implemented.',"Error picking relationship type.");
	}
}


/** Make a paired hidden id and text name control into an autocomplete media picker.
 *
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected media_id (without a leading # selector).
 */
function makeMediaAutocompleteMeta(valueControl, idControl) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/media/component/functions.cfc",
				data: { term: request.term, method: 'getMediaAutocomplete' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, status, error) {
					var message = "";
					if (error == 'timeout') { 
						message = ' Server took too long to respond.';
               } else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
                  message = ' Backing method did not return JSON.';
					} else { 
						message = jqXHR.responseText;
					}
					messageDialog('Error:' + message ,'Error: ' + error);
				}
			})
		},
		select: function (event, result) {
			$('#'+idControl).val(result.item.id);
		},
		minLength: 3
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta with additional information instead of minimal value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};

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
 */
function openAnnotationsDialog(dialogid, target_type, target_id) { 
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

function saveEditsFromForm(formId,methodUrl,outputDivId,action){ 
	$('#'+outputDivId).html('Saving....');
	$('#'+outputDivId).addClass('text-warning');
	$('#'+outputDivId).removeClass('text-success');
	$('#'+outputDivId).removeClass('text-danger');
	jQuery.ajax({
		url : methodUrl,
		type : "post",
		dataType : "json",
		data : $('#' + formId).serialize(),
		success : function (data) {
			$('#'+outputDivId).html('Saved.');
			$('#'+outputDivId).addClass('text-success');
			$('#'+outputDivId).removeClass('text-danger');
			$('#'+outputDivId).removeClass('text-warning');
		},
		error: function(jqXHR,textStatus,error){
			$('#'+outputDivId).html('Error.');
			$('#'+outputDivId).addClass('text-danger');
			$('#'+outputDivId).removeClass('text-success');
			$('#'+outputDivId).removeClass('text-warning');
			handleFail(jqXHR,textStatus,error,action);
		}
	});
};
