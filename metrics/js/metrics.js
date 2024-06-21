
	function callCFC() { 
		// Variables to pass 
		var beginDate = "2022-06-30"; 
		var endDate = "2024-06-30"; 
		// Instantiate CFC 
		var cfc = new ColdFusion.Component("metrics/component/functions.CFC"); 
		// Call CFC method, pass variables as arguments 
		var result = cfc.getLoanNumbers(beginDate,endDate); 
		alert(result);
	} 
