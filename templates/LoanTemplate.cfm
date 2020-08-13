<cfset pageTitle="Form Template">
<cfinclude template = "/shared/_header.cfm">
<!---------------------------------------------------------------------------------->
<script>
	(function() {
'use strict';
window.addEventListener('load', function() {
// Fetch all the forms we want to apply custom Bootstrap validation styles to
var forms = document.getElementsByClassName('needs-validation');
// Loop over them and prevent submission
var validation = Array.prototype.filter.call(forms, function(form) {
form.addEventListener('submit', function(event) {
if (form.checkValidity() === false) {
event.preventDefault();
event.stopPropagation();
}
form.classList.add('was-validated');
}, false);
});
}, false);
})();
	</script>

<cfoutput>
	<div class="container-fluid pb-5">
		<div class="container">
			<div class="row">
				<div class="col-md-12">
					<h1 class="h2 pt-3">Loan Example</h1>
				</div>
				<div class="col-md-7">
					<form class="was-validated">
						<div class="form-row mb-1">
							<div class="col-12 col-md-6">
								<label class="data-entry-label" for="inlineFormCustomSelect">Collection</label>
								<select class="custom-select" id="inlineFormCustomSelect">
									<option selected>Choose...</option>
									<option value="1">Cryogenics</option>
									<option value="2">Entomology</option>
									<option value="3">Herpetology</option>
									<option value="3">Invertebrate Zoology</option>
								</select>
							</div>
							<div class="col-12 col-md-6">
								<label class="data-entry-label" for="inputNum">Loan Number</label>
								<input type="text" class="form-control data-entry-input" id="inputNum">
							</div>
						</div>
						<div class="form-row">
							<div class="col-12 col-md-6">
								<label class="data-entry-label" for="inlineFormCustomSelect">Transaction Date</label>
								<input type="text" class="form-control data-entry-input" id="inputNum">
							</div>
							<div class="col-12 col-md-6">
								<label class="data-entry-label" for="inputNum">Due Date</label>
								<input type="text" class="form-control data-entry-input" id="inputNum">
							</div>
						</div>
						<div class="col-12 pt-1 pl-2 my-3 pb-2 border rounded">
							<div class="form-row mb-0">
								<div class="col-12 col-md-6">
									<span>
										<label for="underscore_agent_name" id="underscore_agent_name_label" class="data-entry-label">Agent
										<span id="underscore_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</span> 
										</label>
									</span>
									<div class="input-group">
										<div class="input-group-prepend">
											<span class="input-group-text input-group-text-sm" id="underscore_agent_name_icon"><i class="fa fa-user" aria-hidden="true"></i></span> 
										</div>
										<input type="text" name="underscore_agent_name" id="underscore_agent_name" class="form-control data-entry-input rounded-right" value="" aria-label="Agent" aria-describedby="underscore_agent_name_label">
										<input type="hidden" name="underscore_agent_id" id="underscore_agent_id" value="">
									</div>
									<script>
										$(document).ready(function() {
											$(makeRichAgentPicker('underscore_agent_name', 'underscore_agent_id', 'underscore_agent_name_icon', 'underscore_agent_view', null));
										});
									</script> 
								</div>
								<div class="col-12 col-md-5">
									<label class="data-entry-label" for="inlineFormCustomSelect">Agent Role</label>
									<select class="custom-select custom-select-sm" id="inlineFormCustomSelect">
										<option selected>Choose...</option>
										<option value="1">Received By</option>
										<option value="2">Authorized By</option>
										<option value="3">In-house Contact</option>
									</select>
								</div>
								<div class="col-12 col-md-1">
									<label class="data-entry-label ml-xl-3row" for="inlineFormCustomSelect">Delete</label>
									<div class="form-check mt-2">
										<input class="form-check-input" type="checkbox" id="gridCheck">
										<label class="form-check-label" for="gridCheck"> </label>
									</div>
								</div>
							</div>
							<div class="col-md-12 text-right"><a href="##">Add</a></div>
						</div>
						<div class="form-row">
							<div class="form-group col-md-4">
								<label class="mr-sm-2" for="inlineFormCustomSelect">Loan Type</label>
								<select class="custom-select mr-sm-2" id="inlineFormCustomSelect">
									<option selected>Choose...</option>
									<option value="1">Exhibition Master</option>
									<option value="2">Exhibition Subloan</option>
									<option value="3">Consumable</option>
									<option value="4">Returnable</option>
								</select>
							</div>
							<div class="form-group col-md-4">
								<label for="inputLoanStatus">Loan Status</label>
								<select class="custom-select mr-sm-2" id="inlineFormCustomSelect">
									<option selected>Choose...</option>
									<option value="1">In Process</option>
									<option value="2">Open</option>
									<option value="3">Closed</option>
									<option value="4">Open Historical</option>
								</select>
							</div>
							<div class="form-group col-md-3">
								<label class="mr-sm-2" for="validatedSubloan">Add Subloan</label>
								<div class="custom-file">
									<input type="file" class="custom-file-input" id="validatedSubloan required">
									<label class="custom-file-label" for="validatedSubloan">Add...</label>
									<div class="invalid-feedback">Example invalid custom file feedback</div>
								</div>
							</div>
						</div>
						<div class="form-row">
							<div class="form-group col-md-11">
								<label for="exampleFormControlTextarea1">Nature of Material</label>
								<textarea class="form-control" id="exampleFormControlTextarea1" rows="3"></textarea>
							</div>
						</div>
						<div class="form-row mt-3">
							<div class="form-group col-md-11">
								<button type="submit" class="btn btn-sm btn-secondary mr-2">Add Items</button>
								<button type="submit" class="btn btn-sm btn-secondary mr-2">Add Items by Barcode</button>
								<button type="submit" class="btn btn-sm btn-secondary mr-2">Review Items</button>
							</div>
						</div>
						<div class="form-row">
							<div class="form-group col-md-11 mt-3">
								<label for="exampleFormControlDescription">Description</label>
								<textarea class="form-control" id="exampleFormControlDescription" rows="3"></textarea>
							</div>
						</div>
						<div class="form-row">
							<div class="form-group col-md-11 mt-3">
								<label for="exampleFormControlDescription">Loan Instructions</label>
								<textarea class="form-control" id="exampleFormControlDescription" rows="3"></textarea>
							</div>
						</div>
						<div class="form-row">
							<div class="form-group col-md-11 mt-3">
								<label for="exampleFormControlDescription">Internal Remarks</label>
								<textarea class="form-control" id="exampleFormControlDescription" rows="3"></textarea>
							</div>
						</div>
						<div class="form-row mt-3">
							<div class="form-group col-md-6">
								<button type="submit" class="btn btn-secondary mr-2">Save Edits</button>
								<button type="submit" class="btn btn-secondary mr-2">Quit</button>
								<button type="submit" class="btn btn-secondary mr-2">Delete Loan</button>
							</div>
						</div>
					</form>
				</div>
				<div class="col-md-5">
					<h3>Invoices and Reports</h3>
					<p>Print Invoices and Reports for shipments and files.</p>
					<div class="form-row">
						<div class="form-group col-md-12">
							<select class="custom-select mr-sm-2" id="inlineFormCustomSelect">
								<option selected>Choose Report...</option>
								<option value="1">Invoice Header</option>
								<option value="2">Itemized List (Cat Num Sort)</option>
								<option value="3">Itemized List (Taxa Sort)</option>
							</select>
						</div>
					</div>
					<div class="form-row mt-3">
						<div class="form-group col-md-12 mb-2">
							<h3>Media</h3>
							<p>Highlighted connections to other records such as projects can go here.</p>
							<button class="btn btn-sm btn-secondary mr-2" type="submit">Link Media</button>
							<button class="btn btn-sm btn-secondary" type="submit">Create Media</button>
						</div>
					</div>
					<div class="col-md-12 px-0">
						<h3 class="mt-4">Shipment Information</h3>
						<div class="form-row mt-3" style="border: 1px solid ##ccc;padding: .5em;padding-bottom: 1em;">
							<div class="col-md-12">
								<h4 class="mt-0">Most Recent Shipment</h4>
								<h5>Shipped To:</h5>
								<p class="fs-14">(☑ Printed on invoice) Stephanie Carson, Senior Museum Registrar American Museum of Natural History Office of the Registrar Central Park West at 79th Street New York, New York 10024 United States</p>
								<h5>Shipped From:</h5>
								<p class="fs-14">Collections Operations Museum of Comparative Zoology Harvard University 26 Oxford St. Cambridge, MA 02138</p>
								<div class="form-row">
									<div class="col-md-5">
										<label class="mr-sm-2 mb-0 ml-1 fs-14" for="inlineShipDate">Ship Date</label>
										<input type="text" class="form-control form-control-sm ml-0" id="inputShipDate">
									</div>
									<div class="col-md-7">
										<label class="mr-sm-2 mb-0 ml-1 fs-14" for="inlineMethod">Method</label>
										<input type="text" class="form-control form-control-sm ml-0" id="inputShipDate">
									</div>
								</div>
								<div class="form-row">
									<div class="col-md-3">
										<label class="mr-sm-2 mb-0 ml-1 fs-14" for="inlinePackages">Packages</label>
										<input type="text" class="form-control form-control-sm ml-0" id="inputShipDate">
									</div>
									<div class="col-md-9">
										<label class="mr-sm-2 mb-0 fs-14" for="inlinePackages">Tracking Number</label>
										<input type="text" class="form-control form-control-sm ml-0" id="inputShipDate">
									</div>
								</div>
								<div class="form-row">
									<div class="col-md-12 mt-3">
										<h5 class="ml-1">Permits: </h5>
										<ul class="list-group" style="background-color: white;">
											<li class="list-group-item d-flex justify-content-between align-items-center fs-14" style="border: 1px solid rgba(0,0,0,.125);"> Collecting/Take Permission OP 834 <br>
												Issued: 2010-02-26, By: Ezemvelo KZN Wildlife <span class="badge badge-primary badge-pill">14</span> </li>
											<li class="list-group-item d-flex justify-content-between align-items-center fs-14" style="border: 1px solid rgba(0,0,0,.125);"> Export Permission FAUNA 581/2009 <br>
												Issued: 2009-09-01, By: Department of Environment and Nature Conservation, Northern Cape <span class="badge badge-primary badge-pill">2</span> </li>
										</ul>
									</div>
								</div>
								<div class="form-row mt-3">
									<div class="form-group col-md-12">
										<button class="btn btn-sm btn-secondary mr-2" type="submit">Edit this Shipment</button>
										<button class="btn btn-sm btn-secondary" type="submit">Add Permit to this Shipment</button>
									</div>
								</div>
							</div>
						</div>
						<div class="col-md-12">
							<div class="form-row mt-3">
								<div class="form-group col-md-12"> <a href="##" class="form-control form-control-sm">See other shipments</a> </div>
							</div>
						</div>
					</div>
				</div>
			</div>
			<div class="container">
				<div class="row">
					<div class="col-md-12 mt-3 px-0">
						<h3 class="pl-1"> Accessions of Materials in this Loan</h3>
						<ul class="list-group" style="background-color: white;">
							<li class="list-group-item d-flex justify-content-between align-items-center" style="border: 1px solid rgba(0,0,0,.125);"> Accn ##: 2001189, Type: Gift, Status: Complete, Date Received: 2013-05-22 <span class="badge badge-primary badge-pill">14</span> </li>
							<li class="list-group-item d-flex justify-content-between align-items-center" style="border: 1px solid rgba(0,0,0,.125);"> Dapibus ac facilisis in <span class="badge badge-primary badge-pill">2</span> </li>
						</ul>
					</div>
				</div>
			</div>
		</div>
	</div>
</cfoutput> 

<!---------------------------------------------------------------------->
<cfinclude template = "/shared/_footer.cfm">
