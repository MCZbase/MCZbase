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
			related_id: related_id,
			callback: okcallback
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

/** function deleteMediaRelation unlink a media record from another object
 *  by deleting a record from media_relations
 * 
 * @param media_relations_id the primary key of the media_relations record to delete.
 * @param okcallback a callback function to invoke on success.
 */
function deleteMediaRelation(media_relations_id, okcallback) {
   jQuery.getJSON("/media/component/functions.cfc",
      {
         method : "deleteMediaRelation",
         media_relations_id : media_relations_id,
         returnformat : "json",
         queryformat : 'column'
      },
      function (result) {
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
      }
   ).fail(function(jqXHR,textStatus,error){
      handleFail(jqXHR,textStatus,error,"removing media from transaction record");
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

/** Add a set of fields for entering a media relationship to a form, the fields
  * comprise inputs for relationship__{n}, related_value__{n}, and related_id__{n}
  * in a div with id relationshipDiv__{n}, the div is attached to a specified element
  * in the dom
  *
  * @param n the serial integer that identifies the set of relationship fields.
  * @param targetId the id of the element in the dom to which to attach the created div, 
  *   not including a leading # selector.
  */
function addRelation(n,targetId,buttonId) {
	var pDiv=document.getElementById(targetId);
	var nDiv = document.createElement('div');
	nDiv.classList='form-row col-12 px-0 mx-0 relationshipDiv__' + n;
	pDiv.appendChild(nDiv);
	var n1=n-1;

	var selName='relationship__' + n1;
	var nSel = document.getElementById(selName).cloneNode(true);
	nSel.name="relationship__" + n;
	nSel.id="relationship__" + n;
	nSel.value='';
	nDiv.appendChild(nSel);

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
	nDiv.classList='form-row col-12 px-0 mx-0 labelDiv__' + n;
	pDiv.appendChild(nDiv);
	var n1=n-1;
	var selName='label__' + n1;
	var nSel = document.getElementById(selName).cloneNode(true);
	nSel.name="label__" + n;
	nSel.id="label__" + n;
	nSel.value='';
	nDiv.appendChild(nSel);

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
		makeAgentAutocompleteMeta(dispInputName, idInputName, true);
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

/** Make a text name control into an autocomplete address country/country code picker for searching addresses
 * on selection return the selected text prefixed with an equals sign for exact match.
 *
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 */
function makeAddrCountryCdeAutocomplete(valueControl) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/transactions/component/functions.cfc",
				data: { term: request.term, method: 'getAddrCountryCdeAutocomplete' },
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
			event.preventDefault();
			$('#'+valueControl).val("=" + result.item.value);
		},
		minLength: 2
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta with additional information instead of minimal value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};

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

/** function monitorForChangesGeneric bind a change monitoring function to inputs 
 * on a given form.  Note: text inputs must have type=text to be bound to change function,
 * binds input of type text, checkbox, textarea and select.  
 * @param formId the id of the form, not including the # id selector to monitor.
 * @param changeFunction the function to fire on change events for inputs on the form.
 */
function monitorForChangesGeneric(formId,changeFunction) { 
	$('#'+formId+' input[type=text]').on("change",changeFunction);
	$('#'+formId+' input[type=checkbox]').on("change",changeFunction);
	$('#'+formId+' select').on("change",changeFunction);
	$('#'+formId+' textarea').on("change",changeFunction);
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
function saveEditsFromFormCallback(formId,methodUrl,outputDivId,action,successCallback){ 
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
			if (jQuery.type(successCallback)==='function') {
				successCallback();
			}
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

/** function loadNamedGroupActivityTable populate a table with data entry activity information 
 * about a named group.
 * 
 * @param underscore_collection_id the named group for which to display activity information.
 * @param start_date a date in the form yyyy-mm-dd for the start of the activity to report.
 * @param end_date a date in the form yyyy-mm-dd for the end of the activity to report.
 * @param targetDiv the id for an element in the dom the content of which to replace with the table.
 */
function loadNamedGroupActivityTable(underscore_collection_id, start_date, end_date, targetDiv) {
   jQuery.getJSON("/info/component/activity.cfc",
      {
         method : "getCollObjectActivity",
         underscore_collection_id : underscore_collection_id,
			start_date : start_date,
			end_date : end_date,
         returnformat : "json",
         queryformat : 'column'
      }
	).done(function (result) {
			var table=$('<table>').addClass('table table-responsive table-striped d-lg-table');
			var head=$('<thead>').addClass('thead-light');
			head.append('<tr><th>Cataloged Items Entered</th><th>Part Count</th><th>Georeferences Added</th><th>Verified Georeferences Added</th></tr>');
			table.append(head);
			var body=$('<tbody>');
			for (var i in result) {
				var row = $("<tr>")
				row.append("<td>" + result[i].catitems_entered + "</td>");
				row.append("<td>" + result[i].part_count+ "</td>");
				row.append("<td>" + result[i].georeferences_added + "</td>");
				row.append("<td>" + result[i].verified_georeferences_added + "</td>");
				body.append(row);
         }
			table.append(body);
			$('#'+targetDiv).append(table);
      }
   ).fail(function(jqXHR,textStatus,error){
      handleFail(jqXHR,textStatus,error,"obtaining activity information for a named group.");
   });
}

/** makeCTAutocomplete make an input control into a picker for a code table 
 *  where the code table name matches the field name. 
 *  Intended as a picker for code table controled data entry inputs, clears
 *  the input if the selected value is edited to one not on the list.
 * @param fieldId the id for the input without a leading # selector.
 * @param codetable the name of the codetable and field without a leading CT.
**/
function makeCTAutocomplete(fieldId,codetable) { 
	jQuery("#"+fieldId).autocomplete({
		source: function (request, response) {
			$.ajax({
				url: "/vocabularies/component/search.cfc",
				data: { 
					term: request.term, 
					codetable: codetable, 
					method: 'getCTAutocomplete' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a code table search autocomplete");
				}
			})
		},
		select: function (event, result) {
			event.preventDefault();
			$('#'+fieldId).val(result.item.value);
		},
		change: function(event,ui) { 
			if(!ui.item){
				// handle a change that isn't a selection from the pick list, clear the input
				$('#'+fieldId).val("");
			}
		},
		minLength: 1
	}).autocomplete( "instance" )._renderItem = function( ul, item ) {
		return $("<li>").append( "<span>" + item.value + "</span>").appendTo( ul );
	};
};
/** makeCTAutocompleteColl make an input control into a picker for a code table 
 *  where the code table name matches the field name (some other cases are handled)
 *  and can be limited by collection.  
 *  Intended as a picker for code table controled data entry inputs, clears
 *  the input if the selected value is edited to one not on the list.
 * @param fieldId the id for the input without a leading # selector.
 * @param codetable the name of the codetable and field without a leading CT.
 * @param collection_cde the collection code to limit possible results
**/
function makeCTAutocompleteColl(fieldId,codetable,collection_cde) { 
	jQuery("#"+fieldId).autocomplete({
		source: function (request, response) {
			$.ajax({
				url: "/vocabularies/component/search.cfc",
				data: { 
					term: request.term, 
					codetable: codetable, 
					collection_cde: collection_cde, 
					method: 'getCTAutocomplete' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a code table search autocomplete");
				}
			})
		},
		select: function (event, result) {
			event.preventDefault();
			$('#'+fieldId).val(result.item.value);
		},
		change: function(event,ui) { 
			if(!ui.item){
				// handle a change that isn't a selection from the pick list, clear the input
				$('#'+fieldId).val("");
			}
		},
		minLength: 1
	}).autocomplete( "instance" )._renderItem = function( ul, item ) {
		return $("<li>").append( "<span>" + item.value + "</span>").appendTo( ul );
	};
};

/** makeGeogAutocomplete make an input control into a picker for a geog_auth_rec field of arbitrary rank.
 *  This version of the function returns the value selected from the picklist, and is
 *  intended as a picker for higher geography data entry, it will include meta in the list of options to
 *  pick, but not the selected value.
 * @param fieldId the id for the input without a leading # selector.
 * @param targetRank the geographic rank (field in geog_auth_rec) to bind the autocomplete to.  
**/
function makeGeogAutocomplete(fieldId, targetRank) { 
	jQuery("#"+fieldId).autocomplete({
		source: function (request, response) {
			$.ajax({
				url: "/localities/component/search.cfc",
				data: { term: request.term, method: 'getGeogAutocomplete', rank: targetRank },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a geography search autocomplete");
				}
			})
		},
		select: function (event, result) {
			event.preventDefault();
			$('#'+fieldId).val(result.item.value);
		},
		minLength: 3
	}).autocomplete( "instance" )._renderItem = function( ul, item ) {
		return $("<li>").append( "<span>" + item.value + " (" + item.meta +")</span>").appendTo( ul );
	};
};

/** Make a paired hidden id and text name control into an autocomplete media picker.
 *
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected media_id (without a leading # selector).
 */
function makeEncumbranceAutocompleteMeta(valueControl, idControl) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/specimens/component/functions.cfc",
				data: { term: request.term, method: 'getEncumbranceAutocompleteMeta' },
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


/** opencollectingeventpickerdialog, create and open a dialog to find and link collecting events
 * @param dialogid id to give to the dialog
 * @param header_text human readable text providing the context for the dialog
 * @param collecting_event_id_control the id for an input where the selected collecting_event_id 
 *  should be stored on selection.
 * @param okcallback callback function to invoke on closing dialog
 */
function opencollectingeventpickerdialog(dialogid, header_text, collecting_event_id_control, okcallback) {
	var title = "Change collecting event for " + header_text;
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
			method: "pickCollectingEventHtml",
			returnformat: "plain",
			collecting_event_id_control: collecting_event_id_control,
			callback: okcallback
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
