<!---
grouping/addToNamedCollection.cfm

For managing arbitrary groupings of collection objects.

Copyright 2020 President and Fellows of Harvard College

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
<cfset pageTitle = "Add to Named Collection">
<cfinclude template="/shared/_header.cfm">
<cfif NOT isdefined("action") >
	<cfset action="selectColl">
</cfif>
<cfswitch expression="#action#">
	<cfcase value="selectColl">
		<cfoutput>
			<cfquery name="getItems" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT
					cataloged_item.collection_object_id,
					cataloged_item.cat_num,
					preferred_agent_name.agent_name,
					collector.coll_order,
					geog_auth_rec.higher_geog,
					locality.spec_locality,
					collecting_event.verbatim_date,
					identification.scientific_name,
					collection.institution_acronym,
					collection.collection
				FROM
					cataloged_item,
					collecting_event,
					locality,
					geog_auth_rec,
					collector,
					preferred_agent_name,
					identification,
					collection
					<cfif (not isdefined("collection_object_id")) > 
						, #session.SpecSrchTab#
					</cfif>
				WHERE
					cataloged_item.collection_object_id = collector.collection_object_id AND
					collector.agent_id = preferred_agent_name.agent_id AND
					collector_role='c' AND
					cataloged_item.collecting_event_id = collecting_event.collecting_event_id AND
					cataloged_item.collection_id = collection.collection_id AND
					collecting_event.locality_id = locality.locality_id AND
					locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id AND
					cataloged_item.collection_object_id = identification.collection_object_id AND
					identification.accepted_id_fg = 1 AND
					cataloged_item.collection_object_id
					<cfif isdefined("collection_object_id") and listlen(collection_object_id) is 1>
						= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
					<cfelseif  isdefined("collection_object_id") and listlen(collection_object_id) gt 1>
						IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#" list="yes">)
					<cfelse>
						= #session.SpecSrchTab#.collection_object_id
					</cfif>
				ORDER BY cataloged_item.collection_object_id
			</cfquery>
		    <div class="container mt-2 mb-3">
				<div class="row">
					<div class="col-12">
						<div role="region" aria-labeled-by="formheading">
							<h1 class="h2" id="formheading">Add all the items (#getItems.recordcount#) listed below to the selected named group of cataloged items.</h1>
							<form name="addItems" method="post" action="addToNamedCollection.cfm">
								<input type="hidden" name="Action" value="addItems">
								<input type="hidden" name="recordcount" value="#getItems.recordcount#">
								<cfif isdefined("collection_object_id") and listlen(collection_object_id) is 1>
									<input type="hidden" name="collection_object_id" value="#collection_object_id#">
								</cfif>
								<div class="form-row mb-3">
									<div class="col-12 col-sm-8">
										<label for="underscore_collection">Select a Named Group</label>
										<input type="text" name="collection_name" id="collection_name" class="form-control-sm reqdClr" required>
										<input type="hidden" name="underscore_collection_id" id="underscore_collection_id">
										<script>
											$(document).ready(function() {
												makeNamedCollectionPicker('collection_name','underscore_collection_id');
											});
										</script>
									</div>					
									<div class="col-6 col-sm-2 mt-1 mt-sm-4">
										<input type="submit" id="add_button" value="Add Items" class="btn-sm btn-primary">
									</div>
									<div class="col-6 col-sm-2 mt-2 mt-sm-4">
									<a href="/grouping/NamedCollection.cfm?action=new" target="_blank">Add new named group</a>
									</div>
								</div>
							</form>
						</div>
		
							<div class="form-row mb-5">
								<table class="table table-responsive">
									<thead>
									<tr>
										<th>Cat Num</th>
										<th>Scientific Name</th>
										<th>Collectors</th>
										<th>Geog</th>
										<th>Spec Loc</th>
										<th>Date</th>
									</tr>
								</thead>
									<tbody>
									<cfloop query="getItems" group="collection_object_id">
									<tr>
										<td>#collection# #cat_num#</td>
										<td style="width: 200px;">#scientific_name#</td>
										<td style="width: 200px;">
											<cfquery name="getAgent" dbtype="query">
												select agent_name, coll_order 
												from getItems where collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getItems.collection_object_id#">
												order by coll_order
											</cfquery>
											<cfset colls = "">
											<cfloop query="getAgent">
												<cfif len(#colls#) is 0>
													<cfset colls = #getAgent.agent_name#>
												  <cfelse>
												  	<cfset colls = "#colls#, #getAgent.agent_name#">
												</cfif>
											</cfloop>
										#colls#</td>
										<td>#higher_geog#</td>
										<td>#spec_locality#</td>
										<td style="width:100px;">#verbatim_date#</td>
									</tr>
									</cfloop>
									</tbody>
								</table>
		
							</div>
						</div>
					</div>
				</div>
			</div>
		</cfoutput>
	</cfcase>
	<cfcase value="addItems">
		<cfif NOT isdefined("underscore_collection_id")>
			<cfthrow message="No named grouping selected, unable to add cataloged items">
		</cfif>
		<cfif NOT isdefined("recordcount") OR recordcount EQ 0>
			<cfthrow message="No cataloged items to add to named group.">
		</cfif>
		<cftransaction>
			<cfquery name="countToAdd" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select count(*) as ct from #session.SpecSrchTab# 
			</cfquery>
			<cfif countToAdd.ct NEQ recordcount>
				<cfthrow message="Add failed.  Discrepancy between the expected and actual number of records to add, user ran a new search before completing add to group.">
			</cfif>
			<cfquery name="unColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT underscore_collection.underscore_collection_id as id
				FROM underscore_collection
				WHERE underscore_collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#underscore_collection_id#">
			</cfquery>
			<cfset idToAdd = unColl.id>
			<cfif unColl.recordcount NEQ 1>
				<cfthrow message="No such named grouping found, unable to add cataloged items">
			</cfif>
			<cfquery name="addItemsToColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="add_result">
				INSERT /*+ ignore_row_on_dupkey_index ( underscore_relation (collection_object_id, underscore_collection_id ) ) */
					into underscore_relation (underscore_collection_id, collection_object_id)
				select #idToAdd#, collection_object_id 
				from #session.SpecSrchTab# 
			</cfquery>
		</cftransaction>
		<cfoutput>
			<cflocation url="/grouping/NamedCollection.cfm?action=edit&underscore_collection_id=#underscore_collection_id#" addtoken="false">
		</cfoutput>
	</cfcase>
	<cfdefaultcase>
		<cfthrow message="Action for addToNamedCollection.cfm not recognized.">
	</cfdefaultcase>
</cfswitch>
<cfinclude template = "/shared/_footer.cfm">
