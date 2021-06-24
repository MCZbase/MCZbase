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
		select: function (event, result) {
			//  on select, set prefix the value with an equals for exact match
			event.preventDefault();
			$('#'+valueControl).val("=" + result.item.value);
		},
      minLength: 3
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta "collection name * (description)" instead of value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};


/** Make an arbitrary media_label control into an autocomplete 
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param media_label the media_label to look up values for
 */
function makeMediaLabelAutocomplete(valueControl,media_label) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/media/component/search.cfc",
				data: { 
					term: request.term, 
					media_label: media_label, 
					method: 'getMediaLabelAutocomplete' 
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
		},
		select: function (event, result) {
			//  on select, set prefix the value with an equals for exact match
			event.preventDefault();
			$('#'+valueControl).val("=" + result.item.value);
		},
      minLength: 3
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta "collection name * (description)" instead of value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};

/** Make a pair of media_label_type and media_label_values control into an autocomplete 
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param typeControl the id for a select who's selected value is the media_label to lookup values for (without a leading # selector).
 */
function makeAnyMediaLabelAutocomplete(valueControl,typeControl) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			var media_label_val = $('#'+typeControl).val();
			$.ajax({
				url: "/media/component/search.cfc",
				data: { 
					term: request.term, 
					media_label: media_label_val, 
					method: 'getMediaLabelAutocomplete' 
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
		},
		select: function (event, result) {
			//  on select, set prefix the value with an equals for exact match
			event.preventDefault();
			$('#'+valueControl).val("=" + result.item.value);
		},
      minLength: 3
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta "collection name * (description)" instead of value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};
/** Make an arbitrary media uri component (hostname, path, filename) into an autocomplete 
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param targetField the part of the media_uri (hostname, path, filename) to look up distinct values for
 */
function makeMediaURIPartAutocomplete(valueControl,targetField) {
	var targetMethod = "";
	if (targetField=="hostname") { 
		targetMethod = "getHostnameAutocomplete";
	} else if (targetField=="path") {
		targetMethod = "getPathAutocomplete";
	} else if (targetField=="filename") {
		targetMethod = "getFilenameAutocomplete";
   } else {
		mesageDialog('Error: unrecognized target field','Error: unrecognized target field');
	}
	if (targetMethod != "") {  
		$('#'+valueControl).autocomplete({
			source: function (request, response) { 
				$.ajax({
					url: "/media/component/search.cfc",
					data: { 
						term: request.term, 
						method: targetMethod
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
			},
			select: function (event, result) {
				//  on select, set prefix the value with an equals for exact match
				event.preventDefault();
				$('#'+valueControl).val("=" + result.item.value);
			},
   	   minLength: 3
		}).autocomplete("instance")._renderItem = function(ul,item) { 
			// override to display meta "collection name * (description)" instead of value in picklist.
			return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
		};
	}
};

function makeAnyMediaRelationAutocomplete(valueControl,typeControl,idControl) { 
	var targetObject = $('#'+typeControl).val().trim().split(" ").pop();
	console.log(targetObject);
	switch (targetObject) {
		case "agent":
			makeConstrainedAgentPicker(valueControl, idControl, 'media_agent'); 
			break;
		case "cataloged_item":
			makeCatalogedItemAutocompleteMeta(valueControl, idControl);
			break;
		case "collecting_event":
			makeCollectingEventAutocompleteMeta(valueControl, idControl);
			break;
		case "locality":
			makeLocalityAutocompleteMeta(valueControl, idControl);
			break;
		case "underscore_collection":
			makeNamedCollectionPicker(valueControl,idControl);
			break;
		case "publication":
			makePublicationAutocompleteMeta(valueControl, idControl);
			break;
		case "project":
			makeProjectAutocompleteMeta(valueControl, idControl);
			break;
		case "permit":
			if (typeof makePermitPicker === "function") { 
				makePermitPicker(valueControl, idControl);
			}
			break;
		case "loan":
			if (typeof makeLoanPicker === "function") { 
				makeLoanPicker(valueControl, idControl);
			}
			break;
		case "accn":
			if (typeof makeAccessionAutocompleteMeta === "function") { 
				makeAccessionAutocompleteMeta(valueControl, idControl);
			}
			break;
		case "deaccession":
			if (typeof makeDeaccessionAutocompleteMeta === "function") { 
				makeDeaccessionAutocompleteMeta(valueControl, idControl);
			}
			break;
		default:
			messageDialog("Unknown or not implemented media relationship target","Error: Unknown");		
	}

}
