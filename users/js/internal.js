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
			search_name :  search_name.
			returnformat : "json",
			queryformat : 'column'
		},
		success: function (result) {
			var message = result.DATA.MESSAGE[0];
			$("#"+targetDiv).html(message);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"saving a search");
		}
	}
	)
}
