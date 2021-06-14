
function loadTransactionFormMedia(transaction_id,transaction_type) {
    jQuery.ajax({
          url: "/component/functions.cfc",
          data : {
            method : "getMediaForTransHtml",
            transaction_id: transaction_id,
            transaction_type: transaction_type
         },
        success: function (result) {
           $("#transactionFormMedia").html(result);
        },
        dataType: "html"
       }
     )};


function loadShipments(transaction_id) {
    jQuery.ajax({
          url: "/component/functions.cfc",
          data : {
            method : "getShipmentsByTransHtml",
            transaction_id : transaction_id
         },
        success: function (result) {
           $("#shipmentTable").html(result);
        },
        dataType: "html"
       }
     )};

function loadTransactionFormPermits(transaction_id) {
    jQuery.ajax({
          url: "/component/functions.cfc",
          data : {
            method : "getPermitsForTransHtml",
            transaction_id: transaction_id
         },
        success: function (result) {
           $("#transactionFormPermits").html(result);
        },
        dataType: "html"
       }
     )};

function loadShipmentFormPermits(shipment_id) {
    jQuery.ajax({
          url: "/component/functions.cfc",
          data : {
            method : "getPermitsForShipment",
            shipment_id : shipment_id
         },
        success: function (result) {
           $("#shipmentFormPermits").html(result);
        },
        dataType: "html"
       }
     )};

// On click handler for use this shipment address in invoice header.
// On result, reloads shipments.
//
// @param shipmentId the shipment to mark as print_flag=1
// @param transactionId the transaction for which to set all other
//    print_flags on shipments to 0.
function setShipmentToPrint(shipmentId,transactionId) {
    jQuery.getJSON("/component/functions.cfc",
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
     )};

function deleteMediaFromPermit(mediaId,permitId,relationType) {
    jQuery.getJSON("/component/functions.cfc",
        {
            method : "removeMediaFromPermit",
            media_id : mediaId,
            permit_id : permitId,
            media_relationship : relationType,
            returnformat : "json",
            queryformat : 'column'
        },
        function (result) {
           loadPermitMedia(permitId);
           loadPermitRelatedMedia(permitId);
        }
      )};
function deleteMediaFromDeacc(mediaId,transactionId,relationType) {
    jQuery.getJSON("/component/functions.cfc",
        {
            method : "removeMediaFromDeaccession",
            media_id : mediaId,
            transaction_id : transactionId,
            media_relationship : relationType,
            returnformat : "json",
            queryformat : 'column'
        },
        function (result) {
           loadDeaccessionMedia(transactionId);
        }
      )};
function deleteMediaFromTrans(mediaId,transactionId,relationType) {
    jQuery.getJSON("/component/functions.cfc",
        {
            method : "removeMediaFromDeaccession",
            media_id : mediaId,
            transaction_id : transactionId,
            media_relationship : relationType,
            returnformat : "json",
            queryformat : 'column'
        },
        function (result) {
           reloadTransMedia();
        }
      )};
/* Supporting function for Add ctspecific_permit_type dialog on New/Edit Permit pages, 
 * save a new ctspecific_permit_type.specific_type value and report feedback.
 */
function storeNewPermitSpecificType() { 
   jQuery.getJSON("component/functions.cfc",
         { 
            method: "addNewctSpecificType",
            new_specific_type: $('#new_specific_type').val()
         },
         function(data) { 
            $('#addTDFeedback').html(data.message);
         }
         );
}
/* Supporting function to create an add ctspecific_permit_type dialog on New/Edit Permit pages.
 */
function openAddSpecificTypeDialog() {
  console.log('called openAddSpecificTypeDialog');
  var dialog = $('#newPermitASTDialog')
  .html(
     '<div id="addTypeDialogFrm"><input type="text" name="new_specific_type" id="new_specific_type"><input type="button" value="Add" onclick="storeNewPermitSpecificType();"></div><div id="addTDFeedback"></div>'
  )
  .dialog({
    title: 'Add A Specific Type',
    autoOpen: false,
    dialogClass: 'dialog_fixed,ui-widget-header',
    modal: true,
    height: 300,
    width: 500,
    minWidth: 300,
    minHeight: 400,
    draggable:true,
    buttons: { "Ok": function () { 
                     var newval = $('#new_specific_type').val(); 
                     console.log(newval);
                     $('#specific_type').append($("<option></option>").attr("value",newval).text(newval)); 
                     $('#specific_type').val(newval);
                     console.log($('#specific_type').val());
                     $(this).dialog("close"); },
               "Close": function () { $(this).dialog("close"); }
             }
  });
  dialog.dialog('open');
  console.log('dialog open');
};
function deletePermitFromTransaction(permitId,transactionId) {
    jQuery.getJSON("/component/functions.cfc",
        {
            method : "removePermitFromTransaction",
            transaction_id : transactionId,
            permit_id : permitId,
            returnformat : "json",
            queryformat : 'column'
        },
        function (result) {
           loadTransactionFormPermits(transactionId);
        }
      )};
function deletePermitFromShipment(shipmentId,permitId,transactionId) {
    jQuery.getJSON("/component/functions.cfc",
        {
            method : "removePermitFromShipment",
            shipment_id : shipmentId,
            permit_id : permitId,
            returnformat : "json",
            queryformat : 'column'
        },
        function (result) {
           loadShipments(transactionId);
        }
      )};
function addPermitToShipment(shipmentId,permitId,transactionId) {
    jQuery.getJSON("/component/functions.cfc",
        {
            method : "setShipmentForPermit",
            shipment_id : shipmentId,
            permit_id : permitId,
            returnformat : "json",
            queryformat : 'column'
        },
        function (result) {
           if (result.DATA.STATUS=="0") {
               alert(result.DATA.MESSAGE);
           } 
           loadShipments(transactionId);
        }
    );
};
// Add a permit to a shipment with a callback function callback(statuscode).
function addPermitToShipmentCB(shipmentId,permitId,transactionId,callback) {
    jQuery.getJSON("/component/functions.cfc",
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

// Move a permit from one shipment to another.
function movePermitFromShipment(oldShipmentId,newShipmentId,permitId,transactionId) {
    jQuery.getJSON("/component/functions.cfc",
        {
            method : "removePermitFromShipment",
            shipment_id : oldShipmentId,
            permit_id : permitId,
            returnformat : "json",
            queryformat : 'column'
        },
        function (result) {
             if (result.DATA.STATUS==1) {
                jQuery.getJSON("/component/functions.cfc",
                  {
                    method : "setShipmentForPermit",
                    shipment_id : newShipmentId,
                    permit_id : permitId,
                    returnformat : "json",
                    queryformat : 'column'
                  },
                  function (result) {
                     if (result.DATA.STATUS!=1) {
                        alert(result.DATA.MESSAGE);
                     } 
                  }
                );
             } else {  
               alert(result.DATA.MESSAGE);
             } 
        }
      );
      loadShipments(transactionId);
}
// Move a permit from one shipment to another with a callback function callback(statuscode).
function movePermitFromShipmentCB(oldShipmentId,newShipmentId,permitId,transactionId,callback) {
    jQuery.getJSON("/component/functions.cfc",
        {
            method : "removePermitFromShipment",
            shipment_id : oldShipmentId,
            permit_id : permitId,
            returnformat : "json",
            queryformat : 'column'
        },
        function (result) {
             if (result.DATA.STATUS==1) {
                jQuery.getJSON("/component/functions.cfc",
                  {
                    method : "setShipmentForPermit",
                    shipment_id : newShipmentId,
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
                );
             } else {  
                alert(result.DATA.MESSAGE);
                callback(0);
             }
        }
      );
      loadShipments(transactionId);
}
function deleteShipment(shipmentId,transactionId) {
    jQuery.getJSON("/component/functions.cfc",
        {
            method : "removeShipment",
            shipment_id : shipmentId,
            transaction_id : transactionId,
            returnformat : "json",
            queryformat : 'column'
        },
        function (result) {
           loadShipments(transactionId);
        }
      )};

function addrPickWithTemp(addrIdFld,addrFld,formName){
	var url="/picks/AddrPick.cfm";
	var addrIdFld;
	var addrFld;
	var formName;
	var popurl=url+"?includeTemporary=true&addrIdFld="+addrIdFld+"&addrFld="+addrFld+"&formName="+formName;
	addrpick=window.open(popurl,"","width=400,height=338, resizable,scrollbars");
}

function addTemporaryAddress(targetAddressIdControl,targetAddressControl,transaction_id) { 
   var address_id = $("#"+targetAddressIdControl).val();
   var address = $("#"+targetAddressControl).val();
   $('#dialog-shipment').parent().hide();
   jQuery.ajax({
          url: "/component/functions.cfc",
          type : "post",
          dataType : "json",
          data : {
            method : "addAddressHtml",
            create_from_address_id : address_id,
            transaction_id : transaction_id
         },
        success: function (result) {
           $("#tempAddressDialog").html(result);
           $("#tempAddressDialog").dialog(
              { autoOpen: false, modal: true, stack: true, title: 'Add Temporary Address',
                  width: 593, 	
                  buttons: {
                     "Close": function() {
                         $("#tempAddressDialog").dialog( "close" );
                     }
                  },
                  beforeClose: function(event,ui) { 
                     var addr = $('#new_address').val();
                     if ($.trim(addr) != '') { 
                        $("#"+targetAddressIdControl).val($('#new_address_id').val());
                        $("#"+targetAddressControl).val(addr);
                     }
                  },
                  close: function(event,ui) { 
                     $('#dialog-shipment').parent().show();
                     $("#tempAddressDialog").dialog('destroy'); 
                     $("#tempAddressDialog").html(""); 
                  }  
              });
           $("#tempAddressDialog").dialog('open');
        },
        dataType: "html"
       }
   )
};

function loadShipment(shipmentId,form) {
    $("#dialog-shipment").dialog( "option", "title", "Edit Shipment " + shipmentId );
    $("#shipmentFormPermits").html(""); 
    $("#shipmentFormStatus").html(""); 
    jQuery.getJSON("/component/functions.cfc",
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
    );
};

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

// Check the validity of a form for submission return true if valid, false if not, and if 
// not valid, popup a message dialog listing the problem form elements and their validation messages.
// @param form DOM node of a form to validate
// @return true if the provided node has checkValidity() of true or if the node lacks the checkValidity method.\
//         false otherwise.
// Example usage in onClick event of a button in a form: if (checkFormValidity($('#formId')[0])) { submit();  }  
function checkFormValidity(form) { 
     var result = false;
     if (!form.checkValidity || form.checkValidity()) { 
         result = true;
     } else { 
         var message = "Form Input validation problem.<br><dl>";
         for(var i=0; i < form.elements.length; i++){
             var element = form.elements[i];
             if (element.checkValidity() == false) { 
                 var label = $( "label[for=" + element.id + "] ").text();
                 if (label==null || label=='') { label = element.id; }
                 message = message + "<dt>" + label + ":</dt> <dd>" + element.validationMessage + "</dd>";
             }
         }
         mmessage = message + "</dl>"
         messageDialog(message,'Unable to Save');
     }
     return result;
};

// Confirm dialog for some action, takes the function to fire on pressing OK as a parameter.
// Wrap the function to be invoked as okFunction in an anonymous function function() { thingToDo() } 
// or it will be evaluated prior to invocation instead of as a callback.
function confirmAction(dialogText, dialogTitle, okFunction) {
  $('<div style="padding: 10px; max-width: 500px; word-wrap: break-word;">' + dialogText + '</div>').dialog({
    modal: true,
    resizable: false,
    draggable: true,
    width: 'auto',
    minHeight: 80,
    title: dialogTitle,
    buttons: {
      OK: function () {
         setTimeout(okFunction, 30);
         $(this).dialog('destroy');
      },
      Cancel: function () {
         $(this).dialog('destroy');
      }
    },
    close: function() {
       $(this).dialog( "destroy" );
    }
  });
};

// Simple message dialog with an OK button.
function messageDialog(dialogText, dialogTitle) {
  $('<div style="padding: 10px; max-width: 500px; word-wrap: break-word;">' + dialogText + '</div>').dialog({
    modal: true,
    resizable: false,
    draggable: true,
    width: 'auto',
    minHeight: 80,
    title: dialogTitle,
    buttons: {
      OK: function () {
         $(this).dialog('destroy');
      }
    },
    close: function() {
       $(this).dialog( "destroy" );
    }
  });
};

/* Update the content of a div containing a count of the items in a Deaccession.
 * @param transactionId the transaction_id of the deaccession to lookup
 * @param targetDiv the id div for which to replace the contents (without a leading #).
 */
function updateDeaccItemCount(transactionId,targetDiv) {
    jQuery.getJSON("/component/functions.cfc",
        {
            method : "getDeaccItemCounts",
            transaction_id : transactionId,
            returnformat : "json",
            queryformat : 'column'
        },
        function (result) {
           if (result.DATA.STATUS[0]==1) { 
              var message  = "There are " + result.DATA.CATITEMCOUNT[0];
                  message += " items from " + result.DATA.PARTCOUNT[0];
                  message += " specimens in " + result.DATA.COLLECTIONCOUNT[0];
                  message += " collections with " + result.DATA.PRESERVECOUNT[0] +  " preservation types in this deaccession."
              $('#' + targetDiv).html(message);
           }
        }
      )};

/* Update the content of a div containing a count of the items in a Loan.
 * @param transactionId the transaction_id of the Loan to lookup
 * @param targetDiv the id div for which to replace the contents (without a leading #).
 */
function updateLoanItemCount(transactionId,targetDiv) {
    jQuery.getJSON("/component/functions.cfc",
        {
            method : "getLoanItemCounts",
            transaction_id : transactionId,
            returnformat : "json",
            queryformat : 'column'
        },
        function (result) {
           if (result.DATA.STATUS[0]==1) {
              var message  = "There are " + result.DATA.PARTCOUNT[0];
                  message += " parts from " + result.DATA.CATITEMCOUNT[0];
                  message += " catalog numbers in " + result.DATA.COLLECTIONCOUNT[0];
                  message += " collections with " + result.DATA.PRESERVECOUNT[0] +  " preservation types in this loan."
              $('#' + targetDiv).html(message);
           }
        }
      )};

/** Check an agent to see if the agent has a flag on the agent, if so alert a message
  * @param agent_id the agent_id of the agent to check for rank flags.  **/
function checkAgent(agent_id) {
    jQuery.getJSON(
        "/component/functions.cfc",
        {
            method : "checkAgentFlag",
            agent_id : agent_id,
            returnformat : "json",
            queryformat : 'column'
        },
        function (result) {
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
      );
};

/** Check to see if an agent is ranked, and update the provided targetLinkDiv accordingly with a View link
  * or a View link with a flag.
  * @param agent_id the agent_id to lookup.
  * @param targetLinkDiv the id (without a leading # for the div the contents of which to replace with the View link.
  */
function updateAgentLink(agent_id,targetLinkDiv) {
    jQuery.getJSON(
        "/component/functions.cfc",
        {
            method : "checkAgentFlag",
            agent_id : agent_id,
            returnformat : "json",
            queryformat : 'column'
        },
        function (result) {
           var rank = result.DATA.AGENTRANK[0];
           if (rank=='A') { 
                $('#'+targetLinkDiv).html("<a href='/Agents.cfm?agent_id=" + agent_id + "' target='_blank'>View</a>");
           } else {
              if (rank=='F') { 
                $('#'+targetLinkDiv).html("<a href='/Agents.cfm?agent_id=" + agent_id + "' target='_blank'>View</a><img src='/images/flag-red.svg.png' width='16'>");
                messageDialog('Please speak to Collections Ops about this loan agent before proceeding.','Agent with an F Rank');
              } else { 
                $('#'+targetLinkDiv).html("<a href='/Agents.cfm?agent_id=" + agent_id + "' target='_blank'>View</a><img src='/images/flag-yellow.svg.png' width='16'>");
                messageDialog("Please check this agent's rankings before proceeding",'Problematic Agent');
              }
           }
        }
      );
};



// Create a generic jquery-ui dialog that loads content from some page in an iframe and binds a callback
// function to the ok button.
//
// @param page uri for the page to load into the dialog
// @param id an id for a div on the calling page which will have its content replaced with the dialog, iframe 
//    in the dialog is also given the id {id}_iframe
// @param title to display in the dialog's heading
// @param okcallback callback function to execute when the OK button is clicked.
// @param dialogHeight the height of the dialog, 650 may be a good default value
// @param dialogWidth the width of the dialog, 800 may be a good default value
function opendialogcallback(page,id,title,okcallback,dialogHeight,dialogWidth) {
  var content = '<iframe style="border: 0px; " src="' + page + '" width="100%" height="100%" id="' + id +  '_iframe"></iframe>';
  var adialog = $("#"+id)
  .html(content)
  .dialog({
    title: title,
    autoOpen: false,
    dialogClass: 'dialog_fixed,ui-widget-header',
    modal: true,
    stack: true,
    zindex: 2000,
    height: dialogHeight,
    width: dialogWidth,
    minWidth: 400,
    minHeight: 450,
    draggable:true,
    buttons: {
        "Ok": function(){ if (jQuery.type(okcallback)==='function') okcallback();} ,
        "Cancel": function() {  $("#"+id).html('').dialog('destroy'); }
    }
  });
  adialog.dialog('open');
};

// Create and open a dialog to create a new media record adding a provided relationship to the media record 
function opencreatemediadialog(dialogid, related_value, related_id, relationship, okcallback) { 
  var title = "Add new Media record to " + related_value;
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
     zindex: 2000,
     height: h,
     width: w,
     minWidth: 400,
     minHeight: 450,
     draggable:true,
     buttons: {
        "Save Media Record": function(){ 
           if (jQuery.type(okcallback)==='function') {
	   if ($('#newMedia')[0].checkValidity()) {
               $.ajax({
                  url: 'media.cfm',
                  type: 'post',
		  returnformat: 'plain',
                  data: $('#newMedia').serialize(),
                  success: function(data) { 
                      okcallback();
                      $("#"+dialogid+"_div").html(data);
                  },
     		  fail: function (jqXHR, textStatus) { 
	 	        $("#"+dialogid+"_div").html("Error:" + textStatus);
     		  }	
		});
           } else { 
                messageDialog('Missing required elements in form.  Fill in all yellow boxes. ','Form Submission Error, missing required values');
           }
           }
        },
        "Close Dialog": function() { 
		$(this).dialog('close'); 
        }
    },
    close: function(event,ui) {
        	if (jQuery.type(okcallback)==='function') {
             		okcallback();
        	}
		if (dialogid.startsWith("addMediaDlg")) { 
        		$("#"+dialogid+"_div").remove();
	        	$("#"+dialogid).empty();
	        	$("#"+dialogid).remove();
                } else { 
        		$("#"+dialogid+"_div").html("");
			$("#"+dialogid).dialog('destroy');
		}
    }
  });
  thedialog.dialog('open');
  jQuery.ajax({
     url: "/component/functions.cfc",
     type: "post",
     data: {
        method: "createMediaHtml",
     	returnformat: "plain",
        relationship: relationship,
        related_value: related_value,
        related_id: related_id
     }, 
     success: function (data) { 
        $("#"+dialogid+"_div").html(data);
     }, 
     fail: function (jqXHR, textStatus) { 
        $("#"+dialogid+"_div").html("Error:" + textStatus);
     }
  });
}
// Create and open a dialog to find and link existing media records with a provided relationship
function openlinkmediadialog(dialogid, related_value, related_id, relationship, okcallback) { 
  var title = "Link Media record to " + related_value;
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
     zindex: 2000,
     height: h,
     width: w,
     minWidth: 400,
     minHeight: 450,
     draggable:true,
     buttons: {
        "Close Dialog": function() { 
		$(this).dialog('close'); 
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
     url: "/component/functions.cfc",
     type: "post",
     data: {
        method: "linkMediaHtml",
     	returnformat: "plain",
        relationship: relationship,
        related_value: related_value,
        related_id: related_id
     }, 
     success: function (data) { 
        $("#"+dialogid+"_div").html(data);
     }, 
     fail: function (jqXHR, textStatus) { 
        $("#"+dialogid+"_div").html("Error:" + textStatus);
     }
  });
}
// Create and open a dialog to find and link existing permit records to a provided shipment
function openlinkpermitshipdialog(dialogid, shipment_id, shipment_label, okcallback) { 
  var title = "Link Permit record(s) to " + shipment_label;
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
     url: "/component/functions.cfc",
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
     fail: function (jqXHR, textStatus) { 
        $("#"+dialogid+"_div").html("Error:" + textStatus);
     }
  });
}
// Create and open a dialog to find and link existing permit records to a provided transaction
function openlinkpermitdialog(dialogid, transaction_id, transaction_label, okcallback) { 
  var title = "Link Permit record(s) to " + transaction_label;
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
     url: "/component/functions.cfc",
     type: "post",
     data: {
        method: "transPermitPickerHtml",
     	returnformat: "plain",
        transaction_id: transaction_id,
        transaction_label: transaction_label
     }, 
     success: function (data) { 
        $("#"+dialogid+"_div").html(data);
     }, 
     fail: function (jqXHR, textStatus) { 
        $("#"+dialogid+"_div").html("Error:" + textStatus);
     }
  });
}
// Create and open a dialog to create a new permit record adding a provided relationship to the permit record
function opencreatepermitdialog(dialogid, related_label, related_id, relation_type, okcallback) { 
  var title = "Add new Permit record to " + related_label;
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
     zindex: 2000,
     height: h,
     width: w,
     minWidth: 400,
     minHeight: 450,
     draggable:true,
     buttons: {
        "Save Permit Record": function(){ 
           var datasub = $('#newPermitForm').serialize();
	       if ($('#newPermitForm')[0].checkValidity()) {
               $.ajax({
     		      url: "/component/functions.cfc",
                  type: 'post',
        		  returnformat: 'plain',
                  data: datasub,
                  success: function(data) { 
                      if (jQuery.type(okcallback)==='function') {
                          okcallback();
                      };
                      $("#"+dialogid+"_div").html(data);
                  },
     		      fail: function (jqXHR, textStatus) { 
	 	            $("#"+dialogid+"_div").html("Error:" + textStatus);
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
        method: "getNewPermitForTransHtml",
     	returnformat: "plain",
        relation_type: relation_type,
        related_label: related_label,
        related_id: related_id
  };
  jQuery.ajax({
     url: "/component/functions.cfc",
     type: "post",
     data: datastr,
     success: function (data) { 
        $("#"+dialogid+"_div").html(data);
     }, 
     fail: function (jqXHR, textStatus) { 
        $("#"+dialogid+"_div").html("Error:" + textStatus);
     }
  });
}
