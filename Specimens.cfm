<!--
Specimens.cfm

Copyright 2019-2022 President and Fellows of Harvard College

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


<cftry>
	<!--- assuming a git repository and readable by coldfusion, determine the checked out branch by reading HEAD --->
	<cfset gitBranch = FileReadLine(FileOpen("#Application.webDirectory#/.git/HEAD", "read"))>
<cfcatch>
	<cfset gitBranch = "unknown">
</cfcatch>
</cftry>

<cfset enableMobileKeywordTabModal = false>
<cfif not isdefined("action") AND not isDefined("execute") AND not isDefined("method")>
	<!--- enable test for mobile browser to make the keyword tab modal on page load if no question was asked in the uri. --->
	<cfset enableMobileKeywordTabModal = true>
</cfif>

<cfif not isdefined("action")>
	<!--- set the default tab based on user preferences --->
	<cfif isDefined("session.specimens_default_action") AND len(session.specimens_default_action) GT 0 >
		<cfset action=session.specimens_default_action>
	</cfif>
	<cfif not isdefined("action") OR len(action) EQ 0 OR NOT ListContains("fixedSearch,keywordSearch,builderSearch",action)>
		<cfset action="fixedSearch">
	</cfif>
</cfif>
<cfswitch expression="#action#">
	<!--- API note: action and method seem duplicative, action is required and used to determine
			which tab to show, method invokes target backing method in form submission, but when 
			invoking this page with execute=true method does not need to be included in the call
			even though it will be included in the URI parameter list when clicking on the 
			"Link to this search" link.
	--->
	<cfcase value="fixedSearch">
		<cfset pageTitle = "Search Specimen | Basic">
		<cfif isdefined("execute")>
			<cfset execute="fixed">
		</cfif>
	</cfcase>
	<cfcase value="keywordSearch">
		<cfset pageTitle = "Search Specimens | by Keyword">
		<cfif isdefined("execute")>
			<cfset execute="keyword">
		</cfif>
	</cfcase>
	<cfcase value="builderSearch">
		<cfset pageTitle = "Search Specimens | Build Parameters">
		<cfif isdefined("execute")>
			<cfset execute="builder">
		</cfif>
	</cfcase>
	<cfdefaultcase>
		<cfset pageTitle = "Basic Specimen Search">
		<cfif isdefined("execute")>
			<cfset execute="fixed">
		</cfif>
	</cfdefaultcase>
</cfswitch>
<cfset pageHasTabs="true">
<cfinclude template = "/shared/_header.cfm">

<cfset defaultSelectionMode = "none">
<cfif defaultSelectionMode EQ "none">
	<cfset defaultenablebrowserselection = "true">
<cfelse>
	<cfset defaultenablebrowserselection = "false">
</cfif>	

<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
<cfelse>
	<cfset oneOfUs = 0>
</cfif>

<cfquery name="ctCollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.short_timeout#">
	SELECT
		collection_cde,
		collection,
		collection_id
	FROM
		collection
	ORDER BY collection.collection
</cfquery>
<cfquery name="ctother_id_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT count(*) ct, other_id_type 
	FROM coll_obj_other_id_num co
	GROUP BY other_id_type 
	ORDER BY other_id_type
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
	<cfquery name="lookupCollection_cde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookupCollection_cde_result" timeout="#Application.short_timeout#">
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
<cfif not isdefined("underscore_collection") AND isdefined("underscore_collection_id") AND len(underscore_collection_id) GT 0 >
	<!--- if underscore collection id was provided, but not a collection name, lookup the collection name --->
	<cfquery name="lookupNamedGroup" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookupNamedGroup_result" timeout="#Application.short_timeout#">
		SELECT
			collection_name
		FROM
			underscore_collection
		WHERE
			underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
	</cfquery>
	<cfloop query="lookupNamedGroup">
		<cfset underscore_collection = lookupNamedGroup.collection_name>
	</cfloop>
</cfif>

<cfoutput>
<style>
.animation-element {
	position: relative;
	width: 30%;
	margin: 0% 1.33 2.66% 1.33%;
	float: left;
}
.bounce-up .fixedResults {
	opacity: 0;
	-moz-transition: all 700ms ease-out;
	-webkit-transition: all 700ms ease-out;
	-o-transition: all 700ms ease-out;
	transition: all 700ms ease-out;
	-moz-transform: translate3d(0px, 200px, 0px);
	-webkit-transform: translate3d(0px, 200px, 0px);
	-o-transform: translate(0px, 200px);
	-ms-transform: translate(0px, 200px);
	transform: translate3d(0px, 200, 0px);
	-webkit-backface-visibility: hidden;
	-moz-backface-visibility: hidden;
	backface-visibility: hidden;
}
.bounce-up.in-view .fixedResults {
	opacity: 1;
	-moz-transform: translate3d(0px, 0px, 0px);
	-webkit-transform: translate3d(0px, 0px, 0px);
	-o-transform: translate(0px, 0px);
	-ms-transform: translate(0px, 0px);
	transform: translate3d(0px, 0px, 0px);
}
@media screen and (max-width: 678px) {
	.animation-element
		width: 100%;
		margin: 0px 0px 30px 0px;
	}
}
</style>
<style>
.ns {
	display:none;
}
##IDP ul {
	display:none;
}

##IDP.sticky{
	display: flex !important;
	position: -webkit-sticky !important;
	position: sticky !important;
	top: 0 !important;
	background-color: ##deebec;
	border: 1px solid ##c7c7c7 !important;
	padding: 10px 25px;
	font-size: 14px;
	z-index: 2;
}
	##IDP.sticky ul {display:flex !important;}
</style>
<script>
  function toggleDisplay1() {
    var elements = document.getElementsByClassName("togglesearchform");

    // Iterate through elements with the specified class and toggle display
    for (var i = 0; i < elements.length; i++) {
      if (elements[i].style.display === "none") {
        elements[i].style.display = "block";
      } else {
        elements[i].style.display = "none";
      }
    }
  }
	
window.onscroll = function() {stickyheader()};
function stickyheader() {
  if (document.documentElement.scrollTop > 50) {
    document.getElementById("IDP").className = "sticky";
  } else {
    document.getElementById("IDP").className = "";
  }
}
	

</script>
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
<!---TODO:--->
			<!---Make results stick to top without room to scroll up. in other words results row sticks to top of browser in view and results scroll under it. See W3Schools and other examples--->
			<div class="row">
				<div class="col-11 mt-1 pb-3">
					<cfquery name="getSpecimenCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT count(collection_object_id) as cnt FROM cataloged_item
					</cfquery>
				
					<h1 class="h3 smallcaps mb-1 pl-3">Find Specimen Records <span class="count  font-italic color-green mx-0"><small> #getSpecimenCount.cnt# records</small><small class="sr-only">Tab into search form</small></span></h1>
					<button class="float-right btn btn-xs m-2 btn-secondary" onclick="toggleDisplay1()">Toggle Search Forms</button>
					<!--- populated with download dialog for external users --->
					<div id="downloadAgreeDialogDiv"></div>
					<!--- Tab header div --->
					<div class="tabs card-header tab-card-header px-2 pt-3">
						<cfswitch expression="#action#">
							<cfcase value="fixedSearch">
								<cfset fixedTabActive = "active">
								<cfset fixedTabShow = "">
								<cfset keywordTabActive = "">
								<cfset keywordTabShow = "hidden">
								<cfset builderTabActive = "">
								<cfset builderTabShow = "hidden">
								<cfset fixedTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset keywordTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset builderTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfcase>
							<cfcase value="keywordSearch">
								<cfset fixedTabActive = "">
								<cfset fixedTabShow = "hidden">
								<cfset keywordTabActive = "active">
								<cfset keywordTabShow = "">
								<cfset builderTabActive = "">
								<cfset builderTabShow = "hidden">
								<cfset fixedTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset keywordTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset builderTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfcase>
							<cfcase value="builderSearch">
								<cfset fixedTabActive = "">
								<cfset fixedTabShow = "hidden">
								<cfset keywordTabActive = "">
								<cfset keywordTabShow = "hidden">
								<cfset builderTabActive = "active">
								<cfset builderTabShow = "">
								<cfset fixedTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset keywordTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset builderTabAria = "aria-selected=""true"" tabindex=""0"" ">
							</cfcase>
							<cfdefaultcase>
								<cfset fixedTabActive = "active">
								<cfset fixedTabShow = "">
								<cfset keywordTabActive = "">
								<cfset keywordTabShow = "hidden">
								<cfset builderTabActive = "">
								<cfset builderTabShow = "hidden">
								<cfset fixedTabAria = "aria-selected=""true"" tabindex=""0"" ">
								<cfset builderTabAria = "aria-selected=""false"" tabindex=""-1"" ">
								<cfset keywordTabAria = "aria-selected=""false"" tabindex=""-1"" ">
							</cfdefaultcase>
						</cfswitch>
						<cfif enableMobileKeywordTabModal EQ true>
							<!--- check for a narrow screen, and if so, make the keyword search tab modal --->
							<script>
								$(document).ready(function() {
									if (window.innerWidth <= 600) { 
										$("##keywordSearchTabButton").trigger("click");
									}
								});
							</script>
						</cfif>
						<div class="tab-headers px-0 tabList" role="tablist" aria-label="search panel tabs">
							<button class="col-3 col-md-2 px-2 my-0 #fixedTabActive#" id="basicSearchTabButton" tabid="1" role="tab" aria-controls="fixedSearchPanel" #fixedTabAria#>Basic Search</button>
							<button class="col-3 col-xl-2 px-1 my-0 #keywordTabActive#" id="keywordSearchTabButton" tabid="2" role="tab" aria-controls="keywordSearchPanel" #keywordTabAria# >Keyword Search</button>
							<button class="col-3 col-xl-2 px-1 my-0 #builderTabActive#" id="builderSearchTabButton" tabid="3" role="tab" aria-controls="builderSearchPanel" #builderTabAria# aria-label="search builder tab">Search Builder</button>
						</div>
						<div class="tab-content mt-0 px-0 pb-0">
							<!---Fixed Search tab panel--->
							<section id="fixedSearchPanel" role="tabpanel" aria-labelledby="basicSearchTabButton" tabindex="0" class="mx-0 #fixedTabActive# unfocus" #fixedTabShow#>
								<div class="col-9 float-right px-0"> 
									<button class="btn btn-xs btn-dark help-btn border-0" type="button" data-toggle="collapse" data-target="##collapseFixed" aria-expanded="false" aria-controls="collapseFixed">
										Search Help
									</button>
									<aside class="collapse collapseStyle" id="collapseFixed">
										<div class="card card-body pl-4 py-3 pr-3 border-danger">
											<h2 class="headerSm">Basic Search Help</h2>
											<p>
												This help applies to the basic specimen search and some other search forms in MCZbase.
												Many fields are autocompletes, values can be selected off of the picklist, or a partial match can be entered in the field.
												Most fields will accept search operators, described below, which alter the behaviour of the search.
												<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")> 
													(see: <a href="https://code.mcz.harvard.edu/wiki/index.php/Search_Operators" target="_blank">Search Operators</a>). For more examples, see: <a href="https://code.mcz.harvard.edu/wiki/index.php/Basic_Specimen_Search" target="_blank">Basic Specimen Search</a>
												</cfif>.
											</p>
											<h2 class="headerSm">Special operators that are entered in the field by themselves with no other value</h2>
											<dl class="mb-0"> 
												<dt><span class="text-info font-weight-bold">NULL</span></dt>
												<dd>Find records where this field is empty.</dd>
												<dt><span class="text-info font-weight-bold">NOT NULL</span></dt>
												<dd>Find records where this field contains some non-empty value.</dd>
											</dl>
											<h2 class="headerSm">Operators entered as the first character in a field, followed by a search term (e.g. =Murex). </h2>
											<dl class="mb-0"> 
												<dt><span class="text-info font-weight-bold">=</span></dt>
												<dd>Perform a (case insensitive, in most cases) exact match search. Fields which take this operator append a wild card to the beginning and end of the search term unless this operator is used.</dd>
												<dt><span class="text-info font-weight-bold">!</span></dt>
												<dd>Perform a (case insensitive, in most cases) exact match <strong>not</strong> search. Will find records where the value in the field does not match the specified search term. </dd>
												<dt><span class="text-info font-weight-bold">~</span></dt>
												<dd>Find nearby strings. Finds matches where the value in the field is a small number of character substitutions away from the provided search term. Makes the comparison using the jaro winkler string distance, with a threshold set, depending on the search, on 0.80 or 0.90.</dd> 
												<dt><span class="text-info font-weight-bold">$</span> </dt>
												<dd> Find sound alike strings. Finds matches where the value in the field sounds like the provided search term. Makes the comparison using the soundex algorithm.</dd>
											</dl>
											<h2 class="headerSm">Wild cards that may be accepted where a search can take a = operator, but that operator is not used.</h2>
											<dl class="mb-0"> 
												<dt><span class="text-info font-weight-bold">%</span></dt>
												<dd>Match any number of characters. (added at the beginning and end of strings for all fields that can take an = operator where that operator is not used).</dd>
												<dt><span class="text-info font-weight-bold">_</span></dt> 
												<dd>Match exactly one character.</dd>
											</dl>
											<h2 class="headerSm">Guidance for specific fields</h2>
											<dl class="mb-0"> 
												<dt><span class="text-info font-weight-bold">Catalog Number</span></dt>
												<dd>Catalog number accepts single numbers (e.g. 1100), ranges of numbers (e.g. 100-110), comma separated lists of number (or search, e.g. 100,110), ranges of numbers with prefixes (e.g. R-200-210 or R-200-R-210), or ranges of numbers with suffixes (e.g. 1-a-50 or 1-a-50-a).  Wildcards are not added to catalog number searches (so =1 and 1 return the same result).  To search with wildcards or to limit both prefixes and suffixes, use the search builder.</dd>
												<dt><span class="text-info font-weight-bold">Other Number</span></dt> 
												<dd>Other number accepts single numbers, ranges of numbers, comma separated lists of numbers, and ranges of numbers, but for most cases with prefixes, search for just a single prefixed number with an exact match search (e.g. =BT-782)</dd>
												<dt><span class="text-info font-weight-bold">Taxonomy and Higher Geography Fields</span> </dt>
												<dd>Search for a substring (e.g. murex), an exact match (e.g. =Murex), or a comma separated list (e.g. Vulpes,Urocyon).</dd>
												<dt><span class="text-info font-weight-bold">Any Geography (keyword) Field</span> </dt>
												<dd>This field runs a keyword search on a large set of geography fields.  See the Keyword Search Help for guidance.</dd>
												<dt><span class="text-info font-weight-bold">Keyword Search Field</span> </dt>
												<dd>This field does the same thing as the Keyword Search.  See the Keyword Search Help for guidance.</dd>
												<dt><span class="text-info font-weight-bold">Dates</span></dt>
												<dd>Collecting Events are stored in two date fields (date began and date ended), plus a verbatim field.  Date Collected searches on both the began date and end date for collecting events.  A range search on Date Collected (e.g. 1980/1985) will find all cataloged items where both the date began and date ended fall within the specified range.  Usually you will want to search on Date Collected.  The began date and ended date fields can be searched separately for special cases, in particular cases where the collecting date range is poorly constrained.  Search on Began Date 1700-01-01 Ended Date 1800-01-01/1899-12-31 to find all material where the began date is not known, but the end date has been constrained to sometime in the 1800s (contrast with Date Collected 1800-01-01/1899-12-31 which finds material where both the start and end dates are in the 1800s).</dd>
												<dt><span class="text-info font-weight-bold">Media Type</span></dt>
												<dd>Click on (Any) to paste NOT NULL into the field, this will find records where there are any related media.</dd>
												<dt><span class="text-info font-weight-bold">Min/Max Depth/Elevation Fields</span> </dt>
												<dd>Search on depth or elevation converted from original units to meters, accepts 1-10 for ranges or <=1 or >=1 to search for open ended ranges.  Search on minimum depth and maximum depth are independent, likewise for elevation.  To search for all material known to be collected between two depth endpoints search on the same range e.g. 1-10 in minimum and maximum depth fields, this will find all material where the minimum depth is in that range and the maximum depth is in that range, likewise for elevation.  Search Minimum depth for NOT NULL to find any depth value.</dd>
											</dl>
										</div>
									</aside>
								</div>
								<div role="search" class="container-fluid px-0">
									<form id="fixedSearchForm">
										<cfif isdefined("session.BASICSRCHPREFS") and len(session.BASICSRCHPREFS) gt 0>
											<cfset searchPrefList = session.BASICSRCHPREFS>
										<cfelse>
											<cfset searchPrefList = "">
										</cfif>
										<input type="hidden" name="result_id" id="result_id_fixedSearch" value="" class="excludeFromLink">
										<input type="hidden" name="method" id="method_fixedSearch" value="executeFixedSearch" class="keeponclear excludeFromLink">
										<input type="hidden" name="action" value="fixedSearch" class="keeponclear">
										<div class="container-flex togglesearchform" style="display: block;">
											<div class="col-12 search-form-basic-odd px-4 py-2">
												<cfset hiddenHaveValue = false>
												<cfif (isDefined("other_id_type_1") and len(other_id_type_1) GT 0) 
													OR (isDefined("other_id_number_1") and len(other_id_number_1) GT 0)>
													<cfset hiddenHaveValue = true>
												</cfif>
												<cfif listFind(searchPrefList,"IDDetail") GT 0 OR hiddenHaveValue>
													<cfset IDDetailStyle="">
													<cfset toggleTo = "0">
													<cfset IDButton = "Fewer Fields">
												<cfelse>
													<cfset IDDetailStyle="display:none;">
													<cfset toggleTo = "1">
													<cfset IDButton = "More Fields">
												</cfif> 
												<div class="col-12 col-xl-1 px-2 px-xl-3 px-md-2 float-left">
													<div class="small95 font-weight-bold d-inline-block-md text-dark mt-2 mb-0 py-0">
														Identifiers&nbsp;&nbsp;
														<cfif findNoCase('redesign',gitBranch) GT 0 OR (isdefined("session.roles") AND listfindnocase(session.roles,"collops") ) >
															<button type="button" id="IDDetailCtl" class="btn btn-xs px-0 float-right small py-0 border-0 btn-link" onclick="toggleIDDetail(#toggleTo#);">(#IDButton#)</button>
														</cfif>
													</div>
												</div>	
												<div class="form-row col-12 col-xl-11 px-0 mx-0 mb-0">
													<div class="col-12 mb-1 col-md-3">
														<label for="fixedCollection" class="data-entry-label small">Collection</label>
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
																$("##fixedCollection").jqxComboBox({ source: collectionsource, displayMember:"name", valueMember:"cde", multiSelect: true, height: '21px', width: '100%' });
																setFixedCollectionValues();
															});
														</script> 
													</div>
													<div class="col-12 mb-1 col-md-3">
														<cfif not isdefined("cat_num")><cfset cat_num=""></cfif>
														<label for="catalogNum" class="data-entry-label small">Catalog Number</label>
														<input id="catalogNum" type="text" name="cat_num" class="data-entry-input small inputHeight" placeholder="1,1-4,A-1,R1-4" value="#encodeForHtml(cat_num)#">
													</div>
													<cfif findNoCase('redesign',gitBranch) GT 0 OR (isdefined("session.roles") and listfindnocase(session.roles,"global_admin") ) >
														<!--- reserve space for debug json control --->
														<cfset other_id_type_cols="col-md-2">
														<cfset other_id_number_cols="col-md-2">
													<cfelse>
														<cfset other_id_type_cols="col-md-3">
														<cfset other_id_number_cols="col-md-3">
													</cfif>
													<div class="col-12 mb-1 #other_id_type_cols#">
														<cfif not isdefined("other_id_type")><cfset other_id_type=""></cfif>
														<label for="otherID" class="data-entry-label small">Other ID Type</label>
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
																$("##other_id_type").jqxComboBox({ source: otheridtypesource, displayMember:"meta", valueMember:"name", multiSelect: true, height: '21px', width: '100%' });
																setOtherIdTypeValues();
															});
														</script> 
													</div>
													<div class="col-12 mb-1 #other_id_number_cols#">
														<cfif not isdefined("other_id_number")><cfset other_id_number=""></cfif>
														<label for="other_id_number" class="data-entry-label small">Other ID Numbers</label>
														<input type="text" class="data-entry-input small inputHeight" id="other_id_number" name="other_id_number" placeholder="10,20-30,=BT-782" value="#encodeForHtml(other_id_number)#">
													</div>
													<cfif findNoCase('redesign',gitBranch) GT 0 OR (isdefined("session.roles") and listfindnocase(session.roles,"global_admin") ) >
														<div class="col-12 mb-1 col-md-2">
															<label class="data-entry-label small" for="debug1">Debug JSON</label>
															<select title="debug" name="debug" id="debug1" class="data-entry-select smaller inputHeight">
																<option value=""></option>
																<cfif isdefined("debug") AND len(debug) GT 0><cfset selected=" selected "><cfelse><cfset selected=""></cfif>
																<option value="true" #selected#>Debug JSON</option>
															</select>
														</div>
													</cfif>
													<div id="IDDetail" class="col-12 px-0" style="#IDDetailStyle#">
													<div class="form-row col-12 col-md-12 px-0 mx-0 mb-0">
														<cfif findNoCase('redesign',gitBranch) GT 0 OR (isdefined("session.roles") AND listfindnocase(session.roles,"collops") ) >
															<!--- for now, while testing nesting, only show second other ID controls for collops users.  --->
																<div class="col-12 mb-1 col-md-3">
																	<cfif not isdefined("other_id_type_1")><cfset other_id_type_1=""></cfif>
																	<label for="otherID" class="data-entry-label small">Other ID Type</label>
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
																			$("##other_id_type_1").jqxComboBox({ source: otheridtypesource, displayMember:"meta", valueMember:"name", multiSelect: true, height: '21px', width: '100%' });
																			setOtherIdType_1_Values();
																		});
																	</script> 
																</div>
																<div class="col-12 mb-1 col-md-3">
																	<cfif not isdefined("other_id_number_1")><cfset other_id_number_1=""></cfif>
																	<label for="other_id_number_1" class="data-entry-label small">Other ID Numbers</label>
																	<input type="text" class="data-entry-input inputHeight" id="other_id_number_1" name="other_id_number_1" placeholder="10,20-30,=BT-782" value="#encodeForHtml(other_id_number_1)#">
																</div>
																<div class="col-12 mb-1 col-md-6">
																	<label for="other_id_controls_note" class="data-entry-label small">Note: </label>
																	<p id="other_id_controls_note" class="px-1 pb-0 small mb-0">Second set of other id type/other id number fields is for testing, may not work as expected.</p>
																</div>
															</cfif>
														</div>
													</div>
												</div>
											</div>
											<div class="col-12 px-4 py-2">
												<cfset hiddenHaveValue = false>
												<cfif (isDefined("phylum") and len(phylum) GT 0)
													OR (isDefined("phylclass") and len(phylclass) GT 0)
													OR (isDefined("phylorder") and len(phylorder) GT 0)
													OR (isDefined("family") and len(family) GT 0)
													OR (isDefined("genus") and len(genus) GT 0)
													OR (isDefined("species") and len(species) GT 0)
													OR (isDefined("determiner") and len(determiner) GT 0)
													OR (isDefined("citation") and len(citation) GT 0)
													OR (isDefined("identification_remarks") and len(identification_remarks) GT 0)
													OR (isDefined("common_name") and len(common_name) GT 0)
													OR (isDefined("nature_of_id") and len(nature_of_id) GT 0)
												>
													<cfset hiddenHaveValue = true>
												</cfif>
												<cfif listFind(searchPrefList,"TaxaDetail") GT 0 OR hiddenHaveValue>
													<cfset TaxaDetailStyle="">
													<cfset toggleTo = "0">
													<cfset TaxaButton = "Fewer Fields">
												<cfelse>
													<cfset TaxaDetailStyle="display:none;">
													<cfset toggleTo = "1">
													<cfset TaxaButton = "More Fields">
												</cfif>
												<div class="col-12 col-xl-1 px-xl-3 px-2 px-md-2 float-left">
													<div class="small95 font-weight-bold d-inline-block-md text-dark my-0 py-1">
														Taxonomy&nbsp;&nbsp;
														<button type="button" id="TaxaDetailCtl" class="btn d-inline-block-md btn-xs px-0 float-right small py-0 border-0 btn-link" onclick="toggleTaxaDetail(#toggleTo#);">(#TaxaButton#)</button>
													</div>
												</div>
												<div class="form-row col-12 col-xl-11 px-0 mx-0 mb-0">
													<div class="col-12 mb-1 col-md-4">
														<div class="form-row mx-0 mb-0">
															<div class="col-9 px-0">
																<cfif not isdefined("any_taxa_term")><cfset any_taxa_term=""></cfif>
																<label for="any_taxa_term" class="data-entry-label small">Any Taxonomic Element</label>
																<input id="any_taxa_term" name="any_taxa_term" class="data-entry-input inputHeight" aria-label="any taxonomy" value="#encodeForHtml(any_taxa_term)#">
															</div>
															<div class="col-3">
																<cfif not isdefined("current_id_only")><cfset current_id_only="any"></cfif>
																<label for="current_id_only" class="data-entry-label small">Search</label>
																<select id="current_id_only" name="current_id_only" class="data-entry-select inputHeight small px-0">
																	<cfif current_id_only EQ "current"><cfset current_selected = " selected "><cfset any_selected=""></cfif>
																	<cfif current_id_only EQ "any"><cfset current_selected = ""><cfset any_selected=" selected "></cfif>
																	<option value="any" #any_selected#>Any Id</option>
																	<option value="current" #current_selected#>Current Id Only</option>
																</select>
															</div>
														</div>
													</div>
													<div class="col-12 mb-1 col-md-3">
														<label for="scientific_name" class="data-entry-label small">Scientific Name</label>
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
														<input type="text" id="scientific_name" name="scientific_name" class="data-entry-input inputHeight" value="#encodeForHtml(scientific_name)#" >
														<input type="hidden" id="taxon_name_id" name="taxon_name_id" value="#encodeForHtml(taxon_name_id)#" >
														<script>
															jQuery(document).ready(function() {
																makeScientificNameAutocompleteMeta('scientific_name','taxon_name_id');
															});
														</script>
													</div>
													<div class="col-12 mb-1 col-md-3">
														<label for="author_text" class="data-entry-label small">Authorship</label>
														<cfif not isdefined("author_text")><cfset author_text=""></cfif>
														<input id="author_text" name="author_text" class="data-entry-input inputHeight" value="#encodeForHtml(author_text)#" >
														<script>
															jQuery(document).ready(function() {
																makeTaxonSearchAutocomplete('author_text','author_text');
															});
														</script>
													</div>
													<div class="col-12 mb-1 col-md-2">
														<label for="type_status" class="data-entry-label small">Type Status/Citation
															<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##type_status').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open pick list</span></a>
														</label>
														<cfif not isdefined("type_status")><cfset type_status=""></cfif>
														<input type="text" class="data-entry-input inputHeight" id="type_status" name="type_status" value="#encodeForHtml(type_status)#">
														<script>
															jQuery(document).ready(function() {
																makeTypeStatusSearchAutocomplete('type_status');
															});
														</script>
													</div>
													<div id="TaxaDetail" class="col-12 px-0" style="#TaxaDetailStyle#">
														<div class="form-row col-12 col-md-12 px-0 mx-0 mb-0">
															<div class="col-12 mb-1 col-md-2">
																<label for="phylum" class="data-entry-label small">Phylum
																	<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##phylum').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open pick list</span></a>
																</label>
																<cfif not isdefined("phylum")><cfset phylum=""></cfif>
																<input id="phylum" name="phylum" class="data-entry-input inputHeight" value="#encodeForHtml(phylum)#" >
																<script>
																	jQuery(document).ready(function() {
																		makeTaxonSearchAutocomplete('phylum','phylum');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="phylclass" class="data-entry-label small">Class</label>
																<cfif not isdefined("phylclass")><cfset phylclass=""></cfif>
																<input id="phylclass" name="phylclass" class="data-entry-input inputHeight" value="#encodeForHtml(phylclass)#" >
																<script>
																	jQuery(document).ready(function() {
																		makeTaxonSearchAutocomplete('phylclass','class');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="phylorder" class="data-entry-label small">Order</label>
																<cfif not isdefined("phylorder")><cfset phylorder=""></cfif>
																<input id="phylorder" name="phylorder" class="data-entry-input inputHeight" value="#encodeForHtml(phylorder)#" >
																<script>
																	jQuery(document).ready(function() {
																		makeTaxonSearchAutocomplete('phylorder','order');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="family" class="data-entry-label small">Family</label>
																<cfif not isdefined("family")><cfset family=""></cfif>
																<input type="text" id="family" name="family" class="data-entry-input inputHeight" value="#encodeForHtml(family)#" >
																<script>
																	jQuery(document).ready(function() {
																		makeTaxonSearchAutocomplete('family','family');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="genus" class="data-entry-label small">Genus</label>
																<cfif not isdefined("genus")><cfset genus=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="genus" name="genus" value="#encodeForHtml(genus)#">
																<script>
																	jQuery(document).ready(function() {
																		makeTaxonSearchAutocomplete('genus','genus');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="species" class="data-entry-label small">Specific Name</label>
																<cfif not isdefined("species")><cfset species=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="species" name="species" value="#encodeForHtml(species)#">
																<script>
																	jQuery(document).ready(function() {
																		makeTaxonSearchAutocomplete('species','species');
																	});
																</script>
															</div>
															
														</div>
														<div class="form-row col-12 col-md-12 px-0 mx-0 mb-0">
															<div class="col-12 mb-1 col-md-2">
																<label for="determiner" class="data-entry-label small">Determiner</label>
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
																<input type="hidden" id="determiner_id" name="determiner_id" class="data-entry-input" value="#encodeForHtml(determiner_id)#" >
																<input type="text" id="determiner" name="determiner" class="data-entry-input inputHeight" value="#encodeForHtml(determiner)#" >
																<script>
																	jQuery(document).ready(function() {
																		makeConstrainedAgentPicker('determiner', 'determiner_id', 'determiner');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-4">
																<label for="publication_id" class="data-entry-label small">Cited In</label>
																<cfif not isdefined("publication_id")><cfset publication_id=""></cfif>
																<cfif not isdefined("citation")><cfset citation=""></cfif>
																<input type="hidden"  id="publication_id" name="publication_id" class="data-entry-input inputHeight" value="#encodeForHtml(publication_id)#" >
																<input type="text" id="citation" name="citation" class="data-entry-input inputHeight" value="#encodeForHtml(citation)#" >
																<script>
																	jQuery(document).ready(function() {
																		makePublicationPicker('citation','publication_id');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="nature_of_id" class="data-entry-label small">Nature Of Id</label>
																<cfif not isdefined("nature_of_id")><cfset nature_of_id=""></cfif>
																<select title="nature of id" name="nature_of_id" id="nature_of_id" class="data-entry-select inputHeight col-sm-12 pl-2">
																	<option value=""></option>
																	<cfset nid = nature_of_id>
																	<cfloop query="ctnature_of_id">
																		<cfif nid EQ "=#ctnature_of_id.nature_of_id#"><cfset selected=" selected "><cfelse><cfset selected = ""></cfif>
																		<option value="=#ctnature_of_id.nature_of_id#" #selected#>#ctnature_of_id.nature_of_id# (#ctnature_of_id.ct#)</option>
																	</cfloop>
																</select>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="identification_remarks" class="data-entry-label small">Id Remarks</label>
																<cfif not isdefined("identification_remarks")><cfset identification_remarks=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="identification_remarks" name="identification_remarks" value="#encodeForHtml(identification_remarks)#">
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="common_name" class="data-entry-label small">Common Name</label>
																<cfif not isdefined("common_name")><cfset common_name=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="common_name" name="common_name" value="#encodeForHtml(common_name)#">
															</div>
														</div>
													</div>
												</div>
											</div>
											<div class="col-12 search-form-basic-odd px-4 py-2">
												<cfset hiddenHaveValue = false>
												<cfif (isDefined("continent_ocean") and len(continent_ocean) GT 0)
													OR (isDefined("country") and len(country) GT 0)
													OR (isDefined("state_prov") and len(state_prov) GT 0)
													OR (isDefined("county") and len(county) GT 0)
													OR (isDefined("ocean_region") and len(ocean_region) GT 0)
													OR (isDefined("ocean_subregion") and len(ocean_subregion) GT 0)
													OR (isDefined("sea") and len(sea) GT 0)
													OR (isDefined("island_group") and len(island_group) GT 0)
													OR (isDefined("island") and len(island) GT 0)
													OR (isDefined("feature") and len(feature) GT 0)
													OR (isDefined("water_feature") and len(water_feature) GT 0)
													OR (isDefined("geo_att_value") and len(geo_att_value) GT 0)
													OR (isDefined("verificationstatus") and len(verificationstatus) GT 0)
													OR (isDefined("min_depth_in_m") and len(min_depth_in_m) GT 0)
													OR (isDefined("max_depth_in_m") and len(ax_depth_in_m) GT 0)
													OR (isDefined("min_elev_in_m") and len(min_elev_in_m) GT 0)
													OR (isDefined("max_elev_in_m") and len(max_elev_in_m) GT 0)>
													<cfset hiddenHaveValue = true>
												</cfif>
												<cfif listFind(searchPrefList,"GeogDetail") GT 0 or hiddenHaveValue>
													<cfset GeogDetailStyle="">
													<cfset toggleTo = "0">
													<cfset GeogButton = "Fewer Fields">
												<cfelse>
													<cfset GeogDetailStyle="display:none;">
													<cfset toggleTo = "1">
													<cfset GeogButton = "More Fields">
												</cfif>
												<div class="col-12 col-xl-1 px-xl-3 px-2 px-md-2 float-left">
													<div class="small95 font-weight-bold d-inline-block-md text-dark my-0 py-1">
														Geography&nbsp;&nbsp;
														<button type="button" id="GeogDetailCtl" class="btn d-inline-block-md px-0 btn-xs float-right small py-0 border-0 btn-link" onclick="toggleGeogDetail(#toggleTo#);">(#GeogButton#)</button>
													</div>
												</div>
												<div class="form-row col-12 col-xl-11 px-0 mx-0 mb-0">
													<div class="col-12 mb-1 col-md-4">
														<cfif not isdefined("any_geography")><cfset any_geography=""></cfif>
														<label for="any_geography" class="data-entry-label small">Any Geography (keywords)</label>
														<input type="text" class="data-entry-input inputHeight" name="any_geography" id="any_geography" value="#encodeForHtml(any_geography)#">
													</div>
													<div class="col-12 mb-1 col-md-4">
														<cfif not isdefined("higher_geog")><cfset higher_geog=""></cfif>
														<label for="higher_geog" class="data-entry-label small">Higher Geography</label>
														<input type="text" class="data-entry-input inputHeight" name="higher_geog" id="higher_geog" value="#encodeForHtml(higher_geog)#">
													</div>
													<div class="col-12 mb-1 col-md-4">
														<label for="spec_locality" class="data-entry-label small">Specific Locality</label>
														<cfif not isdefined("spec_locality")><cfset spec_locality=""></cfif>
														<input type="text" class="data-entry-input inputHeight" id="spec_locality" name="spec_locality" value="#encodeForHtml(spec_locality)#">
														<script>
															jQuery(document).ready(function() {
																makeSpecLocalitySearchAutocomplete('spec_locality',);
															});
														</script>
													</div>
													<div id="GeogDetail" class="col-12 px-0" style="#GeogDetailStyle#">
														<div class="form-row col-12 col-md-12 px-0 mb-0 mx-0">
															<div class="col-12 mb-1 col-md-3">
																<cfif not isdefined("continent_ocean")><cfset continent_ocean=""></cfif>
																<label for="continent_ocean" class="data-entry-label small">Continent/Ocean</label>
																<input type="text" class="data-entry-input inputHeight" name="continent_ocean" id="continent_ocean" value="#encodeForHtml(continent_ocean)#">
																<script>
																	jQuery(document).ready(function() {
																		makeGeogSearchAutocomplete('continent_ocean','continent_ocean');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-3">
																<label for="country" class="data-entry-label small">Country</label>
																<cfif not isdefined("country")><cfset country=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="country" name="country" value="#encodeForHtml(country)#">
																<script>
																	jQuery(document).ready(function() {
																		makeCountrySearchAutocomplete('country');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-3">
																<label for="state_prov" class="data-entry-label small">State/Province</label>
																<cfif not isdefined("state_prov")><cfset state_prov=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="state_prov" name="state_prov" aria-label="state or province" value="#encodeForHtml(state_prov)#">
																<script>
																	jQuery(document).ready(function() {
																		makeGeogSearchAutocomplete('state_prov','state_prov');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-3">
																<label for="county" class="data-entry-label small">County/Shire/Parish</label>
																<cfif not isdefined("county")><cfset county=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="county" name="county" aria-label="county shire or parish" value="#encodeForHtml(county)#">
																<script>
																	jQuery(document).ready(function() {
																		makeGeogSearchAutocomplete('county','county');
																	});
																</script>
															</div>
															
														</div>
														<div class="form-row col-12 col-md-12 px-0 mb-0 mx-0">
															<div class="col-12 mb-1 col-md-2">
																<label for="ocean_region" class="data-entry-label small">Ocean Region</label>
																<cfif not isdefined("ocean_region")><cfset ocean_region=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="ocean_region" name="ocean_region" value="#encodeForHtml(ocean_region)#">
																<script>
																	jQuery(document).ready(function() {
																		makeGeogSearchAutocomplete('ocean_region','ocean_region');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="ocean_subregion" class="data-entry-label small">Ocean Sub-Region</label>
																<cfif not isdefined("ocean_subregion")><cfset ocean_subregion=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="ocean_subregion" name="ocean_subregion" value="#encodeForHtml(ocean_subregion)#">
																<script>
																	jQuery(document).ready(function() {
																		makeGeogSearchAutocomplete('ocean_subregion','ocean_subregion');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="sea" class="data-entry-label small">Sea
																	<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##sea').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open pick list</span></a>
																</label>
																<cfif not isdefined("sea")><cfset sea=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="sea" name="sea" value="#encodeForHtml(sea)#">
																<script>
																	jQuery(document).ready(function() {
																		makeGeogSearchAutocomplete('sea','sea');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-3">
																<label for="island_group" class="data-entry-label small">Island Group</label>
																<cfif not isdefined("island_group")><cfset island_group=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="island_group" name="island_group" value="#encodeForHtml(island_group)#">
																<script>
																	jQuery(document).ready(function() {
																		makeGeogSearchAutocomplete('island_group','island_group');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-3">
																<label for="island" class="data-entry-label small">Island</label>
																<cfif not isdefined("island")><cfset island=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="island" name="island" value="#encodeForHtml(island)#">
																<script>
																	jQuery(document).ready(function() {
																		makeGeogSearchAutocomplete('island','island');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-3">
																<label for="feature" class="data-entry-label small">Land Feature</label>
																<cfif not isdefined("feature")><cfset feature=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="feature" name="feature" value="#encodeForHtml(feature)#">
																<script>
																	jQuery(document).ready(function() {
																		makeGeogSearchAutocomplete('feature','feature');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-3">
																<label for="water_feature" class="data-entry-label small">Water Feature</label>
																<cfif not isdefined("water_feature")><cfset water_feature=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="water_feature" name="water_feature" value="#encodeForHtml(water_feature)#">
																<script>
																	jQuery(document).ready(function() {
																		makeGeogSearchAutocomplete('water_feature','water_feature');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-3">
																<label for="geo_att_value" class="data-entry-label small">Geological Attribute</label>
																<cfif not isdefined("geo_att_value")><cfset geo_att_value=""></cfif>
																<!--- TODO, possibly, implement attribute type, might not be needed --->
																<input type="hidden" id="geology_attribute" name="geology_attribute" value="">
																<input type="hidden" id="geology_attribute_heirarchy_id" name="geology_attribute_heirarchy_id" value="">
																<input type="text" class="data-entry-input inputHeight" id="geo_att_value" name="geo_att_value" value="#encodeForHtml(geo_att_value)#">
																<script>
																	jQuery(document).ready(function() {
																		makeGeologyAutocompleteMeta('geology_attribute', 'geo_att_value', 'geology_attribute_heirarchy_id', 'search', null);
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-3">
																<label for="verificationstatus" class="data-entry-label small">
																	Georeference Verification
																	<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('##verificationstatus').autocomplete('search','%'); return false;" > (&##8595;) <span class="sr-only">open pick list</span></a>
																</label>
																<cfif not isdefined("verificationstatus")><cfset verificationstatus=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="verificationstatus" name="verificationstatus" value="#encodeForHtml(verificationstatus)#">
																<script>
																	jQuery(document).ready(function() {
																		makeCTFieldSearchAutocomplete('verificationstatus','VERIFICATIONSTATUS');
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="min_depth_in_m" class="data-entry-label small">Miniumum Depth (m)</label>
																<cfif not isdefined("min_depth_in_m")><cfset min_depth_in_m=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="min_depth_in_m" name="min_depth_in_m" value="#encodeForHtml(min_depth_in_m)#">
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="max_depth_in_m" class="data-entry-label small">Maximum Depth (m)</label>
																<cfif not isdefined("max_depth_in_m")><cfset max_depth_in_m=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="max_depth_in_m" name="max_depth_in_m" value="#encodeForHtml(max_depth_in_m)#">
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="min_elev_in_m" class="data-entry-label small">Miniumum Elevation (m)</label>
																<cfif not isdefined("min_elev_in_m")><cfset min_elev_in_m=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="min_elev_in_m" name="min_elev_in_m" value="#encodeForHtml(min_elev_in_m)#">
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="max_elev_in_m" class="data-entry-label small">Maximum Elevation (m)</label>
																<cfif not isdefined("max_elev_in_m")><cfset max_elev_in_m=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="max_elev_in_m" name="max_elev_in_m" value="#encodeForHtml(max_elev_in_m)#">
															</div>
														</div>
													</div>
												</div>
											</div>
											<div class="col-12 px-4 py-2">
												<cfset hiddenHaveValue = false>
												<cfif (isDefined("date_began_date") and len(date_began_date) GT 0)
													OR (isDefined("date_ended_date") and len(date_ended_date) GT 0)
													OR (isDefined("verbatim_locality") and len(verbatim_locality) GT 0)>
													<cfset hiddenHaveValue = true>
												</cfif>
												<cfif listFind(searchPrefList,"CollDetail") GT 0 OR hiddenHaveValue>
													<cfset CollDetailStyle="">
													<cfset toggleTo = "0">
													<cfset CollButton = "Fewer Fields">
												<cfelse>
													<cfset CollDetailStyle="display:none;">
													<cfset toggleTo = "1">
													<cfset CollButton = "More Fields">
												</cfif> 
												<div class="col-12 col-xl-1 px-2 px-xl-3 px-md-2 float-left">
													<div class="small95 font-weight-bold d-inline-block-md text-dark my-0 py-1">
														Events&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
														<button type="button" id="CollDetailCtl" class="btn px-0 d-inline-block-md btn-xs float-right small py-0 border-0 btn-link" onclick="toggleCollDetail(#toggleTo#);">(#CollButton#)</button>
													</div>
												</div>
												<div class="form-row col-12 col-lg-11 px-0 mx-0 mb-0">
													<div class="col-12 mb-1 col-md-3">
														<label for="collector" class="data-entry-label small">Collector</label>
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
														<input type="text" id="collector" name="collector" class="data-entry-input inputHeight" value="#encodeForHtml(collector)#">
														<input type="hidden" id="collector_agent_id" name="collector_agent_id" value="#encodeForHtml(collector_agent_id)#">
														<script>
															jQuery(document).ready(function() {
																makeConstrainedAgentPicker('collector','collector_agent_id','collector');
															});
														</script>
													</div>
													<div class="col-12 mb-1 col-md-3">
														<cfif not isdefined("collecting_source")>
															<cfset collecting_source="">
														</cfif>
														<label for="collecting_source" class="data-entry-label small">Collecting Source
															<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('##collecting_source').autocomplete('search','%'); return false;" > (&##8595;) <span class="sr-only">open pick list</span></a>
														</label>
														<input type="text" name="collecting_source" class="data-entry-input inputHeight" id="collecting_source" value="#encodeForHtml(collecting_source)#" >
														<script>
															jQuery(document).ready(function() {
																makeCTFieldSearchAutocomplete("collecting_source","COLLECTING_SOURCE");
															});
														</script>
													</div>
													<div class="col-12 mb-1 col-md-3">
														<cfif not isdefined("date_collected")>
															<cfset date_collected="">
														</cfif>
														<label for="date_collected" class="data-entry-label small">Date Collected</label>
														<input type="text" name="date_collected" class="data-entry-input inputHeight" id="date_collected" placeholder="yyyy-mm-dd/yyyy-mm-dd" value="#encodeForHtml(date_collected)#" >
													</div>
													<div class="col-12 mb-1 col-md-3">
														<cfif not isdefined("verbatim_date")><cfset verbatim_date=""></cfif>
														<label class="data-entry-label small" for="when">Verbatim Date</label>
														<input type="text" name="verbatim_date" class="data-entry-input inputHeight" id="verbatim_date" value="#encodeForHtml(verbatim_date)#">
													</div>
													<div id="CollDetail" class="col-12 px-0" style="#CollDetailStyle#">
														<div class="form-row col-12 col-md-12 px-0 mx-0 mb-0">
															<div class="col-12 mb-1 col-md-3">
																<cfif not isdefined("date_began_date")>
																	<cfset date_began_date="">
																</cfif>
																<label for="date_began_date" class="data-entry-label small">Date Began</label>
																<input type="text" name="date_began_date" class="data-entry-input inputHeight" id="date_began_date" placeholder="yyyy-mm-dd/yyyy-mm-dd" value="#encodeForHtml(date_began_date)#" >
															</div>
															<div class="col-12 mb-1 col-md-3">
																<cfif not isdefined("date_ended_date")>
																	<cfset date_ended_date="">
																</cfif>
																<label for="date_ended_date" class="data-entry-label small">Date Ended</label>
																<input type="text" name="date_ended_date" class="data-entry-input inputHeight" id="date_ended_date" placeholder="yyyy-mm-dd/yyyy-mm-dd" value="#encodeForHtml(date_ended_date)#" >
															</div>
															<div class="col-12 mb-1 col-md-4">
																<label for="verbatim_locality" class="data-entry-label small">Verbatim Locality</label>
																<cfif not isdefined("verbatim_locality")><cfset verbatim_locality=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="verbatim_locality" name="verbatim_locality" value="#encodeForHtml(verbatim_locality)#">
															</div>
														</div>
													</div>
												</div>
											</div>
											<div class="col-12 search-form-basic-odd px-4 py-2">
												<cfset hiddenHaveValue = false>
												<cfif (isDefined("part_remarks") and len(part_remarks) GT 0)
													OR (isDefined("coll_object_remarks") and len(coll_object_remarks) GT 0)
													OR (isDefined("lot_count") and len(lot_count) GT 0)
													OR (isDefined("disposition_remarks") and len(disposition_remarks) GT 0)
													OR (isDefined("coll_obj_disposition") and len(coll_obj_disposition) GT 0)>
													<cfset hiddenHaveValue = true>
												</cfif>
												<cfif listFind(searchPrefList,"SpecDetail") GT 0 OR hiddenHaveValue>
													<cfset SpecDetailStyle="">
													<cfset toggleTo = "0">
													<cfset SpecButton = "Fewer Fields">
												<cfelse>
													<cfset SpecDetailStyle="display:none;">
													<cfset toggleTo = "1">
													<cfset SpecButton = "More Fields">
												</cfif> 
												<div class="col-12 col-xl-1 px-2 px-xl-3 px-md-2 float-left">
													<div class="small95 font-weight-bold d-inline-block text-dark px-0 my-1 py-1">
														Specimen&nbsp;&nbsp;
														<button type="button" id="SpecDetailCtl" class="btn px-0 d-inline-block-md btn-xs float-right small py-0 border-0 btn-link" onclick="toggleSpecDetail(#toggleTo#);">(#SpecButton#)</button>
													</div>
												</div>
												<div class="form-row col-12 col-lg-11 px-0 mx-0 mb-0">
													<div class="col-12 mb-1 col-md-3">
														<cfif not isdefined("part_name")><cfset part_name=""></cfif>
														<label for="part_name" class="data-entry-label small">Part Name</label>
														<input type="text" id="part_name" name="part_name" class="data-entry-input inputHeight" value="#encodeForHtml(part_name)#" >
														<script>
															jQuery(document).ready(function() {
																makePartNameAutocompleteMeta('part_name');
															});
														</script>
													</div>
													<div class="col-12 mb-1 col-md-3">
														<cfif not isdefined("preserve_method")><cfset preserve_method=""></cfif>
														<label for="preserve_method" class="data-entry-label small">Preserve Method
															<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('##preserve_method').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open pick list</span></a>
														</label>
														<input type="text" id="preserve_method" name="preserve_method" class="data-entry-input inputHeight" value="#encodeForHtml(preserve_method)#" >
														<script>
															jQuery(document).ready(function() {
																makePreserveMethodAutocompleteMeta('preserve_method');
															});
														</script>
													</div>
													<div class="col-12 mb-1 col-md-3">
														<cfif not isdefined("biol_indiv_relationship")><cfset biol_indiv_relationship=""></cfif>
														<label for="biol_indiv_relationship" class="data-entry-label small">Has Relationship
															<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('##biol_indiv_relationship').val('NOT NULL'); return false;" > (Any) <span class="sr-only">use NOT NULL to find cataloged items with relationships of any type</span></a>
															<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('##biol_indiv_relationship').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open pick list</span></a>
														</label>
														<input type="text" id="biol_indiv_relationship" name="biol_indiv_relationship" class="data-entry-input inputHeight" value="#encodeForHtml(biol_indiv_relationship)#" >
														<script>
															jQuery(document).ready(function() {
																makeBiolIndivRelationshipAutocompleteMeta('biol_indiv_relationship');
															});
														</script>
													</div>
													<div class="col-12 mb-1 col-md-3">
														<cfif not isdefined("media_type")><cfset media_type=""></cfif>
														<label for="media_type" class="data-entry-label small">Media Type
															<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('##media_type').val('NOT NULL'); return false;" > (Any) <span class="sr-only">use NOT NULL to find cataloged items with media of any type</span></a>
															<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('##media_type').autocomplete('search','%'); return false;" > (&##8595;) <span class="sr-only">open pick list</span></a>
														</label>
														<input type="text" id="media_type" name="media_type" class="data-entry-input inputHeight" value="#encodeForHtml(media_type)#" >
														<script>
															jQuery(document).ready(function() {
																makeCTFieldSearchAutocomplete("media_type","MEDIA_TYPE");
															});
														</script>
													</div>
													<div id="SpecDetail" class="col-12 px-0" style="#SpecDetailStyle#">
														<div class="form-row col-12 col-md-12 px-0 mx-0 mb-0">
															<div class="col-12 mb-1 col-md-3">
																<label for="coll_object_remarks" class="data-entry-label small">Collection Object Remarks</label>
																<cfif not isdefined("coll_object_remarks")><cfset coll_object_remarks=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="coll_object_remarks" name="coll_object_remarks" value="#encodeForHtml(coll_object_remarks)#">
															</div>
															<div class="col-12 mb-1 col-md-3">
																<label for="part_remarks" class="data-entry-label small">Part Remarks</label>
																<cfif not isdefined("part_remarks")><cfset part_remarks=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="part_remarks" name="part_remarks" value="#encodeForHtml(part_remarks)#">
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="lot_count" class="data-entry-label small">Lot Count</label>
																<cfif not isdefined("lot_count")><cfset lot_count=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="lot_count" name="lot_count" value="#encodeForHtml(lot_count)#">
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="coll_obj_disposition" class="data-entry-label small">
																	Disposition
																	<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('##coll_obj_disposition').autocomplete('search','%'); return false;" > (&##8595;) <span class="sr-only">open pick list</span></a>
																</label>
																<cfif not isdefined("coll_obj_disposition")><cfset coll_obj_disposition=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="coll_obj_disposition" name="coll_obj_disposition" value="#encodeForHtml(coll_obj_disposition)#">
																<script>
																	jQuery(document).ready(function() {
																		makeCTFieldSearchAutocomplete("coll_obj_disposition","COLL_OBJ_DISP");
																	});
																</script>
															</div>
															<div class="col-12 mb-1 col-md-2">
																<label for="disposition_remarks" class="data-entry-label small">Disposition Remarks</label>
																<cfif not isdefined("disposition_remarks")><cfset disposition_remarks=""></cfif>
																<input type="text" class="data-entry-input inputHeight" id="disposition_remarks" name="disposition_remarks" value="#encodeForHtml(disposition_remarks)#">
															</div>
														</div>
													</div>
												</div>
											</div>
											<div class="col-12 px-4 py-2">
												<div class="col-12 col-xl-1 px-2 px-xl-3 px-md-2 float-left">
													<div class="small95 font-weight-bold d-inline-block text-dark px-0 my-1 py-1">
														General/ Metadata
													</div>
												</div>
												<div class="form-row col-12 col-xl-11 px-0 mb-0 mx-0">
													<div class="col-12 mb-1 col-md-2">
														<cfif not isdefined("keyword")>
															<cfset keyword="">
														</cfif>
														<label for="keyword" class="data-entry-label small">Keyword Search</label>
														<input type="text" name="keyword" class="data-entry-input inputHeight" id="keyword" value="#encodeForHtml(keyword)#" >
													</div>
													<div class="col-12 mb-1 col-md-2">
														<cfif not isdefined("coll_object_entered_date")>
															<cfset coll_object_entered_date="">
														</cfif>
														<label for="coll_object_entered_date" class="data-entry-label small">Date Entered</label>
														<input type="text" name="coll_object_entered_date" class="data-entry-input inputHeight" id="coll_object_entered_date" placeholder="yyyy-mm-dd/yyyy-mm-dd" value="#encodeForHtml(coll_object_entered_date)#" >
													</div>
													<div class="col-12 mb-1 col-md-2">
														<label for="coll_object_entered_date" class="data-entry-label small">Entered By</label>
														<cfif not isdefined("entered_by")><cfset entered_by=""></cfif>
														<cfif not isdefined("entered_by_id")><cfset entered_by_id=""></cfif>
														<!--- lookup agent name --->
														<cfif len(entered_by) EQ 0 AND len(entered_by_id) GT 0>
															<cfquery name="lookupEnteredBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookupDeterminer_result">
																SELECT agent_name
																FROM preferred_agent_name
																WHERE
																	agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#entered_by_id#">
															</cfquery>
															<cfif lookupEnteredBy.recordcount EQ 1>
																<cfset entered_by = "=#lookupDeterminer.agent_name#">
															</cfif>
														</cfif>
														<input type="hidden" id="entered_by_id" name="entered_by_id" class="data-entry-input" value="#encodeForHtml(entered_by_id)#" >
														<input type="text" id="entered_by" name="entered_by" class="data-entry-input inputHeight" value="#encodeForHtml(entered_by)#" >
														<script>
															jQuery(document).ready(function() {
																// backing doesn't include a join to support substring search, so use picker configured to clear both fields.
																// makeConstrainedAgentPicker('entered_by', 'entered_by_id', 'entered_by');
																makeConstrainedAgentPickerConfig('entered_by', 'entered_by_id', 'entered_by', true);
															});
														</script>
													</div>
													<div class="col-12 mb-1 col-md-2">
														<cfif not isdefined("last_edit_date")>
															<cfset last_edit_date="">
														</cfif>
														<label for="last_edit_date" class="data-entry-label small">Last Updated on</label>
														<input type="text" name="last_edit_date" class="data-entry-input inputHeight" id="last_edit_date" placeholder="yyyy-mm-dd/yyyy-mm-dd" value="#encodeForHtml(last_edit_date)#" >
													</div>
													<div class="col-12 mb-1 col-md-2">
														<label for="coll_object_entered_date" class="data-entry-label small">Last Updated By</label>
														<cfif not isdefined("last_edited_person")><cfset last_edited_person=""></cfif>
														<cfif not isdefined("last_edited_person_id")><cfset last_edited_person_id=""></cfif>
														<!--- lookup agent name --->
														<cfif len(last_edited_person) EQ 0 AND len(last_edited_person_id) GT 0>
															<cfquery name="lookupEnteredBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookupDeterminer_result">
																SELECT agent_name
																FROM preferred_agent_name
																WHERE
																	agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#last_edited_person_id#">
															</cfquery>
															<cfif lookupEnteredBy.recordcount EQ 1>
																<cfset last_edited_person = "=#lookupDeterminer.agent_name#">
															</cfif>
														</cfif>
														<input type="hidden" id="last_edited_person_id" name="last_edited_person_id" class="data-entry-input" value="#encodeForHtml(last_edited_person_id)#" >
														<input type="text" id="last_edited_person" name="last_edited_person" class="data-entry-input inputHeight" value="#encodeForHtml(last_edited_person)#" >
														<script>
															jQuery(document).ready(function() {
																// backing doesn't include a join to support substring search, so use picker configured to clear both fields.
																makeConstrainedAgentPickerConfig('last_edited_person', 'last_edited_person_id', 'last_edited_person', true);
															});
														</script>
													</div>
													<div class="col-12 mb-1 col-md-2">
														<label for="underscore_collection" class="data-entry-label small">Named Group
															<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('##underscore_collection').val('NOT NULL'); $('##underscore_collection_id').val(''); return false;" > (Any) <span class="sr-only">use NOT NULL to find cataloged items in any named group</span></a>
														</label>
														<cfif not isdefined("underscore_collection_id")><cfset underscore_collection_id=""></cfif>
														<cfif not isdefined("underscore_collection")><cfset underscore_collection=""></cfif>
														<input type="hidden"  id="underscore_collection_id" name="underscore_collection_id" class="data-entry-input inputHeight" value="#encodeForHtml(underscore_collection_id)#" >
														<input type="text" id="underscore_collection" name="underscore_collection" class="data-entry-input inputHeight" value="#encodeForHtml(underscore_collection)#" >
														<script>
															jQuery(document).ready(function() {
																makeNamedCollectionPicker('underscore_collection','underscore_collection_id',false);
															});
														</script>
													</div>
												</div>
											</div>
											<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
												<div class="col-12 search-form-basic-odd px-4 py-2">
													<div class="col-12 col-xl-1 px-1 px-xl-3 px-md-2 float-left">
														<div class="small95 font-weight-bold d-inline-block text-dark my-1 py-1">
															Transactions&nbsp;&nbsp;
														</div>
													</div>
													<div class="form-row col-12 col-xl-11 px-0 mb-0 mx-0">
														<div class="col-12 mb-1 col-md-2">
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
															<label for="loan_number" class="data-entry-label small">Loan ##</label>
															<input type="text" name="loan_number" class="data-entry-input inputHeight" id="loan_number" placeholder="yyyy-n-Col" value="#encodeForHtml(loan_number)#" >
														</div>
														<div class="col-12 mb-1 col-md-2">
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
															<label for="accn_number" class="data-entry-label small">Accession ##</label>
															<input type="text" name="accn_number" class="data-entry-input inputHeight" id="accn_number" placeholder="nnnnn" value="#encodeForHtml(accn_number)#" >
														</div>
														<div class="col-12 mb-1 col-md-2">
															<cfif not isdefined("received_date")>
																<cfset received_date="">
															</cfif>
															<label for="received_date" class="data-entry-label small">Date Received</label>
															<input type="text" name="received_date" class="data-entry-input inputHeight" id="received_date" placeholder="yyyy-mm-dd/yyyy-mm-dd" value="#encodeForHtml(received_date)#" >
														</div>
														<div class="col-12 mb-1 col-md-2">
															<cfif not isdefined("accn_status")>
																<cfset accn_status="">
															</cfif>
															<label for="accn_status" class="data-entry-label small">Accession Status
																<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('##accn_status').autocomplete('search','%'); return false;" > (&##8595;) <span class="sr-only">open pick list</span></a>
															</label>
															<input type="text" name="accn_status" class="data-entry-input inputHeight" id="accn_status" value="#encodeForHtml(accn_status)#" >
															<script>
																jQuery(document).ready(function() {
																	makeCTFieldSearchAutocomplete("accn_status","ACCN_STATUS");
																});
															</script>
														</div>
														<div class="col-12 mb-1 col-md-2">
															<cfif not isdefined("accn_type")>
																<cfset accn_type="">
															</cfif>
															<label for="accn_type" class="data-entry-label small">Accession Type
																<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick="$('##accn_type').autocomplete('search','%'); return false;" > (&##8595;) <span class="sr-only">open pick list</span></a>
															</label>
															<input type="text" name="accn_type" class="data-entry-input inputHeight" id="accn_type" value="#encodeForHtml(accn_type)#" >
															<script>
																jQuery(document).ready(function() {
																	makeCTFieldSearchAutocomplete("accn_type","ACCN_TYPE");
																});
															</script>
														</div>
														<div class="col-12 mb-1 col-md-2">
															<cfif not isdefined("deaccession_number")>
																<cfset deaccession_number="">
															</cfif>
															<label for="deaccession_number" class="data-entry-label small">Deaccession ##</label>
															<input type="text" name="deaccession_number" class="data-entry-input inputHeight" id="deaccession_number" placeholder="Dyyyy-n-Col" value="#encodeForHtml(deaccession_number)#" >
														</div>
													</div>
												</div>
											</cfif>
											<div id="searchButtons">
												<div class="form-row mx-0 px-4 my-1 pb-1">
													<div class="col-12 px-2 py-2 py-sm-0">
														<button type="submit" class="btn btn-xs btn-primary col-12 col-md-auto px-md-5 mx-0 my-2 mr-md-5" aria-label="run the fixed search" id="fixedsubmitbtn">Search <i class="fa fa-search"></i></button>
														<button type="reset" class="btn btn-xs btn-warning col-12 col-md-auto px-md-3 mx-0 my-2 mr-md-2" aria-label="Reset this search form to inital values">Reset</button>
														<button type="button" class="btn btn-xs btn-warning col-12 col-md-auto px-md-3 mx-0 my-2" aria-label="Start a new specimen search with a clear page" onclick="window.location.href='#Application.serverRootUrl#/Specimens.cfm?action=fixedSearch';">New Search</button>
													</div>
												</div>
											</div>
										</div><!--- end container-flex --->
										<div class="menu_results"> </div>
									</form>
								</div>
								<!--- results for fixed search --->
								<div class="container-fluid" id="fixedSearchResultsSection">
									<div class="row">
										<div class="col-12">
											<div class="mb-3">
												<div class="row mx-0 mt-1 mb-0 pb-2 pb-md-0 jqx-widget-header border px-2">
													<h1 class="h4 ml-2 ml-md-1 pt3px">
														<span tabindex="0">Results:</span> 
														<span class="pr-2 font-weight-normal" id="fixedresultCount" tabindex="0"></span> 
														<span id="fixedresultLink" class="font-weight-normal pr-2"></span>
													</h1>
													<div id="fixedsaveDialogButton" class=""></div>
													<div id="fixedsaveDialog"></div>
													<div id="fixedcolumnPickDialog">
														<div class="container-fluid">
															<div class="row pick-column-width" id="fixedcolumnPick_row">
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
													<span id="fixedmanageButton" class=""></span>
													<div id="fixedresultBMMapLinkContainer"></div>
													<div id="fixedselectModeContainer" class="ml-3" style="display: none;" >
														<script>
															function fixedchangeSelectMode(){
																var selmode = $("##fixedselectMode").val();
																$("##fixedsearchResultsGrid").jqxGrid({selectionmode: selmode});
																if (selmode=="none") { 
																	$("##fixedsearchResultsGrid").jqxGrid({enableBrowserSelection: true});
																} else {
																	$("##fixedsearchResultsGrid").jqxGrid({enableBrowserSelection: false});
																}
															};
														</script>
														<script>
															function fixedMousewheel(){
																$("##selectBtn").jqxButton({theme: theme});
																$("##selectBtn").click(function(){
																	$("##fixedsearchResultsGrid").jqxGrid({enablemousewheel: true});
																});
																
																//val();
																//$("##fixedsearchResultsGrid").jqxGrid({enablemousewheel: true});
																//if (onOff==0) { 
																//	$("##fixedsearchResultsGrid").jqxGrid({enableBrowserSelection: false});
																//} else {
																//	$("##fixedsearchResultsGrid").jqxGrid({enableBrowserSelection: true});
																//}
															};
															
												
														</script>
														<label class="data-entry-label d-inline w-auto mt-1" for="fixedselectMode">Grid Select:</label>
														<select class="data-entry-select d-inline w-auto mt-1" id="fixedselectMode" onChange="fixedchangeSelectMode();">
															<cfif defaultSelectionMode EQ 'none'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
															<option #selected# value="none">Text</option>
															<cfif defaultSelectionMode EQ 'singlecell'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
															<option #selected# value="singlecell">Single Cell</option>
															<cfif defaultSelectionMode EQ 'singlerow'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
															<option #selected# value="singlerow">Single Row</option>
															<cfif defaultSelectionMode EQ 'multiplerowsextended'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
															<option #selected# value="multiplerowsextended">Multiple Rows (click, drag, release)</option>
															<cfif defaultSelectionMode EQ 'multiplecellsadvanced'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
															<option #selected# value="multiplecellsadvanced">Multiple Cells (click, drag, release)</option>
														</select>
													</div>
												
													<output id="fixedactionFeedback" class="btn btn-xs btn-transparent my-2 px-2 mx-1 pt-1 border-0"></output>
												</div>
												<cfquery name="column_headers1" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
													select column_name from all_tab_columns where table_name = 'FLAT'
												</cfquery>
												<div id="IDP" class="">
													<ul class="list-group list-group-horizontal" style="overflow:hidden;">
													<cfloop query = "column_headers1">
														<li class="list-group-item">#column_headers1.column_name#</li>
													</cfloop>
													</ul>
												</div>
													<!---(TO DO: Figure out how to make this sticky row work on the column header row)--->
												<div class="row mx-0 mt-0"> 
													
													<!--- Grid Related code is below along with search handlers --->
													<div id="fixedsearchResultsGrid" class="jqxGrid" role="table" aria-label="Search Results Table">
															
													</div>
													<div id="fixedenableselection"></div><div id="selectBtn" onClick="fixedMousewheel();" class="btn-xs btn btn-secondary">Toggle Mousewheel</div>
												</div>
											</div>
										</div>
									</div>
								</div>
							</section><!--- end fixed search tab --->
							<script type="text/javascript" language="javascript">
							function toggleIDDetail(onOff) {
								if (onOff==0) {
									$("##IDDetail").hide();
									$("##IDDetailCtl").attr('onCLick','toggleIDDetail(1)').html('More Fields');
								} else {
									$("##IDDetail").show();
									$("##IDDetailCtl").attr('onCLick','toggleIDDetail(0)').html('Fewer Fields');
								}
								<cfif isdefined("session.username") and len(#session.username#) gt 0>
									jQuery.getJSON("/specimens/component/search.cfc",
										{
											method : "saveBasicSrchPref",
											id : 'IDDetail',
											onOff : onOff,
											returnformat : "json",
											queryformat : 'column'
										}, 
										function (data) { 
											console.log(data);
										}
									).fail(function(jqXHR,textStatus,error){
										handleFail(jqXHR,textStatus,error,"persisting IDDetail state");
									});
								</cfif>
							}
							function toggleTaxaDetail(onOff) {
								if (onOff==0) {
									$("##TaxaDetail").hide();
									$("##TaxaDetailCtl").attr('onCLick','toggleTaxaDetail(1)').html('More Fields');
								} else {
									$("##TaxaDetail").show();
									$("##TaxaDetailCtl").attr('onCLick','toggleTaxaDetail(0)').html('Fewer Fields');
								}
								<cfif isdefined("session.username") and len(#session.username#) gt 0>
									jQuery.getJSON("/specimens/component/search.cfc",
										{
											method : "saveBasicSrchPref",
											id : 'TaxaDetail',
											onOff : onOff,
											returnformat : "json",
											queryformat : 'column'
										},
										function (data) { 
											console.log(data);
										}
									).fail(function(jqXHR,textStatus,error){
										handleFail(jqXHR,textStatus,error,"persisting TaxaDetail state");
									});
								</cfif>
							}
							function toggleGeogDetail(onOff) {
								if (onOff==0) {
									$("##GeogDetail").hide();
									$("##GeogDetailCtl").attr('onCLick','toggleGeogDetail(1)').html('More Fields');
								} else {
									$("##GeogDetail").show();
									$("##GeogDetailCtl").attr('onCLick','toggleGeogDetail(0)').html('Fewer Fields');
								}
								<cfif isdefined("session.username") and len(#session.username#) gt 0>
									jQuery.getJSON("/specimens/component/search.cfc",
										{
											method : "saveBasicSrchPref",
											id : 'GeogDetail',
											onOff : onOff,
											returnformat : "json",
											queryformat : 'column'
										},
										function (data) { 
											console.log(data);
										}
									).fail(function(jqXHR,textStatus,error){
										handleFail(jqXHR,textStatus,error,"persisting GeogDetail state");
									});
								</cfif>
							}
							function toggleCollDetail(onOff) {
								if (onOff==0) {
									$("##CollDetail").hide();
									$("##CollDetailCtl").attr('onCLick','toggleCollDetail(1)').html('More Fields');
								} else {
									$("##CollDetail").show();
									$("##CollDetailCtl").attr('onCLick','toggleCollDetail(0)').html('Fewer Fields');
								}
								<cfif isdefined("session.username") and len(#session.username#) gt 0>
									jQuery.getJSON("/specimens/component/search.cfc",
										{
											method : "saveBasicSrchPref",
											id : 'CollDetail',
											onOff : onOff,
											returnformat : "json",
											queryformat : 'column'
										},
										function (data) { 
											console.log(data);
										}
									).fail(function(jqXHR,textStatus,error){
										handleFail(jqXHR,textStatus,error,"persisting CollDetail state");
									});
								</cfif>
							}
							function toggleSpecDetail(onOff) {
								if (onOff==0) {
									$("##SpecDetail").hide();
									$("##SpecDetailCtl").attr('onCLick','toggleSpecDetail(1)').html('More Fields');
								} else {
									$("##SpecDetail").show();
									$("##SpecDetailCtl").attr('onCLick','toggleSpecDetail(0)').html('Fewer Fields');
								}
								<cfif isdefined("session.username") and len(#session.username#) gt 0>
									jQuery.getJSON("/specimens/component/search.cfc",
										{
											method : "saveBasicSrchPref",
											id : 'SpecDetail',
											onOff : onOff,
											returnformat : "json",
											queryformat : 'column'
										},
										function (data) { 
											console.log(data);
										}
									).fail(function(jqXHR,textStatus,error){
										handleFail(jqXHR,textStatus,error,"persisting SpecDetail state");
									});
								</cfif>
							}
						</script>
							<!---Keyword Search/results tab panel--->
							<section id="keywordSearchPanel" role="tabpanel" aria-labelledby="keywordSearchTabButton" tabindex="-1" class="unfocus mx-0 #keywordTabActive# " #keywordTabShow#>
								<div class="col-9 float-right px-0"> 
									<button class="btn btn-xs btn-dark help-btn" type="button" data-toggle="collapse" data-target="##collapseKeyword" aria-expanded="false" aria-controls="collapseKeyword">
													Search Help
									</button>
									<aside class="collapse collapseStyle" id="collapseKeyword">
										<div class="card card-body pl-4 py-3 pr-3">
											<h2 class="headerSm">Keyword Search Help</h2>
											<p>
												This help applies only the keyword search, behavior and operators for other searches are different.
												<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")> 
													(See: <a href="https://code.mcz.harvard.edu/wiki/index.php/Search_Operators" target="_blank">Search Operators</a>). For more examples, see: <a href="https://code.mcz.harvard.edu/wiki/index.php/Keyword_Search" target="_blank">Keyword Search</a>.
												</cfif>
											</p>
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
									</aside>
								</div>
								<div role="search">
									<form name= "keywordSearchForm" id="keywordSearchForm" class="container-fluid togglesearchform">
										<input id="result_id_keywordSearch" type="hidden" name="result_id" value="" class="excludeFromLink">
										<input type="hidden" name="method" value="executeKeywordSearch" class="keeponclear excludeFromLink">
										<input type="hidden" name="action" value="keywordSearch" class="keeponclear">
										<div class="row mx-0">
											<div class="input-group mt-1">
												<div class="input-group-btn col-12 col-sm-5 col-md-5 col-xl-3 mb-1 mb-sm-0 pr-sm-0 pr-md-3">
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
															$("##keywordCollection").jqxComboBox({ source: collectionsource, displayMember:"name", valueMember:"cde", multiSelect: true, height: '24px', width: '100%' });
															setKeywordCollectionValues();
														});
													</script> 
												</div>
												<cfif findNoCase('redesign',gitBranch) GT 0 OR (isdefined("session.roles") and listfindnocase(session.roles,"global_admin") ) >
													<cfset searchCollClasses = "col-sm-5 col-md-5 col-xl-7">
												<cfelse>
													<cfset searchCollClasses = "col-sm-7 col-md-7 col-xl-9">
												</cfif>
												<div class="col-12 #searchCollClasses# pl-md-0 mt-1 mt-sm-0">
													<label for="searchText" class="data-entry-label">Keyword(s)</label>
													<input id="searchText" type="text" class="data-entry-input" name="searchText" placeholder="Search term" aria-label="search text" value="#encodeForHtml(searchText)#">
												</div>
												<cfif findNoCase('redesign',gitBranch) GT 0 OR (isdefined("session.roles") and listfindnocase(session.roles,"global_admin") ) >
													<div class="col-12 col-sm-2 col-md-2 col-xl-2  mt-1 mt-sm-0 pr-2">
														<label class="data-entry-label" for="debug2">Debug</label>
														<select title="debug" name="debug" id="debug2" class="data-entry-select inputHeight">
															<option value=""></option>
															<cfif isdefined("debug") AND len(debug) GT 0><cfset selected=" selected "><cfelse><cfset selected=""></cfif>
															<option value="true" #selected#>Debug JSON</option>
														</select>
													</div>
												</cfif>
											</div>
										</div>
										<div class="row mx-0 my-3">
											<div class="col-12">
												<label for="keySearch" class="sr-only">Keyword search button - click to search MCZbase</label>
												<button type="submit" class="btn btn-xs btn-primary col-12 col-md-auto px-md-5 mx-0 mr-md-5 my-1" id="keySearch" aria-label="Keyword Search of MCZbase"> Search <i class="fa fa-search"></i> </button>
												<button type="reset" class="btn btn-xs btn-warning col-12 col-md-auto px-md-3 mr-md-2 mx-0 my-2 my-sm-1" aria-label="Reset this search form to inital values">Reset</button>
												<button type="button" class="btn btn-xs btn-warning col-12 col-md-auto px-md-3 mr-md-2 mx-0 my-1" aria-label="Start a new specimen search with a clear page" onclick="window.location.href='#Application.serverRootUrl#/Specimens.cfm?action=keywordSearch';">New Search</button>
											</div>
										</div>
									</form>
								</div>
								<!--- results for keyword search --->
								<div class="container-fluid" id="keywordSearchResultsSection">
									<div class="row">
										<div class="col-12">
											<div class="mb-3">
												<div class="row mx-0 mt-0 mt-sm-1 mb-0 pb-2 pb-md-0 jqx-widget-header border px-2">
													<h1 class="h4 pt3px ml-2 ml-md-1">
														<span tabindex="0">Results:</span> 
														<span class="pr-2 font-weight-normal" id="keywordresultCount" tabindex="0"></span> 
														<span id="keywordresultLink" class="font-weight-normal pr-2"></span>
													</h1>
													<div id="keywordsaveDialogButton"></div>
													<div id="keywordsaveDialog"></div>
													<div id="keywordcolumnPickDialog">
														<div class="container-fluid">
															<div class="row pick-column-width" id="keywordcolumnPick_row">
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
													<span id="keywordmanageButton" class=""></span>
													<div id="keywordresultBMMapLinkContainer"></div>
													<div id="keywordselectModeContainer" class="ml-3" style="display: none;" >
														<script>
															function keywordchangeSelectMode(){
																var selmode = $("##keywordselectMode").val();
																$("##keywordsearchResultsGrid").jqxGrid({selectionmode: selmode});
																if (selmode=="none") { 
																	$("##keywordsearchResultsGrid").jqxGrid({enableBrowserSelection: true});
																} else {
																	$("##keywordsearchResultsGrid").jqxGrid({enableBrowserSelection: false});
																}
															};
														</script>
														<label class="data-entry-label d-inline w-auto mt-1" for="keywordselectMode">Grid Select:</label>
														<select class="data-entry-select d-inline w-auto mt-1" id="keywordselectMode" onChange="keywordchangeSelectMode();">
															<cfif defaultSelectionMode EQ 'none'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
															<option #selected# value="none">Text</option>
															<cfif defaultSelectionMode EQ 'singlecell'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
															<option #selected# value="singlecell">Single Cell</option>
															<cfif defaultSelectionMode EQ 'singlerow'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
															<option #selected# value="singlerow">Single Row</option>
															<cfif defaultSelectionMode EQ 'multiplerowsextended'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
															<option #selected# value="multiplerowsextended">Multiple Rows (click, drag, release)</option>
															<cfif defaultSelectionMode EQ 'multiplecellsadvanced'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
															<option #selected# value="multiplecellsadvanced">Multiple Cells (click, drag, release)</option>
														</select>
													</div>
													<output id="keywordactionFeedback" class="btn btn-xs btn-transparent px-2 my-2 mx-1 border-0"></output>
												</div>
												<div class="row mx-0 mt-0"> 
													<!--- Grid Related code is below along with search handlers --->
													<div id="keywordsearchResultsGrid" class="jqxGrid" role="table" aria-label="Search Results Table"></div>
													<div id="keywordenableselection"></div>
												</div>
											</div>
										</div>
									</div>
								</div>
							</section> <!--- end keyword search/results panel --->
								<!---Query Builder tab panel--->
<!--- 
Query:
country = France
and (family = 'Mustelidae' or family = 'Lophiidae')
and collector = 'Brendan Haley'

Target JSON:
 [{"nest":"1","field": "COUNTRY","comparator": "=","value": "FRANCE"},{"nest":"2.1","join":"and","field": "FAMILY","comparator": "=","value": "MUSTELIDAE"},{"nest":"2.2","join":"or","field": "FAMILY","comparator": "=","value": "LOPHIIDAE"},{"nest":"3","join":"and","field": "COLLECTORS_AGENT_ID","comparator": "=","value": "15172"}]
--->
							<section id="builderSearchPanel" role="tabpanel" aria-labelledby="builderSearchTabButton" tabindex="-1" class="mx-0 #builderTabActive# unfocus" #builderTabShow#>
								<div role="search">
									<div class="col-3 float-right px-3"> 
									<button class="btn btn-xs btn-dark help-btn border-0" type="button" data-toggle="collapse" data-target="##collapseBuilder" aria-expanded="false" aria-controls="collapseBuilder">
										Search Help
									</button>
									<aside class="collapse collapseStyle" id="collapseBuilder">
										<div class="card card-body pl-4 py-3 pr-3">
											<h2 class="headerSm">Search Builder Search Help</h2>
											<p>Construct searches on arbitrary sets of fields.  Click the <i>Add</i> button to add a clause to the search, select a field to search, and specify a value to search for.  Search terms can be connected with either <i>and</i> or <i>or</i>. but not (yet) both in the same search.
											<p>There is a page to explain the database fields available to build a search.
											Access it here: <a href="/specimens/viewSpecimenSearchMetadata.cfm?action=search&execute=true&method=getcf_spec_search_cols&access_role=!HIDE">Search Builder Help Page</a>
											</p>
										</div>
									</aside>
								</div>
									<form id="builderSearchForm" class="container-fluid togglesearchform">
										<script>
											var treeMap = new Map();
											treeMap.set("1",["1"]);
											// functions to support nesting
											// push value onto a stack stored as a period separated string.
											function nestDepthStackPush(stack,value) {
												var result = "";
												if (stack=="") { 
													result = value;
												} else {
													result = stack + "." + value;
												}
												return result;
											}

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
														var functionToBind = columnMetadata[i].ui_function;
														if (functionToBind.search(/^[A-Za-z]+$/)>-1) {
															//  makeAutocomplete ->  makeAutocomplete(searchText{n},searchId{n})
															var invokeBinding = Function(functionToBind+"('searchText"+ rowNumber+"','searchId"+ rowNumber+"')");
															invokeBinding(); 
														} else if (functionToBind.search(/^[A-Za-z]+\(\)$/)>-1) {
															// makeAutocomplete(text) -> makeAutocomplete(searchText{n})
															var functionName = functionToBind.substring(0,functionToBind.length-2); // remove trailing ()
															var invokeBinding = Function(functionName+"('searchText"+ rowNumber+"')");
															invokeBinding(); 
														} else if (functionToBind.search(/^[A-Za-z]+\(.*:.*\)$/)>-1) {
															// makeAutocomplete(searchId:,searchText:,param) -> makeAutocomplete(searchId{n},searchText{n}:,param)
															var paramsBit = functionToBind.match(/\(.*\)/);
															var functionBit = functionToBind.substring(0,functionToBind.indexOf("("));
															var params = paramsBit[0].substring(1,paramsBit[0].length-1);
															var paramsArray = params.split(',');
															var paramsReady = "";
															var comma = "";
															for (var par in paramsArray) { 
																paramsReady = paramsReady + comma + "'"+paramsArray[par].replace(":",rowNumber)+"'";
																var comma = ",";
															}
															functionToBind = functionBit + "(" + paramsReady + ")";
															console.log(functionToBind);
															var invokeBinding = Function(functionToBind);
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
															var functionToBind = columnMetadata[i].ui_function;
															if (functionToBind.search(/^[A-Za-z]+$/)>-1) {
																//  makeAutocomplete(text,id)
																var invokeBinding = Function(functionToBind+"('searchText"+ rowNumber+"','searchId"+ rowNumber+"')");
																invokeBinding(); 
															} else if (functionToBind.search(/^[A-Za-z]+\(\)$/)>-1) {
																// makeAutocomplete(text)
																var functionName = functionToBind.substring(0,functionToBind.length-2); // remove trailing ()
																var invokeBinding = Function(functionName+"('searchText"+ rowNumber+"')");
																invokeBinding(); 
															} else if (functionToBind.search(/^[A-Za-z]+\(.*:.*\)$/)>-1) {
																// makeAutocomplete(searchId:,searchText:,param) -> makeAutocomplete(searchId{n},searchText{n}:,param)
																var paramsBit = functionToBind.match(/\(.*\)/);
																var functionBit = functionToBind.substring(0,functionToBind.indexOf("("));
																var params = paramsBit[0].substring(1,paramsBit[0].length-1);
																var paramsArray = params.split(',');
																var paramsReady = "";
																var comma = "";
																for (var par in paramsArray) { 
																	paramsReady = paramsReady + comma + "'"+paramsArray[par].replace(":",rowNumber)+"'";
																	var comma = ",";
																}
																functionToBind = functionBit + "(" + paramsReady + ")";
																console.log(functionToBind);
																var invokeBinding = Function(functionToBind);
																invokeBinding(); 
															}
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
														<a aria-label="Add more search criteria" id="addRowButton" class="btn btn-xs btn-primary rounded px-2 mr-md-auto" target="_self" href="javascript:void(0);">Add</a>
													</div>
													<div class="col-12 col-md-1">
														<label for="nestButton" class="data-entry-label">Nest</label>
														<button id="nestButton1" type="button" class="btn btn-xs btn-secondary disabled" onclick="indent(1);" disabled>&gt;</button>
														<cfif not isDefined("nestdepth1") OR len(trim(nestdepth1)) EQ 0><cfset nestdepth1="1"></cfif>
														<input type="hidden" name="nestdepth1" id="nestdepth1" value="#nestdepth1#">
													</div>
													<script>
														function indent(row) {
															<cfif findNoCase('master',gitBranch) GT 0 >
																messageDialog("Not implemented yet");
															<cfelse>
																console.log(row);
																console.log($('##builderMaxRows').val());
																var currentnestdepth = $('##nestdepth'+row).val();
																console.log(currentnestdepth);
																$('##nestdepth'+row).val(currentnestdepth+"."+1);
																var nextRow = row + 1;
																$('##nestMarkerStart'+row).html("(");
																if (row==$('##builderMaxRows').val() || (row==1 && $('##builderMaxRows').val()==2)) { 
																	// add a row, close ) on that row
																	addBuilderRow();
																	$('##nestdepth'+nextRow).val(currentnestdepth+"."+ 2);
																}
																$('##nestMarkerEnd'+nextRow).html(")");
																$('##nestButton'+row).prop("disabled",true);
																$('##nestButton'+row).addClass("disabled");
															</cfif>
														}
														function promote(row) {
															<cfif findNoCase('master',gitBranch) GT 0 >
																//messageDialog("Not implemented yet");
															<cfelse>
																console.log(row);
																console.log($('##builderMaxRows').val());
																var currentnestdepth = $('##nestdepth'+row).val();
																var nestDepthStack = currentnestdepth.split(".");
																if (nestDepthStack.length > 1) { 
																	nestDepthStack.pop();
																	var nestDepthValue = nestDepthStack.pop();
																	if (nestDepthValue=="") {  nestDepthValue="1"; }
																	var nextNestDepthValue = parseInt(nestDepthValue) + 1;
																	var newnestdepth  = "" + nestDepthStackPush(nestDepthStack.join("."), nextNestDepthValue);  
																	if (newnestdepth.substr(0,1)==".") { 
																		newnestdepth = newnestdepth.substr(1);
																	}
																	console.log(newnestdepth);
																	$('##nestdepth'+row).val(newnestdepth);
																}
																if ($('##nestMarkerEnd'+row).html()==")") { ;
																	$('##nestMarkerEnd'+row).html("");
																}
															</cfif>
														}
													</script>
													<div class="col-12 col-md-1">
														<span id="nestMarkerStart1"></span>
													</div>
													<div class="col-12 col-md-4">
														<cfquery name="fields" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="fields_result">
															SELECT search_category, cf_spec_search_cols.table_name, cf_spec_search_cols.column_name, column_alias, data_type, 
																label, access_role, ui_function, all_col_comments.comments
															FROM cf_spec_search_cols
																left join all_col_comments 
																	on cf_spec_search_cols.table_name = all_col_comments.table_name 
																		and cf_spec_search_cols.column_name = all_col_comments.column_name
																		and all_col_comments.owner = 'MCZBASE'
															WHERE	
																<cfif oneOfUs EQ 0>
																	access_role = 'PUBLIC'
																<cfelse>
																	access_role IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="PUBLIC,#session.roles#" list="yes">)
																</cfif>
																AND access_role <> 'HIDE'
															ORDER BY
																search_category, label, cf_spec_search_cols.table_name
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
																<option value="#fields.table_name#:#fields.column_alias#" #selected#>#fields.label# (#fields.search_category#:#fields.table_name#) #fields.comments#</option>
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
																	dropDownHeight: 400
																});
																// bind an autocomplete, if one applies
																handleFieldSetup('field1',1);
																console.log("field1 setup");
																$('##field1').on("select", function(event) { 
																	handleFieldSelection('field1',1);
																});
																var selectedIndex = $('##field1').jqxComboBox('getSelectedIndex');
																if (selectedIndex<1) {
																	// hack, if intial field1 selection is 0 (-1 is no selection), first on select event doesn't fire.  
																	// forcing clearSelection so that first action on field1 will triggers select event.
																	$('##field1').jqxComboBox('clearSelection');
																}
															});
														</script>
													</div>
													<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
														<cfset searchcol="col-md-4">
													<cfelse>
														<cfset searchcol="col-md-5">
													</cfif>
													<div class="col-12 #searchcol#">
														<cfif not isDefined("searchText1")><cfset searchText1=""></cfif>
														<cfif not isDefined("searchId1")><cfset searchId1=""></cfif>
														<!--- TODO: Add javascript to modify inputs depending on selected field. --->
														<label for="searchText1" class="data-entry-label">Search For</label>
														<input type="text" class="form-control-sm d-flex data-entry-input mx-0" name="searchText1" id="searchText1" value="#encodeForHtml(searchText1)#" required>
														<input type="hidden" name="searchId1" id="searchId1" value="#encodeForHtml(searchId1)#">
														<input type="hidden" name="joinOperator1" id="joinOperator1" value="">
													</div>
													<cfif isdefined("session.roles") and listfindnocase(session.roles,"global_admin")>
														<div class="col-12 col-md-1">
															<label class="data-entry-label" for="debug3">Debug</label>
															<select title="debug" name="debug" id="debug3" class="data-entry-select">
																<option value=""></option>
																<cfif isdefined("debug") AND len(debug) GT 0><cfset selected=" selected "><cfelse><cfset selected=""></cfif>
																<option value="true" #selected#>Debug JSON</option>
															</select>
														</div>
													</cfif>
												</div>
												<cfif builderMaxRows GT 1>
													<cfset parenOpen = 0>
													<cfloop index="row" from="2" to="#builderMaxRows#">
														<cfif isDefined("field#row#")>
															<div class="form-row mb-2" id="builderRow#row#">
																<div class="col-12 col-md-1">
																	&nbsp;
																	<cfif isDefined("nestdepth"&row)>
																		<cfset nestdepthval = Evaluate("nestdepth" & row)>
																	<cfelse>
																		<cfset nestdepthval = "1">
																	</cfif> 
																	<cfset nextRow = row + 1>
																	<cfset closeParen = "">
																	<cfif isDefined("nestdepth"&nextRow)>
																		<cfset nextRownestdepthval = Evaluate("nestdepth" & nextRow)>
																		<!--- check if next row is not incremented by one at current depth --->
																		<cfset na = ListToArray(nestdepthval,".")>
																		<cfset nrna = ListToArray(nextRownestdepthval,".")>
																		<cfif ArrayLen(na) EQ ArrayLen(nrna)>
																			<cfif val(na[ArrayLen(na)]) + 1 EQ val(nrna[ArrayLen(nrna)])>
																				<cfset closeParen = ""> 
																			<cfelse>
																				<cfset closeParen = ")"> 
																				<cfset parenOpen = parenOpen-1>
																			</cfif>
																		<cfelse>
																			<cfif ArrayLen(na) GT ArrayLen(nrna)>
																				<cfif parenOpen GT 0>
																					<cfset closeParen = ")"> 
																					<cfset parenOpen = parenOpen-1>
																				</cfif>
																			</cfif>
																		</cfif>
																	<cfelse>
																		<cfif parenOpen GT 0>
																			<cfset closeParen = ")"> 
																		</cfif>
																	</cfif> 
																	<input type="hidden" name="nestdepth#row#" id="nestdepth#row#" value="#nestdepthval#">
																	<cfif findNoCase('redesign',gitBranch) GT 0 OR (isdefined("session.roles") and listfindnocase(session.roles,"global_admin") ) >
																		[#nestdepthval#]
																	</cfif>
																</div>
																<div class="col-12 col-md-1">
																	<cfif row LT builderMaxRows>
																		<cfset disabled = "disabled">
																	<cfelse>
																		<cfset disabled = "">
																	</cfif>
																	<button id="nestButton#row#" type="button" class="btn btn-xs btn-secondary #disabled#" onclick="indent("+row+");" #disabled#>&gt;</button>
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
																<div class="col-12 col-md-1">
																	<span id="nestMarkerStart#row#">
																		<cfif right(nestdepthval,2) IS ".1">
																			(
																			<cfset parenOpen = parenOpen + 1>
																		</cfif>
																	</span>
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
																			console.log("Setup #row#");
																			$('##field#row#').on("select", function(event) { 
																				console.log("Select on #row#");
																				handleFieldSelection('field#row#',#row#);
																			});
																		});
																	</script>
																</div>
																<div class="col-12 col-md-3">
																	<cfif isDefined("searchText#row#")><cfset sval = Evaluate("searchText#row#")><cfelse><cfset sval=""></cfif>
																	<cfif isDefined("searchId#row#")><cfset sival = Evaluate("searchId#row#")><cfelse><cfset sival=""></cfif>
																	<input type="text" class="data-entry-input" name="searchText#row#" id="searchText#row#" placeholder="Enter Value" value="#encodeForHtml(sval)#">
																	<input type="hidden" name="searchId#row#" id="searchId#row#" value="#encodeForHtml(sival)#" >
																</div>
																<div class="col-12 col-md-1">
																	<span id="nestMarkerEnd#row#">#closeParen#</span>
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
												function addBuilderRow() { 
													var row = $("##builderMaxRows").val();
													var currentnestdepth = $('##nestdepth'+row).val();
													$('##nestButton'+row).prop("disabled",true);
													$('##nestButton'+row).addClass("disabled");
													console.log(currentnestdepth);
													row = parseInt(row) + 1;
													var newControls = '<div class="form-row mb-2" id="builderRow'+row+'">';
													newControls = newControls + '<div class="col-12 col-md-1">&nbsp;';
													newControls = newControls + '<input type="hidden" name="nestdepth'+row+'" id="nestdepth'+row+'">';
													newControls = newControls + '</div>';
													newControls = newControls + '<div class="col-12 col-md-1">';
													newControls = newControls + '<button id="nestButton'+row+'" type="button" class="btn btn-xs btn-secondary" onclick="indent('+row+');">&gt;</button>';
													newControls = newControls + '</div>';
													newControls = newControls + '<div class="col-12 col-md-1">';
													newControls = newControls + '<select title="Join Operator" name="JoinOperator'+row+'" id="joinOperator'+row+'" class="data-entry-select bg-white mx-0 d-flex"><option value="and">and</option><option value="or">or</option></select>';
													newControls = newControls + '</div>';
													newControls = newControls + '<div class="col-12 col-md-1">';
													newControls = newControls + '<span id="nestMarkerStart'+row+'"></span>';
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
													newControls= newControls + '<div class="col-12 col-md-3">';
													newControls = newControls + '<input type="text" class="data-entry-input" name="searchText'+row+'" id="searchText'+row+'" placeholder="Enter Value"/>';
													newControls = newControls + '<input type="hidden" name="searchId'+row+'" id="searchId'+row+'" >';
													newControls = newControls + '</div>';
													newControls = newControls + '<div class="col-12 col-md-1">';
													newControls = newControls + '<span id="nestMarkerEnd'+row+'"></span>';
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
													var nestDepthStack = currentnestdepth.split(".");
													var nestDepthValue = nestDepthStack.pop();
													if (nestDepthValue=="") {  nestDepthValue="1"; }
													var nextNestDepthValue = parseInt(nestDepthValue) + 1;
													var newnestdepth = "" + nestDepthStackPush(nestDepthStack.join("."), nextNestDepthValue);  
													console.log(newnestdepth);
													if (newnestdepth!="" && newnestdepth.substr(0,1)==".") { 
														console.log(newnestdepth.substr(1));
														newnestdepth = newnestdepth.substr(1);
													}
													console.log(newnestdepth);
													$('##nestdepth'+row).val(newnestdepth);
												};
												$(document).ready(function(){
													$("##addRowButton").click(function(){
													   addBuilderRow();
														promote($('##builderMaxRows').val());
													});
												});
											</script>
										</div>
										<div class="form-row mb-3">
											<div class="col-12">
												<button type="submit" class="btn btn-xs btn-primary col-12 col-md-auto px-md-5 mx-0 mr-md-5 my-1" id="searchbuilder-search" aria-label="run the search builder search">Search <i class="fa fa-search"></i></button>
												<button type="reset" class="btn btn-xs btn-outline-warning col-12 col-md-auto px-md-3 mr-md-2 mx-0 my-1" aria-label="Reset this search form to inital values" disabled>Reset</button>
												<button type="button" class="btn btn-xs btn-warning col-12 col-md-auto px-md-3 mr-md-2 mx-0 my-1" aria-label="Start a new specimen search with a clear page" onclick="window.location.href='#Application.serverRootUrl#/Specimens.cfm?action=builderSearch';">New Search</button>
												
											</div>
										</div>
									</form>


								</div>
								<!--- results for search builder search --->
								<div class="container-fluid" id="builderSearchResultsSection" aria-live="polite">
									<div class="row mx-0">
										<div class="col-12">
											<div class="mb-3">
												<div class="row mt-1 mb-0 pb-2 pb-md-0 jqx-widget-header border px-2">
													<h1 class="h4 pt3px ml-2 ml-md-1">
														<span tabindex="0">Results: </span> 
														<span class="pr-2 font-weight-normal" id="builderresultCount" tabindex="0"></span> 
														<span id="builderresultLink" class="pr-2 font-weight-normal"></span>
													</h1>
													
													<div id="buildersaveDialogButton"></div>
													<div id="buildersaveDialog"></div>
													<div id="buildercolumnPickDialog">
														<div class="container-fluid">
															<div class="row pick-column-width" id="buildercolumnPick_row">
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
													<span id="buildermanageButton" class=""></span>
													<div id="builderresultBMMapLinkContainer"></div>
													<div id="builderselectModeContainer" class="ml-3" style="display: none;" >
														<script>
															function builderchangeSelectMode(){
																var selmode = $("##builderselectMode").val();
																$("##buildersearchResultsGrid").jqxGrid({selectionmode: selmode});
																if (selmode=="none") { 
																	$("##buildersearchResultsGrid").jqxGrid({enableBrowserSelection: true});
																} else {
																	$("##buildersearchResultsGrid").jqxGrid({enableBrowserSelection: false});
																}
															};
														</script>
														<label class="data-entry-label d-inline w-auto mt-1" for="builderselectMode">Grid Select:</label>
														<select class="data-entry-select d-inline w-auto mt-1" id="builderselectMode" onChange="builderchangeSelectMode();">
															<cfif defaultSelectionMode EQ 'none'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
															<option #selected# value="none">Text</option>
															<cfif defaultSelectionMode EQ 'singlecell'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
															<option #selected# value="singlecell">Single Cell</option>
															<cfif defaultSelectionMode EQ 'singlerow'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
															<option #selected# value="singlerow">Single Row</option>
															<cfif defaultSelectionMode EQ 'multiplerowsextended'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
															<option #selected# value="multiplerowsextended">Multiple Rows (click, drag, release)</option>
															<cfif defaultSelectionMode EQ 'multiplecellsadvanced'><cfset selected="selected"><cfelse><cfset selected=""></cfif>
															<option #selected# value="multiplecellsadvanced">Multiple Cells (click, drag, release)</option>
														</select>
													</div>
													<output id="builderactionFeedback" class="btn btn-xs btn-transparent my-2 px-2 mx-1 border-0"></output> 
												</div>
												<div class="row mt-0"> 
													<!--- Grid Related code is below along with search handlers --->
													<div id="buildersearchResultsGrid" class="jqxGrid" role="table" aria-label="Search Results Table"></div>
													<div id="builderenableselection"></div>
												</div>
											</div>
										</div>
									</div>
								</div>
							</section><!--- end search builder tab --->
						</div>
					</div>
				</div>
			</div>
		</main>
		<!--- 
		<div>
			<div class="col-12 col-md-6 mx-auto mb-3 pb-3">
				<p class="blockquote small text-center">Collection records at the Museum of Comparative Zoology may contain language that reflect historical place or taxon names in its original form that are no longer acceptable or appropriate in an inclusive environment. While the MCZ is  preserving data in their original form in order to retain authenticity and facilitate research, we do not condone this language and are committed to address the problem of racial and other derogatory language present in our database.</p>
			</div>
		</div>
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
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
				OR access_role = 'MANAGE_SPECIMENS'
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
	
		// *** Cell renderers that look up data from additional columns *********** 

		// NOTE: Since there are three grids, and the cellsrenderer api does not pass a reference to the grid, a separate
		// cell renderer must be added for each grid,  cf_spec_res_cols_r.cellsrenderer values starting with _ are interpreted
		// as fixed_, keyword_, builder_ cell renderers depending on the grid in which the cellsrenderer value is being applied. 
		
		// cell renderer to link out to specimen details page by collection_object_id, only works for role DATA_ENTRY
		// Deprecated.
		<cfif isdefined("session.roles") and listfindnocase(session.roles,"DATA_ENTRY")>
			var fixed_linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("##fixedsearchResultsGrid").jqxGrid('getrowdata',row);
				return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/specimens/Specimen.cfm/' + rowData['COLLECTION_OBJECT_ID'] + '">'+ rowData['GUID'] +'</a></span>';
			};
			var keyword_linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("##keywordsearchResultsGrid").jqxGrid('getrowdata',row);
				return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/specimens/Specimen.cfm/' + rowData['COLLECTION_OBJECT_ID'] + '">'+ rowData['GUID'] +'</a></span>';
			};
			var builder_linkIdCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
				var rowData = jQuery("##buildersearchResultsGrid").jqxGrid('getrowdata',row);
				return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/specimens/Specimen.cfm/' + rowData['COLLECTION_OBJECT_ID'] + '">'+ rowData['GUID'] +'</a></span>';
			};
		</cfif>
		// media cell renderers, use _mediaCellRenderer in cf_spec_res_cols_r.cellsrenderer 
		// note, collection_object_id is not available to users without DATA_ENTRY, but media_id, so 'undefined' will be passed
		// to findMedia.cfm, but findMedia can handle this case.
		var fixed_mediaCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("##fixedsearchResultsGrid").jqxGrid('getrowdata',row);
			if (rowData) { 
				return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/media/findMedia.cfm?execute=true&method=getMedia&media_relationship_type=ANY%20cataloged_item&media_relationship_value='+ rowData['GUID'] +'&media_relationship_id=' + rowData['COLLECTION_OBJECT_ID'] + '">'+ rowData['MEDIA'] +'</a></span>';
			}
		};
		var keyword_mediaCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("##keywordsearchResultsGrid").jqxGrid('getrowdata',row);
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/media/findMedia.cfm?execute=true&method=getMedia&media_relationship_type=ANY%20cataloged_item&media_relationship_value='+ rowData['GUID'] +'&media_relationship_id=' + rowData['COLLECTION_OBJECT_ID'] + '">'+ rowData['MEDIA'] +'</a></span>';
		};
		var builder_mediaCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("##buildersearchResultsGrid").jqxGrid('getrowdata',row);
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/media/findMedia.cfm?execute=true&method=getMedia&media_relationship_type=ANY%20cataloged_item&media_relationship_value='+ rowData['GUID'] +'&media_relationship_id=' + rowData['COLLECTION_OBJECT_ID'] + '">'+ rowData['MEDIA'] +'</a></span>';
		};
		// scientific name (with authorship, etc) cell renderers, use _sciNameCellRenderer in cf_spec_res_cols_r.cellsrenderer 
		var fixed_sciNameCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("##fixedsearchResultsGrid").jqxGrid('getrowdata',row);
			if (rowData) { 
				return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/name/'+ rowData['SCIENTIFIC_NAME'] +'">'+ value +'</a></span>';
			}
		};
		var keyword_sciNameCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("##keywordsearchResultsGrid").jqxGrid('getrowdata',row);
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/name/'+ rowData['SCIENTIFIC_NAME'] +'">'+ value +'</a></span>';
		};
		var builder_sciNameCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("##buildersearchResultsGrid").jqxGrid('getrowdata',row);
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/name/'+ rowData['SCIENTIFIC_NAME'] +'">'+ value +'</a></span>';
		};
		// guid with marker for specimen images 
		var fixed_GuidCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("##fixedsearchResultsGrid").jqxGrid('getrowdata',row);
			var mediaMarker = "";
			if (rowData) { 
				var media = rowData['MEDIA'];
				if (media.includes("shows cataloged_item")) { 
					mediaMarker = " <a href='/media/findMedia.cfm?execute=true&method=getMedia&related_cataloged_item="+ rowData['GUID'] +"' target='_blank'><img src='/shared/images/Image-x-generic.png' height='20' width='20'></a>"
				}
			}
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/guid/' + value + '">'+value+'</a>'+mediaMarker+'</span>';
		};
		var keyword_GuidCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("##keywordsearchResultsGrid").jqxGrid('getrowdata',row);
			var mediaMarker = "";
			var media = rowData['MEDIA'];
			if (media.includes("shows cataloged_item")) { 
				mediaMarker = " <a href='/media/findMedia.cfm?execute=true&method=getMedia&related_cataloged_item="+ rowData['GUID'] +"' target='_blank'><img src='/shared/images/Image-x-generic.png' height='20' width='20'></a>"
			}
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/guid/' + value + '">'+value+'</a>'+mediaMarker+'</span>';
		};
		var builder_GuidCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var rowData = jQuery("##buildersearchResultsGrid").jqxGrid('getrowdata',row);
			var mediaMarker = "";
			var media = rowData['MEDIA'];
			if (media.includes("shows cataloged_item")) { 
				mediaMarker = " <a href='/media/findMedia.cfm?execute=true&method=getMedia&related_cataloged_item="+ rowData['GUID'] +"' target='_blank'><img src='/shared/images/Image-x-generic.png' height='20' width='20'></a>"
			}
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a target="_blank" href="/guid/' + value + '">'+value+'</a>'+mediaMarker+'</span>';
		};

		// *** Cell renderers that display data from only the single rendered column *********** 
	
		// cell renderer to link out to specimen details page by guid, when value is guid.
		var linkGuidCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; "><a class="celllink" target="_blank" href="/guid/' + value + '">'+value+'</a></span>';
		};
		// cell renderer to link out to taxon page by scientific name, when value is scientific name.
		var linkTaxonCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			return '<a target="_blank" href="/name/' + value + '">'+value+'</a>';
		};
		// cell renderer to display yes or blank for a 1/0 flag field.
		var yesBlankFlagRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var displayValue = "";
			if (value==1) {
				displayValue = "Yes";
			}
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+displayValue+'</span>';
		};
		// cell renderer to display yes or no for a 1/0 flag field.
		var yesNoFlagRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			var displayValue = "No";
			if (value==1) {
				displayValue = "Yes";
			}
			return '<span style="margin-top: 8px; float: ' + columnproperties.cellsalign + '; ">'+displayValue+'</span>';
		};

		// Remove row from result set 
		var removeFixedCellRenderer = function (row, columnfield, value, defaulthtml, columnproperties) {
			// Removes a row, then jqwidgets invokes the deleterow callback defined for the dataadaptor
			return '<span style="margin-top: 4px; margin-left: 4px; float: ' + columnproperties.cellsalign + '; "><input type="button" onClick=" confirmDialog(&apos;Remove this row from these search results&apos;,&apos;Confirm Remove Row&apos;, function(){ var commit = $(&apos;##fixedsearchResultsGrid&apos;).jqxGrid(&apos;deleterow&apos;, '+ row +'); } ); " class="p-1 btn btn-xs btn-warning" value="&##8998;" aria-label="Remove"/></span>';
		};
		<!--- " --->

		// cellclass function 
		// NOTE: Since there are three grids, and the cellclass api does not pass a reference to the grid, a separate
		// function is needed for each grid.  Unlike the cell renderer, the same function is used for all columns.
		//
		// Set the row color based on type status
		var keywordcellclass = function (row, columnfield, value) {
			if (row>-1) { 
				var rowData = jQuery("##keywordsearchResultsGrid").jqxGrid('getrowdata',row);
				var toptypestatuskind = rowData['TOPTYPESTATUSKIND'];
				if (toptypestatuskind=='Primary') { 
					return "primaryTypeCell";
				} else if (toptypestatuskind=='Secondary') { 
					return "secondaryTypeCell";
				}
			}
		};
		var fixedcellclass = function (row, columnfield, value) {
			if (row>-1) { 
				var rowData = jQuery("##fixedsearchResultsGrid").jqxGrid('getrowdata',row);
				if (rowData) { 
					var toptypestatuskind = rowData['TOPTYPESTATUSKIND'];
					if (toptypestatuskind=='Primary') { 
						return "primaryTypeCell";
					} else if (toptypestatuskind=='Secondary') { 
						return "secondaryTypeCell";
					}
				}
			}
		};
		var buildercellclass = function (row, columnfield, value) {
			if (row>-1) { 
				var rowData = jQuery("##buildersearchResultsGrid").jqxGrid('getrowdata',row);
				var toptypestatuskind = rowData['TOPTYPESTATUSKIND'];
				if (toptypestatuskind=='Primary') { 
					return "primaryTypeCell";
				} else if (toptypestatuskind=='Secondary') { 
					return "secondaryTypeCell";
				}
			}
		};
	
		// bindingcomplete is fired on each page load of the grid, we need to distinguish the first page load from subsequent loads.
		var fixedSearchLoaded = 0;
		var keywordSearchLoaded = 0;
		var builderSearchLoaded = 0;
	
		function serializeFormAsJSON(formID) {
		  const array = $('##'+formID).serializeArray();
		  const json = {};
		  $.each(array, function () {
		    json[this.name] = this.value || "";
		  });
		  return json;
		}
	
		/* End Setup jqxgrids for search ****************************************************************************************/
		$(document).ready(function() {
			/* Setup jqxgrid for fixed Search */
			$('##fixedSearchForm').bind('submit', function(evt){
				evt.preventDefault();
			
				var uuid = getVersion4UUID();
				$("##result_id_fixedSearch").val(uuid);
	
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					if (Object.keys(window.columnHiddenSettings).length == 0) {
						lookupColumnVisibilities ('#cgi.script_name#','Default');
					}
				</cfif>

				fixedSearchLoaded = 0;

				$("##overlay").show();
				$("##fixedsearchResultsGrid").replaceWith('<div id="fixedsearchResultsGrid" class="fixedResults jqxGrid focus" style="z-index: 1;"></div>');
				$('##fixedresultCount').html('');
				$('##fixedresultLink').html('');
				$('##fixedmanageButton').html('');
				$('##fixedsaveDialogButton').html('');
				$('##fixedactionFeedback').html('');
				$('##fixedselectModeContainer').hide();
				/*var debug = $('##fixedSearchForm').serialize();
				console.log(debug);*/
				/*var datafieldlist = [ ];//add synchronous call to cf component*/
	
				var search = null;

				if ($('##fixedSearchForm').serialize().length > 7900) { 
					// POST to accomodate long catalog number lists
					search = 
					{
						datatype: "json",
						datafields:
						[
							<cfset separator = "">
							<cfloop query="getFieldMetadata">
								<cfif data_type EQ 'VARCHAR2' OR data_type EQ 'DATE'>
									#separator#{name: '#ucase(column_name)#', type: 'string' }
								<cfelseif data_type EQ 'NUMBER' >
									#separator#{name: '#ucase(column_name)#', type: 'number' }
								<cfelse>
									#separator#{name: '#ucase(column_name)#', type: 'string' }
								</cfif>
								<cfset separator = ",">
							</cfloop>
						],
						beforeprocessing: function (data) {
							if (data != null && data.length > 0) {
								search.totalrecords = data[0].recordcount;
							}
						},
						sort: function () {
							$("##fixedsearchResultsGrid").jqxGrid('updatebounddata','sort');
						},
						root: 'specimenRecord',
						id: 'collection_object_id',
						url: '/specimens/component/search.cfc',
						type: 'POST',
						data: serializeFormAsJSON('fixedSearchForm'),
						timeout: #Application.ajax_timeout*2#000,  // units not specified, miliseconds?  Fixed
						loadError: function(jqXHR, textStatus, error) {
							handleFail(jqXHR,textStatus,error, "Error performing specimen search: "); 
						},
						async: true,
						deleterow: function (rowid, commit) {
							console.log(rowid);
							console.log($('##fixedsearchResultsGrid').jqxGrid('getRowData',rowid));
							var collobjtoremove = $('##fixedsearchResultsGrid').jqxGrid('getRowData',rowid)['COLLECTION_OBJECT_ID'];
							console.log(collobjtoremove);
		        			$.ajax({
            				url: "/specimens/component/search.cfc",
            				data: { 
									method: 'removeItemFromResult', 
									result_id: $('##result_id_fixedSearch').val(),
									collection_object_id: collobjtoremove
								},
								dataType: 'json',
           					success : function (data) { 
									console.log(data);
									commit(true);
									$('##fixedsearchResultsGrid').jqxGrid('updatebounddata');
								},
            				error : function (jqXHR, textStatus, error) {
          				   	handleFail(jqXHR,textStatus,error,"removing row from result set");
									commit(false);
            				}
         				});
						} 
					};
				} else { 
					search = 
					{
						datatype: "json",
						datafields:
						[
							<cfset separator = "">
							<cfloop query="getFieldMetadata">
								<cfif data_type EQ 'VARCHAR2' OR data_type EQ 'DATE'>
									#separator#{name: '#ucase(column_name)#', type: 'string' }
								<cfelseif data_type EQ 'NUMBER' >
									#separator#{name: '#ucase(column_name)#', type: 'number' }
								<cfelse>
									#separator#{name: '#ucase(column_name)#', type: 'string' }
								</cfif>
								<cfset separator = ",">
							</cfloop>
						],
						beforeprocessing: function (data) {
							if (data != null && data.length > 0) {
								search.totalrecords = data[0].recordcount;
							}
						},
						sort: function () {
							$("##fixedsearchResultsGrid").jqxGrid('updatebounddata','sort');
						},
						root: 'specimenRecord',
						id: 'collection_object_id',
						url: '/specimens/component/search.cfc?' + $('##fixedSearchForm').serialize(),
						timeout: #Application.ajax_timeout*2#000,  // units not specified, miliseconds?  Fixed
						loadError: function(jqXHR, textStatus, error) {
							handleFail(jqXHR,textStatus,error, "Error performing specimen search: "); 
						},
						async: true,
						deleterow: function (rowid, commit) {
							console.log(rowid);
							console.log($('##fixedsearchResultsGrid').jqxGrid('getRowData',rowid));
							var collobjtoremove = $('##fixedsearchResultsGrid').jqxGrid('getRowData',rowid)['COLLECTION_OBJECT_ID'];
							console.log(collobjtoremove);
		        			$.ajax({
            				url: "/specimens/component/search.cfc",
            				data: { 
									method: 'removeItemFromResult', 
									result_id: $('##result_id_fixedSearch').val(),
									collection_object_id: collobjtoremove
								},
								dataType: 'json',
           					success : function (data) { 
									console.log(data);
									commit(true);
									$('##fixedsearchResultsGrid').jqxGrid('updatebounddata');
								},
            				error : function (jqXHR, textStatus, error) {
          				   	handleFail(jqXHR,textStatus,error,"removing row from result set");
									commit(false);
            				}
         				});
						} 
					};
				};
	

				var dataAdapter = new $.jqx.dataAdapter(search);
				var initRowDetails = function (index, parentElement, gridElement, datarecord) {
					// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
					var details = $($(parentElement).children()[0]);
					console.log(index);
					details.html("<div id='fixedrowDetailsTarget" + index + "'></div>");
					createSpecimenRowDetailsDialog('fixedsearchResultsGrid','fixedrowDetailsTarget',datarecord,index);
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
					virtualmode: true,
					enablemousewheel: false,
					editable: false,
					pagesize: '#session.specimens_pagesize#',
					pagesizeoptions: ['5','10','25','50','100','1000'], // fixed list regardless of actual result set size, dynamic reset goes into infinite loop.
					showaggregates: true,
					columnsresize: true,
					autoshowfiltericon: true,
					autoshowcolumnsmenubutton: false,
					autoshowloadelement: false,  // overlay acts as load element for form+results
					columnsreorder: true,
					groupable: true,
					selectionmode: '#defaultSelectionMode#',
					enablebrowserselection: #defaultenablebrowserselection#,
					altrows: true,
					showtoolbar: false,
					ready: function () {
						$("##fixedsearchResultsGrid").jqxGrid('selectrow', 0);
						$("##fixedsearchResultsGrid").jqxGrid('focus');
				//		$("##fixedsearchResultsGrid").jqxGrid({ everpresentrowposition: 'top'}); 
					},
					rendergridrows: function () {
						return dataAdapter.records;
					},
					columns: [
						<cfif findNoCase('master',Session.gitBranch) EQ 0>
							<cfset removerow = "{text: 'Remove', datafield: 'RemoveRow', cellsrenderer:removeFixedCellRenderer, width: 40, cellclassname: fixedcellclass, hidable:false, hidden: false },">
							#removerow#
						</cfif>
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
								<!--- last column, no trailing comma --->
								<cfset lastrow = "{text: '#label#', datafield: '#ucase(column_name)#',#filtertype##cellrenderer# width: #width#, cellclassname: fixedcellclass, hidable:#hideable#, hidden: getColHidProp('#ucase(column_name)#', #hidden#) }">
							<cfelse> 
								{text: '#label#', datafield: '#ucase(column_name)#',#filtertype##cellrenderer# width: #width#, cellclassname: fixedcellclass, hidable:#hideable#, hidden: getColHidProp('#ucase(column_name)#', #hidden#) },
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

				
								if (document <= 900){
									$(document).scrollTop(200);
								} else {
									$(document).scrollTop(480);
								}
			
					// add a link out to this search, serializing the form as http get parameters
					$('##fixedresultLink').html('<a href="/Specimens.cfm?execute=true&' + $('##fixedSearchForm :input').filter(function(index,element){ return $(element).val()!='';}).not(".excludeFromLink").serialize() + '">Link to this search</a>');
					if (fixedSearchLoaded==0) { 
						gridLoaded('fixedsearchResultsGrid','occurrence record','fixed');
						fixedSearchLoaded = 1;
					}
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
						$('##fixedmanageButton').html('<a href="specimens/manageSpecimens.cfm?result_id='+$('##result_id_fixedSearch').val()+'" target="_blank" class="btn btn-xs btn-secondary px-2 my-2 mx-1" >Manage</a>');
					<cfelse>
						$('##fixedmanageButton').html('');
					</cfif>
					pageLoaded('fixedsearchResultsGrid','occurrence record','fixed');
					<cfif isDefined("session.specimens_pin_guid") AND session.specimens_pin_guid EQ 1> 
						console.log(#session.specimens_pin_guid#);
						setPinColumnState('fixedsearchResultsGrid','GUID',true);
					</cfif>
				});
				$('##fixedsearchResultsGrid').on('rowexpand', function (event) {
					//  Create a content div, add it to the detail row, and make it into a dialog.
					var args = event.args;
					var rowIndex = args.rowindex;
					var datarecord = args.owner.source.records[rowIndex];
					console.log(rowIndex);
					createSpecimenRowDetailsDialog('fixedsearchResultsGrid','fixedrowDetailsTarget',datarecord,rowIndex);
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
	 
			
			/* Setup jqxgrid for keyword Search */
			$('##keywordSearchForm').bind('submit', function(evt){ 
				evt.preventDefault();
				
				var uuid = getVersion4UUID();
				$("##result_id_keywordSearch").val(uuid);
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					if (Object.keys(window.columnHiddenSettings).length == 0) {
						lookupColumnVisibilities ('#cgi.script_name#','Default');
					}
				</cfif>

				keywordSearchLoaded = 0;

				$("##overlay").show();
				$("##collapseKeyword").collapse("hide");  // hide the help text if it is visible.
				$("##keywordsearchResultsGrid").replaceWith('<div id="keywordsearchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
				$("##keywordresultCount").html("");
				$("##keywordresultLink").html("");
				$('##keywordmanageButton').html('');
				$('##keywordsaveDialogButton').html('');
				$('##keywordactionFeedback').html('');
				$('##keywordselectModeContainer').hide();
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
							<cfelseif data_type EQ 'NUMBER' >
								#separator#{name: '#ucase(column_name)#', type: 'number' }
							<cfelse>
								#separator#{name: '#ucase(column_name)#', type: 'string' }
							</cfif>
							<cfset separator = ",">
						</cfloop>
					],
					beforeprocessing: function (data) {
						if (data != null && data.length > 0) {
							search.totalrecords = data[0].recordcount;
						}
					},
					sort: function () {
						$("##keywordsearchResultsGrid").jqxGrid('updatebounddata','sort');
					},
					root: 'specimenRecord',
					id: 'collection_object_id',
					url: '/specimens/component/search.cfc?' + $("##keywordSearchForm").serialize(),
					timeout: #Application.ajax_timeout#000,  // units not specified, miliseconds?  Keyword
					loadError: function(jqXHR, textStatus, error) {
						handleFail(jqXHR,textStatus,error, "Error performing specimen search: "); 
					},
					async: true
				};	
	
				var dataAdapter = new $.jqx.dataAdapter(search);
				var initRowDetails = function (index, parentElement, gridElement, datarecord) {
					// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
					var details = $($(parentElement).children()[0]);
					console.log(index);
					details.html("<div id='keywordrowDetailsTarget" + index + "'></div>");
					createSpecimenRowDetailsDialog('keywordsearchResultsGrid','keywordrowDetailsTarget',datarecord,index);
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
					virtualmode: true,
					enablemousewheel: false,
					pagesize: '#session.specimens_pagesize#',
					pagesizeoptions: ['5','10','25','50','100','1000'], // fixed list regardless of actual result set size, dynamic reset goes into infinite loop.
					showaggregates: true,
					columnsresize: true,
					autoshowfiltericon: true,
					autoshowcolumnsmenubutton: false,
					autoshowloadelement: false,  // overlay acts as load element for form+results
					columnsreorder: true,
					groupable: true,
					selectionmode: '#defaultSelectionMode#',
					enablebrowserselection: #defaultenablebrowserselection#,
					altrows: true,
					showtoolbar: false,
					ready: function () {
						$("##keywordsearchResultsGrid").jqxGrid('selectrow', 0);
					},
					rendergridrows: function () {
						return dataAdapter.records;
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
								<!--- last column, no trailing comma --->
								<cfset lastrow = "{text: '#label#', datafield: '#ucase(column_name)#',#filtertype##cellrenderer# width:#width#, cellclassname: keywordcellclass, hidable:#hideable#, hidden: getColHidProp('#ucase(column_name)#', #hidden#) }">
							<cfelse> 
								{text: '#label#', datafield: '#ucase(column_name)#',#filtertype##cellrenderer# width: #width#, cellclassname: keywordcellclass, hidable:#hideable#, hidden: getColHidProp('#ucase(column_name)#', #hidden#) },
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
					console.log("bindingcomlete: keywordsearchResultsGrid");
					// add a link out to this search, serializing the form as http get parameters
					$('##keywordresultLink').html('<a href="/Specimens.cfm?execute=true&' + $('##keywordSearchForm :input').filter(function(index,element){ return $(element).val()!='';}).not(".excludeFromLink").serialize() + '">Link to this search</a>');
					if (keywordSearchLoaded==0) { 
						gridLoaded('keywordsearchResultsGrid','occurrence record','keyword');
						keywordSearchLoaded = 1;
					}
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
						$('##keywordmanageButton').html('<a href="specimens/manageSpecimens.cfm?result_id='+$('##result_id_keywordSearch').val()+'" target="_blank" class="btn btn-xs btn-secondary my-2 mx-1 px-2" >Manage</a>');
					<cfelse>
						$('##keywordmanageButton').html('');
					</cfif>
					pageLoaded('keywordsearchResultsGrid','occurrence record','keyword');
					<cfif isDefined("session.specimens_pin_guid") AND session.specimens_pin_guid EQ 1> 
						console.log(#session.specimens_pin_guid#);
						setPinColumnState('keywordsearchResultsGrid','GUID',true);
					</cfif>
				});
	
				$('##keywordsearchResultsGrid').on('rowexpand', function (event) {
					//  Create a content div, add it to the detail row, and make it into a dialog.
					var args = event.args;
					var rowIndex = args.rowindex;
					var datarecord = args.owner.source.records[rowIndex];
					console.log(rowIndex);
					createSpecimenRowDetailsDialog('keywordsearchResultsGrid','keywordrowDetailsTarget',datarecord,rowIndex);
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
				
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					if (Object.keys(window.columnHiddenSettings).length == 0) {
						lookupColumnVisibilities ('#cgi.script_name#','Default');
					}
				</cfif>
	
				builderSearchLoaded = 0;

				$("##overlay").show();
		
				$("##buildersearchResultsGrid").replaceWith('<div id="buildersearchResultsGrid" class="jqxGrid" style="z-index: 1;"></div>');
				$("##builderresultCount").html("");
				$("##builderresultLink").html("");
				$('##buildermanageButton').html('');
				$('##buildersaveDialogButton').html('');
				$('##builderactionFeedback').html('');
				$('##builderselectModeContainer').hide();
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
							<cfelseif data_type EQ 'NUMBER' >
								#separator#{name: '#ucase(column_name)#', type: 'number' }
							<cfelse>
								#separator#{name: '#ucase(column_name)#', type: 'string' }
							</cfif>
							<cfset separator = ",">
						</cfloop>
					],
					beforeprocessing: function (data) {
						if (data != null && data.length > 0) {
							search.totalrecords = data[0].recordcount;
						}
					},
					sort: function () {
						$("##buildersearchResultsGrid").jqxGrid('updatebounddata','sort');
					},
					root: 'specimenRecord',
					id: 'collection_object_id',
					url: '/specimens/component/search.cfc?' + $("##builderSearchForm").serialize(),
					timeout: #Application.ajax_timeout#000,  // units not specified, miliseconds?  Builder
					loadError: function(jqXHR, textStatus, error) {
						handleFail(jqXHR,textStatus,error, "Error performing specimen search: "); 
					},
					async: true
				};	
	
				var dataAdapter = new $.jqx.dataAdapter(search);
				var initRowDetails = function (index, parentElement, gridElement, datarecord) {
					// could create a dialog here, but need to locate it later to hide/show it on row details opening/closing and not destroy it.
					var details = $($(parentElement).children()[0]);
					console.log(index);
					details.html("<div id='builderrowDetailsTarget" + index + "'></div>");
					createSpecimenRowDetailsDialog('buildersearchResultsGrid','builderrowDetailsTarget',datarecord,index);
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
					virtualmode: true,
					editable: false,
					enablemousewheel: false,
					pagesize: '#session.specimens_pagesize#',
					pagesizeoptions: ['5','10','25','50','100','1000'], // fixed list regardless of actual result set size, dynamic reset goes into infinite loop.
					showaggregates: true,
					columnsresize: true,
					autoshowfiltericon: true,
					autoshowcolumnsmenubutton: false,
					autoshowloadelement: false,  // overlay acts as load element for form+results
					columnsreorder: true,
					groupable: true,
					selectionmode: '#defaultSelectionMode#',
					enablebrowserselection: #defaultenablebrowserselection#,
					altrows: true,
					showtoolbar: false,
					ready: function () {
						$("##buildersearchResultsGrid").jqxGrid('selectrow', 0);
					},
					rendergridrows: function () {
						return dataAdapter.records;
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
								<!--- last column, no trailing comma --->
								<cfset lastrow = "{text: '#label#', datafield: '#ucase(column_name)#',#filtertype##cellrenderer# width:#width#, cellclassname: buildercellclass, hidable:#hideable#, hidden: getColHidProp('#ucase(column_name)#', #hidden#) }">
							<cfelse> 
								{text: '#label#', datafield: '#ucase(column_name)#',#filtertype##cellrenderer# width: #width#, cellclassname: buildercellclass, hidable:#hideable#, hidden: getColHidProp('#ucase(column_name)#', #hidden#) },
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
					if (builderSearchLoaded==0) { 
						gridLoaded('buildersearchResultsGrid','occurrence record','builder');
						builderSearchLoaded = 1;
					}
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_specimens")>
						$('##buildermanageButton').html('<a href="specimens/manageSpecimens.cfm?result_id='+$('##result_id_builderSearch').val()+'" target="_blank" class="btn btn-xs btn-secondary px-2 my-2 mx-1" >Manage</a>');
					<cfelse>
						$('##buildermanageButton').html('');
					</cfif>
					pageLoaded('buildersearchResultsGrid','occurrence record','builder');
					<cfif isDefined("session.specimens_pin_guid") AND session.specimens_pin_guid EQ 1> 
						console.log(#session.specimens_pin_guid#);
						setPinColumnState('buildersearchResultsGrid','GUID',true);
					</cfif>
				});
				$('##buildersearchResultsGrid').on('rowexpand', function (event) {
					//  Create a content div, add it to the detail row, and make it into a dialog.
					var args = event.args;
					var rowIndex = args.rowindex;
					var datarecord = args.owner.source.records[rowIndex];
					console.log(rowIndex);
					createSpecimenRowDetailsDialog('buildersearchResultsGrid','builderrowDetailsTarget',datarecord,rowIndex);
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
	

			// If requested in uri, execute search immediately.
			<cfif isdefined("execute")>
				<cfswitch expression="#execute#">
					<cfcase value="fixed">
						$('##fixedSearchForm').submit();
					</cfcase>
					<cfcase value="keyword">
						$('##keywordSearchForm').submit();
					</cfcase>
						<cfcase value="builder">
						$('##builderSearchForm').submit();
					</cfcase>
				</cfswitch>
			</cfif>
		}); /* End document.ready */
	
		var columnCategoryPlacements = new Map(); // fieldname and category placement
		var columnCategories = new Map();   // category and count 
		var columnSections = new Map();   // category and array of list rows
		<cfloop query="getFieldMetadata">
			columnCategoryPlacements.set("#getFieldMetadata.column_name#","#getFieldMetadata.category#");
			if (columnCategories.has("#getFieldMetadata.category#")) { 
				columnCategories.set("#getFieldMetadata.category#", columnCategories.get("#getFieldMetadata.category#") + 1);
			} else {
				columnCategories.set("#getFieldMetadata.category#",1);
				columnSections.set("#getFieldMetadata.category#",new Array());
			}
		</cfloop>
	
		function populateSaveSearch(gridId,whichGrid) { 
			// set up a dialog for saving the current search.
			var uri = "/Specimens.cfm?execute=true&" + $('##'+whichGrid+'SearchForm :input').filter(function(index,element){ return $(element).val()!='';}).not(".excludeFromLink").serialize();
			$("##"+whichGrid+"saveDialog").html(
				"<div class='row mx-0'>"+ 
				"<form id='"+whichGrid+"saveForm'> " + 
				" <input type='hidden' value='"+uri+"' name='url'>" + 
				" <div class='col-12 p-1'>" + 
				"  <label for='search_name_input_"+whichGrid+"'>Search Name</label>" + 
				"  <input type='text' id='search_name_input_"+whichGrid+"'  name='search_name' value='' class='data-entry-input reqdClr' placeholder='Your name for this search' maxlength='60' required>" + 
				" </div>" + 
				" <div class='col-12'>" + 
				"  <label for='execute_input_"+whichGrid+"'>Execute Immediately</label>"+
				"  <input id='execute_input_"+whichGrid+"' type='checkbox' name='execute' checked>"+
				" </div>" +
				"</form>"+
				"</div>"
			);
		}
		function populateColumnPicker(gridId,whichGrid) {
			// add a control to show/hide columns organized by category
			var columns = $('##' + gridId).jqxGrid('columns').records;
			var columnCount = columns.length;
			// clear out the datafield arrays for each columnSection category
			for (let [key,value] of columnSections) { value.length = 0; };
			// repopulate the datafield arrays for each columnSection category with the current values.
			for (i = 1; i < columnCount; i++) {
				var text = columns[i].text;
				var datafield = columns[i].datafield;
				var hideable = columns[i].hideable;
				var hidden = columns[i].hidden;
				var show = ! hidden;
				if (hideable == true) {
					var listRow = { label: text, value: datafield, checked: show };
					var inCategory = columnCategoryPlacements.get(datafield);
					if (inCategory) { 
						columnSections.get(inCategory).push(listRow);
					}
				}
			}
			console.log(columnSections);
			$("##"+whichGrid+"columnPick_row").html("");
			$('<div/>',{
    			id: whichGrid +"columnPick_col",
    			class: "col-12 mb-2 accordion"
			}).appendTo("##"+whichGrid+"columnPick_row");
			var firstAccord = true;
			var bodyClass="";
			var ariaExpanded="";
			for (let [key, value] of columnCategories) { 
				// TODO: use value (number of fields in category) to subdivide long categories.
				$('<div/>',{
    				id: whichGrid + "_" + key + "_accord",
    				class: "card bg-light accordion-item",
    				title: key
				}).appendTo("##"+whichGrid+"columnPick_col");
				if (firstAccord) { 
					bodyClass = "show";
					ariaExpanded = "true";
					firstAccord = false;
				} else { 
					bodyClass = "";
					ariaExpanded = "false";
				}
				$('<div/>',{
    				id: whichGrid + "_" + key + "_accord_head",
    				class: "card-header accordion-header"
				}).appendTo("##"+whichGrid+"_"+ key +"_accord");
				$('<h2/>',{
    				id: whichGrid + "_" + key + "_accord_head_h2",
    				class: "h4 my-0"
				}).appendTo("##"+whichGrid+"_"+ key +"_accord_head");
				$("##"+whichGrid+"_"+ key +"_accord_head_h2").html('<button class="accordion-button headerLnk text-left w-100" data-toggle="collapse" data-target="##'+whichGrid+'_'+key+'_accord_body" aria-expanded="'+ariaExpanded+'" aria-controls="##'+whichGrid+'_'+key+'_accord_body">'+key+'</button>');
				$('<div/>',{
    				id: whichGrid + "_" + key + "_accord_body",
    				class: "card-body accordion-collapse collapse " + bodyClass 
				}).appendTo("##"+whichGrid+"_"+ key +"_accord");
				$('<div/>',{
    				id: whichGrid + "_" + key + "_accord_list",
    				class: ""
				}).appendTo("##"+whichGrid+"_"+ key +"_accord_body");
				$("##"+whichGrid+"_"+key+"_accord_list").jqxListBox({ source: columnSections.get(key), autoHeight: true, width: '260px', checkboxes: true });
				$("##"+whichGrid+"_"+key+"_accord_list").on('checkChange', function (event) {
					$("##" + gridId).jqxGrid('beginupdate');
					if (event.args.checked) {
						$("##" + gridId).jqxGrid('showcolumn', event.args.value);
					} else {
						$("##" + gridId).jqxGrid('hidecolumn', event.args.value);
					}
					$("##" + gridId).jqxGrid('endupdate');
				});
			}
		}

		function pageLoaded(gridId, searchType, whichGrid) {
			console.log('pageLoaded:' + gridId);
			var pagingInfo = $("##" + gridId).jqxGrid("getpaginginformation");
		}

		function togglePinColumn(gridId,column) { 
			var state = $('##'+gridId).jqxGrid('getcolumnproperty', column, 'pinned');
			$("##"+gridId).jqxGrid('beginupdate');
			if (state==true) {
				$('##'+gridId).jqxGrid('unpincolumn', column);
				$('##pinGuidToggle').html("Pin GUID Column");
			} else {
				$('##'+gridId).jqxGrid('pincolumn', column);
				$('##pinGuidToggle').html("Unpin GUID Column");
			}
			$("##"+gridId).jqxGrid('endupdate');
		}
		function setPinColumnState(gridId,column,state) { 
			if (state==true) {
				$('##'+gridId).jqxGrid('pincolumn', column);
				$('##pinGuidToggle').html("Unpin GUID Column");
			} else {
				$('##'+gridId).jqxGrid('unpincolumn', column);
				$('##pinGuidToggle').html("Pin GUID Column");
			}
		}
		function gridLoaded(gridId, searchType, whichGrid) {
			console.log('gridLoaded:' + gridId);
			var maxZIndex = getMaxZIndex();

			if (Object.keys(window.columnHiddenSettings).length == 0) {
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					lookupColumnVisibilities ('#cgi.script_name#','Default');
				<cfelse>
					window.columnHiddenSettings = getColumnVisibilities(gridId);
				</cfif>
				<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
					saveColumnVisibilities('#cgi.script_name#',window.columnHiddenSettings,'Default');
				</cfif>
			}
			$("##overlay").hide();
			$('.jqx-header-widget').css({'z-index': maxZIndex + 1 });
			var now = new Date();
			var nowstring = now.toISOString().replace(/[^0-9TZ]/g,'_');
			var filename = searchType.replace(/ /g,'_') + '_results_' + nowstring + '.csv';
			// display the number of rows found
			var datainformation = $('##' + gridId).jqxGrid('getdatainformation');
			var rowcount = datainformation.rowscount;
			if (rowcount == 1) {
				$('##'+whichGrid+'resultCount').html('Found ' + rowcount + ' ' + searchType);
			} else {
				$('##'+whichGrid+'resultCount').html('Found ' + rowcount + ' ' + searchType + 's');
			}
			populateColumnPicker(gridId,whichGrid);

			$("##"+whichGrid+"columnPickDialog").dialog({
				height: 'auto',
				width: 'auto',
				adaptivewidth: true,
				title: 'Show/Hide Columns',
				autoOpen: false,
				modal: true,
				reszable: true,
				close: function(event, ui) { 
					window.columnHiddenSettings = getColumnVisibilities(gridId);		
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
						saveColumnVisibilities('#cgi.script_name#',window.columnHiddenSettings,'Default');
					</cfif>
				},
				buttons: [
					{
						text: "Ok",
						click: function(){ 
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
				`<button id="columnPickDialogOpener" 
					onclick=" populateColumnPicker('`+gridId+`','`+whichGrid+`'); $('##`+whichGrid+`columnPickDialog').dialog('open'); " 
					class="btn btn-xs btn-secondary my-2 mx-1 px-2" >Select Columns</button>
				<button id="pinGuidToggle" onclick=" togglePinColumn('`+gridId+`','GUID'); " class="btn btn-xs btn-secondary mx-1 px-2 my-2" >Pin GUID Column</button>
				`
			);
			<cfif isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user") >
				$("##"+whichGrid+"saveDialog").dialog({
					height: 'auto',
					width: 'auto',
					adaptivewidth: true,
					title: 'Save Search',
					autoOpen: false,
					modal: true,
					reszable: true,
					buttons: [
						{
							text: "Save",
							click: function(){
								var url = $('##'+whichGrid+'saveForm :input[name=url]').val();
								var execute = $('##'+whichGrid+'saveForm :input[name=execute]').is(':checked');
								var search_name = $('##'+whichGrid+'saveForm :input[name=search_name]').val();
								saveSearch(url, execute, search_name, whichGrid+"actionFeedback");
								$(this).dialog("close"); 
							},
							tabindex: 0
						},
						{
							text: "Cancel",
							click: function(){ 
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
				$("##"+whichGrid+"saveDialogButton").html(
				`<button id="`+gridId+`saveDialogOpener"
						onclick=" populateSaveSearch('`+gridId+`','`+whichGrid+`'); $('##`+whichGrid+`saveDialog').dialog('open'); " 
						class="btn btn-xs btn-secondary px-2 my-2 mx-1" >Save Search</button>
				`);
			</cfif>
			// workaround for menu z-index being below grid cell z-index when grid is created by a loan search.
			// likewise for the popup menu for searching/filtering columns, ends up below the grid cells.
			maxZIndex = getMaxZIndex();
			$('.jqx-grid-cell').css({'z-index': maxZIndex + 1});
			$('.jqx-grid-cell').css({'border-color': '##aaa'});
			$('.jqx-grid-group-cell').css({'z-index': maxZIndex + 1});
			$('.jqx-grid-group-cell').css({'border-color': '##aaa'});
			$('.jqx-menu-wrapper').css({'z-index': maxZIndex + 2});
			var result_uuid = $('##result_id_' + whichGrid + 'Search').val(); 
			<cfif isdefined("session.username") AND len(#session.username#) GT 0>
				<cfif oneOfUs EQ 1>
					$('##'+whichGrid+'resultDownloadButtonContainer').html(`<button id="specimencsvbutton" class="btn btn-xs btn-secondary px-2 my-2 mx-1" aria-label="Export results to csv" onclick=" openDownloadDialog('downloadAgreeDialogDiv', '` + result_uuid + `', '` + filename + `'); " >Export to CSV</button>`);
				<cfelse>
					$('##'+whichGrid+'resultDownloadButtonContainer').html(`<button id="specimencsvbutton" class="btn btn-xs btn-secondary px-2 my-2 mx-1" aria-label="Export results to csv" onclick=" openDownloadAgreeDialog('downloadAgreeDialogDiv', '` + result_uuid + `', '` + filename + `'); " >Export to CSV</button>`);
				</cfif>
			<cfelse>
				$('##'+whichGrid+'resultDownloadButtonContainer').html(`<button id="specimencsvbutton" class="btn btn-xs btn-secondary px-2 my-2 mx-1 disabled" aria-label="login or register to download">Login to Download</button>`);
			</cfif>
			<cfif isDefined("session.specimens_pin_guid") AND session.specimens_pin_guid EQ 1> 
				console.log(#session.specimens_pin_guid#);
				setPinColumnState(gridId,'GUID',true);
			</cfif>
			<cfif isdefined("session.username") AND len(#session.username#) GT 0>
				$('##'+whichGrid+'resultBMMapLinkContainer').html(`<a id="`+whichGrid+`BMMapButton" class="btn btn-xs btn-secondary px-2 my-2 mx-1" target="_blank" href="/bnhmMaps/bnhmMapData.cfm?result_id=`+result_uuid+`" aria-label="Plot points in Berkeley Mapper">BerkeleyMapper</a>`);
			</cfif>
			$("html, body").scrollTop($("##"+whichGrid+"SearchResultsSection").offset().top);
			$('##'+whichGrid+'selectModeContainer').show();
		}

	</script>
	
	<!---  script>
	TODO: indentation is broken, and this references ids not present on the page, so it breaks this block.  Remove or add back in if left/right blocks for faceted search are added back in.
	TODO: Fix the indentation and nesting, this looks like one function, but isn't.
	
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
