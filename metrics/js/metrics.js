function loadAnnualNumbers (endDate,beginDate,targetDivId) { 
	jQuery.ajax({
		url: "/metrics/component/functions.cfc",
		data : {
			method : "getAnnualNumbers",
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