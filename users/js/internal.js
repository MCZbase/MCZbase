/** Scripts specific to internal uses related to users **/

function saveSearch(url, execute, search_name, targetDiv) {
	jQuery.ajax(
	{
		dataType: "json",
		url: "/users/component/functions.cfc",
		data: { 
			method : "saveSearch",
			url : url,
			execute : execute,
			search_name :  search_name,
			dataType : "json"
		},
		success: function (result) {
			var status = result[0].status;
			var name = result[0].name;
			var message = "Saved: [" + result[0].name + "]." ;
			$("#"+targetDiv).html(message);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"saving a search");
		}
	}
	)
}
