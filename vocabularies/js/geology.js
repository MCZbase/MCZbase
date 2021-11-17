/** Scripts specific to geological attribute management. **/

/** Add a new geological attribute value 
 *  @param attribute the attribute for which to add a value
 *  @param attribute_value the value to add
 *  @param usable_value_fg is this value accepted for data entry
 *  @param description a description of the attribute value
 *  @param feedback the id of an element in the DOM into which to place feedback without a leading # selector.
 *  @param callback a callback function to invoke on successfull insert
 */
function addGeologicalAttribute(attribute, attribute_value, usable_value_fg, description, feedback, callback) { 
	$('#'+feedback).html('Saving....');
	$('#'+feedback).addClass('text-warning');
	$('#'+feedback).removeClass('text-success');
	$('#'+feedback).removeClass('text-danger');
	$.ajax({
		url: "/vocabularies/component/functions.cfc",
		data: { 
			attribute: attribute, 
			attribute_value: attribute_value, 
			usable_value_fg: usable_value_fg, 
			description: description, 
			method: 'addGeologicalAttribute' 
		},
		dataType: 'json',
		success : function (result) { 
			$('#'+feedback).html(result[0].MESSAGE);
			$('#'+feedback).addClass('text-success');
			$('#'+feedback).removeClass('text-danger');
			$('#'+feedback).removeClass('text-warning');
			if (jQuery.type(callback)==='function') {
				callback();
			}
			if (result[0].STATUS!=1) {
				alert(result[0].MESSAGE);
				$('#'+feedback).addClass('text-danger');
				$('#'+feedback).removeClass('text-success');
				$('#'+feedback).removeClass('text-danger');
			}
		},
		error: function (jqXHR, textStatus, error) {
			$('#'+feedback).addClass('text-danger');
			$('#'+feedback).removeClass('text-success');
			$('#'+feedback).removeClass('text-danger');
			handleFail(jqXHR,textStatus,error, "Error checking existence of preferred name: "); 
		}
	})
};
