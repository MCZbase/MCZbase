<!---
localities/viewLocality.cfm

View locality records.

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

--->

<cfset pageTitle="Locality Details">
<cfinclude template = "/shared/_header.cfm">

<cfif not isDefined("locality_id") OR len(locality_id) EQ 0>
	<cfthrow message="Error: unable to view locality, no locality_id specified.">
<cfelse>
	<cfquery name="locality" datasource="uam_god">
		SELECT locality_id
		FROM locality
		WHERE
			locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
	</cfquery>
	<cfif locality.recordcount NEQ 1>
		<cfinclude template="/errors/404.cfm">
		<cfabort>
	</cfif>
</cfif>

<cfinclude template="/localities/component/public.cfc" runOnce="true"><!--- for getLocalityMap() --->
<cfinclude template="/localities/component/search.cfc" runOnce="true"><!--- for getLocalitySummary() --->

<cfoutput>
	<main class="container-xl mt-3 pb-5 mb-5" id="content">
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
				<section class="col-12 col-md-9 col-xl-8  float-left">
					<div class="border-top border-right border-left border-bottom border-success rounded px-3 my-3 py-3">
							<cfset summary = getLocalitySummary(locality_id="#locality_id#")>
							<div id="summary" class="h3 px-2 mb-0">#summary#</div>
						</div>
					<div class="border rounded px-3 my-2 pt-2 pb-3" arial-labeledby="formheading">
							<div class="row mx-0">
							<cfset blockDetails = getLocalityHtml(locality_id = "#locality_id#")>
							#blockDetails#
						</div>
					</div>	
					<div class="row mx-0 border-bottom-grey">
						<div class="col-12 col-md-6 px-0 pl-md-0 pr-md-2">
							<div class="px-3 my-2 py-3">
								<cfset geology = getLocalityGeologyDetailsHtml(locality_id="#locality_id#")>
								<div id="geologyDiv">#geology#</div>
							</div>
						</div>
						<span class="border-bottom-grey d-block d-md-none w-100"></span>
						<div class="col-12 px-0 pl-md-2 col-md-6">
							<div class="px-3 my-2 py-3">
								<cfset georeferences = getLocalityGeoreferenceDetailsHtml(locality_id="#locality_id#")>
								<div id="georeferencesDiv">#georeferences#</div>
							</div>
						</div>
					</div>
					<div class="row mx-0 border-bottom-grey">
						<div class="col-12 col-md-6 px-0 py-2 px-md-2">
							<cfset blockRelated = getLocalityUsesHtml(locality_id = "#locality_id#")>
							<div id="relatedTo">#blockRelated#</div>
						</div>
						<!--- join through flat/filtered flat to prevent inclusion of encumbered cataloged item records --->
						<cfquery name="years"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT 
								count(flatTableName.collection_object_id) ct,
								to_char(collecting_event.date_began_date,'yyyy') year
							FROM
								<cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
								join collecting_event on flatTableName.collecting_event_id = collecting_event.collecting_event_id
							WHERE
								flatTableName.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
								and
								to_char(collecting_event.date_began_date,'yyyy') = to_char(collecting_event.date_ended_date,'yyyy')
							GROUP BY
								to_char(collecting_event.date_began_date,'yyyy')
							ORDER BY 
								to_char(collecting_event.date_began_date,'yyyy') asc
						</cfquery>
						<cfif years.recordcount GT 0>
							<div class="col-12 col-md-6 px-0 py-2 pl-md-2 pr-md-3">
								<h3 class="h4 px-2">Known Years Collected at this locality</h3>
								<ul class="list-group list-group-horizontal flex-wrap rounded-0">
									<cfloop query="years">
										<li class="list-group-item float-left"> 
											<a class="h4" href="/Specimens.cfm?execute=true&builderMaxRows=4&action=builderSearch&nestdepth1=1&field1=LOCALITY%3ALOCALITY_LOCALITY_ID&searchText1=#locality_id#&nestdepth2=2&JoinOperator2=and&field2=COLLECTING_EVENT%3ABEGAN_DATE&searchText2=#year#&nestdepth4=1&JoinOperator4=and&field4=COLLECTING_EVENT%3ADATE_ENDED_DATE&searchText4=#year#">#years.year# </a> 
										</li>
									</cfloop>
								</ul>
							</div>
						</cfif>
						<cfquery name="collectors"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT distinct
								preferred_agent_name.agent_id, 
								preferred_agent_name.agent_name
							FROM
								<cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
								join collector on flatTableName.collection_object_id = collector.collection_object_id
								join preferred_agent_name on collector.agent_id = preferred_agent_name.agent_id
							WHERE
								flatTableName.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
						</cfquery>
						<cfif collectors.recordcount GT 0>
							<div class="col-12 col-md-6 px-0 pl-md-3 pr-md-3 border rounded">
								<h3 class="h4 px-2 mt-2">Collectors at this locality</h3>
								<ul class="list-group list-group-horizontal flex-wrap rounded-0">
									<cfloop query="collectors">
										<li class="list-group-item float-left"> 
											<a class="h4" href="/agents/Agent.cfm?agent_id=#collectors.agent_id#">#collectors.agent_name# </a> 
										</li>
									</cfloop>
								</ul>
							</div>
						</cfif>
						<cfquery name="taxa"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT 
								count(flatTableName.collection_object_id) ct,
								flatTableName.genus, flatTableName.family
							FROM
								<cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
							WHERE
								flatTableName.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
							GROUP BY
								family, genus
							ORDER BY 
								family, genus
						</cfquery>
						<cfif taxa.recordcount GT 0>
							<div class="col-12 col-md-6 px-0 pl-md-2 pr-md-3 border rounded">
								<h3 class="h4 px-2">Taxa Collected at this locality</h3>
								<ul class="list-group list-group-horizontal flex-wrap rounded-0">
									<cfloop query="taxa">
										<li class="list-group-item float-left"> 
											<a class="h4" href="/Specimens.cfm?execute=true&builderMaxRows=3&action=builderSearch&nestdepth1=1&field1=LOCALITY%3ALOCALITY_LOCALITY_ID&searchText1=#locality_id#&nestdepth2=2&JoinOperator2=and&field2=TAXONOMY%3AFAMILY&searchText2=%3D#taxa.family#&nestdepth3=3&JoinOperator3=and&field3=TAXONOMY%3AGENUS&searchText3=%3D#taxa.genus#">#taxa.family#:#taxa.genus#</a>  
										</li>
									</cfloop>
								</ul>
							</div>
						</cfif>
						<!--- TODO: list collecting events linking out to collecting event details. --->
					</div>
					<div class="row mx-0">
						<div class="col-12 col-md-6 px-0 pl-md-0 pr-md-3">
							<cfset media = getLocalityMediaHtml(locality_id="#locality_id#")>
							<div id="mediaDiv" class="row">#media#</div>
						</div>
					</div>
				</section>
				<section class="mt-3 mt-md-2 col-12 col-md-3 col-xl-4 pl-md-0 float-left">
					<!--- map --->
					<div class="col-12 px-0 bg-light pt-0 pb-1 mt-2 mb-2 border rounded">
						<cfset map = getLocalityMapHtml(locality_id="#locality_id#")>
						<div id="mapDiv">#map#</div>
					</div>
					<!--- verbatim values --->
					<div class="col-12 pt-2">
						<h2 class="h4">Verbatim localities (from associated collecting events)</h2>
						<cfset verbatim = getLocalityVerbatimHtml(locality_id="#locality_id#")>
						<div id="verbatimDiv">#verbatim#</div>
					</div>
				</section>
			</div>
		</div>
	</main>
</cfoutput>

<cfinclude template = "/shared/_footer.cfm">
