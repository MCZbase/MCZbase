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
<cfinclude template = "/shared/_header.cfm">
<style>
#mydiv, #mydiv1, #mydiv2, #mydiv3,#mydiv4, #mydiv5, #mydiv6,#mydiv7,#mydiv8,#mydiv9,#mydiv10,#mydiv11,#mydiv12,#mydiv13 {
	position: absolute;
	z-index: 9;
}
#mydiv, #mydiv1, #mydiv2, #mydiv3 {
	top: 42px;
}
#mydiv4, #mydiv5,#mydiv9 {
	top:131px;
}
#mydiv6 {
	top: 238px;
}
#mydiv7 {
	top:414px;
}
#mydiv8 {
	top:782px;
}

#mydiv10 {
	top:435px;	
	}
#mydiv11  {
	top:664px;
}
#mydiv12 {
	top: 664px;
}
#mydiv13 {
	top:764px;
}
#mydiv, #mydiv4, #mydiv7,#mydiv9,#mydiv6, #mydiv8 {
	left: 0;
}	
#mydiv1,#mydiv5 {
	left: 25%;
}
#mydiv2, #mydiv11, #mydiv10, #mydiv13,#mydiv9 {
	left: 50%;
}
#mydiv3,#mydiv12{
	left: 75%;
}
#mydivheader, #mydivheader1, #mydivheader2, #mydivheader3, #mydivheader4, #mydivheader5, #mydivheader6, #mydivheader7, #mydivheader8, #mydivheader9, #mydivheader10, #mydivheader11, #mydivheader12, #mydivheader13 {
	cursor: move;
	z-index: 10;
	font-size: 
}
#regFormAll .data-entry-title{font-size: .9rem;}

</style>

<cfoutput>

	<div style="position:absolute; top: 99px; left:25px;z-index:3000;"> <a href="javascript:SwapDivsWithClick('swapper-first','swapper-other')">Switch Between Full<br> Screen and Step Form</a> </div>
	<div class="container pt-0 mt-0 bg-blue-gray" id="swapper-other" style="display:none;">
		<div class="row">
			<div class="col-12 col-xl-10 justify-content-center mt-2 mx-auto">
				<form id="regForm" action="/DataEntry.cfm">
					<!-- One "tab" for each step in the form: -->
					<h1 class="text-center my-2">Enter a New Record</h1>
					<div class="tab">
						<h2 class="fs-title text-center">Record Numbers</h2>
						<h3 class="fs-subtitle text-center mb-4">This is step 1</h3>
						<div class="form-group row">
							<label for="cat_num" class="col-sm-3 col-form-label pt-0 text-center text-md-right">Catalog Number</label>
							<div class="col-sm-9">
									<input placeholder="Catalog Number" class="data-entry-input validate" oninput="this.className = ''" name="cat_num">
							
							</div>
						</div>
						<div class="form-group mb-0 row">
							<label for="other_id" class="col-sm-3 col-form-label pt-0 text-center text-md-right">Other ID</label>
							<div class="col-sm-4 col-md-4">
								<select class="form-control border" oninput="this.className = ''" mt-0 required>
									<option value="">Other ID Type</option>
									<option value="1">Field Number</option>
									<option value="2">Collector Number</option>
									<option value="3">Previous Number</option>
								</select>
							</div>
							<div class="col-sm-5">
								<input type="text" class="data-entry-input" oninput="this.className = ''" name="other_id" placeholder="Other ID">
							</div>
						</div>
						<div class="form-group row">
							<label for="other_id" class="col-sm-3 col-form-label text-center text-md-right">Mask Record</label>
							<div class="col-sm-9 col-md-9 text-left">
								<div class="form-check form-check-inline">
									<input class="form-check-input w-auto mt-2" value="mask" type="checkbox" id="gridCheck1">
									<label class="form-check-label w-auto mt-2" for="gridCheck1"> Mask Record (Generic Encumbrance)</label>
								</div>
							</div>
						</div>
						<div class="form-group row">
							<label for="relations" class="col-sm-3 col-form-label pt-0 text-center text-md-right">Other Records</label>
							<div class="col-sm-4 col-md-4 text-left">
								<select class="form-control border mt-0" required>
									<option value="">Relationship Type</option>
									<option value="1">Re-Cataloged as</option>
									<option value="2">Bad Duplicate of</option>
									<option value="3">Cloned from Record</option>
									<option value="4">Duplicate Recataloged as</option>
								</select>
							</div>
							<div class="col-sm-5">
								<input type="text" class="data-entry-input"  oninput="this.className = ''"  id="record_number" placeholder="Record Number">
							</div>
						</div>
					</div>
					<div class="tab">
						<h2 class="fs-title text-center">Collector/Preparator</h2>
						<h3 class="fs-subtitle text-center">This is step 2</h3>
						<div class="form-group row my-0">
							<label for="collector1" class="col-sm-3 col-form-label mt-0">
								<select class="form-control border mt-0 validate">
									<option value="">Role...</option>
									<option value="1">Collector</option>
									<option value="2">Preparator</option>
								</select>
							</label>
							<div class="col-sm-9 col-md-9 mt-1">
								<input type="text" class="data-entry-input validate" id="collector1" placeholder="Agent Name">
							</div>
						</div>
						<div class="form-group row my-0">
							<label for="collector2" class="col-sm-3 col-form-label mt-0">
								<select class="form-control border mt-0">
									<option value="">Role...</option>
									<option value="1">Collector</option>
									<option value="2">Preparator</option>
								</select>
							</label>
							<div class="col-sm-9 col-md-9 mt-1">
								<input type="text" class="data-entry-input" id="collector2" placeholder="Agent Name">
							</div>
						</div>
						<div class="form-group row my-1">
							<label for="collector3" class="col-sm-3 col-form-label mt-0">
								<select class="form-control border mt-0" required>
									<option value="">Role...</option>
									<option value="1">Collector</option>
									<option value="2">Preparator</option>
								</select>
							</label>
							<div class="col-sm-9 col-md-9 mt-1">
								<input type="text" class="data-entry-input" id="collector3" placeholder="Agent Name">
							</div>
						</div>
						<div class="form-group row my-1">
							<label for="collector4" class="col-sm-3 col-form-label mt-0">
								<select class="form-control border mt-0" required >
									<option value="">Role...</option>
									<option value="1">Collector</option>
									<option value="2">Preparator</option>
								</select>
							</label>
							<div class="col-sm-9 col-md-9 mt-1">
								<input type="text" class="data-entry-input" id="collector4" placeholder="Agent Name">
							</div>
						</div>
						<div class="form-group row my-1">
							<label for="collector5" class="col-sm-3 col-form-label mt-0">
								<select class="form-control  border mt-0">
									<option value="">Role...</option>
									<option value="1">Collector</option>
									<option value="2">Preparator</option>
								</select>
							</label>
							<div class="col-sm-9 col-md-9 mt-1">
								<input type="text" class="data-entry-input" id="collector5" placeholder="Agent Name">
							</div>
						</div>
					</div>
					<div class="tab">
						<h2 class="fs-title text-center">Scientific Name</h2>
						<h3 class="fs-subtitle text-center">This is step 3</h3>
						<div class="form-group row">
							<label for="scientific_name" class="col-sm-3 col-form-label pt-0 text-center text-md-right">Scientific Name</label>
							<div class="col-sm-9">
								<input type="text" name="scientific_name" class="data-entry-input" placeholder="Scientific Name" />
							</div>
						</div>
						<div class="form-group row">
							<label for="made_by" class="col-sm-3 col-form-label pt-0 text-center text-md-right">ID Made By</label>
							<div class="col-sm-9">
								<input type="text" name="made_by" class="data-entry-input" placeholder="Identifier's Name" />
							</div>
						</div>
						<div class="form-group row">
							<label for="nature_of_id" class="col-sm-3 col-form-label pt-0 text-center text-md-right">Nature of ID</label>
							<div class="col-sm-4">
								<select class="form-control border" required>
									<option value="">Expert ID</option>
									<option value="1">Field ID</option>
									<option value="2">Non-Expert ID</option>
									<option value="3">Curatorial ID</option>
								</select>
							</div>
							<div class="col-sm-5">
								<input type="text" name="made_by_date" class="data-entry-input" placeholder="Date of ID" />
							</div>
						</div>
						<div class="form-group row my-0">
							<label for="id_remark" class="col-sm-3 col-form-label pt-0 text-center text-md-right">ID Remark</label>
							<div class="col-sm-9">
								<textarea type="text" name="id_remark" class="data-entry-input" placeholder="ID remark"/>
								</textarea>
							</div>
						</div>
					</div>
					<div class="tab">
						<h2 class="fs-title text-center">Locality</h2>
						<h3 class="fs-subtitle text-center">This is step 4</h3>
						<div class="form-group row">
							<label for="higher_geog" class="col-sm-3 col-form-label pt-0 text-center text-md-right">Higher Geography</label>
							<div class="col-sm-9">
								<input type="text" name="higher_geog" class="form-control" placeholder="Higher Geography" />
							</div>
						</div>
						<div class="form-group row">
							<label for="higher_geog" class="col-sm-3 col-form-label pt-0 text-center text-md-right">Specific Locality</label>
							<div class="col-sm-9">
								<input type="text" name="spec_locality" class="form-control" placeholder="Specific Locality" />
							</div>
						</div>
						<div class="form-group row">
							<label for="inputPassword3" class="col-sm-3 col-form-label pt-0 text-center text-md-right">Elevation</label>
							<div class="col-sm-3">
								<input type="text" class="form-control" id="inputMinElev" placeholder="Min Elevation">
							</div>
							<div class="col-sm-3">
								<input type="text" class="form-control" id="inputMaxElev" placeholder="Max Elevation">
							</div>
							<div class="col-sm-2">
								<select class="form-control border" required>
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
							<label for="inputPassword3" class="col-sm-3 col-form-label pt-0 text-center text-md-right">Depth</label>
							<div class="col-sm-3">
								<input type="text" class="form-control" id="inputMinDepth" placeholder="Min Depth">
							</div>
							<div class="col-sm-3">
								<input type="text" class="form-control" id="inputMaxDepth" placeholder="Max Depth">
							</div>
							<div class="col-sm-2">
								<select class="border form-control" required>
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
							<label for="sovereign_nation" class="col-sm-3 col-form-label pt-0 text-center text-md-right">Sovereign Nation</label>
							<div class="col-sm-9">
								<input type="text" name="sovereign_nation" class="form-control" placeholder="Sovereign Nation" />
							</div>
						</div>
						<div class="form-group row">
							<label for="higher_geog" class="col-sm-3 col-form-label pt-0 text-center text-md-right">Geology Attribute</label>
							<div class="col-sm-9 my-0">
								<input type="text" name="geology_attribute" class="form-control" placeholder="Geology Attribute" />
							</div>
						</div>
						<div class="form-group row">
							<label for="habitat" class="col-sm-3 col-form-label pt-0 text-center text-md-right">Habitat</label>
							<div class="col-sm-9">
								<input type="text" name="habitat" class="form-control" placeholder="Habitat" />
							</div>
						</div>
					</div>
					<div style="overflow:auto;" class="mt-4 mb-2">
						<div class="text-right">
							<button type="button" id="prevBtn" class="btn btn-sm btn-primary" onclick="nextPrev(-1)">Previous</button>
							<button type="button" id="nextBtn" class="btn btn-sm btn-primary" onclick="nextPrev(1)">Next</button>
						</div>
					
					</div>
					<!-- Circles which indicates the steps of the form: -->
					<div class="my-4 text-center"> <span class="step">1</span> <span class="step">2</span> <span class="step">3</span> <span class="step">4</span> <span class="step">5</span> <span class="step">6</span> <span class="step">7</span> <span class="step">8</span> <span class="step">9</span> </div>
				</form>
			</div>
		</div>
	</div>
	
	<div class="container-fluid pt-1 bg-blue-gray"  id="swapper-first" style="height: 1111px;">
		<div class="row mx-0 bg-blue-gray" style="background-color:##deebec!important;">
			<div class="col-12 mt-0">
			<form id="regFormAll" class="w-100" action="/DataEntry.cfm">
				<!-- One "tab" for each step in the form: -->
				<h1 class="text-center mt-2 mb-0">Enter a New Record</h1>
				<div class="row">
					<div class="col-12 col-md-3 pb-1 px-1" id="mydiv">
						<div class="border-fill px-3 py-1 m-1" id="mydivheader">
							<h2 class="data-entry-title">Collection</h2>
								<div class="row">
								<label for="collection" class="sr-only">Collection</label>
								<div class="col-12">
									<select class="data-entry-select px-0" required>
										<option value="">Select Collection</option>
										<option value="1">Herpetology</option>
										<option value="2">Mammalogy</option>
										<option value="3">Malacology</option>
									</select>
									<small id="catNumHelp" class="form-text text-center text-muted">Sets Data Entry template</small> 
								</div>
							</div>
						</div>
					</div>
					<div class="col-12 col-md-3 pb-1 px-1" id="mydiv1">
						<div class="border-fill px-3 py-1 m-1" id="mydivheader1">
							<h2 class="data-entry-title">Catalog Number</h2>
							<div class="row">
								<label for="cat_num" class="sr-only">Catalog Number</label>
								<div class="col-12">
									<input type="text" class="data-entry-input" id="cat_num" aria-describedby="catNumHelp" placeholder="Enter Catalog Number" name="cat_num">
									<small id="catNumHelp" class="form-text text-center text-muted">Must be unique for the collection.</small> </div>
							</div>
						</div>
					</div>
					<div class="col-12 col-md-3 pb-1 px-1" id="mydiv2">
						<div class="border-fill px-3 py-1 m-1" id="mydivheader2">
							<h2 class="data-entry-title">Accession Number</h2>
							<!---<h3 class="data-entry-subtitle">This is step 4</h3>--->
							<div class="form-row">
								<label for="cat_num" class="sr-only">Accession</label>
								<div class="col-12">
									<input type="text" class="data-entry-input" id="accn" aria-describedby="accnHelp" placeholder="Accession Number" name="accn">
									<small id="accnHelp" class="form-text text-center text-muted">Should already exist in database.</small> </div>
							</div>
						</div>
					</div>
					<div class="col-12 col-md-3 pb-1 px-1" id="mydiv3">
						<div class="border-fill px-3 py-2 m-1" id="mydivheader3">
							<h2 class="data-entry-title">Encumbrance</h2>
						<!---	<h3 class="data-entry-subtitle">This is step 3</h3>--->
							<div id="encumbrance">
								<div class="row mb-3">
									<label for="mask_record" class="data-entry-label col-12 col-xl-3 text-center pr-0" style="margin-top: -5px;">Mask Record</label>
									<div class="col-xl-9">
										<div class="form-check form-check-inline">
											<input class="form-check-input w-auto mt-1" value="mask" type="checkbox" id="gridCheck1">
											<!--<label class="form-check-label w-auto form-control-sm border-0 mt-0" for="gridCheck1"> Mask Record in Generic Encumbrance</label>--> 
											<small id="accnHelp" class="form-text float-left text-muted">Puts it in a generic encumbrance.</small> </div>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>
				<div class="row">
					<div class="col-12 col-md-3 pb-1 px-1" id="mydiv4">
						<div class="border-fill px-3 py-1 m-1" id="mydivheader4">
							<h2 class="data-entry-title">Collector/Preparator</h2>
							<!---<h3 class="data-entry-subtitle">This is step 6</h3>--->
							<div id="customAgent">
								<div class="row">
									<label for="other_id" class="sr-only">Agent</label>
									<div class="col-12 col-xl-5 pr-1">
										<select class="data-entry-select">
											<option value="">Collector</option>
											<option value="1">Preparator</option>
										</select>
									</div>
									<div class="col-12 col-xl-6 px-1">
										<input type="text" class="data-entry-input" name="other_id" placeholder="Value">
									</div>
								</div>
							</div>
							<div class="col-md-12 col-sm-12 p-0 mx-1 d-flex justify-content-end"> <a aria-label="Add another set of search criteria" class="btn btn-xs btn-primary addAgent loginButtons rounded ml-auto m-1" target="_self" href="javascript:void(0);">Add</a> </div>
						</div>
					</div>
					<div class="col-12 col-md-3 pb-1 px-1" id="mydiv5">
						<div class="border-fill px-3 py-1 m-1" id="mydivheader5">
							<h2 class="data-entry-title">Other IDs</h2>
						<!---	<h3 class="data-entry-subtitle">This is step 5</h3>--->
							<div id="customOtherID">
								<div class="row">
									<label for="other_id" class="sr-only">Other ID</label>
									<div class="col-xl-5 pr-1">
										<select class="data-entry-select" required>
											<option value="">Other ID Type</option>
											<option value="1">Field Number</option>
											<option value="2">Collector Number</option>
											<option value="3">Previous Number</option>
										</select>
									</div>
									<div class="col-xl-6 px-1">
										<input type="text" class="data-entry-input"  name="other_id" placeholder="Other ID">
									</div>
								</div>
							</div>
							<div class="col-md-12 col-sm-12 p-0 mx-1 d-flex justify-content-end"> <a aria-label="Add another set of search criteria" class="btn btn-xs btn-primary addOtherID loginButtons rounded ml-auto m-1" target="_self" href="javascript:void(0);">Add</a> </div>
						</div>
					</div>
					<div class="col-12 col-md-6 pb-1 px-1" id="mydiv6">
						<div class="border-fill px-3 py-1 m-1" id="mydivheader6">
							<h2 class="data-entry-title">Scientific Name</h2>
							<!---<h3 class="data-entry-subtitle">This is step 7</h3>--->
							<div id="customSciName">
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
									<div class="col-12 col-lg-4 pr-xl-0">
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
									<label for="id_remark" class="data-entry-label col-12 col-lg-3 text-center text-md-right px-0">ID Remark</label>
									<div class="col-12 col-lg-9">
										<textarea type="text" name="id_remark" class="data-entry-textarea" placeholder="ID Remark"/>
										</textarea>
									</div>
								</div>
							</div>
							<div class="col-md-12 col-sm-12 p-0 mx-1 d-flex justify-content-end"> <a aria-label="Add identification" class="btn btn-xs btn-primary addSciName  loginButtons rounded ml-auto m-1" target="_self" href="javascript:void(0);">Add</a></div>
						</div>
					</div>
					<div class="col-12 col-md-6 pb-1 px-1" id="mydiv7">
						<div class="border-fill px-3 pt-1 pb-3 m-1" id="mydivheader7">
							<h2 class="data-entry-title">Collecting Event</h2>
							<!---<h3 class="data-entry-subtitle">This is step 8</h3>--->
							<div class="row">
								<label for="collecting_event_id" class="data-entry-label col-sm-3 text-center text-md-right px-0">Use ID only</label>
								<div class="col-sm-9">
									<input type="text" name="collecting_event_id" class="data-entry-input" placeholder="Collecting Event ID" />
								</div>
							</div>
							<div class="row">
								<label for="collecting_event_id" class="data-entry-label col-sm-3 text-center text-md-right px-0"></label>
								<div class="col-sm-9"> <span>OR</span> </div>
							</div>
							<div class="row">
								<label for="verbatim_locality" class="data-entry-label col-sm-3 text-center text-md-right px-xl-0">Verbatim Locality</label>
								<div class="col-sm-9">
									<input type="text" name="verbatim_locality" class="data-entry-input" placeholder="Verbatim Locality" />
								</div>
							</div>
							<div class="row">
								<label for="inputPassword3" class="data-entry-label col-sm-3 text-center text-md-right px-xl-0">ISO Dates and Time</label>
								<div class="col-12 col-sm-3 pr-0">
									<input type="text" class="data-entry-input pr-xl-0" id="began_date" placeholder="Began Date">
								</div>
								<div class="col-12 col-sm-3 pr-0">
									<input type="text" class="data-entry-input pr-xl-0" id="ended_date" placeholder="Date Ended">
								</div>
								<div class="col-12 col-sm-3">
									<input type="text" class="data-entry-input pr-xl-0" id="collecting_time" placeholder="Collecting Time">
								</div>
							</div>
							<div class="row">
								<label for="inputPassword3" class="data-entry-label col-sm-3 text-center text-md-right">Verbatim Date</label>
								<div class="col-sm-9">
									<input type="text" class="data-entry-input" id="verbatim_date" placeholder="Verbatim Date">
								</div>
							</div>
							<div class="row">
								<label for="start_end_dayOfyear" class="data-entry-label col-sm-3 text-center text-md-right px-xl-0">Day of Year</label>
								<div class="col-12 col-sm-4 pr-0">
									<input type="text" class="data-entry-input pr-xl-0" id="start_day_of_year" placeholder="Start Day of Year">
								</div>
								<div class="col-12 col-sm-4 pr-0">
									<input type="text" class="data-entry-input pr-xl-0" id="end_day_of_year" placeholder="End Day of Year">
								</div>
							</div>
							<div class="row">
								<label for="collecting_source_method" class="data-entry-label col-sm-3 text-center text-md-right px-0">Source &amp; Method</label>
								<div class="col-12 col-sm-4 pr-0">
									<input type="text" class="data-entry-input pr-xl-0" id="collecting_source" placeholder="Collecting Source">
								</div>
								<div class="col-12 col-sm-4 pr-0">
									<input type="text" class="data-entry-input pr-xl-0" id="collecting_method" placeholder="Collecting Method">
								</div>
							</div>
							<div class="row">
								<label for="Habitat" class="data-entry-label col-sm-3 text-center text-md-right px-0">Habitat</label>
								<div class="col-sm-9">
									<input type="text" name="habitat_desc" class="data-entry-input" placeholder="Habitat" />
								</div>
							</div>
							<div class="row">
								<label for="microhabitat" class="data-entry-label col-sm-3 text-center text-md-right px-0">Microhabitat</label>
								<div class="col-sm-9">
									<input type="text" name="habitat" class="data-entry-input" placeholder="Microhabitat" />
								</div>
							</div>
							<div class="row">
								<label for="locality_remark" class="data-entry-label col-sm-3 text-center text-md-right px-0">Collecting Remark</label>
								<div class="col-sm-9">
									<textarea type="text" name="locality_remark" class="data-entry-textarea" placeholder="Locality Remark"/>
									</textarea>
								</div>
							</div>
							<div class="row">
								<div class="text-left w-100 py-2 px-5">Verbatim Georeference</div>
								<label for="Coord. System" class="data-entry-label col-sm-3 text-center text-md-right px-xl-0">Coordinate System</label>
								<div class="col-12 col-sm-4 pr-0">
									<input type="text" class="data-entry-input pr-xl-0" id="coord_system" placeholder="e.g., decimal degrees">
								</div>
								<div class="col-12 col-sm-4 pr-0">
									<input type="text" class="data-entry-input pr-xl-0" id="Datum" placeholder="SRS or Datum">
								</div>
							</div>
							<div class="row">
								<label for="lat_long" class="data-entry-label col-sm-3 text-center text-md-right px-xl-0">Lat. and Long.</label>
								<div class="col-12 col-sm-4 pr-0">
									<input type="text" class="data-entry-input pr-xl-0" id="latitude" placeholder="Latitude">
								</div>
								<div class="col-12 col-sm-4 pr-0">
									<input type="text" class="data-entry-input pr-xl-0" id="longitude" placeholder="Longitude">
								</div>
							</div>
						</div>
					</div>				
					<div class="col-12 col-md-6 pb-1 px-1" id="mydiv8">
						<div class="border-fill px-3 pt-1 pb-3 m-1" id="mydivheader8">
							<h2 class="data-entry-title">Locality</h2>
						<!---	<h3 class="data-entry-subtitle">This is step 9</h3>--->
							<div class="row">
								<div class="col-12">
									<p class="text-center"><small>The use of the Collecting Event ID in Collecting Event eliminates the need to complete this step.</small></p>
								</div>
							</div>
							<div class="row">
								<label for="locality_id" class="data-entry-label col-sm-3 text-center text-md-right px-0">Use ID only</label>
								<div class="col-sm-9">
									<input type="text" name="locality_id" class="data-entry-input" placeholder="Locality ID" />
								</div>
							</div>
							<div class="row">
								<label for="collecting_event_id" class="data-entry-label col-sm-3 text-center text-md-right px-0"></label>
								<div class="col-sm-9"> <span>OR</span> </div>
							</div>
							<div class="row">
								<label for="higher_geog" class="data-entry-label col-sm-3 text-center text-md-right px-0">Higher Geography</label>
								<div class="col-sm-9">
									<input type="text" name="higher_geog" class="data-entry-input" placeholder="Higher Geography" />
								</div>
							</div>
							<div class="row">
								<label for="higher_geog" class="data-entry-label col-sm-3 text-center text-md-right px-0">Specific Locality</label>
								<div class="col-sm-9">
									<input type="text" name="spec_locality" class="data-entry-input" placeholder="Specific Locality" />
								</div>
							</div>
							<div class="row">
								<label for="inputPassword3" class="data-entry-label col-sm-3 text-center text-md-right px-0">Elevation</label>
								<div class="col-12 col-sm-3 pr-0">
									<input type="text" class="data-entry-input pr-0" id="inputMinElev" placeholder="Min Elevation">
								</div>
								<div class="col-12 col-sm-3 pr-0">
									<input type="text" class="data-entry-input pr-0" id="inputMaxElev" placeholder="Max Elevation">
								</div>
								<div class="col-12 col-sm-2 pr-0">
									<select class="data-entry-select pr-0" required>
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
								<div class="col-12 col-sm-3 pr-0">
									<input type="text" class="data-entry-input pr-0" id="inputMinDepth" placeholder="Min Depth">
								</div>
								<div class="col-12 col-sm-3 pr-0">
									<input type="text" class="data-entry-input pr-0" id="inputMaxDepth" placeholder="Max Depth">
								</div>
								<div class="col-12 col-sm-2 pr-0">
									<select class="data-entry-select pr-0" required>
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
								<label for="sovereign_nation" class="data-entry-label col-sm-3 text-center text-md-right px-0">Sovereign Nation</label>
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
							<div class="row">
								<label for="locality_remark" class="data-entry-label col-sm-3 text-center text-md-right px-0">Locality Remark</label>
								<div class="col-sm-9">
									<textarea type="text" name="locality_remark" class="data-entry-textarea" placeholder="Locality Remark"/>
									</textarea>
								</div>
							</div>
						</div>
					</div>
					<div class="col-12 col-md-6 pb-1 px-1" id="mydiv9">
						<div class="border-fill px-3 py-1 m-1" id="mydivheader9">
							<h2 class="data-entry-title">Coordinates</h2>
						<!---	<h3 class="data-entry-subtitle">This is step 10</h3>--->
							<div id="customCoord">
								<div class="row">
									<label for="higher_geog" class="data-entry-label col-sm-3 text-center text-md-right px-0">Original Coordinates Units</label>
									<div class="col-sm-9">
										<select class="data-entry-select pr-0" required>
											<option value="">Decimal Degrees</option>
											<option value="1">Dec. Min. Secs.</option>
											<option value="2">Degrees Dec. Minutes</option>
											<option value="3">Unknown</option>
										</select>
									</div>
								</div>
								<div class="row">
									<label for="higher_geog" class="data-entry-label col-sm-3 text-center text-md-right px-0">Maximumm Error</label>
									<div class="col-12 col-sm-4">
										<input type="text" name="maximum_error" class="data-entry-input" placeholder="Maximum Error" />
									</div>
									<div class="col-12 col-sm-4 pr-0">
										<input type="text" class="data-entry-input pr-xl-0" placeholder="Error Units">
									</div>
								</div>
								<div class="row">
									<label for="extent" class="data-entry-label col-sm-3 text-center text-md-right px-0">Extent</label>
									<div class="col-sm-9">
										<input type="text" name="extent" class="data-entry-input" placeholder="Extent" />
									</div>
								</div>
								<div class="row">
									<label for="GPS_accuracy" class="data-entry-label col-sm-3 text-center text-md-right px-0">GPS Accuracy</label>
									<div class="col-sm-9">
										<input type="text" name="gps_accuracy" class="data-entry-input" placeholder="GPS Accuracy" />
									</div>
								</div>
								<div class="row">
									<label for="higher_geog" class="data-entry-label col-sm-3 text-center text-md-right px-0">Datum</label>
									<div class="col-sm-9">
										<select class="data-entry-select pr-0" required>
											<option value="">NAD27</option>
											<option value="1">POS</option>
											<option value="2">GRA</option>
											<option value="3">WGS84</option>
										</select>
									</div>
								</div>
								<div class="row">
									<label for="determiner" class="data-entry-label col-sm-3 text-center text-md-right px-0">Determiner</label>
									<div class="col-sm-4">
										<input type="text" name="determiner" class="data-entry-input" placeholder="Determiner" />
									</div>
									<label for="date" class="sr-only">Date</label>
									<div class="col-sm-4">
										<input type="text" name="date" class="data-entry-input" placeholder="Date" />
									</div>
								</div>						
								<div class="row">
									<label for="higher_geog" class="data-entry-label col-sm-3 text-center text-md-right px-0">Georeference Meth.</label>
									<div class="col-sm-9">
										<select class="data-entry-select pr-0" required>
											<option value="">GeoLocate</option>
											<option value="1">GPS</option>
											<option value="2">Google Earth</option>
											<option value="3">Gazetteer</option>
										</select>
									</div>
								</div>
								<div class="row">
									<label for="reference" class="data-entry-label col-sm-3 text-center text-md-right px-0">Reference</label>
									<div class="col-sm-9">
										<input type="text" name="reference" class="data-entry-input" placeholder="Reference" />
									</div>
								</div>
								<div class="row">
									<label for="locality_remark" class="data-entry-label col-sm-3 text-center text-md-right px-0">Locality Remark</label>
									<div class="col-sm-9">
										<textarea type="text" name="locality_remark" class="data-entry-textarea" placeholder="Locality Remark"/>
										</textarea>

									</div>
								</div>
							</div>
							<div class="col-md-12 col-sm-12 p-0 mx-1 d-flex justify-content-end"> <a aria-label="Add Coordinates" class="btn btn-xs btn-primary addCoord loginButtons rounded ml-auto m-1" target="_self" href="javascript:void(0);">Add</a></div>
						</div>
					</div>
					<div class="col-12 col-md-6 pb-1 px-1" id="mydiv10">
						<div class="border-fill px-3 py-1 m-1" id="mydivheader10">
							<h2 class="data-entry-title">Attributes</h2>
						<!---	<h3 class="data-entry-subtitle">This is step 12</h3>--->
							<div id="customAtt">
								<div class="row mt-3">
									<label for="attribute_name" class="data-entry-label col-sm-3 text-center text-md-right px-0">Attribute Type</label>
									<div class="col-12 col-lg-9">
										<input type="text" class="data-entry-input" name="attribute" placeholder="Attribute Type">
									</div>
									<div class="col-12 row mx-0 px-0">
										<label for="part_number" class="data-entry-label col-lg-3 text-center text-xl-right px-0">Attribute Value</label>
										<div class="col-12 col-lg-5">
											<input type="text" name="attribute value" class="data-entry-input" placeholder="Attribute Value">
										</div>
										<div class="col-12 col-lg-4">
											<select class="data-entry-select" required="">
												<option value="">Units</option>
												<option value="1">Life Cycle Stage</option>
												<option value="2">Citation</option>
												<option value="3">Host</option>
											</select>
										</div>
									</div>
									<label for="date" class="data-entry-label col-sm-3 text-center text-md-right px-0">Date</label>
									<div class="col-12 col-lg-9">
										<input type="text" class="data-entry-input" name="date" placeholder="Date">
									</div>
									<label for="determiner" class="data-entry-label col-sm-3 text-center text-md-right px-0">Determiner</label>
									<div class="col-12 col-lg-9">
										<input type="text" class="data-entry-input" name="determiner" placeholder="Determiner">
									</div>
									<label for="method" class="data-entry-label col-sm-3 text-center text-md-right px-0">Method</label>
									<div class="col-12 col-lg-9">
										<input type="text" class="data-entry-input" name="method" placeholder="Method">
									</div>
									<label for="attribute_remark" class="data-entry-label col-sm-3 text-center text-md-right px-0">Attribute Remark</label>
									<div class="col-12 col-lg-9">
										<textarea type="text" name="attribute_remark" class="data-entry-textarea" placeholder="Attribute Remark"/>
										</textarea>
									</div>
								</div>
							</div>
							<div class="col-md-12 col-sm-12 p-0 mx-1 d-flex justify-content-end"> <a aria-label="Add another set of search criteria" class="btn btn-xs btn-primary addAtt loginButtons rounded ml-auto m-1" target="_self" href="javascript:void(0);">Add</a> </div>
						</div>
					</div>
					<div class="col-12 col-md-3 pb-1 px-1" id="mydiv11">
						<div class="border-fill px-3 py-1 m-1" id="mydivheader11">
							<h2 class="data-entry-title">Biological Relationships</h2>
				<!---			<h3 class="data-entry-subtitle">This is step 5</h3>--->
							<div id="customBiolRelations">
								<div class="row">
									<label for="relations" class="sr-only">Relationship</label>
									<div class="col-12 col-xl-5 pr-1">
										<select class="data-entry-select">
											<option value="">Relationship Type</option>
											<option value="1">Same lot as</option>
											<option value="2">Egg of</option>
											<option value="3">Parent of</option>
											<option value="4">In Nest</option>
										</select>
									</div>
									<div class="col-12 col-xl-6 px-1">
										<input type="text" class="data-entry-input" id="relationship" placeholder="Record Number">
									</div>
								</div>
							</div>
							<div class="col-md-12 col-sm-12 p-0 mx-1 d-flex justify-content-end"> <a aria-label="Add another set of search criteria" class="btn btn-xs btn-primary addBiolRelations loginButtons rounded ml-auto m-1" target="_self" href="javascript:void(0);">Add</a> </div>
						</div>
					</div>
					<div class="col-12 col-md-3 pb-1 px-1" id="mydiv12">
						<div class="border-fill px-3 py-1 m-1" id="mydivheader12">
							<h2 class="data-entry-title">Curatorial Relationships</h2>
							<!---<h3 class="data-entry-subtitle">This is step 4</h3>--->
							<div id="customCurRelations">
								<div class="row">
									<label for="relations" class="sr-only">Relationship</label>
									<div class="col-12 col-xl-5 pr-1">
										<select class="data-entry-select">
											<option value="">Relationship Type</option>
											<option value="1">Re-Cataloged as</option>
											<option value="2">Bad Duplicate of</option>
											<option value="3">Cloned from Record</option>
											<option value="4">Duplicate Recataloged as</option>
										</select>
									</div>
									<div class="col-12 col-xl-6 px-1">
										<input type="text" class="data-entry-input" id="record_number" placeholder="Record Number">
									</div>
								</div>
							</div>
							<div class="col-md-12 col-sm-12 p-0 mx-1 d-flex justify-content-end"> <a aria-label="Add another set of search criteria" class="btn btn-xs btn-primary addCurRelations loginButtons rounded ml-auto m-1" target="_self" href="javascript:void(0);">Add </a> </div>
						</div>
					</div>
					<div class="col-12 col-md-6 px-1" id="mydiv13">
						<div class="border-fill px-3 py-1 m-1" id="mydivheader13">
							<h2 class="data-entry-title">Parts</h2>
				
							<!---<h3 class="data-entry-subtitle">This is step 11</h3>--->
							<div id="customPart">
								<div class="row">
									<label for="part_name" class="data-entry-label col-sm-3 text-center text-md-right px-0">Part Name</label>
									<div class="col-12 col-lg-9">
										<input type="text" class="data-entry-input" name="part_name" placeholder="Part Name">
									</div>
									<label for="preserv_method" class="data-entry-label col-sm-3 text-center text-md-right px-0">Preserve Method</label>
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
									<label for="disposition" class="data-entry-label col-sm-3 text-center text-md-right px-xl-0">Disposition</label>
									<div class="col-12 col-lg-9">
										<select class="data-entry-select" required>
											<option value="">Being Processed</option>
											<option value="1">Deaccessioned</option>
											<option value="2">In Collection</option>
											<option value="3">Missing</option>
										</select>
									</div>
									<div class="col-12 row mx-0 px-0">
										<label for="part_number" class="data-entry-label col-lg-3 text-center text-xl-right px-0">## of Parts</label>
										<div class="col-12 col-lg-4 pr-xl-0">
											<select class="data-entry-select pr-xl-0" required="">
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
									<label for="part_remark" class="data-entry-label col-sm-3 text-center text-md-right px-0">Part Remark</label>
									<div class="col-12 col-lg-9">
										<textarea type="text" name="part_remark" class="data-entry-textarea" placeholder="Part Remark"/>
										</textarea>
									</div>
								</div>
								<div class="col-md-12 col-sm-12 p-0 mx-1 d-flex justify-content-end"> <a aria-label="Add another set of search criteria" class="btn btn-xs btn-primary addPart loginButtons rounded ml-auto m-1" target="_self" href="javascript:void(0);">Add </a></div>
							</div>
							</div>
					</div>
				</div>
			</form>
			</div>
		</div>
	</div>
<script>
	dragElement(document.getElementById("mydiv"));
	dragElement(document.getElementById("mydiv1"));
	dragElement(document.getElementById("mydiv2"));
	dragElement(document.getElementById("mydiv3"));
	dragElement(document.getElementById("mydiv4"));
	dragElement(document.getElementById("mydiv5"));
	dragElement(document.getElementById("mydiv6"));
	dragElement(document.getElementById("mydiv7"));
	dragElement(document.getElementById("mydiv8"));
	dragElement(document.getElementById("mydiv9"));
	dragElement(document.getElementById("mydiv10"));
	dragElement(document.getElementById("mydiv11"));
	dragElement(document.getElementById("mydiv12"));
	dragElement(document.getElementById("mydiv13"));
function dragElement(elmnt) {
  var pos1 = 0, pos2 = 0, pos3 = 0, pos4 = 0;
  if (document.getElementById(elmnt.id + "header")) {
    // if present, the header is where you move the DIV from:
    document.getElementById(elmnt.id + "header").onmousedown = dragMouseDown;
  } else {
    // otherwise, move the DIV from anywhere inside the DIV:
    elmnt.onmousedown = dragMouseDown;
  }

  function dragMouseDown(e) {
    e = e || window.event;
    e.preventDefault();
    // get the mouse cursor position at startup:
    pos3 = e.clientX;
    pos4 = e.clientY;
    document.onmouseup = closeDragElement;
    // call a function whenever the cursor moves:
    document.onmousemove = elementDrag;
  }

  function elementDrag(e) {
    e = e || window.event;
    e.preventDefault();
    // calculate the new cursor position:
    pos1 = pos3 - e.clientX;
    pos2 = pos4 - e.clientY;
    pos3 = e.clientX;
    pos4 = e.clientY;
    // set the element's new position:
    elmnt.style.top = (elmnt.offsetTop - pos2) + "px";
    elmnt.style.left = (elmnt.offsetLeft - pos1) + "px";
  }

  function closeDragElement() {
    // stop moving when mouse button is released:
    document.onmouseup = null;
    document.onmousemove = null;
  }

}
</script>
	<!---Step by step form for each section of the Data Entry form -- Form wizard--->




	<script>
	//this is from https://stackoverflow.com/questions/16183231/jquery-append-and-remove-dynamic-table-row 
		
$(document).ready(function(){
	$(".addOtherID").click(function(){
		$("##customOtherID").append('<div class="row mt-1"><label for="other_id" class="sr-only"></label><div class="col-12 col-xl-5 pr-1 float-left"><select class="data-entry-select" required><option value="">Other ID Type</option><option value="1">Field Number</option><option value="2">Collector Number</option><option value="3">Previous Number</option></select></div><div class="col-12 col-xl-6 px-1 float-left"><input type="text" class="data-entry-input"  name="other_id" placeholder="Other ID"></div><button href="javascript:void(0);" arial-label="remove" class="btn addOtherID float-right data-entry-button remOtherID"><i class="fas fa-times"></i></button></div>');
	});
		$("##customOtherID").on('click','.remOtherID',function(){
			$(this).parent().remove();});
	});

	//this is from https://stackoverflow.com/questions/16183231/jquery-append-and-remove-dynamic-table-row  
$(document).ready(function(){
	$(".addCurRelations").click(function(){$("##customCurRelations").append('<div class="row mt-1"><label for="relations" class="data-entry-label col-12 col-xl-3 text-center text-xl-right">Relationship</label><div class="col-xl-4 px-xl-0"><select class="data-entry-select"><option value="">Relationship Type</option><option value="1">Re-Cataloged as</option><option value="2">Bad Duplicate of</option><option value="3">Cloned from Record</option><option value="4">Duplicate Recataloged as</option></select></div><div class="col-xl-4"><input type="text" class="data-entry-input" id="record_number" placeholder="Record Number"></div><button href="javascript:void(0);" arial-label="remove" class="btn addCurRelations data-entry-button float-right remCurRelations"><i class="fas fa-times"></i></button></div>');
	});
	$("##customCurRelations").on('click','.remCurRelations',function(){$(this).parent().remove();});
	});

	//this is from https://stackoverflow.com/questions/16183231/jquery-append-and-remove-dynamic-table-row  
$(document).ready(function(){
	$(".addBiolRelations").click(function(){$("##customBiolRelations").append('<div class="row mt-1"><label for="relations" class="data-entry-label col-12 col-xl-3 text-center text-xl-right">Relationship</label><div class="col-xl-4 px-xl-0"><select class="data-entry-select"><option value="">Relationship Type</option><option value="1">Re-Cataloged as</option><option value="2">Bad Duplicate of</option><option value="3">Cloned from Record</option><option value="4">Duplicate Recataloged as</option></select></div><div class="col-xl-4"><input type="text" class="data-entry-input" id="record_number" placeholder="Record Number"></div><button href="javascript:void(0);" arial-label="remove" class="btn addBiolRelations data-entry-button float-right remBiolRelations"><i class="fas fa-times"></i></button></div>');
	});
	$("##customBiolRelations").on('click','.remBiolRelations',function(){$(this).parent().remove();});
	});

	//this is from https://stackoverflow.com/questions/16183231/jquery-append-and-remove-dynamic-table-row  
$(document).ready(function(){
	$(".addAgent").click(function(){$("##customAgent").append('<div class="row mt-2"><label for="other_id" class="sr-only float-left">Agent X</label><div class="col-lg-5 pr-1 float-left"><select class="data-entry-select"><option value="">Collector</option><option value="1">Preparator</option></select></div><div class="col-12 col-xl-6 px-1 float-left"><input type="text" class="data-entry-input" name="agent" placeholder="Value"></div><button href="javascript:void(0);" arial-label="remove" class="btn addAgent float-left data-entry-button p-0 m-0 remAgent" style="width:20px;"><i class="fas fa-times"></i></button></div>');
	});
	$("##customAgent").on('click','.remAgent',function(){$(this).parent().remove();});
});

	//this is from https://stackoverflow.com/questions/16183231/jquery-append-and-remove-dynamic-table-row  
$(document).ready(function(){
	$(".addCoord").click(function(){$("##customCoord").append('<div class="row mt-1"><label for="higher_geog" class="data-entry-label col-sm-3 text-center text-md-right px-0">Original Coordinates Units</label><div class="col-sm-9"><select class="data-entry-select pr-0" required><option value="">Decimal Degrees</option><option value="1">Dec. Min. Secs.</option><option value="2">Degrees Dec. Minutes</option><option value="3">Unknown</option></select></div></div><div class="row"><label for="higher_geog" class="data-entry-label col-sm-3 text-center text-md-right px-0">Maximumm Error</label><div class="col-12 col-sm-4"><input type="text" name="maximum_error" class="data-entry-input" placeholder="Maximum Error" /></div><div class="col-12 col-sm-4 pr-0"><input type="text" class="data-entry-input pr-xl-0" placeholder="Error Units"></div></div><div class="row"><label for="extent" class="data-entry-label col-sm-3 text-center text-md-right px-0">Extent</label><div class="col-sm-9"><input type="text" name="extent" class="data-entry-input" placeholder="Extent" /></div></div><div class="row"><label for="GPS_accuracy" class="data-entry-label col-sm-3 text-center text-md-right px-0">GPS Accuracy</label><div class="col-sm-9"><input type="text" name="gps_accuracy" class="data-entry-input" placeholder="GPS Accuracy" /></div></div><div class="row"><label for="higher_geog" class="data-entry-label col-sm-3 text-center text-md-right px-0">Datum</label><div class="col-sm-9"><select class="data-entry-select pr-0" required><option value="">NAD27</option><option value="1">POS</option><option value="2">GRA</option><option value="3">WGS84</option></select></div></div><div class="row"><label for="determiner" class="data-entry-label col-sm-3 text-center text-md-right px-0">Determiner</label><div class="col-sm-9"><input type="text" name="determiner" class="data-entry-input" placeholder="Determiner"/></div></div><div class="row"><label for="date" class="data-entry-label col-sm-3 text-center text-md-right px-0">Date</label><div class="col-sm-9"><input type="text" name="date" class="data-entry-input" placeholder="Date" /></div></div><div class="row"><label for="higher_geog" class="data-entry-label col-sm-3 text-center text-md-right px-0">Georeference Meth.</label><div class="col-sm-9"><select class="data-entry-select pr-0" required><option value="">GeoLocate</option><option value="1">GPS</option><option value="2">Google Earth</option><option value="3">Gazetteer</option></select></div></div><div class="row"><label for="reference" class="data-entry-label col-sm-3 text-center text-md-right px-0">Reference</label><div class="col-sm-9"><input type="text" name="reference" class="data-entry-input" placeholder="Reference" /></div></div><div class="row"><label for="locality_remark" class="data-entry-label col-sm-3 text-center text-md-right px-0">Locality Remark</label><div class="col-12 col-xl-8 pl-xl-0"><textarea type="text" name="locality_remark" class="data-entry-textarea" placeholder="Locality Remark"/></textarea></div><button href="javascript:void(0);" arial-label="remove" class="btn addCoord float-right data-entry-button remCoord"><i class="fas fa-times"></i></button></div>');
	});
	$("##customCoord").on('click','.remCoord',function(){$(this).parent().remove();});
});

	//this is from https://stackoverflow.com/questions/16183231/jquery-append-and-remove-dynamic-table-row  
$(document).ready(function(){
	$(".addSciName").click(function(){$("##customSciName").append('<div class="row my-3 bg-light py-3"><label for="sci_name" class="data-entry-label col-sm-3 text-center text-md-right px-0">Scientific Name</label><div class="col-12 col-lg-9"><input type="text" class="data-entry-input" name="sci_name" placeholder="Scientific Name"></div><label for="ID_made_by" class="data-entry-label col-sm-3 text-center text-md-right px-0">ID Made By</label><div class="col-12 col-lg-9"><input type="text" class="data-entry-input" name="made_by" placeholder="ID Made By"></div><div class="col-12 row mx-0 px-0"><label for="nature_of_id" class="data-entry-label col-lg-3 text-center text-xl-right px-0">Nature of ID</label><div class="col-12 col-lg-4 pr-xl-0"><select class="data-entry-select" required=""><option value="">Expert ID</option><option value="1">Field ID</option><option value="2">Non-Expert ID</option><option value="3">Curatorial ID</option></select></div><div class="col-12 col-lg-5"><input type="text" name="date_of_id" class="data-entry-input" placeholder="Date of ID"></div></div><label for="id_remark" class="data-entry-label col-sm-3 text-center text-md-right px-0">ID Remark</label><div class="col-12 col-sm-8"><textarea type="text" name="ID_remark" class="data-entry-textarea" placeholder="ID Remark"/></textarea></div><button href="javascript:void(0);" arial-label="remove" class="btn data-entry-button addSciName float-right remSciName"><i class="fas fa-times"></i></button></div>');
	});
	$("##customSciName").on('click','.remSciName',function(){$(this).parent().remove()});
});

	//this is from https://stackoverflow.com/questions/16183231/jquery-append-and-remove-dynamic-table-row  
$(document).ready(function(){
	$(".addPart").click(function(){$("##customPart").append('<div class="row mt-2" id="customPartAtt"><label for="part_name" class="data-entry-label col-sm-3 text-center text-md-right px-0">Part Name</label><div class="col-12 col-lg-9"><input type="text" class="data-entry-input" name="part_name" placeholder="Part Name"></div><label for="other_id" class="data-entry-label col-sm-3 text-center text-md-right px-0">Preserve Method</label><div class="col-12 col-lg-9"><select class="data-entry-select" required><option value="">Ethanol</option><option value="1">RNALater</option><option value="2">DNA/RNA Shield</option><option value="3">Alcohol</option></select></div><label for="condition" class="data-entry-label col-sm-3 text-center text-md-right px-0">Condition</label><div class="col-12 col-lg-9"><input type="text" class="data-entry-input" name="condition" placeholder="Condition"></div><label for="disposition" class="data-entry-label col-sm-3 text-center text-md-right px-0">Disposition</label><div class="col-12 col-lg-9"><select class="data-entry-select" required><option value="">Being Processed</option><option value="1">deaccessioned</option><option value="2">in collection</option><option value="3">missing</option></select></div><div class="col-12 row mx-0 px-0"><label for="part_number" class="data-entry-label col-lg-3 text-center text-xl-right px-0">## of Parts</label><div class="col-12 col-lg-4"><select class="data-entry-select" required=""><option value="">Modifier</option><option value="1">ca.</option><option value="2">&gt;</option><option value="3">&lt;</option></select></div><div class="col-12 col-lg-5"><input type="text" name="part_number" class="data-entry-input" placeholder="Number of Parts"></div></div><label for="container_unique_id" class="data-entry-label col-sm-3 text-center text-md-right px-0">Container</label><div class="col-12 col-lg-9"><input type="text" class="data-entry-input" name="container_unique_id" placeholder="Container Unique ID"></div><label for="part_remark" class="data-entry-label col-sm-3 text-center text-md-right px-0">Remark</label><div class="col-12 col-lg-8"><textarea type="text" name="part_remark" class="data-entry-textarea" placeholder="Part Remark"/></textarea></div><button href="javascript:void(0);" arial-label="remove" class="btn data-entry-button addPart float-right remPart"><i class="fas fa-times"></i></button></div>');
	});
	$("##customPart").on('click','.remPart',function(){$(this).parent().remove();});
});

	//this is from https://stackoverflow.com/questions/16183231/jquery-append-and-remove-dynamic-table-row  
$(document).ready(function(){
	$(".addAtt").click(function(){$("##customAtt").append('<div class="row mt-3"><label for="attribute_name" class="data-entry-label col-sm-3 text-center text-md-right px-0">Attribute Type</label><div class="col-12 col-lg-9"><input type="text" class="data-entry-input" name="attribute" placeholder="Attribute Type"></div><div class="col-12 row mx-0 px-0"><label for="part_number" class="data-entry-label col-lg-3 text-center text-xl-right px-0">Attribute Value</label><div class="col-12 col-lg-5"><input type="text" name="attribute value" class="data-entry-input" placeholder="Attribute Value"></div><div class="col-12 col-lg-4"><select class="data-entry-select" required=""><option value="">Units</option><option value="1">Life Cycle Stage</option><option value="2">Citation</option><option value="3">Host</option></select></div></div><label for="date" class="data-entry-label col-sm-3 text-center text-md-right px-0">Date</label><div class="col-12 col-lg-9"><input type="text" class="data-entry-input" name="date" placeholder="Date"></div><label for="determiner" class="data-entry-label col-sm-3 text-center text-md-right px-0">Determiner</label><div class="col-12 col-lg-9"><input type="text" class="data-entry-input" name="determiner" placeholder="Determiner"></div><label for="method" class="data-entry-label col-sm-3 text-center text-md-right px-0">Method</label><div class="col-12 col-lg-9"><input type="text" class="data-entry-input" name="method" placeholder="Method"></div><label for="attribute_remark" class="data-entry-label col-sm-3 text-center text-md-right px-0">Remark</label><div class="col-12 col-lg-9"><textarea type="text" name="attribute_remark" class="data-entry-textarea" placeholder="Attribute Remark"/></textarea></div><button href="javascript:void(0);" arial-label="remove" class="btn btn-primary addAtt btn-sm loginButtons rounded ml-3 mr-auto remAtt">Remove</button></div>');
	});
	$("##customAtt").on('click','.remAtt',function(){$(this).parent().remove();});
	});

	//this is from https://stackoverflow.com/questions/16183231/jquery-append-and-remove-dynamic-table-row  
$(document).ready(function(){
	$(".addPartAtt").click(function(){$("##customPartAtt").append('<div class="mt-2" id="partAtt"><label for="part_att_name" class="data-entry-label col-sm-3 text-center text-md-right px-0">Attribute Name</label><div class="col-12 col-lg-9"><input type="text" class="data-entry-input" name="part_att_name" placeholder="Part Attribute Name"></div><label for="part_att_value" class="data-entry-label col-sm-3 text-center text-md-right px-0">Value</label><div class="col-12 col-lg-9"><input type="text" class="data-entry-input" name="part_att_value" placeholder="Part Attribute Value"></div><label for="part_att_units" class="data-entry-label col-sm-3 text-center text-md-right px-0">Units</label><div class="col-12 col-lg-9"><input type="text" class="data-entry-input" name="part_att_units" placeholder="Part Attribute Units"></div><label for="part_att_determined_by" class="data-entry-label col-sm-3 text-center text-md-right px-0">Determined By</label><div class="col-12 col-lg-9"><input type="text" class="data-entry-input" name="part_att_determined_by" placeholder="Part Attribute Determined By"></div><label for="part_att_remark" class="data-entry-label col-sm-3 text-center text-md-right px-0">Attribute Remark</label><div class="col-12 col-lg-9"><textarea type="text" name="part_att_remark" class="data-entry-textarea" placeholder="Part Attribute Remark"/></textarea></div></div><button href="javascript:void(0);" arial-label="remove Part Att" class="btn btn-primary addPartAtt btn-sm loginButtons rounded ml-3 mr-auto remPartAtt">Remove</button></div>');
	});
	$("##customPartAtt").on('click','.remPartAtt',function(){$(this).parent().remove();});
});
		
$("##seeAnotherField").change(function() {
  if ($(this).val() == "yes") {
    $('##otherFieldDiv').show();
    $('##otherField').attr('required', '');
    $('##otherField').attr('data-error', 'This field is required.');
  } else {
    $('##otherFieldDiv').hide();
    $('##otherField').removeAttr('required');
    $('##otherField').removeAttr('data-error');
  }
});
$("##seeAnotherField").trigger("change");

$("##seeAnotherFieldGroup").change(function() {
  if ($(this).val() == "yes") {
    $('##otherFieldGroupDiv').show();
    $('##otherField1').attr('required', '');
    $('##otherField1').attr('data-error', 'This field is required.');
    $('##otherField2').attr('required', '');
    $('##otherField2').attr('data-error', 'This field is required.');
  } else {
    $('##otherFieldGroupDiv').hide();
    $('##otherField1').removeAttr('required');
    $('##otherField1').removeAttr('data-error');
    $('##otherField2').removeAttr('required');
    $('##otherField2').removeAttr('data-error');
  }
});
$("##seeAnotherFieldGroup").trigger("change");
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
<cfinclude template="/shared/_footer.cfm">
