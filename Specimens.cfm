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
	<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
		<!--- logged in users now able to see redesigned specimen search on production --->
	<cfelse>
		<cfscript>
			getPageContext().forward("/SpecimenSearch.cfm");
		</cfscript>
	</cfif>
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

<cfquery name="ctCollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT
		collection_cde,
		collection,
		collection_id
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
<cfquery name="ctother_id_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT count(*) ct, ct.other_id_type 
	FROM ctcoll_other_id_type ct
		left join coll_obj_other_id_num co on ct.other_id_type = co.other_id_type
	GROUP BY ct.other_id_type 
	ORDER BY ct.other_id_type
</cfquery>
<cfquery name="ctnature_of_id" datasource="cf_dbuser" cachedwithin="#createtimespan(0,0,60,0)#">
	SELECT nature_of_id, count(*) as ct 
	FROM IDENTIFICATION
	GROUP BY nature_of_id
 	ORDER BY nature_of_id
</cfquery>

<cfquery name="column_headers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select column_name, data_type from all_tab_columns where table_name = 'FLAT' and rownum = 1
</cfquery>

<!--- ensure that pass through parameters for linking to a search are defined --->
<cfif NOT isdefined("searchText")>
	<cfset searchText = "">
</cfif>
<cfif not isdefined("collection_cde") AND isdefined("collection_id") AND len(collection_id) GT 0 >
	<!--- if collection id was provided, but not a collection code, lookup the collection code --->
	<cfquery name="lookupCollection_cde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookupCollection_cde_result">
		SELECT
			collection_cde code
		FROM
			collection
		WHERE
			collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
	</cfquery>
	<cfloop query="lookupCollection_cde">
		<cfset collection_cde = lookupCollection_cde.code>
		<cfset collection = lookupCollection_cde.code>
	</cfloop>
</cfif>

<cfoutput>
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
					<cfquery name="getSpecimenCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT count(collection_object_id) as cnt FROM cataloged_item
					</cfquery>
					<h1 class="h3 smallcaps pl-1">Find Specimen Records <span class="count  font-italic color-green mx-0"><small> #getSpecimenCount.cnt# records</small></span></h1>
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
							<button class="col-12 col-md-auto px-md-5 my-1 my-md-0 #keywordTabActive#" id="1" role="tab" aria-controls="keywordSearchPanel" #keywordTabAria# >Keyword Search</button>
							<button class="col-12 col-md-auto px-md-5 my-1 my-md-0 #builderTabActive#" id="2" role="tab" aria-controls="builderSearchPanel" #builderTabAria# aria-label="search builder tab">Search Builder</button>
							<button class="col-12 col-md-auto px-md-5 my-1 my-md-0 #fixedTabActive#" id="3" role="tab" aria-controls="fixedSearchPanel" #fixedTabAria#>Fixed Search</button>
						</div>
						<div class="tab-content">
							<!---Keyword Search/results tab panel--->
							<div id="keywordSearchPanel" role="tabpanel" aria-labelledby="1" tabindex="0" class="mx-0 #keywordTabActive#" #keywordTabShow#>
									<div class="col-9 float-right px-0"> 
										<button class="btn btn-xs btn-dark help-btn" type="button" data-toggle="collapse" data-target="##collapseKeyword" aria-expanded="false" aria-controls="collapseKeyword">
													Search Help
										</button>
										<div class="collapse collapseStyle" id="collapseKeyword">
											<div class="card card-body pl-4 py-3 pr-3">
												<h2 class="headerSm">Keyword Search Help</h2>
												<p>This help applies only the keyword search, behavior and operators for other searches are different<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")> (see: <a href="https://code.mcz.harvard.edu/wiki/index.php/Search_Operators" target="_blank">Search Operators</a>). For more examples, see: <a href="https://code.mcz.harvard.edu/wiki/index.php/Keyword_Search" target="_blank">Keyword Search</a></cfif>.</p>
												<dl class="mb-0"> 
													<dt><span class="text-info font-weight-bold">&nbsp;</span></dt>
													<dd>When words are separated by spaces they form a phrase and it is this phrase which is searched for, not the individual words.  For example <em>Panama Bay</em> searches for those two words found adjacent to each other (ignoring punctuation and capitalization). Use operators such as <em>Panama &amp; Bay</em> or <em>NEAR((Panama,Bay),3)</em>, described below, to find a broader scope of records. </dd>
												</dl>
												<h2 class="headerSm">Keyword Search Operators</h2>
												<dl class="mb-0"> 
													<dt><span class="text-info font-weight-bold">&amp;</span></dt>
													<dd>The "and" operator, matches records where the search terms on both sides of the &amp; are present somewhere in the record.</dd>
													<dt><span class="text-info font-weight-bold">|</span></dt>
													<dd>The "or" operator, matches words where at least one of the search terms is present somewhere in the record.</dd>
													<dt><span class="text-info font-weight-bold">!</span></dt>
													<dd>The exclamation mark finds records that contain the first term but not the second (e.g., Panama ! Canal). Results returned would include "Panama" but not "Canal".</dd>
													<dt><span class="text-info font-weight-bold">NEAR((term,term2),distance) &nbsp;&nbsp;</span></dt>
													<dd>The NEAR((term,term2),distance) finds words that are nearby each other (e.g. NEAR((Panama,Bay),3) finds records where Panama and Bay are within three words of each other). Example of results: "San Miguel Id Bay of Panama" and "Bay of Panama, Dan Miguel Id".</dd>
													<dt><span class="text-info font-weight-bold">=</span></dt>
													<dd>The word equivalence operator, either word is interchangeable in the phrase (e.g., Taboga Island=Id). The results would return rows with "Taboga Island" or "Taboga Id".</dd>
													<dt><span class="text-info font-weight-bold">FUZZY(term) &nbsp;&nbsp;</span> </dt>
													<dd>This finds words that are a fuzzy match to the specified term, fuzzy matching can include variations (e.g. misspellings, typos) anywhere in the term (e.g., FUZZY(Taboga)).</dd>
													<dt><span class="text-info font-weight-bold">$</span></dt>
													<dd>The soundex symbol "$" finds words that sound like the specified term, unlike fuzzy matching, soundex tends to find words that are similar in the first few letters and vary at the end (e.g., $Rongelap finds records that contain words which sound like Rongelap. Soundex can be good for finding alternate endings on specific epithets of taxa).</dd>
													<dt><span class="text-info font-weight-bold">##</span></dt> 
													<dd>The stem operator finds words with the same linguistic stem as the search term, e.g. ##forest finds words with the same stem as forest such as forested or forests.</dd>
													<dt><span class="text-info font-weight-bold">( )</span></dt>
													<dd>Parentheses can be used to group terms for complex operations (e.g. Basiliscus &amp; (FUZZY(Honduras) | (Panama ! Canal)) will return results with a fuzzy match to Honduras, or Panama but not Canal).</dd>
													<dt><span class="text-info font-weight-bold">%</span></dt> 
													<dd>The percent wildcard, matches any number of characters, e.g. %bridge matches Cambridge, bridge, and Stockbridge.</dd>
													<dt><span class="text-info font-weight-bold">_</span> </dt><dd> The underscore wildcard, matches exactly one character and allows for any character to takes its place.</dd>
												</dl>
											</div>
										</div>
									</div>
								<section role="search" class="container-fluid">
								
									<form name= "keywordSearchForm" id="keywordSearchForm">
										<input id="result_id_keywordSearch" type="hidden" name="result_id" value="" class="excludeFromLink">
										<input type="hidden" name="method" value="executeKeywordSearch" class="keeponclear excludeFromLink">
										<input type="hidden" name="action" value="keywordSearch" class="keeponclear">
										<div class="row">
											<div class="input-group mt-1">
												<div class="input-group-btn col-12 col-sm-5 col-md-5 col-xl-3">
													<label for="keywordCollection" class="data-entry-label">Limit to Collection(s)</label>
													<div name="collection_cde" id="keywordCollection" class="w-100 data-entry-select"></div>
													<cfif not isdefined("collection_cde")><cfset collection_cde=""></cfif>
													<cfset collection_array = ListToArray(collection_cde)>
													<script>
														function setKeywordCollectionValues() {
															$('##keywordCollection').jqxComboBox('clearSelection');
															<cfloop query="ctCollection">
																<cfif ArrayContains(collection_array, ctCollection.collection_cde)>
																	$("##keywordCollection").jqxComboBox("selectItem","#ctCollection.collection_cde#");
																</cfif>
															</cfloop>
														};
														$(document).ready(function () {
															var collectionsource = [
																<cfset comma="">
																<cfloop query="ctCollection">
																	#comma#{name:"#ctCollection.collection#",cde:"#ctCollection.collection_cde#"}
																	<cfset comma=",">
																</cfloop>
															];
															$("##keywordCollection").jqxComboBox({ source: collectionsource, displayMember:"name", valueMember:"cde", multiSelect: true, height: '23px', width: '100%' });
															setKeywordCollectionValues();
														});
													</script> 
												</div>
												<div class="col-12 col-sm-7 col-md-7 col-xl-6 pl-md-0">
													<label for="searchText" class="data-entry-label">Keyword(s)</label>
													<input id="searchText" type="text" class="data-entry-input py-1" name="searchText" placeholder="Search term" aria-label="search text" value="#searchText#">
												</div>
												<div class="col-12 col-xl-2">
													<cfif findNoCase('redesign',gitBranch) GT 0 OR (isdefined("session.roles") and listfindnocase(session.roles,"global_admin") ) >
														<label class="data-entry-label" for="debug">Debug</label>
														<select title="debug" name="debug" id="dbug" class="data-entry-select">
															<option value=""></option>
															<cfif isdefined("debug") AND len(debug) GT 0><cfset selected=" selected "><cfelse><cfset selected=""></cfif>
															<option value="true" #selected#>Debug JSON</option>
														</select>
													</cfif>
												</div>
											</div>
										</div>
										<div class="form-row my-3">
											<div class="col-12">
												<label for="keySearch" class="sr-only">Keyword search button - click to search MCZbase</label>
												<button type="submit" class="btn btn-xs btn-primary col-12 col-md-auto px-md-5 mx-0 mr-md-5 my-1" id="keySearch" aria-label="Keyword Search of MCZbase"> Search <i class="fa fa-search"></i> </button>
												<button type="reset" class="btn btn-xs btn-warning col-12 col-md-auto px-md-3 mr-md-2 mx-0 my-1" aria-label="Reset this search form to inital values">Reset</button>
												<button type="button" class="btn btn-xs btn-warning col-12 col-md-auto px-md-3 mr-md-2 mx-0 my-1" aria-label="Start a new specimen search with a clear page" onclick="window.location.href='#Application.serverRootUrl#/Specimens.cfm?action=keywordSearch';">New Search</button>
											</div>
										</div>
									</form>
								

								</section>
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
																<div class="col-12 col-md-3">
																	<div id="keywordcolumnPick" class="px-1"></div>
																</div>
																<div class="col-12 col-md-3">
																	<div id="keywordcolumnPick1" class="px-1"></div>
																</div>
																<div class="col-12 col-md-3">
																	<div id="keywordcolumnPick2" class="px-1"></div>
																</div>
																<div class="col-12 col-md-3">
																	<div id="keywordcolumnPick3" class="px-1"></div>
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
										<script>
											// bind autocomplete to text input/hidden input, and other actions on field selection
											function handleFieldSelection(fieldSelect,rowNumber) { 
												var selection = $('##'+fieldSelect).val();
												console.log(selection);
												console.log(rowNumber);
												for (var i=0; i<columnMetadata.length; i++) {
													if(selection==columnMetadata[i].column) {
														// remove any existing binding.
														$('##searchId'+rowNumber).val("");
														try { 
															$('##searchText'+rowNumber).autocomplete("destroy");
														} catch {}
														$('##searchText'+rowNumber).val("");
														console.log(columnMetadata[i].ui_function);
														if (columnMetadata[i].ui_function) {
															var invokeBinding = Function(columnMetadata[i].ui_function+"('searchText"+ rowNumber+"','searchId"+ rowNumber+"')");
															invokeBinding(); 
														}
													}
												}
											}
											// bind autocomplete to text input/hidden input, but don't clear existing values, used on intial page load.
											function handleFieldSetup(fieldSelect,rowNumber) { 
												var selection = $('##'+fieldSelect).val();
												console.log(selection);
												console.log(rowNumber);
												for (var i=0; i<columnMetadata.length; i++) {
													if(selection==columnMetadata[i].column) {
														console.log(columnMetadata[i].ui_function);
														if (columnMetadata[i].ui_function) {
															var invokeBinding = Function(columnMetadata[i].ui_function+"('searchText"+ rowNumber+"','searchId"+ rowNumber+"')");
															invokeBinding(); 
														}
													}
												}
											}
										</script>
										<cfif not isDefined("builderMaxRows") or len(builderMaxRows) eq 0>
											<cfset builderMaxRows = 1>
										</cfif>
										<input type="hidden" id="builderMaxRows" name="builderMaxRows" value="#builderMaxRows#">
										<input id="result_id_builderSearch" type="hidden" name="result_id" value="" class="excludeFromLink">
										<input type="hidden" name="method" value="executeBuilderSearch" class="keeponclear excludeFromLink">
										<input type="hidden" name="action" value="builderSearch" class="keeponclear">
										<div class="form-row mx-0">
											<div class="mt-1 col-12 p-0 my-2" id="customFields">
												<div class="form-row mb-2">
													<div class="col-12 col-md-1 pt-3">
														<a aria-label="Add more search criteria" class="btn btn-xs btn-primary addCF rounded px-2 mr-md-auto" target="_self" href="javascript:void(0);">Add</a>
													</div>
													<div class="col-12 col-md-1">
														<label for="nestbutton" class="data-entry-label">Nest</label>
														<button id="nestbutton" type="button" class="btn btn-xs btn-secondary" onclick="messageDialog('Not implemented yet');">&gt;</button>
													</div>
													<div class="col-12 col-md-4">
														<cfquery name="fields" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="fields_result">
															SELECT search_category, table_name, column_name, column_alias, data_type, 
																label, access_role, ui_function
															FROM cf_spec_search_cols
															WHERE	
																<cfif oneOfUs EQ 0>
																	access_role = 'PUBLIC'
																<cfelse>
																	access_role IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="PUBLIC,#session.roles#" list="yes">)
																</cfif>
																AND access_role <> 'HIDE'
															ORDER BY
																search_category, label, table_name
														</cfquery>
														<cfset columnMetadata = "[">
														<cfset comma = "">
														<cfloop query="fields">
															<cfset columnMetadata = '#columnMetadata##comma#{"column":"#fields.table_name#:#fields.column_alias#","data_type":"#fields.data_type#","ui_function":"#fields.ui_function#"}'>
															<cfset comma = ",">
														</cfloop>
														<cfset columnMetadata = "#columnMetadata#]">
														<script>
															var columnMetadata = JSON.parse('#columnMetadata#');
														</script>
														<label for="field1" class="data-entry-label">Search Field</label>
														<cfif not isDefined("field1")><cfset field1=""></cfif>
														<select title="Select Field to search..." name="field1" id="field1" class="data-entry-select" required>
															<cfif len(field1) EQ 0>
																<optgroup label="Select a field to search...."><option value="" selected></option></optgroup>
															</cfif>
															<cfset category = "">
															<cfset optgroupOpen = false>
															<cfloop query="fields">
																<cfif category NEQ fields.search_category>
																	<cfif optgroupOpen>
																		</optgroup>
																		<cfset optgroupOpen = false>
																	</cfif>
																	<optgroup label="#fields.search_category#">
																	<cfset optgroupOpen = true>
																	<cfset category = fields.search_category>
																</cfif>
																<cfif field1 EQ "#fields.table_name#:#fields.column_alias#"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
																<option value="#fields.table_name#:#fields.column_alias#" #selected#>#fields.label# (#fields.search_category#:#fields.table_name#)</option>
															</cfloop>
															<cfif optgroupOpen>
																</optgroup>
															</cfif>
														</select>
														<script>
															$(document).ready(function() { 
																$('##field1').jqxComboBox({
																	autoComplete: true,
																	searchMode: 'containsignorecase',
																	width: '100%',
																	dropDownHeight: 400,
																});
																$('##field1').on("select", function(event) { 
																	handleFieldSelection('field1',1);
																});
																handleFieldSetup('field1',1);
															});
														</script>
													</div>
													<cfif findNoCase('redesign',gitBranch) GT 0 OR (isdefined("session.roles") and listfindnocase(session.roles,"global_admin") ) >
														<cfset searchcol="col-md-5">
													<cfelse>
														<cfset searchcol="col-md-1">
													</cfif>
													<div class="col-12 #searchcol#">
														<cfif not isDefined("searchText1")><cfset searchText1=""></cfif>
														<cfif not isDefined("searchId1")><cfset searchId1=""></cfif>
														<!--- TODO: Add javascript to modify inputs depending on selected field. --->
														<label for="searchText1" class="data-entry-label">Search For</label>
														<input type="text" class="form-control-sm d-flex data-entry-input mx-0" name="searchText1" id="searchText1" value="#searchText1#" required>
														<input type="hidden" name="searchId1" id="searchId1" value="#searchId1#">
														<input type="hidden" name="joinOperator1" id="joinOperator1" value="">
													</div>
													<cfif findNoCase('redesign',gitBranch) GT 0 OR (isdefined("session.roles") and listfindnocase(session.roles,"global_admin") ) >
														<div class="col-12 col-md-1">
															<label class="data-entry-label" for="debug">Debug</label>
															<select title="debug" name="debug" id="dbug" class="data-entry-select">
																<option value=""></option>
																<cfif isdefined("debug") AND len(debug) GT 0><cfset selected=" selected "><cfelse><cfset selected=""></cfif>
																<option value="true" #selected#>Debug JSON</option>
															</select>
														</div>
													</cfif>
												</div>
												<cfif builderMaxRows GT 1>
													<cfloop index="row" from="2" to="#builderMaxRows#">
														<cfif isDefined("field#row#")>
															<div class="form-row mb-2" id="builderRow#row#">
																<div class="col-12 col-md-1">
																	&nbsp;
																</div>
																<div class="col-12 col-md-1">
																	<button type="button" class="btn btn-xs btn-secondary" onclick="messageDialog('Not implemented yet');">&gt;</button>
																</div>
																<div class="col-12 col-md-1">
																	<select title="Join Operator" name="JoinOperator#row#" id="joinOperator#row#" class="data-entry-select bg-white mx-0 d-flex">
																		<cfif isDefined("joinOperator#row#") AND Evaluate("joinOperator#row#") EQ "or">
																			<cfset orSel = "selected">
																			<cfset andSel = "">
																		<cfelse>
																			<cfset orSel = "">
																			<cfset andSel = "selected">
																		</cfif>
																		<option value="and" #andSel# >and</option>
																		<option value="or" #orSel# >or</option>
																	</select>
																</div>
																<div class="col-12 col-md-3">
																	<select title="Select Field..." name="field#row#" id="field#row#" class="data-entry-select">
																		<cfset category = "">
																		<cfset optgroupOpen = false>
																		<cfloop query="fields">
																			<cfif category NEQ fields.search_category>
																				<cfif optgroupOpen>
																					</optgroup>
																					<cfset optgroupOpen = false>
																				</cfif>
																				<optgroup label="#fields.search_category#">
																				<cfset optgroupOpen = true>
																				<cfset category = fields.search_category>
																			</cfif>
																			<cfif Evaluate("field#row#") EQ "#fields.table_name#:#fields.column_alias#"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
																			<option value="#fields.table_name#:#fields.column_alias#" #selected#>#fields.label# (#fields.search_category#:#fields.table_name#)</option>
																		</cfloop>
																		<cfif optgroupOpen>
																			</optgroup>
																		</cfif>
																	</select>
																	<script>
																		$(document).ready(function() { 
																			$('##field#row#').jqxComboBox({
																				autoComplete: true,
																				searchMode: 'containsignorecase',
																				width: '100%',
																				dropDownHeight: 400
																			});
																			// bind an autocomplete, if one applies.
																			handleFieldSetup('field#row#',#row#);
																		});
																		$('##field#row#').on("select", function(event) { 
																			handleFieldSelection('field#row#',#row#);
																		});
																	</script>
																</div>
																<div class="col-12 col-md-5">
																	<cfif isDefined("searchText#row#")><cfset sval = Evaluate("searchText#row#")><cfelse><cfset sval=""></cfif>
																	<cfif isDefined("searchId#row#")><cfset sival = Evaluate("searchId#row#")><cfelse><cfset sival=""></cfif>
																	<input type="text" class="data-entry-input" name="searchText#row#" id="searchText#row#" placeholder="Enter Value" value="#sval#">
																	<input type="hidden" name="searchId#row#" id="searchId#row#" value="#sival#" >
																</div>
																<div class="col-12 col-md-1">
																	<button type='button' onclick=' $("##builderRow#row#").remove();' arial-label='remove' class='btn btn-xs px-3 btn-warning mr-auto'>Remove</button>
																</div>
															</div>
														</cfif>
													</cfloop>
												</cfif>

											</div><!--- end customFields: new form rows get appended here --->
											<script>
												//this is the search builder main dropdown for all the columns found in flat
												$(document).ready(function(){
													$(".addCF").click(function(){
														var row = $("##builderMaxRows").val();
														row = parseInt(row) + 1;
														var newControls = '<div class="form-row mb-2" id="builderRow'+row+'">';
														newControls = newControls + '<div class="col-12 col-md-1">&nbsp;';
														newControls = newControls + '</div>';
														newControls = newControls + '<div class="col-12 col-md-1">';
														newControls = newControls + '<button type="button" class="btn btn-xs btn-secondary" onclick="messageDialog(\'Not implemented yet\');">&gt;</button>';
														newControls = newControls + '</div>';
														newControls = newControls + '<div class="col-12 col-md-1">';
														newControls = newControls + '<select title="Join Operator" name="JoinOperator'+row+'" id="joinOperator'+row+'" class="data-entry-select bg-white mx-0 d-flex"><option value="and">and</option><option value="or">or</option></select>';
														newControls= newControls + '</div>';
														newControls= newControls + '<div class="col-12 col-md-3">';
														newControls = newControls + '<select title="Select Field..." name="field'+row+'" id="field'+row+'" class="data-entry-select">';
														newControls = newControls + '<optgroup label="Select a field to search...."><option value="" selected></option></optgroup>';
														<cfset category = "">
														<cfset optgroupOpen = false>
														<cfloop query="fields">
															<cfif category NEQ fields.search_category>
																<cfif optgroupOpen>
																	newControls = newControls + '</optgroup>';
																	<cfset optgroupOpen = false>
																</cfif>
																newControls = newControls + '<optgroup label="#fields.search_category#">';
																<cfset optgroupOpen = true>
																<cfset category = fields.search_category>
															</cfif>
															newControls = newControls + '<option value="#fields.table_name#:#fields.column_alias#">#fields.label# (#fields.search_category#:#fields.table_name#)</option>';
														</cfloop>
														<cfif optgroupOpen>
															newControls = newControls + '</optgroup>';
														</cfif>
														newControls = newControls + '</select>';
														newControls= newControls + '</div>';
														newControls= newControls + '<div class="col-12 col-md-5">';
														newControls = newControls + '<input type="text" class="data-entry-input" name="searchText'+row+'" id="searchText'+row+'" placeholder="Enter Value"/>';
														newControls = newControls + '<input type="hidden" name="searchId'+row+'" id="searchId'+row+'" >';
														newControls= newControls + '</div>';
														newControls= newControls + '<div class="col-12 col-md-1">';
														newControls = newControls + `<button type='button' onclick=' $("##builderRow` + row + `").remove();' arial-label='remove' class='btn btn-xs px-3 btn-warning mr-auto'>Remove</button>`;
														newControls = newControls + '</div>';
														newControls = newControls + '</div>';
														$("##customFields").append(newControls);
														$("##builderMaxRows").val(row);
														$('##field' + row).jqxComboBox({
															autoComplete: true,
															searchMode: 'containsignorecase',
															width: '100%',
															dropDownHeight: 400
														});
														var handleSelectString = "handleFieldSelection('field"+row+"',"+row+")";
														$('##field'+row).on("change", function(event) { 
															var handleSelect = new Function(handleSelectString);
															handleSelect();
														});
													});
												});
											</script>
										</div>
										<div class="form-row mb-3">
											<div class="col-12">
												<button type="submit" class="btn btn-xs btn-primary col-12 col-md-auto px-md-5 mx-0 mr-md-5 my-1" id="searchbuilder-search" aria-label="run the search builder search">Search <i class="fa fa-search"></i></button>
												<button type="reset" class="btn btn-xs btn-warning col-12 col-md-auto px-md-3 mr-md-2 mx-0 my-1" aria-label="Reset this search form to inital values">Reset</button>
												<button type="button" class="btn btn-xs btn-warning col-12 col-md-auto px-md-3 mr-md-2 mx-0 my-1" aria-label="Start a new specimen search with a clear page" onclick="window.location.href='#Application.serverRootUrl#/Specimens.cfm?action=builderSearch';">New Search</button>
												<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
													<!--- TODO: Move to top of search results bar, available after running search --->
													<!--- TODO: Add handler to carry out this action --->
													<!--- 
													<button type="button" class="btn btn-xs btn-primary col-12 col-md-auto px-md-3 mx-0 my-1" id="save-account" aria-label="save this search">
														Save to My Account <i class="fa fa-user-cog"></i>
													</button>
													--->
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
																<div class="col-12 col-md-3">
																	<div id="buildercolumnPick" class="px-1"></div>
																</div>
																<div class="col-12 col-md-3">
																	<div id="buildercolumnPick1" class="px-1"></div>
																</div>
																<div class="col-12 col-md-3">
																	<div id="buildercolumnPick2" class="px-1"></div>
																</div>
																<div class="col-12 col-md-3">
																	<div id="buildercolumnPick3" class="px-1"></div>
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
										<input type="hidden" name="result_id" id="result_id_fixedSearch" value="" class="excludeFromLink">
										<input type="hidden" name="method" id="method_fixedSearch" value="executeFixedSearch" class="keeponclear excludeFromLink">
										<input type="hidden" name="action" value="fixedSearch" class="keeponclear">
										<div class="container-flex">
											<div class="form-row mb-2">
												<div class="col-12 col-md-3">
													<label for="fixedCollection" class="data-entry-label">Collection</label>
													<div name="collection" id="fixedCollection" class="w-100"></div>
													<cfif not isdefined("collection")><cfset collection=""></cfif>
													<cfset collection_array = ListToArray(collection)>
													<script>
														function setFixedCollectionValues() {
															$('##fixedCollection').jqxComboBox('clearSelection');
															<cfloop query="ctCollection">
																<cfif ArrayContains(collection_array, ctCollection.collection_cde)>
																	$("##fixedCollection").jqxComboBox("selectItem","#ctCollection.collection_cde#");
																</cfif>
															</cfloop>
														};
														$(document).ready(function () {
															var collectionsource = [
																<cfset comma="">
																<cfloop query="ctCollection">
																	#comma#{name:"#ctCollection.collection#",cde:"#ctCollection.collection_cde#"}
																	<cfset comma=",">
																</cfloop>
															];
															$("##fixedCollection").jqxComboBox({ source: collectionsource, displayMember:"name", valueMember:"cde", multiSelect: true, height: '23px', width: '100%' });
															setFixedCollectionValues();
														});
													</script> 
												</div>
												<div class="col-12 col-md-3">
													<cfif not isdefined("cat_num")><cfset cat_num=""></cfif>
													<label for="catalogNum" class="data-entry-label">Catalog Number</label>
													<input id="catalogNum" type="text" name="cat_num" class="data-entry-input" placeholder="1,1-4,A-1,R1-4" value="#cat_num#">
												</div>
												<div class="col-12 col-md-3">
													<cfif not isdefined("other_id_type")><cfset other_id_type=""></cfif>
													<label for="otherID" class="data-entry-label">Other ID Type</label>
													<div name="other_id_type" id="other_id_type" class="w-100"></div>
													<cfset otheridtype_array = ListToArray(other_id_type)>
													<script>
														function setOtherIdTypeValues() {
															$('##other_id_type').jqxComboBox('clearSelection');
															<cfloop query="ctother_id_type">
																<cfif ArrayContains(otheridtype_array, ctother_id_type.other_id_type)>
																	$("##other_id_type").jqxComboBox("selectItem","#ctother_id_type.other_id_type#");
																</cfif>
															</cfloop>
														};
														$(document).ready(function () {
															var otheridtypesource = [
																<cfset comma="">
																<cfloop query="ctother_id_type">
																	#comma#{name:"#ctother_id_type.other_id_type#",meta:"#ctother_id_type.other_id_type# (#ctother_id_type.ct#)"}
																	<cfset comma=",">
																</cfloop>
															];
															$("##other_id_type").jqxComboBox({ source: otheridtypesource, displayMember:"meta", valueMember:"name", multiSelect: true, height: '23px', width: '100%' });
															setOtherIdTypeValues();
														});
													</script> 
												</div>
												<div class="col-12 col-md-3">
													<cfif not isdefined("other_id_number")><cfset other_id_number=""></cfif>
													<label for="other_id_number" class="data-entry-label">Other ID Numbers</label>
													<input type="text" class="data-entry-input" id="other_id_number" name="other_id_number" placeholder="10,20-30,=BT-782" value="#other_id_number#">
												</div>
											</div>
											<cfif findNoCase('redesign',gitBranch) GT 0 OR (isdefined("session.roles") and listfindnocase(session.roles,"collops") ) >
												<!--- for now, while testing nesting, only show second other ID controls for collops users.  --->
												<div class="form-row mb-2">
													<div class="col-12 col-md-3">
														<cfif not isdefined("other_id_type_1")><cfset other_id_type_1=""></cfif>
														<label for="otherID" class="data-entry-label">Other ID Type</label>
														<div name="other_id_type_1" id="other_id_type_1" class="w-100"></div>
														<cfset otheridtype_array = ListToArray(other_id_type_1)>
														<script>
															function setOtherIdType_1_Values() {
																$('##other_id_type_1').jqxComboBox('clearSelection');
																<cfloop query="ctother_id_type">
																	<cfif ArrayContains(otheridtype_array, ctother_id_type.other_id_type)>
																		$("##other_id_type_1").jqxComboBox("selectItem","#ctother_id_type.other_id_type#");
																	</cfif>
																</cfloop>
															};
															$(document).ready(function () {
																var otheridtypesource = [
																	<cfset comma="">
																	<cfloop query="ctother_id_type">
																		#comma#{name:"#ctother_id_type.other_id_type#",meta:"#ctother_id_type.other_id_type# (#ctother_id_type.ct#)"}
																		<cfset comma=",">
																	</cfloop>
																];
																$("##other_id_type_1").jqxComboBox({ source: otheridtypesource, displayMember:"meta", valueMember:"name", multiSelect: true, height: '23px', width: '100%' });
																setOtherIdType_1_Values();
															});
														</script> 
													</div>
													<div class="col-12 col-md-3">
														<cfif not isdefined("other_id_number_1")><cfset other_id_number_1=""></cfif>
														<label for="other_id_number_1" class="data-entry-label">Other ID Numbers</label>
														<input type="text" class="data-entry-input" id="other_id_number_1" name="other_id_number_1" placeholder="10,20-30,=BT-782" value="#other_id_number_1#">
													</div>
													<div class="col-12 col-md-6">
														<label for="other_id_controls_note" class="data-entry-label">Note (fields to left): </label>
														<p id="other_id_controls_note">Second set of other id type/other id number fields is for testing, may not work as expected.</p>
													</div>
												</div>
											</cfif>
											<div class="form-row mb-2">
												<div class="col-12 col-md-2">
													<cfif not isdefined("full_taxon_name")><cfset full_taxon_name=""></cfif>
													<label for="taxa" class="data-entry-label">Any Taxonomic Element</label>
													<input id="taxa" name="full_taxon_name" class="data-entry-input" aria-label="any taxonomy" value="#full_taxon_name#">
												</div>
												<div class="col-12 col-md-2">
													<label for="phylum" class="data-entry-label">Phylum</label>
													<cfif not isdefined("phylum")><cfset phylum=""></cfif>
													<input id="phylum" name="phylum" class="data-entry-input" value="#phylum#" >
													<script>
														jQuery(document).ready(function() {
															makeTaxonSearchAutocomplete('phylum','phylum');
														});
													</script>
												</div>
												<div class="col-12 col-md-2">
													<label for="phylclass" class="data-entry-label">Class</label>
													<cfif not isdefined("phylclass")><cfset phylclass=""></cfif>
													<input id="phylclass" name="phylclass" class="data-entry-input" value="#phylclass#" >
													<script>
														jQuery(document).ready(function() {
															makeTaxonSearchAutocomplete('phylclass','class');
														});
													</script>
												</div>
												<div class="col-12 col-md-2">
													<label for="phylorder" class="data-entry-label">Order</label>
													<cfif not isdefined("phylorder")><cfset phylorder=""></cfif>
													<input id="phylorder" name="phylorder" class="data-entry-input" value="#phylorder#" >
													<script>
														jQuery(document).ready(function() {
															makeTaxonSearchAutocomplete('phylorder','order');
														});
													</script>
												</div>
												<div class="col-12 col-md-2">
													<label for="family" class="data-entry-label">Family</label>
													<cfif not isdefined("family")><cfset family=""></cfif>
													<input type="text" id="family" name="family" class="data-entry-input" value="#family#" >
													<script>
														jQuery(document).ready(function() {
															makeTaxonSearchAutocomplete('family','family');
														});
													</script>
												</div>
												<div class="col-12 col-md-2">
													<label for="publication_id" class="data-entry-label">Citation</label>
													<cfif not isdefined("publication_id")><cfset publication_id=""></cfif>
													<cfif not isdefined("citation")><cfset citation=""></cfif>
													<input type="hidden"  id="publication_id" name="publication_id" class="data-entry-input" value="#publication_id#" >
													<input type="text" id="citation" name="citation" class="data-entry-input" value="#citation#" >
													<script>
														jQuery(document).ready(function() {
															makePublicationPicker('citation','publication_id');
														});
													</script>
												</div>
											</div>
											<div class="form-row mb-2">
												<div class="col-12 col-md-2">
													<label for="type_status" class="data-entry-label">Type Status/Citation</label>
													<cfif not isdefined("type_status")><cfset type_status=""></cfif>
													<input type="text" class="data-entry-input" id="type_status" name="type_status" value="#type_status#">
													<script>
														jQuery(document).ready(function() {
															makeTypeStatusSearchAutocomplete('type_status');
														});
													</script>
												</div>
												<div class="col-12 col-md-2">
													<label for="genus" class="data-entry-label">Genus</label>
													<cfif not isdefined("genus")><cfset genus=""></cfif>
													<input type="text" class="data-entry-input" id="genus" name="genus" value="#genus#">
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
													<cfif len(taxon_name_id) GT 0 and len(scientific_name) EQ 0>
														<!--- lookup scientific name --->
														<cfquery name="lookupTaxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookupTaxon_result">
															SELECT scientific_name as sciname
															FROM taxonomy
															WHERE
																taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
														</cfquery>
														<cfif lookupTaxon.recordcount EQ 1>
															<cfset scientific_name = "=#lookupTaxon.sciname#">
														</cfif>
													</cfif>
													<input type="text" id="scientific_name" name="scientific_name" class="data-entry-input" value="#scientific_name#" >
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
													<input id="author_text" name="author_text" class="data-entry-input" value="#author_text#" >
													<script>
														jQuery(document).ready(function() {
															makeTaxonSearchAutocomplete('author_text','author_text');
														});
													</script>
												</div>
												<div class="col-12 col-md-2">
													<label for="determiner" class="data-entry-label">Determiner</label>
													<cfif not isdefined("determiner")><cfset determiner=""></cfif>
													<cfif not isdefined("determiner_id")><cfset determiner_id=""></cfif>
													<!--- lookup agent name --->
													<cfif len(determiner) EQ 0 AND len(determiner_id) GT 0>
														<cfquery name="lookupDeterminer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookupDeterminer_result">
															SELECT agent_name
															FROM preferred_agent_name
															WHERE
																agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#determiner_id#">
														</cfquery>
														<cfif lookupDeterminer.recordcount EQ 1>
															<cfset determiner = "=#lookupDeterminer.agent_name#">
														</cfif>
													</cfif>
													<input type="hidden" id="determiner_id" name="determiner_id" class="data-entry-input" value="#determiner_id#" >
													<input type="text" id="determiner" name="determiner" class="data-entry-input" value="#determiner#" >
													<script>
														jQuery(document).ready(function() {
															makeConstrainedAgentPicker('determiner', 'determiner_id', 'determiner');
														});
													</script>
												</div>
												<div class="col-12 col-md-2">
													<label for="nature_of_id" class="data-entry-label">Nature Of Id</label>
													<cfif not isdefined("nature_of_id")><cfset nature_of_id=""></cfif>
													<select title="nature of id" name="nature_of_id" id="nature_of_id" class="data-entry-select col-sm-12 pl-2">
														<option value=""></option>
														<cfset nid = nature_of_id>
														<cfloop query="ctnature_of_id">
															<cfif nid EQ "=#ctnature_of_id.nature_of_id#"><cfset selected=" selected "><cfelse><cfset selected = ""></cfif>
															<option value="=#ctnature_of_id.nature_of_id#" #selected#>#ctnature_of_id.nature_of_id# (#ctnature_of_id.ct#)</option>
														</cfloop>
													</select>
												</div>
											</div>
											<div class="form-row mb-2">
											</div>
											<div class="form-row mb-2">
												<div class="col-12 col-md-2">
													<cfif not isdefined("higher_geog")><cfset higher_geog=""></cfif>
													<label for="higher_geog" class="data-entry-label">Any Geographic Element</label>
													<input type="text" class="data-entry-input" name="higher_geog" id="higher_geog" value="#higher_geog#">
												</div>
												<div class="col-12 col-md-2">
													<label for="country" class="data-entry-label">Country</label>
													<cfif not isdefined("country")><cfset country=""></cfif>
													<input type="text" class="data-entry-input" id="country" name="country" value="#country#">
													<script>
														jQuery(document).ready(function() {
															makeCountrySearchAutocomplete('country');
														});
													</script>
												</div>
												<div class="col-12 col-md-2">
													<label for="state_prov" class="data-entry-label">State/Province</label>
													<cfif not isdefined("state_prov")><cfset state_prov=""></cfif>
													<input type="text" class="data-entry-input" id="state_prov" name="state_prov" aria-label="state or province" value="#state_prov#">
													<script>
														jQuery(document).ready(function() {
															makeGeogSearchAutocomplete('state_prov','state_prov');
														});
													</script>
												</div>
												<div class="col-12 col-md-2">
													<label for="county" class="data-entry-label">County/Shire/Parish</label>
													<cfif not isdefined("county")><cfset county=""></cfif>
													<input type="text" class="data-entry-input" id="county" name="county" aria-label="county shire or parish" value="#county#">
													<script>
														jQuery(document).ready(function() {
															makeGeogSearchAutocomplete('county','county');
														});
													</script>
												</div>
												<div class="col-12 col-md-2">
													<label for="island_group" class="data-entry-label">Island Group</label>
													<cfif not isdefined("island_group")><cfset island_group=""></cfif>
													<input type="text" class="data-entry-input" id="island_group" name="island_group" value="#island_group#">
													<script>
														jQuery(document).ready(function() {
															makeGeogSearchAutocomplete('island_group','island_group');
														});
													</script>
												</div>
												<div class="col-12 col-md-2">
													<label for="island" class="data-entry-label">Island</label>
													<cfif not isdefined("island")><cfset island=""></cfif>
													<input type="text" class="data-entry-input" id="island" name="island" value="#island#">
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
															makeConstrainedAgentPicker('collector','collector_agent_id','transaction_agent');
														});
													</script>
												</div>
												<div class="col-12 col-md-2">
													<cfif not isdefined("part_name")><cfset part_name=""></cfif>
													<label for="part_name" class="data-entry-label">Part Name</label>
													<input type="text" id="part_name" name="part_name" class="data-entry-input" value="#part_name#" >
													<script>
														jQuery(document).ready(function() {
															makePartNameAutocompleteMeta('part_name');
														});
													</script>
												</div>
												<div class="col-12 col-md-2">
													<cfif not isdefined("preserve_method")><cfset preserve_method=""></cfif>
													<label for="preserve_method" class="data-entry-label">Preserve Method</label>
													<input type="text" id="preserve_method" name="preserve_method" class="data-entry-input" value="#preserve_method#" >
													<script>
														jQuery(document).ready(function() {
															makePreserveMethodAutocompleteMeta('preserve_method');
														});
													</script>
												</div>
												<div class="col-12 col-md-3">
													<cfif not isdefined("verbatim_date")><cfset verbatim_date=""></cfif>
													<label class="data-entry-label" for="when">Verbatim Date</label>
													<input type="text" name="verbatim_date" class="data-entry-input" id="verbatim_date" value="#verbatim_date#">
												</div>
												<div class="col-12 col-md-2">
													<cfif findNoCase('redesign',gitBranch) GT 0 OR (isdefined("session.roles") and listfindnocase(session.roles,"global_admin") ) >
														<label class="data-entry-label" for="debug">Debug</label>
														<select title="debug" name="debug" id="dbug" class="data-entry-select">
															<option value=""></option>
															<cfif isdefined("debug") AND len(debug) GT 0><cfset selected=" selected "><cfelse><cfset selected=""></cfif>
															<option value="true" #selected#>Debug JSON</option>
														</select>
													</cfif>
												</div>
											</div>
											<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
												<div class="form-row mb-2">
													<div class="col-12 col-md-2">
														<cfif not isdefined("loan_number")>
															<cfset loan_number="">
														</cfif>
														<cfif isDefined("loan_trans_id") AND len(loan_trans_id) GT 0>
															<!--- lookup loan number (for api call &loan_trans_id=) --->
															<cfquery name="lookupLoan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookupLoan_result">
																SELECT loan_number as lnum
																FROM loan
																WHERE
																	transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#loan_trans_id#">
															</cfquery>
															<cfif lookupLoan.recordcount EQ 1>
																<cfset accn_number = "=#lookupLoan.lnum#">
															</cfif>
														</cfif>
														<label for="loan_number" class="data-entry-label">Loan Number</label>
														<input type="text" name="loan_number" class="data-entry-input" id="loan_number" placeholder="yyyy-n-Col" value="#loan_number#" >
													</div>
													<div class="col-12 col-md-2">
														<cfif not isdefined("accn_number")>
															<cfset accn_number="">
														</cfif>
														<cfif isDefined("accn_trans_id") AND len(accn_trans_id) GT 0>
															<!--- lookup accession number (for api call &accn_trans_id=) --->
															<cfquery name="lookupAccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookupAccn_result">
																SELECT accn_number as accnum
																FROM accn
																WHERE
																	transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accn_trans_id#">
															</cfquery>
															<cfif lookupAccn.recordcount EQ 1>
																<cfset accn_number = "=#lookupAccn.accnum#">
															</cfif>
														</cfif>
														<label for="accn_number" class="data-entry-label">Accession Number</label>
														<input type="text" name="accn_number" class="data-entry-input" id="accn_number" placeholder="nnnnn" value="#accn_number#" >
													</div>
													<div class="col-12 col-md-2">
														<cfif not isdefined("deaccession_number")>
															<cfset deaccession_number="">
														</cfif>
														<label for="deaccession_number" class="data-entry-label">Deaccession Number</label>
														<input type="text" name="deaccession_number" class="data-entry-input" id="deaccession_number" placeholder="Dyyyy-n-Col" value="#deaccession_number#" >
													</div>
												</div>
											</cfif>
											<div class="form-row my-3">
												<div class="col-12">
													<button type="submit" class="btn btn-xs btn-primary col-12 col-md-auto px-md-5 mx-0 my-1 mr-md-5" aria-label="run the fixed search" id="fixedsubmitbtn">Search <i class="fa fa-search"></i></button>
													<button type="reset" class="btn btn-xs btn-warning col-12 col-md-auto px-md-3 mx-0 my-1 mr-md-2" aria-label="Reset this search form to inital values">Reset</button>
													<button type="button" class="btn btn-xs btn-warning col-12 col-md-auto px-md-3 mx-0 my-1" aria-label="Start a new specimen search with a clear page" onclick="window.location.href='#Application.serverRootUrl#/Specimens.cfm?action=fixedSearch';">New Search</button>
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
																<div class="col-12 col-md-3">
																	<div id="fixedcolumnPick" class="px-1"></div>
																</div>
																<div class="col-12 col-md-3">
																	<div id="fixedcolumnPick1" class="px-1"></div>
																</div>
																<div class="col-12 col-md-3">
																	<div id="fixedcolumnPick2" class="px-1"></div>
																</div>
																<div class="col-12 col-md-3">
																	<div id="fixedcolumnPick3" class="px-1"></div>
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
		<!--- 
		<section>
			<div class="col-12 col-md-6 mx-auto mb-3 pb-3">
				<p class="blockquote small text-center">Collection records at the Museum of Comparative Zoology may contain language that reflect historical place or taxon names in its original form that are no longer acceptable or appropriate in an inclusive environment. While the MCZ is  preserving data in their original form in order to retain authenticity and facilitate research, we do not condone this language and are committed to address the problem of racial and other derogatory language present in our database.</p>
			</div>
		</section>
		--->
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
	
	<!--- lastcolumn is the column to put at the end of the default column set with no width specified --->
	<cfset lastcolumn = 'OTHERCATALOGNUMBERS'>
	<cfquery name="getFieldMetadata" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getFieldMetadata_result">
		SELECT upper(column_name) as column_name, sql_element, data_type, category, label, disp_order, hideable, hidden, cellsrenderer, width
		FROM cf_spec_res_cols_r
		WHERE access_role = 'PUBLIC'
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
				OR access_role = 'COLDFUSION_USER'
			</cfif>
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_transactions")>
				OR access_role = 'MANAGE_TRANSACTIONS'
			</cfif>
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"DATA_ENTRY")>
				OR access_role = 'DATA_ENTRY'
			</cfif>
		ORDER by disp_order
	</cfquery>
	<script>
		// setup for persistence of column selections
		window.columnHiddenSettings = new Object();
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
			lookupColumnVisibilities ('#cgi.script_name#','Default');
		</cfif>
	
		// ***** cell renderers *****
		// cell renderer to display a thumbnail with alt tag given columns preview_uri, media_uri, and ac_description 
		var thumbCellRenderer_f = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("##fixedsearchResultsGrid").jqxGrid('getrowdata',row);
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
		// NOTE: Since there are three grids, and the cellsrenderer api does not pass a reference to the grid, a separate
		// cell renderer must be added for each grid,  cf_spec_res_cols_r.cellsrenderer values starting with _ are interpreted
		// as fixed_, keyword_, builder_ cell renderers depending on the grid in which the cellsrenderer value is being applied. 
		var fixed_linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("##fixedsearchResultsGrid").jqxGrid('getrowdata',row);
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/specimens/Specimen.cfm/' + rowData['COLLECTION_OBJECT_ID'] + '" aria-label="specimen details">'+ rowData['GUID'] +'</a></span>';
		};
		var keyword_linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("##keywordsearchResultsGrid").jqxGrid('getrowdata',row);
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/specimens/Specimen.cfm/' + rowData['COLLECTION_OBJECT_ID'] + '" aria-label="specimen details">'+ rowData['GUID'] +'</a></span>';
		};
		var builder_linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("##buildersearchResultsGrid").jqxGrid('getrowdata',row);
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/specimens/Specimen.cfm/' + rowData['COLLECTION_OBJECT_ID'] + '" aria-label="specimen details">'+ rowData['GUID'] +'</a></span>';
		};
	
		// cell renderer to link out to specimen details page by guid, when value is guid.
		var linkGuidCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/guid/' + value + '" aria-label="specimen details">'+value+'</a></span>';
		};
	
	
		/* End Setup jqxgrids for search ****************************************************************************************/
		$(document).ready(function() {
			/* Setup jqxgrid for keyword Search */
			$('##keywordSearchForm').bind('submit', function(evt){ 
				evt.preventDefault();
				var uuid = getVersion4UUID();
				$("##result_id_keywordSearch").val(uuid);
		
				$("##overlay").show();
				$("##collapseKeyword").collapse("hide");  // hide the help text if it is visible.
		
				$("##keywordsearchResultsGrid").replaceWith('<div id="keywordsearchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
				$("##keywordresultCount").html("");
				$("##keywordresultLink").html("");
				var debug = $("##keywordSearchForm").serialize();
				console.log(debug);
		
				var search =
				{
					datatype: "json",
					datafields:
					[
						<cfset separator = "">
						<cfloop query="getFieldMetadata">
							<cfif data_type EQ 'VARCHAR2' OR data_type EQ 'DATE'>
								#separator#{name: '#ucase(column_name)#', type: 'string' }
							<cfelse>
								#separator#{name: '#ucase(column_name)#', type: 'string' }
							</cfif>
							<cfset separator = ",">
						</cfloop>
					],
					updaterow: function (rowid, rowdata, commit) {
						commit(true);
					},
					root: 'specimenRecord',
					id: 'collection_object_id',
					url: '/specimens/component/search.cfc?' + $("##keywordSearchForm").serialize(),
					timeout: 60000,  // units not specified, miliseconds?
					loadError: function(jqXHR, textStatus, error) {
						handleFail(jqXHR,textStatus,error, "Error performing specimen search: "); 
					},
					async: true
				};	
	
				var dataAdapter = new $.jqx.dataAdapter(search);
				var initRowDetails = function (index, parentElement, gridElement, datarecord) {
					// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
					var details = $($(parentElement).children()[0]);
					details.html("<div id='keywordrowDetailsTarget" + index + "'></div>");
					createRowDetailsDialogNoBlanks('keywordsearchResultsGrid','keywordrowDetailsTarget',datarecord,index);
					// Workaround, expansion sits below row in zindex.
					var maxZIndex = getMaxZIndex();
					$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
				}
		
				$("##keywordsearchResultsGrid").jqxGrid({
					width: '100%',
					autoheight: 'true',
					source: dataAdapter,
					filterable: false,  // turned off, will be difficult to support with server side paging of resultset
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
						$("##keywordsearchResultsGrid").jqxGrid('selectrow', 0);
					},
					columns: [
						<cfset lastrow ="">
						<cfloop query="getFieldMetadata">
							<cfset cellrenderer = "">
							<cfif len(getFieldMetadata.cellsrenderer) GT 0>
								<cfif left(getFieldMetadata.cellsrenderer,1) EQ "_"> 
									<cfset cellrenderer = " cellsrenderer:keyword#getFieldMetadata.cellsrenderer#,">
								<cfelse>
									<cfset cellrenderer = " cellsrenderer:#getFieldMetadata.cellsrenderer#,">
								</cfif>
							</cfif> 
							<cfif ucase(data_type) EQ 'DATE'>
								<cfset filtertype = " filtertype: 'date',">
							<cfelse>
								<cfset filtertype = "">
							</cfif>
							<cfif ucase(column_name) EQ lastcolumn>
								<!--- leave off the width on the last column, no trailing comma --->
								<cfset lastrow = "{text: '#label#', datafield: '#ucase(column_name)#',#filtertype##cellrenderer# hidable:#hideable#, hidden: getColHidProp('#ucase(column_name)#', #hidden#) }">
							<cfelse> 
								{text: '#label#', datafield: '#ucase(column_name)#',#filtertype##cellrenderer# width: #width#, hidable:#hideable#, hidden: getColHidProp('#ucase(column_name)#', #hidden#) },
							</cfif>
						</cfloop>
						#lastrow#
					],
					rowdetails: true,
					rowdetailstemplate: {
						rowdetails: "<div style='margin: 10px;'>Row Details</div>",
						rowdetailsheight:  1 // row details will be placed in popup dialog
					},
					initrowdetails: initRowDetails
				});
		
				$("##keywordsearchResultsGrid").on("bindingcomplete", function(event) {
					// add a link out to this search, serializing the form as http get parameters
					$('##keywordresultLink').html('<a href="/Specimens.cfm?execute=true&' + $('##keywordSearchForm :input').filter(function(index,element){ return $(element).val()!='';}).not(".excludeFromLink").serialize() + '">Link to this search</a>');
					gridLoaded('keywordsearchResultsGrid','occurrence record','keyword');
				});
				$('##keywordsearchResultsGrid').on('rowexpand', function (event) {
					//  Create a content div, add it to the detail row, and make it into a dialog.
					var args = event.args;
					var rowIndex = args.rowindex;
					var datarecord = args.owner.source.records[rowIndex];
					createRowDetailsDialogNoBlanks('keywordsearchResultsGrid','rowDetailsTarget',datarecord,rowIndex);
				});
				$('##keywordsearchResultsGrid').on('rowcollapse', function (event) {
					// remove the dialog holding the row details
					var args = event.args;
					var rowIndex = args.rowindex;
					$("##keywordsearchResultsGridRowDetailsDialog" + rowIndex ).dialog("destroy");
				});
				// display selected row index.
				$("##keywordsearchResultsGrid").on('rowselect', function (event) {
					$("##keywordselectrowindex").text(event.args.rowindex);
				});
				// display unselected row index.
				$("##keywordsearchResultsGrid").on('rowunselect', function (event) {
					$("##keywordunselectrowindex").text(event.args.rowindex);
				});
			});
	
			/* Setup jqxgrid for builder Search */
			$('##builderSearchForm').bind('submit', function(evt){
				evt.preventDefault();
				var uuid = getVersion4UUID();
				$("##result_id_builderSearch").val(uuid);
		
				$("##overlay").show();
		
				$("##buildersearchResultsGrid").replaceWith('<div id="buildersearchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
				$("##builderresultCount").html("");
				$("##builderresultLink").html("");
				var debug = $("##builderSearchForm").serialize();
				console.log(debug);
		
				var search =
				{
					datatype: "json",
					datafields:
					[
						<cfset separator = "">
						<cfloop query="getFieldMetadata">
							<cfif data_type EQ 'VARCHAR2' OR data_type EQ 'DATE'>
								#separator#{name: '#ucase(column_name)#', type: 'string' }
							<cfelse>
								#separator#{name: '#ucase(column_name)#', type: 'string' }
							</cfif>
							<cfset separator = ",">
						</cfloop>
					],
					updaterow: function (rowid, rowdata, commit) {
						commit(true);
					},
					root: 'specimenRecord',
					id: 'collection_object_id',
					url: '/specimens/component/search.cfc?' + $("##builderSearchForm").serialize(),
					timeout: 60000,  // units not specified, miliseconds?
					loadError: function(jqXHR, textStatus, error) {
						handleFail(jqXHR,textStatus,error, "Error performing specimen search: "); 
					},
					async: true
				};	
	
				var dataAdapter = new $.jqx.dataAdapter(search);
				var initRowDetails = function (index, parentElement, gridElement, datarecord) {
					// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
					var details = $($(parentElement).children()[0]);
					details.html("<div id='builderrowDetailsTarget" + index + "'></div>");
					createRowDetailsDialogNoBlanks('buildersearchResultsGrid','builderrowDetailsTarget',datarecord,index);
					// Workaround, expansion sits below row in zindex.
					var maxZIndex = getMaxZIndex();
					$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
				}
		
				$("##buildersearchResultsGrid").jqxGrid({
					width: '100%',
					autoheight: 'true',
					source: dataAdapter,
					filterable: false,
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
						$("##buildersearchResultsGrid").jqxGrid('selectrow', 0);
					},
					columns: [
						<cfset lastrow ="">
						<cfloop query="getFieldMetadata">
							<cfset cellrenderer = "">
							<cfif len(getFieldMetadata.cellsrenderer) GT 0>
								<cfif left(getFieldMetadata.cellsrenderer,1) EQ "_"> 
									<cfset cellrenderer = " cellsrenderer:builder#getFieldMetadata.cellsrenderer#,">
								<cfelse>
									<cfset cellrenderer = " cellsrenderer:#getFieldMetadata.cellsrenderer#,">
								</cfif>
							</cfif> 
							<cfif ucase(data_type) EQ 'DATE'>
								<cfset filtertype = " filtertype: 'date',">
							<cfelse>
								<cfset filtertype = "">
							</cfif>
							<cfif ucase(column_name) EQ lastcolumn>
								<!--- leave off the width on the last column, no trailing comma --->
								<cfset lastrow = "{text: '#label#', datafield: '#ucase(column_name)#',#filtertype##cellrenderer# hidable:#hideable#, hidden: getColHidProp('#ucase(column_name)#', #hidden#) }">
							<cfelse> 
								{text: '#label#', datafield: '#ucase(column_name)#',#filtertype##cellrenderer# width: #width#, hidable:#hideable#, hidden: getColHidProp('#ucase(column_name)#', #hidden#) },
							</cfif>
						</cfloop>
						#lastrow#
					],
					rowdetails: true,
					rowdetailstemplate: {
						rowdetails: "<div style='margin: 10px;'>Row Details</div>",
						rowdetailsheight:  1 // row details will be placed in popup dialog
					},
					initrowdetails: initRowDetails
				});
		
				$("##buildersearchResultsGrid").on("bindingcomplete", function(event) {
					// add a link out to this search, serializing the form as http get parameters
					$('##builderresultLink').html('<a href="/Specimens.cfm?execute=true&' + $('##builderSearchForm :input').filter(function(index,element){ return $(element).val()!='';}).not(".excludeFromLink").serialize() + '">Link to this search</a>');
					gridLoaded('buildersearchResultsGrid','occurrence record','builder');
				});
				$('##buildersearchResultsGrid').on('rowexpand', function (event) {
					//  Create a content div, add it to the detail row, and make it into a dialog.
					var args = event.args;
					var rowIndex = args.rowindex;
					var datarecord = args.owner.source.records[rowIndex];
					createRowDetailsDialogNoBlanks('buildersearchResultsGrid','rowDetailsTarget',datarecord,rowIndex);
				});
				$('##buildersearchResultsGrid').on('rowcollapse', function (event) {
					// remove the dialog holding the row details
					var args = event.args;
					var rowIndex = args.rowindex;
					$("##buildersearchResultsGridRowDetailsDialog" + rowIndex ).dialog("destroy");
				});
				// display selected row index.
				$("##buildersearchResultsGrid").on('rowselect', function (event) {
					$("##builderselectrowindex").text(event.args.rowindex);
				});
				// display unselected row index.
				$("##buildersearchResultsGrid").on('rowunselect', function (event) {
					$("##builderunselectrowindex").text(event.args.rowindex);
				});
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
						<cfset separator = "">
						<cfloop query="getFieldMetadata">
							<cfif data_type EQ 'VARCHAR2' OR data_type EQ 'DATE'>
								#separator#{name: '#ucase(column_name)#', type: 'string' }
							<cfelse>
								#separator#{name: '#ucase(column_name)#', type: 'string' }
							</cfif>
							<cfset separator = ",">
						</cfloop>
					],
					updaterow: function (rowid, rowdata, commit) {
						commit(true);
					},
					root: 'specimenRecord',
					id: 'collection_object_id',
					url: '/specimens/component/search.cfc?' + $('##fixedSearchForm').serialize(),
					timeout: 120000,  // units not specified, miliseconds?
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
					createRowDetailsDialogNoBlanks('fixedsearchResultsGrid','fixedrowDetailsTarget',datarecord,index);
					// Workaround, expansion sits below row in zindex.
					var maxZIndex = getMaxZIndex();
					$(parentElement).css('z-index',maxZIndex - 1); // will sit just behind dialog
				}
	
				$("##fixedsearchResultsGrid").jqxGrid({
					width: '100%',
					autoheight: 'true',
					source: dataAdapter,
					filterable: false,
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
					columns: [
						<cfset lastrow ="">
						<cfloop query="getFieldMetadata">
							<cfset cellrenderer = "">
							<cfif len(getFieldMetadata.cellsrenderer) GT 0>
								<cfif left(getFieldMetadata.cellsrenderer,1) EQ "_"> 
									<cfset cellrenderer = " cellsrenderer:fixed#getFieldMetadata.cellsrenderer#,">
								<cfelse>
									<cfset cellrenderer = " cellsrenderer:#getFieldMetadata.cellsrenderer#,">
								</cfif>
							</cfif> 
							<cfif ucase(data_type) EQ 'DATE'>
								<cfset filtertype = " filtertype: 'date',">
							<cfelse>
								<cfset filtertype = "">
							</cfif>
							<cfif ucase(column_name) EQ lastcolumn>
								<!--- leave off the width on the last column, no trailing comma --->
								<cfset lastrow = "{text: '#label#', datafield: '#ucase(column_name)#',#filtertype##cellrenderer# hidable:#hideable#, hidden: getColHidProp('#ucase(column_name)#', #hidden#) }">
							<cfelse> 
								{text: '#label#', datafield: '#ucase(column_name)#',#filtertype##cellrenderer# width: #width#, hidable:#hideable#, hidden: getColHidProp('#ucase(column_name)#', #hidden#) },
							</cfif>
						</cfloop>
						#lastrow#
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
					$('##fixedresultLink').html('<a href="/Specimens.cfm?execute=true&' + $('##fixedSearchForm :input').filter(function(index,element){ return $(element).val()!='';}).not(".excludeFromLink").serialize() + '">Link to this search</a>');
					gridLoaded('fixedsearchResultsGrid','occurrence record','fixed');
				});
				$('##fixedsearchResultsGrid').on('rowexpand', function (event) {
					//  Create a content div, add it to the detail row, and make it into a dialog.
					var args = event.args;
					var rowIndex = args.rowindex;
					var datarecord = args.owner.source.records[rowIndex];
					createRowDetailsDialogNoBlanks('fixedsearchResultsGrid','fixedrowDetailsTarget',datarecord,rowIndex);
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
				var quartercolumns = Math.round(columns.length/4);
				var columnListSource = [];
				for (i = 1; i < quartercolumns; i++) {
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
				for (i = quartercolumns; i < halfcolumns; i++) {
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

				var columnListSource2 = [];
				for (i = halfcolumns; i < halfcolumns + quartercolumns; i++) {
					var text = columns[i].text;
					var datafield = columns[i].datafield;
					var hideable = columns[i].hideable;
					var hidden = columns[i].hidden;
					var show = ! hidden;
					if (hideable == true) {
						var listRow = { label: text, value: datafield, checked: show };
						columnListSource2.push(listRow);
					}
				}
				$("##"+whichGrid+"columnPick2").jqxListBox({ source: columnListSource2, autoHeight: true, width: '260px', checkboxes: true });
				$("##"+whichGrid+"columnPick2").on('checkChange', function (event) {
					$("##" + gridId).jqxGrid('beginupdate');
					if (event.args.checked) {
						$("##" + gridId).jqxGrid('showcolumn', event.args.value);
					} else {
						$("##" + gridId).jqxGrid('hidecolumn', event.args.value);
					}
					$("##" + gridId).jqxGrid('endupdate');
				});

				var columnListSource3 = [];
				for (i = halfcolumns + quartercolumns; i < columns.length; i++) {
					var text = columns[i].text;
					var datafield = columns[i].datafield;
					var hideable = columns[i].hideable;
					var hidden = columns[i].hidden;
					var show = ! hidden;
					if (hideable == true) {
						var listRow = { label: text, value: datafield, checked: show };
						columnListSource3.push(listRow);
					}
				}
				$("##"+whichGrid+"columnPick3").jqxListBox({ source: columnListSource3, autoHeight: true, width: '260px', checkboxes: true });
				$("##"+whichGrid+"columnPick3").on('checkChange', function (event) {
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
					`<button id="columnPickDialogOpener" onclick=" $('##`+whichGrid+`columnPickDialog').dialog('open'); " class="btn btn-xs btn-secondary my-1 mr-1" >Select Columns</button>
					<button id="pinGuidToggle" onclick=" togglePinColumn('`+gridId+`','GUID'); " class="btn btn-xs btn-secondary mx-1 px-1 my-2" >Pin GUID Column</button>
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
				$('##'+whichGrid+'resultDownloadButtonContainer').html('<button id="loancsvbutton" class="btn btn-xs btn-secondary px-3 pb-1 mx-1 mb-1 my-md-2" aria-label="Export results to csv" onclick=" exportGridToCSV(\''+whichGrid+'searchResultsGrid\', \''+filename+'\'); " >Export to CSV</button>');
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
