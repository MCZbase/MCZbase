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

function getLoanNums() {

// Create CFC object
var cfc = new ActiveXObject("functions");

// Call function
cfc.getLoanNumbers();

// Update page element
document.getElementById("#loanDiv").innerHTML = "Function ran";

}