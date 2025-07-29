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
<cfinclude template = "/specimens/component/manage.cfc">

<cfif not isDefined("result_id") OR len(result_id) EQ 0>
	<cfthrow message = "No result_id provided to manage.">
</cfif>

<cfswitch expression="#action#">

	<cfcase value="manage">
		<cfquery name="results" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="results_result">
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
			<script>
				var bc = new BroadcastChannel('resultset_channel');
			</script>
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
									<a href="/specimens/changeQueryPartContainers.cfm?result_id=#encodeForUrl(result)id)#" class="nav-link btn btn-secondary btn-xs" target="_blank">Change Part Containers</a>
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
						<h2 class="h3 mt-4" id="catItemCountDiv">Summary of #results.ct# cataloged item records that will be affected: </h2>
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
										// Trigger reload of summary section.
										reloadSummarySections();
										// Trigger $('##fixedsearchResultsGrid').jqxGrid('updatebounddata'); etc on grid.
										resultModifiedHere();
									},
            					error : function (jqXHR, textStatus, error) {
          				   		handleFail(jqXHR,textStatus,error,"removing records from result set by collection" );
     		       				}
         					});
							} 
							function removeByPrefix (prefix) {
								console.log(prefix);
			        			$.ajax({
         	   				url: "/specimens/component/search.cfc",
            					data: { 
										method: 'removeItemsFromResult', 
										result_id: '#result_id#',
										grouping_criterion: 'prefix',
										grouping_value: prefix 
									},
									dataType: 'json',
      	     					success : function (data) { 
										console.log(data);
										// Trigger reload of summary section.
										reloadSummarySections();
										// Trigger $('##fixedsearchResultsGrid').jqxGrid('updatebounddata'); etc on grid.
										resultModifiedHere();
									},
            					error : function (jqXHR, textStatus, error) {
          				   		handleFail(jqXHR,textStatus,error,"removing records from result set by prefix");
     		       				}
         					});
							} 
							function removeByCountry (continentCountryString) {
								console.log(continentCountryString);
			        			$.ajax({
         	   				url: "/specimens/component/search.cfc",
            					data: { 
										method: 'removeItemsFromResult', 
										result_id: '#result_id#',
										grouping_criterion: 'country',
										grouping_value: continentCountryString 
									},
									dataType: 'json',
      	     					success : function (data) { 
										console.log(data);
										// Trigger reload of summary section.
										reloadSummarySections();
										// Trigger $('##fixedsearchResultsGrid').jqxGrid('updatebounddata'); etc on grid.
										resultModifiedHere();
									},
            					error : function (jqXHR, textStatus, error) {
          				   		handleFail(jqXHR,textStatus,error,"removing records from result set by country");
     		       				}
         					});
							} 
							function removeByFamily (orderFamilyString) {
								console.log(orderFamilyString);
			        			$.ajax({
         	   				url: "/specimens/component/search.cfc",
            					data: { 
										method: 'removeItemsFromResult', 
										result_id: '#result_id#',
										grouping_criterion: 'family',
										grouping_value: orderFamilyString 
									},
									dataType: 'json',
      	     					success : function (data) { 
										console.log(data);
										// Trigger reload of summary section.
										reloadSummarySections();
										// Trigger $('##fixedsearchResultsGrid').jqxGrid('updatebounddata'); etc on grid.
										resultModifiedHere();
									},
            					error : function (jqXHR, textStatus, error) {
          				   		handleFail(jqXHR,textStatus,error,"removing records from result set by family");
     		       				}
         					});
							} 
							function removeByParts (orderPartsString) {
								console.log(orderPartsString);
			        			$.ajax({
         	   				url: "/specimens/component/search.cfc",
            					data: { 
										method: 'removeItemsFromResult', 
										result_id: '#result_id#',
										grouping_criterion: 'parts',
										grouping_value: orderPartsString 
									},
									dataType: 'json',
      	     					success : function (data) { 
										console.log(data);
										// Trigger reload of summary section.
										reloadSummarySections();
										// Trigger $('##fixedsearchResultsGrid').jqxGrid('updatebounddata'); etc on grid.
										resultModifiedHere();
									},
            					error : function (jqXHR, textStatus, error) {
          				   		handleFail(jqXHR,textStatus,error,"removing records from result set by part");
     		       				}
         					});
							} 
							function removeByPreservations (orderPreservationsString) {
								console.log(orderPreservationsString);
			        			$.ajax({
         	   				url: "/specimens/component/search.cfc",
            					data: { 
										method: 'removeItemsFromResult', 
										result_id: '#result_id#',
										grouping_criterion: 'preserve_method',
										grouping_value: orderPreservationsString 
									},
									dataType: 'json',
      	     					success : function (data) { 
										console.log(data);
										// Trigger reload of summary section.
										reloadSummarySections();
										// Trigger $('##fixedsearchResultsGrid').jqxGrid('updatebounddata'); etc on grid.
										resultModifiedHere();
									},
            					error : function (jqXHR, textStatus, error) {
          				   		handleFail(jqXHR,textStatus,error,"removing records from result set by preserve_method");
     		       				}
         					});
							} 
							function resultModifiedHere() { 
								var result_id = $("##result_id_fixedSearch").val();
								bc.postMessage({"source":"manage","result_id":"#result_id#"});
							}

							bc.onmessage = function (message) { 
								console.log(message);
								if (message.data.source == "search" &&  message.data.result_id == "#result_id#") { 
									reloadSummarySections();
								}  
							} 
						</script>

						<!--- Display summary information about the current result --->
						<div class="rounded redbox">
							<script>
								function reloadSummarySections() { 
									var prefix = "Updated Summary of ";
									var suffix = " cataloged item records in modified result set that will be affected:";
									loadPrefixesSummaryHTML ("#result_id#","prefixesSummaryDiv");
									loadCatalogedItemCount ("#result_id#","catItemCountDiv",prefix,suffix);
									loadGeoreferenceSummaryHTML("#result_id#","georefDiv");
									loadGeoreferenceCount ("#result_id#","georefCountDiv","",""); 
									loadCollectionsSummaryHTML ("#result_id#","collectionsSummaryDiv");
									loadCountriesSummaryHTML ("#result_id#","countriesSummaryDiv");
									loadFamiliesSummaryHTML ("#result_id#","familiesSummaryDiv");
									<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
										loadAccessionsSummaryHTML ("#result_id#","accessionsSummaryDiv");
									</cfif>
									loadLocalitiesSummaryHTML ("#result_id#","localitiesSummaryDiv");
									loadCollEventsSummaryHTML ("#result_id#","collEventsSummaryDiv");
									loadPartsSummaryHTML ("#result_id#","partsSummaryDiv");
									loadPreservationsSummaryHTML ("#result_id#","preservationsSummaryDiv");
								} 
							</script>
							<cfset blockgeoref = getGeoreferenceSummaryHTML(result_id = "#result_id#")>
							<cfset georefCount = getGeoreferenceCount(result_id = "#result_id#")>
							<div class="card bg-light border-secondary mb-3">
								<div class="card-header h4">Georeferences (<span id="georefCountDiv">#georefCount#</span>)</div>
								<div class="card-body" id="georefDiv">
									#blockGeoref#
								</div>
							</div>
							<cfset blockcolls = getCollectionsSummaryHTML(result_id = "#result_id#")>
							<div class="card bg-light border-secondary mb-3" id="collectionsSummaryDiv">
								#blockcolls#
							</div>
							<cfset blockprefixes = getPrefixesSummaryHTML(result_id = "#result_id#")>
							<div class="card bg-light border-secondary mb-3" id="prefixesSummaryDiv">
								#blockprefixes#
							</div>
							<cfset blockcountries = getCountriesSummaryHTML(result_id = "#result_id#")>
							<div class="card bg-light border-secondary mb-3" id="countriesSummaryDiv">
								#blockcountries#
							</div>
							<cfset blockfamilies = getFamiliesSummaryHTML(result_id = "#result_id#")>
							<div class="card bg-light border-secondary mb-3" id="familiesSummaryDiv">
								#blockfamilies#
							</div>
							<cfset blockparts = getPartsSummaryHTML(result_id = "#result_id#")>
							<div class="card bg-light border-secondary mb-3" id="partsSummaryDiv">
								#blockparts#
							</div>
							<cfset blockpreservations = getPreservationsSummaryHTML(result_id = "#result_id#")>
							<div class="card bg-light border-secondary mb-3" id="preservationsSummaryDiv">
								#blockpreservations#
							</div>
							<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"manage_transactions")>
								<cfset blockaccessions = getAccessionsSummaryHTML(result_id = "#result_id#")>
								<div class="card bg-light border-secondary mb-3" id="accessionsSummaryDiv">
									#blockaccessions#
								</div>
							</cfif>
							<cfset blocklocalities = getLocalitiesSummaryHTML(result_id = "#result_id#")>
							<div class="card bg-light border-secondary mb-3" id="localitiesSummaryDiv">
								#blocklocalities#
							</div>
							<cfset blockcollevents = getCollEventsSummaryHTML(result_id = "#result_id#")>
							<div class="card bg-light border-secondary mb-3" id="collEventsSummaryDiv">
								#blockcollevents#
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
