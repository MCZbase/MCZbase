<!---
specimens/manageSpecimens.cfm

Copyright 2021-2022 President and Fellows of Harvard College

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
						<h1 class="h3 my-3">Manage Specimens in search result [result_id=#encodeForHtml(result_id)#]</h1>
						<h5>Select Form:</h5>
						<nav class="navbar navbar-expand-sm bg-white navbar-dark p-0">
							<ul class="navbar-nav d-flex flex-wrap">
								<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
									<li class="nav-item mb-1">
										<a class="nav-link btn btn-xs btn-secondary" href="/specimens/changeQueryAccession.cfm?result_id=#encodeForUrl(result_id)#" target="_blank">Accession</a>
									</li>
									<li class="nav-item mb-1">
										<cfif findNoCase('master',Session.gitBranch) EQ 0>
											<!--- TODO: In progress, BugID:  --->
											<a class="nav-link btn btn-xs btn-secondary" href="/specimens/changeQueryDeaccession.cfm?result_id=#encodeForUrl(result_id)#" target="_blank">Deaccession (in progress)</a>
										<cfelse>
											<a href="javascript:void(0)" class="nav-link btn btn-xs btn-secondary disabled">Deaccession</a>
										</cfif>
									</li>
								</cfif>
								<li class="nav-item mb-1">
									<a href="/specimens/changeQueryCollectors.cfm?result_id=#encodeForUrl(result_id)#" class="btn btn-secondary btn-xs nav-link" target="_blank">Collectors/Preparators</a>
								</li>
								<li class="nav-item mb-1">
									<a href="/specimens/changeQueryCollEvent.cfm?result_id=#encodeForURL(result_id)#" class="nav-link btn btn-xs btn-secondary" target="_blank">Collecting Events</a>
								</li>
								<li class="nav-item mb-1">
									<a href="/specimens/changeQueryLocality.cfm?result_id=#encodeForUrl(result_id)#" class="nav-link btn btn-secondary btn-xs" target="_blank">Localities</a>
								</li>
								<li class="nav-item mb-1">
									<a href="/specimens/changeQueryEncumbrance.cfm?result_id=#encodeForUrl(result_id)#" class="nav-link btn btn-secondary btn-xs" target="_blank">Encumbrances</a>
								</li>
								<li class="nav-item mb-1">
									<a href="/specimens/changeQueryIdentification.cfm?result_id=#encodeForUrl(result_id)#" class="nav-link btn btn-secondary btn-xs" target="_blank">Identifications</a>
								</li>
								<li class="nav-item mb-1">
									<a href="/bnhmMaps/SpecimensByLocality.cfm?result_id=#encodeForUrl(result_id)#" class="nav-link btn btn-secondary btn-xs">Map Localities</a>
								</li>
								<li class="nav-item mb-1">
									<a href="/tools/downloadParts.cfm?result_id=#encodeForUrl(result_id)#" class="nav-link btn btn-secondary btn-xs" target="_blank">Parts Report/Download</a>
								</li>
								<li class="nav-item mb-1">
									<a href="/findContainer.cfm?showControl=1&result_id=#encodeForUrl(result_id)#" class="nav-link btn btn-secondary btn-xs" target="_blank">View Part Containers</a>
								</li>
								<li class="nav-item mb-1">
									<a href="javascript:void(0)" class="nav-link btn btn-secondary btn-xs disabled" target="_blank">Change Part Containers</a>
								</li>
								<li class="nav-item mb-1">
									<a href="/specimens/changeQueryParts.cfm?result_id=#encodeForUrl(result_id)#" class="nav-link btn btn-secondary btn-xs" target="_blank">Modify Parts</a>
								</li>
								<li class="nav-item mb-1">
									<a href="/specimens/changeQueryNamedCollection.cfm?result_id=#encodeForURL(result_id)#" class="nav-link btn btn-secondary btn-xs" target="_blank">Named Group</a>
								</li>
								<li class="nav-item mb-1">
									<a href="/Reports/report_printer.cfm?result_id=#encodeForUrl(result_id)#" class="nav-link btn btn-secondary btn-xs" target="_blank">Print Labels</a>
								</li>
								<li class="nav-item mb-1">
									<a href="/specimens/changeQuerySpecimenRemark.cfm?result_id=#encodeForURL(result_id)#" class="nav-link btn btn-secondary btn-xs" target="_blank">Append Cataloged Item Remarks</a>
								</li>
								<li class="nav-item mb-1">
									<cfset crlf = chr(13) & chr(10) >
									<!--- could use a longer query, but idea is to give them just a very short one that includes the result_id, and does something useful that the search result doesn (show counts of distinct taxa), they can work with the schema to figure out what other fields they may want to answer other questions --->
									<!---  
									<cfset query="SELECT count(flat.collection_object_id) ct, flat.scientific_name, flat.collection, flat.collectors, flat.spec_locality, flat.country, flat.author_text, flat.toptypestatus #crlf#FROM user_search_table#crlf#JOIN flat ON user_search_table.collection_object_id = flat.collection_object_id#crlf#WHERE user_search_table.result_id='#result_id#'#crlf#GROUP BY flat.scientific_name, flat.collection, flat.collectors, flat.spec_locality, flat.country,flat.author_text, flat.toptypestatus#crlf#ORDER BY count(flat.collection_object_id) desc">
									---->
									<cfset query="SELECT count(flat.collection_object_id) ct, scientific_name, author_text sciname_author #crlf#FROM user_search_table#crlf#JOIN flat ON user_search_table.collection_object_id = flat.collection_object_id#crlf#WHERE user_search_table.result_id='#result_id#'#crlf#GROUP BY scientific_name, author_text#crlf#ORDER BY count(flat.collection_object_id) desc">
									<a href="/tools/userSQL.cfm?input_sql=#encodeForURL(query)#" class="nav-link btn btn-secondary btn-xs" target="_blank">Run SQL Queries on this Result</a>
								</li>
	<!---

	Accession - Implemented

	Agents - Implmemented (as Collectors/Preparators)

	Localities - Implemented

	Collecting Events - Implemented, retained in old

	Encumbrances - Implemented

	Identification - Implemented

	Map By Locality - Implemented

	Parts (Report) [Warning: No Tabs] - Implemented, retained in old

	Parts (Locations) - Implemented

	Parts (Modify) - Implemented

	Add To Named Group - Implemented, old not removed yet.

	Print Any Report - Implemented, old not removed yet.

	--->
							</ul>
						</nav>
						<h2 class="h3 mt-4">Summary of #results.ct# cataloged item records that will be affected: </h2>
						<script>
							function removeCollection (collection_cde) {
								console.log(collection_cde);
			        			$.ajax({
         	   				url: "/specimens/component/search.cfc",
            					data: { 
										method: 'removeItemsFromResult', 
										result_id: '#result_id#',
										grouping_criterion: 'collection_cde',
										grouping_value: collection_cde 
									},
									dataType: 'json',
      	     					success : function (data) { 
										console.log(data);
										// TODO: Trigger reload of summary section.
										// TODO: Trigger $('##fixedsearchResultsGrid').jqxGrid('updatebounddata'); etc on grid.
									},
            					error : function (jqXHR, textStatus, error) {
          				   		handleFail(jqXHR,textStatus,error,"removing records from result set");
     		       				}
         					});
							} 
						</script>
						<div class="rounded redbox">
							<!--- TODO: Move to backing method, add ajax reload --->
							<div class="card bg-light border-secondary mb-3">
								<cfquery name="collections" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="collections_result">
									SELECT count(*) ct, 
										collection_cde, 
										collection_id
									FROM user_search_table
										left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on user_search_table.collection_object_id = flat.collection_object_id
									WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
									GROUP BY collection_cde, collection_id
								</cfquery>
								<div class="card-header h4">Collections (#collections.recordcount#)</div>
								<div class="card-body">
									<ul class="list-group list-group-horizontal d-flex flex-wrap">
										<cfloop query="collections">
											<li class="list-group-item">
												<cfif findNoCase('master',Session.gitBranch) EQ 0>
												<cfif collections.recordcount GT 1>
													<input type="button" onClick=" confirmDialog('Remove all records from #collections.collection_cde# from these search results','Confirm Remove By Collection Code', function() { removeCollection ('#collection_cde#'); }  ); " class="p-1 btn btn-xs btn-warning" value="&##8998;" aria-label="Remove"/>
												</cfif>
												</cfif>
												#collections.collection_cde# (#collections.ct#);
											</li>
										</cfloop>
									</ul>
								</div>
							</div>
							<div class="card bg-light border-secondary mb-3">
								<cfquery name="countries" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="countries_result">
									SELECT count(*) ct, 
										nvl(continent_ocean,'[no continent/ocean]') as continent_ocean, nvl(country,'[no country]') as country
									FROM user_search_table
										left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on user_search_table.collection_object_id = flat.collection_object_id
									WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
									GROUP BY 
										continent_ocean, country
								</cfquery>
								<div class="card-header h4">Countries (#countries.recordcount#)</div>
								<div class="card-body">
									<ul class="list-group list-group-horizontal d-flex flex-wrap">
										<cfloop query="countries">
											<li class="list-group-item">#countries.continent_ocean#&thinsp;:&thinsp;#countries.country# (#countries.ct#); </li>
										</cfloop>
									</ul>
								</div>
							</div>
							<div class="card bg-light border-secondary mb-3">
								<cfquery name="families" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="families_result">
									SELECT count(*) ct, 
										nvl(phylorder,'[no order]') as phylorder, nvl(family,'[no family]') as family
									FROM user_search_table
										left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on user_search_table.collection_object_id = flat.collection_object_id
									WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
									GROUP BY phylorder, family
								</cfquery>
								<div class="card-header h4">Families (#families.recordcount#)</div>
								<div class="card-body">
									<ul class="list-group list-group-horizontal d-flex flex-wrap">
										<cfloop query="families">
											<li class="list-group-item">#families.phylorder#&thinsp;:&thinsp;#families.family# (#families.ct#);</li>
										</cfloop>
									</ul>
								</div>
							</div>
							<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
								<div class="card bg-light border-secondary mb-3">
									<cfquery name="accessions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="accessions_result">
										SELECT count(*) ct, 
											accn_number, 
											accn_coll.collection,
											nvl(to_char(accn.received_date,'YYYY'),'[no date]') year
										FROM user_search_table
											left join cataloged_item on user_search_table.collection_object_id = cataloged_item.collection_object_id
											left join accn on cataloged_item.accn_id = accn.transaction_id
											LEFT JOIN trans on accn.transaction_id = trans.transaction_id 
											LEFT JOIN collection accn_coll on trans.collection_id=accn_coll.collection_id
										WHERE 
											result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
										GROUP BY accn_number, accn_coll.collection, nvl(to_char(accn.received_date,'YYYY'),'[no date]')
										ORDER BY accn_number
									</cfquery>
									<div class="card-header h4">Accessions (#accessions.recordcount#)</div>
									<div class="card-body">
										<ul class="list-group list-group-horizontal d-flex flex-wrap">
											<cfloop query="accessions">
												<li class="list-group-item">#accessions.collection# #accessions.accn_number#&thinsp;:&thinsp;#accessions.year# (#accessions.ct#);</li>
											</cfloop>
										</ul>
									</div>
								</div>
							</cfif>
							<div class="card bg-light border-secondary mb-3">
								<cfquery name="localities" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="localities_result">
									SELECT count(*) ct, 
										locality_id, spec_locality
									FROM user_search_table
										left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on user_search_table.collection_object_id = flat.collection_object_id
									WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
									GROUP BY locality_id, spec_locality
								</cfquery>
								<div class="card-header h4">Specific Localities (#localities.recordcount#)</div>
								<div class="card-body">
									<ul class="list-group list-group-horizontal d-flex flex-wrap">
										<cfloop query="localities">
											<li class="list-group-item">#localities.spec_locality# (#localities.ct#);</li>
										</cfloop>
									</ul>
								</div>
							</div>
							<div class="card bg-light border-secondary mb-3">
								<cfquery name="collectingEvents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="collectingEvents_result">
									SELECT count(*) ct, 
										collecting_event_id, began_date, ended_date, verbatim_date
									FROM user_search_table
										left join <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flat on user_search_table.collection_object_id = flat.collection_object_id
									WHERE result_id=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
									GROUP BY 
										collecting_event_id, began_date, ended_date, verbatim_date
									ORDER BY
										began_date, ended_date
								</cfquery>
								<div class="card-header h4">Collecting Events (#collectingEvents.recordcount#)</div>
								<div class="card-body">
									<ul class="list-group list-group-horizontal d-flex flex-wrap">
										<cfloop query="collectingEvents">
											<cfset summary = began_date>
											<cfif ended_date NEQ began_date>
												<cfset summary = "#summary#/#ended_date#">
											</cfif>
											<cfif len(verbatim_date) GT 0 AND verbatim_date NEQ "[no verbatim date data]" >
												<cfset summary = "#summary# [#verbatim_date#]">
											</cfif>
											<li class="list-group-item">#summary# (#collectingEvents.ct#);</li>
										</cfloop>
									</ul>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</cfoutput>
	</cfcase>
	<!---------------------------------------------------------------------------------------------------->
</cfswitch>

<cfinclude template="/shared/_footer.cfm">
