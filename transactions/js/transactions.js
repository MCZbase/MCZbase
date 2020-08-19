/** Scripts specific to transactions pages. **/

/** Make a paired hidden permit_id and text permit_name control into an autocomplete permit picker
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected permit_id (without a leading # selector).
 */
function makePermitPicker(valueControl, idControl) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/transactions/component/functions.cfc",
				data: { term: request.term, method: 'getPermitAutocomplete' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, status, error) {
					var message = "";
					if (error == 'timeout') { 
						message = ' Server took too long to respond.';
					} else { 
						message = jqXHR.responseText;
					}
					messageDialog('Error:' + message ,'Error: ' + error);
				}
			})
		},
		select: function (event, result) {
			$('#'+idControl).val(result.item.id);
		},
		minLength: 3
	});
};

/** Check an agent to see if the agent has a flag on the agent, if so alert a message
  * @param agent_id the agent_id of the agent to check for rank flags.
  **/
function checkAgent(agent_id) {
   console.log("checkAgent("+agent_id+")");
	jQuery.ajax(
		{
			dataType: "json",
			url: "/transactions/component/functions.cfc",	
			data: {
				method : "checkAgentFlag",
				agent_id : agent_id,
				returnformat : "json",
				queryformat : 'column'
			},
			success: function (result) {
				var rank = result.DATA.AGENTRANK[0];
				if (rank=='A') {
					// no message needed 
				} else {
					if (rank=='F') {
						messageDialog('Please speak to Collections Ops about this loan agent before proceeding.','Agent with an F Rank');
					} else {
						messageDialog("Please check this agent's rankings before proceeding",'Problematic Agent');
					}
				}
			},
			error : function (jqXHR, status, error) {
				console.log(status); // log error to console
				console.log(jqXHR.responseText);
			}
		}
	);
};

/** Check to see if an agent is ranked, and update the provided targetLinkDiv accordingly with a View link
  * or a View link with a flag.
  * @param agent_id the agent_id to lookup.
  * @param targetLinkDiv the id (without a leading # for the div the contents of which to replace with the View link.
  */
function updateAgentLink(agent_id,targetLinkDiv) {
   console.log("updateAgentLink("+agent_id+","+targetLinkDiv+")");
	jQuery.ajax({
		dataType: "json",
		url: "/transactions/component/functions.cfc",
		data: { 
			method : "checkAgentFlag",
			agent_id : agent_id,
			returnformat : "json",
			queryformat : 'column'
		},
		error: function (jqXHR, status, message) {
			messageDialog("Error updating agent link: " + status + " " + jqXHR.responseText ,'Error: '+ status);
		},
		success: function (result) {
			var rank = result.DATA.AGENTRANK[0];
			if (rank=='A') {
				$('#'+targetLinkDiv).html("<a href='/agents/Agent.cfm?agent_id=" + agent_id + "' target='_blank'>View</a>");
			} else {
				if (rank=='F') {
					$('#'+targetLinkDiv).html("<a href='/agents/Agent.cfm?agent_id=" + agent_id + "' target='_blank'>View</a><img src='/agents/images/flag-red.svg.png' width='16'>");
					messageDialog('Please speak to Collections Ops about this loan agent before proceeding.','Agent with an F Rank');
				} else {
					$('#'+targetLinkDiv).html("<a href='/agents/Agent.cfm?agent_id=" + agent_id + "' target='_blank'>View</a><img src='/agents/images/flag-yellow.svg.png' width='16'>");
					messageDialog("Please check this agent's rankings before proceeding",'Problematic Agent');
				}
			}
		}
	});
};

/** Deprecated 
 *Compose a text field for entering a name, an id to hold the agent id, 
 * and a control for a view agent link into an agent autocomplete picker control.
 *
 * @param nameControl the id, without a leading # selector, of the text field to hold the agent name.
 * @param idControl the id, without a leading # selector, of the hidden field to hold the selected agent id.
 * @param viewControl the id, without a leading # selector of a span that is to hold a view agent link and 
 *   flags for problematic agents.
 */
function makeTransAgentPicker(nameControl, idControl, viewControl) { 
	console.log('makeTransAgentPicker is deprecated, replace with makeRichTransAgentPicker');
	$('#'+nameControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/agents/component/search.cfc",
				data: { term: request.term, method: 'getAgentAutocomplete' },
				dataType: 'json',
				success : function (data) { response(data); },
				error : function (jqXHR, status, error) {
					var message = "";
					if (error == 'timeout') { 
						message = ' Server took too long to respond.';
					} else { 
						message = jqXHR.responseText;
					}
					messageDialog('Error:' + message ,'Error: ' + error);
					$('#'+nameControl).toggleClass('reqdClr',true);
					$('#'+nameControl).toggleClass('badPick',true);
				}
			})
		},
		select: function (event, result) {
			$('#'+idControl).val(result.item.id);
			updateAgentLink($('#'+idControl).val(),viewControl);
			$('#'+nameControl).toggleClass('reqdClr',false);
			$('#'+nameControl).toggleClass('goodPick',true);
		},
		change: function(event,ui) { 
			if(!ui.item){
				// handle a change that isn't a selection from the pick list, clear the controls.
				$('#'+idControl).val("");
				$('#'+nameControl).val("");
				$('#'+nameControl).toggleClass('reqdClr',true);
				$('#'+nameControl).toggleClass('goodPick',false);
			}
		},
		minLength: 3
	});
}
/** Make a set of hidden agent_id and text agent_name, agent link control, and agent icon controls into an 
 *  autocomplete agent picker.  Intended for use to pick agents for transaction roles where agent flags may apply.
 *  Triggers updateAgentLink on select to update agent flag in view agent link.  If a required class, turns the 
 *  nameControl class from reqdClr to goodPick.
 *  
 *  @param nameControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected agent_id (without a leading # selector).
 *  @param iconControl the id for an input that can take a background color to indicate a successfull pick of an agent
 *    (without an leading # selector)
 *  @param viewControl the id, without a leading # selector of a span that is to hold a view agent link and 
 *   flags for problematic agents.
 *  @param agentID null, or an id for an agent, if an agentid value is provided, then the idControl, viewControl, and
 *    iconControl are initialized in a picked agent state.
 *  @see makeRichAgentPicker 
 */
function makeRichTransAgentPicker(nameControl, idControl, iconControl, viewControl, agentId) { 
	// initialize the controls for appropriate state given an agentId or not.
   console.log("makeRichTransAgentPicker() agentID="+agentId);
	if (agentId!=null) { 
		$('#'+idControl).val(agentId);
		$('#'+iconControl).addClass('bg-lightgreen');
		$('#'+iconControl).removeClass('bg-light');
		$('#'+viewControl).html(" <a href='/agents/Agent.cfm?agent_id=" + agentId + "' target='_blank'>View</a>");
		$('#'+viewControl).attr('aria-label', 'View details for this agent');
		if ($('#'+nameControl).prop('required')) { 
			$('#'+nameControl).toggleClass('reqdClr',false);
			$('#'+nameControl).toggleClass('goodPick',true);
		}
	} else {
		$('#'+idControl).val("");
		$('#'+iconControl).removeClass('bg-lightgreen');
		$('#'+iconControl).addClass('bg-light');
		$('#'+viewControl).html("");
		$('#'+viewControl).removeAttr('aria-label');
		if ($('#'+nameControl).prop('required')) { 
			$('#'+nameControl).toggleClass('reqdClr',true);
			$('#'+nameControl).toggleClass('goodPick',false);
		}
	}
	$('#'+nameControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/agents/component/search.cfc",
				data: { term: request.term, method: 'getAgentAutocompleteMeta' },
				dataType: 'json',
				success : function (data) { 
					// return the result to the autocomplete widget, select event will fire if item is selected.
					response(data); 
				},
				error : function (jqXHR, status, error) {
					var message = "";
					if (error == 'timeout') { 
						message = ' Server took too long to respond.';
					} else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
						message = ' Backing method did not return JSON.';
					} else { 
						message = jqXHR.responseText;
					}
					messageDialog('Error:' + message ,'Error: ' + error);
					$('#'+idControl).val("");
					$('#'+iconControl).removeClass('bg-lightgreen');
					$('#'+iconControl).addClass('bg-light');
					$('#'+viewControl).html("");
					$('#'+viewControl).removeAttr('aria-label');
					if ($('#'+nameControl).prop('required')) { 
						$('#'+nameControl).toggleClass('reqdClr',true);
						$('#'+nameControl).toggleClass('goodPick',false);
					}
				}
			})
		},
		select: function (event, result) {
			// Handle case of a selection from the pick list.  Indicate successfull pick.
			$('#'+idControl).val(result.item.id);
			$('#'+viewControl).html(" <a href='/agents/Agent.cfm?agent_id=" + result.item.id + "' target='_blank'>View</a>");
			$('#'+viewControl).attr('aria-label', 'View details for this agent');
			$('#'+iconControl).addClass('bg-lightgreen');
			$('#'+iconControl).removeClass('bg-light');
			if ($('#'+nameControl).prop('required')) { 
				$('#'+nameControl).toggleClass('reqdClr',false);
				$('#'+nameControl).toggleClass('goodPick',true);
			}
			// Check for a flag on this agent and update the view control accordingly
			updateAgentLink($('#'+idControl).val(),viewControl);
		},
		change: function(event,ui) { 
			if(!ui.item){
				// handle a change that isn't a selection from the pick list, clear the controls.
				$('#'+idControl).val("");
				$('#'+nameControl).val("");
				$('#'+iconControl).removeClass('bg-lightgreen');
				$('#'+iconControl).addClass('bg-light');	
				$('#'+viewControl).html("");
				$('#'+viewControl).removeAttr('aria-label');
				if ($('#'+nameControl).prop('required')) { 
					$('#'+nameControl).toggleClass('reqdClr',true);
					$('#'+nameControl).toggleClass('goodPick',false);
				}
			}
		},
		minLength: 3
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta "matched name * (preferred name)" instead of value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};

/* Update the content of a div containing a count of the items in a Loan.
 * @param transactionId the transaction_id of the Loan to lookup
 * @param targetDiv the id div for which to replace the contents (without a leading #).
 */
function updateLoanItemCount(transactionId,targetDiv) {
	jQuery.ajax(
	{
		dataType: "json",
		url: "/transactions/component/functions.cfc",
		data: { 
			method : "getLoanItemCounts",
			transaction_id : transactionId,
			returnformat : "json",
			queryformat : 'column'
		},
		error: function (jqXHR, status, message) {
			messageDialog("Error updating item count: " + status + " " + jqXHR.responseText ,'Error: '+ status);
		},
		success: function (result) {
			if (result.DATA.STATUS[0]==1) {
				var message  = "There are " + result.DATA.PARTCOUNT[0];
				message += " parts from " + result.DATA.CATITEMCOUNT[0];
				message += " catalog numbers in " + result.DATA.COLLECTIONCOUNT[0];
				message += " collections with " + result.DATA.PRESERVECOUNT[0] +  " preservation types in this loan."
				$('#' + targetDiv).html(message);
			}
		}
	},
	)
};

function loadTransactionFormMedia(transaction_id,transaction_type) {
	jQuery.ajax({
		url: "/transactions/component/functions.cfc",
		data : {
			method : "getMediaForTransHtml",
			transaction_id: transaction_id,
			transaction_type: transaction_type
		},
		success: function (result) {
			$("#transactionFormMedia").html(result);
		},
		error: function (jqXHR, status, message) {
			if (jqXHR.responseXML) { msg = jqXHR.responseXML; } else { msg = jqXHR.responseText; }
			messageDialog("Error loading media: " + message + " " + msg ,'Error: '+ message);
		},
		dataType: "html"
	});
};

function loadShipments(transaction_id) {
	jQuery.ajax({
		url: "/transactions/component/functions.cfc",
		data : {
			method : "getShipmentsByTransHtml",
			transaction_id : transaction_id
		},
		success: function (result) {
			$("#shipmentTable").html(result);
		},
		error: function (jqXHR, status, message) {
			if (jqXHR.responseXML) { msg = jqXHR.responseXML; } else { msg = jqXHR.responseText; }
			messageDialog("Error loading shipments: " + message + " " + msg ,'Error: '+ message);
		},
		dataType: "html"
	});
};

function loadTransactionFormPermits(transaction_id) {
	jQuery.ajax({
		url: "/transactions/component/functions.cfc",
		data : {
			method : "getPermitsForTransHtml",
			transaction_id: transaction_id
		},
		success: function (result) {
			$("#transactionFormPermits").html(result);
		},
		error: function (jqXHR, status, message) {
			messageDialog("Error loading transaction permits: " + message + " " + jqXHR.responseText ,'Error: '+ status);
		},
		dataType: "html"
	});
};

function loadShipmentFormPermits(shipment_id) {
	jQuery.ajax({
		url: "/transactions/component/functions.cfc",
		data : {
			method : "getPermitsForShipment",
			shipment_id : shipment_id
		},
		success: function (result) {
			$("#shipmentFormPermits").html(result);
		},
		error: function (jqXHR, status, message) {
			if (jqXHR.responseXML) { msg = jqXHR.responseXML; } else { msg = jqXHR.responseText; }
			messageDialog("Error loading shipment permits: " + message + " " + msg ,'Error: '+ status);
		},
		dataType: "html"
	});
};

function openfindpermitdialog(valueControl, idControl, dialogid) { 
	var title = "Find Permissions and Rights Documents";
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = $(window).height();
	var w = $(window).width();
	w = Math.floor(w *.9);
	var thedialog = $("#"+dialogid).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		height: h,
		width: w,
		minWidth: 400,
		minHeight: 450,
		draggable:true,
		buttons: {
			"Close Dialog": function() {
				$("#"+dialogid).dialog('close');
			}
		},
		open: function (event, ui) {
			// force the dialog to lay above any other elements in the page.
			var maxZindex = getMaxZIndex();
			$('.ui-dialog').css({'z-index': maxZindex + 6 });
			$('.ui-widget-overlay').css({'z-index': maxZindex + 5 });
		},
		close: function(event,ui) {
			$("#"+dialogid+"_div").html("");
			$("#"+dialogid).dialog('destroy');
		}
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/transactions/component/functions.cfc",
		type: "get",
		data: {
			method: "queryPermitPickerHtml",
			returnformat: "plain",
			valuecontrol: valueControl,
			idcontrol: idControl,
			dialog: dialogid
		},
		success: function(data) {
			$("#"+dialogid+"_div").html(data);
		},
		error: function (jqXHR, status, error) {
			var message = "";
			if (error == 'timeout') { 
				message = ' Server took too long to respond.';
			} else { 
				message = jqXHR.responseText;
			}
			$("#"+dialogid+"_div").html("Error (" + error + "): " + message );
		}
	});
}

/* function closeTransAgent wrapper for addTransAgentToForm 
 * looks up agent id, agent name, and role to clone into.
 * @param i the i incrementing counter for the agent_id_{i}, trans_agent_{i}, etc controls.
 */
function cloneTransAgent(i){
	var id=jQuery('#agent_id_' + i).val();
	var name=jQuery('#trans_agent_' + i).val();
	var role=jQuery('#cloneTransAgent_' + i).val();
	jQuery('#cloneTransAgent_' + i).val('');
	addTransAgentToForm(id,name,role,'editLoan');
}

/** Add an agent to a transaction edit form, appends row to table with id transactionAgentsTable.
 *
 * Assumes the presence of an input numAgents holding a count of the number of agents in the transaction.
 * Assumes the presence of an html table with an id transactionAgentsTable, to which the new agent line is added as the last row.
 */
function addTransAgentToForm (id,name,role,formid) {
	if (typeof id == "undefined") {
		id = "";
	 }
	if (typeof name == "undefined") {
		name = "";
	 }
	if (typeof role == "undefined") {
		role = "";
	 }
	jQuery.getJSON("/transactions/component/functions.cfc",
		{
			method : "getTrans_agent_role",
			returnformat : "json",
			queryformat : 'column'
		},
		function (data) {
			var i=parseInt($('#numAgents').val())+1;
			var d='<tr><td>';
			d+='<input type="hidden" name="trans_agent_id_' + i + '" id="trans_agent_id_' + i + '" value="new">';
			d+='<div class="input-group"><div class="input-group-prepend">';
			d+='<span class="input-group-text" id="agent_icon_'+i+'"><i class="fa fa-user" aria-hidden="true"></i></span> </div>';
			d+='<input type="text" id="trans_agent_' + i + '" name="trans_agent_' + i + '" required class="goodPick form-control form-control-sm data-entry-input" size="30" value="' + name + '" >';
			d+='</div>';
			d+='<input type="hidden" id="agent_id_' + i + '" name="agent_id_' + i + '" value="' + id + '" ';
			d+=' onchange=" updateAgentLink($(\'#agent_id_' + i +'\').val(),\'agentViewLink_' + i + '\'); " >';
			d+='</td><td style="min-width: 3.5em; "><span id="agentViewLink_' + i + '" class="px-2"></span></td><td>';
			d+='<select name="trans_agent_role_' + i + '" id="trans_agent_role_' + i + '" class="data-entry-select">';
			for (a=0; a<data.ROWCOUNT; ++a) {
				d+='<option ';
				if(role==data.DATA.TRANS_AGENT_ROLE[a]){
					d+=' selected="selected"';
				}
				d+=' value="' + data.DATA.TRANS_AGENT_ROLE[a] + '">'+ data.DATA.TRANS_AGENT_ROLE[a] +'</option>';
			}
			d+='</td><td>';
			d+='<input type="checkbox" name="del_agnt_' + i + '" name="del_agnt_' + i + '" value="1" class="data-entry-input">';
			d+='</td><td>';
			d+='<select id="cloneTransAgent_' + i + '" onchange="cloneTransAgent(' + i + ')" class="data-entry-select">';
			d+='<option value=""></option>';
			for (a=0; a<data.ROWCOUNT; ++a) {
				d+='<option value="' + data.DATA.TRANS_AGENT_ROLE[a] + '">'+ data.DATA.TRANS_AGENT_ROLE[a] +'</option>';
			}
			d+='</select>';
			d+='</td></tr>';
			d+='<script>';
			d+=' $(document).ready(function() {';
			d+='   $(makeRichTransAgentPicker("trans_agent_'+i+'","agent_id_'+i+'","agent_icon_'+i+'","agentViewLink_'+i+'",'+id+'));';
			d+=' });';
			d+='</script>';
			$('#numAgents').val(i);
			jQuery('#transactionAgentsTable tr:last').after(d);
		}
	);
}

function cloneTransAgentDeacc(i){
	var id=jQuery('#agent_id_' + i).val();
	var name=jQuery('#trans_agent_' + i).val();
	var role=jQuery('#cloneTransAgent_' + i).val();
	jQuery('#cloneTransAgent_' + i).val('');
	addTransAgentDeacc (id,name,role);
}
function addTransAgentDeacc (id,name,role) {
	if (typeof id == "undefined") {
		id = "";
	 }
	if (typeof name == "undefined") {
		name = "";
	 }
	if (typeof role == "undefined") {
		role = "";
	 }
	jQuery.getJSON("/transactions/component/functions.cfc",
		{
			method : "getTrans_agent_role",
			returnformat : "json",
			queryformat : 'column'
		},
		function (data) {
			var i=parseInt(document.getElementById('numAgents').value)+1;
			var d='<tr><td>';
			d+='<input type="hidden" name="trans_agent_id_' + i + '" id="trans_agent_id_' + i + '" value="new">';
			d+='<input type="text" id="trans_agent_' + i + '" name="trans_agent_' + i + '" class="reqdClr" size="30" value="' + name + '"';
  			d+=' onchange="getAgent(\'agent_id_' + i + '\',\'trans_agent_' + i + '\',\'editDeacc\',this.value);"';
  			d+=' return false;"	onKeyPress="return noenter(event);">';
  			d+='<input type="hidden" id="agent_id_' + i + '" name="agent_id_' + i + '" value="' + id + '">';
  			d+='</td><td>';
  			d+='<select name="trans_agent_role_' + i + '" id="trans_agent_role_' + i + '">';
  			for (a=0; a<data.ROWCOUNT; ++a) {
				d+='<option ';
				if(role==data.DATA.TRANS_AGENT_ROLE[a]){
					d+=' selected="selected"';
				}
				d+=' value="' + data.DATA.TRANS_AGENT_ROLE[a] + '">'+ data.DATA.TRANS_AGENT_ROLE[a] +'</option>';
			}
  			d+='</td><td>';
  			d+='<input type="checkbox" name="del_agnt_' + i + '" name="del_agnt_' + i + '" value="1">';
  			d+='</td><td>';
  			d+='<select id="cloneTransAgent_' + i + '" onchange="cloneTransAgent(' + i + ')" style="width:8em">';
  			d+='<option value=""></option>';
  			for (a=0; a<data.ROWCOUNT; ++a) {
				d+='<option value="' + data.DATA.TRANS_AGENT_ROLE[a] + '">'+ data.DATA.TRANS_AGENT_ROLE[a] +'</option>';
			}
			d+='</select>';
  			d+='</td><td>-</td></tr>';
  			document.getElementById('numAgents').value=i;
  			jQuery('#deaccAgents tr:last').after(d);
		}
	);
}

/** function setupNewShipment set up a shipment dialog to enter a new shipment 
 * for a transaction, emptying form values and setting defaults.
 * @param transaction_id the transaction that this shipment is for 
 */
function setupNewShipment(transaction_id) { 
	$("#dialog-shipment").dialog( "option", "title", "Create New Shipment" );
	$("#shipment_id").val("");
	$("#transaction_id").val(transaction_id);
	var date = new Date();
	var datestring = date.getFullYear() + "-" + ("0"+(date.getMonth()+1)).slice(-2) + "-" + ("0" + date.getDate()).slice(-2);
	$("#shipped_date").val(datestring);
	$("#contents").val("");
	$("#no_of_packages").val("1");
	$("#carriers_tracking_number").val("");
	$("#package_weight").val("");
	$("#packed_by_agent").val("");
	$("#packed_by_agent_id").val("");
	$("#shipment_remarks").val("");
	$("#shipped_to_addr_id").val("");
	$("#shipped_from_addr_id").val("");
	$("#shipped_to_addr").val("");
	$("#shipped_from_addr").val("");
	$("#shipped_carrier_method").val("");
	$("#foreign_shipment_fg option[value='1']").prop('selected',false);
	$("#foreign_shipment_fg option[value='0']").prop('selected',true); 
	$("#hazmat_fg option[value='1']").prop('selected',false);
	$("#hazmat_fg option[value='0']").prop('selected',true); 
	$("#shipmentFormPermits").html(""); 
	$("#shipmentFormStatus").html(""); 
	$(".ui-dialog-buttonpane button").addClass("btn btn-primary btn-sm");
}

// Given a form with id saveShipment (with form fields matching shipment fields), invoke a backing
// function to save that shipment.
// Assumes an element with id shipmentFormStatus exists to present feedback.
function saveShipment(transactionId) { 
	var valid = false;
	// Check required fields 
	if ($("#shipped_carrier_method").val().length==0 ||
		$("#packed_by_agent").val().length==0 ||
		$("#shipped_to_addr").val().length==0 ||
		$("#shipped_from_addr").val().length==0) 
	{ 
		$("#shipmentFormStatus").empty().append("Error: Required field is missing a value");
	} else { 
		// save result
		$('#methodSaveShipmentQF').remove();
		$('<input id="methodSaveShipmentQF" />').attr('type', 'hidden')
			.attr('name', "queryformat")
			.attr('value', "column")
			.appendTo('#shipmentForm');
		$('#methodSaveShipmentInput').remove();
		$('<input id="methodSaveShipmentInput" />').attr('type', 'hidden')
			.attr('name', "method")
			.attr('value', "saveShipment")
			.appendTo('#shipmentForm');
		$.ajax({
			url : "/component/functions.cfc",
			type : "post",
			dataType : "json",
			data: $("#shipmentForm").serialize(),
			success: function (result) {
				if (result.DATA.STATUS[0]==0) { 
					$("#shipmentFormStatus").empty().append(result.DATA.MESSAGE[0]);
				} else { 
					loadShipments(transactionId);
					valid = true;
					$("#dialog-shipment").dialog( "close" );
				}
			},
			fail: function (jqXHR,textStatus) {
				 $("#shipmentFormStatus").empty().append("Error Submitting Form: " + textStatus);
			}
		});
	}
	return valid;
};

/* function loadAgentTable request the html to populate a div with an editable table of agents for a 
 * transaction.
 * @param agentsDiv the id for the div to load the agent table into, without a leading # id selector.
 * @param tranasaction_id the transaction_id of the transaction for which to load agents.
 */
function loadAgentTable(agentsDiv,transaction_id){ 
	$('#' + agentsDiv).html("Loading....");
	jQuery.ajax({
		url : "/transactions/component/functions.cfc",
		type : "get",
		data : {
			method: 'agentTableHtml',
			transaction_id: transaction_id
		},
		success : function (data) {
			$('#' + agentsDiv).html(data);
		},
		error: function(jqXHR,textStatus,error){
			$('#' + agentsDiv).html('Error loading agents.');
			var message = "";
			if (error == 'timeout') {
				message = ' Server took too long to respond.';
			} else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
				message = ' Backing method did not return JSON.';
			} else {
				message = jqXHR.responseText;
			}
			if (!error) { error = ""; } 
			messageDialog('Error retrieving agents for transaction record: '+message, 'Error: '+error.substring(0,50));
		}
	});
}
