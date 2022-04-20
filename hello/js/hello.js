/** Functions for hello world page **/

/**  
 * Populate a hello world message section of a page with the current 
 * hello and counter information without incrementing the counter.
 * 
 * @param targetDiv the id, without a leading # selector for the html element
 * to populate with the hello world message.
 
 */
function loadHello(targetDiv, parameter, other_parameter, id_for_counter) { 
	console.log("loadHello() called for " + targetDiv);
	jQuery.ajax({
		url: "/hello/component/functions.cfc",
		data : {
			method : "getCounterHtml",
			parameter : parameter, 
			other_parameter : other_parameter,
			id_for_counter : id_for_counter
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
 * Increment a counter and invoke a callback function.
 * 
 * @param callback a callback function to invoke on success.
 */
function incrementCounter(callback) { 
	console.log("incrementCounter() called");
	jQuery.ajax({
		url: "/hello/component/functions.cfc",
		data : {
			method : "incrementCounter"
		},
		success: function (result) {
			retval = JSON.parse(result);
			console.log(retval[0].status);
			console.log(retval[0].counter);
			if (jQuery.type(callback)==='function') {
				callback();
			}
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"incrementing hello world counter (1)");
		},
		dataType: "html"
	});
};

/**  
 * Increment a counter and update an element in the page.
 * 
 * @param counterElement the id of a element in the dom, the html
 * of which to update with a new value of counter on success, id
 * without a leading # selector.
 * 
 */
function incrementCounterUpdate(counterElement) { 
	console.log("incrementCounterUpdate() called for " + counterElement);
	jQuery.ajax({
		url: "/hello/component/functions.cfc",
		data : {
			method : "incrementCounter"
		},
		success: function (result) {
			retval = JSON.parse(result);
			console.log(retval[0].status);
			console.log(retval[0].counter);
			$("#" + counterElement).html(retval[0].counter);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"incrementing hello world counter (2)");
		},
		dataType: "html"
	});
};
