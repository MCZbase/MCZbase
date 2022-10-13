/** Scripts specific to named group (underscore_collection) pages. **/

/** loadAgentDivHTML load a block of html listing agents related to 
 a named grouping.
 @param underscore_collection_id the primary key value for the named group 
   for which to retrieve related agents.
 @param targetDivId the id without a leading # selector for the element 
   on the page the content of which to replace with the html listing 
   agents.
*/
function loadAgentDivHTML(underscore_collection_id,targetDivId) { 
	jQuery.ajax({
		url: "/grouping/component/functions.cfc",
		data : {
			method : "getAgentDivHTML",
			underscore_collection_id: underscore_collection_id,
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading agent relationships for named group");
		},
		dataType: "html"
	});
};

// Create and open a dialog to create a new underscore_coll_agent record relating an agent to a named group
function openlinkagenttogroupingdialog(dialogid, underscore_collection_id, grouping_label, okcallback) { 
	var title = "Add a new relationship between an agent and the " + grouping_label;
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = 300;
	var w = $(window).width();
	w = Math.floor(w *.9);
	var thedialog = $("#"+dialogid).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		zindex: 2000,
		height: h,
		width: w,
		minWidth: 400,
		minHeight: 200,
		draggable:true,
		buttons: {
			"Save": function(){ 
				var datasub = $('#newAgentRelationForm').serialize();
				if ($('#newAgentRelationForm')[0].checkValidity()) {
					$.ajax({
						url: "/grouping/component/functions.cfc",
						type: 'post',
						returnformat: 'plain',
						dataType: 'json',
						data: datasub,
						success: function(data) { 
							if (jQuery.type(okcallback)==='function') {
								okcallback();
							};
							console.log(data);
							$("#agentAddResults").html("Saved " + data[0].role + " " + data[0].agent_name);
						},
						error:  function (jqXHR, textStatus,error) { 
							$("#agentAddResults").html("Error");
							handleFail(jqXHR,textStatus,error,"saving underscore_collection_agent record");
						}
					});	
		 		} else { 
					messageDialog('Missing required elements in form.  Fill in all yellow boxes. ','Form Submission Error, missing required values');
		 		};
		 	},
		 	"Close Dialog": function() { 
				if (jQuery.type(okcallback)==='function') {
					okcallback();
				}
			 	$("#"+dialogid+"_div").html("");
				$("#"+dialogid).dialog('close'); 
				$("#"+dialogid).dialog('destroy'); 
			}
		},
		close: function(event,ui) { 
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
		} 
	});
	thedialog.dialog('open');
	datastr = {
		method: "getNewAgentRelationHtml",
		returnformat: "plain",
		underscore_collection_id: underscore_collection_id
	};
	jQuery.ajax({
		url: "/grouping/component/functions.cfc",
		type: "post",
		data: datastr,
		success: function (data) { 
			$("#"+dialogid+"_div").html(data);
		}, 
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading new name group agent dialog");
		}
	});
}


// Create and open a dialog to edit an underscore_coll_agent record relating an agent to a named group
function openeditagenttogroupingdialog(dialogid, underscore_coll_agent_id, grouping_label, okcallback) { 
	var title = "Edit relationship between an agent and the " + grouping_label;
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = 300;
	var w = $(window).width();
	w = Math.floor(w *.9);
	var thedialog = $("#"+dialogid).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		zindex: 2000,
		height: h,
		width: w,
		minWidth: 400,
		minHeight: 200,
		draggable:true,
		buttons: {
			"Save": function(){ 
				var datasub = $('#editAgentRelationForm').serialize();
				if ($('#editAgentRelationForm')[0].checkValidity()) {
					$.ajax({
						url: "/grouping/component/functions.cfc",
						type: 'post',
						returnformat: 'plain',
						dataType: 'json',
						data: datasub,
						success: function(data) { 
							if (jQuery.type(okcallback)==='function') {
								okcallback();
							};
							console.log(data);
							$("#agentUpdateResults").html("Saved " + data[0].role + " " + data[0].agent_name);
						},
						error:  function (jqXHR, textStatus,error) { 
							$("#agentUpdateResults").html("Error");
							handleFail(jqXHR,textStatus,error,"saving edited underscore_collection_agent record");
						}
					});	
		 		} else { 
					messageDialog('Missing required elements in form.  Fill in all yellow boxes. ','Form Submission Error, missing required values');
		 		};
		 	},
		 	"Close Dialog": function() { 
				if (jQuery.type(okcallback)==='function') {
					okcallback();
				}
			 	$("#"+dialogid+"_div").html("");
				$("#"+dialogid).dialog('close'); 
				$("#"+dialogid).dialog('destroy'); 
			}
		},
		close: function(event,ui) { 
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
		} 
	});
	thedialog.dialog('open');
	datastr = {
		method: "updateAgentRelationHtml",
		returnformat: "plain",
		underscore_coll_agent_id: underscore_coll_agent_id
	};
	jQuery.ajax({
		url: "/grouping/component/functions.cfc",
		type: "post",
		data: datastr,
		success: function (data) { 
			$("#"+dialogid+"_div").html(data);
		}, 
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading edit named group agent dialog");
		}
	});
}

/** remove an agent from a relationship with a named group.
  @param underscore_coll_agent_id the primary key of the underscore_collection_agent record
  to delete.
*/
function removeUndColAgent(underscore_coll_agent_id, okcallback) { 
	jQuery.ajax({
		url : "/grouping/component/functions.cfc",
		type : "post",
		dataType : "json",
		data :  { 
			method: 'removeAgentFromUndColl',
			underscore_coll_agent_id: underscore_coll_agent_id
		},
		success : function (data) {
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
		},
		error: function(jqXHR,textStatus,error){
			handleFail(jqXHR,textStatus,error,"removing agent-named group relationship");
		}
	});
}

/** --------------------------------------------------------------  **/

/** loadCitationDivHTML load a block of html listing citations related to 
 a named grouping.
 @param underscore_collection_id the primary key value for the named group 
   for which to retrieve citations.
 @param targetDivId the id without a leading # selector for the element 
   on the page the content of which to replace with the html listing 
   agents.
*/
function loadCitationDivHTML(underscore_collection_id,targetDivId) { 
	jQuery.ajax({
		url: "/grouping/component/functions.cfc",
		data : {
			method : "getCitationDivHTML",
			underscore_collection_id: underscore_collection_id,
		},
		success: function (result) {
			$("#" + targetDivId ).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading citations for named group");
		},
		dataType: "html"
	});
};

// Create and open a dialog to create a new underscore_collection_citation record relating an agent to 
// a publication.
function opencitenamedgroupingdialog(dialogid, underscore_collection_id, grouping_label, okcallback) { 
	var title = "Add a new citation of a publication for the " + grouping_label;
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = 300;
	var w = $(window).width();
	w = Math.floor(w *.9);
	var thedialog = $("#"+dialogid).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		zindex: 2000,
		height: h,
		width: w,
		minWidth: 400,
		minHeight: 200,
		draggable:true,
		buttons: {
			"Save": function(){ 
				var datasub = $('#newCitationForm').serialize();
				if ($('#newCitationForm')[0].checkValidity()) {
					$.ajax({
						url: "/grouping/component/functions.cfc",
						type: 'post',
						returnformat: 'plain',
						dataType: 'json',
						data: datasub,
						success: function(data) { 
							if (jQuery.type(okcallback)==='function') {
								okcallback();
							};
							console.log(data);
							$("#ciationAddResults").html("Saved " + data[0].role + " " + data[0].agent_name);
						},
						error:  function (jqXHR, textStatus,error) { 
							$("#ciationAddResults").html("Error");
							handleFail(jqXHR,textStatus,error,"saving underscore_collection_citation record");
						}
					});	
		 		} else { 
					messageDialog('Missing required elements in form.  Fill in all yellow boxes. ','Form Submission Error, missing required values');
		 		};
		 	},
		 	"Close Dialog": function() { 
				if (jQuery.type(okcallback)==='function') {
					okcallback();
				}
			 	$("#"+dialogid+"_div").html("");
				$("#"+dialogid).dialog('close'); 
				$("#"+dialogid).dialog('destroy'); 
			}
		},
		close: function(event,ui) { 
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
		} 
	});
	thedialog.dialog('open');
	datastr = {
		method: "getNewUndCollCitationHtml",
		returnformat: "plain",
		underscore_collection_id: underscore_collection_id
	};
	jQuery.ajax({
		url: "/grouping/component/functions.cfc",
		type: "post",
		data: datastr,
		success: function (data) { 
			$("#"+dialogid+"_div").html(data);
		}, 
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading new named group citation dialog");
		}
	});
}

/** remove a citation from a named group.
  @param underscore_coll_citation_id the primary key of the underscore_collection_citation record
  to delete.
*/
function removeUndCollCitation(underscore_coll_citation_id, okcallback) { 
	jQuery.ajax({
		url : "/grouping/component/functions.cfc",
		type : "post",
		dataType : "json",
		data :  { 
			method: 'removeCitationFromUndColl',
			underscore_coll_citation_id: underscore_coll_citation_id
		},
		success : function (data) {
			if (jQuery.type(okcallback)==='function') {
				okcallback();
			}
		},
		error: function(jqXHR,textStatus,error){
			handleFail(jqXHR,textStatus,error,"removing publication-named group relationship");
		}
	});
}
