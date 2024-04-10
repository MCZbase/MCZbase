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

