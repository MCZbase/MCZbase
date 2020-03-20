<cfset pageTitle = "Data Entry">
<!-- 
Affiliates.cfm

Copyright 2019 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->
<cfinclude template = "/includes/_header.cfm">

<style>

</style>
<cfoutput>
<p class="font-italic font-weight-bold text-center mt-3 mb-0">
<a href="javascript:SwapDivsWithClick('swapper-first','swapper-other')">(Switch Between Full Screen and Step Form)</a>
</p>


<div class="container-fluid" id="swapper-first" style="display: none;">
	<div class="row">
		<div class="col-12 mt-2">
			<form id="regFormAll" class="w-100" action="/DataEntry.cfm">
			<!-- One "tab" for each step in the form: -->
			<h1 class="text-center mt-3 mb-3">Enter a New Record</h1>	
			<div class="row">	
				<div class="form-group col-12 col-md-4 pb-2 px-1"></div>
				<div class="form-group col-12 col-md-4 pb-2 px-1">
					<div class="border p-3 m-2">
					<h2 class="fs-title text-center">Collection</h2>
					<h3 class="fs-subtitle text-center">This is step 1</h3>	
					<div class="form-group row">
						<label for="collection" class="data-entry-label col-12 col-xl-3 text-center text-md-right px-0">Collection</label>
					<div class="col-12 col-lg-9">
						<select class="data-entry-select px-0" required>
							<option value="">Select Collection</option>
							<option value="1">Herpetology</option>
							<option value="2">Mammalogy</option>
							<option value="3">Malacology</option>
						</select>
					</div>
					</div>	
					</div>
				</div>	
				<div class="form-group col-12 col-md-4 pb-2 px-1"></div>
				</div>
					<div class="row">	
				<!---First block left (below) -- Record Numbers: includes catalog number, other ID, Mask Record and other records  --->
				<div class="form-group col-12 col-md-4 pb-2 px-1">
					<div class="border p-3 m-2">
					<h2 class="fs-title text-center">Catalog Number</h2>
					<h3 class="fs-subtitle text-center">This is step 2</h3>				
					<div class="form-group row">
						<label for="cat_num" class="data-entry-label col-12 col-xl-3 text-center text-xl-right px-0">Catalog Number</label>
						<div class="col-xl-9">
							<input type="text" class="data-entry-input" id="cat_num" aria-describedby="catNumHelp" placeholder="Enter Catalog Number" name="cat_num">
							<small id="catNumHelp" class="form-text text-muted">The catalog number must be unique for the collection.</small>
						</div>
					</div>
					</div>	
				</div>	
				<!---Second block Right (below) -- Collector/Preparator: select role, agent name  --->					
				<div class="form-group col-12 col-md-4 pb-2 px-1">
				<div class="border p-3 m-2">
				<h2 class="fs-title text-center">Other IDs</h2>
				<h3 class="fs-subtitle text-center">This is step 3</h3>
					<div id="customID">
					<div class="form-group row">
					<label for="other_id" class="data-entry-label col-12 col-xl-3 text-center text-xl-right">Other ID</label>
					<div class="col-xl-4 px-xl-0">
						<select class="data-entry-select" required>
							<option value="">Other ID Type</option>
							<option value="1">Field Number</option>
							<option value="2">Collector Number</option>
							<option value="3">Previous Number</option>
						</select>
					</div>
					<div class="col-xl-5">
						<input type="text" class="data-entry-input"  name="other_id" placeholder="Other ID">
					</div>
				</div>
					</div>
					<div class="col-md-12 col-sm-12 p-0 mx-1 d-flex justify-content-end">
					<a aria-label="Add another set of search criteria" class="btn btn-primary addID btn-sm loginButtons rounded ml-auto m-1" target="_self" href="javascript:void(0);">Add Other ID</a>
					</div>
				</div>
			</div>
				
				<div class="form-group col-12 col-md-4 pb-2 px-1">
				<div class="border p-3 m-2">
				<h2 class="fs-title text-center">Record Relationships</h2>
				<h3 class="fs-subtitle text-center">This is step 4</h3>
					<div id="customRelationship">
					<div class="form-group row">
					<label for="relations" class="data-entry-label col-12 col-xl-3 text-center text-xl-right">Relationship</label>
					<div class="col-xl-4 px-xl-0">
						<select class="data-entry-select">
							<option value="">Relationship Type</option>
							<option value="1">Re-Cataloged as</option>
							<option value="2">Bad Duplicate of</option>
							<option value="3">Cloned from Record</option>
							<option value="4">Duplicate Recataloged as</option>
						</select>
					</div>
					<div class="col-xl-5">
						<input type="text" class="data-entry-input" id="record_number" placeholder="Record Number">
					
					</div>
				</div>
					</div>
					<div class="col-md-12 col-sm-12 p-0 mx-1 d-flex justify-content-end">
					<a aria-label="Add another set of search criteria" class="btn btn-primary addRelationship btn-sm loginButtons rounded ml-auto m-1" target="_self" href="javascript:void(0);">Add Record Relationship</a>
					</div>
				</div>
			</div>
			</div>
			<div class="row">
				<div class="form-group col-12 col-md-4 pb-2 px-1">
					<div class="border p-3 m-2">
					<h2 class="fs-title text-center">Encumbrance</h2>
					<h3 class="fs-subtitle text-center">This is step 5</h3>
						<div id="encumbrance">
						<div class="form-group row mb-2">
							<label for="mask_record" class="data-entry-label col-12 col-xl-3 text-center text-xl-right px-0">Mask Record</label>
							<div class="col-xl-9">
								<div class="form-check form-check-inline">
									<input class="form-check-input w-auto mt-0" style="margin-top: -2px" value="mask" type="checkbox" id="gridCheck1">
									<label class="form-check-label w-auto form-control-sm border-0 mt-0" for="gridCheck1"> Mask Record in Generic Encumbrance</label>
								</div>
							</div>
						</div>
						</div>
					</div>
				</div>
			
				<div class="form-group col-12 col-md-4 pb-2 px-1">
				<div class="border p-3 m-2">
				<h2 class="fs-title text-center">Collector/Preparator</h2>
				<h3 class="fs-subtitle text-center">This is step 6</h3>
					<div id="customAgent">
						<div class="form-group row">
							<label for="other_id" class="data-entry-label col-12 col-xl-3 text-center text-xl-right px-0">Agent</label>
							<div class="col-12 col-xl-4">
								<select class="data-entry-select">
									<option value="">Collector</option>
									<option value="1">Preparator</option>
								</select>
							</div>
							<div class="col-12 col-xl-5">
								<input type="text" class="data-entry-input" name="other_id" placeholder="Value">
							</div>
						</div>
					</div>
					<div class="col-md-12 col-sm-12 p-0 mx-1 d-flex justify-content-end">
					<a aria-label="Add another set of search criteria" class="btn btn-primary addAgent btn-sm loginButtons rounded ml-auto m-1" target="_self" href="javascript:void(0);">Add Agent</a>
					</div>
				</div>
			</div>
				
				<div class="form-group col-12 col-md-4 pb-2 px-1">
				<div class="border p-3 m-2">
				<h2 class="fs-title text-center">Scientific Name</h2>
				<h3 class="fs-subtitle text-center">This is step 7</h3>
				<div class="row">
					<label for="scientific_name" class="data-entry-label col-12 col-sm-3 text-center text-md-right px-0">Scientific Name</label>
					<div class="col-12 col-lg-9">
						<input type="text" name="scientific_name" class="data-entry-input" placeholder="Scientific Name" />
					</div>
				</div>
				<div class="row">
					<label for="made_by" class="data-entry-label col-lg-3 text-center text-md-right px-0">ID Made By</label>
					<div class="col-12 col-lg-9">
						<input type="text" name="made_by" class="data-entry-input" placeholder="Identifier's Name" />
					</div>
				</div>
				<div class="row">
					<label for="nature_of_id" class="data-entry-label col-lg-3 text-center text-md-right px-0">Nature of ID</label>
					<div class="col-12 col-lg-4">
						<select class="data-entry-select" required>
							<option value="">Expert ID</option>
							<option value="1">Field ID</option>
							<option value="2">Non-Expert ID</option>
							<option value="3">Curatorial ID</option>
						</select>
					</div>
					<div class="col-12 col-lg-5">
						<input type="text" name="made_by_date" class="data-entry-input" placeholder="Date of ID" />
					</div>
				</div>
				<div class="row">
					<label for="id_remark" class="data-entry-label col-12 col-lg-3 text-center text-md-right">ID Remark</label>
					<div class="col-12 col-lg-9">
						<textarea type="text" name="id_remark" class="data-entry-textarea" placeholder="ID remark"/>
						</textarea>
					</div>
				</div>
				</div>
			</div>	
			</div>
			<div class="row">
				<div class="form-group col-12 col-md-4 pb-2 px-1">
				<div class="border p-3 m-2">
				<h2 class="fs-title text-center">Locality</h2>
				<h3 class="fs-subtitle text-center">This is step 8</h3>
				<div class="row">
					<label for="higher_geog" class="data-entry-label col-sm-3 text-center text-md-right px-0">Higher Geography</label>
					<div class="col-sm-9">
						<input type="text" name="higher_geog" class="data-entry-input" placeholder="Higher Geography" />
					</div>
				</div>
				<div class="row">
					<label for="higher_geog" class="data-entry-label col-sm-3 text-center text-md-right">Specific Locality</label>
					<div class="col-sm-9">
						<input type="text" name="spec_locality" class="data-entry-input" placeholder="Specific Locality" />
					</div>
				</div>
				<div class="row">
					<label for="inputPassword3" class="data-entry-label col-sm-3 text-center text-md-right px-0">Elevation</label>
					<div class="col-12 col-sm-3">
						<input type="text" class="data-entry-input" id="inputMinElev" placeholder="Min Elevation">
					</div>
					<div class="col-12 col-sm-3">
						<input type="text" class="data-entry-input" id="inputMaxElev" placeholder="Max Elevation">
					</div>
					<div class="col-12 col-sm-2">	
						<select class="data-entry-select" required>
							<option value="">Feet</option>
							<option value="1">Fathoms</option>
							<option value="2">Yards</option>
							<option value="3">Meters</option>
							<option value="4">Miles</option>
							<option value="5">Kilometers</option>
						</select>
					</div>
				</div>
				<div class="row">
					<label for="inputPassword3" class="data-entry-label col-sm-3 text-center text-md-right">Depth</label>
					<div class="col-12 col-sm-3">
						<input type="text" class="data-entry-input" id="inputMinDepth" placeholder="Min Depth">
					</div>
					<div class="col-12 col-sm-3">
						<input type="text" class="data-entry-input" id="inputMaxDepth" placeholder="Max Depth">
					</div>
					<div class="col-12 col-sm-2">
						<select class="data-entry-select" required>
							<option value="">Feet</option>
							<option value="1">Fathoms</option>
							<option value="2">Yards</option>
							<option value="3">Meters</option>
							<option value="4">Miles</option>
							<option value="5">Kilometers</option>
						</select>
					</div>
				</div>
				<div class="row">
					<label for="sovereign_nation" class="data-entry-label col-sm-3 text-center text-md-right">Sovereign Nation</label>
					<div class="col-sm-9">
						<input type="text" name="sovereign_nation" class="data-entry-input" placeholder="Sovereign Nation" />
					</div>
				</div>
				<div class="row">
					<label for="higher_geog" class="data-entry-label col-sm-3 text-center text-md-right px-0">Geology Attribute</label>
					<div class="col-sm-9 my-0">
						<input type="text" name="geology_attribute" class="data-entry-input" placeholder="Geology Attribute" />
					</div>
				</div>
				<div class="row">
					<label for="habitat" class="data-entry-label col-sm-3 text-center text-md-right px-0">Habitat</label>
					<div class="col-sm-9">
						<input type="text" name="habitat" class="data-entry-input" placeholder="Habitat" />
					</div>
				</div>
				</div>
				</div>

				<div class="form-group col-12 col-md-4 pb-2 px-1">
					<div class="border p-3 m-2">
				<h2 class="fs-title text-center">Attributes</h2>
				<h3 class="fs-subtitle text-center">This is step 9</h3>
				<div id="customFields">
				<div class="form-group row">
					<label for="other_id" class="data-entry-label col-sm-3 text-center text-md-right px-0">Attribute</label>
					<div class="col-12 col-lg-9">
						<select class="data-entry-select" required>
							<option value="">Age Class</option>
							<option value="1">Citation</option>
							<option value="2">Host</option>
							<option value="3">Life Cycle Stage</option>
						</select>
						<input type="text" class="data-entry-input" name="other_id" placeholder="Value">
						<input type="text" class="data-entry-input" name="other_id" placeholder="Units">
						<input type="text" class="data-entry-input" name="other_id" placeholder="Date">
						<input type="text" class="data-entry-input" name="other_id" placeholder="Determiner">
						<input type="text" class="data-entry-input" name="other_id" placeholder="Method">
						<input type="text" class="data-entry-input" name="other_id" placeholder="Remarks">
					</div>
				</div>
				</div>
				<div class="col-md-12 col-sm-12 p-0 mx-1 d-flex justify-content-end">
					<a aria-label="Add another set of search criteria" class="btn btn-primary addAtt btn-sm loginButtons rounded ml-auto m-1" target="_self" href="javascript:void(0);">Add Attribute</a>
				</div>
				</div>
				</div>
	
				<div class="form-group col-12 col-md-4 pb-2 px-1">
				<div class="border p-3 m-2">
				<h2 class="fs-title text-center">Parts</h2>
				<h3 class="fs-subtitle text-center">This is step 10</h3>
				<div id="customPart">
				<div class="form-group row">
					<label for="other_id" class="data-entry-label col-sm-3 text-center text-md-right px-0">Part Name</label>
					<div class="col-12 col-lg-9">
						<input type="text" class="data-entry-input" name="part_name" placeholder="Part Name">
					</div>
					<label for="other_id" class="data-entry-label col-sm-3 text-center text-md-right px-0">Preserve Method</label>
					<div class="col-12 col-lg-9">
						<select class="data-entry-select" required>
							<option value="">Ethanol</option>
							<option value="1">RNALater</option>
							<option value="2">DNA/RNA Shield</option>
							<option value="3">Alcohol</option>
						</select>
					</div>	
					<label for="condition" class="data-entry-label col-sm-3 text-center text-md-right px-0">Condition</label>
					<div class="col-12 col-lg-9">
						<input type="text" class="data-entry-input" name="condition" placeholder="Condition">
					</div>	
					<label for="disposition" class="data-entry-label col-sm-3 text-center text-md-right px-0">Disposition</label>
					<div class="col-12 col-lg-9">
						<select class="data-entry-select px-0" required>
							<option value="">Being Processed</option>
							<option value="1">Deaccessioned</option>
							<option value="2">In Collection</option>
							<option value="3">Missing</option>
						</select>
					</div>
					<div class="col-12 row mx-0 px-0">
					<label for="part_number" class="data-entry-label col-lg-3 text-center text-xl-right px-0">## of Parts</label>
					<div class="col-12 col-lg-4">
						<select class="data-entry-select" required="">
							<option value="">Modifier</option>
							<option value="1">ca.</option>
							<option value="2">&gt;</option>
							<option value="3">&lt;</option>
						</select>
					</div>
					<div class="col-12 col-lg-5">
						<input type="text" name="part_number" class="data-entry-input" placeholder="Number of Parts">
					</div>
				</div>
					<label for="container_unique_id" class="data-entry-label col-sm-3 text-center text-md-right px-0">Container</label>
					<div class="col-12 col-lg-9">
						<input type="text" class="data-entry-input" name="container_unique_id" placeholder="Container Unique ID">
					</div>
					<label for="part_remark" class="data-entry-label col-sm-3 text-center text-md-right px-0">Remark</label>
					<div class="col-12 col-lg-9">
						<input type="text" class="data-entry-input" name="part_remark" placeholder="Part Remarks">
					</div>
				</div>
				</div>
				<div class="col-md-12 col-sm-12 p-0 mx-1 d-flex justify-content-end">
					<a aria-label="Add another set of search criteria" class="btn btn-primary addPart btn-sm loginButtons rounded ml-auto m-1" target="_self" href="javascript:void(0);">Add Part</a>
				</div>
				</div>
				</div>
			</div>
		</form>
	    </div>
	</div>	
</div>
	
<!---Step by step form for each section of the Data Entry form--->	
<div class="container" id="swapper-other" style="display: block;">
	<div  class="row col-12 col-xl-10 justify-content-center mt-2 mx-auto">
		<form id="regForm" action="/DataEntry.cfm">
			<!-- One "tab" for each step in the form: -->
			<h1 class="text-center mt-2 mb-1">Enter a New Record</h1>
			<div class="tab">
				<h2 class="fs-title text-center">Record Numbers</h2>
				<h3 class="fs-subtitle text-center mb-4">This is step 1</h3>
				<div class="form-group row">
					<label for="cat_num" class="col-sm-3 col-form-label text-center text-md-right">Catalog Number</label>
					<div class="col-sm-9">
						<p>
							<input placeholder="Catalog Number" class="form-control form-control-sm validate" oninput="this.className = ''" name="cat_num">
						</p>
					</div>
				</div>
				<div class="form-group mb-0 row">
					<label for="other_id" class="col-sm-3 col-form-label text-center text-md-right">Other ID</label>
					<div class="col-sm-4 col-md-4">
						<select class="custom-select form-control-sm input-xs border" oninput="this.className = ''" mt-0 required>
							<option value="">Other ID Type</option>
							<option value="1">Field Number</option>
							<option value="2">Collector Number</option>
							<option value="3">Previous Number</option>
						</select>
					</div>
					<div class="col-sm-5">
						<input type="text" class="form-control form-control-sm" oninput="this.className = ''" name="other_id" placeholder="Other ID">
					</div>
				</div>
				<div class="form-group row">
					<label for="other_id" class="col-sm-3 col-form-label text-center text-md-right">Mask Record</label>
					<div class="col-sm-9 col-md-9 text-left">
						<div class="form-check form-check-inline">
							<input class="form-check-input w-auto mt-2" value="mask" type="checkbox" id="gridCheck1">
							<label class="form-check-label w-auto mt-1" for="gridCheck1"> Mask Record (Generic Encumbrance)</label>
						</div>
					</div>
				</div>
				<div class="form-group row">
					<label for="relations" class="col-sm-3 col-form-label text-center text-md-right">Other Records</label>
					<div class="col-sm-4 col-md-4 text-left">
						<select class="custom-select border form-control form-control-sm mt-0" required>
							<option value="">Relationship Type</option>
							<option value="1">Re-Cataloged as</option>
							<option value="2">Bad Duplicate of</option>
							<option value="3">Cloned from Record</option>
							<option value="4">Duplicate Recataloged as</option>
						</select>
					</div>
					<div class="col-sm-5">
						<input type="text" class="form-control"  oninput="this.className = ''"  id="record_number" placeholder="Record Number">
					</div>
				</div>
			</div>
			<div class="tab">
				<h2 class="fs-title text-center">Collector/Preparator</h2>
				<h3 class="fs-subtitle text-center">This is step 2</h3>
				<div class="form-group row my-0">
					<label for="collector1" class="col-sm-3 col-form-label mt-0">
						<select class="custom-select border mt-0 validate">
							<option value="">Select Role...</option>
							<option value="1">Collector</option>
							<option value="2">Preparator</option>
						</select>
					</label>
					<div class="col-sm-9 col-md-9 mt-1">
						<input type="text" class="form-control validate" id="collector1" placeholder="Agent Name">
					</div>
				</div>
				<div class="form-group row my-0">
					<label for="collector2" class="col-sm-3 col-form-label mt-0">
						<select class="custom-select border mt-0">
							<option value="">Select Role...</option>
							<option value="1">Collector</option>
							<option value="2">Preparator</option>
						</select>
					</label>
					<div class="col-sm-9 col-md-9 mt-1">
						<input type="text" class="form-control" id="collector2" placeholder="Agent Name">
					</div>
				</div>
				<div class="form-group row my-1">
					<label for="collector3" class="col-sm-3 col-form-label mt-0">
						<select class="custom-select border mt-0" required>
							<option value="">Select Role...</option>
							<option value="1">Collector</option>
							<option value="2">Preparator</option>
						</select>
					</label>
					<div class="col-sm-9 col-md-9 mt-1">
						<input type="text" class="form-control" id="collector3" placeholder="Agent Name">
					</div>
				</div>
				<div class="form-group row my-1">
					<label for="collector4" class="col-sm-3 col-form-label mt-0">
						<select class="custom-select border mt-0" required >
							<option value="">Select Role...</option>
							<option value="1">Collector</option>
							<option value="2">Preparator</option>
						</select>
					</label>
					<div class="col-sm-9 col-md-9 mt-1">
						<input type="text" class="form-control" id="collector4" placeholder="Agent Name">
					</div>
				</div>
				<div class="form-group row my-1">
					<label for="collector5" class="col-sm-3 col-form-label mt-0">
						<select class="custom-select border mt-0">
							<option value="">Select Role...</option>
							<option value="1">Collector</option>
							<option value="2">Preparator</option>
						</select>
					</label>
					<div class="col-sm-9 col-md-9 mt-1">
						<input type="text" class="form-control" id="collector5" placeholder="Agent Name">
					</div>
				</div>
			</div>
			<div class="tab">
				<h2 class="fs-title text-center">Scientific Name</h2>
				<h3 class="fs-subtitle text-center">This is step 3</h3>
				<div class="form-group row">
					<label for="scientific_name" class="col-sm-3 col-form-label text-center text-md-right">Scientific Name</label>
					<div class="col-sm-9">
						<input type="text" name="scientific_name" class="form-control" placeholder="Scientific Name" />
					</div>
				</div>
				<div class="form-group row">
					<label for="made_by" class="col-sm-3 col-form-label text-center text-md-right">ID Made By</label>
					<div class="col-sm-9">
						<input type="text" name="made_by" class="form-control" placeholder="Identifier's Name" />
					</div>
				</div>
				<div class="form-group row">
					<label for="nature_of_id" class="col-sm-3 col-form-label text-center text-md-right">Nature of ID</label>
					<div class="col-sm-4">
						<select class="custom-select border form-control" required>
							<option value="">Expert ID</option>
							<option value="1">Field ID</option>
							<option value="2">Non-Expert ID</option>
							<option value="3">Curatorial ID</option>
						</select>
					</div>
					<div class="col-sm-5">
						<input type="text" name="made_by_date" class="form-control" placeholder="Date of ID" />
					</div>
				</div>
				<div class="form-group row my-0">
					<label for="id_remark" class="col-sm-3 col-form-label text-center text-md-right">ID Remark</label>
					<div class="col-sm-9">
						<textarea type="text" name="id_remark" class="form-control" placeholder="ID remark"/>
						</textarea>
					</div>
				</div>
			</div>
			<div class="tab">
				<h2 class="fs-title text-center">Locality</h2>
				<h3 class="fs-subtitle text-center">This is step 4</h3>
				<div class="form-group row">
					<label for="higher_geog" class="col-sm-3 col-form-label text-center text-md-right">Higher Geography</label>
					<div class="col-sm-9">
						<input type="text" name="higher_geog" class="form-control" placeholder="Higher Geography" />
					</div>
				</div>
				<div class="form-group row">
					<label for="higher_geog" class="col-sm-3 col-form-label text-center text-md-right">Specific Locality</label>
					<div class="col-sm-9">
						<input type="text" name="spec_locality" class="form-control" placeholder="Specific Locality" />
					</div>
				</div>
				<div class="form-group row">
					<label for="inputPassword3" class="col-sm-3 col-form-label text-center text-md-right">Elevation</label>
					<div class="col-sm-3">
						<input type="text" class="form-control" id="inputMinElev" placeholder="Min Elevation">
					</div>
					<div class="col-sm-3">
						<input type="text" class="form-control" id="inputMaxElev" placeholder="Max Elevation">
					</div>
					<div class="col-sm-2">
						<select class="custom-select border form-control" required>
							<option value="">Feet</option>
							<option value="1">Fathoms</option>
							<option value="2">Yards</option>
							<option value="3">Meters</option>
							<option value="4">Miles</option>
							<option value="5">Kilometers</option>
						</select>
					</div>
				</div>
				<div class="form-group row">
					<label for="inputPassword3" class="col-sm-3 col-form-label text-center text-md-right">Depth</label>
					<div class="col-sm-3">
						<input type="text" class="form-control" id="inputMinDepth" placeholder="Min Depth">
					</div>
					<div class="col-sm-3">
						<input type="text" class="form-control" id="inputMaxDepth" placeholder="Max Depth">
					</div>
					<div class="col-sm-2">
						<select class="custom-select border form-control" required>
							<option value="">Feet</option>
							<option value="1">Fathoms</option>
							<option value="2">Yards</option>
							<option value="3">Meters</option>
							<option value="4">Miles</option>
							<option value="5">Kilometers</option>
						</select>
					</div>
				</div>
				<div class="form-group row">
					<label for="sovereign_nation" class="col-sm-3 col-form-label text-center text-md-right">Sovereign Nation</label>
					<div class="col-sm-9">
						<input type="text" name="sovereign_nation" class="form-control" placeholder="Sovereign Nation" />
					</div>
				</div>
				<div class="form-group row">
					<label for="higher_geog" class="col-sm-3 col-form-label text-center text-md-right">Geology Attribute</label>
					<div class="col-sm-9 my-0">
						<input type="text" name="geology_attribute" class="form-control" placeholder="Geology Attribute" />
					</div>
				</div>
				<div class="form-group row">
					<label for="habitat" class="col-sm-3 col-form-label text-center text-md-right">Habitat</label>
					<div class="col-sm-9">
						<input type="text" name="habitat" class="form-control" placeholder="Habitat" />
					</div>
				</div>
			</div>
			<div style="overflow:auto;" class="mt-4 mb-2">
				<div class="text-right">
					<button type="button" id="prevBtn" class="btn btn-primary" onclick="nextPrev(-1)">Previous</button>
					<button type="button" id="nextBtn" class="btn btn-primary" onclick="nextPrev(1)">Next</button>
				</div>
				<div class="text-center my-2">
					<button type="button" id="seeAll" class="btn btn-primary">See All</button>
				</div>
			</div>
			<!-- Circles which indicates the steps of the form: -->
			<div class="my-4 text-center"> 
				<span class="step">1</span> 
				<span class="step">2</span> 
				<span class="step">3</span> 
				<span class="step">4</span> 
				<span class="step">5</span> 
				<span class="step">6</span> 
				<span class="step">7</span> 
				<span class="step">8</span>
				<span class="step">9</span> 
			</div>
		</form>
	</div>
	
</div>

	

<script>
	//this is from https://stackoverflow.com/questions/16183231/jquery-append-and-remove-dynamic-table-row
$(document).ready(function(){
	$(".addAtt").click(function(){$("##customFields").append('<div class="form-group row"><label for="other_id" class="col-sm-3 form-control-sm border-0 col-form-label text-center text-md-right">Attribute</label><div class="col-sm-9"><select class="custom-select1 form-control-sm input-xs border" mt-0 required><option value="">Age Class</option><option value="1">Citation</option><option value="2">Host</option><option value="3">Life Cycle Stage</option></select><input type="text" class="form-control form-control-sm" name="other_id" placeholder="Value"><input type="text" class="form-control form-control-sm" name="other_id" placeholder="Units"><input type="text" class="form-control form-control-sm" name="other_id" placeholder="Date"><input type="text" class="form-control form-control-sm" name="other_id" placeholder="Determiner"><input type="text" class="form-control form-control-sm" name="other_id" placeholder="Method"><input type="text" class="form-control form-control-sm" name="other_id" placeholder="Remarks"></div><button href="javascript:void(0);" arial-label="remove" class="btn btn-primary addAtt btn-sm loginButtons rounded mr-auto ml-3 remAtt">Remove</button></div>');
	});
	$("##customFields").on('click','.remAtt',function(){$(this).parent().remove();});
});
</script>
	<script>
	//this is from https://stackoverflow.com/questions/16183231/jquery-append-and-remove-dynamic-table-row  
$(document).ready(function(){
	$(".addAgent").click(function(){$("##customAgent").append('<div class="form-group row"><label for="other_id" class="col-sm-3 form-control-sm border-0 col-form-label text-center text-md-right">Agent 1</label><div class="col-lg-4"><select class="custom-select1 form-control-sm input-xs border"><option value="">Collector</option><option value="1">Preparator</option></select></div><div class="col-12 col-lg-5"><input type="text" class="form-control form-control-sm" name="other_id" placeholder="Value"></div><button href="javascript:void(0);" arial-label="remove" class="btn btn-primary addAgent btn-sm loginButtons rounded ml-3 mr-auto remAgent">Remove</button></div>');
	});
	$("##customAgent").on('click','.remAgent',function(){$(this).parent().remove();});
});
</script>
	<script>
	//this is from https://stackoverflow.com/questions/16183231/jquery-append-and-remove-dynamic-table-row  
$(document).ready(function(){
	$(".addPart").click(function(){$("##customPart").append('<div class="form-group row"><h6>Part</h6><label for="part_name" class="col-sm-3 form-control-sm border-0 col-form-label text-center text-md-right">Part Name</label><div class="col-12 col-lg-9"><input type="text" class="form-control form-control-sm" name="part_name" placeholder="Part Name"></div><label for="other_id" class="col-sm-3 form-control-sm border-0 col-form-label text-center text-md-right">Preserve Method</label><div class="col-12 col-lg-9"><select class="custom-select1 form-control-sm input-xs border" mt-0 required><option value="">Ethanol</option><option value="1">RNALater</option><option value="2">DNA/RNA Shield</option><option value="3">Alcohol</option></select></div><label for="condition" class="col-sm-3 form-control-sm border-0 col-form-label text-center text-md-right">Condition</label><div class="col-12 col-lg-9"><input type="text" class="form-control form-control-sm" name="condition" placeholder="Condition"></div><label for="disposition" class="col-sm-3 form-control-sm border-0 col-form-label text-center text-md-right">Disposition</label><div class="col-12 col-lg-9"><select class="custom-select1 form-control-sm input-xs border" mt-0 required><option value="">being processed</option><option value="1">deaccessioned</option><option value="2">in collection</option><option value="3">missing</option></select></div><div class="col-12 row mx-0 px-0"><label for="part_number" class="col-lg-3 form-control-sm border-0 col-form-label text-center text-xl-right">Number of Parts</label><div class="col-12 col-lg-4"><select class="custom-select1 form-control-sm input-xs border form-control" required=""><option value="">modifier</option><option value="1">ca.</option><option value="2">&gt;</option><option value="3">&lt;</option></select></div><div class="col-12 col-lg-5"><input type="text" name="part_number" class="form-control form-control-sm" placeholder="Number of Parts"></div></div><label for="container_unique_id" class="col-sm-3 form-control-sm border-0 col-form-label text-center text-md-right">Container</label><div class="col-12 col-lg-9"><input type="text" class="form-control form-control-sm" name="container_unique_id" placeholder="Container Unique ID"></div><label for="part_remark" class="col-sm-3 form-control-sm border-0 col-form-label text-center text-md-right">Remark</label><div class="col-12 col-lg-9"><input type="text" class="form-control form-control-sm" name="part_remark" placeholder="Part Remarks"></div><button href="javascript:void(0);" arial-label="remove" class="btn btn-primary addPart btn-sm loginButtons rounded ml-3 mr-auto remPart">Remove</button></div>');
	});
	$("##customPart").on('click','.remPart',function(){$(this).parent().remove();});
});
</script>
<script type="text/javascript">
function SwapDivsWithClick(div1,div2)
{
   d1 = document.getElementById(div1);
   d2 = document.getElementById(div2);
   if( d2.style.display == "none" )
   {
      d1.style.display = "none";
      d2.style.display = "block";
   }
   else
   {
      d1.style.display = "block";
      d2.style.display = "none";
   }
}
</script>	
<script>
	var currentTab = 0; // Current tab is set to be the first tab (0)
	showTab(currentTab); // Display the current tab
function showTab(n) {
  // This function will display the specified tab of the form ...
  	var x = document.getElementsByClassName("tab");
  	x[n].style.display = "block";
  // ... and fix the Previous/Next buttons:
  if (n == 0) {
    document.getElementById("prevBtn").style.display = "none";
  } else {
    document.getElementById("prevBtn").style.display = "inline";
  }
  if (n == (x.length - 1)) {
    document.getElementById("nextBtn").innerHTML = "Submit";
  } else {
    document.getElementById("nextBtn").innerHTML = "Next";
  } 
  // ... and run a function that displays the correct step indicator:
  fixStepIndicator(n)
}
	
function nextPrev(n) {
  // This function will figure out which tab to display
  var x = document.getElementsByClassName("tab");
  // Exit the function if any field in the current tab is invalid:
  if (n == 1 && !validateForm()) return false;
  // Hide the current tab:
  x[currentTab].style.display = "none";
  // Increase or decrease the current tab by 1:
  currentTab = currentTab + n;
  // if you have reached the end of the form... :
  if (currentTab >= x.length) {
    //...the form gets submitted:
    document.getElementById("regForm").submit();
    return false;
  }
  // Otherwise, display the correct tab:
  showTab(currentTab);
}

function validateForm() {
  // This function deals with validation of the form fields
  var x, y, i, valid = true;
  x = document.getElementsByClassName("tab");
  y = x[currentTab].getElementsByClassName("validate");
  // A loop that checks every input field in the current tab:
  for (i = 0; i < y.length; i++) {
    // If a field is empty...
    if (y[i].value == "") {
      // add an "invalid" class to the field:
      y[i].className += " invalid";
      // and set the current valid status to false:
      valid = false;
    }
  }
  // If the valid status is true, mark the step as finished and valid:
  if (valid) {
    document.getElementsByClassName("step")[currentTab].className += " finish";
  }
  return valid; // return the valid status
}

function fixStepIndicator(n) {
  // This function removes the "active" class of all steps...
  var i, x = document.getElementsByClassName("step");
  for (i = 0; i < x.length; i++) {
    x[i].className = x[i].className.replace(" active", "");
  }
  //... and adds the "active" class to the current step:
  x[n].className += " active";
}
	
</script> 
</cfoutput>
<cfinclude template="/includes/_footer.cfm">
