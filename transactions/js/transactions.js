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


