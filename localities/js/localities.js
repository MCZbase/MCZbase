
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
			if (result[0].STATUS!=1) {
				alert(result[0].MESSAGE);
			}
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"deleting a georeference");
		},
		dataType: "html"
	});
};

// Create and open a dialog to georeference a locality
// @param dialogid the id of a div in the dom that is to be populated with
//  the content of the dialog, without a leading #.
// @param locality_id the locality to which to add a georeference
// @param locality_label a label for the locality to include in the dialog 
//  header and content
// @param callback a function to invoke on closing the dialog.
function openAddGeoreferenceDialog(dialogid, locality_id, locality_label, okcallback) { 
	var title = "Add a georeference for locality " + locality_label;
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
		minWidth: 600,
		minHeight: 500,
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
			locality_label: locality_label
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
	var title = "Add geological attributes to locality. ";
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = $(window).height();
	var w = $(window).width();
	w = Math.floor(w *.9);
	h = Math.floor(h *.5);
	if (h < 500) { h = 500; }
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
		minWidth: 600,
		minHeight: 500,
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
	var title = "Edit geological attribute of locality. ";
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = $(window).height();
	var w = $(window).width();
	w = Math.floor(w *.9);
	h = Math.floor(h *.5);
	if (h < 500) { h = 500; }
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
		minWidth: 600,
		minHeight: 500,
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

function geolocate() {
	var guri="#Application.protocol#://www.geo-locate.org/web/WebGeoreflight.aspx?georef=run";
	guri+="&state=" + $("##state_prov").val();
	guri+="&country="+$("##country").val();
	guri+="&county="+$("##county").val().replace(" County", "");
	guri+="&locality="+$("##spec_locality").val();
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
	$("##popDiv").append(cDiv);
	var hDiv=document.createElement('div');
	hDiv.className = 'fancybox-help';
	hDiv.id='hDiv';
	hDiv.innerHTML='<a href="https://arctosdb.wordpress.com/how-to/create/data-entry/geolocate/" target="blank">[ help ]</a>';
	$("##popDiv").append(hDiv);
	$("##popDiv").append('<img src="/images/loadingAnimation.gif" class="centeredImage">');
	var theFrame = document.createElement('iFrame');
	theFrame.id='theFrame';
	theFrame.className = 'editFrame';
	theFrame.src=guri;
	$("##popDiv").append(theFrame);
}
 
function getGeolocate(evt) {
	if (evt.origin.includes("://mczbase") && evt.data == "") {
		console.log(evt); // Chrome seems to include an extra invocation of getGeolocate from mczbase.
	} else {
		if (evt.origin !== "#Application.protocol#://www.geo-locate.org") {
			console.log(evt);
			alert( "MCZbase error: iframe url does not have permision to interact with me" );
			closeGeoLocate('intruder alert');
		} else {
			var breakdown = evt.data.split("|");
			if (breakdown.length == 4) {
				var glat=breakdown[0];
				var glon=breakdown[1];
				var gerr=breakdown[2];
				console.log(breakdown[3]);
				if (breakdown[3]== "Unavailable")
				{var gpoly='';}
				else
				{var gpoly=breakdown[3].replace(/([^,]*),([^,]*)[,]{0,1}/g,'$2 $1,');}
				useGL(glat,glon,gerr,gpoly)
			} else {
				alert( "MCZbase error: Unable to parse geolocate data. data length=" +  breakdown.length);
				closeGeoLocate('ERROR - breakdown length');
			}
		}
	}
}
     
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
