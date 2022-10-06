/** Scripts specific to named group (underscore_collection) pages. **/

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
				var datasub = $('#newPermitForm').serialize();
				if ($('#newPermitForm')[0].checkValidity()) {
					$.ajax({
						url: "/grouping/component/functions.cfc",
						type: 'post',
						returnformat: 'plain',
						data: datasub,
						success: function(data) { 
							if (jQuery.type(okcallback)==='function') {
								okcallback();
							};
							$("#"+dialogid+"_div").html(data);
						},
						fail: function (jqXHR, textStatus,error) { 
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
