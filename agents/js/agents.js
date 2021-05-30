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
