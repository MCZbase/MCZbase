function getAnnualNumbers(collection_id,targetDivId) { 
	jQuery.ajax({
		url: "/metrics/component/functions.cfc",
		data : {
			method : "getAnnualNumbers",
			collection_id: collection_id,
			endDate: endDate,
			beginDate: beginDate,
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading annual numbers");
		},
		dataType: "html"
	});
};