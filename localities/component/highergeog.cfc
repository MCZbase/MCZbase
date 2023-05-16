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
				<h2 class="h3">Used for #countUses.ct# Localities</h3>
		
				TODO: Implement.

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
		

<!--- getEditGeographyHtml returns html for a form to edit an existing geog_auth_rec record 

@param geog_auth_rec_id_id the primary key value for the higher geography to edit.
@param formId the id in the dom for the form that encloses the inputs returned from this function.
@param outputDiv the id in the dom for an output element where feedback from form submission actions 
  is placed.
@param saveButtonFunction the name of a javascript function that is to be invoked when the save
  button is clicked, just the name without trailing parenthesies.
--->
<cffunction name="getEditGeographyHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="geog_auth_rec_id" type="string" required="yes">
	<cfargument name="formId" type="string" required="yes">
	<cfargument name="outputDiv" type="string" required="yes">
	<cfargument name="saveButtonFunction" type="string" required="yes">

	<cfset variables.formId = arguments.formId>
	<cfset variables.outputDiv = arguments.outputDiv>
	<cfset variables.saveButtonFunction = arguments.saveButtonFunction>
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="editGeogFormThread#tn#">
		<cfoutput>
			<cftry>
				<div class="form-row mx-0 mb-0">
				
					TODO: Implement

					<div class="col-12 mt-1">
						<input type="button" value="Save" class="btn btn-xs btn-primary mr-2"
							onClick="if (checkFormValidity($('###formId#')[0])) { #saveButtonFunction#();  } " 
							id="submitButton" >
						<output id="#outputDiv#" class="text-danger">&nbsp;</output>	
					</div>
				</div>

				<script>
					function handleChange(){
						$('###outputDiv#').html('Unsaved changes.');
						$('###outputDiv#').addClass('text-danger');
						$('###outputDiv#').removeClass('text-success');
						$('###outputDiv#').removeClass('text-warning');
					};
					$(document).ready(function() {
						monitorForChangesGeneric('#formId#',handleChange);
					});
				</script>
			<cfcatch>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="editGeogFormThread#tn#" />

	<cfreturn cfthread["editGeogFormThread#tn#"].output>
</cffunction>


<cffunction name="getCreateHigherGeographyHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="clone_from_geog_auth_rec_id" type="string" required="no">
	<cfargument name="geog_auth_rec_id" type="string" required="no">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="createGeogFormThread#tn#">
		<cfoutput>
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
						ocean_region, ocean_subregion, sea, water_feature
						country, state_province, county,
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
				</cfloop>
			</cfif>
			<div class="form-row mx-0 mb-0">
				<div class="col-12 col-md-3">
					<label class="data-entry-label" for="continent_ocean">Continent/Ocean</label>
					<cfif NOT isdefined("continent_ocean")><cfset continent_ocean=""></cfif>
					<input type="text" name="continent_ocean" id="continent_ocean" class="data-entry-input" value="#encodeForHTML(continent_ocean)#" required>
					<script>
						$(document).ready(() => makeCTAutocomplete('continent_ocean','continentocean') );
					</script>
				</div>
				<div class="col-12 col-md-3">
					<label class="data-entry-label" for="ocean_region">Ocean Region</label>
					<cfif NOT isdefined("ocean_region")><cfset ocean_region=""></cfif>
					<input type="text" name="ocean_region" id="ocean_region" class="data-entry-input" value="#encodeForHTML(ocean_region)#" required>
					<script>
						$(document).ready(() => makeCTAutocomplete('ocean_region','ocean_region') );
					</script>
				</div>
				<div class="col-12 col-md-3">
					<label class="data-entry-label" for="ocean_subregion">Ocean Subregion</label>
					<cfif NOT isdefined("ocean_subregion")><cfset ocean_subregion=""></cfif>
					<input type="text" name="ocean_subregion" id="ocean_subregion" class="data-entry-input" value="#encodeForHTML(ocean_subregion)#" required>
					<script>
						$(document).ready(() => makeGeogAutocomplete('ocean_subregion','ocean_subregion'));
					</script>
				</div>
				<div class="col-12 col-md-3">
					<label class="data-entry-label" for="water_feature">Water Feature</label>
					<cfif NOT isdefined("water_feature")><cfset water_feature=""></cfif>
					<input type="text" name="water_feature" id="water_feature" class="data-entry-input" value="#encodeForHTML(water_feature)#" required>
					<script>
						$(document).ready(() => makeCTAutocomplete('water_feature','water_feature') );
					</script>
				</div>
				<div class="col-12 col-md-3">
					<label class="data-entry-label" for="sea">Sea</label>
					<cfif NOT isdefined("sea")><cfset sea=""></cfif>
					<input type="text" name="sea" id="sea" class="data-entry-input" value="#encodeForHTML(sea)#" required>
					<script>
						$(document).ready(() => makeGeogAutocomplete('sea','sea'));
					</script>
				</div>
				<div class="col-12 col-md-3">
					<label class="data-entry-label" for="country">Country</label>
					<cfif NOT isdefined("country")><cfset country=""></cfif>
					<input type="text" name="country" id="country" class="data-entry-input" value="#encodeForHTML(country)#" required>
					<script>
						$(document).ready(() => makeGeogAutocomplete('country','country'));
					</script>
				</div>
				<div class="col-12 col-md-3">
					<label class="data-entry-label" for="state_province">State/Province</label>
					<cfif NOT isdefined("state_province")><cfset state_province=""></cfif>
					<input type="text" name="state_province" id="state_province" class="data-entry-input" value="#encodeForHTML(state_province)#" required>
					<script>
						$(document).ready(() => makeGeogAutocomplete('state_province','state_province'));
					</script>
				</div>
				<div class="col-12 col-md-3">
					<label class="data-entry-label" for="county">County</label>
					<cfif NOT isdefined("county")><cfset county=""></cfif>
					<input type="text" name="county" id="county" class="data-entry-input" value="#encodeForHTML(county)#" required>
					<script>
						$(document).ready(() => makeGeogAutocomplete('county','county'));
					</script>
				</div>
				<div class="col-12 col-md-3">
					<label class="data-entry-label" for="quad">Quadrangle</label>
					<cfif NOT isdefined("quad")><cfset quad=""></cfif>
					<input type="text" name="quad" id="quad" class="data-entry-input" value="#encodeForHTML(quad)#" required>
					<script>
						$(document).ready(() => makeGeogAutocomplete('quad','quad'));
					</script>
				</div>
				<div class="col-12 col-md-3">
					<label class="data-entry-label" for="feature">Feature</label>
					<cfif NOT isdefined("feature")><cfset feature=""></cfif>
					<input type="text" name="feature" id="feature" class="data-entry-input" value="#encodeForHTML(feature)#" required>
					<script>
						$(document).ready(() => makeCTAutocomplete('feature','feature'));
					</script>
				</div>
				<div class="col-12 col-md-3">
					<label class="data-entry-label" for="island_group">Island Group</label>
					<cfif NOT isdefined("island_group")><cfset island_group=""></cfif>
					<input type="text" name="island_group" id="island_group" class="data-entry-input" value="#encodeForHTML(island_group)#" required>
					<script>
						$(document).ready(() => makeCTAutocomplete('island_group','island_group'));
					</script>
				</div>
				<div class="col-12 col-md-3">
					<label class="data-entry-label" for="island">Island</label>
					<cfif NOT isdefined("island")><cfset island=""></cfif>
					<input type="text" name="island" id="island" class="data-entry-input" value="#encodeForHTML(island)#" required>
					<script>
						$(document).ready(() => makeGeogAutocomplete('island','island'));
					</script>
				</div>
			
				<div class="col-12 col-md-6">
					<label for = "wktPolygon" class="data-entry-label">Polygon<label>
					<input type="text" name="wktPolygon" value="#wkt_polygon#" id = "wktPolygon" class="data-entry-input">
				</div>
				<div class="col-12 col-md-3">
					<label for="wktFile" class="data-entry-label">Load Polygon from WKT file</label>
					<input type="file" id="wktFile" name="wktFile" accept=".wkt" >
					<script>
						$(document).ready(function() { 
							$("##wktFile").change(loadWKTFromFile);
						});
						function loadWKTFromFile() { 
							loadPolygonWKTFromFile('wktFile', 'wktPolygon', 'wktLoadFeedback');
						}
					</script>
				</div>
				<div class="col-12 col-md-3">
					<output id="wktLoadFeedback"></output>
				</div>

				<div class="col-12 col-md-3">
					<label for="valid_catalog_term_fg" class="data-entry-label">Valid for data entry?</label>
					<select name="valid_catalog_term_fg" id="valid_catalog_term_fg" class="reqdClr">
						<cfif not isDefined("valid_calalog_term_fg") OR len(valid_catalog_term_fg) EQ 0 OR valid_catalog_term_fg is "1"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
						<option value="1" #selected#>Yes</option>
						<cfif isDefined("valid_calalog_term_fg") AND valid_catalog_term_fg EQ "0"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
						<option value="0" #selected#>No</option>
					</select>
				</div>
				<div class="col-12 col-md-3">
					<label class="data-entry-label" for="source_authority">Source Authority</label>
					<cfif NOT isdefined("source_authority")><cfset source_authority=""></cfif>
					<input type="text" name="source_authority" id="source_authority" class="data-entry-input" value="#encodeForHTML(source_authority)#" required>
					<script>
						$(document).ready(() => makeGeogAutocomplete('source_authority','source_authority'));
					</script>
				</div>
				<div class="col-12 col-md-4">
					<label for="highergeographyid" class="data-entry-label">GUID for Higher Geography(dwc:highergeographyID)</label>
					<cfset pattern = "">
					<cfset placeholder = "">
					<cfset regex = "">
					<cfset replacement = "">
					<cfset searchlink = "" >
					<cfset searchtext = "" >
					<cfset searchclass = "" >
					<cfloop query="ctguid_type_highergeography">
						<cfif lookupHigherGeog.highergeographyid_guid_type is ctguid_type_highergeography.guid_type OR ctguid_type_highergeography.recordcount EQ 1 >
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
					<select name="highergeographyid_guid_type" id="highergeographyid_guid_type" size="1">
						<cfif searchtext EQ "">
							<option value=""></option>
						</cfif>
						<cfloop query="ctguid_type_highergeography">
							<cfset sel="">
		 						<cfif lookupHigherGeog.highergeographyid_guid_type is ctguid_type_highergeography.guid_type OR ctguid_type_highergeography.recordcount EQ 1 >
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
				<div class="col-12 col-md-4">
					<a href="#searchlink#" id="highergeographyid_search" target="_blank" #searchclass# >#searchtext#</a>
				</div>
				<div class="col-12 col-md-4">
					<input name="highergeographyid" id="highergeographyid" value="#geogDetails.highergeographyid#" placeholder="#placeholder#" pattern="#pattern#" title="Enter a guid in the form #placeholder#" class="data-entry-input">
					<cfif len(regex) GT 0 >
						<cfset link = REReplace(geogDetails.highergeographyid,regex,replacement)>
					<cfelse>
						<cfset link = geogDetails.highergeographyid>
					</cfif>
					<a id="highergeographyid_link" href="#link#" target="_blank" class="hints">#geogDetails.highergeographyid#</a>
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
								// On changing any geography inptu field name, update search.
								getGuidTypeInfo($('##highergeographyid_guid_type').val(), 'highergeographyid', 'highergeographyid_link','highergeographyid_search',getLowestGeography());
							});
						});
					</script>
				</div>

				<div class="col-12 mt-1">
					<input type="submit" value="Save" class="btn btn-xs btn-primary">
				</div>
			</div>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="createGeogFormThread#tn#" />

	<cfreturn cfthread["createGeogFormThread#tn#"].output>

</cffunction>

</cfcomponent>
