<!---
localities/Locality.cfm

Create and edit locality records.

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2023 President and Fellows of Harvard College

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

<cfif not isdefined("action")>
	<cfif not isdefined("locality_id")>
		<cfset action="new">
	<cfelse>
		<cfset action="edit">
	</cfif>
</cfif>
<cfswitch expression="#action#">
	<cfcase value="edit">
		<cfset pageTitle="Edit Locality">
	</cfcase>
	<cfcase value="new">
		<cfset pageTitle="New Locality">
	</cfcase>
	<cfcase value="makenewLocality">
		<cfset pageTitle="Creating New Locality">
	</cfcase>
	<cfcase value="delete">
		<cfset pageTitle="Deleting Locality">
	</cfcase>
	<cfdefaultcase>
		<cfthrow message="Error: Unknown Action">
	</cfdefaultcase>
</cfswitch>
<cfset pageHasTabs="true">
<cfinclude template = "/shared/_header.cfm">
<cfif findNoCase('master',Session.gitBranch) NEQ 0>
	<!--- not ready for production use, prevent access from production, redirect to locality search --->
	<cflocation url="/localities/Localities.cfm" addtoken="false">
</cfif>

<cfswitch expression="#action#">
	<cfcase value="edit">
		<cfinclude template="/localities/component/functions.cfc" runOnce="true">
		<cfinclude template="/localities/component/public.cfc" runOnce="true"><!--- for getLocalityMap() --->
		<cfinclude template="/localities/component/search.cfc" runOnce="true"><!--- for getLocalitySummary() --->
		<cfquery name="countUses" datasource="uam_god">
			SELECT 
				sum(ct) total_uses
			FROM (
				SELECT
					count(*) ct
				FROM 
					collecting_event
				WHERE
					locality_id=  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
				UNION
				SELECT
					count(*) ct
				FROM
					media_relations
				WHERE
					related_primary_key =  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
					AND
					media_relationship like '%locality'
				UNION
				SELECT
					count(*) ct
				FROM 
					lat_long	
				WHERE
					locality_id=  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
			)
		</cfquery>
		<cfif not isDefined("locality_id") OR len(locality_id) EQ 0>
			<cfthrow message="Error: unable to edit locality, no locality_id specified.">
		</cfif>
		<cfoutput>
			<main class="container-fluid my-2" id="content">
				<div class="row mx-0">
				<section class="col-12 col-md-9 px-xl-0">
					<div class="col-12 px-0 px-md-3">
						<h1 class="h2 mt-3 mb-0 px-3">Edit Locality [#encodeForHtml(locality_id)#]</h1>
						<div class="border-top border-right border-left border-bottom border-success rounded px-2 my-3 py-3">
							<cfset blockRelated = getLocalityUsesHtml(locality_id = "#locality_id#")>
							<div id="relatedTo">#blockRelated#</div>
							<h2 class="h4 mt-3 mb-0 px-2">Locality Summary</h2>
							<cfset summary = getLocalitySummary(locality_id="#locality_id#")>
							<div id="summary" class="small95 px-2 pb-2">#summary#</div>
						</div>
						
						<div class="border rounded px-2 my-2 py-3" arial-labeledby="formheading">
							<cfset formId = "editLocalityForm">
							<cfset outputDiv="saveResultsDiv">
							<form name="editLocality" id="#formId#">
								<input type="hidden" id="locality_id" name="locality_id" value="#locality_id#">
								<input type="hidden" name="method" value="updateLocality">
								<cfset blockEditForm = getEditLocalityHtml(locality_id = "#locality_id#", formId="#formId#", outputDiv="#outputDiv#", saveButtonFunction="saveEdits")>
								#blockEditForm#
							</form>
							<script>
								function reloadLocalityBlocks() { 
									updateLocalitySummary('#locality_id#','summary');	
									reloadGeology();
									reloadGeoreferences();
								}
								function reloadGeology()  {
									loadGeologyHTML('#locality_id#','geologyDiv', 'reloadGeology');
								}
								function reloadMap()  {
									loadLocalityMapHTML('#locality_id#','mapDiv');
								}
								function reloadGeoreferences() {
									loadGeoreferencesHTML('#locality_id#','georeferencesDiv', 'reloadGeoreferences');
									reloadMap();
								}
								function saveEdits(){ 
									saveEditsFromFormCallback("#formId#","/localities/component/functions.cfc","#outputDiv#","saving locality record",reloadLocalityBlocks);
								};
							</script>
							<button type="button" class="btn btn-xs btn-secondary" style="position:absolute;left: 6rem; margin-top: -1.9rem;" onClick=" location.assign('/localities/Locality.cfm?action=new&clone_from_locality_id=#encodeForUrl(locality_id)#');" >Clone Locality</button>
							<cfif countUses.total_uses EQ "0">
								<button type="button" 
									onClick="confirmDialog('Delete this Locality?', 'Confirm Delete Locality', function() { location.assign('/localities/Locality.cfm?action=delete&locality_id=#encodeForUrl(locality_id)#'); } );" 
									class="btn btn-xs btn-danger" >
										Delete Locality
								</button>
							</cfif>
						</div>
<!---						<div class="border rounded px-3 my-2 py-3">
		
						</div>--->
					</div>	
					<div class="row mx-0">
						<div class="col-12 col-md-6">
							<div class="border rounded px-3 my-2 py-3">
								<cfset geology = getLocalityGeologyHtml(locality_id="#locality_id#",callback_name='reloadGeology')>
								<div id="geologyDiv">#geology#</div>
							</div>
						</div>
						<div class="col-12 col-md-6">
							<div class="border rounded px-3 my-2 py-3">
								<cfset georeferences = getLocalityGeoreferencesHtml(locality_id="#locality_id#",callback_name='reloadGeoreferences')>
								<div id="georeferencesDiv">#georeferences#</div>
							</div>
						</div>
					</div>
					<div class="col-12">
						<div class="border bg-light rounded p-3 my-2">
							<script type='text/javascript' language="javascript" src='/dataquality/js/bdq_quality_control.js'></script>
							<script>
								function runTests() {
									$("##SpaceDQDiv").html("Running tests....");
									loadSpaceQC("", #locality_id#, "SpaceDQDiv");
								}
							</script>
							<input type="button" value="Run Quality Control Tests" class="btn btn-xs btn-secondary" onClick=" runTests(); ">
							<!---  Space tests --->
							<div id="SpaceDQDiv"></div>
						</div>
					</div>
				</section>
				<section class="mt-4 col-12 col-md-3 px-0 pl-xl-0">
						<!--- map --->
						<div class="col-12 px-0">
							<cfset map = getLocalityMapHtml(locality_id="#locality_id#")>
							<div id="mapDiv">#map#</div>
						</div>
						<!--- verbatim values --->
						<div class="col-12 px-0">
							<h2 class="h4">Verbatim localities (from associated collecting events)</h2>
							<cfset verbatim = getLocalityVerbatimHtml(locality_id="#locality_id#")>
							<div id="verbatimDiv">#verbatim#</div>
						</div>
				</section>
				</div>
			</main>
		</cfoutput>
	</cfcase>
	<cfcase value="new">
		<cfinclude template="/localities/component/functions.cfc" runOnce="true">
		<cfoutput>
			<cfset extra = "">
			<cfif isDefined("geog_auth_rec_id") AND len(geog_auth_rec_id) GT 0 AND NOT (isDefined("clone_from_locality_id") and len(clone_from_locality_id) GT 0)>
					<cfquery name="lookupHigherGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT higher_geog
						FROM geog_auth_rec
						WHERE 
							geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
					</cfquery>
					<cfloop query="lookupHigherGeog">
						<cfset extra = " within #lookupHigherGeog.higher_geog#">
					</cfloop>
					<cfset blockform = getCreateLocalityHtml(geog_auth_rec_id = "#geog_auth_rec_id#")>
			<cfelseif isDefined("clone_from_locality_id") and len(clone_from_locality_id) GT 0>
				<cfset extra = " cloned from #encodeForHtml(clone_from_locality_id)#">
				<cfset blockform = getCreateLocalityHtml(clone_from_locality_id = "#clone_from_locality_id#")>
			<cfelse>
				<cfset blockform = getCreateLocalityHtml()>
			</cfif>
			<main class="container my-2" id="content">
				<section class="row">
					<div class="col-12">
					<h1 class="h2 mt-3 pl-1 ml-2" id="formheading">Create New Locality#extra#</h1>
						<div class="border rounded px-2 my-2 pt-3 pb-2" arial-labeledby="formheading">
							<form name="createLocality" method="post" action="/localities/Locality.cfm">
								<input type="hidden" name="Action" value="makenewLocality">
								#blockform#
							</form>
						</div>
					</div>
				</section>
			</main>
		</cfoutput>
	</cfcase>
	<cfcase value="makenewLocality">
		<cfif NOT isdefined("cloneCoords") OR cloneCoords NEQ "yes">
			<cfset cloneCoords = "no">
		</cfif>
		<cftransaction>
			<cfquery name="nextLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_locality_id.nextval nextLoc from dual
			</cfquery>
			<cfquery name="newLocality" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO locality (
					LOCALITY_ID,
					GEOG_AUTH_REC_ID
					,MAXIMUM_ELEVATION
					,MINIMUM_ELEVATION
					,ORIG_ELEV_UNITS
					,MAX_DEPTH
					,MIN_DEPTH
					,DEPTH_UNITS
					,SPEC_LOCALITY
					,SOVEREIGN_NATION
					,LOCALITY_REMARKS
					,section_part
					,section
					,township
					,township_direction
					,range
					,range_direction
					,nogeorefbecause
					,georef_updated_date
					,georef_by
					,curated_fg
					,LEGACY_SPEC_LOCALITY_FG )
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nextLoc.nextLoc#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#GEOG_AUTH_REC_ID#">,
					<cfif len(#MAXIMUM_ELEVATION#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#MAXIMUM_ELEVATION#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#MINIMUM_ELEVATION#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#MINIMUM_ELEVATION#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#orig_elev_units#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#orig_elev_units#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#max_depth#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#max_depth#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#min_depth#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#min_depth#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#depth_units#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#depth_units#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#SPEC_LOCALITY#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#SPEC_LOCALITY#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#SOVEREIGN_NATION#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#SOVEREIGN_NATION#">,
					<cfelse>
						'[unknown]',
					</cfif>
					<cfif len(#LOCALITY_REMARKS#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LOCALITY_REMARKS#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#section_part#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#section_part#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#section#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#section#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#township#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#township#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#township_direction#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#township_direction#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#range#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#range#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#range_direction#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#range_direction#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif isDefined("nogeorefbecause") AND len(#nogeorefbecause#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nogeorefbecause#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif isDefined("georef_updated_date") AND len(#georef_updated_date#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_DATE" value="#georef_updated_date#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif isDefined("georef_by") AND len(#georef_by#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#georef_by#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#curated_fg#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#curated_fg#">,
					<cfelse>
						NULL,
					</cfif>
					0 )
			</cfquery>
			<cfif #cloneCoords# is "yes">
				<cfquery name="cloneCoordinates" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT * 
					FROM
						 lat_long
					WHERE
						locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#clone_from_locality_id#">
						and
						accepted_lat_long_fg = 1
				</cfquery>
				<cfloop query="cloneCoordinates">
					<cfquery name="newLL" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						INSERT INTO lat_long (
							LAT_LONG_ID,
							LOCALITY_ID
							,LAT_DEG
							,DEC_LAT_MIN
							,LAT_MIN
							,LAT_SEC
							,LAT_DIR
							,LONG_DEG
							,DEC_LONG_MIN
							,LONG_MIN
							,LONG_SEC
							,LONG_DIR
							,DEC_LAT
							,DEC_LONG
							,DATUM
							,UTM_ZONE
							,UTM_EW
							,UTM_NS
							,ORIG_LAT_LONG_UNITS
							,DETERMINED_BY_AGENT_ID
							,DETERMINED_DATE
							,LAT_LONG_REF_SOURCE
							,LAT_LONG_REMARKS
							,MAX_ERROR_DISTANCE
							,MAX_ERROR_UNITS
							,NEAREST_NAMED_PLACE
							,LAT_LONG_FOR_NNP_FG
							,FIELD_VERIFIED_FG
							,ACCEPTED_LAT_LONG_FG
							,EXTENT
							,GPSACCURACY
							,GEOREFMETHOD
							,VERIFICATIONSTATUS)
						VALUES (
							sq_lat_long_id.nextval,
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nextLoc.nextLoc#">
							<cfif len(#LAT_DEG#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LAT_DEG#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#DEC_LAT_MIN#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DEC_LAT_MIN#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LAT_MIN#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LAT_MIN#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LAT_SEC#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LAT_SEC#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LAT_DIR#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LAT_DIR#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LONG_DEG#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LONG_DEG#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#DEC_LONG_MIN#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DEC_LONG_MIN#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LONG_MIN#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LONG_MIN#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LONG_SEC#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LONG_SEC#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LONG_DIR#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#LONG_DIR#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#DEC_LAT#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DEC_LAT#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#DEC_LONG#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DEC_LONG#">
							<cfelse>
								,NULL
							</cfif>
							,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DATUM#">
							<cfif len(#UTM_ZONE#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#UTM_ZONE#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#UTM_EW#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#UTM_EW#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#UTM_NS#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#UTM_NS#">
							<cfelse>
								,NULL
							</cfif>
							,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ORIG_LAT_LONG_UNITS#">
							,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#DETERMINED_BY_AGENT_ID#">
							,<cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(DETERMINED_DATE,"yyyy-mm-dd")#">
							,<cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#LAT_LONG_REF_SOURCE#">
							<cfif len(#LAT_LONG_REMARKS#) gt 0>
								,<cfqueryparam CFSQLTYPE="CF_SQL_VARCHAR" value="#LAT_LONG_REMARKS#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#MAX_ERROR_DISTANCE#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#MAX_ERROR_DISTANCE#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#MAX_ERROR_UNITS#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#MAX_ERROR_UNITS#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#NEAREST_NAMED_PLACE#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#NEAREST_NAMED_PLACE#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#LAT_LONG_FOR_NNP_FG#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#LAT_LONG_FOR_NNP_FG#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#FIELD_VERIFIED_FG#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#FIELD_VERIFIED_FG#">
							<cfelse>
								,NULL
							</cfif>
							,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ACCEPTED_LAT_LONG_FG#">
							<cfif len(#EXTENT#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#EXTENT#">
							<cfelse>
								,NULL
							</cfif>
							<cfif len(#GPSACCURACY#) gt 0>
								,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#GPSACCURACY#">
							<cfelse>
								,NULL
							</cfif>
							,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#GEOREFMETHOD#">
							,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VERIFICATIONSTATUS#">
						)
					</cfquery>
				</cfloop>
			</cfif><!---  end cloneCoordinates  --->
		</cftransaction>
		<cfoutput>
			<cflocation addtoken="no" url="/localities/Locality.cfm?locality_id=#nextLoc.nextLoc#">
		</cfoutput>
	</cfcase>
	<cfcase value="delete">  
		<cftransaction>
			<cftry>
				<cfquery name="countUses" datasource="uam_god">
					SELECT 
						sum(ct) total_uses
					FROM (
						SELECT
							count(*) ct
						FROM 
							collecting_event
						WHERE
							locality_id=  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
						UNION
						SELECT
							count(*) ct
						FROM
							media_relations
						WHERE
							related_primary_key =  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
							AND
							media_relationship like '%locality'
					)
				</cfquery>
				<cfif countUses.total_uses GT 0>
					<cfthrow message="Unable to delete. Locality has collecting events or media.">
				</cfif>
				<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="delete_result">
						DELETE FROM locality
						WHERE
							locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
				</cfquery>
				<cfoutput>
					<h1 class="h2">Locality successfully deleted.</h1>
					<ul>
						<li><a href="/localities/Localities.cfm">Search for Localities</a>.</li>
						<li><a href="/localities/Locality.cfm?action=new">Create a new Locality</a>.</li>
					</ul>
				</cfoutput>
			<cfcatch>
				<cfthrow type="Application" message="Error deleting Locality (<a href='/localities/Locality.cfm?locality_id=#encodeForUrl(locality_id)#'>#encodeForHtml(locality_id)#</a>): #cfcatch.Message# #cfcatch.Detail#"><!--- " --->
			</cfcatch>
			</cftry>
		<cftransaction>
	</cfcase>
</cfswitch>

<cfinclude template = "/shared/_footer.cfm">
