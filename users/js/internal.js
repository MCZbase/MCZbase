/** Scripts specific to internal uses related to users **/

function saveSearch(url, execute, search_name, targetDiv) {
	jQuery.ajax(
	{
		dataType: "json",
		url: "/specimens/component/functions.cfc",
		data: { 
			method : "saveSearch",
			url : url,
			execute : execute,
			search_name :  search_name,
			dataType : "json"
		},
		success: function (result) {
			var message = "Saved: [" + result[0].message + "]." ;
			$("#"+targetDiv).html(message);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"saving a search");
		}
	}
	)
}
