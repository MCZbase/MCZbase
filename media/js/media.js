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
		case "":
			// blank option selected, remove an autocomplete, but not the values.
			try { 
				$('#'+valueControl).autocomplete("destroy");
			} catch (err) {
				console.log(err);
			}
			break;
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
		case "borrow":
			if (typeof makeBorrowAutocompleteMeta === "function") { 
				makeBorrowAutocompleteMeta(valueControl, idControl);
			}
			break;
		default:
			messageDialog("Unknown or not implemented media relationship target, only NULL and NOT NULL values are supported","Error: Unknown");		
	}

}

function loadCommonNames(7319,target) { 
   jQuery.ajax({
      url: "/media/component/functions.cfc",
      data : {
         method : "getCommonHtml",
         taxon_name_id: taxon_name_id,
         target: target
      },
      success: function (result) {
         $("#" + target).html(result);
      },
      error: function (jqXHR, textStatus, message) {
			handleFail(jqXHR,textStatus,message,"loading common names for taxon");
      },
      dataType: "html"
   });
}

/**
 * newCommon, given a taxon and text string for a common name of the taxon
 * link the common name and reload the list of common names for the taxon.
 * 
 * @param taxon_name_id the primary key for the taxon record to which to add the common name.
 * @param common_name the text string to add to the taxon as a common name.
 * @param target the id of the target div containing the list of common names 
 *   to reload, without a leading # selector.
 */
function newCommon(taxon_name_id,common_name,target) {
	jQuery.getJSON("/media/component/functions.cfc",
		{
			method : "newCommon",
			common_name : common_name,
			taxon_name_id : taxon_name_id,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			loadCommonNames(taxon_name_id,target);
			$('#new_common_name').val("");
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"adding common name to taxon");
	});
};

/**
 * deleteCommonName, given common name record for a taxon delete the common name
 * record and reload the list of common names for the taxon.
 * 
 * @param common_name_id the primary key value for the common name to delete.
 * @param taxon_name_id the primary key for the taxon record for the common name.
 * @param target the id of the target div containing the list of common names 
 *   to reload, without a leading # selector.
 */
function deleteCommonName(common_name_id,taxon_name_id,target) {
	jQuery.getJSON("/media/component/functions.cfc",
		{
			method : "deleteCommon",
			common_name_id: common_name_id,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			loadCommonNames(taxon_name_id,target);
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"removing common name from taxon");
	});
};

function saveCommon(common_name_id, common_name, taxon_name_id, target) {
	jQuery.getJSON("/media/component/functions.cfc",
		{
			method : "saveCommon",
			common_name : common_name,
			common_name_id : common_name_id,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			loadCommonNames(taxon_name_id,target);
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"saving changes to common name of taxon");
	});
};
