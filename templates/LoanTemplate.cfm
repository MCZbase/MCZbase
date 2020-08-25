<cfset pageTitle="Form Template">
<cfinclude template = "/shared/_header.cfm">
<!---------------------------------------------------------------------------------->
<!--- source of function?  Looks like copy/paste from somwehere, not formatted according to style guide, won't work as is with expected ajax submission handling --->
<!--- use $(document).ready() rather than adding a load event listener --->
<script>
	$(document).ready( function() {   
		// Fetch all the forms we want to apply custom Bootstrap validation styles to
		var forms = document.getElementsByClassName('needs-validation');
		// Loop over them and prevent submission on validation failure
		// handled directly by browser with html 5 pattern and required elements
		var validation = Array.prototype.filter.call(forms, function(form) {
			form.addEventListener('submit', function(event) {
			if (form.checkValidity() === false) {
				event.preventDefault();
				event.stopPropagation();
			}
			form.classList.add('was-validated');
		}, false);
	});
</script>
<script>
	jQuery(document).ready(function() {
  		$("##trans_date").datepicker({ dateFormat: 'yy-mm-dd'});
	});
</script>
<cfoutput>
<main class="container-fluid">
	<section class="row"><!--- see notes below about aside, main form and additional form elements (shipments, media, permits, etc) should be sections, all wrapped in a main --->
		<div class="col-12">
			<h1 class="h2">Loan Example</h1>
		</div>
		<div class="col-12">
			<form id="loanTemplateForm"  class="was-validated"><!--- with the ajax save/update form handling instead of form posts to reload page, we would need much more complex logic to handle adding/removing needs-validation and was-validated, probably best to not use these, but use the browser's html5 required and pattern support.  Form must have ID--->
				<div class="form-row mb-0">
					<div class="form-group col-12 col-md-3 col-lg-2 mx-lg-3"><!--- typically use 4 columns for forms --->
						<label class="data-entry-label" for="inlineFormCustomSelect">Collection</label>
						<select class="custom-select custom-select-sm" id="inlineFormCustomSelect">
							<option value="" selected>Choose...</option>
							<option value="1">Cryogenic</option>
							<option value="2">Entomology</option>
							<option value="3">Herpetology</option>
							<option value="3">Invertebrate Zoology</option>
						</select>
					</div>
					<div class="form-group col-md-3 col-lg-2 mx-lg-3">
						<label class="data-entry-label" for="loan_number">Loan Number</label>
						<input type="text" name="loan_number" class="form-control form-control-sm reqdClr" id="loan_number" required > <!--- Need to mark required elements, both with required and with a class, class must give them a yellow background --->
					</div>
					<div class="form-group col-12 col-md-3 col-lg-2 mx-lg-3">
						<label class="data-entry-label" for="trans_date">Transaction Date</label>
						<input type="text" class="form-control form-control-sm" id="trans_date" name="trans_date"><!--- all form inputs must have a name, this should almost always match the database field name, also provide an id, almost always the same as the name ---><!--- bound to date picker on document ready in script above --->
					</div>
					<div class="form-group col-12 col-md-3 col-lg-2 mx-lg-3">
						<label class="data-entry-label" for="inputNum">Due Date</label>
						<input type="text" class="form-control form-control-sm" id="inputNum">
					</div>
				</div>
				<div class="col-12 my-3 pb-3 pt-2 border rounded bg-light">
					<div class="form-row mb-1">
						<div class="col-12 col-md-6"><!--- Why no form-group?  Does form-group do anything desirable, or can we just omit it everywhere? --->
							<span>
								<label for="underscore_agent_name" id="underscore_agent_name_label" class="data-entry-label">Agent
								<span id="underscore_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> 
								</label>
							</span>
							<div class="input-group">
								<div class="input-group-prepend">
									<span class="input-group-text input-group-text-sm" id="underscore_agent_name_icon bg-grayish"><i class="fa fa-user" aria-hidden="true"></i></span> 
								</div>
								<input type="text" name="underscore_agent_name" id="underscore_agent_name" class="form-control form-control-sm rounded-right" value="" aria-label="Agent" aria-describedby="underscore_agent_name_label">
								<input type="hidden" name="underscore_agent_id" id="underscore_agent_id" value="">
							</div>
							<script>
								$(document).ready(function() {
									$(makeRichAgentPicker('underscore_agent_name', 'underscore_agent_id', 'underscore_agent_name_icon', 'underscore_agent_view', null));
								});
							</script> 
						</div>
						<div class="col-12 col-md-4 mt-3 mt-md-0">
							<label class="data-entry-label" for="inlineFormCustomSelect">Agent Role</label>
							<select class="custom-select custom-select-sm" id="inlineFormCustomSelect">
								<option selected>Choose...</option>
								<option value="1">Received By</option>
								<option value="2">Authorized By</option>
								<option value="3">In-house Contact</option>
							</select>
						</div>
						<div class="col-6 col-md-1 mt-3 mt-md-0">
							<label class="data-entry-label form-row text-danger mt-2" for="inlineFormCustomSelect">Delete</label>
							<div class="form-check mt-1">
								<input class="form-check-input" type="checkbox" id="gridCheck">
								<label class="form-check-label" for="gridCheck"> </label>
							</div>
						</div>
						<div class="col-6 col-md-1 pt-3 pt-md-0 mt-4"><a class="btn-link" href="##">Add</a></div>
					</div>
				</div>
				<div class="form-row mb-1">
					<div class="form-group col-12 col-md-3">
						<label class="data-entry-label" for="inlineFormCustomSelect">Loan Type</label>
						<select class="custom-select custom-select-sm" id="inlineFormCustomSelect">
							<option selected>Choose...</option>
							<option value="1">Exhibition Master</option>
							<option value="2">Exhibition Subloan</option>
							<option value="3">Consumable</option>
							<option value="4">Returnable</option>
						</select>
					</div>
					<div class="form-group col-12 col-md-3">
						<label class="data-entry-label" for="inputLoanStatus">Loan Status</label>
						<select class="custom-select custom-select-sm" id="inlineFormCustomSelect">
							<option selected>Choose...</option>
							<option value="1">In Process</option>
							<option value="2">Open</option>
							<option value="3">Closed</option>
							<option value="4">Open Historical</option>
						</select>
					</div>
					<div class="form-group col-12 col-md-6">
						<label class="data-entry-label" for="validatedSubloan">Add Subloan</label>
						<div class="custom-file">
							<input type="file" class="custom-file-input" id="validatedSubloan required">
							<label class="custom-file-label" for="validatedSubloan">Add...</label>
							<div class="invalid-feedback">Example invalid custom file feedback</div>
						</div>
					</div>
				</div>
				<div class="form-row">
					<div class="form-group col-12 mb-4">
						<!--- on all text areas include a span to display characters used/remaining --->
						<label class="data-entry-label" for="exampleFormControlTextarea1">Nature of Material (<span id="length_loan_nature"></span>)</label>
						<textarea class="autogrow form-control" 
								onkeyup="countCharsLeft('nature_of_material', 4000, 'length_loan_nature');"
								id="nature_of_material" 
								rows="2"></textarea><!--- see script below, makes text areas autogrow, add autogrow class, onkeyup handler and span to display chars used/remaining --->
					</div>
				</div>
					<div class="col-12 mb-3 mt-3 py-2 border rounded bg-light">
					<div class="form-row mb-1">
						<div class="form-group col-12">
							<h3 class="h4 m-0">Add collection objects to loan</h3>
						</div>
						<div class="col-12">
							<button type="submit" class="btn-xs btn-secondary mr-2">Add</button>
							<button type="submit" class="btn-xs btn-secondary mr-2">Add by Barcode</button>
							<button type="submit" class="btn-xs btn-secondary mr-2">Review</button>
						</div>

					</div>
				</div>

				<div class="form-row">
					<div class="form-group col-12 mt-2">
						<label class="data-entry-label" for="exampleFormControlDescription">Description</label>
						<textarea class="form-control autogrow" id="exampleFormControlDescription" rows="2"></textarea>
					</div>
				</div>
				<div class="form-row">
					<div class="form-group col-12 mt-2">
						<label class="data-entry-label" for="exampleFormControlDescription">Loan Instructions</label>
						<textarea class="form-control autogrow" id="exampleFormControlDescription" rows="2"></textarea>
					</div>
				</div>
				<div class="form-row">
					<div class="form-group col-12 mt-2">
						<label class="data-entry-label" for="exampleFormControlDescription">Internal Remarks</label>
						<textarea class="form-control autogrow" id="exampleFormControlDescription" rows="2"></textarea>
					</div>
				</div>
				<div class="form-row mt-3">
					<div class="form-group col-12">
						<button type="submit" class="btn-xs btn-primary mr-2"
							onClick="if (checkFormValidity($('##loanTemplateForm')[0])) { saveEdits();  } " 
							id="submitButton" >Save Edits</button>
						<button type="submit" class="btn-xs btn-danger mr-2">Delete Loan</button>
					</div>
				</div>
				<output id="saveResultDiv" class="text-danger mx-auto text-center">&nbsp;</output>	
			</form>
			<script>
				function changed(){
					$('##saveResultDiv').html('Unsaved changes.');
					$('##saveResultDiv').addClass('text-danger');
					$('##saveResultDiv').removeClass('text-success');
					$('##saveResultDiv').removeClass('text-warning');
				};
				// not all inputs on this form are bound by the selectors below, need additional lines for this to work with all form elements
				$(document).ready(function() {
					// caution, text inputs must have type=text to be bound to change function.
					$('##taxon_form input[type=text]').on("change",changed);
					$('##taxon_form select').on("change",changed);
					$('##taxon_remarks').on("change",changed);
					countCharsLeft('taxon_remarks', 4000, 'length_taxon_remarks');
				});
				function saveEdits(confirmClicked=false){ 
					// ajax handling of form submission and response 
					// see a working example on /taxonomy/Taxonomy.cfm
				});
			</script>
		</div>
		<script>
			// Make all textareas currently defined autogrow as text is entered, for all areas, place this inside the document ready function below, can be on selector textarea.autogrow
			$("textarea").keyup(autogrow);  
			// When editing existing data, on page load, trigger they keyup event on all autogrow classed text areas to set the used/remaining spans to initial values.
			$(document).ready(function() {
				// trigger keyup event to size textareas to existing text
				$('textarea.autogrow').keyup();
			});
		</script>
	</section>
	<section class="row mx-0">
		<div class="col-12"><!--- aside isn't correct semantics here, this should all be within main - the semantics are this is main page content, but handled as subforms, not as loosely related sidebar content.  Aside would be appropriate for lists of similar loans or other content related, but not part of the loan itself. --->
			<h2 class="h3 mb-0">Invoices and Reports</h2>
			<h3 class="h4 font-weight-light">Print Invoices and Reports for shipments and files.</h3>
			<div class="form-row">
				<div class="form-group col-12">
					<select class="custom-select mr-sm-2" id="inlineFormCustomSelect">
						<option selected>Choose Report...</option>
						<option value="1">Invoice Header</option>
						<option value="2">Itemized List (Cat Num Sort)</option>
						<option value="3">Itemized List (Taxa Sort)</option>
					</select>
				</div>
			</div>
			<div class="form-row mt-1">
				<div class="form-group col-12 mb-2">
					<h2 class="h3 mb-0">Media</h2>
					<h3 class="h4 font-weight-light">Connections to other records such as projects can go here.</h3>
					<button class="btn-xs btn-secondary mr-2" type="submit">Link Media</button>
					<button class="btn-xs btn-secondary" type="submit">Create Media</button>
				</div>
			</div>
			<div class="col-12 px-0">
				<h2 class="mt-4 h3">Shipment Information</h2>
				<div class="form-row mt-3 border px-2 pt-3 pb-1">
					<div class="col-md-12">
						<h3 class="h4 mt-0">Most Recent Shipment</h3>
						<h5>Shipped To:</h5>
						<p class="fs-14">(☑ Printed on invoice) Stephanie Carson, Senior Museum Registrar American Museum of Natural History Office of the Registrar Central Park West at 79th Street New York, New York 10024 United States</p>
						<h5>Shipped From:</h5>
						<p class="fs-14">Collections Operations Museum of Comparative Zoology Harvard University 26 Oxford St. Cambridge, MA 02138</p>
						<div class="form-row mb-1">
							<div class="col-md-5 form-group">
								<label class="data-entry-label" for="inlineShipDate">Ship Date</label>
								<input type="text" class="form-control data-entry-input ml-0" id="inputShipDate">
							</div>
							<div class="col-md-7 form-group">
								<label class="data-entry-label" for="inlineMethod">Method</label>
								<input type="text" class="form-control data-entry-input ml-0" id="inputShipDate">
							</div>
						</div>
						<div class="form-row mb-2">
							<div class="col-md-3 form-group">
								<label class="data-entry-label" for="inlinePackages">Packages</label>
								<input type="text" class="form-control data-entry-input" id="inputShipDate">
							</div>
							<div class="col-md-9 form-group">
								<label class="data-entry-label" for="inlinePackages">Tracking Number</label>
								<input type="text" class="form-control data-entry-input" id="inputShipDate">
							</div>
						</div>
						<div class="form-row">
							<div class="col-md-12 mt-1">
								<h5 class="ml-1">Permits: </h5>
								<ul class="list-group" style="background-color: white;">
									<li class="list-group-item d-flex justify-content-between align-items-center fs-14" style="border: 1px solid rgba(0,0,0,.125);"> Collecting/Take Permission OP 834 <br>
										Issued: 2010-02-26, By: Ezemvelo KZN Wildlife <span class="badge badge-primary badge-pill">14</span> </li>
									<li class="list-group-item d-flex justify-content-between align-items-center fs-14" style="border: 1px solid rgba(0,0,0,.125);"> Export Permission FAUNA 581/2009 <br>
										Issued: 2009-09-01, By: Department of Environment and Nature Conservation, Northern Cape <span class="badge badge-primary badge-pill">2</span> </li>
								</ul>
							</div>
						</div>
						<div class="form-row mt-1">
							<div class="form-group col-md-12">
								<button class="btn-xs btn-secondary mr-2" type="submit">Edit this Shipment</button>
								<button class="btn-xs btn-secondary mt-3 mt-xl-0" type="submit">Add Permit to this Shipment</button>
							</div>
						</div>
					</div>
				</div>

			</div>
			<div class="col-12">
				<div class="form-row mt-1">
					<div class="form-group col-md-12"> <a href="##" class="btn-link">See other shipments</a> </div>
				</div>
			</div>
		</div>
	</section>
	<section class="row"><!--- see notes above about main, aside, and section --->
		<div class="col-12 mb-4">
			<h2 class="h3"> Accessions of Materials in this Loan</h2>
			<ul class="list-group">
				<li class="list-group-item d-flex justify-content-between align-items-center" style="border: 1px solid rgba(0,0,0,.125);"> Accn ##: 2001189, Type: Gift, Status: Complete, Date Received: 2013-05-22 <span class="badge badge-primary badge-pill">14</span> </li>
				<li class="list-group-item d-flex justify-content-between align-items-center" style="border: 1px solid rgba(0,0,0,.125);"> Dapibus ac facilisis in <span class="badge badge-primary badge-pill">2</span> </li>
			</ul>
		</div>
	</section>
</main>
</cfoutput> 

<!---------------------------------------------------------------------->
<cfinclude template = "/shared/_footer.cfm">
