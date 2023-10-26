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
<cfinclude template="/shared/component/functions.cfc" runOnce="true"><!--- For getCommentForField, reportError --->
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
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfoutput>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- function updateLocality update a locality record 
  @param locality_id the locality to update 
  @return json structure with status=updated and id=locality_id of the locality, 
   or http 500 status on an error.
--->
<cffunction name="updateLocality" access="remote" returntype="any" returnformat="json">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="geog_auth_rec_id" type="string" required="yes">
	<cfargument name="spec_locality" type="string" required="no">
	<cfargument name="sovereign_nation" type="string" required="no">
	<cfargument name="minimum_elevation" type="string" required="no">
	<cfargument name="maximum_elevation" type="string" required="no">
	<cfargument name="orig_elev_units" type="string" required="no">
	<cfargument name="min_depth" type="string" required="no">
	<cfargument name="max_depth" type="string" required="no">
	<cfargument name="section_part" type="string" required="no">
	<cfargument name="section" type="string" required="no">
	<cfargument name="township" type="string" required="no">
	<cfargument name="township_direction" type="string" required="no">
	<cfargument name="range" type="string" required="no">
	<cfargument name="range_direction" type="string" required="no">
	<cfargument name="depth_units" type="string" required="no">
	<cfargument name="curated_fg" type="string" required="no">
	<cfargument name="locality_remarks" type="string" required="no">
	<cfargument name="nogeorefbecause" type="string" required="no">
	<!--- update georef_updated_date and georef_by when adding georeferences --->

	<cfif not isDefined("minimum_elevation")><cfset minimum_elevation = ""></cfif>
	<cfif not isDefined("maximum_elevation")><cfset maximum_elevation = ""></cfif>
	<cfif not isDefined("min_depth")><cfset min_depth = ""></cfif>
	<cfif not isDefined("max_depth")><cfset max_depth = ""></cfif>

	<cfset data = ArrayNew(1)>

	<cftransaction>
		<cftry>
			<cfif len(MINIMUM_ELEVATION) gt 0 OR len(MAXIMUM_ELEVATION) gt 0>
				<cfif not isDefined("orig_elev_units") OR len(ORIG_ELEV_UNITS) is 0>
					<cfthrow message="You must provide elevation units if you provide elevation data.">
				</cfif>
			</cfif>
			<cfif len(MIN_DEPTH) gt 0 OR len(MAX_DEPTH) gt 0>
				<cfif not isDefined("depth_units") OR len(depth_units) is 0>
					<cfthrow message="You must provide depth units if you provide depth data.">
				</cfif>
			</cfif>
			<cfif len(ORIG_ELEV_UNITS) gt 0>
				<cfif len(MINIMUM_ELEVATION) is 0 AND len(MAXIMUM_ELEVATION) is 0>
						<cfset orig_elev_units = "">
				</cfif>
			</cfif>
			<cfif len(DEPTH_UNITS) gt 0>
				<cfif len(MIN_DEPTH) is 0 AND len(MAX_DEPTH) is 0>
						<cfset depth_units = "">
				</cfif>
			</cfif>
			<cfif len(maximum_elevation) GT 0>
				<cfset max_elev_scale = len(rereplace(maximum_elevation,'^[0-9-]*[.]',''))>
			</cfif>
			<cfif len(minimum_elevation) GT 0>
				<cfset min_elev_scale = len(rereplace(minimum_elevation,'^[0-9-]*[.]',''))>
			</cfif>
			<cfif len(max_depth) GT 0>
				<cfset max_depth_scale = len(rereplace(max_depth,'^[0-9-]*[.]',''))>
			</cfif>
			<cfif len(min_depth) GT 0>
				<cfset min_depth_scale = len(rereplace(min_depth,'^[0-9-]*[.]',''))>
			</cfif>

			<cfquery name="updateLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateLocality_result">
				UPDATE locality SET
				geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">,
				<cfif len(#spec_locality#) GT 0>
					spec_locality = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#spec_locality#">,
			  <cfelse>
					spec_locality = null,
				</cfif>
				<cfif isdefined("curated_fg") AND len(#curated_fg#) gt 0>
					curated_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#curated_fg#">,
				</cfif>
				<cfif len(#MINIMUM_ELEVATION#) gt 0>
					MINIMUM_ELEVATION = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="#min_elev_scale#" value="#MINIMUM_ELEVATION#">,
				<cfelse>
					MINIMUM_ELEVATION = null,
				</cfif>
				<cfif len(#MAXIMUM_ELEVATION#) gt 0>
					MAXIMUM_ELEVATION = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="#max_elev_scale#" value="#MAXIMUM_ELEVATION#">,
				<cfelse>
					MAXIMUM_ELEVATION = null,
				</cfif>
				<cfif len(#ORIG_ELEV_UNITS#) gt 0>
					ORIG_ELEV_UNITS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ORIG_ELEV_UNITS#">,
				<cfelse>
					ORIG_ELEV_UNITS = null,
				</cfif>
				<cfif len(#min_depth#) gt 0>
					min_depth = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="#min_depth_scale#" value="#min_depth#">,
				<cfelse>
					min_depth = null,
				</cfif>
				<cfif len(#max_depth#) gt 0>
					max_depth = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="#max_depth_scale#" value="#max_depth#">,
				<cfelse>
					max_depth = null,
				</cfif>
				<cfif len(#depth_units#) gt 0>
					depth_units = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#depth_units#">,
				<cfelse>
					depth_units = null,
				</cfif>
				<cfif len(#section_part#) gt 0>
					section_part = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#section_part#">,
				<cfelse>
					section_part = null,
				</cfif>
				<cfif len(#section#) gt 0>
					section = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#section#">,
				<cfelse>
					section = null,
				</cfif>
				<cfif len(#township_direction#) gt 0>
					township_direction = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#township_direction#">,
				<cfelse>
					township_direction = null,
				</cfif>
				<cfif len(#township#) gt 0>
					township = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#township#">,
				<cfelse>
					township = null,
				</cfif>
				<cfif len(#range_direction#) gt 0>
					range_direction = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#range_direction#">,
				<cfelse>
					range_direction = null,
				</cfif>
				<cfif len(#range#) gt 0>
					range = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#range#">,
				<cfelse>
					range = null,
				</cfif>
				<cfif len(#sovereign_nation#) gt 0>
					SOVEREIGN_NATION = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#sovereign_nation#">,
				</cfif>
				<cfif len(#LOCALITY_REMARKS#) gt 0>
					LOCALITY_REMARKS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LOCALITY_REMARKS#">,
				<cfelse>
					LOCALITY_REMARKS = null,
				</cfif>
				<!--- last field in set clause, no commas at end --->
				<cfif len(#nogeorefbecause#) gt 0>
					nogeorefbecause = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nogeorefbecause#">
				<cfelse>
					nogeorefbecause = null
				</cfif>
				WHERE locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
			</cfquery>

			<cfset row = StructNew()>
			<cfset row["status"] = "updated">
			<cfset row["id"] = "#locality_id#">
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




<!--- getEditLocalityHtml returns html for a form to edit an existing locality record 

@param locality_id the primary key value for the locality to edit.
@param formId the id in the dom for the form that encloses the inputs returned from this function.
@param outputDiv the id in the dom for an output element where feedback from form submission actions 
  is placed.
@param saveButtonFunction the name of a javascript function that is to be invoked when the save
  button is clicked, just the name without trailing parenthesies.
--->
<cffunction name="getEditLocalityHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="formId" type="string" required="yes">
	<cfargument name="outputDiv" type="string" required="yes">
	<cfargument name="saveButtonFunction" type="string" required="yes">
	
	<!---
	NOTE: When using threads, cfarguments are out of scope for the thread, place copies of them
	   into the variables scope.    See: https://gist.github.com/bennadel/9760037 for more examples of
   	scope issues related to cfthread 
	--->
	<cfset variables.formId = arguments.formId>
	<cfset variables.outputDiv = arguments.outputDiv>
	<cfset variables.saveButtonFunction = arguments.saveButtonFunction>
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="editLocalityFormThread#tn#">
		<cfoutput>
			<cftry>
			<cfquery name="ctElevUnit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
				SELECT orig_elev_units
				FROM ctorig_elev_units 
				ORDER BY orig_elev_units
			</cfquery>
			<cfquery name="ctDepthUnit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
				SELECT depth_units as unit
				FROM ctdepth_units 
				ORDER BY depth_units
			</cfquery>
			<cfquery name="lookupLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					geog_auth_rec_id, spec_locality, sovereign_nation, 
					minimum_elevation, maximum_elevation, orig_elev_units, 
					min_depth, max_depth, depth_units,
					section_part, section, township, township_direction, range, range_direction,
					nogeorefbecause, georef_updated_date, georef_by,
					curated_fg, locality_remarks
				FROM locality
				WHERE 
					locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
			</cfquery>
			<cfif lookupLocality.recordcount NEQ 1>
				<cfthrow message="Found other than one locality with specified locality_id [#encodeForHtml(locality_id)#].  Locality may be used only by a department for which you do not have access.">
			</cfif>
			<cfloop query="lookupLocality">
				<cfset geog_auth_rec_id = "#lookupLocality.geog_auth_rec_id#">
				<cfset spec_locality = "#lookupLocality.spec_locality#">
				<cfset sovereign_nation = "#lookupLocality.sovereign_nation#">
				<cfset minimum_elevation = "#lookupLocality.minimum_elevation#">
				<cfset maximum_elevation = "#lookupLocality.maximum_elevation#">
				<cfset orig_elev_units = "#lookupLocality.orig_elev_units#">
				<cfset min_depth = "#lookupLocality.min_depth#">
				<cfset max_depth = "#lookupLocality.max_depth#">
				<cfset section_part = "#lookupLocality.section_part#">
				<cfset section = "#lookupLocality.section#">
				<cfset township = "#lookupLocality.township#">
				<cfset township_direction = "#lookupLocality.township_direction#">
				<cfset range = "#lookupLocality.range#">
				<cfset range_direction = "#lookupLocality.range_direction#">
				<cfset depth_units = "#lookupLocality.depth_units#">
				<cfset nogeorefbecause = "#lookupLocality.nogeorefbecause#">
				<cfset georef_by = "#lookupLocality.georef_by#">
				<cfset georef_updated_date = "#lookupLocality.georef_updated_date#">
				<cfset curated_fg = "#lookupLocality.curated_fg#">
				<cfset locality_remarks = "#lookupLocality.locality_remarks#">
			</cfloop>
			<cfquery name="lookupHigherGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT higher_geog
				FROM geog_auth_rec
				WHERE 
					geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
			</cfquery>
			<cfloop query="lookupHigherGeog">
				<cfset higher_geog = "#lookupHigherGeog.higher_geog#">
			</cfloop>
			<div class="form-row mx-0 mb-0">
				<cfif lookupLocality.curated_fg EQ 1 >
				<div class="col-12 mt-0">
					<h2 class="h3 mb-3">This locality record has been vetted. Please do not edit (or delete).</h3>
				</div>
				</cfif>
				<div class="col-12 col-md-10 mt-0">
					<input type="hidden" name="geog_auth_rec_id" id="geog_auth_rec_id" value="#geog_auth_rec_id#">
					<label class="data-entry-label" for="higher_geog">Higher Geography </label>
					<input type="text" name="higher_geog" id="higher_geog" class="data-entry-input reqdClr" value = "#encodeForHTML(higher_geog)#" required>
					<script>
						function setSovereignNation(){
							if ($("##geog_auth_rec_id").val() && ! $("##sovereign_nation").val()){
								<!--- Set a probably sane value for sovereign_nation from selected higher geography. --->
								var geog = $("##geog_auth_rec_id").val();
								console.log(geog);
								suggestSovereignNation(geog, "sovereign_nation");
							}
						}
						$(document).ready(function() {
							makeHigherGeogAutocomplete("higher_geog","geog_auth_rec_id");
							$("##higher_geog").on("change", function(evt){ 
								setSovereignNation();
								if ($("##higher_geog").val()) { 
									$("##details_button").removeClass("disabled");
								} else { 
									$("##details_button").addClass("disabled");
								}
							});
						});
					</script>
				</div>
				<div class="col-12 col-md-2 mt-0 mb-2">
					<label class="data-entry-label sr-only mt-3 text-white" for="details_button">Higher Geography</label>
					<cfset otherClass="">
					<cfif NOT isdefined("geog_auth_rec_id") or len(geog_auth_rec_id) EQ 0>
						<cfset otherClass="disabled">
					</cfif>
					<a id="details_button" role="button" class="btn btn-xs mt-3 btn-info #otherClass#" href="/localities/viewHigherGeography.cfm?geog_auth_rec_id=#geog_auth_rec_id#" target="_blank"
>Details</a>
				</div>
				<div class="col-12 mb-2 mt-1">
					<label class="data-entry-label" for="spec_locality">Specific Locality</label>
					<cfif NOT isdefined("spec_locality")><cfset spec_locality=""></cfif>
					<input type="text" name="spec_locality" id="spec_locality" class="data-entry-input reqdClr" value="#encodeForHTML(spec_locality)#" required>
				</div>
				<div class="col-12 col-md-4 mb-2 mt-1">
					<cfif NOT isdefined("sovereign_nation")><cfset sovereign_nation=""></cfif>
					<label class="data-entry-label" for="sovereign_nation">
						Sovereign Nation
						<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##sovereign_nation').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open pick list</span></a>
					</label>
					<input type="text" name="sovereign_nation" id="sovereign_nation" class="data-entry-input reqdClr" value="#encodeforHTML(sovereign_nation)#" required>
					<script>
						$(document).ready(function() {
							makeSovereignNationAutocomplete("sovereign_nation");
						});
					</script>
				</div>
				<div class="col-12 col-md-2 mb-2 mt-1">
					<label class="data-entry-label" for="curated_fg">Vetted</label>
					<select name="curated_fg" id="curated_fg" size="1" class="data-entry-select reqdClr">
						<cfif not isDefined("curated_fg") OR (isdefined("curated_fg") AND curated_fg NEQ 1) ><cfset selected="selected"><cfelse><cfset selected=""></cfif>
						<option value="0" #selected#>No</option>
						<cfif isdefined("curated_fg") AND curated_fg EQ 1 ><cfset selected="selected"><cfelse><cfset selected=""></cfif>
						<option value="1" #selected#>Yes (*)</option>
					</select>
				</div>
				<div class="col-12 col-md-6 mb-2 mt-1">
					<cfif NOT isdefined("nogeorefbecause")><cfset nogeorefbecause=""></cfif>
					<label class="data-entry-label" for="nogeorefbecause">
						No Georeference Because
						<i class="fas fa-info-circle" onClick="getMCZDocs('Not_Georeferenced_Because')" aria-label="help link with suggested entries for why no georeference was added"></i>
					</label>
					<input type="text" name="nogeorefbecause" id="nogeorefbecause" class="data-entry-input" value="#encodeForHTML(nogeorefbecause)#">
				</div>
			</div>
			<div class="form-row mx-0 mb-0">
				<div class="col-12 col-md-2 py-2 mt-1">
					<cfif NOT isdefined("minimum_elevation")><cfset minimum_elevation=""></cfif> 
					<label class="data-entry-label" for="minimum_elevation"><span class="font-weight-lessbold">Elevation:</span> Minimum</label>
					<input type="text" name="minimum_elevation" id="minimum_elevation" class="data-entry-input" value="#encodeForHTML(minimum_elevation)#" >
				</div>
				<div class="col-12 col-md-2 py-2 mt-1">
					<cfif NOT isdefined("maximum_elevation")><cfset maximum_elevation=""></cfif>
					<label class="data-entry-label" for="maximum_elevation">Maximum Elevation</label>
					<input type="text" name="maximum_elevation" id="maximum_elevation" class="data-entry-input" value="#encodeForHTML(maximum_elevation)#" >
				</div>
				<div class="col-12 col-md-2 py-2 mt-1">
					<label class="data-entry-label" for="orig_elev_units">Elevation Units</label>
					<select name="orig_elev_units" id="orig_elev_units" size="1" class="data-entry-select">
						<option value=""></option>
						<cfloop query="ctElevUnit">
							<cfif isdefined("orig_elev_units") AND ctelevunit.orig_elev_units is orig_elev_units><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option #selected# value="#ctElevUnit.orig_elev_units#">#ctElevUnit.orig_elev_units#</option>
						</cfloop>
					</select>
				</div>
				<div class="col-12 col-md-2 py-2 mt-1">
					<cfif NOT isdefined("min_depth")><cfset min_depth=""></cfif> 
					<label class="data-entry-label" for="min_depth"><span class="font-weight-lessbold">Depth:</span> Minimum</label>
					<input type="text" name="min_depth" id="min_depth" class="data-entry-input" value="#encodeForHTML(min_depth)#" >
				</div>
				<div class="col-12 col-md-2 py-2 mt-1">
					<cfif NOT isdefined("max_depth")><cfset max_depth=""></cfif>
					<label class="data-entry-label" for="max_depth">Maximum Depth</label>
					<input type="text" name="max_depth" id="max_depth" class="data-entry-input" value="#encodeForHTML(max_depth)#" >
				</div>
				<div class="col-12 col-md-2 py-2 mt-1">
					<label class="data-entry-label" for="depth_units">Depth Units</label>
					<select name="depth_units" id="depth_units" size="1" class="data-entry-select">
						<option value=""></option>
						<cfloop query="ctDepthUnit">
							<cfif isdefined("depth_units") AND ctDepthUnit.unit is depth_units><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option #selected# value="#ctDepthUnit.unit#">#ctDepthUnit.unit#</option>
						</cfloop>
					</select>
				</div>
			</div>
			<div class="form-row border rounded m-1 p-1">
				<div class="col-12 col-md-2 py-2">
					<cfif NOT isdefined("section_part")><cfset section_part=""></cfif>
					<label class="data-entry-label" for="section_part"><span class="font-weight-lessbold">PLSS: </span> Section Part</label>
					<input type="text" name="section_part" id="section_part" class="data-entry-input" value="#encodeForHTML(section_part)#" placeholder="NE 1/4" >
				</div>
				<div class="col-12 col-md-2 py-2">
					<cfif NOT isdefined("section")><cfset section=""></cfif>
					<label class="data-entry-label" for="section">Section</label>
					<input type="text" name="section" id="section" class="data-entry-input" value="#encodeForHTML(section)#" pattern="[0-3]{0,1}[0-9]{0,1}" >
				</div>
				<div class="col-12 col-md-2 py-2">
					<cfif NOT isdefined("township")><cfset township=""></cfif>
					<label class="data-entry-label" for="township">Township</label>
					<input type="text" name="township" id="township" class="data-entry-input" value="#encodeForHTML(township)#" pattern="[0-9]+" >
				</div>
				<div class="col-12 col-md-2 py-2">
					<cfif NOT isdefined("township_direction")><cfset township_direction=""></cfif>
					<label class="data-entry-label" for="township_direction">Township Direction</label>
					<input type="text" name="township_direction" id="township_direction" class="data-entry-input" value="#encodeForHTML(township_direction)#" >
				</div>
				<div class="col-12 col-md-2 py-2">
					<cfif NOT isdefined("range")><cfset range=""></cfif>
					<label class="data-entry-label" for="range">Range</label>
					<input type="text" name="range" id="range" class="data-entry-input" value="#encodeForHTML(range)#" pattern="[0-9]+">
				</div>
				<div class="col-12 col-md-2 py-2">
					<cfif NOT isdefined("range_direction")><cfset range_direction=""></cfif>
					<label class="data-entry-label" for="range_direction">Range Direction</label>
					<input type="text" name="range_direction" id="range_direction" class="data-entry-input" value="#encodeForHTML(range_direction)#" >
				</div>
			</div>
			<div class="form-row mx-0 my-1">
				<cfif isdefined("clone_from_locality_id") and len(clone_from_locality_id) gt 0>
					<cfset remarksClass = "col-md-9">
				<cfelse>
					<cfset remarksClass = "">
				</cfif>
				<div class="col-12 py-2 #remarksClass#">
					<cfif NOT isdefined("locality_remarks")><cfset locality_remarks=""></cfif>
					<label class="data-entry-label" for="locality_remarks">Locality Remarks (<span id="length_locality_remarks"></span>)</label>
					<textarea name="locality_remarks" id="locality_remarks" 
						onkeyup="countCharsLeft('locality_remarks', 4000, 'length_locality_remarks');"
						class="form-control form-control-sm w-100 autogrow mb-1" rows="2">#encodeForHtml(locality_remarks)#</textarea>
					<script>
						// Bind input to autogrow function on key up, and trigger autogrow to fit text
						$(document).ready(function() { 
							$("##locality_remarks").keyup(autogrow);  
							$('##locality_remarks').keyup();
						});
					</script>
				</div>
				<cfif isdefined("clone_from_locality_id") and len(clone_from_locality_id) gt 0>
					<div class="col-12 col-md-3">
						<input type="hidden" name="locality_id" value="locality_id" />
						<label class="data-entry-label" for="">Include accepted georeference from <a href="/localities/viewLocality.cfm?locality_id=#clone_from_locality_id#" target="_blank">#clone_from_locality_id#</a>?</label>
						Y<input type="radio" name="cloneCoords" value="yes" />
						<br>
						N<input type="radio" name="cloneCoords" value="no" checked="checked" />
					</div>
		 		</cfif>
				<div class="col-6">
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
				<h2 class="h3 text-danger mt-0">Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="editLocalityFormThread#tn#" />

	<cfreturn cfthread["editLocalityFormThread#tn#"].output>
</cffunction>

<!--- given a locality id, return a block of html with an editable list of geological attributes.
  @param locality_id the locality for which to lookup the geology.
  @param callback_name the name of a callback function that can be passed on to action buttons for
   changing the geological attributes.
  @return block of html containing a list of geological attribtues, or an error message.
--->
<cffunction name="getLocalityGeologyHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="callback_name" type="string" required="yes">

	<cfset variables.callback_name = arguments.callback_name>
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="localityGeologyFormThread#tn#">
		<cfoutput>
			<cftry>
				<cfquery name="getGeologicalAttributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.query_timeout#">
					SELECT
						geology_attribute_id,
						ctgeology_attribute.type,
						geology_attributes.geology_attribute,
						geology_attributes.geo_att_value,
						geology_attributes.geo_att_determiner_id,
						agent_name determined_by,
						to_char(geology_attributes.geo_att_determined_date,'yyyy-mm-dd') determined_date,
						geology_attributes.geo_att_determined_method determined_method,
						geology_attributes.geo_att_remark,
						geology_attributes.previous_values,
						geology_attribute_hierarchy.usable_value_fg,
						geology_attribute_hierarchy.geology_attribute_hierarchy_id
					FROM
						geology_attributes
						join ctgeology_attribute on geology_attributes.geology_attribute = ctgeology_attribute.geology_attribute
						left join preferred_agent_name on geo_att_determiner_id = agent_id
						left join geology_attribute_hierarchy 
							on geology_attributes.geo_att_value = geology_attribute_hierarchy.attribute_value 
								and
								geology_attributes.geology_attribute = geology_attribute_hierarchy.attribute
					WHERE 
						geology_attributes.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
					ORDER BY
						ctgeology_attribute.ordinal
				</cfquery>
				<cfif getGeologicalAttributes.recordcount EQ 0>
					<h3 class="h4">Geological Attributes</h3>
						<ul>
							<li>
								Recent (no geological attributes) 
							</li>
						</ul>
						<button type="button" class="btn btn-xs btn-secondary" onClick=" openAddGeologyDialog('#locality_id#','addGeologyDialog',#callback_name#); ">Add</button>
				<cfelse>
					<h3 class="h4">Geological Attributes</h3>
						<ul>
							<cfset valList = "">
							<cfset shownParentsList = "">
							<cfset separator = "">
							<cfset separator2 = "">
							<cfloop query="getGeologicalAttributes">
								<cfset valList = "#valList##separator##getGeologicalAttributes.geo_att_value#">
								<cfset separator = "|">
							</cfloop>
							<cfloop query="getGeologicalAttributes">
								<cfquery name="getParentage" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" timeout="#Application.query_timeout#">
									SELECT distinct
									  connect_by_root geology_attribute_hierarchy.attribute parent_attribute,
									  connect_by_root attribute_value parent_attribute_value,
									  connect_by_root usable_value_fg
									FROM geology_attribute_hierarchy
									  left join geology_attributes on
									     geology_attribute_hierarchy.attribute = geology_attributes.geology_attribute
									     and
							   		  geology_attribute_hierarchy.attribute_value = geology_attributes.geo_att_value
									WHERE geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getGeologicalAttributes.geology_attribute_hierarchy_id#">
									CONNECT BY nocycle PRIOR geology_attribute_hierarchy_id = parent_id
								</cfquery>
								<cfset parentage="">
								<cfloop query="getParentage">
									<cfif ListContains(valList,getParentage.parent_attribute_value,"|") EQ 0 AND  ListContains(shownParentsList,getParentage.parent_attribute_value,"|") EQ 0 >
										<cfset parentage="#parentage#<li><span class='text-secondary'>#getParentage.parent_attribute#:#getParentage.parent_attribute_value#</span></li>" > <!--- " --->
										<cfset shownParentsList = "#shownParentsList##separator2##getParentage.parent_attribute_value#">
										<cfset separator2 = "|">
									</cfif>
								</cfloop>
								#parentage#
								<li>
									<cfif len(getGeologicalAttributes.determined_method) GT 0>
										<cfset method = " Method: #getGeologicalAttributes.determined_method#">
									<cfelse>
										<cfset method = "">
									</cfif>
									<cfif len(getGeologicalAttributes.geo_att_remark) GT 0>
										<cfset remarks = " <span class='smaller-text'>Remarks: #getGeologicalAttributes.geo_att_remark#</span>"><!--- " --->
									<cfelse>
										<cfset remarks="">
									</cfif>
									<cfif usable_value_fg EQ 1>
										<cfset marker = "*">
										<cfset spanClass = "">
									<cfelse>
										<cfset marker = "">
										<cfset spanClass = "text-danger">
									</cfif>
									<span class="#spanClass#">#geo_att_value# #marker#</span> (#geology_attribute#) #determined_by# #determined_date##method##remarks#
									<button type="button" class="btn btn-xs btn-secondary" onClick=" openEditGeologyDialog('#geology_attribute_id#','#locality_id#','editGeologyDialog',#callback_name#);">Edit</button>
									<button type="button" 
										class="btn btn-xs btn-warning" 
										onClick=" confirmDialog('Remove #geology_attribute#:#geo_att_value# from this locality ?', 'Confirm Remove Geological Attribute', function() { removeGeologyAttribute('#geology_attribute_id#','#locality_id#',#callback_name#); } );">Remove</button>
								</li>
							</cfloop>
						</ul>
						<button type="button" class="btn btn-xs btn-secondary" onClick=" openAddGeologyDialog('#locality_id#','addGeologyDialog',#callback_name#); ">Add</button>
				</cfif>
				<div id="editGeologyDialog"></div>
				<div id="addGeologyDialog"></div>
			<cfcatch>
				<h3 class="h4 text-danger">Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="localityGeologyFormThread#tn#" />

	<cfreturn cfthread["localityGeologyFormThread#tn#"].output>
</cffunction>

<!--- delete a geological attribute, .
  @param geology_attribute_id the primary key value of the locality from which to delete the 
   geological attribute.
  @param locality_id the locality the geology_attribute_id applies to.
  @return json with status=deleted, or an http status 500.
--->
<cffunction name="deleteGeologyAttribute" access="remote" returntype="any" returnformat="json">
	<cfargument name="geology_attribute_id" type="string" required="yes">
	<cfargument name="locality_id" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="getGeoAttribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					locality_id
				FROM
					geology_attributes
				WHERE 
					geology_attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_id#">
					and 
					locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
			</cfquery>
			<cfif getGeoAttribute.recordcount NEQ "1">
				<cfthrow message="Unable to delete. Found other than one attribute for the geology_attribute_id [#encodeForHtml(geology_attribute_id)#] and locality_id [#encodeForHtml(locality_id)#] provided.">
			</cfif>
			<cfquery name="deleteGeoAttribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="deleteGeoAttribute_result">
				DELETE FROM geology_attributes
				WHERE 
					geology_attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_id#">
			</cfquery>
			<cfif deleteGeoAttribute_result.recordcount NEQ 1>
				<cfthrow message="Error deleteing geology_attribute, provided geology_attribute_id matched other than one record.">
			</cfif>
			<cfset row = StructNew()>
			<cfset row["status"] = "deleted">
			<cfset row["id"] = "#locality_id#">
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

<!--- insert a geological attribute, .
  @param locality_id the locality the geology_attribute_id applies to.
  @return json with status=added and id=inserted geology_attribute_id, or an http status 500.
--->
<cffunction name="addGeologyAttribute" access="remote" returntype="any" returnformat="json">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="geology_attribute" type="string" required="no">
	<cfargument name="geo_att_value" type="string" required="no">
	<cfargument name="geology_attribute_hierarchy_id" type="string" required="no">
	<cfargument name="geo_att_determiner_id" type="string" required="yes">
	<cfargument name="geo_att_determined_date" type="string" required="yes">
	<cfargument name="geo_att_determined_method" type="string" required="yes">
	<cfargument name="geo_att_remark" type="string" required="yes">
	<cfargument name="add_parents" type="string" required="no">

	<!--- either attribute+value or hierarchy_id are required to specify attribute to add --->
	<cfif 
		isDefined("geology_attribute_hierarchy_id") AND len(geology_attribute_hierarchy_id) GT 0
		OR ( 
			isDefined("geology_attribute") AND len(geology_attribute) GT 0
			AND
			isDefined("geo_att_value") AND len(geo_att_value) GT 0
		)
	> 
		<!--- there is a value to insert, continue --->
	<cfelse>
		<cfthrow message="Unable to insert. Either a geology_attribute_heirarchy_id or both geology_attribute and geo_att_value must be specified for the attribtue to add.">
	</cfif>
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfif isDefined("geology_attribute_hierarchy_id") AND len(geology_attribute_hierarchy_id) GT 0>
				<cfquery name="getGeoAttribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						attribute geology_attribute,
						attribute_value geo_att_value
					FROM
						geology_attribute_hierarchy
					WHERE 
						geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
				</cfquery>
				<cfset geology_attribute = getGeoAttribute.geology_attribute>
				<cfset geo_att_value = getGeoAttribute.geo_att_value>
			<cfelse>
				<cfquery name="getGeoAttributeId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						geology_attribute_hierarchy_id id
					FROM
						geology_attribute_hierarchy
					WHERE 
						attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geology_attribute#">
						AND
						attribute_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geo_att_value#">
				</cfquery>
				<cfif getGeoAttributeId.recordcount NEQ 1>
					<cfthrow message="Unable to insert, unable to find a geology_attribute_hierarchy record for the specified geology_attribute and geo_att_value">
				</cfif>
				<cfset geology_attribute_hierarchy_id = getGeoAttributeId.id>
			</cfif>
			<cfquery name="addGeoAttribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="addGeoAttribute_result">
				INSERT INTO geology_attributes
					( locality_id,
						geology_attribute,
						geo_att_value,
						geo_att_determiner_id,
						geo_att_determined_date,
						geo_att_determined_method,
						geo_att_remark
					) VALUES (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geology_attribute#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geo_att_value#">,
						<cfif isDefined("geo_att_determiner_id") and len(geo_att_determiner_id) GT 0>
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geo_att_determiner_id#">,
						<cfelse>
							NULL,
						</cfif>
						<cfif isDefined("geo_att_determined_date") and len(geo_att_determined_date) GT 0>
							<cfqueryparam cfsqltype="CF_SQL_DATE" value="#geo_att_determined_date#">,
						<cfelse>
							NULL,
						</cfif>
						<cfif isDefined("geo_att_determined_method") and len(geo_att_determined_method) GT 0>
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geo_att_determined_method#">,
						<cfelse>
							NULL,
						</cfif>
						<cfif isDefined("geo_att_remark") and len(geo_att_remark) GT 0>
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geo_att_remark#">
						<cfelse>
							NULL
						</cfif>
					)
			</cfquery>
			<cfif addGeoAttribute_result.recordcount NEQ 1>
				<cfthrow message="Error inserting geology attribtue, insert would affect other than one row.">
			</cfif>
			<cfquery name="getPK" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getPK_result">
					select geology_attribute_id 
					from geology_attributes
					where ROWIDTOCHAR(rowid) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#addGeoAttribute_result.GENERATEDKEY#">
			</cfquery>
			<cfif getPK.recordcount NEQ 1>
				<cfthrow message="Error inserting geology attribute, inserted row not found.">
			</cfif>
			<cfset values="#geology_attribute#:#geo_att_value#">
			<cfset count=1>
			<cfif isDefined("add_parents") AND ucase(add_parents) EQ "YES">
				<!--- add any parents of the inserted node that aren't already present --->
				<cfquery name="getParents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT * FROM (
						SELECT 
							level as parentagelevel,
							connect_by_root attribute as geology_attribute,
							connect_by_root attribute_value as geo_att_value,
							connect_by_root geology_attribute_hierarchy_id as geology_attribute_hierarchy_id,
							connect_by_root PARENT_ID as parent_id,
							connect_by_root USABLE_VALUE_FG as USABLE_VALUE_FG,
							connect_by_root DESCRIPTION as description
						FROM geology_attribute_hierarchy 
						WHERE
							geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
						CONNECT BY PRIOR geology_attribute_hierarchy_id = parent_id
						ORDER BY level asc
					) WHERE parentagelevel > 1
				</cfquery>
				<cfloop query="getParents">
					<cfquery name="checkParents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT count(*) ct 
						FROM geology_attributes
						WHERE
							locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
							and geology_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getParents.geology_attribute#">
							and geo_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getParents.geo_att_value#">
					</cfquery>
					<cfif checkParents.ct EQ 0>
						<cfquery name="addGeoAttribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="addGeoAttribute_result">
							INSERT INTO geology_attributes
								( locality_id,
									geology_attribute,
									geo_att_value,
									geo_att_determiner_id,
									geo_att_determined_date,
									geo_att_determined_method
								) VALUES (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getParents.geology_attribute#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getParents.geo_att_value#">,
									<cfif isDefined("geo_att_determiner_id") and len(geo_att_determiner_id) GT 0>
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geo_att_determiner_id#">,
									<cfelse>
										NULL,
									</cfif>
									<cfif isDefined("geo_att_determined_date") and len(geo_att_determined_date) GT 0>
										<cfqueryparam cfsqltype="CF_SQL_DATE" value="#geo_att_determined_date#">,
									<cfelse>
										NULL,
									</cfif>
									<cfif isDefined("geo_att_determined_method") and len(geo_att_determined_method) GT 0>
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geo_att_determined_method#">
									<cfelse>
										NULL
									</cfif>
								)
						</cfquery>
						<cfset count= count + 1>
						<cfset values="#getParents.geology_attribute#:#getParents.geo_att_value#; #values#">
					</cfif>
				</cfloop>
			</cfif>
			<cfset row = StructNew()>
			<cfset row["status"] = "added">
			<cfset row["id"] = "#getPK.geology_attribute_id#">
			<cfset row["values"] = "#values#">
			<cfset row["count"] = "#count#">
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

<!--- update a geological attribute.
  @param locality_id the locality the geology_attribute_id applies to.
  @return json with status=added and id=inserted geology_attribute_id, or an http status 500.
--->
<cffunction name="updateGeologyAttribute" access="remote" returntype="any" returnformat="json">
	<cfargument name="geology_attribute_id" type="string" required="yes">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="geology_attribute" type="string" required="no">
	<cfargument name="geo_att_value" type="string" required="no">
	<cfargument name="geology_attribute_hierarchy_id" type="string" required="no">
	<cfargument name="geo_att_determiner_id" type="string" required="yes">
	<cfargument name="geo_att_determined_date" type="string" required="yes">
	<cfargument name="geo_att_determined_method" type="string" required="yes">
	<cfargument name="geo_att_remark" type="string" required="yes">
	<cfargument name="add_parents" type="string" required="no">

	<!--- either attribute+value or hierarchy_id are required to specify attribute --->
	<cfif 
		isDefined("geology_attribute_hierarchy_id") AND len(geology_attribute_hierarchy_id) GT 0
		OR ( 
			isDefined("geology_attribute") AND len(geology_attribute) GT 0
			AND
			isDefined("geo_att_value") AND len(geo_att_value) GT 0
		)
	> 
		<!--- there is a value to insert, continue --->
	<cfelse>
		<cfthrow message="Unable to update. Either a geology_attribute_heirarchy_id or both geology_attribute and geo_att_value must be specified for the attribute to update.">
	</cfif>
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfif isDefined("geology_attribute_hierarchy_id") AND len(geology_attribute_hierarchy_id) GT 0>
				<cfquery name="getGeoAttribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						attribute geology_attribute,
						attribute_value geo_att_value
					FROM
						geology_attribute_hierarchy
					WHERE 
						geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
				</cfquery>
				<cfset geology_attribute = getGeoAttribute.geology_attribute>
				<cfset geo_att_value = getGeoAttribute.geo_att_value>
			<cfelse>
				<cfquery name="getGeoAttributeId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						geology_attribute_hierarchy_id id
					FROM
						geology_attribute_hierarchy
					WHERE 
						attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geology_attribute#">
						AND
						attribute_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geo_att_value#">
				</cfquery>
				<cfif getGeoAttributeId.recordcount NEQ 1>
					<cfthrow message="Unable to insert, unable to find a geology_attribute_hierarchy record for the specified geology_attribute and geo_att_value">
				</cfif>
				<cfset geology_attribute_hierarchy_id = getGeoAttributeId.id>
			</cfif>
			<cfquery name="updateGeoAttribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="updateGeoAttribute_result">
				UPDATE geology_attributes 
				SET
					geology_attribute =<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geology_attribute#">,
					geo_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geo_att_value#">,
					<cfif isDefined("geo_att_determiner_id")>
						geo_att_determiner_id =
						<cfif len(geo_att_determiner_id) GT 0>
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geo_att_determiner_id#">,
						<cfelse>
							NULL,
						</cfif>
					</cfif>
					<cfif isDefined("geo_att_determined_date")>
						geo_att_determined_date =
						<cfif len(geo_att_determined_date) GT 0>
							<cfqueryparam cfsqltype="CF_SQL_DATE" value="#geo_att_determined_date#">,
						<cfelse>
							NULL,
						</cfif>
					</cfif>
					<cfif isDefined("geo_att_determined_method")>
						geo_att_determined_method =
						<cfif len(geo_att_determined_method) GT 0>
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geo_att_determined_method#">,
						<cfelse>
							NULL,
						</cfif>
					</cfif>
					<cfif isDefined("geo_att_remark") >
						geo_att_remark = 
						<cfif len(geo_att_remark) GT 0>
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geo_att_remark#">
						<cfelse>
							NULL
						</cfif>
					</cfif>
				WHERE 
					locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
					and 
					geology_attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_id#">
			</cfquery>
			<cfif updateGeoAttribute_result.recordcount NEQ 1>
				<cfthrow message="Error updating geology attribtue, update would affect other than one row.">
			</cfif>
			<cfset values="[Updated: #geology_attribute#:#geo_att_value#]">
			<cfset count=1>
			<cfif isDefined("add_parents") AND ucase(add_parents) EQ "YES">
				<!--- add any parents of the inserted node that aren't already present --->
				<cfquery name="getParents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT * FROM (
						SELECT 
							level as parentagelevel,
							connect_by_root attribute as geology_attribute,
							connect_by_root attribute_value as geo_att_value,
							connect_by_root geology_attribute_hierarchy_id as geology_attribute_hierarchy_id,
							connect_by_root PARENT_ID as parent_id,
							connect_by_root USABLE_VALUE_FG as USABLE_VALUE_FG,
							connect_by_root DESCRIPTION as description
						FROM geology_attribute_hierarchy 
						WHERE
							geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
						CONNECT BY PRIOR geology_attribute_hierarchy_id = parent_id
						ORDER BY level asc
					) WHERE parentagelevel > 1
				</cfquery>
				<cfloop query="getParents">
					<cfquery name="checkParents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT count(*) ct 
						FROM geology_attributes
						WHERE
							locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
							and geology_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getParents.geology_attribute#">
							and geo_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getParents.geo_att_value#">
					</cfquery>
					<cfif checkParents.ct EQ 0>
						<cfquery name="addGeoAttribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="addGeoAttribute_result">
							INSERT INTO geology_attributes
								( locality_id,
									geology_attribute,
									geo_att_value,
									geo_att_determiner_id,
									geo_att_determined_date,
									geo_att_determined_method
								) VALUES (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getParents.geology_attribute#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getParents.geo_att_value#">,
									<cfif isDefined("geo_att_determiner_id") and len(geo_att_determiner_id) GT 0>
										<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geo_att_determiner_id#">,
									<cfelse>
										NULL,
									</cfif>
									<cfif isDefined("geo_att_determined_date") and len(geo_att_determined_date) GT 0>
										<cfqueryparam cfsqltype="CF_SQL_DATE" value="#geo_att_determined_date#">,
									<cfelse>
										NULL,
									</cfif>
									<cfif isDefined("geo_att_determined_method") and len(geo_att_determined_method) GT 0>
										<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geo_att_determined_method#">
									<cfelse>
										NULL
									</cfif>
								)
						</cfquery>
						<cfset count= count + 1>
						<cfset values="(Added: #getParents.geology_attribute#:#getParents.geo_att_value#); #values#">
					</cfif>
				</cfloop>
			</cfif>
			<cfset row = StructNew()>
			<cfset row["status"] = "updated">
			<cfset row["id"] = "#geology_attribute_id#">
			<cfset row["values"] = "#values#">
			<cfset row["count"] = "#count#">
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

<!--- returns html to populate a dialog to add geological attributes to a locality 
	@param locality_id the id of the locality for which to add geological attributes
	@return html to populate a dialog, including save buttons.
--->
<cffunction name="geologyAttributeDialogHtml" access="remote" returntype="string">
	<cfargument name="locality_id" type="string" required="yes">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getGeolAttDialThread#tn#">
		<cftry>
			<cfquery name="currentAttributes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					geology_attribute_id, 
					geology_attributes.geology_attribute,
					geology_attributes.geo_att_value
				FROM
					geology_attributes
				WHERE 
					locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
			</cfquery>
			<cfquery name="types" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					distinct type
				FROM	
					ctgeology_attribute
				ORDER BY
					type
			</cfquery>
			<cfquery name="ctgeology_attribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					ctgeology_attribute.geology_attribute,
					ctgeology_attribute.type,
					ctgeology_attribute.ordinal,
					ctgeology_attribute.description
				FROM	
					ctgeology_attribute
				ORDER BY
					ctgeology_attribute.ordinal
			</cfquery>
			<cfquery name="getLabel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					nvl(spec_locality,'[No specific locality value]') locality_label
				FROM locality
				WHERE
					locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
			</cfquery>
			<cfoutput>
				<form id="addGeoAttForm">
					<input type="hidden" name="method" value="addGeologyAttribute">
					<input type="hidden" name="locality_id" value="#locality_id#">
					<h2 class="small95 mb-3">#encodeForHtml(getLabel.locality_label)#</h2>
					<div class="form-row">
						<div class="col-12 col-md-3 mb-2">
							<label for="attribute_type" class="data-entry-label">Type</label>
							<select id="attribute_type" name="attribute_type" class="data-entry-select reqdClr" onChange=" changeGeoAttType(); ">
								<cfset selected="selected">
								<cfloop query="types">
									<option value="#types.type#" #selected#>#types.type#</option>
									<cfset selected="">
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-3 mb-2">
							<label for="geo_att_value" class="data-entry-label">Attribute Value</label>
							<input type="text" id="geo_att_value" name="geo_att_value" class="data-entry-input" onFocusOut=" addParentsChange(); ">
							<input type="hidden" id="geology_attribute" name="geology_attribute">
							<input type="hidden" id="geology_attribute_hierarchy_id" name="geology_attribute_hierarchy_id">
						</div>
						<div class="col-12 col-md-2 mb-2">
							<label for="add_parents" class="data-entry-label">Add Parents</label>
							<select id="add_parents" name="add_parents" class="data-entry-select" onChange=" addParentsChange(); ">
								<option value="no" selected>No</option>
								<option value="yes">Yes</option>
							</select>
						</div>
						<div class="col-12 col-md-4 mb-2" id="parentsDiv">
							<!--- Area to show parents of selected attribute value --->
						</div>
						<div class="col-12 col-md-4 mb-2">
							<label for="determiner" class="data-entry-label">Determiner</label>
							<input type="text" id="determiner" name="determiner" class="data-entry-input">
							<input type="hidden" id="geo_att_determiner_id" name="geo_att_determiner_id">
						</div>
						<div class="col-12 col-md-4 mb-2">
							<label for="geo_att_determined_date" class="data-entry-label">Date Determined</label>
							<input type="text" name="geo_att_determined_date" id="geo_att_determined_date"
								value="#dateformat(now(),"yyyy-mm-dd")#" class="data-entry-input">
						</div>
						<div class="col-12 col-md-4 mb-2">
							<label for="geo_att_determined_method" class="data-entry-label">Determination Method</label>
							<input type="text" id="geo_att_determined_method" name="geo_att_determined_method" class="data-entry-input">
						</div>
						<div class="col-12 col-md-12 mb-2">
							<label for="geo_att_remark" class="data-entry-label">Remarks (<span id="length_geo_att_remark">0 characters, 4000 left</span>)</label>
							<textarea name="geo_att_remark" id="geo_att_remark" 
								onkeyup="countCharsLeft('geo_att_remark', 4000, 'length_geo_att_remark');"
								class="form-control form-control-sm w-100 autogrow mb-1" rows="2"></textarea>
							<script>
								// Bind textarea to autogrow function on key up
								$(document).ready(function() { 
									$("##geo_att_remark").keyup(autogrow);  
								});
							</script>
						</div>
						<div class="col-12 col-md-3 mb-2">
							<label class="data-entry-label">&nbsp;</label>
							<button type="button" class="btn btn-xs btn-primary" onClick=" saveGeoAtt(); " >Add</button>
						</div>
						<div class="col-12 col-md-3 mb-2">
							<output id="geoAttFeedback"></output>
						</div>
					</div>
				</form>
				<script>
					function addParentsChange() { 
						var selection = $('##add_parents').val();
						if (selection=="yes") { 
							lookupGeoAttParents($('##geology_attribute_hierarchy_id').val(),'parentsDiv');
						} else { 
							$('##parentsDiv').html("");
						}
					};
					function saveGeoAtt(){ 
						$('##geoAttFeedback').html('Saving....');
						$('##geoAttFeedback').addClass('text-warning');
						$('##geoAttFeedback').removeClass('text-success');
						$('##geoAttFeedback').removeClass('text-danger');
						jQuery.ajax({
							url : "/localities/component/functions.cfc",
							type : "post",
							dataType : "json",
							data : $('##addGeoAttForm').serialize(),
							success : function (data) {
								console.log(data);
								$('##geoAttFeedback').html('Saved.' + data[0].values);
								$('##geoAttFeedback').addClass('text-success');
								$('##geoAttFeedback').removeClass('text-danger');
								$('##geoAttFeedback').removeClass('text-warning');
							},
							error: function(jqXHR,textStatus,error){
								$('##geoAttFeedback').html('Error.');
								$('##geoAttFeedback').addClass('text-danger');
								$('##geoAttFeedback').removeClass('text-success');
								$('##geoAttFeedback').removeClass('text-warning');
								handleFail(jqXHR,textStatus,error,'saving geological attribute for locality');
							}
						});
					};
					function changeGeoAttType() { 
						$('##geology_attribute').val("");
						$('##geo_att_value').val("");
						makeGeologyAutocompleteMeta('geology_attribute', 'geo_att_value','geology_attribute_hierarchy_id','entry',$('##attribute_type').val());
					} 
					$(document).ready(function(){ 
						makeGeologyAutocompleteMeta('geology_attribute', 'geo_att_value','geology_attribute_hierarchy_id','entry',$('##attribute_type').val());
						makeAgentAutocompleteMeta('determiner', 'geo_att_determiner_id',true);
						$("##geo_att_determined_date").datepicker({ dateFormat: 'yy-mm-dd'});
					});
				</script>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h3 class="h4">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getGeolAttDialThread#tn#" />
	<cfreturn cfthread["getGeolAttDialThread#tn#"].output>
</cffunction>


<!--- returns html to populate a dialog to edit a geological attribute for a locality 
	@param geology_attribute_id the pk value of the geological attribute to edit.
	@param locality_id the id of the locality for which to add geological attributes
	@return html to populate a dialog, including save buttons.
--->
<cffunction name="geologyAttributeEditDialogHtml" access="remote" returntype="string">
	<cfargument name="geology_attribute_id" type="string" required="yes">
	<cfargument name="locality_id" type="string" required="yes">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="editGeoAtt#tn#">
		<cftry>
			<cfquery name="currentAttribute" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					geology_attribute_id, 
					ctgeology_attributes.type,
					geology_attribute_hierarchy_id,
					geology_attribute_hierarchy.usable_value_fg,
					geology_attributes.geology_attribute,
					geology_attributes.geo_att_value,
					geo_att_determiner_id,
					agent_name determiner,
					to_char(geo_att_determined_date,'yyyy-mm-dd') geo_att_determined_date,
					geo_att_determined_method,
					geo_att_remark
				FROM
					geology_attributes
					left join preferred_agent_name on geo_att_determiner_id = preferred_agent_name.agent_id
					join ctgeology_attributes on geology_attributes.geology_attribute = ctgeology_attributes.geology_attribute
					left join geology_attribute_hierarchy on geology_attributes.geology_attribute = geology_attribute_hierarchy.attribute 
						AND geology_attributes.geo_att_value = geology_attribute_hierarchy.attribute_value
				WHERE 
					geology_attribute_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_id#">
			</cfquery>
			<cfquery name="types" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					distinct type
				FROM	
					ctgeology_attribute
				ORDER BY
					type
			</cfquery>
			<cfquery name="getLabel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					nvl(spec_locality,'[No specific locality value]') locality_label
				FROM locality
				WHERE
					locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
			</cfquery>
			<cfoutput>
				<form id="editGeoAttForm">
					<input type="hidden" name="method" value="updateGeologyAttribute">
					<input type="hidden" name="locality_id" value="#locality_id#">
					<input type="hidden" name="geology_attribute_id" value="#geology_attribute_id#">
					<cfset spanClass="">
					<cfif currentAttribute.usable_value_fg EQ 1>
						<cfset accepted="<strong>*</strong></span>"><!---" --->
					<cfelse>
						<cfset accepted="</span>"><!--- " --->
						<cfset spanClass="text-danger">
					</cfif>
					<h2 class="h3">Edit geological attribute <span class="#spanClass#">#currentAttribute.geo_att_value# #accepted# (#currentAttribute.geology_attribute#) for locality #encodeForHtml(getLabel.locality_label)#</h2>
					<div class="form-row">
						<div class="col-12 col-md-3">
							<label for="attribute_type" class="data-entry-label">Type</label>
							<select id="attribute_type" name="attribute_type" class="data-entry-select reqdClr" onChange=" changeGeoAttType(); ">
								<cfloop query="types">
									<cfif types.type EQ currentAttribute.type><cfset selected="selected"><cfelse><cfset selected = ""></cfif>
									<option value="#types.type#" #selected#>#types.type#</option>
									<cfset selected="">
								</cfloop>
							</select>
						</div>
						<div class="col-12 col-md-3">
							<label for="geo_att_value" class="data-entry-label">Attribute Value</label>
							<input type="text" id="geo_att_value" name="geo_att_value" class="data-entry-input" onFocusOut=" addParentsChange(); " value="#encodeForHtml(currentAttribute.geo_att_value)#">
							<input type="hidden" id="geology_attribute" name="geology_attribute" value="#currentAttribute.geology_attribute#">
							<input type="hidden" id="geology_attribute_hierarchy_id" name="geology_attribute_hierarchy_id" value="#currentAttribute.geology_attribute_hierarchy_id#">
						</div>
						<div class="col-12 col-md-2">
							<label for="add_parents" class="data-entry-label">Add Parents</label>
							<select id="add_parents" name="add_parents" class="data-entry-select" onChange=" addParentsChange(); ">
								<option value="no" selected>No</option>
								<option value="yes">Yes</option>
							</select>
						</div>
						<div class="col-12 col-md-4" id="parentsDiv">
							<!--- Area to show parents of selected attribute value --->
						</div>
						<div class="col-12 col-md-4">
							<label for="determiner" class="data-entry-label">Determiner</label>
							<input type="text" id="determiner" name="determiner" class="data-entry-input" value="#encodeForHtml(currentAttribute.determiner)#">
							<input type="hidden" id="geo_att_determiner_id" name="geo_att_determiner_id" value="#currentAttribute.geo_att_determiner_id#">
						</div>
						<div class="col-12 col-md-4">
							<label for="geo_att_determined_date" class="data-entry-label">Date Determined</label>
							<input type="text" name="geo_att_determined_date" id="geo_att_determined_date"
								value="#dateformat(currentAttribute.geo_att_determined_date,"yyyy-mm-dd")#" class="data-entry-input">
						</div>
						<div class="col-12 col-md-4">
							<label for="geo_att_determined_method" class="data-entry-label">Determination Method</label>
							<input type="text" id="geo_att_determined_method" name="geo_att_determined_method" class="data-entry-input" value="#encodeForHtml(currentAttribute.geo_att_determined_method)#">
						</div>
						<div class="col-12 col-md-12">
							<label for="geo_att_remark" class="data-entry-label">Remarks (<span id="length_geo_att_remark">0 characters, 4000 left</span>)</label>
							<textarea name="geo_att_remark" id="geo_att_remark" 
								onkeyup="countCharsLeft('geo_att_remark', 4000, 'length_geo_att_remark');"
								class="form-control form-control-sm w-100 autogrow mb-1" rows="2">#encodeForHtml(currentAttribute.geo_att_remark)#</textarea>
							<script>
								// Bind textarea to autogrow function on key up
								$(document).ready(function() { 
									$("##geo_att_remark").keyup(autogrow);  
								});
							</script>
						</div>
						<div class="col-12 col-md-3">
							<label class="data-entry-label">&nbsp;</label>
							<button type="button" class="btn btn-xs btn-primary" onClick=" saveGeoAttChanges(); " >Save</button>
						</div>
						<div class="col-12 col-md-3">
							<output id="geoAttFeedback"></output>
						</div>
					</div>
				</form>
				<script>
					function handleChange(){
						$('##geoAttFeedback').html('Unsaved changes.');
						$('##geoAttFeedback').addClass('text-danger');
						$('##geoAttFeedback').removeClass('text-success');
						$('##geoAttFeedback').removeClass('text-warning');
					};
					$(document).ready(function() {
						monitorForChangesGeneric('editGeoAttForm',handleChange);
					});
					function addParentsChange() { 
						var selection = $('##add_parents').val();
						if (selection=="yes") { 
							lookupGeoAttParents($('##geology_attribute_hierarchy_id').val(),'parentsDiv');
						} else { 
							$('##parentsDiv').html("");
						}
					};
					function saveGeoAttChanges(){ 
						$('##geoAttFeedback').html('Saving....');
						$('##geoAttFeedback').addClass('text-warning');
						$('##geoAttFeedback').removeClass('text-success');
						$('##geoAttFeedback').removeClass('text-danger');
						jQuery.ajax({
							url : "/localities/component/functions.cfc",
							type : "post",
							dataType : "json",
							data : $('##editGeoAttForm').serialize(),
							success : function (data) {
								console.log(data);
								$('##geoAttFeedback').html('Saved.' + data[0].values);
								$('##geoAttFeedback').addClass('text-success');
								$('##geoAttFeedback').removeClass('text-danger');
								$('##geoAttFeedback').removeClass('text-warning');
							},
							error: function(jqXHR,textStatus,error){
								$('##geoAttFeedback').html('Error.');
								$('##geoAttFeedback').addClass('text-danger');
								$('##geoAttFeedback').removeClass('text-success');
								$('##geoAttFeedback').removeClass('text-warning');
								handleFail(jqXHR,textStatus,error,'saving changes to geological attribute for locality');
							}
						});
					};
					function changeGeoAttType() { 
						$('##geology_attribute').val("");
						$('##geo_att_value').val("");
						makeGeologyAutocompleteMeta('geology_attribute', 'geo_att_value','geology_attribute_hierarchy_id','entry',$('##attribute_type').val());
					} 
					$(document).ready(function(){ 
						makeGeologyAutocompleteMeta('geology_attribute', 'geo_att_value','geology_attribute_hierarchy_id','entry',$('##attribute_type').val());
						makeAgentAutocompleteMeta('determiner', 'geo_att_determiner_id',true);
						$("##geo_att_determined_date").datepicker({ dateFormat: 'yy-mm-dd'});
						lookupGeoAttParents($('##geology_attribute_hierarchy_id').val(),'parentsDiv');
					});
				</script>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h3 class="h4">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="editGeoAtt#tn#" />
	<cfreturn cfthread["editGeoAtt#tn#"].output>
</cffunction>

<!--- getCreateLocalityHtml returns html for a set of form inputs to create or clone a locality record, optionally with
higher geography specified, optionally cloning from an existing locality, optionally with field values specified.
Does not provide the enclosing form.  Expected context provided by calling page:

<cfset blockform = getCreateLocalityHtml()>
<main class="container mt-3" id="content">
	<section class="row">
		<div class="col-12">
     		<h1 class="h2 mt-3 pl-1 ml-2" id="formheading">Create New Locality#extra#</h1>
			<div class="border rounded px-2 py-2" arial-labeledby="formheading">
     			<form name="createLocality" method="post" action="/localities/Locality.cfm">
  			   	<input type="hidden" name="Action" value="makenewLocality">
					#blockform#
				</form>
			</div>
		</div>
	</section>
</main>

@param clone_from_locality_id if specified and a matching locality is found, copy the fields 
  from the specified locality into the form and ignore any other specified values.
@param geog_auth_rec_id if specified, populate the higher geography fields in the form with this
  higher geography, use to link a create a locality form from a higher geography.
@return html block for the content of a create locality form.
--->
<cffunction name="getCreateLocalityHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="clone_from_locality_id" type="string" required="no">
	<cfargument name="geog_auth_rec_id" type="string" required="no">
	<cfargument name="spec_locality" type="string" required="no">
	<cfargument name="sovereign_nation" type="string" required="no">
	<cfargument name="minimum_elevation" type="string" required="no">
	<cfargument name="maximum_elevation" type="string" required="no">
	<cfargument name="orig_elev_units" type="string" required="no">
	<cfargument name="min_depth" type="string" required="no">
	<cfargument name="max_depth" type="string" required="no">
	<cfargument name="section_part" type="string" required="no">
	<cfargument name="section" type="string" required="no">
	<cfargument name="township" type="string" required="no">
	<cfargument name="township_direction" type="string" required="no">
	<cfargument name="range" type="string" required="no">
	<cfargument name="range_direction" type="string" required="no">
	<cfargument name="depth_units" type="string" required="no">
	<cfargument name="curated_fg" type="string" required="no">
	<cfargument name="locality_remarks" type="string" required="no">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="createLocalityFormThread#tn#">
		<cfoutput>
			<cfquery name="ctElevUnit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
				SELECT orig_elev_units 
				FROM ctorig_elev_units 
				ORDER BY orig_elev_units
			</cfquery>
			<cfquery name="ctDepthUnit" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
				SELECT depth_units as unit
				FROM ctdepth_units 
				ORDER BY depth_units
			</cfquery>
			<cfif isdefined('clone_from_locality_id') AND len(clone_from_locality_id) GT 0>
				<cfquery name="lookupLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT geog_auth_rec_id, spec_locality, sovereign_nation, 
						minimum_elevation, maximum_elevation, orig_elev_units, 
						min_depth, max_depth, depth_units,
						section_part, section, township, township_direction, range, range_direction,
						curated_fg, locality_remarks
					FROM locality
					WHERE 
						locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#clone_from_locality_id#">
				</cfquery>
				<!--- by design, overwrite any other provided value --->
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
					<cfset section_part = "#lookupLocality.section_part#">
					<cfset section = "#lookupLocality.section#">
					<cfset township = "#lookupLocality.township#">
					<cfset township_direction = "#lookupLocality.township_direction#">
					<cfset range = "#lookupLocality.range#">
					<cfset range_direction = "#lookupLocality.range_direction#">
					<cfset curated_fg = "#lookupLocality.curated_fg#">
					<cfset locality_remarks = "#lookupLocality.locality_remarks#">
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
			<div class="form-row mx-0">
				<div class="col-12 col-md-10 mb-2">
					<input type="hidden" name="geog_auth_rec_id" id="geog_auth_rec_id" value="#geog_auth_rec_id#">
					<label class="data-entry-label" for="higher_geog">Higher Geography:</label>
					<input type="text" name="higher_geog" id="higher_geog" class="data-entry-input reqdClr" value = "#encodeForHTML(higher_geog)#" required>
					<script>
						function setSovereignNation(){
							if ($("##geog_auth_rec_id").val() && ! $("##sovereign_nation").val()){
								<!--- Set a probably sane value for sovereign_nation from selected higher geography. --->
								var geog = $("##geog_auth_rec_id").val();
								console.log(geog);
								suggestSovereignNation(geog, "sovereign_nation");
							}
						}
						$(document).ready(function() {
							makeHigherGeogAutocomplete("higher_geog","geog_auth_rec_id");
							$("##higher_geog").on("change", function(evt){ 
								setSovereignNation();
								if ($("##higher_geog").val()) { 
									$("##details_button").removeClass("disabled");
									$("##details_button").attr("href","/localities/viewHigherGeography.cfm?geog_auth_rec_id="+$("##geog_auth_rec_id").val());
								} else { 
									$("##details_button").addClass("disabled");
								}
							});
						});
					</script>
				</div>
				<div class="col-12 col-md-2 mb-2 mt-md-3 mb-md-2">
					<label class="data-entry-label text-white sr-only" for="details_button">Higher Geography</label>
					<cfset otherClass="disabled">
					<cfif isdefined("geog_auth_rec_id") and len(geog_auth_rec_id) GT 0>
						<cfset otherClass="">
					</cfif>
					<a value="Details" id="details_button" class="btn btn-xs btn-info #otherClass# mb-1 mb-md-0"
						href="/localities/viewHigherGeography.cfm?geog_auth_rec_id=#geog_auth_rec_id#" target="_blank">Details</a>
					<script>
						$(document).ready( function() { 
							$('##details_button').on('click', function(e) {
								if($('##details_button').hasClass('disabled')) {
									e.preventDefault();
								} 
							});
						});
					</script>
				</div>
				<div class="col-12 mb-2 mb-md-2">
					<label class="data-entry-label" for="spec_locality">Specific Locality</label>
					<cfif NOT isdefined("spec_locality")><cfset spec_locality=""></cfif>
					<input type="text" name="spec_locality" id="spec_locality" class="data-entry-input reqdClr" value="#encodeForHTML(spec_locality)#" required>
				</div>
				<div class="col-12 col-md-4 mb-2 mb-md-2">
					<cfif NOT isdefined("sovereign_nation")><cfset sovereign_nation=""></cfif>
					<label class="data-entry-label" for="sovereign_nation">
						Sovereign Nation
						<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##sovereign_nation').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open pick list</span></a>
					</label>
					<input type="text" name="sovereign_nation" id="sovereign_nation" class="data-entry-input reqdClr" value="#encodeforHTML(sovereign_nation)#" required>
					<script>
						$(document).ready(function() {
							makeSovereignNationAutocomplete("sovereign_nation");
						});
					</script>
				</div>
				<div class="col-12 col-md-2 mb-2 mb-md-2">
					<label class="data-entry-label" for="curated_fg">Vetted</label>
					<select name="curated_fg" id="curated_fg" size="1" class="data-entry-select reqdClr">
						<cfif not isDefined("curated_fg") OR (isdefined("curated_fg") AND curated_fg NEQ 1) ><cfset selected="selected"><cfelse><cfset selected=""></cfif>
						<option value="0" #selected#>No</option>
						<cfif isdefined("curated_fg") AND curated_fg EQ 1 ><cfset selected="selected"><cfelse><cfset selected=""></cfif>
						<option value="1" #selected#>Yes (*)</option>
					</select>
				</div>
			</div>
			<div class="form-row mx-0 mb-1">
				<div class="col-12 col-md-2 mb-1 mb-md-2">
					<cfif NOT isdefined("minimum_elevation")><cfset minimum_elevation=""></cfif> 
					<label class="data-entry-label" for="minimum_elevation"><strong>Elevation</strong>: Minimum</label>
					<input type="text" name="minimum_elevation" id="minimum_elevation" class="data-entry-input" value="#encodeForHTML(minimum_elevation)#" >
				</div>
				<div class="col-12 col-md-2 mb-1 mb-md-2">
					<cfif NOT isdefined("maximum_elevation")><cfset maximum_elevation=""></cfif>
					<label class="data-entry-label" for="maximum_elevation">Maximum Elevation</label>
					<input type="text" name="maximum_elevation" id="maximum_elevation" class="data-entry-input" value="#encodeForHTML(maximum_elevation)#" >
				</div>
				<div class="col-12 col-md-2 mb-1 mb-md-2">
					<label class="data-entry-label" for="orig_elev_units">Elevation Units</label>
					<select name="orig_elev_units" id="orig_elev_units" size="1" class="data-entry-select">
						<option value=""></option>
						<cfloop query="ctElevUnit">
							<cfif isdefined("orig_elev_units") AND ctelevunit.orig_elev_units is orig_elev_units><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option #selected# value="#ctElevUnit.orig_elev_units#">#ctElevUnit.orig_elev_units#</option>
						</cfloop>
					</select>
				</div>
						
				<div class="col-12 col-md-2 mb-1 mb-md-2">
					<cfif NOT isdefined("min_depth")><cfset min_depth=""></cfif> 
					<label class="data-entry-label" for="min_depth"><strong>Depth</strong>: Minimum</label>
					<input type="text" name="min_depth" id="min_depth" class="data-entry-input" value="#encodeForHTML(min_depth)#" >
				</div>
				<div class="col-12 col-md-2 mb-1 mb-md-2">
					<cfif NOT isdefined("max_depth")><cfset max_depth=""></cfif>
					<label class="data-entry-label" for="max_depth">Maximum Depth</label>
					<input type="text" name="max_depth" id="max_depth" class="data-entry-input" value="#encodeForHTML(max_depth)#" >
				</div>
				<div class="col-12 col-md-2 mb-1 mb-md-2">
					<label class="data-entry-label" for="depth_units">Depth Units</label>
					<select name="depth_units" id="depth_units" size="1" class="data-entry-select">
						<option value=""></option>
						<cfloop query="ctDepthUnit">
							<cfif isdefined("depth_units") AND ctDepthUnit.unit is depth_units><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option #selected# value="#ctDepthUnit.unit#">#ctDepthUnit.unit#</option>
						</cfloop>
					</select>
				</div>
					
			</div>
			<div class="form-row border rounded mx-1 px-1 mt-1 mb-2 pt-2 pb-1">
				<div class="col-12 col-md-2 mb-1 mb-md-2">
					<cfif NOT isdefined("section_part")><cfset section_part=""></cfif>
					<label class="data-entry-label" for="section_part"><strong>PLSS</strong> Section Part</label>
					<input type="text" name="section_part" id="section_part" class="data-entry-input" value="#encodeForHTML(section_part)#" placeholder="NW 1/4" >
				</div>
				<div class="col-12 col-md-2 mb-1 mb-md-2">
					<cfif NOT isdefined("section")><cfset section=""></cfif>
					<label class="data-entry-label" for="section">Section</label>
					<input type="text" name="section" id="section" class="data-entry-input" value="#encodeForHTML(section)#" pattern="[0-3]{0,1}[0-9]{0,1}" >
				</div>
				<div class="col-12 col-md-2 mb-1 mb-md-2">
					<cfif NOT isdefined("township")><cfset township=""></cfif>
					<label class="data-entry-label" for="township">Township</label>
					<input type="text" name="township" id="township" class="data-entry-input" value="#encodeForHTML(township)#" pattern="[0-9]+" >
				</div>
				<div class="col-12 col-md-2 mb-1 mb-md-2">
					<cfif NOT isdefined("township_direction")><cfset township_direction=""></cfif>
					<label class="data-entry-label" for="township_direction">Township Direction</label>
					<input type="text" name="township_direction" id="township_direction" class="data-entry-input" value="#encodeForHTML(township_direction)#" >
				</div>
				<div class="col-12 col-md-2 mb-1 mb-md-2">
					<cfif NOT isdefined("range")><cfset range=""></cfif>
					<label class="data-entry-label" for="range">Range</label>
					<input type="text" name="range" id="range" class="data-entry-input" value="#encodeForHTML(range)#" pattern="[0-9]+">
				</div>
				<div class="col-12 col-md-2 mb-1 mb-md-2">
					<cfif NOT isdefined("range_direction")><cfset range_direction=""></cfif>
					<label class="data-entry-label" for="range_direction">Range Direction</label>
					<input type="text" name="range_direction" id="range_direction" class="data-entry-input" value="#encodeForHTML(range_direction)#" >
				</div>
			</div>
			<div class="form-row mx-0 mb-1 mb-md-2">
				<cfif isdefined("clone_from_locality_id") and len(clone_from_locality_id) gt 0>
					<cfset remarksClass = "col-md-9">
				<cfelse>
					<cfset remarksClass = "">
				</cfif>
				<div class="col-12 #remarksClass#">
					<cfif NOT isdefined("locality_remarks")><cfset locality_remarks=""></cfif>
					<label class="data-entry-label" for="locality_remarks">Locality Remarks (<span id="length_locality_remarks"></span>)</label>
					<textarea name="locality_remarks" id="locality_remarks" 
						onkeyup="countCharsLeft('locality_remarks', 4000, 'length_locality_remarks');"
						class="form-control form-control-sm w-100 autogrow mb-1" rows="2">#encodeForHtml(locality_remarks)#</textarea>
					<script>
						// Bind input to autogrow function on key up, and trigger autogrow to fit text
						$(document).ready(function() { 
							$("##locality_remarks").keyup(autogrow);  
							$('##locality_remarks').keyup();
						});
					</script>
				</div>
				<cfif isdefined("clone_from_locality_id") and len(clone_from_locality_id) gt 0>
					<div class="col-12 col-md-3 my-2 px-1">
						<input type="hidden" name="clone_from_locality_id" value="#clone_from_locality_id#" />
						<h2 class="h4 w-100 px-3" for="">Include accepted georeference from <a href="/localities/viewLocality.cfm?locality_id=#clone_from_locality_id#" target="_blank">#clone_from_locality_id#</a>?</h2>
						<div class="input-group-prepend col-6 mt-2 float-left rounded">
							<span class="px-2">Yes</span>
							<div class="input-group-text">
								<input type="radio" name="cloneCoords" value="yes" />
							</div>
						</div>
						<div class="input-group-prepend col-6 mt-2 float-left rounded">
							<span class="px-2">No</span>
							<div class="input-group-text">
								<input type="radio" name="cloneCoords" value="no" checked="checked" />
							</div>
						</div>
					</div>
		 		</cfif>
				<div class="col-6 mt-1">
					<input type="submit" value="Save" class="btn btn-xs btn-primary">
				</div>
			</div>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="createLocalityFormThread#tn#" />

	<cfreturn cfthread["createLocalityFormThread#tn#"].output>

</cffunction>

<!--- delete a georeference.
  @param locality_id the primary key value of the locality from which to delete the lat_long
  @param lat_long_id the primary key value of the georeference to delete.
  @return json with status=deleted, or an http status 500.
--->
<cffunction name="deleteGeoreference" access="remote" returntype="any" returnformat="json">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="lat_long_id" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="getGeoreference" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					lat_long_id
					accepted_lat_long_fg
				FROM
					lat_long
				WHERE 
					locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
					and 
					lat_long_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lat_long_id#">
				ORDER BY
					accepted_lat_long_fg desc
			</cfquery>
			<cfif getGeoreference.recordcount NEQ "1">
				<cfthrow message="Unable to delete. Found more than one georefrence for lat_long_id and locality_id provided.">
			</cfif>
			<cfquery name="deleteGeoreference" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="delete_result">
				DELETE FROM lat_long
				WHERE 
					lat_long_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lat_long_id#">
			</cfquery>
			<cfif delete_result.recordcount NEQ 1>
				<cfthrow message="Error deleteing georeference, provided lat_long_id matched other than one record.">
			</cfif>
			<cfset row = StructNew()>
			<cfset row["status"] = "deleted">
			<cfset row["id"] = "#locality_id#">
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

<cffunction name="getLocalityGeoreferencesHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="callback_name" type="string" required="yes">

	<cfset variables.callback_name = arguments.callback_name>
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="localityGeoRefFormThread#tn#">
		<cfoutput>
			<cftry>
				<cfquery name="getLocalityMetadata" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						nvl(spec_locality,'[No specific locality value]') spec_locality, 
						locality_id, 
						decode(curated_fg,1,' *','') curated
					FROM locality
					WHERE
						locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
				</cfquery>
				<cfif getLocalityMetadata.recordcount NEQ 1>
					<cfthrow message="Other than one locality found for the specified locality_id [#encodeForHtml(locality_id)#].  Locality may be used only by a department for which you do not have access.">
				</cfif>
				<cfquery name="getGeoreferences" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						lat_long_id,
						georefmethod,
						nvl2(coordinate_precision, round(dec_lat,coordinate_precision), round(dec_lat,5)) dec_lat,
						dec_lat raw_dec_lat,
						nvl2(coordinate_precision, round(dec_long,coordinate_precision), round(dec_long,5)) dec_long,
						dec_long raw_dec_long,
						max_error_distance,
						max_error_units,
						round(to_meters(lat_long.max_error_distance, lat_long.max_error_units)) coordinateUncertaintyInMeters,
						error_polygon,
						datum,
						extent,
						extent_units,
						to_meters(lat_long.extent, lat_long.extent_units) extentInMeters,
						spatialfit,
						footprint_spatialfit,
						determined_by_agent_id,
						det_agent.agent_name determined_by,
						determined_date,
						gpsaccuracy,
						lat_long_ref_source,
						nearest_named_place,
						lat_long_for_nnp_fg,
						verificationstatus,
						field_verified_fg,
						verified_by_agent_id,
						ver_agent.agent_name verified_by,
						orig_lat_long_units,
						lat_deg, dec_lat_min, lat_min, lat_sec, lat_dir,
						long_deg, dec_long_min, long_min, long_sec, long_dir,
						utm_zone, utm_ew, utm_ns,
						CASE orig_lat_long_units
							WHEN 'decimal degrees' THEN dec_lat || '&##176;'
							WHEN 'deg. min. sec.' THEN lat_deg || '&##176; ' || lat_min || '&apos; ' || lat_sec || '&quot; ' || lat_dir
							WHEN 'degrees dec. minutes' THEN lat_deg || '&##176; ' || dec_lat_min || '&apos; ' || lat_dir
						END as LatitudeString,
						CASE orig_lat_long_units
							WHEN 'decimal degrees' THEN dec_long || '&##176;'
							WHEN'degrees dec. minutes' THEN long_deg || '&##176; ' || dec_long_min || '&apos; ' || long_dir
							WHEN 'deg. min. sec.' THEN long_deg || '&##176; ' || long_min || '&apos; ' || long_sec || '&quot ' || long_dir
						END as LongitudeString,
						accepted_lat_long_fg,
						decode(accepted_lat_long_fg,1,'Accepted','') accepted_lat_long,
						geolocate_uncertaintypolygon,
						geolocate_score,
						geolocate_precision,
						geolocate_numresults,
						geolocate_parsepattern,
						lat_long_remarks
					FROM
						lat_long
						left join preferred_agent_name det_agent on lat_long.determined_by_agent_id = det_agent.agent_id
						left join preferred_agent_name ver_agent on lat_long.verified_by_agent_id = ver_agent.agent_id
					WHERE 
						lat_long.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
					ORDER BY
						accepted_lat_long_fg desc
				</cfquery>
				<h3 class="h4 w-100">Georeferences (#getGeoreferences.recordcount#)</h3>
				<cfif getGeoreferences.recordcount EQ 0>
					<cfquery name="checkNoGeorefBecause" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT
							nogeorefbecause
						FROM
							locality
						WHERE
							locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
					</cfquery>
					<cfif len(checkNoGeorefBecause.nogeorefbecause) EQ 0 >
						<cfset noGeoRef = "<span class='text-warning'> - Add a georeference or put a value in Not Georeferenced Because.</span>"><!--- " --->
					<cfelse> 
						<cfset noGeoRef = " (#checkNoGeorefBecause.nogeorefbecause#)">
					</cfif>
					<div class="w-100">
						<ul>
							<li>None #noGeoRef#</li>
						</ul>
							<button type="button" class="btn btn-xs btn-secondary" 
									onClick=" openAddGeoreferenceDialog('addGeorefDialog', '#locality_id#', #callback_name#) " 
									aria-label = "Add a georeference to this locality"
							>Add</button>
							<button type="button" class="btn btn-xs btn-secondary" 
								onClick=" openAddGeoreferenceDialog('addGeorefDialog1', '#locality_id#', #callback_name#, 'yes') " 
								aria-label = "Add another georeference to this locality going straight to GeoLocate"
							>Add using GeoLocate</button>
					</div>
				<cfelse>
					<div class="w-100">
						<cfloop query="getGeoreferences">
								<cfset original="">
								<cfset det = "">
								<cfset ver = "">
								<cfif len(determined_by) GT 0>
									<cfset det = " Determiner: #determined_by#. ">
								</cfif>
								<cfif len(verified_by) GT 0>
									<cfset ver = " Verified by: #verified_by#. ">
								</cfif>
								<cfif len(utm_zone) GT 0>
									<cfset original = "(as: #utm_zone# #utm_ew# #utm_ns#)">
								<cfelse>
									<cfset original = "(as: #LatitudeString#,#LongitudeString#)">
								</cfif>
								<cfset divClass="small90 my-1 w-100">
								<cfif accepted_lat_long EQ "Accepted">
									<cfset divClass="small90 font-weight-lessbold my-1 w-100">
								</cfif>
								<div class="#divClass#">#dec_lat#, #dec_long# &nbsp; #datum# ±#coordinateUncertaintyInMeters#m</div>
								<ul class="mb-2">
									<li>
										#original# <span class="#divClass#">#accepted_lat_long#</span>
									</li>
									<li>
										Method: #georefmethod# #det# Verification: #verificationstatus# #ver#
									</li>
									<cfif len(spatialfit) GT 0>
										<li>
											<cfif spatialfit EQ 0>
												<cfset spatialfit_interp = " Actual locality larger than point-radius.">
											<cfelseif spatialfit EQ 1>
												<cfset spatialfit_interp = " Actual locality is the same as the point-radius">
											<cfelse>
												<cfset spatialfit_interp = ":1 (ratio of point-radius to actual locality)">
											</cfif>
											Point Radius Spatial Fit: #spatialfit##spatialfit_interp#
										</li>
									</cfif>
									<cfif len(error_polygon) GT 0>
										<li>Has Footprint.
											<cfif footprint_spatialfit EQ 0>
												<cfset spatialfit_interp = " Actual locality larger than footprint.">
											<cfelseif spatialfit EQ 1>
												<cfset spatialfit_interp = " Actual locality is the same as the footprint">
											<cfelse>
												<cfset spatialfit_interp = ":1 (ratio of footprint to actual locality)">
											</cfif>
											Footprint Spatial Fit: #footprint_spatialfit##spatialfit_interp#
										</li>
									</cfif>
									<cfif len(geolocate_score) GT 0>
										<li>
											GeoLocate: score=#geolocate_score# precision=#geolocate_precision# results=#geolocate_numresults# pattern=#geolocate_parsepattern#
										</li>
									</cfif>
									<cfif len(extent) GT 0>
										<li>
											Radial of feature: #extentInMeters# m
										</li>
									</cfif>
									<cfif len(nearest_named_place) GT 0>
										<cfif lat_long_for_nnp_fg EQ 1>
											<cfset label = "Georefrence is for Nearest Named Place: ">
										<cfelse>
											<cfset label = "Nearest Named Place is ">
										</cfif>
										<li>
											#label##nearest_named_place#
										</li>
									</cfif>
								</ul>
								<script>
									var bouncing#lat_long_id# = false;
									function toggleBounce#lat_long_id#() { 
										if (bouncing#lat_long_id#==true) { 
											bouncing#lat_long_id# = false;
											map.data.forEach(function (feature) { console.log(feature.getId()); if (feature.getId() == "#lat_long_id#") { map.data.overrideStyle(feature, { animation: null });  } }); 
											$('##toggleButton#lat_long_id#').html("Highlight on map");
										} else { 
											bouncing#lat_long_id# = true;
											map.data.forEach(function (feature) { console.log(feature.getId()); if (feature.getId() == "#lat_long_id#") { map.data.overrideStyle(feature, { animation: google.maps.Animation.BOUNCE});  } }); 
											$('##toggleButton#lat_long_id#').html("Stop bouncing");
										}
									};
								</script>
								<button type="button" id="toggleButton#lat_long_id#" class="btn btn-xs btn-info mb-1" onClick=" toggleBounce#lat_long_id#(); ">Highlight on map</button>
								<button type="button" class="btn btn-xs btn-secondary mb-1" 
									onClick=" openEditGeorefDialog('#lat_long_id#','editGeorefDialog',#callback_name#);"
									aria-label = "Edit this georeference"
								>Edit</button>
								<button type="button" class="btn btn-xs btn-warning mb-1" 
									onClick=" confirmDialog('Delete this georeference?  Georeferences should not normally be deleted.  In most cases, a new accepted georeference should be added instead.','Confirm Delete Georeference', doDeleteGeoref ); "
									aria-label = "Delete this georeference from this locality"
								>Delete</button>
								<script>
									function doDeleteGeoref() { 
										deleteGeoreference('#locality_id#','#lat_long_id#',#callback_name#);
									};
								</script>
							</cfloop>
					</div>
						<button type="button" class="btn btn-xs btn-secondary mt-3" 
							onClick=" openAddGeoreferenceDialog('addGeorefDialog', '#locality_id#', #callback_name#) " 
							aria-label = "Add another georeference to this locality"
						>Add</button>
						<button type="button" class="btn btn-xs btn-secondary mt-3" 
							onClick=" openAddGeoreferenceDialog('addGeorefDialog1', '#locality_id#', #callback_name#, 'yes') " 
							aria-label = "Add another georeference to this locality going straight to GeoLocate"
						>Add using GeoLocate</button>
				</cfif>
				<div id="editGeorefDialog"></div>
				<div id="addGeorefDialog"></div>
				<div id="addGeorefDialog1"></div>
				<output id="georeferenceDialogFeedback">&nbsp;</output>	
			<cfcatch>
				<h3 class="h4 text-danger">Error: #cfcatch.type# #cfcatch.message#</h3> 
				<div>#cfcatch.detail#</div>
				<cfif isDefined("cfcatch.cause.tagcontext")>
					<div>Line #cfcatch.cause.tagcontext[1].line# of #replace(cfcatch.cause.tagcontext[1].template,Application.webdirectory,'')#</div>
				</cfif>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="localityGeoRefFormThread#tn#" />

	<cfreturn cfthread["localityGeoRefFormThread#tn#"].output>
</cffunction>

<!--- given a locality_id create the html for a dialog to add a georeference to the locality
  @param locality_id the locality to which to add the georeference.
  @param geolocateImmediate optional, if yes, then immediately invoke geolocate on opening the dialog.
  @return html for a dialog, or html with an error message.
--->
<cffunction name="georeferenceDialogHtml" access="remote" returntype="string">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="geolocateImmediate" type="string" required="no" default="no">

	<cfset variables.geolocateImmediate = arguments.geolocateImmediate>

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getGeorefThread#tn#">
		<cftry>
			<cfquery name="ctunits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT ORIG_LAT_LONG_UNITS 
				FROM ctlat_long_units
				ORDER BY ORIG_LAT_LONG_UNITS
			</cfquery>
			<cfquery name="ctGeorefMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT georefmethod 
				FROM ctgeorefmethod
				ORDER BY georefmethod
			</cfquery>
			<cfquery name="ctVerificationStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT verificationStatus 
				FROM ctVerificationStatus 
				ORDER BY verificationStatus
			</cfquery>
			<cfquery name="lookupForGeolocate" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					country, state_prov, county,
					spec_locality
				FROM locality
					join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
				WHERE
					locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
			</cfquery>
			<cfquery name="getCurrentUser" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT agent_id, 
						agent_name
				FROM preferred_agent_name
				WHERE
					agent_id in (
						SELECT agent_id 
						FROM agent_name 
						WHERE upper(agent_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(session.username)#">
							and agent_name_type = 'login'
					)
			</cfquery>
			<cfquery name="getLocalityMetadata" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					nvl(spec_locality,'[No specific locality value]') spec_locality, 
					locality_id, 
					decode(curated_fg,1,' *','') curated
				FROM locality
				WHERE
					locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
			</cfquery>
			<cfif getLocalityMetadata.recordcount NEQ 1>
				<cfthrow message="Other than one locality found for the specified locality_id [#encodeForHtml(locality_id)#].  Locality may be used only by a department for which you do not have access.">
			</cfif>
			<cfset locality_label = "#getLocalityMetadata.spec_locality##getLocalityMetadata.curated#">
			<cfoutput>
				<h2 class="h3 mt-0 px-1 font-weight-bold">
					New Georeference
					<i class="fas fa-info-circle" onClick="getMCZDocs('Georeferencing')" aria-label="georeferencing help link"></i>
					For Locality:
					#encodeForHtml(locality_label)#</p>
				</h2>
				<p class="small95 col-12 d-block px-0 pb-0 mb-0">See: Chapman A.D. &amp; Wieczorek J.R. 2020, Georeferencing Best Practices. Copenhagen: GBIF Secretariat. <a href="https://doi.org/10.15468/doc-gg7h-s853" target="_blank">DOI:10.15468/doc-gg7h-s853</a>.</p>
				<div>
					<div class="tabs card-header tab-card-header px-2 pt-3">
						<!-- Nav tabs -->
						<div class="tab-headers tabList px-0 px-md-3" role="tablist" aria-label="create georeference by">
							<button class="col-12 px-1 px-sm-2 col-xl-auto px-xl-5 my-1 my-md-0 active" id="manualTabButton" tabid="1" role="tab" aria-controls="manualPanel" aria-selected="true" tabindex="0" aria-label="Enter original coordinates">You have original coordinates: Enter manually</button>
							<button class="col-12 px-1 px-sm-2 col-xl-auto px-xl-5 my-1 my-md-0 text-truncate" id="geolocateTabButton" tabid="2" role="tab" aria-controls="geolocatePanel" aria-selected="false" tabindex="-1" aria-label="Use geolocate to georeference specific locality">Use Geolocate with Specific Locality</button>
							<button class="col-12 px-1 px-sm-2 col-xl-auto px-xl-5 my-1 my-md-0 text-truncate" id="cloneTabButton" tabid="2" role="tab" aria-controls="clonePanel" aria-selected="false" tabindex="-1" aria-label="Clone from another locality">Clone from another Locality</button>
						</div>
						<!-- Tab panes -->
						<script>
							$(document).ready(loadTabs);
						</script>
						<div class="tab-content  pt-1 flex-wrap d-flex">
							<div id="manualPanel" role="tabpanel" aria-labelledby="manualTabButton" tabindex="0" class="col-12 px-0 mx-0 active unfocus">
								<form id="manualGeorefForm">
									<input type="hidden" name="method" value="addGeoreference">
									<input type="hidden" name="field_mapping" value="generic"> 
									<input type="hidden" name="locality_id" value="#locality_id#">
									<h2 class="px-1 h3">Enter georeference</h2>
									<div class="form-row">
										<div class="col-12 col-md-3 mb-2">
											<label for="orig_lat_long_units" class="data-entry-label">Coordinate Format</label>
											<select id="orig_lat_long_units" name="orig_lat_long_units" class="data-entry-select reqdClr" onChange=" changeLatLongUnits(); ">
												<option></option>
												<option value="decimal degrees">decimal degrees</option>
												<option value="degrees dec. minutes">degrees decimal minutes</option>
												<option value="deg. min. sec.">deg. min. sec.</option>
												<option value="UTM">UTM (Universal Transverse Mercator)</option>
											</select>
											<script>
												function changeLatLongUnits(){ 
													$(".latlong").prop('disabled', true);
													$(".latlong").prop('required', false);
													$(".latlong").removeClass('reqdClr');
													$(".latlong").addClass('bg-lt-gray');
													$(".utm").removeClass('reqdClr');
													$(".utm").addClass('bg-lt-gray');
													$(".utm").prop('disabled', true);
													$(".utm").prop('required', false);
													var units = $("##orig_lat_long_units").val();
													if (!units) { 
														$(".latlong").prop('disabled', true);
														$(".utm").prop('disabled', true);
													} else if (units == 'decimal degrees') {
														$("##lat_deg").prop('disabled', false);
														$("##lat_deg").prop('required', true);
														$("##lat_deg").addClass('reqdClr');
														$("##lat_deg").removeClass('bg-lt-grey');
														$("##long_deg").prop('disabled', false);
														$("##long_deg").prop('required', true);
														$("##long_deg").addClass('reqdClr');
														$("##long_deg").removeClass('bg-lt-grey');
													} else if (units == 'degrees dec. minutes') {
														$("##lat_deg").prop('disabled', false);
														$("##lat_deg").prop('required', true);
														$("##lat_deg").addClass('reqdClr');
														$("##lat_deg").removeClass('bg-lt-grey');
														$("##lat_min").prop('disabled', false);
														$("##lat_min").prop('required', true);
														$("##lat_min").addClass('reqdClr');
														$("##lat_min").removeClass('bg-lt-grey');
														$("##lat_dir").prop('disabled', false);
														$("##lat_dir").prop('required', true);
														$("##lat_dir").addClass('reqdClr');
														$("##long_deg").prop('disabled', false);
														$("##long_deg").prop('required', true);
														$("##long_deg").addClass('reqdClr');
														$("##long_deg").removeClass('bg-lt-grey');
														$("##long_min").prop('disabled', false);
														$("##long_mit").prop('required', true);
														$("##long_min").addClass('reqdClr');
														$("##long_min").removeClass('bg-lt-grey');
														$("##long_dir").prop('disabled', false);
														$("##long_dir").prop('required', true);
														$("##long_dir").addClass('reqdClr');
														$("##long_dir").removeClass('bg-lt-grey');
													} else if (units == 'deg. min. sec.') {
														$(".latlong").prop('disabled', false);
														$(".latlong").addClass('reqdClr');
														$(".latlong").removeClass('bg-lt-grey');
														$(".latlong").prop('required', true);
													} else if (units == 'UTM') {
														$(".utm").prop('disabled', false);
														$(".utm").prop('required', true);
														$(".utm").addClass('reqdClr');
														$(".utm").removeClass('bg-lt-grey');
													}
												} 
												$(document).ready(changeLatLongUnits);
											</script>
										</div>
										<div class="col-12 col-md-3 mb-2">
											<label for="accepted_lat_long_fg" class="data-entry-label">Accepted</label>
											<select name="accepted_lat_long_fg" size="1" id="accepted_lat_long_fg" class="data-entry-select reqdClr">
												<option value="1" selected>Yes</option>
												<option value="0">No</option>
											</select>
										</div>
										<div class="col-12 col-md-3 mb-2">
											<label for="determined_by_agent" class="data-entry-label">
												Determiner
												<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##determined_by_agent_id').val('#getCurrentUser.agent_id#');  $('##determined_by_agent').val('#encodeForHtml(getCurrentUser.agent_name)#'); return false;" > (me) <span class="sr-only">Fill in determined by with #encodeForHtml(getCurrentUser.agent_name)#</span></a>
											</label>
											<input type="hidden" name="determined_by_agent_id" id="determined_by_agent_id">
											<input type="text" name="determined_by_agent" id="determined_by_agent" class="data-entry-input reqdClr">
											<script>
												$(document).ready(function() { 
													makeAgentAutocompleteMeta("determined_by_agent", "determined_by_agent_id");
												});
											</script>
										</div>
										<div class="col-12 col-md-3 mb-2">
											<label for="determined_date" class="data-entry-label">Date Determined</label>
											<input type="text" name="determined_date" id="determined_date" class="data-entry-input reqdClr" placeholder="yyyy-mm-dd" value="#dateformat(now(),"yyyy-mm-dd")#">
											<script>
												$(document).ready(function() {
													$("##determined_date").datepicker({ dateFormat: 'yy-mm-dd'});
												});
											</script>
										</div>
										<div class="col-12 col-md-3 mb-2">
											<label for="lat_deg" class="data-entry-label">Latitude Degrees &##176;</label>
											<input type="text" name="lat_deg" id="lat_deg" class="data-entry-input latlong">
										</div>
										<div class="col-12 col-md-3 mb-2">
											<label for="lat_min" class="data-entry-label">Minutes &apos;</label>
											<input type="text" name="lat_min" id="lat_min" class="data-entry-input latlong">
										</div>
										<div class="col-12 col-md-3 mb-2">
											<label for="lat_sec" class="data-entry-label">Seconds &quot;</label>
											<input type="text" name="lat_sec" id="lat_sec" class="data-entry-input latlong">
										</div>
										<div class="col-12 col-md-3 mb-2">
											<label for="lat_dir" class="data-entry-label">Direction</label>
											<select name="lat_dir" size="1" id="lat_dir" class="data-entry-select latlong">
												<option value=""></option>
												<option value="N">N</option>
												<option value="S">S</option>
											</select>
										</div>
										<div class="col-12 col-md-3 mb-2">
											<label for="long_deg" class="data-entry-label">Longitude Degrees &##176;</label>
											<input type="text" name="long_deg" size="4" id="long_deg" class="data-entry-input latlong">
										</div>
										<div class="col-12 col-md-3 mb-2">
											<label for="long_min" class="data-entry-label">Minutes &apos;</label>
											<input type="text" name="long_min" size="4" id="long_min" class="data-entry-input latlong">
										</div>
										<div class="col-12 col-md-3 mb-2">
											<label for="long_sec" class="data-entry-label">Seconds &quot;</label>
											<input type="text" name="long_sec" size="4" id="long_sec" class="data-entry-input latlong">
										</div>
										<div class="col-12 col-md-3 mb-2">
											<label for="long_dir" class="data-entry-label">Direction</label>
											<select name="long_dir" size="1" id="long_dir" class="data-entry-select latlong">
												<option value=""></option>
												<option value="E">E</option>
												<option value="W">W</option>
											</select>
										</div>
										<div class="col-12 col-md-4 mb-2">
											<label for="utm_zone" class="data-entry-label">UTM Zone/Letter</label>
											<input type="text" name="utm_zone" size="4" id="utm_zone" class="data-entry-input utm">
										</div>
										<div class="col-12 col-md-4 mb-2">
											<label for="utm_ew" class="data-entry-label">Easting</label>
											<input type="text" name="utm_ew" size="4" id="utm_ew" class="data-entry-input utm">
										</div>
										<div class="col-12 col-md-4 mb-2">
											<label for="utm_ns" class="data-entry-label">Northing</label>
											<input type="text" name="utm_ns" size="4" id="utm_ns" class="data-entry-input utm">
										</div>
										<div class="col-12 col-md-3 mb-2">
											<label for="datum" class="data-entry-label">
												Geodetic Datum
												<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##datum').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open geodetic datum pick list</span></a>
											</label>
											<input type="text" name="datum" id="datum" class="data-entry-input reqdClr" value="" required>
											<script>
												$(document).ready(function (){
													makeCTAutocomplete('datum','datum');
												});
											</script> 
										</div>
										<div class="col-12 col-md-2 mb-2">
											<label for="max_error_distance" class="data-entry-label">Error Radius</label>
											<input type="text" name="max_error_distance" id="max_error_distance" class="data-entry-input reqdClr" value="" required>
										</div>
										<div class="col-12 col-md-1 mb-2">
											<label for="max_error_units" class="data-entry-label">
												Units
												<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##max_error_units').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open pick list for error radius units</span></a>
											</label>
											<input type="text" name="max_error_units" id="max_error_units" class="data-entry-input reqdClr" value="" required>
											<script>
												$(document).ready(function (){
													makeCTAutocomplete('max_error_units','lat_long_error_units');
												});
											</script> 
										</div>
										<div class="col-12 col-md-3 mb-2">
											<label for="spatialfit" class="data-entry-label">Point Radius Spatial Fit</label>
											<input type="text" name="spatialfit" id="spatialfit" class="data-entry-input" value="" pattern="^(0|1(\.[0-9]+)|[1-9][0-9.]{0,5}){0,1}$" >
										</div>
										<div class="col-12 col-md-2 mb-2">
											<label for="extent" class="data-entry-label">Radial of Feature [Extent]</label>
											<input type="text" name="extent" id="extent" class="data-entry-input" value="" pattern="^[0-9.]*$" >
										</div>
										<div class="col-12 col-md-1 mb-2">
											<label for="extent_units" class="data-entry-label">
												Units
												<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##extent_units').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open pick list for radial of feature (extent) units</span></a>
											</label>
											<input type="text" name="extent_units" id="extent_units" class="data-entry-input" value="" >
											<script>
												$(document).ready(function (){
													makeCTAutocomplete('extent_units','lat_long_error_units');
												});
											</script> 
										</div>
										<div class="col-12 col-md-3 mb-2">
											<label for="coordinate_precision" class="data-entry-label">Precision</label>
											<select name="coordinate_precision" id="coordinate_precision" class="data-entry-select reqdClr" required>
												<option value=""></option>
												<option value="0">Specified to 1&##176;</option>
												<option value="1">Specified to 0.1&##176;. latitude known to 11 km.</option>
												<option value="2">Specified to 0.01&##176;, use if known to 1&apos;, latitude known to 1,111 meters.</option>
												<option value="3">Specified to 0.001&##176;, latitude known to 111 meters.</option>
												<option value="4">Specified to 0.0001&##176;, use if known to 1&quot;, latitude known to 11 meters.</option>
												<option value="5">Specified to 0.00001&##176;, latitude known to 1 meter.</option>
												<option value="6">Specified to 0.000001&##176;, latitude known to 11 cm.</option>
											</select>
										</div>
										<div class="col-12 col-md-3 mb-2">
											<label for="gpsaccuracy" class="data-entry-label">GPS Accuracy</label>
											<input type="text" name="gpsaccuracy" id="gpsaccuracy" class="data-entry-input" value="">
										</div>
										<div class="col-12 col-md-3 mb-2">
											<label for="nearest_named_place" class="data-entry-label">Nearest Named Place</label>
											<input type="text" name="nearest_named_place" id="nearest_named_place" class="data-entry-input" value="">
										</div>
										<div class="col-12 col-md-3 mb-2">
											<label for="lat_long_for_nnp_fg" class="data-entry-label">Georeference is of Nearest Named Place</label>
											<select name="lat_long_for_nnp_fg" id="lat_long_for_nnp_fg" class="data-entry-select reqdClr" required>
												<option value="0" selected>No</option>
												<option value="1">Yes</option>
											</select>
										</div>
										<div class="col-12 col-md-3 mb-2">
											<label for="lat_long_ref_source" class="data-entry-label">Reference</label>
											<input type="text" name="lat_long_ref_source" id="lat_long_ref_source" class="data-entry-input reqdClr" value="" required>
										</div>
										<div class="col-12 col-md-3 mb-2">
											<label for="georefmethod" class="data-entry-label">
												Method
												<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##georefmethod').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open georeference method pick list</span></a>
											</label>
											<input type="text" name="georefmethod" id="georefmethod" class="data-entry-input reqdClr" value="" required>
											<script>
												$(document).ready(function (){
													makeCTAutocomplete('georefmethod','georefmethod');
												});
											</script> 
										</div>
										<div class="col-12 col-md-3 mb-2">
											<label for="verificationstatus" class="data-entry-label">Verification Status</label>
											<select name="verificationstatus" size="1" id="verificationstatus" class="data-entry-select reqdClr" onChange="changeVerificationStatus();">
												<cfloop query="ctVerificationStatus">
													<cfif ctVerificationStatus.verificationstatus EQ "unverified"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="#ctVerificationStatus.verificationStatus#" #selected#>#ctVerificationStatus.verificationStatus#</option>
												</cfloop>
											</select>
											<script>
												/* show/hide verified by agent controls depending on verification status */
												function changeVerificationStatus() { 
													var status = $('##verificationstatus').val();
													if (status=='verified by MCZ collection' || status=='rejected by MCZ collection' || status=='verified by collector') {
														$('##verified_by_agent').show();
														$('##verified_by_agent_label').show();
													} else { 
														$('##verified_by_agent').hide();
														$('##verified_by_agent_label').hide();
														$('##verified_by_agent').val("");
														$('##verified_by_agent_id').val("");
													}
												};
											</script>
										</div>
										<div class="col-12 col-md-3 mb-2">
											<label for="verified_by_agent" class="data-entry-label" id="verified_by_agent_label">
												Verified by
												<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##verified_by_agent_id').val('#getCurrentUser.agent_id#');  $('##verified_by_agent').val('#encodeForHtml(getCurrentUser.agent_name)#'); return false;" > (me) <span class="sr-only">Fill in verified by with #encodeForHtml(getCurrentUser.agent_name)#</span></a>
											</label>
											<input type="hidden" name="verified_by_agent_id" id="verified_by_agent_id">
											<input type="text" name="verified_by_agent" id="verified_by_agent" class="data-entry-input reqdClr">
											<script>
												$(document).ready(function() { 
													makeAgentAutocompleteMeta("verified_by_agent", "verified_by_agent_id");
													$('##verified_by_agent').hide();
													$('##verified_by_agent_label').hide();
												});
											</script>
										</div>
										<div class="col-12 mb-2">
											<label class="data-entry-label" for="lat_long_remarks">Georeference Remarks (<span id="length_lat_long_remarks">0 of 4000 characters</span>)</label>
											<textarea name="lat_long_remarks" id="lat_long_remarks" 
												onkeyup="countCharsLeft('lat_long_remarks', 4000, 'length_lat_long_remarks');"
												class="form-control form-control-sm w-100 autogrow mb-1" rows="2" style="min-height: 30px;"></textarea>
											<script>
												// Bind input to autogrow function on key up, and trigger autogrow to fit text
												$(document).ready(function() { 
													$("##lat_long_remarks").keyup(autogrow);  
													$('##lat_long_remarks').keyup();
												});
											</script>
										</div>
										<div class="col-12 col-md-9 col-xl-10 mb-2">
											<label for="error_polygon" class="data-entry-label" id="error_polygon_label">Footprint Polygon (WKT)</label>
											<input type="text" name="error_polygon" id="error_polygon" class="data-entry-input">
										</div>
										<div class="col-12 col-md-3 col-xl-2 mb-2">
											<label for="footprint_spatialfit" class="data-entry-label">Footprint Spatial Fit</label>
											<input type="text" name="footprint_spatialfit" id="footprint_spatialfit" class="data-entry-input" value="" pattern="^(0|1(\.[0-9]+)|[1-9][0-9.]{0,5}){0,1}$" >
										</div>
										<div class="col-12 col-md-6 col-xl-3 mb-2">
											<label for="wktFile" class="data-entry-label">Load Footprint Polygon from WKT file</label>
											<input type="file" id="wktFile" name="wktFile" accept=".wkt" class="w-100 p-0">
											<script>
												$(document).ready(function() { 
													$("##wktFile").change(confirmLoadWKTFromFile);
												});
												function confirmLoadWKTFromFile(){
													if ($("##error_polygon").val().length > 1) {
														confirmDialog('This Georeference has a Footprint Polygon, do you wish to overwrite it?','Confirm overwrite Footprint WKT', loadWKTFromFile);
													} else {
														loadWKTFromFile();
													}
												}
												function loadWKTFromFile() { 
													loadPolygonWKTFromFile('wktFile', 'error_polygon', 'wktReplaceFeedback');
												}
											</script>
										</div>
										<div class="col-12 col-md-6 col-xl-2 mt-3 text-danger mb-2">
											<output id="wktReplaceFeedback"></output>
										</div>
										<div class="col-12 col-md-6 col-xl-3 mb-2">
											<label for="copyFootprintFrom" class="data-entry-label" >Copy Polygon from locality_id</label>
											<input type="hidden" name="copyFootprintFrom_id" id="copyFootprintFrom_id" value="">
											<input type="text" name="copyFootprintFrom" id="copyFootprintFrom" value="" class="data-entry-input">
											<script> 
												$(document).ready(function() { 
													makeLocalityAutocompleteMetaLimited("copyFootprintFrom", "copyFootprintFrom_id","has_footprint");
												});
												function copyWKTFromLocality() { 
													var lookup_locality_id = $("##copyFootprintFrom_id").val();
													if (lookup_locality_id=="") {
														$("##wktLocReplaceFeedback").html("No locality selected to look up.");
													} else {  
														$("##wktLocReplaceFeedback").html("Loading...");
														jQuery.ajax({
															url: "/localities/component/georefUtilities.cfc",
															type: "get",
															data: {
																method: "getGeoreferenceErrorWKT",
																returnformat: "plain",
																locality_id: lookup_locality_id
															}, 
															success: function (data) { 
																$("##error_polygon").val(data);
																$("##wktLocReplaceFeedback").html("Loaded.");
															}, 
															error: function (jqXHR, textStatus, error) {
																$("##wktLocReplaceFeedback").html("Error looking up polygon WKT.");
																handleFail(jqXHR,textStatus,error,"looking up wkt for accepted lat_long for locality");
															}
														});
													} 
												} 
												function confirmCopyWKTFromLocality(){
													if ($("##error_polygon").val().length > 1) {
														confirmDialog('This Georeference has a Footprint Polygon, do you wish to overwrite it?','Confirm overwrite Footprint WKT', copyWKTFromLocality);
													} else {
														copyWKTFromLocality();
													}
												}
											</script>
										</div>
										<div class="col-12 col-md-2 col-xl-1 mb-2">
											<label class="data-entry-label d-none d-md-block">&nbsp;</label>
											<input type="button" value="Copy" class="btn btn-xs btn-secondary" onClick=" confirmCopyWKTFromLocality(); ">
										</div>
										<div class="col-12 col-md-4 col-xl-3 mb-2">
											<output id="wktLocReplaceFeedback"></output>
										</div>
										<div class="geolocateMetadata col-12">
											<h3 class="h4 mt-4">Batch GeoLocate Georeference Metadata</h3>
										</div>
										<div class="geolocateMetadata col-12 mb-2">
											<label for="geolocate_uncertaintypolygon" class="data-entry-label" id="geolocate_uncertaintypolygon_label">GeoLocate Uncertainty Polygon</label>
											<input type="text" name="geolocate_uncertaintypolygon" id="geolocate_uncertaintypolygon" class="data-entry-input bg-lt-gray" readonly>
										</div>
										<div class="geolocateMetadata col-12 col-md-3 mb-2">
											<label for="geolocate_score" class="data-entry-label" id="geolocate_score_label">GeoLocate Score</label>
											<input type="text" name="geolocate_score" id="geolocate_score" class="data-entry-input bg-lt-gray" readonly>
										</div>
										<div class="geolocateMetadata col-12 col-md-3 mb-2">
											<label for="geolocate_precision" class="data-entry-label" id="geolocate_precision_label">GeoLocate Precision</label>
											<input type="text" name="geolocate_precision" id="geolocate_precision" class="data-entry-input bg-lt-gray" readonly>
										</div>
										<div class="geolocateMetadata col-12 col-md-3 mb-2">
											<label for="geolocate_numresults" class="data-entry-label" id="geolocate_numresults_label">Number of Matches</label>
											<input type="text" name="geolocate_numresults" id="geolocate_numresults" class="data-entry-input bg-lt-gray" readonly>
										</div>
										<div class="geolocateMetadata col-12 col-md-3 mb-2">
											<label for="geolocate_parsepattern" class="data-entry-label" id="geolocate_parsepattern_label">Parse Pattern</label>
											<input type="text" name="geolocate_parsepattern" id="geolocate_parsepattern" class="data-entry-input bg-lt-gray" readonly>
										</div>
										<script>
											$(document).ready(function() { 
												$('.geolocateMetadata').hide();
											});
										</script>
										<div class="col-12 col-md-3 pt-2">
											<input type="button" value="Save" class="btn btn-xs btn-primary mr-2"
												onClick="if (checkFormValidity($('##manualGeorefForm')[0])) { saveManualGeoref();  } " 
												id="submitButton" >
											<output id="manualFeedback" class="text-danger">&nbsp;</output>	
										</div>
										<script>
											function saveManualGeoref() { 
												$('##manualFeedback').html('Saving....');
												$('##manualFeedback').addClass('text-warning');
												$('##manualFeedback').removeClass('text-success');
												$('##manualFeedback').removeClass('text-danger');
												jQuery.ajax({
													url : "/localities/component/functions.cfc",
													type : "post",
													dataType : "json",
													data : $('##manualGeorefForm').serialize(),
													success : function (data) {
														console.log(data);
														$('##manualFeedback').html('Saved.' + data[0].values + ' <span class="text-danger">' + data[0].message + '</span>');
														$('##georeferenceDialogFeedback').html('Saved.' + data[0].values + ' <span class="text-danger">' + data[0].message + '</span>');
														$('##manualFeedback').addClass('text-success');
														$('##manualFeedback').removeClass('text-danger');
														$('##manualFeedback').removeClass('text-warning');
														$('##addGeorefDialog').dialog('close');
													},
													error: function(jqXHR,textStatus,error){
														$('##manualFeedback').html('Error.');
														$('##manualFeedback').addClass('text-danger');
														$('##manualFeedback').removeClass('text-success');
														$('##manualFeedback').removeClass('text-warning');
														handleFail(jqXHR,textStatus,error,'saving manually entered georeference for locality');
													}
												});
											}
										</script>
									</div>
								</form>
							</div>
							<div id="geolocatePanel" role="tabpanel" aria-labelledby="geolocateTabButton" tabindex="-1" class="col-12 px-0 mx-0 unfocus" hidden>
								<form id="geolocateForm">
									<input type="hidden" name="method" value="addGeoreference">
									<input type="hidden" name="field_mapping" value="specific"> 
									<input type="hidden" name="locality_id" value="#locality_id#">
									<h2 class="px-1 h3">Use GeoLocate: <input type="button" value="GeoLocate" class="btn btn-xs btn-warning" onClick=" geolocate('#Application.protocol#'); "></h2>
										<div class="col-12 px-1 mb-2">
											<div class="h4">Values from Locality to send to GeoLocate to obtain a georeference:</div>
										</div>
										<div class="col-12 col-md-4 mb-2 px-1 float-left">
											<label for="country" class="data-entry-label">Country</label>
											<input type="text" name="country" id="country" class="border-info data-entry-input" value="#encodeForHtml(lookupForGeolocate.country)#" disabled readonly >
										</div>
										<div class="col-12 col-md-4 mb-2 px-1 float-left">
											<label for="state_prov" class="data-entry-label">State/Province</label>
											<input type="text" name="state_prov" id="state_prov" class="border-info data-entry-input" value="#encodeForHtml(lookupForGeolocate.state_prov)#" disabled readonly >
										</div>
										<div class="col-12 col-md-4 mb-2 px-1 float-left">
											<label for="county" class="data-entry-label">County</label>
											<input type="text" name="county" id="county" class="data-entry-input border-info" value="#encodeForHtml(lookupForGeolocate.county)#" disabled readonly >
										</div>
										<div class="col-12 mb-2 px-1 float-left">
											<label for="gl_spec_locality" class="data-entry-label">Specific Locality</label>
											<input type="text" name="gl_spec_locality" id="gl_spec_locality" class="border-info data-entry-input" value="#encodeForHtml(lookupForGeolocate.spec_locality)#" disabled readonly>
										</div>
										<div class="col-12 px-1 my-2 preGeoLocate float-left">
											<div class="h4">Some fields will need to be entered manually here after obtaining the georeference from GeoLocate.</div>
										</div>
										<div class="col-12 px-1 mb-2 postGeolocate float-left">
											<div class="h4 mt-1">Results from GeoLocate, edit metadata as needed and save.</div>
										</div>
										<div class="postGeolocate col-12 col-md-2 mb-2 px-1 float-left">
											<input type="hidden" name="ORIG_LAT_LONG_UNITS" value="decimal degrees">
											<label for="gl_orig_units" class="data-entry-label">Coordinate Format</label>
											<input type="text" name="orig_units" id="gl_orig_units" class="data-entry-input" value="decimal degrees" disabled readonly>
										</div>
										<div class="postGeolocate col-12 col-md-1 px-1 float-left mb-2">
											<label for="gl_dec_lat" class="data-entry-label">Latitude</label>
											<input type="text" name="dec_lat" id="gl_dec_lat" class="data-entry-input reqdClr" value="" required>
										</div>
										<div class="postGeolocate col-12 col-md-1 px-1 float-left mb-2">
											<label for="gl_dec_long" class="data-entry-label">Longitude</label>
											<input type="text" name="dec_long" id="gl_dec_long" class="data-entry-input reqdClr" value="" required>
										</div>
										<div class="postGeolocate col-12 col-md-2 px-1 float-left mb-2">
											<label for="gl_datum" class="data-entry-label">Geodetic Datum</label>
											<input type="text" name="datum" id="gl_datum" class="data-entry-input reqdClr" value="" required>
											<script>
												$(document).ready(function (){
													makeCTAutocomplete('gl_datum','datum');
												});
											</script> 
										</div>
										<div class="postGeolocate col-12 col-md-2 float-left px-1 mb-2">
											<label for="gl_max_error_distance" class="data-entry-label">Error Radius</label>
											<input type="text" name="max_error_distance" id="gl_max_error_distance" class="data-entry-input reqdClr" value="" required>
										</div>
										<div class="postGeolocate col-12 col-md-1 float-left px-1 mb-2">
											<label for="gl_max_error_units" class="data-entry-label">
												Units
												<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##gl_max_error_units').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open pick list for error radius units</span></a>
											</label>
											<input type="text" name="max_error_units" id="gl_max_error_units" class="data-entry-input reqdClr" value="" required>
											<script>
												$(document).ready(function (){
													makeCTAutocomplete('gl_max_error_units','lat_long_error_units');
												});
											</script> 
										</div>
										<div class="postGeolocate col-12 col-md-3 float-left px-1 mb-2">
											<label for="gl_spatialfit" class="data-entry-label">Point-Radius Spatial Fit</label>
											<input type="text" name="spatialfit" id="gl_spatialfit" class="data-entry-input" value="" pattern="^(0|1(\.[0-9]+)|[1-9][0-9.]{0,5}){0,1}$">
										</div>
										<div class="postGeolocate col-12 col-md-4 float-left px-1 mb-2">
											<label for="gl_coordinate_precision" class="data-entry-label">Precision</label>
											<select name="coordinate_precision" id="gl_coordinate_precision" class="data-entry-select reqdClr" required>
												<option value=""></option>
												<option value="0">Specified to 1&##176;</option>
												<option value="1">Specified to 0.1&##176;, latitude known to 11 km.</option>
												<option value="2">Specified to 0.01&##176;, use if known to 1&apos;, latitude known to 1,111 meters.</option>
												<option value="3">Specified to 0.001&##176;, latitude known to 111 meters.</option>
												<option value="4">Specified to 0.0001&##176;, use if known to 1&quot;, latitude known to 11 meters.</option>
												<option value="5" selected >Specified to 0.00001&##176;, latitude known to 1 meter.</option>
												<option value="6">Specified to 0.000001&##176;, latitude known to 11 cm.</option>
											</select>
										</div>
										<div class="postGeolocate col-12 col-md-1 float-left px-1 mb-2">
											<label for="gl_lat_long_ref_source" class="data-entry-label">Reference</label>
											<input type="text" name="lat_long_ref_source" id="gl_lat_long_ref_source" class="data-entry-input reqdClr" value="" required>
										</div>
										<div class="postGeolocate col-12 col-md-1 float-left px-1 mb-2">
											<label for="gl_georefmethod" class="data-entry-label">Method</label>
											<input type="text" name="georefmethod" id="gl_georefmethod" class="data-entry-input reqdClr" value="" required>
											<script>
												$(document).ready(function (){
													makeCTAutocomplete('gl_georefmethod','georefmethod');
												});
											</script> 
										</div>
										<div class="postGeolocate col-12 col-md-3 float-left px-1 mb-2">
											<label for="gl_nearest_named_place" class="data-entry-label">Nearest Named Place</label>
											<input type="text" name="nearest_named_place" id="gl_nearest_named_place" class="data-entry-input" value="">
										</div>
										<div class="postGeolocate col-12 col-md-3 px-1 float-left mb-2">
											<label for="gl_lat_long_for_nnp_fg" class="data-entry-label">Georeference is of Nearest Named Place</label>
											<select name="lat_long_for_nnp_fg" id="gl_lat_long_for_nnp_fg" class="data-entry-select reqdClr" required>
												<option value="0" selected>No</option>
												<option value="1">Yes</option>
											</select>
										</div>
										<div class="postGeolocate col-12 col-md-2 float-left px-1 mb-2">
											<label for="gl_extent" class="data-entry-label">Radial of Feature [Extent]</label>
											<input type="text" name="extent" id="gl_extent" class="data-entry-input" value="">
										</div>
										<div class="postGeolocate col-12 col-md-1 float-left mb-2" >
											<label for="gl_extent_units" class="data-entry-label">
												Units
												<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##gl_extent_units').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open pick list for radial of feature (extent) units</span></a>
											</label>
											<input type="text" name="extent_units" id="gl_extent_units" class="data-entry-input" value="">
											<script>
												$(document).ready(function (){ 
													makeCTAutocomplete('gl_extent_units','lat_long_error_units'); 
												});
											</script>
										</div>
										<div class="postGeolocate col-10 col-md-7 float-left px-1 mb-2">
											<label for="gl_error_polygon" class="data-entry-label" id="error_polygon_label">Footprint Polygon (WKT)</label>
											<input type="text" name="error_polygon" id="gl_error_polygon" class="data-entry-input">
										</div>
										<div class="postGeolocate col-12 col-md-2 float-left px-1 mb-2">
											<label for="gl_footprint_spatialfit" class="data-entry-label">Footprint Spatial Fit</label>
											<input type="text" name="footprint_spatialfit" id="gl_footprint_spatialfit" class="data-entry-input" value="" pattern="^(0|1(\.[0-9]+)|[1-9][0-9.]{0,5}){0,1}$" >
										</div>
										<div class="postGeolocate col-12 col-md-2 float-left px-1 mb-2">
											<label for="gl_accepted_lat_long_fg" class="data-entry-label">Accepted</label>
											<select name="accepted_lat_long_fg" size="1" id="gl_accepted_lat_long_fg" class="data-entry-select reqdClr">
												<option value="1" selected>Yes</option>
												<option value="0">No</option>
											</select>
										</div>
										<div class="postGeolocate col-12 col-md-3 float-left px-1 mb-2">
											<label for="gl_determined_by_agent" class="data-entry-label">Determiner</label>
											<input type="hidden" name="determined_by_agent_id" id="gl_determined_by_agent_id" value="#getCurrentUser.agent_id#">
											<input type="text" name="determined_by_agent" id="gl_determined_by_agent" class="data-entry-input reqdClr" value="#getCurrentUser.agent_name#">
											<script>
												$(document).ready(function() { 
													makeAgentAutocompleteMeta("gl_determined_by_agent", "gl_determined_by_agent_id", true);
												});
											</script>
										</div>
										<div class="postGeolocate col-12 col-md-2 float-left px-1 mb-2">
											<label for="gl_determined_date" class="data-entry-label">Date Determined</label>
											<input type="text" name="determined_date" id="gl_determined_date" class="data-entry-input reqdClr" placeholder="yyyy-mm-dd" value="#dateformat(now(),"yyyy-mm-dd")#">
											<script>
												$(document).ready(function() {
													$("##gl_determined_date").datepicker({ dateFormat: 'yy-mm-dd'});
												});
											</script>
										</div>
										<div class="postGeolocate col-12 col-md-2 float-left px-1 mb-2">
											<label for="gl_verificationstatus" class="data-entry-label">Verification Status</label>
											<select name="verificationstatus" size="1" id="gl_verificationstatus" class="data-entry-select reqdClr" onChange="changeGLVerificationStatus();">
												<cfloop query="ctVerificationStatus">
													<cfif ctVerificationStatus.verificationstatus EQ "unverified"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
													<option value="#ctVerificationStatus.verificationStatus#" #selected#>#ctVerificationStatus.verificationStatus#</option>
												</cfloop>
											</select>
											<script>
												/* show/hide verified by agent controls depending on verification status */
												function changeGLVerificationStatus() { 
													var status = $('##gl_verificationstatus').val();
													if (status=='verified by MCZ collection' || status=='rejected by MCZ collection' || status=='verified by collector') {
														$('##gl_verified_by_agent').show();
														$('##gl_verified_by_agent_label').show();
													} else { 
														$('##gl_verified_by_agent').hide();
														$('##gl_verified_by_agent_label').hide();
														$('##gl_verified_by_agent').val("");
														$('##gl_verified_by_agent_id').val("");
													}
												};
											</script>
										</div>
										<div class="postGeolocate col-12 col-md-3 float-left px-1 mb-2">
											<label for="gl_verified_by_agent" class="data-entry-label" id="gl_verified_by_agent_label">
												Verified by
												<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##gl_verified_by_agent_id').val('#getCurrentUser.agent_id#');  $('##gl_verified_by_agent').val('#encodeForHtml(getCurrentUser.agent_name)#'); return false;" > (me) <span class="sr-only">Fill in verified by with #encodeForHtml(getCurrentUser.agent_name)#</span></a>
</label>
											<input type="hidden" name="verified_by_agent_id" id="gl_verified_by_agent_id">
											<input type="text" name="verified_by_agent" id="gl_verified_by_agent" class="data-entry-input reqdClr">
											<script>
												$(document).ready(function() { 
													makeAgentAutocompleteMeta("gl_verified_by_agent", "gl_verified_by_agent_id");
													$('##gl_verified_by_agent').hide();
													$('##gl_verified_by_agent_label').hide();
												});
											</script>
										</div>
										<div class="postGeolocate col-12 float-left px-1 mb-2">
											<label class="data-entry-label" for="gl_lat_long_remarks">Georeference Remarks (<span id="gl_length_lat_long_remarks">0 of 4000 characters</span>)</label>
											<textarea name="lat_long_remarks" id="gl_lat_long_remarks" 
												onkeyup="countCharsLeft('gl_lat_long_remarks', 4000, 'gl_length_lat_long_remarks');"
												class="form-control form-control-sm w-100 autogrow mb-1" style="min-height: 30px;" rows="2"></textarea>
											<script>
												// Bind input to autogrow function on key up, and trigger autogrow to fit text
												$(document).ready(function() { 
													$("##lat_long_remarks").keyup(autogrow);  
													$('##lat_long_remarks').keyup();
												});
											</script>
										</div>
										<div class="postGeolocate col-12 col-md-3 float-left px-1 pt-3">
											<input type="button" value="Save" class="btn btn-xs btn-primary mr-2"
												onClick="if (checkFormValidity($('##geolocateForm')[0])) { saveGeolocate();  } " 
												id="submitButton" >
											<output id="geolocateFeedback" class="text-danger">&nbsp;</output>	
										</div>
										<script>
											function saveGeolocate() { 
												$('##geolocateFeedback').html('Saving....');
												$('##geolocateFeedback').addClass('text-warning');
												$('##geolocateFeedback').removeClass('text-success');
												$('##geolocateFeedback').removeClass('text-danger');
												jQuery.ajax({
													url : "/localities/component/functions.cfc",
													type : "post",
													dataType : "json",
													data : $('##geolocateForm').serialize(),
													success : function (data) {
														console.log(data);
														$('##geolocateFeedback').html('Saved.' + data[0].values + ' <span class="text-danger">' + data[0].message + '</span>');
														$('##georeferenceDialogFeedback').html('Saved.' + data[0].values + ' <span class="text-danger">' + data[0].message + '</span>');
														$('##geolocateFeedback').addClass('text-success');
														$('##geolocateFeedback').removeClass('text-danger');
														$('##geolocateFeedback').removeClass('text-warning');
														$('##addGeorefDialog').dialog('close');
													},
													error: function(jqXHR,textStatus,error){
														$('##geolocateFeedback').html('Error.');
														$('##geolocateFeedback').addClass('text-danger');
														$('##geolocateFeedback').removeClass('text-success');
														$('##geolocateFeedback').removeClass('text-warning');
														handleFail(jqXHR,textStatus,error,'saving georeference from geolocate for locality');
													}
												});
											}
											/** populate form with data returned from geolocate. **/
											function useGL(glat,glon,gerr,gpoly){
												if (gpoly=='') {
													var gpoly_wkt='';
												} else {
													var gpoly_wkt='POLYGON ((' + gpoly.replace(/,$/,'') + '))';
												}
												$("##gl_max_error_distance").val(gerr);
												$("##gl_max_error_units").val('m');
												$("##gl_datum").val('WGS84');
												$("##gl_georefmethod").val('GEOLocate');
												$("##gl_lat_long_ref_source").val('GEOLocate');
												$("##gl_dec_lat").val(glat);
												$("##gl_dec_long").val(glon);
												$("##gl_error_polygon").val(gpoly_wkt);
												closeGeoLocate();
												$(".postGeolocate").show();
												$(".preGeolocate").hide();
											}
											/** message handler for messages from geolocate iframe **/
											function getGeolocate(evt) {
												if (evt.origin.includes("://mczbase") && evt.data == "") {
													console.log(evt); // Chrome seems to include an extra invocation of getGeolocate from mczbase.
												} else {
													if (evt.origin !== "#Application.protocol#://www.geo-locate.org") {
														console.log(evt);
														alert( "MCZbase error: iframe url does not have permision to interact with me" );
														closeGeoLocate('intruder alert');
													} else {
														var breakdown = evt.data.split("|");
														if (breakdown.length == 4) {
															var glat=breakdown[0];
															var glon=breakdown[1];
															var gerr=breakdown[2];
															console.log(breakdown[3]);
															if (breakdown[3]== "Unavailable")
															{var gpoly='';}
															else
															{var gpoly=breakdown[3].replace(/([^,]*),([^,]*)[,]{0,1}/g,'$2 $1,');}
															useGL(glat,glon,gerr,gpoly)
														} else {
															alert( "MCZbase error: Unable to parse geolocate data. data length=" +  breakdown.length);
															closeGeoLocate('ERROR - breakdown length');
														}
													}
												}
											}
											$(document).ready(function() { 
												if (window.addEventListener) {
													window.addEventListener("message", getGeolocate, false);
												} else {
													window.attachEvent("onmessage", getGeolocate);
												}
												$(".postGeolocate").hide();
											});
										</script>
									</form>
								</div>
							<div id="clonePanel" role="tabpanel" aria-labelledby="cloneTabButton" tabindex="-1" class="col-12 px-0 mx-0 unfocus" hidden>
								<h2 class="px-1 h3">Clone accepted georeference from another Locality</h2>
								<p class="px-1">Type text from the specific locality or enter a locality_id and select from the pick list. The accepted georeference for the selected locality will be pasted into the edit form to allow you to add it to this locality.  Use this only in exceptional cases such as multiple localities at different depths at the same location.  </p>
								<div class="form-row mx-0">
									<div class="col-12 px-1">
										<label for="locality_text" class="data-entry-label">Locality</label>
										<input type="hidden" name="selected_locality_id" id="selected_locality_id">
										<input type="text" name="selected_locality_text" id="selected_locality_text" class="data-entry-input">
										<script> 
											$(document).ready(function() { 
												makeLocalityAutocompleteMetaLimited("selected_locality_text", "selected_locality_id", "has_accepted_georeference", loadGeoreference);
											});
										</script>
									</div>
									<div class="col-12 px-1">
										<output id="cloneFeedback"></output>
									</div>
								</div>
								<script>
									function loadGeoreference() { 
										var lookup_locality_id = $('##selected_locality_id').val();
										if (lookup_locality_id == "") { 
											$('##cloneFeedback').html("No locality selected");
										} else { 
											$('##cloneFeedback').html("Searching....");
											jQuery.ajax({
												dataType: "json",
												url: "/localities/component/functions.cfc",
												data : {
													method : "getGeoreference",
													returnformat : "json",
													locality_id: lookup_locality_id
												},
												success: function (result) {
													$('##cloneFeedback').html("Found, loading data into form...");
													result = JSON.parse(result);
													console.log(result);
													if (jQuery.isArray(result) && result.length > 0) { 
														var orig_lat_long_units = result[0].ORIG_LAT_LONG_UNITS;
														$("##orig_lat_long_units").val(orig_lat_long_units);
														changeLatLongUnits();
														console.log(orig_lat_long_units);
														if (orig_lat_long_units == "decimal degrees") { 
															$("##lat_deg").val(result[0].RAW_DEC_LAT);
															$("##long_deg").val(result[0].RAW_DEC_LONG);
														} else if (orig_lat_long_units == "degrees dec. minutes") { 
															$("##lat_deg").val(result[0].LAT_DEG);
															$("##long_deg").val(result[0].LONG_DEG);
															$("##lat_min").val(result[0].DEC_LAT_MIN);
															$("##long_min").val(result[0].DEC_LONG_MIN);
															$("##lat_dir").val(result[0].LAT_DIR);
															$("##long_dir").val(result[0].LONG_DIR);
														} else if (orig_lat_long_units == "deg. min. sec.") { 
															$("##lat_deg").val(result[0].LAT_DEG);
															$("##long_deg").val(result[0].LONG_DEG);
															$("##lat_min").val(result[0].LAT_MIN);
															$("##long_min").val(result[0].LONG_MIN);
															$("##lat_sec").val(result[0].LAT_SEC);
															$("##long_sec").val(result[0].LONG_SEC);
															$("##lat_dir").val(result[0].LAT_DIR);
															$("##long_dir").val(result[0].LONG_DIR);
														} else if (orig_lat_long_units == "UTM") { 
															$("##utm_zone").val(result[0].UTM_ZONE);
															$("##utm_ew").val(result[0].UTM_EW);
															$("##utm_ns").val(result[0].UTM_NS);
														}
														$("##accepted_lat_long_fg").val(result[0].ACCEPTED_LAT_LONG_FG);
														$("##georefmethod").val(result[0].GEOREFMETHOD);
														$("##max_error_distance").val(result[0].MAX_ERROR_DISTANCE);
														$("##max_error_units").val(result[0].MAX_ERROR_UNITS);
														$("##datum").val(result[0].DATUM);
														$("##extent").val(result[0].EXTENT);
														$("##extent_units").val(result[0].EXTENT_UNITS);
														$("##spatialfit").val(result[0].SPATIALFIT);
														$("##gpsaccuracy").val(result[0].GPSACCURACY);
														$("##geolocate_uncertaintypolygon").val(result[0].GEOLOCATE_UNCERTAINTYPOLYGON);
														$("##error_polygon").val(result[0].ERROR_POLYGON);
														$("##footprint_spatialfit").val(result[0].FOOTPRINT_SPATIALFIT);
														$('##determined_by_agent_id').val(result[0].DETERMINED_BY_AGENT_ID);
														$('##determined_by_agent').val(result[0].DETERMINED_BY);
														$('##determined_date').val(result[0].DETERMINED_DATE);
														$('##verified_by_agent_id').val(result[0].VERIFIED_BY_AGENT_ID);
														$('##verified_by_agent').val(result[0].VERIFIED_BY);
														$("##verificationstatus").val(result[0].VERIFICATIONSTATUS);
														$("##lat_long_remarks").val(result[0].LAT_LONG_REMARKS);
														$("##lat_long_ref_source").val(result[0].LAT_LONG_REF_SOURCE);
														$("##nearest_named_place").val(result[0].NEAREST_NAMED_PLACE);
														var lat_long_for_nnp_fg = result[0].LAT_LONG_FOR_NNP_FG;
														if (lat_long_for_nnp_fg == "") { lat_long_for_nnp_fg = 0; } 
														$("##lat_long_for_nnp_fg").val(lat_long_for_nnp_fg);
														var geolocate_score = result[0].GEOLOCATE_SCORE;
														if (geolocate_score) { 
															$("##geolocate_score").val(geolocate_score);
															$("##geolocate_parsepattern").val(result[0].GEOLOCATE_PARSEPATTERN);
															$("##geolocate_numresults").val(result[0].GEOLOCATE_NUMRESULTS);
															$("##geolocate_precision").val(result[0].GEOLOCATE_PRECISION);
															$('.geolocateMetadata').show();
														} 
														$("##manualTabButton").click();
													} else {
														$('##cloneFeedback').html("No Georeference to Clone.");
													} 
												},
												error: function (jqXHR, textStatus, error) {
													$('##cloneFeedback').html("Error.");
													handleFail(jqXHR,textStatus,error,"loading a georeference to clone");
												},
												dataType: "html"
											});
										}
									}
								</script>
							</div>
						</div>
					</div>
				</div>
				<cfif isDefined("geolocateImmediate") AND geolocateImmediate EQ "yes">
					<!--- switch to the geolocatePanel and invoke geolocate --->
					<script>
						$(document).ready(function() { 
							$("##geolocateTabButton").click();
							geolocate('#Application.protocol#');
						});
					</script>
				</cfif>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h3 class="h4">Error in #function_called#:</h3>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getGeorefThread#tn#" />
	<cfreturn cfthread["getGeorefThread#tn#"].output>
</cffunction>


<!--- add a georeference, inserting a value into lat_long.
  @param locality_id the primary key value of the locality from which to add the lat_long
  @param field_mapping if generic, then use lat_deg, lat_min etc translating to target fields
    based on value of orig_lat_long_units (for decimal degrees, map input lat_deg onto field dec_lat, for
    decimal minutes, map input lat_min onto field dec_lat_min, if specific, then specific 
    fields for the specified orig_lat_long units must be used (for decimal degrees, dec_lat must be
    provided).  field_mapping=generic allows a form to use degrees, minutes, seconds, direction fields,
    along with a units field to specify which fields apply, field_mapping=specific requires each 
    unit type to have its own set of fields.
  @param orig_lat_long_units the form of the georeference, dms, dm, d, or utm.
  @param accepted_lat_long_fg 1 if new georeference is to be the accepted one for the locality.

  @return json with status=added and lat_long_id for the new record in id, or an http status 500.
--->
<cffunction name="addGeoreference" access="remote" returntype="any" returnformat="json">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="field_mapping" type="string" required="yes">
	<cfargument name="accepted_lat_long_fg" type="string" required="yes">
	<cfargument name="orig_lat_long_units" type="string" required="yes">
	<cfargument name="datum" type="string" required="yes">
	<cfargument name="lat_long_ref_source" type="string" required="no">
	<cfargument name="determined_by_agent_id" type="string" required="yes">
	<cfargument name="verified_by_agent_id" type="string" required="no">
	<cfargument name="determined_date" type="string" required="no">
	<cfargument name="georefmethod" type="string" required="no">
	<cfargument name="verificationstatus" type="string" required="yes">
	<cfargument name="extent" type="string" required="no">
	<cfargument name="extent_units" type="string" required="no">
	<cfargument name="spatialfit" type="string" required="no">
	<cfargument name="gpsaccuracy" type="string" required="no">
	<cfargument name="max_error_distance" type="string" required="yes">
	<cfargument name="max_error_units" type="string" required="yes">
	<cfargument name="lat_long_remarks" type="string" required="no">
	<cfargument name="dec_lat" type="string" required="no">
	<cfargument name="dec_long" type="string" required="no">
	<cfargument name="lat_deg" type="string" required="no">
	<cfargument name="long_deg" type="string" required="no">
	<cfargument name="geolocate_uncertaintypolygon" type="string" required="no">
	<cfargument name="geolocate_score" type="string" required="no">
	<cfargument name="geolocate_precision" type="string" required="no">
	<cfargument name="geolocate_num_results" type="string" required="no">
	<cfargument name="geolocate_parsepattern" type="string" required="no">
	<cfargument name="nearest_named_place" type="string" required="no">
	<cfargument name="lat_long_for_nnp_fg" type="string" required="no">
	<cfargument name="footprint_spatialfit" type="string" required="no">
	
	<!--- field_verified_fg unused and deprecated --->

	<cfif lcase(field_mapping) EQ "generic"> 
		<!--- map lat_deg/long_deg onto dec_lat/dec_long and lat_min/long_min onto dec_lat_min/dec_long_min if appropriate. --->
		<cfswitch expression="#ORIG_LAT_LONG_UNITS#">
			<cfcase value="deg. min. sec.">
				<!---  validate expectations --->
				<cfif isDefined("dec_lat_min") and len(dec_lat_min) GT 0>
					<cfthrow message = "A value was provided for dec_lat_min, but units are degrees, minutes, seconds. Unable to save.">
				</cfif>
				<cfif isDefined("dec_long_min") and len(dec_long_min) GT 0>
					<cfthrow message = "A value was provided for dec_long_min, but units are degrees, minutes, seconds. Unable to save.">
				</cfif>
			</cfcase>
			<cfcase value="degrees dec. minutes">
				<cfset dec_lat_min = lat_min>
				<cfset dec_long_min = long_min>
				<cfset lat_min= "">
				<cfset long_min = "">
			</cfcase>
			<cfcase value="decimal degrees">
				<cfset dec_lat = lat_deg>
				<cfset dec_long = long_deg>
				<cfset lat_deg = "">
				<cfset long_deg = "">
			</cfcase>
		</cfswitch>
	<cfelseif lcase(field_mapping) EQ "specific">
		<!---  validate expectations --->
		<cfswitch expression="#ORIG_LAT_LONG_UNITS#">
			<cfcase value="deg. min. sec.">
				<cfif isDefined("dec_lat_min") and len(dec_lat_min) GT 0>
					<cfthrow message = "A value was provided for dec_lat_min, but units are degrees, minutes, seconds. Unable to save.">
				</cfif>
				<cfif isDefined("dec_long_min") and len(dec_long_min) GT 0>
					<cfthrow message = "A value was provided for dec_long_min, but units are degrees, minutes, seconds. Unable to save.">
				</cfif>
			</cfcase>
			<cfcase value="degrees dec. minutes">
				<cfif isDefined("lat_min") and len(lat_min) GT 0>
					<cfthrow message = "A value was provided for lat_min, but units are degrees, decimal minutes, Unable to save.">
				</cfif>
				<cfif isDefined("long_min") and len(long_min) GT 0>
					<cfthrow message = "A value was provided for long_min, but units are degrees, decimal minutes. Unable to save.">
				</cfif>
				<cfif isDefined("lat_sec") and len(lat_sec) GT 0>
					<cfthrow message = "A value was provided for lat_sec, but units are degrees, decimal minutes, Unable to save.">
				</cfif>
				<cfif isDefined("long_sec") and len(long_sec) GT 0>
					<cfthrow message = "A value was provided for long_sec, but units are degrees, decimal minutes. Unable to save.">
				</cfif>
			</cfcase>
			<cfcase value="decimal degrees">
			</cfcase>
			<cfcase value="UTM">
				<cfif not isDefined("utm_zone") OR len(utm_zone) EQ 0>
					<cfthrow message = "A value was not provided for UTM Zone, but units are UTM. zone, easting, and northing are required. Unable to save.">
				</cfif>
				<cfif not isDefined("utm_ew") OR len(utm_ew) EQ 0>
					<cfthrow message = "A value was not provided for UTM Easting, but units are UTM. zone, easting, and northing are required. Unable to save.">
				</cfif>
				<cfif not isDefined("utm_ns") OR len(utm_ns) EQ 0>
					<cfthrow message = "A value was not provided for UTM Northing, but units are UTM. zone, easting, and northing are required. Unable to save.">
				</cfif>
			</cfcase>
		</cfswitch>
	<cfelse>
		<cfthrow message="Unknown value for field_mapping [#encodeForHtml(field_mapping)#] must be 'generic' or 'specific'.">
	</cfif>

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cfset triggerState = "on">
		<cftry>
			<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_locality")>
				<!--- as trigger needs to be disabled, and user_login probably does not have rights to do so, queries are run under a more priviliged user,
        			but within a transaction, so all queries in the transaction need to use the same data source, so check if user has rights to update lat_long 
        			table before performing actual update (unaccept others) and insert.  
				--->
			<cfelse>
				<cfthrow message="Unable to insert into lat_long table, current user does not have adequate rights.">
			</cfif>
			<!--- TR_LATLONG_ACCEPTED_BIUPA checks for only one accepted georeference, uses pragma autonomous_transaction, so 
					adding a new accepted lat long when one already exists has to occur in more than one transaction or with the trigger disabled --->
			<cfquery name="countAcceptedPre" datasource="uam_god" result="countAcceptedPre_result">
				SELECT count(*) ct
				FROM lat_long
				WHERE
					locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
					and 
					accepted_lat_long_fg = 1
			</cfquery>
			<cfif accepted_lat_long_fg EQ "1" and countAcceptedPre.ct GT 0>
				<cfquery name="turnOff" datasource="uam_god">
					ALTER TRIGGER MCZBASE.TR_LATLONG_ACCEPTED_BIUPA DISABLE
				</cfquery>
				<cfset triggerState = "off">
				<cfquery name="unacceptOthers" datasource="uam_god" result="unacceptOthers_result">
					UPDATE lat_long 
					SET accepted_lat_long_fg = 0 
					WHERE
					locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
				</cfquery>
			</cfif>
			<cfquery name="getLatLongID" datasource="uam_god" result="getLatLongID_result">
				SELECT sq_lat_long_id.nextval latlongid 
				FROM dual
			</cfquery>
			<cfquery name="insertLatLong" datasource="uam_god" result="insertLatLong_result">
				INSERT INTO lat_long (
					LAT_LONG_ID
					,LOCALITY_ID
					,ACCEPTED_LAT_LONG_FG
					,DATUM
					,lat_long_ref_source
					,determined_by_agent_id
					,determined_date
					,georefmethod
					,verificationstatus
					<cfif isDefined("verified_by_agent_id") AND len(#verified_by_agent_id#) gt 0>
						,verified_by_agent_id
					</cfif>
					<cfif len(#extent#) gt 0>
						,extent
					</cfif>
					<cfif len(#extent_units#) gt 0>
						,extent_units
					</cfif>
					<cfif isDefined("gpsaccuracy") AND len(#gpsaccuracy#) gt 0>
						,gpsaccuracy
					</cfif>
					<cfif isDefined("coordinate_precision") AND len(#coordinate_precision#) gt 0>
						,coordinate_precision
					</cfif>
					<cfif isDefined("lat_long_remarks") AND len(#lat_long_remarks#) gt 0>
						,lat_long_remarks
					</cfif>
					<cfif len(#MAX_ERROR_DISTANCE#) gt 0>
						,MAX_ERROR_DISTANCE
					</cfif>
					<cfif len(#MAX_ERROR_UNITS#) gt 0>
						,MAX_ERROR_UNITS
					</cfif>
					,ORIG_LAT_LONG_UNITS
					<cfif #ORIG_LAT_LONG_UNITS# is "deg. min. sec.">
						,LAT_DEG
						,LAT_MIN
						,LAT_SEC
						,LAT_DIR
						,LONG_DEG
						,LONG_MIN
						,LONG_SEC
						,LONG_DIR
					<cfelseif #ORIG_LAT_LONG_UNITS# is "degrees dec. minutes">
						,LAT_DEG
						,DEC_LAT_MIN
						,LAT_DIR
						,LONG_DEG
						,DEC_LONG_MIN
						,LONG_DIR
					<cfelseif #ORIG_LAT_LONG_UNITS# is "decimal degrees">
						,DEC_LAT
						,DEC_LONG
					<cfelseif #ORIG_LAT_LONG_UNITS# is "UTM">
					 	,UTM_ZONE
					 	,UTM_EW
					 	,UTM_NS
					<cfelse>
						<cfthrow message = "Unsupported orig_lat_long_units [#encodeForHtml(orig_lat_long_units)#].">
					</cfif>
					<cfif isDefined("geolocate_uncertaintypolygon") AND len(geolocate_uncertaintypolygon) GT 0>
						,geolocate_uncertaintypolygon
					</cfif>
					<cfif isDefined("geolocate_score") AND len(geolocate_score) GT 0>
						,geolocate_score
					</cfif>
					<cfif isDefined("geolocate_precision") AND len(geolocate_precision) GT 0>
						,geolocate_precision
					</cfif>
					<cfif isDefined("geolocate_numresults") AND len(geolocate_numresults) GT 0>
						,geolocate_numresults
					</cfif>
					<cfif isDefined("geolocate_parsepattern") AND len(geolocate_parsepattern) GT 0>
						,geolocate_parsepattern
					</cfif>
					<cfif isDefined("spatialfit") AND len(spatialfit) GT 0>
						,spatialfit
					</cfif>
					<cfif isDefined("footprint_spatialfit") AND len(footprint_spatialfit) GT 0>
						,footprint_spatialfit
					</cfif>
					<cfif isDefined("nearest_named_place") AND len(nearest_named_place) GT 0>
						,nearest_named_place
					</cfif>
					<cfif isDefined("lat_long_for_nnp_fg") AND len(lat_long_for_nnp_fg) GT 0>
						,lat_long_for_nnp_fg
					</cfif>
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#getLATLONGID.latlongid#">
					,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LOCALITY_ID#">
					,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ACCEPTED_LAT_LONG_FG#">
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DATUM#">
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lat_long_ref_source#">
					,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#determined_by_agent_id#">
					,<cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateformat(determined_date,'yyyy-mm-dd')#">
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#georefmethod#">
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#verificationstatus#">
					<cfif isDefined("verified_by_agent_id") AND len(#verified_by_agent_id#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#verified_by_agent_id#">
					</cfif>
					<cfif len(#extent#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#extent#" scale="5">
					</cfif>
					<cfif len(#extent_units#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#extent_units#">
					</cfif>
					<cfif isDefined("gpsaccuracy") AND len(#gpsaccuracy#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#gpsaccuracy#" scale="3">
					</cfif>
					<cfif isDefined("coordinate_precision") AND len(#coordinate_precision#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#coordinate_precision#">
					</cfif>
					<cfif len(#lat_long_remarks#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lat_long_remarks#">
					</cfif>
					<cfif len(#MAX_ERROR_DISTANCE#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#MAX_ERROR_DISTANCE#">
					</cfif>
					<cfif len(#MAX_ERROR_UNITS#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#MAX_ERROR_UNITS#">
					</cfif>
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ORIG_LAT_LONG_UNITS#">
					<cfif #ORIG_LAT_LONG_UNITS# is "deg. min. sec.">
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LAT_DEG#">
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LAT_MIN#">
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LAT_SEC#" scale="6">
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LAT_DIR#">
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LONG_DEG#">
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LONG_MIN#">
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LONG_SEC#" scale="6">
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LONG_DIR#">
					<cfelseif #ORIG_LAT_LONG_UNITS# is "degrees dec. minutes">
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LAT_DEG#">
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DEC_LAT_MIN#" scale="6">
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LAT_DIR#">
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LONG_DEG#">
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DEC_LONG_MIN#" scale="8">
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LONG_DIR#">
					<cfelseif #ORIG_LAT_LONG_UNITS# is "decimal degrees">
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DEC_LAT#" scale="10">
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DEC_LONG#" scale="10">
					<cfelseif #ORIG_LAT_LONG_UNITS# is "UTM">
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#UTM_ZONE#">
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#UTM_EW#">
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#UTM_NS#">
					</cfif>
					<cfif isDefined("geolocate_uncertaintypolygon") AND len(geolocate_uncertaintypolygon) GT 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geolocate_uncertaintypolygon#">
					</cfif>
					<cfif isDefined("geolocate_score") AND len(geolocate_score) GT 0>
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geolocate_score#">
					</cfif>
					<cfif isDefined("geolocate_precision") AND len(geolocate_precision) GT 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geolocate_precision#">
					</cfif>
					<cfif isDefined("geolocate_numresults") AND len(geolocate_numresults) GT 0>
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geolocate_numresults#">
					</cfif>
					<cfif isDefined("geolocate_parsepattern") AND len(geolocate_parsepattern) GT 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geolocate_parsepattern#">
					</cfif>
					<cfif isDefined("spatialfit") AND len(spatialfit) GT 0>
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#spatialfit#" scale="3"> 
					</cfif>
					<cfif isDefined("footprint_spatialfit") AND len(footprint_spatialfit) GT 0>
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#footprint_spatialfit#" scale="3"> 
					</cfif>
					<cfif isDefined("nearest_named_place") AND len(nearest_named_place) GT 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nearest_named_place#"> 
					</cfif>
					<cfif isDefined("lat_long_for_nnp_fg") AND len(lat_long_for_nnp_fg) GT 0>
						,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lat_long_for_nnp_fg#"> 
					</cfif>
				)
			</cfquery>
			<cfif insertLatLong_result.recordcount NEQ 1>
				<cfthrow message="Unable to insert, other than one row would be inserted.">
			</cfif>
			<cfif isDefined("error_polygon") AND len(#error_polygon#) gt 0>
				<cfquery name="addErrorPolygon" datasource="uam_god" result="addErrorPolygon_result">
					UPDATE 
						lat_long 
					SET
						error_polygon = <cfqueryparam cfsqltype="CF_SQL_CLOB" value="#error_polygon#"> 
					WHERE 
						lat_long_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getLATLONGID.latlongid#">
				</cfquery>
				<cfif addErrorPolygon_result.recordcount NEQ 1>
					<cfthrow message="Unable to insert, other than one row would be changed when updating error polygon.">
				</cfif>
			</cfif>
			<cfquery name="countAccepted" datasource="uam_god" result="countAccepted_result">
				SELECT count(*) ct
				FROM lat_long
				WHERE
					locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
					and 
					accepted_lat_long_fg = 1
			</cfquery>
			<cfset message = "">
			<cfif countAccepted.ct EQ 0>
				<!--- warning state, but not a failure case --->
				<cfset message = "This locality has no accepted georeferences.">
			</cfif>
			<cfset row = StructNew()>
			<cfset row["status"] = "added">
			<cfset row["id"] = "#getLATLONGID.latlongid#">
			<cfset row["values"] = "#getLATLONGID.latlongid#">
			<cfset row["message"] = "#message#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		<cffinally>
			<cfif accepted_lat_long_fg EQ "1" AND triggerState EQ "off">
				<cfquery name="turnOn" datasource="uam_god">
					ALTER TRIGGER MCZBASE.TR_LATLONG_ACCEPTED_BIUPA ENABLE
				</cfquery>
			</cfif>
		</cffinally>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- getGeoreference obtain json for the accepted georeference for a locality, if any.
 @param locality_id the locality for which to obtain the georeference.
--->
<cffunction name="getGeoreference" returntype="any" access="remote" returnformat="json">
	<cfargument name="locality_id" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftry>
		<cfset i = 1>
		<cfquery name="getGeoreference" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				lat_long_id,
				georefmethod,
				nvl2(coordinate_precision, round(dec_lat,coordinate_precision), round(dec_lat,5)) dec_lat,
				dec_lat raw_dec_lat,
				nvl2(coordinate_precision, round(dec_long,coordinate_precision), round(dec_long,5)) dec_long,
				dec_long raw_dec_long,
				max_error_distance,
				max_error_units,
				round(to_meters(lat_long.max_error_distance, lat_long.max_error_units)) coordinateUncertaintyInMeters,
				error_polygon,
				datum,
				extent,
				extent_units,
				spatialfit,
				determined_by_agent_id,
				det_agent.agent_name determined_by,
				to_char(determined_date,'yyyy-mm-dd') determined_date,
				gpsaccuracy,
				lat_long_ref_source,
				nearest_named_place,
				lat_long_for_nnp_fg,
				verificationstatus,
				field_verified_fg,
				verified_by_agent_id,
				ver_agent.agent_name verified_by,
				orig_lat_long_units,
				lat_deg, dec_lat_min, lat_min, lat_sec, lat_dir,
				long_deg, dec_long_min, long_min, long_sec, long_dir,
				utm_zone, utm_ew, utm_ns,
				CASE orig_lat_long_units
					WHEN 'decimal degrees' THEN dec_lat || '&##176;'
					WHEN 'deg. min. sec.' THEN lat_deg || '&##176; ' || lat_min || '&apos; ' || lat_sec || '&quot; ' || lat_dir
					WHEN 'degrees dec. minutes' THEN lat_deg || '&##176; ' || dec_lat_min || '&apos; ' || lat_dir
				END as LatitudeString,
				CASE orig_lat_long_units
					WHEN 'decimal degrees' THEN dec_long || '&##176;'
					WHEN'degrees dec. minutes' THEN long_deg || '&##176; ' || dec_long_min || '&apos; ' || long_dir
					WHEN 'deg. min. sec.' THEN long_deg || '&##176; ' || long_min || '&apos; ' || long_sec || '&quot ' || long_dir
				END as LongitudeString,
				accepted_lat_long_fg,
				geolocate_uncertaintypolygon,
				geolocate_score,
				geolocate_precision,
				geolocate_numresults,
				geolocate_parsepattern,
				lat_long_remarks
			FROM
				lat_long
				left join preferred_agent_name det_agent on lat_long.determined_by_agent_id = det_agent.agent_id
				left join preferred_agent_name ver_agent on lat_long.verified_by_agent_id = ver_agent.agent_id
			WHERE 
				lat_long.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
				and 
				accepted_lat_long_fg = 1
				and
				rownum < 2
			ORDER BY
				determined_date desc
		</cfquery>
		<cfloop query="getGeoreference">
			<cfset row = StructNew()>
			<cfset columnNames = ListToArray(getGeoreference.columnList)>
			<cfloop array="#columnNames#" index="columnName">
				<cfset row["#columnName#"] = "#getGeoreference[columnName][currentrow]#">
			</cfloop>
			<cfset data[i] = row>
			<cfset i = i + 1>
		</cfloop>
	<cfcatch>
		<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
		<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn #serializeJSON(data)#>

</cffunction>

<!--- given a lat_long_id, return html to populate a dialog to edit the specified georeference.
  @param lat_long_id the pk value of the georeference to edit.
  @return html to populate a dialog.
--->
<cffunction name="editGeoreferenceDialogHtml" access="remote" returntype="string">
	<cfargument name="lat_long_id" type="string" required="yes">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getGeorefThread#tn#">
		<cftry>
			<cfquery name="getGeoref" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					locality_id,
					lat_long_id,
					accepted_lat_long_fg,
					decode(accepted_lat_long_fg,1,'Accepted','') accepted_lat_long,
					orig_lat_long_units,
					lat_deg, dec_lat_min, lat_min, lat_sec, lat_dir,
					long_deg, dec_long_min, long_min, long_sec, long_dir,
					utm_zone, utm_ew, utm_ns,
					georefmethod,
					coordinate_precision,
					nvl2(coordinate_precision, round(dec_lat,coordinate_precision), round(dec_lat,5)) dec_lat,
					dec_lat raw_dec_lat,
					nvl2(coordinate_precision, round(dec_long,coordinate_precision), round(dec_long,5)) dec_long,
					dec_long raw_dec_long,
					max_error_distance,
					max_error_units,
					round(to_meters(lat_long.max_error_distance, lat_long.max_error_units)) coordinateUncertaintyInMeters,
					spatialfit,
					error_polygon,
					footprint_spatialfit,
					datum,
					extent,
					extent_units,
					determined_by_agent_id,
					det_agent.agent_name determined_by,
					to_char(determined_date,'yyyy-mm-dd') determined_date,
					gpsaccuracy,
					lat_long_ref_source,
					nearest_named_place,
					lat_long_for_nnp_fg,
					verificationstatus,
					field_verified_fg,
					verified_by_agent_id,
					ver_agent.agent_name verified_by,
					CASE orig_lat_long_units
						WHEN 'decimal degrees' THEN dec_lat || '&##176;'
						WHEN 'deg. min. sec.' THEN lat_deg || '&##176; ' || lat_min || '&apos; ' || lat_sec || '&quot; ' || lat_dir
						WHEN 'degrees dec. minutes' THEN lat_deg || '&##176; ' || dec_lat_min || '&apos; ' || lat_dir
					END as LatitudeString,
					CASE orig_lat_long_units
						WHEN 'decimal degrees' THEN dec_long || '&##176;'
						WHEN'degrees dec. minutes' THEN long_deg || '&##176; ' || dec_long_min || '&apos; ' || long_dir
						WHEN 'deg. min. sec.' THEN long_deg || '&##176; ' || long_min || '&apos; ' || long_sec || '&quot ' || long_dir
					END as LongitudeString,
					geolocate_uncertaintypolygon,
					geolocate_score,
					geolocate_precision,
					geolocate_numresults,
					geolocate_parsepattern,
					lat_long_remarks
				FROM
					lat_long
					left join preferred_agent_name det_agent on lat_long.determined_by_agent_id = det_agent.agent_id
					left join preferred_agent_name ver_agent on lat_long.verified_by_agent_id = ver_agent.agent_id
				WHERE 
					lat_long_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lat_long_id#">
			</cfquery>
			<cfif getGeoref.recordcount NEQ 1>
				<cfthrow message="Error: lat_long record not found for provided lat_long_id [#encodeForHtml(lat_long_id)#].">
			</cfif>
			<cfquery name="ctunits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT ORIG_LAT_LONG_UNITS 
				FROM ctlat_long_units
				ORDER BY ORIG_LAT_LONG_UNITS
			</cfquery>
			<cfquery name="ctGeorefMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT georefmethod 
				FROM ctgeorefmethod
				ORDER BY georefmethod
			</cfquery>
			<cfquery name="ctVerificationStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT verificationStatus 
				FROM ctVerificationStatus 
				ORDER BY verificationStatus
			</cfquery>
			<cfquery name="getCurrentUser" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT agent_id, 
						agent_name
				FROM preferred_agent_name
				WHERE
					agent_id in (
						SELECT agent_id 
						FROM agent_name 
						WHERE upper(agent_name) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(session.username)#">
							and agent_name_type = 'login'
					)
			</cfquery>
			<cfoutput>
				<cfloop query="getGeoref">
					<cfquery name="getLocalityMetadata" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT 
							nvl(spec_locality,'[No specific locality value]') spec_locality, 
							locality_id, 
							decode(curated_fg,1,' *','') curated
						FROM locality
						WHERE
							locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getGeoref.locality_id#">
					</cfquery>
					<cfset locality_label = "#getLocalityMetadata.spec_locality##getLocalityMetadata.curated#">
					<h2 class="h3 mt-0 px-1 font-weight-bold">
						Edit Georeference: 
						<i class="fas fa-info-circle" onClick="getMCZDocs('Georeferencing')" aria-label="georeferencing help link"></i>
						#latitudeString#, #longitudeString# for locality #encodeForHtml(locality_label)#
					</h2>
					<p class="px-3">See: Chapman A.D. &amp; Wieczorek J.R. 2020, Georeferencing Best Practices. Copenhagen: GBIF Secretariat. <a href="https://doi.org/10.15468/doc-gg7h-s853" target="_blank">DOI:10.15468/doc-gg7h-s853</a>.</p>
					<div id="editEnclosingDiv" class="col-12 px-0 mx-0 active unfocus">
						<form id="editGeorefForm">
							<input type="hidden" name="method" value="updateGeoreference">
							<input type="hidden" name="field_mapping" value="generic"> 
							<input type="hidden" name="locality_id" value="#locality_id#">
							<input type="hidden" name="lat_long_id" value="#lat_long_id#">
							<!---<h2 class="px-2 h3">Edit georeference</h2>--->
							<div class="form-row">
								<div class="col-12 col-md-3 mb-2">
									<label for="orig_lat_long_units" class="data-entry-label">Coordinate Format</label>
									<select id="orig_lat_long_units" name="orig_lat_long_units" class="data-entry-select reqdClr" onChange=" changeLatLongUnits(); ">
										<cfif orig_lat_long_units EQ "decimal degrees"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="decimal degrees" #selected#>decimal degrees</option>
										<cfif orig_lat_long_units EQ "degrees dec. minutes"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="degrees dec. minutes" #selected#>degrees decimal minutes</option>
										<cfif orig_lat_long_units EQ "deg. min. sec."><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="deg. min. sec." #selected#>deg. min. sec.</option>
										<cfif orig_lat_long_units EQ "UTM"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="UTM" #selected#>UTM (Universal Transverse Mercator)</option>
									</select>
									<script>
										function changeLatLongUnits(){ 
											$(".latlong").prop('disabled', true);
											$(".latlong").prop('required', false);
											$(".latlong").removeClass('reqdClr');
											$(".latlong").addClass('bg-lt-gray');
											$(".utm").removeClass('reqdClr');
											$(".utm").addClass('bg-lt-gray');
											$(".utm").prop('disabled', true);
											$(".utm").prop('required', false);
											var units = $("##orig_lat_long_units").val();
											if (!units) { 
												$(".latlong").prop('disabled', true);
												$(".utm").prop('disabled', true);
											} else if (units == 'decimal degrees') {
												$("##lat_deg").prop('disabled', false);
												$("##lat_deg").prop('required', true);
												$("##lat_deg").addClass('reqdClr');
												$("##lat_deg").removeClass('bg-lt-grey');
												$("##long_deg").prop('disabled', false);
												$("##long_deg").prop('required', true);
												$("##long_deg").addClass('reqdClr');
												$("##long_deg").removeClass('bg-lt-grey');
											} else if (units == 'degrees dec. minutes') {
												$("##lat_deg").prop('disabled', false);
												$("##lat_deg").prop('required', true);
												$("##lat_deg").addClass('reqdClr');
												$("##lat_deg").removeClass('bg-lt-grey');
												$("##lat_min").prop('disabled', false);
												$("##lat_min").prop('required', true);
												$("##lat_min").addClass('reqdClr');
												$("##lat_min").removeClass('bg-lt-grey');
												$("##lat_dir").prop('disabled', false);
												$("##lat_dir").prop('required', true);
												$("##lat_dir").addClass('reqdClr');
												$("##long_deg").prop('disabled', false);
												$("##long_deg").prop('required', true);
												$("##long_deg").addClass('reqdClr');
												$("##long_deg").removeClass('bg-lt-grey');
												$("##long_min").prop('disabled', false);
												$("##long_mit").prop('required', true);
												$("##long_min").addClass('reqdClr');
												$("##long_min").removeClass('bg-lt-grey');
												$("##long_dir").prop('disabled', false);
												$("##long_dir").prop('required', true);
												$("##long_dir").addClass('reqdClr');
												$("##long_dir").removeClass('bg-lt-grey');
											} else if (units == 'deg. min. sec.') {
												$(".latlong").prop('disabled', false);
												$(".latlong").addClass('reqdClr');
												$(".latlong").removeClass('bg-lt-grey');
												$(".latlong").prop('required', true);
											} else if (units == 'UTM') {
												$(".utm").prop('disabled', false);
												$(".utm").prop('required', true);
												$(".utm").addClass('reqdClr');
												$(".utm").removeClass('bg-lt-grey');
											}
										} 
										$(document).ready(changeLatLongUnits);
									</script>
								</div>
								<div class="col-12 col-md-3 mb-2">
									<label for="accepted_lat_long_fg" class="data-entry-label">Accepted</label>
									<select name="accepted_lat_long_fg" size="1" id="accepted_lat_long_fg" class="data-entry-select reqdClr">
										<cfif accepted_lat_long_fg EQ "1"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="1" #selected#>Yes</option>
										<cfif accepted_lat_long_fg EQ "0"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="0" #selected#>No</option>
									</select>
								</div>
								<div class="col-12 col-md-3 mb-2">
									<label for="determined_by_agent" class="data-entry-label">Determiner</label>
									<input type="hidden" name="determined_by_agent_id" id="determined_by_agent_id" value="#determined_by_agent_id#">
									<input type="text" name="determined_by_agent" id="determined_by_agent" class="data-entry-input reqdClr" value="#encodeForHtml(determined_by)#">
									<script>
										$(document).ready(function() { 
											makeAgentAutocompleteMeta("determined_by_agent", "determined_by_agent_id");
										});
									</script>
								</div>
								<div class="col-12 col-md-3">
									<label for="determined_date" class="data-entry-label">Date Determined</label>
									<input type="text" name="determined_date" id="determined_date" class="data-entry-input reqdClr" placeholder="yyyy-mm-dd" value="#determined_date#">
									<script>
										$(document).ready(function() {
											$("##determined_date").datepicker({ dateFormat: 'yy-mm-dd'});
										});
									</script>
								</div>
								<div class="col-12 col-md-3 mb-2">
									<cfif orig_lat_long_units EQ "decimal degrees"><cfset deg="#dec_lat#"><cfelse><cfset deg="#lat_deg#"></cfif>
									<label for="lat_deg" class="data-entry-label">Latitude Degrees &##176;</label>
									<input type="text" name="lat_deg" id="lat_deg" class="data-entry-input latlong" value="#deg#">
								</div>
								<div class="col-12 col-md-3 mb-2">
									<label for="lat_min" class="data-entry-label">Minutes &apos;</label>
									<cfif orig_lat_long_units EQ "degrees dec. minutes"><cfset min="#dec_lat_min#"><cfelse><cfset min="#lat_min#"></cfif>
									<input type="text" name="lat_min" id="lat_min" class="data-entry-input latlong" value="#min#">
								</div>
								<div class="col-12 col-md-3 mb-2">
									<label for="lat_sec" class="data-entry-label">Seconds &quot;</label>
									<input type="text" name="lat_sec" id="lat_sec" class="data-entry-input latlong" value="#lat_sec#">
								</div>
								<div class="col-12 col-md-3 mb-2">
									<label for="lat_dir" class="data-entry-label">Direction</label>
									<select name="lat_dir" size="1" id="lat_dir" class="data-entry-select latlong">
										<cfif lat_dir EQ ""><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="" #selected#></option>
										<cfif lat_dir EQ "N"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="N" #selected#>N</option>
										<cfif lat_dir EQ "S"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="S" #selected#>S</option>
									</select>
								</div>
								<div class="col-12 col-md-3 mb-2">
									<cfif orig_lat_long_units EQ "decimal degrees"><cfset deg="#dec_long#"><cfelse><cfset deg="#long_deg#"></cfif>
									<label for="long_deg" class="data-entry-label">Longitude Degrees &##176;</label>
									<input type="text" name="long_deg" size="4" id="long_deg" class="data-entry-input latlong" value="#deg#">
								</div>
								<div class="col-12 col-md-3 mb-2">
									<cfif orig_lat_long_units EQ "degrees dec. minutes"><cfset min="#dec_long_min#"><cfelse><cfset min="#long_min#"></cfif>
									<label for="long_min" class="data-entry-label">Minutes &apos;</label>
									<input type="text" name="long_min" size="4" id="long_min" class="data-entry-input latlong" value="#min#">
								</div>
								<div class="col-12 col-md-3 mb-2">
									<label for="long_sec" class="data-entry-label">Seconds &quot;</label>
									<input type="text" name="long_sec" size="4" id="long_sec" class="data-entry-input latlong" value="#long_sec#">
								</div>
								<div class="col-12 col-md-3 mb-2">
									<label for="long_dir" class="data-entry-label">Direction</label>
									<select name="long_dir" size="1" id="long_dir" class="data-entry-select latlong">
										<cfif long_dir EQ ""><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="" #selected#></option>
										<cfif long_dir EQ "E"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="E" #selected#>E</option>
										<cfif long_dir EQ "W"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="W" #selected#>W</option>
									</select>
								</div>
								<div class="col-12 col-md-4 mb-2">
									<label for="utm_zone" class="data-entry-label">UTM Zone/Letter</label>
									<input type="text" name="utm_zone" size="4" id="utm_zone" class="data-entry-input utm" value="#encodeForHtml(utm_zone)#">
								</div>
								<div class="col-12 col-md-4 mb-2">
									<label for="utm_ew" class="data-entry-label">Easting</label>
									<input type="text" name="utm_ew" size="4" id="utm_ew" class="data-entry-input utm" value="#encodeForHtml(utm_ew)#">
								</div>
								<div class="col-12 col-md-4 mb-2">
									<label for="utm_ns" class="data-entry-label">Northing</label>
									<input type="text" name="utm_ns" size="4" id="utm_ns" class="data-entry-input utm" value="#encodeForHtml(utm_ns)#">
								</div>
								<div class="col-12 col-md-3 mb-2">
									<label for="datum" class="data-entry-label">
										Geodetic Datum
										<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##datum').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open geodetic datum pick list</span></a>
									</label>
									<input type="text" name="datum" id="datum" class="data-entry-input reqdClr" value="#encodeForHtml(datum)#" required>
									<script>
										$(document).ready(function (){
											makeCTAutocomplete('datum','datum');
										});
									</script> 
								</div>
								<div class="col-12 col-md-2 mb-2">
									<label for="max_error_distance" class="data-entry-label">Error Radius</label>
									<input type="text" name="max_error_distance" id="max_error_distance" class="data-entry-input reqdClr" value="#max_error_distance#" required>
								</div>
								<div class="col-12 col-md-1 mb-2">
									<label for="max_error_units" class="data-entry-label">
										Units
										<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##max_error_units').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open pick list for error radius units</span></a>
									</label>
									<input type="text" name="max_error_units" id="max_error_units" class="data-entry-input reqdClr" value="#encodeForHtml(max_error_units)#" required>
									<script>
										$(document).ready(function (){
											makeCTAutocomplete('max_error_units','lat_long_error_units');
										});
									</script> 
								</div>
								<div class="col-12 col-md-3 mb-2">
									<label for="spatialfit" class="data-entry-label">Point Radius Spatial Fit</label>
									<input type="text" name="spatialfit" id="spatialfit" class="data-entry-input" value="#spatialfit#" pattern="^(0|1(\.[0-9]+)|[1-9][0-9.]{0,5}){0,1}$" >
								</div>
								<div class="col-12 col-md-2 mb-2">
									<label for="extent" class="data-entry-label">Radial of Feature [Extent]</label>
									<input type="text" name="extent" id="extent" class="data-entry-input" value="#extent#" pattern="^[0-9.]*$" >
								</div>
								<div class="col-12 col-md-1 mb-2">
									<cfif len(extent) GT 0 AND len(extent_units EQ 0)>
										<!--- if extent has a value and units do not, force user to set units on the extent when editing the georeference --->
										<cfset reqExtentUnits="required">
										<cfset reqdClrEU="reqdClr">
									<cfelse>
										<cfset reqExtentUnits="">
										<cfset reqdClrEU="">
									</cfif>
									<label for="extent_units" class="data-entry-label">
										Units
										<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##extent_units').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open pick list for radial of feature (extent) units</span></a>
									</label>
									<input type="text" name="extent_units" id="extent_units" class="data-entry-input #reqdClrEU#" value="#encodeForHtml(extent_units)#" #reqExtentUnits#>
									<script>
										$(document).ready(function (){
											makeCTAutocomplete('extent_units','lat_long_error_units');
										});
									</script> 
								</div>
								<div class="col-12 col-md-3 mb-2">
									<label for="coordinate_precision" class="data-entry-label">Precision</label>
									<select name="coordinate_precision" id="coordinate_precision" class="data-entry-select reqdClr" required>
										<cfif len(coordinate_precision) EQ 0><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="" #selected#></option>
										<cfif coordinate_precision EQ "0"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="0" #selected#>Specified to 1&##176;</option>
										<cfif coordinate_precision EQ "1"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="1" #selected#>Specified to 0.1&##176;. latitude known to 11 km.</option>
										<cfif coordinate_precision EQ "2"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="2" #selected#>Specified to 0.01&##176;, use if known to 1&apos;, latitude known to 1,111 meters.</option>
										<cfif coordinate_precision EQ "3"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="3" #selected#>Specified to 0.001&##176;, latitude known to 111 meters.</option>
										<cfif coordinate_precision EQ "4"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="4" #selected#>Specified to 0.0001&##176;, use if known to 1&quot;, latitude known to 11 meters.</option>
										<cfif coordinate_precision EQ "5"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="5" #selected#>Specified to 0.00001&##176;, latitude known to 1 meter.</option>
										<cfif coordinate_precision EQ "6"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="6" #selected#>Specified to 0.000001&##176;, latitude known to 11 cm.</option>
									</select>
								</div>
								<div class="col-12 col-md-3 mb-2">
									<label for="gpsaccuracy" class="data-entry-label">GPS Accuracy</label>
									<input type="text" name="gpsaccuracy" id="gpsaccuracy" class="data-entry-input" value="#encodeForHtml(gpsaccuracy)#">
								</div>
								<div class="col-12 col-md-3 mb-2">
									<label for="nearest_named_place" class="data-entry-label">Nearest Named Place</label>
									<input type="text" name="nearest_named_place" id="nearest_named_place" class="data-entry-input" value="#encodeForHtml(nearest_named_place)#">
								</div>
								<div class="col-12 col-md-3 mb-2">
									<label for="lat_long_for_nnp_fg" class="data-entry-label">Georeference is of Nearest Named Place</label>
									<select name="lat_long_for_nnp_fg" id="lat_long_for_nnp_fg" class="data-entry-select reqdClr" required>
										<cfif lat_long_for_nnp_fg EQ "0"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="0" #selected#>No</option>
										<cfif lat_long_for_nnp_fg EQ "1"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
										<option value="1" #selected#>Yes</option>
									</select>
								</div>
								<div class="col-12 col-md-3">
									<label for="lat_long_ref_source" class="data-entry-label">Reference</label>
									<input type="text" name="lat_long_ref_source" id="lat_long_ref_source" class="data-entry-input reqdClr" value="#encodeForHtml(lat_long_ref_source)#" required>
								</div>
								<div class="col-12 col-md-3 mb-2">
									<label for="georefmethod" class="data-entry-label">
										Method
										<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##georefmethod').autocomplete('search','%%%'); return false;" > (&##8595;) <span class="sr-only">open georeference method pick list</span></a>
									</label>
									<input type="text" name="georefmethod" id="georefmethod" class="data-entry-input reqdClr" value="#encodeForHtml(georefmethod)#" required>
									<script>
										$(document).ready(function (){
											makeCTAutocomplete('georefmethod','georefmethod');
										});
									</script> 
								</div>
								<div class="col-12 col-md-3 mb-2">
									<label for="verificationstatus" class="data-entry-label">
										Verification Status
										<cfif getGeoRef.verificationstatus NEQ "unverified">
											<span id="oldverifstatus" class="text-danger" onClick="setVerificationStatus('#getGeoRef.verificationstatus#');">Was: #encodeForHtml(getGeoRef.verificationstatus)# (&##8595;)<span/>
										</cfif>
									</label>
									<select name="verificationstatus" size="1" id="verificationstatus" class="data-entry-select reqdClr" onChange="changeVerificationStatus();">
										<cfloop query="ctVerificationStatus">
											<!--- user needs to explicitly address the verification status or it reverts to unverified --->
											<cfif ctVerificationStatus.verificationstatus EQ "unverified"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
											<option value="#ctVerificationStatus.verificationStatus#" #selected#>#ctVerificationStatus.verificationStatus#</option>
										</cfloop>
									</select>
									<script>
										/* show/hide verified by agent controls depending on verification status */
										function changeVerificationStatus() { 
											var status = $('##verificationstatus').val();
											if (status=='verified by MCZ collection' || status=='rejected by MCZ collection' || status=='verified by collector') {
												$('##verified_by_agent').show();
												$('##verified_by_agent_label').show();
											} else { 
												$('##verified_by_agent').hide();
												$('##verified_by_agent_label').hide();
												$('##verified_by_agent').val("");
												$('##verified_by_agent_id').val("");
											}
											$('##verificationstatus').removeClass("bg-verylightred");
											$('##verified_by_agent').removeClass("bg-verylightred");
											$('##verificationstatus').addClass("reqdClr");
											$('##verified_by_agent').addClass("reqdClr");
										};
										function setVerificationStatus(value) { 
											$('##verificationstatus').val(value);
											changeVerificationStatus();
											$('##oldverifstatus').removeClass("text-danger");
										} 
									</script>
								</div>
								<div class="col-12 col-md-3 mb-2">
									<label for="verified_by_agent" class="data-entry-label" id="verified_by_agent_label" >
										Verified by
										<a href="javascript:void(0)" tabindex="-1" aria-hidden="true" class="btn-link" onclick=" $('##verified_by_agent_id').val('#getCurrentUser.agent_id#');  $('##verified_by_agent').val('#encodeForHtml(getCurrentUser.agent_name)#'); return false;" > (me) <span class="sr-only">Fill in verified by with #encodeForHtml(getCurrentUser.agent_name)#</span></a>
									</label>
									<input type="hidden" name="verified_by_agent_id" id="verified_by_agent_id" value="#verified_by_agent_id#">
									<input type="text" name="verified_by_agent" id="verified_by_agent" class="data-entry-input reqdClr" value="#verified_by#">
									<script>
										$(document).ready(function() { 
											makeAgentAutocompleteMeta("verified_by_agent", "verified_by_agent_id");
											<cfif getGeoRef.verificationstatus EQ "unverified" OR getGeoRef.verificationstatus EQ "migration" OR getGeoRef.verificationstatus EQ "unknown" >
												$('##verified_by_agent').hide();
												$('##verified_by_agent_label').hide();
											</cfif>
											<cfif getGeoRef.verificationstatus NEQ "unverified">
												<!--- setup appearance when user needs to explicitly address the verification status or it reverts to unverified --->
												$('##verificationstatus').addClass("bg-verylightred");
												$('##verified_by_agent').addClass("bg-verylightred");
												$('##verificationstatus').removeClass("reqdClr");
												$('##verified_by_agent').removeClass("reqdClr");
											</cfif>
										});
									</script>
								</div>
								<div class="col-12 mb-2">
									<label class="data-entry-label" for="lat_long_remarks">Georeference Remarks (<span id="length_lat_long_remarks">0 of 4000 characters</span>)</label>
									<textarea name="lat_long_remarks" id="lat_long_remarks" 
										onkeyup="countCharsLeft('lat_long_remarks', 4000, 'length_lat_long_remarks');"
										class="form-control form-control-sm w-100 autogrow mb-1" style="min-height: 30px;" rows="2">#encodeForHtml(lat_long_remarks)#</textarea>
									<script>
										// Bind input to autogrow function on key up, and trigger autogrow to fit text
										$(document).ready(function() { 
											$("##lat_long_remarks").keyup(autogrow);  
											$('##lat_long_remarks').keyup();
										});
									</script>
								</div>
								<div class="col-12 col-md-9 mb-2">
									<label for="error_polygon" class="data-entry-label" id="error_polygon_label">Footprint Polygon (WKT)</label>
									<input type="text" name="error_polygon" id="error_polygon" class="data-entry-input" value="#encodeForHtml(error_polygon)#">
								</div>
								<div class="col-12 col-md-3 mb-2">
									<label for="footprint_spatialfit" class="data-entry-label">Footprint Spatial Fit</label>
									<input type="text" name="footprint_spatialfit" id="footprint_spatialfit" class="data-entry-input" value="#footprint_spatialfit#" pattern="^(0|1(\.[0-9]+)|[1-9][0-9.]{0,5}){0,1}$" >
								</div>
								<div class="col-12 col-md-6 col-xl-3 mb-2">
									<label for="wktFile" class="data-entry-label">Load Footprint Polygon from WKT file</label>
									<input type="file" id="wktFile" name="wktFile" accept=".wkt" class="w-100 p-0">
									<script>
										$(document).ready(function() { 
											$("##wktFile").change(confirmLoadWKTFromFile);
										});
										function confirmLoadWKTFromFile(){
											if ($("##error_polygon").val().length > 1) {
												confirmDialog('This Georeference has a Footprint Polygon, do you wish to overwrite it?','Confirm overwrite Footprint WKT', loadWKTFromFile);
											} else {
												loadWKTFromFile();
											}
										}
										function loadWKTFromFile() { 
											loadPolygonWKTFromFile('wktFile', 'error_polygon', 'wktReplaceFeedback');
										}
									</script>
								</div>
								<div class="col-12 col-md-6 col-xl-2 mt-3 text-danger mb-2">
									<output id="wktReplaceFeedback"></output>
								</div>
								<div class="col-12 col-md-6 col-xl-3 mb-2">
									<label for="copyFootprintFrom" class="data-entry-label" >Copy Polygon from locality_id</label>
									<input type="hidden" name="copyFootprintFrom_id" id="copyFootprintFrom_id" value="">
									<input type="text" name="copyFootprintFrom" id="copyFootprintFrom" value="" class="data-entry-input">
									<script> 
										$(document).ready(function() { 
											makeLocalityAutocompleteMetaLimited("copyFootprintFrom", "copyFootprintFrom_id","has_footprint");
										});
										function copyWKTFromLocality() { 
											var lookup_locality_id = $("##copyFootprintFrom_id").val();
											if (lookup_locality_id=="") {
												$("##wktLocReplaceFeedback").html("No locality selected to look up.");
											} else {  
												$("##wktLocReplaceFeedback").html("Loading...");
												jQuery.ajax({
													url: "/localities/component/georefUtilities.cfc",
													type: "get",
													data: {
														method: "getGeoreferenceErrorWKT",
														returnformat: "plain",
														locality_id: lookup_locality_id
													}, 
													success: function (data) { 
														$("##error_polygon").val(data);
														$("##wktLocReplaceFeedback").html("Loaded.");
													}, 
													error: function (jqXHR, textStatus, error) {
														$("##wktLocReplaceFeedback").html("Error looking up polygon WKT.");
														handleFail(jqXHR,textStatus,error,"looking up wkt for accepted lat_long for locality");
													}
												});
											} 
										} 
										function confirmCopyWKTFromLocality(){
											if ($("##error_polygon").val().length > 1) {
												confirmDialog('This Georeference has a Footprint Polygon, do you wish to overwrite it?','Confirm overwrite Footprint WKT', copyWKTFromLocality);
											} else {
												copyWKTFromLocality();
											}
										}
									</script>
								</div>
								<div class="col-2 col-md-2 col-xl-1 mb-2">
									<label class="data-entry-label">&nbsp;</label>
									<input type="button" value="Copy" class="btn btn-xs btn-secondary" onClick=" confirmCopyWKTFromLocality(); ">
								</div>
								<div class="col-12 col-md-4 col-xl-3 mb-2">
									<output id="wktLocReplaceFeedback"></output>
								</div>
								<cfif len(geolocate_score) GT 0>
									<div class="geolocateMetadata col-12 mb-1">
										<h3 class="h4 my-1 px-1">Batch GeoLocate Georeference Metadata</h3>
									</div>
									<div class="geolocateMetadata col-12 col-md-3 mb-0">
										<label for="geolocate_uncertaintypolygon" class="data-entry-label" id="geolocate_uncertaintypolygon_label">GeoLocate Uncertainty Polygon</label>
										<input type="text" name="geolocate_uncertaintypolygon" id="geolocate_uncertaintypolygon" class="data-entry-input bg-lt-gray" value="#encodeForHtml(geolocate_uncertaintypolygon)#"  readonly>
									</div>
									<div class="geolocateMetadata col-12 col-md-2 mb-0">
										<label for="geolocate_score" class="data-entry-label" id="geolocate_score_label">GeoLocate Score</label>
										<input type="text" name="geolocate_score" id="geolocate_score" class="data-entry-input bg-lt-gray" value="#encodeForHtml(geolocate_score)#" readonly>
									</div>
									<div class="geolocateMetadata col-12 col-md-2 mb-0">
										<label for="geolocate_precision" class="data-entry-label" id="geolocate_precision_label">GeoLocate Precision</label>
										<input type="text" name="geolocate_precision" id="geolocate_precision" class="data-entry-input bg-lt-gray" value="#encodeForHtml(geolocate_precision)#" readonly>
									</div>
									<div class="geolocateMetadata col-12 col-md-2 mb-0">
										<label for="geolocate_numresults" class="data-entry-label" id="geolocate_numresults_label">Number of Matches</label>
										<input type="text" name="geolocate_numresults" id="geolocate_numresults" class="data-entry-input bg-lt-gray" value="#encodeForHtml(geolocate_numresults)#" readonly>
									</div>
									<div class="geolocateMetadata col-12 col-md-3 mb-0">
										<label for="geolocate_parsepattern" class="data-entry-label" id="geolocate_parsepattern_label">Parse Pattern</label>
										<input type="text" name="geolocate_parsepattern" id="geolocate_parsepattern" class="data-entry-input bg-lt-gray" value="#encodeForHtml(geolocate_parsepattern)#" readonly>
									</div>
								</cfif>
								<div class="col-12 col-md-3 mb-2">
									<input type="button" value="Save" class="btn btn-xs btn-primary mr-2"
										onClick="if (checkFormValidity($('##editGeorefForm')[0])) { saveGeorefUpdate();  } " 
										id="submitButton" >
									<output id="georefEditFeedback" class="text-danger">&nbsp;</output>	
								</div>
								<script>
									function saveGeorefUpdate() { 
										$('##georefEditFeedback').html('Saving....');
										$('##georefEditFeedback').addClass('text-warning');
										$('##georefEditFeedback').removeClass('text-success');
										$('##georefEditFeedback').removeClass('text-danger');
										jQuery.ajax({
											url : "/localities/component/functions.cfc",
											type : "post",
											dataType : "json",
											data : $('##editGeorefForm').serialize(),
											success : function (data) {
												console.log(data);
												$('##georefEditFeedback').html('Saved.' + data[0].values + ' <span class="text-danger">' + data[0].message + '</span>');
												$('##georeferenceDialogFeedback').html('Saved.' + data[0].values + ' <span class="text-danger">' + data[0].message + '</span>');
												$('##georefEditFeedback').addClass('text-success');
												$('##georefEditFeedback').removeClass('text-danger');
												$('##georefEditFeedback').removeClass('text-warning');
												$('##addGeorefDialog').dialog('close');
											},
											error: function(jqXHR,textStatus,error){
												$('##georefEditFeedback').html('Error.');
												$('##georefEditFeedback').addClass('text-danger');
												$('##georefEditFeedback').removeClass('text-success');
												$('##georefEditFeedback').removeClass('text-warning');
												handleFail(jqXHR,textStatus,error,'updating georeference for locality');
											}
										});
									}
								</script>
							</div>
						</form>
					</div>
				</cfloop>
			</cfoutput>
		<cfcatch>
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfoutput>
				<h2 class="h3">Error in #function_called#:</h2>
				<div>#error_message#</div>
			</cfoutput>
		</cfcatch>
		</cftry>
	</cfthread>
	<cfthread action="join" name="getGeorefThread#tn#" />
	<cfreturn cfthread["getGeorefThread#tn#"].output>
</cffunction>


<cffunction name="updateGeoreference" access="remote" returntype="any" returnformat="json">
	<cfargument name="lat_long_id" type="string" required="yes">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="field_mapping" type="string" required="yes">
	<cfargument name="accepted_lat_long_fg" type="string" required="yes">
	<cfargument name="orig_lat_long_units" type="string" required="yes">
	<cfargument name="datum" type="string" required="yes">
	<cfargument name="lat_long_ref_source" type="string" required="no">
	<cfargument name="determined_by_agent_id" type="string" required="yes">
	<cfargument name="verified_by_agent_id" type="string" required="no">
	<cfargument name="determined_date" type="string" required="no">
	<cfargument name="georefmethod" type="string" required="no">
	<cfargument name="verificationstatus" type="string" required="yes">
	<cfargument name="extent" type="string" required="no">
	<cfargument name="extent_units" type="string" required="no">
	<cfargument name="spatialfit" type="string" required="no">
	<cfargument name="gpsaccuracy" type="string" required="no">
	<cfargument name="max_error_distance" type="string" required="yes">
	<cfargument name="max_error_units" type="string" required="yes">
	<cfargument name="lat_long_remarks" type="string" required="no">
	<cfargument name="dec_lat" type="string" required="no">
	<cfargument name="dec_long" type="string" required="no">
	<cfargument name="lat_deg" type="string" required="no">
	<cfargument name="long_deg" type="string" required="no">
	<cfargument name="geolocate_uncertaintypolygon" type="string" required="no">
	<cfargument name="geolocate_score" type="string" required="no">
	<cfargument name="geolocate_precision" type="string" required="no">
	<cfargument name="geolocate_num_results" type="string" required="no">
	<cfargument name="geolocate_parsepattern" type="string" required="no">
	<cfargument name="nearest_named_place" type="string" required="no">
	<cfargument name="lat_long_for_nnp_fg" type="string" required="no">
	<cfargument name="footprint_spatialfit" type="string" required="no">
	
	<!--- field_verified_fg unused and deprecated --->

	<!--- currently, not allowing updates to geolocate batch georeferencing metadata fields --->

	<cfif lcase(field_mapping) EQ "generic"> 
		<!--- map lat_deg/long_deg onto dec_lat/dec_long and lat_min/long_min onto dec_lat_min/dec_long_min if appropriate. --->
		<cfswitch expression="#ORIG_LAT_LONG_UNITS#">
			<cfcase value="deg. min. sec.">
				<!---  validate expectations --->
				<cfif isDefined("dec_lat_min") and len(dec_lat_min) GT 0>
					<cfthrow message = "A value was provided for dec_lat_min, but units are degrees, minutes, seconds. Unable to save.">
				</cfif>
				<cfif isDefined("dec_long_min") and len(dec_long_min) GT 0>
					<cfthrow message = "A value was provided for dec_long_min, but units are degrees, minutes, seconds. Unable to save.">
				</cfif>
			</cfcase>
			<cfcase value="degrees dec. minutes">
				<cfset dec_lat_min = lat_min>
				<cfset dec_long_min = long_min>
				<cfset lat_min= "">
				<cfset long_min = "">
			</cfcase>
			<cfcase value="decimal degrees">
				<cfset dec_lat = lat_deg>
				<cfset dec_long = long_deg>
				<cfset lat_deg = "">
				<cfset long_deg = "">
			</cfcase>
		</cfswitch>
	<cfelseif lcase(field_mapping) EQ "specific">
		<!---  validate expectations --->
		<cfswitch expression="#ORIG_LAT_LONG_UNITS#">
			<cfcase value="deg. min. sec.">
				<cfif isDefined("dec_lat_min") and len(dec_lat_min) GT 0>
					<cfthrow message = "A value was provided for dec_lat_min, but units are degrees, minutes, seconds. Unable to save.">
				</cfif>
				<cfif isDefined("dec_long_min") and len(dec_long_min) GT 0>
					<cfthrow message = "A value was provided for dec_long_min, but units are degrees, minutes, seconds. Unable to save.">
				</cfif>
			</cfcase>
			<cfcase value="degrees dec. minutes">
				<cfif isDefined("lat_min") and len(lat_min) GT 0>
					<cfthrow message = "A value was provided for lat_min, but units are degrees, decimal minutes, Unable to save.">
				</cfif>
				<cfif isDefined("long_min") and len(long_min) GT 0>
					<cfthrow message = "A value was provided for long_min, but units are degrees, decimal minutes. Unable to save.">
				</cfif>
				<cfif isDefined("lat_sec") and len(lat_sec) GT 0>
					<cfthrow message = "A value was provided for lat_sec, but units are degrees, decimal minutes, Unable to save.">
				</cfif>
				<cfif isDefined("long_sec") and len(long_sec) GT 0>
					<cfthrow message = "A value was provided for long_sec, but units are degrees, decimal minutes. Unable to save.">
				</cfif>
			</cfcase>
			<cfcase value="decimal degrees">
			</cfcase>
			<cfcase value="UTM">
				<cfif not isDefined("utm_zone") OR len(utm_zone) EQ 0>
					<cfthrow message = "A value was not provided for UTM Zone, but units are UTM. zone, easting, and northing are required. Unable to save.">
				</cfif>
				<cfif not isDefined("utm_ew") OR len(utm_ew) EQ 0>
					<cfthrow message = "A value was not provided for UTM Easting, but units are UTM. zone, easting, and northing are required. Unable to save.">
				</cfif>
				<cfif not isDefined("utm_ns") OR len(utm_ns) EQ 0>
					<cfthrow message = "A value was not provided for UTM Northing, but units are UTM. zone, easting, and northing are required. Unable to save.">
				</cfif>
			</cfcase>
		</cfswitch>
	<cfelse>
		<cfthrow message="Unknown value for field_mapping [#encodeForHtml(field_mapping)#] must be 'generic' or 'specific' ">
	</cfif>
	
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cfset triggerState = "on">
		<cftry>
			<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_locality")>
				<!--- as trigger needs to be disabled, and user_login probably does not have rights to do so, queries are run under a more priviliged user,
        			but within a transaction, so all queries in the transaction need to use the same data source, so check if user has rights to update lat_long 
        			table before performing actual update.  
				--->
			<cfelse>
				<cfthrow message="Unable to update lat_long table, current user does not have adequate rights.">
			</cfif>
			<!--- TR_LATLONG_ACCEPTED_BIUPA checks for only one accepted georeference, uses pragma autonomous_transaction, so 
					updating a lat lont to accepted when one already exists has to occur in more than one transaction or with the trigger disabled --->
			<cfquery name="countAcceptedPre" datasource="uam_god" result="countAcceptedPre_result">
				SELECT count(*) ct
				FROM lat_long
				WHERE
					locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
					and 
					accepted_lat_long_fg = 1
			</cfquery>
			<cfif accepted_lat_long_fg EQ "1" and countAcceptedPre.ct GT 0>
				<cfquery name="turnOff" datasource="uam_god">
					ALTER TRIGGER MCZBASE.TR_LATLONG_ACCEPTED_BIUPA DISABLE
				</cfquery>
				<cfset triggerState = "off">
				<!--- tr_latlong_accepted_biupa doesn't distinguish between current record and other records, it prevents an update when an accepted georeference exists --->
				<cfquery name="unacceptOthers" datasource="uam_god" result="unacceptOthers_result">
					UPDATE lat_long 
					SET accepted_lat_long_fg = 0 
					WHERE
					locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
				</cfquery>
			</cfif>
			<cfquery name="updateLatLong" datasource="uam_god" result="updateLatLong_result">
				UPDATE
					lat_long 
				SET 
					LOCALITY_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LOCALITY_ID#">
					, ACCEPTED_LAT_LONG_FG = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ACCEPTED_LAT_LONG_FG#">
					, DATUM = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DATUM#">
					, lat_long_ref_source = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lat_long_ref_source#">
					, determined_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#determined_by_agent_id#">
					, determined_date = <cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateformat(determined_date,'yyyy-mm-dd')#">
					, georefmethod = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#georefmethod#">
					, verificationstatus = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#verificationstatus#">
					<cfif isDefined("verified_by_agent_id") AND len(#verified_by_agent_id#) gt 0>
						, verified_by_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#verified_by_agent_id#">
					<cfelse>
						, verified_by_agent_id = null
					</cfif>
					<cfif len(#extent#) gt 0>
						, extent = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#extent#" scale="5">
					<cfelse>
						, extent = null
					</cfif>
					<cfif len(#extent_units#) gt 0>
						, extent_units = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#extent_units#">
					<cfelse>
						, extent_units = null
					</cfif>
					<cfif isDefined("gpsaccuracy") AND len(#gpsaccuracy#) gt 0>
						, gpsaccuracy = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#gpsaccuracy#" scale="3">
					<cfelse>
						, gpsaccuracy = null
					</cfif>
					<cfif isDefined("coordinate_precision") AND len(#coordinate_precision#) gt 0>
						, coordinate_precision = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#coordinate_precision#">
					<cfelse>
						, coordinate_precision = null
					</cfif>
					<cfif isDefined("lat_long_remarks") AND len(#lat_long_remarks#) gt 0>
						, lat_long_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lat_long_remarks#">
					<cfelse>
						, lat_long_remarks = null
					</cfif>
					<cfif len(#MAX_ERROR_DISTANCE#) gt 0>
						, MAX_ERROR_DISTANCE = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#MAX_ERROR_DISTANCE#">
					<cfelse>
						, MAX_ERROR_DISTANCE = null
					</cfif>
					<cfif len(#MAX_ERROR_UNITS#) gt 0>
						, MAX_ERROR_UNITS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#MAX_ERROR_UNITS#">
					<cfelse>
						, MAX_ERROR_UNITS = null
					</cfif>
					, ORIG_LAT_LONG_UNITS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ORIG_LAT_LONG_UNITS#">
					<cfif #ORIG_LAT_LONG_UNITS# is "deg. min. sec.">
						, LAT_DEG =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LAT_DEG#">
						, LAT_MIN =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LAT_MIN#">
						, LAT_SEC =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LAT_SEC#" scale="6">
						, LAT_DIR =<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LAT_DIR#">
						, LONG_DEG =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LONG_DEG#">
						, LONG_MIN =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LONG_MIN#">
						, LONG_SEC =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LONG_SEC#" scale="6">
						, LONG_DIR =<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LONG_DIR#">
						, dec_lat_min = null
						, dec_long_min = null
					<cfelseif #ORIG_LAT_LONG_UNITS# is "degrees dec. minutes">
						, LAT_DEG =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LAT_DEG#">
						, DEC_LAT_MIN =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DEC_LAT_MIN#" scale="6">
						, LAT_DIR =<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LAT_DIR#">
						, LONG_DEG =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LONG_DEG#">
						, DEC_LONG_MIN =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DEC_LONG_MIN#" scale="8">
						, LONG_DIR =<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LONG_DIR#">
						, lat_min = null
						, lat_sec = null
						, long_min = null
						, long_sec = null
					<cfelseif #ORIG_LAT_LONG_UNITS# is "decimal degrees">
						, DEC_LAT = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DEC_LAT#" scale="10">
						, DEC_LONG = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DEC_LONG#" scale="10">
						, lat_deg = null
						, lat_min = null
						, lat_sec = null
						, dec_lat_min = null
						, long_deg = null
						, long_min = null
						, long_sec = null
						, dec_long_min = null
					<cfelseif #ORIG_LAT_LONG_UNITS# is "UTM">
					 	, UTM_ZONE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#UTM_ZONE#">
					 	, UTM_EW = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#UTM_EW#">
					 	, UTM_NS = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#UTM_NS#">
						, lat_deg = null
						, lat_min = null
						, lat_sec = null
						, dec_lat_min = null
						, long_deg = null
						, long_min = null
						, long_sec = null
						, dec_long_min = null
					<cfelse>
						<cfthrow message = "Unsupported orig_lat_long_units [#encodeForHtml(orig_lat_long_units)#].">
					</cfif>
					<cfif isDefined("spatialfit") AND len(spatialfit) GT 0>
						, spatialfit = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#spatialfit#" scale="3"> 
					<cfelse>
						, spatialfit = null
					</cfif>
					<cfif isDefined("footprint_spatialfit") AND len(footprint_spatialfit) GT 0>
						, footprint_spatialfit = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#footprint_spatialfit#" scale="3"> 
					<cfelse>
						, footprint_spatialfit = null
					</cfif>
					<cfif isDefined("nearest_named_place") AND len(nearest_named_place) GT 0>
						, nearest_named_place = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nearest_named_place#"> 
					<cfelse>
						, nearest_named_place = null
					</cfif>
					<cfif isDefined("lat_long_for_nnp_fg") AND len(lat_long_for_nnp_fg) GT 0>
						, lat_long_for_nnp_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lat_long_for_nnp_fg#"> 
					<cfelse>
						, lat_long_for_nnp_fg = null
					</cfif>
				WHERE
					lat_long_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lat_long_id#">
			</cfquery>
			<cfif updateLatLong_result.recordcount NEQ 1>
				<cfthrow message="Unable to update, other than one row would be affected.">
			</cfif>
			<cfif isDefined("error_polygon") AND len(#error_polygon#) gt 0>
				<cfquery name="addErrorPolygon" datasource="uam_god" result="addErrorPolygon_result">
					UPDATE 
						lat_long 
					SET
						error_polygon = <cfqueryparam cfsqltype="CF_SQL_CLOB" value="#error_polygon#"> 
					WHERE 
						lat_long_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lat_long_id#">
				</cfquery>
				<cfif addErrorPolygon_result.recordcount NEQ 1>
					<cfthrow message="Unable to insert, other than one row would be changed when updating error polygon.">
				</cfif>
			</cfif>
			<cfquery name="countAccepted" datasource="uam_god" result="countAccepted_result">
				SELECT count(*) ct
				FROM lat_long
				WHERE
					locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
					and 
					accepted_lat_long_fg = 1
			</cfquery>
			<cfif countAccepted.ct EQ 0>
				<!--- warning state, but not a failure case --->
				<cfset message = "This locality has no accepted georeferences.">
			</cfif>
			<cfquery name="summary" datasource="uam_god" result="summary_result">
				SELECT 
					nvl2(coordinate_precision, round(dec_lat,coordinate_precision), round(dec_lat,5)) dec_lat,
					nvl2(coordinate_precision, round(dec_long,coordinate_precision), round(dec_long,5)) dec_long,
					decode(accepted_lat_long_fg,1,'Accepted','') accepted_lat_long
				FROM
					lat_long
				WHERE
					lat_long_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#lat_long_id#">
			</cfquery>		
			<cfset message = "">
			<cfset row = StructNew()>
			<cfset row["status"] = "updated">
			<cfset row["id"] = "#lat_long_id#">
			<cfset row["values"] = "#summary.dec_lat#,#summary.dec_long# #summary.accepted_lat_long#">
			<cfset row["message"] = "#message#">
			<cfset data[1] = row>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset function_called = "#GetFunctionCalledName()#">
			<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
			<cfabort>
		</cfcatch>
		<cffinally>
			<cfif accepted_lat_long_fg EQ "1" AND triggerState EQ "off">
				<cfquery name="turnOn" datasource="uam_god">
					ALTER TRIGGER MCZBASE.TR_LATLONG_ACCEPTED_BIUPA ENABLE
				</cfquery>
			</cfif>
		</cffinally>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

<!--- obtain html form content for creating, cloning, or editing a collecting event. 
--->
<cffunction name="getCollectingEventFormHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="mode" type="string" required="yes">
	<cfargument name="clone_from_collecting_event_id" type="string" required="no">
	<cfargument name="locality_id" type="string" required="no">
	<cfargument name="collecting_event_id" type="string" required="no">
	<cfargument name="verbatim_locality" type="string" required="no">
	<cfargument name="verbatimDepth" type="string" required="no">
	<cfargument name="verbatimElevation" type="string" required="no">
	<cfargument name="verbatimCoordinates" type="string" required="no">
	<cfargument name="verbatimLatitude" type="string" required="no">
	<cfargument name="verbatimLongitude" type="string" required="no">
	<cfargument name="verbatimCoordinateSystem" type="string" required="no">
	<cfargument name="verbatimSRS" type="string" required="no">
	<cfargument name="verbatim_date" type="string" required="no">
	<cfargument name="collecting_time" type="string" required="no">
	
	<cfif isDefined("arguments.verbatim_date")>
		<cfset variables.verbatim_date = arguments.verbatim_date>
	</cfif>
	<cfif isDefined("arguments.verbatim_locality")>
		<cfset variables.verbatim_locality = arguments.verbatim_locality>
	</cfif>
	<cfif isDefined("arguments.verbatimDepth")>
		<cfset variables.verbatimDepth = arguments.verbatimDepth>
	</cfif>
	<cfif isDefined("arguments.verbatimElevation")>
		<cfset variables.verbatimElevation = arguments.verbatimElevation>
	</cfif>
	<cfif isDefined("arguments.verbatimCoordinates")>
		<cfset variables.verbatimCoordinates = arguments.verbatimCoordinates>
	</cfif>
	<cfif isDefined("arguments.verbatimLatitude")>
		<cfset variables.verbatimLatitude = arguments.verbatimLatitude>
	</cfif>
	<cfif isDefined("arguments.verbatimLongitude")>
		<cfset variables.verbatimLongitude = arguments.verbatimLongitude>
	</cfif>
	<cfif isDefined("arguments.verbatimCoordinateSystem")>
		<cfset variables.verbatimCoordinateSystem = arguments.verbatimCoordinateSystem>
	</cfif>
	<cfif isDefined("arguments.verbatimSRS")>
		<cfset variables.verbatimSRS = arguments.verbatimSRS>
	</cfif>
	<cfif isDefined("arguments.collecting_time")>
		<cfset variables.collecting_time = arguments.collecting_time>
	</cfif>
	<cfif isDefined("arguments.locality_id")>
		<cfset variables.locality_id = arguments.locality_id>
	</cfif>

	<cfif mode NEQ "edit" AND mode NEQ "create">
		<cfthrow message="Unknown value for mode [#encodeForHtml(mode)#], must be create or edit.">
	</cfif>

	<cfif isDefined("clone_from_collecting_event_id") AND len(clone_from_collecting_event_id) GT 0 AND mode EQ "create" >
		<cfquery name="eventToCloneFrom" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT locality_id, verbatim_locality, verbatimDepth, verbatimElevation,
				verbatimCoordinates, verbatimLatitude, verbatimLongitude,
				verbatimCoordinateSystem, verbatimSRS,
				verbatim_date, collecting_time,
				startDayOfYear, endDayOfYear, began_date, ended_date,
				coll_event_remarks, collecting_source, habitat_desc
			FROM collecting_event
			WHERE
				collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#clone_from_collecting_event_id#">
		</cfquery>
		<cfif eventToCloneFrom.recordcount EQ 0>
			<cfthrow message = "No event to clone from found for specified collecting event id.">
		<cfelse>
			<cfset variables.locality_id = eventToCloneFrom.locality_id>
			<cfset variables.verbatim_locality = eventToCloneFrom.verbatim_locality>
			<cfset variables.verbatimDepth = eventToCloneFrom.verbatimDepth>
			<cfset variables.verbatimElevation = eventToCloneFrom.verbatimElevation>
			<cfset variables.verbatimCoordinates = eventToCloneFrom.verbatimCoordinates>
			<cfset variables.verbatimLatitude = eventToCloneFrom.verbatimLatitude>
			<cfset variables.verbatimLongitude = eventToCloneFrom.verbatimLongitude>
			<cfset variables.verbatimCoordinateSystem = eventToCloneFrom.verbatimCoordinateSystem>
			<cfset variables.verbatimSRS = eventToCloneFrom.verbatimSRS>
			<cfset variables.verbatim_date = eventToCloneFrom.verbatim_date>
			<cfset variables.collecting_time = eventToCloneFrom.collecting_time>
			<cfset startDayOfYear = eventToCloneFrom.startDayOfYear>
			<cfset endDayOfYear = eventToCloneFrom.endDayOfYear>
			<cfset began_date = eventToCloneFrom.began_date>
			<cfset ended_date = eventToCloneFrom.ended_date>
			<cfset coll_event_remarks = eventToCloneFrom.coll_event_remarks>
			<cfset collecting_source = eventToCloneFrom.collecting_source>
			<cfset habitat_desc = eventToCloneFrom.habitat_desc>
			<!--- TODO: Missing fields in clone 
				valid_distribtion_fg, collecting_method,
				date_determined_by_agent_id, fish_field_number
			--->
		</cfif>
	<cfelseif mode EQ "edit" >
		<cfquery name="getEvent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				collecting_event_id,
				locality_id, verbatim_locality, verbatimDepth, verbatimElevation,
				verbatimCoordinates, verbatimLatitude, verbatimLongitude,
				verbatimCoordinateSystem, verbatimSRS,
				verbatim_date, collecting_time,
				startDayOfYear, endDayOfYear, began_date, ended_date,
				coll_event_remarks, collecting_source, habitat_desc,
				date_began_date, date_ended_date,
				valid_distribution_fg, collecting_method,
				date_determined_by_agent_id, fish_field_number
			FROM collecting_event
			WHERE
				collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
		</cfquery>
		<cfif getEvent.recordcount EQ 0>
			<cfthrow message = "No collecting event found for the specified collecting event id [#encodeForHtml(collecting_event_id)#].">
		<cfelse>
			<cfloop query="getEvent">
				<cfset variables.locality_id = getEvent.locality_id>
				<cfset variables.verbatim_locality = getEvent.verbatim_locality>
				<cfset variables.verbatimDepth = getEvent.verbatimDepth>
				<cfset variables.verbatimElevation = getEvent.verbatimElevation>
				<cfset variables.verbatimCoordinates = getEvent.verbatimCoordinates>
				<cfset variables.verbatimLatitude = getEvent.verbatimLatitude>
				<cfset variables.verbatimLongitude = getEvent.verbatimLongitude>
				<cfset variables.verbatimCoordinateSystem = getEvent.verbatimCoordinateSystem>
				<cfset variables.verbatimSRS = getEvent.verbatimSRS>
				<cfset variables.verbatim_date = getEvent.verbatim_date>
				<cfset variables.collecting_time = getEvent.collecting_time>
				<cfset startDayOfYear = getEvent.startDayOfYear>
				<cfset endDayOfYear = getEvent.endDayOfYear>
				<cfset began_date = getEvent.began_date>
				<cfset ended_date = getEvent.ended_date>
				<cfset coll_event_remarks = getEvent.coll_event_remarks>
				<cfset collecting_source = getEvent.collecting_source>
				<cfset habitat_desc = getEvent.habitat_desc>
				<cfset valid_distribution_fg = getEvent.valid_distribution_fg>
				<cfset collecting_method = getEvent.collecting_method>
				<cfset date_determined_by_agent_id = getEvent.date_determined_by_agent_id>
				<cfset fish_field_number = getEvent.fish_field_number>
			</cfloop>
		</cfif>
	</cfif> 
	<cfset higher_geog = "">
	<cfset spec_locality = "">
	<cfif isDefined("locality_id") AND len(locality_id) GT 0>
		<cfquery name="lookupLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT higher_geog, spec_locality
			FROM 
				locality
				join geog_auth_rec on locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id
			WHERE 
				locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
		</cfquery>
		<cfif lookupLocality.recordCount EQ 0>
			<cfthrow message = "No locality found for specified locality_id [#encodeForHtml(locality_id)#].">
		<cfelse>
			<cfset higher_geog = "#lookupLocality.higher_geog#">
			<cfset spec_locality = "#lookupLocality.spec_locality#">
		</cfif>
	</cfif>

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="createCollEventFormThread#tn#">
		<cfoutput>
			<cftry>
				<cfquery name="ctCollecting_Source" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
					select collecting_source from ctcollecting_source order by collecting_source
				</cfquery>
				<cfquery name="ctCollecting_method" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
					select collecting_method from ctcollecting_method order by collecting_method
				</cfquery>
				<div class="form-row">
					<cfif NOT isDefined("locality_id") OR len(locality_id) EQ 0>
						<div class="col-12">
							<label class="data-entry-label" for="locality_id">Pick Locality for this Collecting Event</label>
							<input type="text" name="locality" id="locality" class="data-entry-input reqdClr" required>
							<input type="hidden" name="locality_id" id="locality_id">
							<script>
								$(document).ready(function() { 
									makeLocalityAutocompleteMeta("locality", "locality_id");
								});
							</script>
						</div>
					<cfelse>
						<div class="col-10">
							<label class="data-entry-label" for="locality_id">Locality</label>
							<input type="text" name="locality" id="locality" class="data-entry-input reqdClr" disabled value="#higher_geog#: #spec_locality# (#locality_id#)">
							<input type="hidden" name="locality_id" id="locality_id" value="#locality_id#">
						</div>
						<div class="col-2">
							<label class="data-entry-label">&nbsp;</label>
							<button type="button" class="btn btn-xs btn-secondary" onclick="enableChangeLocality();">Change Locality</button>
							<script>
								function enableChangeLocality() { 
									console.log("locality edit enabled");
									$("##locality").prop("disabled",false);
									$("##locality").prop("required",true);
									makeLocalityAutocompleteMeta("locality", "locality_id");
								}
							</script>
						</div>
					</cfif>
					<div class="col-12 col-md-3">
						<label for="verbatim_date" class="data-entry-label">
							Verbatim Date
							<span onClick="fillDatesFromVerbatim()">[ copy ]</span>
						</label>
						<cfif not isDefined("variables.verbatim_date")><cfset variables.verbatim_date = ""></cfif>
						<input type="text" name="verbatim_date" id="verbatim_date" class="reqdClr data-entry-input" required="required" value="#encodeForHtml(variables.verbatim_date)#">
						<!--- TODO: interpret and populate began_date/ended_date --->
						<script>
							function fillDatesFromVerbatim() { 
							} 
						</script>
					</div>
					<div class="col-12 col-md-3">
						<label for="began_date" class="data-entry-label">Began Date</label>
						<cfif not isDefined("began_date")><cfset began_date = ""></cfif>
					    <input type="text" name="began_date" id="began_date"  class="reqdClr data-entry-input" required="required" value="#encodeForHTML(began_date)#">
					</div>
					<div class="col-12 col-md-3">
					    <label for="ended_date" class="data-entry-label">Ended Date</label>
						<cfif not isDefined("ended_date")><cfset ended_date = ""></cfif>
					    <input type="text" name="ended_date" id="ended_date" class="reqdClr data-entry-input" required="required" value="#encodeForHTML(ended_date)#" >
					</div>
					<div class="col-12 col-md-3">
						<label for="collecting_time" class="data-entry-label">Collecting Time</label>
						<cfif not isDefined("collecting_time")><cfset collecting_time = ""></cfif>
						<input type="text" name="collecting_time" id="collecting_time"  class="data-entry-input" value="#encodeForHtml(collecting_time)#">
					</div>
					<div class="col-12 col-md-2">
						<label for="startDayOfYear" class="data-entry-label">Start Day of Year</label>
						<cfif not isDefined("startDayOfYear")><cfset startDayOfYear = ""></cfif>
						<input type="text" name="startDayOfYear" id="startDayOfYear" value="#encodeForHTML(startDayOfYear)#" class="data-entry-input">
					</div>
					<div class="col-12 col-md-2">
						<label for="endDayOfYear" class="data-entry-label">End Day of Year</label>
						<cfif not isDefined("endDayOfYear")><cfset endDayOfYear = ""></cfif>
						<input type="text" name="endDayOfYear" id="endDayOfYear" class="data-entry-input" value="#encodeForHTML(endDayOfYear)#">
					</div>
					<div class="col-12 col-md-2">
						<label for="date_determined_by_agent_id" class="data-entry-label">Event Date Determined By</label>
						<input type="hidden" name="date_determined_by_agent_id" id="date_determined_by_agent_id">
						<input type="text" name="date_determined_by_agent" id="date_determined_by_agent" class="data-entry-input">
						<script>
							$(document).ready(function() { 
								makeAgentAutocompleteMeta("date_determined_by_agent", "date_determined_by_agent_id");
							});
						</script>
					</div>
					<div class="col-12 col-md-3">
						<label for="collecting_source" class="data-entry-label">Collecting Source</label>
						<cfif isdefined("collecting_source")> <cfset collsrc = collecting_source> <cfelse> <cfset collsrc = ""> </cfif>
						<select name="collecting_source" id="collecting_source" size="1" class="reqdClr data-entry-select" required="required" >
							<option value=""></option>
							<cfloop query="ctCollecting_Source">
								<cfif ctCollecting_Source.Collecting_Source is collsrc><cfset selected='selected="selected"'><cfelse><cfset selected=''></cfif>
								<option value="#ctCollecting_Source.Collecting_Source#" #selected#>#ctCollecting_Source.Collecting_Source#</option>
							</cfloop>
						</select>
					</div>
					<div class="col-12 col-md-3">
						<label for="fish_field_number">Fish Field Number (Ich only)</label>
						<cfif not isDefined("fish_field_number")><cfset fish_field_number = ""></cfif>
						<input type="text" name="fish_field_number" value="#encodeForHTML(fish_field_number)#" id="fish_field_number" class="data-entry-input">
					</div>
					<div class="col-12 col-md-12">
						<label for="collecting_method" class="data-entry-label">Collecting Method</label>
						<cfif not isdefined("collecting_method")><cfset collecting_method = ""></cfif>
						<input type="text" name="collecting_method" id="collecting_method" value="#encodeForHTML(collecting_method)#" class="data-entry-input" maxlength="255">
					</div>
					<div class="col-12 col-md-12">
						<label for="habitat_desc" class="data-entry-label">Habitat</label>
						<cfif not isDefined("habitat_desc")><cfset habitat_desc = ""></cfif>
						<input type="text" name="habitat_desc" id="habitat_desc" value="#encodeForHTML(HABITAT_DESC)#" class="data-entry-input" maxlength="500">
					</div>
					<div class="col-12">
				     	<label for="verbatim_locality" class="data-entry-label">Verbatim Locality</label>
						<cfset vl_value="">
						<cfif isdefined("variables.verbatim_locality")>
							<cfset vl_value=verbatim_locality>
						<cfelseif isdefined("spec_locality")>
							<cfset vl_value=spec_locality>
						</cfif>
		     			<input type="text" name="verbatim_locality" id="verbatim_locality" class="data-entry-input" value="#encodeForHtml(vl_value)#">
					</div>
					<div class="col-12 col-md-3">
						<label for="verbatimDepth" class="data-entry-label">Verbatim Depth</label>
						<cfif not isDefined("verbatimDepth")><cfset verbatimDepth = ""></cfif>
						<input type="text" name="verbatimDepth" value="#encodeForHTML(verbatimDepth)#" id="verbatimDepth" class="data-entry-input">
					</div>
					<div class="col-12 col-md-3">
						<label for="verbatimElevation" class="data-entry-label">Verbatim Elevation</label>
						<cfif not isDefined("verbatimElevation")><cfset verbatimElevation = ""></cfif>
						<input type="text" name="verbatimElevation" value="#encodeForHTML(verbatimElevation)#" id="verbatimElevation" class="data-entry-input">
					</div>
					<div class="col-12 col-md-3">
						<label for="verbatimCoordinates" class="data-entry-label">Verbatim Coordinates</label>
						<cfif not isDefined("verbatimCoordinates")><cfset verbatimCoordinates = ""></cfif>
						<input type="text" name="verbatimCoordinates" value="#encodeForHTML(verbatimCoordinates)#" id="verbatimCoordinates"  class="data-entry-input">
					</div>
					<div class="col-12 col-md-3">
						<label for="verbatimCoordinateSystem" class="data-entry-label">Verbatim Coordinate System (e.g., decimal degrees)</label>
						<cfif not isDefined("verbatimCoordinateSystem")><cfset verbatimCoordinateSystem = ""></cfif>
						<input type="text" name="verbatimCoordinateSystem" value="#encodeForHTML(verbatimCoordinateSystem)#" id="verbatimCoordinateSystem" class="data-entry-input">
					</div>
					<div class="col-12 col-md-3">
						<label for="verbatimLatitude" class="data-entry-label">Verbatim Latitude</label>
						<cfif not isDefined("verbatimLatitude")><cfset verbatimLatitude = ""></cfif>
						<input type="text" name="verbatimLatitude" value="#encodeForHTML(verbatimLatitude)#" id="verbatimLatitude" class="data-entry-input">
					</div>
					<div class="col-12 col-md-3">
						<label for="verbatimLongitude" class="data-entry-label">Verbatim Longitude</label>
						<cfif not isDefined("verbatimLongitude")><cfset verbatimLongitude = ""></cfif>
						<input type="text" name="verbatimLongitude" value="#encodeForHTML(verbatimLongitude)#" id="verbatimLongitude" class="data-entry-input">
					</div>
					<div class="col-12 col-md-3">
						<label for="verbatimSRS">Verbatim SRS (includes ellipsoid model/Datum)</label>
						<cfif not isDefined("verbatimSRS")><cfset verbatimSRS = ""></cfif>
						<input type="text" name="verbatimSRS" value="#encodeForHTML(verbatimSRS)#" id="verbatimSRS" class="data-entry-input">
					</div>
					<div class="col-12 col-md-3">
						<label for="valid_distribution_fg">Valid Distribution</label>
						<cfif not isDefined("valid_distribution_fg")>
							<cfset valid_distribution_fg = "1">
						</cfif>
						<select name="valid_distribution_fg" id="valid_distribution_fg" class="data-entry-select">
							<cfif valid_distribution_fg EQ "1"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="1" #selected#>Yes, material from this event represents distribution in the wild</option>
							<cfif valid_distribution_fg EQ "0"><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option value="0" #selected#>No, material from this event does not represent distribution in the wild</option>
						</select>
					</div>
					<div class="col-12">
						<label for="coll_event_remarks" class="data-entry-label">Remarks</label>
						<cfif not isDefined("coll_event_remarks")><cfset coll_event_remarks = ""></cfif>
						<textarea name="coll_event_remarks" id="coll_event_remarks" class="autogrow border rounded w-100">#encodeForHTML(coll_event_remarks)#</textarea>
						<script>
							// make selected textareas autogrow as text is entered.
							$(document).ready(function() {
								// bind the autogrow function to the keyup event
								$('textarea.autogrow').keyup(autogrow);
								// trigger keyup event to size textareas to existing text
								$('textarea.autogrow').keyup();
							});
						</script> 
					</div>
				</div>
			<cfcatch>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class="h3 text-danger mt-0">Error: #cfcatch.type# #cfcatch.message# in #function_called#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="createCollEventFormThread#tn#" />

	<cfreturn cfthread["createCollEventFormThread#tn#"].output>

</cffunction>


<cffunction name="getEditCollectingEventNumbersHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collecting_event_id" type="string" required="yes">

	<cfset variables.collecting_event_id = arguments.collecting_event_id>
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="editCollEventFormThread#tn#">
		<cfoutput>
			<cftry>
				<cfquery name="colEventNumbers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT number_series,
						MCZBASE.get_agentnameoftype(collector_agent_id) as collector_agent,
						coll_event_number,
						coll_event_number_id
					FROM
						coll_event_number
						left join coll_event_num_series on coll_event_number.coll_event_num_series_id = coll_event_num_series.coll_event_num_series_id
					WHERE
						coll_event_number.collecting_event_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
				</cfquery>
				<h3>Collector/Field Numbers (identifying collecting events)</h3>
				<ul>
					<cfloop query="colEventNumbers">
						<li><span id="collEventNumber_#coll_event_number_id#">#coll_event_number# (#number_series#, #collector_agent#) <input type="button" value="Delete" class="btn btn-xs btn-danger" onclick=" deleteCollEventNumber(#coll_event_number_id#); "></span></li>
					</cfloop>
					<li><button onClick="openAddCollEventNumberDialog("#collecting_event_id#", "addCENumberDialog#collecting_event_id#", reloadNumbers);" class="btn btn-xs btn-secondary">Add</button></li>
				</ul>
				<div id="addCENumberDialog#collecting_event_id#"></div>
			<cfcatch>
				<cfset function_called = "#GetFunctionCalledName()#">
				<h2 class="h3 text-danger mt-0">Error: #cfcatch.type# #cfcatch.message# in #function_called#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="editCollEventFormThread#tn#" />
	<cfreturn cfthread["editCollEventFormThread#tn#"].output>
</cffunction>

<!--- populate a dialog for adding collecting event numbers to a collecting event 
 @param collecting_event_id the collecting event to which add numbers
 @return a block of html to populate a dialog.
--->
<cffunction name="getAddCollEventNumberDialogHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="collecting_event_id" type="string" required="yes">
	
	<cftry>
		<cfoutput>
			<cfquery name="collEventNumberSeries" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT coll_event_num_series_id, number_series, pattern, remarks, collector_agent_id,
					CASE collector_agent_id WHEN null THEN '[No Agent]' ELSE mczbase.get_agentnameoftype(collector_agent_id) END as collector_agent
				FROM coll_event_num_series
				ORDER BY number_series, mczbase.get_agentnameoftype(collector_agent_id)
			</cfquery>
			<h3>Add</h3>
			<label for="coll_event_number_series">Collecting Event Number Series</label>
			<span>
				<select id="coll_event_number_series" name="coll_event_number_series">
					<option value=""></option>
					<cfset ifbit = "">
					<cfloop query="collEventNumberSeries">
						<option value="#collEventNumberSeries.coll_event_num_series_id#">#collEventNumberSeries.number_series# (#collEventNumberSeries.collector_agent#)</option>
						<cfset ifbit = ifbit & "if (selectedid=#collEventNumberSeries.coll_event_num_series_id#) { $('##pattern_span').html('#collEventNumberSeries.pattern#'); }; ">
					</cfloop>
				</select>
				<a href="/vocabularies/CollEventNumberSeries.cfm?action=new" target="_blank">Add new number series</a>
			</span>
			<!---  On change of picklist, look up the expected pattern for the collecting event number series --->
			<script>
				$( document ).ready(function() {
					$('##coll_event_number_series').change( function() { selectedid = $('##coll_event_number_series').val(); #ifbit# } );
				});
			</script>
			<label for="coll_event_number">Collector/Field Number <span id="pattern_span" style="color: Gray;">#patternvalue#</span></label>
			<input type="text" name="coll_event_number" id="coll_event_number" size=50>
		</cfoutput>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfoutput>
			<h3 class="h4">Error in #function_called#:</h2>
			<div>#error_message#</div>
		</cfoutput>
	</cfcatch>
	</cftry>
</cffunction>

<!--- update a collecting event record with new values, use only when editing a 
 collecting event and changes should be applied to all related cataloged items, 
 not for use to split cataloged item into a new collecting event
 @param collecting_event_id the primary key value of the collecting_event record to update.
 @return a json object with status, id, and message properties, or an http 500.
 --->
<cffunction name="updateCollectingEvent" access="remote" returntype="any" returnformat="json">
	<cfargument name="collecting_event_id" type="string" required="yes">
	<cfargument name="began_date" type="string" required="yes">
	<cfargument name="ended_date" type="string" required="yes">
	<cfargument name="verbatim_date" type="string" required="yes">
	<cfargument name="collecting_source" type="string" required="yes">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="verbatim_locality" type="string" required="no">
	<cfargument name="verbatimDepth" type="string" required="no">
	<cfargument name="verbatimElevation" type="string" required="no">
	<cfargument name="verbatimCoordinates" type="string" required="no">
	<cfargument name="verbatimLatitude" type="string" required="no">
	<cfargument name="verbatimLongitude" type="string" required="no">
	<cfargument name="verbatimCoordinateSystem" type="string" required="no">
	<cfargument name="verbatimSRS" type="string" required="no">
	<cfargument name="collecting_time" type="string" required="no">

	<cfif not isDefined("action")><cfset action="update"></cfif>
	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<cfquery name="ctVerificationStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE collecting_event 
				SET
					began_date = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#began_date#">,
					ended_date = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ended_date#">,
					verbatim_date = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#verbatim_date#">,
					collecting_source = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collecting_source#">,
					locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
					<cfif len(#verbatim_locality#) gt 0>
						,verbatim_locality = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#verbatim_locality#">
					<cfelse>
						,verbatim_locality = null
					</cfif>
					<cfif len(#verbatimdepth#) gt 0>
						,verbatimdepth = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#verbatimdepth#">
					<cfelse>
						,verbatimdepth = null
					</cfif>
					<cfif len(#verbatimelevation#) gt 0>
						,verbatimelevation = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#verbatimelevation#">
					<cfelse>
						,verbatimelevation = null
					</cfif>
					<cfif len(#COLL_EVENT_REMARKS#) gt 0>
						,COLL_EVENT_REMARKS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLL_EVENT_REMARKS#">
					<cfelse>
						,COLL_EVENT_REMARKS = null
					</cfif>
					<cfif len(#COLLECTING_METHOD#) gt 0>
						,COLLECTING_METHOD = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLLECTING_METHOD#">
					<cfelse>
						,COLLECTING_METHOD = null
					</cfif>
					<cfif len(#HABITAT_DESC#) gt 0>
						,HABITAT_DESC = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#HABITAT_DESC#">
					<cfelse>
						,HABITAT_DESC = null
					</cfif>
					<cfif len(#COLLECTING_TIME#) gt 0>
						,COLLECTING_TIME = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#COLLECTING_TIME#">
					<cfelse>
						,COLLECTING_TIME = null
					</cfif>
					<cfif len(#ICH_FIELD_NUMBER#) gt 0>
						,FISH_FIELD_NUMBER = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ICH_FIELD_NUMBER#">
					<cfelse>
						,FISH_FIELD_NUMBER = null
					</cfif>
					<cfif len(#verbatimCoordinates#) gt 0>
						,verbatimCoordinates = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#verbatimCoordinates#">
					<cfelse>
						,verbatimCoordinates = null
					</cfif>
					<cfif len(#verbatimLatitude#) gt 0>
						,verbatimLatitude = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#verbatimLatitude#">
					<cfelse>
						,verbatimLatitude = null
					</cfif>
					<cfif len(#verbatimLongitude#) gt 0>
						,verbatimLongitude = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#verbatimLongitude#">
					<cfelse>
						,verbatimLongitude = null
					</cfif>
					<cfif len(#verbatimCoordinateSystem#) gt 0>
						,verbatimCoordinateSystem = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#verbatimCoordinateSystem#">
					<cfelse>
						,verbatimCoordinateSystem = null
					</cfif>
					<cfif len(#verbatimSRS#) gt 0>
						,verbatimSRS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#verbatimSRS#">
					<cfelse>
						,verbatimSRS = null
					</cfif>
					<cfif len(#startDayOfYear#) gt 0>
						,startDayOfYear = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#startDayOfYear#">
					<cfelse>
						,startDayOfYear = null
					</cfif>
					<cfif len(#endDayOfYear#) gt 0>
						,endDayOfYear = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#endDayOfYear#">
					<cfelse>
						,endDayOfYear = null
					</cfif>
	 			WHERE
					 collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
			</cfquery>
			<cfset message = "">
			<cfset row = StructNew()>
			<cfset row["status"] = "updated">
			<cfset row["id"] = "#collecting_event_id#">
			<cfset row["message"] = "#message#">
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

<!--- function deleteCollectingEvent
Delete an existing collecting event record.

Probably won't be used, delete is action on localities/CollectingEvent.cfm

@param collecting_event_id primary key of record to delete
@return json structure with status and id or http status 500
--->
<cffunction name="deleteCollectingEvent" access="remote" returntype="any" returnformat="json">
	<cfargument name="collecting_event_id" type="string" required="yes">

	<cfset data = ArrayNew(1)>
	<cftransaction>
		<cftry>
			<!--- check if something would block deletion --->
			<cfquery name="hasSpecimens" datasource="uam_god">
				SELECT count(collection_object_id) ct from cataloged_item
				WHERE collecting_event_id= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
			</cfquery>
			<cfif #hasSpecimens.ct# gt 0>
				<cfthrow message="Unable to delete, Collecting Event has #hasSpecimens.ct# related cataloged items..">
			</cfif>
			<cfquery name="deleteBlocks" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT 
					count(*) ct, 'media' as block
				FROM media_relations
				WHERE
					related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
					and media_relationship like '% collecting_event'
					and media_id is not null
				UNION
				SELECT
					count(*) ct, 'number' as block
				FROM
					coll_event_number
				WHERE
					collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
					and coll_event_number_id is not null
			</cfquery>
			<cfset hasBlock = false>
			<cfloop query="deleteBlocks">
				<cfif deleteBlocks.ct GT 0>
					<cfset hasBlock = true>
				</cfif>
			</cfloop>
			<cfif hasBlock>
				<cfthrow message="Unable to delete, Collecting Event has related media or collector numbers.">
			<cfelse>
				<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					delete from collecting_event
					where 
						collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
				</cfquery>
				<cfset row = StructNew()>
				<cfset row["status"] = "deleted">
				<cfset row["id"] = "#collecting_event_id#">
				<cfset data[1] = row>
			</cfif>
			<cftransaction action="commit"/>
		<cfcatch>
			<cftransaction action="rollback"/>
			<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
			<cfset message = trim("Error processing deleteCollEvent: " & cfcatch.message & " " & cfcatch.detail & " " & queryError) >
			<cfheader statusCode="500" statusText="#message#">
			<cfoutput>
				<cfif isDefined("cfcatch.queryError") ><cfset queryError=cfcatch.queryError><cfelse><cfset queryError = ''></cfif>
				<cfset error_message = trim(cfcatch.message & " " & cfcatch.detail & " " & queryError) >
				<cfset function_called = "#GetFunctionCalledName()#">
				<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
				<cfabort>
			</cfoutput>
			<cfabort>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn #serializeJSON(data)#>
</cffunction>

</cfcomponent>
