function getAnnualNums(endDate,beginDate) { 
	jQuery.ajax({
		url: "/metrics/component/functions.cfc",
		data : {
			method : "getAnnualNumbers",
			endDate: endDate,
			beginDate: beginDate,
		},
		success: function (result) {
			$("#annualNumbersDiv").html(result);
		},
		dataType: "html"
	});
}