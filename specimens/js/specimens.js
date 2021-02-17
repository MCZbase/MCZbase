function loadCitPubForMedia(publication_id) {
targetDiv="CitPubFormMedia";
	console.log(" media in #"+ targetDiv);
	jQuery.ajax({
		url: "/specimens/component/functions.cfc",
		data : {
			method : "getMediaForCitPub",
			publication_id: publication_id,
		},
		success: function (result) {
			$("#CitPubFormMedia").html(result);
		},
		error: function (jqXHR, textStatus, error) {
			handleFail(jqXHR,textStatus,error,"removing pub");
		},
		dataType: "html"
	});
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

