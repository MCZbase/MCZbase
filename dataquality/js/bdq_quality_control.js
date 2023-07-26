
/** 
 * function loadEventQC
 * 
 * Given an collection object id and the id of a target div into which to place results
 * make an ajax call on getEventQCReportFlat(), take the results, and place them in 
 * human readable form as html as the content of the target div.
 * @param collection_object_id of the collection object to run the TDWG BDQ TG2 event tests on, selects
 *   target FLAT if specified.
 * @param collecting_event_id of the locality to run the TDWG BDQ TG2 space tests on, selects 
 *  target COLLEVENT if provided and collection_object_id is null.
 * @param targetDivId the id of an element in the DOM of which to replace the content with the results.
 */
function loadEventQC(collection_object_id,collecting_event_id,targetDivId){
   var target_id = "";
   var target = "";
	if (collection_object_id && String(collection_object_id).length > 0) { 
		target_id = String(collection_object_id);
		target = "FLAT";
		$("#"+targetDivId).html("<div>Running Event Quality Control Tests...</div>");
	} else if (collecting_event_id && String(collecting_event_id).length > 0) {
		target_id = String(collecting_event_id);
		target = "COLLEVENT";
		$("#"+targetDivId).html("<div>Running Event Quality Control Tests...</div>");
	} else { 
		$("#" + targetDivId).html("Error: Neither a collection_object_id nor a collecting_event_id was provided." );
	}
	$.ajax({
		url: "/dataquality/component/functions.cfc",
		type: "get",
		data: {
			method: "getEventQCReportFlat",
			returnformat: "json",
			target: target,
			target_id: target_id
		}, 
		success: function (datareturn) { 
		data = JSON.parse(datareturn);
		  if (data.STATUS == "success") { 
				displayQCResult(data,"Event",targetDivId);
			} else { 
				$("#"+targetDivId).html("<h2>Error:</h2><div>" + data.ERROR + "</div>");
			}
		}, 
		fail: function (jqXHR, textStatus) { 
			$("#" + targetDivId).html("Error:" + textStatus);
		}
	});
}

/** 
 * function loadNameQC
 * 
 * Given an collection object id and the id of a target div into which to place results
 * make an ajax call on getNameQCReportFlat(), take the results, and place them in 
 * human readable form as html as the content of the target div.
 * @param collection_object_id of the collection object to run the TDWG BDQ TG2 NAME tests on.
 * @param taxon_name_id of the taxonomy record to run the TDWG BDQ TG2 NAME tests on, used if
 *   collection_object_id is empty.
 * @param targetDivId the id of an element in the DOM of which to replace the content with the results.
 */
function loadNameQC(collection_object_id,taxon_name_id,targetDivId){
   var target_id = "";
   var target = "";
   console.log(collection_object_id);
   console.log(taxon_name_id);
	if (collection_object_id && String(collection_object_id).length > 0) { 
		target_id = String(collection_object_id);
		target = "FLAT";
		$("#"+targetDivId).html("<div>Running Taxon Quality Control Tests...</div>");
	} else if (taxon_name_id && String(taxon_name_id).length > 0) {
		target_id = String(taxon_name_id);
		target = "TAXONOMY";
		$("#"+targetDivId).html("<div>Running Taxon Quality Control Tests...</div>");
	} else { 
		$("#" + targetDivId).html("Error: Neither a collection_object_id nor a taxon_name_id was provided." );
	}
	$.ajax({
		url: "/dataquality/component/functions.cfc",
		type: "get",
		data: {
			method: "getNameQCReport",
			returnformat: "json",
			target_id: target_id,
			target: target
		}, 
		success: function (datareturn) { 
		data = JSON.parse(datareturn);
		  if (data.STATUS == "success") { 
				displayQCResult(data,"Taxon Name",targetDivId);
			} else { 
				$("#"+targetDivId).html("<h2>Error:</h2><div>" + data.ERROR + "</div>");
			}
		}, 
		fail: function (jqXHR, textStatus) { 
			$("#" + targetDivId).html("Error:" + textStatus);
		}
	});
}

/** 
 * function loadSpaceQC
 * 
 * Given an collection object id and the id of a target div into which to place results
 * make an ajax call on getSpaceQCReportFlat(), take the results, and place them in 
 * human readable form as html as the content of the target div.
 * @param collection_object_id of the collection object to run the TDWG BDQ TG2 space tests on,
 *   selects target FLAT if a value is provided.
 * @param locality_id of the locality to run the TDWG BDQ TG2 space tests on, selects 
 *  target LOCALITY if provided and collection_object_id is null.
 * @param targetDivId the id of an element in the DOM of which to replace the content with the 
 *  results, without a leading # selector.
 */
function loadSpaceQC(collection_object_id,locality_id,targetDivId){
   var target_id = "";
   var target = "";
	if (collection_object_id && String(collection_object_id).length > 0) { 
		target_id = String(collection_object_id);
		target = "FLAT";
		$("#"+targetDivId).html("<div>Running Spatial Quality Control Tests...</div>");
	} else if (locality_id && String(locality_id).length > 0) {
		target_id = String(locality_id);
		target = "LOCALITY";
		$("#"+targetDivId).html("<div>Running Spatial Quality Control Tests...</div>");
	} else { 
		$("#" + targetDivId).html("Error: Neither a collection_object_id nor a locality_id was provided." );
	}
	$.ajax({
		url: "/dataquality/component/functions.cfc",
		type: "get",
		data: {
			method: "getSpaceQCReport",
			returnformat: "json",
			target: target,
			target_id: target_id
		}, 
		success: function (datareturn) { 
		data = JSON.parse(datareturn);
		  if (data.STATUS == "success") { 
				displayQCResult(data,"Geospatial",targetDivId);
			} else { 
				$("#"+targetDivId).html("<h2>Error:</h2><div>" + data.ERROR + "</div>");
			}
		}, 
		fail: function (jqXHR, textStatus) { 
			$("#" + targetDivId).html("Error:" + textStatus);
		}
	});
}

/**
 * Render the results of a QC test in html
 *
 * @param data the data object returned from an ajax call to a qc backing method, expected to 
 *  contain data.guid, data.preamedment, data.postamendment, data.amendment, etc.
 * @param category a label for the test category, e.g. Event, Taxon Name, Geospatial of which
 *  these are the results.
 * @param targetDivId the id of a div in the DOM for which to replace the html content of with
 *   the test results, specified without a leading # selector.
 */
function displayQCResult(data,category,targetDivId) { 
	// extract the phases from the returned result
	var pre = data.PREAMENDMENT;   // extract pre-amendment phase test results
	var post = data.POSTAMENDMENT; // extract post-amendment phase results
	var amend = data.AMENDMENT;	 // extract amendments

	// variables to assemble display output
	var display = "<h2>QC " + category + " for " +data.guid+"</h2>";   // output to display as the result of the invocation of this method
	display = display + "<div>Results of the TDWG Biodiversity Data Quality IG TG2 " + category + "  related tests.</div>";
	display = display + "<div>Tests run using (mechanism): " + data.MECHANISM + ".</div>";
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
		console.log(k);
		counter ++;
		if (counter % 2 == 0) { rowstyle = ""; } else { rowstyle = "style='background-color: #f2f2f2;'"; }
		var key = pre[k];
		if (key.STATUS == "RUN_HAS_RESULT" && key.VALUE == "COMPLIANT") {
			prepass = prepass + 1;
			cs="<span style='color: green;'><strong>"; ce="</strong></span>";
			status = "";  // don't show status when there is a result
		} else { 
			if (key.STATUS == "RUN_HAS_RESULT" && key.VALUE == "NOT_COMPLIANT") {
				cs="<span style='color: red;'><strong>"; ce="</strong></span>";
				status = "";  // don't show status when there is a result
			} else { 
				cs=""; ce="";
				status = key.STATUS;  // show the status when there is no result.
			}
		}
		if (key.TYPE == "VALIDATION") { 
			validationcount = validationcount + 1; 
			// pre-amendment results for this test.
			displayprepost = displayprepost + "<tr " +rowstyle+ "><td>" + key.LABEL + "</td><td>" + status + " " + cs + key.VALUE + ce  + "</td><td>" + key.COMMENT + "</td>";
			// find matching post-amendment results for this test.
			var postkey = post[k];
			if (postkey.STATUS == "RUN_HAS_RESULT" && postkey.VALUE == "COMPLIANT") {
				cs="<span style='color: green;'><strong>"; ce="</strong></span>";
				status = "";
			} else { 
				if (postkey.STATUS == "RUN_HAS_RESULT" && postkey.VALUE == "NOT_COMPLIANT") {
					cs="<span style='color: red;'><strong>"; ce="</strong></span>";
					status = "";
				} else { 
					cs=""; ce="";
					status = key.STATUS;
				}
			}
			displayprepost = displayprepost + "<td>" + status + " " + cs + postkey.VALUE + ce  + "</td><td> " + postkey.COMMENT + "</td></tr>";
		} else { 
			if (counter % 2 == 0) { rowstyle = "style='background-color: #ccffcc;'"; } else { rowstyle = "style='background-color: #e6ffe6;'"; }
			// is a MEASURE (or possibly ISSUE), note that amendments won't be in this phase.
			displaymeasure = displaymeasure + "<tr " + rowstyle+ "><td>" + key.LABEL + "</td><td>" + key.STATUS + " " + cs + key.VALUE + ce  + "</td><td>" + key.COMMENT + "</td>";
			var postkey = post[k];
			displaymeasure = displaymeasure + "<td>" + postkey.STATUS + " " + postkey.VALUE + "</td><td>" + postkey.COMMENT + "</td></tr>";
		}
	}

	// Iterate through amendments (would need to obtain acted upon/consulted annotations on terms to fully present as changes to terms).
	// Could extract change terms from values and present in term centric rather than test centric view.
	var amendmentCount = 0;
	for (var k in amend) { 
		var key = amend[k];
		var spanClass = '';
		if (key.STATUS == 'AMENDED' || key.STATUS=='FILLED_IN') {
			spanClass="";
			var commentbit = key.COMMENT;
			commentbit = commentbit.toUpperCase();
			if (key.STATUS == 'FILLED IN') {   		
  					cs="<span style='color: blue;'><strong>"; ce="</strong></span>";
			} else { 		
  					cs="<span style='color: red;'><strong>"; ce="</strong></span>";
			}
		} else { 
  				cs=""; ce="";
				spanClass=" class='text-muted' ";
		}
		displayamendments = displayamendments + "<li><span " + spanClass + ">" + key.LABEL + " " + key.STATUS + " " + cs + key.VALUE + ce + " " + key.COMMENT + "</span></li>";
		amendmentCount++;
	}
	if (amendmentCount==0) { 
		displayamendments = displayamendments + "<li><span>None</span></li>";
	}

	// Iterate through post-amendment tests to calculate postpass.
	for (var k in post) { 
		var key = post[k];
		if (key.STATUS == "RUN_HAS_RESULT" && key.VALUE == "COMPLIANT") { 
			postpass = postpass + 1;
		}
	}
	
	// assemble and display the result
	display = display + "<div>Compliant Results Pre-amendment: " + Math.round((prepass/validationcount)*100) + "%; Post-amendment: " + Math.round((postpass/validationcount)*100) + "% </div>";
	displayprepostheader = "<tr style='background-color: #ccffff;'><th>Test</th><th>Pre-amendment Result</th><th>Comment</th><th>Post-Amendment Result</th><th>Comment</th></tr>";
	display = display + "<table style='border: 1px solid #ddd;' >" + displayprepostheader + displaymeasure + displayprepost + "</table>";
	display = display + "<h3>Proposed Amendments</h3><div><ul>" + displayamendments + "</ul></div>";

	$("#"+targetDivId).html(display);
}
