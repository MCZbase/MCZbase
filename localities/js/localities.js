
/** given a geog_auth_rec_id, look up a plausible value for sovereign nation
 and paste it into a control.
 @param geog_auth_rec_id the higher geography record from which to suggest 
   a sovereign nation value based on the country in the higher geography.
 @param pasteTarget the id in the dom, without a leading pound selector
   into which to paste the suggestion if any.
**/
function suggestSovereignNation(geog_auth_rec_id, pasteTarget) {
   jQuery.getJSON("/localities/component/search.cfc",
      {
         method : "suggestSovereignNation",
         geog_auth_rec_id : geog_auth_rec_id,
         returnformat : "json",
         queryformat : 'column'
      },
      function (result) {
			console.log(result);
			if (result && result[0]) { 
				var suggestion = result[0].id;
				console.log(suggestion);
				if (suggestion) { 
					$("#"+pasteTarget).val(suggestion);
				}
			}
      }
   ).fail(function(jqXHR,textStatus,error){
      handleFail(jqXHR,textStatus,error,"looking up sovereign nation from higher geography");
   });
}

/** given a locality_id, look up the uses for the locality
 determine if it can be deleted, and present either a delete 
 button or a message.
 @param locality_id the locality to look up.
 @param pasteTarget the id in the dom, without a leading pound selector
   the content of which to replace with the returned uses.
**/
function updateLocalityDeleteBit(locality_id,pasteTarget) {
	jQuery.ajax({
		url: "/localities/component/functions.cfc",
		data : {
			method : "getLocalityDeleteBitHtml",
			locality_id: locality_id
		},
		success: function (result) {
			$("#"+pasteTarget).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"obtaining delete button or message for a locality");
		},
		dataType: "html"
	});
};

/** given a locality_id, look up the uses for the locality
 and set it as the content of a target div.
 @param locality_id the locality to look up.
 @param pasteTarget the id in the dom, without a leading pound selector
   the content of which to replace with the returned uses.
**/
function updateLocalityUses(locality_id,pasteTarget) {
	jQuery.ajax({
		url: "/localities/component/public.cfc",
		data : {
			method : "getLocalityUsesHtml",
			locality_id: locality_id
		},
		success: function (result) {
			$("#"+pasteTarget).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"obtaining uses for a locality");
		},
		dataType: "html"
	});
};

/** given a locality_id, look up the summary for the locality
 and set it as the content of a target div.
 @param locality_id the locality to look up.
 @param pasteTarget the id in the dom, without a leading pound selector
   the content of which to replace with the returned summary.
**/
function updateLocalitySummary(locality_id,pasteTarget) {
	jQuery.ajax({
		url: "/localities/component/search.cfc",
		data : {
			method : "getLocalitySummary",
			locality_id: locality_id
		},
		success: function (result) {
			$("#"+pasteTarget).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"obtaining summary for a locality");
		},
		dataType: "html"
	});
};

/** given a locality_id lookup the media for a locality and
 set the returned html as the content of a target div.
 @param locality_id the locality to look up the media for.
*/
function loadLocalityMediaHTML(locality_id,targetDivId) { 
	jQuery.ajax({
		url: "/localities/component/public.cfc",
		data : {
			method : "getLocalityMediaHtml",
			locality_id: locality_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading media for locality");
		},
		dataType: "html"
	});
};

/** given a locality_id lookup the map for a locality and
 set it as the content of a target div, assumes reload of
 existing map.
 @param locality_id the locality to look up.
*/
function loadLocalityMapHTML(locality_id,targetDivId) { 
	jQuery.ajax({
		url: "/localities/component/public.cfc",
		data : {
			method : "getLocalityMapHtml",
			locality_id: locality_id,
			reload : "true"
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading map for locality");
		},
		dataType: "html"
	});
};

/** given a locality_id lookup the geological attributes for a locality and
 set the returned html as the content of a target div.
 @param locality_id the locality to look up.
 @param callback_name the name of a callback function that can be passed
   to actions within the returned html.
*/
function loadGeologyHTML(locality_id,targetDivId, callback_name) { 
	jQuery.ajax({
		url: "/localities/component/functions.cfc",
		data : {
			method : "getLocalityGeologyHtml",
			locality_id: locality_id,
			callback_name: callback_name
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading geological attributes for locality");
		},
		dataType: "html"
	});
};

/** given a locality_id lookup the georeferences for a locality and
 set the returned html as the content of a target div.
 @param locality_id the locality to look up georeferences for.
 @param callback_name the name of a callback function that can be passed
   to actions within the returned html.
*/
function loadGeoreferencesHTML(locality_id,targetDivId, callback_name) { 
	jQuery.ajax({
		url: "/localities/component/functions.cfc",
		data : {
			method : "getLocalityGeoreferencesHtml",
			locality_id: locality_id,
			callback_name: callback_name
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading georeferences for locality");
		},
		dataType: "html"
	});
};

/** given a locality_id and lat_long_id, attempt to delete the georeference.
 @param locality_id the locality for the georeference to delete
 @param lat_long_id the primary key value for the georeference to delete
 @param callback a callback function to invoke on success.
**/
function deleteGeoreference(locality_id, lat_long_id,callback) {
	jQuery.ajax({
		url: "/localities/component/functions.cfc",
		data : {
			method : "deleteGeoreference",
			locality_id: locality_id,
			lat_long_id: lat_long_id
		},
		success: function (result) {
			if (jQuery.type(callback)==='function') {
				callback();
			}
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"deleting a georeference");
		},
		dataType: "html"
	});
};

// Create and open a dialog to edit a georeference for a locality
// @param dialogid the id of a div in the dom that is to be populated with
//  the content of the dialog, without a leading #.
// @param lat_long_id the lat_long to edit.
// @param callback a function to invoke on closing the dialog.
function openEditGeorefDialog(lat_long_id, dialogid, callback) { 
	var title = "Edit georeference for locality";
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	$("#georeferenceDialogFeedback").html('&nbsp;');
	var h = $(window).height();
	var w = $(window).width();
	w = Math.floor(w *.9);
	h = Math.floor(h *.9);
	if (h<750) { h = 750; }
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
		minWidth: 300,
		minHeight: 750,
		draggable:true,
		buttons: {
			"Close Dialog": function() { 
				$("#"+dialogid).dialog('close'); 
			}
		},
		close: function(event,ui) { 
			if (jQuery.type(callback)==='function') {
				callback();
	  		}
			$("#"+dialogid+"_div").html("");
			$("#"+dialogid).dialog('destroy'); 
		} 
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/localities/component/functions.cfc",
		type: "post",
		data: {
			method: "editGeoreferenceDialogHtml",
			returnformat: "plain",
			lat_long_id: lat_long_id
		}, 
		success: function (data) { 
			$("#"+dialogid+"_div").html(data);
		}, 
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading edit georeference dialog");
		}
	});
}

// Create and open a dialog to georeference a locality
// @param dialogid the id of a div in the dom that is to be populated with
//  the content of the dialog, without a leading #.
// @param locality_id the locality to which to add a georeference
// @param callback a function to invoke on closing the dialog.
// @param geolocateImmediate optional if yes, immediately invoke GeoLocate on opening the dialog.
function openAddGeoreferenceDialog(dialogid, locality_id, okcallback, geolocateImmediate='no') { 
	var title = "Add a georeference for locality";
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	$("#georeferenceDialogFeedback").html('&nbsp;');
	var h = $(window).height();
	var w = $(window).width();
	w = Math.floor(w *.9);
	h = Math.floor(h *.9);
	if (h<750) { h=750; }
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
		minWidth: 300,
		minHeight: 750,
		draggable:true,
		buttons: {
			"Close Dialog": function() { 
				$("#"+dialogid).dialog('close'); 
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
		url: "/localities/component/functions.cfc",
		type: "post",
		data: {
			method: "georeferenceDialogHtml",
			returnformat: "plain",
			locality_id: locality_id,
			geolocateImmediate: geolocateImmediate
		}, 
		success: function (data) { 
			$("#"+dialogid+"_div").html(data);
		}, 
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading add georeference dialog");
		}
	});
}

// Create and open a dialog to add geological attributes to a locality
// @param locality_id the locality to which to add geological attributes
// @param dialogid the id of a div in the dom that is to be populated with
//  the content of the dialog, without a leading #.
// @param callback a function to invoke on closing the dialog.
function openAddGeologyDialog(locality_id, dialogid, callback) { 
	var title = "Add geological attributes to locality ";
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = $(window).height();
	var w = $(window).width();
	w = Math.floor(w *.9);
	h = Math.floor(h *.5);
	if (h < 600) { h = 600; }
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
		minWidth: 300,
		minHeight: 600,
		draggable:true,
		buttons: {
			"Close Dialog": function() { 
				$("#"+dialogid).dialog('close'); 
			}
		},
		close: function(event,ui) { 
			if (jQuery.type(callback)==='function') {
				callback();
	  		}
			$("#"+dialogid+"_div").html("");
			$("#"+dialogid).dialog('destroy'); 
		} 
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/localities/component/functions.cfc",
		type: "post",
		data: {
			method: "geologyAttributeDialogHtml",
			returnformat: "plain",
			locality_id: locality_id
		}, 
		success: function (data) { 
			$("#"+dialogid+"_div").html(data);
		}, 
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading add geology attribute dialog");
		}
	});
}
// Create and open a dialog to edit geological attributes for a locality
// @param geology_attribute_id the geological attribute to edit
// @param locality_id the locality to which to add geological attributes
// @param dialogid the id of a div in the dom that is to be populated with
//  the content of the dialog, without a leading #.
// @param callback a function to invoke on closing the dialog.
function openEditGeologyDialog(geology_attribute_id, locality_id, dialogid, callback) { 
	var title = "Edit geological attribute of locality";
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = $(window).height();
	var w = $(window).width();
	w = Math.floor(w *.9);
	h = Math.floor(h *.5);
	if (h < 600) { h = 600; }
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
		minWidth: 300,
		minHeight: 600,
		draggable:true,
		buttons: {
			"Close Dialog": function() { 
				$("#"+dialogid).dialog('close'); 
			}
		},
		close: function(event,ui) { 
			if (jQuery.type(callback)==='function') {
				callback();
	  		}
			$("#"+dialogid+"_div").html("");
			$("#"+dialogid).dialog('destroy'); 
		} 
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/localities/component/functions.cfc",
		type: "post",
		data: {
			method: "geologyAttributeEditDialogHtml",
			returnformat: "plain",
			geology_attribute_id: geology_attribute_id,
			locality_id: locality_id
		}, 
		success: function (data) { 
			$("#"+dialogid+"_div").html(data);
		}, 
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading edit geology attribute dialog");
		}
	});
}

/** given a geology_attribute_id delete the geology attribute record 
  removingthe reference to a geological attribute from a locality.
 @param geology_attribute_id the primary key value for the geological 
  attribute to delete.
 @param locality_id the locality from which to remove the geological
  attribute as a crosscheck.
 @param callback a callback function to invoke on success.
**/
function removeGeologyAttribute(geology_attribute_id, locality_id, callback) { 
	jQuery.ajax({
		url: "/localities/component/functions.cfc",
		data : {
			method : "deleteGeologyAttribute",
			locality_id: locality_id,
			geology_attribute_id: geology_attribute_id
		},
		success: function (result) {
			if (jQuery.type(callback)==='function') {
				callback();
			}
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"deleting a geological attribute");
		},
		dataType: "html"
	});
};

/* function geolocate 
  create an iframe in a dialog and open a link to geolocate's web application in it.
  @param protocol http or https to request geolocate with the same protocol as the requesting page.
*/
function geolocate(protocol) {
	var guri=protocol+"://www.geo-locate.org/web/WebGeoreflight.aspx?georef=run";
	guri+="&state=" + $("#state_prov").val();
	guri+="&country="+$("#country").val();
	guri+="&county="+$("#county").val().replace(" County", "");
	guri+="&locality="+$("#spec_locality").val();
	var bgDiv = document.createElement('div');
	bgDiv.id = 'bgDiv';
	bgDiv.className = 'bgDiv';
	bgDiv.setAttribute('onclick','closeGeoLocate("clicked closed")');
	document.body.appendChild(bgDiv);
	var popDiv=document.createElement('div');
	popDiv.id = 'popDiv';
	popDiv.className = 'editAppBox';
	document.body.appendChild(popDiv);
	var cDiv=document.createElement('div');
	cDiv.className = 'fancybox-close';
	cDiv.id='cDiv';
	cDiv.setAttribute('onclick','closeGeoLocate("clicked closed")');
	$("#popDiv").append(cDiv);
	var hDiv=document.createElement('div');
	hDiv.className = 'fancybox-help';
	hDiv.id='hDiv';
	hDiv.innerHTML='<a href="https://arctosdb.wordpress.com/how-to/create/data-entry/geolocate/" target="blank">[ help ]</a>';
	$("#popDiv").append(hDiv);
	$("#popDiv").append('<img src="/images/loadingAnimation.gif" class="centeredImage">');
	var theFrame = document.createElement('iFrame');
	theFrame.id='theFrame';
	theFrame.className = 'editFrame';
	theFrame.src=guri;
	$("#popDiv").append(theFrame);
}
 
/** close the geolocate dialog holding the iframe for geolocate 
**/
function closeGeoLocate(msg) {
	$('#bgDiv').remove();
	$('#bgDiv', window.parent.document).remove();
	$('#popDiv').remove();
	$('#popDiv', window.parent.document).remove();
	$('#cDiv').remove();
	$('#cDiv', window.parent.document).remove();
	$('#theFrame').remove();
	$('#theFrame', window.parent.document).remove();
}

// Create and open a dialog to add collecting event numbers to a collecting event
// @param collecting_event_id the collecting event for which to add numbers
// @param dialogid the id of a div in the dom that is to be populated with
//  the content of the dialog, without a leading #.
// @param callback a function to invoke on closing the dialog.
function openAddCollEventNumberDialog(collecting_event_id, dialogid, callback) { 
	var title = "Add collecting event numbers to a collecting event";
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = $(window).height();
	var w = $(window).width();
	w = Math.floor(w *.9);
	h = Math.floor(h *.3);
	if (h < 325) { h = 325; }
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
		minWidth: 300,
		minHeight: 600,
		draggable:true,
		buttons: {
			"Close Dialog": function() { 
				$("#"+dialogid).dialog('close'); 
			}
		},
		close: function(event,ui) { 
			if (jQuery.type(callback)==='function') {
				callback();
	  		}
			$("#"+dialogid+"_div").html("");
			$("#"+dialogid).dialog('destroy'); 
		} 
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/localities/component/functions.cfc",
		type: "post",
		data: {
			method: "getAddCollEventNumberDialogHtml",
			returnformat: "plain",
			collecting_event_id: collecting_event_id
		}, 
		success: function (data) { 
			$("#"+dialogid+"_div").html(data);
		}, 
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading add collecting event number dialog");
		}
	});
}
