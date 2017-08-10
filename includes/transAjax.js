
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

function loadShipment(shipmentId,form) {
    $("#dialog-shipment").dialog( "option", "title", "Edit Shipment " + shipmentId );
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
                   $("#shipped_to_addr").text(result.DATA.SHIPPED_TO_ADDRESS[i]);
                   $("#shipped_from_addr").text(result.DATA.SHIPPED_FROM_ADDRESS[i]);
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
        $("#shipped_to_addr").text("");
        $("#shipped_from_addr").text("");
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
             if (result.DATA.STATUS==0) { 
               $("#shipmentFormStatus").empty().append(result.DATA.MESSAGE);
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

// Confirm dialog for some action, takes the function to fire on pressing OK as a parameter.
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
                alert ('F problem agent message');
              } else { 
                alert ('B-D problem agent message');
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
function opendialogcallback(page,id,title,okcallback) {
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
    height: 650,
    width: 800,
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

