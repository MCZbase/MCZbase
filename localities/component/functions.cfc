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

<!--- function updateLocality update a locality record 
  @param locality_id the locality to update 
  @return json structure with status=updated and id=locality_id of the locality, 
   or http 500 status on an error.
--->
<cffunction name="updateLocality" access="remote" returntype="any" returnformat="json">
	<cfargument name="locality_id" type="string" required="yes">
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


<!--- function getLocalityUsesHtml return a block of html sumarizing the collecting events, 
   collections, and cataloged items associated with a locality.

   @param locality_id the primary key value for the locality for which to return html.
   @return block of html.
--->
<cffunction name="getLocalityUsesHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="locality_id" type="string" required="yes">
	
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="localityUsesThread#tn#">
		<cfoutput>
			<cftry>
				<cfquery name="localityUses" datasource="uam_god">
			  		SELECT
						count(cataloged_item.cat_num) numOfSpecs,
						count(distinct collecting_event.collecting_event_id) numOfCollEvents,
						collection.collection,
						collection.collection_cde,
						collection.collection_id
					from
						collecting_event
						left join cataloged_item on cataloged_item.collecting_event_id = collecting_event.collecting_event_id 
						left join collection on cataloged_item.collection_id = collection.collection_id
					WHERE
						collecting_event.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
					GROUP BY
						collection.collection,
						collection.collection_cde,
						collection.collection_id
			  	</cfquery>
				<div>
					<cfif #localityUses.recordcount# is 0>
						<div>This Locality (#locality_id#) contains no specimens. Please delete it if you don&apos;t have plans for it!</div>
					<cfelseif #localityUses.recordcount# is 1>
						<div>
							This Locality (#locality_id#) contains 
							<a href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=1&field1=LOCALITY%3ALOCALITY_LOCALITY_ID&searchText1=#locality_id#">
								#localityUses.numOfSpecs# #localityUses.collection_cde# specimens
							</a>
							from <a href="/Locality.cfm?action=findCollEvent&locality_id=#locality_id#&include_counts=true&include_ce_counts=true">#localityUses.numOfCollEvents# collecting events</a>.
						</div>
					<cfelse>
						<cfset totalEvents=0>
						<cfset totalSpecimens=0>
						<cfloop query="localityUses">
							<cfset totalEvents=totalEvents+localityUses.numOfCollEvents>
							<cfset totalSpecimens=totalSpecimens+localityUses.numOfSpecs>
						</cfloop>
						<div>
							This Locality (#locality_id#)
							contains the following <a href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=1&field1=LOCALITY%3ALOCALITY_LOCALITY_ID&searchText1=#locality_id#">#totalSpecimens# specimens</a>
							from <a href="/Locality.cfm?action=findCollEvent&locality_id=#locality_id#&include_counts=true&include_ce_counts=true">#totalEvents# collecting events</a>:
						</div>
						<div>
							<ul>
								<cfloop query="localityUses">
									<li>
										<cfif numOfSpecs GT 0>
											<cfif numOfSpecs EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
											<a href="/Specimens.cfm?execute=true&builderMaxRows=2&action=builderSearch&nestdepth1=1&field1=LOCALITY%3ALOCALITY_LOCALITY_ID&searchText1=#locality_id#&nestdepth2=2&JoinOperator2=and&field2=CATALOGED_ITEM%3ACOLLECTION_CDE&searchText2=%3D#localityUses.collection_cde#">
												#numOfSpecs# #collection_cde# specimen#plural#
											</a>
										<cfelse>
											no specimens
										</cfif>
										from 
										<cfset numSole = 0>
										<cfset numShared = 0>
										<cfif len(localityUses.collection_id) GT 0>
											<cfquery name="countSole" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
												SELECT flatTableName.collecting_event_id 
												FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
													left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat1 on
														flatTableName.collecting_event_id = flat1.collecting_event_id
												WHERE flatTableName.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
														and flat1.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#localityUses.collection_id#">
												GROUP BY flatTableName.collecting_event_id
												HAVING count(distinct flatTableName.collection_cde) = 1
											</cfquery>
											<cfset numSole = countSole.recordcount>
											<cfquery name="countShared" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
												SELECT flatTableName.collecting_event_id 
												FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
													left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat1 on
														flatTableName.collecting_event_id = flat1.collecting_event_id
												WHERE flatTableName.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
														and flat1.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#localityUses.collection_id#">
												GROUP BY flatTableName.collecting_event_id
												HAVING count(distinct flatTableName.collection_cde) > 1
											</cfquery>
											<cfset numShared = countShared.recordcount>
										</cfif>
										<cfif numShared EQ 0 and numSole GT 0>
											<cfif numSole EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
											<a href="/Locality.cfm?action=findCollEvent&locality_id=#locality_id#&collnOper=eventUsedOnlyBy&collection_id=#localityUses.collection_id#&include_counts=true&include_ce_counts=true">
												#numSole# #collection_cde# only collecting event#plural#
											</a>
										<cfelseif numShared EQ 0 AND numSole EQ 0>
												#localityUses.numOfCollEvents# unused collecting events
										<cfelse>
											<cfquery name="sharedWith" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
												SELECT DISTINCT collection_cde 
												FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
													WHERE collecting_event_id in (
														SELECT flatTableName.collecting_event_id 
														FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
															left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat1
																on flatTableName.collecting_event_id = flat1.collecting_event_id
														WHERE flatTableName.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
															and flat1.collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#localityUses.collection_id#">
														GROUP BY flatTableName.collecting_event_id
														HAVING count(distinct flatTableName.collection_cde) > 1
													)
													and collection_cde <> <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#localityUses.collection_cde#">
											</cfquery>
											<cfset sharedNames = "">
											<cfset separator= "">
											<cfloop query="sharedWith">
												<cfset sharedNames = "#sharedNames##separator##sharedWith.collection_cde#">
												<cfset separator= ";">
											</cfloop>
											<cfif numSole EQ 0>
												<cfif numShared EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
												<a href="/Locality.cfm?action=findCollEvent&locality_id=#locality_id#&collnOper=eventSharedOnlyBy&collection_id=#localityUses.collection_id#&include_counts=true&include_ce_counts=true">
													#numShared# shared collecting event#plural# (#collection_cde# shared with #sharedNames#)
												</a>
											<cfelse>
												<div>
													<cfif numSole EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
													<a href="/Locality.cfm?action=findCollEvent&locality_id=#locality_id#&collnOper=eventUsedOnlyBy&collection_id=#localityUses.collection_id#&include_counts=true&include_ce_counts=true">
														#numSole# #collection_cde# only collecting event#plural#
													</a>
												</div>
												<div>
													and 
													<cfif numShared EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
													<a href="/Locality.cfm?action=findCollEvent&locality_id=#locality_id#&collnOper=eventSharedOnlyBy&collection_id=#localityUses.collection_id#&include_counts=true&include_ce_counts=true">
														#numShared# shared collecting event#plural# (#collection_cde# shared with #sharedNames#)
													</a>
												</div>
												<div>
													All 
													<cfif numShared + numSole EQ 1><cfset plural=""><cfelse><cfset plural="s"></cfif>
													<a href="/Locality.cfm?action=findCollEvent&locality_id=#locality_id#&collnOper=eventUsedBy&collection_id=#localityUses.collection_id#&include_counts=true&include_ce_counts=true">
														#numSole+numShared# #collection_cde# collecting event#plural#
													</a>.
												</div>
											</cfif>
										</cfif>
									</li>
								</cfloop>
							</ul>
						</div>
					</cfif>
				</div>
			<cfcatch>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="localityUsesThread#tn#" />

	<cfreturn cfthread["localityUsesThread#tn#"].output>
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
				<cfthrow message="Found other than one locality with specified locality_id [#encodeForHtml(locality_id)#]">
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
					<h2 class="h3">This locality record has been vetted. Please do not edit (or delete).</h3>
				</div>
				</cfif>
				<div class="col-12 col-md-10 mt-0">
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
								} else { 
									$("##details_button").addClass("disabled");
								}
							});
						});
					</script>
				</div>
				<div class="col-12 col-md-2 mt-0">
					<label class="data-entry-label" for="details_button">Higher Geography</label>
					<cfset otherClass="">
					<cfif NOT isdefined("geog_auth_rec_id") or len(geog_auth_rec_id) EQ 0>
						<cfset otherClass="disabled">
					</cfif>
					<a id="details_button" class="btn btn-xs btn-info #otherClass#" href="/localities/viewHigherGeography.cfm?geog_auth_rec_id=#geog_auth_rec_id#" target="_blank"
>Details</a>
				</div>
				<div class="col-12">
					<label class="data-entry-label" for="spec_locality">Specific Locality</label>
					<cfif NOT isdefined("spec_locality")><cfset spec_locality=""></cfif>
					<input type="text" name="spec_locality" id="spec_locality" class="data-entry-input reqdClr" value="#encodeForHTML(spec_locality)#" required>
				</div>
				<div class="col-12 col-md-4">
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
				<div class="col-12 col-md-2">
					<label class="data-entry-label" for="curated_fg">Vetted</label>
					<select name="curated_fg" id="curated_fg" size="1" class="data-entry-select reqdClr">
						<cfif not isDefined("curated_fg") OR (isdefined("curated_fg") AND curated_fg NEQ 1) ><cfset selected="selected"><cfelse><cfset selected=""></cfif>
						<option value="0" #selected#>No</option>
						<cfif isdefined("curated_fg") AND curated_fg EQ 1 ><cfset selected="selected"><cfelse><cfset selected=""></cfif>
						<option value="1" #selected#>Yes (*)</option>
					</select>
				</div>
				<div class="col-12 col-md-6">
					<cfif NOT isdefined("nogeorefbecause")><cfset nogeorefbecause=""></cfif>
					<label class="data-entry-label" for="nogeorefbecause">No Georeference Because</label>
					<input type="text" name="nogeorefbecause" id="nogeorefbecause" class="data-entry-input" value="#encodeForHTML(nogeorefbecause)#" >
				</div>
			</div>
			<div class="form-row mx-0 mb-0">
				<div class="col-12 col-md-2">
					<cfif NOT isdefined("minimum_elevation")><cfset minimum_elevation=""></cfif> 
					<label class="data-entry-label" for="minimum_elevation"><strong>Elevation</strong>: Minimum</label>
					<input type="text" name="minimum_elevation" id="minimum_elevation" class="data-entry-input" value="#encodeForHTML(minimum_elevation)#" >
				</div>
				<div class="col-12 col-md-2">
					<cfif NOT isdefined("maximum_elevation")><cfset maximum_elevation=""></cfif>
					<label class="data-entry-label" for="maximum_elevation">Maximum Elevation</label>
					<input type="text" name="maximum_elevation" id="maximum_elevation" class="data-entry-input" value="#encodeForHTML(maximum_elevation)#" >
				</div>
				<div class="col-12 col-md-2">
					<label class="data-entry-label" for="orig_elev_units">Elevation Units</label>
					<select name="orig_elev_units" id="orig_elev_units" size="1" class="data-entry-select">
						<option value=""></option>
						<cfloop query="ctElevUnit">
							<cfif isdefined("orig_elev_units") AND ctelevunit.orig_elev_units is orig_elev_units><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option #selected# value="#ctElevUnit.orig_elev_units#">#ctElevUnit.orig_elev_units#</option>
						</cfloop>
					</select>
				</div>
				<div class="col-12 col-md-2">
					<cfif NOT isdefined("min_depth")><cfset min_depth=""></cfif> 
					<label class="data-entry-label" for="min_depth"><strong>Depth</strong>: Minimum</label>
					<input type="text" name="min_depth" id="min_depth" class="data-entry-input" value="#encodeForHTML(min_depth)#" >
				</div>
				<div class="col-12 col-md-2">
					<cfif NOT isdefined("max_depth")><cfset max_depth=""></cfif>
					<label class="data-entry-label" for="max_depth">Maximum Depth</label>
					<input type="text" name="max_depth" id="max_depth" class="data-entry-input" value="#encodeForHTML(max_depth)#" >
				</div>
				<div class="col-12 col-md-2">
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
			<div class="form-row border m-1 p-1 pb-2">
				<div class="col-12 col-md-2">
					<cfif NOT isdefined("section_part")><cfset section_part=""></cfif>
					<label class="data-entry-label" for="section_part"><strong>PLSS</strong> Section Part</label>
					<input type="text" name="section_part" id="section_part" class="data-entry-input" value="#encodeForHTML(section_part)#" placeholder="NE 1/4" >
				</div>
				<div class="col-12 col-md-2">
					<cfif NOT isdefined("section")><cfset section=""></cfif>
					<label class="data-entry-label" for="section">Section</label>
					<input type="text" name="section" id="section" class="data-entry-input" value="#encodeForHTML(section)#" pattern="[0-3]{0,1}[0-9]{0,1}" >
				</div>
				<div class="col-12 col-md-2">
					<cfif NOT isdefined("township")><cfset township=""></cfif>
					<label class="data-entry-label" for="township">Township</label>
					<input type="text" name="township" id="township" class="data-entry-input" value="#encodeForHTML(township)#" pattern="[0-9]+" >
				</div>
				<div class="col-12 col-md-2">
					<cfif NOT isdefined("township_direction")><cfset township_direction=""></cfif>
					<label class="data-entry-label" for="township_direction">Township Direction</label>
					<input type="text" name="township_direction" id="township_direction" class="data-entry-input" value="#encodeForHTML(township_direction)#" >
				</div>
				<div class="col-12 col-md-2">
					<cfif NOT isdefined("range")><cfset range=""></cfif>
					<label class="data-entry-label" for="range">Range</label>
					<input type="text" name="range" id="range" class="data-entry-input" value="#encodeForHTML(range)#" pattern="[0-9]+">
				</div>
				<div class="col-12 col-md-2">
					<cfif NOT isdefined("range_direction")><cfset range_direction=""></cfif>
					<label class="data-entry-label" for="range_direction">Range Direction</label>
					<input type="text" name="range_direction" id="range_direction" class="data-entry-input" value="#encodeForHTML(range_direction)#" >
				</div>
			</div>
			<div class="form-row mx-0 mb-1">
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
					<div class="col-12 col-md-3">
						<input type="hidden" name="locality_id" value="locality_id" />
						<label class="data-entry-label" for="">Include accepted georeference from <a href="/editLocality.cfm?locality_id=#clone_from_locality_id#" target="_blank">#clone_from_locality_id#</a>?</label>
						Y<input type="radio" name="cloneCoords" value="yes" />
						<br>
						N<input type="radio" name="cloneCoords" value="no" checked="checked" />
					</div>
		 		</cfif>
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
	<cfthread action="join" name="editLocalityFormThread#tn#" />

	<cfreturn cfthread["editLocalityFormThread#tn#"].output>
</cffunction>

<cffunction name="getLocalityGeologyHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="callbackName" type="string" required="yes">

	<cfset variables.callbackName = arguments.callbackName>
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
						geology_attributes.geo_att_determined_date determined_date,
						geology_attributes.geo_att_determined_method determined_method,
						geology_attributes.geo_att_remark,
						geology_attributes.previous_values,
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
					<div>
						<ul>
							<li>
								Recent (no geological attributes) 
								<button type="button" class="btn btn-xs btn-secondary" onClick=" openAddGeologyDialog('#locality_id#','addGeologyDialog','#callbackName#'); ">Add</button>
							</li>
						</ul>
					</div>
				<cfelse>
					<div>
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
									#geology_attribute#:#geo_att_value# #determined_by# #determined_date# #determined_method#
									<button type="button" class="btn btn-xs btn-secondary" onClick=" openEditGeologyDialog('#geology_attribute_id#','editGeologyDialog','#callbackName#');">Edit</button>
									<button type="button" 
										class="btn btn-xs btn-warning" 
										onClick=" confirmDialog('Remove #geology_attribute#:#geo_att_value# from this locality ?', 'Confirm Remove Geological Attribute', function() { removeGeologyAttribute('#geology_attribute_id#','#locality_id#','#callbackName#'); } ">Remove</button>
								</li>
							</cfloop>
							<li>
								<button type="button" class="btn btn-xs btn-secondary" onClick=" openAddGeologyDialog('#locality_id#','addGeologyDialog','#callbackName#'); ">Add</button>
							</li>
						</ul>
					</div>
				</cfif>
				<div id="editGeologyDialog"></div>
				<div id="addGeologyDialog"></div>
				<script>
					function openEditGeologyDialog(geology_attribute_id, dialogDiv,callback) { 
						console.log(geology_attribute_id);
					}
				</script>
			<cfcatch>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
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
			<cfif getRereferences.recordcount NEQ "1">
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

<!--- returns html to populate a dialog to add geological attributes to a locality 
	@param locality_id the id of the locality for which to add geological attributes
	@return html to populate a dialog, including save buttons.
--->
<cffunction name="geologyAttributeDialogHtml" access="remote" returntype="string">
	<cfargument name="locality_id" type="string" required="yes">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getGeorefThread#tn#">
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
					<input type="hidden" name="method" value="saveGeologyAttribute">
				<h2 class="h3">Add a geological attribute for locality #encodeForHtml(getLabel.locality_label)#</h2>
				<div class="form-row">
					<div class="col-12 col-md-3">
						<label for="attribute_type" class="data-entry-label">Type</label>
						<select id="attribute_type" name="attribute_type" class="data-entry-select reqdClr" onChange=" changeGeoAttType(); ">
							<cfset selected="selected">
							<cfloop query="types">
								<option value="#types.type#" #selected#>#types.type#</option>
								<cfset selected="">
							</cfloop>
						</select>
					</div>
					<div class="col-12 col-md-3">
						<label for="geo_att_value" class="data-entry-label">Attribute Value</label>
						<input type="text" id="geo_att_value" name="geo_att_value" class="data-entry-input">
						<input type="hidden" id="geo_attribute" name="geo_attribute">
						<input type="hidden" id="geology_attribute_hierarchy_id" name="geology_attribute_hierarchy_id">
					</div>
					<div class="col-12 col-md-2">
						<label for="add_parents" class="data-entry-label">Add Parents</label>
						<select id="add_parents" name="add_parents" class="data-entry-select" onChange=" addParentsChange(); ">
							<option value="no" selected>No</option>
							<option value="yes">Yes</option>
						</select>
					</div>
					<div class="col-12 col-md-2" id="parentsDiv">
						<!--- Area to show parents of selected attribute value --->
					</div>
					<div class="col-12 col-md-4">
						<label for="determiner" class="data-entry-label">Determiner</label>
						<input type="text" id="determiner" name="determiner" class="data-entry-input">
						<input type="hidden" id="geo_att_determiner_id" name="geo_att_determiner_id">
					</div>
					<div class="col-12 col-md-4">
						<label for="geo_att_determined_date" class="data-entry-label">Date Determined</label>
						<input type="text" name="geo_att_determined_date" id="geo_att_determined_date"
							value="#dateformat(now(),"yyyy-mm-dd")#" class="data-entry-input">
					</div>
					<div class="col-12 col-md-4">
						<label for="geo_att_determined_method" class="data-entry-label">Determination Method</label>
						<input type="text" id="geo_att_determined_method" name="geo_att_determined_method" class="data-entry-input">
					</div>
					<div class="col-12 col-md-12">
						<label for="geo_att_remark" class="data-entry-label">Remarks</label>
						<textarea name="geo_att_remark" id="geo_att_remark" 
							onkeyup="countCharsLeft('geo_att_remarks', 4000, 'length_locality_remarks');"
							class="form-control form-control-sm w-100 autogrow mb-1" rows="2"></textarea>
						<script>
							// Bind textarea to autogrow function on key up
							$(document).ready(function() { 
								$("##geo_att_remark").keyup(autogrow);  
							});
						</script>
					</div>
					<div class="col-12 col-md-3">
						<label class="data-entry-label">&nbsp;</label>
						<button type="button" class="btn btn-xs btn-primary" onClick=" saveGeoAtt(); " >Add</button>
					</div>
					<div class="col-12 col-md-3">
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
								$('##geoAttFeedback').html('Saved.');
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
						$('##geo_attribute').val("");
						$('##geo_att_value').val("");
						makeGeologyAutocompleteMeta('geo_attribute', 'geo_att_value','entry',$('##attribute_type').val());
					} 
					$(document).ready(function(){ 
						makeGeologyAutocompleteMeta('geo_attribute', 'geo_att_value','geology_attribute_hierarchy_id','entry',$('##attribute_type').val());
						makeAgentAutocompleteMeta('determiner', 'geo_att_determiner_id');
						$("##geo_att_determined_date").datepicker({ dateFormat: 'yy-mm-dd'});
					});
				</script>
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
					curated_fg, locality_remarks
				FROM locality
				WHERE 
					locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
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
				<cfset section_part = "#lookupLocality.section_part#">
				<cfset section = "#lookupLocality.section#">
				<cfset township = "#lookupLocality.township#">
				<cfset township_direction = "#lookupLocality.township_direction#">
				<cfset range = "#lookupLocality.range#">
				<cfset range_direction = "#lookupLocality.range_direction#">
				<cfset depth_units = "#lookupLocality.depth_units#">
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
		<cfoutput>
			<div class="form-row mx-0 mb-0">
				<div class="col-12 col-md-10 mt-0">
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
								} else { 
									$("##details_button").addClass("disabled");
								}
							});
						});
					</script>
				</div>
				<div class="col-12 col-md-2 mt-0">
					<label class="data-entry-label" for="details_button">Higher Geography</label>
					<cfset otherClass="">
					<cfif isdefined("geog_auth_rec_id") and len(geog_auth_rec_id) GT 0>
						<cfset otherClass="disabled">
					</cfif>
					<input type="button" value="Details" id="details_button" class="btn btn-xs btn-info #otherClass#"
						onclick="document.location='Locality.cfm?Action=editGeog&geog_auth_rec_id=#geog_auth_rec_id#'">
				</div>
				<div class="col-12">
					<label class="data-entry-label" for="spec_locality">Specific Locality</label>
					<cfif NOT isdefined("spec_locality")><cfset spec_locality=""></cfif>
					<input type="text" name="spec_locality" id="spec_locality" class="data-entry-input reqdClr" value="#encodeForHTML(spec_locality)#" required>
				</div>
				<div class="col-12 col-md-4">
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
				<div class="col-12 col-md-2">
					<label class="data-entry-label" for="curated_fg">Vetted</label>
					<select name="curated_fg" id="curated_fg" size="1" class="data-entry-select reqdClr">
						<cfif not isDefined("curated_fg") OR (isdefined("curated_fg") AND curated_fg NEQ 1) ><cfset selected="selected"><cfelse><cfset selected=""></cfif>
						<option value="0" #selected#>No</option>
						<cfif isdefined("curated_fg") AND curated_fg EQ 1 ><cfset selected="selected"><cfelse><cfset selected=""></cfif>
						<option value="1" #selected#>Yes (*)</option>
					</select>
				</div>
			</div>
			<div class="form-row mx-0 mb-0">
				<div class="col-12 col-md-2">
					<cfif NOT isdefined("minimum_elevation")><cfset minimum_elevation=""></cfif> 
					<label class="data-entry-label" for="minimum_elevation"><strong>Elevation</strong>: Minimum</label>
					<input type="text" name="minimum_elevation" id="minimum_elevation" class="data-entry-input" value="#encodeForHTML(minimum_elevation)#" >
				</div>
				<div class="col-12 col-md-2">
					<cfif NOT isdefined("maximum_elevation")><cfset maximum_elevation=""></cfif>
					<label class="data-entry-label" for="maximum_elevation">Maximum Elevation</label>
					<input type="text" name="maximum_elevation" id="maximum_elevation" class="data-entry-input" value="#encodeForHTML(maximum_elevation)#" >
				</div>
				<div class="col-12 col-md-2">
					<label class="data-entry-label" for="orig_elev_units">Elevation Units</label>
					<select name="orig_elev_units" id="orig_elev_units" size="1" class="data-entry-select">
						<option value=""></option>
						<cfloop query="ctElevUnit">
							<cfif isdefined("orig_elev_units") AND ctelevunit.orig_elev_units is orig_elev_units><cfset selected="selected"><cfelse><cfset selected=""></cfif>
							<option #selected# value="#ctElevUnit.orig_elev_units#">#ctElevUnit.orig_elev_units#</option>
						</cfloop>
					</select>
				</div>
				<div class="col-12 col-md-2">
					<cfif NOT isdefined("min_depth")><cfset min_depth=""></cfif> 
					<label class="data-entry-label" for="min_depth"><strong>Depth</strong>: Minimum</label>
					<input type="text" name="min_depth" id="min_depth" class="data-entry-input" value="#encodeForHTML(min_depth)#" >
				</div>
				<div class="col-12 col-md-2">
					<cfif NOT isdefined("max_depth")><cfset max_depth=""></cfif>
					<label class="data-entry-label" for="max_depth">Maximum Depth</label>
					<input type="text" name="max_depth" id="max_depth" class="data-entry-input" value="#encodeForHTML(max_depth)#" >
				</div>
				<div class="col-12 col-md-2">
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
			<div class="form-row border m-1 p-1 pb-2">
				<div class="col-12 col-md-2">
					<cfif NOT isdefined("section_part")><cfset section_part=""></cfif>
					<label class="data-entry-label" for="section_part"><strong>PLSS</strong> Section Part</label>
					<input type="text" name="section_part" id="section_part" class="data-entry-input" value="#encodeForHTML(section_part)#" placeholder="NW 1/4" >
				</div>
				<div class="col-12 col-md-2">
					<cfif NOT isdefined("section")><cfset section=""></cfif>
					<label class="data-entry-label" for="section">Section</label>
					<input type="text" name="section" id="section" class="data-entry-input" value="#encodeForHTML(section)#" pattern="[0-3]{0,1}[0-9]{0,1}" >
				</div>
				<div class="col-12 col-md-2">
					<cfif NOT isdefined("township")><cfset township=""></cfif>
					<label class="data-entry-label" for="township">Township</label>
					<input type="text" name="township" id="township" class="data-entry-input" value="#encodeForHTML(township)#" pattern="[0-9]+" >
				</div>
				<div class="col-12 col-md-2">
					<cfif NOT isdefined("township_direction")><cfset township_direction=""></cfif>
					<label class="data-entry-label" for="township_direction">Township Direction</label>
					<input type="text" name="township_direction" id="township_direction" class="data-entry-input" value="#encodeForHTML(township_direction)#" >
				</div>
				<div class="col-12 col-md-2">
					<cfif NOT isdefined("range")><cfset range=""></cfif>
					<label class="data-entry-label" for="range">Range</label>
					<input type="text" name="range" id="range" class="data-entry-input" value="#encodeForHTML(range)#" pattern="[0-9]+">
				</div>
				<div class="col-12 col-md-2">
					<cfif NOT isdefined("range_direction")><cfset range_direction=""></cfif>
					<label class="data-entry-label" for="range_direction">Range Direction</label>
					<input type="text" name="range_direction" id="range_direction" class="data-entry-input" value="#encodeForHTML(range_direction)#" >
				</div>
			</div>
			<div class="form-row mx-0 mb-1">
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
					<div class="col-12 col-md-3">
						<input type="hidden" name="locality_id" value="locality_id" />
						<label class="data-entry-label" for="">Include accepted georeference from <a href="/editLocality.cfm?locality_id=#clone_from_locality_id#" target="_blank">#clone_from_locality_id#</a>?</label>
						Y<input type="radio" name="cloneCoords" value="yes" />
						<br>
						N<input type="radio" name="cloneCoords" value="no" checked="checked" />
					</div>
		 		</cfif>
				<div class="col-12 mt-1">
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
			<cfif getRereferences.recordcount NEQ "1">
				<cfthrow message="Unable to delete. Found other than one georefrence for lat_long_id and locality_id provided.">
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
	<cfargument name="callbackName" type="string" required="yes">

	<cfset variables.callbackName = arguments.callbackName>
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="localityGeoRefFormThread#tn#">
		<cfoutput>
			<cftry>
				<cfquery name="getLocalityMetadata" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT 
						spec_locality, locality_id, 
						decode(curated_fg,1,' *','') curated
					FROM locality
					WHERE
						locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
				</cfquery>
				<cfif getLocalityMetadata.recordcount NEQ 1>
					<cfthrow message="Other than one locality found for the specified locality_id [#encodeForHtml(locality_id)#]">
				</cfif>
				<cfset localityLabel = "#getLocalityMetadata.spec_locality##getLocalityMetadata.curated#">
				<cfquery name="getGeoreferences" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT
						lat_long_id,
						georefmethod,
						dec_lat,
						dec_long,
						max_error_distance,
						max_error_units,
						to_meters(lat_long.max_error_distance, lat_long.max_error_units) coordinateUncertaintyInMeters,
						error_polygon,
						datum,
						extent,
						spatialfit,
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
							WHEN 'decimal degrees' THEN dec_lat || 'd'
							WHEN 'deg. min. sec.' THEN lat_deg || 'd ' || lat_min || 'm ' || lat_sec || 's ' || lat_dir
							WHEN 'degrees dec. minutes' THEN lat_deg || 'd ' || dec_lat_min || 'm ' || lat_dir
						END as LatitudeString,
						CASE orig_lat_long_units
							WHEN 'decimal degrees' THEN dec_long || 'd'
							WHEN'degrees dec. minutes' THEN long_deg || 'd ' || dec_long_min || 'm ' || long_dir
							WHEN 'deg. min. sec.' THEN long_deg || 'd ' || long_min || 'm ' || long_sec || 's ' || long_dir
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
				<h2 class="h3">Georeferences (#getGeoreferences.recordcount#)</h2>
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
						<cfset noGeoRef = "<span class='text-warning'>Add a georeference or put a value in Not Georeferenced Because.</span>"><!--- " --->
					<cfelse> 
						<cfset noGeoRef = " (#checkNoGeorefBecause.nogeorefbecause#)">
					</cfif>
					<div>
						<ul>
							<li>None #noGeoRef#</li>
							<li>
								<button type="button" class="btn btn-xs btn-secondary" 
									onClick=" openAddGeoreferenceDialog('addGeorefDialog', '#locality_id#', '#localityLabel#', '#callbackName#') " 
									aria-label = "Add a georeference to this locality"
								>Add</button>
							</li>
						</ul>
					</div>
				<cfelse>
					<div>
						<ul>
							<cfloop query="getGeoreferences">
								<li>
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
									<cfset spanClass="">
									<cfif accepted_lat_long EQ "Accepted">
										<cfset spanClass="font-weight-bold">
									</cfif>
									<span class="#spanClass#">#dec_lat#, #dec_long# #datum# ±#coordinateUncertaintyInMeters#m</span>
									<ul>
										<li>
											#original# <span class="#spanClass#">#accepted_lat_long#</span>
										</li>
										<li>
											Method: #georefmethod# #det# Verification: #verificationstatus# #ver#
										</li>
										<cfif len(geolocate_score) GT 0>
											<li>
												GeoLocate: score=#geolocate_score# precision=#geolocate_precision# results=#geolocate_numresults# pattern=#geolocate_parsepattern#
											</li>
										</cfif>
										<li>
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
											<button type="button" id="toggleButton#lat_long_id#" class="btn btn-xs btn-info" onClick=" toggleBounce#lat_long_id#(); ">Highlight on map</button>
											<button type="button" class="btn btn-xs btn-secondary" 
												onClick=" openEditGeorefDialog('#lat_long_id#','editGeorefDialog','#callbackName#');"
												aria-label = "Edit this georeference"
											>Edit</button>
											<button type="button" class="btn btn-xs btn-warning" 
												onClick=" deleteGeoreference('#locality_id#','#lat_long_id#','#callbackName#');"
												aria-label = "Delete this georeference from this locality"
											>Delete</button>
										</li>
									</ul>
								</li>
							</cfloop>
							<li>
								<button type="button" class="btn btn-xs btn-secondary" 
									onClick=" openAddGeoreferenceDialog('addGeorefDialog', '#locality_id#', '#localityLabel#', '#callbackName#') " 
									aria-label = "Add another georeference to this locality"
								>Add</button>
							</li>
						</ul>
					</div>
				</cfif>
				<div id="editGeorefDialog"></div>
				<div id="addGeorefDialog"></div>
				<script>
					function openEditGeorefDialog(lat_long_id, dialogDiv, callback) { 
						console.log(geology_attribute_id);
					}
					function deleteGeoreference(locality_id,lat_long_id, callback) { 
						console.log(geology_attribute_id);
					}
				</script>
			<cfcatch>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
				<cfif isDefined("cfcatch.cause.tagcontext")>
					<div>Line #cfcatch.cause.tagcontext[1].line# of #replace(cfcatch.cause.tagcontext[1].template,Application.webdirectory,'')#</div>
				</cfif>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="localityGeorefFormThread#tn#" />

	<cfreturn cfthread["localityGeorefFormThread#tn#"].output>
</cffunction>

<cffunction name="georeferenceDialogHtml" access="remote" returntype="string">
	<cfargument name="locality_id" type="string" required="yes">
	<cfargument name="locality_label" type="string" required="yes">

	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="getGeorefThread#tn#">
		<cftry>
			<cfquery name="ctunits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT ORIG_LAT_LONG_UNITS 
				FROM ctlat_long_units
				ORDER BY ORIG_LAT_LONG_UNITS
			</cfquery>
			<cfoutput>
				<h2 class="h3">Add a georeference for locality #encodeForHtml(locality_label)#</h2>
				<div>
					<div class="tabs card-header tab-card-header px-2 pt-3">
						<!-- Nav tabs -->
						<div class="tab-headers tabList px-0 px-md-3" role="tablist" aria-label="create georeference by">
							<button class="col-12 px-1 col-sm-2 px-sm-2 col-xl-auto px-xl-5 my-1 my-md-0 active" id="manualTabButton" tabid="1" role="tab" aria-controls="manualPanel" aria-selected="true" tabindex="0" aria-label="Enter original coordinates">You have original coordinates: Enter manually</button>
							<button class="col-12 px-1 col-sm-2 px-sm-2 col-xl-auto px-xl-5 my-1 text-truncate my-md-0 " id="geolocateTabButton" tabid="2" role="tab" aria-controls="geolocatePanel" aria-selected="false" tabindex="-1" aria-label="Use geolocate to georeference specific locality">Use Geolocate with Specific Locality</button>
						</div>
						<!-- Tab panes -->
						<script>
							$(document).ready(loadTabs);
						</script>
						<div class="tab-content flex-wrap d-flex">
							<div id="manualPanel" role="tabpanel" aria-labelledby="manualTabButton" tabindex="0" class="col-12 px-0 mx-0 active unfocus">
								<h2 class="px-2 h3">Enter georeference</h2>
								<div class="form-row">
									<div class="col-12 col-md-3">
										<label for="orig_lat_long_units" class="data-entry-label">Original Units</label>
										<select id="orig_lat_long_units" class="data-entry-select reqdClr" onChange=" changeLatLongUnits(); ">
											<option></option>
											<option value="decimal degrees">decimal degrees</option>
											<option value="degrees dec. minutes">degrees with decimal minutes</option>
											<option value="deg. min. sec.">degrees, minutes and seconds</option>
											<option value="UTM">Universal Transverse Mercator (UTM)</option>
										</select>
										<script>
											function changeLatLongUnits(){ 
												$(".latlong").prop('disabled', true);
												$(".latlong").prop('required', false);
												$(".latlong").removeClass('reqdClr');
												$(".utm").removeClass('reqdClr');
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
													$("##long_deg").prop('disabled', false);
													$("##long_deg").prop('required', true);
													$("##long_deg").addClass('reqdClr');
												} else if (units == 'degrees dec. minutes') {
													$("##lat_deg").prop('disabled', false);
													$("##lat_deg").prop('required', true);
													$("##lat_deg").addClass('reqdClr');
													$("##lat_min").prop('disabled', false);
													$("##lat_min").prop('required', true);
													$("##lat_min").addClass('reqdClr');
													$("##lat_ns").prop('disabled', false);
													$("##lat_ns").prop('required', true);
													$("##lat_ns").addClass('reqdClr');
													$("##long_deg").prop('disabled', false);
													$("##long_deg").prop('required', true);
													$("##long_deg").addClass('reqdClr');
													$("##long_min").prop('disabled', false);
													$("##long_mit").prop('required', true);
													$("##long_min").addClass('reqdClr');
													$("##long_ew").prop('disabled', false);
													$("##long_ew").prop('required', true);
													$("##long_ew").addClass('reqdClr');
												} else if (units == 'deg. min. sec.') {
													$(".latlong").prop('disabled', false);
													$(".latlong").addClass('reqdClr');
													$(".latlong").prop('required', true);
												} else if (units == 'UTM') {
													$(".utm").prop('disabled', false);
													$(".utm").prop('required', true);
													$(".utm").addClass('reqdClr');
												}
											} 
											$(document).ready(changeLatLongUnits);
										</script>
									</div>
									<div class="col-12 col-md-3">
										<label for="accepted" class="data-entry-label">Accepted</label>
										<select name="accepted_lat_long_fg" size="1" id="accepted_lat_long_fg" class="data-entry-select reqdClr">
											<option value="Yes" selected>Yes</option>
											<option value="No">No</option>
										</select>
									</div>
									<div class="col-12 col-md-3">
										<label for="determined_by_agent" class="data-entry-label">Determiner</label>
										<input type="hidden" name="determined_by_agent_id" id="determined_by_agent_id">
										<input type="text" name="determined_by_agent" id="determined_by_agent" class="data-entry-input reqdClr">
										<script>
											$(document).ready(function() { 
												makeAgentAutocompleteMeta("determined_by_agent", "determined_by_agent_id");
											});
										</script>
									</div>
									<div class="col-12 col-md-3">
										<label for="determined_date" class="data-entry-label">Date Determined</label>
										<input type="text" name="determined_date" id="determined_date" class="data-entry-input reqdClr" placeholder="yyyy-mm-dd">
										<script>
											$(document).ready(function() {
												$("##determined_date").datepicker({ dateFormat: 'yy-mm-dd'});
											});
										</script>
									</div>
									<div class="col-12 col-md-3">
										<label for="lat_deg" class="data-entry-label">Latitude Degrees</label>
										<input type="text" name="lat_deg" id="lat_deg" class="data-entry-input latlong">
									</div>
									<div class="col-12 col-md-3">
										<label for="lat_min" class="data-entry-label">Minutes</label>
										<input type="text" name="lat_min" id="lat_min" class="data-entry-input latlong">
									</div>
									<div class="col-12 col-md-3">
										<label for="lat_sec" class="data-entry-label">Seconds</label>
										<input type="text" name="lat_sec" id="lat_sec" class="data-entry-input latlong">
									</div>
									<div class="col-12 col-md-3">
										<label for="lat_ns" class="data-entry-label">Direction</label>
										<select name="lat_ns" size="1" id="lat_ns" class="data-entry-select latlong">
											<option value=""></option>
											<option value="N">N</option>
											<option value="S">S</option>
										</select>
									</div>
									<div class="col-12 col-md-3">
										<label for="long_deg" class="data-entry-label">Longitude Degrees</label>
										<input type="text" name="long_deg" size="4" id="long_deg" class="data-entry-input latlong">
									</div>
									<div class="col-12 col-md-3">
										<label for="long_min" class="data-entry-label">Minutes</label>
										<input type="text" name="long_min" size="4" id="long_min" class="data-entry-input latlong">
									</div>
									<div class="col-12 col-md-3">
										<label for="long_sec" class="data-entry-label">Seconds</label>
										<input type="text" name="long_sec" size="4" id="long_sec" class="data-entry-input latlong">
									</div>
									<div class="col-12 col-md-3">
										<label for="long_ew" class="data-entry-label">Direction</label>
										<select name="long_ew" size="1" id="long_ew" class="data-entry-select latlong">
											<option value=""></option>
											<option value="E">E</option>
											<option value="W">W</option>
										</select>
									</div>
									<div class="col-12 col-md-4">
										<label for="utm_zone" class="data-entry-label">UTM Zone/Letter</label>
										<input type="text" name="utm_zone" size="4" id="utm_zone" class="data-entry-input utm">
									</div>
									<div class="col-12 col-md-4">
										<label for="utm_ew" class="data-entry-label">Easting</label>
										<input type="text" name="utm_ew" size="4" id="utm_ew" class="data-entry-input utm">
									</div>
									<div class="col-12 col-md-4">
										<label for="utm_ns" class="data-entry-label">Northing</label>
										<input type="text" name="utm_ns" size="4" id="utm_ns" class="data-entry-input utm">
									</div>
								</div>
							</div>
							<div id="geolocatePanel" role="tabpanel" aria-labelledby="geolocateTabButton" tabindex="-1" class="col-12 px-0 mx-0 unfocus" hidden>
								<h2 class="px-2 h3">Use Geolocate</h2>
							</div>
						</div>
					</div>
				</div>
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

<!--- function getLocalityVerbatimHtml return a block of html with verbatim data from
 collecting events associated with a locality. 

   @param locality_id the primary key value for the locality for which to return 
     verbatim data.
   @return block of html.
--->
<cffunction name="getLocalityVerbatimHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="locality_id" type="string" required="yes">
	
	<cfset tn = REReplace(CreateUUID(), "[-]", "", "all") >
	<cfthread name="localityVerbatimThread#tn#">
		<cfoutput>
			<cftry>
				<cfquery name="getVerbatim" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getVerbatim_result">
					SELECT 
						count(*) ct,
						verbatim_locality
					FROM collecting_event
					WHERE
						locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
						and verbatim_locality is not null
					GROUP BY 
						verbatim_locality
				</cfquery>
				<cfif getVerbatim.recordcount EQ 0>
					<div class="h4">No verbatim locality values</div>
				<cfelse>
					<ul>
						<cfloop query="getVerbatim">
							<cfif ct GT 1><cfset counts=" (in #ct# collecting events)"><cfelse><cfset counts=""></cfif>
							<li>#verbatim_locality##counts#</li>
						</cfloop>
					</ul>
				</cfif>
				<cfquery name="getVerbatimGeoref" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getVerbatimGeoref_result">
					SELECT 
						count(*) ct,
						verbatimcoordinates,
						verbatimlatitude, verbatimlongitude,
						verbatimcoordinatesystem, verbatimsrs
					FROM collecting_event
					WHERE
						locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
						and (verbatimcoordinates is not null or verbatimlatitude is not null)
					GROUP BY 
						verbatimcoordinates,
						verbatimlatitude, verbatimlongitude,
						verbatimcoordinatesystem, verbatimsrs
				</cfquery>
				<cfif getVerbatimGeoref.recordcount EQ 0>
					<div class="h4">No verbatim coordinates</div>
				<cfelse>
					<div class="h4">Verbatim coordinate values</div>
					<ul>
						<cfloop query="getVerbatimGeoref">
							<cfif ct GT 1><cfset counts=" (in #ct# collecting events)"><cfelse><cfset counts=""></cfif>
							<li>#verbatimcoordinatesystem# #verbatimcoordinates# #verbatimlatitude# #verbatimlongitude# #verbatimsrs# #counts#</li>
						</cfloop>
					</ul>
				</cfif>
			<cfcatch>
				<h2>Error: #cfcatch.type# #cfcatch.message#</h2> 
				<div>#cfcatch.detail#</div>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="localityVerbatimThread#tn#" />

	<cfreturn cfthread["localityVerbatimThread#tn#"].output>
</cffunction>


</cfcomponent>
