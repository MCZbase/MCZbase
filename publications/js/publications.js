/** Scripts specific to publications pages. **/
/**

Copyright 2022 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	 http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

**/

/** markup apply an html tage to selected text in a text area.
 * @param textAreaId the id of a textarea input to which to apply markup.
 * @param the tag to use, supported values: i, b, sub, sup.
 **/
function markup(textAreaId, tag){
	var len = $("##"+textAreaId).val().length;
	var start = $("##"+textAreaId)[0].selectionStart;
	var end = $("##"+textAreaId)[0].selectionEnd;
	var selection = $("##"+textAreaId).val().substring(start, end);
	if (selection.length>0){
		var replace = selection;
		if (tag=='i') { 
			replace = '<i>' + selection + '</i>';
		} else if(tag=='b') { 
			replace = '<b>' + selection + '</b>';
		} else if(tag=='sub') { 
			replace = '<sub>' + selection + '</sub>';
		} else if(tag=='sup') { 
			replace = '<sup>' + selection + '</sup>';
		}
		$("##"+textAreaId).val($("##"+textAreaId).val().substring(0,start) + replace + $("##"+textAreaId).val().substring(end,len));
	}
}

/** loadFullCitDivHTML load a block of html showing the current full form
 * of the citation for a publication.
 * @param publication_id the publication for which to show the citation.
 * @param targetDivId the id without a leading # selector of the element in 
 *  the dom the content of which to replace with the returned html.
*/
function loadFullCitDivHTML(publication_id,targetDivId) { 
	jQuery.ajax({
		url: "/publications/component/functions.cfc",
		data : {
			method : "getCitationForPubHtml",
			form: "full",
			publication_id: publication_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading publication citation text");
		},
		dataType: "html"
	});
};
/** loadPlainCitDivHTML load the value of the current full form
 * of the citation for a publication without html markup into an input control.
 * @param publication_id the publication for which to show the citation.
 * @param targetDivId the id without a leading # selector of the element in 
 *  the dom the value of which to replace with the returned text.
*/
function loadPlainCitDivHTML(publication_id,targetDivId) { 
	jQuery.ajax({
		url: "/publications/component/functions.cfc",
		data : {
			method : "getCitationForPubHtml",
			form: "plain",
			publication_id: publication_id
		},
		success: function (result) {
			$("#" + targetDivId ).val(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading publication citation plain text");
		},
		dataType: "html"
	});
};

/** function monitorForChanges bind a change monitoring function to inputs 
 * on a given form.  Note: text inputs must have type=text to be bound to change function.
 * @param formId the id of the form, not including the # id selector to monitor.
 * @param changeFunction the function to fire on change events for inputs on the form.
 */
function monitorForChanges(formId,changeFunction) { 
	$('#'+formId+' input[type=text]').on("change",changeFunction);
	$('#'+formId+' input[type=checkbox]').on("change",changeFunction);
	$('#'+formId+' select').on("change",changeFunction);
	$('#'+formId+' textarea').on("change",changeFunction);
}

/** lookupDOI use information from a publication record to find a DOI for that 
 * publication.
 * @param publication_id the publication for which to lookup the doi.
 * @param doiInput the id without a leading pound selector of the input whos value
 *  is to be set to the returned doi on success.
 * @param doiLinkDiv the id without a leading pound selector of a div that is to
 *  have its html replaced by a link for the doi on success.
 */
function lookupDOI(publication_id, doiInput, doiLinkDiv) {
	jQuery.ajax({
		dataType: "json",
		url: "/publications/component/functions.cfc",
		data: { 
			method : "crossRefLookup",
			publication_id : publication_id,
			returnformat : "json",
			queryformat : 'column'
		},
		error: function (jqXHR, status, message) {
			messageDialog("Error looking up DOI: " + status + " " + jqXHR.responseText ,'Error: '+ status);
		},
		success: function (result) {
			console.log(result);
			var match = result[0].match;
			if (match=='1') {
				var doi = result[0].doi;
				$('#'+doiInput).val(doi);
				$('#'+doiLinkDiv).html("<a class='external' target='_blank' href='https://doi.org/"+doi+"'>"+doi+"</a>");
			}
		}
	});
}

/** openEditAttributeDialog open a dialog to edit an attribute of a publication.
 * @param dialogid the id of a div in the dom which to make into the dialog 
 *   without leading pound selector.
 * @param publication_attribute_id the primary key of the publication attribute
 *  to edit.
 * @param attribute the current attribute type to edit.
 * @param okcallback a callback function to invoke on success.
 */
function openEditAttributeDialog(dialogid,publication_attribute_id, attribute, okcallback) { 
	var title = "Edit publication attribute "+attribute+".";
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = $(window).height();
	var w = $(window).width();
	w = Math.floor(w *.4);
	h = Math.floor(h *.5);
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
		minWidth: 320,
		minHeight: 250,
		draggable:true,
		buttons: {
			"Close Dialog": function() {
				$(this).dialog('close'); 
			}
		}, 
		close: function(event,ui) {
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
			$("#"+dialogid+"_div").html("");
			$(this).dialog("destroy");
		}
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/publications/component/functions.cfc",
		type: "post",
		data: {
			method: "getAttributeEditDialogHtml",
			returnformat: "plain",
			publication_attribute_id: publication_attribute_id
		},
		success: function (data) {
			$("#"+dialogid+"_div").html(data);
		}, 
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading dialog to edit publication attribute");
		}
	});
}
/** openAddAttributeDialog open a dialog to add an attribute to a publication.
 * @param dialogid the id of a div in the dom which to make into the dialog 
 *   without leading pound selector.
 * @param publication_id the primary key of the publication to which to add 
 *   the attribute.
 * @param attribute optional attribute type to add.
 * @param okcallback a callback function to invoke on success.
 */
function openAddAttributeDialog(dialogid,publication_id, attribute, okcallback) { 
	var title = "Add publication attribute "+attribute;
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = $(window).height();
	var w = $(window).width();
	w = Math.floor(w *.4);
	h = Math.floor(h *.5);
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
		minWidth: 320,
		minHeight: 250,
		draggable:true,
		buttons: {
			"Close Dialog": function() {
				$(this).dialog('close'); 
			}
		}, 
		close: function(event,ui) {
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
			$("#"+dialogid+"_div").html("");
			$(this).dialog("destroy");
		}
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/publications/component/functions.cfc",
		type: "post",
		data: {
			method: "getAttributeAddDialogHtml",
			returnformat: "plain",
			publication_id: publication_id,
			attribute: attribute
		},
		success: function (data) {
			$("#"+dialogid+"_div").html(data);
		}, 
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading dialog to add publication attribute");
		}
	});
}

/** saveAttribute update an existing row in publication_attributes
 * @param publication_attribute_id the publication attribute to be updated.
 * @param publication_id the publication to which the attribute applies.
 * @param publication_attribute the new type of attribute.
 * @param pub_att_value the new value of the attribute.
 * @param okcallback a callback function to invoke on success.
*/
function saveAttribute(publication_attribute_id, publication_id, publication_attribute, pub_att_value, feedbackdiv, okcallback) { 
	console.log(publication_id);
	console.log(publication_attribute);
	console.log(pub_att_value);
	jQuery.ajax({
		url: "/publications/component/functions.cfc",
		data : {
			method : "updateAttribute",
			returnformat : "json",
			queryformat : 'struct',
			publication_attribute_id: publication_attribute_id,
			publication_id: publication_id,
			publication_attribute: publication_attribute,
			pub_att_value: pub_att_value
		},
		success: function (result) {
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
			var status = result[0].status;
			if (status=='updated') {
				console.log(status);
				$('#'+feedbackdiv).html(status);
			}
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"adding attribute to publication");
		},
		dataType: "json"
	});
};

/** saveNewAttribute insert a row into publication_attributes
 * @param publication_id the publication to which the attribute applies.
 * @param publication_attribute the type of attribute to add.
 * @param pub_att_value the value of the attribute to add.
 * @param feedbackdiv id of an element in the dom without leading pound 
 *  selector into which to place feedback on success.
 * @param okcallback a callback function to invoke on success.
*/
function saveNewAttribute(publication_id, publication_attribute, pub_att_value , feedbackdiv, okcallback) { 
	jQuery.ajax({
		url: "/publications/component/functions.cfc",
		data : {
			method : "addAttribute",
			returnformat : "json",
			queryformat : 'struct',
			publication_id: publication_id,
			publication_attribute: publication_attribute,
			pub_att_value: pub_att_value
		},
		success: function (result) {
			console.log(result);
			var status = result[0].status;
			console.log(status);
			if (status=='inserted') {
				$('#'+feedbackdiv).html(status);
			}
			if (okcallback && jQuery.type(okcallback)==='function') {
				okcallback();
			}
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"adding attribute to publication");
		},
		dataType: "json"
	});
};

/** deleteAttribute delete an attribute from a publication.
 * @param publication_attribute_id the primary key of the publication attribute
 *  to delete.
 * @param okcallback a callback function to invoke on success.
 */
function deleteAttribute(publication_attribute_id, okcallback) { 
	jQuery.ajax({
		dataType: "json",
		url: "/publications/component/functions.cfc",
		data: { 
			method : "deleteAttribute",
			publication_attribute_id : publication_attribute_id,
			returnformat : "json",
			queryformat : 'column'
		},
		error: function (jqXHR, status, message) {
			messageDialog("Error deleting publication attribute: " + status + " " + jqXHR.responseText ,'Error: '+ status);
		},
		success: function (result) {
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
			var status = result[0].status;
			if (status=='deleted') {
				console.log(status);
			}
		}
	});
}

/** loadAuthorsDivHTML load a block of html for editing/viewing
 *  authors and editors of a publication.
 * @param publication_id the publication for which to load authors/editors
 * @param targetDivId the id without a leading # selector of the element in 
 *  the dom the content of which to replace with the returned html.
*/
function loadAuthorsDivHTML(publication_id,targetDivId) { 
	jQuery.ajax({
		url: "/publications/component/functions.cfc",
		data : {
			method : "getAuthorsForPubHtml",
			publication_id: publication_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading authors/editors for publication");
		},
		dataType: "html"
	});
};

/** loadAttributesDivHTML load a block of html for editing/viewing
 *  attributes of a publication.
 * @param publication_id the publication for which to load attributes
 * @param targetDivId the id without a leading # selector of the element in 
 *  the dom the content of which to replace with the returned html.
*/
function loadAttributesDivHTML(publication_id,targetDivId) { 
	jQuery.ajax({
		url: "/publications/component/functions.cfc",
		data : {
			method : "getAttributesForPubHtml",
			publication_id: publication_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading attributes for publication");
		},
		dataType: "html"
	});
};

/** loadMediaDivHTML load a block of html for editing/viewing
 *  media related a publication.
 * @param publication_id the publication for which to load media
 * @param targetDivId the id without a leading # selector of the element in 
 *  the dom the content of which to replace with the returned html.
*/
function loadMediaDivHTML(publication_id,targetDivId) { 
	jQuery.ajax({
		url: "/publications/component/functions.cfc",
		data : {
			method : "getMediaForPubHtml",
			publication_id: publication_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading media for publication");
		},
		dataType: "html"
	});
};

/** loadAnnotationDivHTML load a block of html for editing/viewing
 *  attributes of a publication.
 * @param publication_id the publication for which to load attributes
 * @param targetDivId the id without a leading # selector of the element in 
 *  the dom the content of which to replace with the returned html.
*/
function loadAnnotationDivHTML(publication_id,targetDivId) { 
	jQuery.ajax({
		url: "/publications/component/functions.cfc",
		data : {
			method : "getAnnotationsForPubHtml",
			publication_id: publication_id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading annotations for publication");
		},
		dataType: "html"
	});
};

function removeAuthor(publication_author_name_id, okcallback) { 
	jQuery.ajax({
		url: "/publications/component/functions.cfc",
		data : {
			method : "removeAuthor",
			publication_author_name_id: publication_author_name_id
		},
		success: function (result) {
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
			var status = result[0].status;
			if (status=='deleted') {
				console.log(status);
			}
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"removing author/editor from publication");
		},
		dataType: "html"
	});
};

/** openAddAuthorEditorDialog, create and open a dialog to add authors or editors to a publication
 * @param dialogid id to give to the dialog
 * @param publication_id the publication that authors/editors are to be linked to
 * @param role the role for the dialog to create either authors or editors
 * @param okcallback callback function to invoke on closing dialog
 */
function openAddAuthorEditorDialog(dialogid, publication_id, role, okcallback) {
	var title = "Add " + role + " to publication.";
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = $(window).height();
	var w = $(window).width();
	w = Math.floor(w *.8);
	h = Math.floor(h *.5);
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
		minWidth: 320,
		minHeight: 250,
		draggable:true,
		buttons: {
			"Close Dialog": function() {
				$(this).dialog('close'); 
			}
		}, 
		close: function(event,ui) {
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
			$(this).dialog("destroy");
		}
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/publications/component/functions.cfc",
		type: "post",
		data: {
			method: "addAuthorEditorHtml",
			returnformat: "plain",
			publication_id: publication_id,
			role: role
		},
		success: function (data) {
			$("#"+dialogid+"_div").html(data);
		}, 
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading dialog to add author/editor to publication");
		}
	});
}


/** openAddAgentNameOfTypeDialog, create and open a dialog to add author or second author
 * form of an agent name
 * @param dialogid id to give to the dialog
 * @param agent_id the agent to which to add the agent_name to
 * @param agent_name_type the type of agent name to add 
 */
function openAddAgentNameOfTypeDialog(dialogid, agent_id, agent_name_type) {
	var title = "Add agent name of type " + agent_name_type + " to agent.";
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = $(window).height();
	var w = $(window).width();
	w = Math.floor(w *.6);
	h = Math.floor(h *.6);
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
		minWidth: 300,
		minHeight: 300,
		draggable:true,
		buttons: {
			"Close Dialog": function() {
				$(this).dialog('close'); 
			}
		}, 
		close: function(event,ui) {
			$("#"+dialogid+"_div").html("");
			$(this).dialog("destroy");
		}
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/publications/component/functions.cfc",
		type: "post",
		data: {
			method: "addAgentNameOfTypeHtml",
			returnformat: "plain",
			agent_id: agent_id,
			agent_name_type: agent_name_type
		},
		success: function (data) {
			$("#"+dialogid+"_div").html(data);
		}, 
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading dialog to add name to agent");
		}
	});
}

/** addAuthorName, add a specified type of agent name to an agent, handling integration
 * with add author name workflow.  
 * @param agent_id the agent to which to add the agent_name to.
 * @param agent_name_type the type of agent name to add.
 * @param agent_name the value of the agent name to add. 
 * @param agent_name_id_control the id for an input without a leading pound selector
 *   that is to take the agent_name_id of the new agent_name on success.
 * @see addAgentName for general purpose invocation.
 */
function addAuthorName(agent_id,agent_name_type,agent_name,agent_name_id_control,feedback_control) { 
	jQuery.getJSON("/agents/component/functions.cfc",
		{
			method : "addNameToAgent",
			agent_id : agent_id,
			agent_name_type : agent_name_type,
			agent_name : agent_name,
			returnformat : "json",
			queryformat : 'struct'
		},
		function (result) {
			if (result[0].STATUS!=1) {
				messageDialog('Error adding name to agent' ,'Error: ' + result[0].MESSAGE);
			} else { 
				$('#'+agent_name_id_control).val(result[0].AGENT_NAME_ID)
				$('#'+feedback_control).html("Added " + agent_name + " to agent.");
				if ($('#author_name_id').val()=='') { 
					$('#author_name_control').html(agent_name);
					$('#author_name_id').val(result[0].AGENT_NAME_ID);
					$('#addButton').prop('disabled',false);
					$('#addButton').removeClass('disabled');
					console.log(result[0].AGENT_NAME_ID);
				}
			} 
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"adding name to agent");
	});
} 

/** Make a set of hidden agent_id and text agent_name, agent link control, and agent icon controls into an 
 *  autocomplete agent picker supporting populating publication_author records
 *  
 *  @param nameControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected agent_id (without a leading # selector).
 *  @param iconControl the id for an input that can take a background color to indicate a successfull pick of an agent
 *    (without an leading # selector)
 *  @param linkControl the id for a page element that can contain a hyperlink to an agent, by agent id.
 *  @param agentID null, or an id for an agent, if an agentid value is provided, then the idControl, linkControl, and
 *    iconControl are initialized in a picked agent state.
 *  @param authorNameControl the id for a page element that can contain an agent name.
 *  @param authorNameIdControl the id of a hidden inmpt to hold the selected agent_name_id for the desired authorship form of the name
 *  @param authorshipPosition 1, >1 for first or second for the author position form for which to find an author name.
 */
function makeRichAuthorPicker(nameControl, idControl, iconControl, linkControl, agentId, authorNameControl, authorNameIdControl, authorshipPosition) { 
	// initialize the controls for appropriate state given an agentId or not.
	if (agentId) { 
		$('#'+idControl).val(agentId);
		$('#'+iconControl).addClass('bg-lightgreen');
		$('#'+iconControl).removeClass('bg-light');
		$('#'+linkControl).html(" <a href='/agents/Agent.cfm?agent_id=" + agentId + "' target='_blank'>View</a>");
		$('#'+linkControl).attr('aria-label', 'View details for this agent');
	} else {
		$('#'+idControl).val("");
		$('#'+iconControl).removeClass('bg-lightgreen');
		$('#'+iconControl).addClass('bg-light');
		$('#'+linkControl).html("");
		$('#'+linkControl).removeAttr('aria-label');
	}
	$('#'+nameControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/agents/component/search.cfc",
				data: { 
					term: request.term, 
					method: 'getAuthorAutocompleteMeta' 
				},
				dataType: 'json',
				success : function (data) { 
					// return the result to the autocomplete widget, select event will fire if item is selected.
					response(data); 
				},
				error : function (jqXHR, status, error) {
					var message = "";
					if (error == 'timeout') { 
						message = ' Server took too long to respond.';
               } else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
                  message = ' Backing method did not return JSON.';
					} else { 
						message = jqXHR.responseText;
					}
					messageDialog('Error:' + message ,'Error: ' + error);
					$('#'+idControl).val("");
					$('#'+iconControl).removeClass('bg-lightgreen');
					$('#'+iconControl).addClass('bg-light');
					$('#'+linkControl).html("");
					$('#'+linkControl).removeAttr('aria-label');
				}
			})
		},
		select: function (event, result) {
			// Handle case of a selection from the pick list.  Indicate successfull pick.
			console.log(result);
			console.log(authorshipPosition);
			// cleanup from previous state
			$('#'+authorNameControl).html("");
			$('#'+authorNameIdControl).val("");
			// set values based on selection
			$('#'+idControl).val(result.item.id);
			$('#'+linkControl).html(" <a href='/agents/Agent.cfm?agent_id=" + result.item.id + "' target='_blank'>View</a> <a href='/agents/editAgent.cfm?agent_id=" + result.item.id + "' target='_blank'>Edit</a> " + result.item.value);
			$('#'+linkControl).attr('aria-label', 'View details for this agent');
			$('#'+iconControl).addClass('bg-lightgreen');
			$('#'+iconControl).removeClass('bg-light');
			// if result doesn't include the author name/id data, will need to make another call at this point to getAgentNameOfType to find those values for the selected agent_id
			if (authorshipPosition==1) { 
				$('#'+authorNameControl).html(result.item.firstauthor_name);
				$('#'+authorNameIdControl).val(result.item.firstauthor_agent_name_id);
			} else {
				$('#'+authorNameControl).html(result.item.secondauthor_name);
				$('#'+authorNameIdControl).val(result.item.secondauthor_agent_name_id);
			}
			if ($('#'+authorNameIdControl).val()=='') { 	
				// name of desired type is not available
				$('#missingNameDiv').show();
				$('#addButton').addClass('disabled');
				$('#addButton').prop('disabled',true);
				$('#addNameButton').removeClass('disabled');
				$('#addNameButton').prop('disabled',false);
			} else { 
				// name of desired type is available
				$('#missingNameDiv').hide();
				$('#addButton').removeClass('disabled');
				$('#addButton').prop('disabled',false);
				$('#addNameButton').addClass('disabled');
				$('#addNameButton').prop('disabled',true);
			}
		},
		change: function(event,ui) { 
			if(!ui.item){
				// handle a change that isn't a selection from the pick list, clear the controls.
				$('#'+idControl).val("");
				$('#'+nameControl).val("");
				$('#'+iconControl).removeClass('bg-lightgreen');
				$('#'+iconControl).addClass('bg-light');	
				$('#'+linkControl).html("");
				$('#'+linkControl).removeAttr('aria-label');
				$('#addButton').addClass('disabled');
				$('#addButton').prop('disabled',true);
				$('#addNameButton').addClass('disabled');
				$('#addNameButton').prop('disabled',true);
				$('#'+authorNameControl).html("");
				$('#'+authorNameIdControl).val("");
				$('#missingNameDiv').hide();
			}
		},
		minLength: 3
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta "matched name * (preferred name)" instead of value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};

function addAuthor(agent_name_id,publication_id,author_position,author_role,okcallback) { 
	jQuery.ajax({
		dataType: "json",
		url: "/publications/component/functions.cfc",
		data : {
			method : "addAuthor",
			agent_name_id: agent_name_id,
			publication_id: publication_id,
			author_position: author_position,
			author_role: author_role,
			returnformat : "json",
			queryformat : 'column'
		},
		success: function (retval) {
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
			$('#form_to_add_span').html('second author');
			var result = jQuery.parseJSON(retval);
			console.log(result);
			var status = result[0].status;
			if (status=='added') {
				var agent_id = result[0].agent_id;
				var agent_name = result[0].agent_name;
				console.log(agent_name);
				$('<li><a href="/agents/Agent.cfm?agent_id='+agent_id+'">'+agent_name+'</a></li>').appendTo('#authorListOnDialog');
			}
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"adding author/editor to publication");
		},
		dataType: "html"
	});
}

/** loadPubAttribtueControl load html for an input for a publication attribute
 * bound to appropriate controls for values for the attribute type.
 * @param attribute the attribute type for the input
 * @param value the attribute value, if to populate the input with
 * @param name a name to give the input for submission in a form
 * @param id the id in the DOM for the input without a leading # selector.
 * @param targetDivId the id without a leading # selector of the element in 
 *  the dom the html content of which to replace with the returned input.
*/
function loadPubAttributeControl(attribute,value,name,id,targetDivId) { 
	jQuery.ajax({
		url: "/publications/component/functions.cfc",
		data : {
			method : "getPubAttributeControl",
			form: "plain",
			attribute: attribute,
			value: value,
			name: name,
			id: id
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading publication attribute input control");
		},
		dataType: "html"
	});
};
