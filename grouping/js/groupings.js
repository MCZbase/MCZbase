// JavaScript Document

function requestPoints() { 
	$.ajax({
			url: "/grouping/component/functions.cfc",
			data: { 
				method: 'get_coordList' 
			},
				dataType: 'json',
				success : function (data) { response(data); },
			error : function (jqXHR, status, error) {
				var message = "";
				if (error == 'timeout') { 
					message = ' Server took too long to respond.';
				} else { 
					message = jqXHR.responseText;
				}
				messageDialog('Error:' + message ,'Error: ' + error);
			}
		})
	}