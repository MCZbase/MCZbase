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

function getLoans() {
// Create CFC object
var cfc = new ActiveXObject("functions");
// Call function
cfc.getLoanNumbers();
// Update page element
document.getElementById("loanresult").innerHTML = "";
}

function getCitations() {
// Create CFC object
var cfc = new ActiveXObject("functions");
// Call function
cfc.getCitationNumbers();
// Update page element
document.getElementById("citationresult").innerHTML = "";
}