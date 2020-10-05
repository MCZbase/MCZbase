/**
 * Place scripts that should be available on all web pages for all coldfusion users here.
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
	if (relatedTable=='') {
		// do nothing, cleanup already happened
	} else if (relatedTable=='agent'){
		makeAgentPicker(dispInputName, idInputName) { 
	} else if (relatedTable=='locality'){
		LocalityPick(idInputName,dispInputName,formName);
	} else if (relatedTable=='collecting_event'){
		findCollEvent(idInputName,formName,dispInputName);
	} else if (relatedTable=='cataloged_item'){
		findCatalogedItem(idInputName,dispInputName,formName);
	} else if (relatedTable=='project'){
		getProject(idInputName,dispInputName,formName);
	} else if (relatedTable=='taxonomy'){
		taxaPick(idInputName,dispInputName,formName);
	} else if (relatedTable=='publication'){
		getPublication(dispInputName,idInputName,'',formName);
	} else if (relatedTable=='accn'){
		getAccn(dispInputName,idInputName,formName);
	} else if (relatedTable=='deaccession'){
		getDeaccession(dispInputName,idInputName,formName);
	} else if (relatedTable=='permit'){
		getPermit(dispInputName,idInputName,formName);
	} else if (relatedTable=='loan'){
		getLoan(dispInputName,idInputName,formName);
	//  } else if (relatedTable=='borrow'){
		// TODO: Implement a borrow picker
		// getBorrow(dispInputName,idInputName,formName);
	} else if (relatedTable=='media'){
		findMedia(dispInputName,idInputName);
	} else if (relatedTable=='delete'){
		document.getElementById(dispInputName).value='Marked for deletion.....';
	} else {
		messageDialog('Handling of relationships to ' + relatedTable + ' not yet implemented.',"Error picking relationship type.");
	}
}
