/** Scripts specific to named group (underscore_collection) pages. **/

/** loadAgentDivHTML load a block of html listing agents related to 
 a named grouping.
 @param underscore_collection_id the primary key value for the named group 
   for which to retrieve related agents.
 @param targetDivId the id without a leading # selector for the element 
   on the page the content of which to replace with the html listing 
   agents.
*/
function loadAgentDivHTML(underscore_collection_id,targetDivId) { 
	jQuery.ajax({
		url: "/grouping/component/functions.cfc",
		data : {
			method : "getAgentDivHTML",
			underscore_collection_id: underscore_collection_id,
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading agent relationships for named group");
		},
		dataType: "html"
	});
};

// Create and open a dialog to create a new underscore_coll_agent record relating an agent to a named group
function openlinkagenttogroupingdialog(dialogid, underscore_collection_id, grouping_label, okcallback) { 
	var title = "Add a new relationship between an agent and the " + grouping_label;
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = 300;
	var w = $(window).width();
	w = Math.floor(w *.9);
	var thedialog = $("#"+dialogid).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		zindex: 2000,
		height: h,
		width: w,
		minWidth: 400,
		minHeight: 200,
		draggable:true,
		buttons: {
			"Save": function(){ 
				var datasub = $('#newAgentRelationForm').serialize();
				if ($('#newAgentRelationForm')[0].checkValidity()) {
					$.ajax({
						url: "/grouping/component/functions.cfc",
						type: 'post',
						returnformat: 'plain',
						dataType: 'json',
						data: datasub,
						success: function(data) { 
							if (jQuery.type(okcallback)==='function') {
								okcallback();
							};
							console.log(data);
							$("#agentAddResults").html("Saved " + data[0].role + " " + data[0].agent_name);
						},
						error:  function (jqXHR, textStatus,error) { 
							$("#agentAddResults").html("Error");
							handleFail(jqXHR,textStatus,error,"saving underscore_collection_agent record");
						}
					});	
		 		} else { 
					messageDialog('Missing required elements in form.  Fill in all yellow boxes. ','Form Submission Error, missing required values');
		 		};
		 	},
		 	"Close Dialog": function() { 
				if (jQuery.type(okcallback)==='function') {
					okcallback();
				}
			 	$("#"+dialogid+"_div").html("");
				$("#"+dialogid).dialog('close'); 
				$("#"+dialogid).dialog('destroy'); 
			}
		},
		close: function(event,ui) { 
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
		} 
	});
	thedialog.dialog('open');
	datastr = {
		method: "getNewAgentRelationHtml",
		returnformat: "plain",
		underscore_collection_id: underscore_collection_id
	};
	jQuery.ajax({
		url: "/grouping/component/functions.cfc",
		type: "post",
		data: datastr,
		success: function (data) { 
			$("#"+dialogid+"_div").html(data);
		}, 
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading new name group agent dialog");
		}
	});
}


// Create and open a dialog to edit an underscore_coll_agent record relating an agent to a named group
function openeditagenttogroupingdialog(dialogid, underscore_coll_agent_id, grouping_label, okcallback) { 
	var title = "Edit relationship between an agent and the " + grouping_label;
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = 300;
	var w = $(window).width();
	w = Math.floor(w *.9);
	var thedialog = $("#"+dialogid).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		zindex: 2000,
		height: h,
		width: w,
		minWidth: 400,
		minHeight: 200,
		draggable:true,
		buttons: {
			"Save": function(){ 
				var datasub = $('#editAgentRelationForm').serialize();
				if ($('#editAgentRelationForm')[0].checkValidity()) {
					$.ajax({
						url: "/grouping/component/functions.cfc",
						type: 'post',
						returnformat: 'plain',
						dataType: 'json',
						data: datasub,
						success: function(data) { 
							if (jQuery.type(okcallback)==='function') {
								okcallback();
							};
							console.log(data);
							$("#agentUpdateResults").html("Saved " + data[0].role + " " + data[0].agent_name);
						},
						error:  function (jqXHR, textStatus,error) { 
							$("#agentUpdateResults").html("Error");
							handleFail(jqXHR,textStatus,error,"saving edited underscore_collection_agent record");
						}
					});	
		 		} else { 
					messageDialog('Missing required elements in form.  Fill in all yellow boxes. ','Form Submission Error, missing required values');
		 		};
		 	},
		 	"Close Dialog": function() { 
				if (jQuery.type(okcallback)==='function') {
					okcallback();
				}
			 	$("#"+dialogid+"_div").html("");
				$("#"+dialogid).dialog('close'); 
				$("#"+dialogid).dialog('destroy'); 
			}
		},
		close: function(event,ui) { 
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
		} 
	});
	thedialog.dialog('open');
	datastr = {
		method: "updateAgentRelationHtml",
		returnformat: "plain",
		underscore_coll_agent_id: underscore_coll_agent_id
	};
	jQuery.ajax({
		url: "/grouping/component/functions.cfc",
		type: "post",
		data: datastr,
		success: function (data) { 
			$("#"+dialogid+"_div").html(data);
		}, 
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading edit named group agent dialog");
		}
	});
}

/** remove an agent from a relationship with a named group.
  @param underscore_coll_agent_id the primary key of the underscore_collection_agent record
  to delete.
*/
function removeUndColAgent(underscore_coll_agent_id, okcallback) { 
	jQuery.ajax({
		url : "/grouping/component/functions.cfc",
		type : "post",
		dataType : "json",
		data :  { 
			method: 'removeAgentFromUndColl',
			underscore_coll_agent_id: underscore_coll_agent_id
		},
		success : function (data) {
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
		},
		error: function(jqXHR,textStatus,error){
			handleFail(jqXHR,textStatus,error,"removing agent-named group relationship");
		}
	});
}

/** --------------------------------------------------------------  **/

/** loadCitationDivHTML load a block of html listing citations related to 
 a named grouping.
 @param underscore_collection_id the primary key value for the named group 
   for which to retrieve citations.
 @param targetDivId the id without a leading # selector for the element 
   on the page the content of which to replace with the html listing 
   agents.
*/
function loadCitationDivHTML(underscore_collection_id,targetDivId) { 
	jQuery.ajax({
		url: "/grouping/component/functions.cfc",
		data : {
			method : "getCitationDivHTML",
			underscore_collection_id: underscore_collection_id,
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading citations for named group");
		},
		dataType: "html"
	});
};

// Create and open a dialog to create a new underscore_collection_citation record relating an agent to 
// a publication.
function opencitenamedgroupingdialog(dialogid, underscore_collection_id, grouping_label, okcallback) { 
	var title = "Add a new citation of a publication for the " + grouping_label;
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = 300;
	var w = $(window).width();
	w = Math.floor(w *.9);
	var thedialog = $("#"+dialogid).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		zindex: 2000,
		height: h,
		width: w,
		minWidth: 400,
		minHeight: 200,
		draggable:true,
		buttons: {
			"Save": function(){ 
				var datasub = $('#newCitationForm').serialize();
				if ($('#newCitationForm')[0].checkValidity()) {
					$.ajax({
						url: "/grouping/component/functions.cfc",
						type: 'post',
						returnformat: 'plain',
						dataType: 'json',
						data: datasub,
						success: function(data) { 
							if (jQuery.type(okcallback)==='function') {
								okcallback();
							};
							console.log(data);
							$("#citationAddResults").html("Saved " + data[0].type + " " + data[0].publication);
						},
						error:  function (jqXHR, textStatus,error) { 
							$("#citationAddResults").html("Error");
							handleFail(jqXHR,textStatus,error,"saving underscore_collection_citation record");
						}
					});	
		 		} else { 
					messageDialog('Missing required elements in form.  Fill in all yellow boxes. ','Form Submission Error, missing required values');
		 		};
		 	},
		 	"Close Dialog": function() { 
				if (jQuery.type(okcallback)==='function') {
					okcallback();
				}
			 	$("#"+dialogid+"_div").html("");
				$("#"+dialogid).dialog('close'); 
				$("#"+dialogid).dialog('destroy'); 
			}
		},
		close: function(event,ui) { 
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
		} 
	});
	thedialog.dialog('open');
	datastr = {
		method: "getNewUndCollCitationHtml",
		returnformat: "plain",
		underscore_collection_id: underscore_collection_id
	};
	jQuery.ajax({
		url: "/grouping/component/functions.cfc",
		type: "post",
		data: datastr,
		success: function (data) { 
			$("#"+dialogid+"_div").html(data);
		}, 
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading new named group citation dialog");
		}
	});
}

// Create and open a dialog to edit an underscore_collection_citation record relating a publication to a named group
function openeditgroupingcitationdialog(dialogid, underscore_coll_citation_id, grouping_label, okcallback) { 
	var title = "Edit a citation of the " + grouping_label;
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = 300;
	var w = $(window).width();
	w = Math.floor(w *.9);
	var thedialog = $("#"+dialogid).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		zindex: 2000,
		height: h,
		width: w,
		minWidth: 400,
		minHeight: 200,
		draggable:true,
		buttons: {
			"Save": function(){ 
				var datasub = $('#editUndCollCitationForm').serialize();
				if ($('#editUndCollCitationForm')[0].checkValidity()) {
					$.ajax({
						url: "/grouping/component/functions.cfc",
						type: 'post',
						returnformat: 'plain',
						dataType: 'json',
						data: datasub,
						success: function(data) { 
							if (jQuery.type(okcallback)==='function') {
								okcallback();
							};
							console.log(data);
							$("#citationUpdateResults").html("Saved " + data[0].type + " " + data[0].publication);
						},
						error:  function (jqXHR, textStatus,error) { 
							$("#citationUpdateResults").html("Error");
							handleFail(jqXHR,textStatus,error,"saving edited underscore_collection_citation record");
						}
					});	
		 		} else { 
					messageDialog('Missing required elements in form.  Fill in all yellow boxes. ','Form Submission Error, missing required values');
		 		};
		 	},
		 	"Close Dialog": function() { 
				if (jQuery.type(okcallback)==='function') {
					okcallback();
				}
			 	$("#"+dialogid+"_div").html("");
				$("#"+dialogid).dialog('close'); 
				$("#"+dialogid).dialog('destroy'); 
			}
		},
		close: function(event,ui) { 
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
		} 
	});
	thedialog.dialog('open');
	datastr = {
		method: "updateCitationHtml",
		returnformat: "plain",
		underscore_coll_citation_id: underscore_coll_citation_id
	};
	jQuery.ajax({
		url: "/grouping/component/functions.cfc",
		type: "post",
		data: datastr,
		success: function (data) { 
			$("#"+dialogid+"_div").html(data);
		}, 
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading edit named group citation dialog");
		}
	});
}

/** remove a citation from a named group.
  @param underscore_coll_citation_id the primary key of the underscore_collection_citation record
  to delete.
*/
function removeUndCollCitation(underscore_coll_citation_id, okcallback) { 
	jQuery.ajax({
		url : "/grouping/component/functions.cfc",
		type : "post",
		dataType : "json",
		data :  { 
			method: 'removeCitationFromUndColl',
			underscore_coll_citation_id: underscore_coll_citation_id
		},
		success : function (data) {
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
		},
		error: function(jqXHR,textStatus,error){
			handleFail(jqXHR,textStatus,error,"removing publication-named group relationship");
		}
	});
}

/** --------------------------------------------------------------  **/

/** Builds a link_name value from a named group's collection_name, using the same
 * transform used to backfill underscore_collection.link_name for existing rows:
 * trim, collapse runs of spaces to a single underscore, strip anything that isn't
 * alphanumeric or an underscore, collapse runs of underscores, then truncate to 200
 * characters (the column's width). Used to auto-populate link_name on the create
 * named group page.
 * @param collectionName the collection_name value to derive a link_name from.
 * @return the derived link_name value.
 */
function slugifyCollectionNameForLinkName(collectionName) {
	var result = (collectionName || '').trim();
	result = result.replace(/ +/g, '_');
	result = result.replace(/[^A-Za-z0-9_]/g, '');
	result = result.replace(/_+/g, '_');
	return result.substring(0, 200);
}

/** Auto-populates the link_name field from the collection_name field's current value on
 * collection_name's onblur, but only while link_name is still empty. Bound to blur rather
 * than keyup/input so the whole typed name is used at once -- binding this to every keystroke
 * instead would derive link_name from only the first character typed, since link_name stops
 * being empty the moment that first character is written.
 * @param collectionNameFieldId id of the collection name text input, without a leading # selector.
 * @param linkNameFieldId id of the link name text input to auto-populate, without a leading # selector.
 */
function autoPopulateNamedGroupLinkName(collectionNameFieldId, linkNameFieldId) {
	var linkNameField = $('#' + linkNameFieldId);
	if (linkNameField.val().length > 0) {
		return;
	}
	linkNameField.val(slugifyCollectionNameForLinkName($('#' + collectionNameFieldId).val()));
}

/** (Re)builds link_name from collection_name's current value, using the same transform as
 * the auto-populate above -- unlike auto-populate, this always overwrites whatever link_name
 * currently holds, letting a user reset it to match the group name on demand.
 * @param collectionNameFieldId id of the collection name text input, without a leading # selector.
 * @param linkNameFieldId id of the link name text input to (re)generate, without a leading # selector.
 */
function generateNamedGroupLinkName(collectionNameFieldId, linkNameFieldId) {
	var collectionName = $('#' + collectionNameFieldId).val();
	$('#' + linkNameFieldId).val(slugifyCollectionNameForLinkName(collectionName));
}

/** Toggles a link_name input between disabled and enabled, relabeling the adjacent toggle
 * button "Edit"/"Lock" to match, so a save made without pressing the button leaves the field
 * disabled (and so excluded from the submitted form) rather than editable by default.
 * @param linkNameFieldId id of the link name text input, without a leading # selector.
 * @param toggleButtonId id of the toggle button, without a leading # selector.
 */
function toggleNamedGroupLinkNameEdit(linkNameFieldId, toggleButtonId) {
	var input = $('#' + linkNameFieldId);
	var button = $('#' + toggleButtonId);
	if (input.prop('disabled')) {
		input.prop('disabled', false).trigger('focus');
		button.text('Lock').attr('aria-pressed', 'true');
	} else {
		input.prop('disabled', true);
		button.text('Edit').attr('aria-pressed', 'false');
	}
}

/** Rebuilds the /namedGroup/{link_name} permalink preview to match the link_name field's
 * current value, choosing between a full text link and an icon-only link with an aria-label
 * once the value reaches charLimit, matching the same threshold and markup used when the
 * page was first rendered, so the preview never falls out of sync with a live edit.
 * @param linkNameFieldId id of the link name text input, without a leading # selector.
 * @param displayContainerId id of the element whose contents should be replaced with the
 *	rendered permalink, without a leading # selector.
 * @param serverRootUrl the application's server root URL to prefix the permalink path with.
 * @param charLimit link_name length at or above which the icon-only display is used instead
 *	of the full text link.
 */
function updateNamedGroupPermalinkPreview(linkNameFieldId, displayContainerId, serverRootUrl, charLimit) {
	var linkName = $('#' + linkNameFieldId).val();
	var container = $('#' + displayContainerId);
	container.empty();
	if (!linkName) {
		return;
	}
	var url = serverRootUrl + '/namedGroup/' + encodeURIComponent(linkName);
	if (linkName.length < charLimit) {
		container.append($('<a id="link_name_permalink" target="_blank"></a>').attr('href', url).text(url));
	} else {
		var link = $('<a id="link_name_permalink" class="px-1 text-muted" target="_blank"></a>')
			.attr('href', url)
			.attr('aria-label', 'Permalink: ' + url)
			.append('<i class="fas fa-link" aria-hidden="true"></i>');
		container.append(link);
	}
}
