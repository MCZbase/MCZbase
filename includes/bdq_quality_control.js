
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
				display = display + "<div>Results of the TDWG Biodiversity Data Quality IG TG2 Event related tests.</div>";
				var dpre = "";
				var da = "";
				var dpost = "";
				var dprepost = "";
				var dprepostheader = "";
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
				var status = "";

				// iterate through preamendment tests, for each test found, look up the corresponding post-amendment test and 
				// obtain the results to display pre/post together in tabular form.
				for (var k in pre) { 
					var key = pre[k];
					if (key.status == "HAS_RESULT" && key.value == "COMPLIANT") {
						prepass = prepass + 1;
						cs="<span style='font-color: green;'><strong>"; ce="</strong></span>";
						status = "";  // don't show status when there is a result
					} else { 
						if (key.status == "HAS_RESULT" && key.value == "NOT_COMPLIANT") {
							cs="<span style='font-color: red;'><strong>"; ce="</strong></span>";
							status = "";  // don't show status when there is a result
						} else { 
							cs=""; ce="";
							status = key.status;  // show the status when there is no result.
						}
					}
					if (key.type == "VALIDATION") { 
						validationcount = validationcount + 1; 
						// dpre = dpre + "<span>" + key.label + " " + status + " " + cs + key.value + ce  + " " + key.comment + "</span><br>";
						// pre-amendment results for this test.
						dprepost = dprepost + "<tr><td>" + key.label + "<td><td>" + status + " " + cs + key.value + ce  + "</td><td>" + key.comment + "</td>";
						// post-amendment results for this test.
						var postkey = post[k];
						if (postkey.status == "HAS_RESULT" && postkey.value == "COMPLIANT") {
							cs="<span style='font-color: green;'><strong>"; ce="</strong></span>";
							status = "";
						} else { 
							if (postkey.status == "HAS_RESULT" && postkey.value == "NOT_COMPLIANT") {
								cs="<span style='font-color: red;'><strong>"; ce="</strong></span>";
								status = "";
							} else { 
								cs=""; ce="";
								status = key.status;
							}
						}
						dprepost = dprepost + "<td>" + status + " " + cs + key.value + ce  + "</td><td> " + key.comment + "</td></tr>";
					} else { 
						// is a MEASURE (or possibly ISSUE), note that amendments won't be in this phase.
						// premeasure = premeasure + "<span>" + key.label + " " + key.status + " " + cs + key.value + ce  + " " + key.comment + "</span><br>";
						premeasure = premeasure + "<tr><td>" + key.label + "</td><td>" + key.status + " " + cs + key.value + ce  + "</td><td>" + key.comment + "</td>";
						var postkey = post[k];
						premeasure = premeasure + "<td>" + postkey.status + " " postkey.value + "</td><td>" + postkey.comment + "</td></tr>";
					}
            }

				// Iterate through amendments (would need to obtain acted upon/consulted annotations on terms to fully present as changes to terms).
				// Could extract change terms from values and present in term centric rather than test centric view.
				for (var k in amend) { 
					var key = amend[k];
					da = da + "<span>" + key.label + " " + key.status + " " + key.value + " " + key.comment + "</span><br>";
            }

				// Iterate through post-amendment tests to calculate postpass.
				for (var k in post) { 
					var key = post[k];
					if (key.status == "HAS_RESULT" && key.value == "COMPLIANT") { 
						postpass = postpass + 1;
						//cs="<span style='font-color: green;'><strong>"; ce="</strong></span>";
					//} else { 
					//	if (key.status == "HAS_RESULT" && key.value == "NOT_COMPLIANT") {
					//		cs="<span style='font-color: red;'><strong>"; ce="</strong></span>";
					//		status = "";
					//	} else { 
					//		cs=""; ce="";
					//		status = key.status;
					//	}
					}
					//if (key.type == "VALIDATION") { 
					//	dpost = dpost + "<span>" + key.label + " " + status + " " + cs + key.value + ce + " " + key.comment + "</span></br>";
					//} else { 
					//	postmeasure = postmeasure + "<span>" + key.label + " " + key.status + " " + cs + key.value + ce + " " + key.comment + "</span></br>";
					//}
            }
				
				display = display + "<div>Compliant Results Pre-amendment: " + Math.round((prepass/validationcount)*100) + "%; Post-amendment: " + Math.round((postpass/validationcount)*100) + "% </div>";
 
				dprepostheader = "<th><td>Test</td><td>Pre-amendment Result</td><td>Comment</td><td>Post-Amendment Result</td><td>Comment</td></th>";
				display = display + "<table>" + dprepostheader + premeasure + dprepost + "</table>";

				//display = display + "<h3>Pre-Ammendment Tests</h3><div>" + premeasure + dpre + "</div>";
				display = display + "<h3>Proposed Amendments</h3><div>" + da + "</div>";
				//display = display + "<h3>Post-Amendment Tests</h3></div>" + postmeasure + dpost + "</div>";


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
