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
			<cfif isdefined('clone_from_geog_auth_rec_id') AND len(clone_from_geog_auth_rec_id) GT 0>
				<cfquery name="lookupHigherGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						higher_geog, 
						continent_ocean
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
					<input type="text" name="continent_ocean" id="continent_ocean" class="data-entry-input reqdClr" value="#encodeForHTML(continent_ocean)#" required>
					<script>
						$(document).ready(() => makeGeogAutocomplete('continent_ocean','continent_ocean'));
					</script>
				</div>
				<div class="col-12 col-md-3">
					<label class="data-entry-label" for="ocean_region">Ocean Region</label>
					<cfif NOT isdefined("ocean_region")><cfset ocean_region=""></cfif>
					<input type="text" name="ocean_region" id="ocean_region" class="data-entry-input reqdClr" value="#encodeForHTML(ocean_region)#" required>
					<script>
						$(document).ready(() => makeGeogAutocomplete('ocean_region','ocean_region'));
					</script>
				</div>
				<div class="col-12 col-md-3">
					<label class="data-entry-label" for="ocean_subregion">Ocean Subregion</label>
					<cfif NOT isdefined("ocean_subregion")><cfset ocean_subregion=""></cfif>
					<input type="text" name="ocean_subregion" id="ocean_subregion" class="data-entry-input reqdClr" value="#encodeForHTML(ocean_subregion)#" required>
					<script>
						$(document).ready(() => makeGeogAutocomplete('ocean_subregion','ocean_subregion'));
					</script>
				</div>
			
				TODO: Complete implementation


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
