function getMetrics(targetDiv) { 
	console.log("Where is it? " + targetDiv);
	jQuery.ajax({
		url: "/metrics/component/functions.cfc",
		data : {
			method : "getMetrics",
	
		},
		success: function (result) {
			$("#" + targetDiv).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"retrieving metadata block");
		},
		dataType: "html"
	});
};