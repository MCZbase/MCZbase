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
		}
   );
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
/** Scripts specific to transactions pages. **/

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
		fail: function(jqXHR, textStatus) {
			$("#"+dialogid+"_div").html("Error:" + textStatus);
		}
	});
}

function cloneTransAgent(i){
	var id=jQuery('#agent_id_' + i).val();
	var name=jQuery('#trans_agent_' + i).val();
	var role=jQuery('#cloneTransAgent_' + i).val();
	jQuery('#cloneTransAgent_' + i).val('');
	addTransAgentToForm(id,name,role,'editLoan');
}

/** Add an agent to a transaction edit form.
 *
 * Assumes the presence of an input numAgents holding a count of the number of agents in the transaction.
 * Assumes the presence of an html table with an id loanAgents, to which the new agent line is added as the last row.
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
			d+='<input type="text" id="trans_agent_' + i + '" name="trans_agent_' + i + '" class="reqdClr" size="30" value="' + name + '"';
  			d+=' onchange="getAgent(\'agent_id_' + i + '\',\'trans_agent_' + i + '\',\'' + formid + '\',this.value);"';
  			d+=' return false;"	onKeyPress="return noenter(event);">';
  			d+='<input type="hidden" id="agent_id_' + i + '" name="agent_id_' + i + '" value="' + id + '" ';
			d+=' onchange=" updateAgentLink($(\'#agent_id_' + i +'\').val(),\'agentViewLink_' + i + '\'); " >';
  			d+='</td><td><span id="agentViewLink_' + i + '"></span></td><td>';
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
  			d+='</td></tr>';
  			$('#numAgents').val(i);
  			jQuery('#loanAgents tr:last').after(d);
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

function addLendersObject (transaction_id,catalog_number,sci_name,no_of_spec,spec_prep,type_status,country_of_origin,object_remarks) {

	if (typeof catalog_number == "undefined") {
		catalog_number = "";
	 }
	if (typeof sci_name == "undefined") {
		sci_name = "";
	 }
    if (typeof no_of_spec == "undefined") {
		no_of_spec = "";
	 }
     if (typeof spec_prep == "undefined") {
		spec_prep = "";
	 }
     if (typeof type_status == "undefined") {
		type_status = "";
	 }
    if (typeof country_of_origin == "undefined") {
		country_of_origin = "";
	 }
      if (typeof object_remarks == "undefined") {
		object_remarks = "";
	 }

	jQuery.getJSON("/component/functions.cfc",
		{
			method : "getLenders_Object",
			returnformat : "json",
			queryformat : 'column'
		},
                   	function (data) {
			var i=parseInt(document.getElementById('numObject').value)+1;
			var d='<input type="hidden" name="transaction_id_' + i + '" id="transaction_id_' + i + '" value="newLender_Object">';
			d+='<label for "catalog_number_' + i + '"><input type="text" id="catalog_number_' + i + '" name="catalog_number_' + i + '" value="catalog_number_' + i + '"></label>';
  			d+='<label for "sci_name_' + i + '"><input type="text" id="sci_name_' + i + '" name="sci_name_' + i + '" value="sci_name_' + i + '"></label>';
  			d+='<label for "no_of_spec_' + i + '"><input type="text" id="no_of_spec_' + i + '" name="no_of_spec_' + i + '" value="no_of_spec_' + i + '"></label>';
  			d+='<label for "spec_prep_' + i + '"><input type="text" id="spec_prep_' + i + '" name="spec_prep_' + i + '" value="spec_prep_' + i + '"></label>';
  			d+='<label for "type_status_' + i + '"><input type="text" id="type_status_' + i + '" name="type_status_' + i + '" value="type_status_' + i + '"></label>';
  			d+='<label for "country_of_origin_' + i + '"><input type="text" id="country_of_origin_' + i + '" name="country_of_origin_' + i + '" value="country_of_origin_' + i + '"></label>';
            d+='<label for "object_remarks_' + i + '"><input type="text" id="object_remarks_' + i + '" name="object_remarks_' + i + '" value="object_remarks_' + i + '"></label>';
  			document.getElementById('numObject').value=i;
  			jQuery('#addLender_Object label:last').after(d);
		}

	);
}
