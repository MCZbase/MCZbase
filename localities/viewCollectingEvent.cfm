<cfset pageTitle = "Collecting Event Details">
<!--
localities/viewCollectingEvent.cfm

Form for displaying collecting event details

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

-->

<cfif NOT isdefined("collecting_event_id")>
	<cfthrow message="No collecting_event specified.">
</cfif>
<cfinclude template = "/shared/_header.cfm">
<cfinclude template = "/localities/component/search.cfc" runOnce="true"><!--- for getLocalitySummary() --->
<cfinclude template = "/shared/component/functions.cfc" runOnce="true"><!--- for getGuidLink() --->
<cfinclude template = "/localities/component/public.cfc" runOnce="true"><!--- for  getHigherGeographyMapHtml() --->

<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_locality")>
	<cfset encumber = "">
<cfelse> 
	<cfquery name="checkForEncumbrances" datasource="uam_god">
		SELECT encumbrance_action 
		FROM 
 			cataloged_item 
 			join coll_object_encumbrance on cataloged_item.collection_object_id = coll_object_encumbrance.collection_object_id
			join encumbrance on coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id
		WHERE
			cataloged_item.collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
	</cfquery>
	<cfset encumber = ValueList(checkForEncumbrances.encumbrance_action)>
	<!--- potentially relevant actions: mask collector, mask coordinates, mask original field number. --->
</cfif>

<cfquery name="getCollectingEvent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getCollectingEvent_result">
	SELECT 
		locality_id,
		date_began_date, date_ended_date, verbatim_date,
		verbatim_locality, coll_event_remarks, valid_distribution_fg,
		collecting_source, collecting_method, habitat_desc,
		date_determined_by_agent_id, fish_field_number, 
		began_date, ended_date, collecting_time,
		startdayofyear, enddayofyear, 
		verbatimcoordinates, verbatimlatitude, verbatimlongitude,
		verbatimcoordinatesystem, verbatimsrs,
		verbatimelevation, verbatimdepth
	FROM
		collecting_event
	WHERE
		collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
</cfquery>

<cfoutput query="getCollectingEvent">
	<main class="container-xl " id="content">
		<div class="row mx-0">
			<div class="col-12 px-0">
				<div class="row mx-0">
					<div class="col-12 mt-4 pb-2 border-bottom border-dark">
						<h1 class="h2 mr-2 mb-0 col-10 px-1 mt-0 float-left">Locality [#encodeForHtml(locality.locality_id)#]</h1>
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_locality")>
							<a role="button" href="/localities/Locality.cfm?locality_id=#locality_id#" class="btn btn-primary btn-xs float-right mr-1">Edit Locality</a>
						</cfif>
					</div>
				</div>
				<section class="col-12 col-md-9 col-xl-8 float-left">
					
					<div class="border-top border-right border-left border-bottom border-success rounded px-3 my-3 py-3">
						<cfset summary = getLocalitySummary(locality_id="#locality_id#")>
						<div id="summary" class="small95 px-2 mb-0"><span class="sr-only">Summary: </span>#summary#</div>
					</div>

					<div class="col-12 px-0 bg-light pt-0 pb-1 mt-2 mb-2 border rounded">
						<!--- TODO: event details --->
						<ul>
							<li>#began_date#</li>
							<li>#ended_date#</li>
						</ul>
					</div>

					<cfif ListContains(encumber,"mask collector") GT 0>
						<div class="col-12 px-0 bg-light pt-0 pb-1 mt-2 mb-2 border rounded">
							[Masked]
						</div>
					<cfelse>

						<!--- TODO: Collecting event numbers --->

						<!--- TODO: Collectors --->

					</cfif>


				</section>
				<section class="mt-3 mt-md-2 col-12 col-md-3 col-xl-4 pl-md-0 float-left">
					<cfif ListContains(encumber,"mask coordinates") GT 0>
						<div class="col-12 px-0 bg-light pt-0 pb-1 mt-2 mb-2 border rounded">
							[Masked]
						</div>
					<cfelse>
						<!--- map --->
						<div class="col-12 px-0 bg-light pt-0 pb-1 mt-2 mb-2 border rounded">
							<cfset map = getLocalityMapHtml(locality_id="#locality_id#")>
							<div id="mapDiv">#map#</div>
						</div>
						<!--- verbatim values --->
						<div class="col-12 pt-2">
							<h2 class="h4">Verbatim localities (from other associated collecting events)</h2>
							<cfset verbatim = getLocalityVerbatimHtml(locality_id="#locality_id#", context="view")>
							<div id="verbatimDiv">#verbatim#</div>
						</div>
					</cfif>
				</section>
			</div>
		</div>
	</main>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
