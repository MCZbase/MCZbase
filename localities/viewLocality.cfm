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
<cfif findNoCase('master',Session.gitBranch) NEQ 0>
	<!--- not ready for production use, prevent access from production, redirect to locality search --->
	<cflocation url="/localities/Localities.cfm" addtoken="false">
</cfif>

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
			<div class="col-12">
				<div class="col-12 mt-4 pb-2 border-bottom border-dark">
					<h1 class="h2 mr-2 col-10 px-0 float-left">Locality [#encodeForHtml(locality.locality_id)#]</h1>
					<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_locality")>
						<a role="button" href="/localities/Locality.cfm?locality_id=#locality_id#" class="btn btn-primary btn-xs float-right">Edit</a>
					</cfif>
				</div>
				<section class="col-12 col-md-9 px-md-0 col-xl-8 px-xl-0">
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

					<div class="row mx-0">
						<div class="col-12 col-md-6 px-0 pl-md-0 pr-md-2">
							<div class="border rounded px-3 my-2 py-3">
								<cfset geology = getLocalityGeologyDetailsHtml(locality_id="#locality_id#")>
								<div id="geologyDiv">#geology#</div>
							</div>
						</div>
						<div class="col-12 px-0 pl-md-2 col-md-6">
							<div class="border rounded px-3 my-2 py-3">
								<cfset georeferences = getLocalityGeoreferenceDetailsHtml(locality_id="#locality_id#")>
								<div id="georeferencesDiv">#georeferences#</div>
							</div>
						</div>
					</div>
					<div class="row mx-0">
						<div class="col-12 col-md-6 px-0 px-md-2">
							<cfset blockRelated = getLocalityUsesHtml(locality_id = "#locality_id#")>
							<div id="relatedTo">#blockRelated#</div>
						</div>
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
							<div class="col-12 col-md-6 px-0 pl-md-3 pr-md-3">
								<h3 class="h4 px-2 mt-2">Collectors at this locality</h3>
								<ul class="list-group list-group-horizontal flex-wrap rounded-0">
									<cfloop query="collectors">
										<li class="list-group-item col-12 col-md-4 col-lg-3 float-left"> 
											<a class="h4" href="/agents/Agent.cfm?agent_id=#collectors.agent_id#">#collectors.agent_name# </a> 
										</li>
									</cfloop>
								</ul>
							</div>
						</cfif>
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
							<div class="col-12 col-md-6 px-0 pl-md-2 pr-md-3">
								<h3 class="h4 px-2">Known Years Collected at this locality</h3>
								<ul class="list-group list-group-horizontal flex-wrap rounded-0">
									<cfloop query="years">
										<li class="list-group-item col-12 col-md-4 col-lg-3 float-left"> 
											<a class="h4" href="/?=#locality_id#=#years.year#">#years.year# </a> 
										</li>
									</cfloop>
								</ul>
							</div>
						</cfif>
						<!--- TODO: list collecting events, etc. --->
					</div>
					<div class="row mx-0">
						<div class="col-12 col-md-6 px-0 pl-md-0 pr-md-3">
							<cfset media = getLocalityMediaHtml(locality_id="#locality_id#")>
							<div id="mediaDiv" class="row">#media#</div>
						</div>
					</div>
				</section>
				<section class="mt-3 mt-md-5 col-12 px-md-0 col-md-3 col-xl-4">
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
