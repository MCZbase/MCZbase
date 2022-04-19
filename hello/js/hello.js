/** Functions for hello world page **/

/**  
 * Populate a hello world message section of a page with the current 
 * hello and counter information without incrementing the counter.
 * 
 * @param targetDiv the id, without a leading # selector for the html element
 * to populate with the hello world message.
 */
function loadHello(targetDiv, parameter, other_parameter) { 
	console.log("loadHello() called for " + targetDiv);
	jQuery.ajax({
		url: "/hello/component/functions.cfc",
		data : {
			method : "getCounterHtml",
			parameter : parameter, 
			other_parameter : other_parameter
		},
		success: function (result) {
			$("#" + targetDiv).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"retrieving hello world data");
		},
		dataType: "html"
	});
};


/**  
 * Populate a hello world message section of a page with the current 
 * hello and counter information without incrementing the counter.
 * 
 * @param targetDiv the id, without a leading # selector for the html element
 * to populate with the hello world message.
 */
function incrementCounter(callback) { 
	console.log("incrementCounter() called");
	jQuery.ajax({
		url: "/hello/component/functions.cfc",
		data : {
			method : "incrementCounterHtml"
		},
		success: function (result) {
			console.log(result[0].counter);
			if (jQuery.type(callback)==='function') {
				callback();
			}
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"incrementing hello world counter);
		},
		dataType: "html"
	});
};
