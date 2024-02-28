<!--- 

localities/searchLocationForm.cfm

Copyright 2023 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


Expectations: 

Includes only the form fields and buttons, not a form.

Must be embedded within a form.  Form can have multiple uses, specified by form action and by hidden action/method inputs.

Expects to be within a row and a container-fluid.

Behavior is affected by the values of variables: 

	showLocality, if true, show the locality fields (default, false).
	showEvent, if true, show the collecting event fields (default, false).
	showExtraFields, if true, render form with fields not supported in custom tag findLocality (default false (work with findLocality)).
	showSpecimenCounts, if true, show the specimen counts control (default, true).
	newSearchTarget, target for onClick event for New Search button, if empty (default) no new search button is shown (as for manage).

Typical use: 

	<main id="content">
		<h1 class="h2 mt-3 mb-0 px-4">Find new collecting event for cataloged items [in #encodeForHtml(result_id)#]</h1>
		<form name="getLoc" method="post" action="/specimens/changeQueryCollEvent.cfm">
			<input type="hidden" name="Action" value="findCollectingEvent">
			<input type="hidden" name="result_id" value="#result_id#">
			<div class="row mx-0">
				<section class="container-fluid" role="search">
					<cfset showSpecimenCounts = false>
					<cfinclude template="/localities/searchLocationForm.cfm">
				</section>
			</div>
		</form>


--->

<cfif not isdefined("showLocality")>
	<!--- display the form with the locality fields included --->
	<cfset showLocality=0>
</cfif>
<cfif not isdefined("showEvent")>
	<!--- display the form with the locality and event fields included --->
	<cfset showEvent=0>
</cfif>
<cfif not isdefined("showExtraFields")>
	<!--- support rendering form with fields not supported in findLocality custom tag. --->
	<cfset showExtraFields=0>
</cfif>
<cfif not isdefined("showSpecimenCounts")>
	<!--- show or hide the specimen counts control, show by default if locality section is included --->
	<cfset showSpecimenCounts = true>
</cfif>
<cfif not isdefined("newSearchTarget")>
	<!--- if newSearchTarget has a value, the New Search button will be shown with an onclick event that reloads to the specified newSearchTarget --->
	<cfset newSearchTarget="">
</cfif>

<cfquery name="ctElevUnit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select orig_elev_units from ctorig_elev_units order by orig_elev_units
</cfquery>
<cfquery name="ctDepthUnit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
        select depth_units from ctdepth_units order by depth_units
</cfquery>
<cfquery name="ctCollectingSource" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select collecting_source from ctcollecting_source order by collecting_source
</cfquery>
<cfquery name="ctVerificationStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select VerificationStatus from ctVerificationStatus order by VerificationStatus
</cfquery>
<cfquery name="ctGeorefMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select georefMethod from ctgeorefmethod order by georefMethod
</cfquery>
<cfquery name="ctgeology_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select geology_attribute from ctgeology_attribute order by ordinal
</cfquery>
<cfquery name="ctsovereign_nation" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select ctsovereign_nation.sovereign_nation, count(locality_id) as ct from ctsovereign_nation
 		left join locality on ctsovereign_nation.sovereign_nation=locality.sovereign_nation
	group by ctsovereign_nation.sovereign_nation
	order by sovereign_nation
</cfquery>
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select collection,collection_id from collection order by collection
</cfquery>
<cfquery name="geolocate_score_range" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
	select min(geolocate_score) min_score, max(geolocate_score) max_score from lat_long where geolocate_score is not null
</cfquery>

<cfif isdefined("session.locSrchPrefs") and len(session.locSrchPrefs) gt 0>
	<cfset searchPrefList = session.locSrchPrefs>
<cfelse>
	<cfset searchPrefList = "">
</cfif>

<cfoutput>
	<div class="row mx-0 mb-2">
		<div class="search-box mt-0 pb-2"><!--- start teal search-box --->
			
			<!--------------------------------------- Higher Geography ----------------------------------------------------------->
			<div class="row mx-0 mb-0">
				<div class="col-12 px-0 mt-0">
					<div class="search-box-header">
						<h2 class="h3 mt-1 text-white" id="searchForm">Higher Geography</h2>
					</div>
					<cfif listFind(searchPrefList,"GeogDetail") EQ 0>
						<cfset geogDetailStyle="display:none;">
						<cfset toggleTo = "1">
						<cfset geogButton = "More Fields">
					<cfelse>
						<cfset geogDetailStyle="">
						<cfset toggleTo = "0">
						<cfset geogButton = "Fewer Fields">
					</cfif> 
					<div class="form-row mx-0 mb-2">
						<div class="col-12 col-md-8 col-xl-6 pr-xl-0 px-3 py-2">
							<label for="higher_geog" class="data-entry-label">
								Higher Geog
								<span class="small90">
									(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link p-0 border-0 bg-light" onclick="var e=document.getElementById('higher_geog');e.value='='+e.value;" >=<span class="sr-only">prefix with = for exact match</span></button>)
								</span>
							</label>
							<cfif not isDefined("higher_geog")><cfset higher_geog=""></cfif>
							<input type="text" name="higher_geog" id="higher_geog" class="data-entry-input" value="#encodeForHtml(higher_geog)#"> 
						</div>
						<div class="col-12 col-md-3 col-xl-2 px-3 pl-xl-2 pr-xl-2 py-2">
							<label for="geog_auth_rec_id" class="data-entry-label">Geog Auth Rec ID</label>
							<cfif not isDefined("geog_auth_rec_id")><cfset geog_auth_rec_id=""></cfif>
							<input type="text" name="geog_auth_rec_id" id="geog_auth_rec_id" class="data-entry-input" value="#encodeForHtml(geog_auth_rec_id)#">
						</div>
						<div class="col-12 col-md-2 col-xl-1 px-3 py-2 pl-xl-0 pt-md-0 pt-xl-4">
							<label for="geogDetailCtl" class="data-entry-label text-light sr-only" >Geography</label>
							<button type="button" id="geogDetailCtl" class="btn btn-xs btn-secondary" onclick="toggleGeogDetail(#toggleTo#);">#geogButton#</button>
						</div>
					</div>
					<div id="geogDetail" class="col-12 mb-3 px-3" style="#geogDetailStyle#">
						<div class="form-row">
							<div class="col-12 col-md-4 col-xl-2 my-1">
								<label for="continent_ocean" class="data-entry-label">Continent or Ocean
									<span class="small90">
										(<button type="button" tabindex="-1" aria-hidden="true" class="btn-link p-0 border-0 bg-light" onclick="var e=document.getElementById('continent_ocean');e.value='='+e.value;" >=<span class="sr-only">prefix with = for exact match</span></button>)
									</span>
								</label>
								<cfif not isDefined("continent_ocean")><cfset continent_ocean=""></cfif>
								<input type="text" name="continent_ocean" id="continent_ocean" class="data-entry-input" value="#encodeForHtml(continent_ocean)#">
								<script>
									jQuery(document).ready(function() {
										makeGeogSearchAutocomplete('continent_ocean','continent_ocean');
									});
								</script>
							</div>
							<div class="col-12 col-md-4 col-xl-2 my-1">
								<cfif not isDefined("ocean_region")><cfset ocean_region=""></cfif>
								<label for="ocean_region" class="data-entry-label" >Ocean Region</label>
								<input type="text" name="ocean_region" id="ocean_region" class="data-entry-input" value="#encodeForHtml(ocean_region)#">
								<script>
									jQuery(document).ready(function() {
										makeGeogSearchAutocomplete('ocean_region','ocean_region');
									});
								</script>
							</div>
							<div class="col-12 col-md-4 col-xl-2 my-1">
								<cfif not isDefined("ocean_subregion")><cfset ocean_subregion=""></cfif>
								<label for="ocean_subregion" class="data-entry-label">Ocean SubRegion</label>
								<input type="text" name="ocean_subregion" id="ocean_subregion" class="data-entry-input" value="#encodeForHtml(ocean_subregion)#">
								<script>
									jQuery(document).ready(function() {
										makeGeogSearchAutocomplete('ocean_subregion','ocean_subregion');
									});
								</script>
							</div>
							<div class="col-12 col-md-4 col-xl-2 my-1">
								<cfif not isDefined("sea")><cfset sea=""></cfif>
								<label for="sea" class="data-entry-label">Sea</label>
								<input type="text" name="sea" id="sea" class="data-entry-input" value="#encodeForHtml(sea)#">
								<script>
									jQuery(document).ready(function() {
										makeGeogSearchAutocomplete('sea','sea');
									});
								</script>
							</div>
							<div class="col-12 col-md-4 col-xl-2 my-1">
								<cfif not isDefined("water_feature")><cfset water_feature=""></cfif>
								<label for="water_feature" class="data-entry-label">Water Feature</label>
								<input type="text" name="water_feature" id="water_feature" class="data-entry-input" value="#encodeForHtml(water_feature)#">
								<script>
									jQuery(document).ready(function() {
										makeGeogSearchAutocomplete('water_feature','water_feature');
									});
								</script>
							</div>
							<div class="col-12 col-md-4 col-xl-2 my-1">
								<cfif not isDefined("country")><cfset country=""></cfif>
								<label for="country" class="data-entry-label">Country</label>
								<input type="text" name="country" id="country" class="data-entry-input" value="#encodeForHtml(country)#">
								<script>
									jQuery(document).ready(function() {
										makeGeogSearchAutocomplete('country','country');
									});
								</script>
							</div>
							<div class="col-12 col-md-4 col-xl-2 my-1">
								<cfif not isDefined("state_prov")><cfset state_prov=""></cfif>
								<label for="state_prov" class="data-entry-label">State or Province</label>
								<input type="text" name="state_prov" id="state_prov" class="data-entry-input" value="#encodeForHtml(state_prov)#">
								<script>
									jQuery(document).ready(function() {
										makeGeogSearchAutocomplete('state_prov','state_prov');
									});
								</script>
							</div>
							<div class="col-12 col-md-4 col-xl-2 my-1">
								<cfif not isDefined("county")><cfset county=""></cfif>
								<label for="county" class="data-entry-label">County</label>
								<input type="text" name="county" id="county" class="data-entry-input" value="#encodeForHtml(county)#">
								<script>
									jQuery(document).ready(function() {
										makeGeogSearchAutocomplete('county','county');
									});
								</script>
							</div>
							<div class="col-12 col-md-4 col-xl-2 my-1">
								<cfif not isDefined("feature")><cfset feature=""></cfif>
								<label for="feature" class="data-entry-label">Land Feature</label>
								<input type="text" name="feature" id="feature" class="data-entry-input" value="#encodeForHtml(feature)#">
								<script>
									jQuery(document).ready(function() {
										makeGeogSearchAutocomplete('feature','feature');
									});
								</script>
							</div>
							<div class="col-12 col-md-4 col-xl-2 my-1">
								<cfif not isDefined("island")><cfset island=""></cfif>
								<label for="island" class="data-entry-label">Island</label>
								<input type="text" name="island" id="island" class="data-entry-input" value="#encodeForHtml(island)#">
								<script>
									jQuery(document).ready(function() {
										makeGeogSearchAutocomplete('island','island');
									});
								</script>
							</div>
							<div class="col-12 col-md-4 col-xl-2 my-1">
								<cfif not isDefined("island_group")><cfset island_group=""></cfif>
								<label for="island_group" class="data-entry-label">Island Group</label>
								<input type="text" name="island_group" id="island_group" class="data-entry-input" value="#encodeForHtml(island_group)#">
								<script>
									jQuery(document).ready(function() {
										makeGeogSearchAutocomplete('island_group','island_group');
									});
								</script>
							</div>
							<div class="col-12 col-md-4 col-xl-2 my-1">
								<cfif not isDefined("quad")><cfset quad=""></cfif>
								<label for="quad" class="data-entry-label">Quad</label>
								<input type="text" name="quad" id="quad" class="data-entry-input" value="#encodeForHtml(quad)#">
								<script>
									jQuery(document).ready(function() {
										makeGeogSearchAutocomplete('quad','quad');
									});
								</script>
							</div>
							<cfif #showExtraFields# IS 1>
								<div class="col-12 col-md-4 col-xl-2 my-1">
									<cfif not isDefined("wkt_polygon")><cfset wkt_polygon=""></cfif>
									<label for="wkt_polygon" class="data-entry-label">Polygon (WKT)</label>
									<select name="wkt_polygon" id="wkt_polygon" size="1" class="data-entry-select">
										<option value=""></option>
										<cfif ucase(wkt_polygon) EQ "NOT NULL"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="NOT NULL" #selected#>Has Shape</option>
										<cfif ucase(wkt_polygon) EQ "NULL"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="NULL" #selected#>No Shape</option>
									</select>
								</div>
								<div class="col-12 col-md-4 col-xl-2 my-1">
									<cfif not isDefined("highergeographyid")><cfset highergeographyid=""></cfif>
									<label for="highergeographyid" class="data-entry-label">dwc:higherGeographyID</label>
									<input type="text" name="highergeographyid" id="highergeographyid" class="data-entry-input" value="#encodeForHtml(highergeographyid)#">
									<script>
										jQuery(document).ready(function() {
											makeGeogSearchAutocomplete('highergeographyid','highergeographyid');
										});
									</script>
								</div>
								<div class="col-12 col-md-4 col-xl-2 my-1">
									<cfif not isDefined("source_authority")><cfset source_authority=""></cfif>
									<label for="source_authority" class="data-entry-label">Source Authority</label>
									<input type="text" name="source_authority" id="source_authority" class="data-entry-input" value="#encodeForHtml(source_authority)#">
									<script>
										jQuery(document).ready(function() {
											makeGeogSearchAutocomplete('source_authority','source_authority');
										});
									</script>
								</div>
								<cfif showLocality EQ 0 and showEvent EQ 0 AND isdefined("session.roles") and listfindnocase(session.roles,"manage_geography")>
									<div class="col-12 col-md-4 col-xl-2 my-1">
										<cfif not isDefined("curated_fg")><cfset curated_fg=""></cfif>
										<label for="curated_fg" class="data-entry-label">Vetted (manage only)</label>
										<select name="curated_fg" id="curated_fg" size="1" class="data-entry-select">
											<cfif len(curated_fg) EQ "0"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="" #selected#>Any</option>
											<cfif ucase(curated_fg) EQ "0"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="0" #selected#>No</option>
											<cfif ucase(curated_fg) EQ "1"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="1" #selected#>Yes</option>
										</select>
									</div>
								</cfif>
								<div class="col-12 col-md-4 col-xl-2 my-1">
									<cfif not isDefined("valid_catalog_term_fg")><cfset valid_catalog_term_fg=""></cfif>
									<label for="valid_catalog_term_fg" class="data-entry-label">Valid for data entry</label>
									<select name="valid_catalog_term_fg" id="valid_catalog_term_fg" size="1" class="data-entry-select">
										<cfif len(valid_catalog_term_fg) EQ "0"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="" #selected#>Any</option>
										<cfif ucase(valid_catalog_term_fg) EQ "1"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="1" #selected#>Yes</option>
										<cfif ucase(valid_catalog_term_fg) EQ "0"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="0" #selected#>No</option>
									</select>
								</div>
							</cfif>
						</div>
					</div>
				</div>
			</div>

			<!--------------------------------------- Locality ----------------------------------------------------------->
			<cfif #showLocality# IS 1>
				<div class="row mb-1"> 
					<div class="col-12 mt-0">
						<div class="search-box-header rounded-teal">
							<h2 class="h3 mt-1 text-white" id="searchForm">Locality</h2>
						</div>
						<cfif listFind(searchPrefList,"LocDetail") EQ 0>
							<cfset locDetailStyle="display:none;">
							<cfset toggleTo = "1">
							<cfset locButton = "More Fields">
						<cfelse>
							<cfset locDetailStyle="">
							<cfset toggleTo = "0">
							<cfset locButton = "Fewer Fields">
						</cfif> 
						<div class="form-row mx-0 mt-2 mb-2">
							<cfif #showExtraFields# IS 1>
								<cfset spec_loc_class = "col-md-2">
							<cfelse>
								<cfset spec_loc_class = "col-md-4">
							</cfif>
							<div class="col-12 col-md-3 col-xl-4 px-3 pl-md-3 pr-md-2 py-1">
								<cfif not isDefined("spec_locality")><cfset spec_locality=""></cfif>
								<label for="spec_locality" class="data-entry-label">Specific Locality</label>
								<input type="text" name="spec_locality" id="spec_locality" class="data-entry-input" value="#encodeForHtml(spec_locality)#">
							</div>
							<cfif #showExtraFields# IS 1>
								<div class="col-12 col-md-3 col-xl-2 px-3 px-md-0 py-1">
									<cfif not isDefined("any_geography")><cfset any_geography=""></cfif>
									<label for="any_geography" class="data-entry-label">Any Geography (keyword)</label>
									<input type="text" name="any_geography" id="any_geography" class="data-entry-input" value="#encodeForHtml(any_geography)#">
								</div>
							</cfif>
							<div class="col-12 col-md-1 px-3 px-md-2 py-1">
								<cfif not isDefined("collnOper")><cfset collnOper=""></cfif>
								<cfif not isDefined("collnEvOper")><cfset collnEvOper=""></cfif>
								<cfif #showExtraFields# IS 1>
									<!--- collnOper is split into two controls in new API, collnEvOper for event and collnOper for locality --->
									<cfif collnEvOper NEQ "" AND left(collnOper,2) EQ "ev">
										<cfset collnEvOper = collnOper>
										<cfset collnOper = "">
									</cfif> 
								</cfif>
								<label for="collnOper" class="data-entry-label">Use</label>
								<select name="collnOper" id="collnOper" size="1" class="data-entry-select">
									<cfif len(collnOper) EQ 0><cfset selected="selected"><cfelse><cfset selected=""></cfif>
									<option value="" #selected#></option>
									<cfif collnOper EQ "usedOnlyBy"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
									<option value="usedOnlyBy" #selected#>used only by</option>
									<cfif collnOper EQ "usedBy"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
									<option value="usedBy" #selected#>used by</option>
									<cfif collnOper EQ "notUsedBy"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
									<option value="notUsedBy" #selected#>not used by</option>
									<cfif #showExtraFields# NEQ 1>
										<cfif collnOper EQ "eventUsedOnlyBy"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="eventUsedOnlyBy" #selected#>event used only by</option>
										<cfif collnOper EQ "eventUsedBy"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="eventUsedBy" #selected#>event used by</option>
										<cfif collnOper EQ "eventSharedOnlyBy"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="eventSharedOnlyBy" #selected#>event shared only by</option>
									</cfif>
								</select>
							</div>
							<div class="col-12 col-md-2 px-3 px-md-0 py-1">
								<cfif isDefined("collection_id")><cfset collection_id_val="#collection_id#"><cfelse><cfset collection_id_val=""></cfif>
								<label for="collection_id" class="data-entry-label">Collection</label>
								<select name="collection_id" id="collection_id" size="1" class="data-entry-select">
									<option value=""></option>
									<cfloop query="ctcollection">
										<cfif collection_id_val EQ ctcollection.collection_id><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="#ctcollection.collection_id#" #selected#>#ctcollection.collection#</option>
									</cfloop>
								</select>
								<script>
									function changeColl() { 
										if ($("##collection_id").val()=="") { 
											$("##collnOper").removeClass("reqdClr");
										} else { 
											$("##collnOper").addClass("reqdClr");
										}
									} 
									$(document).ready(function() { 
										$("##collection_id").on("change",changeColl);
									});
								</script>
							</div>
							<div class="col-6 col-md-1 pl-3 pr-1 px-md-2 py-1">
								<cfif not isDefined("curated_fg")><cfset curated_fg=""></cfif>
								<label for="curated_fg" class="data-entry-label">Vetted</label>
								<select name="curated_fg" id="curated_fg" class="data-entry-select">
									<option value=""></option>
									<cfif curated_fg EQ 0><cfset selected="selected"><cfelse><cfset selected=""></cfif>
									<option value="0" #selected#>No</option>
									<cfif curated_fg EQ 1><cfset selected="selected"><cfelse><cfset selected=""></cfif>
									<option value="1" #selected#>Yes *</option>
								</select>
							</div>
							<div class="col-6 col-md-2 col-xl-1 pr-3 pl-1 pr-md-3 pl-md-0 py-1">
								<cfif not isDefined("locality_id")><cfset locality_id=""></cfif>
								<label for="locality_id" class="data-entry-label">Locality ID</label>
								<input type="text" name="locality_id" id="locality_id" class="data-entry-input" value="#encodeForHtml(encodeForHtml(locality_id))#">
							</div>
							<div class="col-12 col-md-2 col-xl-1 px-3 py-1 pt-md-1 px-xl-1 pt-xl-3">
								<label for="locDetailCtl" class="data-entry-label text-light sr-only">Locality</label>
								<button type="button" id="locDetailCtl" class="btn btn-xs mt3px btn-secondary" onclick="toggleLocDetail(#toggleTo#);">#locButton#</button>
							</div>
						</div>
						<div id="locDetail" class="" style="#locDetailStyle#">
							<div class="form-row mx-0 my-2">
								<div class="col-12 col-md-8 px-3 pl-md-3 pr-md-1 py-1">
									<cfif not isDefined("locality_remarks")><cfset locality_remarks=""></cfif>
									<label for="locality_remarks" class="data-entry-label">Locality Remarks</label>
									<input type="text" name="locality_remarks" id="locality_remarks" class="data-entry-input" value="#encodeForHtml(locality_remarks)#">
								</div>
								<div class="col-12 col-md-4 px-3 pl-md-1 pr-md-3 py-1">
									<cfif not isDefined("sovereign_nation")><cfset sovereign_nation_val=""><cfelse><cfset sovereign_nation_val="#sovereign_nation#"></cfif>
									<label for="sovereign_nation" class="data-entry-label">Sovereign Nation</label>
									<select name="sovereign_nation" id="sovereign_nation" size="1" class="data-entry-select">
										<option value=""></option>
										<cfloop query="ctsovereign_nation">
											<cfif sovereign_nation_val EQ ctsovereign_nation.sovereign_nation><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="#ctsovereign_nation.sovereign_nation#" #selected# >#ctsovereign_nation.sovereign_nation#(#ctsovereign_nation.ct#)</option>
										</cfloop>
										<cfloop query="ctsovereign_nation" startRow="1">
											<cfif sovereign_nation_val EQ "!#ctsovereign_nation.sovereign_nation#"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="!#ctsovereign_nation.sovereign_nation#" #sovereign_nation#>!#ctsovereign_nation.sovereign_nation#</option>
										</cfloop>
									</select>
								</div>
							</div>
							<div class="form-row mx-0 my-1">
								<div class="form-row mx-0 my-1 col-12 col-lg-6">
									<div class="col-5 col-md-2 px-3 pl-md-3 pr-md-2 py-1">
										<cfif isDefined("orig_elev_units")><cfset orig_elev_units_val="#orig_elev_units#"><cfelse><cfset orig_elev_units_val=""></cfif>
										<label for="orig_elev_units" class="data-entry-label">Orig. Elev. Units</label>
										<select name="orig_elev_units" id="orig_elev_units" size="1" class="data-entry-select" style="min-width: 100px;">
											<option value=""></option>
											<cfloop query="ctElevUnit">
												<cfif ctElevUnit.orig_elev_units EQ orig_elev_units_val><cfset selected="selected"><cfelse><cfset selected=""></cfif>
												<option value="#ctElevUnit.orig_elev_units#" #selected#>#ctElevUnit.orig_elev_units#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-12 col-md-5 px-3 pl-md-3 pr-md-0 py-1">
										<label for="maximum_elevation" class="data-entry-label mb-0">Minimum Elevation <span class="small">(Original Units)</span></label>
										<cfif not isDefined("MinElevOper")><cfset MinElevOper="="></cfif>
										<cfif MinElevOper IS "!"><cfset MinElevOper="<>"></cfif>
										<label for="MinElevOper" class="data-entry-label text-white sr-only">(operator)</label>
										<select name="MinElevOper" id="MinElevOper" size="1" class="data-entry-select w-auto d-inline-block col-12 col-md-4">
											<cfif MinElevOper IS "="><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="=" #selected#>is</option>
											<cfif MinElevOper IS "<>"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="<>" #selected#>is not</option><!--- " --->
											<cfif MinElevOper IS ">"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value=">" #selected#>more than</option><!--- " --->
											<cfif MinElevOper IS "<"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="<" #selected#>less than</option>
										</select>
										<cfif not isDefined("minimum_elevation")><cfset minimum_elevation=""></cfif>
										<input type="text" name="minimum_elevation" id="minimum_elevation" class="data-entry-input w-100 d-inline-block col-12 col-md-8" value="#encodeForHtml(minimum_elevation)#">
									</div>
									<div class="col-12 col-md-5 px-3 pr-md-3 pl-md-0 py-1">
										<label for="MaxElevOper" class="data-entry-label mb-0">Maximum Elevation <span class="small">(Original Units)</span></label>
										<cfif not isDefined("MaxElevOper")><cfset MaxElevOper="="></cfif>
										<cfif MaxElevOper IS "!"><cfset MaxElevOper="<>"></cfif>
										<select name="MaxElevOper" id="MaxElevOper" size="1" class="data-entry-select w-auto d-inline-block col-12 col-md-4">
											<cfif MaxElevOper IS "="><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="=" #selected#>is</option>
											<cfif MaxElevOper IS "<>"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="<>" #selected#>is not</option><!--- " --->
											<cfif MaxElevOper IS ">"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value=">" #selected#>more than</option><!--- " --->
											<cfif MaxElevOper IS "<"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="<" #selected#>less than</option>
										</select>
										<cfif not isDefined("maximum_elevation")><cfset maximum_elevation=""></cfif>
										<label for="maximum_elevation" class="data-entry-label text-white sr-only">Elevation</label>
										<input type="text" name="maximum_elevation" id="maximum_elevation" class="data-entry-input w-auto d-inline-block col-12 col-md-8" value="#encodeForHtml(maximum_elevation)#">
									</div>
								</div>
								<div class="form-row mx-0 my-1 col-12 col-lg-6">
									<div class="col-12 col-md-6 px-3 pr-md-0 py-2">
										<label for="MinElevOperM" class="data-entry-label">Minimum Elevation <span class="small">(in meters)</span></label>
										<cfif not isDefined("MinElevOperM")><cfset MinElevOperM="="></cfif>
										<cfif MinElevOperM IS "!"><cfset MinElevOperM="<>"></cfif>
										<select name="MinElevOperM" id="MinElevOperM" size="1" class="data-entry-select w-auto d-inline-block col-12 col-md-4">
											<cfif MinElevOperM IS "="><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="=" #selected#>is</option>
											<cfif MinElevOperM IS "<>"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="<>" #selected#>is not</option><!--- " --->
											<cfif MinElevOperM IS ">"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value=">" #selected#>more than</option><!--- " --->
											<cfif MinElevOperM IS "<"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="<" #selected#>less than</option>
										</select>
										<cfif not isDefined("minimum_elevation_m")><cfset minimum_elevation_m=""></cfif>
										<label for="minimum_elevation_m" class="data-entry-label sr-only text-light">Minimum</label>
										<input type="text" name="minimum_elevation_m" id="minimum_elevation_m" class="data-entry-input w-100 d-inline-block col-12 col-md-8" value="#encodeForHtml(minimum_elevation_m)#">
									</div>
									<div class="col-12 col-md-6 px-3 pl-md-0 py-2">
										<label for="MaxElevOperM" class="data-entry-label">Maximum Elevation <span class="small">(in meters)</span></label>
										<cfif not isDefined("MaxElevOperM")><cfset MaxElevOperM="="></cfif>
										<cfif MaxElevOperM IS "!"><cfset MaxElevOperM="<>"></cfif>
										<select name="MaxElevOperM" id="MaxElevOperM" size="1" class="data-entry-select w-auto d-inline-block col-12 col-md-4">
											<cfif MaxElevOperM IS "="><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="=" #selected#>is</option>
											<cfif MaxElevOperM IS "<>"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="<>" #selected#>is not</option><!--- " --->
											<cfif MaxElevOperM IS ">"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value=">" #selected#>more than</option><!--- " --->
											<cfif MaxElevOperM IS "<"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="<" #selected#>less than</option>
										</select>
										<cfif not isDefined("maximum_elevation_m")><cfset maximum_elevation_m=""></cfif>
										<label for="maximum_elevation_m" class="data-entry-label sr-only text-light">Maximum</label>
										<input type="text" name="maximum_elevation_m" id="maximum_elevation_m" class="data-entry-input w-100 d-inline-block col-12 col-md-8" value="#encodeForHtml(maximum_elevation_m)#">
									</div>
								</div>
							</div>
							<div class="form-row mx-0 my-1">
								<div class="form-row mx-0 my-1 col-12 col-lg-6">
									<div class="col-5 col-md-2 px-3 pl-md-3 pr-md-2 py-1">
										<cfif isDefined("depth_units")><cfset depth_units_val="#depth_units#"><cfelse><cfset depth_units_val=""></cfif>
										<label for="depth_units" class="data-entry-label">Orig. Depth Units</label>
										<select name="depth_units" id="depth_units" size="1" class="data-entry-select"  style="min-width: 100px;">
											<option value=""></option>
											<cfloop query="ctDepthUnit">
												<cfif ctDepthUnit.Depth_units EQ depth_units_val><cfset selected="selected"><cfelse><cfset selected=""></cfif>
												<option value="#ctDepthUnit.Depth_units#" #selected#>#ctDepthUnit.Depth_units#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-12 col-md-5 px-3 pl-md-3 pr-md-0 py-1">
										<label class="data-entry-label">Minimum Depth <span class="small">(Original Units)</span></label>
										<cfif not isDefined("minDepthOper")><cfset minDepthOper="="></cfif>
										<label for="minDepthOper" class="data-entry-label sr-only">Operator</label>
										<select name="minDepthOper" id="MinDepthOper" size="1" class="data-entry-select w-auto d-inline-block col-12 col-md-4">
											<cfif minDepthOper IS "="><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="=">is</option>
											<cfif minDepthOper IS "<>"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="<>">is not</option><!--- " --->
											<cfif minDepthOper IS ">"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value=">">more than</option><!--- " --->
											<cfif minDepthOper IS "<"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="<">less than</option>
										</select>
										<cfif not isDefined("min_depth")><cfset min_depth=""></cfif>
										<label for="min_depth" class="data-entry-label text-light sr-only">Minimum Depth</label>
										<input type="text" name="min_depth" id="min_depth" class="data-entry-input w-100 d-inline-block col-12 col-md-8" value="#encodeForHtml(min_depth)#">
									</div>
									<div class="col-12 col-md-5 px-3 pr-md-3 pl-md-0 py-1">
										<label for="max_depth" class="data-entry-label mb-0">Maximum Depth <span class="small">(Original Units)</span></label>
										<cfif isDefined("MaxDepthOper")><cfset MaxDepthOper="#MaxDepthOper#"><cfelse><cfset MaxDepthOper=""></cfif>
										<label for="MaxDepthOper" class="data-entry-label text-light sr-only">operator</label>
										<select name="MaxDepthOper" id="MaxDepthOper" size="1" class="data-entry-select w-auto d-inline-block col-12 col-md-4">
											<cfif MaxDepthOper EQ "="><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="=" #selected#>is</option>
											<cfif MaxDepthOper EQ "<>"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="<>" #selected#>is not</option><!--- " --->
											<cfif MaxDepthOper EQ ">"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value=">" #selected#>more than</option><!--- " --->
											<cfif MaxDepthOper EQ "<"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="<" #selected#>less than</option>
										</select>
										<cfif not isDefined("max_depth")><cfset max_depth=""></cfif>
										<input type="text" name="max_depth" id="max_depth" class="data-entry-input w-auto d-inline-block col-12 col-md-8" value="#encodeForHtml(max_depth)#">
									</div>
								</div>
								<div class="form-row mx-0 my-1 col-12 col-lg-6">
									<div class="col-12 col-md-6 pr-md-0 px-3 pr-md-0 py-2">
										<cfif not isDefined("minDepthOperM")><cfset minDepthOperM="="></cfif>
										<label for="minDepthOperM" class="data-entry-label">Minimum Depth <span class="small">(in meters)</span></label>
										<select name="minDepthOperM" id="MinDepthOperM" size="1" class="data-entry-select w-auto d-inline-block col-12 col-md-4">
											<cfif minDepthOperM IS "="><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="=" #selected#>is</option>
											<cfif minDepthOperM IS "<>"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="<>" #selected#>is not</option><!--- " --->
											<cfif minDepthOperM IS ">"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value=">" #selected#>more than</option><!--- " --->
											<cfif minDepthOperM IS "<"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="<" #selected#>less than</option>
										</select>
										<cfif not isDefined("min_depth_m")><cfset min_depth_m=""></cfif>
										<label for="min_depth_m" class="data-entry-label sr-only text-light">Mimimum</label>
										<input type="text" name="min_depth_m" id="min_depth_m" class="data-entry-input w-100 d-inline-block col-12 col-md-8" value="#encodeForHtml(min_depth_m)#">
									</div>
									<div class="col-12 col-md-6 px-3 pl-md-0 py-2">
										<cfif not isDefined("MaxDepthOperM")><cfset MaxDepthOperM="="></cfif>
										<label for="MaxDepthOperM" class="data-entry-label">Maximum Depth <span class="small">(in meters)</span></label>
										<select name="MaxDepthOperM" id="MaxDepthOperM" size="1" class="data-entry-select w-auto d-inline-block col-12 col-md-4">
											<cfif MaxDepthOperM IS "="><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="=" #selected#>is</option>
											<cfif MaxDepthOperM IS "<>"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="<>" #selected#>is not</option><!--- " --->
											<cfif MaxDepthOperM IS ">"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value=">" #selected#>more than</option><!--- " --->
											<cfif MaxDepthOperM IS "<"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="<" #selected#>less than</option>
										</select>
										<cfif not isDefined("max_depth_m")><cfset max_depth_m=""></cfif>
										<label for="max_depth_m" class="data-entry-label text-light sr-only">Maximum</label>
										<input type="text" name="max_depth_m" id="max_depth_m" class="data-entry-input w-100 d-inline-block col-12 col-md-8" value="#encodeForHtml(max_depth_m)#">
									</div>
								</div>
							</div>
							<cfif #showExtraFields# IS 1>
								<div class="form-row mx-0 my-1">
									<div class="col-12 col-md-2 px-3 pl-md-3 pr-md-0 py-2">
										<cfif not isDefined("section_part")><cfset section_part=""></cfif>
										<label for="section_part" class="data-entry-label">PLSS Section Part</label>
										<input type="text" name="section_part" id="section_part" class="data-entry-input" value="#encodeForHtml(section_part)#">
									</div>
									<div class="col-12 col-md-2 px-3 px-md-2 py-2">
										<cfif not isDefined("section")><cfset section=""></cfif>
										<label for="section" class="data-entry-label">PLSS Section</label>
										<input type="text" name="section" id="section" class="data-entry-input" value="#encodeForHtml(section)#">
									</div>
									<div class="col-12 col-md-2 px-3 px-md-0 py-2">
										<cfif not isDefined("township")><cfset township=""></cfif>
										<label for="township" class="data-entry-label">PLSS Township</label>
										<input type="text" name="township" id="township" class="data-entry-input" value="#encodeForHtml(township)#">
									</div>
									<div class="col-12 col-md-2 px-3 px-md-2 py-2">
										<cfif not isDefined("township_direction")><cfset township_direction=""></cfif>
										<label for="township_direction" class="data-entry-label">Township Dir.</label>
										<select name="township_direction" id="" size="1" class="data-entry-select">
											<cfif len(township_direction) EQ 0><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="" #selected#></option>
											<cfif ucase(township_direction) EQ "N"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="N" #selected#>N</option>
											<cfif ucase(township_direction) EQ "S"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="S" #selected#>S</option>
										</select>
									</div>
									<div class="col-12 col-md-2 px-3 px-md-0 py-2">
										<cfif not isDefined("range")><cfset range=""></cfif>
										<label for="range" class="data-entry-label">PLSS Range</label>
										<input type="text" name="range" id="range" class="data-entry-input" value="#encodeForHtml(range)#">
									</div>
									<div class="col-12 col-md-2 px-3 pr-md-3 pl-md-2 py-2">
										<cfif not isDefined("range_direction")><cfset range_direction=""></cfif>
										<label for="range_direction" class="data-entry-label">Range Dir.</label>
										<select name="range_direction" id="" size="1" class="data-entry-select">
											<cfif len(range_direction) EQ 0><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="" #selected#></option>
											<cfif ucase(range_direction) EQ "N"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="N" #selected#>N</option>
											<cfif ucase(range_direction) EQ "S"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="S" #selected#>S</option>
										</select>
									</div>
								</div>
							</cfif>
							<div class="form-row mx-0 my-1">
								<div class="col-12 col-md-3 px-3 py-2 py-md-0 pl-md-3 pr-md-0">
									<cfif isDefined("geology_attribute")><cfset geology_attribute_val="#geology_attribute#"><cfelse><cfset geology_attribute_val=""></cfif>
									<label for="geology_attribute" class="data-entry-label">Geology Attribute</label>
									<select name="geology_attribute" id="geology_attribute" class="data-entry-select">
										<option value=""></option>
										<cfloop query="ctgeology_attribute">
											<cfif ctgeology_attribute.geology_attribute EQ geology_attribute_val><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value = "#ctgeology_attribute.geology_attribute#" #selected#>#ctgeology_attribute.geology_attribute#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-3 px-3 py-md-0 px-md-2 py-2">
									<cfif not isDefined("geo_att_value")><cfset geo_att_value=""></cfif>
									<label for="geo_att_value" class="data-entry-label">Attribute Value</label>
									<input type="text" name="geo_att_value" class="data-entry-input" value="#encodeForHtml(geo_att_value)#">
								</div>
								<div class="col-12 col-md-3 px-3 py-2 py-md-0 pr-md-3 pl-md-0">
									<cfif isDefined("geology_attribute_hier") and len(geology_attribute_hier) GT 0 ><cfset geology_attribute_hierValue="#geology_attribute_hier#"><cfelse><cfset geology_attribute_hierValue=""></cfif>
									<label for="geology_attribute_hier" class="data-entry-label">Traverse Hierarchies?</label>
									<select name="geology_attribute_hier" id="geology_attribute_hier" class="data-entry-select">
										<cfif len(geology_attribute_hierValue) EQ 0 or geology_attribute_hierValue EQ "0"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="0" #selected#>No</option>
										<cfif geology_attribute_hierValue EQ "1"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="1" #selected#>Yes</option>
									</select>
								</div>
								<cfif listFind(searchPrefList,"GeorefDetail") EQ 0>
									<cfset georefDetailStyle="display:none;">
									<cfset toggleTo = "1">
									<cfset georefButton = "Show Georef Fields">
								<cfelse>
									<cfset georefDetailStyle="">
									<cfset toggleTo = "0">
									<cfset georefButton = "Hide Georef Fields">
								</cfif> 
								<div class="col-12 col-md-3 px-3 pt-2 pt-md-3 pb-md-2 pb-3">
									<label for="georefDetailCtl" class="data-entry-label text-light sr-only">Georeference</label>
									<button type="button" id="georefDetailCtl" class="btn btn-xs btn-secondary" onclick="toggleGeorefDetail(#toggleTo#);">#georefButton#</button>
								</div>
							</div>
							<div id="georefDetail" class="border my-2 mx-3 rounded p-1" style="#georefDetailStyle#">
								<cfif #showExtraFields# IS 1>
									<div class="form-row px-2 mx-0 my-1">
										<div class="col-12 col-md-2">
											<cfif not isDefined("dec_lat")><cfset dec_lat=""></cfif>
											<label for="dec_lat" class="data-entry-label">Latitude</label>
											<input type="text" name="dec_lat" class="data-entry-input" value="#encodeForHtml(dec_lat)#">
										</div>
										<div class="col-12 col-md-2 py-2">
											<cfif not isDefined("dec_long")><cfset dec_long=""></cfif>
											<label for="dec_long" class="data-entry-label">Longitude</label>
											<input type="text" name="dec_long" class="data-entry-input" value="#encodeForHtml(dec_long)#">
										</div>
										<div class="col-12 col-md-2 py-2">
											<cfquery name="ctDatum" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
												select datum from ctdatum order by datum
											</cfquery>
											<cfif isDefined("datum")><cfset datum_val="#datum#"><cfelse><cfset datum_val=""></cfif>
											<label for="datum" class="data-entry-label">Datum</label>
											<select name="datum" id="datum" size="1" class="data-entry-select">
												<option value=""></option>
												<cfloop query="ctDatum">
													<cfif ctDatum.datum EQ datum_val><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="#ctDatum.datum#" #selected#>#ctDatum.datum#</option>
												</cfloop>
											</select>
										</div>
										<div class="col-12 col-md-2 py-2">
											<cfif not isDefined("max_error_distance")><cfset max_error_distance=""></cfif>
											<label for="max_error_distance" class="data-entry-label">Coordinate Uncertainty</label>
											<input type="text" name="max_error_distance" class="data-entry-input" value="#encodeForHtml(max_error_distance)#">
										</div>
										<div class="col-12 col-md-3 py-2">
											<cfif NOT isDefined("georeference_verified_by") ><cfset georeference_verified_by=""></cfif>
											<cfif NOT isDefined("georeference_verified_by_id") ><cfset georeference_verified_by_id=""></cfif>
											<label for="georeference_verified_by" class="data-entry-label">Georeference verified by</label>
											<input type="text" name="georeference_verified_by" id="georeference_verified_by" class="data-entry-input" value="#encodeForHtml(georeference_verified_by)#">
											<input type="hidden" name="georeference_verified_by_id" id="georeference_verified_by_id" value="#encodeForHtml(georeference_verified_by_id)#">
											<script>
												jQuery(document).ready(function() {
													makeConstrainedAgentPicker('georeference_verified_by', 'georeference_verified_by_id','georeference_verifier');
												});
											</script>
										</div>
									</div>
								</cfif>
								<div class="form-row mx-0 px-2 my-1">
									<div class="col-12 col-md-2 px-4 py-2 float-left">
										<div class="form-check">
											<cfif isDefined("findNoGeoRef") AND findNoGeoRef EQ "1"><cfset checked="checked"><cfelse><cfset checked=""></cfif>
											<input type="checkbox" name="findNoGeoRef" id="findNoGeoRef" class="form-check-input" #checked#>
											<label for="findNoGeoRef" class="form-check-label mt3px small95">No Georeferences</label>
										</div>
									</div>
									<div class="col-12 col-md-2 px-4 float-left py-2">
										<div class="form-check">
											<cfif isDefined("findHasGeoRef") AND findHasGeoRef EQ "1"><cfset checked="checked"><cfelse><cfset checked=""></cfif>
											<input class="form-check-input" name="findHasGeoRef" id="findHasGeoRef" value="1" type="checkbox" #checked#>
											<label class="form-check-label mt3px small95" for="findHasGeoRef">Has Georeferences</label>
										</div>
									</div>
									<div class="col-12 col-md-3 px-4 py-2 float-left">
										<div class="form-check">
											<cfif isDefined("findNoAccGeoRef") AND findNoAccGeoRef EQ "1"><cfset checked="checked"><cfelse><cfset checked=""></cfif>
											<input type="checkbox" name="findNoAccGeoRef" id="findNoAccGeoRef" class="form-check-input" #checked#>
											<label for="findNoAccGeoRef" class="form-check-label mt3px small95">No Accepted Georeferences</label>
										</div>
									</div>
<!--- TODO: Support findNoAccGeoRefStrict --->
									<div class="col-12 col-md-4 col-xl-3 pr-3 pl-0 py-2">
										<div class="form-check">
											<cfif isDefined("NoGeorefBecause") AND NoGeorefBecause EQ "1"><cfset checked="checked"><cfelse><cfset checked=""></cfif>
											<label for="NoGeorefBecause" class="data-entry-label">No Georeferece Because</label>
											<input type="text" name="NoGeorefBecause" id="NoGeorefBecause" class="data-entry-input" #checked#>
										</div>
									</div>
								</div>
								<div class="form-row mx-0 px-2 my-1">
									<div class="col-12 col-md-2 px-4 py-2 float-left">
										<div class="form-check">
											<cfif isDefined("isIncomplete") AND isIncomplete EQ "1"><cfset checked="checked"><cfelse><cfset checked=""></cfif>
											<input type="checkbox" name="isIncomplete" id="isIncomplete" class="form-check-input" #checked#>
											<label for="isIncomplete" class="form-check-label mt3px small95">Is Incomplete</label>
										</div>
									</div>
									<div class="col-12 col-md-2 px-4 py-2 float-left">
										<div class="form-check">
											<cfif isDefined("nullNoGeorefBecause") AND nullNoGeorefBecause EQ "1"><cfset checked="checked"><cfelse><cfset checked=""></cfif>
											<input type="checkbox" name="nullNoGeorefBecause" id="nullNoGeorefBecause" class="form-check-input" #checked#>
											<label for="nullNoGeorefBecause" class="form-check-label mt3px small95">NULL, No Georef. Because</label>
										</div>
									</div>
									<div class="col-12 col-md-2 px-2 py-2">
										<cfif isDefined("VerificationStatus") and len(VerificationStatus) GT 0 ><cfset VerificationStatusValue="#VerificationStatus#"><cfelse><cfset VerificationStatusValue=""></cfif>
										<label for="VerificationStatus" class="data-entry-label">VerificationStatus</label>
										<select name="VerificationStatus" id="VerificationStatus" size="1" class="data-entry-select">
											<option value=""></option>
											<cfloop query="ctVerificationStatus">
												<cfif verificationStatusValue EQ VerificationStatus><cfset selected="selected"><cfelse><cfset selected=""></cfif>
												<option value="#VerificationStatus#" #selected#>#VerificationStatus#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-12 col-md-2 px-4 px-md-5 mt-xl-3 py-2">
										<div class="form-check">
											<cfif isDefined("onlyShared") AND (onlyShared EQ "1" OR onlyShared EQ "on")><cfset checked="checked"><cfelse><cfset checked=""></cfif>
											<input type="checkbox" name="onlyShared" id="onlyShared" class="form-check-input" #checked#>
											<label for="onlyShared" class="form-check-label mt3px small95">Shared Localities Only</label>
										</div>
									</div>
									<div class="col-12 col-md-3 px-2 my-1">
										<cfif isDefined("GeorefMethod") and len(GeorefMethod) GT 0 ><cfset GeorefMethodValue="#GeorefMethod#"><cfelse><cfset GeorefMethodValue=""></cfif>
										<label for="GeorefMethod" class="data-entry-label">GeorefMethod</label>
										<select name="GeorefMethod" id="GeorefMethod" size="1" class="data-entry-select">
											<option value=""></option>
											<cfloop query="ctGeorefMethod">
												<cfif verificationStatusValue EQ GeorefMethod><cfset selected="selected"><cfelse><cfset selected=""></cfif>
												<option value="#GeorefMethod#" #selected#>#GeorefMethod#</option>
											</cfloop>
										</select>
									</div>

								</div>
								<div class="form-row mx-0 px-2 my-1">
									<div class="col-12 col-md-2 px-2 py-2">
										<label class="data-entry-label">Geolocate Precision</label>
										<cfif isDefined("geolocate_precision") and len(geolocate_precision) GT 0 ><cfset geolocate_precisionValue="#geolocate_precision#"><cfelse><cfset geolocate_precisionValue=""></cfif>
										<select name="geolocate_precision" id="geolocate_precision" size="1" class="data-entry-select">
											<cfif geolocate_precisionValue EQ ""><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="" #selected#></option>
											<cfif geolocate_precisionValue EQ "high"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="high" #selected#>high</option>
											<cfif geolocate_precisionValue EQ "medium"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="medium" #selected#>medium</option>
											<cfif geolocate_precisionValue EQ "low"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="low" #selected#>low</option>
										</select>
									</div>
									<div class="col-12 col-md-2 px-2 py-2">
										<cfif NOT isDefined("coordinateDeterminer") ><cfset coordinateDeterminer=""></cfif>
										<cfif NOT isDefined("georeference_determined_by_id") ><cfset georeference_determined_by_id=""></cfif>
										<label for="coordinateDeterminer" class="data-entry-label">Coordinate Determiner</label>
										<input type="text" name="coordinateDeterminer" id="coordinateDeterminer" class="data-entry-input" value="#encodeForHtml(coordinateDeterminer)#">
										<cfif #showExtraFields# IS 1>
											<input type="hidden" name="georeference_determined_by_id" id="georeference_determined_by_id" value="#encodeForHtml(georeference_determined_by_id)#">
											<script>
												jQuery(document).ready(function() {
													makeConstrainedAgentPicker('coordinateDeterminer', 'georeference_determined_by_id','georeference_determiner');
												});
											</script>
										</cfif>
									</div>
									<div class="col-12 col-md-2 px-2 py-2">
										<cfif isDefined("gs_comparator") and len(gs_comparator) GT 0 ><cfset gs_comparatorValue="#gs_comparator#"><cfelse><cfset gs_comparatorValue=""></cfif>
										<label class="data-entry-label">Geolocate Score</label>
										<select name="gs_comparator" id="gs_comparator" size="1" class="data-entry-select">
											<cfif gs_comparatorValue EQ "=" or len(gs_comparatorValue) EQ 0><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="=" #selected#>=</option>
											<cfif gs_comparatorValue EQ "<"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="<" #selected#><</option>
											<cfif gs_comparatorValue EQ ">"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value=">" #selected#>></option>
											<cfif gs_comparatorValue EQ "between"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="between" #selected#>between</option><!--- " --->
										</select>
									</div>
									<div class="col-12 col-md-2 px-2 py-2">
										<cfif not isDefined("geolocate_score")><cfset geolocate_score=""></cfif>
										<label class="data-entry-label">Min (#geolocate_score_range.min_score#)</label>
										<input type="text" name="geolocate_score" size="3" id="geolocate_score" class="data-entry-input" value="#encodeForHtml(geolocate_score)#">
									</div>
									<div class="col-12 col-md-2 px-2 py-2">
										<cfif not isDefined("geolocate_score2")><cfset geolocate_score2=""></cfif>
										<label class="data-entry-label">Max (#geolocate_score_range.max_score#)</label>
										<input type="text" name="geolocate_score2" size="3" id="geolocate_score2" class="data-entry-input" value="#encodeForHtml(geolocate_score2)#">
									</div>
								</div>
							</div><!--- end georefDetail --->
						</div><!--- end locDetail --->
					</div>
				</div>
			</cfif>
				
			<!----------------------------------- Collecting Event ----------------------------------------------------------->
			<cfif #showEvent# is 1>
				<div class="row mx-0 mb-0"> 
					<div class="col-12 px-0 mt-0">
						<div class="search-box-header rounded-teal">
							<h2 class="h3 text-white mt-1" id="searchForm">Collecting Event</h2>
						</div>
						<cfif listFind(searchPrefList,"EventDetail") EQ 0>
							<cfset eventDetailStyle="display:none;">
							<cfset toggleTo = "1">
							<cfset eventButton = "More Fields">
						<cfelse>
							<cfset eventDetailStyle="">
							<cfset toggleTo = "0">
							<cfset eventButton = "Fewer Fields">
						</cfif> 
						<div class="form-row px-3 mt-2">
							<div class="col-12 col-md-5 col-xl-4 py-1">
								<cfif NOT isDefined("verbatim_locality") ><cfset verbatim_locality=""></cfif>
								<label for="verbatim_locality" class="data-entry-label">Verbatim Locality</label>
								<input type="text" name="verbatim_locality" id="verbatim_locality" size="75" class="data-entry-input" value="#encodeForHtml(verbatim_locality)#">
								<script>
									//jQuery(document).ready(function() {
									//	makeCEFieldAutocomplete("verbatim_locality", "verbatim_locality");
									//});
								</script>
							</div>
							<div class="col-12 col-md-3 col-xl-2 py-1">
								<cfif NOT isDefined("verbatim_date") ><cfset verbatim_date=""></cfif>
								<label for="verbatim_date" class="data-entry-label">Verbatim Date</label>
								<input type="text" name="verbatim_date" id="verbatim_date" class="data-entry-input" value="#encodeForHtml(verbatim_date)#" >
								<script>
									//jQuery(document).ready(function() {
									//	makeCEFieldAutocomplete("verbatim_date", "verbatim_date");
									//});
								</script>
							</div>
							<div class="col-12 col-md-2 col-xl-2 py-1">
								<cfif NOT isDefined("collecting_event_id") ><cfset collecting_event_id=""></cfif>
								<label for="collecting_event_id" class="data-entry-label">Collecting Event ID</label>
								<input type="text" name="collecting_event_id" id="collecting_event_id" class="data-entry-input" value="#encodeForHtml(collecting_event_id)#" >
							</div>
							<div class="col-12 col-md-2 py-1 pt-xl-3">
								<label for="eventDetailCtl" class="data-entry-label d-sm-none d-md-inline float-left sr-only text-light">Collecting Event</label> 
								<button type="button" id="eventDetailCtl" class="btn btn-xs mt3px btn-secondary" onclick="toggleEventDetail(#toggleTo#);">#eventButton#</button>
							</div>
						</div>
						<div id="eventDetail" style="#eventDetailStyle#">
							<div class="form-row px-3">
								<div class="col-12 col-md-2 mt3px py-1">
									<cfif NOT isDefined("verbatimdepth") ><cfset verbatimdepth=""></cfif>
									<label for="verbatimdepth" class="data-entry-label">Verbatim Depth</label>
									<input type="text" name="verbatimdepth" id="verbatimdepth" size="75" class="data-entry-input" value="#encodeForHtml(verbatimdepth)#">
									<script>
										jQuery(document).ready(function() {
											makeCEFieldAutocomplete("verbatimdepth", "verbatimdepth"); 
										});
									</script>
								</div>
								<div class="col-12 col-md-2 mt3px py-1">
									<cfif NOT isDefined("verbatimelevation") ><cfset verbatimelevation=""></cfif>
									<label for="verbatimelevation" class="data-entry-label">Verbatim Elevation</label>
									<input type="text" name="verbatimelevation" id="verbatimelevation" size="75" class="data-entry-input" value="#encodeForHtml(verbatimelevation)#">
									<script>
										jQuery(document).ready(function() {
											makeCEFieldAutocomplete("verbatimelevation", "verbatimelevation");
										});
									</script>
								</div>
								<div class="col-6 col-md-3 col-xl-2 pr-0 py-1">
									<label for="began_date" class="data-entry-label mt3px" style="margin-top:0.15rem;">Began Date</label>
									<cfif NOT isDefined("begDateOper") ><cfset begDateOper=""></cfif>
									<select name="begDateOper" id="begDateOper" size="1" class="data-entry-select col-6 col-md-3 d-inline-block w-auto pr-0" style="max-width: 30%" aria-label="operator for began date">
										<cfif begDateOper EQ "="><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="=" #selected#>is</option>
										<cfif begDateOper EQ "<"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="<" #selected#>before</option>
										<cfif begDateOper EQ ">"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value=">" #selected#>after</option><!--- " --->
									</select>
									<cfif NOT isDefined("began_date") ><cfset began_date=""></cfif>
									<input type="text" name="began_date" id="began_date" class="data-entry-input col-7 col-md-6 d-inline-block col-md-8 w-auto" value="#encodeForHtml(began_date)#" placeholder="yyyy-mm-dd">
								</div>
								<div class="col-6 col-md-3 col-xl-2 pr-0 py-1">
									<label for="ended_date" class="data-entry-label mt3px" style="margin-top: 0.15rem;">End Date</label>
									<cfif NOT isDefined("endDateOper") ><cfset endDateOper=""></cfif>
									<select name="endDateOper" id="endDateOper" size="1" class="data-entry-select col-6 col-md-3 d-inline-block w-auto pr-0" style="max-width: 30%" aria-label="operator for end date">
										<cfif endDateOper EQ "="><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="=" #selected#>is</option>
										<cfif endDateOper EQ "<"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="<" #selected#>before</option>
										<cfif endDateOper EQ ">"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value=">" #selected#>after</option><!--- " --->
									</select>
									<cfif NOT isDefined("ended_date") ><cfset ended_date=""></cfif>
									<input type="text" name="ended_date" id="ended_date" class="data-entry-input col-7 col-md-6 d-inline-block col-md-8 w-auto" value="#encodeForHtml(ended_date)#" placeholder="yyyy-mm-dd">
								</div>
					
								<cfif #showExtraFields# IS 1>
									<div class="col-12 col-md-2  py-1">
										<cfif NOT isDefined("collecting_time") ><cfset collecting_time=""></cfif>
										<span class="data-entry-label">Collecting Time</span>
										<input type="text" name="collecting_time" id="collecting_time" class="data-entry-input" value="#encodeForHtml(collecting_time)#">
										<script>
											jQuery(document).ready(function() {
												makeCEFieldAutocomplete("collecting_time", "collecting_time"); 
											});
										</script>
									</div>
									<div class="col-6 col-md-2 col-xl-1 py-1">
										<cfif NOT isDefined("startdayofyear") ><cfset startdayofyear=""></cfif>
										<span class="data-entry-label">Start Day</span>
										<input type="text" name="startdayofyear" id="startdayofyear" class="data-entry-input" value="#encodeForHtml(startdayofyear)#">
									</div>
									<div class="col-6 col-md-2 col-xl-1 py-1">
										<cfif NOT isDefined("enddayofyear") ><cfset enddayofyear=""></cfif>
										<span class="data-entry-label">End Day</span>
										<input type="text" name="enddayofyear" id="enddayofyear" class="data-entry-input" value="#encodeForHtml(enddayofyear)#">
									</div>
								</cfif>
							</div>
							<div class="form-row px-3">
								<div class="col-12 col-md-2 py-2">
									<cfif NOT isDefined("verbatimCoordinates") ><cfset verbatimCoordinates=""></cfif>
									<label for="verbatimCoordinates" class="data-entry-label">Verbatim Coordinates</label>
									<input type="text" name="verbatimCoordinates" id="verbatimCoordinates" class="data-entry-input" value="#encodeForHtml(verbatimCoordinates)#">
								</div>
								<div class="col-12 col-md-2 py-2">
									<label for="verbatimCoordinateSystem" class="data-entry-label">Verbatim Coord. System</label>
									<input type="text" name="verbatimCoordinateSystem" id="verbatimCoordinateSystem" class="data-entry-input">
									<script>
										jQuery(document).ready(function() {
											makeCEFieldAutocomplete("verbatimCoordinateSystem", "verbatimCoordinateSystem");
										});
									</script>
								</div>
								<div class="col-12 col-md-2 py-2">
									<label for="verbatimSRS" class="data-entry-label">Verbatim SRS (datum)</label>
									<input type="text" name="verbatimSRS" id="verbatimSRS" class="data-entry-input">
									<script>
										jQuery(document).ready(function() {
											makeCEFieldAutocomplete("verbatimSRS", "verbatimSRS");
										});
									</script>
								</div>
								<div class="col-12 col-md-2 py-2">
									<label for="collecting_method" class="data-entry-label pr-md-3 pr-lg-0">Collecting Method</label>
									<input type="text" name="collecting_method" id="collecting_method" class="data-entry-input">
									<script>
										jQuery(document).ready(function() {
											makeCEFieldAutocomplete("collecting_method", "collecting_method"); 
										});
									</script>
								</div>
								<div class="col-12 col-md-2 py-2">
									<cfif NOT isDefined("habitat_desc") ><cfset habitat_desc=""></cfif>
									<label for="habitat_desc" class="data-entry-label pr-md-5 pr-lg-0">General Habitat</label>
									<input type="text" name="habitat_desc" id="habitat_desc" class="data-entry-input" value="#encodeForHtml(habitat_desc)#">
									<script>
										jQuery(document).ready(function() {
											makeCEFieldAutocomplete("habitat_desc", "habitat_desc");
										});
									</script>
								</div>
								<div class="col-12 col-md-2 py-2">
									<label for="collecting_source" class="data-entry-label pr-md-4 pr-lg-0">Collecting Source</label>
									<select name="collecting_source" id="collecting_source" size="1" class="data-entry-select">
										<option value=""></option>
										<cfloop query="ctCollectingSource">
											<option value="#ctCollectingSource.collecting_source#">#ctCollectingSource.collecting_source#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-4 py-2 pt-md-4 pt-lg-2">
									<label for="coll_event_remarks" class="data-entry-label">Collecting Event Remarks</label>
									<input type="text" name="coll_event_remarks" id="coll_event_remarks" class="data-entry-input">
								</div>
								<cfif #showExtraFields# IS 1>
									<div class="col-12 col-md-2 py-2">
										<cfif NOT isDefined("fish_field_number") ><cfset fish_field_number=""></cfif>
										<label for="fish_field_number" class="data-entry-label pr-md-3 pr-lg-0">Fish Field Number</label>
										<input type="text" name="fish_field_number" id="fish_field_number" class="data-entry-input" value="#encodeForHtml(fish_field_number)#">
										<script>
											jQuery(document).ready(function() {
												makeCEFieldAutocomplete("fish_field_number", "fish_field_number");
											});
										</script>
									</div>
									<div class="col-12 col-md-2 py-2">
										<cfif NOT isDefined("verbatimlatitude") ><cfset verbatimlatitude=""></cfif>
										<label for="verbatimlatitude" class="data-entry-label pr-md-3 pr-lg-0">Verbatim Latitude</label>
										<input type="text" name="verbatimlatitude" id="verbatimlatitude" class="data-entry-input" value="#encodeForHtml(verbatimlatitude)#">
									</div>
									<div class="col-12 col-md-2 py-2">
										<cfif NOT isDefined("verbatimlongigude") ><cfset verbatimlongigude=""></cfif>
										<label for="verbatimlongigude" class="data-entry-label">Verbatim Longitude</label>
										<input type="text" name="verbatimlongigude" id="verbatimlongigude" class="data-entry-input" value="#encodeForHtml(verbatimlongigude)#">
									</div>
									<div class="col-12 col-md-2 pt-md-4 pt-lg-2 py-2">
										<cfif NOT isDefined("valid_distribution_fg") ><cfset valid_distribution_fg=""></cfif>
										<label for="valid_distribution_fg" class="data-entry-label">Valid Distribution</label>
										<select name="valid_distribution_fg" id="valid_distribution_fg" size="1" class="data-entry-select">
											<cfif valid_distribution_fg EQ ""><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="" #selected#></option>
											<cfif valid_distribution_fg EQ "1"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="1" #selected#>Yes</option>
											<cfif valid_distribution_fg EQ "NULL"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="NULL" #selected#>NULL</option>
											<cfif valid_distribution_fg EQ "NOT NULL"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="NOT NULL" #selected#>NOT NULL</option>
										</select>
									</div>
									<div class="col-12 col-md-3 py-2">
										<cfif NOT isDefined("date_determined_by_agent") ><cfset date_determined_by_agent=""></cfif>
										<cfif NOT isDefined("date_determined_by_agent_id") ><cfset date_determined_by_agent_id=""></cfif>
										<label for="date_determined_by_agent" class="data-entry-label">Date Det. by</label>
										<input type="text" name="date_determined_by_agent" id="date_determined_by_agent" class="data-entry-input" value="#encodeForHtml(date_determined_by_agent)#">
										<input type="hidden" name="date_determined_by_agent_id" id="date_determined_by_agent_id" value="#encodeForHtml(date_determined_by_agent_id)#">
										<script>
											jQuery(document).ready(function() {
												makeConstrainedAgentPicker('date_determined_by_agent', 'date_determined_by_agent_id','ce_date_determiner');
											});
										</script>
									</div>
									<div class="col-12 col-md-3 py-2">
										<cfif NOT isDefined("collector_agent") ><cfset collector_agent=""></cfif>
										<cfif NOT isDefined("collector_agent_id") ><cfset collector_agent_id=""></cfif>
										<label for="collector_agent" class="data-entry-label">Specimen Collector</label>
										<input type="text" name="collector_agent" id="collector_agent" class="data-entry-input" value="#encodeForHtml(collector_agent)#">
										<input type="hidden" name="collector_agent_id" id="collector_agent_id" value="#encodeForHtml(collector_agent_id)#">
										<script>
											jQuery(document).ready(function() {
												makeConstrainedAgentPicker('collector_agent', 'collector_agent_id','collector');
											});
										</script>
									</div>
									<div class="col-12 col-md-3 px-3 px-md-2 py-1">
										<cfif not isDefined("collnEvOper")><cfset collnEvOper=""></cfif>
										<label for="collnEvOper" class="data-entry-label">Event Use</label>
										<select name="collnEvOper" id="collnEvOper" size="1" class="data-entry-select">
											<cfif len(collnEvOper) EQ 0><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="" #selected#></option>
											<cfif collnEvOper EQ "eventUsedOnlyBy"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="eventUsedOnlyBy" #selected#>used only by (pick collection above)</option>
											<cfif collnEvOper EQ "eventUsedBy"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="eventUsedBy" #selected#>used by (pick collection above)</option>
											<cfif collnEvOper EQ "eventSharedOnlyBy"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="eventSharedOnlyBy" #selected#>shared only including (pick collection above)</option>
										</select>
									</div>
								</cfif>
							</div>
						</div>
					</div>
				</div>
			</cfif>


		</div><!---End teal search-box class div--->
			
		<!---------------   Buttons ------------------------------------------------>
		<!--- Note: form that these buttons submit/reset must be provided by the enclosing page --->
		<div class="col-12 mt-0 px-0 mb-3"> 
			<div class="row mx-2 mb-3"> 
				<div class="col-12 col-md-5 col-lg-4 px-0 px-md-2 pt-3">
					<input type="submit" value="Search" aria-label="execute a search with the current search form parameters"
						class="btn btn-xs btn-primary px-2 px-xl-3 mx-1"  style="padding-top:.13rem;">
					<input type="reset" value="Reset Form" aria-label="reset form values to those on initial page load"
						class="btn btn-xs btn-warning ml-2" style="padding-top:.13rem;">
					<cfif len(newSearchTarget) GT 0>
						<button type="button" class="btn btn-xs btn-warning ml-2 my-1" style="padding-top:.13rem;" aria-label="Start a new search with a clear page" onclick="window.location.href='#Application.serverRootUrl##encodeForHTML(newSearchTarget)#';">New Search</button>
					</cfif>
				</div>
			
				<div class="col-12 col-md-2 px-0 px-md-2 pt-3">
					<div class="form-check">
						<cfif not isDefined("accentInsensitive")><cfset accentInsensitive = "1"></cfif>
						<cfif accentInsensitive EQ "1"><cfset checked = "checked"><cfelse><cfset checked=""></cfif>
						<input class="form-check-input" name="accentInsensitive" id="accentInsensitive" value="1" #checked# type="checkbox"/>
						<label class="form-check-label mt3px data-entry-label pt-md-1" for="accentInsenstive">Accent Insensitive?</label>
					</div>
				</div>
				<cfif showLocality is 1 AND showSpecimenCounts >
					<div class="col-12 col-md-3 px-0 px-md-2 pt-3">
						<cfif not isDefined("include_counts")><cfset include_counts = ""></cfif>
						<label for="include_counts" class="data-entry-label d-inline-block w-auto px-0">Include Specimen Counts?</label>
						<select name="include_counts" id="include_counts" class="data-entry-select w-auto d-inline-block">
							<cfif include_counts EQ "1">
								<cfset y_selected = "">
								<cfset n_selected = 'selected="selected"'>
							<cfelse>
								<cfset y_selected = 'selected="selected"'>
								<cfset n_selected = "">
							</cfif>
							<option #y_selected# value="0">No</option>
							<option #n_selected# value="1">Yes</option>
						</select>
					</div>
				</cfif>
				<cfif #showExtraFields# IS 1>
					<div class="col-12 col-md-2 px-0 px-md-2 pt-3">
						<cfif not isDefined("show_unused")><cfset show_unused = ""></cfif>
						<label for="show_unused" class="data-entry-label w-auto d-inline-block px-0">Unused</label>
						<select name="show_unused" id="show_unused" class="data-entry-select d-inline-block w-auto">
							<cfif show_unused EQ ""><cfset selected='selected="selected"'><cfelse><cfset selected=""></cfif>
							<option #selected# value="">Show All</option>
							<cfif show_unused EQ "unused_only"><cfset selected='selected="selected"'><cfelse><cfset selected=""></cfif>
							<option #selected# value="unused_only">Unused Only</option>
						</select>
					</div>
				</cfif>
			
			</div>
		</div>

		<script type="text/javascript" language="javascript">
			function toggleGeogDetail(onOff) {
				if (onOff==0) {
					$("##geogDetail").hide();
					$("##geogDetailCtl").attr('onCLick','toggleGeogDetail(1)').html('More Fields');
				} else {
					$("##geogDetail").show();
					$("##geogDetailCtl").attr('onCLick','toggleGeogDetail(0)').html('Fewer Fields');
				}
				<cfif isdefined("session.username") and len(#session.username#) gt 0>
					jQuery.getJSON("/localities/component/functions.cfc",
						{
							method : "saveLocSrchPref",
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
			function toggleLocDetail(onOff) {
				if (onOff==0) {
					$("##locDetail").hide();
					$("##locDetailCtl").attr('onCLick','toggleLocDetail(1)').html('More Fields');
				} else {
					$("##locDetail").show();
					$("##locDetailCtl").attr('onCLick','toggleLocDetail(0)').html('Fewer Fields');
				}
				<cfif isdefined("session.username") and len(#session.username#) gt 0>
					jQuery.getJSON("/localities/component/functions.cfc",
						{
							method : "saveLocSrchPref",
							id : 'LocDetail',
							onOff : onOff,
							returnformat : "json",
							queryformat : 'column'
						},
						function (data) { 
							console.log(data);
						}
					).fail(function(jqXHR,textStatus,error){
						handleFail(jqXHR,textStatus,error,"persisting LocDetail state");
					});
				</cfif>
			}
			function toggleGeorefDetail(onOff) {
				if (onOff==0) {
					$("##georefDetail").hide();
					$("##georefDetailCtl").attr('onCLick','toggleGeorefDetail(1)').html('Show Georef Fields');
				} else {
					$("##georefDetail").show();
					$("##georefDetailCtl").attr('onCLick','toggleGeorefDetail(0)').html('Hide Georef Fields');
				}
				<cfif isdefined("session.username") and len(#session.username#) gt 0>
					jQuery.getJSON("/localities/component/functions.cfc",
						{
							method : "saveLocSrchPref",
							id : 'GeorefDetail',
							onOff : onOff,
							returnformat : "json",
							queryformat : 'column'
						},
						function (data) { 
							console.log(data);
						}
					).fail(function(jqXHR,textStatus,error){
						handleFail(jqXHR,textStatus,error,"persisting GeorefDetail state");
					});
				</cfif>
			}
			function toggleEventDetail(onOff) {
				if (onOff==0) {
					$("##eventDetail").hide();
					$("##eventDetailCtl").attr('onCLick','toggleEventDetail(1)').html('More Fields');
				} else {
					$("##eventDetail").show();
					$("##eventDetailCtl").attr('onCLick','toggleEventDetail(0)').html('Fewer Fields');
				}
				<cfif isdefined("session.username") and len(#session.username#) gt 0>
					jQuery.getJSON("/localities/component/functions.cfc",
						{
							method : "saveLocSrchPref",
							id : 'EventDetail',
							onOff : onOff,
							returnformat : "json",
							queryformat : 'column'
						},
						function (data) { 
							console.log(data);
						}
					).fail(function(jqXHR,textStatus,error){
						handleFail(jqXHR,textStatus,error,"persisting EventDetail state");
					});
				</cfif>
			}
		</script>
	</div>
</cfoutput>
