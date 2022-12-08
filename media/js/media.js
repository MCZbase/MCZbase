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


function loadMediaRelations(targetDiv, media_id) { 
	console.log("loadHello() called for " + targetDiv);
	jQuery.ajax({
		url: "/media/component/search.cfc",
		data : {
			method : "getMediaRelationsHtml",
			media_id : media_id,
	
		},
		success: function (result) {
			$("#" + targetDiv).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"retrieving relationship block");
		},
		dataType: "html"
	});
};

function loadMetadata(targetDiv, media_id) { 
	console.log("Where is it? " + targetDiv);
	jQuery.ajax({
		url: "/media/component/search.cfc",
		data : {
			method : "getMediaMetadata",
			media_id : media_id,
	
		},
		success: function (result) {
			$("#" + targetDiv).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"retrieving metadata block");
		},
		dataType: "html"
	});
};

function saveMediaRelationship(targetDiv, media_id, media_relations_id) { 
	console.log("loadRelation() called for " + targetDiv);
	jQuery.ajax({
		url: "/media/component/search.cfc",
		data : {
			method : "updateMediaRelationship",
			media_id : media_id
		},
		success: function (result) {
			$("#" + targetDiv).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"retrieving relationship block");
		},
		dataType: "html"
	});
};

function createMedia(targetDiv, media_id, media_relations_id) { 
	console.log("loadRelation() called for " + targetDiv);
	jQuery.ajax({
		url: "/media/component/functions.cfc",
		data : {
			method : "createMedia",
			media_id : media_id,
			media_relations_id: media_relations_id
		},
		success: function (result) {
			$("#" + targetDiv).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"retrieving relationship block");
		},
		dataType: "html"
	});
};

/** Functions for hello world page **/

/**  
 * Populate a hello world message section of a page with the current 
 * hello and counter information without incrementing the counter.
 * 
 * @param targetDiv the id, without a leading # selector for the html element
 * to populate with the hello world message.
 
 */
function loadHello(targetDiv, parameter, other_parameter, id_for_counter, id_for_dialog) { 
	console.log("loadHello() called for " + targetDiv);
	jQuery.ajax({
		url: "/media/component/search.cfc",
		data : {
			method : "getCounterHtml",
			parameter : parameter, 
			other_parameter : other_parameter,
			id_for_counter : id_for_counter,
			id_for_dialog : id_for_dialog
		},
		success: function (result) {
			$("#" + targetDiv).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"retrieving hello world data");
		},
		dataType: "html"
	});
};

/**  
 * Increment all counters and invoke a callback function.
 * 
 * @param callback a callback function to invoke on success.
 */
function incrementCounters(callback) { 
	console.log("incrementCounters() called");
	jQuery.ajax({
		url: "/media/component/search.cfc",
		data : {
			method : "incrementAllCounters"
		},
		success: function (result) {
			retval = JSON.parse(result);
			console.log(retval[0].status);
			console.log(retval[0].counter);
			if (jQuery.type(callback)==='function') {
				callback();
			}
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"incrementing hello world counter (1)");
		}
	});
};

/**  
 * Increment all counters and update an element in the page.
 * 
 * @param counterElement the id of a element in the dom, the html
 * of which to update with a new value of counter on success, id
 * without a leading # selector.
 * 
 */
function incrementCountersUpdate(counterElement) { 
	console.log("incrementCountersUpdate() called for " + counterElement);
	jQuery.ajax({
		url: "/media/component/search.cfc",
		data : {
			method : "incrementAllCounters"
		},
		success: function (result) {
			retval = JSON.parse(result);
			console.log(retval[0].status);
			console.log(retval[0].counter);
			$("#" + counterElement).html(retval[0].counter);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"incrementing hello world counter (2)");
		}
	});
};


/**  
 * Increment a counter and update an element in the page.
 * 
 * @param helloworld_id the row for which to update the counter
 * @param counterElement the id of a element in the dom, the html
 * of which to update with a new value of counter on success, id
 * without a leading # selector.
 * 
 */
function incrementCounterUpdate(counterElement, helloworld_id) { 
	console.log("incrementCounterUpdate() called for " + counterElement);
	console.log(helloworld_id);
	jQuery.ajax({
		url: "/media/component/search.cfc",
		data : {
			method : "incrementCounter",
			helloworld_id : helloworld_id
		},
		success: function (result) {
			retval = JSON.parse(result);
			console.log(retval[0].status);
			console.log(retval[0].counter);
			$("#" + counterElement).html(retval[0].counter);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"incrementing hello world counter for single record");
		}
	});
};

/* function openUpdateTextDialog create a dialog using an existing div to update the hello world text. 
 * 
 * @param helloworld_id the id of the cf_helloworld row to update
 * @param dialogId the id, without a leading # selector, of the div that is to contain the dialog.
 */
function openUpdateTextDialog(helloworld_id, dialogId) { 
	console.log("openUpdateTextDialog called");
	console.log(helloworld_id);
	console.log(dialogId);
	var title = "Update Media URI";
	var content = '<div id="'+dialogId+'_div">Loading....</div>';
	var thedialog = $("#"+dialogId).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		minWidth: 320,
		minHeight: 200,
		draggable:true,
		buttons: {
			"Close Dialog": function() {
				console.log("close dialog clicked");
				$("#"+dialogId).dialog('close');
				doReload(); 
			}
		},
		open: function (event, ui) {
			console.log("close dialog open event");
			// force the dialog to lay above any other elements in the page.
			var maxZindex = getMaxZIndex();
			$('.ui-dialog').css({'z-index': maxZindex + 6 });
			$('.ui-widget-overlay').css({'z-index': maxZindex + 5 });
		},
		close: function(event,ui) {
			console.log("close dialog close event");
			$("#"+dialogId+"_div").html("");
			$("#"+dialogId).dialog('destroy');
		}
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/media/component/search.cfc",
		type: "post",
		data: {
			method: 'getTextDialogHtml',
			returnformat: "plain",
			helloworld_id: helloworld_id
		},
		success: function(data) {
			console.log("dialog data returned, populating dialog div");
			$("#"+dialogId+"_div").html(data);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"populating edit text dialog for hello world");
		}
	});
}

function openSlideAtlas(SlideAtlas_id, dialogId) { 
	console.log("openUpdateTextDialog called");
	console.log(helloworld_id);
	console.log(dialogId);
	var title = "In Viewer";
	var content = '<div id="'+dialogId+'_div">Loading....</div>';
	var thedialog = $("#"+dialogId).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		minWidth: 520,
		minHeight: 500,
		draggable:true,
		buttons: {
			"Close Viewer": function() {
				console.log("close dialog clicked");
				$("#"+dialogId).dialog('close');
				doReload(); 
			}
		},
		open: function (event, ui) {
			console.log("close dialog open event");
			// force the dialog to lay above any other elements in the page.
			var maxZindex = getMaxZIndex();
			$('.ui-dialog').css({'z-index': maxZindex + 6 });
			$('.ui-widget-overlay').css({'z-index': maxZindex + 5 });
		},
		close: function(event,ui) {
			console.log("close dialog close event");
			$("#"+dialogId+"_div").html("");
			$("#"+dialogId).dialog('destroy');
		}
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/media/component/search.cfc",
		type: "post",
		data: {
			method: 'getTextDialogHtml',
			returnformat: "plain",
			helloworld_id: helloworld_id
		},
		success: function(data) {
			console.log("dialog data returned, populating dialog div");
			$("#"+dialogId+"_div").html(data);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"populating edit text dialog for hello world");
		}
	});
}