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
