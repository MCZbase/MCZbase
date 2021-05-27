/** Scripts specific to agent pages. **/

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
      error: function (jqXHR, status, message) {
         if (jqXHR.responseXML) { msg = jqXHR.responseXML; } else { msg = jqXHR.responseText; }
         messageDialog("Error checking existance of preferred name: " + message + " " + msg ,'Error: '+ message);
      },
      dataType: "html"
   });
};
