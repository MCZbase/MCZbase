/** Functions supporting administration of specimen search and results **/

/** makeSpecResCollsAutocomplete make an input control into a picker for a arbitrary specimen search
 * results field metadata.
 * @param inputId the id for the input without a leading # selector.
 * @param targetField the field in cf_spec_res_cols_r for which to lookup distinct values and
 *  to bind the autocomplete to.  
**/
function makeSpecResColsAutocomplete(inputId, targetField) { 
	jQuery("#"+inputId).autocomplete({
		source: function (request, response) {
			$.ajax({
				url: "/specimens/component/search.cfc",
				data: { term: request.term, method: 'getSpecResColsAutocomplete', field: targetField },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a cf_spec_res_cols_r autocomplete");
				}
			})
		},
		select: function (event, result) {
			event.preventDefault();
			$('#'+inputId).val(result.item.value);
		},
		minLength: 3
	}).autocomplete( "instance" )._renderItem = function( ul, item ) {
		return $("<li>").append( "<span>" + item.value + " (" + item.meta +")</span>").appendTo( ul );
	};
};

/** makeSpecSearchCollsAutocomplete make an input control into a picker for a arbitrary specimen search
 * results field metadata.
 * @param inputId the id for the input without a leading # selector.
 * @param targetField the field in cf_spec_search_cols for which to lookup distinct values and
 *  to bind the autocomplete to.  
**/
function makeSpecSearchColsAutocomplete(inputId, targetField) { 
	jQuery("#"+inputId).autocomplete({
		source: function (request, response) {
			$.ajax({
				url: "/specimens/component/search.cfc",
				data: { term: request.term, method: 'getSpecSearchColsAutocomplete', field: targetField },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error,"making a cf_spec_res_cols_r autocomplete");
				}
			})
		},
		select: function (event, result) {
			event.preventDefault();
			$('#'+inputId).val(result.item.value);
		},
		minLength: 3
	}).autocomplete( "instance" )._renderItem = function( ul, item ) {
		return $("<li>").append( "<span>" + item.value + " (" + item.meta +")</span>").appendTo( ul );
	};
};
