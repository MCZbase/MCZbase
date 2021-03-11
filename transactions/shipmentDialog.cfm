<cfquery name="ctShip" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select shipped_carrier_method from ctshipped_carrier_method order by shipped_carrier_method
</cfquery>
<cfoutput>
<!----  Shipment Popup Dialog autoOpen is false --->
	
<script>
	////shipment dialog needs to have a minimum of 320px and then be 90% of ipad and up
	$( document ).ready(function() {
		console.log("initializing dialog-shipment");
		$("##dialog-shipment").dialog({
			autoOpen: false,
			modal: true,
			width: 'auto',
			height: 'auto',
			minWidth: 320,
			minHeight: 500,
			buttons: {
				"Save": function() {  saveShipment(#transaction_id#); } ,
				Cancel: function() { $(this).dialog( "close" ); }
			},
			close: function() {
				$(this).dialog( "close" );
			}
		});
	});
</script>
<script>
	/** Given a form with id shipmentForm (with form fields matching shipment fields), invoke a backing
	 *  function to save that shipment.
	 *  Assumes an element with id shipmentFormStatus exists to present feedback.
	 *  Assumes the form has an id of shipmentForm
	 *
	 *  @param transactionId the transaction_id of the transaction to which the shipment is to be added.
	 */
	function saveShipment(transactionId) { 
		var valid = false;
		if (checkFormValidity('shipmentForm')) { 
			// save result
			$('##methodSaveShipmentQF').remove();
			$('<input id="methodSaveShipmentQF" />').attr('type', 'hidden')
				.attr('name', "queryformat")
				.attr('value', "column")
				.appendTo('##shipmentForm');
			$('##methodSaveShipmentInput').remove();
			$('<input id="methodSaveShipmentInput" />').attr('type', 'hidden')
				.attr('name', "method")
				.attr('value', "saveShipment")
				.appendTo('##shipmentForm');
			$.ajax({
				url : "/transactions/component/functions.cfc",
				type : "post",
				dataType : "json",
				data: $("##shipmentForm").serialize(),
				success: function (result) {
					if (result.DATA.STATUS[0]==0) { 
						$("##shipmentFormStatus").empty().append(result.DATA.MESSAGE[0]);
					} else { 
						loadShipments(transactionId);
						valid = true;
						$("##dialog-shipment").dialog( "close" );
					}
				},
				error: function (jqXHR, status, error) {
					$("##shipmentFormStatus").empty().append("Error Submitting Form: " + status);
					handleFail(jqXHR,status,error,"opening dialog to for project creation from transaction dialog");
				}
			});
		}
		return valid;
	};
</script>
	<dialog id="dialog-shipment" title="Create New Shipment">
		<div class="container-fluid">
			<div class="row">
				<div class="col-12 px-0">
					<form name="shipmentForm" id="shipmentForm" >
						<fieldset>
							<input type="hidden" name="transaction_id" value="#transaction_id#" id="shipmentForm_transaction_id" >
							<input type="hidden" name="shipment_id" value="" id="shipment_id">
							<input type="hidden" name="returnFormat" value="json" id="returnFormat">
								<div class="border bg-light px-3 rounded mt-3 pt-2 pb-3">
									<div class="row mt-2">
										<div class="col-12 col-md-4">
											<label for="shipped_carrier_method" class="data-entry-label">Shipping Method</label>
											<select name="shipped_carrier_method" id="shipped_carrier_method" size="1" class="reqdClr data-entry-select" required >
												<option value=""></option>
												<cfloop query="ctShip">
													<option value="#ctShip.shipped_carrier_method#">#ctShip.shipped_carrier_method#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-8">
											<label for="carriers_tracking_number" class="data-entry-label">Tracking Number</label>
											<input type="text" value="" name="carriers_tracking_number" id="carriers_tracking_number" size="30" class="data-entry-input" >
										</div>
									</div>
									<div class="row mt-2">
										<div class="col-12 col-md-4">
											<label for="no_of_packages" class="data-entry-label">Number of Packages</label>
											<input type="text" value="1" name="no_of_packages" id="no_of_packages" class="data-entry-input">
										</div>
										<div class="col-12 col-md-4">
											<label for="shipped_date" class="data-entry-label">Ship Date</label>
											<input type="text" value="#dateformat(Now(),'yyyy-mm-dd')#" name="shipped_date" id="shipped_date" class="data-entry-input">
										</div>
										<div class="col-12 col-md-4">
											<label for="foreign_shipment_fg" class="data-entry-label">Foreign shipment?</label>
											<select name="foreign_shipment_fg" id="foreign_shipment_fg" size="1" class="data-entry-select">
												<option selected value="0">no</option>
												<option value="1">yes</option>
											</select>
										</div>
									</div>
									<div class="row mt-2">
										<div class="col-12 col-md-5">
											<label for="package_weight" class="data-entry-label">Package Weight <small>(TEXT, include units)</small></label>
											<input type="text" value="" name="package_weight" id="package_weight" class="data-entry-input">
										</div>
										<div class="col-12 col-md-5">
											<label for="insured_for_insured_value" class="data-entry-label w-100">Insured Value <small>(NUMBER, US$)</small></label>
											<input type="text" validate="float" label="Numeric value required."
												value="" name="insured_for_insured_value" id="insured_for_insured_value" pattern="^[0-9.]*$" class="data-entry-input">
										</div>
										<div class="col-12 col-md-2">
											<label for="hazmat_fg" class="data-entry-label">HAZMAT?</label>
											<select name="hazmat_fg" id="hazmat_fg" size="1" class="data-entry-select">
												<option selected value="0">no</option>
												<option value="1">yes</option>
											</select>
										</div>
									</div>
									<div class="row mt-2">
										<div class="col-12">
											<span class="data-entry-label">
												<label for="packed_by_agent">Packed By Agent</label>
												<span id="packed_by_agent_view_link" class="px-2">&nbsp;</span>
											</span>
											<div class="input-group">
												<div class="input-group-prepend">
													<span class="input-group-text small" id="packed_by_agent_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
												</div>
												<input type="text" name="packed_by_agent" id="packed_by_agent" required class="form-control rounded-right data-entry-input reqdClr" value="">
											</div>
											<input type="hidden" class="data-entry-input" name="packed_by_agent_id" id="packed_by_agent_id" value=""
												onchange=" updateAgentLink($('##packed_by_agent_id').val(),'packed_by_agent_view_link'); ">
											<script>
												$(document).ready(function() {
													$(makeRichTransAgentPicker('packed_by_agent','packed_by_agent_id','packed_by_agent_icon','packed_by_agent_view_link',null)); 
												});
											</script>
										</div>
									</div>
									<div class="row mt-2">
										<div class="col-12 my-1">
											<span class="data-entry-label">
												<label for="shipped_to_addr">Shipped To Address</label>
												<input type="button" value="Pick Address" class="btn btn-primary btn-xs my-2"
													onClick="openfindaddressdialog('shipped_to_addr','shipped_to_addr_id','addressDialog',#transaction_id#); return false;">
											</span>
											<div class="form-group">
												<textarea name="shipped_to_addr" id="shipped_to_addr" cols="65" rows="5" required style="height: 5rem;"
													readonly="yes" class="reqdClr w-100"></textarea><!--- not autogrow --->
											</div>
											<input type="hidden" name="shipped_to_addr_id" id="shipped_to_addr_id" value="">
										</div>
									</div>
									<div class="row mt-2">
										<div class="col-12 my-1">
											<span class="data-entry-label">
												<label for="shipped_from_addr">Shipped From Address</label>
												<input type="button" value="Pick Address" class="btn btn-primary btn-xs my-2" 
													onClick="openfindaddressdialog('shipped_from_addr','shipped_from_addr_id','addressDialog',#transaction_id#); return false;">
											</span>
											<div class="form-group">
												<textarea name="shipped_from_addr" id="shipped_from_addr" cols="65" rows="5" required style="height: 5rem;"
													readonly="yes" class="reqdClr w-100"></textarea><!--- not autogrow --->
											</div>
											<input type="hidden" name="shipped_from_addr_id" id="shipped_from_addr_id" value="">
										</div>
									</div>
									<div class="row mt-2">
										<div class="col-12">
											<label for="shipment_remarks" class="data-entry-label">Remarks</label>
											<input type="text" value="" name="shipment_remarks" id="shipment_remarks" size="60" class="data-entry-input">
										</div>
									</div>
									<div class="row mt-2">
										<div class="col-12">
											<label for="contents" class="data-entry-label">Contents</label>
											<input type="text" value="" name="contents" id="contents" size="60" class="data-entry-input">
										</div>
									</div>
								</div>
						</fieldset>
					</form>
				</div>
			</div>
		</div>
	<div id="shipmentFormPermits"></div>
	<div id="shipmentFormStatus"></div>
	<div id="addressDialog"></div>
	</dialog>
<!----  End Shipment dialog --->
</cfoutput>
