/** Functions related to specimens used on any /specimens/ page */

/** Functions for loading result set summary information */

/** Load information about georeferences in a result set into a target div.
*/
function loadCatalogedItemCount (result_id,targetDivId,prefix,suffix) { 
	jQuery.ajax({
		url: "/specimens/component/manage.cfc",
		data : {
			method : "getCatalogedItemCount",
			result_id: result_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(prefix + result + suffix);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading catalogedItem count");
		},
		dataType: "html"
	});
};

/** Load information about georeferences in a result set into a target div.
*/
function loadGeoreferenceSummaryHTML (result_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/manage.cfc",
		data : {
			method : "getGeoreferenceSummaryHTML",
			result_id: result_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading georeference summary");
		},
		dataType: "html"
	});
};

/** Load information about georeferences in a result set into a target div.
*/
function loadGeoreferenceCount (result_id,targetDivId,prefix,suffix) { 
	jQuery.ajax({
		url: "/specimens/component/manage.cfc",
		data : {
			method : "getGeoreferenceCount",
			result_id: result_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(prefix + result + suffix);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading georeference count");
		},
		dataType: "html"
	});
};

/** Load information about collections in a result set into a target div.
*/
function loadCollectionsSummaryHTML (result_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/manage.cfc",
		data : {
			method : "getCollectionsSummaryHTML",
			result_id: result_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading collections summary");
		},
		dataType: "html"
	});
};

/** Load information about catalog number prefixes in a result set into a target div.
*/
function loadPrefixesSummaryHTML (result_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/manage.cfc",
		data : {
			method : "getPrefixesSummaryHTML",
			result_id: result_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading prefix summary");
		},
		dataType: "html"
	});
};

/** Load information about countries in a result set into a target div.
*/
function loadCountriesSummaryHTML (result_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/manage.cfc",
		data : {
			method : "getCountriesSummaryHTML",
			result_id: result_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading country summary");
		},
		dataType: "html"
	});
};

/** Load information about families in a result set into a target div.
*/
function loadFamiliesSummaryHTML (result_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/manage.cfc",
		data : {
			method : "getFamiliesSummaryHTML",
			result_id: result_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading family summary");
		},
		dataType: "html"
	});
};


/** Load information about accessions in a result set into a target div.
*/
function loadAccessionsSummaryHTML (result_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/manage.cfc",
		data : {
			method : "getAccessionsSummaryHTML",
			result_id: result_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading accession summary");
		},
		dataType: "html"
	});
};

/** Load information about localities in a result set into a target div.
*/
function loadLocalitiesSummaryHTML (result_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/manage.cfc",
		data : {
			method : "getLocalitiesSummaryHTML",
			result_id: result_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading locality summary");
		},
		dataType: "html"
	});
};


/** Load information about collecting events in a result set into a target div.
*/
function loadCollEventsSummaryHTML (result_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/manage.cfc",
		data : {
			method : "getCollEventsSummaryHTML",
			result_id: result_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading collecting event summary");
		},
		dataType: "html"
	});
};

/** Load information about parts in a result set into a target div.
*/
function loadPartsSummaryHTML (result_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/manage.cfc",
		data : {
			method : "getPartsSummaryHTML",
			result_id: result_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading part summary");
		},
		dataType: "html"
	});
};

/** Load information about parts in a result set into a target div.
*/
function loadPreservationsSummaryHTML (result_id,targetDivId) { 
	jQuery.ajax({
		url: "/specimens/component/manage.cfc",
		data : {
			method : "getPreservationsSummaryHTML",
			result_id: result_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading preserve type summary");
		},
		dataType: "html"
	});
};

/** Create a dialog for displaying container placement of a specimen part. 
  * 
  * @param collection_object_id the specimen part for which to retrieve the container placement.
  * @param dialogid the id of the div that is to contain the dialog, without a leading # selector.
  */
function openPartContainersDialog(collection_object_id, dialogid) { 
	var title = "Part Container Placement";
	console.log(dialogid);
	var dialogElement = $("#" + dialogid);

	// Check if dialog already exists and close it first if it does
	if (dialogElement.hasClass('ui-dialog-content')) {
		try {
			dialogElement.dialog('close');
			dialogElement.dialog('destroy');
		} catch (e) {}
	}

	var content = '<div id="'+dialogid+'_div" class="col-12 px-1 px-xl-2">Loading....</div>';
	var thedialog = dialogElement.html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'ui-widget-header left-3',
		modal: false,
		stack: true,
		height: 'auto',
		width: 'auto',
		maxWidth: 600,
		minHeight: 500,
		draggable:true,
		buttons: {
			"Close Dialog": function() {
				$(this).dialog('close');
			}
		},
		open: function (event, ui) {
			if (typeof(getMaxZIndex) === "function") { 
				// force the dialog to lay above any other elements in the page.
				var maxZindex = getMaxZIndex();
				$('.ui-dialog').css({'z-index': maxZindex + 6 });
				$('.ui-widget-overlay').css({'z-index': maxZindex + 5 });
			}; 
		},
		close: function(event,ui) {
			setTimeout(function() { 
				$("#"+dialogid+"_div").html("");
			}, 100);
			try {  
				$("#"+dialogid).dialog('destroy');
			} catch (e) {} 
		}
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		type: "get",
		data: {
			method: "getPartContainersHTML",
			returnformat: "plain",
			collection_object_id: collection_object_id
		},
		success: function(data) {
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
