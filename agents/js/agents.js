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
         	$("#" + target).html("no duplicates.");
			} else {
				var s = "s";
				if (matchcount==1) { 
					s = "";
				}
         	$("#" + target).html("<a href='/agents/Agents.cfm?execute=true&method=getAgents&anyName=%3D" + preferred_name + "' target='_blank'>" + matchcount + " agent"+s+" with same name</a>");
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
   	      	$("#" + target).html("no agents with this name.");
				} else {
					if (matchcount==1) { 
   	      		$("#" + target).html("<a href='/agents/Agents.cfm?execute=true&method=getAgents&anyName=%3D" + preferred_name + "' target='_blank'> one agent with this name</a>");
					} else { 
   	      		$("#" + target).html("<a href='/agents/Agents.cfm?execute=true&method=getAgents&anyName=%3D" + preferred_name + "' target='_blank'>" + matchcount + " agents with this name</a>");
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
   	      	$("#" + target).html("<a href='/agents/Agents.cfm?execute=true&method=getAgents&anyName=%3D" + preferred_name + "' target='_blank'>" + matchcount + " agent"+s+" with same name</a>");
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
			console.log(matches);
			if (matchcount==0) { 
   	     	$("#" + target).html("no duplicates.");
			} else {
				var s = "s";
				if (matchcount==1) { 
					s = "";
				}
   	     	$("#" + target).html("<a href='/agents/Agents.cfm?execute=true&method=getAgents&anyName=%3D" + preferred_name + "' target='_blank'>" + matchcount + " other agent"+s+" with same name</a>");
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
