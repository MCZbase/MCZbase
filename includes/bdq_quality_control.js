
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
				// extract the phases from the returned result
				var pre = data.preamendment;   // extract pre-amendment phase test results
				var post = data.postamendment; // extract post-amendment phase results
				var amend = data.amendment;	 // extract amendments

				// variables to assemble display output
				var display = "<h2>"+data.guid+"</h2>";   // output to display as the result of the invocation of this method
				display = display + "<div>Results of the TDWG Biodiversity Data Quality IG TG2 Event related tests.</div>";
				display = display + "<div>Tests run using (mechanism): " + data.mechanism + ".</div>";
				var displayamendments = "";   // results of amendment test formatted for display
				var displayprepost = "";  // results of pre- and post-amendment tests formatted for display
				var displayprepostheader = "";  // table header for pre- and post-amendment results formatted for display
				var displaymeasure = "";  // results of measures pre- and post-amendment formatted for display
				var status = "";  // to show or hide status from display
				var cs = "";  // open tag styling of status/value 
				var ce = "";  // close tag for styling of status/value
				var counter = 0;

				// variable for counting results
				var prepass = 0;  // total number of compliant tests pre-amendment
				var postpass = 0; // total number of compliant tests post-amendment
				var validationcount = 0;  // total number of validations run

				// iterate through preamendment tests, for each test found, look up the corresponding post-amendment test and 
				// obtain the results to display pre/post together in tabular form.
				for (var k in pre) { 
					counter ++;
					if (counter % 2 == 0) { rowstyle = ""; } else { rowstyle = "style='background-color: #f2f2f2;'"; }
					var key = pre[k];
					if (key.status == "HAS_RESULT" && key.value == "COMPLIANT") {
						prepass = prepass + 1;
						cs="<span style='color: green;'><strong>"; ce="</strong></span>";
						status = "";  // don't show status when there is a result
					} else { 
						if (key.status == "HAS_RESULT" && key.value == "NOT_COMPLIANT") {
							cs="<span style='color: red;'><strong>"; ce="</strong></span>";
							status = "";  // don't show status when there is a result
						} else { 
							cs=""; ce="";
							status = key.status;  // show the status when there is no result.
						}
					}
					if (key.type == "VALIDATION") { 
						validationcount = validationcount + 1; 
						// pre-amendment results for this test.
						displayprepost = displayprepost + "<tr " +rowstyle+ "><td>" + key.label + "</td><td>" + status + " " + cs + key.value + ce  + "</td><td>" + key.comment + "</td>";
						// find matching post-amendment results for this test.
						var postkey = post[k];
						if (postkey.status == "HAS_RESULT" && postkey.value == "COMPLIANT") {
							cs="<span style='color: green;'><strong>"; ce="</strong></span>";
							status = "";
						} else { 
							if (postkey.status == "HAS_RESULT" && postkey.value == "NOT_COMPLIANT") {
								cs="<span style='color: red;'><strong>"; ce="</strong></span>";
								status = "";
							} else { 
								cs=""; ce="";
								status = key.status;
							}
						}
						displayprepost = displayprepost + "<td>" + status + " " + cs + key.value + ce  + "</td><td> " + key.comment + "</td></tr>";
					} else { 
						if (counter % 2 == 0) { rowstyle = "style='background-color: #ccffcc;'"; } else { rowstyle = "style='background-color: #e6ffe6;'"; }
						// is a MEASURE (or possibly ISSUE), note that amendments won't be in this phase.
						displaymeasure = displaymeasure + "<tr " + rowstyle+ "><td>" + key.label + "</td><td>" + key.status + " " + cs + key.value + ce  + "</td><td>" + key.comment + "</td>";
						var postkey = post[k];
						displaymeasure = displaymeasure + "<td>" + postkey.status + " " + postkey.value + "</td><td>" + postkey.comment + "</td></tr>";
					}
				}

				// Iterate through amendments (would need to obtain acted upon/consulted annotations on terms to fully present as changes to terms).
				// Could extract change terms from values and present in term centric rather than test centric view.
				for (var k in amend) { 
					var key = amend[k];
					displayamendments = displayamendments + "<span>" + key.label + " " + key.status + " " + key.value + " " + key.comment + "</span><br>";
				}

				// Iterate through post-amendment tests to calculate postpass.
				for (var k in post) { 
					var key = post[k];
					if (key.status == "HAS_RESULT" && key.value == "COMPLIANT") { 
						postpass = postpass + 1;
					}
				}
				
				// assemble and display the result
				display = display + "<div>Compliant Results Pre-amendment: " + Math.round((prepass/validationcount)*100) + "%; Post-amendment: " + Math.round((postpass/validationcount)*100) + "% </div>";
				displayprepostheader = "<tr style='background-color: #ccffff;'><th>Test</th><th>Pre-amendment Result</th><th>Comment</th><th>Post-Amendment Result</th><th>Comment</th></tr>";
				display = display + "<table style='border: 1px solid #ddd;' >" + displayprepostheader + displaymeasure + displayprepost + "</table>";
				display = display + "<h3>Proposed Amendments</h3><div>" + displayamendments + "</div>";

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
