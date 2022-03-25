<!---
specimens/manageSpecimens.cfm

Copyright 2021 President and Fellows of Harvard College

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
<cfif NOT isdefined("action")>
	<cfset action = "manage">
</cfif>
<cfset pageTitle = "Manage Specimens">
<cfinclude template = "/shared/_header.cfm">

<cfif not isDefined("result_id") OR len(result_id) EQ 0>
	<cfthrow message = "No result_id provided to manage.">
</cfif>

<cfswitch expression="#action#">
	<cfcase value="manage">
		<cfquery name="results" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="results_result">
			SELECT count(distinct collection_object_id) ct
			FROM user_search_table
			WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
		</cfquery>
		<cfif results.ct EQ 0>
			<cfthrow message = "No results found in user's USER_SEARCH_TABLE for result_id #encodeForHtml(result_id)#.">
		</cfif>
		<cfoutput>
			<div class="container">
				<div class="row mb-4">
					<div class="col-12">
						<h1 class="h2">Manage Specimens in search result [result_id=#encodeForHtml(result_id)#]</h1>

						<ul class='list-group list-group-horizontal'>
							<li class='list-group-item'>
								Accession
							</li>
							<li class='list-group-item'>
								<a href='/specimens/changeQueryCollectors.cfm?result_id=#encodeForUrl(result_id)#' class='btn btn-secondary btn-xs' target='_blank'>Collectors/Preparators</a>
							</li>
							<li class='list-group-item'>
								Collecting Events
							</li>
							<li class='list-group-item'>
								<a href='/specimens/changeQueryLocality.cfm?result_id=#encodeForUrl(result_id)#' class='btn btn-secondary btn-xs' target='_blank'>Localities</a>
							</li>
							<li class='list-group-item'>
								Encumbrances
							</li>
							<li class='list-group-item'>
								Identifications
							</li>
							<li class='list-group-item'>
								Map By Locality
							</li>
							<li class='list-group-item'>
								Parts Report
							</li>
							<li class='list-group-item'>
								Change Part Locations
							</li>
							<li class='list-group-item'>
								Modify Parts
							</li>
							<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
								<li class='list-group-item'>
									Add To Named Group
								</li>
							</cfif>
							<li class='list-group-item'>
								Print Labels
							</li>
<!---

<option value="/addAccn.cfm"> works with either, collection_object_id has priority, session search table looked up, not passed. 
Accession [Warning: No Tabs]
				
<option value="/bulkCollEvent.cfm"> works only with collection_object_id 
Collecting Events

<option value="/Encumbrances.cfm"> works only with collection_object_id 
Encumbrances

<option value="/multiIdentification.cfm"> works only with collection_object_id 
Identification

<option value="/bnhmMaps/SpecimensByLocality.cfm"> works only on session search table, passed as table_name 
Map By Locality [Warning: No Tabs]

<option value="/tools/downloadParts.cfm"> works only on session search table, passed as table_name 
Parts (Report) [Warning: No Tabs]

<option value="/findContainer.cfm?showControl=1"> looks like it works only with collection_object_id, but downstream code has reference to session.username and passed table name 
Parts (Locations)

<option value="/tools/bulkPart.cfm"> works only on session search table, passed as table_name 
Parts (Modify) [Warning: No Tabs]

<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_specimens")>
<option value="/grouping/addToNamedCollection.cfm"> works with either, collection_objecT_id has priority, session search table looked up, not passed 
Add To Named Group [Warning: No Tabs]
</option>
</cfif>

<option value="/Reports/report_printer.cfm?collection_object_id=#collObjIdList#"> works only with collection_object_id 
Print Any Report

--->
						</ul>

						<p>Manage #results.ct# cataloged item records</p>

						<h2 class="h3">These records are in these Collections</h2>
						<cfquery name="collections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="collections_result">
							SELECT count(*) ct, 
								collection_cde, 
								collection_id
							FROM user_search_table
								left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on user_search_table.collection_object_id = flat.collection_object_id
							WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
							GROUP BY collection_cde, collection_id
						</cfquery>
						<ul>
							<cfloop query="collections">
								<li class="pr-1" style="list-style-type: circle; display: inline;">#collections.collection_cde# (#collections.ct#);</li>
							</cfloop>
						</ul>

						<h2 class="h3">These records are in these Countries</h2>
						<cfquery name="countries" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="collections_result">
							SELECT count(*) ct, 
								nvl(continent_ocean,'[no continent/ocean]') as continent_ocean, nvl(country,'[no country]') as country
							FROM user_search_table
								left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on user_search_table.collection_object_id = flat.collection_object_id
							WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
							GROUP BY 
								continent_ocean, country
						</cfquery>
						<ul>
							<cfloop query="countries">
								<li class="pr-1" style="list-style-type: circle; display: inline;">#countries.continent_ocean#:#countries.country# (#countries.ct#);</li>
							</cfloop>
						</ul>

						<h2 class="h3">These records are in these Families</h2>
						<cfquery name="families" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="collections_result">
							SELECT count(*) ct, 
								nvl(phylorder,'[no order]') as phylorder, nvl(family,'[no family]') as family
							FROM user_search_table
								left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on user_search_table.collection_object_id = flat.collection_object_id
							WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
							GROUP BY phylorder, family
						</cfquery>
						<ul>
							<cfloop query="families">
								<li class="pr-1" style="list-style-type: circle; display: inline;">#families.phylorder#:#families.family# (#families.ct#);</li>
							</cfloop>
						</ul>
					</div>
				</div>
			</div>
		</cfoutput>
	</cfcase>
	<!---------------------------------------------------------------------------------------------------->
</cfswitch>

<cfinclude template="/shared/_footer.cfm">
