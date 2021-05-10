/** Scripts specific to media pages. **/

/** Make a text media_label aspect control into an autocomplete 
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 */
function makeAspectAutocomplete(valueControl) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/media/component/search.cfc",
				data: { term: request.term, method: 'getAspectAutocomplete' },
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
		},
		minLength: 3
	});
};
