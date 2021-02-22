<cfoutput> 
	<!----  Identification Popup Dialog autoOpen is false ---> 
	
	<script>
	////identification dialog needs to have a minimum of 320px and then be 90% of ipad and up
	$( document ).ready(function() {
		console.log("initializing dialog-identification");
		$("##dialog").dialog({
			autoOpen: false,
			modal: true,
			width: 'auto',
			height: 'auto',
			minWidth: 320,
			minHeight: 500,
			buttons: {
				"Save": function() {  saveIdentification(#identification_id#); } ,
				Cancel: function() { $(this).dialog( "close" ); }
			},
			close: function() {
				$(this).dialog( "close" );
			}
		});
	});
</script> 
	<script>
	/** Given a form with id identificationForm (with form fields matching identification fields), invoke a backing
	 *  function to save that identification.
	 *  Assumes an element with id identificationFormStatus exists to present feedback.
	 *  Assumes the form has an id of shipmentForm
	 */
	function saveIdentification(identificationId) { 
		var valid = false;
		if (checkFormValidity('identificationForm')) { 
			// save result
			$('##methodSaveIdentificationQF').remove();
			$('<input id="methodSaveIdentificationQF" />').attr('type', 'hidden')
				.attr('name', "queryformat")
				.attr('value', "column")
				.appendTo('##identificationForm');
			$('##methodSaveIdentificationInput').remove();
			$('<input id="methodSaveIdentificationInput" />').attr('type', 'hidden')
				.attr('name', "method")
				.attr('value', "saveIdentification")
				.appendTo('##identificationForm');
			$.ajax({
				url : "/specimens/component/functions.cfc",
				type : "post",
				dataType : "json",
				data: $("##identificationForm").serialize(),
				success: function (result) {
					if (result.DATA.STATUS[0]==0) { 
						$("##identificationFormStatus").empty().append(result.DATA.MESSAGE[0]);
					} else { 
						loadIdentifications(identificationId);
						valid = true;
						$("##dialog-identification").dialog( "close" );
					}
				},
				error: function (jqXHR, status, error) {
					$("##identificationFormStatus").empty().append("Error Submitting Form: " + status);
					handleFail(jqXHR,status,error,"opening dialog for identification dialog");
				}
			});
		}
		return valid;
	};
</script>
	
	
	
	<dialog id="dialog-identification" title="Create New Identification">
		<div class="container-fluid">
			<div class="row">
				<div class="col-12 px-0">
					<form name="newIdentificationForm" id="newIdentificationForm" >
						<fieldset>
						<input type="hidden" name="identification_id" value="#identification_id#" id="newIdentificationForm_identification_id" >
						<input type="hidden" name="identification_id" value="" id="identification_id">
						<input type="hidden" name="returnFormat" value="json" id="returnFormat">
							<div class="border bg-light px-3 rounded mt-3 pt-2 pb-3">
								<div class='identifcationForm'>
								<form>
									<div class='container pl-1'>
										<div class='col-md-6 col-sm-12 float-left'>
											<div class='form-group'>
												<label for='scientific_name'>Scientific Name:</label>
												<input type='text' name='taxona' id='taxona' class='reqdClr form-control form-control-sm' value='#scientific_name#' size='1' onChange='taxaPick(''taxona_id'',''taxona'',''newID'',this.value); return false;'	onKeyPress=return noenter(event);'>
												<input type='hidden' name='taxona_id' id=taxona_id' class='reqdClr'>
											</div>
											<div class='form-group w-25 mb-3 float-left'>
												<label for='taxa_formula'>Formula:</label>
												<select class='border custom-select form-control input-sm' id='select'>
													<option value='' disabled='' selected=''>#taxa_formula#</option>
													<option value='A'>A</option>
													<option value='B'>B</option>
													<option value='sp.'>sp.</option>
												</select>
											</div>
											<div class='form-group w-50 mb-3 ml-3 float-left'>
												<label for='made_date'>Made Date:</label>
												<input type='text' class='form-control ml-0 input-sm' id='made_date' value='#dateformat(made_date,'yyyy-mm-dd')#'>
											</div>
										</div>
										<div class='col-md-6 col-sm-12 float-left'>
											<div class='form-group'>
												<label for='nature_of_id'>Determined By:</label>
												<input type='text' class='form-control-sm' id='nature_of_id' value='#agent_name#'>
											</div>
											<div class='form-group'>
												<label for='nature_of_id'>Nature of ID:</label>
												<select name='nature_of_id' id='nature_of_id' size='1' class='reqdClr custom-select form-control'>
													<cfloop query='theResult'>
														<option value='theResult.nature_of_id'>#nature_of_id#</option>
													</cfloop>
												</select>
											</div>
										</div>
										<div class='col-md-12 col-sm-12 float-left'>
											<div class='form-group'>
												<label for='full_taxon_name'>Full Taxon Name:</label>
												<input type='text' class='form-control-sm' id='full_taxon_name' value='#full_taxon_name#'>
											</div>
											<div class='form-group'>
												<label for='identification_remarks'>Identification Remarks:</label>
												<textarea type='text' class='form-control' id='identification_remarks' value='#identification_remarks#'></textarea>
											</div>
											<div class='form-check'>
												<input type='checkbox' class='form-check-input' id='materialUnchecked'>
												<label class='mt-2 form-check-label' for='materialUnchecked'>Stored as #scientific_name#</label>
											</div>

										</div>
									</div>
								</form>
								</div>
							</div>
						</fieldset>
					</form>
				</div>
			</div>
		</div>
		<div id="identificationFormStatus"></div>
	</dialog>
	<!----  End dialog ---> 
</cfoutput> 