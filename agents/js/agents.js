/** Scripts specific to agent pages. **/

/** function checPrefNameExists chec to see if there is an exact match for a preferred name
 * @param preferred_name a name string to check against existing preferred names.
 * @param target id of a dom element into which to place the results of the check.
 */
function checkPrefNameExists(preferred_name,target) {
   jQuery.ajax({
      url: "/agents/component/functions.cfc",
      data : {
         method : "checkPrefNameExists",
         pref_name: preferred_name,
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
