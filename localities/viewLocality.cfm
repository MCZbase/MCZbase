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
<cfinclude template="/shared/component/functions.cfc" runOnce="true"><!--- for getGuidLink() --->

<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_locality")>
	<cfset encumber = "">
<cfelse> 
	<cfquery name="checkForEncumbrances" datasource="uam_god">
		SELECT encumbrance_action 
		FROM 
			collecting_event 
 			join cataloged_item on collecting_event.collecting_event_id = cataloged_item.collecting_event_id 
 			join coll_object_encumbrance on cataloged_item.collection_object_id = coll_object_encumbrance.collection_object_id
			join encumbrance on coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id
		WHERE
			collecting_event.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
	</cfquery>
	<cfset encumber = ValueList(checkForEncumbrances.encumbrance_action)>
	<!--- potentially relevant actions: mask collector, mask coordinates, mask original field number, mask locality. --->
</cfif>

<cfoutput>
	<main class="container-xl pt-2 pb-5 mb-5" id="content">
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
					<div class="border rounded px-3 mt-2 pt-2 pb-3" arial-labeledby="formheading">
							<div class="row mx-0">
							<cfset blockDetails = getLocalityHtml(locality_id = "#locality_id#")>
							#blockDetails#
						</div>
					</div>	
					<div class="row mx-0 border-bottom-grey">
						<h2 class="sr-only">Parsed By Locality Form Field: </h2>
						<div class="col-12 col-md-6 px-3 pt-3 pb-0">
							<cfset geology = getLocalityGeologyDetailsHtml(locality_id="#locality_id#")>
							<div id="geologyDiv">#geology#</div>
						</div>
						<span class="border-bottom-grey d-block d-md-none w-100"></span>
							<div class="col-12 col-md-6 px-3 pt-3 pb-2">
								<cfif ListContains(encumber,"mask coordinates") GT 0>
									[Masked]
								<cfelse>
									<cfset georeferences = getLocalityGeoreferenceDetailsHtml(locality_id="#locality_id#")>
									<div id="georeferencesDiv">#georeferences#</div>
								</cfif>
							</div>
					</div>
					<div class="row mx-0 border-bottom-grey">
						<div class="col-12 col-md-6 p-3">
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
						<span class="border-bottom-grey d-block d-md-none w-100"></span>
						<cfif years.recordcount GT 0>
							<div class="col-12 col-md-6 p-3">
								<h3 class="h4 px-2">Known Years Collected at this locality</h3>
								<ul class="list-group list-group-horizontal flex-wrap rounded-0">
									<cfloop query="years">
										<li class="list-group-item float-left"> 
											<a class="small95" href="/Specimens.cfm?execute=true&builderMaxRows=4&action=builderSearch&nestdepth1=1&field1=LOCALITY%3ALOCALITY_LOCALITY_ID&searchText1=#locality_id#&nestdepth2=2&JoinOperator2=and&field2=COLLECTING_EVENT%3ABEGAN_DATE&searchText2=#year#&nestdepth4=1&JoinOperator4=and&field4=COLLECTING_EVENT%3ADATE_ENDED_DATE&searchText4=#year#">#years.year# </a> 
										</li>
									</cfloop>
								</ul>
							</div>
						</cfif>
					</div>
					<cfquery name="collectors"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT distinct
								preferred_agent_name.agent_id, 
								preferred_agent_name.agent_name,
								agent.agentguid,
								agent.agentguid_guid_type
							FROM
								<cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
								join collector on flatTableName.collection_object_id = collector.collection_object_id
								join preferred_agent_name on collector.agent_id = preferred_agent_name.agent_id
								join agent on collector.agent_id = agent.agent_id
							WHERE
								flatTableName.locality_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#locality_id#">
							ORDER BY
								preferred_agent_name.agent_name
						</cfquery>
					<div class="row mx-0 border-bottom-grey">
						<cfif collectors.recordcount GT 0>
							<div class="col-12 col-md-6 p-3">
								<h3 class="h4 px-2">Collectors at this locality</h3>
								<ul class="list-group list-group-horizontal flex-wrap rounded-0">
									<cfif ListContains(encumber,"mask collector") GT 0>
										<li class="list-group-item float-left">[Masked]</li>
									<cfelse>
										<cfloop query="collectors">
											<li class="list-group-item float-left"> 
												<span class="input-group">
													<a class="small95" href="/Specimens.cfm?execute=true&action=fixedSearch&current_id_only=any&collector=#encodeForURL(collectors.agent_name)#&collector_agent_id=#collectors.agent_id#">#collectors.agent_name#&thinsp;<span class="sr-only">link to collector's specimen records </span> </a> 
													<span class="input-group-append">
														<span class="bg-lightgreen">
															<a class="p-1" aria-label='link to agent record' href="/agents/Agent.cfm?agent_id=#collectors.agent_id#">
																<i class="fa fa-user" aria-hidden="true"></i>
															</a>
														</span>
														<cfif len(collectors.agentguid) gt 0>
															<cfset link = getGuidLink(guid=#collectors.agentguid#,guid_type=#collectors.agentguid_guid_type#)>
															#link#
														</cfif>
													</span>
												</span>
											</li>
										</cfloop>
									</cfif>
								</ul>
							</div>
						</cfif>
						<span class="border-bottom-grey d-block d-md-none w-100"></span>
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
							<div class="col-12 col-md-6 p-3">
								<h3 class="h4 px-2">Taxa Collected at this locality</h3>
								<ul class="list-group list-group-horizontal flex-wrap rounded-0">
									<cfloop query="taxa">
										<li class="list-group-item float-left"> 
											<a class="small95" href="/Specimens.cfm?execute=true&builderMaxRows=3&action=builderSearch&nestdepth1=1&field1=LOCALITY%3ALOCALITY_LOCALITY_ID&searchText1=#locality_id#&nestdepth2=2&JoinOperator2=and&field2=TAXONOMY%3AFAMILY&searchText2=%3D#taxa.family#&nestdepth3=3&JoinOperator3=and&field3=TAXONOMY%3AGENUS&searchText3=%3D#taxa.genus#">#taxa.family#:&##8201;#taxa.genus#</a>  
										</li>
									</cfloop>
								</ul>
							</div>
						</cfif>
					</div>
					<div class="row mx-0">
						<div class="col-12 col-md-6 px-2 py-3">
							<cfif ListContains(encumber,"mask coordinates") GT 0>
								[Masked]
							<cfelse>
								<!--- TODO: list collecting events linking out to collecting event details. --->
							</cfif>
							<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_locality")>
								<form name="createNewCollEventForm" id="createNewCollEventForm" method="post" action="/Locality.cfm">
									<input type="hidden" name="action" value="newCollEvent">
									<input type="hidden" name="locality_id" value="#locality_id#">
								</form>
								<input type="button" class="btn btn-secondary btn-xs" onClick=" $('##createNewCollEventForm').submit(); " value="Add a Collecting Event to this Locality">
							</cfif>
						</div>
					</div>
					
					<div class="row mx-0">
						<div class="col-12 col-md-6 px-2 py-3">
							<cfset media = getLocalityMediaHtml(locality_id="#locality_id#")>
							<div id="mediaDiv" class="row mx-0">#media#</div>
						</div>
					</div>
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
							<h2 class="h4">Verbatim localities (from associated collecting events)</h2>
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
