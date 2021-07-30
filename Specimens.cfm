<cfset pageTitle = "Search Specimens">
<!--
Specimens.cfm

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
<!--- **** Beging temporary block, to prevent Specimens.cfm from displaying on production before we are ready * --->
<!--- Delete this temporary block when Specimens.cfm is ready for production --->
<cftry>
	<!--- assuming a git repository and readable by coldfusion, determine the checked out branch by reading HEAD --->
	<cfset gitBranch = FileReadLine(FileOpen("#Application.webDirectory#/.git/HEAD", "read"))>
<cfcatch>
	<cfset gitBranch = "unknown">
</cfcatch>
</cftry>
<cfif findNoCase('redesign',gitBranch) EQ 0>
	<cfscript>
		getPageContext().forward("/SpecimenSearch.cfm");
	</cfscript>
</cfif>
<!--- **** End temporary block ******************************************************************************** --->
<cfinclude template = "/shared/_header.cfm">
<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
	<cfset isClicky = "likeLink">
	<cfelse>
	<cfset oneOfUs = 0>
	<cfset isClicky = "">
</cfif>

<cfoutput>
	<cfquery name="getCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT count(collection_object_id) as cnt FROM cataloged_item
</cfquery>
	<cfquery name="collSearch" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT
		collection.institution,
		collection.collection,
		collection.collection_id,
		collection.guid_prefix
	FROM
		collection
	ORDER BY collection.collection
</cfquery>
	<cfquery name="ctElevUnits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
select orig_elev_units from CTORIG_ELEV_UNITS
</cfquery>
	<cfquery name="ctDepthUnits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
select depth_units from ctDepth_Units
</cfquery>
	<cfquery name="ContOcean" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
select continent_ocean from ctContinent ORDER BY continent_ocean
</cfquery>
	<cfquery name="Country" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
select distinct(country) from geog_auth_rec order by country
</cfquery>
	<cfquery name="IslGrp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
select island_group from ctIsland_Group order by Island_Group
</cfquery>
	<cfquery name="Feature" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
select distinct(Feature) from geog_auth_rec order by Feature
</cfquery>
	<cfquery name="Water_Feature" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
select distinct(Water_Feature) from geog_auth_rec order by Water_Feature
</cfquery>
	<cfquery name="ctgeology_attribute"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
select attribute from geology_attribute_hierarchy group by attribute order by attribute
</cfquery>
	<cfquery name="ctgeology_attribute_val"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
select attribute_value from geology_attribute_hierarchy group by attribute_value order by attribute_value
</cfquery>
	<cfquery name="ctlat_long_error_units"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
select lat_long_error_units from ctlat_long_error_units group by lat_long_error_units order by lat_long_error_units
</cfquery>
	<cfquery name="ctverificationstatus"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
select verificationstatus from ctverificationstatus group by verificationstatus order by verificationstatus
</cfquery>
	<cfquery name="ctmedia_type" datasource="cf_dbuser" cachedwithin="#createtimespan(0,0,60,0)#">
select media_type from ctmedia_type order by media_type
</cfquery>
	<cfquery name="column_headers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
select column_name, data_type from all_tab_columns where table_name = 'FLAT' and rownum = 1
</cfquery>
<main>
	<section class="container-fluid pb-3 px-3" id="content" role="search">
		<div class="row">
			<div class="col-12 col-lg-11 mb-3">
				<h1 class="h3 smallcaps pl-1">Search Specimen Records <span class="count font-italic color-green mx-0"><small>(access to #getCount.cnt# records)</small></span> </h1>
				<div class="tabs card-header tab-card-header pb-0">
					<div class="tab-headers" role="tablist" aria-label="search panel tabs">
						<button class="px-5" id="tab-1" role="tab" tabindex="0" aria-controls="panel-1" aria-selected="true" >Keyword Search</button>
						<button class="px-5" id="tab-2" role="tab" tabindex="-1" aria-selected="panel-2" aria-selected="false">Search Builder</button>
						<button class="px-5" id="tab-3" role="tab" tabindex="-1" aria-selected="panel-3" aria-select="false">Custom Fixed Search</button>
					</div>
					<div class="tab-content"> 
					<!---Keyword Search--->
					<div id="panel-1" role="tabpanel" aria-labelledby="tab-1" class="py-3 mx-0">
						<form id="searchForm">
							<div class="col-12 col-md-12 col-lg-11 mt-2 pl-3">
								<div class="row">
									<div class="input-group mt-1 px-3">
										<div class="input-group-btn col-12 col-sm-4 col-md-3 pr-md-0">
											<label for="col-multi-select" class="sr-only">Collection</label>
											<select class="custom-select-sm bg-white multiselect2 w-100" name="col-multi-select" multiple="multiple" size="10" style="padding:.3em .5em">
												<cfloop query="collSearch">
													<option value="#collSearch.collection#"> #collSearch.collection# (#collSearch.guid_prefix#)</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-sm-5 col-md-6 px-md-0">
											<label for="searchText" class="sr-only">Keyword input field </label>
											<input id="searchText" type="text" class="form-control-sm" name="searchText" placeholder="Search term" aria-label="search text">
										</div>
										<div class="col-12 col-sm-3 col-md-3 input-group-btn">
											<label for="keySearch" class="sr-only">Keyword search button - click to search MCZbase around Harvard or put in a search term to in the keyword input field and click</label>
											<button class="btn btn-sm btn-primary px-2 py-1" id="keySearch" type="submit" aria-label="Keyword Search of MCZbase"> Search <i class="fa fa-search"></i> </button>
										</div>
									</div>
								</div>
							</div>
						</form>
					</div>
					<script>
						$("select.multiselect2").multiselect({
							selectedList: 10 // 0-based index
						});
						$("select.multiselect2").multiselect({
							selectedText: function(numChecked, numTotal, checkedItems){
								return numChecked + ' of ' + numTotal + ' checked';
							}
						});	
					</script> 
					<!---Search Builder--->
					<div id="panel-2" role="tabpanel" aria-labelledby="tab-2" class="py-3 mx-0" tabindex="0" hidden>
					<form id="searchForm2">
					<div class="bg-0 col-sm-12 col-md-12 p-0">
						<div class="input-group">
							<div class="mt-1 col-md-12 col-sm-12 p-0 my-2 mb-3" id="customFields">
								<div class="row border-0 p-0 mx-1 my-1 px-2 mb-2">
									<div class="col-md-3 col-sm-12 p-0 mx-1">
										<label for="selectType" class="sr-only">Select type</label>
										<select title="Select Type..." name="selectType" id="selectType" class="custom-select-sm bg-white form-control-sm border d-flex">
											<option>Select Type...</option>
											<optgroup label="Identifiers">
											<option>MCZ Catalog (Collection)</option>
											<option>Catalog Number</option>
											<option>Number plus other identifiers?</option>
											<option>Other Identifier Type</option>
											<option>Accession</option>
											<option>Accession Agency</option>
											</optgroup>
											<optgroup label="Taxonomy">
											<option>Any Taxonomic Element</option>
											<option>Scientific Name</option>
											<option>Genus</option>
											<option>Subgenus</option>
											<option>Species</option>
											<option>Subspecies</option>
											<option>Author Text</option>
											<option>Infraspecific Author Text</option>
											<option>Class</option>
											<option>Superclass</option>
											<option>Subclass</option>
											<option>Order</option>
											<option>Superorder</option>
											<option>Suborder</option>
											<option>Infraorder</option>
											<option>Family</option>
											<option>Superfamily</option>
											<option>Subfamily</option>
											<option>Tribe</option>
											<option>Authority</option>
											<option>Nomenclatural Status</option>
											<option>Nomenclatural Code</option>
											<option>Common Name</option>
											</optgroup>
											<optgroup label="Locality">
											<option>Any Geographic Element</option>
											<option>Continent/Ocean</option>
											<option>Ocean Region</option>
											<option>Ocean Subregion</option>
											<option>Country</option>
											<option>State/Province</option>
											<option>County</option>
											<option>Island Group</option>
											<option>Island</option>
											<option>Land Feature</option>
											<option>Water Feature</option>
											<option>Specific Locality</option>
											<option>Elevation</option>
											<option>Depth</option>
											<option>Verification Status</option>
											<option>Maximum Uncertainty</option>
											<option>USGS Quad Map</option>
											<option>Geology Attribute</option>
											<option>Geology Hierarchy</option>
											<option>Geog Auth Rec ID</option>
											<option>Locality Remarks</option>
											<option>Select on Google Map</option>
											<option>Locality ID</option>
											<option>Geolocate Precision</option>
											<option>Geolocate Score</option>
											<option>Is Locality Georeferenced?</option>
											<option>Accepted Georeference?</option>
											<option>Not Georeferenced Because</option>
											</optgroup>
											<optgroup label="Collecting Event">
											<option>Collector/Agent/Inst.</option>
											<option>Verbatim Locality</option>
											<option>Began Date</option>
											<option>Ended Date</option>
											<option>Verbatim Date</option>
											<option>Verbatim Coordinates</option>
											<option>Collecting Method</option>
											<option>Collecting Event Remarks</option>
											<option>Verbatim Coordinate System</option>
											<option>Habitat</option>
											<option>Collecting Source</option>
											<option>Verbatim SRS (Datum)</option>
											<option>Collecting Event ID</option>
											</optgroup>
											<optgroup label="Media">
											<option>Any Media Type</option>
											<option>Image</option>
											<option>Audible</option>
											<option>Video</option>
											<option>Spectrometer Data</option>
											<option>Media URI</option>
											<option>Any Media Relationship</option>
											<option>Created By Agent</option>
											<option>Document for Permit</option>
											<option>Document for Loan</option>
											<option>Shows Accession</option>
											<option>Shows Borrows</option>
											<option>Shows Cataloged Items</option>
											<option>Shows Collecting Event</option>
											<option>Shows Deaccession</option>
											<option>Shows Locality</option>
											<option>Shows Permit</option>
											<option>Shows Project</option>
											<option>Shows Publication</option>
											<option>Any Media Label</option>
											<option>Aspect</option>
											<option>Credit</option>
											<option>Description</option>
											<option>Height</option>
											<option>Internal Remarks</option>
											<option>Light Source</option>
											<option>Made Date</option>
											<option>md5hash</option>
											<option>Original Filename</option>
											<option>Owner</option>
											<option>Remarks</option>
											<option>Spectrometer</option>
											<option>Spectrometer Reading Location</option>
											<option>Subject</option>
											<option>Width</option>
											</optgroup>
											<optgroup label="Publications">
											<option>Accepted Scientific Name</option>
											<option>Any Publication Type</option>
											<option>Annual Report</option>
											<option>Author (agent)</option>
											<option>Book</option>
											<option>Book Section</option>
											<option>Cites Collection</option>
											<option>Cites Specimens</option>
											<option>Data Release</option>
											<option>Editor (agent)</option>
											<option>Journal Article</option>
											<option>Journal Name</option>
											<option>Journal Section</option>
											<option>Newsletter</option>
											<option>Peer Reviewed Only?</option>
											<option>Publication Remarks</option>
											<option>Serial Monograph</option>
											<option>Title</option>
											<option>Year (or Years as range)</option>
											</optgroup>
											<optgroup label="Usage">
											<option>Any Type</option>
											<option>Additional Material</option>
											<option>Allolectotype</option>
											<option>Allotype</option>
											<option>Cotype</option>
											<option>Erroneous Citation</option>
											<option>Figured</option>
											<option>Genetic Voucher</option>
											<option>Genotype</option>
											<option>Holotype</option>
											<option>Ideotype</option>
											<option>Lectotype</option>
											<option>Neotype</option>
											</optgroup>
											<optgroup label="Biological Individual">
											<option>Part Name</option>
											<option>Preserve Method</option>
											<option>Relationship</option>
											<option>Disposition</option>
											<option>Condition</option>
											<option>Lot Number</option>
											<option>Uniquie Container ID</option>
											<option>Part Remarks</option>
											<option>Part Attribute</option>
											<option>Part Relationships</option>
											<option>Specimen Attributes</option>
											</optgroup>
											<optgroup label="Curatorial">
											<option>Loan Number</option>
											<option>Permit Issued By</option>
											<option>Permit Issued To</option>
											<option>Permit Type</option>
											<option>Permit Number</option>
											<option>Print Flag</option>
											<option>Entered By</option>
											<option>Entered Date</option>
											<option>Last Edited By</option>
											<option>Last Edited Date</option>
											<option>Missing (Flags)</option>
											<option>Specimen Remarks</option>
											</optgroup>
										</select>
									</div>
									<div class="col-md-2 col-sm-12 p-0 mx-1">
										<label for="comparator" class="sr-only">Select Comparator</label>
										<select title="Select Comparator..." name="comparator" id="comparator" class="custom-select-sm bg-white form-control-sm border d-flex">
											<option>Compare with...</option>
											<option label="contains" value="like">contains</option>
											<option label="eq" value="eq">is</option>
										</select>
									</div>
									<div class="col p-0 mx-1">
										<label for="srchTxt" class="sr-only">Search Text</label>
										<input type="text" class="form-control-sm d-flex enter-search mx-0" name="srchTxt" id="srchTxt" placeholder="Enter Value"/>
									</div>
									<div class="col-md-1 col-sm-12 p-0 mx-1 d-flex justify-content-end"> <a aria-label="Add another set of search criteria" class="btn-sm btn-primary addCF rounded px-2 mr-md-auto" target="_self" href="javascript:void(0);">Add</a> </div>
								</div>
							</div>
							<span class="d-flex justify-content-center col-sm-12 px-1">
							<button class="btn-sm px-3 btn-primary m-1 ml-0" id="searchbuilder-search" aria-label="searchbuilder search" type="submit">Search <i class="fa fa-search"></i></button>
							<button class="btn-sm px-3 btn-primary m-1 ml-0" id="save-account" type="submit" aria-label="searchbuilder save">Save to My Account <i class="fa fa-user-cog"></i></button>
							<button class="btn-sm px-3 btn-primary m-1 ml-0" id="save-fixed-search" type="submit" aria-label="searchbuilder custom search">Save to Custom Fixed Search</i></button>
							</span> </div>
					</div>
					</div>
					<!---custom fixed search--->
					<div id="panel-3" aria-labelledby="tab-3" role="tabpanel" class="py-3 mx-0" tabindex="0" hidden>
					<form id="searchForm3">
						<div class="container">
							<div class="form-row col-12 px-0 mx-0 mb-2">
								<label for="multi-select" class="col-sm-2 data-entry-label align-right-center">Collection</label>
								<div class="col-sm-4">
									<select class="custom-select-sm bg-white multiselect w-100" name="multi-select" multiple="multiple" style="padding: .25em .5em" size="10">
										<cfloop query="collSearch">
											<option value="#collSearch.collection#"> #collSearch.collection# (#collSearch.guid_prefix#)</option>
										</cfloop>
									</select>
								</div>
								<label for="catalogNum" class="col-sm-2 data-entry-label align-right-center">Catalog Number</label>
								<div class="col-sm-4">
									<input id="catalogNum" type="text" rows="1" name="cat_num" class="data-entry-input" placeholder="Catalog ##(s)">
									</input>
								</div>
							</div>
							<div class="form-row col-12 px-0 mx-0 mb-2">
								<label for="otherID" class="col-sm-2 data-entry-label align-right-center">Other ID Type</label>
								<div class="col-sm-4">
									<select title="otherID" name="otherID" id="otherID" class="data-entry-select col-sm-12 pl-2">
										<option value="">Other ID Type</option>
										<option value="Collector Number">Collector Number </option>
										<option value="field number">Field Number</option>
									</select>
								</div>
								<label for="otherIDnumber" class="col-sm-2 data-entry-label align-right-center">Other ID Text</label>
								<div class="col-sm-4">
									<input type="text" class="data-entry-input" id="otherIDnumber" aria-label="Other ID number" placeholder="Other ID(s)">
								</div>
							</div>
							<div class="form-row col-12 px-0 mx-0 mb-2">
								<label for="taxa" class="mb-1 col-sm-2 data-entry-label align-right-center">Any Taxonomy</label>
								<div class="col-sm-4">
									<input id="taxa" class="data-entry-input" aria-label="any taxonomy" >
								</div>
								<label for="geography" class="col-sm-2 data-entry-label align-right-center">Any Geography</label>
								<div class="col-sm-4">
									<input type="text" class="data-entry-input" id="geography" aria-label="any geography">
								</div>
							</div>
							<div class="form-row col-12 px-0 mx-0 mb-2">
								<label for="collectors_prep" class="col-sm-2 data-entry-label align-right-center">Collectors/ Preparators</label>
								<div class="col-sm-4">
									<input id="collectors_prep" type="text" class="data-entry-input">
								</div>
								<label for="part_name" class="col-sm-2 data-entry-label align-right-center">Part Name</label>
								<div class="col-sm-4">
									<input type="text" id="part_name" name="part_name" class="data-entry-input">
								</div>
							</div>
							<div class="form-row col-12 px-0 mx-0 mb-2">
								<label for="place" class="col-sm-2 data-entry-label align-right-center">Loan Number</label>
								<div class="col-sm-4">
									<input type="text" name="place" class="data-entry-input" id="place">
								</div>
								<label class="col-sm-2 data-entry-label align-right-center" for="when">Verbatim Date</label>
								<div class="col-sm-4">
									<input type="text" class="data-entry-input" id="when">
								</div>
							</div>
							<div class="form-row mt-1">
								<label class="sr-only col-sm-2 position-col-form-label" for="submitbtn" style="position:static;">Submit button</label>
								<div class="col-sm-10">
									<button type="submit" class="btn-sm mr-1 px-3 btn-primary float-right" id="submitbtn">Search MCZbase <i class="fa fa-search"></i></button>
								</div>
							</div>
						</div>
						<div class="menu_results"> </div>
					</form>
				</div>
				</div>
				</div>
			</div>
		</div>
	</section>
	<script>
//// script for multiselect dropdown for collections
//// on keyword

$("select.multiselect").multiselect({
selectedList: 10 // 0-based index
});
$("select.multiselect").multiselect({
	selectedText: function(numChecked, numTotal, checkedItems){
		return numChecked + ' of ' + numTotal + ' checked';
	}
});	
		

		</script>
	<!--Grid Related code below along with search handler for keyword search-->
	<section class="container-fluid">
		<div class="row">
			<div class="col-12">
				<div id="jqxWidget">
					<div class="mb-5">
						<div class="row mx-0">
						<div id="jqxgrid" class="jqxGrid"></div>
						<div class="mt-005" id="enableselection"></div>
						<div style="margin-top: 30px;">
							<div id="cellbegineditevent"></div>
							<div style="margin-top: 10px;" id="cellendeditevent"></div>
						</div>
						<div id="popupWindow" style="display:none;">
							<div style="padding:.25em;">Edit</div>
							<div style="overflow: hidden;">
								<div class="container-fluid">
									<div class="row">
										<fieldset>
											<legend class="sr-only">Editable fields</legend>
											<label for="imageurl">Image:</label>
											<input id="imageurl" class="fs-13 mx-1 px-1 border-0">
											<label for="collection">Collection:</label>
											<input id="collection" class="mx-1 px-1 border-0">
											<label for="cat_num">Catalog Number:</label>
											<input id="cat_num" class="mx-1 px-1 border-0">
											<label for="began_date">Began Date:</label>
											<input id="began_date" class="mx-1">
											<label for="ended_date">Ended Date:</label>
											<input id="ended_date" class="mx-1">
											<label for="scientific_name">Scientific Name:</label>
											<input id="scientific_name" class="mx-1 px-1 border-0">
											<label for="higher_geog">Higher Geography:</label>
											<input id="higher_geog" class="mx-1 px-1 border-0">
											<label for="spec_locality">Specific Locality:</label>
											<input id="spec_locality" class="mx-1 px-1 border-0">
											<label for="collectors">Collectors:</label>
											<input id="collectors" class="mx-1 border-0" />
											<label for="verbatim_date">Verbatim Date:</label>
											<input id="verbatim_date" class="mx-1 border-0">
											<label for="coll_obj_disposition">Disposition:</label>
											<input id="coll_obj_disposition" class="mx-1 border-0">
											<label for="othercatalognumbers">Other Cat Nums:</label>
											<textarea id="othercatalognumbers" class="mx-1 border-0"></textarea>
											<input aria-label="save button" class="mr-1" type="button" id="Save" value="Save" />
											<input aria-label="cancel button" id="Cancel" type="button" value="Cancel" />
										</fieldset>
									</div>
								</div>
							</div>
						</div>
					</div>
					</div>
					<nav aria-label="filter_menu" class="cbp-spmenu cbp-spmenu-vertical cbp-spmenu-right zindex-sticky" id="cbp-spmenu-s2">
					<section> <a id="showRightPush" class="btn black-filter-btn hiddenclass" role="button" aria-label="refine results slider">Refine Results</a> </section>
					<h3 class="filters">Refine Results</h3>
					<div class="col-md-3 py-2 px-4 mb-3 pl-3 bg-transparent">
						<div class="float-left">
							<label for="columnchooser" class="mt-1"><em>By Columns in Dropdown</em></label>
							<div id="columnchooser" class="mb-1"></div>
							<div class="mt-2"><em>Then by checkboxes of values</em></div>
							<div class="mt-1 ml-0 d-inline float-left w-257" id="filterbox">
								<p>Search for something to filter</p>
							</div>
							<div>
								<input type="button" id="applyfilter" class="d-inline float-left ml-0 mr-3 mt-2 py-1 px-2 fs-14" aria-label="apply filter" value="Apply Filter"/>
								<input type="button" id="clearfilter" class="d-inline ml-0 mt-2 py-1 px-2 fs-14" value="Clear Filter"/>
							</div>
						</div>
					</nav>
					<nav aria-label="choose_columns" class="cbp-spmenu cbp-spmenu-vertical-left cbp-spmenu-left zindex-sticky" id="cbp-spmenu-s3">
						<section> <a id="showLeftPush" class="btn black-columns-btn hiddenclass" aria-label="display column selections" role="button">Columns</a> </section>
						<h3 class="columns">Display Columns</h3>
						<div class="col-md-3 mb-3 pl-1 mt-2">
							<ul class="checks">
								<li>
									<input type="radio" aria-label="check all">
									Check all </li>
								<li>
									<input type="radio" aria-label="most often displayed">
									Minimum</li>
							</ul>
							<div class="float-left zindex-sticky bg-white">
								<div id="jqxlistbox2" class="ml-1 mt-3"></div>
							</div>
						</div>
					</nav>
				</div>
			</div>
		</div>
	</section>
</main>
	<script>
///   JQXGRID -- for Keyword Search /////
$(document).ready(function() {

	$('##searchForm').bind('submit', function(evt){
	var searchParam = $('##searchText').val();
	var element = document.getElementById("showRightPush");
	element.classList.remove("hiddenclass");
	var element = document.getElementById("showLeftPush");
	element.classList.remove("hiddenclass");
	$('##searchText').jqxGrid('showloadelement');
	$("##jqxgrid").jqxGrid('clearfilters');

		var datafieldlist = [ ];//add synchronous call to cf component

	var search =
		{
			datatype: "json",
			datafields: datafieldlist,
			updaterow: function (rowid, rowdata, commit) {
			// synchronize with the server - send update command
			// call commit with parameter true if the synchronization with the server is successful
			// and with parameter false if the synchronization failder.
			commit(true);
			},
			root: 'specimenRecord',
			id: 'collection_object_id',
			url: '/specimens/component/search.cfc?method=getSpecimens&searchText=' + searchParam,
			async: false
			};

		var imagerenderer = function (row, datafield, value) {
			return '<img style="margin-left: 5px;" height="60" width="50" src="' + value + '"/></a>';
		}

		var dataAdapter = new $.jqx.dataAdapter(search);

		evt.preventDefault();


		$(document).ready(function () {
			$(".jqxDateTimeInput").jqxDateTimeInput({ width: '250px', height: '25px', theme: 'summer' });
		});

		var editrow = -1;
		// grid rendering starts below

		$("##jqxgrid").jqxGrid({
			width: '100%',
			autoheight: 'true',
			source: dataAdapter,
			filterable: true,
			//showfilterrow: true,
			sortable: true,
			pageable: true,
			autoheight: true,
			editable: true,
			pagesize: '10',
			showaggregates: true,
			columnsresize: true,
			autoshowfiltericon: false,
			autoshowcolumnsmenubutton: false,
			selectionmode: 'multiplecellsextended',
			columnsreorder: true,
			groupable: true,
			selectionmode: 'checkbox',
			altrows: true,
			showtoolbar: true,
			rendertoolbar: function (toolbar) {
				var me = this;
				var container = $("<div style='margin: .25em 1em .25em .5em;'></div>");
				toolbar.append(container);
				container.append('<h2 class="h3 float-left mt-0 pt-1 mr-4">Results</h2>');
				container.append('<input id="deleterowbutton" class="btn btn-sm ml-2 fs-13 py-1 px-2" type="button" value="Delete Selected Row(s)"/>');
				container.append('<input id="csvExport" class="btn btn-sm ml-3 fs-13 py-1 px-2" type="button" value="Download Full Record(s)"/>');
				container.append('<input id="csvExportDisplayed" class="btn btn-sm ml-3 fs-13 py-1 px-2" type="button" value="Download Displayed Columns"/>');
				container.append('<input id="clearfilter1" class="btn btn-sm ml-3 fs-13 py-1 px-2" type="button" value="Clear Filters"/>');

				//$("##csvExport").jqxButton();
				$("##csvExportDisplayed").jqxButton();

				//delete row.
				$("##deleterowbutton").jqxButton();
				$("##deleterowbutton").click(function () {
					var rowIndexes = $('##jqxgrid').jqxGrid('getselectedrowindexes');
					var rowIds = new Array();
					for (var i = 0; i < rowIndexes.length; i++) {
						var currentId = $('##jqxgrid').jqxGrid('getrowid', rowIndexes[i]);
						rowIds.push(currentId);
					};
					$('##jqxgrid').jqxGrid('deleterow', rowIds);
					$('##jqxgrid').jqxGrid('clearselection');
				});
			},
			// This part needs to be dynamic.
			columns: [
			{ text: 'Edit',
				datafield: 'Edit',
				columntype: 'button',
				cellsrenderer: function () {
				return "Edit";
				},

				buttonclick: function (row) {
					editrow = row;

					var offset = $("##jqxgrid").offset();
					$("##popupWindow").jqxWindow({ position: { x: ($(window).width() - $("##popupWindow").jqxWindow('width')) / 2 + $(window).scrollLeft(), y: ($(window).height() - $("##popupWindow").jqxWindow('height')) / 2 + $(window).scrollTop() } });
					//var rowID = $('##jqxgrid').jqxGrid('getrowid', editrow);
							 // get the clicked row's data and initialize the input fields.
							 var dataRecord = $("##jqxgrid").jqxGrid('getrowdata', editrow);
							 $("##imageurl").val(dataRecord.imageurl);
							 $("##collection").val(dataRecord.collection);
							 $("##cat_num").val(dataRecord.cat_num);
							 $("##began_date").val(dataRecord.began_date);
							 $("##ended_date").val(dataRecord.ended_date);
							 $("##scientific_name").val(dataRecord.scientific_name);
							 $("##spec_locality").val(dataRecord.spec_locality);
							 $("##locality_id").val(dataRecord.locality_id);
							 $("##higher_geog").val(dataRecord.higher_geog);
							 $("##collectors").val(dataRecord.collectors);
							 $("##verbatim_date").val(dataRecord.verbatim_date);
							 $("##coll_obj_disposition").val(dataRecord.coll_obj_disposition);
							 $("##othercatalognumbers").val(dataRecord.othercatalognumbers);
							// show the popup window.
							 $("##popupWindow").jqxWindow('show');
						 }
					},
					{text: 'Image URLs', datafield: 'imageurl', width: 50, cellsrenderer: imagerenderer},

					{text: 'Link', datafield: 'collection_object_id', width: 100,
						createwidget: function  (row, column, value, htmlElement) {
							var datarecord = value;
							var linkurl = '/specimens/SpecimenDetail.cfm?collection_object_id=' + value;
							var link = '<div class="justify-content-center p-1 pl-2 mt-1"><a aria-label="specimen detail" href="' + linkurl + '">';
							var button = $(link + "<span>View Record</span></a></div>");
						$(htmlElement).append(button);
						},
						initwidget: function (row, column, value, htmlElement) {  }
					},
					{text: 'Collection', datafield: 'collection', width: 150},
					{text: 'Catalog Number', datafield: 'cat_num', width: 130},
					{text: 'Began Date', datafield: 'began_date', width: 180, cellsformat: 'yyyy-mm-dd', filtertype: 'date'},
					{text: 'Ended Date', datafield: 'ended_date',filtertype: 'date', cellsformat: 'yyyy-mm-dd',width: 180},
					{text: 'Scientific Name', datafield: 'scientific_name', width: 250},
					{text: 'Specific Locality', datafield: 'spec_locality', width: 250},
					{text: 'Locality by ID', datafield: 'locality_id', width: 100},
					{text: 'Higher Geography', datafield: 'higher_geog', width: 280},
					{text: 'Collectors', datafield: 'collectors', width: 180},
					{text: 'Verbatim Date', datafield: 'verbatim_date', width: 190},
					{text: 'Disposition', datafield: 'coll_obj_disposition', width: 120},
					{text: 'Other IDs', datafield: 'othercatalognumbers', width: 280}
			]
		});
			// initialize the popup window and buttons.
			$("##popupWindow").jqxWindow({
				width: 850, resizable: false, isModal: true, autoOpen: false, cancelButton: $("##Cancel"), modalOpacity: 0.5
			});

			$("##popupWindow").on('open', function () {
				$("##imageurl").jqxInput('selectAll');
			});

			$("##Cancel").jqxButton({ theme: theme });
			$("##Save").jqxButton({ theme: theme });

			// update the edited row when the user clicks the 'Save' button.
			$("##Save").click(function () {
				if (editrow >= 0) {
					var row = {
						imageurl: $("##imageurl").val(),
						collection: $("##collection").val(),
						began_date: $("##began_date").val(),
						ended_date: $("##ended_date").val(),
						scientific_name: $("##scientific_name").val(),
						spec_locality: $("##spec_locality").val(),
						locality_id: $("##locality_id").val(),
						higher_geog: $("##higher_geog").val(),
						collectors: $("##collectors").val(),
						verbatim_date: $("##verbatim_date").val(),
						coll_obj_disposition: $("##coll_obj_disposition").val(),
						othercatalognumbers: $("##othercatalognumbers").val()
				};
				var rowID = $('##jqxgrid').jqxGrid('getrowid', editrow);
				$('##jqxgrid').jqxGrid('updaterow', rowID, row);
				$("##popupWindow").jqxWindow('hide');
			}
		});
		// You can drag and drop the columns into a new order.  The event log reminds you what you just did --but it only shows the last move.
		$("##jqxgrid").on('columnreordered', function (event) {
			var column = event.args.columntext;
			var newindex = event.args.newindex
			var oldindex = event.args.oldindex;
			$("##eventlog").text("Column: " + column + ", " + "New Index: " + newindex + ", Old Index: " + oldindex);
		});
		//button to download records and delete selected rows
		$("##csvExport").jqxButton();
			$("##csvExport").click(function () {
			$("##jqxgrid").jqxGrid('exportdata', 'csv', 'jqxGrid');
		});
	
		//This code starts the filters on the refine results tray (right of page)

				$("##clearfilter1").jqxButton({theme: 'Classic'});

				$("##clearfilter1").click(function (datafield) {
				//we added datafield to pass to the function
				$("##jqxgrid").jqxGrid('clearfilters');
				$("##filterbox").jqxListBox('uncheckAll');
				//we added this line to the code
				});

		$("##applyfilter").jqxButton({theme: 'Classic'});
	$("##clearfilter").jqxButton({theme: 'Classic'});
	$("##filterbox").jqxListBox({ checkboxes: true, width: 257, height: 240 });
	$("##columnchooser").jqxDropDownList({ autoDropDownHeight: true, selectedIndex: 0, width: 257, height: 25,
		source: [
			{label: 'Collectors', value: 'collectors'},
			{label: 'Collection Object ID', value: 'collection_object_id'},
			{label: 'Collection', value: 'collection'},
			{label: 'Cat Num', value: 'cat_num'},
			{label: 'Scientific Name', value: 'scientific_name'},
			{label: 'Locality', value: 'spec_locality'},
			{label: 'Higher Geography', value: 'higher_geog'},
			{label: 'Verbatim Date',value: 'verbatim_date'},
			{label: 'Disposition', value: 'coll_obj_disposition'},
			{label: 'Other IDs', value: 'othercatalognumbers'}
			]
		});
	var updateFilterBox = function (datafield) {
	var filterBoxAdapter = new $.jqx.dataAdapter(search,
	{
		uniqueDataFields: [datafield],
		autoBind: true
	});
	var uniqueRecords = filterBoxAdapter.records;
	uniqueRecords.splice(0, 0, '(All or None)');
	$("##filterbox").jqxListBox({ source: uniqueRecords, displayMember: datafield });
	$("##filterbox").jqxListBox('checkAll');
	}
	updateFilterBox('collectors');
	var handleCheckChange = true;
	$("##filterbox").on('checkChange', function (event) {
		if (!handleCheckChange)
			return;
		if (event.args.label != '(All or None)') {
			handleCheckChange = false;
			$("##filterbox").jqxListBox('checkIndex', 0);
			var checkedItems = $("##filterbox").jqxListBox('getCheckedItems');
			var items = $("##filterbox").jqxListBox('getItems');
			if (checkedItems.length == 1) {
				$("##filterbox").jqxListBox('uncheckIndex', 0);
			}
			else if (items.length != checkedItems.length) {
				$("##filterbox").jqxListBox('indeterminateIndex', 0);
			}
			handleCheckChange = true;
		}
		else {
			handleCheckChange = false;
			if (event.args.checked) {
				$("##filterbox").jqxListBox('checkAll');
			}
			else {
				$("##filterbox").jqxListBox('uncheckAll');
			}
			handleCheckChange = true;
		}
	});
		// handle columns selection.
	$("##columnchooser").on('select', function (event) {
	//	console.log(event);
		updateFilterBox(event.args.item.value);
	});
			// builds and applies the filter.
			var applyFilter = function (datafield) {
			//	console.log(datafield);
			$("##jqxgrid").jqxGrid('clearfilters');
			var filtertype = 'stringfilter';
			if (datafield == 'collection_object_id' || datafield == 'locality_id') filtertype = 'numericfilter';

			var filtergroup = new $.jqx.filter();
			var checkedItems = $("##filterbox").jqxListBox('getCheckedItems');
			if (checkedItems.length == 0) {
				var filter_or_operator = 1;
				var filtervalue = "Empty";
				var filtercondition = 'equal';
				var filter = filtergroup.createfilter(filtertype, filtervalue, filtercondition);
				filtergroup.addfilter(filter_or_operator, filter);
			}
			else {
				for (var i = 0; i < checkedItems.length; i++) {
					var filter_or_operator = 1;
					var filtervalue = checkedItems[i].label;
					var filtercondition = 'equal';
					var filter = filtergroup.createfilter(filtertype, filtervalue, filtercondition);
					filtergroup.addfilter(filter_or_operator, filter);
				}
			}
			$("##jqxgrid").jqxGrid('addfilter', datafield, filtergroup);
			$("##jqxgrid").jqxGrid('applyfilters');
			}
			$("##clearfilter").click(function (datafield) {
			//we added datafield to pass to the function
			$("##jqxgrid").jqxGrid('clearfilters');
			$("##filterbox").jqxListBox('uncheckAll');
			//we added this line to the code
			});
			$("##applyfilter").click(function () {
			var dataField = $("##columnchooser").jqxDropDownList('getSelectedItem').value;
			applyFilter(dataField);
		});
			var listSource = [
				{ label: 'Image URL', value: 'imageurl' },
				{ label: 'Collection Object ID', value: 'collection_object_id' },
				{ label: 'Collection', value: 'collection' },
				{ label: 'Cat Num', value: 'cat_num' },
				{ label: 'Scientific Name', value: 'scientific_name'},
				{ label: 'Locality', value: 'spec_locality' },
				{ label: 'Locality ID', value: 'locality_id' },
				{ label: 'Higher Geography', value: 'higher_geog' },
				{ label: 'Collectors', value: 'collectors' },
				{ label: 'Verbatim Date',value: 'verbatim_date'},
				{ label: 'Disposition', value: 'coll_obj_disposition' },
				{ label: 'Other IDs', value: 'originalcatalognumbers'}
			];
		// jqxlistbox2 is the show/hide column filter
			$("##jqxlistbox2").jqxListBox({ source: listSource, width: 198, height: 300, theme: theme, checkboxes: true });
			$("##jqxlistbox2").jqxListBox('checkAll');
			$("##jqxlistbox2").on('checkChange', function (event) {
			$("##jqxgrid").jqxGrid('beginupdate');
			if (event.args.checked) {
				$("##jqxgrid").jqxGrid('showcolumn', event.args.value);
			}
				else {
				$("##jqxgrid").jqxGrid('hidecolumn', event.args.value);
			}
				$("##jqxgrid").jqxGrid('endupdate');
			});
		$("##clearselectionbutton").jqxButton({ theme: theme });
		$("##enableselection").jqxDropDownList({
			autoDropDownHeight: true, dropDownWidth: 230, width: 120, height: 25, selectedIndex: 1, source: ['none', 'single row', 'multiple rows',
			'multiple rows extended', 'multiple rows advanced']
		});
		$("##enablehover").jqxCheckBox({  checked: true });
		// clears the selection.
		$("##clearselectionbutton").click(function () {
			$("##jqxgrid").jqxGrid('clearselection');
		});
		// enable or disable the selection.  Used for Delete selected row button.
		$("##enableselection").on('select', function (event) {
			var index = event.args.index;
			console.log(event.args.index);
			$("##selectrowbutton").jqxButton({ disabled: false });
			switch (index) {
				case 0:
					$("##jqxgrid").jqxGrid('selectionmode', 'none');
					$("##selectrowbutton").jqxButton({ disabled: true });
					break;
				case 1:
					$("##jqxgrid").jqxGrid('selectionmode', 'singlerow');
					break;
				case 2:
					$("##jqxgrid").jqxGrid('selectionmode', 'multiplerows');
					break;
				case 3:
					$("##jqxgrid").jqxGrid('selectionmode', 'multiplerowsextended');
					break;
				case 4:
					$("##jqxgrid").jqxGrid('selectionmode', 'multiplerowsadvanced');
					break;
			}
		});
		// enable or disable the hover state.
		$("##enablehover").on('change', function (event) {
			$("##jqxgrid").jqxGrid('enablehover', event.args.checked);
		});
		// display selected row index.
		$("##jqxgrid").on('rowselect', function (event) {
			$("##selectrowindex").text(event.args.rowindex);
		});
		// display unselected row index.
		$("##jqxgrid").on('rowunselect', function (event) {
			$("##unselectrowindex").text(event.args.rowindex);
		});
	});
});
</script> 
<script>
	//this is the search builder main dropdown for all the columns found in flat
$(document).ready(function(){
	$(".addCF").click(function(){$("##customFields").append('<ul class="row col-md-11 col-sm-12 mx-0 my-4"><li class="d-inline col-sm-12 col-md-1 px-0 mr-2"><select title="Join Operator" name="JoinOperator" id="joinOperator" class="data-entry-select bg-white mx-0 d-flex"><option value="">Join with...</option><option value="and">and</option><option value="or">or</option><option value="not">not</option></select></li><li class="d-inline mr-2 col-sm-12 px-0 col-md-2"><select title="Select Type" name="SelectType" class="data-entry-select bg-white d-flex"><option>Select Type...</option><optgroup label="Identifiers"><option>MCZ Catalog (Collection)</option><option>Catalog Number</option><option>Number plus other identifiers?</option><option>Other Identifier Type</option><option>Accession</option><option>Accession Agency</option></optgroup><optgroup label="Taxonomy"><option>Any Taxonomic Element</option><option>Scientific Name</option><option>Began Date</option><option>Ended Date</option></optgroup></select></li><li class="d-inline col-sm-12 px-0 mr-2 col-md-2"><select title="Comparator" name="comparator" id="comparator" class="bg-white data-entry-select d-flex"><option value="">Compare with...</option><option value="like">contains</option><option value="eq">is</option></select></li><li class="col d-inline mr-2 px-0"><input type="text" class="data-entry-input" name="customFieldValue[]" id="srchTxt" placeholder="Enter Value"/></li><li class="d-inline mr-2 col-md-1 col-sm-1 px-0 d-flex justify-content-end"><button href="javascript:void(0);" arial-label="remove" class="btn-xs px-3 btn-primary remCF mr-auto">Remove</button></li></ul>');
	$("##customFields").on('click','.remCF',function(){
		$(this).parent().parent().remove();
		});
	});
});
</script> 
	<script>
//// script for DatePicker
//$(function() {
//	$("##began_date").datepicker({
//		dateFormat: "yy-mm-dd",
//		changeMonth: true,
//		changeYear: true
//	}).val()
//	$("##ended_date").datepicker({
//		dateFormat: "yy-mm-dd",
//		changeMonth: true,
//		changeYear: true
//	}).val()
//});

function saveSearch(returnURL){
	var sName=prompt("Name this search", "my search");
	if (sName!==null){
		var sn=encodeURIComponent(sName);
		var ru=encodeURI(returnURL);
		jQuery.getJSON("/component/functions.cfc",
			{
				method : "saveSearch",
				returnURL : ru,
				srchName : sn,
				returnformat : "json",
				queryformat : 'column'
			},
			function (r) {
				if(r!='success'){
					alert(r);
				}
			}
		);
	}
}


</script> 
<script>

var	menuRight = document.getElementById( 'cbp-spmenu-s2' ),
	showRightPush = document.getElementById( 'showRightPush' ),
	menuLeft = document.getElementById( 'cbp-spmenu-s3' ),
	showLeftPush = document.getElementById( 'showLeftPush' ),
	body = document.body;

    showRightPush.onclick = function() {
	classie.toggle( this, 'active' );
	classie.toggle( body, 'cbp-spmenu-push-toleft' );
	classie.toggle( menuRight, 'cbp-spmenu-open' );
	
	disableOther( 'showRightPush' );
    };
		
	showLeftPush.onclick = function() {
		classie.toggle( this, 'active' );
		classie.toggle( body, 'cbp-spmenu-push-toright');
		classie.toggle( menuLeft, 'cbp-spmenu-open' );
		disableOther( 'showLeftPush' );
	};
	
	function disableOther( button ) {
	if( button !== 'showLeftPush' ) {
		classie.toggle( showLeftPush, 'disabled' );
	}
	if( button !== 'showRightPush' ) {
		classie.toggle( showRightPush, 'disabled' );
	}
}
/*!
 * classie - class helper functions
 * from bonzo https://github.com/ded/bonzo
 * 
 * classie.has( elem, 'my-class' ) -> true/false
 * classie.add( elem, 'my-new-class' )
 * classie.remove( elem, 'my-unwanted-class' )
 * classie.toggle( elem, 'my-class' )
 */
/*jshint browser: true, strict: true, undef: true */

( function( window ) {

'use strict';

// class helper functions from bonzo https://github.com/ded/bonzo

function classReg( className ) {
  return new RegExp("(^|\\s+)" + className + "(\\s+|$)");
}

// classList support for class management
// altho to be fair, the api sucks because it won't accept multiple classes at once
var hasClass, addClass, removeClass;

if ( 'classList' in document.documentElement ) {
  hasClass = function( elem, c ) {
    return elem.classList.contains( c );
  };
  addClass = function( elem, c ) {
    elem.classList.add( c );
  };
  removeClass = function( elem, c ) {
    elem.classList.remove( c );
  };
}
else {
  hasClass = function( elem, c ) {
    return classReg( c ).test( elem.className );
  };
  addClass = function( elem, c ) {
    if ( !hasClass( elem, c ) ) {
      elem.className = elem.className + ' ' + c;
    }
  };
  removeClass = function( elem, c ) {
    elem.className = elem.className.replace( classReg( c ), ' ' );
  };
}

function toggleClass( elem, c ) {
  var fn = hasClass( elem, c ) ? removeClass : addClass;
  fn( elem, c );
}

window.classie = {
  // full names
  hasClass: hasClass,
  addClass: addClass,
  removeClass: removeClass,
  toggleClass: toggleClass,
  // short names
  has: hasClass,
  add: addClass,
  remove: removeClass,
  toggle: toggleClass
};

})( window );
</script> 
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
