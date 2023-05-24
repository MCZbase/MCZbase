<!---
localities/component/highergeog.cfc

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

Functions supporting editing higher geographies.

--->
<cfcomponent>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
<cf_rolecheck>

<cffunction name="getGeographyUsesHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="geog_auth_rec_id" type="string" required="yes">
	<cfargument name="containingDiv" type="string" required="yes">
	
	<cfset variables.containingDiv = arguments.containingDiv>
	<cfset variables.geog_auth_rec_id = arguments.geog_auth_rec_id>

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="geogUsesThread#tn#">
		<cfoutput>
			<cftry>
				<cfquery name="countUses" datasource="uam_god">
					SELECT
						count(*) ct
					FROM 
						locality
					WHERE
						geog_auth_rec_id=  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
				</cfquery>
				<cfif countUses.ct GT 0>
					<script>
						$(document).ready(function() { 
							$('###containingDiv#').addClass('bg-danger');
							$('###containingDiv#').addClass('text-light');
						});
					</script>
					<h2 class="h3 px-4">This higher geography record is in use.  Altering this record will update: </h2>
					<cfquery name="ceCount" datasource="uam_god">
						SELECT
							count(collecting_event_id) ct
						FROM 
							locality 
							join collecting_event on locality.locality_id = collecting_event.locality_id
						WHERE
							geog_auth_rec_id=  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
					</cfquery>
					<cfquery name="specCount" datasource="uam_god">
						SELECT
							count(collection_object_id) ct
						FROM 
							locality 
							join collecting_event on locality.locality_id = collecting_event.locality_id
							join cataloged_item on collecting_event.collecting_event_id = cataloged_item.collecting_event_id
						WHERE
							geog_auth_rec_id=  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
					</cfquery>
					<h3 class="h4 px-5">#countUses.ct# Localities, #ceCount.ct# Collecting Events, #specCount.ct# Cataloged Items</h3>
					<cfquery name="localityUses" datasource="uam_god">
						SELECT
							count(cataloged_item.cat_num) numOfSpecs,
							count(distinct collecting_event.collecting_event_id) numOfCollEvents,
							count(distinct locality.locality_id) numOfLocalities,
							collection.collection,
							collection.collection_cde,
							collection.collection_id
						from
							locality
							left join collecting_event on locality.locality_id = collecting_event.locality_id 
							left join cataloged_item on cataloged_item.collecting_event_id = collecting_event.collecting_event_id 
							left join collection on cataloged_item.collection_id = collection.collection_id
						WHERE
							locality.geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
						GROUP BY
							collection.collection,
							collection.collection_cde,
							collection.collection_id
					</cfquery>
					<div class="px-3">
						<ul class="mx-2">
							<cfloop query="localityUses">
								<li class="mx-2 small95"><cfif len(collection) gt 0>#collection# #numOfSpecs# specimens in <cfelse>No Specimens associated with </cfif> #numOfCollEvents# collecting events in #numOfLocalities# localities</li>
							</cfloop>
						</ul>
					</div>
				<cfelse>
					<h2 class="h3 px-2">This higher geography is not used in any localities.</h2>
				</cfif>
			<cfcatch>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="geogUsesThread#tn#" />

	<cfreturn cfthread["geogUsesThread#tn#"].output>
</cffunction>

<!--- given a geog_auth_rec_id, return the higher_geog string for the specified geog_auth_rec
  @param geog_auth_rec_id the primary key value for the higher geography to return.
  @return the higher_geog string for the specified geog_auth_rec.
--->
<cffunction name="getGeographySummary" returntype="string" access="remote" returnformat="plain">
	<cfargument name="geog_auth_rec_id" type="string" required="yes">
	
	<cfset retval = "">
	<cfquery name="lookupHigherGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="lookupHigherGeog_result">
		SELECT
			higher_geog
		FROM
			geog_auth_rec
		WHERE
			geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geog_auth_rec_id#">
	</cfquery>
	<cfloop query="lookupHigherGeog">
		<cfset retval = "#higher_geog#">
	</cfloop>
	<cfreturn retval>
</cffunction>
		


<!--- getHigherGeographyFormHtml returns html for a form to create a new geog_auth_rec 
  record or to edit an existing geog_auth_rec record.

@param mode if new will produce a new higher geography form, optionaly loading cloned data from
 a specified higher geography, if edit will 
@param clone_from_geog_auth_rec_id applies to mode=new, populate the form with data from the 
 specified record.
@param geog_auth_rec_id applies to mode=edit the primary key value for the higher geography to edit.
@param formId applies to mode=edit the id in the dom for the form that encloses the inputs returned from this function.
@param outputDiv applies to mode=edit the id in the dom for an output element where feedback from form submission actions 
  is placed.
@param saveButtonFunction applies to mode=edit the name of a javascript function that is to be invoked when the save
  button is clicked, just the name without trailing parenthesies.
--->
<cffunction name="getHigherGeographyFormHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="mode" type="string" required="yes">
	<cfargument name="clone_from_geog_auth_rec_id" type="string" required="no" default="">
	<cfargument name="geog_auth_rec_id" type="string" required="no" default="">
	<cfargument name="formId" type="string" required="no" default="">
	<cfargument name="outputDiv" type="string" required="no" default="">
	<cfargument name="saveButtonFunction" type="string" required="no" default="">

	<cfif mode EQ "new">
		<!--- optional parameter to clone from --->
		<cfset variables.clone_from_geog_auth_rec_id = arguments.clone_from_geog_auth_rec_id>
	<cfelseif mode EQ "edit">
		<cfif not isDefined("geog_auth_rec_id") or len(geog_auth_rec_id) EQ 0>
			<cfthrow message="geog_auth_rec_id is a required parameter, you must specify the higher geography to edit.">
		</cfif>
		<cfif not isDefined("formId") or len(formId) EQ 0><cfthrow message="formId is a required parameter"></cfif>
		<cfif not isDefined("outputDiv") or len(outputDiv) EQ 0><cfthrow message="outputDiv is a required parameter"></cfif>
		<cfif not isDefined("saveButtonFunction") or len(saveButtonFunction) EQ 0><cfthrow message="saveButtonFunction is a required parameter"></cfif>
		<cfset variables.geog_auth_rec_id = arguments.geog_auth_rec_id>
		<cfset variables.formId = arguments.formId>
		<cfset variables.outputDiv = arguments.outputDiv>
		<cfset variables.saveButtonFunction = arguments.saveButtonFunction>
	<cfelse>
		<cfthrow message="unknown mode [#encodeForHtml(mode)#] allowed values are new and edit">
	</cfif>
	<cfset variables.mode = arguments.mode>

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="editCreateGeogFormThread#tn#">
		<cfoutput>
			<cftry>
				<cfquery name="ctguid_type_highergeography" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT guid_type, placeholder, pattern_regex, resolver_regex, resolver_replacement, search_uri
				   FROM ctguid_type
				   WHERE applies_to like '%geog_auth_rec.highergeographyid%'
				</cfquery>
				<cfif isdefined('clone_from_geog_auth_rec_id') AND len(clone_from_geog_auth_rec_id) GT 0>
					<cfquery name="lookupHigherGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT 
							higher_geog, 
							continent_ocean,
							ocean_region, ocean_subregion, sea, water_feature,
							country, state_prov, county,
							quad, feature,
							island_group, island,
							valid_catalog_term_fg, source_authority, 
							wkt_polygon,
							highergeographyid, highergeographyid_guid_type
						FROM geog_auth_rec
						WHERE 
							geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#clone_from_geog_auth_rec_id#">
					</cfquery>
					<cfloop query="lookupHigherGeog">
						<cfset higher_geog = "#lookupHigherGeog.higher_geog#">
						<cfset continent_ocean = "#lookupHigherGeog.continent_ocean#">
						<cfset continent_ocean = "#lookupHigherGeog.continent_ocean#">
						<cfset ocean_region  = "#lookupHigherGeog.ocean_region #">
						<cfset ocean_subregion  = "#lookupHigherGeog.ocean_subregion #">
						<cfset sea  = "#lookupHigherGeog.sea #">
						<cfset water_feature = "#lookupHigherGeog.water_feature#">
						<cfset country  = "#lookupHigherGeog.country #">
						<cfset state_prov  = "#lookupHigherGeog.state_prov #">
						<cfset county = "#lookupHigherGeog.county#">
						<cfset quad  = "#lookupHigherGeog.quad #">
						<cfset feature = "#lookupHigherGeog.feature#">
						<cfset island_group  = "#lookupHigherGeog.island_group #">
						<cfset island = "#lookupHigherGeog.island#">
						<cfset valid_catalog_term_fg  = "#lookupHigherGeog.valid_catalog_term_fg #">
						<cfset source_authority  = "#lookupHigherGeog.source_authority #">
						<cfset wkt_polygon = "#lookupHigherGeog.wkt_polygon#">
					</cfloop>
				<cfelseif mode EQ "edit">
					<cfquery name="lookupHigherGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT 
							geog_auth_rec_id,
							higher_geog, 
							continent_ocean,
							ocean_region, ocean_subregion, sea, water_feature,
							country, state_prov, county,
							quad, feature,
							island_group, island,
							valid_catalog_term_fg, source_authority, 
							wkt_polygon,
							highergeographyid, highergeographyid_guid_type
						FROM geog_auth_rec
						WHERE 
							geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
					</cfquery>
					<cfloop query="lookupHigherGeog">
						<cfset higher_geog = "#lookupHigherGeog.higher_geog#">
						<cfset continent_ocean = "#lookupHigherGeog.continent_ocean#">
						<cfset continent_ocean = "#lookupHigherGeog.continent_ocean#">
						<cfset ocean_region  = "#lookupHigherGeog.ocean_region#">
						<cfset ocean_subregion  = "#lookupHigherGeog.ocean_subregion#">
						<cfset sea  = "#lookupHigherGeog.sea#">
						<cfset water_feature = "#lookupHigherGeog.water_feature#">
						<cfset country  = "#lookupHigherGeog.country#">
						<cfset state_prov  = "#lookupHigherGeog.state_prov#">
						<cfset county = "#lookupHigherGeog.county#">
						<cfset quad  = "#lookupHigherGeog.quad#">
						<cfset feature = "#lookupHigherGeog.feature#">
						<cfset island_group  = "#lookupHigherGeog.island_group#">
						<cfset island = "#lookupHigherGeog.island#">
						<cfset valid_catalog_term_fg  = "#lookupHigherGeog.valid_catalog_term_fg#">
						<cfset source_authority  = "#lookupHigherGeog.source_authority#">
						<cfset wkt_polygon = "#lookupHigherGeog.wkt_polygon#">
					</cfloop>
				</cfif>
				<cfif mode EQ "edit">
					<input type="hidden" name="geog_auth_rec_id" value="#lookupHigherGeog.geog_auth_rec_id#">
				</cfif>
				<div class="form-row mx-0 pt-1 mb-0">
					<div class="col-12 col-md-3 mb-2">
						<label class="data-entry-label" for="continent_ocean">Continent/Ocean</label>
						<cfif NOT isdefined("continent_ocean")><cfset continent_ocean=""></cfif>
						<input type="text" name="continent_ocean" id="continent_ocean" class="data-entry-input" value="#encodeForHTML(continent_ocean)#">
						<script>
							$(document).ready(() => makeCTAutocomplete('continent_ocean','continent_ocean') );
						</script>
					</div>
					<div class="col-12 col-md-3 mb-2">
						<label class="data-entry-label" for="ocean_region">Ocean Region</label>
						<cfif NOT isdefined("ocean_region")><cfset ocean_region=""></cfif>
						<input type="text" name="ocean_region" id="ocean_region" class="data-entry-input" value="#encodeForHTML(ocean_region)#">
						<script>
							$(document).ready(() => makeCTAutocomplete('ocean_region','ocean_region') );
						</script>
					</div>
					<div class="col-12 col-md-3 mb-2">
						<label class="data-entry-label" for="ocean_subregion">Ocean Subregion</label>
						<cfif NOT isdefined("ocean_subregion")><cfset ocean_subregion=""></cfif>
						<input type="text" name="ocean_subregion" id="ocean_subregion" class="data-entry-input" value="#encodeForHTML(ocean_subregion)#">
						<script>
							$(document).ready(() => makeGeogAutocomplete('ocean_subregion','ocean_subregion'));
						</script>
						<cfif mode EQ "new">
							<script>
								// if empty, and unique, fill in higher terms from value of ocean_subregion
								$(document).ready(function() { 
									$('##ocean_subregion').on('change',lookupAboveOceanSubregion);
								});
								function lookupAboveOceanSubregion() { 
								$.ajax({
									url: "/localities/component/search.cfc",
									data : {
										method : "getHigherTermsForOceanSubregion",
										ocean_subregion: $('##ocean_subregion').val()
									},
									success: function (result) {
										console.log(result);
										if ($('##continent_ocean').val()=="" && $('##ocean_region').val()=="") {
											$('##continent_ocean').val(result[0].continent_ocean);
											$('##ocean_region').val(result[0].ocean_region);
										}
									},
									error: function (jqXHR, textStatus, error) {
										handleFail(jqXHR,textStatus,error,"loading higher geography for ocean_subregion");
									},
									dataType: "json"
								});
								}
							</script>
						</cfif>
					</div>
					<div class="col-12 col-md-3 mb-2">
						<label class="data-entry-label" for="sea">Sea</label>
						<cfif NOT isdefined("sea")><cfset sea=""></cfif>
						<input type="text" name="sea" id="sea" class="data-entry-input" value="#encodeForHTML(sea)#">
						<script>
							$(document).ready(() => makeGeogAutocomplete('sea','sea'));
						</script>
					</div>
					<div class="col-12 col-md-3 mb-2">
						<label class="data-entry-label" for="water_feature">Water Feature</label>
						<cfif NOT isdefined("water_feature")><cfset water_feature=""></cfif>
						<input type="text" name="water_feature" id="water_feature" class="data-entry-input" value="#encodeForHTML(water_feature)#">
						<script>
							$(document).ready(() => makeCTAutocomplete('water_feature','water_feature') );
						</script>
					</div>
					<div class="col-12 col-md-3 mb-2">
						<label class="data-entry-label" for="country">Country</label>
						<cfif NOT isdefined("country")><cfset country=""></cfif>
						<input type="text" name="country" id="country" class="data-entry-input" value="#encodeForHTML(country)#">
						<script>
							$(document).ready(() => makeGeogAutocomplete('country','country'));
						</script>
					</div>
					<div class="col-12 col-md-3 mb-2">
						<label class="data-entry-label" for="state_prov">State/Province</label>
						<cfif NOT isdefined("state_prov")><cfset state_prov=""></cfif>
						<input type="text" name="state_prov" id="state_prov" class="data-entry-input" value="#encodeForHTML(state_prov)#">
						<script>
							$(document).ready(() => makeGeogAutocomplete('state_prov','state_prov'));
						</script>
						<cfif mode EQ "new">
							<script>
								// if empty, and unique, fill in higher terms from value of state_prov
								$(document).ready(function() { 
									$('##state_prov').on('change',lookupAboveStateProv);
								});
								function lookupAboveStateProv() { 
								$.ajax({
									url: "/localities/component/search.cfc",
									data : {
										method : "getHigherTermsForStateProv",
										state_prov: $('##state_prov').val()
									},
									success: function (result) {
										console.log(result);
										if ($('##continent_ocean').val()=="" && $('##country').val()=="") {
											$('##continent_ocean').val(result[0].continent_ocean);
											$('##country').val(result[0].country);
										}
									},
									error: function (jqXHR, textStatus, error) {
										handleFail(jqXHR,textStatus,error,"loading higher geography for state_prov");
									},
									dataType: "json"
								});
								}
							</script>
						</cfif>
					</div>
					<div class="col-12 col-md-3 mb-2">
						<label class="data-entry-label" for="county">County</label>
						<cfif NOT isdefined("county")><cfset county=""></cfif>
						<input type="text" name="county" id="county" class="data-entry-input" value="#encodeForHTML(county)#">
						<script>
							$(document).ready(() => makeGeogAutocomplete('county','county'));
						</script>
						<cfif mode EQ "new">
							<script>
								// if empty, and unique, fill in higher terms from value of county
								$(document).ready(function() { 
									$('##county').on('change',lookupAboveCounty);
								});
								function lookupAboveCounty() { 
								$.ajax({
									url: "/localities/component/search.cfc",
									data : {
										method : "getHigherTermsForCounty",
										county: $('##county').val()
									},
									success: function (result) {
										console.log(result);
										if ($('##continent_ocean').val()=="" && $('##country').val()=="" && $('##state_prov').val()=="") {
											$('##continent_ocean').val(result[0].continent_ocean);
											$('##country').val(result[0].country);
											$('##state_prov').val(result[0].state_prov);
										}
									},
									error: function (jqXHR, textStatus, error) {
										handleFail(jqXHR,textStatus,error,"loading higher geography for county");
									},
									dataType: "json"
								});
								}
							</script>
						</cfif>
					</div>
					<div class="col-12 col-md-3 mb-2">
						<label class="data-entry-label" for="quad">Quadrangle</label>
						<cfif NOT isdefined("quad")><cfset quad=""></cfif>
						<input type="text" name="quad" id="quad" class="data-entry-input" value="#encodeForHTML(quad)#">
						<script>
							$(document).ready(() => makeGeogAutocomplete('quad','quad'));
						</script>
					</div>
					<div class="col-12 col-md-3 mb-2">
						<label class="data-entry-label" for="feature">Feature</label>
						<cfif NOT isdefined("feature")><cfset feature=""></cfif>
						<input type="text" name="feature" id="feature" class="data-entry-input" value="#encodeForHTML(feature)#">
						<script>
							$(document).ready(() => makeCTAutocomplete('feature','feature'));
						</script>
					</div>
					<div class="col-12 col-md-3 mb-2">
						<label class="data-entry-label" for="island_group">Island Group</label>
						<cfif NOT isdefined("island_group")><cfset island_group=""></cfif>
						<input type="text" name="island_group" id="island_group" class="data-entry-input" value="#encodeForHTML(island_group)#">
						<script>
							$(document).ready(() => makeCTAutocomplete('island_group','island_group'));
						</script>
					</div>
					<div class="col-12 col-md-3 mb-2">
						<label class="data-entry-label" for="island">Island</label>
						<cfif NOT isdefined("island")><cfset island=""></cfif>
						<input type="text" name="island" id="island" class="data-entry-input" value="#encodeForHTML(island)#">
						<script>
							$(document).ready(() => makeGeogAutocomplete('island','island'));
						</script>
					</div>
					<div class="col-12 col-xl-6 mb-2">
						<cfif NOT isdefined("wkt_polygon")><cfset wkt_polygon=""></cfif>
						<cfif len(wkt_polygon) GT 0><cfset labelText = " (Present)"><cfelse><cfset labelText=""></cfif>
						<label for = "wktPolygon" class="data-entry-label">Polygon#labelText#</label>
						<input type="text" name="wkt_polygon" value=""id="wktPolygon" class="data-entry-input">
					</div>
					<div class="col-12 col-xl-6 mb-2">
						<label for="wktFile" class="data-entry-label mb1px">Load Polygon from WKT file</label>
						<input type="file" id="wktFile" name="wktFile" accept=".wkt" class="w-100 p-0 data-entry-input">
						<script>
							$(document).ready(function() { 
								$("##wktFile").change(loadWKTFromFile);
							});
							function loadWKTFromFile() { 
								loadPolygonWKTFromFile('wktFile', 'wktPolygon', 'wktLoadFeedback');
							}
						</script>
					</div>
					<div class="col-12 col-xl-6 mb-2">
						<output id="wktLoadFeedback"></output>
					</div>
					<div class="col-12 col-md-3 mb-2">
						<label for="valid_catalog_term_fg" class="data-entry-label">Valid for data entry?</label>
						<select name="valid_catalog_term_fg" id="valid_catalog_term_fg" class="data-entry-select reqdClr">
							<cfif not isDefined("valid_calalog_term_fg") OR len(valid_catalog_term_fg) EQ 0 OR valid_catalog_term_fg is "1"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="1" #selected#>Yes</option>
							<cfif isDefined("valid_calalog_term_fg") AND valid_catalog_term_fg EQ "0"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="0" #selected#>No</option>
						</select>
					</div>
					<div class="col-12 col-md-3 mb-2">
						<label class="data-entry-label" for="source_authority">Source Authority</label>
						<cfif NOT isdefined("source_authority")><cfset source_authority=""></cfif>
						<input type="text" name="source_authority" id="source_authority" class="data-entry-input reqdClr" value="#encodeForHTML(source_authority)#" required>
						<script>
							$(document).ready(() => makeGeogAutocomplete('source_authority','source_authority'));
						</script>
					</div>
				</div>
				<div class="form-row mx-1 px-1 border rounded pt-2 my-2">
					<div class="col-12 col-md-5" >
						<label for="highergeographyid" class="data-entry-label mb1px">Authority for GUID for Higher Geography</label>
						<cfset pattern = "">
						<cfset placeholder = "">
						<cfset regex = "">
						<cfset replacement = "">
						<cfset searchlink = "" >
						<cfset searchtext = "" >
						<cfset searchclass = "" >
						<cfloop query="ctguid_type_highergeography">
							<cfif (isDefined("lookupHigherGeog") AND lookupHigherGeog.highergeographyid_guid_type is ctguid_type_highergeography.guid_type) OR ctguid_type_highergeography.recordcount EQ 1 >
								<cfset searchlink = ctguid_type_highergeography.search_uri & lookupHigherGeog.higher_geog >
								<cfif len(lookupHigherGeog.highergeographyid) GT 0>
									<cfset searchtext = "Edit" >
									<cfset searchclass = 'class="btn btn-xs btn-secondary editGuidButton"' >
								<cfelse>
									<cfset searchtext = "Find GUID" >
									<cfset searchclass = 'class="btn btn-xs btn-secondary findGuidButton external"' >
								</cfif>
							</cfif>
						</cfloop>
						<select name="highergeographyid_guid_type" id="highergeographyid_guid_type" class="data-entry-select">
							<cfif searchtext EQ "">
								<option value=""></option>
							</cfif>
							<cfloop query="ctguid_type_highergeography">
								<cfset sel="">
			 						<cfif (isDefined("lookupHigherGeog") AND lookupHigherGeog.highergeographyid_guid_type is ctguid_type_highergeography.guid_type) OR ctguid_type_highergeography.recordcount EQ 1 >
										<cfset sel="selected='selected'">
										<cfset placeholder = "#ctguid_type_highergeography.placeholder#">
										<cfset pattern = "#ctguid_type_highergeography.pattern_regex#">
										<cfset regex = "#ctguid_type_highergeography.resolver_regex#">
										<cfset replacement = "#ctguid_type_highergeography.resolver_replacement#">
									</cfif>
								<option #sel# value="#ctguid_type_highergeography.guid_type#">#ctguid_type_highergeography.guid_type#</option>
							</cfloop>
						</select>
					</div>
					<div class="col-12 col-md-auto">
						<label for="highergeographyid" class="data-entry-label">Action</label>
						<a href="#searchlink#" id="highergeographyid_search" target="_blank" #searchclass# >#searchtext#</a>
					</div>
					<div class="col-12 col-md-5">
						<label class="data-entry-label mb1px">dwc:highergeographyID</label>
						<cfif isDefined("lookupHigherGeog")><cfset hgeogid = lookupHigherGeog.highergeographyid><cfelse><cfset hgeogid=""></cfif>
						<cfif NOT isDefined("regex")><cfset regex=""></cfif>
						<input name="highergeographyid" id="highergeographyid" value="#hgeogid#" placeholder="#placeholder#" pattern="#pattern#" title="Enter a guid in the form #placeholder#" class="data-entry-input">
						<cfif len(regex) GT 0 >
							<cfset link = REReplace(hgeogid,regex,replacement)>
						<cfelse>
							<cfset link = hgeogid>
						</cfif>
						<a id="highergeographyid_link" href="#link#" target="_blank" class="pl-1 mt3px pr-5 pb-1 hints small95">#hgeogid#</a>
						<script>
							$(document).ready(function () {
								if ($('##highergeographyid').val().length > 0) {
									$('##highergeographyid').hide();
								}
								$('##highergeographyid_search').click(function (evt) {
									switchGuidEditToFind('highergeographyid','highergeographyid_search','highergeographyid_link',evt);
								});
								$('##highergeographyid_guid_type').change(function () {
									// On selecting a guid_type, remove an existing guid value.
									$('##highergeographyid').val("");
									$('##highergeographyid').show();
									// On selecting a guid_type, change the pattern.
									getGuidTypeInfo($('##highergeographyid_guid_type').val(), 'highergeographyid', 'highergeographyid_link','highergeographyid_search',getLowestGeography());
								});
								$('##highergeographyid').blur( function () {
									// On loss of focus for input, validate against the regex, update link
									getGuidTypeInfo($('##highergeographyid_guid_type').val(), 'highergeographyid', 'highergeographyid_link','highergeographyid_search',getLowestGeography());
								});
								$('.geoginput').change(function () {
									// On changing any geography input field name, update search.
									getGuidTypeInfo($('##highergeographyid_guid_type').val(), 'highergeographyid', 'highergeographyid_link','highergeographyid_search',getLowestGeography());
								});
							});
						</script>
					</div>
				</div>
				<div class="form-row my-1 mx-0">
					<div class="col-12 mt-1">
						<cfif mode EQ "new">
							<input type="submit" value="Save" class="btn btn-xs btn-primary">
						<cfelseif mode EQ "edit">
							<input type="button" value="Save" class="btn btn-xs btn-primary mr-2"
								onClick="if (checkFormValidity($('###formId#')[0])) { #saveButtonFunction#();  } " 
								id="submitButton" >
							<output id="#outputDiv#" class="text-danger">&nbsp;</output>
						</cfif>
					</div>
				</div>
				<cfif mode EQ "edit">
					<script>
						function handleChange(){
							$('###outputDiv#').html('Unsaved changes.');
							$('###outputDiv#').addClass('text-danger');
							$('###outputDiv#').removeClass('text-success');
							$('###outputDiv#').removeClass('text-secondary');
						};
						$(document).ready(function() {
							monitorForChangesGeneric('#formId#',handleChange);
						});
					</script>
				</cfif>
			<cfcatch>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="editCreateGeogFormThread#tn#" />

	<cfreturn cfthread["editCreateGeogFormThread#tn#"].output>

</cffunction>

<!--- function updateHigherGeography update a geog_auth_red
  @param geog_auth_rec_id the pk of the higher geography to update 
  @return json structure with status=updated and id=geog_auth_rec_id of the geog_auth_red, 
   or http 500 status on an error.
--->
<cffunction name="updateHigherGeography" access="remote" returntype="any" returnformat="json">
	<cfargument name="geog_auth_rec_id" type="string" required="no">
	<cfargument name="valid_catalog_term_fg" type="string" required="yes">
	<cfargument name="source_authority" type="string" required="yes">
	<cfargument name="continent_ocean" type="string" required="no">
	<cfargument name="country" type="string" required="no">
	<cfargument name="state_prov" type="string" required="no">
	<cfargument name="county" type="string" required="no">
	<cfargument name="quad" type="string" required="no">
	<cfargument name="feature" type="string" required="no">
	<cfargument name="ocean_region" type="string" required="no">
	<cfargument name="ocean_subregion" type="string" required="no">
	<cfargument name="sea" type="string" required="no">
	<cfargument name="water_feature" type="string" required="no">
	<cfargument name="island_group" type="string" required="no">
	<cfargument name="island" type="string" required="no">
	<cfargument name="wkt_polygon" type="string" required="no">
	<cfargument name="highergeographyid_guid_type" type="string" required="no">
	<cfargument name="highergeographyid" type="string" required="no">

	<cfset data = ArrayNew(1)>

	<cftransaction>
		<cftry>
			<cfquery name="updateGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateGeog_result">
				UPDATE geog_auth_rec SET
				valid_catalog_term_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#valid_catalog_term_fg#">,
				source_authority = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#source_authority#">,
				<cfif len(#continent_ocean#) GT 0>
					continent_ocean = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#continent_ocean#">,
				<cfelse>
					continent_ocean = null,
				</cfif>
				<cfif len(#country#) GT 0>
					country = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#country#">,
				<cfelse>
					country = null,
				</cfif>
				<cfif len(#state_prov#) GT 0>
					state_prov = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#state_prov#">,
				<cfelse>
					state_prov = null,
				</cfif>
				<cfif len(#county#) GT 0>
					county = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#county#">,
				<cfelse>
					county = null,
				</cfif>
				<cfif len(#quad#) GT 0>
					quad = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#quad#">,
				<cfelse>
					quad = null,
				</cfif>
				<cfif len(#feature#) GT 0>
					feature = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#feature#">,
				<cfelse>
					feature = null,
				</cfif>
				<cfif len(#ocean_region#) GT 0>
					ocean_region = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ocean_region#">,
				<cfelse>
					ocean_region = null,
				</cfif>
				<cfif len(#ocean_subregion#) GT 0>
					ocean_subregion = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ocean_subregion#">,
				<cfelse>
					ocean_subregion = null,
				</cfif>
				<cfif len(#sea#) GT 0>
					sea = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#sea#">,
				<cfelse>
					sea = null,
				</cfif>
				<cfif len(#water_feature#) GT 0>
					water_feature = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#water_feature#">,
				<cfelse>
					water_feature = null,
				</cfif>
				<cfif len(#island_group#) GT 0>
					island_group = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#island_group#">,
				<cfelse>
					island_group = null,
				</cfif>
				<cfif len(#island#) GT 0>
					island = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#island#">,
				<cfelse>
					island = null,
				</cfif>
				<cfif len(#wkt_polygon#) GT 0>
					wkt_polygon = <cfqueryparam cfsqltype="CF_SQL_CLOB" value="#wkt_polygon#">,
				</cfif>
				<cfif len(#highergeographyid_guid_type#) GT 0>
					highergeographyid_guid_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#highergeographyid_guid_type#">,
				<cfelse>
					highergeographyid_guid_type = null,
				</cfif>
				<cfif len(#highergeographyid#) GT 0>
					highergeographyid = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#highergeographyid#">
				<cfelse>
					highergeographyid = null
				</cfif>
				WHERE 
					geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
			</cfquery>

			<cfset row = StructNew()>
			<cfset row["status"] = "updated">
			<cfset row["id"] = "#encodeForHtml(geog_auth_rec_id)#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>
</cfcomponent>
