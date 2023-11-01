// Functions related to editing collecting events

/** deleteCollEventNumber give an collecting event number, delete
  that record.
  Assumes the presence of a collEventNumber_{id} id in the DOM 
   for feedback.
  @param id the coll_event_number_id identifying the collecting 
    event number to delete.
*/
function deleteCollEventNumber(id) {
	$('#collEventNumber_' + id ).append('Deleting...');
	$.ajax({
		url : "/localities/component/functions.cfc",
		type : "post",
		dataType : "json",
		data : {
			method: "deleteCollEventNumber",
			returnformat: "json",
			coll_event_number_id: id
		},
		success : function (data) {
			$('#collEventNumber_' + id ).html('Deleted.');
		},
		error: function(jqXHR,textStatus,error){
			$('#collEventNumber_' + id ).append('Error.');
			var message = "";
			if (error == 'timeout') {
				message = ' Server took too long to respond.';
			} else {
				message = jqXHR.responseText;
			}
			messageDialog('Error deleting collecting event number: '+message, 'Error: '+error);
		}
	});
};
/** given a collecting_event_id, attempt to delete the collecting_event.
 @param collecting_event_id the collecting_event to delete
 @param callback a callback function to invoke on success.
**/
function deleteCollectingEvent(collecting_event_id, callback) {
	jQuery.ajax({
		url: "/localities/component/functions.cfc",
		data : {
			method : "deleteCollectingEvent",
			collecting_event_id: collecting_event_id
		},
		success: function (result) {
			if (jQuery.type(callback)==='function') {
				callback();
			}
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"deleting a collecting event");
		},
		dataType: "html"
	});
};
/** function monitorForChanges bind a change monitoring function to inputs 
 * on a given form.  Note: text inputs must have type=text to be bound to change function.
 * @param formId the id of the form, not including the # id selector to monitor.
 * @param changeFunction the function to fire on change events for inputs on the form.
 */
function monitorForChanges(formId,changeFunction) { 
	$('#'+formId+' input[type=text]').on("change",changeFunction);
	$('#'+formId+' input[type=checkbox]').on("change",changeFunction);
	$('#'+formId+' select').on("change",changeFunction);
	$('#'+formId+' textarea').on("change",changeFunction);
}
/** given a collecting_event_id lookup the media for a locality and
 set the returned html as the content of a target div.
 @param collecting_event_id the locality to look up the media for.
*/
function loadCollEventMediaHTML(collecting_event_id,targetDivId) { 
	jQuery.ajax({
		url: "/localities/component/public.cfc",
		data : {
			method : "getCollectingEventMediaHtml",
			collecting_event_id: collecting_event_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading media for collecting event");
		},
		dataType: "html"
	});
};
/** given a collecting_event_id lookup the summary for a collecting event and
 set the returned html as the content of a target div.
 @param collecting_event_id the collecting event to look up the summary for.
*/
function loadCollEventSummaryHTML(collecting_event_id,targetDivId) { 
	jQuery.ajax({
		url: "/localities/component/public.cfc",
		data : {
			method : "getCollectingEventSummary",
			collecting_event_id: collecting_event_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading summary for collecting event");
		},
		dataType: "html"
	});
};
/** given a collecting_event_id lookup the numbers for a collecting eventand
 set the returned html as the content of a target div.
 @param collecting_event_id the collecting event to look up the numbers for.
*/
function loadCollEventNumbersHTML(collecting_event_id,targetDivId) { 
	jQuery.ajax({
		url: "/localities/component/functions.cfc",
		data : {
			method : "getEditCollectingEventNumbersHtml",
			collecting_event_id: collecting_event_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading numbers for collecting event");
		},
		dataType: "html"
	});
};
