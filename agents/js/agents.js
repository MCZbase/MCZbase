/** Scripts specific to agent pages. **/

function checkPrefNameExists(preferred_name,target) {
   jQuery.ajax({
      url: "/agents/component/functions.cfc",
      data : {
         method : "checkPrefNameExists",
         pref_name: preferred_name,
      },
      success: function (result) {
			var matches = result.data;
			var matchcount = matches.length;
			console.log(matches);
         $("#" + target).html(matchcount + " existing agents with same name");
      },
      error: function (jqXHR, status, message) {
         if (jqXHR.responseXML) { msg = jqXHR.responseXML; } else { msg = jqXHR.responseText; }
         messageDialog("Error checking existance of preferred name: " + message + " " + msg ,'Error: '+ message);
      },
      dataType: "html"
   });
};
