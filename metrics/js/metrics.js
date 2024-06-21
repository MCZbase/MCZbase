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

function callCFCFunction1() {

  // Create XMLHttpRequest object
  var xhr = new XMLHttpRequest();

  // Call CFC function via AJAX
  xhr.open('GET', '/metrics/component/functions.cfc?method=getLoanNumbers&beginDate=#beginDate#&endDate=#endDate#'); 
  xhr.send();

  // Handle response
  xhr.onload = function() {
    if (xhr.status === 200) {
      document.getElementById("loanresult").innerHTML = "loan results"; 
    }
  }

}