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

/** createLoanRowDetailsDialog, create a custom loan specific popup dialog to show details for
	a row of loan data from the loan reults grid.

	@see createRowDetailsDialog defined in /shared/js/shared-scripts.js for details of use.
 */
function createLoanRowDetailsDialog(gridId, rowDetailsTargetId, datarecord, rowIndex) {
   var columns = $('#' + gridId).jqxGrid('columns').records;
   var content = "<div id='" + gridId+  "RowDetailsDialog" + rowIndex + "'><ul class='card-columns'>";
   if (columns.length < 21) {
      // don't split into columns for shorter sets of columns.
      content = "<div id='" + gridId+  "RowDetailsDialog" + rowIndex + "'><ul>";
   }
	var daysdue = datarecord['dueindays'];
	var loanstatus = datarecord['loan_status'];
   var gridWidth = $('#' + gridId).width();
   var dialogWidth = Math.round(gridWidth/2);
   if (dialogWidth < 150) { dialogWidth = 150; }
   for (i = 1; i < columns.length; i++) {
      var text = columns[i].text;
      var datafield = columns[i].datafield;
		if (datafield == 'dueindays') { 
			var daysoverdue = -(datarecord[datafield]);
			if (daysoverdue > 0 && loanstatus != 'closed') {
				var overdue = "";
				if (daysoverdue > 731) { 
					overdue = Math.round(daysoverdue/365.25) + " years";
				} else if (daysoverdue > 365) { 
					overdue = Math.round(daysoverdue/30.44) + " months";
 				} else {
					overdue = daysoverdue + " days";
				} 
      		content = content + "<li class='text-danger'><strong>Overdue:</strong> <strong>by " + overdue +  "</strong></li>";
			} else { 
      		content = content + "<li><strong>" + text + ":</strong> " + datarecord[datafield] +  "</li>";
			}
		} else if (datafield == 'return_due_date') { 
			if (daysdue < 0 && loanstatus != 'closed') {
      		content = content + "<li class='text-danger'><strong>" + text + ":</strong> " + datarecord[datafield] +  "</li>";
			} else { 
      		content = content + "<li><strong>" + text + ":</strong> " + datarecord[datafield] +  "</li>";
			}
		} else {
      	content = content + "<li><strong>" + text + ":</strong> " + datarecord[datafield] +  "</li>";
		}
   }
   content = content + "</ul>";
	var transaction_id = datarecord['transaction_id'];
	content = content + "<a href='/a_loanItemReview?transaction_id="+transaction_id+"' class='btn btn-secondary' target='_blank'>Review Items</a>";
	content = content + "<a href='/SpecimenSearch.cfm?Action=dispCollObj&transaction_id="+transaction_id+"' class='btn btn-secondary' target='_blank'>Add Items</a>";
	content = content + "<a href='/loanByBarcode.cfm?transaction_id="+transaction_id+"' class='btn btn-secondary' target='_blank'>Add Items by Barcode</a>";
	content = content + "<a href='/Loan.cfm?action=editLoan&transaction_id=" + transaction_id +"' class='btn btn-secondary' target='_blank'>Edit Loan</a>";
   content = content + "</div>";
   $("#" + rowDetailsTargetId + rowIndex).html(content);
   $("#"+ gridId +"RowDetailsDialog" + rowIndex ).dialog(
      {
         autoOpen: true,
         buttons: [ { text: "Ok", click: function() { $( this ).dialog( "close" ); $("#" + gridId).jqxGrid('hiderowdetails',rowIndex); } } ],
         width: dialogWidth,
         title: 'Loan Details'
      }
   );
   // Workaround, expansion sits below row in zindex.
   var maxZIndex = getMaxZIndex();
   $("#"+gridId+"RowDetailsDialog" + rowIndex ).parent().css('z-index', maxZIndex + 1);
};

