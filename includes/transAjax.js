
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
        var datestring = date.getFullYear() + "-" + ("0"+(date.getMonth()+1)).slice(-2) + "-" ("0" + date.getDate()).slice(-2);
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
    }

    function saveShipment(transactionId) { 
       var valid = true;
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
             if (result.status==0) { 
               alert(result.message);
               $("#shipmentFormStatus").innerHTML=result.message;
             } else { 
               loadShipments(transactionId);
               $("#dialog-shipment").dialog( "close" );
             }
           },
           fail: function (jqXHR,textStatus) {
               $("#shipmentFormStatus").innerHTML="Error Submitting Form: " +textStatus;
           }
       });
       return valid;
    };
