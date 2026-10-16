//
//	function callCFC() { 
//		// Variables to pass 
//		var beginDate = "2022-06-30"; 
//		var endDate = "2024-06-30"; 
//		// Instantiate CFC 
//		var cfc = new ColdFusion.Component("metrics/component/functions"); 
//		// Call CFC method, pass variables as arguments 
//		var result = cfc.getLoanNumbers(beginDate,endDate); 
//		alert(result);
//	} 

/** Select a fiscal year in the annual report form, setting the hidden begin and end dates
 * that the form submits along with the picklist.
 *
 * @param selectId the id of the fiscal year picklist, without a leading #.
 * @param beginDateId the id of the hidden input for the begin date, without a leading #.
 * @param endDateId the id of the hidden input for the end date, without a leading #.
 * @param beginDate the first day of the fiscal year, yyyy-mm-dd.
 * @param endDate the last day of the fiscal year, yyyy-mm-dd.
 */
function selectFiscalYear(selectId, beginDateId, endDateId, beginDate, endDate) {
	$('#' + selectId).val(beginDate + ',' + endDate);
	$('#' + beginDateId).val(beginDate);
	$('#' + endDateId).val(endDate);
}
