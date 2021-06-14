/** Scripts specific to agent pages. **/

/** function checkPrefNameExists check to see if there is an exact match for a preferred name
 * @param preferred_name a name string to check against existing preferred names.
 * @param target id of a dom element into which to place the results of the check.
 */
function checkPrefNameExists(preferred_name,target) {
	jQuery.ajax({
		url: "/agents/component/functions.cfc",
		data : {
		method : "checkPrefNameExists",
		pref_name: preferred_name
	},
	success: function (result) {
		var matches = jQuery.parseJSON(result);
		var matchcount = matches.length;
		console.log(matches);
		if (matchcount==0) { 
			$("#" + target).html("No duplicates.");
		} else {
			var s = "s";
			if (matchcount==1) { 
				s = "";
			}
			$("#" + target).html("<a href='/Agents.cfm?execute=true&method=getAgents&anyName=%3D" + preferred_name + "' target='_blank'>" + matchcount + " agent"+s+" with same name</a>");
		}
	},
	error: function (jqXHR, textStatus, error) {
		handleFail(jqXHR,textStatus,error, "Error checking existence of preferred name: "); 
	},
		dataType: "html"
	});
};

/** function checkNameExists check to see if there is a case insensitive exact 
 * match for a specified name against any agent name.
 *
 * @param preferred_name a name string to check against existing agent names.
 * @param target id of a dom element into which to place the results of the check.
 * @param expect_one affects text of response, if true, then one match is expected,
 *  as in editing an existing agent, if false then no matches are expected as in 
 *  adding a new agent.
 */
function checkNameExists(preferred_name,target,expect_one) {
	jQuery.ajax({
		url: "/agents/component/functions.cfc",
		data : {
		method : "checkPrefNameExists",
		pref_name: preferred_name
	},
	success: function (result) {
		var matches = jQuery.parseJSON(result);
		var matchcount = matches.length;
		console.log(matches);
		if (expect_one===true) {
			if (matchcount==0) { 
				$("#" + target).html("No agents with this name.");
			} else {
				if (matchcount==1) { 
					$("#" + target).html("<a href='/Agents.cfm?execute=true&method=getAgents&anyName=%3D" + preferred_name + "' target='_blank'> one agent with this name</a>");
				} else { 
					$("#" + target).html("<a href='/Agents.cfm?execute=true&method=getAgents&anyName=%3D" + preferred_name + "' target='_blank'>" + matchcount + " agents with this name</a>");
				}
			}
		} else {
			if (matchcount==0) { 
				$("#" + target).html("no duplicates.");
			} else {
				var s = "s";
				if (matchcount==1) { 
					s = "";
				}
				$("#" + target).html("<a href='/Agents.cfm?execute=true&method=getAgents&anyName=%3D" + preferred_name + "' target='_blank'>" + matchcount + " agent"+s+" with same name</a>");
			}
		}
	},
	error: function (jqXHR, textStatus, error) {
		handleFail(jqXHR,textStatus,error, "Error checking existence of preferred name: "); 
	},
		dataType: "html"
	});
};
/** function checkNameExistsAlso check to see if there is a case insensitive exact 
 * match for a specified name against any agent name.
 *
 * @param preferred_name a name string to check against existing agent names.
 * @param target id of a dom element into which to place the results of the check.
 * @param expect_one affects text of response, if true, then one match is expected,
 *  as in editing an existing agent, if false then no matches are expected as in 
 *  adding a new agent.
 */
function checkNameExistsAlso(preferred_name,target,agent_id) {
	jQuery.ajax({
		url: "/agents/component/functions.cfc",
		data : {
		method : "checkPrefNameExists",
		pref_name: preferred_name,
		not_agent_id: agent_id
	},
	success: function (result) {
		var matches = jQuery.parseJSON(result);
		var matchcount = matches.length;
		if (matchcount==0) { 
			$("#" + target).html("No duplicates.");
		} else {
			var s = "s";
			if (matchcount==1) { 
				s = "";
			}
			$("#" + target).html("<a href='/Agents.cfm?execute=true&method=getAgents&anyName=%3D" + preferred_name + "' target='_blank'>" + matchcount + " other agent"+s+" with same name</a>");
		}
	},
	error: function (jqXHR, textStatus, error) {
		handleFail(jqXHR,textStatus,error, "Error checking existence of preferred name: "); 
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

/* Update the content of a div containing names for an agent.
 *
 * @param agent_id the agent_id of the agent for which to lookup names
 * @param targetDiv the id div for which to replace the contents, without a leading # selector.
 */
function updateAgentNames(agent_id,targetDiv) {
	jQuery.ajax({
		url: "/agents/component/functions.cfc",
		data : {
			method : "getAgentNamesHTML",
			agent_id: agent_id
		},
		success: function (result) {
			$("#"+targetDiv).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"obtaining names for an agent");
		},
		dataType: "html"
	});
};

/* Save a change to an existing agent name.
 *
 * @param agentNameIdControl id of an input containing the PK name to update, without a leading # selector.
 * @param nameValueControl id of an input containing the new value of the agent name, without a leading # selector.
 * @param nameTypeControl id of an input cotnaining the new value of the agent name type, without a leading # selector.
 * @param feedbackControl a control within which to display feedback, without a leading # selector.
 */
function saveAgentName(agent_id, agentNameIdControl, nameValueControl, nameTypeControl,feedbackControl) {
	var agent_name_id = $('#'+agentNameIdControl).val();
	var agent_name = $('#'+nameValueControl).val();
	var agent_name_type = $('#'+nameTypeControl).val();
	$('#'+feedbackControl).html("Saving...");
	jQuery.getJSON("/agents/component/functions.cfc",
		{
			method : "updateAgentName",
			agent_id : agent_id,
			agent_name_id : agent_name_id,
			agent_name_type : agent_name_type,
			agent_name : agent_name,
			returnformat : "json",
			queryformat : 'struct'
		},
		function (result) {
			if (result[0].STATUS==1) {
				$('#'+feedbackControl).html("Saved");
			} else {
				$('#'+feedbackControl).html("Error");
				alert(result[0].MESSAGE);
			}
		}
	).fail(function(jqXHR,textStatus,error){
		$('#'+feedbackControl).html("Error");
		handleFail(jqXHR,textStatus,error,"updating agent name");
	});
}

/* Delete an existing agent name from an agent
 *
 * @param agentNameIdControl id of an input containing the PK of name to delete, without a leading # selector.
 * @param callback a callback function to invoke on completion.
 */
function deleteAgentName(agentNameIdControl, callback) {
	var agent_name_id = $('#'+agentNameIdControl).val();
	jQuery.getJSON("/agents/component/functions.cfc",
		{
			method : "deleteAgentName",
			agent_name_id : agent_name_id,
			returnformat : "json",
			queryformat : 'struct'
		},
		function (result) {
			if (jQuery.type(callback)==='function') {
				callback();
			}
			if (result[0].STATUS!=1) {
				alert(result[0].MESSAGE);
			}
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"updating agent name");
	});
}

/* Add a new agent name to an agent.
 *
 * @param agent_id the agent to which to add the name.
 * @param nameValueControl a control from which to get the value of the agent_name to add, without a leading # selector.
 * @param nameTypeControl a control from which to get the value of the agent_name_type, without a leading # selector.
 * @param callback a callback function to invoke on completion.
 */
function addNameToAgent(agent_id,nameValueControl,nameTypeControl,callback) {
	var agent_name = $('#'+nameValueControl).val();
	var agent_name_type = $('#'+nameTypeControl).val();
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
			if (jQuery.type(callback)==='function') {
				callback();
			}
			if (result[0].STATUS!=1) {
				alert(result[0].MESSAGE);
			}
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"adding name to agent");
	});
}

/* Update the content of a div containing group membership for an agent.
 *
 * @param agent_id the agent_id of the agent for which to lookup group membership
 * @param targetDiv the id div for which to replace the contents, without a leading # selector.
 */
function updateGroupMembers(agent_id,targetDiv) {
	jQuery.ajax({
		url: "/agents/component/functions.cfc",
		data : {
			method : "getGroupMembersHTML",
			agent_id: agent_id
		},
		success: function (result) {
			$("#"+targetDiv).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"obtaining group membership for an agent");
		},
		dataType: "html"
	});
};

/* Add an agent to a group with an ordinal position and a callback function.
 * @param agent_id the group to which to add the member
 * @param member_agent_id the agent to add to the group as a member
 * @param ordinal_position the 1 indexed position of the member in the group.
 * @param callback the callback function to invoke on success.
 */
function addAgentToGroupCB(agent_id,member_agent_id,ordinal_position,callback) {
	jQuery.getJSON("/agents/component/functions.cfc",
		{
			method : "addAgentToGroup",
			agent_id : agent_id,
			member_agent_id : member_agent_id,
			member_position : ordinal_position,
			returnformat : "json",
			queryformat : 'struct'
		},
		function (result) {
			if (jQuery.type(callback)==='function') {
				callback();
			}
			if (result[0].STATUS!=1) {
				alert(result[0].MESSAGE);
			}
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"adding agent to group");
	});
};

function removeAgentFromGroupCB(agent_id,member_agent_id,callback) {
	jQuery.getJSON("/agents/component/functions.cfc",
		{
			method : "removeAgentFromGroup",
			agent_id : agent_id,
			member_agent_id : member_agent_id,
			returnformat : "json",
			queryformat : 'struct'
		},
		function (result) {
			if (jQuery.type(callback)==='function') {
				callback();
			}
			if (result[0].STATUS!=1) {
				alert(result[0].MESSAGE);
			}
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"removing agent from group");
	});
};

function moveAgentInGroupCB(agent_id,member_agent_id,direction,callback) {
	jQuery.getJSON("/agents/component/functions.cfc",
		{
			method : "moveAgentInGroup",
			agent_id : agent_id,
			member_agent_id : member_agent_id,
			direction: direction,
			returnformat : "json",
			queryformat : 'struct'
		},
		function (result) {
			if (jQuery.type(callback)==='function') {
				callback();
			}
			if (result[0].STATUS!=1) {
				alert(result[0].MESSAGE);
			}
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"moving position of agent in group");
	});
};

/* Update the content of a div containing addresses for an agent
 *
 * @param agent_id the agent_id of the agent for which to lookup addresses
 * @param targetDiv the id div for which to replace the contents, without a leading # selector.
 */
function updateAgentAddresses(agent_id,targetDiv) {
	jQuery.ajax({
		url: "/agents/component/functions.cfc",
		data : {
			method : "getAgentAddressesHTML",
			agent_id: agent_id
		},
		success: function (result) {
			$("#"+targetDiv).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"obtaining relationships for an agent");
		},
		dataType: "html"
	});
};


/** given a div with a specified id and an agent_id, create dialog to create a new
 *  address of a specfied type for the given agent.  */
function addAddressForAgent(agentIdControl,addressTypeControl,dialogDivId,callback) { 
	var agent_id = $("#"+agentIdControl).val();
	var address_type = $("#"+addressTypeControl).val();

	jQuery.ajax({
		url: "/agents/component/functions.cfc",
		type : "get",
		dataType : "json",
		data : {
			method : "addAddressHtml",
			agent_id : agent_id,
			address_type : address_type
		},
		success: function (result) {
			$("#"+dialogDivId).html(result);
			$("#"+dialogDivId).dialog(
				{ autoOpen: false, modal: true, stack: true, title: 'Add Address',
					width: 593, 	
					buttons: {
						"Close": function() {
							$("#"+dialogDivId).dialog( "close" );
						}
					},
					beforeClose: function(event,ui) { 
						var addr = $('#new_address').val();
						if (jQuery.type(callback)==='function') {
							callback();
						}
					},
					close: function(event,ui) { 
						$("#"+dialogDivId).dialog('destroy'); 
						$("#"+dialogDivId).html(""); 
					}
				});
				$("#"+dialogDivId).dialog('open');
			},
			error: function (jqXHR, textStatus, error) {
				handleFail(jqXHR,textStatus,error,"opening dialog to add an address to an agent");
			},
			dataType: "html"
		}
	)
};

function editAddressForAgent(addr_id,dialogDivId,callback){
	jQuery.ajax({
		url: "/agents/component/functions.cfc",
		type : "get",
		dataType : "json",
		data : {
			method : "addAddressHtml",
			addr_id: addr_id
		},
		success: function (result) {
			$("#"+dialogDivId).html(result);
			$("#"+dialogDivId).dialog(
				{ autoOpen: false, modal: true, stack: true, title: 'Add Address',
					width: 593, 	
					buttons: {
						"Close": function() {
							$("#"+dialogDivId).dialog( "close" );
						}
					},
					beforeClose: function(event,ui) { 
						if (jQuery.type(callback)==='function') {
							callback();
						}
					},
					close: function(event,ui) { 
						$("#"+dialogDivId).dialog('destroy'); 
						$("#"+dialogDivId).html(""); 
					}
				});
				$("#"+dialogDivId).dialog('open');
			},
			error: function (jqXHR, textStatus, error) {
				handleFail(jqXHR,textStatus,error,"opening dialog to edit an address");
			},
			dataType: "html"
		}
	)
};

/* Save a change to an existing address for an agent, the record to be updated is identified by
 * the addr_id
 *
 * @param agent_id the agent for which to update the address.
 * @param addressIdControl the id of an input containing the addr_id for the address to update,
 *   without a leading # selector.
 * @param feedbackControl a control within which to display feedback, without a leading # selector.
 */
function updateAgentAddress(agent_id, addressIdControl, addTypCtl, vaCtl, st1Ctl, st2Ctl, insCtl, deptCtl, cityCtl, stateCtl, ccCtl, zipCtl, mastCtl, jtCtl, remCtl,feedbackControl) {
	var addr_id = $('#'+addressIdControl).val();
	var add_type = $('#'+addTypCtl).val();
	var valid_addr_fg = $('#'+vaCtl).val();
	var street_addr1 = $('#'+s1Ctl).val();
	var street_addr2 = $('#'+s2Ctl).val();
	var institution = $('#'+insCtl).val();
	var department = $('#'+deptCtl).val();
	var city = $('#'+cityCtl).val();
	var state = $('#'+stateCtl).val();
	var country_cde = $('#'+ccCtl).val();
	var zip = $('#'+zipCtl).val();
	var mail_stop = $('#'+mastCtl).val();
	var job_title = $('#'+jtCtl).val();
	var addr_remarks = $('#'+remCtl).val();
	$('#'+feedbackControl).html("Saving...");
	jQuery.getJSON("/agents/component/functions.cfc",
		{
			method : "updateAddress",
			agent_id: agent_id,
			addr_id: addr_id,
			addr_type: addr_type,
			street_addr1: street_addr1,
			street_addr2: street_addr2,
			institution: institution,
			department: department,
			city: city,
			country_cde: country_cde,
			zip: zip,
			mail_stop: mail_stop,
			job_title: job_title,
			addr_remarks: addr_remarks,
			returnformat : "json",
			queryformat : 'struct'
		},
		function (result) {
			if (result[0].STATUS==1) {
				$('#'+feedbackControl).html("Saved");
			} else {
				$('#'+feedbackControl).html("Error");
				alert(result[0].MESSAGE);
			}
		}
	).fail(function(jqXHR,textStatus,error){
		$('#'+feedbackControl).html("Error");
		handleFail(jqXHR,textStatus,error,"updating address");
	});
}

/* Delete an existing address
 *
 * @param addr_id the address to delete.
 * @param callback a callback function to invoke on completion.
 */
function deleteAgentAddress(addr_id, callback) {
	jQuery.getJSON("/agents/component/functions.cfc",
		{
			method : "deleteAddress",
			addr_id : addr_id,
			returnformat : "json",
			queryformat : 'struct'
		},
		function (result) {
			if (jQuery.type(callback)==='function') {
				callback();
			}
			if (result[0].STATUS!=1) {
				alert(result[0].MESSAGE);
			}
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"deleting address");
	});
}

/* Add a new address to an agent.
 *
 * @param form_id a form containing fields with names matching the expected parameters for addAddressToAgent.
 * @param callback a callback function to invoke on completion.
 */
function addAddressToAgent(form_id, callback) {
   var formFields =  $('#'+form_id).serializeArray();
   formFields.push({ 
		method : "addAddressToAgent",
		returnformat : "json",
		queryformat : 'struct'
	});
	jQuery.getJSON("/agents/component/functions.cfc",
		formFields,
		function (result) {
			if (jQuery.type(callback)==='function') {
				callback();
			}
			if (result[0].STATUS!=1) {
				alert(result[0].MESSAGE);
			}
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"adding address to agent");
	});
}



/* Update the content of a div containing relationships for an agent.
 *
 * @param agent_id the agent_id of the agent for which to lookup relationships
 * @param targetDiv the id div for which to replace the contents, without a leading # selector.
 */
function updateAgentRelationships(agent_id,targetDiv) {
	jQuery.ajax({
		url: "/agents/component/functions.cfc",
		data : {
			method : "getAgentRelationshipsHTML",
			agent_id: agent_id
		},
		success: function (result) {
			$("#"+targetDiv).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"obtaining relationships for an agent");
		},
		dataType: "html"
	});
};


/* Save a change to an existing relationship for an agent, the record to be updated is identified by
 * the agent_id, old_related_agent_id, and old_relationship.
 *
 * @param agent_id the agent for which to update the relationship.
 * @param relatedAgentIdControl the id of an input containing the new value for the agent to be linked to,
 *   without a leading # selector.
 * @param relationshipControl the id of an input containing the new value for the relationship,
 *   without a leading # selector.
 * @param remarksControl the id of an input containing the new value for the remarks on the relationship,
 *   without a leading # selector.
 * @param oldRelatedAgentIdControl the id of an input containing the current value for the agent to be linked to,
 *   without a leading # selector.
 * @param oldRelationshipControl the id of an input containing the current value for the relationship,
 *   without a leading # selector.
 * @param feedbackControl a control within which to display feedback, without a leading # selector.
 */
function updateAgentRelationship(agent_id, relatedAgentIdControl, relationshipControl, remarksControl, oldRelatedAgentIdControl, oldRelationshipControl,feedbackControl) {
	var related_agent_id = $('#'+relatedAgentIdControl).val();
	var relationship = $('#'+relationshipControl).val();
	var agent_remarks = $('#'+remarksControl).val();
	var old_related_agent_id = $('#'+oldRelatedAgentIdControl).val();
	var old_relationship = $('#'+oldRelationshipControl).val();
	$('#'+feedbackControl).html("Saving...");
	jQuery.getJSON("/agents/component/functions.cfc",
		{
			method : "updateAgentRelationship",
			agent_id: agent_id,
			related_agent_id: related_agent_id,
			relationship : relationship,
			agent_remarks : agent_remarks,
			old_related_agent_id: old_related_agent_id,
			old_relationship : old_relationship,
			returnformat : "json",
			queryformat : 'struct'
		},
		function (result) {
			if (result[0].STATUS==1) {
				$('#'+feedbackControl).html("Saved");
			} else {
				$('#'+feedbackControl).html("Error");
				alert(result[0].MESSAGE);
			}
		}
	).fail(function(jqXHR,textStatus,error){
		$('#'+feedbackControl).html("Error");
		handleFail(jqXHR,textStatus,error,"updating agent relationship");
	});
}

/* Delete an existing relationship from an agent
 *
 * @param agentRelationshipIdControl input containing the email/phone to delete without a leading # selector.
 * @param callback a callback function to invoke on completion.
 */
function deleteAgentRelationship(agent_id, relatedAgentIdControl, relationshipControl,callback) {
	var related_agent_id = $('#'+relatedAgentIdControl).val();
	var relationship = $('#'+relationshipControl).val();
	jQuery.getJSON("/agents/component/functions.cfc",
		{
			method : "deleteAgentRelationship",
			agent_id : agent_id,
			related_agent_id : related_agent_id,
			relationship : relationship,
			returnformat : "json",
			queryformat : 'struct'
		},
		function (result) {
			if (jQuery.type(callback)==='function') {
				callback();
			}
			if (result[0].STATUS!=1) {
				alert(result[0].MESSAGE);
			}
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"deleting agent relationship");
	});
}

/* Add a new relationship to an agent.
 *
 * @param agent_id the agent to which to add the relationship.
 * @param relatedAgentIdControl a control from which to get the agent_id of the related agent, without a leading # selector/
 * @param relationControl a control from which to get the type of relationship to add, without a leading # selector.
 * @param remarksControl a control from which to get relationship remarks, without a leading # selector.
 * @param callback a callback function to invoke on completion.
 */
function addRelationshipToAgent(agent_id,relatedAgentIdControl,relationControl,remarksControl,callback) {
	var related_agent_id = $('#'+relatedAgentIdControl).val();
	var relationship = $('#'+relationControl).val();
	var agent_remarks = $('#'+remarksControl).val();
	jQuery.getJSON("/agents/component/functions.cfc",
		{
			method : "addRelationshipToAgent",
			agent_id : agent_id,
			related_agent_id : related_agent_id,
			relationship : relationship,
			agent_remarks : agent_remarks,
			returnformat : "json",
			queryformat : 'struct'
		},
		function (result) {
			if (jQuery.type(callback)==='function') {
				callback();
			}
			if (result[0].STATUS!=1) {
				alert(result[0].MESSAGE);
			}
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"adding relationship to agent");
	});
}



/* Update the content of a div containing emails/phone numbers for an agent.
 *
 * @param agent_id the agent_id of the agent for which to lookup electronic addresses
 * @param targetDiv the id div for which to replace the contents, without a leading # selector.
 */
function updateElectronicAddresses(agent_id,targetDiv) {
	jQuery.ajax({
		url: "/agents/component/functions.cfc",
		data : {
			method : "getElectronicAddressesHTML",
			agent_id: agent_id
		},
		success: function (result) {
			$("#"+targetDiv).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"obtaining phone numbers/emails for an agent");
		},
		dataType: "html"
	});
};

/* Save a change to an existing email/phone number for an agent.
 *
 * @param electronicAddressIdControl the id of an input containing the PK value of the
 *   email/phone to update, without a leading # selector.
 * @param addressControl the id of an input containing the new value of the electronic address,
 *   without a leading # selector.
 * @param addressTypeControl the id of ain input containing the new value of the electronic address
 *   type, without a leading # selector.
 * @param feedbackControl a control within which to display feedback, without a leading # selector.
 */
function updateElectronicAddress(agent_id, electronicAddressIdControl, addressControl, addressTypeControl,feedbackControl) {
	var electronic_address_id = $('#'+electronicAddressIdControl).val();
	var address = $('#'+addressControl).val();
	var address_type = $('#'+addressTypeControl).val();
	$('#'+feedbackControl).html("Saving...");
	jQuery.getJSON("/agents/component/functions.cfc",
		{
			method : "updateElectronicAddress",
			electronic_address_id: electronic_address_id,
			address_type : address_type,
			address : address,
			returnformat : "json",
			queryformat : 'struct'
		},
		function (result) {
			if (result[0].STATUS==1) {
				$('#'+feedbackControl).html("Saved");
			} else {
				$('#'+feedbackControl).html("Error");
				alert(result[0].MESSAGE);
			}
		}
	).fail(function(jqXHR,textStatus,error){
		$('#'+feedbackControl).html("Error");
		handleFail(jqXHR,textStatus,error,"updating electronic address (email/phone)");
	});
}

/* Delete an existing email/phone from an agent
 *
 * @param electronicAddressIdControl input containing the email/phone to delete without a leading # selector.
 * @param callback a callback function to invoke on completion.
 */
function deleteElectronicAddress(electronicAddressIdControl, callback) {
	var electronic_address_id = $('#'+electronicAddressIdControl).val();
	jQuery.getJSON("/agents/component/functions.cfc",
		{
			method : "deleteElectronicAddress",
			electronic_address_id : electronic_address_id,
			returnformat : "json",
			queryformat : 'struct'
		},
		function (result) {
			if (jQuery.type(callback)==='function') {
				callback();
			}
			if (result[0].STATUS!=1) {
				alert(result[0].MESSAGE);
			}
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"deleting electronic address (phone/email)");
	});
}

/* Add a new phone/email to an agent.
 *
 * @param agent_id the agent to which to add the electronic address.
 * @param addressControl a control from which to get the value of the address to add, without a leading # selector.
 * @param addressTypeControl a control from which to get the value of the address_type, without a leading # selector.
 * @param callback a callback function to invoke on completion.
 */
function addElectronicAddressToAgent(agent_id,addressControl,addressTypeControl,callback) {
	var address = $('#'+addressControl).val();
	var address_type = $('#'+addressTypeControl).val();
	jQuery.getJSON("/agents/component/functions.cfc",
		{
			method : "addElectronicAddressToAgent",
			agent_id : agent_id,
			address_type : address_type,
			address : address,
			returnformat : "json",
			queryformat : 'struct'
		},
		function (result) {
			if (jQuery.type(callback)==='function') {
				callback();
			}
			if (result[0].STATUS!=1) {
				alert(result[0].MESSAGE);
			}
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"adding electronic address (email/phone) to agent");
	});
}

// *** functions for dealing with agent ranks ****

function loadAgentRankSummary(targetId,agentId) {
	jQuery.getJSON("/agents/component/functions.cfc",
		{
			method : "getAgentRanks",
			agent_id : agentId,
			returnformat : 'json',
			queryformat : 'column'
		},
		function (result) {
			if (result.DATA.STATUS[0]==1) {
				var output = "Ranking: ";
				var flag = "";
				for (a=0; a<result.ROWCOUNT; ++a) {
					output = output + result.DATA.CT[a] + "&nbsp;" + result.DATA.AGENT_RANK[a];
					if (result.DATA.AGENT_RANK[a]=='F') {
						flag = "&nbsp;<img src='/agents/images/flag-red.svg.png' width='16'>";
					} else if (result.DATA.AGENT_RANK[a]=='B' && flag=="") { 
						flag ="&nbsp;<img src='/agents/images/flag-yellow.svg.png' width='16'>";
					} else if (result.DATA.AGENT_RANK[a]=='C' && flag=="") { 
						flag = "&nbsp;<img src='/agents/images/flag-yellow.svg.png' width='16'>";
					} else if (result.DATA.AGENT_RANK[a]=='D' && flag=="") { 
						flag = "&nbsp;<img src='/agents/images/flag-yellow.svg.png' width='16'>";
					}
					if (a<result.ROWCOUNT-1) { output = output + ";&nbsp;"; }
				}
				output = output + flag;
				$("#" + targetId).html(output);
			} else {
				$("#" + targetId).html(result.DATA.MESSAGE[0]);
			}
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"looking up agent rankings");
	});
}
/** insert a new record for the ranking of an agent into the agent_rank table 
 * @param agent_id the agent for which to add the ranking.
 * @param agent_rank the new rank value to add for the specified agent.
 * @param remark a remark concerning the ranking.
 * @param transaction_type the transaction type to which the ranking applies.
 * @param feedbackDivId the id in the dom, without a leading # selector into which to 
 *   place feedback from this function.
 */
function saveAgentRank(agent_id, agent_rank, remark, transaction_type,feedbackDivId) { 
	jQuery.getJSON("/component/functions.cfc",
		{
			method : "saveAgentRank",
			agent_id : agent_id,
			agent_rank : agent_rank,
			remark : remark,
			transaction_type : transaction_type,
			returnformat : 'json',
			queryformat : 'column'
		},
		function (data) {
			if(data.length>0 && data.substring(0,4)=='fail'){
				console.log(data);
				$('#' + feedbackDivId).append(data);
			} else {
				var feedback = 'Thank you for adding an agent rank.';
				$('#' + feedbackDivId).append(feedback);
			}
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"looking up agent rankings");
	});
}

/** Toggle the agent rank details block on the agent rank dialog.
 * @param toState if 1, change state to visible, otherwise change state to hidden.
 */
function tog_AgentRankDetail(toState){
	if(toState==1){
		document.getElementById('agentRankDetails').style.display='block';
		jQuery('#t_agentRankDetails').text('Hide Details').removeAttr('onclick').bind("click", function() {
			tog_AgentRankDetail(0);
		});
	} else {
		document.getElementById('agentRankDetails').style.display='none';
		jQuery('#t_agentRankDetails').text('Show Details').removeAttr('onclick').bind("click", function() {
			tog_AgentRankDetail(1);
		});
	}
}
/** given a div with a specified id and an agent_id, create dialog to view/add agent 
 *  rankings  */
function openRankDialog(dialogDivId,dialogTitle,agentId,callback) {
	jQuery.ajax({
		url: "/agents/component/functions.cfc",
		type : "get",
		dataType : "json",
		data : {
			method : "getAgentRankDialogHtml",
			agent_id : agentId
		},
		success: function (result) {
			$("#"+dialogDivId).html(result);
			$("#"+dialogDivId).dialog(
				{ autoOpen: false, 
					modal: true, 
					stack: true, 
					title: dialogTitle,
					width: 593, 	
					buttons: {
						"Close": function() {
							$("#"+dialogDivId).dialog( "close" );
						}
					},
					beforeClose: function(event,ui) { 
						if (jQuery.type(callback)==='function') {
							callback();
						}
					},
					close: function(event,ui) { 
						$("#"+dialogDivId).dialog('destroy'); 
						$("#"+dialogDivId).html(""); 
					}
				});
				$("#"+dialogDivId).dialog('open');
			},
			error: function (jqXHR, textStatus, error) {
				handleFail(jqXHR,textStatus,error,"opening dialog to rank an agent");
			},
			dataType: "html"
		}
	)
};
