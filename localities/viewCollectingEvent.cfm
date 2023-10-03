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
		began_date, ended_date, collecting_time,
		verbatim_date,
		verbatim_locality, coll_event_remarks, 
		decode(valid_distribution_fg, null, '', 1, 'yes',0,'no','') valid_distribution_flag,
		collecting_source, collecting_method, habitat_desc,
		date_determined_by_agent_id, agent_name,
		fish_field_number, 
		startdayofyear, enddayofyear, 
		verbatimcoordinates, verbatimlatitude, verbatimlongitude,
		verbatimcoordinatesystem, verbatimsrs,
		verbatimelevation, verbatimdepth
	FROM
		collecting_event
		left join preferred_agent_name on collecting_event.date_determined_by_agent_id = preferred_agent_name.agent_id
	WHERE
		collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
</cfquery>

<cfoutput query="getCollectingEvent">
	<cfset locality_id = getCollectingEvent.locality_id>
	<main class="container-xl " id="content">
		<div class="row mx-0">
			<div class="col-12 px-0">
				<div class="row mx-0">
					<div class="col-12 mt-4 pb-2 border-bottom border-dark">
						<h1 class="h2 mr-2 mb-0 col-10 px-1 mt-0 float-left">Collecting Event [#encodeForHtml(collecting_event_id)#]</h1>
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_locality")>
							<a role="button" href="/localities/CollectingEvent.cfm?collecting_event_id=#encodeForURL(collecting_event_id)#" class="btn btn-primary btn-xs float-right mr-1">Edit Collecting Event</a>
						</cfif>
					</div>
					<div class="col-12 mt-4 pb-2 border-bottom border-dark">
						<h1 class="h2 mr-2 mb-0 col-10 px-1 mt-0 float-left">In Locality [#encodeForHtml(locality_id)#]</h1>
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"manage_locality")>
							<a role="button" href="/localities/Locality.cfm?locality_id=#locality_id#" class="btn btn-primary btn-xs float-right mr-1">Edit Locality</a>
						</cfif>
					</div>
				</div>
				<section class="col-12 col-md-9 col-xl-8 float-left">
					
					<div class="border-top border-right border-left border-bottom border-success rounded px-3 my-3 py-3">
						<cfset summary = getLocalitySummary(locality_id="#locality_id#")>
						<div id="summary" class="small95 px-2 mb-0"><span class="sr-only">Locality Summary: </span>#summary#</div>
					</div>

					<div class="col-12 px-0 bg-light pt-0 pb-1 mt-2 mb-2 border rounded">
						<!--- TODO: event details --->
						<ul class="sd list-unstyled bg-light row mx-0 px-2 pt-1 mb-0 border-top">
							<cfif len(collecting_source) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Collecting Source: </li>
								<li class="list-group-item col-7 col-xl-8 px-0 last">#collecting_source#</li>
							</cfif>
							<cfif len(collecting_method) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Collecting Method: </li>
								<li class="list-group-item col-7 col-xl-8 px-0 last">#collecting_method#</li>
							</cfif>
							<cfif len(began_date) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Start Date: </li>
								<li class="list-group-item col-7 col-xl-8 px-0 last">#began_date#</li>
							</cfif>
							<cfif len(ended_date) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">End Date: </li>
								<li class="list-group-item col-7 col-xl-8 px-0 last">#ended_date#</li>
							</cfif>
							<cfif len(collecting_time) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Time: </li>
								<li class="list-group-item col-7 col-xl-8 px-0 last">#collecting_time#</li>
							</cfif>
							<cfif len(startdayofyear) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Start Day: </li>
								<li class="list-group-item col-7 col-xl-8 px-0 last">#startdayofyear#</li>
							</cfif>
							<cfif len(enddayofyear) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">End Day: </li>
								<li class="list-group-item col-7 col-xl-8 px-0 last">#enddayofyear#</li>
							</cfif>
							<cfif len(verbatim_date) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Verbatim Date: </li>
								<li class="list-group-item col-7 col-xl-8 px-0 last">#verbatim_date#</li>
							</cfif>
							<cfif len(date_determined_by_agent_id) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Date Determined By: </li>
								<li class="list-group-item col-7 col-xl-8 px-0 last"><a href="/agents/Agent.cfm?agent_id="#date_determined_by_agent_id#">#agent_name#</a></li>
							</cfif>
							<cfif isdefined("valid_distribution_flag") AND len(valid_distribution_flag) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Valid Distribution: </li>
								<li class="list-group-item col-7 col-xl-8 px-0 last">#valid_distribution_flag#</li>
							</cfif>
							<cfif len(verbatim_locality) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Verbatim Locality: </li>
								<li class="list-group-item col-7 col-xl-8 px-0 last">#verbatim_locality#</li>
							</cfif>
							<cfif len(verbatimcoordinates) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Verbatim Coordinates: </li>
								<li class="list-group-item col-7 col-xl-8 px-0 last">#verbatimcoordinates#</li>
							</cfif>
							<cfif len(verbatimcoordinatesystem) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Verbatim Coordinate System: </li>
								<li class="list-group-item col-7 col-xl-8 px-0 last">#verbatimcoordinatesystem#</li>
							</cfif>
							<cfif len(verbatimsrs) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Verbatim Spatial Reference System: </li>
								<li class="list-group-item col-7 col-xl-8 px-0 last">#verbatimsrs#</li>
							</cfif>
							<cfif len(verbatimlatitude) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Verbatim Latitude: </li>
								<li class="list-group-item col-7 col-xl-8 px-0 last">#verbatimlatitude#</li>
							</cfif>
							<cfif len(verbatimlongitude) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Verbatim Longitude: </li>
								<li class="list-group-item col-7 col-xl-8 px-0 last">#verbatimlongitude#</li>
							</cfif>
							<cfif len(verbatimdepth) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Verbatim Depth: </li>
								<li class="list-group-item col-7 col-xl-8 px-0 last">#verbatimdepth#</li>
							</cfif>
							<cfif len(verbatimelevation) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Verbatim Elevation: </li>
								<li class="list-group-item col-7 col-xl-8 px-0 last">#verbatimelevation#</li>
							</cfif>
							<cfif len(habitat_desc) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Habitat: </li>
								<li class="list-group-item col-7 col-xl-8 px-0 last">#habitat_desc#</li>
							</cfif>
							<cfif len(fish_field_number) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Fish Field Number: </li>
								<li class="list-group-item col-7 col-xl-8 px-0 last">#fish_field_number#</li>
							</cfif>
							<cfif len(coll_event_remarks) gt 0>
								<li class="list-group-item col-5 col-xl-4 px-0 font-weight-lessbold">Remarks: </li>
								<li class="list-group-item col-7 col-xl-8 px-0 last">#coll_event_remarks#</li>
							</cfif>
						</ul>
					</div>

					<cfif ListContains(encumber,"mask collector") GT 0>
						<div class="col-12 px-0 bg-light pt-0 pb-1 mt-2 mb-2 border rounded">
							[Masked]
						</div>
					<cfelse>

						<!--- TODO: Collecting event numbers --->
						<cfquery name="getCollEventNumbers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getCollEventNumbers_result">
							SELECT 
								coll_event_number, number_series, agent_name, preferred_agent_name.agent_id
							FROM
								coll_event_number
								left join coll_event_num_series on coll_event_number.coll_event_num_series_id = coll_event_num_series.coll_event_num_series_id
								left join preferred_agent_name on coll_event_num_series.collector_agent_id = preferred_agent_name.agent_id
							WHERE
								coll_event_number.collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
						</cfquery>
						<cfif getCollEventNumbers.recordcount GT 0>
							<div class="col-12 px-0 bg-light pt-0 pb-1 mt-2 mb-2 border rounded">
								<h2 class="h3">Collector Numbers/Field Numbers for this event</h2>
								<ul>
									<cfloop query="getCollEventNumbers">
										<cfset agentLink ="">
										<cfif len(getCollEventNumbers.agent_id) GT 0>
											<cfset agentLink = '<a href="/agents/Agent.cfm?agent_id=#getCollEventNumbers.agent_id#">#getCollEventNumbers.agent_name#</a>'>
										</cfif>
										<li>#coll_event_number# #number_series# #agentLink#</li>
									</cfloop>
								</ul>
							</div>
						</cfif>

						<!--- Collectors --->
						<cfquery name="getCollectors" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getCollectors_result">
							SELECT 
								count(cataloged_item.collection_object_id) ct, preferred_agent_name.agent_id, agent_name
							FROM
								cataloged_item
								left join collector on cataloged_item.collection_object_id = collector.collection_object_id and collector.collector_role = 'c'
								left join preferred_agent_name on collector.agent_id = preferred_agent_name.agent_id
							WHERE
								cataloged_item.collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
							GROUP BY
								preferred_agent_name.agent_id, agent_name
							ORDER BY
								agent_name
						</cfquery>
						
						<div class="col-12 px-0 bg-light pt-0 pb-1 mt-2 mb-2 border rounded">
							<h2 class="h3">Collectors in this event</h2>
							<ul>
								<cfif getCollectors.recordcount EQ 0>
									<li>None</li>
								<cfloop query="getCollectors">
									<li><a href="/agents/Agent.cfm?agent_id=#getCollectors.agent_id#">#getCollectors.agent_name#</a> (#getCollectors.ct#)</li>
								</cfoop>
							</ul>
						</div>

					</cfif>

					<!--- Summary of cataloged item records --->
					<cfquery name="getItemCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getItemCount_result">
						SELECT count(collection_object_id) ct
						FROM 
							<cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
						WHERE
							collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
					</cfquery>
					<div class="col-12 px-0 bg-light pt-0 pb-1 mt-2 mb-2 border rounded">
						<h2 class="h3">
							Material collected in this event 
							<a href="/Specimens.cfm?execute=true&builderMaxRows=1&action=builderSearch&nestdepth1=1&field1=COLLECTING_EVENT%3ACOLLECTING%20EVENTS_COLLECTING_EVENT_ID&searchText1=#encodeForURL(collecting_event_id)#">(#getItemCount.recordcount#)</a>
						</h2>
						<ul>
							<cfif getItemCount.recordCount EQ 0>
								<li>None</li>
							<cfelseif getItemCount.recordcount LT 11>
								<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getItems_result">
									SELECT 
										guid, phylclass, phylorder, family, scientific_name, author_text, partdetail, typestatus, collection
									FROM 
										<cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
									WHERE
										collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
								</cfquery>
								<cfloop query="getItems">
									<li>#collection# <a href="/guid/#guid#">#guid#</a> #scientific_name# <span class="">#author_text#</span> #partdetail# #typestatus#</li>
								</cfloop>
							<cfelse>
								<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getItems_result">
									SELECT 
										count(collection_object_id) ct, collection, phylclass, phylorder, family, collection_cde
									FROM 
										<cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat
									WHERE
										collecting_event_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collecting_event_id#">
									GROUP BY
										collection, phylclass, phylorder, family, collection_cde
									ORDER BY
										collection, family
								</cfquery>
								<cfloop query="getItems">
									<li>
										#collection# #phylclass# #phylorder# #family# 
										<a href="/Specimens.cfm?execute=true&builderMaxRows=3&action=builderSearch&nestdepth1=1&field1=COLLECTING_EVENT%3ACOLLECTING%20EVENTS_COLLECTING_EVENT_ID&searchText1=#encodeForUrl(collecting_event_id)#&nestdepth2=2&JoinOperator2=and&field2=CATALOGED_ITEM%3ACOLLECTION_CDE&searchText2=%3D#collection_cde#&nestdepth3=3&JoinOperator3=and&field3=TAXONOMY%3AFAMILY&searchText3=%3D#family#">(#ct#)</a>
									</li>
								</cfloop>
							</cfif>
						</ul>
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
							<cfset map = getLocalityMapHtml(locality_id="#getCollectingEvent.locality_id#")>
							<div id="mapDiv">#map#</div>
						</div>
						<!--- verbatim values --->
						<div class="col-12 pt-2">
							<h2 class="h4">Verbatim localities (from other associated collecting events)</h2>
							<cfset verbatim = getLocalityVerbatimHtml(locality_id="#getCollectingEvent.locality_id#", context="view")>
							<div id="verbatimDiv">#verbatim#</div>
						</div>
					</cfif>
				</section>
			</div>
		</div>
	</main>
</cfoutput>
<cfinclude template = "/shared/_footer.cfm">
