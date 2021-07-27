<!--
Specimens.cfm

Copyright 2019-2021 President and Fellows of Harvard College

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

<cfif not isdefined("action")>
	<cfset action="keywordSearch">
</cfif>
<cfswitch expression="#action#">
	<!--- API note: action and method seem duplicative, action is required and used to determine
			which tab to show, method invokes target backing method in form submission, but when 
			invoking this page with execute=true method does not need to be included in the call
			even though it will be included in the URI parameter list when clicking on the 
			"Link to this search" link.
	--->
	<cfcase value="keywordSearch">
		<cfset pageTitle = "Specimen Search by Keyword">
		<cfif isdefined("execute")>
			<cfset execute="keyword">
		</cfif>
	</cfcase>
	<cfcase value="builderSearch">
		<cfset pageTitle = "Specimen Search Builder">
		<cfif isdefined("execute")>
			<cfset execute="builder">
		</cfif>
	</cfcase>
	<cfcase value="fixedSearch">
		<cfset pageTitle = "Specimen Search">
		<cfif isdefined("execute")>
			<cfset execute="fixed">
		</cfif>
	</cfcase>
	<cfdefaultcase>
		<cfset pageTitle = "Specimen Search by Keyword">
		<cfif isdefined("execute")>
			<cfset execute="keyword">
		</cfif>
	</cfdefaultcase>
</cfswitch>
<cfinclude template = "/shared/_header.cfm">

<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
	<cfelse>
	<cfset oneOfUs = 0>
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
<cfquery name="distinctContOcean" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select continent_ocean from ctContinent ORDER BY continent_ocean
</cfquery>
<cfquery name="distinctCountry" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select geog_auth_rec.country, count(flat.collection_object_id) as ct
	FROM geog_auth_rec 
		left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat 
			on geog_auth_rec.geog_auth_rec_id = flat.geog_auth_rec_id
	GROUP BY geog_auth_rec.country 
	order by geog_auth_rec.country
</cfquery>
<cfquery name="IslGrp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select island_group from ctIsland_Group order by Island_Group
</cfquery>
<cfquery name="distinctFeature" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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

<!--- ensure that pass through parameters for linking to a search are defined --->
<cfif NOT isdefined("searchText")>
	<cfset searchText = "">
</cfif>

<!--- TODO: Replace with a native javascript UUID function when it becomes available --->
<script>
// From broofa's answer in https://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid
// uses the crypto library to obtain a random number and generates RFC4122 version 4 UUID.
function getVersion4UUID() {
  return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
    (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
  );
}
</script>
<div id="overlaycontainer" style="position: relative;">
	<main id="content" class="container-fluid">
		<div class="row">
			<div class="col-12 pt-1 pb-3">
				<h1 class="h3 smallcaps pl-1">Find Specimen Records <span class="count  font-italic color-green mx-0"><small> #getCount.cnt# records</small></span></h1>
				<!--- Tab header div --->
				<div class="tabs card-header tab-card-header px-2 pt-3">
					<cfswitch expression="#action#">
						<cfcase value="keywordSearch">
							<cfset keywordTabActive = "active">
							<cfset keywordTabShow = "">
							<cfset builderTabActive = "">
							<cfset builderTabShow = "hidden">
							<cfset fixedTabActive = "">
							<cfset fixedTabShow = "hidden">
							<cfset keywordTabAria = "aria-selected=""true"" tabindex=""0"" ">
							<cfset builderTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							<cfset fixedTabAria = "aria-selected=""false"" tabindex=""-1"" ">
						</cfcase>
						<cfcase value="builderSearch">
							<cfset keywordTabActive = "">
							<cfset keywordTabShow = "hidden">
							<cfset builderTabActive = "active">
							<cfset builderTabShow = "">
							<cfset fixedTabActive = "">
							<cfset fixedTabShow = "hidden">
							<cfset keywordTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							<cfset builderTabAria = "aria-selected=""true"" tabindex=""0"" ">
							<cfset fixedTabAria = "aria-selected=""false"" tabindex=""-1"" ">
						</cfcase>
						<cfcase value="fixedSearch">
							<cfset keywordTabActive = "">
							<cfset keywordTabShow = "hidden">
							<cfset builderTabActive = "">
							<cfset builderTabShow = "hidden">
							<cfset fixedTabActive = "active">
							<cfset fixedTabShow = "">
							<cfset keywordTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							<cfset builderTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							<cfset fixedTabAria = "aria-selected=""true"" tabindex=""0"" ">
						</cfcase>
						<cfdefaultcase>
							<cfset keywordTabActive = "active">
							<cfset keywordTabShow = "">
							<cfset builderTabActive = "">
							<cfset builderTabShow = "hidden">
							<cfset fixedTabActive = "">
							<cfset fixedTabShow = "hidden">
							<cfset keywordTabAria = "aria-selected=""true"" tabindex=""0"" ">
							<cfset builderTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							<cfset fixedTabAria = "aria-selected=""false"" tabindex=""-1"" ">
						</cfdefaultcase>
					</cfswitch>
					<div class="tab-headers tabList" role="tablist" aria-label="search panel tabs">
						<button class="px-5 #keywordTabActive#" id="1" role="tab" aria-controls="keywordSearchPanel" #keywordTabAria# >Keyword Search</button>
						<button class="px-5 #builderTabActive#" id="2" role="tab" aria-controls="builderSearchPanel" #builderTabAria#>Search Builder</button>
						<button class="px-5 #fixedTabActive#" id="3" role="tab" aria-controls="fixedSearchPanel" #fixedTabAria#>Custom Fixed Search</button>
					</div>
					<div class="tab-content">
						<!---Keyword Search/results tab panel--->
						<div id="keywordSearchPanel" role="tabpanel" aria-labelledby="1" tabindex="0" class="mx-0 #keywordTabActive#" #keywordTabShow#>
							<section role="search" class="container-fluid">
								<form name= "keywordSearchForm" id="keywordSearchForm">
									<input id="result_id_keywordSearch" type="hidden" name="result_id" value="">
									<input type="hidden" name="method" value="getSpecimens" class="keeponclear">
									<input type="hidden" name="action" value="keywordSearch" class="keeponclear">
									<div class="form-row">
										<div class="input-group mt-1 px-3">
											<div class="input-group-btn col-12 col-sm-4 col-md-3 pr-md-0">
												<label for="collmultiselect" class="sr-only">Collection</label>
												<select class="custom-select-sm bg-white multiselect2 w-100" name="collmultiselect" multiple="multiple" size="10">
													<cfloop query="collSearch">
														<option value="#collSearch.collection_id#"> #collSearch.collection# (#collSearch.guid_prefix#)</option>
													</cfloop>
												</select>
											</div>
											<div class="col-12 col-sm-5 col-md-6 px-md-0">
												<label for="searchText" class="sr-only">Keyword input field </label>
												<input id="searchText" type="text" class="data-entry-input py-1" name="searchText" placeholder="Search term" aria-label="search text" value="#searchText#">
											</div>
										</div>
									</div>
									<div class="form-row mt-1">
										<div class="col-12">
											<label for="keySearch" class="sr-only">Keyword search button - click to search MCZbase</label>
											<button type="submit" class="btn btn-xs btn-primary px-2" id="keySearch" aria-label="Keyword Search of MCZbase"> Search <i class="fa fa-search"></i> </button>
											<button type="reset" class="btn btn-xs btn-warning mr-2" aria-label="Reset this search form to inital values">Reset</button>
											<button type="button" class="btn btn-xs btn-warning mr-2" aria-label="Start a new specimen search with a clear page" onclick="window.location.href='#Application.serverRootUrl#/Specimens.cfm?action=keywordSearch';">New Search</button>
										</div>
									</div>
								</form>
							</section>
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
							<!--- results for keyword search --->
							<section class="container-fluid">
								<div class="row mx-0">
									<div class="col-12">
										<div class="mb-5">
											<div class="row mt-1 mb-0 pb-0 jqx-widget-header border px-2">
												<h1 class="h4">Results: </h1>
												<span class="d-block px-3 p-2" id="keywordresultCount"></span> <span id="keywordresultLink" class="d-block p-2"></span>
												<div id="keywordcolumnPickDialog">
													<div class="container-fluid">
														<div class="row">
															<div class="col-12 col-md-6">
																<div id="keywordcolumnPick" class="px-1"></div>
															</div>
															<div class="col-12 col-md-6">
																<div id="keywordcolumnPick1" class="px-1"></div>
															</div>
														</div>
													</div>
												</div>
												<div id="keywordcolumnPickDialogButton"></div>
												<div id="keywordresultDownloadButtonContainer"></div>
											</div>
											<div class="row mt-0"> 
												<!--- Grid Related code is below along with search handlers --->
												<div id="keywordsearchResultsGrid" class="jqxGrid" role="table" aria-label="Search Results Table"></div>
												<div id="keywordenableselection"></div>
											</div>
										</div>
									</div>
								</div>
							</section>
						</div><!--- end keyword search/results panel --->

							<!---Query Builder tab panel--->
						<div id="builderSearchPanel" role="tabpanel" aria-labelledby="2" tabindex="0" class="mx-0 #builderTabActive#"  #builderTabShow#>
							<section role="search" class="container-fluid">
								<form id="builderSearchForm">
									<input id="result_id_builderSearch" type="hidden" name="result_id" value="">
									<div class="form-row">
										<div class="mt-1 col-md-12 col-sm-12 p-0 my-2 mb-3" id="customFields">
											<div class="row border-0 p-0 mx-1 my-1 px-2 mb-2">
												<div class="col-md-3 col-sm-12 p-0 mx-1">
													<cfquery name="fields" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="fields_result">
														SELECT search_category, table_name, column_name, data_type, label
														FROM cf_spec_search_cols
														ORDER BY
															search_category, table_name, label
													</cfquery>
													<label for="selectType" class="sr-only">Search Field</label>
													<!--- TODO: Move into a backing component for reuse with an ajax add field --->
													<select title="Select Type..." name="selectType" id="selectType" class="custom-select-sm bg-white form-control-sm border d-flex">
														<option>Select Type...</option>
														<cfset category = "">
														<cfset optgroupOpen = false>
														<cfloop query="fields">
															<cfif category NEQ fields.search_category>
																<cfif optgroupOpen>
																	</optgroup>
																	<cfset optgroupOpen = false>
																</cfif>
																<optgroup label="fields.search_category">
																<cfset optgroupOpen = true>
																<cfset category = fields.search_category>
															</cfif>
															<option value="#fields.table_name#:#fields.column_name#">#fields.label#</option>
														</cfloop>
														<cfif optgroupOpen>
															</optgroup>
														</cfif>
													</select>
												</div>
												<!--- TODO: Replace with operators and autocompletes on search values --->
												<div class="col-md-2 col-sm-12 p-0 mx-1">
													<label for="comparator" class="sr-only">Comparator</label>
													<select title="Select Comparator..." name="comparator" id="comparator" class="custom-select-sm bg-white form-control-sm border d-flex">
														<option>Compare with...</option>
														<option label="contains" value="like">contains</option>
														<option label="eq" value="eq">is</option>
													</select>
												</div>
												<div class="col p-0 mx-1">
													<!--- TODO: Add javascript to modify inputs depending on selected field. --->
													<label for="srchTxt" class="sr-only">Search For</label>
													<input type="text" class="form-control-sm d-flex enter-search mx-0" name="srchTxt" id="srchTxt" placeholder="Enter Value"/>
												</div>
												<div class="col-md-1 col-sm-12 p-0 mx-1 d-flex justify-content-end">
													<a aria-label="Add another set of search criteria" class="btn-sm btn-primary addCF rounded px-2 mr-md-auto" target="_self" href="javascript:void(0);">Add</a> 
												</div>
											</div>
										</div><!--- end customFields: new form rows get appended here --->
									</div>
									<div class="form-row mt-1 mb-1">
										<div class="col-12">
											<button type="submit" class="btn btn-xs px-2 btn-primary" id="searchbuilder-search" aria-label="run the search builder search">Search <i class="fa fa-search"></i></button>
											<button type="reset" class="btn btn-xs btn-warning mr-2" aria-label="Reset this search form to inital values">Reset</button>
											<button type="button" class="btn btn-xs btn-warning mr-2" aria-label="Start a new specimen search with a clear page" onclick="window.location.href='#Application.serverRootUrl#/Specimens.cfm?action=builderSearch';">New Search</button>
											<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
												<!--- TODO: Move to top of search results bar, available after running search --->
												<!--- TODO: Add handler to carry out this action --->
												<button type="button" class="btn-sm px-3 btn-primary m-1 ml-0" id="save-account" aria-label="save this search">
													Save to My Account <i class="fa fa-user-cog"></i>
												</button>
											</cfif>
										</div>
									</div>
								</form>
							</section>
							<!--- results for search builder search --->
							<section class="container-fluid">
								<div class="row mx-0">
									<div class="col-12">
										<div class="mb-5">
											<div class="row mt-1 mb-0 pb-0 jqx-widget-header border px-2">
												<h1 class="h4">Results: </h1>
												<span class="d-block px-3 p-2" id="builderresultCount"></span> <span id="builderresultLink" class="d-block p-2"></span>
												<div id="buildercolumnPickDialog">
													<div class="container-fluid">
														<div class="row">
															<div class="col-12 col-md-6">
																<div id="buildercolumnPick" class="px-1"></div>
															</div>
															<div class="col-12 col-md-6">
																<div id="buildercolumnPick1" class="px-1"></div>
															</div>
														</div>
													</div>
												</div>
												<div id="buildercolumnPickDialogButton"></div>
												<div id="builderresultDownloadButtonContainer"></div>
											</div>
											<div class="row mt-0"> 
												<!--- Grid Related code is below along with search handlers --->
												<div id="buildersearchResultsGrid" class="jqxGrid" role="table" aria-label="Search Results Table"></div>
												<div id="builderenableselection"></div>
											</div>
										</div>
									</div>
								</div>
							</section>
						</div><!--- end search builder tab --->

						<!---Fixed Search tab panel--->
						<div id="fixedSearchPanel" role="tabpanel" aria-labelledby="3" tabindex="0" class="mx-0 #fixedTabActive#"  #fixedTabShow#>
							<section role="search" class="container-fluid">
								<form id="fixedSearchForm">
									<input id="result_id_fixedSearch" type="hidden" name="result_id" value="">
									<input id="method_fixedSearch" type="hidden" name="method" value="executeFixedSearch" class="keeponclear">
									<input type="hidden" name="action" value="fixedSearch" class="keeponclear">
									<div class="container-flex">
										<div class="form-row mb-2">
											<div class="col-12 col-md-3">
												<label for="multi-select" class="data-entry-label">Collection</label>
												<select class="custom-select-sm bg-white multiselect w-100" name="multi-select" multiple="multiple" style="padding: .25em .5em" size="10" disabled>
													<cfloop query="collSearch">
														<option value="#collSearch.collection#"> #collSearch.collection# (#collSearch.guid_prefix#)</option>
													</cfloop>
												</select>
											</div>
											<div class="col-12 col-md-3">
												<label for="catalogNum" class="data-entry-label">Catalog Number</label>
												<input id="catalogNum" type="text" name="cat_num" class="data-entry-input" placeholder="Catalog ##(s)" disabled>
											</div>
											<div class="col-12 col-md-3">
												<label for="otherID" class="data-entry-label">Other ID Type</label>
												<select title="otherID" name="otherID" id="otherID" class="data-entry-select col-sm-12 pl-2" disabled>
													<option value="">Other ID Type</option>
													<option value="Collector Number">Collector Number </option>
													<option value="field number">Field Number</option>
												</select>
											</div>
											<div class="col-12 col-md-3">
												<label for="otherIDnumber" class="data-entry-label">Other ID Text</label>
												<input type="text" class="data-entry-input" id="otherIDnumber" aria-label="Other ID number" placeholder="Other ID(s)" disabled>
											</div>
										</div>
										<div class="form-row mb-2">
											<div class="col-12 col-md-2">
												<label for="taxa" class="data-entry-label">Any Taxonomy</label>
												<input id="taxa" name="full_taxon_name" class="data-entry-input" aria-label="any taxonomy">
											</div>
											<div class="col-12 col-md-2">
												<label for="phylorder" class="data-entry-label">Order</label>
												<cfif not isdefined("phylorder")><cfset phylorder=""></cfif>
												<input id="phylorder" name="phylorder" class="data-entry-input" aria-label="phylorder" value="#phylorder#" >
												<script>
													jQuery(document).ready(function() {
														makeTaxonSearchAutocomplete('phylorder','order');
													});
												</script>
											</div>
											<div class="col-12 col-md-2">
												<label for="family" class="data-entry-label">Family</label>
												<cfif not isdefined("family")><cfset family=""></cfif>
												<input id="family" name="family" class="data-entry-input" aria-label="family" value="#family#" >
												<script>
													jQuery(document).ready(function() {
														makeTaxonSearchAutocomplete('family','family');
													});
												</script>
											</div>
											<div class="col-12 col-md-2">
												<label for="genus" class="data-entry-label">Genus</label>
												<cfif not isdefined("genus")><cfset genus=""></cfif>
												<input type="text" class="data-entry-input" id="genus" name="genus" aria-label="genus" value="#genus#">
												<script>
													jQuery(document).ready(function() {
														makeTaxonSearchAutocomplete('genus','genus');
													});
												</script>
											</div>
											<div class="col-12 col-md-2">
												<label for="scientific_name" class="data-entry-label">Scientific Name</label>
												<cfif not isdefined("scientific_name")><cfset scientific_name=""></cfif>
												<cfif not isdefined("taxon_name_id")><cfset taxon_name_id=""></cfif>
												<input type="text" id="scientific_name" name="scientific_name" class="data-entry-input" aria-label="scientific_name" value="#scientific_name#" >
												<input type="hidden" id="taxon_name_id" name="taxon_name_id" value="#taxon_name_id#" >
												<script>
													jQuery(document).ready(function() {
														makeScientificNameAutocompleteMeta('scientific_name','taxon_name_id');
													});
												</script>
											</div>
											<div class="col-12 col-md-2">
												<label for="author_text" class="data-entry-label">Authorship</label>
												<cfif not isdefined("author_text")><cfset author_text=""></cfif>
												<input id="author_text" name="author_text" class="data-entry-input" aria-label="author_text" value="#author_text#" >
												<script>
													jQuery(document).ready(function() {
														makeTaxonSearchAutocomplete('author_text','author_text');
													});
												</script>
											</div>
										</div>
										<div class="form-row mb-2">
											<div class="col-12 col-md-2">
												<label for="geography" class="data-entry-label">Any Geography</label>
												<input type="text" class="data-entry-input" id="geography" aria-label="any geography" disabled>
											</div>
											<div class="col-12 col-md-2">
												<label for="country" class="data-entry-label">Country</label>
												<cfif not isdefined("country")><cfset country=""></cfif>
												<input type="text" class="data-entry-input" id="country" name="country" aria-label="country" value="#country#">
												<script>
													jQuery(document).ready(function() {
														makeCountrySearchAutocomplete('country');
													});
												</script>
											</div>
											<div class="col-12 col-md-2">
												<label for="state_prov" class="data-entry-label">State/Province</label>
												<cfif not isdefined("state_prov")><cfset state_prov=""></cfif>
												<input type="text" class="data-entry-input" id="state_prov" name="state_prov" aria-label="state_prov" value="#state_prov#">
												<script>
													jQuery(document).ready(function() {
														makeGeogSearchAutocomplete('state_prov','state_prov');
													});
												</script>
											</div>
											<div class="col-12 col-md-2">
												<label for="county" class="data-entry-label">County/Shire/Parish</label>
												<cfif not isdefined("county")><cfset county=""></cfif>
												<input type="text" class="data-entry-input" id="county" name="county" aria-label="county" value="#county#">
												<script>
													jQuery(document).ready(function() {
														makeGeogSearchAutocomplete('county','county');
													});
												</script>
											</div>
											<div class="col-12 col-md-2">
												<label for="island_group" class="data-entry-label">Island Group</label>
												<cfif not isdefined("island_group")><cfset island_group=""></cfif>
												<input type="text" class="data-entry-input" id="island_group" name="island_group" aria-label="island_group" value="#island_group#">
												<script>
													jQuery(document).ready(function() {
														makeGeogSearchAutocomplete('island_group','island_group');
													});
												</script>
											</div>
											<div class="col-12 col-md-2">
												<label for="island" class="data-entry-label">Island</label>
												<cfif not isdefined("island")><cfset island=""></cfif>
												<input type="text" class="data-entry-input" id="island" name="island" aria-label="island" value="#island#">
												<script>
													jQuery(document).ready(function() {
														makeGeogSearchAutocomplete('island','island');
													});
												</script>
											</div>
										</div>
										<div class="form-row mb-2">
											<div class="col-12 col-md-3">
												<label for="collector" class="data-entry-label">Collector</label>
												<cfif not isdefined("collector")>
													<cfset collector="">
												</cfif>
												<cfif not isdefined("collector_agent_id") OR len(collector_agent_id) EQ 0>
													<cfif len(collector) EQ 0>
														<cfset collector_agent_id ="">
													<cfelse>
														<cfset collector_agent_id ="">
														<!--- lookup collector's agent_id --->
														<cfquery name="collectorLookup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
															SELECT agent_id 
															FROM preferred_agent_name 
															WHERE agent_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collector#"> 
																AND rownum < 2
														</cfquery>
														<cfloop query="collectorLookup">
															<cfset collector_agent_id = collectorLookup.agent_id>
														</cfloop>
													</cfif>
												<cfelse>
													<!--- lookup collector --->
													<cfquery name="collectorLookup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
														SELECT agent_name 
														FROM preferred_agent_name 
														WHERE agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collector_agent_id#">
															AND rownum < 2
													</cfquery>
													<cfif collectorLookup.recordcount GT 0>
														<cfloop query="collectorLookup">
															<cfset collector = collectorLookup.agent_name>
														</cfloop>
													</cfif>
												</cfif>
												<input type="text" id="collector" name="collector" class="data-entry-input" value="#collector#">
												<input type="hidden" id="collector_agent_id" name="collector_agent_id" value="#collector_agent_id#">
												<script>
													jQuery(document).ready(function() {
														$(makeConstrainedAgentPicker('collector','collector_agent_id','transaction_agent'));
													});
												</script>
											</div>
											<div class="col-12 col-md-2">
												<label for="part_name" class="data-entry-label">Part Name</label>
												<input type="text" id="part_name" name="part_name" class="data-entry-input" disabled>
											</div>
											<div class="col-12 col-md-2">
												<label for="place" class="data-entry-label">Loan Number</label>
												<input type="text" name="place" class="data-entry-input" id="place" disabled>
											</div>
											<div class="col-12 col-md-3">
												<label class="data-entry-label" for="when">Verbatim Date</label>
												<input type="text" class="data-entry-input" id="when" diabled>
											</div>
											<div class="col-12 col-md-2">
												<cfif findNoCase('redesign',gitBranch) GT 0>
													<label class="data-entry-label" for="debug">Debug</label>
													<select title="debug" name="debug" id="dbug" class="data-entry-select">
														<option value=""></option>
														<cfif isdefined("debug") AND len(debug) GT 0><cfset selected=" selected "><cfelse><cfset selected=""></cfif>
														<option value="true" #selected#>Debug JSON</option>
													</select>
												</cfif>
											</div>
										</div>
										<div class="form-row mt-1 mb-1">
											<div class="col-12">
												<button type="submit" class="btn mr-1 px-3 btn-primary btn-xs" aria-label="run the fixed search" id="fixedsubmitbtn">Search <i class="fa fa-search"></i></button>
												<button type="reset" class="btn btn-xs btn-warning mr-2" aria-label="Reset this search form to inital values">Reset</button>
												<button type="button" class="btn btn-xs btn-warning mr-2" aria-label="Start a new specimen search with a clear page" onclick="window.location.href='#Application.serverRootUrl#/Specimens.cfm?action=fixedSearch';">New Search</button>
											</div>
										</div>
									</div><!--- end container-flex --->
									<div class="menu_results"> </div>
								</form>
							</section>
							<!--- results for fixed search --->
							<section class="container-fluid">
								<div class="row mx-0">
									<div class="col-12">
										<div class="mb-5">
											<div class="row mt-1 mb-0 pb-0 jqx-widget-header border px-2">
												<h1 class="h4">Results: </h1>
												<span class="d-block px-3 p-2" id="fixedresultCount"></span> <span id="fixedresultLink" class="d-block p-2"></span>
												<div id="fixedcolumnPickDialog">
													<div class="container-fluid">
														<div class="row">
															<div class="col-12 col-md-6">
																<div id="fixedcolumnPick" class="px-1"></div>
															</div>
															<div class="col-12 col-md-6">
																<div id="fixedcolumnPick1" class="px-1"></div>
															</div>
														</div>
													</div>
												</div>
												<div id="fixedcolumnPickDialogButton"></div>
												<div id="fixedresultDownloadButtonContainer"></div>
											</div>
											<div class="row mt-0"> 
												<!--- Grid Related code is below along with search handlers --->
												<div id="fixedsearchResultsGrid" class="jqxGrid" role="table" aria-label="Search Results Table"></div>
												<div id="fixedenableselection"></div>
											</div>
										</div>
									</div>
								</div>
							</section>
						</div><!--- end fixed search tab --->

					</div>
				</div>
			</div>
		</div>
	</main>
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
	
	</main>
	<div id="overlay" style="position: absolute; top:0px; left:0px; width: 100%; height: 100%; background: rgba(0,0,0,0.5); border-color: transparent; opacity: 0.99; display: none; z-index: 2;">
		<div class="jqx-rc-all jqx-fill-state-normal" style="position: absolute; left: 50%; top: 25%; width: 10em; height: 2.4em;line-height: 2.4em; padding: 5px; color: ##333333; border-color: ##898989; border-style: solid; margin-left: -5em; opacity: 1;">
			<div class="jqx-grid-load" style="float: left; overflow: hidden; height: 32px; width: 32px;"></div>
			<div style="float: left; display: block; margin-left: 1em;" >Searching...</div>	
		</div>
	</div>	
</div><!--- end overlaycontainer --->	

		<!---  TODO: Work the special case specimen search showLeftPush and showRightPush sections back into the standard grid divs used everywhere else above.
		<section class="container-fluid">
			<div class="row">
				<div class="col-12">
					<div id="jqxWidget">
						<div class="mb-5">
							<div class="row mx-0">
							<div id="searchResultsGrid" class="jqxGrid"></div>
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
	--->

<script>
	// setup for persistence of column selections
	window.columnHiddenSettings = new Object();
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
		lookupColumnVisibilities ('#cgi.script_name#','Default');
	</cfif>

	// ***** cell renderers *****
	// cell renderer to display a thumbnail with alt tag given columns preview_uri, media_uri, and ac_description 
	var thumbCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
		var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
		var puri = rowData['preview_uri'];
		var muri = rowData['media_uri'];
		var alt = rowData['ac_description'];
		if (puri != "") { 
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="'+ muri + '"><img src="'+puri+'" alt="'+alt+'" width="100"></a></span>';
		} else { 
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+value+'</span>';
		}
	};

	// cell renderer to link out to specimen details page by specimen id
	var linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
		var rowData = jQuery("##searchResultsGrid").jqxGrid('getrowdata',row);
		return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/specimens/Specimen.cfm/' + rowData['COLLECTION_OBJECT_ID'] + '" aria-label="specimen details">'+ rowData['GUID'] +'</a></span>';
	};

	// cell renderer to link out to specimen details page by guid, when value is guid.
	var linkGuidCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
		return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/guid/' + value + '" aria-label="specimen details">'+value+'</a></span>';
	};


	/* execute arbitrary search and populate jqxgrid  */
	function setupGrid(gridId,gridPrefix) { 
		var uuid = getVersion4UUID();
		$("##result_id_"+gridPrefix+"Search").val(uuid);

		$("##overlay").show();

		$("##"+gridPrefix+"searchResultsGrid").replaceWith('<div id="'+gridPrefix+'searchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
		$("##"+gridPrefix+"resultCount").html("");
		$("##"+gridPrefix+"resultLink").html("");
		var debug = $("##"+gridPrefix+"SearchForm").serialize();
		console.log(debug);
		/*var datafieldlist = [ ];//add synchronous call to cf component*/

		var search =
		{
			datatype: "json",
			datafields:
			[
				{name: 'GUID', type: 'string' },
				{name: 'IMAGEURL', type: 'string' },
				{name: 'COLLECTION_OBJECT_ID', type: 'n' },
				{name: 'COLLECTION', type: 'string' },
				{name: 'CAT_NUM', type: 'string' },
				{name: 'BEGAN_DATE', type: 'string' },
				{name: 'ENDED_DATE', type: 'string' },
				{name: 'SCIENTIFIC_NAME', type: 'string' },
				{name: 'SPEC_LOCALITY', type: 'string' },
				{name: 'LOCALITY_ID', type: 'n' },
				{name: 'HIGHER_GEOG', type: 'string' },
				{name: 'COLLECTORS', type: 'string' },
				{name: 'VERBATIM_DATE', type: 'string' },
				{name: 'COLL_OBJECT_DISPOSITION', type: 'string' },
				{name: 'OTHERCATALOGNUMBERS', type: 'string' }
			],
			updaterow: function (rowid, rowdata, commit) {
				commit(true);
			},
			root: 'specimenRecord',
			id: 'collection_object_id',
			url: '/specimens/component/search.cfc?' + $("##"+gridPrefix+"SearchForm").serialize(),
			timeout: 30000,  // units not specified, miliseconds?
			loadError: function(jqXHR, textStatus, error) {
				handleFail(jqXHR,textStatus,error, "Error performing specimen search: "); 
			},
			async: true
		};

		var dataAdapter = new $.jqx.dataAdapter(search);
		var initRowDetails = function (index, parentElement, gridElement, datarecord) {
			// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
			var details = $($(parentElement).children()[0]);
			details.html("<div id='"+gridPrefix+"rowDetailsTarget" + index + "'></div>");
			createRowDetailsDialog(gridId,gridPrefix+'rowDetailsTarget',datarecord,index);
			// Workaround, expansion sits below row in zindex.
			var maxZIndex = getMaxZIndex();
			$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
		}

		$("##"+gridId).jqxGrid({
			width: '100%',
			autoheight: 'true',
			source: dataAdapter,
			filterable: true,
			sortable: true,
			pageable: true,
			editable: false,
			pagesize: '50',
			pagesizeoptions: ['5','50','100'], // reset in gridLoaded
			showaggregates: true,
			columnsresize: true,
			autoshowfiltericon: true,
			autoshowcolumnsmenubutton: false,
			autoshowloadelement: false,  // overlay acts as load element for form+results
			columnsreorder: true,
			groupable: true,
			selectionmode: 'singlerow',
			altrows: true,
			showtoolbar: false,
			ready: function () {
				$("##"+gridId).jqxGrid('selectrow', 0);
			},
			// This part needs to be dynamic
			columns: [
				{text: 'GUID', datafield: 'GUID', width: 130, hidable: false, cellsrenderer: linkGuidCellRenderer },
				{text: 'CollObjectID', datafield: 'COLLECTION_OBJECT_ID', width: 100, hidable: true, hidden: getColHidProp('COLLECTION_OBJECT_ID',true), cellsrenderer: linkIdCellRenderer },
				{text: 'Collection', datafield: 'COLLECTION', width: 150, hidable: true, hidden: getColHidProp('COLLECTION', false) },
				{text: 'Catalog Number', datafield: 'CAT_NUM', width: 130, hidable: true, hidden: getColHidProp('CAT_NUM', false) },
				{text: 'Began Date', datafield: 'BEGAN_DATE', width: 180, cellsformat: 'yyyy-mm-dd', filtertype: 'date', hidable: true, hidden: getColHidProp('BEGAN_DATE', false) },
				{text: 'Ended Date', datafield: 'ENDED_DATE',filtertype: 'date', cellsformat: 'yyyy-mm-dd',width: 180, hidable: true, hidden: getColHidProp('ENDED_DATE', false) },
				{text: 'Scientific Name', datafield: 'SCIENTIFIC_NAME', width: 250, hidable: true, hidden: getColHidProp('SCIENTIFIC_NAME', false) },
				{text: 'Specific Locality', datafield: 'SPEC_LOCALITY', width: 250, hidable: true, hidden: getColHidProp('SPEC_LOCALITY', false) },
				{text: 'Locality by ID', datafield: 'LOCALITY_ID', width: 100, hidable: true, hidden: getColHidProp('LOCALITY_ID', true)  },
				{text: 'Higher Geography', datafield: 'HIGHER_GEOG', width: 280, hidable: true, hidden: getColHidProp('HIGHER_GEOG', false) },
				{text: 'Collectors', datafield: 'COLLECTORS', width: 180, hidable: true, hidden: getColHidProp('COLLECTORS', false) },
				{text: 'Verbatim Date', datafield: 'VERBATIM_DATE', width: 190, hidable: true, hidden: getColHidProp('VERBATIM_DATE', false) },
				{text: 'Other IDs', datafield: 'OTHERCATALOGNUMBERS', hidable: true, hidden: getColHidProp('OTHERCATALOGNUMBERS', false)  }
			],
			rowdetails: true,
			rowdetailstemplate: {
				rowdetails: "<div style='margin: 10px;'>Row Details</div>",
				rowdetailsheight:  1 // row details will be placed in popup dialog
			},
			initrowdetails: initRowDetails
		});

		$("##"+gridId).on("bindingcomplete", function(event) {
			// add a link out to this search, serializing the form as http get parameters
			$('##'+gridPrefix+'resultLink').html('<a href="/Specimens.cfm?execute=true&' + $('##'+gridPrefix+'SearchForm :input').filter(function(index,element){ return $(element).val()!='';}).serialize() + '">Link to this search</a>');
			gridLoaded(gridId,'occurrence record',gridPrefix);
		});
		$('##'+gridId).on('rowexpand', function (event) {
			//  Create a content div, add it to the detail row, and make it into a dialog.
			var args = event.args;
			var rowIndex = args.rowindex;
			var datarecord = args.owner.source.records[rowIndex];
			createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,rowIndex);
		});
		$('##'+gridId).on('rowcollapse', function (event) {
			// remove the dialog holding the row details
			var args = event.args;
			var rowIndex = args.rowindex;
			$("##"+gridPrefix+"searchResultsGridRowDetailsDialog" + rowIndex ).dialog("destroy");
		});
		// display selected row index.
		$("##"+gridId).on('rowselect', function (event) {
			$("##"+gridPrefix+"selectrowindex").text(event.args.rowindex);
		});
		// display unselected row index.
		$("##"+gridId).on('rowunselect', function (event) {
			$("##"+gridPrefix+"unselectrowindex").text(event.args.rowindex);
		});
	}
	/* End Setup jqxgrid for search ****************************************************************************************/

	$(document).ready(function() {
		/* Setup jqxgrid for keyword Search */
		$('##keywordSearchForm').bind('submit', function(evt){ 
			evt.preventDefault();
			setupGrid('keywordsearchResultsGrid','keyword');
		});

		/* Setup jqxgrid for builder Search */
		$('##builderSearchForm').bind('submit', function(evt){
			evt.preventDefault();
			setupGrid('buildersearchResultsGrid','builder');
		});

		/* Setup jqxgrid for fixed Search */
		$('##fixedSearchForm').bind('submit', function(evt){
			evt.preventDefault();
			var uuid = getVersion4UUID();
			$("##result_id_fixedSearch").val(uuid);

			$("##overlay").show();

			$("##fixedsearchResultsGrid").replaceWith('<div id="fixedsearchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
			$('##fixedresultCount').html('');
			$('##fixedresultLink').html('');
			/*var debug = $('##fixedSearchForm').serialize();
			console.log(debug);*/
			/*var datafieldlist = [ ];//add synchronous call to cf component*/

			var search =
			{
				datatype: "json",
				datafields:
				[
					{name: 'GUID', type: 'string' },
					{name: 'IMAGEURL', type: 'string' },
					{name: 'COLLECTION_OBJECT_ID', type: 'n' },
					{name: 'COLLECTION', type: 'string' },
					{name: 'CAT_NUM', type: 'string' },
					{name: 'BEGAN_DATE', type: 'string' },
					{name: 'ENDED_DATE', type: 'string' },
					{name: 'SCIENTIFIC_NAME', type: 'string' },
					{name: 'SPEC_LOCALITY', type: 'string' },
					{name: 'LOCALITY_ID', type: 'n' },
					{name: 'HIGHER_GEOG', type: 'string' },
					{name: 'COLLECTORS', type: 'string' },
					{name: 'VERBATIM_DATE', type: 'string' },
					{name: 'COLL_OBJECT_DISPOSITION', type: 'string' },
					{name: 'OTHERCATALOGNUMBERS', type: 'string' }
				],
				updaterow: function (rowid, rowdata, commit) {
					commit(true);
				},
				root: 'specimenRecord',
				id: 'collection_object_id',
				url: '/specimens/component/search.cfc?' + $('##fixedSearchForm').serialize(),
				timeout: 30000,  // units not specified, miliseconds?
				loadError: function(jqXHR, textStatus, error) {
					handleFail(jqXHR,textStatus,error, "Error performing specimen search: "); 
				},
				async: true
			};

			var dataAdapter = new $.jqx.dataAdapter(search);
			var initRowDetails = function (index, parentElement, gridElement, datarecord) {
				// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
				var details = $($(parentElement).children()[0]);
				details.html("<div id='fixedrowDetailsTarget" + index + "'></div>");
				createRowDetailsDialog('fixedsearchResultsGrid','fixedrowDetailsTarget',datarecord,index);
				// Workaround, expansion sits below row in zindex.
				var maxZIndex = getMaxZIndex();
				$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
			}

			$("##fixedsearchResultsGrid").jqxGrid({
				width: '100%',
				autoheight: 'true',
				source: dataAdapter,
				filterable: true,
				sortable: true,
				pageable: true,
				editable: false,
				pagesize: '50',
				pagesizeoptions: ['5','50','100'], // reset in gridLoaded
				showaggregates: true,
				columnsresize: true,
				autoshowfiltericon: true,
				autoshowcolumnsmenubutton: false,
				autoshowloadelement: false,  // overlay acts as load element for form+results
				columnsreorder: true,
				groupable: true,
				selectionmode: 'singlerow',
				altrows: true,
				showtoolbar: false,
				ready: function () {
					$("##fixedsearchResultsGrid").jqxGrid('selectrow', 0);
				},
				// This part needs to be dynamic.
				columns: [
					{text: 'GUID', datafield: 'GUID', width: 130, hidable: false, cellsrenderer: linkGuidCellRenderer },
					{text: 'CollObjectID', datafield: 'COLLECTION_OBJECT_ID', width: 100, hidable: true, hidden: getColHidProp('COLLECTION_OBJECT_ID',true), cellsrenderer: linkIdCellRenderer },
					{text: 'Collection', datafield: 'COLLECTION', width: 150, hidable: true, hidden: getColHidProp('COLLECTION', false) },
					{text: 'Catalog Number', datafield: 'CAT_NUM', width: 130, hidable: true, hidden: getColHidProp('CAT_NUM', false) },
					{text: 'Began Date', datafield: 'BEGAN_DATE', width: 180, cellsformat: 'yyyy-mm-dd', filtertype: 'date', hidable: true, hidden: getColHidProp('BEGAN_DATE', false) },
					{text: 'Ended Date', datafield: 'ENDED_DATE',filtertype: 'date', cellsformat: 'yyyy-mm-dd',width: 180, hidable: true, hidden: getColHidProp('ENDED_DATE', false) },
					{text: 'Scientific Name', datafield: 'SCIENTIFIC_NAME', width: 250, hidable: true, hidden: getColHidProp('SCIENTIFIC_NAME', false) },
					{text: 'Specific Locality', datafield: 'SPEC_LOCALITY', width: 250, hidable: true, hidden: getColHidProp('SPEC_LOCALITY', false) },
					{text: 'Locality by ID', datafield: 'LOCALITY_ID', width: 100, hidable: true, hidden: getColHidProp('LOCALITY_ID', true)  },
					{text: 'Higher Geography', datafield: 'HIGHER_GEOG', width: 280, hidable: true, hidden: getColHidProp('HIGHER_GEOG', false) },
					{text: 'Collectors', datafield: 'COLLECTORS', width: 180, hidable: true, hidden: getColHidProp('COLLECTORS', false) },
					{text: 'Verbatim Date', datafield: 'VERBATIM_DATE', width: 190, hidable: true, hidden: getColHidProp('VERBATIM_DATE', false) },
					{text: 'Other IDs', datafield: 'OTHERCATALOGNUMBERS', hidable: true, hidden: getColHidProp('OTHERCATALOGNUMBERS', false)  }
				],
				rowdetails: true,
				rowdetailstemplate: {
					rowdetails: "<div style='margin: 10px;'>Row Details</div>",
					rowdetailsheight:  1 // row details will be placed in popup dialog
				},
				initrowdetails: initRowDetails
			});

			$("##fixedsearchResultsGrid").on("bindingcomplete", function(event) {
				// add a link out to this search, serializing the form as http get parameters
				$('##fixedresultLink').html('<a href="/Specimens.cfm?execute=true&' + $('##fixedSearchForm :input').filter(function(index,element){ return $(element).val()!='';}).serialize() + '">Link to this search</a>');
				gridLoaded('fixedsearchResultsGrid','occurrence record','fixed');
			});
			$('##fixedsearchResultsGrid').on('rowexpand', function (event) {
				//  Create a content div, add it to the detail row, and make it into a dialog.
				var args = event.args;
				var rowIndex = args.rowindex;
				var datarecord = args.owner.source.records[rowIndex];
				createRowDetailsDialog('searchResultsGrid','rowDetailsTarget',datarecord,rowIndex);
			});
			$('##fixedsearchResultsGrid').on('rowcollapse', function (event) {
				// remove the dialog holding the row details
				var args = event.args;
				var rowIndex = args.rowindex;
				$("##fixedsearchResultsGridRowDetailsDialog" + rowIndex ).dialog("destroy");
			});
			// display selected row index.
			$("##fixedsearchResultsGrid").on('rowselect', function (event) {
				$("##fixedselectrowindex").text(event.args.rowindex);
			});
			// display unselected row index.
			$("##fixedsearchResultsGrid").on('rowunselect', function (event) {
				$("##fixedunselectrowindex").text(event.args.rowindex);
			});
		});
		/* End Setup jqxgrid for keyword Search ****************************************************************************************/
 
		// If requested in uri, execute search immediately.
		<cfif isdefined("execute")>
			<cfswitch expression="#execute#">
				<cfcase value="keyword">
					$('##keywordSearchForm').submit();
				</cfcase>
					<cfcase value="builder">
					$('##builderSearchForm').submit();
				</cfcase>
					<cfcase value="fixed">
					$('##fixedSearchForm').submit();
				</cfcase>
			</cfswitch>
		</cfif>
	}); /* End document.ready */


	function gridLoaded(gridId, searchType, whichGrid) {
			if (Object.keys(window.columnHiddenSettings).length == 0) { 
				window.columnHiddenSettings = getColumnVisibilities(gridId);		
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					saveColumnVisibilities('#cgi.script_name#',window.columnHiddenSettings,'Default');
				</cfif>
			}
			$("##overlay").hide();
			$('.jqx-header-widget').css({'z-index': maxZIndex + 1 });
			var now = new Date();
			var nowstring = now.toISOString().replace(/[^0-9TZ]/g,'_');
			var filename = searchType + '_results_' + nowstring + '.csv';
			// display the number of rows found
			var datainformation = $('##' + gridId).jqxGrid('getdatainformation');
			var rowcount = datainformation.rowscount;
			if (rowcount == 1) {
				$('##'+whichGrid+'resultCount').html('Found ' + rowcount + ' ' + searchType);
			} else {
				$('##'+whichGrid+'resultCount').html('Found ' + rowcount + ' ' + searchType + 's');
			}
			// set maximum page size
			if (rowcount > 100) {
				$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','50', '100', rowcount],pagesize: 50});
				$('##' + gridId).jqxGrid({ pagesize: 50});
			} else if (rowcount > 50) {
				$('##' + gridId).jqxGrid({ pagesizeoptions: ['5','50', rowcount],pagesize: 50});
				$('##' + gridId).jqxGrid({ pagesize: 50});
			} else {
				$('##' + gridId).jqxGrid({ pageable: false });
			}
			// add a control to show/hide columns
			var columns = $('##' + gridId).jqxGrid('columns').records;
			var halfcolumns = Math.round(columns.length/2);
			var columnListSource = [];
			for (i = 1; i < halfcolumns; i++) {
				var text = columns[i].text;
				var datafield = columns[i].datafield;
				var hideable = columns[i].hideable;
				var hidden = columns[i].hidden;
				var show = ! hidden;
				if (hideable == true) {
					var listRow = { label: text, value: datafield, checked: show };
					columnListSource.push(listRow);
				}
			}
			$("##"+whichGrid+"columnPick").jqxListBox({ source: columnListSource, autoHeight: true, width: '260px', checkboxes: true });
			$("##"+whichGrid+"columnPick").on('checkChange', function (event) {
				$("##" + gridId).jqxGrid('beginupdate');
				if (event.args.checked) {
					$("##" + gridId).jqxGrid('showcolumn', event.args.value);
				} else {
					$("##" + gridId).jqxGrid('hidecolumn', event.args.value);
				}
				$("##" + gridId).jqxGrid('endupdate');
			});
			var columnListSource1 = [];
			for (i = halfcolumns; i < columns.length; i++) {
				var text = columns[i].text;
				var datafield = columns[i].datafield;
				var hideable = columns[i].hideable;
				var hidden = columns[i].hidden;
				var show = ! hidden;
				if (hideable == true) {
					var listRow = { label: text, value: datafield, checked: show };
					columnListSource1.push(listRow);
				}
			}
			$("##"+whichGrid+"columnPick1").jqxListBox({ source: columnListSource1, autoHeight: true, width: '260px', checkboxes: true });
			$("##"+whichGrid+"columnPick1").on('checkChange', function (event) {
				$("##" + gridId).jqxGrid('beginupdate');
				if (event.args.checked) {
					$("##" + gridId).jqxGrid('showcolumn', event.args.value);
				} else {
					$("##" + gridId).jqxGrid('hidecolumn', event.args.value);
				}
				$("##" + gridId).jqxGrid('endupdate');
			});
			$("##"+whichGrid+"columnPickDialog").dialog({
				height: 'auto',
				width: 'auto',
				adaptivewidth: true,
				title: 'Show/Hide Columns',
				autoOpen: false,
				modal: true,
				reszable: true,
				buttons: [
					{
						text: "Ok",
						click: function(){ 
							window.columnHiddenSettings = getColumnVisibilities(gridId);		
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
								saveColumnVisibilities('#cgi.script_name#',window.columnHiddenSettings,'Default');
							</cfif>
							$(this).dialog("close"); 
						},
						tabindex: 0
					}
				],
				open: function (event, ui) {
					var maxZIndex = getMaxZIndex();
					// force to lie above the jqx-grid-cell and related elements, see z-index workaround below
					$('.ui-dialog').css({'z-index': maxZIndex + 4 });
					$('.ui-widget-overlay').css({'z-index': maxZIndex + 3 });
				}
			});
			$("##"+whichGrid+"columnPickDialogButton").html(
				`<button id="columnPickDialogOpener" onclick=" $('##`+whichGrid+`columnPickDialog').dialog('open'); " class="btn-xs btn-secondary my-1 mr-1" >Select Columns</button>
				<button id="pinGuidToggle" onclick=" togglePinColumn('`+gridId+`','GUID'); " class="btn-xs btn-secondary mx-1 px-1 py-1 my-2" >Pin GUID Column</button>
				`
			);
			// workaround for menu z-index being below grid cell z-index when grid is created by a loan search.
			// likewise for the popup menu for searching/filtering columns, ends up below the grid cells.
			var maxZIndex = getMaxZIndex();
			$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
			$('.jqx-grid-cell').css({'border-color': '##aaa'});
			$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
			$('.jqx-grid-group-cell').css({'border-color': '##aaa'});
			$('.jqx-menu-wrapper').css({'z-index': maxZIndex + 2});
			$('##'+whichGrid+'resultDownloadButtonContainer').html('<button id="loancsvbutton" class="btn-xs btn-secondary px-3 pb-1 mx-1 mb-1 my-md-2" aria-label="Export results to csv" onclick=" exportGridToCSV(\''+whichGrid+'searchResultsGrid\', \''+filename+'\'); " >Export to CSV</button>');
		}

		function togglePinColumn(gridId,column) { 
			var state = $('##'+gridId).jqxGrid('getcolumnproperty', column, 'pinned');
			$("##"+gridId).jqxGrid('beginupdate');
			if (state==true) {
				$('##'+gridId).jqxGrid('unpincolumn', column);
			} else {
				$('##'+gridId).jqxGrid('pincolumn', column);
			}
			$("##"+gridId).jqxGrid('endupdate');
		}
</script>

<script>
	//this is the search builder main dropdown for all the columns found in flat
	$(document).ready(function(){
		var newControls = '<ul class="row col-md-11 col-sm-12 mx-0 my-4"><li class="d-inline col-sm-12 col-md-1 px-0 mr-2">';
		newControls = newControls + '<select title="Join Operator" name="JoinOperator" id="joinOperator" class="data-entry-select bg-white mx-0 d-flex"><option value="">Join with...</option><option value="and">and</option><option value="or">or</option><option value="not">not</option></select>';
		newControls= newControls + '</li><li class="d-inline mr-2 col-sm-12 px-0 col-md-2">';

		newControls = newControls + '<select title="Select Type..." name="selectType" id="selectType" class="custom-select-sm bg-white form-control-sm border d-flex">';
		newControls = newControls + '<option>Select Type...</option>';
		<cfset category = "">
		<cfset optgroupOpen = false>
		<cfloop query="fields">
			<cfif category NEQ fields.search_category>
				<cfif optgroupOpen>
					newControls = newControls + '</optgroup>';
					<cfset optgroupOpen = false>
				</cfif>
				newControls = newControls + '<optgroup label="fields.search_category">';
				<cfset optgroupOpen = true>
				<cfset category = fields.search_category>
			</cfif>
			newControls = newControls + '<option value="#fields.table_name#:#fields.column_name#">#fields.label#</option>';
		</cfloop>
		<cfif optgroupOpen>
			newControls = newControls + '</optgroup>';
		</cfif>
		newControls = newControls + '</select>';

		newControls = newControls + '</li><li class="d-inline col-sm-12 px-0 mr-2 col-md-2">';
		newControls = newControls + '<select title="Comparator" name="comparator" id="comparator" class="bg-white data-entry-select d-flex"><option value="">Compare with...</option><option value="like">contains</option><option value="eq">is</option></select></li><li class="col d-inline mr-2 px-0"><input type="text" class="data-entry-input" name="customFieldValue[]" id="srchTxt" placeholder="Enter Value"/>';
		newControls = newControls + '</li><li class="d-inline mr-2 col-md-1 col-sm-1 px-0 d-flex justify-content-end">';
		newControls = newControls + '<button href="javascript:void(0);" arial-label="remove" class="btn-xs px-3 btn-primary remCF mr-auto">Remove</button>';
		newControls = newControls + '</li></ul>';
		$(".addCF").click(function(){$("##customFields").append(newControls);
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
	messageDialog("Not implemented yet");
//	var sName=prompt("Name this search", "my search");
//	if (sName!==null){
//		var sn=encodeURIComponent(sName);
//		var ru=encodeURI(returnURL);
//		jQuery.getJSON("/component/functions.cfc",
//			{
//				method : "saveSearch",
//				returnURL : ru,
//				srchName : sn,
//				returnformat : "json",
//				queryformat : 'column'
//			},
//			function (r) {
//				if(r!='success'){
//					alert(r);
//				}
//			}
//		);
//	}
}

</script>
<!---  script>
TODO: indentation is broken, and this references ids not present on the page, so it breaks this block.  Remove or add back in if left/right blocks for faceted search are added back in.
TODO: Fix the indentation and nestinng, this looks like one function, but isn't.

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
</script --->
<script>
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
