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

/** 
 * removeSubloandFromParent unlink a subloan from a master exhibition loan and reload
 * the subloan_section of the page.
 *
 * @param parentTransactionId the transaction_id the id of the master exhibition loan.
 * @param childTransactionId the transaction_id of the subloan to unlink from the parent.
 */
function removeSubloanFromParent(parentTransactionId,childTransactionId) {
	jQuery.getJSON("/transactions/component/functions.cfc",
		{
			method : "removeSubloanFromParent",
			parent_transaction_id : parentTransactionId,
			child_transaction_id : childTransactionId,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			loadSubloans(parentTransactionId);
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"removing subloan from master exhibition loan");
	});
};

/**
 * addSubloanToParent, given a parent exhibition loan and a subloan, link the subloan to 
 * the parent exhibition loan and reload the subloan_section of the page.
 * 
 * @param parentTransactionId the transaction_id the id of the master exhibition loan.
 * @param childTransactionId the transaction_id of the subloan to link to the parent.
 */
function addSubloanToParent(parentTransactionId,childTransactionId) {
	jQuery.getJSON("/transactions/component/functions.cfc",
		{
			method : "addSubLoanToLoan",
			transaction_id : parentTransactionId,
			subloan_transaction_id : childTransactionId,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			loadSubloans(parentTransactionId);
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"removing subloan from master exhibition loan");
	});
};

/**  
 * :oadSubloans populate the subloan_section div of a loan form
 * with a list of subloans, if any, and a picklist of unlinked subloans, if any.
 * 
 * @param transaction_id the id of the master exhibition loan.
 */
function loadSubLoans(transactionId) { 
	jQuery.ajax({
		url: "/transactions/component/functions.cfc",
		data : {
			method : "getSubloansForLoanHtml",
			transaction_id: transactionId
		},
		success: function (result) {
			$("#subloan_section").html(result);
		},
		error: function (jqXHR, status, message) {
			if (jqXHR.responseXML) { msg = jqXHR.responseXML; } else { msg = jqXHR.responseText; }
			messageDialog("Error loading media: " + message + " " + msg ,'Error: '+ message);
		},
		dataType: "html"
	});
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
	console.log("Reloading shipments in #shipmentTable");
	jQuery.ajax({
		url: "/transactions/component/functions.cfc",
		data : {
			method : "getShipmentsByTransHtml",
			transaction_id : transaction_id
		},
		success: function (result) {
			$("#shipmentTable").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"deleting shipment");
		},
		dataType: "html"
	});
};

function setShipmentToPrint(shipmentId,transactionId) {
	jQuery.getJSON("/transactions/component/functions.cfc",
		{
			method : "setShipmentToPrint",
			shipment_id : shipmentId,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			if (result.DATA.STATUS=="0") {
				messagDialog(result.DATA.MESSAGE,'Error setting Shipment to Print');
			}
			loadShipments(transactionId);
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"deleting shipment");
	});
};

/* function deleteShipment remove a shipment from a transaction.
 */
function deleteShipment(shipmentId,transactionId) {
	jQuery.getJSON("/transactions/component/functions.cfc",
		{
			method : "removeShipment",
			shipment_id : shipmentId,
			transaction_id : transactionId,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			if (result.DATA.STATUS=="1") { 
				loadShipments(transactionId);
			} else { 
				messageDialog("Error deleting shipment " + result.DATA.MESSAGE, "Error deleting shipment");
			}
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"deleting shipment");
	});
}

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

function loadTransactionPermitMediaList(transaction_id) {
	targetDiv="transPermitMediaListDiv";
	console.log("Reloading permit media in #"+ targetDiv);
	jQuery.ajax({
		url: "/transactions/component/functions.cfc",
		data : {
			method : "getTransPermitMediaList",
			transaction_id : transaction_id
		},
		success: function (result) {
			$("#"+targetDiv).html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"loading permit media list");
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
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"deleting shipment");
		},
		dataType: "html"
	});
};

function openfindpermitdialog(valueControl, idControl, dialogid) { 
	var title = "Find Permissions and Rights Documents";
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = $(window).height();
	if (h>775) { h=775; } // cap height at 775
	var w = $(window).width();
	// full width at less than medium screens
	if (w>768 && w<=1333) { 
		// 90% width up to extra large screens
		w = Math.floor(w *.9);
	} else if (w>1333) { 
		// cap width at 1200 pixel
		w = 1200;
	} 
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
			d+='</td><td class="text-center">';
			d+='<input type="checkbox" name="del_agnt_' + i + '" name="del_agnt_' + i + '" value="1" class="checkbox-inline">';
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
	).fail(function(jqXHR,textStatus,error){
		var message = "";
		if (error == 'timeout') {
			message = ' Server took too long to respond.';
		} else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
			message = ' Backing method did not return JSON.';
		} else {
			message = jqXHR.responseText;
		}
		if (!error) { error = ""; } 
		messageDialog('Error adding agents to transaction record: '+message, 'Error: '+error.substring(0,50));
	});
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
	).fail(function(jqXHR,textStatus,error){
		var message = "";
		if (error == 'timeout') {
			message = ' Server took too long to respond.';
		} else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
			message = ' Backing method did not return JSON.';
		} else {
			message = jqXHR.responseText;
		}
		if (!error) { error = ""; } 
		messageDialog('Error adding agents to transaction record: '+message, 'Error: '+error.substring(0,50));
	});
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

/** function loadShipment load a shipment into an edit shipment form within a shipment dialog.
 *  @param shipmentId the shipment_id of the shipment to edit
 *  @param form the id without a leading # selector of the shipment form.
 */
function loadShipment(shipmentId,form) {
	$("#dialog-shipment").dialog( "option", "title", "Edit Shipment " + shipmentId );
	$("#shipmentFormPermits").html(""); 
	$("#shipmentFormStatus").html(""); 
	jQuery.getJSON("/transactions/component/functions.cfc",
		{
			method : "getShipments",
			shipmentidList : shipmentId,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			try{
				if (result.ROWCOUNT == 1) {
					var i = 0;
					$(" #" + form + " input[name=transaction_id]").val(result.DATA.TRANSACTION_ID[i]);
					$("#shipment_id").val(result.DATA.SHIPMENT_ID[i]);
					$("#shipped_date").val(result.DATA.SHIPPED_DATE[i]);
					$("#contents").val(result.DATA.CONTENTS[i]);
					$("#no_of_packages").val(result.DATA.NO_OF_PACKAGES[i]);
					$("#carriers_tracking_number").val(result.DATA.CARRIERS_TRACKING_NUMBER[i]);
					$("#package_weight").val(result.DATA.PACKAGE_WEIGHT[i]);
					$("#packed_by_agent").val(result.DATA.PACKED_BY_AGENT[i]);
					$("#packed_by_agent_id").val(result.DATA.PACKED_BY_AGENT_ID[i]);
					$("#shipment_remarks").val(result.DATA.SHIPMENT_REMARKS[i]);
					$("#shipped_to_addr_id").val(result.DATA.SHIPPED_TO_ADDR_ID[i]);
					$("#shipped_from_addr_id").val(result.DATA.SHIPPED_FROM_ADDR_ID[i]);
					$("#shipped_to_addr").val(result.DATA.SHIPPED_TO_ADDRESS[i]);
					$("#shipped_from_addr").val(result.DATA.SHIPPED_FROM_ADDRESS[i]);
					$("#shipped_carrier_method").val(result.DATA.SHIPPED_CARRIER_METHOD[i]);
					var target = "#shipped_carrier_method option[value='" + result.DATA.SHIPPED_CARRIER_METHOD[i] + "']";
$(target).attr("selected",true);
					if (result.DATA.FOREIGN_SHIPMENT_FG[i] == 0) { 
						$("#foreign_shipment_fg option[value='1']").prop('selected',false);
						$("#foreign_shipment_fg option[value='0']").prop('selected',true); 
					} else { 
						$("#foreign_shipment_fg option[value='0']").prop('selected',false);
						$("#foreign_shipment_fg option[value='1']").prop('selected',true); 
					}
					if (result.DATA.HAZMAT_FG[i] == 0) { 
						$("#hazmat_fg option[value='1']").prop('selected',false);
						$("#hazmat_fg option[value='0']").prop('selected',true); 
					} else { 
						$("#hazmat_fg option[value='0']").prop('selected',false);
						$("#hazmat_fg option[value='1']").prop('selected',true); 
					}
				} else { 
					 $("#dialog-shipment").dialog( "close" );
				}
				loadShipmentFormPermits(shipmentId);
			}
			catch(e){ alert(e); }
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"loading shipment record");
	});
};


function deletePermitFromShipment(shipmentId,permitId,transactionId) {
	jQuery.getJSON("/transactions/component/functions.cfc",
		{
			method : "removePermitFromShipment",
			shipment_id : shipmentId,
			permit_id : permitId,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			if (result.DATA.STATUS == "1") { 
				loadShipments(transactionId);
			} else {
				messageDialog("Error removing permit from shipment: " + result.DATA.MESSAGE, "Error removing permit");
			}
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"removing permit from shipment record");
	});
};

/** function loadAgentTable request the html to populate a div with an editable table of agents for a 
 * transaction.
 *
 * Assumes the presence of a change() function defined within scole containg the agent table.
 *
 * @param agentsDiv the id for the div to load the agent table into, without a leading # id selector.
 * @param tranasaction_id the transaction_id of the transaction for which to load agents.
 * @param containingFormId the id for the form containing the agent table, without a leading # id selector.
 * @param changeHandler callback function to pass to monitorForChanges to be called when input values change.
 */
function loadAgentTable(agentsDiv,transaction_id,containingFormId,changeHandler){ 
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
			monitorForChanges(containingFormId,changeHandler);
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

/** function loadProjects load the projects related to a transaction into the provided projectsDiv.
 * 
 * @param projectsDiv the id of the div into which to load the projects list, without # id selector.
 * @param transaction_id the id of the transaction for which to look up projects.
 */
function loadProjects(projectsDiv,transaction_id) { 
	$('#' + projectsDiv).html("Loading....");
	jQuery.ajax({
		url : "/transactions/component/functions.cfc",
		type : "get",
		data : {
			method: 'getProjectListHtml',
			transaction_id: transaction_id
		},
		success : function (data) {
			$('#' + projectsDiv).html(data);
		},
		error: function(jqXHR,textStatus,error){
			$('#' + projectsDiv).html('Error loading projects.');
			var message = "";
			if (error == 'timeout') {
				message = ' Server took too long to respond.';
			} else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
				message = ' Backing method did not return JSON.';
			} else {
				message = jqXHR.responseText;
			}
			if (!error) { error = ""; } 
			messageDialog('Error retrieving projects for transaction record: '+message, 'Error: '+error.substring(0,50));
		}
	});

}

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

/** Create a dialog for printing transaction paperwork. 
  * 
  * @param transaction_id the transaction for which to print the paperwork
  * @param transaction_type the type of transaction (loan, accession, deaccession, borrow)
  * @param dialogid the id of the div that is to contain the dialog, without a leading # selector.
  */
function openTransactionPrintDialog(transaction_id, transaction_type, dialogid) { 
	var title = "Print " + transaction_type + " paperwork.";
	var method = "";
	if (transaction_type == "Loan") { 
		method = "getLoanPrintListDialogContent";
	}
	if (method=="") { 
		messageDialog('No Implementation for print list dialog for transactions of type ' + transaction_type, 'Error: Method not Implemented');
	} else { 
		var content = '<div id="'+dialogid+'_div">Loading....</div>';
		var thedialog = $("#"+dialogid).html(content)
		.dialog({
			title: title,
			autoOpen: false,
			dialogClass: 'dialog_fixed,ui-widget-header',
			modal: true,
			stack: true,
			height: "auto",
			width: "auto",
			minWidth: 200,
			minHeight: 300,
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
				method: method,
				returnformat: "plain",
				transaction_id: transaction_id
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
}

/** Make a paired hidden project_id and text project_name control into an autocomplete project picker
 *
 *  @param valueControl the id for a text input that is to be the autocomplete field (without a leading # selector).
 *  @param idControl the id for a hidden input that is to hold the selected project_id (without a leading # selector).
 */
function makeProjectPicker(valueControl, idControl) { 
	$('#'+valueControl).autocomplete({
		source: function (request, response) { 
			$.ajax({
				url: "/projects/component/functions.cfc",
				data: { term: request.term, method: 'getProjectAutocomplete' },
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
		minLength: 2
	}).autocomplete("instance")._renderItem = function(ul,item) { 
		// override to display meta "matched project_name * (date_range)" instead of value in picklist.
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
};

/* function openTransProjectLinkDialog create a dialog using an existing div to link projects to a transaction. 
 * 
 * @param transaction_id the id of the transaction to link selected projects to.
 * @param dialogId the id, without a leading # selector, of the div that is to contain the dialog.
 * @param projectsDivId the id, without a leading # selector, of the div containing a list of projects
 *   that is to be repopulated with loadProjects on close of the dialog.
 * @see loadProjects
 */
function openTransProjectLinkDialog(transaction_id, dialogId, projectsDivId) { 
	var title = "Link existing Project.";
	var content = '<div id="'+dialogId+'_div">Loading....</div>';
	var thedialog = $("#"+dialogId).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		minWidth: 550,
		minHeight: 200,
		draggable:true,
		buttons: {
			"Close Dialog": function() {
				$("#"+dialogId).dialog('close');
				loadProjects(projectsDivId,transaction_id); 
			}
		},
		open: function (event, ui) {
			// force the dialog to lay above any other elements in the page.
			var maxZindex = getMaxZIndex();
			$('.ui-dialog').css({'z-index': maxZindex + 6 });
			$('.ui-widget-overlay').css({'z-index': maxZindex + 5 });
		},
		close: function(event,ui) {
			$("#"+dialogId+"_div").html("");
			$("#"+dialogId).dialog('destroy');
		}
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/transactions/component/functions.cfc",
		type: "get",
		data: {
			method: 'getLinkProjectDialogHtml',
			returnformat: "plain",
			transaction_id: transaction_id
		},
		success: function(data) {
			$("#"+dialogId+"_div").html(data);
		},
		error: function (jqXHR, status, error) {
			var message = "";
			if (error == 'timeout') { 
				message = ' Server took too long to respond.';
			} else { 
				message = jqXHR.responseText;
			}
			$("#"+dialogId+"_div").html("Error (" + error + "): " + message );
		}
	});
}

/* function openTransProjectCreateDialog create a dialog using an existing div to create
 * a new project and link it to a transaction. 
 * 
 * @param transaction_id the id of the transaction to link the created project to.
 * @param dialogId the id, without a leading # selector, of the div that is to contain the dialog.
 * @param projectsDivId the id, without a leading # selector, of the div containing a list of projects
 *   that is to be repopulated with loadProjects on close of the dialog.
 * @see loadProjects
 */
function openTransProjectCreateDialog(transaction_id, dialogId, projectsDivId) { 
	var title = "Create and Link New Project.";
	var content = '<div id="'+dialogId+'_div">Loading....</div>';
	var thedialog = $("#"+dialogId).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		minWidth: 550,
		minHeight: 450,
		draggable:true,
		buttons: {
			"Close Dialog": function() {
				$("#"+dialogId).dialog('close');
				loadProjects(projectsDivId,transaction_id);
			}
		},
		open: function (event, ui) {
			// force the dialog to lay above any other elements in the page.
			var maxZindex = getMaxZIndex();
			$('.ui-dialog').css({'z-index': maxZindex + 6 });
			$('.ui-widget-overlay').css({'z-index': maxZindex + 5 });
		},
		close: function(event,ui) {
			$("#"+dialogId+"_div").html("");
			$("#"+dialogId).dialog('destroy');
		}
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/transactions/component/functions.cfc",
		type: "get",
		data: {
			method: 'getAddProjectDialogHtml',
			returnformat: "plain",
			transaction_id: transaction_id
		},
		success: function(data) {
			$("#"+dialogId+"_div").html(data);
		},
		error: function (jqXHR, status, error) {
			handleFail(jqXHR,status,error,"opening dialog to for project creation from transaction dialog");
		}
	});
}

/** function removeMediaFromTrans unlink a media record from a transaction 
 * 
 * @param mediaId the media_id of media record to unlink from the transaction.
 * @param transactionId the transaction_id of the transaction from which to unlink the media
 * @param relationType the type of media_relations to be deleted.
 */
function removeMediaFromTrans(mediaId,transactionId,relationType) {
	jQuery.getJSON("/transactions/component/functions.cfc",
		{
			method : "removeMediaFromTransaction",
			media_id : mediaId,
			transaction_id : transactionId,
			media_relationship : relationType,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			reloadTransMedia();
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"removing media from transaction record");
	});
}

/** function removeProjectFromTrans unlink a project record from a transaction 
 * 
 * @param projectId the project_id of project record to unlink from the transaction.
 * @param transactionId the transaction_id of the transaction from which to unlink the project
 */
function removeProjectFromTrans(projectId,transactionId) {
	jQuery.getJSON("/transactions/component/functions.cfc",
		{
			method : "removeProjectFromTransaction",
			project_id : projectId,
			transaction_id : transactionId,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			reloadTransProjects();
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"removing project from transaction record");
	});
}

function openfindaddressdialog(valueControl, idControl, dialogid,transaction_id) { 
	var title = "Find Shipping Addresses";
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = $(window).height();
	if (h>775) { h=775; } // cap height at 775
	var w = $(window).width();
	// full width at less than medium screens
	if (w>768 && w<=1333) { 
		// 90% width up to extra large screens
		w = Math.floor(w *.9);
	} else if (w>1333) { 
		// cap width at 1200 pixel
		w = 1200;
	} 
	var thedialog = $("#"+dialogid).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		height: h,
		width: w,
		minWidth: 600,
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
			method: "getAddressPickerHtml",
			returnformat: "plain",
			valuecontrol: valueControl,
			idcontrol: idControl,
			dialog: dialogid,
			transaction_id: transaction_id
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
// Create and open a dialog to find and link existing permit records to a provided shipment
function openlinkpermitshipdialog(dialogid, shipment_id, shipment_label, okcallback) { 
	var title = "Link Permit record(s) to " + shipment_label;
	var content = '<div id="'+dialogid+'_div">Loading....</div>';
	var h = $(window).height();
	if (h>775) { h=775; } // cap height at 775
	var w = $(window).width();
	// full width at less than medium screens
	if (w>768 && w<=1333) { 
		// 90% width up to extra large screens
		w = Math.floor(w *.9);
	} else if (w>1333) { 
		// cap width at 1200 pixel
		w = 1200;
	} 
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
			minHeight: 450,
			draggable:true,
			buttons: {
				"Close Dialog": function() { 
					$("#"+dialogid).dialog('close'); 
		 		}
		 	},
			close: function(event,ui) { 
				if (jQuery.type(okcallback)==='function') {
		 			okcallback();
				}
				$("#"+dialogid+"_div").html("");
				$("#"+dialogid).dialog('destroy'); 
			} 
		});
		thedialog.dialog('open');
		jQuery.ajax({
			url: "/transactions/component/functions.cfc",
			type: "post",
			data: {
		 		method: "shipmentPermitPickerHtml",
		 		returnformat: "plain",
				shipment_id: shipment_id,
				shipment_label: shipment_label
		 	}, 
			success: function (data) { 
				$("#"+dialogid+"_div").html(data);
			}, 
			error: function (jqXHR, textStatus, error) { 
				handleFail(jqXHR,textStatus,error,"removing project from transaction record");
			}
	});
}

/* function openMovePermitDialog create a dialog using an existing div to move or copy a permit among 
 * shipments in a transaction.
 * 
 * @param transaction_id the id of the transaction to which the shipments are associated.
 * @param curent_shipment_id the shipment with which the permit is currently associated.
 * @param permit_id the permit_id of the permit to move or add to another shipment.
 * @param dialogId the id, without a leading # selector, of the div that is to contain the dialog.
 */
function openMovePermitDialog(transaction_id, current_shipment_id, permit_id, dialogId) { 
	var title = "Move/Copy Permissions and Rights Document.";
	var content = '<div id="'+dialogId+'_div">Loading....</div>';
	var thedialog = $("#"+dialogId).html(content)
	.dialog({
		title: title,
		autoOpen: false,
		dialogClass: 'dialog_fixed,ui-widget-header',
		modal: true,
		stack: true,
		minWidth: 550,
		minHeight: 200,
		draggable:true,
		buttons: {
			"Close Dialog": function() {
				$("#"+dialogId).dialog('close');
			}
		},
		open: function (event, ui) {
			// force the dialog to lay above any other elements in the page.
			var maxZindex = getMaxZIndex();
			$('.ui-dialog').css({'z-index': maxZindex + 6 });
			$('.ui-widget-overlay').css({'z-index': maxZindex + 5 });
		},
		close: function(event,ui) {
			$("#"+dialogId+"_div").html("");
			$("#"+dialogId).dialog('destroy');
		}
	});
	thedialog.dialog('open');
	jQuery.ajax({
		url: "/transactions/component/functions.cfc",
		type: "get",
		data: {
			method: 'movePermitHtml',
			returnformat: "plain",
			permit_id: permit_id,
			current_shipment_id: current_shipment_id,
			transaction_id: transaction_id
		},
		success: function(data) {
			$("#"+dialogId+"_div").html(data);
		},
		error: function (jqXHR, status, error) {
			var message = "";
			if (error == 'timeout') { 
				message = ' Server took too long to respond.';
			} else { 
				message = jqXHR.responseText;
			}
			$("#"+dialogId+"_div").html("Error (" + error + "): " + message );
		}
	});
}

// Add a permit to a shipment with a callback function callback(statuscode).
function addPermitToShipmentCB(shipmentId,permitId,transactionId,callback) {
	jQuery.getJSON("/transactions/component/functions.cfc",
		{
			method : "setShipmentForPermit",
			shipment_id : shipmentId,
			permit_id : permitId,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			if (result.DATA.STATUS==1) {
				callback(1);
			} else {
				alert(result.DATA.MESSAGE);
				callback(0);
			}
			loadShipments(transactionId);
		}
	);
};
// Move a permit from one shipment to another with a callback function callback(statuscode).
function movePermitFromShipmentCB(oldShipmentId,newShipmentId,permitId,transactionId,callback) {
	jQuery.getJSON("/transactions/component/functions.cfc",
		{
			method : "movePermitToShipment",
			source_shipment_id : oldShipmentId,
			target_shipment_id : newShipmentId,
			permit_id : permitId,
			returnformat : "json",
			queryformat : 'column'
		},
		function (result) {
			if (result.DATA.STATUS==1) {
				callback(1);
			} else {
				alert(result.DATA.MESSAGE);
				callback(0);
			}
		}
	).fail(function(jqXHR,textStatus,error){
		handleFail(jqXHR,textStatus,error,"removing project from transaction record");
	});
	loadShipments(transactionId);
}

