/** Scripts for the administrative pages in /Admin/. **/

/** Make a search field into an autocomplete backed by a method of /Admin/component/functions.cfc.
 *  The search matches anywhere in the value unless it starts with =, so choosing an item from the
 *  list puts = in front of it for an exact match, as on other MCZbase searches.
 *  @param valueControl the id of the text input, without a leading # selector.
 *  @param method the remote method returning value and meta pairs for a term.
 */
function makeAdminExactMatchAutocomplete(valueControl, method) {
	$('#'+valueControl).autocomplete({
		source: function (request, response) {
			$.ajax({
				url: "/Admin/component/functions.cfc",
				data: { term: request.term, method: method },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, status, error) {
					handleFail(jqXHR,status,error,"looking up values for " + valueControl);
				}
			})
		},
		select: function (event, result) {
			// on select, prefix the value with an equals for an exact match
			event.preventDefault();
			$('#'+valueControl).val("=" + result.item.value);
		},
		minLength: 2
	}).autocomplete("instance")._renderItem = function(ul,item) {
		return $("<li>").append("<span>" + $("<div>").text(item.meta).html() + "</span>").appendTo(ul);
	};
}

/** Load an Admin Panel widget: replace the content of a target element with the HTML a method of
 *  /Admin/component/functions.cfc returns, showing the loading indicator meanwhile.
 *  @param targetId the id of the element to fill, without a leading # selector.
 *  @param method the remote method returning the widget's HTML.
 *  @param params optional object of further arguments for the method.
 */
function loadAdminWidget(targetId, method, params) {
	$('#'+targetId).html('<div class="my-2 text-center"><img src="/shared/images/indicator.gif" alt=""> Loading...</div>');
	$.ajax({
		url: "/Admin/component/functions.cfc",
		data: $.extend({ method: method, returnformat: "plain" }, params || {}),
		type: "get",
		success: function (data) {
			$('#'+targetId).html(data);
		},
		error: function (jqXHR, textStatus, error) {
			$('#'+targetId).html('<p class="text-danger">This widget could not be loaded.</p>');
			handleFail(jqXHR, textStatus, error, "loading the " + method + " widget");
		}
	});
}
