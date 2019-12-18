
/** 
 * function loadEventQC
 * 
 * Given an collection object id and the id of a target div into which to place results
 * make an ajax call on getEventQCReportFlat(), take the results, and place them in 
 * human readable form as html as the content of the target div.
 * @param collection_object_id of the collection object to run the TDWG BDQ TG2 event tests on.
 * @param targetid the id of an element in the DOM of which to replace the content with the results.
 */
function loadEventQC(collection_object_id,targetid){
  $.ajax({
     url: "/component/functions.cfc",
     type: "get",
     data: {
        method: "getEventQCReportFlat",
	     returnformat: "json",
		  collection_object_id	:collection_object_id
     }, 
     success: function (datareturn) { 
		data = JSON.parse(datareturn);
		  if (data.status == "success") { 
				var display = "<h2>"+data.guid+"</h2>";
				display = display "<div>Results of the TDWG Biodiversity Data Quality IG TG2 Event related tests.</div>";
				var dpre = "";
				var da = "";
				var dpost = "";
				var pre = data.preamendment;
				var post = data.postamendment;
				var amend = data.amendment;			
				var prepass = 0;
				var postpass = 0;
				var validationcount = 0;
				var cs = "";  
				var ce = "";
				var premeasure = "";
				var postmeasure = "";

				for (var k in pre) { 
					var key = pre[k];
					if (key.status == "HAS_RESULT" && key.value == "COMPLIANT") {
						prepass = prepass + 1;
						cs="<strong>"; ce="</strong>"  
					} else { 
						cs=""; ce="";
					}
					if (key.type == "VALIDATION") { 
						validationcount = validationcount + 1; 
						dpre = dpre + "<span>" + key.label + " " + key.status + " " + cs + key.value + ce  + " " + key.comment + "</span><br>";
					} else { 
						premeasure = premeasure + "<span>" + key.label + " " + key.status + " " + cs + key.value + ce  + " " + key.comment + "</span><br>";
					}
            }

				for (var k in amend) { 
					var key = amend[k];
					da = da + "<span>" + key.label + " " + key.status + " " + key.value + " " + key.comment + "</span><br>";
            }

				for (var k in post) { 
					var key = post[k];
					if (key.status == "HAS_RESULT" && key.value == "COMPLIANT") { 
						postpass = postpass + 1;
						cs="<strong>"; ce="</strong>"  
					} else { 
						cs=""; ce="";
					}
					if (key.type == "VALIDATION") { 
						dpost = dpost + "<span>" + key.label + " " + key.status + " " + cs + key.value + ce + " " + key.comment + "</span></br>";
					} else { 
						postmeasure = postmeasure + "<span>" + key.label + " " + key.status + " " + cs + key.value + ce + " " + key.comment + "</span></br>";
					}
            }
				
				display = display + "<div>Compliant Results Pre-amendment: " + Math.round((prepass/validationcount)*100) + "%; Post-amendment: " + Math.round((postpass/validationcount)*100) + "% </div>";
 
				display = display + "<h3>Pre-Ammendment Tests</h3><div>" + premeasure + dpre + "</div>";
				display = display + "<h3>Proposed Amendments</h3><div>" + da + "</div>";
				display = display + "<h3>Post-Amendment Tests</h3></div>" + postmeasure + dpost + "</div>";

            $("#"+targetid).html(display);
        } else { 
            $("#"+targetid).html("<h2>Error:</h2><div>" + data.error + "</div>");
		  }
     }, 
     fail: function (jqXHR, textStatus) { 
        $("#" + targetid).html("Error:" + textStatus);
     }
  });
}
