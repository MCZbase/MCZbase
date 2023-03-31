<!---
localities/component/functions.cfc

Copyright 2020-2023 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--->
<cfcomponent>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
<cf_rolecheck>

<!--- Save preferences for open/closed sections of geography/locality/collecting event 
  search form.
  @param id the id of the div on the form to show/hide, without a leading # selector, 
    one of GeogDetail, LocDetail, GeorefDetail, EventDetail.
  @param onOff new state for the provided id 1 for show, 0 for hide 
--->
<cffunction name="saveLocSrchPref" access="remote">
	<cfargument name="id" type="string" required="yes">
	<cfargument name="onOff" type="numeric" required="yes">

	<cfset retval = "">
	<cfif isdefined("session.username") and len(#session.username#) gt 0>
	   <cfthread name="saveLocSrchThread" >
			<cfoutput>
			<cftransaction>
			<cftry>
				<cfif listFind("GeogDetail,LocDetail,GeorefDetail,EventDetail",id) EQ 0 >
					<cfthrow message="unknown location search preference id.">
				</cfif>
				<cfquery name="getcurrentvalues" datasource="cf_dbuser">
					SELECT LOCSRCHPREFS
					FROM cf_users
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfset currentList=valuelist(getcurrentvalues.LOCSRCHPREFS)>
				<cfset nv = currentList>
				<cfif onOff is 1>
					<cfif not listfind(currentList,id)>
						<cfset nv=listappend(currentList,id)>
					</cfif>
				<cfelse>
					<cfif listfind(currentList,id)>
						<cfset nv=listdeleteat(currentList,listfind(currentList,id))>
					</cfif>
				</cfif>
				<cfquery name="update" datasource="cf_dbuser" result="update_result">
					update cf_users
					set LOCSRCHPREFS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nv#">
					where
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfset session.locSrchPrefs=nv>
				<cftransaction action="commit">
			<cfcatch>
				<cftransaction action="rollback">
				<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
				<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfset function_called = "#GetFunctionCalledName()#">
				<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
				<cfabort>
			</cfcatch>
			</cftry>
			</cftransaction>
			</cfoutput>
	   </cfthread>
		<cfthread action="join" name="saveLocSrchThread" />
		<cfset retval = session.locSrchPrefs>
	</cfif>
	<cfreturn retval>
</cffunction>

<!--- function deleteCollEventNumber
Delete an existing collecting event number record.

@param coll_event_number_id primary key of record to delete
@return json structure with status and id or http status 500
--->
<cffunction name="deleteCollEventNumber" access="remote" returntype="any" returnformat="json">
	<cfargument name="coll_event_number_id" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfquery name="save" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from coll_event_number 
			where 
				coll_event_number_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#coll_event_number_id#">
		</cfquery>
		<cfset row = StructNew()>
		<cfset row["status"] = "deleted">
		<cfset row["id"] = "#coll_event_number_id#">
		<cfset data[1] = row>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset message = trim("Error processing deleteCollEventNumber: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfheader statusCode="500" statusText="#message#">
		<cfoutput>
			<div class="container">
				<div class="row">
					<div class="alert alert-danger" role="alert">
						<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
						<h2>Internal Server Error.</h2>
						<p>#message#</p>
						<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
					</div>
				</div>
			</div>
		</cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- getEditLocalityHtml returns html for a form to edit an existing locality record 

@param locality_id the primary key value for the locality to edit.
--->
<cffunction name="getEditLocalityHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="locality_id" type="string" required="yes">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="editLocalityFormThread#tn#">
		<cfoutput>
			TODO: Implement
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="editLocalityFormThread#tn#" />

	<cfreturn cfthread["editLocalityFormThread#tn#"].output>
</cffunction>

<!--- getCreateLocalityHtml returns html for a form to create or clone a locality record 

--->
<cffunction name="getCreateLocalityHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="geog_auth_rec_id" type="string" required="no">
	<cfargument name="spec_locality" type="string" required="no">
	<cfargument name="sovereign_nation" type="string" required="no">
	<cfargument name="minimum_elevation" type="string" required="no">
	<cfargument name="maximum_elevation" type="string" required="no">
	<cfargument name="orig_elev_units" type="string" required="no">
	<cfargument name="min_depth" type="string" required="no">
	<cfargument name="max_depth" type="string" required="no">
	<cfargument name="depth_units" type="string" required="no">
	<cfargument name="locality_remarks" type="string" required="no">
	<cfargument name="clone_from_locality_id" type="string" required="no">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="createLocalityFormThread#tn#">
		<cfquery name="ctElevUnit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT orig_elev_units 
			FROM ctorig_elev_units 
			ORDER BY orig_elev_units
		</cfquery>
		<cfquery name="ctDepthUnit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
			SELECT depth_units 
			FROM ctdepth_units 
			ORDER BY depth_units
		</cfquery>
		<cfif isdefined('clone_from_locality_id') AND len(clone_from_locality_id) GT 0>
			<cfquery name="lookupLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT geog_auth_rec_id, spec_locality, sovereign_nation, 
					minimum_elevation, maximum_elevation, orig_elev_units, 
					min_depth, max_depth, depth_units,
					locality_remarks
				FROM locality
				WHERE 
					locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
			</cfquery>
			<cfloop query="lookupLocality">
				<cfset geog_auth_rec_id = "#lookupLocality.geog_auth_rec_id#">
				<cfset spec_locality = "#lookupLocality.spec_locality#">
				<cfset sovereign_nation = "#lookupLocality.sovereign_nation#">
				<cfset minimum_elevation = "#lookupLocality.minimum_elevation#">
				<cfset maximum_elevation = "#lookupLocality.maximum_elevation#">
				<cfset orig_elev_units = "#lookupLocality.orig_elev_units#">
				<cfset min_depth = "#lookupLocality.min_depth#">
				<cfset max_depth = "#lookupLocality.max_depth#">
				<cfset depth_units = "#lookupLocality.depth_units#">
				<cfset locality_remarks = "#lookupLocality.locality_remarks#">
<!--- TODO: Add 
TOWNSHIP ,
TOWNSHIP_DIRECTION ,
RANGE ,
RANGE_DIRECTION ,
SECTION ,
SECTION_PART ,
CURATED_FG 
--->
			</cfloop>
		<cfelse> 
			<cfset clone_from_locality_id = "">
		</cfif>
		<cfset higher_geog = "">
		<cfif isdefined('geog_auth_rec_id') AND len(geog_auth_rec_id) GT 0>
			<cfquery name="lookupHigherGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT higher_geog
				FROM geog_auth_rec
				WHERE 
					geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
			</cfquery>
			<cfloop query="lookupHigherGeog">
				<cfset higher_geog = "#lookupHigherGeog.higher_geog#">
			</cfloop>
		<cfelse> 
			<cfset geog_auth_rec_id = "">
		</cfif>
		<cfoutput>
			<div class="row mx-0 mb-0">
				<div class="col-12 col-md-10 mt-0">
					<input type="hidden" name="geog_auth_rec_id" value = "#geog_auth_rec_id#">
					<label class="data-entry-label" for="higher_geog">Higher Geography:</label>
					<input type="text" name="higher_geog" id="higher_geog" class="data-entry-input" value = "#encodeForHTML(higher_geog)#" readonly="yes">
				</div>
				<div class="col-12 col-md-2 mt-0">
					<input type="button" value="Pick" class="btn btn-xs btn-secondary" onclick="pickHigherGeography(); return false;">
					<script>
						function pickHigherGeography(){
   						<!--- TODO: Set a probably sane value for sovereign_nation from selected higher geography. --->
						}
					</script>
					<cfif isdefined("geog_auth_rec_id") and len(geog_auth_rec_id) GT 0>
						<input type="button" value="Details" class="btn btn-xs btn-info"
							onclick="document.location='Locality.cfm?Action=editGeog&geog_auth_rec_id=#geog_auth_rec_id#'">
					</cfif>
				</div>
				<div class="col-12">
					<label class="data-entry-label" for="spec_locality">Specific Locality</label>
					<cfif NOT isdefined("spec_locality")><cfset spec_locality=""></cfif>
					<input type="text" name="spec_locality" id="spec_locality" class="data-entry-input reqdClr" value="#encodeForHTML(spec_locality)#" required>
				</div>
				<div class="col-12 col-md-4">
					<cfif NOT isdefined("sovereign_nation")><cfset sovereign_nation=""></cfif>
					<label class="data-entry-label" for="sovereign_nation">Sovereign Nation</label>
					<input type="text" name="sovereign_nation" id="sovereign_nation" class="data-entry-input" value="#encodeforHTML(sovereign_nation)#">
					<script>
						$(document).ready(function() {
							makeSovereignNationAutocomplete("sovereign_nation");
						});
					</script>
				</div>
				<div class="col-12 col-md-3">
					<cfif NOT isdefined("minimum_elevation")><cfset minimum_elevation=""></cfif> 
					<label class="data-entry-label" for="minimum_elevation">Minimum Elevation</label>
					<input type="text" name="minimum_elevation" id="minimum_elevation" class="data-entry-input" value="#encodeForHTML(minimum_elevation)#" >
				</div>
				<div class="col-12 col-md-3">
					<cfif NOT isdefined("maximum_elevation")><cfset maximum_elevation=""></cfif>
					<label class="data-entry-label" for="maximum_elevation">Maximum Elevation</label>
					<input type="text" name="maximum_elevation" id="maximum_elevation" class="data-entry-input" value="#encodeForHTML(maximum_elevation)#" >
				</div>
				<div class="col-12 col-md-2">
					<label class="data-entry-label" for="orig_elev_units">Elevation Units</label>
					<select name="orig_elev_units" id="orig_elev_units" size="1" class="data-entry-select">
						<option value=""></option>
						<cfloop query="ctElevUnit">
							<cfif isdefined("orig_elev_units") AND ctelevunit.orig_elev_units is orig_elev_units><cfset selected="selected"></cfif>
							<option #selected# value="#ctElevUnit.orig_elev_units#">#ctElevUnit.orig_elev_units#</option>
						</cfloop>
					</select>
				</div>
				<div class="col-12 col-md-3">
					<cfif NOT isdefined("min_depth")><cfset min_depth=""></cfif> 
					<label class="data-entry-label" for="min_depth">Minimum Depth</label>
					<input type="text" name="min_depth" id="min_depth" class="data-entry-input" value="#encodeForHTML(min_depth)#" >
				</div>
				<div class="col-12 col-md-3">
					<cfif NOT isdefined("max_depth")><cfset max_depth=""></cfif>
					<label class="data-entry-label" for="max_depth">Maximum Depth</label>
					<input type="text" name="max_depth" id="max_depth" class="data-entry-input" value="#encodeForHTML(max_depth)#" >
				</div>
				<div class="col-12 col-md-2">
					<label class="data-entry-label" for="depth_units">Depth Units</label>
					<select name="depth_units" id="depth_units" size="1" class="data-entry-select">
						<option value=""></option>
						<cfloop query="ctDepthUnit">
							<cfif isdefined("depth_units") AND ctDepthUnit.depth_units is depth_units><cfset selected="selected"></cfif>
							<option #selected# value="#ctElevUnit.depth_units#">#ctElevUnit.depth_units#</option>
						</cfloop>
					</select>
				</div>
				<div class="col-12">
					<cfif NOT isdefined("locality_remarks")><cfset locality_remarks=""></cfif>
					<label class="data-entry-label" for="locality_remarks">Locality Remarks</label>
					<input type="text" name="locality_remarks" id="locality_remarks" class="data-entry-input">
					<cfif isdefined("clone_from_locality_id") and len(clone_from_locality_id) gt 0>
						<input type="hidden" name="locality_id" value="locality_id" />
						<label class="data-entry-label" for="">Include accepted georeference from <a href="/editLocality.cfm?locality_id=#clone_from_locality_id#" target="_blank">#clone_from_locality_id#</a>?</label>
						Y<input type="radio" name="cloneCoords" value="yes" />
						<br>
						N<input type="radio" name="cloneCoords" value="no" checked="checked" />
		 			</cfif>
				</div>
				<div class="col-12">
					<input type="submit" value="Save" class="btn btn-xs btn-primary">
				</div>
			</div>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="createLocalityFormThread#tn#" />

	<cfreturn cfthread["createLocalityFormThread#tn#"].output>

</cffunction>

</cfcomponent>
