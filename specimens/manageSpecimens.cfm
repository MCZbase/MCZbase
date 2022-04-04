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
			<style>
				.navbar-dark .navbar-nav .active > .nav-link, .active {color:black;background-color: white;}
			</style>
			<div class="container pb-5">
				<div class="row">
					<div class="col-12 mt-4">
						<h1 class="h3 my-2">Manage Specimens in search result [<a href="##">result_id=#encodeForHtml(result_id)#</a>]</h1>
						<nav class="navbar navbar-expand-sm bg-white navbar-dark p-0">
						<ul class="navbar-nav">
							<li class="nav-item">
								<a class="nav-link btn btn-xs btn-secondary disabled" href="##">Accession</a>
							</li>
							<li class="nav-item">
								<a href="/specimens/changeQueryCollectors.cfm?result_id=#encodeForUrl(result_id)#" class="btn btn-secondary btn-xs nav-link" target="_blank">Collectors/Preparators</a>
							</li>
							<li class="nav-item">
								<a href="##" class="nav-link btn btn-xs btn-secondary disabled">Collecting Events</a>
							</li>
							<cfif findNoCase('master',Session.gitBranch) EQ 0>
								<!--- not working yet, don't link to on production --->
								<li class="nav-item">
									<a href="/specimens/changeQueryLocality.cfm?result_id=#encodeForUrl(result_id)#" class="nav-link btn btn-secondary btn-xs" target="_blank">Localities</a>
								</li>
							<cfelse>
								<li class="nav-item">
									<a href="##" class="nav-link btn btn-secondary btn-xs disabled">Localities</a>
								</li>
							</cfif>
							<li class="nav-item">
								<a href="##" class="nav-link btn btn-secondary btn-xs disabled">Encumbrances</a>
							</li>
							<li class="nav-item">
								<a href="##" class="nav-link btn btn-secondary btn-xs disabled">Identifications</a>
							</li>
							<li class="nav-item">
								<a href="##" class="nav-link btn btn-secondary btn-xs disabled">Map By Locality</a>
							</li>
							<li class="nav-item">
								<a href="##" class="nav-link btn btn-secondary btn-xs disabled">Parts Report</a>
							</li>
							<li class="nav-item">
								<a href="##" class="nav-link btn btn-secondary btn-xs disabled">Change Part Locations</a>
							</li>
							<li class="nav-item">
								<a href="##" class="nav-link btn btn-secondary btn-xs disabled">Modify Parts</a>
							</li>
							<li class="nav-item">
								<a href="##" class="nav-link btn btn-secondary btn-xs disabled">Add To Named Group</a>
							</li>
							<li class="nav-item">
								<a href="##" class="nav-link btn btn-secondary btn-xs disabled">Print Labels</a>
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
						</nav>
						<h2 class="h3 mt-4">Summary of #results.ct# cataloged item records: </h2>

						<h3 class="h4 mt-3 mb-2">Collections</h3>
						<cfquery name="collections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="collections_result">
							SELECT count(*) ct, 
								collection_cde, 
								collection_id
							FROM user_search_table
								left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on user_search_table.collection_object_id = flat.collection_object_id
							WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
							GROUP BY collection_cde, collection_id
						</cfquery>
					<ul class="list-group list-group-horizontal d-flex flex-wrap">
							<cfloop query="collections">
								<li class="list-group-item">#collections.collection_cde# (#collections.ct#);</li>
							</cfloop>
						</ul>

						<h3 class="h4 mt-3 mb-2">Countries</h3>
						<cfquery name="countries" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="collections_result">
							SELECT count(*) ct, 
								nvl(continent_ocean,'[no continent/ocean]') as continent_ocean, nvl(country,'[no country]') as country
							FROM user_search_table
								left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on user_search_table.collection_object_id = flat.collection_object_id
							WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
							GROUP BY 
								continent_ocean, country
						</cfquery>
						<ul class="list-group list-group-horizontal d-flex flex-wrap">
							<cfloop query="countries">
								<li class="list-group-item">#countries.continent_ocean#&thinsp;:&thinsp;#countries.country# (#countries.ct#); </li>
							</cfloop>
						</ul>

						<h3 class="h4 mt-3 mb-2">Families</h3>
						<cfquery name="families" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="collections_result">
							SELECT count(*) ct, 
								nvl(phylorder,'[no order]') as phylorder, nvl(family,'[no family]') as family
							FROM user_search_table
								left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on user_search_table.collection_object_id = flat.collection_object_id
							WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
							GROUP BY phylorder, family
						</cfquery>
						<ul class="list-group list-group-horizontal d-flex flex-wrap">
							<cfloop query="families">
								<li class="list-group-item">#families.phylorder#&thinsp;:&thinsp;#families.family# (#families.ct#);</li>
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
