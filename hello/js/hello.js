/** Functions for hello world page **/

/**  
 * Populate a hello world message section of a page with the current 
 * hello and counter information without incrementing the counter.
 * 
 * @param targetDiv the id, without a leading # selector for the html element
 * to populate with the hello world message.
 
 */
function loadHello(targetDiv, parameter, other_parameter, id_for_counter, id_for_dialog) { 
	console.log("loadHello() called for " + targetDiv);
	jQuery.ajax({
		url: "/hello/component/functions.cfc",
		data : {
			method : "getCounterHtml",
			parameter : parameter, 
			other_parameter : other_parameter,
			id_for_counter : id_for_counter,
			id_for_dialog : id_for_dialog
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
 * Increment all counters and invoke a callback function.
 * 
 * @param callback a callback function to invoke on success.
 */
function incrementCounters(callback) { 
	console.log("incrementCounters() called");
	jQuery.ajax({
		url: "/hello/component/functions.cfc",
		data : {
			method : "incrementAllCounters"
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
		}
	});
};

/**  
 * Increment all counters and update an element in the page.
 * 
 * @param counterElement the id of a element in the dom, the html
 * of which to update with a new value of counter on success, id
 * without a leading # selector.
 * 
 */
function incrementCountersUpdate(counterElement) { 
	console.log("incrementCountersUpdate() called for " + counterElement);
	jQuery.ajax({
		url: "/hello/component/functions.cfc",
		data : {
			method : "incrementAllCounters"
		},
		success: function (result) {
			retval = JSON.parse(result);
			console.log(retval[0].status);
			console.log(retval[0].counter);
			$("#" + counterElement).html(retval[0].counter);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"incrementing hello world counter (2)");
		}
	});
};


/**  
 * Increment a counters and update an element in the page.
 * 
 * @param helloworld_id the row for which to update the counter
 * @param counterElement the id of a element in the dom, the html
 * of which to update with a new value of counter on success, id
 * without a leading # selector.
 * 
 */
function incrementCounterUpdate(counterElement, helloworld_id) { 
	console.log("incrementCounterUpdate() called for " + counterElement);
	console.log(helloworld_id);
	jQuery.ajax({
		url: "/hello/component/functions.cfc",
		data : {
			method : "incrementCounter",
			helloworld_id : helloworld_id
		},
		success: function (result) {
			retval = JSON.parse(result);
			console.log(retval[0].status);
			console.log(retval[0].counter);
			$("#" + counterElement).html(retval[0].counter);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"incrementing hello world counter for single record");
		}
	});
};

/* function openUpdateTextDialog create a dialog using an existing div to update the hello world text. 
 * 
 * @param helloworld_id the id of the cf_helloworld row to update
 * @param dialogId the id, without a leading # selector, of the div that is to contain the dialog.
 */
function openUpdateTextDialog(helloworld_id, dialogId) { 
	console.log("openUpdateTextDialog called");
	console.log(helloworld_id);
	console.log(dialogId);
	var title = "Update Hello World Text.";
	var content = '<div id="'+dialogId+'_div">Loading....</div>';
	var thedialog = $("#"+dialogId).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		minWidth: 320,
		minHeight: 200,
		draggable:true,
		buttons: {
			"Close Dialog": function() {
				console.log("close dialog clicked");
				$("#"+dialogId).dialog('close');
				doReload(); 
			}
		},
		open: function (event, ui) {
			console.log("close dialog open event");
			// force the dialog to lay above any other elements in the page.
			var maxZindex = getMaxZIndex();
			$('.ui-dialog').css({'z-index': maxZindex + 6 });
			$('.ui-widget-overlay').css({'z-index': maxZindex + 5 });
		},
		close: function(event,ui) {
			console.log("close dialog close event");
			$("#"+dialogId+"_div").html("");
			$("#"+dialogId).dialog('destroy');
		}
	});
	thedialog.dialog('open');
	jQuery.ajax({
		console.log("requesting dialog data");
		url: "/hello/component/functions.cfc",
		type: "post",
		data: {
			method: 'getHtml',
			returnformat: "plain",
			transaction_id: transaction_id
		},
		success: function(data) {
			console.log("dialog data returned, populating dialog div");
			$("#"+dialogId+"_div").html(data);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"populating edit text dialog for hello world");
		}
	});
}
