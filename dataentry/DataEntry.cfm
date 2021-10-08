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
	body {
		background-color: #deebec;
	}
.tilt.right {
	transform: rotate(3deg);
	-moz-transform: rotate(3deg);
	-webkit-transform: rotate(3deg);
}
.tilt.left {
	transform: rotate(-3deg);
	-moz-transform: rotate(-3deg);
	-webkit-transform: rotate(-3deg);
}
.portlet {
	margin: 0 .25rem .25rem 0;
	padding: 0.3em;
}
.portlet-header {
	padding: 0.2em 0.3em;
	margin-bottom: 0.5em;
	position: relative;
}
.portlet-header span.ui-icon {
	margin-top:-9px;
}
.portlet-toggle {
	position: absolute;
	top: 50%;
	right: 0;
}
.portlet-content {
	padding: 0.4em;
}
.portlet-placeholder {
	border: 1px dotted black;
	margin: 0 1em 1em 0;
	height: 50px;
}
#d .data-entry-title{font-size: .76rem;}

.swapperBtnDiv {
	position:relative; 
	top: 8px; 
	left:15px;
}

@media (min-width: 768px) {
	.swapperBtnDiv {
		position:absolute; 
		top: 108px; 
		left:15px;
		z-index:3000;
	}
}
@media (min-width: 992px) {
	.swapperBtnDiv {
		position:absolute; 
		top: 108px; 
		left:15px;
		z-index:3000;
	}
}
@media (min-width: 1200px) {
	.swapperBtnDiv {
		position:absolute; 
		top: 102px; 
		left:15px;
		z-index:100;
	}
}
</style>

<cfoutput>
 <cfquery name="error_units" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select
		ctlat_long_error_units.lat_long_error_units
	from
		mczbase.ctlat_long_error_units
	order by lat_long_error_units asc
</cfquery>
 <cfquery name="collection_full_name" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select collection from ctcollections_full_names
</cfquery>
<cfquery name="otherIDType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select other_id_type from ctcoll_other_id_type
</cfquery>
<cfquery name="currRelations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select biol_indiv_relationship from ctbiol_relations where rel_type = 'curatorial'
</cfquery>
<cfquery name="biolRelations" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select biol_indiv_relationship from ctbiol_relations where rel_type = 'biological'
</cfquery>
<cfquery name="depthUnits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select depth_units from ctdepth_units
</cfquery>
<cfquery name="nature_of_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select nature_of_id from ctnature_of_id
</cfquery>
<cfquery name="nature_of_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select nature_of_id from ctnature_of_id
</cfquery>
<cfquery name="lat_long_units" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select orig_lat_Long_units from ctlat_long_units
</cfquery>
<cfquery name="obj_disp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select coll_obj_disposition from ctcoll_obj_disp
</cfquery>
<cfquery name="num_mod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select modifier from ctnumeric_modifiers
</cfquery>
<cfquery name="spec_preserv_method" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select preserve_method from ctspecimen_preserv_method
</cfquery>
<cfquery name="attType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select attribute_type from ctattribute_type
</cfquery>
<cfquery name="datum" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select datum from ctdatum
</cfquery>
<cfquery name="georefmeth" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select georefmethod from ctgeorefmethod
</cfquery>
<cfquery name="verifications" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select verificationstatus from ctverificationstatus
</cfquery>
	<div class="swapperBtnDiv" style="margin: 0 2rem;"> <a class="btn btn-xs btn-secondary" href="javascript:SwapDivsWithClick('swapper-first','swapper-other')">Switch Form</a> 
	</div>
<div class="container-fluid bg-light">
	<div class="container px-4 pt-0 mt-0" id="swapper-other" style="display:none;">
		<div class="row">
			<div class="col-12 justify-content-center mt-2 mx-auto">
				<form id="regForm" action="/DataEntry.cfm">
					<!-- One "tab" for each step in the form: -->
					<h1 class="text-center mb-2 mt-5 mt-md-2">Enter a New Record</h1>
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
						<h2 class="fs-title text-center">COLLECTOR/PREPARATOR</h2>
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
									<option value="">Units</option>
									<cfloop query="error_units">
										<option value="error_units.lat_long_error_units"></option>
									</cfloop>
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
								<select class="form-control border" required>
									<option value="">Units</option>
									<cfloop query="error_units">
										<option value="error_units.lat_long_error_units"></option>
									</cfloop>								
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
					<div class="my-4 text-center"> 
						<span class="step">1</span> <span class="step">2</span> <span class="step">3</span> <span class="step">4</span> <span class="step">5</span> <span class="step">6</span> <span class="step">7</span> <span class="step">8</span> <span class="step">9</span> 
					</div>
				</form>
			</div>
		</div>
	</div>

	<div class="container-fluid pt-1" id="swapper-first">
		<div class="row full">
			<h1 class="text-center my-3 w-100">Enter a New <span class="font-weight-bold text-info">#collection#</span> Record</h1>
			<div class="col-12 mt-0 pb-4">
				<form name="dataEntry" method="post" id="regFormAll" onsubmit="return cleanup(); return noEnter();" class="w-100" action="/DataEntry.cfm">
					<!-- One "tab" for each step in the form: -->
					<div class="col-12 col-md-4 px-0 column float-left">
						<div class="portlet shadow-none rounded-0 m-0 bg-blue-gray">
							<h2 class="portlet-header small90">SPECIMEN IDENTIFIERS</h2>
							<div class="portlet-content px-3">
								<div class="row mx-0">
									<div class="col-12 col-md-6 px-0 float-left">
										<div class="px-2 pb-1">
											<label for="cat_num" class="small font-weight-light float-left d-block mt-1 mb-0">Catalog Number</label>
											<input type="text" class="data-entry-input height1p2" id="cat_num" aria-describedby="catNumHelp" placeholder="Enter Catalog Number" name="cat_num">
											<small id="catNumHelp" class="form-text text-center text-muted">Must be unique for the collection</small>
										</div>
									</div>
									<div class="col-12 col-md-6 px-0 float-left">
										<div class="px-2 pb-1">
											<label for="accn" class="small font-weight-light float-left d-block mt-1 mb-0">Accession Number</label>
											<input type="text" class="data-entry-input height1p2" id="accn" aria-describedby="accnHelp" name="accn">
											<small id="accnHelp" class="form-text text-center text-muted">Should already exist in database</small>
										</div>
									</div>
									<div class="col-12 px-0 float-left">
										<div id="customOtherID">
										<a aria-label="Add another set of search criteria" class="btn btn-xs btn-primary addOtherID py-0 mt-2 mx-2" target="_self" href="javascript:void(0);"><i class="fa fa-plus"></i> Add Other ID</a>
										<div class="form-row mx-0 mb-2">
											
											<div class="col-12 col-md-6 float-left">
												<label for="other_id" class="small font-weight-light float-left d-block mt-1 mb-0">Other ID Type</label>
												<select class="data-entry-select mt-1 smallselect height1p2">
													<option value="">Other ID Type</option>
													<cfloop query="otherIDType">
														<option value="#otherIDType.other_id_type#">#otherIDType.other_id_type#</option>
													</cfloop>
												</select>
											</div>
											<div class="col-12 col-md-6 float-left">
												<label for="other_id" class="small font-weight-light float-left d-block mt-1 mb-0">Other ID</label>
												<input type="text" class="data-entry-input height1p2" id="other_id" name="other_id">
											</div>
											<div class="col-12 col-md-6 float-left">
								<!---				<label for="other_id" class="small font-weight-light float-left d-block mt-1 mb-0">Other ID</label>--->
												<select class="data-entry-select mt-1 smallselect height1p2">
													<option value="">Other ID Type</option>
													<cfloop query="otherIDType">
														<option value="#otherIDType.other_id_type#">#otherIDType.other_id_type#</option>
													</cfloop>
												</select>
											</div>
											<div class="col-12 col-md-6 float-left">
								<!---				<label for="other_id" class="small font-weight-light float-left d-block mt-1 mb-0">Other ID</label>--->
												<input type="text" class="data-entry-input mt-1 height1p2" id="other_id" name="other_id">
											</div>
										</div>
									</div>
									</div>
								</div>
							</div>
						</div>
						<div class="portlet shadow-none rounded-0 m-0 bg-blue-gray">
							<h2 class="portlet-header small90">IDENTIFICATION</h2>
							<div class="portlet-content px-3">
								<div class="form-row mx-0">
									<div id="customSciName">
									<a aria-label="Add another set of search criteria" class="btn btn-xs btn-primary addSciName py-0 m-0" target="_self" href="javascript:void(0);"><i class="fa fa-plus"></i> Add Identification</a>
									<div class="form-row mx-0 my-2">
										<label for="scientific_name" class="small col-12 col-md-2 font-weight-light float-left d-block mt-1 mb-0">Identification</label>
										<input type="text" name="scientific_name" class="col-12 col-md-10 mt-1 pl-0 float-left data-entry-input height1p2"/>
										<label for="made_by" class="small font-weight-light col-12 col-md-2 float-left d-block mt-1 mb-0">ID Made By</label>
										<input type="text" name="made_by" class="col-12 col-md-10 mt-1 pl-0 float-left data-entry-input height1p2"/>
										<div class="col-12 col-md-6 px-0 mt-1">
											<label for="nature_of_id" class="small font-weight-light col-12 col-md-4 px-1 float-left d-block mt-1 mb-0">Nature of ID</label>
											<select class="data-entry-select smallselect col-12 col-md-7 pl-0 float-left height1p2">
												<option value="">Nature of ID</option>
												<cfloop query="nature_of_id">
													<option value="#nature_of_id.nature_of_id#">#nature_of_id.nature_of_id#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-6 px-0 mt-1">
											<label for="made_by_date" class="small font-weight-light col-12 col-md-3 px-1 float-left d-block mt-1 mb-0">Date of ID</label>
											<input type="text" name="made_by_date" class="col-12 col-md-9 float-left data-entry-input height1p2"/>
										</div>
										<label for="id_remark" class="small font-weight-light col-12 col-md-2 float-left d-block mt-1 mb-0">ID Remark</label>
										<textarea type="text" name="id_remark" rows="1" class="col-12 col-md-10 mt-1 float-left data-entry-textarea"/></textarea>
									</div>
								</div>
							</div>
						</div>
					</div>
					</div>
					<div class="col-12 col-md-4 px-0 column float-left">
						<div class="portlet shadow-none rounded-0 m-0 bg-blue-gray">
							<h2 class="portlet-header small90" id="col_collector">COLLECTOR OR PREPARATOR</h2>
							<div class="portlet-content bg-blue-gray px-3">
								<div class="form-row mx-0">
									<div class="col-12 px-0">
										<div id="customAgent1">
											<a aria-label="Add another set of search criteria" class="btn btn-xs btn-primary py-0 addAgent1 m-0" target="_self" href="javascript:void(0);"> <i class="fa fa-plus"></i> Add Agent</a> 
											<div class="form-row mx-0">
												<div class="col-12 col-xl-6 float-left">
													<label for="collector_role" class="small font-weight-light float-left d-block mt-1 mb-0">Agent Role</label>
													<select class="data-entry-select smallselect height1p2" required>
												
														<option value="c" required>Collector</option>
														<option value="p">Preparator</option>
													</select>
												</div>
												<div class="col-12 col-xl-6 float-left">
													<label for="agent_name" class="small font-weight-light float-left d-block mt-1 mb-0">Agent Name</label>
													<input type="text" class="data-entry-input height1p2" required  name="agent_name">
												</div>
											</div>
											<div class="form-row mx-0 my-2">
												<div class="col-12 col-xl-6 float-left">
													<select class="data-entry-select smallselect height1p2" required>
														<option value="">Agent Role</option>
														<option value="c">Collector</option>
														<option value="p">Preparator</option>
													</select>
												</div>
												<div class="col-12 col-xl-6 float-left">
													<input type="text" class="data-entry-input height1p2"  name="agent_name">
												</div>
											</div>
										</div>
									</div>
								</div>
							</div>
						</div>
						<div class="portlet shadow-none bg-blue-gray m-0">
							<h2 class="portlet-header small90">COLLECTING EVENT</h2>
							<div class="portlet-content px-3">
								<div class="form-row mx-0">
									<div class="col-12 px-0">
									<div id="customSciName">
										<div class="form-row mx-0 mb-2">
											<h5 class="mb-0 font-weight-bold text-center mt-0 d-block w-100">
												<label for="collecting_event_id" class="">Use Collecting Event ID only</label>
											</h5>
											<input type="text" name="collecting_event_id" class="data-entry-input col-5 mx-auto height1p2" placeholder="Collecting Event ID" />
											<span class="small w-100 float-left text-center mt-2">- OR - </span>
											<h5 class="font-weight-bold text-left mb-1 d-block w-100">New Collecting Event</h5>
										
											<label for="verbatim_locality" class="small font-weight-light col-12 col-md-3 px-0 float-left d-block mt-1 mb-0">Verbatim Locality</label>
											<input type="text" name="verbatim_locality mt-0" class="data-entry-input height1p2 col-12 col-md-9 px-0 float-left"/>
											
											<div class="col-12 col-md-5 px-0 mt-1 float-left">
												<label for="inputPassword3" class="small font-weight-light col-12 col-md-5 pl-0 float-left d-block mt-1 mb-0">Verbatim Date</label>
												<input type="text" class="data-entry-input col-12 col-md-7 pl-0 mt-0 height1p2" id="verbatim_date">
											</div>
											<div class="col-12 col-md-7 pr-0 mt-1 float-left">
												<label for="inputPassword3" class="small font-weight-light col-12 col-md-4 float-left d-block mt-1 mb-0 text-right">ISO Dates</label>
												<input type="text" class="data-entry-input col-12 col-md-4 float-left mt-0 height1p2" id="began_date" placeholder="Began Date">
												<input type="text" class="data-entry-input col-12 col-md-4 float-left mt-0 height1p2" id="ended_date" placeholder="Date Ended">
											</div>
										
											<div class="col-12 col-md-4 pl-0 mt-1 float-left">
												<label for="inputPassword3" class="small font-weight-light col-12 col-md-3 px-0 float-left d-block mt-1 mb-0">Time</label>
												<input type="text" class="data-entry-input mt-0 height1p2 col-12 col-md-8" id="collecting_time">
											</div>
											<div class="col-12 col-md-8 float-left pr-0 mt-1">
												<label for="start_end_dayOfyear" class="small font-weight-light col-12 col-md-2 px-0 float-left d-block mt-1 mb-0">Day of Year</label>
												<input type="text" class="data-entry-input float-left col-12 col-md-5 mt-0 height1p2" id="start_day_of_year" placeholder="Start Day of Year">
												<input type="text" class="data-entry-input float-left col-12 col-md-5 mt-0 height1p2" id="end_day_of_year" placeholder="End Day of Year">
											</div>
											<div class="col-12 px-0 float-left">
												<div class="col-12 col-md-6 px-0 float-left">
													<label for="collecting_source_method" class="small font-weight-light float-left d-block mt-1 mb-0">Source</label>
													<input type="text" class="data-entry-input mt-0 height1p2" id="collecting_source">
												</div>
												<div class="col-12 col-md-6 px-0 float-left">
													<label for="collecting_source_method" class="small font-weight-light float-left d-block mt-1 mb-0">Method</label>
													<input type="text" class="data-entry-input mt-0 height1p2" id="collecting_method">
												</div>
											</div>
											<label for="Habitat" class="small font-weight-light float-left d-block mt-1 mb-0">Habitat</label>
											<input type="text" name="habitat_desc" class="data-entry-input mt-0 height1p2"/>
											<label for="microhabitat" class="small font-weight-light float-left d-block mt-1 mb-0">Microhabitat</label>
											<input type="text" name="habitat" class="data-entry-input mt-0 height1p2"/>
											<label for="locality_remark" class="small font-weight-light float-left d-block mt-1 mb-0">Collecting Remark</label>
											<textarea type="text" name="locality_remark" class="data-entry-textarea mt-0"/>
											</textarea>
											<div class="col-12 px-0">
												<label for="coll_number_series" class="small font-weight-light float-left w-100 d-block mt-1 mb-0">Collecting Event Number Series</label>
												<input type="text" class="data-entry-input col-12 col-xl-8 float-left height1p2" id="coll_number_series" placeholder="Existing Series">
												<div class="col-12 col-xl-4 border-transparent float-left ">
													<a class="infoLink height1p2" href="/vocabularies/CollEventNumberSeries.cfm?action=new" target="_blank">Add New Series</a>
												</div>
											</div>
											<label for="Coord. System" class="small font-weight-light float-left d-block mt-1 mb-0">Verbatim SRS or Datum</label>
											<input type="text" class="data-entry-input height1p2" id="Datum">
											<label for="lat_long" class="small font-weight-light float-left d-block mt-1 mb-0">Verbatim Latitude</label>
											<input type="text" class="data-entry-input height1p2" id="latitude">
											<label for="lat_long" class="small font-weight-light float-left d-block mt-1 mb-0">Verbatim Longitude</label>
											<input type="text" class="data-entry-input height1p2" id="longitude">
										</div>
									</div>
								</div>
								</div>
							</div>
						</div>
						<div class="portlet shadow-none m-0 bg-blue-gray">
							<h2 class="portlet-header small90">LOCALITY</h2>
							<div class="portlet-content px-3 pb-3">
								<div class="form-row mx-0">
									<div id="customSciName">
										<div class="form-row mx-0 my-0">
											<h5 class="mb-0 font-weight-bold text-center mt-0 d-block w-100">
												<label for="locality_id" class="">Use Locality ID only</label>
											</h5>
											<input type="text" name="locality_id" class="data-entry-input col-5 mb-0 mx-auto height1p2" placeholder="Locality ID" />
											<span class="small w-100 float-left text-center mt-0">- OR - </span>
											<h5 class="font-weight-bold text-left mb-0 d-block w-100">New Locality</h5>
											<label for="higher_geog" class="small font-weight-light float-left d-block mt-1 mb-0">Higher Geography</label>
											<input type="text" name="higher_geog" class="data-entry-input height1p2" placeholder="Higher Geography" />
											<label for="spec_locality" class="small font-weight-light float-left d-block mt-1 mb-0">Specific Locality</label>
											<input type="text" name="spec_locality" class="data-entry-input height1p2" placeholder="Specific Locality" />
											<div class="col-12 px-0">
												<label for="inputMinElev" class="small font-weight-light col-12 px-0 float-left d-block mt-1 mb-0">Elevation</label>
												<input type="text" class="data-entry-input col-12 col-xl-4 float-left height1p2" id="inputMinElev" placeholder="Min Elevation">
												<input type="text" class="data-entry-input col-12 col-xl-4 float-left height1p2" id="inputMaxElev" placeholder="Max Elevation">
												<select class="data-entry-select col-12 col-xl-4 smallselect height1p2">
													<option value="">Units</option>
													<cfloop query="depthUnits">
														<option value="#depthUnits.depth_units#">#depthUnits.depth_units#</option>
													</cfloop>
												</select>
											</div>
											<div class="col-12 px-0">
												<label for="inputMinDepth" class="small font-weight-light float-left col-12 px-0 d-block mt-1 mb-0">Depth</label>
												<input type="text" class="data-entry-input col-12 col-xl-4 float-left height1p2" id="inputMinDepth" placeholder="Min Depth">
												<input type="text" class="data-entry-input col-12 col-xl-4 float-left height1p2" id="inputMaxDepth" placeholder="Max Depth">
												<select class="data-entry-select col-12 col-xl-4 smallselect height1p2">
													<option value="">Units</option>
													<cfloop query="depthUnits">
														<option value="#depthUnits.depth_units#">#depthUnits.depth_units#</option>
													</cfloop>
												</select>
											</div>
											<label for="sovereign_nation" class="small font-weight-light float-left d-block mt-1 mb-0">Sovereign Nation</label>
											<input type="text" name="sovereign_nation" class="data-entry-input height1p2" placeholder="Sovereign Nation" />
											<label for="higher_geog" class="small font-weight-light float-left d-block mt-1 mb-0">Geology Attribute</label>
											<input type="text" name="geology_attribute" class="data-entry-input height1p2" placeholder="Geology Attribute" />
											<label for="habitat" class="small font-weight-light float-left d-block mt-1 mb-0">Habitat</label>
											<input type="text" name="habitat" class="data-entry-input height1p2" placeholder="Habitat" />
											<label for="locality_remark" class="small font-weight-light float-left d-block mt-1 mb-0">Locality Remark</label>
											<textarea type="text" name="locality_remark" class="data-entry-textarea" placeholder="Locality Remark"/></textarea>
										</div>
									</div>
								</div>
							</div>
						</div>
						<div class="portlet shadow-none m-0 bg-blue-gray">
							<h2 class="portlet-header small90">COORDINATES</h2>
							<div class="portlet-content px-3 pb-3">
								<div class="form-row mx-0">
									<div id="customSciName">
										<div class="bg-light border rounded px-2 pb-2"> 
											<div class="form-row mx-0 my-2">
												<label for="Coord. System" class="sr-only">Coordinate System</label>
												<select name="orig_lat_long_units" title="ORIG_LAT_LONG_UNITS" id="orig_lat_long_units" class="data-entry-select smallselect height1p2">
													<option value="dec_lat_long">Decimal Degrees</option>
													<option value="dec_min_sec">Degrees Minutes Seconds</option>
													<option value="deg_decmin">Degrees Decimal Degrees</option>
													<option value="unknown">Unknown</option>
												</select>
												<!--- dec lat/long--->
												<div class="row mx-0 choose dec_lat_long box mt-2">
													<div id="dec_lat_long" class="col-12 border px-1 pb-1 rounded" style="background-color: aliceblue">
														<div class="float-left col-12 col-xl-6 px-0">
															<label for="dec_lat" class="small font-weight-light float-left d-block mt-1 mb-0">Decimal Latitude</label>
															<input type="text" name="dec_lat" class="data-entry-input height1p2"/>
														</div>
														<div class="float-left col-12 col-xl-6 px-0">
															<label for="dec_long" class="small font-weight-light float-left d-block mt-1 mb-0">Decimal Longitude</label>
															<input type="text" name="dec_long" class="data-entry-input height1p2"/>
														</div>
													</div>
												</div>
											</div>

											<!--- deg/min/sec--->
											<div class="row mx-0 mt-2 dec_min_sec box" id="dec_min_sec" style="display:none;">
												<div class="col-12 px-1 pb-1 border rounded float-left" style="background-color: aliceblue">
													<h5 class="small font-weight-bold d-block mt-2 float-left mb-0 w-100"> Deg. Min. Sec. Latitude</h5>
													<div class="float-left col-12 col-md-3 px-0">
														<label for="lat_deg" class="small font-weight-light d-block mt-1 mb-0">Degrees</label>
														<input type="text" name="lat_deg" id="lat_deg" class="data-entry-input height1p2"/>
													</div>
													<div class="float-left col-12 col-md-3 px-0">
														<label for="lat_deg" class="small font-weight-light d-block mt-1 mb-0">Minutes</label>
														<input type="text" name="lat_deg" id="lat_deg" class="data-entry-input height1p2"/>
													</div>
													<div class="float-left col-12 col-md-3 px-0">
														<label for="lat_sec" class="small font-weight-light mt-1 mb-0">Seconds</label>
														<input type="text" name="lat_sec" class="data-entry-input height1p2"/>
													</div>
													<div class="float-left col-12 col-md-3 px-0">
														<label for="lat_dir" class="small font-weight-light float-left d-block mt-1 mb-0">Direction</label>
														<input type="text" name="lat_dir" class="data-entry-input height1p2"/>
													</div>								
													<h5 class="small font-weight-bold d-block mt-2 float-left mb-0 w-100">Deg. Min. Sec. Longitude</h5>
													<div class="float-left col-12 col-md-3 px-0">
														<label for="long_deg" class="small font-weight-light d-block mt-1 mb-0">Degrees</label>
														<input type="text" name="lat_deg" class="data-entry-input height1p2"/>
													</div>
													<div class="float-left col-12 col-md-3 px-0">
														<label for="long_min" class="small font-weight-light float-left d-block mt-1 mb-0">Minutes</label>
														<input type="text" name="lat_min" class="data-entry-input height1p2"/>
													</div>
													<div class="float-left col-12 col-md-3 px-0">
														<label for="long_sec" class="small font-weight-light float-left d-block mt-1 mb-0">Seconds</label>
														<input type="text" name="lat_sec" class="data-entry-input height1p2"/>
													</div>
													<div class="float-left col-12 col-md-3 px-0">
														<label for="long_dir" class="small font-weight-light float-left d-block mt-1 mb-0">Direction</label>
														<input type="text" name="long_dir" class="data-entry-input height1p2"/>
													</div>
												</div>
											</div>
											<!--- deg dec min dir--->
											<div class="row mx-0 mt-2 deg_decmin box" id="deg_decmin" style="display: none;">
												<div class="col-12 px-1 pb-1 border rounded float-left" style="background-color: aliceblue">
													<h5 class="small font-weight-bold d-block mt-2 float-left mb-0 w-100"> Deg. Decimal Min. Latitude</h5>
													<div class="float-left col-12 col-md-4 px-0">
														<label for="lat_deg" class="small font-weight-light d-block mt-1 mb-0">Degrees</label>
														<input type="text" name="lat_deg" id="lat_deg" class="data-entry-input height1p2"/>
													</div>
													<div class="float-left col-12 col-md-4 px-0">
														<label for="lat_deg" class="small font-weight-light d-block mt-1 mb-0">Dec. Min.</label>
														<input type="text" name="lat_deg" id="lat_deg" class="data-entry-input height1p2"/>
													</div>
													<div class="float-left col-12 col-md-4 px-0">
														<label for="lat_dir" class="small font-weight-light float-left d-block mt-1 mb-0">Direction</label>
														<input type="text" name="lat_dir" class="data-entry-input height1p2"/>
													</div>								
													<h5 class="small font-weight-bold d-block mt-2 float-left mb-0 w-100">Deg. Decimal Min. Longitude</h5>
													<div class="float-left col-12 col-md-4 px-0">
														<label for="long_deg" class="small font-weight-light d-block mt-1 mb-0">Degrees</label>
														<input type="text" name="lat_deg" class="data-entry-input height1p2"/>
													</div>
													<div class="float-left col-12 col-md-4 px-0">
														<label for="long_min" class="small font-weight-light float-left d-block mt-1 mb-0">Dec. Min.</label>
														<input type="text" name="lat_min" class="data-entry-input height1p2"/>
													</div>
													<div class="float-left col-12 col-md-4 px-0">
														<label for="long_dir" class="small font-weight-light float-left d-block mt-1 mb-0">Direction</label>
														<input type="text" name="long_dir" class="data-entry-input height1p2"/>
													</div>
												</div>
											</div>
											<!--- unknown --->
											<div class="row mx-0 unknown box mt-2" id="unknown" style="display:none;"></div>
										</div>
									</div>
											<div class="col-12 px-0">
												<label for="higher_geog" class="small font-weight-light float-left d-block mt-1 col-12 px-0 mb-0">Max Error</label>
												<input type="text" name="max_error_distance" id="max_error_distance" class="data-entry-input col-8 col-md-7 float-left height1p2" />
												<select class="data-entry-select col-4 col-md-5 float-left smallselect height1p2" required>
													<option value="">Units</option>
													<cfloop query="error_units">
														<option value="#error_units.lat_long_error_units#">#error_units.lat_long_error_units#</option>
													</cfloop>
												</select>
											</div>
											<div class="col-12 mt-2 border bg-light rounded p-1">
												<label for="" class="small font-weight-light float-left col-12 text-xl-right col-xl-4 d-block pl-0 pr-2 mt-1 mb-0">Determiner</label>
												<input type="text" name="" class="data-entry-input mt-1 float-left col-12 col-xl-8 height1p2" id=""/>
												<label for="" class="small font-weight-light float-left text-xl-right pr-2 col-12 col-xl-4 d-block pl-0 mt-1 mb-0">Date</label>
												<input type="text" class="data-entry-input mt-1 float-left col-12 col-xl-8 height1p2" id="">
											</div>
												<label for="datum" class="small font-weight-light float-left d-block mt-1 mb-0">Geodetic Datum or SRS</label>
												<select class="data-entry-select col-12 px-0 float-left" required>
													<option value="">Datum or SRS</option>
													<cfloop query="datum">
														<option value="#datum.datum#">#datum.datum#</option>
													</cfloop>
												</select>
												<label for="" class="small font-weight-light float-left d-block mt-1 mb-0">Georeference Method</label>
												<select class="data-entry-select col-12 px-0 float-left smallselect height1p2" required>
													<option value="">Method</option>
													<cfloop query="georefmeth">
														<option value="#georefmeth.georefmethod#">#georefmeth.georefmethod#</option>
													</cfloop>
												</select>
												<label for="" class="small font-weight-light float-left d-block mt-1 mb-0">Extent</label>
												<input type="text" name="" class="data-entry-input height1p2"/>
												<label for="" class="small font-weight-light float-left d-block mt-1 mb-0">GPS Accuracy</label>
												<input type="text" name="" class="data-entry-input height1p2"/>
												<label for="" class="small font-weight-light float-left d-block mt-1 mb-0">Verification Status</label>
												<select class="data-entry-select col-12 px-0 float-left smallselect height1p2" required>
													<option value="">Status </option>
													<cfloop query="verifications">
														<option value="#verifications.verificationstatus#">#verifications.verificationstatus#</option>
													</cfloop>
												</select>
												<label for="" class="small font-weight-light float-left d-block mt-1 mb-0">GPS Accuracy</label>
												<input type="text" name="" class="data-entry-input height1p2"/>
												<label for="" class="small font-weight-light float-left d-block mt-1 mb-0">Coordinate Remarks</label>
												<textarea type="text" name="remarks" class="data-entry-textarea"/></textarea>
												<label for="" class="small font-weight-light float-left d-block mt-1 mb-0">Reference</label>
												<input type="text" name="" class="data-entry-input height1p2"/>
										</div>
	<script>
	$(document).ready(function(){
		$("select").change(function(){
			$( "select option:selected").each(function(){
				if($(this).attr("value")=="dec_lat_long"){
					$(".box").hide();
					$(".dec_lat_long").show();
				}
				if($(this).attr("value")=="dec_min_sec"){
					$(".box").hide();
					$(".dec_min_sec").show();
				}
				if($(this).attr("value")=="deg_decmin"){
					$(".box").hide();
					$(".deg_decmin").show();
				}
				if($(this).attr("value")=="unknown"){
					$(".box").hide();
					$(".unknown").show();
				}
			});
		}).change();
	});	
	</script>



										</div>
						</div>
					</div>
					<div class="col-12 col-md-4 px-0 column float-left">
						<div class="portlet shadow-none m-0 bg-blue-gray">
							<h2 class="portlet-header small90">PARTS</h2>
							<div class="portlet-content px-3">
								<div id="customPart">
									<a aria-label="Add another set of search criteria" class="btn btn-xs btn-primary addPart py-0 m-0" target="_self" href="javascript:void(0);"><i class="fa fa-plus"></i> Add Part</a>
									<div class="form-row mx-0 my-2">
										<label for="part_name" class="small font-weight-light float-left d-block mt-1 mb-0">Part Name</label>
										<input type="text" class="data-entry-input" name="part_name">
										<label for="preserv_method" class="small font-weight-light float-left d-block mt-1 mb-0">Preserve Method</label>
											<select class="data-entry-select">
												<option value="">Preserve Method</option>
												<cfloop query="spec_preserv_method">
													<option value="#spec_preserv_method.preserve_method#">#spec_preserv_method.preserve_method#</option>
												</cfloop>
											</select>
										<label for="condition" class="small font-weight-light float-left d-block mt-1 mb-0">Condition</label>
										<input type="text" class="data-entry-input" name="condition">
										<label for="disposition" class="small font-weight-light float-left d-block mt-1 mb-0">Disposition</label>
											<select class="data-entry-select">
												<option value="">Disposition</option>
												<cfloop query="obj_disp">
													<option value="#obj_disp.coll_obj_disposition#">#obj_disp.coll_obj_disposition#</option>
												</cfloop>
											</select>							
										<label for="num_modifier" class="small font-weight-light float-left d-block mt-1 mb-0">## Modifier</label>
											<select class="data-entry-select" name="num_modifier">
												<option value="">Modifier </option>
												<cfloop query="num_mod">
													<option value="#num_mod.modifier#">#num_mod.modifier#</option>
												</cfloop>
											</select>
										<label for="part_number" class="small font-weight-light float-left d-block mt-1 mb-0">Number of Parts</label>
										<input type="text" name="part_number" class="data-entry-input">
										<label for="container_unique_id" class="small font-weight-light float-left d-block mt-1 mb-0">Container Unique ID</label>
										<input type="text" class="data-entry-input" name="container_unique_id">
										<label for="part_remark" class="small font-weight-light float-left d-block mt-1 mb-0">Part Remark</label>
										<textarea type="text" name="part_remark" class="data-entry-textarea"/></textarea>
									</div>
								</div>
							</div>
						</div>
						<div class="portlet shadow-none m-0 bg-blue-gray">
							<h2 class="portlet-header small90">ATTRIBUTES</h2>
							<div class="portlet-content px-3">
								<div class="form-row mx-0">
									<a aria-label="Add another set of search criteria" class="btn btn-xs btn-primary addAtt m-0 py-0" target="_self" href="javascript:void(0);"><i class="fa fa-plus"></i> Add Atrribute</a>
									<div id="customAtt">
										<div class="form-row mx-0 my-2">
											<select class="data-entry-select mt-1">
												<option value="">Attribute Type</option>
												<cfloop query="attType">
													<option value="#attType.attribute_type#">#attType.attribute_type#</option>
												</cfloop>
											</select>
											<label for="part_number" class="small font-weight-light float-left d-block mt-1 mb-0">Attribute Value</label>
											<input type="text" name="attribute value" class="data-entry-input">

											<label for="date" class="small font-weight-light float-left d-block mt-1 mb-0">Date</label>
											<input type="text" class="data-entry-input" name="date">
											<label for="determiner" class="small font-weight-light float-left d-block mt-1 mb-0">Determiner</label>
											<input type="text" class="data-entry-input" name="determiner">
											<label for="method" class="small font-weight-light float-left d-block mt-1 mb-0">Method</label>
											<input type="text" class="data-entry-input" name="method">
											<label for="attribute_remark" class="small font-weight-light float-left d-block mt-1 mb-0">Attribute Remark</label>
											<textarea type="text" name="attribute_remark" class="data-entry-textarea"/>
											</textarea>
										</div>
									</div>
								</div>
							</div>
						</div>
						<div class="portlet shadow-none m-0 bg-blue-gray">
							<h2 class="portlet-header small90">BIOLOGICAL RELATIONSHIPS</h2>
							<div class="portlet-content">
								<div class="form-row mx-0">
									<div id="customBiolRelations">
										<a aria-label="Add another set of search criteria" class="btn btn-xs btn-primary addBiolRelations py-0 m-0" target="_self" href="javascript:void(0);"><i class="fa fa-plus"></i> Add Relationship</a>
										<div class="form-row my-2 mx-0">

											<select class="data-entry-select mt-1">
												<option value="">Biological Relationship</option>
												<cfloop query="biolRelations">
													<option value="#biolRelations.biol_indiv_relationship#">#biolRelations.biol_indiv_relationship#</option>
												</cfloop>
											</select>
											<label for="relations" class="small font-weight-light float-left d-block mt-1 mb-0">Relationship Value</label>
											<input type="text" class="data-entry-input" id="relationship">
										</div>
									</div>
								</div>
							</div>
						</div>
						<div class="portlet shadow-none m-0 bg-blue-gray">
							<h2 class="portlet-header small90">CURATORIAL RELATIONSHIPS</h2>
							<div class="portlet-content">
								<div class="form-row mx-0">
									<div id="customCurRelations">
									<a aria-label="Add another set of search criteria" class="btn btn-xs btn-primary addCurRelations m-0 py-0" target="_self" href="javascript:void(0);"><i class="fa fa-plus"></i> Add Relationship</a>
									<div class="form-row mx-0 my-2">
										<label for="relations" class="sr-only">Relationship</label>
											<select class="data-entry-select mt-1">
												<option value="">Curatorial Relationship Type</option>
												<cfloop query="currRelations">
													<option value="#currRelations.biol_indiv_relationship#">#currRelations.biol_indiv_relationship#</option>
												</cfloop>
											</select>
										<label for="record number" class="small font-weight-light float-left d-block mt-1 mb-0">Related Record Number</label>
										<input type="text" class="data-entry-input" id="record_number">
									</div>
									</div>
								</div>
							</div>
						</div>
						<div class="portlet shadow-none m-0 bg-blue-gray">
							<h2 class="portlet-header small90">ENCUMBRANCE</h2>
							<div class="portlet-content">
								<label for="mask_record" class="float-left mt-2">Mask Record</label>
								<input class="float-left ml-2 mt-1" value="1" type="checkbox" id="gridCheck1">
								<!--<label class="form-check-label w-auto form-control-sm border-0 mt-0" for="gridCheck1"> Mask Record in Generic Encumbrance</label>--> 
								<small id="accnHelp" class="form-text float-left w-100 text-center text-muted">Puts it in a generic encumbrance.</small>
							</div>
						</div>
					</div>				
				</form>
			</div>
		</div>
	</div>

</div>
	<!---Step by step form for each section of the Data Entry form -- Form wizard--->

<script>
$( ".column" ).sortable({
    connectWith: ".column",
    handle: ".portlet-header",
    cancel: ".portlet-toggle",
    start: function (event, ui) {
        ui.item.addClass('tilt');
        tilt_direction(ui.item);
    },
    stop: function (event, ui) {
        ui.item.removeClass("tilt");
        $("html").unbind('mousemove', ui.item.data("move_handler"));
        ui.item.removeData("move_handler");
    }
});

function tilt_direction(item) {
    var left_pos = item.position().left,
        move_handler = function (e) {
            if (e.pageX >= left_pos) {
                item.addClass("right");
                item.removeClass("left");
            } else {
                item.addClass("left");
                item.removeClass("right");
            }
            left_pos = e.pageX;
        };
    $("html").bind("mousemove", move_handler);
    item.data("move_handler", move_handler);
}  

$( ".portlet" )
    .addClass( "ui-widget ui-widget-content ui-helper-clearfix ui-corner-all" )
    .find( ".portlet-header" )
    .addClass( "ui-widget-header ui-corner-all" )
    .prepend( "<span class='ui-icon ui-icon-minusthick portlet-toggle'></span>");

$( ".portlet-toggle" ).click(function() {
    var icon = $( this );
    icon.toggleClass( "ui-icon-minusthick ui-icon-plusthick" );
    icon.closest( ".portlet" ).find( ".portlet-content" ).toggle();
});
</script>
<script>
	//this is from https://stackoverflow.com/questions/16183231/jquery-append-and-remove-dynamic-table-row 
		
$(document).ready(function(){
	$(".addOtherID").click(function(){
		$("##customOtherID").append('<div class="form-row mx-0 my-2"><label for="other_id" class="sr-only">Other ID</label><select class="data-entry-select" required><option value="">Other ID Type</option><option value="1">Field Number</option><option value="2">Collector Number</option><option value="3">Previous Number</option></select><input type="text" class="data-entry-input"  name="other_id" placeholder="Other ID"><button href="javascript:void(0);" arial-label="remove" class="btn addOtherID p-0 m-0 float-left data-entry-button remOtherID" style="width:20px;"><i class="fas fa-times"></i></button></div>');
	});
		$("##customOtherID").on('click','.remOtherID',function(){$(this).parent().remove();});
	});

	//this is from https://stackoverflow.com/questions/16183231/jquery-append-and-remove-dynamic-table-row  
$(document).ready(function(){
	$(".addCurRelations").click(function(){$("##customCurRelations").append('<div class="form-row mx-0 my-2"><label for="relations" class="sr-only">Relationship</label><select class="data-entry-select"><option value="">Relationship Type</option><option value="1">Re-Cataloged as</option><option value="2">Bad Duplicate of</option><option value="3">Cloned from Record</option><option value="4">Duplicate Recataloged as</option></select><input type="text" class="data-entry-input" id="record_number" placeholder="Record Number"><button href="javascript:void(0);" arial-label="remove" class="btn addCurRelations data-entry-button float-left p-0 m-0 remCurRelations"><i class="fas fa-times"></i></button></div>');
	});
	$("##customCurRelations").on('click','.remCurRelations',function(){$(this).parent().remove();});
	});

	//this is from https://stackoverflow.com/questions/16183231/jquery-append-and-remove-dynamic-table-row  
$(document).ready(function(){
	$(".addBiolRelations").click(function(){$("##customBiolRelations").append('<div class="form-row my-2 mx-0"><label for="relations" class="sr-only">Relationship</label><select class="data-entry-select"><option value="">Relationship Type</option><option value="1">Same lot as</option><option value="2">Egg of</option><option value="3">Parent of</option><option value="4">In Nest</option></select><input type="text" class="data-entry-input" id="relationship" placeholder="Record Number"><button href="javascript:void(0);" arial-label="remove" class="btn addBiolRelations data-entry-button float-left p-0 m-0 remBiolRelations"><i class="fas fa-times"></i></button></div>');
	});
	$("##customBiolRelations").on('click','.remBiolRelations',function(){$(this).parent().remove();});
	});

	//this is from https://stackoverflow.com/questions/16183231/jquery-append-and-remove-dynamic-table-row  
//$(document).ready(function(){
//	$(".addAgent").click(function(){$("##customAgent").append('<div class="form-row mx-0 mt-2"><label for="agent_id" class="sr-only float-left">Agent as collector</label><select class="data-entry-select"><option value="">Collector</option><option value="1">Preparator</option></select><input type="text" class="data-entry-input" name="agent" placeholder="Value"></div><button href="javascript:void(0);" arial-label="remove" class="btn addAgent data-entry-button p-0 m-0 remAgent" style="width:20px;"><i class="fas fa-times"></i></button></div>');
//	});
//	$("##customAgent").on('click','.remAgent',function(){$(this).parent().remove();});
//});
	
$(document).ready(function(){
	$(".addAgent1").click(function(){
		$("##customAgent1").append('<div class="form-row mx-0 mt-1"><label for="agent_id" class="sr-only"></label><select class="data-entry-select" required><option value="0">Collector</option><option value="1">Preparator</option></select><input type="text" class="data-entry-input" name="agent_id" placeholder="Agent ID"><button href="javascript:void(0);" arial-label="remove" class="btn addAgent p-0 m-0 float-left data-entry-button remAgent1" style="width:20px;"><i class="fas fa-times"></i></button></div>');
	});
		$("##customAgent1").on('click','.remAgent1',function(){$(this).parent().remove();});
	});

	//this is from https://stackoverflow.com/questions/16183231/jquery-append-and-remove-dynamic-table-row  
$(document).ready(function(){
	$(".addCoord").click(function(){$("##customCoord").append('<div class="form-row mt-2"><label for="higher_geog" class="data-entry-label col-sm-3 text-center text-md-right pr-0">Coordinates Units</label><div class="col-sm-8 px-1"><select class="data-entry-select pr-0" required><option value="">Decimal Degrees</option><option value="1">Dec. Min. Secs.</option><option value="2">Degrees Dec. Minutes</option><option value="3">Unknown</option></select></div></div><div class="form-row"><label for="higher_geog" class="data-entry-label col-sm-3 text-center text-md-right pr-0">Maximumm Error</label><div class="col-12 col-sm-4 pl-1 pr-0"><input type="text" name="maximum_error" class="data-entry-input" placeholder="Maximum Error" /></div><div class="col-12 col-sm-4 px-1"><input type="text" class="data-entry-input pr-xl-0" placeholder="Error Units"></div></div><div class="form-row"><label for="extent" class="data-entry-label col-sm-3 text-center text-md-right pr-0">Extent</label><div class="col-sm-8 px-1"><input type="text" name="extent" class="data-entry-input" placeholder="Extent" /></div></div><div class="form-row"><label for="GPS_accuracy" class="data-entry-label col-sm-3 text-center text-md-right pr-0">GPS Accuracy</label><div class="col-sm-8 px-1"><input type="text" name="gps_accuracy" class="data-entry-input" placeholder="GPS Accuracy" /></div></div><div class="form-row"><label for="higher_geog" class="data-entry-label col-sm-3 text-center text-md-right pr-0">Datum</label><div class="col-sm-8 px-1"><select class="data-entry-select pr-0" required><option value="">NAD27</option><option value="1">POS</option><option value="2">GRA</option><option value="3">WGS84</option></select></div></div><div class="form-row"><label for="determiner" class="data-entry-label col-sm-3 text-center text-md-right pr-0">Determiner</label><div class="col-sm-8 px-1"><input type="text" name="determiner" class="data-entry-input" placeholder="Determiner"/></div></div><div class="form-row"><label for="date" class="data-entry-label col-sm-3 text-center text-md-right pr-0">Date</label><div class="col-sm-8 px-1"><input type="text" name="date" class="data-entry-input" placeholder="Date" /></div></div><div class="form-row"><label for="higher_geog" class="data-entry-label col-sm-3 text-center text-md-right pr-0">Georeference Meth.</label><div class="col-sm-8 px-1"><select class="data-entry-select pr-0" required><option value="">GeoLocate</option><option value="1">GPS</option><option value="2">Google Earth</option><option value="3">Gazetteer</option></select></div></div><div class="form-row"><label for="reference" class="data-entry-label col-sm-3 text-center text-md-right pr-0">Reference</label><div class="col-sm-8 px-1"><input type="text" name="reference" class="data-entry-input" placeholder="Reference" /></div></div><div class="form-row"><label for="locality_remark" class="data-entry-label col-sm-3 text-center text-md-right pr-0">Locality Remark</label><div class="col-12 col-xl-8 px-1"><textarea type="text" name="locality_remark" class="data-entry-textarea" placeholder="Locality Remark"/></textarea></div><button href="javascript:void(0);" arial-label="remove" class="btn addCoord float-right data-entry-button remCoord" style="width:20px;"><i class="fas fa-times"></i></button></div>');});						 
	$("##customCoord").on('click','.remCoord',function(){$(this).parent().remove();});
});

	//this is from https://stackoverflow.com/questions/16183231/jquery-append-and-remove-dynamic-table-row  
$(document).ready(function(){
	$(".addSciName").click(function(){$("##customSciName").append('<div class="form-row mx-0 my-2"><label for="scientific_name" class="sr-only">Scientific Name</label><input type="text" name="scientific_name" class="data-entry-input" placeholder="Scientific Name" /><label for="made_by" class="sr-only">ID Made By</label><input type="text" name="made_by" class="data-entry-input" placeholder="Identifier Name" /><label for="nature_of_id" class="sr-only">Nature of ID</label><select class="data-entry-select" required><option value="">Expert ID</option><option value="1">Field ID</option><option value="2">Non-Expert ID</option><option value="3">Curatorial ID</option></select><input type="text" name="made_by_date" class="data-entry-input" placeholder="Date of ID" /><label for="id_remark" class="sr-only">ID Remark</label><textarea type="text" name="id_remark" rows="1" class="data-entry-textarea" placeholder="ID Remark"/></textarea><button href="javascript:void(0);" arial-label="remove" class="btn float-right data-entry-button remSciName" style="width:20px;"><i class="fas fa-times"></i></button></div>');
	});
	$("##customSciName").on('click','.remSciName',function(){$(this).parent().remove()});
});

	//this is from https://stackoverflow.com/questions/16183231/jquery-append-and-remove-dynamic-table-row  
$(document).ready(function(){
	$(".addPart").click(function(){$("##customPart").append('<div class="form-row mx-0 my-2"><label for="part_name" class="sr-only">Part Name</label><input type="text" class="data-entry-input" name="part_name" placeholder="Part Name"><label for="other_id" class="sr-only">Preserve Method</label><select class="data-entry-select" required><option value="">Ethanol</option><option value="1">RNALater</option><option value="2">DNA/RNA Shield</option><option value="3">Alcohol</option></select><label for="condition" class="sr-only">Condition</label><input type="text" class="data-entry-input" name="condition" placeholder="Condition"><label for="disposition" class="sr-only">Disposition</label><select class="data-entry-select" required><option value="">Being Processed</option><option value="1">deaccessioned</option><option value="2">in collection</option><option value="3">missing</option></select><label for="part_number" class="sr-only">## of Parts</label><select class="data-entry-select" required=""><option value="">Modifier</option><option value="1">ca.</option><option value="2">&gt;</option><option value="3">&lt;</option></select><input type="text" name="part_number" class="data-entry-input" placeholder="Number of Parts"><label for="container_unique_id" class="sr-only">Container</label><input type="text" class="data-entry-input" name="container_unique_id" placeholder="Container Unique ID"><label for="part_remark" class="sr-only">Remark</label><textarea type="text" name="part_remark" class="data-entry-textarea" placeholder="Part Remark"/></textarea><button href="javascript:void(0);" arial-label="remove" class="btn float-right data-entry-button remPart" style="width:20px;"><i class="fas fa-times"></i></button></div>');
	});
	$("##customPart").on('click','.remPart',function(){$(this).parent().remove();});
});

	//this is from https://stackoverflow.com/questions/16183231/jquery-append-and-remove-dynamic-table-row  
$(document).ready(function(){
	$(".addAtt").click(function(){$("##customAtt").append('<div class="form-row mx-0 my-2"><label for="attribute_name" class="sr-only">Attribute Type</label><input type="text" class="data-entry-input" name="attribute" placeholder="Attribute Type"><label for="part_number" class="sr-only">Attribute Value</label><input type="text" name="attribute value" class="data-entry-input" placeholder="Attribute Value"><select class="data-entry-select" required=""><option value="">Units</option><option value="1">Life Cycle Stage</option><option value="2">Citation</option><option value="3">Host</option></select><label for="date" class="sr-only">Date</label><input type="text" class="data-entry-input" name="date" placeholder="Date"><label for="determiner" class="sr-only">Determiner</label><input type="text" class="data-entry-input" name="determiner" placeholder="Determiner"><label for="method" class="sr-only">Method</label><input type="text" class="data-entry-input" name="method" placeholder="Method"><label for="attribute_remark" class="sr-only">Remark</label><textarea type="text" name="attribute_remark" class="data-entry-textarea" placeholder="Attribute Remark"/></textarea><button href="javascript:void(0);" arial-label="remove" class="btn float-right data-entry-button remAtt" style="width:20px;"><i class="fas fa-times"></i></button></div>');
	});
	$("##customAtt").on('click','.remAtt',function(){$(this).parent().remove();});
	});

	//this is from https://stackoverflow.com/questions/16183231/jquery-append-and-remove-dynamic-table-row  
$(document).ready(function(){
	$(".addPartAtt").click(function(){$("##customPartAtt").append('<div class="form-row mx-0 my-2"><label for="part_att_name" class="data-entry-label col-sm-3 text-center text-md-right px-0">Attribute Name</label><div class="col-12 col-lg-9"><input type="text" class="data-entry-input" name="part_att_name" placeholder="Part Attribute Name"></div><label for="part_att_value" class="sr-only">Value</label><div class="col-12 col-lg-9"><input type="text" class="data-entry-input" name="part_att_value" placeholder="Part Attribute Value"></div><label for="part_att_units" class="data-entry-label col-sm-3 text-center text-md-right px-0">Units</label><div class="col-12 col-lg-9"><input type="text" class="data-entry-input" name="part_att_units" placeholder="Part Attribute Units"></div><label for="part_att_determined_by" class="data-entry-label col-sm-3 text-center text-md-right px-0">Determined By</label><div class="col-12 col-lg-9"><input type="text" class="data-entry-input" name="part_att_determined_by" placeholder="Part Attribute Determined By"></div><label for="part_att_remark" class="sr-only">Attribute Remark</label><textarea type="text" name="part_att_remark" class="data-entry-textarea" placeholder="Part Attribute Remark"/></textarea><button href="javascript:void(0);" arial-label="remove" class="btn float-right data-entry-button remPartAtt" style="width:20px;"><i class="fas fa-times"></i></button></div>');
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
	<script type="text/javascript">
function SwapDivsWithClick(multi_collector,col_collector)
{
   d3 = document.getElementById(multi_collector);
   d4 = document.getElementById(col_collector);
   if( d4.style.display == "none" )
   {
      d3.style.display = "none";
      d4.style.display = "block";
   }
   else
   {
      d3.style.display = "block";
      d4.style.display = "none";
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
