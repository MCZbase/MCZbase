<!---
localities/HigherGeography.cfm

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
	<cfif not isdefined("geog_auth_rec_id")>
		<cfset action="new">
	<cfelse>
		<cfset action="edit">
	</cfif>
</cfif>
<cfswitch expression="#action#">
	<cfcase value="edit">
		<cfset pageTitle="Edit Higher Geography">
	</cfcase>
	<cfcase value="new">
		<cfset pageTitle="New Higher Geography">
	</cfcase>
	<cfcase value="makenewHigherGeography">
		<cfset pageTitle="Creating New Higher Geography">
	</cfcase>
	<cfcase value="delete">
		<cfset pageTitle="Deleting Higher Geography">
	</cfcase>
	<cfdefaultcase>
		<cfthrow message="Error: Unknown Action">
	</cfdefaultcase>
</cfswitch>
<cfset pageHasTabs="true">
<cfinclude template = "/shared/_header.cfm">

<cfswitch expression="#action#">
	<cfcase value="edit">
		<cfinclude template="/localities/component/highergeog.cfc" runOnce="true">
		<cfinclude template="/localities/component/public.cfc" runOnce="true">
		<cfquery name="countUses" datasource="uam_god">
			SELECT 
				sum(ct) total_uses
			FROM (
				SELECT
					count(*) ct
				FROM 
					locality
				WHERE
					geog_auth_rec_id=  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
				UNION
				SELECT
					count(*) ct
				FROM
					media_relations
				WHERE
					related_primary_key =  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
					AND
					media_relationship like '%geog_auth_rec'
			)
		</cfquery>
		<cfif not isDefined("geog_auth_rec_id") OR len(geog_auth_rec_id) EQ 0>
			<cfthrow message="Error: unable to edit higher geography, no geog_auth_rec_id specified.">
		</cfif>
		<cfoutput>
		   <main class="container-float mt-3" id="content">
				<section class="row mx-1">
					<div class="col-12 col-md-9">
      				<h1 class="h2 mt-3 mb-0 px-4">Edit Higher Geography [#encodeForHtml(geog_auth_rec_id)#]</h1>
						<div class="border rounded px-2 py-2">
							<cfset blockRelated = getGeographyUsesHtml(geog_auth_rec_id = "#geog_auth_rec_id#")>
							<div id="relatedTo">#blockRelated#</div>
						</div>
						<div class="border rounded px-2 py-2">
							<cfset summary = getGeographySummary(geog_auth_rec_id="#geog_auth_rec_id#")>
							<div id="summary">#summary#</div>
						</div>
						<div class="border rounded px-2 py-2" arial-labeledby="formheading">
							<cfset formId = "editHigherGeographyForm">
							<cfset outputDiv="saveResultsDiv">
 			    			<form name="editHigherGeography" id="#formId#">
								<input type="hidden" id="geog_auth_rec_id" name="geog_auth_rec_id" value="#geog_auth_rec_id#">
								<input type="hidden" name="method" value="updateHigherGeography">
								<cfset blockEditForm = getHigherGeographyFormHtml(mode="edit", geog_auth_rec_id = "#geog_auth_rec_id#", formId="#formId#", outputDiv="#outputDiv#", saveButtonFunction="saveEdits")>
								#blockEditForm#
							</form>
							<script>
								function reloadHigherGeographyBlocks() { 
									updateHigherGeographySummary('#geog_auth_rec_id#','summary');	
								}
								function reloadMap()  {
									loadHigherGeographyMapHTML('#geog_auth_rec_id#','mapDiv');
								}
								function saveEdits(){ 
									saveEditsFromFormCallback("#formId#","/localities/component/highergeog.cfc","#outputDiv#","saving higher geography record",reloadHigherGeographyBlocks);
								};
							</script>
						</div>
						<div class="border rounded px-2 py-2">
							<cfif countUses.total_uses EQ "0">
								<button type="button" 
									onClick="confirmDialog('Delete this Higher Geography?', 'Confirm Delete Higher Geography', function() { location.assign('/localities/HigherGeography.cfm?action=delete&geog_auth_rec_id=#encodeForUrl(geog_auth_rec_id)#'); } );" 
									class="btn btn-xs btn-danger" >
										Delete HigherGeography
								</button>
							</cfif>
						</div>
					<section class="mt-2 float-left col-12 px-0">
					</div>
					<div class="col-12 col-md-3 pt-5">
						<!--- map --->
						<div class="border rounded p-1 w-100">
							<cfset map = getHigherGeographyMapHtml(geog_auth_rec_id="#geog_auth_rec_id#")>
							<div id="mapDiv">#map#</div>
						</div>
					</div>
				</section>
			</main>
		</cfoutput>
	</cfcase>
	<cfcase value="new">
		<cfinclude template="/localities/component/highergeog.cfc" runOnce="true">
		<cfoutput>
			<cfset extra = "">
			<cfset blockform = getHigherGeographyFormHtml(mode="new")>
		   <main class="container mt-3" id="content">
				<section class="row">
					<div class="col-12">
		      		<h1 class="h2 mt-3 pl-1 ml-2" id="formheading">Create New HigherGeography#extra#</h1>
						<div class="border rounded px-2 py-2" arial-labeledby="formheading">
			     			<form name="createHigherGeography" method="post" action="/localities/HigherGeography.cfm">
         			   	<input type="hidden" name="Action" value="makenewHigherGeography">
								#blockform#
							</form>
						</div>
					</div>
				</section>
			</main>
		</cfoutput>
	</cfcase>
	<cfcase value="makenewHigherGeography">
		<cfif NOT isdefined("cloneCoords") OR cloneCoords NEQ "yes">
			<cfset cloneCoords = "no">
		</cfif>
		<cftransaction>
			<cfquery name="nextLoc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_geog_auth_rec_id.nextval nextLoc from dual
			</cfquery>
			<cfquery name="newHigherGeography" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO geog_auth_rec (
					GEOG_AUTH_REC_ID
					,valid_catalog_term_fg
					,source_authority
					,continent_ocean
					,ocean_region
					,ocean_subregion
					,sea
					,water_feature
					,country
					,state_prov
					,county
					,feature
					,quad
					,island_group
					,island
					,highergeographyid_guid_type
					,highergeographyid
					,wkt_polygon
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nextLoc.nextLoc#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#valid_catalog_term_fg#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#source_authority#">,
					<cfif len(#continent_ocean#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#continent_ocean#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#ocean_region#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ocean_region#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#ocean_subregion#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ocean_subregion#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#sea#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#sea#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#water_feature#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#water_feature#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#country#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#country#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#state_prov#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#state_prov#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#county#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#county#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#feature#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#feature#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#quad#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#quad#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#island_group#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#island_group#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#island#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#island#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#highergeographyid_guid_type#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#highergeographyid_guid_type#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#highergeographyid#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#highergeographyid#">,
					<cfelse>
						NULL,
					</cfif>
					<cfif len(#wkt_polygon#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_CLOB" value="#wkt_polygon#">
					<cfelse>
						NULL
					</cfif>
				)
			</cfquery>
		</cftransaction>
		<cfoutput>
			<cflocation addtoken="no" url="/localities/HigherGeography.cfm?geog_auth_rec_id=#nextLoc.nextLoc#">
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
							locality
						WHERE
							geog_auth_rec_id=  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
						UNION
						SELECT
							count(*) ct
						FROM
							media_relations
						WHERE
							related_primary_key =  <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
							AND
							media_relationship like '%geog_auth_rec'
					)
				</cfquery>
				<cfif countUses.total_uses GT 0>
					<cfthrow message="Unable to delete. Higher Geography has collecting events or media.">
				</cfif>
				<cfquery name="delete" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="delete_result">
						DELETE FROM geog_auth_rec
						WHERE
							geog_auth_rec_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geog_auth_rec_id#">
				</cfquery>
				<cfoutput>
					<h1 class="h2">Higher Geography successfully deleted.</h1>
					<ul>
						<li><a href="/localities/HigherGeographies.cfm">Search for Higher Geographies</a>.</li>
						<li><a href="/localities/HigherGeography.cfm?action=new">Create a new Higher Geography</a>.</li>
					</ul>
				</cfoutput>
			<cfcatch>
				<cfthrow type="Application" message="Error deleting Higher Geography (<a href='/localities/HigherGeography.cfm?geog_auth_rec_id=#encodeForUrl(geog_auth_rec_id)#'>#encodeForHtml(geog_auth_rec_id)#</a>): #cfcatch.Message# #cfcatch.Detail#"><!--- " --->
			</cfcatch>
			</cftry>
		<cftransaction>
	</cfcase>
</cfswitch>

<cfinclude template = "/shared/_footer.cfm">
