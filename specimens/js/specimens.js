/** Functions related to specimens used on any /specimens/ page */

/** Functions for loading result set summary information */

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
